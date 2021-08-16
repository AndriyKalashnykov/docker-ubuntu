.DEFAULT_GOAL := help

SHELL := /bin/bash
SDKMAN := $(HOME)/.sdkman/bin/sdkman-init.sh
CURRENT_USER_NAME := $(shell whoami)

UBUNTU_VERSION := 21.10
JAVA_VERSION := 11.0.11.hs-adpt
MAVEN_VERSION := 3.8.1
USER_UID := 1000
USER_GID := 1000
USER_NAME := user

IMAGE := docker-ubuntu-base
IMAGE_NAME := $$DOCKER_LOGIN/${IMAGE}:${UBUNTU_VERSION}
IMAGE_INLINE_CACHE_NAME	:= $$DOCKER_LOGIN/${IMAGE}-cache:${UBUNTU_VERSION}

IMAGE_JAVA := docker-ubuntu-java
IMAGE_JAVA_NAME := $$DOCKER_LOGIN/${IMAGE_JAVA}:${UBUNTU_VERSION}
IMAGE_JAVA_INLINE_CACHE_NAME := $$DOCKER_LOGIN/${IMAGE_JAVA}-cache:${UBUNTU_VERSION}

DOCKER_REGISTRY := docker.io
export DOCKER_SCAN_SUGGEST=false

# make sure docker is installed
DOCKER_EXISTS	:= @printf "docker"
DOCKER_WHICH	:= $(shell which docker)
ifeq ($(strip $(DOCKER_WHICH)),)
	DOCKER_EXISTS := @echo "ERROR: docker not found. See: https://docs.docker.com/get-docker/" && exit 1
endif

DOCKER_LOGIN_EXISTS := @printf "DOCKER_LOGIN"
ifndef DOCKER_LOGIN
#	$(error DOCKER_PWD is undefined)
	DOCKER_LOGIN_EXISTS := @echo "DOCKER_LOGIN is undefined" && exit 1
endif

DOCKER_PWD_EXISTS := @printf "DOCKER_PWD"
ifndef DOCKER_PWD
#	$(error DOCKER_PWD is undefined)
	DOCKER_PWD_EXISTS := @echo "DOCKER_PWD is undefined" && exit 1
endif

#help: @ List available tasks on this project
help:
	@clear
	@echo "Usage: make COMMAND"
	@echo
	@echo "Commands :"
	@echo
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#' | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[32m%-23s\033[0m - %s\n", $$1, $$2}'

#check-env: @ Check environment variables and installed tools
check-env:

	@printf "\xE2\x9C\x94 "
	$(DOCKER_EXISTS)
	@printf " "
	$(DOCKER_LOGIN_EXISTS)
	@printf " "
	$(DOCKER_PWD_EXISTS)
	@echo ""	
#	$(debug   DOCKER_EXISTS is $(DOCKER_EXISTS))

#login: @ Login to a registry
login: check-env
	@docker login --username $$DOCKER_LOGIN --password $$DOCKER_PWD $$DOCKER_REGISTRY

SSH_PRIVATE_KEY := $(shell cat ~/.ssh/id_rsa)
SSH_PUBLIC_KEY	:= $(shell cat ~/.ssh/id_rsa.pub)

#build-base-inline-cache: @ Build remote cache for the base image
build-base-inline-cache: check-env
	@DOCKER_BUILDKIT=1 docker build --build-arg BUILDKIT_INLINE_CACHE=1 --build-arg IMAGE_LABEL=${IMAGE} --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} --build-arg USER_UID=${USER_UID} --build-arg USER_GID=${USER_GID} --build-arg USER_NAME=${USER_NAME} -t $(IMAGE_INLINE_CACHE_NAME) ./base
	@DOCKER_BUILDKIT=1 docker push $(IMAGE_INLINE_CACHE_NAME)

#build-base: @ Build base image
build-base: check-env
	@DOCKER_BUILDKIT=1 docker build --build-arg IMAGE_LABEL=${IMAGE} --build-arg SSH_PUBLIC_KEY="$(SSH_PUBLIC_KEY)" --build-arg SSH_PRIVATE_KEY="$(SSH_PRIVATE_KEY)" --cache-from $(IMAGE_INLINE_CACHE_NAME) --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} --build-arg USER_UID=${USER_UID} --build-arg USER_GID=${USER_GID} --build-arg USER_NAME=${USER_NAME} -t $(IMAGE_NAME) ./base

#run-base: @ Run base image
run-base: check-env build-base
	@docker run -it --rm -u $$UID $(IMAGE_NAME) bash

