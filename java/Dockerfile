# https://hub.docker.com/_/ubuntu/

# renovate: datasource=docker depName=ubuntu versioning=ubuntu
ARG UBUNTU_VERSION="24.04"

FROM ghcr.io/andriykalashnykov/docker-ubuntu-base:$UBUNTU_VERSION

ARG USER_UID="1000"
ARG USER_GID="1000"
ARG USER_NAME="user"
ARG USER_EMAIL="user@test.com"
ARG IMAGE_LABEL="docker-ubuntu-java"

# Google Cloud SDK — official versioned installer (multi-component SDK, not a
# single mise-managed binary). Pinned for reproducibility.
# renovate: datasource=docker depName=google/cloud-sdk
ARG GCLOUD_VERSION="570.0.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm
ENV TZ=America/New_York

LABEL stage=$IMAGE_LABEL

# Named user so Docker loads supplementary groups (sudo, docker).
USER $USER_NAME
SHELL ["/bin/bash", "-c"]
WORKDIR /home/$USER_NAME

# git config + github known_hosts/ssh config. No private key is baked — the
# IdentityFile is generated per-container at runtime (base scripts/entry.sh) or
# mounted by the operator.
RUN git config --global user.name $USER_NAME \
    && git config --global user.email $USER_EMAIL \
    && mkdir -p /home/$USER_NAME/.ssh \
    && ssh-keyscan -H github.com > /home/$USER_NAME/.ssh/known_hosts \
    && printf 'Host github.com\n\tStrictHostKeyChecking no\n\tIdentityFile /home/%s/.ssh/id_rsa\n\tUpdateHostKeys yes\n' "$USER_NAME" >> /home/$USER_NAME/.ssh/config \
    && chmod 700 /home/$USER_NAME/.ssh \
    && chmod 644 /home/$USER_NAME/.ssh/config /home/$USER_NAME/.ssh/known_hosts

# JVM stack (java/maven/gradle) + cloud-sql-proxy via mise — replaces SDKMAN.
# Merges on top of the base image's global mise config (full base toolset inherited).
COPY --chown=$USER_UID:$USER_GID .mise.toml /home/$USER_NAME/.mise.toml
RUN mise trust /home/$USER_NAME/.mise.toml && mise install --yes && mise reshim

# Google Cloud SDK — pinned official installer.
RUN curl -fsSL --retry 3 --retry-delay 5 --retry-all-errors --connect-timeout 30 "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_VERSION}-linux-x86_64.tar.gz" -o /tmp/gcloud.tgz \
    && sudo tar -xzf /tmp/gcloud.tgz -C /opt \
    && sudo /opt/google-cloud-sdk/install.sh --quiet --path-update false \
    && rm -f /tmp/gcloud.tgz
ENV PATH="/opt/google-cloud-sdk/bin:$PATH"

CMD ["/bin/bash"]
ENTRYPOINT bash -c "source $HOME/scripts/entry.sh && $0 $@"
