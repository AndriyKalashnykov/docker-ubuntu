# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Docker Ubuntu base image plus Java and Go development-environment variants, built on
**Ubuntu 24.04 LTS**. Each image bundles a broad cloud-native / DevOps toolchain for use
as a disposable dev container. All CLI tool versions are pinned and managed by **mise**.
Images publish to **GHCR** (`ghcr.io/andriykalashnykov/...`).

## Build / Run Commands

All workflows go through the Makefile (`make help` lists every target):

```bash
make check-env        # Verify docker is installed
make lint             # hadolint over base/java/go Dockerfiles (uses .hadolint.yaml)
make ci               # Local CI: lint + build-base
make renovate-validate# Validate renovate.json against the schema
make login            # Log in to GHCR (needs GITHUB_PAT with write:packages)
make build-base       # Build base; build-java/build-go depend on this
make build-java       # Build Java dev image (FROM base)
make build-go         # Build Go dev image  (FROM base) — secrets via BuildKit mounts
make run-base|run-java|run-go   # docker run -it --rm <img> bash (run-go bind-mounts the docker socket via --group-add — DooD)
make delete-base|delete-java|delete-go
make build-all        # build-base + build-go + build-java
make build-push-all   # Build inline caches + images, push to GHCR
make cleanup          # Remove all images/layers/exited containers/dangling vols + prune buildx
```

`make lint`/`make ci` are the local quality gates (there is no app source / test suite —
validation of an image is "does it build"). `make delete-*` / `make cleanup` find images
by the `LABEL stage=<IMAGE_LABEL>` set in each Dockerfile, so the build-arg `IMAGE_LABEL`
is load-bearing for cleanup, not cosmetic. The registry is forced to `ghcr.io` with `:=`
(env-pollution-proof); override per-invocation with `make DOCKER_REGISTRY=...`.

## Tool / version management (read TOOLING.md)

**mise is the single tool-version manager.** Every CLI tool is pinned in a per-image
`.mise.toml` (`base/.mise.toml`, `java/.mise.toml`, `go/.mise.toml`); the base OS tag,
mise itself, and the Google Cloud SDK are pinned via Dockerfile/Makefile `ARG`s/vars with
`# renovate:` annotations. **[TOOLING.md](./TOOLING.md)** is the authoritative strategy doc.
Key rules:

- A tool version lives in exactly one place (its `.mise.toml` line, or a `# renovate:`
  ARG). Never `latest`, never fetched-at-build-time.
- Validate a manifest before building: `cd <img> && mise ls --current` resolves every
  tool identifier; `mise install` in an isolated `MISE_DATA_DIR` proves versions install.
- mise configs MERGE: `base/.mise.toml` installs as the mise GLOBAL config
  (`~/.config/mise/config.toml`); java/go add a LOCAL `~/.mise.toml` on top, so each
  variant inherits the full base toolset.
- `entry.sh` runs `mise activate --shims` + `mise env` at container start, so tool env
  (`JAVA_HOME`, `GOROOT`, …) is set in interactive AND non-interactive shells.
- Backends in use: core (kubectl, helm, go, java, …), `aqua:` (vivid, cloud-sql-proxy,
  goreleaser), `github:` (s2i — not in the aqua registry; needs `exe = "s2i"`), `go:`
  (Go dev CLIs). Non-mise tools (apt packages, docker-engine, the multi-component gcloud
  SDK) stay on apt / official pinned installers — see TOOLING.md for the why.

## Secrets (BuildKit secret mounts, not build args)

**base and java are secret-free** (base generates its own SSH key; java reuses the
inherited one) — they build with no host secrets and are published from CI. Only the **go**
image consumes operator secrets, and only via **BuildKit `--secret` mounts** (never build
args — those leak through `docker history`):

| Secret id | Source | Absent → |
|-----------|--------|----------|
| `ssh_priv` / `ssh_pub` | `~/.ssh/id_rsa{,.pub}` | a fresh key is generated |
| `gpg_secret` / `gpg_ownertrust` | `${DOTFILES_DIR}/gnupg/AndriyKalashnykov-*.{key,txt}` | GPG import skipped |
| `gpg_pwd` | `$MY_GPG_PASSWORD` | GPG import skipped |
| `github_pat` | `$GITHUB_PAT` | `.netrc` not written |

