# https://hub.docker.com/_/ubuntu/

ARG UBUNTU_VERSION="21.10"

FROM andriykalashnykov/docker-ubuntu-base:$UBUNTU_VERSION

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

# SHELL ["/bin/bash", "-c"]

# Switching to non-root user to install SDKMAN!
USER $USER_UID:$USER_GID

# followint line skips caching of downloaded ldap-server.jar
ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache
# Downloading SDKMAN!
RUN curl -s "https://get.sdkman.io" | bash && tree $HOME/.sdkman && ls -al /home/
# Installing Java and Maven, removing some unnecessary SDKMAN files
# RUN bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && \
#     yes | sdk install java $JAVA_VERSION && \
#     yes | sdk install maven $MAVEN_VERSION && \
#     rm -rf $HOME/.sdkman/archives/* && \
#     rm -rf $HOME/.sdkman/tmp/*"

ENV MAVEN_HOME="/home/$USER_NAME/.sdkman/candidates/maven/current" 
ENV JAVA_HOME="/home/$USER_NAME/.sdkman/candidates/java/current" 
ENV PATH="$MAVEN_HOME/bin:$JAVA_HOME/bin:$PATH"

WORKDIR /home/$USER_NAME

CMD ["/bin/bash"]
# ENTRYPOINT bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && $0 $@"
