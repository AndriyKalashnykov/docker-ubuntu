#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

VERSION_TO_INSTALL=${1:-}
VERSION_INSTALLED=""

USER=buildpacks
PROJECT=pack

# ./install-buildpacks.sh 0.18.0
# https://buildpacks.io/docs/tools/pack/
# https://github.com/buildpacks/pack/releases
# https://github.com/buildpacks/pack/releases/download/v0.18.0/pack-v0.18.0-linux.tgz

sudo -v
cd ${TMP_DIR}

if [ -z "${VERSION_TO_INSTALL}" ]; then
    VERSION_TO_INSTALL=$(curl -sL https://api.github.com/repos/$USER/$PROJECT/releases/latest  | grep '"tag_name":' | awk -F '"' '{printf("%s",$4)}' | cut -c 2-)
fi

if [ -f "$BIN_DIR/$PROJECT" ]; then
    VERSION_INSTALLED=$($BIN_DIR/$PROJECT --version | sed 's/+.*//')
fi

# echo "VERSION_TO_INSTALL: $VERSION_TO_INSTALL"
# echo "VERSION_INSTALLED: $VERSION_INSTALLED"

if [ "${VERSION_TO_INSTALL}" != "${VERSION_INSTALLED}" ]; then
    if [ -z $VERSION_INSTALLED ]; then
        echo "Installing $PROJECT: $VERSION_TO_INSTALL "
    else 
        echo "Replacing $PROJECT: $VERSION_INSTALLED > $VERSION_TO_INSTALL"
    fi

    curl -sSL "https://github.com/${USER}/${PROJECT}/releases/download/v${VERSION_TO_INSTALL}/${PROJECT}-v${VERSION_TO_INSTALL}-${OS_LC}${TGZ_EXT}" | sudo tar --no-same-owner -xz -C $BIN_DIR ${PROJECT}

  else
    echo "$PROJECT $VERSION_TO_INSTALL already installed"
fi

cd $LAUNCH_DIR