# 青龙面板 for KernelSU

这是一个在 Android arm64 设备上运行青龙面板的 KernelSU/APatch/Magisk 模块。
模块不在手机上启动 Docker，而是在 GitHub Actions 中预先提取青龙官方容器镜像，
再把离线 chroot 运行环境打包进模块 ZIP。

## 主要功能

- 内置青龙运行环境，刷入模块后重启即可使用。
- 支持 KernelSU WebUI：启动、停止、重启、打开面板、修改端口/时区/DNS/开机自启。
- 支持修改青龙登录用户名、密码，解除登录锁定，关闭两步验证。
- 配置与青龙数据都放在 `/data/adb/qinglong`，升级模块不会覆盖。
- 接入 KernelSU/Magisk 常见的 `update.json` 在线更新检测。
- 仓库提供手动工作流，可以拉取青龙官方最新稳定镜像并构建新版模块。

## 安装前须知

- 仅支持 `arm64-v8a`。
- 需要 KernelSU、APatch 或 Magisk 这类能执行 root 脚本、mount、chroot 的环境。
- 模块 ZIP 已包含离线运行环境，体积会比较大。
- 这是社区封装，不是青龙官方 Android 版本。
- 卸载模块不会自动删除 `/data/adb/qinglong` 中的数据。

默认面板地址：

```text
http://127.0.0.1:5700
```

如果要从局域网其他设备访问，请使用手机的局域网 IP 和你设置的端口。
实际能否访问还取决于青龙监听地址、Android 网络策略和其他防火墙规则。

## 数据、端口与备份恢复

模块把“模块配置”和“青龙数据”分开保存：

- 模块配置：`/data/adb/qinglong/config.env`
- 青龙数据：`/data/adb/qinglong/data`
- 青龙运行环境：`/data/adb/qinglong/rootfs`

面板端口由模块配置里的 `QL_PORT` 控制，不写在青龙数据库里。
所以从另一个青龙恢复 `/ql/data` 后，脚本、数据库、账号等青龙数据可以恢复，
但模块端口通常仍保持你当前模块里设置的值。比如你本机是 `5900`，
恢复另一份青龙数据后端口仍是 `5900`，这是正常现象，不是端口被写死。

需要改端口时，在 WebUI 保存并重启，或手动修改：

```sh
su -c '/data/adb/modules/qinglong_ksu/bin/ql config set QL_PORT 5900'
su -c '/data/adb/modules/qinglong_ksu/bin/ql restart'
```

如果从 x86_64 VPS 或其他架构的 Docker 备份恢复了 `/ql/data`，`/ql/data/dep_cache`
里可能带着旧架构的 Python/Node 原生依赖。典型报错包括
`Cannot load native module 'Crypto.Util._cpuid_c'`、缺少
`aarch64-linux-gnu.so`，或 Node 原生模块加载失败。模块启动时会尽量自动识别并隔离这类明显的旧架构缓存；如果已经启动过仍然报错，
也可以手动隔离旧依赖缓存，再在青龙面板的“依赖管理”中重新安装脚本所需依赖：

```sh
su -c '/data/adb/modules/qinglong_ksu/bin/ql repair-deps python'
# 如果 Node.js 原生依赖也来自旧 VPS，可改用：
# su -c '/data/adb/modules/qinglong_ksu/bin/ql repair-deps all'
```

隔离后的目录会保留为 `dep_cache/python3.incompatible.<时间>` 或
`dep_cache/nodejs.incompatible.<时间>`，确认脚本恢复正常后可自行删除。

## KernelSU WebUI

在 KernelSU 管理器中打开模块 WebUI，可以使用：

- 运行控制：启动、停止、重启、打开面板。
- 持久配置：面板端口、时区、DNS、开机启动延迟、开机自动启动。
- 账号与登录安全：修改用户名、修改密码、解除登录锁定、关闭两步验证。
- 青龙运行日志：只显示青龙启动日志 `qinglong.log` 的原始内容。

端口、时区或 DNS 修改后需要重启青龙进程；WebUI 的“保存并重启”会自动提交后台重启。

## 配置文件说明

首次安装时会从模块内置模板生成 `/data/adb/qinglong/config.env`。
升级模块不会覆盖你已经保存的配置。

```env
# 青龙面板监听端口，范围 1-65535。修改后需要重启青龙进程。
QL_PORT=5700

# Linux 时区名称，例如 Asia/Shanghai、Asia/Hong_Kong、UTC。
TZ=Asia/Shanghai

# 青龙运行环境使用的 DNS，多个地址使用英文逗号分隔。
DNS=1.1.1.1,8.8.8.8

# 手机开机完成后，等待多少秒再启动青龙。范围 0-600。
BOOT_DELAY=10

# 是否开机自动启动青龙：1=启用，0=禁用。
AUTO_START=1
```

DNS 只影响青龙 chroot 运行环境里的域名解析，不会修改 Android 系统 DNS。

## 终端命令

`ql` 不会自动加入系统 PATH。终端里请使用完整路径，或自己加 alias。

常用命令：

