# Yarpinator

This project provides a Dockerized `YARP` + `event-driven` workstation with:

- a reusable Ubuntu-based image
- GUI tool support on the host desktop
- YARP networking through the host network
- a bind-mounted host data folder at a fixed container path
- helper scripts for non-expert users
- `yarpmanager` applications for the same tools and demos

The current local setup on this machine mounts:

```text
/home/bmaacaron-iit.local/Documents/Datasets/2026_PRIMI/
```

into the container as:

```text
/workspace/data
```

That means the BallBalance dataset is available inside the container at:

```text
/workspace/data/BallBalance
```

## Installation and Setup

This section covers the installation and setup steps for users who want to run the workstation on their own machine. Currently it is tailored for Ubuntu, but the Docker-based approach should be portable to other Linux distributions with minimal adjustments.

### Required on the host

- Docker Engine
- Docker Compose plugin
- a Desktop session with X11 / XWayland available through `DISPLAY`
- the `xhost` command - Ubuntu users should install the `x11-xserver-utils` package if it is missing
- `git` if they still need to clone or update the repository

### Exact Docker packages on Ubuntu

For this project, the recommended host-side Docker install is native Docker Engine, not Docker Desktop.

The key packages are:

- `docker-ce`
- `docker-ce-cli`
- `containerd.io`
- `docker-buildx-plugin`
- `docker-compose-plugin`

If `xhost` is missing, install:

- `x11-xserver-utils`

### What users do not need to install on the host

These are already installed inside the Docker image:

- `YARP`
- `event-driven`
- `yarpmanager`
- `yarpview`
- `yarpscope`
- `yarpdataplayer`
- `vFramer`

### Official install references

- Docker Engine on Ubuntu:
  - https://docs.docker.com/engine/install/ubuntu/
- Docker Compose plugin on Linux:
  - https://docs.docker.com/compose/install/linux/

### Minimal Ubuntu install flow

Docker's official Ubuntu setup ends with these Docker packages installed:

