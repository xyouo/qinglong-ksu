#!/usr/bin/env python3

import json
from pathlib import Path

metadata = json.loads(Path("update.json").read_text(encoding="utf-8"))
image = Path("qinglong-image.txt").read_text(encoding="utf-8").strip()
workflow = Path(".github/workflows/release.yml").read_text(encoding="utf-8")
updater = Path(".github/workflows/update-qinglong.yml").read_text(encoding="utf-8")
build_script = Path("scripts/build-runtime.sh").read_text(encoding="utf-8")
package_script = Path("scripts/package-module.sh").read_text(encoding="utf-8")
module = {}
for line in Path("module/module.prop").read_text(encoding="utf-8").splitlines():
    key, separator, value = line.partition("=")
    if separator:
        module[key] = value

assert module["updateJson"] == (
    "https://raw.githubusercontent.com/xyouo/qinglong-ksu/main/update.json"
)
version = metadata["version"].removeprefix("v")
major, minor, patch = (int(part) for part in version.split("."))
assert metadata["versionCode"] == major * 10000 + minor * 100 + patch
assert f"/releases/download/{metadata['version']}/" in metadata["zipUrl"]
assert metadata["zipUrl"].endswith(f"qinglong-ksu-{metadata['version']}.zip")
assert image.startswith("ghcr.io/whyour/qinglong:")
assert "cat qinglong-image.txt" in build_script
assert "2.20.2-debian" not in workflow
assert "ghcr.io/v2/whyour/qinglong/tags/list" in updater
assert "docker manifest inspect" in updater
assert "scripts/prepare-upstream-release.py" in updater
assert "scripts/resolve-latest-qinglong.py" in updater
assert 'cp README.md "$module_dir/README.md"' in package_script

print("release metadata tests passed")
