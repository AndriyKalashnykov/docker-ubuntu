.DEFAULT_GOAL := help

SHELL := /bin/bash

# Base-image tag only. Java/Maven/Go and every other tool version are pinned in
# the per-image .mise.toml files (base/.mise.toml, java/.mise.toml, go/.mise.toml)
# and managed by mise + Renovate — NOT here.
# renovate: datasource=docker depName=ubuntu versioning=ubuntu
UBUNTU_VERSION := 26.04

# Dev-container identity defaults — non-secret, operator-tunable. `?=` lets the
# env / command line override them (e.g. `make USER_UID=1001 build-base`).
ROOT_PWD  ?= Docker!
USER_UID  ?= 1000
USER_GID  ?= 1000
USER_NAME ?= user
USER_PWD  ?= user
USER_EMAIL ?= AndriyKalashnykov@gmail.com

# Registry — GitHub Container Registry. Auth uses a GitHub PAT (GITHUB_PAT) with
# write:packages. REGISTRY_OWNER MUST be lowercase (ghcr requirement).
# `:=` (not `?=`) so an exported IMAGE_REGISTRY in the shell can't silently
# redirect publishes; override on the command line with `make IMAGE_REGISTRY=...`.
IMAGE_REGISTRY := ghcr.io
REGISTRY_OWNER  := andriykalashnykov

IMAGE      := docker-ubuntu-base
IMAGE_JAVA := docker-ubuntu-java
IMAGE_GO   := docker-ubuntu-go

IMAGE_NAME                   := $(IMAGE_REGISTRY)/$(REGISTRY_OWNER)/$(IMAGE):$(UBUNTU_VERSION)
IMAGE_INLINE_CACHE_NAME      := $(IMAGE_REGISTRY)/$(REGISTRY_OWNER)/$(IMAGE)-cache:$(UBUNTU_VERSION)
IMAGE_JAVA_NAME              := $(IMAGE_REGISTRY)/$(REGISTRY_OWNER)/$(IMAGE_JAVA):$(UBUNTU_VERSION)
IMAGE_JAVA_INLINE_CACHE_NAME := $(IMAGE_REGISTRY)/$(REGISTRY_OWNER)/$(IMAGE_JAVA)-cache:$(UBUNTU_VERSION)
IMAGE_GO_NAME                := $(IMAGE_REGISTRY)/$(REGISTRY_OWNER)/$(IMAGE_GO):$(UBUNTU_VERSION)

export DOCKER_BUILDKIT=1

DOTFILES_DIR ?= $(HOME)/projects/dotfiles

# Runtime credential injection for the go image (`make run-go`). The image bakes
# NO secrets — the operator's SSH/GPG keys and PAT are mounted/passed at CONTAINER
# START and set up by go/scripts/entry.sh. Each is included only when present on
# the host (so a bare run still works: a fresh SSH key is generated, GPG/PAT
# skipped). Secret VALUES never touch argv: `-e` passes the var NAME (value
# inherited from the env); file secrets are read-only bind mounts.
# Per-file `$(wildcard ...)` guards are load-bearing: mounting a NON-existent host
# path makes Docker create a root-owned empty dir at both ends, so only files that
# actually exist are mounted. Both id_rsa and id_ed25519 are supported.
GO_RUN_CREDS :=
ifneq ($(wildcard $(HOME)/.ssh/id_rsa),)
GO_RUN_CREDS += -v $(HOME)/.ssh/id_rsa:/run/host-ssh/id_rsa:ro
endif
ifneq ($(wildcard $(HOME)/.ssh/id_rsa.pub),)
GO_RUN_CREDS += -v $(HOME)/.ssh/id_rsa.pub:/run/host-ssh/id_rsa.pub:ro
endif
ifneq ($(wildcard $(HOME)/.ssh/id_ed25519),)
GO_RUN_CREDS += -v $(HOME)/.ssh/id_ed25519:/run/host-ssh/id_ed25519:ro
endif
ifneq ($(wildcard $(HOME)/.ssh/id_ed25519.pub),)
GO_RUN_CREDS += -v $(HOME)/.ssh/id_ed25519.pub:/run/host-ssh/id_ed25519.pub:ro
endif
ifneq ($(wildcard $(DOTFILES_DIR)/gnupg/AndriyKalashnykov-secret-gpg.key),)
GO_RUN_CREDS += -v $(DOTFILES_DIR)/gnupg/AndriyKalashnykov-secret-gpg.key:/run/host-gpg/secret.key:ro
endif
ifneq ($(wildcard $(DOTFILES_DIR)/gnupg/AndriyKalashnykov-ownertrust-gpg.txt),)
GO_RUN_CREDS += -v $(DOTFILES_DIR)/gnupg/AndriyKalashnykov-ownertrust-gpg.txt:/run/host-gpg/ownertrust.txt:ro
endif
ifneq ($(strip $(GITHUB_PAT)),)
GO_RUN_CREDS += -e GITHUB_PAT
endif
ifneq ($(strip $(GPG_PASSPHRASE)),)
GO_RUN_CREDS += -e GPG_PASSPHRASE
endif

