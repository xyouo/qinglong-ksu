#!/system/bin/sh

MODDIR="${0%/*}"
exec "$MODDIR/bin/ql" status