```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

For normal non-root use:

```bash
sudo usermod -aG docker $USER
newgrp docker
docker info
docker compose version
```

If `xhost` is missing:

```bash
sudo apt install x11-xserver-utils
```

## Quickstart

This is the shortest path from zero to a running demo.

1. Open a terminal in the project root:

```bash
cd ~/Documents/Dockers/YarpinatorDocker
```

2. Build the Docker image once:

```bash
./scripts/build.sh
```

3. Start the workstation:

```bash
./scripts/start-workstation.sh
```

4. Open the operator menu:

```bash
./scripts/workstation-menu.sh
```

5. In the menu, choose:

- `Open yarpmanager`

6. Inside `yarpmanager`, launch one of:

- `BallBalance Moving Demo`
- `BallBalance Stationary Demo`

What happens next:

- `yarpdataplayer` loads the selected dataset
- `yarpview` opens for RGB
- `yarpscope` opens for right-arm encoders
- `vFramer` opens for the event stream

## Current State

The current project state is:

- Docker image build works through `./scripts/build.sh`
- container startup works through `./scripts/start-workstation.sh`
- `yarpserver` is automatically detected and started if needed
- GUI tools launch from the container onto the host desktop
- `yarpmanager` is configured with generic tools and BallBalance demos
- BallBalance `moving` and `stationary` demos both work
- BallBalance demo startup cleans previous demo tools before launching a new replay
- user data is exposed read-only at `/workspace/data`

Important current behavior:

- the BallBalance demos use `yarpdataplayer` replay outputs under the fixed prefix `/yarpdataplayer/...`
- starting a BallBalance demo stops existing `yarpdataplayer`, `yarpview`, `yarpscope`, and `vFramer` processes inside the container before launching the new session
- `All Tools` in `yarpmanager` opens the generic tools, but it does not auto-load a dataset
- the BallBalance demos are the auto-loaded workflows

## Core Concepts

`Docker image`
: the built environment defined by [Dockerfile](/home/bmaacaron-iit.local/Documents/Dockers/YarpinatorDocker/Dockerfile)

`Docker container`
: the running instance of that image

`docker compose`
: the runtime definition in [compose.yaml](/home/bmaacaron-iit.local/Documents/Dockers/YarpinatorDocker/compose.yaml)

`bind mount`
: a host folder exposed directly inside the container without copying it into the image

`yarpserver`
: the YARP name server; other YARP tools depend on it to find ports

`YARP port`
: a named communication endpoint such as `/yarpdataplayer/grabber`

`yarpmanager`
: a GUI launcher/orchestrator for named applications made of one or more modules

## How This Stack Works

The runtime defined in [compose.yaml](/home/bmaacaron-iit.local/Documents/Dockers/YarpinatorDocker/compose.yaml) does five important things:

1. builds and runs a single `robotology` container
2. shares the host network with `network_mode: host`
3. mounts the project at `/workspace/project`
4. mounts the user data folder at `/workspace/data`
5. forwards X11 so GUI programs from the container can open on the host desktop

The helper layer in [common.sh](/home/bmaacaron-iit.local/Documents/Dockers/YarpinatorDocker/scripts/common.sh) standardizes:

- Docker availability checks
- Compose calls with the current host `UID` and `GID`
- execution as the `robotology` user inside the container
- `yarpserver` startup and detection
- GUI launcher behavior

The container entrypoint in [container-entrypoint.sh](/home/bmaacaron-iit.local/Documents/Dockers/YarpinatorDocker/container-scripts/container-entrypoint.sh) remaps the internal `robotology` user to the current host user’s numeric `UID` and `GID` at container start. That helps avoid file ownership problems on bind-mounted folders.

## Configuration

The operator-facing configuration lives in:

- [`.env.example`](/home/bmaacaron-iit.local/Documents/Dockers/YarpinatorDocker/.env.example)
- [`.env`](/home/bmaacaron-iit.local/Documents/Dockers/YarpinatorDocker/.env)

The most important values are:

- `DISPLAY`
  - host display used for GUI forwarding
- `HOST_DATA_PATH`
  - host folder mounted into the container as `/workspace/data`
- `YCM_VERSION`
- `YARP_VERSION`
- `ED_VERSION`

For a new machine:

1. copy `.env.example` to `.env`
2. set `HOST_DATA_PATH` to the host folder containing the datasets
3. keep `DISPLAY` aligned with the active desktop session

## Paths You Should Remember

On the host:

- project root: `/home/bmaacaron-iit.local/Documents/Dockers/Yarpinator`
- current dataset root: `/home/bmaacaron-iit.local/Documents/Datasets/2026_PRIMI/`

Inside the container:

- project root: `/workspace/project`
- user data root: `/workspace/data`
- BallBalance dataset: `/workspace/data/BallBalance`

## CLI Workflow

This is the simplest workflow if you want operator-style commands without entering the container manually.

### Build

```bash
./scripts/build.sh
```

Builds the Docker image from [Dockerfile](/home/bmaacaron-iit.local/Documents/Dockers/YarpinatorDocker/Dockerfile).

### Start the workstation

```bash
./scripts/start-workstation.sh
```

What it does:

- applies the current Compose config
- starts the container if needed
- starts `yarpserver` if needed
- verifies that `yarpserver` is detectable

### Check status

```bash
./scripts/status.sh
```

Shows:

- container status
- whether the YARP name server is detectable

### Inspect mounted data

```bash
./scripts/list-data.sh
```

Lists the container-visible contents of `/workspace/data`.

### Open the generic tools

```bash
./scripts/open-manager.sh
./scripts/open-yarpview.sh
./scripts/open-yarpscope.sh
./scripts/open-vframer.sh
./scripts/open-dataplayer.sh
```

Use these when you want the tools themselves but not an auto-loaded dataset workflow.

### Run the BallBalance demos

```bash
./scripts/demo-ballbalance-moving.sh
./scripts/demo-ballbalance-stationary.sh
```

Each demo:

- ensures the workstation is up
- stops old replay/viewer demo tools
- starts `yarpdataplayer`
- launches `yarpview`
- launches `yarpscope`
- launches `vFramer`

### Stop only the demo tools

```bash
./scripts/stop-demo.sh
```

This stops:

- `yarpdataplayer`
- `yarpview`
- `yarpscope`
- `vFramer`

It leaves the container and `yarpserver` running.
If the container is already stopped, it exits cleanly and reports that there is nothing to stop.

### Stop the whole workstation

```bash
./scripts/stop-workstation.sh
```

This stops the whole Docker container.

## yarpmanager Workflow

Launch the manager with:

```bash
./scripts/open-manager.sh
```

The manager loads its local applications from:

- [ymanager.ini](/home/bmaacaron-iit.local/Documents/Dockers/YarpinatorDocker/yarpmanager/ymanager.ini)
- [applications/](/home/bmaacaron-iit.local/Documents/Dockers/YarpinatorDocker/yarpmanager/applications)

The currently configured applications are:

- `YARP Data Player`
- `YARP Scope`
- `YARP View`
- `VFramer`
- `All Tools`
- `BallBalance Moving Demo`
- `BallBalance Stationary Demo`

What they mean:

- `YARP Data Player`
  - opens the generic `yarpdataplayer` GUI
- `YARP Scope`
  - opens the generic `yarpscope` GUI
- `YARP View`
  - opens the generic `yarpview` GUI
- `VFramer`
  - opens `vFramer` using the default source in [defaults.env](/home/bmaacaron-iit.local/Documents/Dockers/YarpinatorDocker/yarpmanager/defaults.env)
- `All Tools`
  - opens the four generic tools together
  - does not auto-load a dataset
- `BallBalance Moving Demo`
  - auto-loads `test_moving`
  - opens the three matching viewers
  - uses one coordinated launcher internally so the viewers do not race each other during startup
- `BallBalance Stationary Demo`
  - auto-loads `test_stationary`
  - opens the three matching viewers
  - uses one coordinated launcher internally so the viewers do not race each other during startup

If you want to stop a manager-launched BallBalance session from the CLI, use:

```bash
./scripts/stop-demo.sh
```

## Shell / YARP Workflow

Use this path if you want manual control.

Open a shell inside the running container:

```bash
./scripts/shell.sh
```

Useful commands inside the container:

```bash
yarp check
yarp detect
yarp name list
```

What they do:

- `yarp check`
  - basic YARP sanity test
- `yarp detect`
  - checks whether `yarpserver` is reachable
- `yarp name list`
  - lists the registered YARP ports known to the name server

Manual BallBalance replay inside the container uses these effective sources:

- dataplayer session root:
  - `/workspace/data/BallBalance/test_moving`
  - or `/workspace/data/BallBalance/test_stationary`
- RGB replay port:
  - `/yarpdataplayer/grabber`
- right arm encoder replay port:
  - `/yarpdataplayer/icub/right_arm/state:o`
- event replay port:
  - `/yarpdataplayer/zynqGrabber/left/AE:o`

That means:

- `yarpview` should receive `/yarpdataplayer/grabber`
- `yarpscope` should receive `/yarpdataplayer/icub/right_arm/state:o`
- `vFramer` should use `/yarpdataplayer/zynqGrabber/left/AE:o`

## BallBalance Tool Associations

The current BallBalance associations are:

| Tool | Dataset / source | Purpose |
| --- | --- | --- |
| `yarpdataplayer` | `/workspace/data/BallBalance/test_moving` or `/workspace/data/BallBalance/test_stationary` | replays the recorded session |
| `yarpview` | `/yarpdataplayer/grabber` | shows the RGB camera stream |
| `yarpscope` | `/yarpdataplayer/icub/right_arm/state:o` | plots the right-arm encoder stream |
| `vFramer` | `/yarpdataplayer/zynqGrabber/left/AE:o` | visualizes the event-camera stream |

## Menu Workflow

For the simplest interactive operator experience:

```bash
./scripts/workstation-menu.sh
```

The menu currently exposes:

- workstation start
- status
- `yarpmanager`
- BallBalance moving demo
- BallBalance stationary demo
- each individual GUI tool
- stop demo only
- list data
- shell
- stop workstation

## Stopping Things

There are three stop levels:

### Stop only the BallBalance / GUI demo tools

```bash
./scripts/stop-demo.sh
```

### Stop the whole container

```bash
./scripts/stop-workstation.sh
```

### Stop from inside yarpmanager

Use the manager’s stop controls for the running application.

## Troubleshooting

### Docker socket / daemon problems

If a command complains about `/var/run/docker.sock`, run:

```bash
docker info
```

If that fails because the daemon is down:

```bash
sudo systemctl start docker
docker info
```

### No GUI window appears

Check:

- `DISPLAY` is set correctly in `.env`
- you are running from a desktop session
- the X11 socket mount exists at `/tmp/.X11-unix`

### `vFramer` opens but needs a different source

Edit:

[defaults.env](/home/bmaacaron-iit.local/Documents/Dockers/YarpinatorDocker/yarpmanager/defaults.env)

Change:

```bash
VFRAMER_SRC=/event_camera/events:o
```

The generic `VFramer` launcher and the generic `All Tools` manager app both use that value.

### Data folder changed on the host

Update:

[`.env`](/home/bmaacaron-iit.local/Documents/Dockers/YarpinatorDocker/.env)

Then re-apply the runtime:

```bash
./scripts/start-workstation.sh
```

## Known Limits

- the current image assumes the Prophesee / Metavision SDK path from the upstream `event-driven` Dockerfile
- the exact live camera vendor is still a hardware-specific unknown
- BallBalance demos are opinionated workflows; they intentionally clean old replay/viewer processes before starting a new session
- `All Tools` is generic and not dataset-aware

## Task Options Table

This table compares the available ways to do the same task.

| Task | Simplest CLI | Menu | yarpmanager | Manual shell / YARP |
| --- | --- | --- | --- | --- |
| Build image | `./scripts/build.sh` | not exposed | not applicable | `docker compose build` |
| Start container + `yarpserver` | `./scripts/start-workstation.sh` | `Start workstation` | not the primary path | `docker compose up -d` then `yarpserver` |
| Check runtime status | `./scripts/status.sh` | `Show status` | visual only after launch | `docker compose ps` and `yarp detect` |
| Inspect mounted data | `./scripts/list-data.sh` | `List mounted data` | not applicable | `ls /workspace/data` |
| Open generic tool launcher | `./scripts/open-manager.sh` | `Open yarpmanager` | `yarpmanager` itself | `yarpmanager --from /workspace/project/yarpmanager/ymanager.ini` |
| Open generic `yarpdataplayer` | `./scripts/open-dataplayer.sh` | `Open yarpdataplayer` | `YARP Data Player` | `yarpdataplayer` |
| Open generic `yarpview` | `./scripts/open-yarpview.sh` | `Open yarpview` | `YARP View` | `yarpview` |
| Open generic `yarpscope` | `./scripts/open-yarpscope.sh` | `Open yarpscope` | `YARP Scope` | `yarpscope` |
| Open generic `vFramer` | `./scripts/open-vframer.sh` | `Open vFramer` | `VFramer` | `vFramer --src ...` |
| Open all generic tools | not exposed directly | not exposed directly | `All Tools` | start each tool manually |
| Run BallBalance moving demo | `./scripts/demo-ballbalance-moving.sh` | `Run BallBalance moving demo` | `BallBalance Moving Demo` | manual replay + manual viewer launch |
| Run BallBalance stationary demo | `./scripts/demo-ballbalance-stationary.sh` | `Run BallBalance stationary demo` | `BallBalance Stationary Demo` | manual replay + manual viewer launch |
| Stop demo tools only | `./scripts/stop-demo.sh` | `Stop demo tools only` | stop app in manager | `pkill ...` then `yarp clean --timeout 1` |
| Stop whole workstation | `./scripts/stop-workstation.sh` | `Stop workstation` | close tools, then stop container separately | `docker compose down` |
