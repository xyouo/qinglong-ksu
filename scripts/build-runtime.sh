#!/usr/bin/env bash

set -euo pipefail

IMAGE="${QL_IMAGE:-ghcr.io/whyour/qinglong:2.20.2-debian}"
PLATFORM="${QL_PLATFORM:-linux/arm64}"
OUTPUT="${1:-dist/qinglong-rootfs-arm64.tar.gz}"

mkdir -p "$(dirname "$OUTPUT")" build
rm -rf build/rootfs-normalized
docker pull --platform "$PLATFORM" "$IMAGE"
container="$(docker create --platform "$PLATFORM" "$IMAGE")"
trap 'docker rm -f "$container" >/dev/null 2>&1 || true' EXIT

docker inspect "$container" >build/inspect.json
python3 scripts/make-entrypoint.py build/inspect.json build/qinglong-container-entrypoint

# Docker export preserves hardlinks. Android's Toybox tar cannot reliably
# restore forward hardlinks in large pnpm trees, so normalize them to regular
# files before packaging.
docker export "$container" >build/rootfs.tar
mkdir -p build/rootfs-normalized
tar -xpf build/rootfs.tar -C build/rootfs-normalized
mkdir -p build/rootfs-normalized/usr/local/bin
install -m 0755 build/qinglong-container-entrypoint \
  build/rootfs-normalized/usr/local/bin/qinglong-container-entrypoint
python3 scripts/patch-qinglong-entrypoint.py \
  build/rootfs-normalized/ql/docker/docker-entrypoint.sh
tar --hard-dereference --numeric-owner -cpf - -C build/rootfs-normalized . |
  gzip -9 >"$OUTPUT"
python3 scripts/verify-runtime.py "$OUTPUT"
