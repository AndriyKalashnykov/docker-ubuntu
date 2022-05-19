#!/bin/bash

docker run -v /var/run/docker.sock:/var/run/docker.sock -it --rm go-dev bash

# docker run -v /home/$USER/.ssh:/home/user/.ssh -it --rm go-dev bash