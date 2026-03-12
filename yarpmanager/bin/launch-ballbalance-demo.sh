#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
session="${1:?Usage: launch-ballbalance-demo.sh <moving|stationary>}"

if [[ "$session" != "moving" && "$session" != "stationary" ]]; then
    echo "Unknown session: $session" >&2
    exit 1
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

"$SCRIPT_DIR/launch-ballbalance-tool.sh" "$session" dataplayer &
pids+=("$!")

sleep 2

"$SCRIPT_DIR/launch-ballbalance-tool.sh" "$session" yarpview &
pids+=("$!")

"$SCRIPT_DIR/launch-ballbalance-tool.sh" "$session" yarpscope &
pids+=("$!")

"$SCRIPT_DIR/launch-ballbalance-tool.sh" "$session" vframer &
pids+=("$!")

wait "${pids[@]}"
