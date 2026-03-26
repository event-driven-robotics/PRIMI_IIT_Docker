#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

side="left"

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

open_gui_command 'cd /workspace/project && exec ./scripts/internal/launch-vframer.sh "$@"' "$side" "$@"