The Makefile builds the `GO_BUILD_SECRETS` list conditionally (`$(wildcard ...)`), so the
go image builds with whatever subset is present. The go image's scripts read
`/run/secrets/<id>` and fall back gracefully. NOTE: the go image still *contains* the
operator's key material in its filesystem by design (a personal dev container) — keep go
images private; CI does not build go.

## Architecture

Three independent build contexts, one per image, layered by `FROM`:

```
ubuntu:24.04 (UBUNTU_VERSION)
  └─ base/   → docker-ubuntu-base   (apt dev tools, Docker-in-Docker, mise + base toolchain)
       ├─ java/ → docker-ubuntu-java (Java 25 LTS / Maven / Gradle via mise, GCloud SDK, Cloud SQL Proxy)
       └─ go/   → docker-ubuntu-go   (Go toolchain & CLIs via mise, kubebuilder, GPG, PostgreSQL, GCloud SDK)
```

Each `<context>/` directory holds: a `Dockerfile`, a pinned `.mise.toml`, and a small
`scripts/` dir (`entry.sh` activates mise; `go/scripts` also keeps
`generate-ssh-keys.sh` / `generate-gpg-keys.sh`, which read `/run/secrets/*`). The old
`install-*.sh` tool-fetch scripts were removed when mise took over.

### Cross-cutting build mechanics

- **Named USER (load-bearing)**: all three Dockerfiles use `USER $USER_NAME` (not numeric
  `1000:1000`). Numeric USER does NOT load supplementary groups, so passwordless `sudo`
  (group `sudo`) and docker-socket access (group `docker`) would silently break in the
  java/go builds. Keep it as the name.
- **Base-image coupling**: `java/Dockerfile` and `go/Dockerfile` hardcode
  `FROM ghcr.io/andriykalashnykov/docker-ubuntu-base:$UBUNTU_VERSION`. The Makefile's
  `build-java`/`build-go` depend on `build-base` to produce that tag locally; otherwise
  they pull the published base from GHCR.
- **Version pins**: only `UBUNTU_VERSION` (Makefile, passed `--build-arg`), `MISE_VERSION`
  and `GCLOUD_VERSION` (Dockerfile `ARG`s) live outside mise. Java/Maven/Go and every other
  tool version live in the `.mise.toml` files — do NOT add language version vars back to
  the Makefile.
- **gcloud download resilience**: the gcloud `curl` uses `--retry 3 --retry-all-errors
  --connect-timeout 30` (the 150 MB tarball can time out under parallel java+go builds).
- **Reproducible caching**: pinned tools make builds reproducible, so the old `random.org`
  cache-busting `ADD`s were removed; `build-*-inline-cache` targets push a `-cache` tag.

### CI

`.github/workflows/main.yml` (`name: CI`) builds, scans, signs and **publishes base + java
to GHCR** (the go image is local-only — it needs operator secrets). Jobs: `changes`
(dorny/paths-filter) → `static-check` (hadolint + Trivy fs) → `build` (build → Trivy image
scan → tag-gated push with provenance+SBOM → cosign keyless signing) → `ci-pass` aggregator.
Push happens on `push`/tag events only (PRs build+scan but don't push/sign).
`cleanup-runs.yml` prunes old runs via `gh`. Renovate (`renovate.json`) updates the Ubuntu
tag, Action SHAs, gcloud/mise ARGs, and every mise-pinned tool.

## Skills

| File(s) | Skill |
|---------|-------|
| `Makefile` | `/makefile` |
| `README.md` | `/readme` |
| `.github/workflows/*.{yml,yaml}` | `/ci-workflow` |
| `renovate.json` | `/renovate` |
| `base/Dockerfile`, `java/Dockerfile`, `go/Dockerfile` | `/harden-image-pipeline` |

When spawning subagents, always pass the conventions from the respective skill into the
agent's prompt.

## Improvement Backlog

- **Multi-arch** — images build `linux/amd64` only; add `linux/arm64` for Apple Silicon /
  Graviton (gcloud + some mise tools need arch-aware asset selection).
- **go image credential surface** — the go image bakes operator SSH/GPG/PAT material into
  its filesystem by design (personal dev container). Keep go images private; consider a
  runtime-mount alternative if it ever needs to be shared.
- **Publish go from CI** — currently local-only because it needs operator secrets; would
  require GH secrets + a decision on the credential surface above.
