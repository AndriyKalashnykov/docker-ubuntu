#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

sudo -v
cd ${TMP_DIR}

USER=kubernetes-sigs
PROJECT=kustomize

LATEST_VERSION=$(curl -s "https://api.github.com/repos/${USER}/${PROJECT}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
# VERSION=$(echo -n $LATEST_VERSION | sed 's/^.//')
echo "Downloading ${LATEST_VERSION} ..."

[ -e ${TMP_DIR}/${PROJECT} ] && sudo rm ${TMP_DIR}/${PROJECT}

curl -sL "https://raw.githubusercontent.com/${USER}/${PROJECT}/master/hack/install_kustomize.sh" | bash
sudo install ${TMP_DIR}/${PROJECT} /usr/local/bin/${PROJECT}

${PROJECT} version

cd $LAUNCH_DIR