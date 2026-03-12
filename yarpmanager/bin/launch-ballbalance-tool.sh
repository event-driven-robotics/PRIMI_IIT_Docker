#!/usr/bin/env bash
set -euo pipefail

session="${1:?Usage: launch-ballbalance-tool.sh <moving|stationary> <tool>}"
tool="${2:?Usage: launch-ballbalance-tool.sh <moving|stationary> <tool>}"

case "$session" in
    moving)
        dataset="/workspace/data/BallBalance/test_moving"
        label="BallBalance Moving"
        local_prefix="/ballbalance_moving"
        ;;
    stationary)
        dataset="/workspace/data/BallBalance/test_stationary"
        label="BallBalance Stationary"
        local_prefix="/ballbalance_stationary"
        ;;
    *)
        echo "Unknown session: $session" >&2
        exit 1
        ;;
esac

# yarpdataplayer publishes replay outputs under its fixed /yarpdataplayer prefix.
player_prefix="/yarpdataplayer"
rgb_remote="${player_prefix}/grabber"
events_remote="${player_prefix}/zynqGrabber/left/AE:o"
encoders_remote="${player_prefix}/icub/right_arm/state:o"
view_local="${local_prefix}/yarpview/img:i"
vframer_name="${local_prefix}/vframer"

wait_for_port() {
    local port="$1"

    for _ in $(seq 1 40); do
        if yarp ping "$port" >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.25
    done

    echo "Timed out waiting for $port" >&2
    return 1
}

retry_connect() {
    local source="$1"
    local target="$2"

    for _ in $(seq 1 40); do
        if yarp connect "$source" "$target" >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.25
    done

    echo "Failed to connect $source -> $target" >&2
    return 1
}

cleanup_demo_tools() {
    local pids=()

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
}

case "$tool" in
    dataplayer)
        cleanup_demo_tools
        exec yarpdataplayer --dataset "$dataset" --add_prefix
        ;;
    yarpview)
        yarpview --name "$view_local" --title "$label RGB" &
        view_pid=$!

        wait_for_port "$rgb_remote" || {
            kill "$view_pid" 2>/dev/null || true
            exit 1
        }

        retry_connect "$rgb_remote" "$view_local" || {
            kill "$view_pid" 2>/dev/null || true
            exit 1
        }

        wait "$view_pid"
        ;;
    yarpscope)
        wait_for_port "$encoders_remote"
        exec yarpscope --remote "$encoders_remote" --carrier tcp --title "$label Right Arm Encoders"
        ;;
    vframer)
        wait_for_port "$events_remote"
        exec vFramer --name "$vframer_name" --src "$events_remote"
        ;;
    *)
        echo "Unknown tool: $tool" >&2
        exit 1
        ;;
esac
