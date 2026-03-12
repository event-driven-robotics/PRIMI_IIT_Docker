#!/usr/bin/env bash
set -euo pipefail

exec yarpserver >/tmp/yarpserver.log 2>&1