# make sure docker is installed
DOCKER_EXISTS := @printf "docker"
DOCKER_WHICH  := $(shell which docker)
ifeq ($(strip $(DOCKER_WHICH)),)
	DOCKER_EXISTS := @echo "ERROR: docker not found. See: https://docs.docker.com/get-docker/" && exit 1
endif

#help: @ List available tasks on this project
help:
	@echo "Usage: make COMMAND"
	@echo
	@echo "Commands :"
	@echo
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#' | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[32m%-23s\033[0m - %s\n", $$1, $$2}'

#check-env: @ Check that docker is installed
check-env:
	@printf "\xE2\x9C\x94 "
	$(DOCKER_EXISTS)
	@echo ""

#login: @ Log in to GHCR (uses GITHUB_PAT with write:packages)
login: check-env
	@[ -n "$$GITHUB_PAT" ] || { echo "ERROR: GITHUB_PAT (write:packages) is required to log in to $(IMAGE_REGISTRY)"; exit 1; }
	@printf '%s' "$$GITHUB_PAT" | docker login $(IMAGE_REGISTRY) -u $(REGISTRY_OWNER) --password-stdin

#lint: @ Lint Dockerfiles (hadolint) + verify shell scripts are executable
lint: lint-scripts-exec
	@command -v hadolint >/dev/null 2>&1 || { echo "ERROR: hadolint not found. See: https://github.com/hadolint/hadolint"; exit 1; }
	@hadolint base/Dockerfile java/Dockerfile go/Dockerfile

#lint-scripts-exec: @ Fail if any committed shell script lacks the +x bit
lint-scripts-exec:
	@NONEXEC=$$(find base go -name '*.sh' -not -executable -print); \
		if [ -n "$$NONEXEC" ]; then \
			echo "ERROR: shell scripts missing +x (run: chmod +x <file>):"; \
			echo "$$NONEXEC" | sed 's/^/  /'; exit 1; \
		fi

#ci: @ Run local CI checks (Dockerfile lint + build the base image)
ci: lint build-base

#renovate-validate: @ Validate renovate.json against the Renovate schema
renovate-validate:
	@npx --yes --package renovate -- renovate-config-validator

# --- Multi-arch (arm64): PREPARED but DISABLED — builds are amd64-only for now ---
# The images are arm64-ready: no arch-specific assets remain (gcloud removed,
# every mise tool has verified arm64 builds, rar→unrar), and a linux/arm64 base
# build has been confirmed to succeed. To enable arm64 later, build with buildx
# and push a manifest list (multi-arch images cannot be `docker load`ed locally):
#
#   docker buildx build --platform linux/amd64,linux/arm64 \
#     --build-arg UBUNTU_VERSION=$(UBUNTU_VERSION) --build-arg IMAGE_LABEL=$(IMAGE) \
#     --push -t $(IMAGE_NAME) ./base
#
# CI would also need: a QEMU setup or native arm64 runners, and multi-arch-aware
# cosign signing + SBOM (sign/scan the index digest). Until then: amd64 only.
# PLATFORMS ?= linux/amd64
# ---------------------------------------------------------------------------------

#build-base-inline-cache: @ Build remote cache for the base image
build-base-inline-cache: check-env
	@docker build --build-arg BUILDKIT_INLINE_CACHE=1 --build-arg IMAGE_LABEL=$(IMAGE) --build-arg UBUNTU_VERSION=$(UBUNTU_VERSION) --build-arg USER_UID=$(USER_UID) --build-arg USER_GID=$(USER_GID) --build-arg USER_NAME=$(USER_NAME) --build-arg USER_PWD=$(USER_PWD) --build-arg ROOT_PWD=$(ROOT_PWD) -t $(IMAGE_INLINE_CACHE_NAME) ./base
	@docker push $(IMAGE_INLINE_CACHE_NAME)

#build-base: @ Build base image
build-base: check-env
	@docker build --build-arg IMAGE_LABEL=$(IMAGE) --build-arg UBUNTU_VERSION=$(UBUNTU_VERSION) --build-arg USER_UID=$(USER_UID) --build-arg USER_GID=$(USER_GID) --build-arg USER_NAME=$(USER_NAME) --build-arg USER_PWD=$(USER_PWD) --build-arg ROOT_PWD=$(ROOT_PWD) -t $(IMAGE_NAME) ./base

