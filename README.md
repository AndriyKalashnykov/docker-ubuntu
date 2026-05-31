[![CI](https://github.com/AndriyKalashnykov/docker-ubuntu/actions/workflows/main.yml/badge.svg)](https://github.com/AndriyKalashnykov/docker-ubuntu/actions/workflows/main.yml)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://app.renovatebot.com/dashboard#github/AndriyKalashnykov/docker-ubuntu)
[![Hits](https://hits.sh/github.com/AndriyKalashnykov/docker-ubuntu.svg?style=plastic)](https://hits.sh/github.com/AndriyKalashnykov/docker-ubuntu/)
[![License: MIT](https://img.shields.io/badge/License-MIT-brightgreen.svg)](https://opensource.org/licenses/MIT)

# Ubuntu Development Environment (Java and Go Docker images)

A layered set of Ubuntu-based development-environment Docker images. A common
**base** image ships a broad cloud-native / DevOps toolchain (kubectl, helm,
kustomize, k9s, kind, flux, conftest, opa, Docker-in-Docker, …); the **java**
and **go** variants build on it with their respective language stacks. Every
tool version is pinned and reproducible — see [TOOLING.md](./TOOLING.md).

![make-help](./images/carbon.png)

## Image hierarchy

```
ubuntu:26.04 (LTS)
  └─ docker-ubuntu-base   base + DevOps toolchain (mise-managed) + Docker-in-Docker
       ├─ docker-ubuntu-java   + Java 25 LTS / Maven / Gradle, Google Cloud SDK, Cloud SQL Proxy
       └─ docker-ubuntu-go     + Go toolchain & dev CLIs, kubebuilder, goreleaser,
                                 GPG, PostgreSQL, Google Cloud SDK, Cloud SQL Proxy
```

The `java` and `go` images are built `FROM ghcr.io/andriykalashnykov/docker-ubuntu-base`,
so `make build-java` / `make build-go` depend on `make build-base`.

## Tooling & versions

All CLI tools are managed by **[mise](https://mise.jdx.dev)** and pinned in
per-image `.mise.toml` files (`base/.mise.toml`, `java/.mise.toml`,
`go/.mise.toml`); the base OS, mise itself, and the Google Cloud SDK are pinned
via Dockerfile `ARG`s. Everything is kept current automatically by Renovate.
The full strategy and the list of what is/ isn't mise-managed is documented in
**[TOOLING.md](./TOOLING.md)**.

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| [Docker](https://docs.docker.com/get-docker/) with BuildKit | `DOCKER_BUILDKIT=1`; `buildx` for `--secret` mounts |
| GNU Make | drives all build/run/push targets |
| `GITHUB_PAT` (write:packages) | only for `make login` / `push-*` to GHCR |

**base** and **java** build with no host secrets. The **go** image optionally
consumes operator secrets via BuildKit secret mounts (it builds without them — a
fresh SSH key is generated and the GPG import is skipped): an SSH key pair at
`~/.ssh/id_rsa{,.pub}`, a GPG key pair at
`${DOTFILES_DIR}/gnupg/AndriyKalashnykov-secret-gpg.key` + `…-ownertrust-gpg.txt`
(`DOTFILES_DIR` defaults to `~/projects/dotfiles`), and the `GITHUB_PAT` /
`MY_GPG_PASSWORD` env vars. These paths are owner-specific.

```bash
export GITHUB_PAT=<github-pat-with-write:packages>   # for `make login` / push to GHCR
```

## Quick start

### Build and run the images locally

```bash
make build-base && make run-base      # base image
make build-java && make run-java      # java dev image
make build-go   && make run-go        # go dev image
```

`run-*` drops you into an interactive `bash` shell with the full toolchain on
`PATH` (and `JAVA_HOME` / `GOROOT` set by the entrypoint). `run-go` additionally
bind-mounts the host Docker socket (Docker-out-of-Docker) and the current directory.

### Run a published image (no build needed)

The `base` and `java` images are published to GHCR — pull and run directly:

```bash
docker run -it --rm ghcr.io/andriykalashnykov/docker-ubuntu-base:26.04 bash
docker run -it --rm ghcr.io/andriykalashnykov/docker-ubuntu-java:26.04 bash
```

### Build a Java or Go app inside the container

Mount your project and run the toolchain. The entrypoint activates mise, so
`java`/`mvn`/`gradle`/`go` and `JAVA_HOME`/`GOROOT` are ready:

```bash
# Java (image ships Java 25 LTS, Maven 3.9, Gradle 9)
docker run --rm -it -v "$PWD":/home/user/app -w /home/user/app \
  ghcr.io/andriykalashnykov/docker-ubuntu-java:26.04 mvn -B package
docker run --rm -it -v "$PWD":/home/user/app -w /home/user/app \
  ghcr.io/andriykalashnykov/docker-ubuntu-java:26.04 gradle build

# Go (image ships Go 1.26 + dlv, goreleaser, swag, goose, …) — build go locally first
make build-go
docker run --rm -it -v "$PWD":/home/user/app -w /home/user/app \
  ghcr.io/andriykalashnykov/docker-ubuntu-go:26.04 go build ./...
docker run --rm -it -v "$PWD":/home/user/app -w /home/user/app \
  ghcr.io/andriykalashnykov/docker-ubuntu-go:26.04 go test ./...

# …or open an interactive shell with your project mounted and work normally:
docker run --rm -it -v "$PWD":/home/user/app -w /home/user/app \
  ghcr.io/andriykalashnykov/docker-ubuntu-java:26.04 bash
```

> The **go** image is built locally only (`make build-go`) — it is not published
> to GHCR because it can carry operator credentials, so build it before running it.

## Make targets

Run `make help` for the authoritative list.

| Target | Description |
|--------|-------------|
| `help` | List available targets |
| `check-env` | Check required env vars and installed tools |
| `login` | Log in to GHCR (GITHUB_PAT via `--password-stdin`) |
| `lint` | Lint all Dockerfiles with hadolint |
| `ci` | Run local CI checks (lint + build-base) |
| `renovate-validate` | Validate `renovate.json` against the Renovate schema |
| `build-base` / `run-base` / `push-base` / `delete-base` | Base image lifecycle |
| `build-java` / `run-java` / `push-java` / `delete-java` | Java image lifecycle |
| `build-go` / `run-go` / `delete-go` | Go image lifecycle (built locally only) |
| `push-go` | Push go image — **blocked unless `ALLOW_GO_PUSH=1`** (it bakes operator creds; private registries only) |
| `build-base-inline-cache` / `build-java-inline-cache` | Build & push the registry inline cache |
| `build-all` | Build base + go + java |
| `build-push-all` | Build & push the **publishable** images (base + java; go excluded) |
| `cleanup` | Remove all images/layers/containers/volumes and prune build cache |

## Environment variables

| Variable | Purpose |
|----------|---------|
| `GITHUB_PAT` | GHCR auth (write:packages) for `login`/`push-*`; also injected into the **go** image `.netrc` (secret mount) |
| `MY_GPG_PASSWORD` | GPG key passphrase for the **go** image (secret mount) |
| `DOTFILES_DIR` | Override the dotfiles path (default `~/projects/dotfiles`) |
| `DOCKER_REGISTRY` | Override the publish registry (default `ghcr.io`) |

## CI/CD

- **`CI`** ([`main.yml`](./.github/workflows/main.yml)) — builds, scans, signs and
  publishes the **base + java** images to GHCR. Pipeline: `changes`
  (paths-filter) → `static-check` (hadolint + Trivy filesystem scan) → `build`
  (build → Trivy image scan → tag-gated push with provenance + SBOM → cosign
  keyless signing) → `ci-pass`. PRs build and scan but do not push/sign. The
  **go** image is built locally only (it needs operator secrets).
- **Cleanup runs** ([`cleanup-runs.yml`](./.github/workflows/cleanup-runs.yml))
  — weekly prune of old workflow runs via the `gh` CLI.

Dependency updates are handled by **Renovate** (`renovate.json`): the Ubuntu base
tag, GitHub Action SHAs, the gcloud/mise `ARG`s, and every mise-pinned tool.

## License

[MIT](./LICENSE)
