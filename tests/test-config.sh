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

grep -q 'bash /ql/shell/update.sh "$rau_action"' "$QL" ||
  fail "account commands do not use QingLong's real update script"
if grep -q '/usr/local/bin/ql reset' "$QL"; then
  fail "account commands reference the missing /usr/local/bin/ql symlink"
fi

grep -q 'process_uses_rootfs' "$QL" ||
  fail "stop does not clean up child processes in the QingLong chroot"
grep -q 'ln -s /proc/self/fd "$ROOTFS/dev/fd"' "$QL" ||
  fail "runtime does not provide /dev/fd for shell process substitution"
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
if grep -q '模块后台重启日志' "$QL" || grep -q '模块开机启动日志' "$QL" ||
  grep -q '===== 青龙运行日志 =====' "$QL"; then
  fail "the main log view must only show raw qinglong.log"
fi
if grep -q 'bind_mount /dev ' "$QL" || grep -q 'dev/pts' "$QL" ||
  grep -q 'bind_device "/dev/' "$QL"; then
  fail "runtime must not mount Android device nodes into the chroot"
fi
if grep -q 'umount -l' "$QL"; then
  fail "runtime must not lazily detach Android mount targets"
fi
grep -q 'TMPDIR=/tmp TMP=/tmp TEMP=/tmp' "$QL" ||
  fail "runtime does not sanitize inherited KernelSU temporary paths"
grep -q 'runtime.sha256' "$QL" ||
  fail "module updates do not refresh a changed runtime"
if grep -q 'create_upgrade_snapshot' "$QL" || grep -q 'pre-runtime-' "$QL"; then
  fail "runtime upgrades must not create automatic data snapshots"
fi
grep -q 'port_listening' "$QL" ||
  fail "status and diagnostics do not verify the actual TCP listener"
grep -q 'health_ok' "$QL" ||
  fail "status and diagnostics do not expose QingLong health"
grep -q 'LOG_MAX_BYTES' "$QL" ||
  fail "module logs are not bounded"
grep -q 'DATA_DIR/log/pm2-runtime.log' "$QL" ||
  fail "detailed pm2-runtime output is not rotated separately"
grep -q 'runtime-logs)' "$QL" ||
  fail "detailed runtime logs do not have an explicit CLI command"
grep -q 'QL_DIR=/ql QL_DATA_DIR=/ql/data' "$QL" ||
  fail "account commands do not pass QingLong's required environment"
grep -q 'bash /ql/shell/update.sh' "$QL" ||
  fail "account commands should run QingLong's update script through bash"
grep -q '失败(' "$QL" ||
  fail "account commands should fail when QingLong reports an API failure"

if [ -e "$ROOT/module/action.sh" ]; then
  fail "KernelSU action button should not be exposed"
fi

case "$(uname -s)" in
  MINGW*|MSYS*) ;;
  *)
    chmod_mode="$(stat -c '%a' "$STATE/config.env")"
    assert_eq "$chmod_mode" "600"
    ;;
esac

echo "config tests passed"
