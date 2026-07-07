#!/system/bin/sh

# shellcheck disable=SC2034 # Read by the Magisk/KernelSU installer.
SKIPUNZIP=0

ui_print "- 青龙面板 for KernelSU"
ui_print "- 兼容 KernelSU / APatch / Magisk"

ARCH="$(getprop ro.product.cpu.abi)"
case "$ARCH" in
  arm64-v8a) ;;
  *)
    ui_print "! 不支持的处理器架构：$ARCH"
    ui_print "! 当前版本仅支持 arm64-v8a"
    abort
    ;;
esac

mkdir -p /data/adb/qinglong
touch /data/adb/qinglong/.keep
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/bin/ql" 0 0 0755

ui_print "- 模块已内置离线运行环境"
ui_print "- 持久数据目录：/data/adb/qinglong/data"
ui_print "- 持久配置文件：/data/adb/qinglong/config.env"
ui_print "- 默认面板地址：http://127.0.0.1:5700"
ui_print "- 终端命令：su -c '/data/adb/modules/qinglong_ksu/bin/ql status'"
