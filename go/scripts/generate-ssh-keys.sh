#!/bin/bash
#
# Install SSH keys into the user's ~/.ssh. Keys are provided as BuildKit secret
# mounts (raw files at /run/secrets/ssh_priv and /run/secrets/ssh_pub); if absent,
# a fresh key pair is generated. No key material is ever passed as a build arg.

USER_NAME=${1:-user}
USER_EMAIL=${2:-user@test.com}

mkdir -p "/home/${USER_NAME}/.ssh"

if [ -s /run/secrets/ssh_priv ] && [ -s /run/secrets/ssh_pub ]; then
    echo "Using provided SSH keys..."
    cp /run/secrets/ssh_priv "/home/${USER_NAME}/.ssh/id_rsa"
    cp /run/secrets/ssh_pub  "/home/${USER_NAME}/.ssh/id_rsa.pub"
else
    echo "Generating SSH keys..."
    ssh-keygen -q -t rsa -b 4096 -N '' -C "$USER_EMAIL" -f "/home/${USER_NAME}/.ssh/id_rsa"
fi

chmod 700 "/home/${USER_NAME}/.ssh"
chmod 600 "/home/${USER_NAME}/.ssh/id_rsa"
chmod 644 "/home/${USER_NAME}/.ssh/id_rsa.pub"
