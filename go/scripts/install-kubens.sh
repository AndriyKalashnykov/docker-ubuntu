#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

sudo -v
cd $TMP_DIR

USER=ahmetb
PROJECT=kubens

LATEST_VERSION=$(curl -s "https://api.github.com/repos/${USER}/kubectx/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
# VERSION=$(echo -n $LATEST_VERSION | sed 's/^.//')
echo "Downloading ${PROJECT} ${LATEST_VERSION} ..."

sudo curl -sLo $TMP_DIR/${PROJECT}_${LATEST_VERSION}_Linux_x86_64.tar.gz https://github.com/${USER}/kubectx/releases/download/${LATEST_VERSION}/${PROJECT}_${LATEST_VERSION}_Linux_x86_64.tar.gz
sudo tar xzf $TMP_DIR/${PROJECT}_${LATEST_VERSION}_Linux_x86_64.tar.gz
sudo install $TMP_DIR/${PROJECT} /usr/local/bin/${PROJECT}

cd $LAUNCH_DIR