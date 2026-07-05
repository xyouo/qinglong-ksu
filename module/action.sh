#!/system/bin/sh

MODDIR="${0%/*}"
"$MODDIR/bin/ql" status
echo
"$MODDIR/bin/ql" doctor
echo
echo "===== 当前配置 ====="
"$MODDIR/bin/ql" config list
echo
echo "===== 最近日志 ====="
"$MODDIR/bin/ql" logs 30
