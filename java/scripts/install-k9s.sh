#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

VERSION_TO_INSTALL=${1:-}
VERSION_INSTALLED=""

USER=derailed
PROJECT=k9s
OS=$(echo $(uname))
ARCH=$(echo $(uname -m))
EXT=.tar.gz

# https://github.com/derailed/k9s
# https://k9scli.io/topics/install/

sudo -v

if [ -z "${VERSION_TO_INSTALL}" ]; then
    VERSION_TO_INSTALL=$(curl -s https://api.github.com/repos/$USER/$PROJECT/releases/latest  | grep '"tag_name":' | awk -F '"' '{printf("%s",$4)}')
fi

if [ -f "$BIN_DIR/$PROJECT" ]; then
    VERSION_INSTALLED=$($BIN_DIR/$PROJECT version -s | grep "Version" | awk '{printf("%s",$2)}')
fi

if [ "${VERSION_TO_INSTALL}" != "${VERSION_INSTALLED}" ]; then
    if [ -z $VERSION_INSTALLED ]; then
        echo "Installing $PROJECT: $VERSION_TO_INSTALL "
    else 
        echo "Replacing $PROJECT: $VERSION_INSTALLED > $VERSION_TO_INSTALL"
    fi

    curl -sL "https://github.com/$USER/$PROJECT/releases/download/${VERSION_TO_INSTALL}/${PROJECT}_${OS}_${ARCH}${EXT}"  | sudo tar zx -C $BIN_DIR $PROJECT
  else
    echo "$PROJECT $VERSION_TO_INSTALL already installed"
fi

cd $LAUNCH_DIR