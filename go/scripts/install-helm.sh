#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

PROJECT=helm

sudo -v

# https://www.howtoforge.com/ubuntu-kubernetes-helm-packages-manager/

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 |  bash

${PROJECT} version

cd $LAUNCH_DIR