# CLAUDE.md

Docker Ubuntu base image with development environment variants (Java, Go).
Builds multi-layer Docker images on top of Ubuntu with development tooling pre-installed.

## Build / Test Commands

```bash
make help                    # List available targets
make check-env               # Check environment variables and installed tools
make login                   # Login to a registry
make build-base              # Build base image
make run-base                # Run base image
make push-base               # Push base image to a registry
make delete-base             # Delete base image locally
make build-base-inline-cache # Build remote cache for the base image
make build-java              # Build java dev image
make run-java                # Run java dev image
make push-java               # Push java dev image to a registry
make delete-java             # Delete java dev image locally
make build-java-inline-cache # Build remote cache for the java dev image
make build-go                # Build go dev image
make run-go                  # Run go dev image
make push-go                 # Push go dev image to a registry
make build-all               # Build all images
make build-push-all          # Build and push all cache and images
make cleanup                 # Cleanup docker images, containers, volumes, networks, build cache
```

## Environment Variables

- `DOCKER_LOGIN` - Docker registry username
- `DOCKER_PWD` - Docker registry password

## Image Hierarchy

```
ubuntu:22.10 (base OS)
  -> docker-ubuntu-base (base + dev tools, Docker-in-Docker)
       -> docker-ubuntu-java (+ SDKMAN, Java, Maven, Gradle, GCloud SDK)
       -> docker-ubuntu-go   (+ Go, GPG, GCloud SDK, PostgreSQL)
```

## Skills

- Makefile -> /makefile
- README.md -> /readme
- .github/workflows/*.yml -> /ci-workflow

## Improvement Backlog

- Add renovate.json for automated dependency updates
- Upgrade Ubuntu base version (currently 22.10, EOL)
- Update Java/Maven/Go versions in Makefile
- Add Hadolint for Dockerfile linting in CI
