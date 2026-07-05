#!/usr/bin/env python3

import subprocess
import sys
import tempfile
from pathlib import Path

fixture = """#!/bin/bash
pm2 l &>/dev/null || log_with_style "WARN" "PM2 初始化可能失败，将在启动时尝试使用备用方案"
reload_pm2
# 自动检测调度模式
tail -f /dev/null
exec "$@"
"""

legacy_fixture = """#!/bin/bash
pm2 l &>/dev/null || log_with_style "WARN" "PM2 初始化可能失败，将在启动时尝试使用备用方案"
reload_pm2
tail -f /dev/null
exec "$@"
"""

for candidate in (fixture, legacy_fixture):
    with tempfile.TemporaryDirectory() as directory:
        entrypoint = Path(directory) / "docker-entrypoint.sh"
        entrypoint.write_text(candidate, encoding="utf-8")
        subprocess.run(
            [sys.executable, "scripts/patch-qinglong-entrypoint.py", str(entrypoint)],
            check=True,
        )
        result = entrypoint.read_text(encoding="utf-8")

    assert "exec pm2-runtime start /ql/ecosystem.config.js --update-env" in result
    assert "\nreload_pm2\n" not in result
    assert "pm2 l &>/dev/null" not in result
    assert "QL_SCHEDULER=node" in result

print("entrypoint patch tests passed")