```sh
su -c '/data/adb/modules/qinglong_ksu/bin/ql status'
su -c '/data/adb/modules/qinglong_ksu/bin/ql start'
su -c '/data/adb/modules/qinglong_ksu/bin/ql stop'
su -c '/data/adb/modules/qinglong_ksu/bin/ql restart'
su -c '/data/adb/modules/qinglong_ksu/bin/ql logs 200'
su -c '/data/adb/modules/qinglong_ksu/bin/ql runtime-logs 200'
su -c '/data/adb/modules/qinglong_ksu/bin/ql doctor'
su -c '/data/adb/modules/qinglong_ksu/bin/ql shell'
su -c '/data/adb/modules/qinglong_ksu/bin/ql config list'
```

账号安全命令：

```sh
su -c '/data/adb/modules/qinglong_ksu/bin/ql account set-username 新用户名'
su -c '/data/adb/modules/qinglong_ksu/bin/ql account set-password 新密码'
su -c '/data/adb/modules/qinglong_ksu/bin/ql account reset-lock'
su -c '/data/adb/modules/qinglong_ksu/bin/ql account disable-2fa'
```

这些账号命令调用青龙官方脚本的 `resetname/resetpwd/resetlet/resettfa` 能力。
执行时青龙必须处于运行状态；密码长度需为 6-128 位，不能为 `admin`。

如果你想少打路径，可以在 Termux 里临时加一个 alias：

```sh
alias qlmod="su -c /data/adb/modules/qinglong_ksu/bin/ql"
qlmod status
```

## 日志与排查

WebUI 的“青龙运行日志”和 `ql logs` 只显示：

```text
/data/adb/qinglong/logs/qinglong.log
```

更详细的 PM2、Node、gRPC 输出单独放在：

```text
/data/adb/qinglong/data/log/pm2-runtime.log
```

排查启动失败时建议收集：

```sh
su -c '/data/adb/modules/qinglong_ksu/bin/ql status'
su -c '/data/adb/modules/qinglong_ksu/bin/ql doctor'
su -c '/data/adb/modules/qinglong_ksu/bin/ql logs 200'
su -c '/data/adb/modules/qinglong_ksu/bin/ql runtime-logs 200'
su -c 'tail -n 200 /data/adb/qinglong/logs/restart.log'
su -c 'tail -n 200 /data/adb/qinglong/logs/service.log'
```

## 为什么不在手机上安装 Docker

Android 厂商内核经常缺少 Docker 所需的 cgroup controller、namespace、
overlayfs 或 iptables 功能。即使 dockerd 能启动，也很容易在升级系统或更换
内核后失效。chroot 直接使用 KSU 已有的 root 权限，依赖更少、开销也更低。

## 青龙本体更新

模块不会在手机上直接覆盖升级青龙运行环境。仓库根目录的
`qinglong-image.txt` 固定当前构建使用的青龙官方镜像版本；上游发布新版本后，
维护者在 GitHub Actions 中手动运行 `Update QingLong and release`：

1. 填写新的模块版本号。
2. 青龙版本留空时，工作流会读取官方容器镜像标签中的最新稳定 Debian 版本。
3. 工作流构建新的离线运行环境、更新 `update.json`、创建 GitHub Release。
4. 用户通过模块管理器更新，或覆盖刷入新版 ZIP。

升级模块会替换 `/data/adb/qinglong/rootfs`，但不会覆盖
`/data/adb/qinglong/data` 和 `/data/adb/qinglong/config.env`。
模块不再自动创建升级前数据快照；如果你的青龙数据很重要，建议在升级前自行备份
`/data/adb/qinglong/data`。

## 如何应用云端修改

本仓库里的代码改动不会自动出现在你手机里。要让手机上的模块使用新代码，需要先把改动推送到 GitHub，
再通过 GitHub Actions 构建并发布新的模块 ZIP，最后在 KernelSU/APatch/Magisk 里刷入新版 ZIP。

推荐流程：

1. 在 GitHub 仓库确认改动已经合并到 `main` 分支。
2. 打开仓库的 **Actions** 页面。
3. 如果只想用当前青龙版本重新打包模块，运行 **Build release**，填写新的模块版本号，例如 `0.4.5`。
4. 如果想顺便更新到最新稳定青龙，运行 **Update QingLong and release**，填写新的模块版本号；青龙版本留空即可自动选择最新稳定 Debian 镜像。
5. 工作流完成后，到 **Releases** 下载 `qinglong-ksu-v*.zip`。
6. 在手机的模块管理器里覆盖刷入这个 ZIP 并重启。

如果暂时不想换新版 ZIP，只能在手机上执行文档里给出的临时修复命令；这类命令不会把云端代码更新到模块文件里。

## 构建与发布

普通发布：

1. 将本仓库推送到 GitHub。
2. 在 Actions 页面运行 `Build release`，填写模块版本号。
3. Action 会创建 GitHub Release，并只上传 `qinglong-ksu-v*.zip` 模块包。

跟随青龙上游更新：

1. 在 Actions 页面运行 `Update QingLong and release`。
2. 填写模块版本号。
3. 青龙版本留空则自动选择最新稳定 Debian 镜像；也可以显式填写指定版本。

青龙本体来自 [whyour/qinglong](https://github.com/whyour/qinglong)，并遵循其
上游许可证。本仓库只发布启动、安装与构建逻辑。