#run-base: @ Run base image
run-base: check-env
	@docker run -it --rm $(IMAGE_NAME) bash

#push-base: @ Push base image to a registry
push-base: login build-base
	@docker push $(IMAGE_NAME)

IMAGE_CMD := docker images --filter=reference=$(IMAGE_NAME) --format "{{.ID}}" | awk '{print $$1}'
IMAGE_ID  := $(shell $(IMAGE_CMD))
IMAGE_CNT := $(shell $(IMAGE_CMD) | wc -l)

IMAGE_CACHE_CMD := docker images --filter=reference=$(IMAGE_INLINE_CACHE_NAME) --format "{{.ID}}" | awk '{print $$1}'
IMAGE_CACHE_ID  := $(shell $(IMAGE_CACHE_CMD))
IMAGE_CACHE_CNT := $(shell $(IMAGE_CACHE_CMD) | wc -l)

IMAGE_LAYER_CMD := docker images -q --filter label=$(IMAGE)
IMAGE_LAYER_CNT := $(shell $(IMAGE_LAYER_CMD) | wc -l)

#delete-base: @ Delete base image locally
delete-base: check-env

ifeq ($(shell test $(IMAGE_CNT) -gt 0; echo $$?),0)
# remove image
	docker rmi -f $(IMAGE_ID)
endif

ifeq ($(shell test $(IMAGE_LAYER_CNT) -gt 0; echo $$?),0)
# remove image layers
	@docker rmi -f $$($(IMAGE_LAYER_CMD))
endif

ifeq ($(shell test $(IMAGE_CACHE_CNT) -gt 0; echo $$?),0)
# remove image inline cache
	docker rmi -f $(IMAGE_CACHE_ID)
endif


#build-java-inline-cache: @ Build remote cache for the java dev image
build-java-inline-cache: check-env build-base
	@docker build --build-arg BUILDKIT_INLINE_CACHE=1 --build-arg IMAGE_LABEL=$(IMAGE_JAVA) --build-arg UBUNTU_VERSION=$(UBUNTU_VERSION) -t $(IMAGE_JAVA_INLINE_CACHE_NAME) ./java
	@docker push $(IMAGE_JAVA_INLINE_CACHE_NAME)

#build-java: @ Build java dev image
build-java: check-env build-base
	@docker build --build-arg IMAGE_LABEL=$(IMAGE_JAVA) --build-arg UBUNTU_VERSION=$(UBUNTU_VERSION) -t $(IMAGE_JAVA_NAME) ./java

#run-java: @ Run java dev image
run-java: check-env
	@docker run -it --rm $(IMAGE_JAVA_NAME) bash

#push-java: @ Push java dev image to a registry
push-java: login build-java
	@docker push $(IMAGE_JAVA_NAME)

IMAGE_JAVA_CMD := docker images --filter=reference=$(IMAGE_JAVA_NAME) --format "{{.ID}}" | awk '{print $$1}'
IMAGE_JAVA_ID  := $(shell $(IMAGE_JAVA_CMD))
IMAGE_JAVA_CNT := $(shell $(IMAGE_JAVA_CMD) | wc -l)

IMAGE_JAVA_CACHE_CMD := docker images --filter=reference=$(IMAGE_JAVA_INLINE_CACHE_NAME) --format "{{.ID}}" | awk '{print $$1}'
IMAGE_JAVA_CACHE_ID  := $(shell $(IMAGE_JAVA_CACHE_CMD))
IMAGE_JAVA_CACHE_CNT := $(shell $(IMAGE_JAVA_CACHE_CMD) | wc -l)

IMAGE_JAVA_LAYER_CMD := docker images -q --filter label=$(IMAGE_JAVA)
IMAGE_JAVA_LAYER_CNT := $(shell $(IMAGE_JAVA_LAYER_CMD) | wc -l)

#delete-java: @ Delete java dev image locally
delete-java: check-env

ifeq ($(shell test $(IMAGE_JAVA_CNT) -gt 0; echo $$?),0)
# remove image
	docker rmi -f $(IMAGE_JAVA_ID)
endif

ifeq ($(shell test $(IMAGE_JAVA_LAYER_CNT) -gt 0; echo $$?),0)
# remove image layers
	@docker rmi -f $$($(IMAGE_JAVA_LAYER_CMD))
endif

ifeq ($(shell test $(IMAGE_JAVA_CACHE_CNT) -gt 0; echo $$?),0)
# remove image inline cache
	docker rmi -f $(IMAGE_JAVA_CACHE_ID)
endif

