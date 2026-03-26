#!/usr/bin/env bash
set -euo pipefail

export HOME="${HOME:-/home/robotology}"
mkdir -p "$HOME/.config/yarp"

# Refresh the stored YARP name-server address when the host IP changes.
exec yarpserver --write >/tmp/yarpserver.log 2>&1
