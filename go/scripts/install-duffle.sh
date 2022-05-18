#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

VERSION_TO_INSTALL=${1:-}
VERSION_INSTALLED=""

USER=cnabio
PROJECT=duffle

# ./install-duffle.sh 0.3.4-beta.1
# https://duffle.sh/
# https://github.com/cnabio/duffle 
# https://github.com/cnabio/duffle/releases
# https://github.com/cnabio/duffle/releases/download/0.3.4-beta.1/duffle-linux-amd64

sudo -v

if [ -z "${VERSION_TO_INSTALL}" ]; then
    VERSION_TO_INSTALL=$(curl -sL https://api.github.com/repos/$USER/$PROJECT/releases/latest  | grep '"tag_name":' | awk -F '"' '{printf("%s",$4)}') 
fi

if [ -f "$BIN_DIR/$PROJECT" ]; then
    VERSION_INSTALLED=$($BIN_DIR/$PROJECT version | awk '{printf("%s",$1)}')
fi

# echo "VERSION_TO_INSTALL: $VERSION_TO_INSTALL"
# echo "VERSION_INSTALLED: $VERSION_INSTALLED"

if [ "${VERSION_TO_INSTALL}" != "${VERSION_INSTALLED}" ]; then
    if [ -z $VERSION_INSTALLED ]; then
        echo "Installing $PROJECT: $VERSION_TO_INSTALL "
    else 
        echo "Replacing $PROJECT: $VERSION_INSTALLED > $VERSION_TO_INSTALL"
    fi

    sudo curl -sLo $BIN_DIR/$PROJECT "https://github.com/$USER/$PROJECT/releases/download/${VERSION_TO_INSTALL}/${PROJECT}-${OS_LC}-${ARCH}"
  else
    echo "$PROJECT $VERSION_TO_INSTALL already installed"
fi

cd $LAUNCH_DIR