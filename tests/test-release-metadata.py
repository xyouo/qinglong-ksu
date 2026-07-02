#!/usr/bin/env python3

import json
from pathlib import Path

metadata = json.loads(Path("update.json").read_text(encoding="utf-8"))
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

print("release metadata tests passed")
