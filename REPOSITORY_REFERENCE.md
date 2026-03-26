# Repository Reference

This document is the file-by-file operational reference for the repository. It explains what the runnable scripts, environment files, build files, `yarpmanager` definitions, and automation files do.

Conventions used below:

- `public script`: intended to be run directly by a user or operator
- `internal script`: called by another script; usually not the main entrypoint
- `container script`: copied into the Docker image and run inside the container
- `config file`: affects build/runtime behavior but is not itself executable

## Documentation Files

| Path | What it does |
| --- | --- |
| [README.md](README.md) | Front page for the repository. It routes readers to the user guide or developer guide. |
| [USER_README.md](USER_README.md) | Operator-facing guide: setup, quickstart, normal workflows, demos, troubleshooting. |
| [DEVELOPER_README.md](DEVELOPER_README.md) | Maintainer-facing guide: architecture, launch model, build/distribution details, and GHCR workflow notes. |
| [REPOSITORY_REFERENCE.md](REPOSITORY_REFERENCE.md) | This file. It is the inventory/reference for scripts, configs, and automation. |

## Build And Runtime Files

| Path | Type | What it does |
| --- | --- | --- |
| [Dockerfile](Dockerfile) | config file | Builds the Ubuntu-based workstation image. Installs system dependencies, Prophesee/Metavision SDK, YCM, YARP, `event-driven`, the `robotology` user, and the in-container helper scripts. |
| [compose.yaml](compose.yaml) | config file | Defines the single `robotology` container. Builds from the Dockerfile, uses host networking, mounts the project and data directories, forwards X11, and keeps the container alive with `sleep infinity`. |
| [`.env.example`](.env.example) | config file | Template for the local environment file. Sets the display, host data path, build versions, and default base image. |
| [`.env`](.env) | config file | Local machine-specific copy of `.env.example`. Docker Compose reads this automatically when scripts call `docker compose`. |

## Public Host Scripts

These are the main scripts people are expected to run from the host machine.

| Path | What it does |
| --- | --- |
| [scripts/build.sh](scripts/build.sh) | Runs `docker compose build` after verifying Docker is reachable. This is the normal image-build entrypoint. |
| [scripts/start-workstation.sh](scripts/start-workstation.sh) | Starts the container if needed, ensures `yarpserver` is up, and exits once the workstation is ready. |
| [scripts/start-yarpserver.sh](scripts/start-yarpserver.sh) | Ensures `yarpserver` is running inside the already-started container. It is safe to call repeatedly. |
| [scripts/status.sh](scripts/status.sh) | Shows the Compose service status and reports whether the YARP name server is currently detectable inside the container. |
| [scripts/show-versions.sh](scripts/show-versions.sh) | Prints the configured build refs and, when the container is running, the installed `YARP` and `event-driven` versions from inside the image. |
| [scripts/stop-workstation.sh](scripts/stop-workstation.sh) | Stops and removes the Compose-managed container with `docker compose down`. |
| [scripts/shell.sh](scripts/shell.sh) | Opens an interactive shell inside the running container as the `robotology` user. |
| [scripts/list-data.sh](scripts/list-data.sh) | Prints the mounted container data path and lists the contents of `/workspace/data`. Useful for checking that the host dataset mount is correct. |
| [scripts/open-manager.sh](scripts/open-manager.sh) | Launches `yarpmanager` from the container using the repo’s `ymanager.ini`. |
| [scripts/open-dataplayer.sh](scripts/open-dataplayer.sh) | Launches the generic `yarpdataplayer` GUI from the container. |
| [scripts/open-yarpview.sh](scripts/open-yarpview.sh) | Launches the generic `yarpview` GUI from the container. |
| [scripts/open-yarpscope.sh](scripts/open-yarpscope.sh) | Launches the generic `yarpscope` GUI from the container. |
| [scripts/open-vframer.sh](scripts/open-vframer.sh) | Launches `vFramer` through the script-based launcher. Accepts `left` or `right` and still reads defaults from `yarpmanager/defaults.env`. |
| [scripts/demo-ballbalance.sh](scripts/demo-ballbalance.sh) | Shared BallBalance demo launcher. Accepts `moving` or `stationary`, ensures X11 and `yarpserver`, then starts the internal coordinated demo launcher. |
| [scripts/demo-ballbalance-moving.sh](scripts/demo-ballbalance-moving.sh) | Thin wrapper that runs `demo-ballbalance.sh moving`. |
| [scripts/demo-ballbalance-stationary.sh](scripts/demo-ballbalance-stationary.sh) | Thin wrapper that runs `demo-ballbalance.sh stationary`. |
| [scripts/stop-demo.sh](scripts/stop-demo.sh) | Stops matching GUI/demo processes inside the container (`yarpdataplayer`, `yarpview`, `yarpscope`, `vFramer`) and cleans stale YARP ports. |
| [scripts/workstation-menu.sh](scripts/workstation-menu.sh) | Text menu that exposes the main public scripts in a guided interactive form. |
| [scripts/verify-repo.sh](scripts/verify-repo.sh) | Developer consistency check. Validates `yarpmanager` XML, ensures the XML apps are not shelling out through `bash`, and checks that the left/right `vFramer` source, name, width, and height defaults stay aligned. |

