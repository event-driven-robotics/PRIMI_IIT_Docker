# User README

This guide is for operators and users who want to run the workstation, open the tools, and launch demos.

## What This Project Provides

- one Dockerized `YARP` + `event-driven` workstation
- GUI forwarding from the container to the host desktop
- helper scripts for common tasks
- `yarpmanager` applications for the generic tools and BallBalance demos

Inside the container, user data is mounted at:

```text
/workspace/data
```

The BallBalance dataset is expected at:

```text
/workspace/data/BallBalance
```

## Requirements

Required on the host:

- Docker Engine
- Docker Compose plugin
- a desktop session with X11 or XWayland available through `DISPLAY`
- the `xhost` command
- `git` if you still need to clone or update the repository

Recommended Ubuntu Docker packages:

- `docker-ce`
- `docker-ce-cli`
- `containerd.io`
- `docker-buildx-plugin`
- `docker-compose-plugin`

If `xhost` is missing, install:

- `x11-xserver-utils`

You do not need to install these on the host:

- `YARP`
- `event-driven`
- `yarpmanager`
- `yarpview`
- `yarpscope`
- `yarpdataplayer`
- `vFramer`

Those are installed inside the Docker image from [Dockerfile](Dockerfile).

## First-Time Setup

1. Copy [`.env.example`](.env.example) to [`.env`](.env).
2. Set `HOST_DATA_PATH` to the host folder that should appear in the container as `/workspace/data`.
3. Make sure `DISPLAY` matches the active desktop session.

## Quickstart

1. Open a terminal in the project root:

```bash
cd ~/Documents/Dockers/PRIMI_IIT_Docker
```

2. Build the image once:

```bash
./scripts/build.sh
```

If your repository owner has already published a GHCR image for this project, they may give you a pull-first path instead of a local build. This guide keeps the local build as the default operator workflow.

Pull-first alternative:

```bash
docker pull ghcr.io/<owner>/<repo>:latest
```

If you use that path, make sure your maintainer also tells you how they want [compose.yaml](compose.yaml) to consume the pulled image on your machine.

3. Start the workstation:

```bash
./scripts/start-workstation.sh
```

4. Open the operator menu:

```bash
./scripts/workstation-menu.sh
```

5. In the menu, choose `Open yarpmanager`.

6. Inside `yarpmanager`, launch one of:

- `BallBalance Moving Demo`
- `BallBalance Stationary Demo`

What opens:

- `yarpdataplayer`
- `yarpview`
- `yarpscope`
- `vFramer`

## Main Ways To Use It

### Menu Workflow

For the simplest interactive operator flow:

```bash
./scripts/workstation-menu.sh
```

The menu exposes:

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

### CLI Workflow

Use this if you want script-based entrypoints without entering the container manually.

Build:

```bash
./scripts/build.sh
```

Start workstation:

```bash
./scripts/start-workstation.sh
```

Check status:

```bash
./scripts/status.sh
```

List mounted data:

```bash
./scripts/list-data.sh
```

Open generic tools:

```bash
./scripts/open-manager.sh
./scripts/open-yarpview.sh
./scripts/open-yarpscope.sh
./scripts/open-vframer.sh
./scripts/open-dataplayer.sh
```

Run the BallBalance demos:

```bash
./scripts/demo-ballbalance-moving.sh
./scripts/demo-ballbalance-stationary.sh
```

Stop the matching GUI demo tools:

```bash
./scripts/stop-demo.sh
```

Stop the whole workstation:

```bash
./scripts/stop-workstation.sh
```

### yarpmanager Workflow

Launch the manager with:

```bash
./scripts/open-manager.sh
```

Configured applications:

- `YARP Data Player`
- `YARP Scope`
- `YARP View`
- `VFramer`
- `All Tools`
- `BallBalance Moving Demo`
- `BallBalance Stationary Demo`

What they mean:

- `YARP Data Player`: opens the generic `yarpdataplayer` GUI
- `YARP Scope`: opens the generic `yarpscope` GUI
- `YARP View`: opens the generic `yarpview` GUI
- `VFramer`: opens `vFramer` using the default source configured in [04-vframer.xml](yarpmanager/applications/04-vframer.xml)
- `All Tools`: opens the four generic tools together and does not auto-load a dataset
- `BallBalance Moving Demo`: auto-loads `test_moving` and opens the three matching viewers directly in `yarpmanager`
- `BallBalance Stationary Demo`: auto-loads `test_stationary` and opens the three matching viewers directly in `yarpmanager`

If you want to stop a manager-launched BallBalance session from the CLI, use:

```bash
./scripts/stop-demo.sh
```

### Manual Shell / YARP Workflow

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

## Important Behavior

- BallBalance demos use `yarpdataplayer` replay outputs under `/yarpdataplayer/...`
- scripted BallBalance demos clean up matching old GUI/demo tools before launching a new session
- manager-launched BallBalance demos run tools directly and do not pre-clean old GUI/demo tools
- `All Tools` is generic and does not auto-load a dataset

## BallBalance Tool Associations

| Tool | Dataset / source | Purpose |
| --- | --- | --- |
| `yarpdataplayer` | `/workspace/data/BallBalance/test_moving` or `/workspace/data/BallBalance/test_stationary` | replays the recorded session |
| `yarpview` | `/yarpdataplayer/grabber` | shows the RGB camera stream |
| `yarpscope` | `/yarpdataplayer/icub/right_arm/state:o` | plots the right-arm encoder stream |
| `vFramer` | `/yarpdataplayer/zynqGrabber/left/AE:o` | visualizes the event-camera stream |

## Troubleshooting

Docker socket / daemon problems:

```bash
docker info
```

If the daemon is down:

```bash
sudo systemctl start docker
docker info
```

If no GUI window appears, check:

- `DISPLAY` is set correctly in [`.env`](.env)
- you are running from a desktop session
- the X11 socket mount exists at `/tmp/.X11-unix`

If the `yarpmanager` `VFramer` application needs a different default source, edit [04-vframer.xml](yarpmanager/applications/04-vframer.xml):

```xml
<parameters>--src /zynqGrabber/left/AE:o</parameters>
```

If the script-based `./scripts/open-vframer.sh` launcher needs a different default source, edit [defaults.env](yarpmanager/defaults.env):

```bash
VFRAMER_SRC=/zynqGrabber/left/AE:o
```

If the host data folder changes, update [`.env`](.env) and re-apply the runtime:

```bash
./scripts/start-workstation.sh
```
