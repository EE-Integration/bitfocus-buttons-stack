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
    locales \
    dbus \
    && rm -rf /var/lib/apt/lists/*

# PostgreSQL init requires this locale for Buttons database creation
RUN sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Restore normal policy so runtime service calls work
RUN rm /usr/sbin/policy-rc.d

# Create buttons group and user (matches what the service file expects)
RUN groupadd buttons \
    && useradd -m -s /bin/bash -g buttons buttons

# Copy local release cache (optional for local builds)
COPY bitfocus-buttons-linux-x64/ /tmp/bitfocus-buttons-linux-x64/

# Extract local tarball when present; otherwise download from CDN.
# Override BUTTONS_TARBALL and/or BUTTONS_URL at build time as needed.
ARG BUTTONS_TARBALL=bitfocus-buttons-linux-x64-5585-918fc50d.tar.gz
ARG BUTTONS_URL=https://s4-cf.bitfocus.io/builds/buttons/bitfocus-buttons-linux-x64-5585-918fc50d.tar.gz
RUN mkdir -p /opt/bitfocus-buttons \
    && if [ -f "/tmp/bitfocus-buttons-linux-x64/$BUTTONS_TARBALL" ]; then \
         tar -xzf "/tmp/bitfocus-buttons-linux-x64/$BUTTONS_TARBALL" -C /opt/bitfocus-buttons --strip-components=1; \
       else \
         curl -fsSL "$BUTTONS_URL" | tar -xz -C /opt/bitfocus-buttons --strip-components=1; \
       fi \
    && rm -rf /tmp/bitfocus-buttons-linux-x64 \
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