## Shared And Internal Host Scripts

These scripts support the public entrypoints. Most are not intended as the first thing a normal user runs.

| Path | What it does |
| --- | --- |
| [scripts/common.sh](scripts/common.sh) | Shared function library for the host scripts. Wraps `docker compose`, handles Docker checks, X11 access, exec modes, container startup, and `yarpserver` detection. |
| [scripts/require-docker.sh](scripts/require-docker.sh) | Checks whether Docker is reachable and prints tailored troubleshooting guidance for common failure modes such as socket permissions or a stopped daemon. |
| [scripts/internal/launch-ballbalance-demo.sh](scripts/internal/launch-ballbalance-demo.sh) | Coordinates the script-based BallBalance demo startup. Starts the dataplayer first, then launches the viewers, tracks child PIDs, and cleans them up on exit. |
| [scripts/internal/launch-ballbalance-tool.sh](scripts/internal/launch-ballbalance-tool.sh) | Implements the script-based BallBalance tool logic for one tool at a time. Chooses the dataset, waits for ports, performs YARP connections, and handles cleanup/retry behavior. |
| [scripts/internal/launch-vframer.sh](scripts/internal/launch-vframer.sh) | Reads `yarpmanager/defaults.env`, resolves the requested side-specific source, YARP name, width, and height, and starts `vFramer`. |

## Container Scripts

These are copied into the image and used inside the container.

| Path | What it does |
| --- | --- |
| [container-scripts/container-entrypoint.sh](container-scripts/container-entrypoint.sh) | Docker entrypoint. Remaps the in-container `robotology` user/group to the host UID/GID, sets the runtime user environment, and drops privileges with `gosu`. This avoids bind-mount ownership issues. |
| [container-scripts/start-yarpserver.sh](container-scripts/start-yarpserver.sh) | In-container helper that starts `yarpserver` and logs to `/tmp/yarpserver.log`. It is invoked by the host-side startup helpers. |

## yarpmanager Files

These files define what `yarpmanager` sees and how it behaves.

