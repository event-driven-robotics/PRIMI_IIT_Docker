# Developer README

This guide is for maintainers and contributors. It covers the repository structure, the current launch model, image/build details, and the current GitHub Actions + GHCR distribution path.

For a file-by-file inventory of scripts, env files, build files, `yarpmanager` configs, and automation, see [REPOSITORY_REFERENCE.md](REPOSITORY_REFERENCE.md).

## Goals

This repo intentionally allows multiple user-facing entrypoints:

- menu
- direct CLI scripts
- `yarpmanager`
- manual shell / YARP

The policy is:

- redundancy in access methods is acceptable
- hidden implementation layers should not be duplicated unnecessarily
- `yarpmanager` applications should launch the applications themselves, not `bash` wrappers
- deprecated launch wrappers should be removed when they stop carrying their own behavior

## Current Architecture

### Runtime Layers

- [Dockerfile](Dockerfile): builds the workstation image
- [compose.yaml](compose.yaml): runs the single `robotology` container
- [container-entrypoint.sh](container-scripts/container-entrypoint.sh): remaps the in-container user to the host UID/GID
- [start-yarpserver.sh](container-scripts/start-yarpserver.sh): starts `yarpserver` inside the container

### Operator-Facing Layers

- [workstation-menu.sh](scripts/workstation-menu.sh): guided operator menu
- [common.sh](scripts/common.sh): shared host-side Docker and launcher helpers
- public scripts under [scripts](scripts/): stable CLI entrypoints
- internal script launchers under [scripts/internal](scripts/internal/): shell-only orchestration that still carries meaningful behavior
- `yarpmanager` apps under [yarpmanager/applications](yarpmanager/applications/): direct application launches

### Current Launch Engines

There are two real launch engines now:

1. `yarpmanager` XML apps
   - generic tools and BallBalance demos launch the applications directly
   - the BallBalance manager apps use native dependencies and connections

2. script-based internal launchers
   - [launch-ballbalance-demo.sh](scripts/internal/launch-ballbalance-demo.sh)
   - [launch-ballbalance-tool.sh](scripts/internal/launch-ballbalance-tool.sh)
   - [launch-vframer.sh](scripts/internal/launch-vframer.sh)
   - these are still useful because they add cleanup, waiting, retries, or script-only configuration

The old generic `yarpmanager/bin` wrapper layer was removed because it no longer added behavior.

## How The Stack Works

The runtime defined in [compose.yaml](compose.yaml) does five important things:

1. builds and runs a single `robotology` container
2. shares the host network with `network_mode: host`
3. mounts the project at `/workspace/project`
4. mounts the user data folder at `/workspace/data`
5. forwards X11 so GUI programs from the container can open on the host desktop

The helper layer in [common.sh](scripts/common.sh) standardizes:

- Docker availability checks
- Compose calls with the current host `UID` and `GID`
- execution as the `robotology` user inside the container
- `yarpserver` startup and detection
- GUI launcher behavior

## Important Configuration

The main operator-facing configuration lives in:

- [`.env.example`](.env.example)
- [`.env`](.env)

The most important values are:

- `DISPLAY`
- `HOST_DATA_PATH`
- `BASE_IMAGE`
- `YCM_VERSION`
- `YARP_VERSION`
- `ED_VERSION`

### `BASE_IMAGE`

[Dockerfile](Dockerfile) now uses a configurable base image:

```dockerfile
ARG BASE_IMAGE=public.ecr.aws/ubuntu/ubuntu:22.04
FROM ${BASE_IMAGE}
```

and [compose.yaml](compose.yaml) passes that through as a build arg.

This keeps Ubuntu 22.04 compatibility while avoiding anonymous Docker Hub pull-rate limits by default.

### `vFramer` Defaults

There are intentionally two configuration points now, because there are still two real launch engines:

- `yarpmanager` `VFramer` app: [04-vframer.xml](yarpmanager/applications/04-vframer.xml)
- script-based `vFramer` launcher: [defaults.env](yarpmanager/defaults.env)

Keep them aligned when changing defaults.

## Developer Workflows

Build:

```bash
./scripts/build.sh
```

Start workstation:

```bash
./scripts/start-workstation.sh
```

Open shell:

```bash
./scripts/shell.sh
```

Verify repo launch definitions:

```bash
./scripts/verify-repo.sh
```

