#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

SSH_PUBLIC_KEY=${1:-}
SSH_PRIVATE_KEY=${2:-}
USER_NAME=${3:-user}
USER_EMAIL=${4:-user@test.com}

cd $SCRIPT_DIR

if [ -z "$SSH_PUBLIC_KEY" ]
then
      echo "\$SSH_PUBLIC_KEY is empty"
else
      echo "\$SSH_PUBLIC_KEY is NOT empty"
fi

if [ -z "$SSH_PRIVATE_KEY" ]
then
      echo "\$SSH_PRIVATE_KEY is empty"
else
      echo "\$SSH_PRIVATE_KEY is NOT empty"
fi

# RUN echo "${SSH_PRIVATE_KEY}" > /home/$USER_NAME/.ssh/id_rsa \
#     && echo "${SSH_PUBLIC_KEY}" > /home/$USER_NAME/.ssh/id_rsa.pub

ssh-keygen -q -t rsa -b 4096 -N '' -C $USER_EMAIL -f /home/$USER_NAME/.ssh/id_rsa

cd $LAUNCH_DIR