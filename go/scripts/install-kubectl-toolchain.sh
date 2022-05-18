#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

cd $SCRIPT_DIR

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

./install-conftest.sh
./install-duffle.sh
./install-flux.sh
./install-helm.sh
./install-hugo.sh
./install-k9s.sh
./install-kind.sh
./install-kubebuilder.sh
./install-kubectx.sh
./install-kubens.sh
./install-kustomize.sh
./install-opa.sh

cd $LAUNCH_DIR