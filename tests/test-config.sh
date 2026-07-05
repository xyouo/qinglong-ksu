#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QL="$ROOT/module/bin/ql"
STATE="$(mktemp -d)"
trap 'rm -rf "$STATE"' EXIT
export QL_STATE_DIR="$STATE"

run_ql() {
  bash "$QL" "$@"
}

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_eq() {
  [ "$1" = "$2" ] || fail "expected '$1' to equal '$2'"
}

run_ql config init
assert_eq "$(run_ql config get QL_PORT)" "5700"
assert_eq "$(run_ql config get AUTO_START)" "1"

run_ql config set QL_PORT 5800 >/dev/null
assert_eq "$(run_ql config get QL_PORT)" "5800"
grep -q '^# 青龙面板监听端口' "$STATE/config.env" ||
  fail "persistent config is missing Chinese parameter documentation"

if run_ql config set QL_PORT 70000 >/dev/null 2>&1; then
  fail "accepted an out-of-range port"
fi
assert_eq "$(run_ql config get QL_PORT)" "5800"

if run_ql config set TZ 'Asia/Shanghai;reboot' >/dev/null 2>&1; then
  fail "accepted shell metacharacters"
fi

if run_ql config get 'QL_PORT.*' >/dev/null 2>&1; then
  fail "accepted an unknown key"
fi

if run_ql account set-password admin >/dev/null 2>&1; then
  fail "accepted the forbidden password"
fi

if run_ql account set-password short >/dev/null 2>&1; then
  fail "accepted a password shorter than six characters"
fi

if run_ql account set-password 'bad$(reboot)' >/dev/null 2>&1; then
  fail "accepted shell expansion characters in a password"
fi

grep -q '/ql/shell/update.sh resetlet' "$QL" ||
  fail "account commands do not use QingLong's real update script"
if grep -q '/usr/local/bin/ql reset' "$QL"; then
  fail "account commands reference the missing /usr/local/bin/ql symlink"
fi

grep -q 'process_uses_rootfs' "$QL" ||
  fail "stop does not clean up child processes in the QingLong chroot"
grep -q '健康检查失败' "$QL" ||
  fail "start does not verify that the configured port is reachable"
grep -q 'operation_lock_acquire' "$QL" ||
  fail "start/stop/restart operations are not serialized"
if grep -q 'stop) run_locked' "$QL"; then
  fail "stop must be able to interrupt a locked start or restart"
fi
grep -q 'stop) cancel_operation_and_stop' "$QL" ||
  fail "stop does not cancel an in-progress start or restart"
grep -q '/api/health' "$QL" ||
  fail "start does not use QingLong's official health endpoint"
grep -q 'PM2 实际 BACK_PORT' "$QL" ||
  fail "start failures do not report PM2's actual port"
grep -q '模块后台重启日志' "$QL" ||
  fail "the log view does not include background restart output"
if grep -q 'bind_mount /dev ' "$QL" || grep -q 'dev/pts' "$QL"; then
  fail "runtime must not mount Android's global /dev or /dev/pts"
fi
grep -q 'bind_device "/dev/$device"' "$QL" ||
  fail "runtime does not bind the minimal safe device set"
if grep -q 'umount -l' "$QL"; then
  fail "runtime must not lazily detach Android mount targets"
fi
grep -q 'TMPDIR=/tmp TMP=/tmp TEMP=/tmp' "$QL" ||
  fail "runtime does not sanitize inherited KernelSU temporary paths"
grep -q 'runtime.sha256' "$QL" ||
  fail "module updates do not refresh a changed runtime"
grep -q 'port_listening' "$QL" ||
  fail "status and diagnostics do not verify the actual TCP listener"
grep -q 'health_ok' "$QL" ||
  fail "status and diagnostics do not expose QingLong health"
grep -q 'LOG_MAX_BYTES' "$QL" ||
  fail "module logs are not bounded"
grep -q 'create_upgrade_snapshot' "$QL" ||
  fail "runtime upgrades do not create a safety snapshot"

case "$(uname -s)" in
  MINGW*|MSYS*) ;;
  *)
    chmod_mode="$(stat -c '%a' "$STATE/config.env")"
    assert_eq "$chmod_mode" "600"
    ;;
esac

echo "config tests passed"
