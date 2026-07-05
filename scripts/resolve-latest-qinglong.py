#!/usr/bin/env python3

import json
import re
import sys

pattern = re.compile(r"^([0-9]+)\.([0-9]+)\.([0-9]+)-debian$")
payload = json.load(sys.stdin)
candidates = []
for tag in payload.get("tags") or []:
    match = pattern.fullmatch(tag)
    if match:
        candidates.append((tuple(map(int, match.groups())), tag.removesuffix("-debian")))

if not candidates:
    raise SystemExit("GHCR did not return any stable X.Y.Z-debian tags")

print(max(candidates)[1])
