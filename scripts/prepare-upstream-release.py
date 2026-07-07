#!/usr/bin/env python3

import argparse
import json
import re
from pathlib import Path

SEMVER = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")


def normalize_version(value: str, name: str) -> str:
    version = value.removeprefix("v")
    if not SEMVER.fullmatch(version):
        raise SystemExit(f"{name} must use X.Y.Z format: {value}")
    return version


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("module_version")
    parser.add_argument("qinglong_version")
    parser.add_argument("--root", type=Path, default=Path("."))
    args = parser.parse_args()

    module_version = normalize_version(args.module_version, "module version")
    qinglong_version = normalize_version(args.qinglong_version, "QingLong version")
    image = f"ghcr.io/whyour/qinglong:{qinglong_version}-debian"

    (args.root / "qinglong-image.txt").write_text(image + "\n", encoding="utf-8", newline="\n")
    major, minor, patch = map(int, module_version.split("."))
    metadata = {
        "version": f"v{module_version}",
        "versionCode": major * 10000 + minor * 100 + patch,
        "zipUrl": (
            "https://github.com/xyouo/qinglong-ksu/releases/download/"
            f"v{module_version}/qinglong-ksu-v{module_version}.zip"
        ),
        "changelog": (
            "https://github.com/xyouo/qinglong-ksu/releases/tag/"
            f"v{module_version}"
        ),
    }
    (args.root / "update.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(image)


if __name__ == "__main__":
    main()
