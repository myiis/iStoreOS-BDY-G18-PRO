# iStoreOS for BDY-G18-Pro

![OpenWrt logo](include/logo.png)

iStoreOS 是基于 OpenWrt 的路由与 NAS 系统。本项目以 [iStoreOS 官方仓库](https://github.com/istoreos/istoreos)的 `istoreos-24.10` 分支为基础，为 **BDY-G18-Pro / RK3568** 提供板级支持、原生 MT7615 Wi-Fi 和默认软件包配置。

本 README 沿用官方的下载、开发编译、相关仓库、支持与许可证结构，并说明本项目的定制部分。

## Download / 固件下载

本项目镜像的设备后缀为 `rockchip-armv8-bdy_g18-pro-squashfs-sysupgrade.img`，文件名前缀会随版本变化。公开发布的固件以本仓库实际提供的发布文件为准。

2026-10-13 的已测试构建可以正常刷机，用户反馈 Wi-Fi 温度正常。默认服务包已检查是否进入镜像，尚未逐项验证全部服务的运行功能。

上游固件与通用设备信息：

- [iStoreOS 官方项目](https://github.com/istoreos/istoreos)
- [OpenWrt Firmware Selector](https://firmware-selector.openwrt.org/)
- [OpenWrt 固件下载说明](https://openwrt.org/downloads)

本项目的 G18-Pro 定制镜像不由 OpenWrt Firmware Selector 提供。

## Development / 开发与编译

### Requirements / 基础环境

上游支持 GNU/Linux、BSD 或 macOS 编译环境，源码所在文件系统必须区分大小写；Cygwin 不受支持。本项目已验证的环境是 **Docker 中的 Ubuntu 22.04 ARM64**，源码和构建产物位于 Linux 数据卷中。

官方列出的基础工具如下，具体软件包名称随发行版变化：

```text
binutils bzip2 diff find flex gawk gcc-6+ getopt grep install libc-dev libz-dev
make4.1+ perl python3.7+ rsync subversion unzip which
```

完整环境说明见 [OpenWrt Build System Setup](https://openwrt.org/docs/guide-developer/build-system/install-buildsystem)。

Ubuntu 22.04 可使用以下命令准备本项目所需的基础依赖：

```bash
sudo apt update
sudo apt install -y build-essential clang flex bison g++ gawk gcc-multilib \
  gettext git libncurses-dev libssl-dev python3 python3-dev python3-setuptools \
  python3-pyelftools rsync unzip zlib1g-dev file wget curl subversion \
  swig libelf-dev device-tree-compiler zstd time
```

ARM64 环境不提供 `gcc-multilib` 时，从安装列表中去掉该项。本项目的 Go 引导环境使用 Ubuntu 的 Go 1.18；Rust/LLVM 编译需要足够的内存，已测试环境采用单并发构建。

### Quickstart / 上游通用编译流程

进入源码目录，按官方流程获取软件包、选择设备并构建：

```bash
./scripts/feeds update -a
./scripts/feeds install -a
make menuconfig
make -j1 V=s
```

构建会下载源码，生成交叉编译工具链，并编译内核和所选软件包。该流程说明上游构建方式；G18-Pro 完整默认服务配置还需要下面的补充包源与适配。

### G18-Pro 配置

默认配置入口为 [`config/g18-pro.config`](config/g18-pro.config)。准备好所需包源后加载配置：

```bash
cp config/g18-pro.config .config
make defconfig
make menuconfig
make download -j1
make -j1 V=s
```

确认选择的设备为 `BDY G18-PRO`，并检查 `make defconfig` 没有丢弃所需软件包。完整默认配置包含中文 LuCI、iStore、Docker/Compose、Docker Manager 0.1.1、Alist、OpenClash、Passwall、HomeProxy、DDNS-Go、文件共享、磁盘管理、流量统计、OpenAppFilter、ZeroTier、UPnP、定时限速及 `app-meta-modem` 等。

完整服务配置需要额外的 ImmortalWrt 包源：

```text
src-git g18packages https://github.com/immortalwrt/packages.git;openwrt-24.10
src-git g18luci https://github.com/immortalwrt/luci.git;openwrt-24.10
```

这两项是补充来源，不能直接覆盖 iStoreOS 已有 feeds。已测试构建只安装缺少的包，并固定到下文记录的提交。部分兼容修改目前保存在已准备的 Docker feeds 中：完整 sing-box 与 Alist 的替代包依赖声明适配，以及 Rust 单任务限制。**新克隆的源码尚不能仅靠加载配置就完全复现这套默认服务构建，需要补齐这些 feeds 适配。**

Alist 的 FUSE 依赖、ndisc6 的 C11 编译设置、固定提交的 Quectel 源码、Modem 翻译及 PCIe 依赖适配已包含在本仓库的附加包源码中。

Docker Manager 0.1.1 已在 `config/g18-pro.config` 中明确选为默认内置包，包含管理程序、LuCI 页面、iStore 元数据及轻量应用入口和认证依赖。源码入口保存在 `package/g18-services/`，版本来源见该目录的 `DOCKER-MANAGER-SOURCES.md`。加载预设后执行 `make defconfig` 即会选中这些包。Quickstart 的 LuCI 界面、后端服务及直接依赖也已明确列入该预设，包定义保存在 `package/g18-services/`。

### Ubuntu 本机一键构建

当前直接使用本机 Ubuntu 24 编译，不需要 Docker。准备 feeds、加载配置并完成 `make defconfig` 后，在源码根目录运行：

```bash
bash scripts/g18-build.sh
```

脚本使用现有 `.config`，先检查锁定的无线构建输入、G18-Pro 设备和 MT7615E 包选择，再下载源码并以单线程显示详细日志构建。它设置 `FORCE_UNSAFE_CONFIGURE=1` 以支持当前 root 编译环境，不会更新 feeds、覆盖配置或清理构建目录。日志保存在 `logs/g18-build-*.log`，失败时停止并返回失败状态，修复后可以重新执行同一命令。

构建产物位于 `bin/targets/rockchip/armv8/`，不会自动导出到 `releases/`。完整默认服务所需的补充 feeds 和适配仍需按前文准备，本脚本不负责补齐。

预设中的 Go 引导路径 `/usr/lib/go-1.18` 来自旧 Ubuntu 22.04 环境。在当前 Linux x86_64 本机上，如果该路径不存在，一键脚本会通过构建参数改用软件源自带的 Go 引导流程，不修改预设或 `.config`；首次构建需要额外下载并编译引导工具链。其他架构缺少引导环境时会提前停止。

### 历史 Docker 编译环境与目录约定

在 Docker 中使用区分大小写的 Linux 数据卷存放编译副本。feeds、下载缓存、工具链及构建日志留在容器；最终镜像和校验结果统一导出到仓库根目录的 `releases/`，文档中的路径均相对于仓库根目录。

当前已准备的环境使用 Ubuntu 容器 `istoreos-g18-build`，编译副本位于 `/build/istoreos`，构建日志位于容器内 `/build/g18-output`，最终结果导出到 `releases/`。环境专用脚本 `/build/istoreos/scripts/g18-build-services.sh` 只存在于该容器，不是公开仓库的通用构建入口。

需要全量重建时，在 Linux 编译副本中执行：

```bash
make dirclean
cp config/g18-pro.config .config
make defconfig
make -j1 V=s
```

OpenWrt 原始构建结果位于 Linux 编译副本的 `bin/targets/rockchip/armv8/`。当前 Docker 构建脚本验证成功后，将 G18-Pro 镜像、软件包清单、构建信息和校验结果导出到仓库的 `releases/`；`releases/sha256sums` 使用相对文件名，可在该目录执行 `sha256sum -c sha256sums`。该目录不纳入 Git，发布文件可单独上传到 GitHub Releases。启动、无线及温度需要实机验证。

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

默认软件源为 `https://downloads.openwrt.org/releases/24.10.8`。 G18-Pro 的 `kmods` 源按指定使用 `https://downloads.openwrt.org/releases/24.10.8/targets/rockchip/armv8/kmods/6.6.144-1-77d4782035a23e6f19f9c4751451b4e3`。此目录索引可下载，但与已测试定制内核的校验值 `53211280c46958652d1ef7e7816d26d3` 不一致，不保证模块可安装或加载；本项目未修改内核校验值或绕过依赖检查。板级、启动和交换机改动是 G18-Pro 正常启动、识别无线及联网所需的移植内容。

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

Modem 管理界面为 1.4.4。默认配置补充 `modemmanager`、`fibocom-dial`、`meig-cm` 和通用 `kmod-usb-net-qmi-wwan`、`kmod-mhi-net`、`kmod-qrtr-mhi`；保留 Quectel QConnectManager 1.6.7（包名 `quectel-CM-5G`）。插件版本检测兼容该包名，并显示 opkg 中完整版本，不再要求三段数字格式。

fibocom-dial 与 meig-cm 的源码取自 [Siriling/5G-Modem-Support](https://github.com/Siriling/5G-Modem-Support/tree/b1d9a12ac4c209b82fb9db533b067c3fec95a9a6)，提交 `b1d9a12ac4c209b82fb9db533b067c3fec95a9a6`；保留原源码声明，独立授权条款仍需核实。

“未加载”表示驱动没有出现在 lsmod，不能据此判定没有安装。厂商私有的 GobiNet、QMI、MHI、MTK PCIe 驱动是不同模组的可选实现，不因管理页面列出就全部强制集成；需要具体模组型号、连接方式及内核 6.6 兼容性验证后选用。以上新增配置尚需下一次完整固件构建及实机验证，正在进行的构建不包含这些改动。

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
| [Linux](https://www.kernel.org/)、[U-Boot](https://source.denx.de/u-boot/u-boot)、[mt76](https://github.com/openwrt/mt76)、[Rockchip rkbin](https://github.com/rockchip-linux/rkbin) | 内核、引导程序、原生无线驱动及 Rockchip 启动二进制 | 分别按所使用版本的源码文件、许可证及二进制分发条款 |

编译时沿用的 iStoreOS feeds 来源包括 [jjm2473/packages](https://github.com/jjm2473/packages)、[jjm2473/luci](https://github.com/jjm2473/luci)、[jjm2473/openwrt-third](https://github.com/jjm2473/openwrt-third)、[OpenWrt routing](https://github.com/openwrt/routing)、[OpenWrt telephony](https://github.com/openwrt/telephony) 和 [linkease/istore](https://github.com/linkease/istore)。补充 feeds 和已测试提交见下文。通过 feeds 引入的每个服务及其依赖仍保留各自作者与许可证；上表不是镜像中所有传递依赖的完整清单。

## 构建参考与版本记录


配置参考 [ImmortalWrt-NSY](https://github.com/xiaomeng9597/ImmortalWrt-NSY) 的 `g18-pro.config`、`g18-pro-docker.config` 和 `g18_mtk_wifi.config`，最终采用原生 MT7615 路线。板级参考来自 [immortalwrt-rk356x](https://github.com/zhoufuli/immortalwrt-rk356x)。

- iStoreOS 基准：`fb971407ffd9a094e6f16d9c029f1f580ed5c2ad`。
- 板级参考提交：`0c31fa40197fd59e9f401179c105d5815d5b6e2b`。
- MT7615 校准 SHA256：`7415f5bcd642eeb66702a8c0a7df18893afb1f31ed3b917ed020000646fea01d`。

已测试构建使用的 feeds 版本：

| feeds | 提交 |
|---|---|
| telephony | `92892fa285360b8981f62bf4e0a097e6449e7e33` |
| third | `335fa421e0fcd673a78986117981d4dfa3bf57d7` |
| g18luci | `80ed8a44f244627c5a9f808d09f4c3d8f985b764` |
| luci | `b28d7f1da49c3cb4ce931aff3267473fb327a05b` |
| routing | `00619bc7bc60d8b67ecc490121e45298b122cd6e` |
| packages | `f1c73e13fc8c78f5f1c74096f25494817494dc47` |
| g18packages | `110d325c507051d78dac56d95d1c98a724eb0753` |
| store | `a97ace34f2da358a015b094d326bba2697697f2e` |

当前系统保留 iStoreOS 的内核和驱动版本，并非已知正常 ImmortalWrt 固件的逐字节复刻。

## 已测试镜像校验

文件：`istoreos-24.10.8-r29755-fb971407ff-rockchip-armv8-bdy_g18-pro-squashfs-sysupgrade.img`。

大小：2,483,028,761 字节。

SHA256：`2870db14135ee7a5fbf7a332d08abed9e6c1feef1c95d0a661413d70477224b3`。

## License / 许可证

本仓库包含多种许可证的源码与构建配方。具体授权以 `COPYING`、`LICENSES`、各文件的 SPDX/版权声明，以及各软件包对应版本的许可证为准。修改文件应保留原始署名、版权与许可证声明；本 README 的致谢不替代这些声明。

发布源码和固件时，应随附适用的许可证和通知，并按相关许可证提供对应版本的完整源码及构建修改。Apache-2.0 组件存在 NOTICE 时应保留其适用内容。仅列出来源链接不能替代许可证要求。

**公开发布前仍需完成的核实**：MT7615 校准文件 `mt7615e_rf.bin` 的再分发授权；本地 OpenAppFilter 副本及其特征库的许可证；`app-meta-modem` 原始分发条款；固定版本 Quectel、Alist 前端和 Rockchip 启动二进制的授权与通知。许可证不明确的文件不能仅因可公开下载而认定可再分发。本 README 记录来源，不表示这些项目或作者为本固件背书。
