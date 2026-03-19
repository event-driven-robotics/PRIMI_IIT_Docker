#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

require_docker

config_output="$(compose_cmd config)"

extract_build_arg() {
    local key="$1"
    awk -v key="$key" '$1 == key ":" { print $2; exit }' <<<"$config_output"
}

echo "Configured build refs:"
echo "  YCM: $(extract_build_arg YCM_VERSION)"
echo "  YARP: $(extract_build_arg YARP_VERSION)"
echo "  event-driven ref: $(extract_build_arg ED_VERSION)"
echo "  event-driven commit: $(extract_build_arg ED_COMMIT)"
echo
echo "Installed versions:"

if ! compose_cmd ps --status running --services | grep -qx "$COMPOSE_SERVICE"; then
    echo "  container is not running"
    echo "  start it with ./scripts/start-workstation.sh to inspect the built image"
    exit 0
fi

compose_exec bash -lc '
set -euo pipefail

yarp_version="$(yarp version 2>/dev/null | sed -n "s/^YARP version //p")"
ed_package_version="$(sed -n "s/^set(PACKAGE_VERSION \"\\(.*\\)\")/\\1/p" /usr/local/lib/cmake/event-driven/event-driven-config-version.cmake 2>/dev/null || true)"
ed_source_ref="$(git -c safe.directory=/usr/local/src/event-driven -C /usr/local/src/event-driven log -1 --format="%H %cs %s" 2>/dev/null || true)"

echo "  YARP: ${yarp_version:-unknown}"
echo "  event-driven package: ${ed_package_version:-unknown}"

if [[ -n "${ed_source_ref:-}" ]]; then
    echo "  event-driven source: ${ed_source_ref}"
fi
'
