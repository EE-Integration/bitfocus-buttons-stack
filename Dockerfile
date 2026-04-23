FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive

# Prevent services from auto-starting during apt install (Docker best practice)
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# Base tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Add PostgreSQL 17 official repo (Ubuntu default is too old)
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list' \
    && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg

# Install all runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-17 \
    redis-server \
    avahi-daemon \
    libnss-mdns \
    libudev1 \
    dbus \
    && rm -rf /var/lib/apt/lists/*

# Restore normal policy so runtime service calls work
RUN rm /usr/sbin/policy-rc.d

# Create buttons group and user (matches what the service file expects)
RUN groupadd buttons \
    && useradd -m -s /bin/bash -g buttons buttons

# Download and extract the Bitfocus Buttons release
# Override BUTTONS_URL at build time to deploy a different version
ARG BUTTONS_URL=https://s4-cf.bitfocus.io/builds/buttons/bitfocus-buttons-linux-x64-5585-918fc50d.tar.gz
RUN mkdir -p /opt/bitfocus-buttons \
    && curl -fsSL "$BUTTONS_URL" \
    | tar -xz -C /opt/bitfocus-buttons --strip-components=1 \
    && chown -R buttons:buttons /opt/bitfocus-buttons \
    && chmod +x /opt/bitfocus-buttons/watchdog-cli

# Config, home, and PostgreSQL data dir — all owned by buttons
RUN mkdir -p /home/buttons/.config/bitfocus-buttons /var/lib/postgresql \
    && chown -R buttons:buttons /home/buttons /var/lib/postgresql

COPY --chmod=755 entrypoint.sh /entrypoint.sh

WORKDIR /opt/bitfocus-buttons

EXPOSE 4440
EXPOSE 4443

ENTRYPOINT ["/entrypoint.sh"]
