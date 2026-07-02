#!/system/bin/sh

MODDIR="${0%/*}"
"$MODDIR/bin/ql" status
echo
"$MODDIR/bin/ql" config list
