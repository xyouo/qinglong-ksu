#!/system/bin/sh

MODDIR="${0%/*}"
STATE_DIR=/data/adb/qinglong
LOG_DIR="$STATE_DIR/logs"

mkdir -p "$LOG_DIR"

# Android may report boot completion before networking is actually usable.
until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 5
done

sleep 10
"$MODDIR/bin/ql" start >>"$LOG_DIR/service.log" 2>&1

