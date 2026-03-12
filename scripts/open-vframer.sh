#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

open_gui_command 'cd /workspace/project && exec ./yarpmanager/bin/launch-vframer.sh "$@"' "$@"
