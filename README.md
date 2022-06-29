[![main](https://github.com/AndriyKalashnykov/docker-ubuntu/actions/workflows/main.yml/badge.svg)](https://github.com/AndriyKalashnykov/docker-ubuntu/actions/workflows/main.yml)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2FAndriyKalashnykov%2Fdocker-ubuntu&count_bg=%2333CD56&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
# Ubuntu Development environment (Java and Go Docker images)

## Help

![make-help](./images/carbon.png)


## Pre-Requisites

* [Docker](https://docs.docker.com/get-docker/)

* Set DockerHub login and password
  
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
