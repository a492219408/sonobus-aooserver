#!/bin/sh
set -eu

AOO_LOG_MODE="${AOO_LOG_MODE:-stdout}"
AOO_ENABLE_BLOCKLIST="${AOO_ENABLE_BLOCKLIST:-false}"

is_mountpoint() {
    target="$(readlink -f "$1")"
    awk -v target="$target" '$5 == target { found=1 } END { exit !found }' /proc/self/mountinfo
}

LOGS_NOT_MOUNTED_WARN="WARN: file logging was requested, but /logs is not a mounted volume/bind mount. Log files would be stored only inside the container layer and may be lost on container recreation. File logging will be skipped."

set -- aooserver "$@"

case "$AOO_LOG_MODE" in
    stdout)
        ;;
    both)
        if is_mountpoint /logs; then
            set -- "$@" --logdir=/logs
        else
            echo "$LOGS_NOT_MOUNTED_WARN" >&2
        fi
        ;;
    file)
        if is_mountpoint /logs; then
            set -- "$@" --logdir=/logs --logfile-only
        else
            echo "$LOGS_NOT_MOUNTED_WARN" >&2
        fi
        ;;
    *)
        echo "WARN: invalid AOO_LOG_MODE '$AOO_LOG_MODE', falling back to 'stdout'." >&2
        ;;
esac

if [ "$AOO_ENABLE_BLOCKLIST" = "true" ]; then
    if [ -f /config/blocklist.txt ]; then
        set -- "$@" --blocklist=/config/blocklist.txt
    else
        echo "WARN: blocklist is enabled, but /config/blocklist.txt was not found. The server will start without IP blocking." >&2
    fi
fi

exec "$@"
