#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ensure_container_running
compose_exec bash -lc 'echo "Container data path: /workspace/data"; ls -la /workspace/data'
