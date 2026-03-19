#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

xmllint --noout yarpmanager/applications/*.xml

search_pattern='<name>bash</name>|<parameters>-lc '

if command -v rg >/dev/null 2>&1; then
    search_cmd=(rg -n "$search_pattern" yarpmanager/applications)
else
    search_cmd=(grep -R -n -E "$search_pattern" yarpmanager/applications)
fi

if "${search_cmd[@]}" >/dev/null; then
    echo "yarpmanager applications still contain bash-based launch definitions." >&2
    exit 1
fi

default_src="$(sed -n 's/^VFRAMER_SRC=//p' yarpmanager/defaults.env)"
manager_src="$(sed -n 's@.*<parameters>--src \(.*\)</parameters>@\1@p' yarpmanager/applications/04-vframer.xml)"
all_tools_src="$(sed -n 's@.*<parameters>--src \(.*\)</parameters>@\1@p' yarpmanager/applications/05-all-tools.xml)"

if [[ -z "$default_src" || -z "$manager_src" || -z "$all_tools_src" ]]; then
    echo "Failed to extract one or more vFramer defaults for verification." >&2
    exit 1
fi

if [[ "$default_src" != "$manager_src" || "$default_src" != "$all_tools_src" ]]; then
    echo "vFramer defaults are out of sync:" >&2
    echo "  defaults.env: $default_src" >&2
    echo "  04-vframer.xml: $manager_src" >&2
    echo "  05-all-tools.xml: $all_tools_src" >&2
    exit 1
fi

echo "Repo launch definitions look consistent."
