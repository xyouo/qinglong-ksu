#!/system/bin/sh

MODDIR="${0%/*}"
STATE_DIR=/data/adb/qinglong
LOG_DIR="$STATE_DIR/logs"

mkdir -p "$LOG_DIR"
"$MODDIR/bin/ql" config init >>"$LOG_DIR/service.log" 2>&1

AUTO_START="$("$MODDIR/bin/ql" config get AUTO_START)"
[ "$AUTO_START" = "1" ] || exit 0

# Android may report boot completion before networking is actually usable.
until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 5
done

BOOT_DELAY="$("$MODDIR/bin/ql" config get BOOT_DELAY)"
sleep "$BOOT_DELAY"
"$MODDIR/bin/ql" start >>"$LOG_DIR/service.log" 2>&1
