#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

USER=gohugoio
PROJECT=hugo
OS=Linux
ARCH=64bit
EXT=deb

# https://computingforgeeks.com/how-to-install-hugo-on-ubuntu-debian/
# https://www.atlantic.net/vps-hosting/how-to-install-hugo-website-generator-on-ubuntu-20-04/
# https://www.howtoforge.com/how-to-install-hugo-site-generator-on-ubuntu/
# https://github.com/gohugoio/hugo

sudo -v
cd ${TMP_DIR}


LATEST_VERSION=$(curl --silent "https://api.github.com/repos/${USER}/${PROJECT}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
VERSION=$(echo -n $LATEST_VERSION | sed 's/^.//')
echo "Downloading ${PROJECT} ${LATEST_VERSION}..."

# curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest \
#  | grep  browser_download_url \
#  | grep Linux-64bit.deb \
#  | grep -v extended \
#  | cut -d '"' -f 4 \
#  | wget -i -

sudo curl -sLo $TMP_DIR/${PROJECT}_${VERSION}_${OS}-${ARCH}.${EXT} https://github.com/${USER}/${PROJECT}/releases/download/${LATEST_VERSION}/${PROJECT}_extended_${VERSION}_${OS}-${ARCH}.${EXT}
sudo dpkg -i $TMP_DIR/${PROJECT}_${VERSION}_${OS}-${ARCH}.${EXT}

$PROJECT version

cd $LAUNCH_DIR