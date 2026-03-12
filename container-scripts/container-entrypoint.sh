#!/usr/bin/env bash
set -euo pipefail

RUNTIME_USER="robotology"
TARGET_UID="${LOCAL_UID:-1000}"
TARGET_GID="${LOCAL_GID:-1000}"

if [[ ! "$TARGET_UID" =~ ^[0-9]+$ ]] || [[ ! "$TARGET_GID" =~ ^[0-9]+$ ]]; then
    echo "LOCAL_UID and LOCAL_GID must be numeric." >&2
    exit 1
fi

TARGET_GROUP_NAME="$RUNTIME_USER"

if getent group "$TARGET_GID" >/dev/null 2>&1; then
    TARGET_GROUP_NAME="$(getent group "$TARGET_GID" | cut -d: -f1)"
else
    CURRENT_GID="$(id -g "$RUNTIME_USER")"
    if [[ "$CURRENT_GID" != "$TARGET_GID" ]]; then
        groupmod -o -g "$TARGET_GID" "$RUNTIME_USER"
    fi
fi

CURRENT_GID="$(id -g "$RUNTIME_USER")"
if [[ "$CURRENT_GID" != "$TARGET_GID" ]]; then
    usermod -g "$TARGET_GROUP_NAME" "$RUNTIME_USER"
fi

if getent passwd "$TARGET_UID" >/dev/null 2>&1; then
    TARGET_USER_NAME="$(getent passwd "$TARGET_UID" | cut -d: -f1)"
else
    CURRENT_UID="$(id -u "$RUNTIME_USER")"
    if [[ "$CURRENT_UID" != "$TARGET_UID" ]]; then
        usermod -o -u "$TARGET_UID" "$RUNTIME_USER"
    fi
    TARGET_USER_NAME="$RUNTIME_USER"
fi

TARGET_HOME="$(getent passwd "$TARGET_USER_NAME" | cut -d: -f6)"
mkdir -p "$TARGET_HOME"
chown "$TARGET_UID":"$TARGET_GID" "$TARGET_HOME"

export HOME="$TARGET_HOME"
export USER="$TARGET_USER_NAME"
export LOGNAME="$TARGET_USER_NAME"

exec gosu "$TARGET_USER_NAME" "$@"
