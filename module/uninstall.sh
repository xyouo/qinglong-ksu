#!/system/bin/sh

MODDIR="${0%/*}"
"$MODDIR/bin/ql" stop >/dev/null 2>&1 || true

# User data is intentionally retained in /data/adb/qinglong.

