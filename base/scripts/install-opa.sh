#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

USER=open-policy-agent
PROJECT=opa
OS=$(echo $(uname) | awk '{print tolower($0)}')
ARCH=amd64

# https://www.openpolicyagent.org/docs/latest/#running-opa

cd ${TMP_DIR}

$PROJECT version

# curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
# curl -L -o opa https://github.com/open-policy-agent/opa/releases/download/v0.28.0/opa_linux_amd64

LATEST_VERSION=$(curl --silent "https://api.github.com/repos/${USER}/${PROJECT}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
VERSION=$(echo -n $LATEST_VERSION | sed 's/^.//')
echo "Downloading ${PROJECT} ${LATEST_VERSION}..."

curl -sLo ${PROJECT} https://github.com/${USER}/${PROJECT}/releases/download/${LATEST_VERSION}/${PROJECT}_${OS}_${ARCH}
# chmod 755 $TMP_DIR/${PROJECT}
sudo install $TMP_DIR/${PROJECT} /usr/local/bin/${PROJECT}

$PROJECT version


cd $LAUNCH_DIR