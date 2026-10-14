# iStoreOS for BDY-G18-Pro

![OpenWrt logo](include/logo.png)

iStoreOS 是基于 OpenWrt 的路由与 NAS 系统。本项目以 [iStoreOS 官方仓库](https://github.com/istoreos/istoreos)的 `istoreos-24.10` 分支为基础，为 **BDY-G18-Pro / RK3568** 提供板级支持、原生 MT7615 Wi-Fi 和默认软件包配置。

## Download / 固件下载

- [最新固件 Releases](https://github.com/myiis/iStoreOS-BDY-G18-PRO/releases/latest)
- [2026-10-14 第二版：iStoreOS 24.10.8](https://github.com/myiis/iStoreOS-BDY-G18-PRO/releases/tag/g18-pro-24.10.8-20261014-r2)
- [下载第二版压缩包，约 189 MiB](https://github.com/myiis/iStoreOS-BDY-G18-PRO/releases/download/g18-pro-24.10.8-20261014-r2/iStoreOS-G18-PRO-24.10.8-20261014-r2.tar.gz)
- [压缩包 SHA256SUMS](https://github.com/myiis/iStoreOS-BDY-G18-PRO/releases/download/g18-pro-24.10.8-20261014-r2/SHA256SUMS)

本项目固件适用于 **BDY G18-PRO / RK3568**。下载压缩包后先解压，固件文件后缀为 `rockchip-armv8-bdy_g18-pro-squashfs-sysupgrade.img`。压缩包同时包含软件包清单、构建配置、feeds 版本、源码提交信息及镜像校验值。

在下载目录校验压缩包：

```bash
sha256sum -c SHA256SUMS
```

解压后，在解压目录校验镜像及构建信息：

```bash
sha256sum -c sha256sums
```

第二版已完成编译、软件包安装及固件清单检查，确认包含下列预置软件。此前用户反馈已测试的 G18-Pro 固件能够刷机且 Wi-Fi 温度正常；各服务的完整运行功能仍需按具体设备、模组和配置验证。

## 默认预置软件

默认配置保存在 [`config/g18-pro.config`](config/g18-pro.config)，附加包源码位于 [`package/g18-services`](package/g18-services)。第二版的主要预置内容如下：

| 功能 | 预置内容 |
|---|---|
| 系统与管理界面 | iStoreOS 24.10.8、Linux 6.6.144、中文 LuCI、iStore、终端与 SFTP |
| Wi-Fi | 固定版本 `kmod-mt7615e`、`kmod-mt7615-firmware`，保留已验证的校准文件 |
| 首页与网络向导 | Quickstart 中文界面、中文“网络向导”和“网口配置”菜单 |
| Docker | Docker/Compose、Docker Manager 0.1.1、管理设置页中文翻译及入口/认证依赖 |
| Passwall | 26.10.4、中文界面、所选代理组件、DNS 工具及 GeoIP/Geosite 分流数据 |
| OpenClash | 0.48.002、中文界面、ARM64 Mihomo 1.19.32 核心 |
| WireGuard | `kmod-wireguard`、`wireguard-tools`、`luci-proto-wireguard` 及加密/隧道依赖 |
| 移动网络 | Modem 管理界面 1.4.4、`modemmanager`、`luci-proto-modemmanager`、Quectel/Fibocom/MeiG 拨号工具及所选 USB/PCIe 驱动 |
| 存储与网络服务 | Alist、Samba/ksmbd 文件共享、Quickstart 磁盘管理、流量统计、OpenAppFilter、UPnP、定时限速等 |

历史预设中仍有 HomeProxy、DDNS-Go、ZeroTier 和独立 `luci-app-diskman` 的选择，但它们未出现在第二版固件清单中；这些条目需要另行补齐包源和依赖，不能视为已集成。每次发布实际包含的软件以附件中的 `.manifest` 为准。

`luci-proto-modemmanager` 和 `luci-proto-wireguard` 是网络接口协议插件。安装后在“网络 → 接口 → 添加新接口”的协议列表中选择 **ModemManager** 或 **WireGuard VPN**，它们没有独立的侧栏服务菜单。

Passwall 和 OpenClash 需要自行配置节点或订阅后使用；透明代理请按实际需求选择其中一套启用。相关源码已随仓库保存，固定来源见 [Passwall/OpenClash 来源记录](package/g18-services/PROXY-SOURCES.md)及[提交清单](package/g18-services/PROXY-SOURCES.json)。Quickstart 与 Docker Manager 来源分别见 [QUICKSTART-SOURCES.md](package/g18-services/QUICKSTART-SOURCES.md) 和 [DOCKER-MANAGER-SOURCES.md](package/g18-services/DOCKER-MANAGER-SOURCES.md)。

## Development / 开发与编译

### Ubuntu 24 原生构建环境

当前已在 **Ubuntu 24 x86_64 本机**完成构建，不需要 Docker。源码应位于区分大小写的 Linux 文件系统。当前构建环境为 16 核 CPU、16 GiB 内存；Rust/LLVM 及默认服务占用较多磁盘，建议预留至少 100 GB 构建分区，条件允许时使用 150 GB。此前 30 GB 和 60 GB 分区均在 Rust 构建或安装阶段写满。

安装基础依赖：

```bash
sudo apt update
sudo apt install -y build-essential clang flex bison g++ gawk gcc-multilib \
  gettext git libncurses-dev libssl-dev python3 python3-dev python3-setuptools \
  python3-pyelftools rsync unzip zlib1g-dev file wget curl subversion \
  swig libelf-dev device-tree-compiler zstd time
```

ARM64 环境没有 `gcc-multilib` 时需去掉该项，并单独准备适用的 Go 引导环境；本文的本机构建验证基于 x86_64。通用环境说明见 [OpenWrt Build System Setup](https://openwrt.org/docs/guide-developer/build-system/install-buildsystem)。

### 首次获取源码与加载默认配置

```bash
git clone -b istoreos-24.10 https://github.com/myiis/iStoreOS-BDY-G18-PRO.git
cd iStoreOS-BDY-G18-PRO
git config core.hooksPath .githooks
./scripts/feeds update -a
./scripts/feeds install -a
cp config/g18-pro.config .config
make defconfig
```

如需调整软件包，可再运行 `make menuconfig`；已经使用仓库默认配置时，不必逐个勾选软件包。保持设备为 `BDY G18-PRO`，保留 MT7615E 驱动与固件，并禁用冲突的 `kmod-mt_wifi`。

项目使用 [`feeds.conf.default`](feeds.conf.default) 中的六个 feeds，Passwall/OpenClash 等缺失包及兼容版本已补入仓库。无需再按旧 Docker 说明额外添加 `g18packages`、`g18luci` 或手动复制容器中的适配。feeds 分支会继续变化；复现已发布固件时，应使用压缩包内 `feeds.buildinfo` 记录的提交。

### 一键构建与多核编译

在源码根目录执行：

```bash
bash scripts/g18-build.sh
```

默认并行数为可用 CPU 核心数与 8 的较小值。使用 16 个并行任务：

```bash
JOBS=16 bash scripts/g18-build.sh
```

内存不足或定位构建报错时，可降低并行数：

```bash
JOBS=1 bash scripts/g18-build.sh
```

脚本使用当前 `.config`，不复制默认配置、不自动更新 feeds，也不清理已编译的内容。构建系统可能按当前选择补全配置。脚本会：

1. 检查 Python 开发头文件、G18-Pro 设备选择和 MT7615E 保护清单。
2. 检查 Passwall、OpenClash、Mihomo、ModemManager 与 WireGuard 的关键预置项已在当前 `.config` 中启用。
3. 设置 `FORCE_UNSAFE_CONFIGURE=1`，下载源码，再按指定并行数构建。
4. 核对最终固件 `.manifest` 中确实包含关键预置包，缺包时返回失败。

日志保存在 `logs/g18-build-*.log`，产物位于 `bin/targets/rockchip/armv8/`。脚本不会自动上传到 GitHub Releases。

### 默认配置更新后如何生效

**修改 `config/g18-pro.config` 不会自动改变已有 `.config`。单独运行 `make defconfig` 也不会从预设导入新增选项。**

如要完整载入新版默认配置，先备份现有配置，再重新载入：

```bash
cp .config .config.backup
cp config/g18-pro.config .config
make defconfig
JOBS=16 bash scripts/g18-build.sh
```

这会将自选配置替换为仓库预设。若要保留自己的选择，改用 `make menuconfig` 启用新增包，再运行 `make defconfig` 和构建脚本。需要随仓库发布的默认选择必须写入 `config/g18-pro.config`，不能只保存在被 Git 忽略的 `.config`。

### 增量构建与构建适配

修复错误或调整软件包后，可以重新运行同一个构建命令。保留 `build_dir`、`staging_dir` 和 `dl` 可复用已完成的编译与下载；日常重试无需执行 `make clean` 或 `make dirclean`。

预设中的 `/usr/lib/go-1.18` 是旧环境的 Go 引导路径。Linux x86_64 上如果该路径不存在，脚本会通过本次构建参数使用 feeds 自带的引导流程，不修改配置；首次构建会额外下载并编译引导工具链。Passwall 的新增 Go/Rust 依赖已选择兼容现有 Go 1.23、Rust 1.90 工具链的固定版本。

源码解压使用 `tar --no-same-owner`，避免压缩包属主超出当前系统 UID/GID 映射而失败。磁盘写满时先扩容或释放空间；若 Rust 安装中断，需确认 Cargo 和标准库安装完整，不能仅凭旧的构建完成标记判断成功。

### 历史 Docker 环境

早期构建使用 Ubuntu 22.04 ARM64 容器，编译副本在 `/build/istoreos`，容器专用脚本为 `g18-build-services.sh`。这些路径和脚本只属于当时的环境；当前仓库的公开构建入口是 `scripts/g18-build.sh`，原生 Ubuntu 24 构建流程见上文。

## G18-Pro 定制范围

**MT7615E 驱动禁止被上游替换或升级。** 当前驱动、校准文件、公共无线组件及默认配置已建立锁定检查。上游同步必须使用专用流程，详见 [G18 上游同步与无线保护](config/G18-UPSTREAM.md)。

无线使用原生 `mt76 / mt7615e`。G18-Pro 专用补丁加载与已知正常参考一致的校准文件，设备树提供 EEPROM 数据时优先使用设备树数据。此前射频过热的唯一原因尚未确认。

| 位置 | 定制内容 |
|---|---|
| `config/g18-pro.config` | 默认软件包和设备配置 |
| `package/kernel/mt76` | MT7615 校准文件安装与加载 |
| `target/linux/rockchip` | G18-Pro 设备树、平台适配、网口及镜像生成 |
| `package/boot/uboot-rockchip` | G18-Pro 启动支持 |
| `target/linux/generic` | RTL8367 交换机及接口适配 |
| `package/g18-services` | 默认服务所需的附加源码 |
| `include/version.mk`、`package/base-files/image-config.in` | 官方软件源默认值 |

默认软件源为 `https://downloads.openwrt.org/releases/24.10.8`。 G18-Pro 的 `kmods` 源按指定使用 `https://downloads.openwrt.org/releases/24.10.8/targets/rockchip/armv8/kmods/6.6.144-1-77d4782035a23e6f19f9c4751451b4e3`。该软件源目录与第二版固件定制内核的校验值 `545bd50ed2abca824b1e044f4e01a4b3` 不一致，不保证模块可安装或加载；本项目未修改内核校验值或绕过依赖检查。板级、启动和交换机改动是 G18-Pro 正常启动、识别无线及联网所需的移植内容。

## Related Repositories / 相关仓库

- [iStoreOS](https://github.com/istoreos/istoreos)：上游系统源码。
- [LuCI](https://github.com/openwrt/luci)：Web 管理界面。
- [OpenWrt Packages](https://github.com/openwrt/packages)：社区软件包。
- [OpenWrt Routing](https://github.com/openwrt/routing)：路由及 Mesh 软件包。
- [OpenWrt Video](https://github.com/openwrt/video)：显示与视频相关软件包。

## Support Information / 支持与文档

- [OpenWrt 设备数据库](https://openwrt.org/supported_devices)
- [快速入门](https://openwrt.org/docs/guide-quick-start/start)
- [用户指南](https://openwrt.org/docs/guide-user/start)
- [开发者文档](https://openwrt.org/docs/guide-developer/start)
- [技术参考](https://openwrt.org/docs/techref/start)
- [OpenWrt 社区论坛](https://forum.openwrt.org/)
- [OpenWrt 开发邮件列表](https://lists.openwrt.org/mailman/listinfo/openwrt-devel)
- [OpenWrt 社区聊天](https://webchat.oftc.net/#openwrt)
- [OpenWrt 开发者聊天](https://webchat.oftc.net/#openwrt-devel)

定制设备或服务包问题请通过本仓库的 Issues 反馈，并附设备型号、构建版本、配置和相关日志。上游使用说明适用于通用功能，本项目的设备与默认包差异以本文为准。

## Modem 默认支持与状态显示

Modem 管理界面为 1.4.4。默认配置包含 `modemmanager`、`luci-proto-modemmanager`、`fibocom-dial`、`meig-cm` 和通用 `kmod-usb-net-qmi-wwan`、`kmod-mhi-net`、`kmod-qrtr-mhi`；保留 Quectel QConnectManager 1.6.7（包名 `quectel-CM-5G`）。插件版本检测兼容该包名，并显示 opkg 中完整版本，不再要求三段数字格式。

fibocom-dial 与 meig-cm 的源码取自 [Siriling/5G-Modem-Support](https://github.com/Siriling/5G-Modem-Support/tree/b1d9a12ac4c209b82fb9db533b067c3fec95a9a6)，提交 `b1d9a12ac4c209b82fb9db533b067c3fec95a9a6`；保留原源码声明，独立授权条款仍需核实。

“未加载”表示驱动没有出现在 lsmod，不能据此判定没有安装。厂商私有的 GobiNet、QMI、MHI、MTK PCIe 驱动是不同模组的可选实现，不因管理页面列出就全部强制集成；需要具体模组型号、连接方式及内核 6.6 兼容性验证后选用。上述预置项已进入 2026-10-14 第二版固件，并通过软件包安装及清单检查；不同模组的拨号、短信和 PCIe 功能仍需按实际硬件验证。

## 来源、署名与致谢

本项目在以下项目的基础上移植和适配，感谢原作者与维护者。下表区分直接引入的源码、配置参考和编译时的软件包来源；本项目的修改不改变原作品的版权归属。

| 项目 / 作者 | 本项目使用内容 | 来源及许可证说明 |
|---|---|---|
| [iStoreOS / iStore](https://github.com/istoreos/istoreos)、[linkease/istore](https://github.com/linkease/istore) | 系统基础、官方编译流程、iStore 及 `app-meta-modem` 元数据 | 系统基准提交见下文；各组件分别遵循其原始许可证，元数据保留 Siriling 作者信息 |
| [OpenWrt](https://github.com/openwrt/openwrt) | 构建系统、系统基础和软件包机制 | 遵循上游文件与包的许可证，不能将所有固件组件统一视为 GPL-2.0 |
| [xiaomeng9597/ImmortalWrt-NSY](https://github.com/xiaomeng9597/ImmortalWrt-NSY) | `g18-pro.config`、`g18-pro-docker.config`、`g18_mtk_wifi.config` 的默认包配置参考；OpenAppFilter 的直接移植来源 | 采用用户提供的 2026-02-06 本地参考快照；文件的权利归原作者及其上游所有 |
| [xiaomeng9597/iStoreOS-RK35XX-NSY](https://github.com/xiaomeng9597/iStoreOS-RK35XX-NSY) | RK35XX 移植布局、zhoufuli 模板及无线处理流程的对照参考 | 最终无线采用原生 mt76；并非完整照搬该模板 |
| [zhoufuli/immortalwrt-rk356x](https://github.com/zhoufuli/immortalwrt-rk356x) | G18-Pro Linux/U-Boot 设备树、启动配置、RTL8367 与 RK3568 网口/PHY 适配，以及 MT7615 校准参考 | 参考提交见下文；设备树标注 `GPL-2.0+ OR MIT`，其余按各文件原声明；校准二进制的独立再分发许可尚需核实 |
| [ImmortalWrt](https://github.com/immortalwrt/immortalwrt)、[packages](https://github.com/immortalwrt/packages)、[LuCI](https://github.com/immortalwrt/luci) | 补充服务包、LuCI，以及 `package/emortal` 的 cpufreq 工具 | 本地 cpufreq 文件声明 `GPL-2.0-only`；其余以具体包为准 |
| [destan19/OpenAppFilter](https://github.com/destan19/OpenAppFilter) | 应用识别、过滤服务与 LuCI；本地副本经 NSY 参考项目取得 | 本地副本缺少完整顶层许可证，发布前需追溯对应版本并核实源码和特征库许可 |
| [sbwml/luci-app-alist](https://github.com/sbwml/luci-app-alist)、[AlistGo/alist](https://github.com/AlistGo/alist)、[alist-web](https://github.com/AlistGo/alist-web) | Alist 的 OpenWrt 打包、管理界面、后端及前端资源 | 本地 LuCI 文件声明 Apache-2.0；后端 Makefile 声明 GPL-3.0；前端及下载源码分别按对应版本许可证 |
| [sirpdboy/luci-app-eqosplus](https://github.com/sirpdboy/luci-app-eqosplus) | 定时限速服务 | 本地保留 LICENSE，Makefile 声明 Apache-2.0 |
| [Siriling/5G-Modem-Support](https://github.com/Siriling/5G-Modem-Support) | Modem 管理界面、脚本及依赖适配 | 本地保留 GPL-3.0 许可证及作者信息 |
| [Quectel/Quectel_QConnectManager_Linux](https://github.com/quectel-open-source/Quectel_QConnectManager_Linux) | Quectel 拨号管理程序 | 固定提交 `4dd7951dd9cbd078fbe50221d93ed098f7e38289`；下载源码的授权条款需按该版本核实，不由本仓库统一授权 |
| [ndisc6](https://www.remlab.net/ndisc6/)、[Debian 源码镜像](https://deb.debian.org/debian/pool/main/n/ndisc6/) | IPv6 网络工具的 1.0.8 源码与编译适配 | Debian 是下载来源，原作者及许可按源码包中的版权与 COPYING 文件 |
| [Openwrt-Passwall/openwrt-passwall](https://github.com/Openwrt-Passwall/openwrt-passwall)、[配套依赖](https://github.com/Openwrt-Passwall/openwrt-passwall-packages) | Passwall 界面及缺失依赖源码；选择兼容现有工具链的版本 | 固定提交见 `package/g18-services/PROXY-SOURCES.json`，遵循各包原始许可证 |
| [vernesong/OpenClash](https://github.com/vernesong/OpenClash)、[MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo) | OpenClash 0.48.002 与 ARM64 Mihomo 1.19.32 核心 | 保留上游署名；Mihomo 核心按固定版本和 SHA256 下载，许可见来源记录 |
| [animegasan/luci-app-quickstart](https://github.com/animegasan/luci-app-quickstart) | 用户指定的 Quickstart 前端，本地补充中文界面与菜单 | 固定提交及本地修改见 `QUICKSTART-SOURCES.md`，保留原始版权与许可证 |
| [linkease/nas-packages](https://github.com/linkease/nas-packages)、[nas-packages-luci](https://github.com/linkease/nas-packages-luci)、[openwrt-app-meta](https://github.com/linkease/openwrt-app-meta) | Quickstart 后端、Docker Manager、入口与认证集成及元数据 | 具体版本、提交及二进制来源见 `QUICKSTART-SOURCES.md`、`DOCKER-MANAGER-SOURCES.md` |
| [Linux](https://www.kernel.org/)、[U-Boot](https://source.denx.de/u-boot/u-boot)、[mt76](https://github.com/openwrt/mt76)、[Rockchip rkbin](https://github.com/rockchip-linux/rkbin) | 内核、引导程序、原生无线驱动及 Rockchip 启动二进制 | 分别按所使用版本的源码文件、许可证及二进制分发条款 |

编译时沿用的 iStoreOS feeds 来源包括 [jjm2473/packages](https://github.com/jjm2473/packages)、[jjm2473/luci](https://github.com/jjm2473/luci)、[jjm2473/openwrt-third](https://github.com/jjm2473/openwrt-third)、[OpenWrt routing](https://github.com/openwrt/routing)、[OpenWrt telephony](https://github.com/openwrt/telephony) 和 [linkease/istore](https://github.com/linkease/istore)。第二版构建所用 feeds 提交见下文。通过 feeds 引入的每个服务及其依赖仍保留各自作者与许可证；上表不是镜像中所有传递依赖的完整清单。

## 构建参考与版本记录


配置参考 [ImmortalWrt-NSY](https://github.com/xiaomeng9597/ImmortalWrt-NSY) 的 `g18-pro.config`、`g18-pro-docker.config` 和 `g18_mtk_wifi.config`，最终采用原生 MT7615 路线。板级参考来自 [immortalwrt-rk356x](https://github.com/zhoufuli/immortalwrt-rk356x)。

- iStoreOS 基准：`fb971407ffd9a094e6f16d9c029f1f580ed5c2ad`。
- 板级参考提交：`0c31fa40197fd59e9f401179c105d5815d5b6e2b`。
- MT7615 校准 SHA256：`7415f5bcd642eeb66702a8c0a7df18893afb1f31ed3b917ed020000646fea01d`。

2026-10-14 第二版使用的 feeds 版本（与压缩包内 `feeds.buildinfo` 一致）：

| feeds | 提交 |
|---|---|
| telephony | `92892fa285360b8981f62bf4e0a097e6449e7e33` |
| third | `335fa421e0fcd673a78986117981d4dfa3bf57d7` |
| luci | `b28d7f1da49c3cb4ce931aff3267473fb327a05b` |
| routing | `00619bc7bc60d8b67ecc490121e45298b122cd6e` |
| packages | `f1c73e13fc8c78f5f1c74096f25494817494dc47` |
| store | `a97ace34f2da358a015b094d326bba2697697f2e` |

当前系统保留 iStoreOS 的内核和驱动版本，并非已知正常 ImmortalWrt 固件的逐字节复刻。

## 第二版发布文件与校验

- 发布标签：`g18-pro-24.10.8-20261014-r2`。
- 构建源码提交：`ab5625cd3d19c5139688defbb2cbf35c8172a70b`。
- 固件文件：`istoreos-24.10.8-r29758+10-ae6f94ed34-rockchip-armv8-bdy_g18-pro-squashfs-sysupgrade.img`。
- 解压后镜像大小：2,483,028,764 字节。
- 镜像 SHA256：`488df2a5b312cfb74b086dab67a495838491fc41bebaa73e0265c7151a790e24`。
- 压缩包：`iStoreOS-G18-PRO-24.10.8-20261014-r2.tar.gz`，198,381,779 字节。
- 压缩包 SHA256：`20172df27d77acf5392df3b13997d6bcfb3267122131b34505826761fc5f5753`。

源码提交信息同时保存在压缩包内的 `source-info.txt`；文件名中的版本标识与源码提交哈希不完全相同，应结合该文件和构建信息确认来源。

## License / 许可证

本仓库包含多种许可证的源码与构建配方。具体授权以 `COPYING`、`LICENSES`、各文件的 SPDX/版权声明，以及各软件包对应版本的许可证为准。修改文件应保留原始署名、版权与许可证声明；本 README 的致谢不替代这些声明。

发布源码和固件时，应随附适用的许可证和通知，并按相关许可证提供对应版本的完整源码及构建修改。Apache-2.0 组件存在 NOTICE 时应保留其适用内容。仅列出来源链接不能替代许可证要求。

**公开发布前仍需完成的核实**：MT7615 校准文件 `mt7615e_rf.bin` 的再分发授权；本地 OpenAppFilter 副本及其特征库的许可证；`app-meta-modem` 原始分发条款；固定版本 Quectel、Alist 前端和 Rockchip 启动二进制的授权与通知。许可证不明确的文件不能仅因可公开下载而认定可再分发。本 README 记录来源，不表示这些项目或作者为本固件背书。
