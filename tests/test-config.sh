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

case "$(uname -s)" in
  MINGW*|MSYS*) ;;
  *)
    chmod_mode="$(stat -c '%a' "$STATE/config.env")"
    assert_eq "$chmod_mode" "600"
    ;;
esac

echo "config tests passed"
