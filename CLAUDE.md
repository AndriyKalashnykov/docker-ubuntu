# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Docker Ubuntu base image plus Java and Go development-environment variants, built on
**Ubuntu 26.04 LTS**. Each image bundles a broad cloud-native / DevOps toolchain for use
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
make build-go         # Build Go dev image  (FROM base) — credential-free; creds injected at run time
make run-base|run-java|run-go   # docker run -it --rm <img> bash (run-go bind-mounts the docker socket and CWD, joins the host docker group via --group-add — DooD)
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
- Backends in use: core (kubectl, helm, go, java, …), `aqua:` (vivid, goreleaser),
  `github:` (s2i — not in the aqua registry; needs `exe = "s2i"`), `go:`
  (Go dev CLIs). Non-mise tools (apt packages, docker-engine) stay on apt / the official
  pinned installer — see TOOLING.md for the why.

## Secrets (runtime injection, not baked into the image)

**All three images are credential-free at build time** — base, java, and go build with
no host secrets, so any of them can be built anywhere (including CI). base generates its
own SSH key; java reuses the inherited one. The **go** image's operator credentials
(SSH/GPG/PAT) are injected **at container start** by `go/scripts/entry.sh`, from runtime
bind-mounts / env supplied by `make run-go` — they never enter the image filesystem:

| Credential | Runtime source (mounted/passed by `make run-go`) | In-container target | Absent → |
|-----------|--------|--------|----------|
| SSH key | `~/.ssh/id_rsa{,.pub}` → `/run/host-ssh/` (ro bind) | `~/.ssh/id_rsa{,.pub}` + `authorized_keys` | a fresh per-container key is generated |
| GPG key | `${DOTFILES_DIR}/gnupg/AndriyKalashnykov-*.{key,txt}` → `/run/host-gpg/` (ro bind) | imported into `~/.gnupg` | GPG import skipped |
| GPG passphrase | `$MY_GPG_PASSWORD` (`-e`, value from env) | used for the import | GPG import skipped |
| GitHub PAT | `$GITHUB_PAT` (`-e`, value from env) | `~/.netrc` (0600) | `.netrc` not written |

The Makefile builds the `GO_RUN_CREDS` mount/env list conditionally (`$(wildcard ...)` +
`-e VAR` name-only, so secret VALUES never touch argv). Because the go image no longer
contains operator credentials it is now safe to build/share, but it stays **local-only by
policy** (a personal dev container layered on the published base+java): CI does not build
go, **`make push-go` is blocked unless `ALLOW_GO_PUSH=1`**, and `build-push-all` excludes it.

## Architecture

Three independent build contexts, one per image, layered by `FROM`:

```
ubuntu:26.04 (UBUNTU_VERSION)
  └─ base/   → docker-ubuntu-base   (apt dev tools, Docker-in-Docker, mise + base toolchain)
       ├─ java/ → docker-ubuntu-java (Java 25 LTS / Maven / Gradle via mise)
       └─ go/   → docker-ubuntu-go   (Go 1.26 toolchain & CLIs via mise, kubebuilder, GPG, PostgreSQL)
```

Each `<context>/` directory holds: a `Dockerfile`, a pinned `.mise.toml`, and a small
`scripts/` dir. `entry.sh` activates mise at container start; the **go** `entry.sh` also
runs `generate-ssh-keys.sh` / `generate-gpg-keys.sh` then, setting up credentials from
runtime bind-mounts (`/run/host-ssh`, `/run/host-gpg`) + env — nothing is baked into the
image. The old `install-*.sh` tool-fetch scripts were removed when mise took over.

### Cross-cutting build mechanics

- **Named USER (load-bearing)**: all three Dockerfiles use `USER $USER_NAME` (not numeric
  `1000:1000`). Numeric USER does NOT load supplementary groups, so passwordless `sudo`
  (group `sudo`) and docker-socket access (group `docker`) would silently break in the
  java/go builds. Keep it as the name.
- **Base-image coupling**: `java/Dockerfile` and `go/Dockerfile` hardcode
  `FROM ghcr.io/andriykalashnykov/docker-ubuntu-base:$UBUNTU_VERSION`. The Makefile's
  `build-java`/`build-go` depend on `build-base` to produce that tag locally; otherwise
  they pull the published base from GHCR.
- **Version pins**: only `UBUNTU_VERSION` (Makefile, passed `--build-arg`) and
  `MISE_VERSION` (base Dockerfile `ARG`) live outside mise. Java/Maven/Go and every other
  tool version live in the `.mise.toml` files — do NOT add language version vars back to
  the Makefile.
- **Reproducible caching**: pinned tools make builds reproducible, so the old `random.org`
  cache-busting `ADD`s were removed; `build-*-inline-cache` targets push a `-cache` tag.

### CI

`.github/workflows/main.yml` (`name: CI`) builds, scans, signs and **publishes base + java
to GHCR** (the go image is local-only — it needs operator secrets). Jobs: `changes`
(dorny/paths-filter) → `static-check` (hadolint + Trivy fs) → `build` (build → Trivy image
scan → tag-gated push → cosign keyless signing by digest → SBOM (base)) → `ci-pass` aggregator.
Push happens on `push`/tag events only (PRs build+scan but don't push/sign).
`cleanup-runs.yml` prunes old runs via `gh`. Renovate (`renovate.json`) updates the Ubuntu
tag (+ its pinned digest), Action SHAs, the mise ARG, and every mise-pinned tool.

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

- **Multi-arch (arm64)** — PREPARED but intentionally DISABLED; builds are `linux/amd64`
  only for now (see the commented scaffold near `build-base` in the Makefile). All
  asset-level blockers are cleared and a `linux/arm64` base build was confirmed to
  succeed: gcloud (the one hardcoded `x86_64` asset) and cloud-sql-proxy were removed,
  the amd64-only `rar` package was swapped for `unrar` (arm64-available; extraction
  kept, proprietary creation dropped), and every mise-pinned tool has verified arm64
  builds; `mise.run`, `get.docker.com`, and apt are already arch-aware. To enable later:
  convert the build to `docker buildx --platform linux/amd64,linux/arm64 --push`
  (Makefile + CI) with multi-arch cosign/SBOM and a QEMU/native-arm-runner choice.
- **Publish go from CI** — now *unblocked* (the go image is credential-free; see "Secrets"
  above). Still local-only by policy; enabling CI publish would only require adding go to
  the build/push jobs — no secret-surface decision remains.

### Resolved
- **go image credential surface** — RESOLVED. Operator SSH/GPG/PAT are injected at
  container start (`go/scripts/entry.sh` from `make run-go` runtime mounts/env), never
  baked into the image filesystem.
