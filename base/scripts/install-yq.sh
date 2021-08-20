#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

# https://github.com/mikefarah/yq

sudo -v

USER=mikefarah
PROJECT=yq
OS=linux
ARCH=amd64
EXT=

sudo -v

cd ${TMP_DIR}

LATEST_VERSION=$(curl --silent "https://api.github.com/repos/${USER}/${PROJECT}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
VERSION=$(echo -n $LATEST_VERSION | sed 's/^.//')
echo "Downloading ${PROJECT} ${LATEST_VERSION} ..."

sudo curl -sLo /usr/local/bin/yq https://github.com/${USER}/${PROJECT}/releases/download/${LATEST_VERSION}/${PROJECT}_${OS}_${ARCH} 
# sudo curl -L https://github.com/mikefarah/yq/releases/download/v4.5.1/yq_linux_amd64 -o /usr/local/bin/yq
sudo chmod +x /usr/local/bin/yq

yq --version

cd $LAUNCH_DIR