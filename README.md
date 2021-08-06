# docker-ubuntu
Docker based Ubuntu dev environment

## Help

```{r, attr.source='.numberLines'}
if (TRUE) {
  x <- 1:10
  x + 1
}
```
```

![make-help](./images/carbon.png)

```console
$ make help

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

## Dockerfile to build a Ubuntu baseimage with additional of extra packages

![ubuntu-base](./images/ubuntu-base.png)

## Java dev image based off of Ubuntu baseimage

![ubuntu-java](./images/ubuntu-java.png)