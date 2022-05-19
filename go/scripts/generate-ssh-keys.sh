#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

USER_NAME=${1:-user}
USER_EMAIL=${2:-user@test.com}
SSH_PUBLIC_KEY=${3:-}
SSH_PRIVATE_KEY=${4:-}

cd $SCRIPT_DIR

# echo "USER_NAME: $USER_NAME"
# echo "USER_EMAIL: $USER_EMAIL"
# echo "SSH_PUBLIC_KEY: $SSH_PUBLIC_KEY"
# echo "SSH_PRIVATE_KEY: $SSH_PRIVATE_KEY"

# https://www.cyberciti.biz/faq/unix-linux-bash-script-check-if-variable-is-empty/
if [[ -z "${SSH_PUBLIC_KEY}" || -z "${SSH_PRIVATE_KEY}" ]]; then
      echo "Generating SSH keys..."
      ssh-keygen -q -t rsa -b 4096 -N '' -C $USER_EMAIL -f /home/$USER_NAME/.ssh/id_rsa
else
      echo "Using provided SSH keys..."

      mkdir -p /home/$USER_NAME/.ssh
      
      echo "${SSH_PRIVATE_KEY}" | base64 --decode > /home/$USER_NAME/.ssh/id_rsa
      echo "${SSH_PUBLIC_KEY}" | base64 --decode > /home/$USER_NAME/.ssh/id_rsa.pub
fi

# # ssh -vT git@github.com

cd $LAUNCH_DIR