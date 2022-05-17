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

USER $USER_UID:$USER_GID
SHELL ["/bin/bash", "-c"]

# RUN echo "${SSH_PRIVATE_KEY}" > /home/$USER_NAME/.ssh/id_rsa \
#     && echo "${SSH_PUBLIC_KEY}" > /home/$USER_NAME/.ssh/id_rsa.pub \
#     && eval "$(ssh-agent)" \
#     && ssh-agent -s \
#     && ssh-add /home/$USER_NAME/.ssh/id_rsa

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

COPY ./scripts/ /home/$USER_NAME/scripts
RUN ls -al /home/$USER_NAME/ && /home/$USER_NAME/scripts/install-all.sh

# Google Cloud SDL CLI - https://github.com/GoogleCloudPlatform/cloud-sdk-docker
RUN curl https://sdk.cloud.google.com | bash

# Cloud SQL Proxy - https://www.how2shout.com/linux/install-google-cloud-sql-proxy-on-ubuntu-22-04-20-04/
ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache5
RUN wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy && chmod +x cloud_sql_proxy && sudo mv cloud_sql_proxy /usr/local/bin/

ENV GRADLE_HOME=/home/$USER_NAME/.sdkman/candidates/gradle/current
ENV MAVEN_HOME="/home/$USER_NAME/.sdkman/candidates/maven/current" 
ENV JAVA_HOME="/home/$USER_NAME/.sdkman/candidates/java/current" 
ENV PATH="$GRADLE_HOME/bin:$MAVEN_HOME/bin:$JAVA_HOME/bin:$PATH"

WORKDIR /home/$USER_NAME

CMD ["/bin/bash"]
ENTRYPOINT bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && source $HOME/scripts/entry.sh && $0 $@"
