#!/bin/sh
# Entrypoint for the vdirsyncer container.
#
# `vdirsyncer discover` is what triggers the Google OAuth flow on a first run
# (it creates the token file). The flow needs a browser, so the URL is printed
# to the logs for the operator to open on their own machine.
#
# `vdirsyncer sync` then runs the configured pairs on a schedule.

set -eu

CONFIG_FILE="${VDIRSYNCER_CONFIG:-/config/config}"
PAIRS="${VDIRSYNCER_PAIRS:-}"
INTERVAL="${VDIRSYNCER_INTERVAL:-3600}"

log() { echo "[vdirsyncer-entrypoint] $*"; }

if [ "${1:-}" = "discover" ]; then
    log "Running discovery. If a Google storage is configured, open the URL printed below in your browser."
    log "The browser will redirect to http://127.0.0.1:<port> — if that fails, see the description for the manual token step."
    exec vdirsyncer -c "$CONFIG_FILE" discover
fi

if [ "${1:-}" = "sync" ]; then
    # First pass at boot so the app converges without waiting a full interval.
    log "Initial sync pass."
    vdirsyncer -c "$CONFIG_FILE" sync $PAIRS || log "Initial sync failed; will retry on the next interval."

    log "Entering the sync loop (every ${INTERVAL}s)."
    while true; do
        sleep "$INTERVAL"
        log "Sync pass."
        vdirsyncer -c "$CONFIG_FILE" sync $PAIRS || log "Sync failed; retrying next pass."
    done
fi

exec vdirsyncer -c "$CONFIG_FILE" "$@"
