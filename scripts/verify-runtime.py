#!/usr/bin/env python3

import sys
import tarfile
from pathlib import Path

archive = Path(sys.argv[1])
hardlinks: list[str] = []
required = {
    "./usr/local/bin/qinglong-container-entrypoint": False,
    "./usr/bin/curl": False,
    "./ql": False,
    "./ql/shell/update.sh": False,
}

with tarfile.open(archive, mode="r:gz") as tar:
    for member in tar:
        if member.islnk():
            hardlinks.append(f"{member.name} -> {member.linkname}")
        if member.name in required:
            required[member.name] = True

if hardlinks:
    print(f"runtime contains {len(hardlinks)} hardlinks:", file=sys.stderr)
    print("\n".join(hardlinks[:20]), file=sys.stderr)
    raise SystemExit(1)

missing = [name for name, found in required.items() if not found]
if missing:
    print(f"runtime is missing required paths: {', '.join(missing)}", file=sys.stderr)
    raise SystemExit(1)

print("runtime verification passed: no hardlinks and required paths are present")
