#!/bin/bash
#
# Runtime GPG import — called by scripts/entry.sh at CONTAINER START (not at build
# time). Key material is bind-mounted read-only at $GPG_SRC_DIR (default
# /run/host-gpg) and the passphrase comes from the MY_GPG_PASSWORD env var, both
# injected by `make run-go`. Skipped if absent. Nothing is baked into the image.

set -uo pipefail

GPG_SRC_DIR="${GPG_SRC_DIR:-/run/host-gpg}"

if [ -s "${GPG_SRC_DIR}/secret.key" ] && [ -s "${GPG_SRC_DIR}/ownertrust.txt" ] && [ -n "${MY_GPG_PASSWORD:-}" ]; then
    if gpg --list-secret-keys 2>/dev/null | grep -q '^sec'; then
        echo "GPG secret key already present — skipping import."
    else
        echo "Importing operator GPG key from ${GPG_SRC_DIR} (runtime mount)..."
        # https://unix.stackexchange.com/questions/60213
        echo "$MY_GPG_PASSWORD" | gpg --batch --yes --passphrase-fd 0 --import "${GPG_SRC_DIR}/secret.key"
        gpg --import-ownertrust "${GPG_SRC_DIR}/ownertrust.txt"
        gpg --list-secret-keys --keyid-format=long || true
    fi
else
    echo "GPG key material not provided — skipping GPG import."
fi