CNT_TAG_CMD     := docker images | grep '<none>' | awk '{print $$3}'
CNT_TAG         := $(shell $(CNT_TAG_CMD) | wc -l)

CNT_EXITED_CMD  := docker ps -qa --no-trunc --filter 'status=exited'
CNT_EXITED      := $(shell $(CNT_EXITED_CMD) | wc -l)

CNT_NETWORK_CMD := docker network ls | awk '$$3 == "bridge" && $$2 != "bridge" { print $$1 }'
CNT_NETWORK     := $(shell $(CNT_NETWORK_CMD) | wc -l)

CNT_DANGLING_CMD := docker volume ls -qf dangling=true
CNT_DANGLING     := $(shell $(CNT_DANGLING_CMD) | wc -l)


#build-go: @ Build go dev image (no secrets — image is credential-free)
build-go: check-env build-base
	@docker build --build-arg IMAGE_LABEL=$(IMAGE_GO) --build-arg USER_EMAIL="$(USER_EMAIL)" --build-arg UBUNTU_VERSION=$(UBUNTU_VERSION) -t $(IMAGE_GO_NAME) ./go

#run-go: @ Run go dev image (DooD socket + runtime-injected SSH/GPG/PAT creds)
run-go: check-env
	@docker run --group-add "$$(stat -c '%g' /var/run/docker.sock)" -v /var/run/docker.sock:/var/run/docker.sock -v "$$(pwd)":/home/user/host_launchdir $(GO_RUN_CREDS) --name docker-ubuntu-go -it --rm $(IMAGE_GO_NAME) bash

#push-go: @ Push go dev image (BLOCKED by default — local-only by policy; set ALLOW_GO_PUSH=1)
push-go: login build-go
	@[ "$$ALLOW_GO_PUSH" = "1" ] || { \
		echo "ERROR: the go image is local-only by project policy — a personal dev"; \
		echo "       container layered on the published base+java, not part of the"; \
		echo "       published set. (It no longer bakes operator credentials; SSH/GPG/PAT"; \
		echo "       are injected at runtime by 'make run-go'.) To override: make push-go ALLOW_GO_PUSH=1"; \
		exit 1; }
	@docker push $(IMAGE_GO_NAME)

IMAGE_GO_CMD := docker images --filter=reference=$(IMAGE_GO_NAME) --format "{{.ID}}" | awk '{print $$1}'
IMAGE_GO_ID  := $(shell $(IMAGE_GO_CMD))
IMAGE_GO_CNT := $(shell $(IMAGE_GO_CMD) | wc -l)

IMAGE_GO_LAYER_CMD := docker images -q --filter label=$(IMAGE_GO)
IMAGE_GO_LAYER_CNT := $(shell $(IMAGE_GO_LAYER_CMD) | wc -l)

#delete-go: @ Delete go dev image locally
delete-go: check-env

ifeq ($(shell test $(IMAGE_GO_CNT) -gt 0; echo $$?),0)
# remove image
	docker rmi -f $(IMAGE_GO_ID)
endif

ifeq ($(shell test $(IMAGE_GO_LAYER_CNT) -gt 0; echo $$?),0)
# remove image layers
	@docker rmi -f $$($(IMAGE_GO_LAYER_CMD))
endif

#build-all: @ Build base + go + java images
build-all: check-env build-base build-go build-java

#build-push-all: @ Build and push the publishable images (base + java; go is local-only)
build-push-all: check-env build-base-inline-cache build-base push-base build-java-inline-cache build-java push-java

#cleanup: @ Cleanup docker images, containers, volumes, networks, build cache
cleanup: delete-go delete-java delete-base

ifeq ($(shell test $(CNT_TAG) -gt 0; echo $$?),0)
# remove tagged <none>
	@docker rmi -f $$($(CNT_TAG_CMD))
endif

ifeq ($(shell test $(CNT_EXITED) -gt 0; echo $$?),0)
# remove docker containers exited
	@docker rm $$($(CNT_EXITED_CMD))
endif

ifeq ($(shell test $(CNT_NETWORK) -gt 0; echo $$?),0)
# remove networks
	@docker network rm -q $$($(CNT_NETWORK_CMD))
endif

ifeq ($(shell test $(CNT_DANGLING) -gt 0; echo $$?),0)
# remove volumes
	@docker volume rm $$($(CNT_DANGLING_CMD))
endif

	@docker builder prune -af

.PHONY: help check-env login lint lint-scripts-exec ci renovate-validate \
	build-base-inline-cache build-base run-base push-base delete-base \
	build-java-inline-cache build-java run-java push-java delete-java \
	build-go run-go push-go delete-go \
	build-all build-push-all cleanup
