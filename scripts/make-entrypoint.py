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

lines = [
    "#!/bin/sh",
    "set -e",
    # Preserve the module's user-facing override before applying image defaults.
    'QL_PORT_OVERRIDE="${QlPort:-}"',
    'TZ_OVERRIDE="${TZ:-}"',
    'BACK_PORT_OVERRIDE="${BACK_PORT:-}"',
    'HOME_OVERRIDE="${HOME:-}"',
    'PM2_HOME_OVERRIDE="${PM2_HOME:-}"',
    'TMPDIR_OVERRIDE="${TMPDIR:-}"',
    'TMP_OVERRIDE="${TMP:-}"',
    'TEMP_OVERRIDE="${TEMP:-}"',
]
for key, value in environment.items():
    lines.append(f"export {key}={shlex.quote(value)}")
lines.extend(
    [
        '[ -z "$QL_PORT_OVERRIDE" ] || export QlPort="$QL_PORT_OVERRIDE"',
        '[ -z "$TZ_OVERRIDE" ] || export TZ="$TZ_OVERRIDE"',
        '[ -z "$BACK_PORT_OVERRIDE" ] || export BACK_PORT="$BACK_PORT_OVERRIDE"',
        '[ -z "$HOME_OVERRIDE" ] || export HOME="$HOME_OVERRIDE"',
        '[ -z "$PM2_HOME_OVERRIDE" ] || export PM2_HOME="$PM2_HOME_OVERRIDE"',
        '[ -z "$TMPDIR_OVERRIDE" ] || export TMPDIR="$TMPDIR_OVERRIDE"',
        '[ -z "$TMP_OVERRIDE" ] || export TMP="$TMP_OVERRIDE"',
        '[ -z "$TEMP_OVERRIDE" ] || export TEMP="$TEMP_OVERRIDE"',
        "unset QL_PORT_OVERRIDE TZ_OVERRIDE BACK_PORT_OVERRIDE HOME_OVERRIDE",
        "unset PM2_HOME_OVERRIDE TMPDIR_OVERRIDE TMP_OVERRIDE TEMP_OVERRIDE",
    ]
)
if config.get("WorkingDir"):
    lines.append(f"cd {shlex.quote(config['WorkingDir'])}")
lines.append("exec " + " ".join(shlex.quote(item) for item in argv))
Path(sys.argv[2]).write_text("\n".join(lines) + "\n", encoding="utf-8")
