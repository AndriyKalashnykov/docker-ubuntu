# https://hub.docker.com/_/ubuntu/

ARG UBUNTU_VERSION="22.10"

FROM ubuntu:$UBUNTU_VERSION

ARG ROOT_PWD="Docker!"
ARG USER_UID="1000"
ARG USER_GID="1000"
ARG USER_NAME="user"
ARG USER_PWD="user"
ARG USER_EMAIL="user@test.com"
ARG IMAGE_LABEL="docker-ubuntu-base"
ARG SSH_PUBLIC_KEY
ARG SSH_PRIVATE_KEY

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM xterm
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

LABEL stage=$IMAGE_LABEL

RUN groupadd -g $USER_GID $USER_NAME && useradd -m -g $USER_GID -u $USER_UID --shell /bin/bash $USER_NAME

RUN apt-get install -y apt-transport-https \
    && apt-get -y update \
    && apt-get install -y ca-certificates apt-utils software-properties-common curl wget lsb-release lsb-core sudo locales xclip xsel bash-completion \
    vim nano zip unzip rar openssl ssh openssh-client tree git gitg git-core git-lfs graphviz \
    gnupg gnupg2 net-tools jq httpie htop nmon iputils-ping html-xml-utils libxml2-utils xmlstarlet libnss3-tools slirp4netns \
    xdotool buildah podman skopeo postgresql-client make gcc lsb-release python3-dev python3-pip python3-crcmod \
    && apt-get autoremove \
    && apt-get autoclean \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/cache/apt \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# https://devopscube.com/run-docker-in-docker/
RUN curl -sSL https://get.docker.com/ | sudo sh && sudo usermod -aG docker $USER_NAME

RUN echo "$USER_NAME:$USER_PWD" | chpasswd && usermod -aG sudo $USER_NAME && mkdir -p /home/$USER_NAME/.ssh/ && sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers

COPY ./scripts/ /home/$USER_NAME/scripts

RUN ls -al /home/$USER_NAME/ && /home/$USER_NAME/scripts/install-all.sh && rm -rf /home/$USER_NAME/scripts/

RUN ssh-keygen -t rsa -b 4096 -N '' -C $USER_EMAIL -f /home/$USER_NAME/.ssh/id_rsa

RUN sudo chown -R $USER_UID:$USER_GID /home/$USER_NAME/

RUN echo 'root:${ROOT_PWD}' | chpasswd

USER $USER_UID:$USER_GID
WORKDIR /home/$USER_NAME
SHELL ["/bin/bash", "-c"]
CMD ["/bin/bash"]
ENTRYPOINT bash -c "source $HOME/scripts/entry.sh && $0 $@"

