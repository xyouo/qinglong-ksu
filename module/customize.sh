#!/system/bin/sh

# shellcheck disable=SC2034 # Read by the Magisk/KernelSU installer.
SKIPUNZIP=0

ui_print "- QingLong for KernelSU"
ui_print "- KernelSU/APatch/Magisk compatible"

ARCH="$(getprop ro.product.cpu.abi)"
case "$ARCH" in
  arm64-v8a) ;;
  *)
    ui_print "! Unsupported ABI: $ARCH"
    ui_print "! This release currently supports arm64-v8a only"
    abort
    ;;
esac

mkdir -p /data/adb/qinglong
touch /data/adb/qinglong/.keep
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/bin/ql" 0 0 0755

ui_print "- Runtime will be downloaded on first boot"
ui_print "- Persistent data: /data/adb/qinglong/data"
ui_print "- Default panel: http://127.0.0.1:5700"
