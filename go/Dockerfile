ARG UBUNTU_VERSION="21.10"

FROM andriykalashnykov/docker-ubuntu-base:$UBUNTU_VERSION

ARG GOLANG_VERSION="1.18.2"
ARG USER_UID="1000"
ARG USER_GID="1000"
ARG USER_NAME="user"
ARG USER_PWD="user"
ARG USER_EMAIL="user@test.com"
ARG IMAGE_LABEL="ubuntu-dev-go"
ARG SSH_PUBLIC_KEY
ARG SSH_PRIVATE_KEY
ARG GPG_SECRET
ARG GPG_OWNER_TRUST
ARG GPG_PWD
ARG GITHUB_PAT

ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm
ENV TZ=America/New_York

LABEL stage=$IMAGE_LABEL

# RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# RUN groupadd -g $USER_GID $USER_NAME && useradd -m -g $USER_GID -u $USER_UID --shell /bin/bash $USER_NAME

# RUN apt-get install -y apt-transport-https \
#     && apt-get -y update \
#     && apt-get install -y ca-certificates apt-utils software-properties-common curl wget lsb-release lsb-core sudo locales xclip xsel bash-completion \
#     vim nano zip unzip rar openssl ssh openssh-client tree git gitg git-core git-lfs graphviz \
#     gnupg gnupg2 net-tools jq httpie htop nmon iputils-ping html-xml-utils libxml2-utils xmlstarlet libnss3-tools slirp4netns \
#     xdotool buildah podman skopeo postgresql-client make gcc lsb-release python3-dev python3-pip python3-crcmod \
#     && apt-get autoremove \
#     && apt-get autoclean \
#     && apt-get clean \
#     && rm -rf /var/lib/apt/lists/* \
#     && rm -rf /tmp/* \
#     && rm -rf /var/cache/apt \
#     && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# RUN apt-get -y update && \
#     apt-get -y install golang-${GOLANG_VERSION} && \
#     apt-get clean
# RUN echo 'export PATH="/usr/lib/go-${GOLANG_VERSION} /bin:$PATH"' >> /etc/bash.bashrc

# # https://devopscube.com/run-docker-in-docker/
# RUN curl -sSL https://get.docker.com/ | sh

# RUN echo "$USER_NAME:$USER_PWD" | chpasswd && usermod -aG sudo $USER_NAME && mkdir -p /home/$USER_NAME/.ssh/ && sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers

USER $USER_UID:$USER_GID
WORKDIR /home/$USER_NAME
SHELL ["/bin/bash", "-c"]

COPY ./profile/ /home/$USER_NAME/
COPY ./scripts/ /home/$USER_NAME/scripts

RUN sudo chown -R $USER_UID:$USER_GID /home/$USER_NAME/

ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache0
RUN /home/$USER_NAME/scripts/generate-ssh-keys.sh "${USER_NAME}" "${USER_EMAIL}" "${SSH_PUBLIC_KEY}" "${SSH_PRIVATE_KEY}"

RUN git lfs install \
    && git config --global user.name $USER_NAME \
    && git config --global user.email $USER_EMAIL \
    && cat /home/$USER_NAME/.ssh/id_rsa.pub >> /home/$USER_NAME/.ssh/authorized_keys \
    && chmod 755 /home/$USER_NAME/.ssh \
    && chmod 600 /home/$USER_NAME/.ssh/authorized_keys \
    && chmod 600 /home/$USER_NAME/.ssh/id_rsa \
    && chmod 644 /home/$USER_NAME/.ssh/id_rsa.pub \
    && ssh-keyscan -H github.com > /home/$USER_NAME/.ssh/known_hosts \
    && echo -e "Host github.com\n\tStrictHostKeyChecking no" >> /home/$USER_NAME/.ssh/config \
    && echo -e "\tIdentityFile /home/$USER_NAME/.ssh/id_rsa" >> /home/$USER_NAME/.ssh/config \
    && echo -e "\tUpdateHostKeys yes" >> /home/$USER_NAME/.ssh/config \
    && chmod 644 /home/$USER_NAME/.ssh/config \
    && chmod 644 /home/$USER_NAME/.ssh/known_hosts \
    && chown -R $USER_UID:$USER_GID  /home/$USER_NAME/.ssh/ \
    && eval "$(ssh-agent)" \
    && ssh-agent -s \
    && ssh-add /home/$USER_NAME/.ssh/id_rsa \
    && echo -e "\nexport TERM=$TERM" >> /home/$USER_NAME/.bashrc \
    && echo -e "\nexport GITHUB_PAT=$GITHUB_PAT" >> /home/$USER_NAME/.bashrc \
    && echo -e "machine github.com" >> /home/$USER_NAME/.netrc \
    && echo -e "login AndriyKalashnykov" >> /home/$USER_NAME/.netrc \
    && echo -e "password $GITHUB_PAT" >> /home/$USER_NAME/.netrc

RUN sudo chown -R $USER_UID:$USER_GID /home/$USER_NAME/

ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache1
RUN /home/$USER_NAME/scripts/install-all.sh ${GOLANG_VERSION}

ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache2
RUN /home/$USER_NAME/scripts/generate-gpg-keys.sh $USER_NAME $GPG_SECRET $GPG_OWNER_TRUST $GPG_PWD

CMD ["/bin/bash"]
ENTRYPOINT bash -c "source $HOME/scripts/entry.sh && $0 $@"
