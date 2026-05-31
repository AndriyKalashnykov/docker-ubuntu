# syntax=docker/dockerfile:1
# https://hub.docker.com/_/ubuntu/

# renovate: datasource=docker depName=ubuntu versioning=ubuntu
ARG UBUNTU_VERSION="26.04"

FROM ghcr.io/andriykalashnykov/docker-ubuntu-base:$UBUNTU_VERSION

ARG USER_UID="1000"
ARG USER_GID="1000"
ARG USER_NAME="user"
ARG USER_PWD="user"
ARG USER_EMAIL="user@test.com"
ARG IMAGE_LABEL="docker-ubuntu-go"

# Google Cloud SDK — official versioned installer (multi-component SDK, not a
# single mise-managed binary). Pinned for reproducibility.
# renovate: datasource=docker depName=google/cloud-sdk
ARG GCLOUD_VERSION="570.0.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm
ENV TZ=America/New_York

LABEL stage=$IMAGE_LABEL

RUN sudo apt-get update && sudo apt-get install -y postgresql postgresql-contrib postgresql-client \
    && sudo apt-get autoremove -y && sudo apt-get autoclean && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/cache/apt

# Named user so Docker loads supplementary groups (sudo, docker).
USER $USER_NAME
WORKDIR /home/$USER_NAME
SHELL ["/bin/bash", "-c"]

COPY ./profile/ /home/$USER_NAME/
COPY ./scripts/ /home/$USER_NAME/scripts
RUN sudo chown -R $USER_UID:$USER_GID /home/$USER_NAME/

# Non-secret git + SSH host config baked at build time. Operator SSH/GPG/PAT
# credentials are NOT baked into the image — scripts/entry.sh sets them up at
# container start from runtime bind-mounts / env (`make run-go`), so the image
# filesystem stays credential-free and is safe to build anywhere.
RUN git lfs install \
    && git config --global user.name "$USER_NAME" \
    && git config --global user.email "$USER_EMAIL" \
    && mkdir -p /home/$USER_NAME/.ssh \
    && ssh-keyscan -H github.com > /home/$USER_NAME/.ssh/known_hosts \
    && printf 'Host github.com\n\tStrictHostKeyChecking no\n\tIdentityFile /home/%s/.ssh/id_ed25519\n\tIdentityFile /home/%s/.ssh/id_rsa\n\tUpdateHostKeys yes\n' "$USER_NAME" "$USER_NAME" >> /home/$USER_NAME/.ssh/config \
    && chmod 700 /home/$USER_NAME/.ssh \
    && chmod 644 /home/$USER_NAME/.ssh/config /home/$USER_NAME/.ssh/known_hosts \
    && echo -e "\nexport TERM=$TERM" >> /home/$USER_NAME/.bashrc

# Go toolchain + Go dev CLIs + kubebuilder + goreleaser + cloud-sql-proxy via mise.
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
