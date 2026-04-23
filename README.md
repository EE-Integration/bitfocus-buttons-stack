# Bitfocus Buttons

Docker deployment for [Bitfocus Buttons](https://bitfocus.io/buttons), targeting Portainer with repository-based stack deployment.

The image is built from source at deploy time. The Bitfocus Buttons release is downloaded directly from the Bitfocus CDN during the Docker build — no binary files are stored in this repository.

## Prerequisites

- Portainer Business Edition with access to this private repository
- A valid Bitfocus Buttons license
- The Bitfocus Buttons Linux x64 CDN URL for the release you intend to deploy

## Deployment

### Portainer Stack

1. In Portainer, go to **Stacks → Add stack → Git repository**
2. Set the repository URL and configure credentials for private repo access
3. Set the compose file path to `compose.yaml`
4. Add the following environment variables:

| Variable | Required | Description |
|---|---|---|
| `BUTTONS_URL` | Yes | Bitfocus CDN URL for the Linux x64 release tarball |
| `IMAGE_TAG` | No | Tag for the built image (defaults to `latest`) |

5. Deploy the stack. Portainer will build the image and start the container.

The application will be available at `http://<host>:4440` once the container is healthy. First boot takes longer due to PostgreSQL cluster initialization.

### Updating

To deploy a new Buttons release, update `BUTTONS_URL` in the Portainer stack environment variables to the new CDN URL and redeploy.

## Architecture Notes

- The container runs on host networking (`network_mode: host`) to support mDNS/Bonjour via Avahi.
- Bitfocus Buttons manages its own PostgreSQL 17 and Redis instances internally. System-installed packages provide the binaries; no system services are started.
- The application runs as the `buttons` user. The entrypoint starts `dbus` and `avahi-daemon` as root before dropping privileges.
- Three named volumes persist state across container restarts: `buttons_config`, `buttons_pgdata`, and `buttons_logs`.

## Disclaimer

Bitfocus Buttons is the property of [Bitfocus AS](https://bitfocus.io). This repository contains only the infrastructure configuration required to run Bitfocus Buttons in a containerized environment. Use of Bitfocus Buttons requires a valid license from Bitfocus AS. This project is not affiliated with or endorsed by Bitfocus AS.
