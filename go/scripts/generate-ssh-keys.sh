#!/bin/bash
#
# Runtime SSH key setup — called by scripts/entry.sh at CONTAINER START (not at
# build time). Operator keys are bind-mounted read-only at $SSH_SRC_DIR (default
# /run/host-ssh) by `make run-go`; whichever standard key types are present
# (id_rsa, id_ed25519, id_ecdsa) are copied in. If none are mounted, a fresh
# throwaway RSA key is generated. No key material is ever baked into the image —
# it exists only in the running container's writable layer.

set -euo pipefail

USER_NAME="${1:-${USER:-user}}"
USER_EMAIL="${2:-user@test.com}"
SSH_SRC_DIR="${SSH_SRC_DIR:-/run/host-ssh}"
SSH_DIR="/home/${USER_NAME}/.ssh"

mkdir -p "$SSH_DIR"

copied=0
if [ -d "$SSH_SRC_DIR" ]; then
    for name in id_rsa id_ed25519 id_ecdsa; do
        [ -s "${SSH_SRC_DIR}/${name}" ] || continue
        echo "Using operator SSH key ${name} from ${SSH_SRC_DIR} (runtime mount)..."
        cp "${SSH_SRC_DIR}/${name}" "${SSH_DIR}/${name}"
        chmod 600 "${SSH_DIR}/${name}"
        if [ -s "${SSH_SRC_DIR}/${name}.pub" ]; then
            cp "${SSH_SRC_DIR}/${name}.pub" "${SSH_DIR}/${name}.pub"
            chmod 644 "${SSH_DIR}/${name}.pub"
        fi
        copied=1
    done
fi

if [ "$copied" -eq 0 ] && [ ! -f "${SSH_DIR}/id_rsa" ]; then
    echo "No operator SSH keys mounted — generating a fresh per-container key pair..."
    ssh-keygen -q -t rsa -b 4096 -N '' -C "$USER_EMAIL" -f "${SSH_DIR}/id_rsa"
fi

chmod 700 "$SSH_DIR"

# Allow ssh-ing into this container with whatever public keys are present
# (idempotent — never duplicates a line).
touch "${SSH_DIR}/authorized_keys"
for pub in "${SSH_DIR}"/*.pub; do
    [ -s "$pub" ] || continue
    if ! grep -qxFf "$pub" "${SSH_DIR}/authorized_keys" 2>/dev/null; then
        cat "$pub" >> "${SSH_DIR}/authorized_keys"
    fi
done
chmod 600 "${SSH_DIR}/authorized_keys"
