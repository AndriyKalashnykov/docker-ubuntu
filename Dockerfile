# https://hub.docker.com/_/ubuntu/

ARG UBUNTU_VERSION="21.04"

FROM andriykalashnykov/docker-ubuntu-base:$UBUNTU_VERSION
# FROM debian:stretch-slim

ARG USER_UID="1000"
ARG USER_GID="1000"
ARG USER_NAME="user"
ARG USER_PWD="user"
ARG USER_EMAIL="user@test.com"
ARG IMAGE_LABEL="docker-ubuntu-dev"
ARG SSH_PUBLIC_KEY
ARG SSH_PRIVATE_KEY

LABEL stage=$IMAGE_LABEL

# RUN echo "${SSH_PRIVATE_KEY}" > /home/$USER_NAME/.ssh/id_rsa \
#     && echo "${SSH_PUBLIC_KEY}" > /home/$USER_NAME/.ssh/id_rsa.pub \
#     && eval "$(ssh-agent)" \
#     && ssh-agent -s \
#     && ssh-add /home/$USER_NAME/.ssh/id_rsa


# Switching to non-root user to install SDKMAN!
USER $USER_UID:$USER_GID
SHELL ["/bin/bash", "-c"]

# RUN apt-get -y update
# RUN apt-get install -y --no-install-recommends apt-utils ca-certificates openssl curl zip unzip tree apt-transport-https iputils-ping 

# fskips caching
ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache
# Downloading SDKMAN!
RUN curl -vsSL "https://get.sdkman.io" | bash
# Installing Java and Maven, removing some unnecessary SDKMAN files
RUN bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && \
    yes | sdk install java $JAVA_VERSION && \
    yes | sdk install maven $MAVEN_VERSION && \
    yes | sdk install gradle && \
    rm -rf $HOME/.sdkman/archives/* && \
    rm -rf $HOME/.sdkman/tmp/*"

ENV GRADLE_HOME=/home/$USER_NAME/.sdkman/candidates/gradle/current
ENV MAVEN_HOME="/home/$USER_NAME/.sdkman/candidates/maven/current" 
ENV JAVA_HOME="/home/$USER_NAME/.sdkman/candidates/java/current" 
ENV PATH="$GRADLE_HOME/bin:$MAVEN_HOME/bin:$JAVA_HOME/bin:$PATH"

WORKDIR /home/$USER_NAME

CMD ["/bin/bash"]
ENTRYPOINT bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && $0 $@"
