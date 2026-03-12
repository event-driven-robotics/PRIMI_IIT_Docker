#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

actions=(
    "Start workstation"
    "Show status"
    "Open yarpmanager"
    "Run BallBalance moving demo"
    "Run BallBalance stationary demo"
    "Open yarpview"
    "Open yarpscope"
    "Open vFramer"
    "Open yarpdataplayer"
    "Stop demo tools only"
    "List mounted data"
    "Open shell"
    "Stop workstation"
    "Quit"
)

PS3="Choose an action: "

select action in "${actions[@]}"; do
    case "$REPLY" in
        1) "$SCRIPT_DIR/start-workstation.sh" ;;
        2) "$SCRIPT_DIR/status.sh" ;;
        3) "$SCRIPT_DIR/open-manager.sh" ;;
        4) "$SCRIPT_DIR/demo-ballbalance-moving.sh" ;;
        5) "$SCRIPT_DIR/demo-ballbalance-stationary.sh" ;;
        6) "$SCRIPT_DIR/open-yarpview.sh" ;;
        7) "$SCRIPT_DIR/open-yarpscope.sh" ;;
        8) "$SCRIPT_DIR/open-vframer.sh" ;;
        9) "$SCRIPT_DIR/open-dataplayer.sh" ;;
        10) "$SCRIPT_DIR/stop-demo.sh" ;;
        11) "$SCRIPT_DIR/list-data.sh" ;;
        12) "$SCRIPT_DIR/shell.sh" ;;
        13) "$SCRIPT_DIR/stop-workstation.sh" ;;
        14) exit 0 ;;
        *) echo "Invalid choice." >&2 ;;
    esac
done
