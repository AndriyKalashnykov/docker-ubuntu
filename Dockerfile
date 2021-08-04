# https://hub.docker.com/_/ubuntu/

ARG UBUNTU_VERSION="21.10"

FROM ubuntu:$UBUNTU_VERSION

# Defining default non-root user UID, GID, and name
ARG USER_UID="1000"
ARG USER_GID="1000"
ARG USER_NAME="user"
ARG USER_PWD="user"

# Creating default non-user
RUN groupadd -g $USER_GID $USER_NAME && \
    useradd -m -g $USER_GID -u $USER_UID $USER_NAME

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y sudo zip unzip curl tree git git-core openssh-client gnupg locales wget nano && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    mkdir -m 700 -p /home/$USER_NAME/.ssh/
    # adduser --quiet --disabled-password --shell /bin/bash --home /home/$USER_NAME --gecos "User" $USER_NAME && \
    # echo "$USER_NAME:root" | chpasswd &&  usermod -aG sudo $USER_NAME

RUN ssh-keygen -q -t rsa -b 4096 -C "AndriyKalashnykov@gmail.com" -P $USER_PWD -f /home/$USER_NAME/.ssh/id_rsa && \
    ssh-keygen -q -p -P $USER_PWD -N "" -f /home/$USER_NAME/.ssh/id_rsa && \
    chown --recursive $USER_UID:$USER_GID /home/$USER_NAME/.ssh && \
    chmod 600 /home/$USER_NAME/.ssh/id_rsa && \
    chmod 600 /home/$USER_NAME/.ssh/id_rsa.pub && \
    touch -m 600 /home/$USER_NAME/.ssh/known_hosts && \
    ssh-keyscan -T 60 github.com >/home/$USER_NAME/.ssh/known_hosts && \
    chown --recursive $USER_UID:$USER_GID /home/$USER_NAME/.ssh && \
    # chmod 644 /home/$USER_NAME/.ssh/authorized_keys && \
    # chmod 600 /home/$USER_NAME/.ssh/config && \
    eval "$(ssh-agent)" && ssh-agent -s && \
    ssh-add /home/$USER_NAME/.ssh/id_rsa

# Switching to non-root user to install SDKMAN!
USER $USER_UID:$USER_GID

# # Downloading SDKMAN!
# RUN curl -s "https://get.sdkman.io" | bash

# # Installing Java and Maven, removing some unnecessary SDKMAN files
# RUN bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && \
#     yes | sdk install java $JAVA_VERSION && \
#     yes | sdk install maven $MAVEN_VERSION && \
#     rm -rf $HOME/.sdkman/archives/* && \
#     rm -rf $HOME/.sdkman/tmp/*"

ENV MAVEN_HOME="/home/$USER_NAME/.sdkman/candidates/maven/current" 
ENV JAVA_HOME="/home/$USER_NAME/.sdkman/candidates/java/current" 
ENV PATH="$MAVEN_HOME/bin:$JAVA_HOME/bin:$PATH"

WORKDIR /home/$USER_NAME

RUN git clone https://github.com/AndriyKalashnykov/sdkman-java-maven-builder.git

# ENTRYPOINT bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && $0 $@" 
# ENTRYPOINT ["/bin/bash"]
# ENTRYPOINT ["tail", "-f", "/dev/null"]