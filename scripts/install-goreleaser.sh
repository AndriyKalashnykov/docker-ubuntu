#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

VERSION_TO_INSTALL=${1:-}
VERSION_INSTALLED=""

USER=goreleaser
PROJECT=goreleaser

# ./install-goreleaser.sh 0.172.0
# https://goreleaser.com/install/
# https://github.com/goreleaser/goreleaser/releases
# curl -sSLf https://github.com/goreleaser/goreleaser/releases/download/v0.169.0/goreleaser_Linux_x86_64.tar.gz

sudo -v

cd $TMP_DIR

if [ -z "${VERSION_TO_INSTALL}" ]; then
    VERSION_TO_INSTALL=$(curl -sL https://api.github.com/repos/$USER/$PROJECT/releases/latest  | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^.//')
fi

if [ -f "$BIN_DIR/$PROJECT" ]; then
    VERSION_INSTALLED=$($BIN_DIR/$PROJECT --version | grep 'goreleaser version' | awk '{printf("%s",$3)}')
fi

# echo "VERSION_TO_INSTALL: $VERSION_TO_INSTALL"
# echo "VERSION_INSTALLED: $VERSION_INSTALLED"

if [ "${VERSION_TO_INSTALL}" != "${VERSION_INSTALLED}" ]; then
    if [ -z $VERSION_INSTALLED ]; then
        echo "Installing $PROJECT: $VERSION_TO_INSTALL"
    else 
        echo "Replacing $PROJECT: $VERSION_INSTALLED > $VERSION_TO_INSTALL"
    fi

    curl -sSLf "https://github.com/$USER/$PROJECT/releases/download/v${VERSION_TO_INSTALL}/${PROJECT}_${OS}_${ARCH_ORIG}${TAR_GZ_EXT}" | sudo tar -zx -C $BIN_DIR ${PROJECT}
  else
    echo "$PROJECT $VERSION_TO_INSTALL already installed"
fi

cd $LAUNCH_DIR