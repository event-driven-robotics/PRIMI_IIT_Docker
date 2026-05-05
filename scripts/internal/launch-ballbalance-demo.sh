#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULTS_FILE="$SCRIPT_DIR/../../yarpmanager/defaults.env"

if [[ -f "$DEFAULTS_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$DEFAULTS_FILE"
fi

selected_trial="${BALLBALANCE_DEMO_TRIAL:-trial_2}"
rgb_data_log="/workspace/data/BallBalance/$selected_trial/rgb/data.log"
has_rgb=0

if [[ -s "$rgb_data_log" ]]; then
    has_rgb=1
fi

pids=()

cleanup() {
    if ((${#pids[@]})); then
        kill "${pids[@]}" >/dev/null 2>&1 || true
        sleep 1
        kill -9 "${pids[@]}" >/dev/null 2>&1 || true
        wait "${pids[@]}" >/dev/null 2>&1 || true
    fi
}

trap cleanup EXIT INT TERM

"$SCRIPT_DIR/launch-ballbalance-tool.sh" dataplayer &
pids+=("$!")

sleep 2

if [[ "$has_rgb" -eq 1 ]]; then
    "$SCRIPT_DIR/launch-ballbalance-tool.sh" yarpview &
    pids+=("$!")
fi

"$SCRIPT_DIR/launch-ballbalance-tool.sh" yarpscope &
pids+=("$!")

"$SCRIPT_DIR/launch-ballbalance-tool.sh" skingui &
pids+=("$!")

"$SCRIPT_DIR/launch-ballbalance-tool.sh" vframer-left &
pids+=("$!")

# vFramer derives an internal AE input port name at startup. Launching the
# two instances back-to-back can make them collide on that generated name.
sleep 1

"$SCRIPT_DIR/launch-ballbalance-tool.sh" vframer-right &
pids+=("$!")

wait "${pids[@]}"
