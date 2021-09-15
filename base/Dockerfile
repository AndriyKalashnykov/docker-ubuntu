# https://hub.docker.com/_/ubuntu/

ARG UBUNTU_VERSION="21.04"

FROM ubuntu:$UBUNTU_VERSION

ARG USER_UID="1000"
ARG USER_GID="1000"
ARG USER_NAME="user"
ARG USER_PWD="user"
ARG USER_EMAIL="user@test.com"
ARG IMAGE_LABEL="docker-ubuntu-base"
ARG SSH_PUBLIC_KEY
ARG SSH_PRIVATE_KEY

ENV TERM xterm
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

LABEL stage=$IMAGE_LABEL

RUN groupadd -g $USER_GID $USER_NAME && useradd -m -g $USER_GID -u $USER_UID --shell /bin/bash $USER_NAME

RUN apt-get install -y apt-transport-https && apt-get -y update && DEBIAN_FRONTEND=noninteractive apt-get install -y sudo ssh locales lsb-core nano zip unzip rar curl wget tree git gitg git-core \ 
    gnupg gnupg2 net-tools ca-certificates jq httpie htop nmon iputils-ping html-xml-utils libxml2-utils xmlstarlet libnss3-tools slirp4netns \
    xdotool buildah podman skopeo \
    && apt-get autoremove && apt-get autoclean \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN echo "$USER_NAME:$USER_PWD" | chpasswd && usermod -aG sudo $USER_NAME && mkdir -p /home/$USER_NAME/.ssh/

COPY ./scripts/ /home/$USER_NAME/scripts
RUN ls -al /home/$USER_NAME/ && /home/$USER_NAME/scripts/install-all.sh

# RUN echo "${SSH_PRIVATE_KEY}" > /home/$USER_NAME/.ssh/id_rsa \
#     && echo "${SSH_PUBLIC_KEY}" > /home/$USER_NAME/.ssh/id_rsa.pub

RUN ssh-keygen -t rsa -b 4096 -N '' -C $USER_EMAIL -f /home/$USER_NAME/.ssh/id_rsa

RUN git config --global user.name $USER_NAME \
    && git config --global user.email $USER_EMAIL \
    && cat /home/$USER_NAME/.ssh/id_rsa.pub >> /home/$USER_NAME/.ssh/authorized_keys \
    && chmod 755 /home/$USER_NAME/.ssh \
    && chmod 600 /home/$USER_NAME/.ssh/authorized_keys \
    && chmod 600 /home/$USER_NAME/.ssh/id_rsa \
    && chmod 644 /home/$USER_NAME/.ssh/id_rsa.pub \
    && ssh-keyscan -H github.com > /home/$USER_NAME/.ssh/known_hosts \
    && echo "IdentityFile /home/$USER_NAME/.ssh/id_rsa" >> /home/$USER_NAME/.ssh/config \
    && echo "StrictHostKeyChecking no" >> /home/$USER_NAME/.ssh/config \
    && echo "Host github.com\n\tStrictHostKeyChecking no\n" >> /home/$USER_NAME/.ssh/config \
    && chmod 644 /home/$USER_NAME/.ssh/config \
    && chmod 644 /home/$USER_NAME/.ssh/known_hosts \
    && chown -R $USER_UID:$USER_GID  /home/$USER_NAME/.ssh/ \
    && eval "$(ssh-agent)" \
    && ssh-agent -s \
    && ssh-add /home/$USER_NAME/.ssh/id_rsa \
    && echo "\nexport TERM=$TERM" >> /home/$USER_NAME/.bashrc \
    && chown -R $USER_UID:$USER_GID  /home/$USER_NAME/

USER $USER_UID:$USER_GID

WORKDIR /home/$USER_NAME

CMD ["/bin/bash"]
ENTRYPOINT bash -c "source $HOME/scripts/entry.sh && $0 $@"

