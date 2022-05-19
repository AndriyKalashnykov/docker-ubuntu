#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

USER_NAME=${1:-user}
GPG_SECRET=${2:-}
GPG_OWNER_TRUST=${3:-}
GPG_PwD=${4:-}

cd $SCRIPT_DIR

# echo "USER_NAME: ${USER_NAME}"
# echo "GPG_SECRET: ${GPG_SECRET}"
# echo "GPG_OWNER_TRUST: ${GPG_OWNER_TRUST}"
# echo "GPG_PwD: ${GPG_PwD}"

# https://www.cyberciti.biz/faq/unix-linux-bash-script-check-if-variable-is-empty/
if [[ -n "${GPG_SECRET}" && -n "${GPG_PwD}" && -n "${GPG_OWNER_TRUST}" ]]; then
    
    echo "Importing provided GPG keys..."

    mkdir -p /home/$USER_NAME/.gpg

    # Save provided keys
    echo "${GPG_OWNER_TRUST}" | base64 --decode > /home/$USER_NAME/.gpg/ownertrust-gpg.txt
    echo "${GPG_SECRET}" | base64 --decode > /home/$USER_NAME/.gpg/secret-gpg.key

    # Import provided keys
    # https://unix.stackexchange.com/questions/60213/gpg-asks-for-password-even-with-passphrase/68726#68726
    echo "${GPG_PwD}" | gpg --batch --yes --passphrase-fd 0 --import /home/$USER_NAME/.gpg/secret-gpg.key
    gpg --import-ownertrust /home/$USER_NAME/.gpg/ownertrust-gpg.txt
    
    # https://github.com/ci-and-cd/maven-build/blob/34be4660e3912eeeb2d27762a8993c1110001620/src/main/ci-script/lib_ci.sh#L240
    # List imported keys
    gpg --batch=true --version
    gpg --list-secret-keys --keyid-format=long
    gpg --export-ownertrust

    # export GPG_TTY=$(tty)
    # export GPG_TTY=$(tty) && echo "test" | gpg --clearsign
    GPG_TTY=$(tty || echo "")
    if [[ -z "${GPG_TTY}" ]]; then unset GPG_TTY; fi
    echo "gpg tty '${GPG_TTY}'"
    echo "test" | gpg --clearsign
    # gpg --status-fd=2 -bsau D1FAA03AF6F5F048

    # Congigure git to use GPG: ~/.gitconfig
    # git config --global user.signingkey D1FAA03AF6F5F048
    # git config --global commit.gpgsign true
fi

cd $LAUNCH_DIR