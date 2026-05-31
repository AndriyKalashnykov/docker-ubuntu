# Tooling & Version Management

This repo pins **every** tool it installs into the images, so builds are
reproducible and dependency bumps are automated. There is one rule:

> **A tool version lives in exactly one place, and that place is automatically
> tracked by Renovate.** Never `latest`, never fetched-at-build-time.

## Strategy at a glance

| Layer | Mechanism | Source of truth | Auto-updated by |
|-------|-----------|-----------------|-----------------|
| CLI dev tools (kubectl, helm, go, java, …) | **[mise](https://mise.jdx.dev)** | `base/.mise.toml`, `java/.mise.toml`, `go/.mise.toml` | Renovate `mise` manager |
| Go dev CLIs (dlv, swag, goose, …) | mise **`go:` backend** | `go/.mise.toml` | Renovate |
| Prebuilt single binaries (goreleaser, cloud-sql-proxy, vivid) | mise **`aqua:` backend** | the `.mise.toml` files | Renovate |
| s2i (not in the aqua registry) | mise **`github:` backend** (`exe = "s2i"`) | `base/.mise.toml` | Renovate |
| Base OS image | Docker `FROM` + `ARG UBUNTU_VERSION` | `Makefile` (`UBUNTU_VERSION`) + Dockerfile `ARG` | Renovate (`# renovate:` custom manager) |
| mise itself | pinned installer | `base/Dockerfile` (`ARG MISE_VERSION`) | Renovate (`# renovate:`) |
| OS packages (git, gnupg, postgresql, docker-engine…) | `apt-get` | the Dockerfiles | — (tracks the Ubuntu release) |
| Google Cloud SDK | pinned official tarball | java/go Dockerfiles (`ARG GCLOUD_VERSION`) | Renovate (`# renovate:`) |

## Why mise for "everything possible"

Before this migration, every tool was fetched with a `curl …/releases/latest`
call at build time — no pins, no checksums, non-reproducible (two builds a day
apart could ship different tool versions). mise replaces all of that with a
declarative, pinned, lockable manifest.

mise manages a tool when a backend exists for it (core / `aqua:` / `go:` /
asdf). The full active tool set is mise-managed; see the three `.mise.toml`
files for the authoritative list.

## What is NOT under mise (and why)

| Tool | Why it stays off mise | How it's still pinned |
|------|-----------------------|-----------------------|
| `git`, `gnupg`, `postgresql`, build tools | OS packages — belong to apt, not a version manager | Tracks the pinned Ubuntu release |
| Docker engine (Docker-in-Docker) | Installed via the official `get.docker.com` convenience script in the base image | Tied to the Docker channel; bump by re-building |
| **Google Cloud SDK** | A multi-component SDK (hundreds of files, component manager), not a single versioned binary — mise has no first-class backend | `ARG GCLOUD_VERSION` pinned to the official versioned tarball + `# renovate:` comment |

`cloud-sql-proxy` **is** a single binary, so it lives under mise (`aqua:`) even
though the gcloud SDK does not.

## The image layering & mise config merge

```
base/.mise.toml  → installed as the mise GLOBAL config (~/.config/mise/config.toml)
                   k8s + devops toolset every image inherits
   │
   ├─ java/.mise.toml → ~/.mise.toml (LOCAL, merges on top) → + java/maven/gradle + cloud-sql-proxy
   └─ go/.mise.toml   → ~/.mise.toml (LOCAL, merges on top) → + go + go CLIs + kubebuilder + goreleaser + cloud-sql-proxy
```

At container start, `scripts/entry.sh` runs `mise activate`, so every pinned
tool is on `PATH` with its environment (`JAVA_HOME`, `GOROOT`, …) set.

## How to add or bump a tool

1. **Bump a version** — edit the version string in the relevant `.mise.toml`
   (or the `ARG` for gcloud/ubuntu/mise). Renovate will also open PRs for these
   automatically.
2. **Add a new tool** — confirm a backend exists: `mise registry | grep <name>`
   (or use an explicit `aqua:owner/repo` / `go:module` ref). Add the pinned
   line to the appropriate `.mise.toml`, then rebuild the image.
3. **Validate before building** — `mise ls --current` from the build context
   directory confirms every tool identifier and version resolves.

## Validation

- `make renovate-validate` — validates `renovate.json` against the schema.
- `mise ls --current` (run inside `base/`, `java/`, or `go/`) — confirms the
  manifest parses and all tool identifiers resolve.
- `make lint` — hadolint over all three Dockerfiles.