#push-base: @ Push base image to a registry
push-base: login build-base
	@docker push $(IMAGE_NAME)

IMAGE_CMD := docker images --filter=reference=$(IMAGE_NAME) --format "{{.ID	}}" | awk '{print $$1}'
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
	@docker rmi -f $(IMAGE_LAYER_CMD) 
endif

ifeq ($(shell test $(IMAGE_CACHE_CNT) -gt 0; echo $$?),0)
# remove image inline cache
	docker rmi -f $(IMAGE_CACHE_ID) 
endif


#build-java-inline-cache: @ Build remote cache for the java dev image
build-java-inline-cache: check-env build-base
	@DOCKER_BUILDKIT=1 docker build --build-arg BUILDKIT_INLINE_CACHE=1 --build-arg IMAGE_LABEL=${IMAGE_JAVA} --build-arg SSH_PUBLIC_KEY="$(SSH_PUBLIC_KEY)" --build-arg SSH_PRIVATE_KEY="$(SSH_PRIVATE_KEY)" --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} --build-arg JAVA_VERSION=${JAVA_VERSION} --build-arg MAVEN_VERSION=${MAVEN_VERSION} -t $(IMAGE_JAVA_INLINE_CACHE_NAME) .
	@DOCKER_BUILDKIT=1 docker push $(IMAGE_JAVA_INLINE_CACHE_NAME)

#build-java: @ Build java dev image
build-java: check-env build-base
	@DOCKER_BUILDKIT=1 docker build --build-arg IMAGE_LABEL=${IMAGE_JAVA} --build-arg SSH_PUBLIC_KEY="$(SSH_PUBLIC_KEY)" --build-arg SSH_PRIVATE_KEY="$(SSH_PRIVATE_KEY)" --cache-from $(IMAGE_JAVA_INLINE_CACHE_NAME) --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} --build-arg JAVA_VERSION=${JAVA_VERSION} --build-arg MAVEN_VERSION=${MAVEN_VERSION} -t $(IMAGE_JAVA_NAME) .

#run-java: @ Run java dev image
run-java: check-env build-java
	@docker run -it --rm -u $$UID $(IMAGE_JAVA_NAME) bash

#push-java: @ Push java dev image to a registry
push-java: login build-java
	@docker push $(IMAGE_JAVA_NAME)

IMAGE_JAVA_CMD := docker images --filter=reference=$(IMAGE_JAVA_NAME) --format "{{.ID	}}" | awk '{print $$1}'
IMAGE_JAVA_ID  := $(shell $(IMAGE_JAVA_CMD))
IMAGE_JAVA_CNT := $(shell $(IMAGE_JAVA_CMD) | wc -l)

IMAGE_JAVA_CACHE_CMD := docker images --filter=reference=$(IMAGE_JAVA_INLINE_CACHE_NAME) --format "{{.ID}}" | awk '{print $$1}'
IMAGE_JAVA_CACHE_ID  := $(shell $(IMAGE_JAVA_CACHE_CMD))
IMAGE_JAVA_CACHE_CNT := $(shell $(IMAGE_JAVA_CACHE_CMD) | wc -l)

IMAGE_JAVA_LAYER_CMD := docker images -q --filter label=${IMAGE_JAVA}
IMAGE_JAVA_LAYER_CNT := $(shell $(IMAGE_JAVA_LAYER_CMD) | wc -l)

#delete-java: @ Delete java dev image locally
delete-java: check-env

ifeq ($(shell test $(IMAGE_JAVA_CNT) -gt 0; echo $$?),0)
# remove image
	docker rmi -f $(IMAGE_JAVA_ID) 
endif

ifeq ($(shell test $(IMAGE_JAVA_LAYER_CNT) -gt 0; echo $$?),0)
# remove image layers
	@docker rmi -f $(IMAGE_JAVA_LAYER_CMD) 
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

#build-all: @ Build all and images
build-all: check-env build-base build-java

#build-push-all: @ Build and push all cache and images
build-push-all: check-env build-base-inline-cache build-base push-base build-java-inline-cache build-java push-java

#cleanup: @ Cleanup docker images, containers, volumes, networks, build cache
cleanup: delete-java delete-base

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

img:
	@silicon ./base/Dockerfile -o ./images/ubuntu-base.png --background '#fff0'
	@silicon Dockerfile -o ./images/ubuntu-java.png --background '#fff0'
	@shutter --window=.*Tilix.* -o ./images/terminal.png -e