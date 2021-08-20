#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh


# https://computingforgeeks.com/install-source-to-image-toolkit-on-linux/
# https://github.com/openshift/source-to-image

sudo -v

USER=openshift
PROJECT=source-to-image
OS=$(echo $(uname) | awk '{print tolower($0)}')
ARCH=amd64

mkdir -p $TMP_DIR/s2i && cd $TMP_DIR/s2i

curl -s https://api.github.com/repos/${USER}/${PROJECT}/releases/latest \
  | grep browser_download_url \
  | grep ${OS}-${ARCH} \
  | cut -d '"' -f 4 \
  | wget -qi -

cd $TMP_DIR/s2i
tar xvf ${PROJECT}*.gz
# ls -al $TMP_DIR/s2i
sudo install s2i /usr/local/bin/s2i
unlink sti
rm -rf $TMP_DIR/s2i/

s2i version

cd $LAUNCH_DIR