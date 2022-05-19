#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

GOLANG_VERSION=${1:-1.18.2}

cd $SCRIPT_DIR

echo "Install all ..."

./install-git.sh
./install-vivid.sh
./install-kubectl-toolchain.sh

cd $LAUNCH_DIR