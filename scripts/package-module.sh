#!/usr/bin/env bash

set -euo pipefail

repository="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
version="${VERSION:-0.1.0}"
module_dir=build/module
output="dist/qinglong-ksu-v${version}.zip"

rm -rf "$module_dir"
mkdir -p "$module_dir" dist
cp -a module/. "$module_dir/"

base="https://github.com/${repository}"
sed -i \
  -e "s|@UPDATE_JSON@|${base}/releases/latest/download/update.json|g" \
  -e "s|@RUNTIME_URL@|${base}/releases/latest/download/qinglong-rootfs-arm64.tar.gz|g" \
  -e "s|@RUNTIME_SHA256_URL@|${base}/releases/latest/download/SHA256SUMS|g" \
  "$module_dir/module.prop" "$module_dir/config.env"

(
  cd "$module_dir"
  zip -9r "../../$output" .
)

cat >dist/update.json <<EOF
{
  "version": "v${version}",
  "versionCode": ${VERSION_CODE:-1},
  "zipUrl": "${base}/releases/download/v${version}/qinglong-ksu-v${version}.zip",
  "changelog": "${base}/releases/tag/v${version}"
}
EOF

