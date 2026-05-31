# https://hub.docker.com/_/ubuntu/

# renovate: datasource=docker depName=ubuntu versioning=ubuntu
ARG UBUNTU_VERSION="24.04"

FROM ubuntu:$UBUNTU_VERSION

ARG ROOT_PWD="Docker!"
ARG USER_UID="1000"
ARG USER_GID="1000"
ARG USER_NAME="user"
ARG USER_PWD="user"
ARG USER_EMAIL="user@test.com"
ARG IMAGE_LABEL="docker-ubuntu-base"

# mise (https://mise.jdx.dev) — the single tool-version manager for the whole
# image hierarchy. Pinned; Renovate tracks the GitHub release.
# renovate: datasource=github-releases depName=jdx/mise
ARG MISE_VERSION="v2026.5.16"

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

LABEL stage=$IMAGE_LABEL

# Ubuntu 24.04 ships a stock `ubuntu` user at UID/GID 1000 — remove it before
# creating ours so the requested UID/GID is free.
RUN (userdel -r ubuntu 2>/dev/null || true) \
    && (groupdel ubuntu 2>/dev/null || true) \
    && groupadd -g $USER_GID $USER_NAME \
    && useradd -m -g $USER_GID -u $USER_UID --shell /bin/bash $USER_NAME

RUN apt-get update && apt-get install -y apt-transport-https

RUN apt-get install -y ca-certificates apt-utils software-properties-common curl wget lsb-release sudo locales xclip xsel bash-completion \
    vim nano zip unzip rar openssl ssh openssh-client tree git gitg git-lfs graphviz \
    gnupg gnupg2 net-tools jq httpie htop nmon iputils-ping html-xml-utils libxml2-utils xmlstarlet libnss3-tools slirp4netns \
    xdotool buildah podman skopeo postgresql-client make gcc python3-dev python3-pip python3-crcmod \
    && apt-get autoremove -y \
    && apt-get autoclean \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/cache/apt \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Docker-in-Docker via the official convenience script.
# https://devopscube.com/run-docker-in-docker/
RUN curl -fsSL https://get.docker.com/ | sudo sh && sudo usermod -aG docker $USER_NAME

RUN echo "$USER_NAME:$USER_PWD" | chpasswd && usermod -aG sudo $USER_NAME && mkdir -p /home/$USER_NAME/.ssh/ && sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers

COPY ./scripts/ /home/$USER_NAME/scripts

RUN ssh-keygen -t rsa -b 4096 -N '' -C $USER_EMAIL -f /home/$USER_NAME/.ssh/id_rsa

RUN echo 'root:${ROOT_PWD}' | chpasswd

RUN chown -R $USER_UID:$USER_GID /home/$USER_NAME/

# Use the user NAME (not numeric uid:gid) so Docker loads the supplementary
# groups (sudo, docker) — required for passwordless sudo in downstream builds.
USER $USER_NAME
WORKDIR /home/$USER_NAME
SHELL ["/bin/bash", "-c"]

# --- Tool management via mise -------------------------------------------------
# Tools are installed for the non-root user; the layer persists into the java/go
# images (which add their own ~/.mise.toml on top of this global config).
ENV MISE_DATA_DIR="/home/$USER_NAME/.local/share/mise"
ENV PATH="/home/$USER_NAME/.local/bin:/home/$USER_NAME/.local/share/mise/shims:$PATH"
RUN curl -fsSL https://mise.run | MISE_VERSION=$MISE_VERSION sh
COPY --chown=$USER_UID:$USER_GID .mise.toml /home/$USER_NAME/.config/mise/config.toml
RUN mise trust /home/$USER_NAME/.config/mise/config.toml \
    && mise install --yes \
    && mise reshim \
    && echo 'eval "$(mise activate bash)"' >> /home/$USER_NAME/.bashrc
# -----------------------------------------------------------------------------

CMD ["/bin/bash"]
ENTRYPOINT bash -c "source $HOME/scripts/entry.sh && $0 $@"
