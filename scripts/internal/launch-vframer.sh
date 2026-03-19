#!/usr/bin/env bash
set -euo pipefail

DEFAULTS_FILE="/workspace/project/yarpmanager/defaults.env"

if [[ -f "$DEFAULTS_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$DEFAULTS_FILE"
fi

VFRAMER_SRC="${VFRAMER_SRC:-/zynqGrabber/left/AE:o}"

exec vFramer --src "$VFRAMER_SRC" "$@"
