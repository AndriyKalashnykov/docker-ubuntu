#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

cd $SCRIPT_DIR

source /etc/profile.d/golang_path.sh

# https://github.com/jfeliu007/goplantuml
go install github.com/jfeliu007/goplantuml/cmd/goplantuml@latest

cd $LAUNCH_DIR