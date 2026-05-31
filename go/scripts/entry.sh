#!/bin/bash
#
# Container entrypoint hook (sourced by the image ENTRYPOINT before the command).
# Activates mise so every pinned tool is on PATH with its environment set
# (JAVA_HOME, GOROOT, etc.) for non-interactive and interactive shells alike.

if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash --shims)"
    # Export each active tool's env (JAVA_HOME, GOROOT, …) so they are set in
    # non-interactive shells too, not only interactive ones (which get them via
    # `mise activate` in ~/.bashrc).
    eval "$(mise env -s bash 2>/dev/null)"
fi

lsb_release -a 2>/dev/null || true
