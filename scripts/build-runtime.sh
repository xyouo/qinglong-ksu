#!/usr/bin/env bash

set -euo pipefail

IMAGE="${QL_IMAGE:-ghcr.io/whyour/qinglong:2.20.2-debian}"
PLATFORM="${QL_PLATFORM:-linux/arm64}"
OUTPUT="${1:-dist/qinglong-rootfs-arm64.tar.gz}"

mkdir -p "$(dirname "$OUTPUT")" build
docker pull --platform "$PLATFORM" "$IMAGE"
container="$(docker create --platform "$PLATFORM" "$IMAGE")"
trap 'docker rm -f "$container" >/dev/null 2>&1 || true' EXIT

docker inspect "$container" >build/inspect.json
python3 scripts/make-entrypoint.py build/inspect.json build/qinglong-container-entrypoint

# docker export produces the merged filesystem and avoids requiring an OCI
# runtime on the phone. Inject our generated launcher into that filesystem.
docker export "$container" >build/rootfs.tar
mkdir -p build/inject/usr/local/bin
install -m 0755 build/qinglong-container-entrypoint \
  build/inject/usr/local/bin/qinglong-container-entrypoint
tar -rf build/rootfs.tar -C build/inject usr/local/bin/qinglong-container-entrypoint
gzip -9 <build/rootfs.tar >"$OUTPUT"

