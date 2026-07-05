#!/usr/bin/env python3

import json
import subprocess
import sys
import tempfile
from pathlib import Path

script = Path("scripts/prepare-upstream-release.py").resolve()

with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    result = subprocess.run(
        [
            sys.executable,
            str(script),
            "1.2.3",
            "v2.20.2",
            "--root",
            str(root),
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    assert result.stdout.strip() == "ghcr.io/whyour/qinglong:2.20.2-debian"
    assert (root / "qinglong-image.txt").read_text(encoding="utf-8").strip() == (
        "ghcr.io/whyour/qinglong:2.20.2-debian"
    )
    metadata = json.loads((root / "update.json").read_text(encoding="utf-8"))
    assert metadata["version"] == "v1.2.3"
    assert metadata["versionCode"] == 10203
    assert metadata["zipUrl"].endswith("/v1.2.3/qinglong-ksu-v1.2.3.zip")

invalid = subprocess.run(
    [sys.executable, str(script), "next", "2.20.2"],
    capture_output=True,
    text=True,
)
assert invalid.returncode != 0
assert "X.Y.Z" in invalid.stderr

print("upstream release preparation tests passed")
