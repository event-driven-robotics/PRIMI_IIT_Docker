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

default_side="$(sed -n 's/^VFRAMER_DEFAULT_SIDE=//p' yarpmanager/defaults.env)"
default_left_src="$(sed -n 's/^VFRAMER_LEFT_SRC=//p' yarpmanager/defaults.env)"
default_right_src="$(sed -n 's/^VFRAMER_RIGHT_SRC=//p' yarpmanager/defaults.env)"
default_left_name="$(sed -n 's/^VFRAMER_LEFT_NAME=//p' yarpmanager/defaults.env)"
default_right_name="$(sed -n 's/^VFRAMER_RIGHT_NAME=//p' yarpmanager/defaults.env)"
default_width="$(sed -n 's/^VFRAMER_WIDTH=//p' yarpmanager/defaults.env)"
default_height="$(sed -n 's/^VFRAMER_HEIGHT=//p' yarpmanager/defaults.env)"

left_manager_src="$(sed -n 's@.*<parameters>--name /vframer/left --src \([^ ]*\) .*@\1@p' yarpmanager/applications/04-vframer-left.xml)"
right_manager_src="$(sed -n 's@.*<parameters>--name /vframer/right --src \([^ ]*\) .*@\1@p' yarpmanager/applications/04-vframer-right.xml)"
all_tools_left_src="$(sed -n 's@.*<parameters>--name /vframer/left --src \([^ ]*\) .*@\1@p' yarpmanager/applications/05-all-tools.xml)"
all_tools_right_src="$(sed -n 's@.*<parameters>--name /vframer/right --src \([^ ]*\) .*@\1@p' yarpmanager/applications/05-all-tools.xml)"

left_manager_name="$(sed -n 's@.*<parameters>--name \([^ ]*\) --src .*@\1@p' yarpmanager/applications/04-vframer-left.xml)"
right_manager_name="$(sed -n 's@.*<parameters>--name \([^ ]*\) --src .*@\1@p' yarpmanager/applications/04-vframer-right.xml)"
all_tools_left_name="$(sed -n 's@.*<parameters>--name \(/vframer/left\) --src .*@\1@p' yarpmanager/applications/05-all-tools.xml)"
all_tools_right_name="$(sed -n 's@.*<parameters>--name \(/vframer/right\) --src .*@\1@p' yarpmanager/applications/05-all-tools.xml)"
left_manager_width="$(sed -n 's@.*--width \([^ ]*\) .*@\1@p' yarpmanager/applications/04-vframer-left.xml)"
right_manager_width="$(sed -n 's@.*--width \([^ ]*\) .*@\1@p' yarpmanager/applications/04-vframer-right.xml)"
all_tools_left_width="$(sed -n 's@.*--name /vframer/left .*--width \([^ ]*\) .*@\1@p' yarpmanager/applications/05-all-tools.xml)"
all_tools_right_width="$(sed -n 's@.*--name /vframer/right .*--width \([^ ]*\) .*@\1@p' yarpmanager/applications/05-all-tools.xml)"
left_manager_height="$(sed -n 's@.*--height \([^ <]*\)</parameters>@\1@p' yarpmanager/applications/04-vframer-left.xml)"
right_manager_height="$(sed -n 's@.*--height \([^ <]*\)</parameters>@\1@p' yarpmanager/applications/04-vframer-right.xml)"
all_tools_left_height="$(sed -n 's@.*--name /vframer/left .*--height \([^ <]*\)</parameters>@\1@p' yarpmanager/applications/05-all-tools.xml)"
all_tools_right_height="$(sed -n 's@.*--name /vframer/right .*--height \([^ <]*\)</parameters>@\1@p' yarpmanager/applications/05-all-tools.xml)"

if [[ -z "$default_side" || -z "$default_left_src" || -z "$default_right_src" || -z "$default_left_name" || -z "$default_right_name" || -z "$default_width" || -z "$default_height" || -z "$left_manager_src" || -z "$right_manager_src" || -z "$all_tools_left_src" || -z "$all_tools_right_src" || -z "$left_manager_name" || -z "$right_manager_name" || -z "$all_tools_left_name" || -z "$all_tools_right_name" || -z "$left_manager_width" || -z "$right_manager_width" || -z "$all_tools_left_width" || -z "$all_tools_right_width" || -z "$left_manager_height" || -z "$right_manager_height" || -z "$all_tools_left_height" || -z "$all_tools_right_height" ]]; then
    echo "Failed to extract one or more vFramer defaults for verification." >&2
    exit 1
fi

if [[ "$default_side" != "left" ]]; then
    echo "VFRAMER_DEFAULT_SIDE must stay set to left for the default CLI behavior." >&2
    exit 1
fi

if [[ "$default_left_src" != "$left_manager_src" || "$default_left_src" != "$all_tools_left_src" || "$default_right_src" != "$right_manager_src" || "$default_right_src" != "$all_tools_right_src" || "$default_left_name" != "$left_manager_name" || "$default_left_name" != "$all_tools_left_name" || "$default_right_name" != "$right_manager_name" || "$default_right_name" != "$all_tools_right_name" || "$default_width" != "$left_manager_width" || "$default_width" != "$right_manager_width" || "$default_width" != "$all_tools_left_width" || "$default_width" != "$all_tools_right_width" || "$default_height" != "$left_manager_height" || "$default_height" != "$right_manager_height" || "$default_height" != "$all_tools_left_height" || "$default_height" != "$all_tools_right_height" ]]; then
    echo "vFramer defaults are out of sync:" >&2
    echo "  defaults.env left:  $default_left_name $default_left_src ${default_width}x${default_height}" >&2
    echo "  defaults.env right: $default_right_name $default_right_src ${default_width}x${default_height}" >&2
    echo "  04-vframer-left.xml:  $left_manager_name $left_manager_src ${left_manager_width}x${left_manager_height}" >&2
    echo "  04-vframer-right.xml: $right_manager_name $right_manager_src ${right_manager_width}x${right_manager_height}" >&2
    echo "  05-all-tools.xml left:  $all_tools_left_name $all_tools_left_src ${all_tools_left_width}x${all_tools_left_height}" >&2
    echo "  05-all-tools.xml right: $all_tools_right_name $all_tools_right_src ${all_tools_right_width}x${all_tools_right_height}" >&2
    exit 1
fi

echo "Repo launch definitions look consistent."
