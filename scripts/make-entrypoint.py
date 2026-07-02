#!/usr/bin/env python3

import json
import shlex
import sys
from pathlib import Path

inspection = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))[0]
config = inspection["Config"]
argv = (config.get("Entrypoint") or []) + (config.get("Cmd") or [])
if not argv:
    raise SystemExit("Image has neither Entrypoint nor Cmd")

environment = {}
for item in config.get("Env") or []:
    key, _, value = item.partition("=")
    environment[key] = value

lines = ["#!/bin/sh", "set -e"]
for key, value in environment.items():
    lines.append(f"export {key}={shlex.quote(value)}")
if config.get("WorkingDir"):
    lines.append(f"cd {shlex.quote(config['WorkingDir'])}")
lines.append("exec " + " ".join(shlex.quote(item) for item in argv))
Path(sys.argv[2]).write_text("\n".join(lines) + "\n", encoding="utf-8")

