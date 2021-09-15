# Ubuntu dev environment docker image
[![main](https://github.com/AndriyKalashnykov/docker-ubuntu/actions/workflows/main.yml/badge.svg)](https://github.com/AndriyKalashnykov/docker-ubuntu/actions/workflows/main.yml)
[![Ubuntu Base - Docker Pulls](https://img.shields.io/docker/pulls/andriykalashnykov/docker-ubuntu-base.svg)](https://hub.docker.com/r/andriykalashnykov/docker-ubuntu-base/)
[![Ubuntu JDK - Docker Pulls](https://img.shields.io/docker/pulls/andriykalashnykov/docker-ubuntu-java.svg)](https://hub.docker.com/r/andriykalashnykov/docker-ubuntu-java/)

## Help

![make-help](./images/carbon.png)


## Pre-Requisites

* [Docker](https://docs.docker.com/get-docker/)

* DockerHub login and password
  
    ```bash
    #!/bin/bash
    
    DOCKER_LOGIN= 
    DOCKER_PWD=
## Ubuntu base docker image with additional packages

<!-- ![ubuntu-base](./images/ubuntu-base.png) -->
```bash
make build-base
make run-base
```

## Java dev environment docker image off of Ubuntu base image

<!-- ![ubuntu-java](./images/ubuntu-java.png) -->
```bash
make build-java
make run-java
```