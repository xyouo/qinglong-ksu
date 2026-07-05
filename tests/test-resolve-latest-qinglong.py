#!/usr/bin/env python3

import json
import subprocess
import sys

payload = {
    "tags": [
        "latest",
        "develop",
        "2.9.9-debian",
        "2.20.2-debian",
        "2.21.0-debian",
        "2.22.0-beta-debian",
    ]
}
result = subprocess.run(
    [sys.executable, "scripts/resolve-latest-qinglong.py"],
    input=json.dumps(payload),
    capture_output=True,
    text=True,
    check=True,
)
assert result.stdout.strip() == "2.21.0"

empty = subprocess.run(
    [sys.executable, "scripts/resolve-latest-qinglong.py"],
    input='{"tags":["latest","debian-dev"]}',
    capture_output=True,
    text=True,
)
assert empty.returncode != 0
assert "stable" in empty.stderr

print("latest QingLong resolver tests passed")
