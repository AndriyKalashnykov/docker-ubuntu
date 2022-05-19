#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

OVERWRITE_INSTALL=${1:-false}
VERSION_TO_INSTALL=${2:-}

if [ -z "$VERSION_TO_INSTALL" ]; then
    INSTALL_LATEST=true
else
    INSTALL_LATEST=false     
fi

VERSION_INSTALLED=""

USER=k8s-staging-kind
PROJECT=kind
OS=$(echo $(uname) | awk '{print tolower($0)}')
ARCH=amd64

# https://storage.googleapis.com/k8s-staging-kind/
# https://github.com/kubernetes-sigs/kind/releases
# install-kind.sh true 0.11.0

sudo -v
cd $TMP_DIR

if [ -z "${VERSION_TO_INSTALL}" ]; then
    sudo curl -sLo $TMP_DIR/${PROJECT}-${OS}-${ARCH} "https://storage.googleapis.com/${USER}/latest/${PROJECT}-${OS}-${ARCH}"
    sudo chmod 755 $TMP_DIR/${PROJECT}-${OS}-${ARCH}
    TMP_STR=$($TMP_DIR/${PROJECT}-${OS}-${ARCH} --version | awk '{print $3}')
    VERSION_TO_INSTALL=${TMP_STR%-*}
fi

if [ -f "$BIN_DIR/$PROJECT" ]; then
    TMP_STR=$(${PROJECT} --version | awk '{print $3}')
    VERSION_INSTALLED=${TMP_STR%-*}
fi

if [ "${VERSION_TO_INSTALL}" != "${VERSION_INSTALLED}" ] || [ "$OVERWRITE_INSTALL" == true ]; then
    if [ -z $VERSION_INSTALLED ]; then
        echo "Installing $PROJECT: $VERSION_TO_INSTALL "
    else 
        echo "Replacing $PROJECT: $VERSION_INSTALLED > $VERSION_TO_INSTALL"
    fi

    if [ "$INSTALL_LATEST" == true ]; then
        # echo "installing latest."
        sudo install $TMP_DIR/${PROJECT}-${OS}-${ARCH} /usr/local/bin/${PROJECT}
    else
        # echo "installing specified."
        sudo curl -sLo $TMP_DIR/${PROJECT}-${OS}-${ARCH} "https://github.com/kubernetes-sigs/$PROJECT/releases/download/v${VERSION_TO_INSTALL}/${PROJECT}-${OS}-${ARCH}"  
        # $TMP_DIR/${PROJECT}-${OS}-${ARCH} --version
        sudo install $TMP_DIR/${PROJECT}-${OS}-${ARCH} /usr/local/bin/${PROJECT}
    fi
  else
    echo "$PROJECT $VERSION_TO_INSTALL already installed"
fi

${PROJECT} --version

cd $LAUNCH_DIR