| Path | What it does |
| --- | --- |
| [yarpmanager/ymanager.ini](yarpmanager/ymanager.ini) | Main `yarpmanager` configuration. Points to the applications/modules/resources folders and enables `auto_connect` so the BallBalance app-defined connections can happen automatically. |
| [yarpmanager/defaults.env](yarpmanager/defaults.env) | Script-only defaults for the `vFramer` launcher, including the left/right source ports, unique YARP names, and shared window size. This does not drive the direct-launch `yarpmanager` XML by itself. |
| [yarpmanager/applications/01-yarp-data-player.xml](yarpmanager/applications/01-yarp-data-player.xml) | `yarpmanager` application definition for the generic `yarpdataplayer` GUI. |
| [yarpmanager/applications/02-yarp-scope.xml](yarpmanager/applications/02-yarp-scope.xml) | `yarpmanager` application definition for the generic `yarpscope` GUI. |
| [yarpmanager/applications/03-yarp-view.xml](yarpmanager/applications/03-yarp-view.xml) | `yarpmanager` application definition for the generic `yarpview` GUI. |
| [yarpmanager/applications/04-vframer-left.xml](yarpmanager/applications/04-vframer-left.xml) | `yarpmanager` application definition for the generic left `vFramer` GUI, using `/zynqGrabber/left/AE:o`, the unique name `/vframer/left`, and a `640x480` window. |
| [yarpmanager/applications/04-vframer-right.xml](yarpmanager/applications/04-vframer-right.xml) | `yarpmanager` application definition for the generic right `vFramer` GUI, using `/zynqGrabber/right/AE:o`, the unique name `/vframer/right`, and a `640x480` window. |
| [yarpmanager/applications/05-all-tools.xml](yarpmanager/applications/05-all-tools.xml) | `yarpmanager` application that launches the generic tools together, including both `vFramer` viewers. It does not auto-load a dataset. |
| [yarpmanager/applications/06-ballbalance-moving-demo.xml](yarpmanager/applications/06-ballbalance-moving-demo.xml) | Direct-launch `yarpmanager` application for the moving BallBalance demo. Loads `test_moving`, declares port dependencies, and connects the RGB stream to `yarpview`. |
| [yarpmanager/applications/07-ballbalance-stationary-demo.xml](yarpmanager/applications/07-ballbalance-stationary-demo.xml) | Direct-launch `yarpmanager` application for the stationary BallBalance demo. Loads `test_stationary`, declares port dependencies, and connects the RGB stream to `yarpview`. |
| [yarpmanager/modules/.gitkeep](yarpmanager/modules/.gitkeep) | Placeholder to keep the modules directory in Git even though this repo does not currently define custom module XML files. |
| [yarpmanager/resources/.gitkeep](yarpmanager/resources/.gitkeep) | Placeholder to keep the resources directory in Git even though this repo does not currently define custom resource files. |

## GitHub Automation

| Path | What it does |
| --- | --- |
| [.github/workflows/test-image-build.yml](.github/workflows/test-image-build.yml) | GitHub Actions build-only workflow. It builds the Docker image on GitHub-hosted runners, loads it locally on the runner, and runs a lightweight smoke test without pushing to GHCR. |
| [.github/workflows/publish-image.yml](.github/workflows/publish-image.yml) | GitHub Actions workflow that builds the Docker image on GitHub-hosted runners and pushes it to GitHub Container Registry (`ghcr.io`). It triggers on manual dispatch, pushes to `main`/`master`, and version tags like `v*`. After pushing, it writes a workflow summary with the published image tags and a reminder that GHCR package visibility is managed in GitHub package settings. |

## How The Pieces Fit Together

The typical operator flow is:

1. Build the image with [scripts/build.sh](scripts/build.sh).
2. Start the workstation with [scripts/start-workstation.sh](scripts/start-workstation.sh).
3. Launch tools through either [scripts/workstation-menu.sh](scripts/workstation-menu.sh), the other public scripts in [scripts](scripts/), or the `yarpmanager` apps defined in [yarpmanager/applications](yarpmanager/applications/).
4. Stop demo tools with [scripts/stop-demo.sh](scripts/stop-demo.sh) or stop the full workstation with [scripts/stop-workstation.sh](scripts/stop-workstation.sh).

The key implementation split is:

- public entrypoints live in [scripts](scripts/)
- shared logic lives in [scripts/common.sh](scripts/common.sh)
- script-only orchestration lives in [scripts/internal](scripts/internal/)
- in-container runtime helpers live in [container-scripts](container-scripts/)
- direct-launch `yarpmanager` behavior lives in [yarpmanager/applications](yarpmanager/applications/)
