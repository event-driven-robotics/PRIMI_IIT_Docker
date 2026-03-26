#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
COMPOSE_SERVICE="robotology"
CONTAINER_USER="robotology"
CONTAINER_HOME="/home/robotology"

require_docker() {
    bash "$SCRIPT_DIR/require-docker.sh"
}

allow_local_x11() {
    require_display
    xhost +local:
}

compose_cmd() {
    (
        cd "$PROJECT_ROOT"
        env LOCAL_UID="$(id -u)" LOCAL_GID="$(id -g)" docker compose "$@"
    )
}

compose_exec() {
    compose_cmd exec \
        -T \
        -u "$CONTAINER_USER" \
        -e HOME="$CONTAINER_HOME" \
        -e USER="$CONTAINER_USER" \
        -e LOGNAME="$CONTAINER_USER" \
        "$COMPOSE_SERVICE" \
        "$@"
}

compose_exec_tty() {
    compose_cmd exec \
        -u "$CONTAINER_USER" \
        -e HOME="$CONTAINER_HOME" \
        -e USER="$CONTAINER_USER" \
        -e LOGNAME="$CONTAINER_USER" \
        "$COMPOSE_SERVICE" \
        "$@"
}

compose_exec_detached() {
    compose_cmd exec \
        -u "$CONTAINER_USER" \
        -e HOME="$CONTAINER_HOME" \
        -e USER="$CONTAINER_USER" \
        -e LOGNAME="$CONTAINER_USER" \
        -d \
        "$COMPOSE_SERVICE" \
        "$@"
}

require_display() {
    if [[ -z "${DISPLAY:-}" ]]; then
        echo "DISPLAY is not set. Run this from your desktop session." >&2
        exit 1
    fi
}

reconcile_container() {
    require_docker

    compose_cmd up -d
}

ensure_container_running() {
    require_docker

    if compose_cmd ps --status running --services | grep -qx "$COMPOSE_SERVICE"; then
        return 0
    fi

    compose_cmd up -d
}

yarpserver_detected() {
    compose_exec bash -lc 'timeout 2 yarp detect >/dev/null 2>&1'
}

ensure_yarpserver() {
    ensure_container_running

    if yarpserver_detected; then
        return 0
    fi

    compose_exec_detached bash -lc 'exec /workspace/project/container-scripts/start-yarpserver.sh'

    for _ in 1 2 3 4 5; do
        if yarpserver_detected; then
            return 0
        fi
        sleep 1
    done

    echo "Failed to detect yarpserver after starting it." >&2
    echo "Check /tmp/yarpserver.log inside the container." >&2
    exit 1
}

open_gui_tool() {
    local tool="$1"
    shift

    allow_local_x11
    ensure_yarpserver
    compose_exec_detached "$tool" "$@"
}

open_gui_command() {
    local command="$1"
    shift

    allow_local_x11
    ensure_yarpserver
    compose_exec_detached bash -lc "$command" bash "$@"
}
