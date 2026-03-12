#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

session="${1:-}"

if [[ "$session" != "moving" && "$session" != "stationary" ]]; then
    echo "Usage: $(basename "$0") <moving|stationary>" >&2
    exit 1
fi

allow_local_x11
ensure_yarpserver

launch_demo_tool() {
    local selected_session="$1"

    compose_exec_detached bash -lc 'cd /workspace/project && exec ./yarpmanager/bin/launch-ballbalance-demo.sh "$@"' bash "$selected_session"
}

launch_demo_tool "$session"

echo "BallBalance $session demo started."
echo "Dataset is loaded in yarpdataplayer."
echo "Use the dataplayer window to press Play."
