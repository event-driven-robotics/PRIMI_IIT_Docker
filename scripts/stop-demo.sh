#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

require_docker

if ! compose_cmd ps --status running --services | grep -qx "$COMPOSE_SERVICE"; then
    echo "Container is not running. Nothing to stop."
    exit 0
fi

compose_exec bash -lc '
    pids=()
    while read -r pid comm; do
        case "$comm" in
            yarpdataplayer|yarpdataplayer-c|yarpview|yarpscope|vFramer)
                pids+=("$pid")
                ;;
        esac
    done < <(ps -eo pid=,comm=)

    if ((${#pids[@]})); then
        kill "${pids[@]}" >/dev/null 2>&1 || true
        sleep 1
        kill -9 "${pids[@]}" >/dev/null 2>&1 || true
    fi

    yarp clean --timeout 1 >/dev/null 2>&1 || true
'

echo "Demo tools stopped."
