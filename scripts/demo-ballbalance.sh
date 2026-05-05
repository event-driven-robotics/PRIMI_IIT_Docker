#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
DEFAULTS_FILE="$SCRIPT_DIR/../yarpmanager/defaults.env"

if [[ -f "$DEFAULTS_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$DEFAULTS_FILE"
fi

if (($# != 0)); then
    echo "Usage: $(basename "$0")" >&2
    exit 1
fi

selected_trial="${BALLBALANCE_DEMO_TRIAL:-trial_2}"
dataset="/workspace/data/BallBalance/$selected_trial"

allow_local_x11
ensure_yarpserver

rgb_available=1
if ! compose_exec bash -lc "test -s '$dataset/rgb/data.log'"; then
    rgb_available=0
fi

compose_exec_detached bash -lc 'cd /workspace/project && exec ./scripts/internal/launch-ballbalance-demo.sh'

echo "BallBalance demo started."
echo "Selected trial: $selected_trial"
echo "Container dataset path: $dataset"
echo "Dataset is loaded in yarpdataplayer."
if [[ "$rgb_available" -eq 0 ]]; then
    echo "RGB replay data is empty for $selected_trial, so yarpview is skipped for this demo."
fi
echo "Use the dataplayer window to press Play."
