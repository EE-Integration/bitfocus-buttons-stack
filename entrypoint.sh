#!/bin/bash
set -euo pipefail

# D-Bus system socket — required by avahi-daemon
mkdir -p /run/dbus
if dbus-daemon --system --fork 2>/dev/null; then
    echo "[buttons] dbus-daemon started"
else
    echo "[buttons] warn: dbus-daemon failed — mDNS/Bonjour discovery disabled"
fi

# Avahi mDNS daemon — enables .local hostname resolution for network integrations
if avahi-daemon --daemonize --no-chroot 2>/dev/null; then
    echo "[buttons] avahi-daemon started"
else
    echo "[buttons] warn: avahi-daemon failed — mDNS/Bonjour discovery disabled"
fi

# Drop to buttons user and exec watchdog-cli (su works from root without setuid)
echo "[buttons] starting watchdog-cli as user 'buttons'"
exec su -s /bin/bash -c 'exec /opt/bitfocus-buttons/watchdog-cli 0.0.0.0 4440' buttons
