# QingLong for KernelSU

在 Android arm64 设备上通过轻量 chroot 运行青龙面板，优先支持
KernelSU，同时兼容 APatch 和 Magisk。手机端不运行 Docker daemon；
GitHub Actions 会预先提取青龙官方容器镜像，并把离线运行环境封装进模块。

## 为什么不在手机上安装 Docker

Android 厂商内核经常缺少 Docker 所需的 cgroup controller、namespace、
overlayfs 或 iptables 功能。即使 dockerd 能启动，也很容易在升级系统或更换
内核后失效。chroot 直接使用 KSU 已有的 root 权限，依赖更少、开销也更低。

## 构建与发布

1. 将本仓库推送到 GitHub。
2. 在 `Actions` 页面运行 `Build release`，填写版本号。
3. Action 会创建 GitHub Release，并且只上传
   `qinglong-ksu-v*.zip` 这一个 KSU/Magisk 刷入包。
4. 在 KernelSU 管理器中刷入 ZIP，然后重启。ZIP 已包含离线运行环境，
   第一次启动无需再下载独立运行包。

从 v0.2.1 开始，模块通过仓库主分支上的标准 `update.json` 接入
KernelSU/Magisk 的原生更新检测。Release 仍然只发布模块 ZIP。

默认面板地址为 `http://127.0.0.1:5700`。局域网访问使用手机的局域网 IP；
是否能被其他设备访问取决于青龙监听地址和 Android 防火墙。

## KernelSU WebUI

在 KernelSU 管理器中打开模块的 WebUI，可以：

- 启动、停止或重启青龙；
- 修改面板端口、时区和 DNS；
- 控制开机自启和启动延迟；
- 打开面板并查看最近日志。

配置保存在 `/data/adb/qinglong/config.env`，升级模块不会覆盖现有值。
Magisk/APatch 没有兼容 WebUI 时，仍可使用下面的命令行。
端口、时区或 DNS 修改后需要重启青龙；WebUI 的“保存并重启”会自动完成。

## 管理命令

模块管理器中的“操作”按钮会显示状态。也可以在 root shell 中执行：

```sh
/data/adb/modules/qinglong_ksu/bin/ql status
/data/adb/modules/qinglong_ksu/bin/ql logs
/data/adb/modules/qinglong_ksu/bin/ql restart
/data/adb/modules/qinglong_ksu/bin/ql shell
/data/adb/modules/qinglong_ksu/bin/ql config list
/data/adb/modules/qinglong_ksu/bin/ql config set QL_PORT 5800
```

手动修改配置时，请编辑 `/data/adb/qinglong/config.env`，不要编辑模块目录中的
`config.env`；后者只用于首次安装时生成默认配置。手动修改后执行：

```sh
/data/adb/modules/qinglong_ksu/bin/ql restart
```

如果启动失败，可以收集以下输出：

```sh
/data/adb/modules/qinglong_ksu/bin/ql doctor
/data/adb/modules/qinglong_ksu/bin/ql logs 200
cat /data/adb/qinglong/logs/service.log
```

运行环境位于 `/data/adb/qinglong/rootfs`，青龙数据持久化在
`/data/adb/qinglong/data`。卸载模块不会自动删除数据。

## 当前限制

- 首版仅支持 `arm64-v8a`。
- 必须由支持 mount 与 chroot 的 root 方案启动。
- 某些高度裁剪或 SELinux 策略异常严格的内核可能仍需针对性适配。
- 这是社区封装，不是青龙官方 Android 版本。

青龙本体来自 [whyour/qinglong](https://github.com/whyour/qinglong)，并遵循其
上游许可证。本仓库只发布启动、安装与构建逻辑。
