# Bitfocus Buttons

Docker deployment for [Bitfocus Buttons](https://bitfocus.io/buttons), targeting Portainer with repository-based stack deployment.

The stack deploy pulls a prebuilt image from Docker Hub at deploy time.

## Prerequisites

- Portainer Business Edition with access to this private repository
- A valid Bitfocus Buttons license
- Docker Hub access to pull `efg01/bitfocus-buttons` (or your forked image)

## Deployment

### Portainer Stack

1. In Portainer, go to **Stacks → Add stack → Git repository**
2. Set the repository URL and configure credentials for private repo access
3. Set the compose file path to `compose.yaml`
4. Add the following environment variables:

| Variable | Required | Description |
|---|---|---|
| `IMAGE_TAG` | No | Tag for the pulled image (defaults to `latest`) |

5. Deploy the stack. Portainer will pull the image and start the container.

The application will be available at `http://<host>:4440` once the container is healthy. First boot takes longer due to PostgreSQL cluster initialization.

### Updating

To deploy a new Buttons release, push a new image tag to Docker Hub and update `IMAGE_TAG` in the Portainer stack environment variables, then redeploy.

### Local image builds

For local `docker build` workflows, place the release tarball in `bitfocus-buttons-linux-x64/`.
The Dockerfile will use the local file first (default `BUTTONS_TARBALL=bitfocus-buttons-linux-x64-5585-918fc50d.tar.gz`) and fall back to `BUTTONS_URL` if that file is not present.
This is only needed when producing/pushing new image tags.

You can use the included Make targets:

- `make docker-build-amd64 IMAGE_TAG=<tag>` to build and load locally
- `make docker-push-amd64 IMAGE_TAG=<tag>` to build and push to Docker Hub

On Apple Silicon, these targets use the Docker `colima` context by default and build for `linux/amd64`.
If Colima is not running, start it first with:

- `make docker-colima-up`

## Architecture Notes

- The container runs on host networking (`network_mode: host`) to support mDNS/Bonjour via Avahi.
- Bitfocus Buttons manages its own PostgreSQL 17 and Redis instances internally. System-installed packages provide the binaries; no system services are started.
- The application runs as the `buttons` user. The entrypoint starts `dbus` and `avahi-daemon` as root before dropping privileges.
- Three named volumes persist state across container restarts: `buttons_config`, `buttons_pgdata`, and `buttons_logs`.

## Disclaimer

Bitfocus Buttons is the property of [Bitfocus AS](https://bitfocus.io). This repository contains only the infrastructure configuration required to run Bitfocus Buttons in a containerized environment. Use of Bitfocus Buttons requires a valid license from Bitfocus AS. This project is not affiliated with or endorsed by Bitfocus AS.
