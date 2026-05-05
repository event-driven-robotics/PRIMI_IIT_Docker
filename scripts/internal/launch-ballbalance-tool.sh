#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULTS_FILE="$SCRIPT_DIR/../../yarpmanager/defaults.env"

if [[ -f "$DEFAULTS_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$DEFAULTS_FILE"
fi

tool="${1:?Usage: launch-ballbalance-tool.sh <tool>}"

selected_trial="${BALLBALANCE_DEMO_TRIAL:-trial_2}"
source_dataset="/workspace/data/BallBalance/$selected_trial"
dataset="$source_dataset"
label="BallBalance Demo"
local_prefix="/ballbalance_demo"

if [[ ! -d "$source_dataset" ]]; then
    echo "Dataset not found: $source_dataset" >&2
    exit 1
fi

rgb_data_log="$source_dataset/rgb/data.log"

if [[ ! -s "$rgb_data_log" ]]; then
    trial_tag="${selected_trial//[^A-Za-z0-9_-]/_}"
    dataset="/tmp/ballbalance_${trial_tag}_without_rgb"

    rm -rf "$dataset"
    mkdir -p "$dataset"

    # Some recordings ship an empty RGB replay log. yarpdataplayer crashes on
    # that input, so build a replay dataset with the valid streams only.
    for stream in atisleft atisright head rightarm skinrighthand torso; do
        if [[ ! -d "$source_dataset/$stream" ]]; then
            echo "Dataset stream not found: $source_dataset/$stream" >&2
            exit 1
        fi

        ln -sfn "$source_dataset/$stream" "$dataset/$stream"
    done
fi

# yarpdataplayer publishes replay outputs under its fixed /yarpdataplayer prefix.
player_prefix="/yarpdataplayer"
rgb_remote_candidates=(
    "${player_prefix}/grabber"
    "${player_prefix}/rgb"
)
left_events_remote="${player_prefix}/zynqGrabber/left/AE:o"
right_events_remote="${player_prefix}/zynqGrabber/right/AE:o"
encoders_remote="${player_prefix}/icub/right_arm/state:o"
view_local="${local_prefix}/yarpview/img:i"
vframer_left_name="${local_prefix}/vframer/left"
vframer_right_name="${local_prefix}/vframer/right"
vframer_width="640"
vframer_height="480"

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

wait_for_any_port() {
    local port

    for _ in $(seq 1 40); do
        for port in "$@"; do
            if yarp ping "$port" >/dev/null 2>&1; then
                printf '%s\n' "$port"
                return 0
            fi
        done
        sleep 0.25
    done

    echo "Timed out waiting for one of: $*" >&2
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
            yarpdataplayer|yarpdataplayer-c|yarpview|yarpscope|vFramer|iCubSkinGui)
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

        rgb_remote="$(wait_for_any_port "${rgb_remote_candidates[@]}")" || {
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
        wait_for_port "${player_prefix}/icub/right_arm/state:o"
        wait_for_port "${player_prefix}/icub/head/state:o"
        wait_for_port "${player_prefix}/icub/torso/state:o"
        
        xml_file="$SCRIPT_DIR/yarpscope_encoders.xml"

        exec yarpscope --title "$label Encoders (Arm, Head, Torso)" --xml "$xml_file"
        ;;
    skingui)
        skin_remote="${player_prefix}/icub/skin/righthand_comp"
        skin_local="/skinGui/right_hand:i"
        
        # If the dataset port is just /icub/skin/righthand without _comp, it will be mapped correctly below
        # since yarpdataplayer appends the original port name. I'll pick the comp data if possible, else fallback.
        
        skin_remote_candidates=(
            "${player_prefix}/icub/skin/right_hand"
            "${player_prefix}/icub/skin/righthand_comp"
            "${player_prefix}/icub/skin/righthand"
        )
        
        iCubSkinGui --from right_hand.ini &
        skin_pid=$!
        
        skin_remote="$(wait_for_any_port "${skin_remote_candidates[@]}")" || {
            kill "$skin_pid" 2>/dev/null || true
            exit 1
        }
        
        retry_connect "$skin_remote" "$skin_local" || {
            kill "$skin_pid" 2>/dev/null || true
            exit 1
        }
        
        wait "$skin_pid"
        ;;
    vframer-left)
        wait_for_port "$left_events_remote"
        exec vFramer --name "$vframer_left_name" --src "$left_events_remote" --width "$vframer_width" --height "$vframer_height"
        ;;
    vframer-right)
        wait_for_port "$right_events_remote"
        exec vFramer --name "$vframer_right_name" --src "$right_events_remote" --width "$vframer_width" --height "$vframer_height"
        ;;
    *)
        echo "Unknown tool: $tool" >&2
        exit 1
        ;;
esac
