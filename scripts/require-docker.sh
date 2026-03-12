#!/usr/bin/env bash
set -euo pipefail

if docker info >/dev/null 2>&1; then
    exit 0
fi

output="$(docker info 2>&1 || true)"

echo "Docker is installed, but the daemon is not reachable." >&2

if grep -qi "permission denied" <<<"$output"; then
    cat >&2 <<'EOF'
Your user can see the Docker client, but it cannot talk to the Docker socket.
Add your user to the docker group, then refresh your session:

  sudo usermod -aG docker $USER
  newgrp docker
  docker info
EOF
    exit 1
fi

if grep -qi "no such file or directory" <<<"$output"; then
    if dpkg -s docker-desktop >/dev/null 2>&1 && ! dpkg -s docker-ce >/dev/null 2>&1; then
        cat >&2 <<'EOF'
Docker Desktop is installed, but its backend is not running.

Start it with:
  systemctl --user start docker-desktop

Then verify it with:
  docker info

For this robotics setup, native Docker Engine is usually a better long-term fit
than Docker Desktop on Linux because USB access and host networking are simpler.
EOF
    else
        cat >&2 <<'EOF'
The Docker daemon socket does not exist, which usually means the daemon is not
running.

On a native Docker Engine install, the usual fix is:
  sudo systemctl start docker
  docker info
EOF
    fi
    exit 1
fi

echo "$output" >&2
exit 1
