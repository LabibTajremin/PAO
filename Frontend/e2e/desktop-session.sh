#!/usr/bin/env bash
# Runs a command the way a Linux desktop session would: a virtual display, a D-Bus
# session bus and an unlocked keyring, so flutter_secure_storage (libsecret) works
# in the apps' real composition roots. Usage: desktop-session.sh <command> [args...]
set -euo pipefail

if [[ -z "${PAO_DESKTOP_SESSION:-}" ]]; then
  export PAO_DESKTOP_SESSION=1
  exec dbus-run-session -- xvfb-run -a -s '-screen 0 1280x1024x24' "$0" "$@"
fi
# The keyring starts unlocked with a throwaway password for this session only.
printf 'pao-e2e' | gnome-keyring-daemon --unlock --components=secrets >/dev/null
exec "$@"
