#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

VERSION_TO_INSTALL=${1:-}
VERSION_INSTALLED=""

USER=kubernetes-sigs
PROJECT=kubebuilder
OS=$(echo $(uname) | awk '{print tolower($0)}')
ARCH=amd64

# ./install-kubebuilder.sh v3.0.0
# curl -sLO https://github.com/kubernetes-sigs/kubebuilder/releases/download/v3.1.0/kubebuilder_linux_amd64
# https://github.com/kubernetes-sigs/kubebuilder/releases/download/v3.1.0/checksums.txt

sudo -v

if [ -z "${VERSION_TO_INSTALL}" ]; then
    VERSION_TO_INSTALL=$(curl -sL https://api.github.com/repos/$USER/$PROJECT/releases/latest  | grep '"tag_name":' | awk -F '"' '{printf("%s",$4)}')
fi

if [ -f "$BIN_DIR/$PROJECT" ]; then
    VERSION_INSTALLED=$($BIN_DIR/$PROJECT version | awk '{where = match($$0, /KubeBuilderVersion:"[0-9]\.[0-9]+\.[0-9]+(-(alpha|beta)\.[0-9+])?"/); if (where != 0) print substr($$0, RSTART+20, RLENGTH)}' | sed s/\",.\*// )
    VERSION_INSTALLED=v${VERSION_INSTALLED}
fi

# echo "VERSION_TO_INSTALL: $VERSION_TO_INSTALL"
# echo "VERSION_INSTALLED: $VERSION_INSTALLED"

if [ "${VERSION_TO_INSTALL}" != "${VERSION_INSTALLED}" ]; then
    if [ -z $VERSION_INSTALLED ]; then
        echo "Installing $PROJECT: $VERSION_TO_INSTALL "
    else 
        echo "Replacing $PROJECT: $VERSION_INSTALLED > $VERSION_TO_INSTALL"
    fi

    cd $TMP_DIR
    curl -sLO "https://github.com/$USER/$PROJECT/releases/download/${VERSION_TO_INSTALL}/${PROJECT}_${OS}_${ARCH}"  
    sudo install $TMP_DIR/${PROJECT}_${OS}_${ARCH} $BIN_DIR/${PROJECT}
  else
    echo "$PROJECT $VERSION_TO_INSTALL already installed"
fi

cd $LAUNCH_DIR