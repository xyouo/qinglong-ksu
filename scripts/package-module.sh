#!/usr/bin/env bash

set -euo pipefail

version="${VERSION:-0.1.0}"
runtime="${RUNTIME_ARCHIVE:-dist/qinglong-rootfs-arm64.tar.gz}"
module_dir=build/module
output="dist/qinglong-ksu-v${version}.zip"

[ -s "$runtime" ] || {
  echo "Runtime archive not found: $runtime" >&2
  exit 1
}

rm -rf "$module_dir"
mkdir -p "$module_dir" dist
cp -a module/. "$module_dir/"
cp "$runtime" "$module_dir/runtime.tar.gz"
sha256sum "$runtime" | awk '{print $1}' >"$module_dir/runtime.sha256"

sed -i \
  -e "s|^version=.*|version=v${version}|g" \
  -e "s|^versionCode=.*|versionCode=${VERSION_CODE:-1}|g" \
  "$module_dir/module.prop"

(
  cd "$module_dir"
  zip -0r "../../$output" .
)
