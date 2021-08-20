#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

sudo -v
cd ${TMP_DIR}

PROJECT=ytt

sudo curl -sL "https://k14s.io/install.sh" | sudo bash

cd $LAUNCH_DIR