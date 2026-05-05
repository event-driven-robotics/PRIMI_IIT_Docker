# User README

This guide is for operators and users who want to run the workstation, open the tools, and launch demos.

## What This Project Provides

- one Dockerized `YARP` + `event-driven` workstation
- GUI forwarding from the container to the host desktop
- helper scripts for common tasks
- `yarpmanager` applications for the generic tools and the BallBalance demo

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

Check the configured build refs and the currently installed container versions:

```bash
./scripts/show-versions.sh
```

The default image omits Prophesee's Metavision SDK. That is intentional. The documented BallBalance and generic GUI workflows in this repository use recorded YARP streams and do not need the SDK.

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

5. In the menu, choose `Run BallBalance demo`.

What opens:

- `yarpdataplayer`
- `yarpscope`
- `vFramer Left`
- `vFramer Right`

If the selected trial is mounted with an empty `rgb/data.log`, `yarpview` is skipped.
That recording's `rgb/data.log` is empty, and `yarpdataplayer` crashes on it unless the RGB stream is omitted.

The menu demo loads:

- `/workspace/data/BallBalance/<BALLBALANCE_DEMO_TRIAL>`

Change the selected BallBalance recording in [yarpmanager/defaults.env](yarpmanager/defaults.env):

```bash
BALLBALANCE_DEMO_TRIAL=trial_2
```

## Optional Metavision SDK

This repository omits Metavision SDK by default.

What we need it for:

- live Prophesee event-camera integration through the upstream `event-driven` Prophesee bridge tooling such as `atis3-bridge`
- development work that specifically depends on Prophesee's proprietary SDK packages rather than recorded YARP datasets

What the problem is:

- the old anonymous `apt.prophesee.ai` package feed used by older Dockerfiles is no longer the current documented install path
- the current Prophesee SDK 5.x Linux install flow uses authenticated access to Prophesee's JFrog server
- without those credentials, the Docker build either times out against the old feed or cannot install `metavision-sdk`

What still works without it:

- `yarpmanager`
- `yarpdataplayer`
- `yarpview`
- `yarpscope`
- `vFramer`
- BallBalance demos based on recorded data under `/workspace/data`

How to include the SDK if you have access:

1. Obtain your Prophesee JFrog credentials by following Prophesee's Linux installation guide for Metavision SDK: https://docs.prophesee.ai/stable/installation/linux.html
2. Open your local [`.env`](.env) file.
3. Set `INSTALL_METAVISION_SDK=1`.
4. Set `PROPHESEE_JFROG_USER` to your Prophesee JFrog login.
5. Set `PROPHESEE_JFROG_TOKEN` to your Prophesee JFrog identity token.
6. Rebuild the image with `./scripts/build.sh`.
7. Run `./scripts/show-versions.sh` after starting the workstation and confirm it reports `Metavision SDK: installed`.

Keep those credentials only in your local [`.env`](.env). Do not commit them.

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
- BallBalance demo
- each individual GUI tool
- stop demo only
- list data
- shell
- stop workstation

The menu demo entry loads the trial selected by `BALLBALANCE_DEMO_TRIAL` in [yarpmanager/defaults.env](yarpmanager/defaults.env).

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
./scripts/open-vframer.sh left
./scripts/open-vframer.sh right
./scripts/open-dataplayer.sh
```

Run the BallBalance demo:

```bash
./scripts/demo-ballbalance.sh
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
- `VFramer Left`
- `VFramer Right`
- `All Tools`
- `BallBalance Demo`

The BallBalance demo entry loads the trial selected by `BALLBALANCE_DEMO_TRIAL` in [yarpmanager/defaults.env](yarpmanager/defaults.env).

What they mean:

- `YARP Data Player`: opens the generic `yarpdataplayer` GUI
- `YARP Scope`: opens the generic `yarpscope` GUI
- `YARP View`: opens the generic `yarpview` GUI
- `VFramer Left`: opens `vFramer` using the left source configured in [04-vframer-left.xml](yarpmanager/applications/04-vframer-left.xml)
- `VFramer Right`: opens `vFramer` using the right source configured in [04-vframer-right.xml](yarpmanager/applications/04-vframer-right.xml)
- `All Tools`: opens the generic tools together, including both `vFramer` viewers, and does not auto-load a dataset
- `BallBalance Demo`: runs the coordinated launcher for the trial selected by `BALLBALANCE_DEMO_TRIAL`; if the mounted recording has an empty `rgb/data.log`, it skips `yarpview`

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

From the host, the quickest combined version check is:

```bash
./scripts/show-versions.sh
```

If you change `YCM_VERSION`, `YARP_VERSION`, `ED_VERSION`, or `ED_COMMIT`, rebuild the image before expecting the installed versions to change:

```bash
./scripts/build.sh
./scripts/start-workstation.sh
```

## Important Behavior

- BallBalance demos use `yarpdataplayer` replay outputs under `/yarpdataplayer/...`
- the BallBalance demo always loads `/workspace/data/BallBalance/<BALLBALANCE_DEMO_TRIAL>`
- change the selected trial in [yarpmanager/defaults.env](yarpmanager/defaults.env) with `BALLBALANCE_DEMO_TRIAL=trial_0`, `trial_1`, or `trial_2`
- the menu, CLI, and `yarpmanager` BallBalance entry all reuse the same coordinated launcher
- the launcher cleans up matching old GUI/demo tools before starting a new session
- if the selected trial has an empty `rgb/data.log`, the launcher omits the RGB stream so `yarpdataplayer` does not crash
- `All Tools` is generic and does not auto-load a dataset

## BallBalance Tool Associations

| Tool | Dataset / source | Purpose |
| --- | --- | --- |
| `yarpdataplayer` | `/workspace/data/BallBalance/<BALLBALANCE_DEMO_TRIAL>` | replays the selected recorded session |
| `yarpview` | `/yarpdataplayer/grabber` or `/yarpdataplayer/rgb` | shows the RGB camera stream when the mounted recording actually contains RGB replay data |
| `yarpscope` | `/yarpdataplayer/icub/right_arm/state:o` | plots the right-arm encoder stream |
| `vFramer Left` | `/yarpdataplayer/zynqGrabber/left/AE:o` | visualizes the left event-camera stream |
| `vFramer Right` | `/yarpdataplayer/zynqGrabber/right/AE:o` | visualizes the right event-camera stream |

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

If the `yarpmanager` `VFramer Left` application needs a different default source, edit [04-vframer-left.xml](yarpmanager/applications/04-vframer-left.xml):

```xml
<parameters>--name /vframer/left --src /zynqGrabber/left/AE:o --width 640 --height 480</parameters>
```

If the `yarpmanager` `VFramer Right` application needs a different default source, edit [04-vframer-right.xml](yarpmanager/applications/04-vframer-right.xml):

```xml
<parameters>--name /vframer/right --src /zynqGrabber/right/AE:o --width 640 --height 480</parameters>
```

If the script-based `./scripts/open-vframer.sh` launcher needs different default source or size settings, edit [defaults.env](yarpmanager/defaults.env):

```bash
VFRAMER_LEFT_SRC=/zynqGrabber/left/AE:o
VFRAMER_RIGHT_SRC=/zynqGrabber/right/AE:o
VFRAMER_WIDTH=640
VFRAMER_HEIGHT=480
```

If you want the BallBalance demo to use a different recording, edit the same file:

```bash
BALLBALANCE_DEMO_TRIAL=trial_0
```

If the host data folder changes, update [`.env`](.env) and re-apply the runtime:

```bash
./scripts/start-workstation.sh
```
