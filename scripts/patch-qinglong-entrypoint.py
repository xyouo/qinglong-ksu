#!/usr/bin/env python3

import sys
from pathlib import Path

path = Path(sys.argv[1])
source = path.read_text(encoding="utf-8")

pm2_probe = (
    'pm2 l &>/dev/null || log_with_style "WARN" '
    '"PM2 初始化可能失败，将在启动时尝试使用备用方案"'
)
if pm2_probe not in source:
    raise SystemExit("QingLong entrypoint PM2 probe was not found")
source = source.replace(pm2_probe, ': # PM2 由前台 pm2-runtime 管理', 1)

reload_call = "\nreload_pm2\n"
if reload_call not in source:
    raise SystemExit("QingLong entrypoint reload_pm2 call was not found")
source = source.replace(reload_call, "\n: # 跳过后台 PM2 daemon\n", 1)

scheduler_marker = "# 自动检测调度模式"
legacy_tail_marker = "tail -f /dev/null"
if scheduler_marker in source:
    foreground_start = source.index(scheduler_marker)
elif legacy_tail_marker in source:
    foreground_start = source.index(legacy_tail_marker)
else:
    raise SystemExit("QingLong entrypoint foreground wait block was not found")
source = source[:foreground_start] + """# Android chroot 使用前台进程监管：
# 避免 PM2 daemon 被系统回收后留下半存活的 Node 进程。
export QL_SCHEDULER=node
mkdir -p /ql/data/log
exec pm2-runtime start /ql/ecosystem.config.js >>/ql/data/log/pm2-runtime.log 2>&1
"""

path.write_text(source, encoding="utf-8")
