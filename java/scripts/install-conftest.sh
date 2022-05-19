#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

VERSION_TO_INSTALL=${1:-}
VERSION_INSTALLED=""

USER=open-policy-agent
PROJECT=conftest

# ./install-conftest.sh 0.24.0
# https://github.com/open-policy-agent/conftest/releases
# https://github.com/open-policy-agent/conftest/releases/download/v0.25.0/conftest_0.25.0_Linux_x86_64.tar.gz

sudo -v

if [ -z "${VERSION_TO_INSTALL}" ]; then
    VERSION_TO_INSTALL=$(curl -sL https://api.github.com/repos/$USER/$PROJECT/releases/latest  | grep '"tag_name":' | awk -F '"' '{printf("%s",$4)}' | cut -c 2-) 
fi

if [ -f "$BIN_DIR/$PROJECT" ]; then
    VERSION_INSTALLED=$($BIN_DIR/$PROJECT --version | grep "Version:" | awk '{printf("%s",$2)}')
fi

# echo "VERSION_TO_INSTALL: $VERSION_TO_INSTALL"
# echo "VERSION_INSTALLED: $VERSION_INSTALLED"

if [ "${VERSION_TO_INSTALL}" != "${VERSION_INSTALLED}" ]; then
    if [ -z $VERSION_INSTALLED ]; then
        echo "Installing $PROJECT: $VERSION_TO_INSTALL "
    else 
        echo "Replacing $PROJECT: $VERSION_INSTALLED > $VERSION_TO_INSTALL"
    fi

    curl -sL "https://github.com/$USER/$PROJECT/releases/download/v${VERSION_TO_INSTALL}/${PROJECT}_${VERSION_TO_INSTALL}_${OS}_${ARCH_ORIG}${TAR_GZ_EXT}" | sudo tar -xz -C $BIN_DIR $PROJECT
  else
    echo "$PROJECT $VERSION_TO_INSTALL already installed"
fi

cd $LAUNCH_DIR