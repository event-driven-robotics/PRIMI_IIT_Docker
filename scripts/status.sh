#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

require_docker

echo "Container status:"
compose_cmd ps
echo

if compose_cmd ps --status running --services | grep -qx "$COMPOSE_SERVICE"; then
    echo "YARP name server:"
    if compose_exec yarp detect >/dev/null 2>&1; then
        echo "  detected"
    else
        echo "  not detected"
    fi
else
    echo "YARP name server:"
    echo "  container is not running"
fi
