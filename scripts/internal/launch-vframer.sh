#!/usr/bin/env bash
set -euo pipefail

DEFAULTS_FILE="/workspace/project/yarpmanager/defaults.env"

if [[ -f "$DEFAULTS_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$DEFAULTS_FILE"
fi

default_side="${VFRAMER_DEFAULT_SIDE:-left}"
side="$default_side"

if (($# > 0)); then
    case "$1" in
        left|right)
            side="$1"
            shift
            ;;
        -*)
            ;;
        *)
            echo "Usage: $(basename "$0") [left|right] [vFramer args...]" >&2
            exit 1
            ;;
    esac
fi

case "$side" in
    left)
        vframer_src="${VFRAMER_LEFT_SRC:-${VFRAMER_SRC:-/zynqGrabber/left/AE:o}}"
        vframer_name="${VFRAMER_LEFT_NAME:-/vframer/left}"
        ;;
    right)
        vframer_src="${VFRAMER_RIGHT_SRC:-/zynqGrabber/right/AE:o}"
        vframer_name="${VFRAMER_RIGHT_NAME:-/vframer/right}"
        ;;
    *)
        echo "Unsupported vFramer side: $side" >&2
        exit 1
        ;;
esac

vframer_width="${VFRAMER_WIDTH:-640}"
vframer_height="${VFRAMER_HEIGHT:-480}"

exec vFramer --name "$vframer_name" --src "$vframer_src" "$@" --width "$vframer_width" --height "$vframer_height"
