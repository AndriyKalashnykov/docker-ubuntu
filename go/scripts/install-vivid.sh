#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

USER=sharkdp
PROJECT=vivid
OS=linux
ARCH=amd64
EXT=.deb

# curl -L https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.256dark -o ~/.dir_colors
# eval `dircolors ~/.dir_colors`
# test -r ~/.dir_colors && eval "$(dircolors -b ~/.dir_colors)" || eval "$(dircolors -b)"

# https://github.com/sharkdp/vivid
# wget "https://github.com/sharkdp/vivid/releases/download/v0.8.0/vivid_0.8.0_amd64.deb"
# sudo dpkg -i vivid_0.8.0_amd64.deb

LATEST_VERSION=$(curl --silent "https://api.github.com/repos/${USER}/${PROJECT}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
VERSION=$(echo -n $LATEST_VERSION | sed 's/^.//')
echo "Downloading ${PROJECT} ${LATEST_VERSION} ..."

sudo curl -sLo $TMP_DIR/${PROJECT}_${VERSION}_${ARCH}${EXT} "https://github.com/sharkdp/vivid/releases/download/${LATEST_VERSION}/vivid_${VERSION}_${ARCH}${EXT}"
sudo dpkg -i $TMP_DIR/${PROJECT}_${VERSION}_${ARCH}${EXT}

vivid --version

export LS_COLORS="$(vivid generate snazzy)"

cd $LAUNCH_DIR