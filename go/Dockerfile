# syntax=docker/dockerfile:1
# https://hub.docker.com/_/ubuntu/

# renovate: datasource=docker depName=ubuntu versioning=ubuntu
ARG UBUNTU_VERSION="24.04"

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

# SSH keys — injected via BuildKit secret mounts when present on the host;
# otherwise a fresh key is generated. Secrets never enter build args / layers.
RUN --mount=type=secret,id=ssh_priv,uid=1000,required=false \
    --mount=type=secret,id=ssh_pub,uid=1000,required=false \
    /home/$USER_NAME/scripts/generate-ssh-keys.sh "$USER_NAME" "$USER_EMAIL"

RUN git lfs install \
    && git config --global user.name $USER_NAME \
    && git config --global user.email $USER_EMAIL \
    && cat /home/$USER_NAME/.ssh/id_rsa.pub >> /home/$USER_NAME/.ssh/authorized_keys \
    && chmod 755 /home/$USER_NAME/.ssh \
    && chmod 600 /home/$USER_NAME/.ssh/authorized_keys /home/$USER_NAME/.ssh/id_rsa \
    && chmod 644 /home/$USER_NAME/.ssh/id_rsa.pub \
    && ssh-keyscan -H github.com > /home/$USER_NAME/.ssh/known_hosts \
    && printf 'Host github.com\n\tStrictHostKeyChecking no\n\tIdentityFile /home/%s/.ssh/id_rsa\n\tUpdateHostKeys yes\n' "$USER_NAME" >> /home/$USER_NAME/.ssh/config \
    && chmod 644 /home/$USER_NAME/.ssh/config /home/$USER_NAME/.ssh/known_hosts \
    && echo -e "\nexport TERM=$TERM" >> /home/$USER_NAME/.bashrc

# GitHub PAT → ~/.netrc (for authenticated git/HTTPS). Mounted as a secret, so the
# token never appears in build args or `docker history`.
RUN --mount=type=secret,id=github_pat,uid=1000,required=false bash -c '\
    if [ -s /run/secrets/github_pat ]; then \
      PAT="$(cat /run/secrets/github_pat)"; \
      printf "machine github.com\nlogin AndriyKalashnykov\npassword %s\n" "$PAT" >> "$HOME/.netrc"; \
      printf "\nexport GITHUB_PAT=%s\n" "$PAT" >> "$HOME/.bashrc"; \
      chmod 600 "$HOME/.netrc"; \
    fi'

# Go toolchain + Go dev CLIs + kubebuilder + goreleaser + cloud-sql-proxy via mise.
# Merges on top of the base image's global mise config (full base toolset inherited).
COPY --chown=$USER_UID:$USER_GID .mise.toml /home/$USER_NAME/.mise.toml
RUN mise trust /home/$USER_NAME/.mise.toml && mise install --yes && mise reshim

# GPG key material — imported via secret mounts when present; skipped otherwise.
RUN --mount=type=secret,id=gpg_secret,uid=1000,required=false \
    --mount=type=secret,id=gpg_ownertrust,uid=1000,required=false \
    --mount=type=secret,id=gpg_pwd,uid=1000,required=false \
    /home/$USER_NAME/scripts/generate-gpg-keys.sh "$USER_NAME"

# Google Cloud SDK — pinned official installer.
RUN curl -fsSL --retry 3 --retry-delay 5 --retry-all-errors --connect-timeout 30 "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_VERSION}-linux-x86_64.tar.gz" -o /tmp/gcloud.tgz \
    && sudo tar -xzf /tmp/gcloud.tgz -C /opt \
    && sudo /opt/google-cloud-sdk/install.sh --quiet --path-update false \
    && rm -f /tmp/gcloud.tgz
ENV PATH="/opt/google-cloud-sdk/bin:$PATH"

CMD ["/bin/bash"]
ENTRYPOINT bash -c "source $HOME/scripts/entry.sh && $0 $@"
