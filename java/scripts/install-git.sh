#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh


git --version

# ssh -vT git@github.com

git clone https://github.com/magicmonty/bash-git-prompt.git .bash-git-prompt --depth=1

# curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash

git lfs install

git --version

# Signing commits GPG commits
# https://docs.github.com/en/github/authenticating-to-github/managing-commit-signature-verification/signing-commits
# git config --global commit.gpgsign true
# edit ../../git/.gitconfig
# add -s to "c" and "cmp" aliases
# git commit -S -m your commit message

cd $LAUNCH_DIR