# docker-ubuntu
Docker based Ubuntu dev environment

## Run help

```markdown
make help

Usage: make COMMAND

Commands :

help                    - List available tasks on this project
check-env               - Check environment variables and installed tools
login                   - Login to a registry
build-base-inline-cache - Build remote cache for the base image
build-base              - Build base image
run-base                - Run base image
push-base               - Push base image to a registry
delete-base             - Delete base image locally
build-java-inline-cache - Build remote cache for the java dev image
build-java              - Build java dev image
run-java                - Run java dev image
push-java               - Push java dev image to a registry
delete-java             - Delete java dev image locally
build-all               - Build all and images
build-push-all          - Build and push all cache and images
cleanup                 - Cleanup docker images, containers, volumes, networks, build cache

```