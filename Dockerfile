# https://hub.docker.com/_/ubuntu/

ARG UBUNTU_VERSION="21.10"

FROM andriykalashnykov/docker-ubuntu-base:$UBUNTU_VERSION
# FROM debian:stretch-slim

ARG JAVA_VERSION="18.0.1-tem"
ARG MAVEN_VERSION="3.8.5"
ARG GOLANG_VERSION="1.18.2"

ARG ROOT_PWD="Docker!"
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

# skip caching
ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache
# Downloading SDKMAN!
RUN curl -vsSL "https://get.sdkman.io" | bash
ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache2
# Installing Java and Maven, removing some unnecessary SDKMAN files
RUN bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && \
    yes | sdk install java $JAVA_VERSION && \
    yes | sdk install maven $MAVEN_VERSION && \
    yes | sdk install gradle && \
    rm -rf $HOME/.sdkman/archives/* && \
    rm -rf $HOME/.sdkman/tmp/*"

ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache3
RUN git clone https://github.com/udhos/update-golang ~/projects/update-golang/ 
ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache4
RUN sudo ~/projects/update-golang/update-golang.sh && source /etc/profile.d/golang_path.sh
RUN sudo echo 'source /etc/profile.d/golang_path.sh' | sudo tee -a ~/.bashrc

ENV GRADLE_HOME=/home/$USER_NAME/.sdkman/candidates/gradle/current
ENV MAVEN_HOME="/home/$USER_NAME/.sdkman/candidates/maven/current" 
ENV JAVA_HOME="/home/$USER_NAME/.sdkman/candidates/java/current" 
ENV PATH="$GRADLE_HOME/bin:$MAVEN_HOME/bin:$JAVA_HOME/bin:$PATH"

WORKDIR /home/$USER_NAME

CMD ["/bin/bash"]
ENTRYPOINT bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && source $HOME/scripts/entry.sh && $0 $@"