Useful manual checks inside the container:

```bash
yarp check
yarp detect
yarp name list
```

## Launch-Model Notes

### Generic Tools

The generic `yarpmanager` applications are direct-launch only:

- [01-yarp-data-player.xml](yarpmanager/applications/01-yarp-data-player.xml)
- [02-yarp-scope.xml](yarpmanager/applications/02-yarp-scope.xml)
- [03-yarp-view.xml](yarpmanager/applications/03-yarp-view.xml)
- [04-vframer.xml](yarpmanager/applications/04-vframer.xml)
- [05-all-tools.xml](yarpmanager/applications/05-all-tools.xml)

### BallBalance

BallBalance is intentionally available via two approaches:

- script-based demos from the public CLI wrappers
- direct-launch `yarpmanager` demos

Those duplicate some session metadata, but the duplication is currently justified because the script path still carries behavior that the manager path does not:

- pre-cleanup of matching old GUI/demo tools
- explicit waits for ports
- retry logic for connections

If this behavior ever gets unified elsewhere, that duplicated session metadata should be reduced.

## GitHub Distribution

This repository now includes two GitHub Actions workflows:

- [.github/workflows/test-image-build.yml](.github/workflows/test-image-build.yml): build-only CI that verifies the image can be built and smoke-tested without publishing
- [.github/workflows/publish-image.yml](.github/workflows/publish-image.yml): publish workflow that pushes the built image to GitHub Container Registry

### Goal

Build the image in GitHub Actions and publish it to GitHub Container Registry so normal users can pull it instead of building locally.

Target image naming:

```text
ghcr.io/<owner>/<repo>:<tag>
```

Examples:

```text
ghcr.io/my-org/primi_iit_docker:latest
ghcr.io/my-org/primi_iit_docker:v1.0.0
ghcr.io/my-org/primi_iit_docker:main
```

### Why This Helps

- avoids asking every user to run a heavy local build
- reduces exposure to upstream registry rate limits during normal use
- makes GitHub the practical distribution point for the workstation
- still keeps the Dockerfile as the source of truth

### Current Workflow Shape

Build-only workflow:

- name: `Test image build`
- triggers: `workflow_dispatch`, `pull_request`
- behavior: builds the image with Buildx, loads it into the runner, and smoke-tests the installed binaries without pushing anything

Publish workflow:

Current triggers:

- `workflow_dispatch` while the repo is still evolving
- pushes to `main` and `master`
- tag pushes like `v*` for releases

Current job permissions:

- `contents: read`
- `packages: write`

Current workflow steps:

1. checkout the repository
2. set up Docker Buildx
3. log in to `ghcr.io` using `${{ secrets.GITHUB_TOKEN }}`
4. derive tags and labels
5. build from [Dockerfile](Dockerfile)
6. push to `ghcr.io/${{ github.repository }}`

The workflow builds from the Dockerfile defaults, so changing the Dockerfile or build defaults in the repo affects both local builds and GitHub-published images.

### Current Tagging Policy

- `vX.Y.Z` on releases
- `latest` on the default branch
- branch tags such as `main` or `master`
- `sha-...` tags for exact workflow outputs

Stable users should pull release tags. Maintainers and testers can use `latest` or `main`.

### Runner Behavior

GitHub-hosted runners are the intended build environment for this workflow. That is useful here because GitHub’s official Docker publishing guidance explicitly calls out GitHub-hosted runners as the supported publishing path, and they are not affected the same way as your local anonymous Docker Hub build path.

### Current User Distribution Flow

Today, users typically do:

```bash
./scripts/build.sh
./scripts/start-workstation.sh
```

After GHCR publishing is in place, the preferred user path becomes:

```bash
docker pull ghcr.io/<owner>/<repo>:latest
./scripts/start-workstation.sh
```

or later, if Compose is updated to support pull-first distribution more explicitly:

```bash
docker compose pull
./scripts/start-workstation.sh
```

### GitHub-Side Setup Still Required

1. Push this repository to GitHub with Actions enabled.
2. Run the workflow once manually or push to `main` / `master` / a `v*` tag.
3. Confirm the GHCR package appears under the repository owner namespace.
4. Set the GHCR package visibility to public if you want anonymous pulls.

### Workflow Files

Build-only workflow:

