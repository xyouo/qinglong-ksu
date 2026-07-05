#!/system/bin/sh

MODDIR="${0%/*}"
"$MODDIR/bin/ql" status
echo
echo "常用诊断命令："
echo "  $MODDIR/bin/ql doctor"
echo "  $MODDIR/bin/ql logs 200"
