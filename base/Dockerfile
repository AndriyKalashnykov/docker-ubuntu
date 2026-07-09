# https://hub.docker.com/_/ubuntu/

# renovate: datasource=docker depName=ubuntu versioning=ubuntu
ARG UBUNTU_VERSION="26.04"
# Pinned digest of the ubuntu:${UBUNTU_VERSION} multi-arch manifest list — for
# reproducibility/supply-chain. Renovate keeps it current via the renovate.json
# customManager that captures the UBUNTU_VERSION tag + this digest together.
# Kept separate from UBUNTU_VERSION because that var doubles as the published
# image tag (docker-ubuntu-base:<ver>), which cannot carry an @sha256 suffix.
ARG UBUNTU_DIGEST="sha256:b7f48194d4d8b763a478a621cdc81c27be222ba2206ca3ca6bc42b49685f3d9e"

FROM ubuntu:${UBUNTU_VERSION}@${UBUNTU_DIGEST}

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
ARG MISE_VERSION="v2026.7.5"

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

LABEL stage=$IMAGE_LABEL

# Run RUN steps under bash with pipefail so a failure anywhere in a pipe
# (curl … | sh, echo … | chpasswd) fails the build. Persists for all RUNs below.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Ubuntu 24.04+ ships a stock `ubuntu` user at UID/GID 1000 — remove it before
# creating ours so the requested UID/GID is free. `--no-log-init` avoids a huge
# sparse lastlog/faillog file (hadolint DL3046).
RUN (userdel -r ubuntu 2>/dev/null || true) \
    && (groupdel ubuntu 2>/dev/null || true) \
    && groupadd -g $USER_GID $USER_NAME \
    && useradd -m --no-log-init -g $USER_GID -u $USER_UID --shell /bin/bash $USER_NAME

# Single apt layer: update once, install the curated toolset with
# --no-install-recommends (DL3015), then clean the apt lists in the same layer
# (DL3009). Verified the curated packages keep their real binaries under
# --no-install-recommends (e.g. postgresql-client Depends: postgresql-client-18,
# so psql is preserved; it is a Depends, not a Recommends).
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https ca-certificates apt-utils software-properties-common curl wget lsb-release sudo locales xclip xsel bash-completion \
    vim nano zip unzip unrar openssl ssh openssh-client tree git gitg git-lfs graphviz \
    gnupg gnupg2 net-tools jq httpie htop nmon iputils-ping html-xml-utils libxml2-utils xmlstarlet libnss3-tools slirp4netns \
    xdotool buildah podman skopeo postgresql-client make gcc python3-dev python3-pip python3-crcmod \
    && apt-get autoremove -y \
    && apt-get autoclean \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/cache/apt \
    && rm -f /etc/ssh/ssh_host_* \
    && localedef -i en_US -c -f UTF-8 en_US.UTF-8

# Docker-in-Docker via the official convenience script.
# https://devopscube.com/run-docker-in-docker/
RUN curl -fsSL https://get.docker.com/ | sudo sh && sudo usermod -aG docker $USER_NAME

RUN echo "$USER_NAME:$USER_PWD" | chpasswd && usermod -aG sudo $USER_NAME && mkdir -p /home/$USER_NAME/.ssh/ && sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers

COPY ./scripts/ /home/$USER_NAME/scripts

# NOTE: no SSH key is generated at build time — baking a private key into a
# published image ships the same "private" key to everyone who pulls it (and
# Trivy flags it). A per-container key is generated at runtime by scripts/entry.sh
# if none is mounted.

# Double quotes so the ROOT_PWD build-arg actually expands (single quotes set
# root's password to the literal string "${ROOT_PWD}" — SC2016, and a latent bug).
RUN echo "root:${ROOT_PWD}" | chpasswd

RUN chown -R $USER_UID:$USER_GID /home/$USER_NAME/

# Use the user NAME (not numeric uid:gid) so Docker loads the supplementary
# groups (sudo, docker) — required for passwordless sudo in downstream builds.
USER $USER_NAME
WORKDIR /home/$USER_NAME

# --- Tool management via mise -------------------------------------------------
# Tools are installed for the non-root user; the layer persists into the java/go
# images (which add their own ~/.mise.toml on top of this global config).
ENV MISE_DATA_DIR="/home/$USER_NAME/.local/share/mise"
ENV PATH="/home/$USER_NAME/.local/bin:/home/$USER_NAME/.local/share/mise/shims:$PATH"
RUN curl -fsSL https://mise.run | MISE_VERSION=$MISE_VERSION sh
COPY --chown=$USER_UID:$USER_GID .mise.toml /home/$USER_NAME/.config/mise/config.toml
# SC2016: the single quotes are intentional — the literal string
# `eval "$(mise activate bash)"` must be written to .bashrc and evaluated per
# shell at runtime, NOT expanded at build time.
# hadolint ignore=SC2016
RUN mise trust /home/$USER_NAME/.config/mise/config.toml \
    && mise install --yes \
    && mise reshim \
    && echo 'eval "$(mise activate bash)"' >> /home/$USER_NAME/.bashrc
# -----------------------------------------------------------------------------

CMD ["/bin/bash"]
ENTRYPOINT bash -c "source $HOME/scripts/entry.sh && $0 $@"