```yaml
name: Test image build

on:
  workflow_dispatch:
  pull_request:

jobs:
  build-and-smoke-test:
    runs-on: ubuntu-latest
    permissions:
      contents: read

    steps:
      - name: Checkout repository
        uses: actions/checkout@v5
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      - name: Build image
        uses: docker/build-push-action@v6
        with:
          context: .
          file: ./Dockerfile
          load: true
          tags: primi-iit-docker:test
          platforms: linux/amd64
          cache-from: type=gha
          cache-to: type=gha,mode=max
      - name: Smoke test installed tools
        run: |
          docker run --rm --entrypoint bash primi-iit-docker:test -lc '
            set -euo pipefail
            command -v yarp >/dev/null
            command -v yarpmanager >/dev/null
            command -v yarpview >/dev/null
            command -v yarpscope >/dev/null
            command -v yarpdataplayer >/dev/null
            command -v vFramer >/dev/null
            command -v start-yarpserver >/dev/null
            command -v container-entrypoint >/dev/null
            yarp check
          '
```

Publish workflow:

This is the current workflow:

```yaml
name: Publish image to GHCR

on:
  workflow_dispatch:
  push:
    branches:
      - main
      - master
    tags:
      - "v*"

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v5
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Extract image metadata
        uses: docker/metadata-action@v5
        id: meta
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=tag
            type=sha,prefix=sha-
            type=raw,value=latest,enable={{is_default_branch}}
      - name: Build and push image
        uses: docker/build-push-action@v6
        with:
          context: .
          file: ./Dockerfile
          push: true
          platforms: linux/amd64
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### What To Test

Local repository checks:

1. Run `./scripts/verify-repo.sh`.
2. Run `docker compose config` and confirm the build args and service config still resolve correctly.
3. Read [README.md](README.md), [USER_README.md](USER_README.md), and [DEVELOPER_README.md](DEVELOPER_README.md) on GitHub or in a Markdown preview and verify the links render correctly.

GitHub workflow checks:

1. Open the Actions tab and confirm both `Test image build` and `Publish image to GHCR` appear.
2. Run `Test image build` manually with `workflow_dispatch`.
3. Confirm the build-only workflow logs show successful checkout, Buildx setup, image build, and smoke test.
4. Confirm the build-only workflow does not create or update any GHCR package.
5. Run `Publish image to GHCR` manually with `workflow_dispatch` or trigger it from `main` / `master` / a `v*` tag.
6. Confirm the publish workflow logs show successful checkout, GHCR login, metadata generation, build, and push.
7. Confirm the package is created at `ghcr.io/<owner>/<repo>`.
8. Confirm the expected tags exist: `latest` on the default branch, branch tags like `main`, release tags like `v1.0.0`, and `sha-...`.
9. Confirm both workflows use the Dockerfile in the repo root and build `linux/amd64`.
10. Confirm later runs reuse the GitHub Actions cache instead of rebuilding every layer from scratch.

GHCR pull checks:

1. If the package is public, run `docker pull ghcr.io/<owner>/<repo>:latest` from a clean machine or a shell without prior local state.
2. Run `docker image inspect ghcr.io/<owner>/<repo>:latest` and confirm the image exists locally afterward.
3. Optionally pull a release tag like `ghcr.io/<owner>/<repo>:v1.0.0` and compare it to `latest`.

Runtime checks after pulling:

1. Decide whether you want to keep using the local build path or test a pull-first path manually.
2. If testing a pull-first path manually, tag the pulled image to the local Compose image name if needed, then run `./scripts/start-workstation.sh`.
3. Open `yarpmanager` and launch a BallBalance demo.
4. Open the script-based demo path and make sure it still behaves correctly.
5. Confirm the GUI tools open and `yarpserver` is detected.

## References

Official GitHub references for the GHCR workflow:

- Publishing Docker images with GitHub Actions: https://docs.github.com/actions/guides/publishing-docker-images
- Working with the GitHub Container registry: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
- Package access and visibility for GHCR: https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility

## Known Limits

- the current image still assumes the Prophesee / Metavision SDK path from the upstream `event-driven` Dockerfile
- the exact live camera vendor is still a hardware-specific unknown
- scripted BallBalance demos intentionally pre-clean matching GUI/demo tools before launch
- manager-launched BallBalance demos do not pre-clean matching GUI/demo tools before launch
- `All Tools` is generic and not dataset-aware
