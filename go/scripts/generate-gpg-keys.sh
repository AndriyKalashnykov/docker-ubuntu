#!/bin/bash
#
# Import GPG key material provided as BuildKit secret mounts:
#   /run/secrets/gpg_secret      — the secret key (raw, ASCII-armored or binary)
#   /run/secrets/gpg_ownertrust  — the ownertrust export
#   /run/secrets/gpg_pwd         — the key passphrase
# If any is missing, the import is skipped. No key material is ever a build arg.

USER_NAME=${1:-user}

if [ -s /run/secrets/gpg_secret ] && [ -s /run/secrets/gpg_pwd ] && [ -s /run/secrets/gpg_ownertrust ]; then
    echo "Importing provided GPG keys..."
    GPG_PWD="$(cat /run/secrets/gpg_pwd)"

    # https://unix.stackexchange.com/questions/60213/gpg-asks-for-password-even-with-passphrase
    echo "$GPG_PWD" | gpg --batch --yes --passphrase-fd 0 --import /run/secrets/gpg_secret
    gpg --import-ownertrust /run/secrets/gpg_ownertrust

    gpg --batch=true --version
    gpg --list-secret-keys --keyid-format=long || true
    gpg --export-ownertrust || true
else
    echo "GPG key material not provided — skipping GPG import."
fi
