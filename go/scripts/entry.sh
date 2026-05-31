#!/bin/bash
#
# Container entrypoint hook (sourced by the image ENTRYPOINT before the command).
#
# 1) Activates mise so every pinned tool is on PATH with its environment set
#    (GOROOT, JAVA_HOME, etc.) for non-interactive and interactive shells alike.
# 2) Sets up operator credentials AT RUNTIME from bind-mounts / env injected by
#    `make run-go`, so the IMAGE filesystem never contains SSH/GPG/PAT material.
#    Bare `docker run` without those mounts still works: a fresh SSH key is
#    generated and GPG/PAT setup is skipped.

USER_NAME="${USER:-user}"
SCRIPTS_DIR="/home/${USER_NAME}/scripts"

if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash --shims)"
    # Export each active tool's env (GOROOT, …) so non-interactive shells get them
    # too, not only interactive ones (which load it via ~/.bashrc).
    eval "$(mise env -s bash 2>/dev/null)"
fi

# --- Runtime credential setup — nothing here is baked into the image ---------
if [ -x "${SCRIPTS_DIR}/generate-ssh-keys.sh" ]; then
    "${SCRIPTS_DIR}/generate-ssh-keys.sh" "$USER_NAME" "${USER_EMAIL:-user@test.com}" || true
fi
if [ -x "${SCRIPTS_DIR}/generate-gpg-keys.sh" ]; then
    "${SCRIPTS_DIR}/generate-gpg-keys.sh" || true
fi
# GitHub PAT -> ~/.netrc (authenticated git/HTTPS), only when provided at runtime.
# Append the machine entry to whatever .netrc the image ships (a non-secret
# template), but only if a github.com entry isn't already present (idempotent
# across restarts). The token lives only in the running container, never the image.
if [ -n "${GITHUB_PAT:-}" ] && ! grep -q '^machine github\.com' "${HOME}/.netrc" 2>/dev/null; then
    umask 077
    printf 'machine github.com\nlogin %s\npassword %s\n' \
        "${GITHUB_USER:-AndriyKalashnykov}" "$GITHUB_PAT" >> "${HOME}/.netrc"
    chmod 600 "${HOME}/.netrc"
fi
# -----------------------------------------------------------------------------

lsb_release -a 2>/dev/null || true
