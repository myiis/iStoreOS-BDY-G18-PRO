# G18-Pro 上游同步与无线保护

MT7615E 必须保留当前已验证版本。不得为了消除编译错误而替换、升级驱动或校准文件。

`g18-wifi-lock.json` 锁定 mt76 全目录（公共组件、源码提交、下载校验值、固件及补丁）、mac80211 全目录、G18 设备树和注册补丁、Rockchip 平台构建文件、当前内核版本记录及 G18 默认配置。同时锁定保护脚本、构建入口、Git hooks 和 CI 文件。mt76 源码提交固定为 `eb567bc7f9b692bbf1ddfe31dd740861c58ec85b`。不要重新生成清单来让变更通过检查。

## 新克隆的仓库

```sh
git config core.hooksPath .githooks
git remote add upstream https://github.com/istoreos/istoreos.git
python3 scripts/g18-wifi-guard.py
```

Git 远程和 hooks 配置只对当前克隆生效，不会随源码自动继承。本次已在当前克隆设置。

## 同步

先提交当前工作，包括首次新增的保护机制，确保工作区干净。随后执行：

```sh
git fetch upstream
git switch -c sync-istoreos-YYYYMMDD
sh scripts/g18-sync-upstream.sh upstream/istoreos-24.10
```

脚本在合并前检查锁定状态，以合并前本地版本恢复受保护目录和文件，删除上游在受保护目录新增的文件，再检查结果。它不会自动提交。其他文件发生冲突时会保留合并现场，解决冲突后继续检查：

```sh
python3 scripts/g18-wifi-guard.py --baseline HEAD
git diff --cached --stat
git commit
```

如需放弃合并，使用 `git merge --abort`。不要直接用网页的 Sync fork、普通 pull 或自动升级工具替代上述流程。

## 检查与限制

普通 `make` 配置和构建入口会校验工作区；Git 提交及合并 hooks 校验暂存区，并使用 HEAD 中的清单防止同时修改清单绕过保护。GitHub Actions 在推送和 PR 时检查，并在父版本已有保护时使用父版本的检查程序和清单。

初次引入保护的提交没有父版本清单，只能校验本次清单。后续提交会与已提交基准核对。建议仓库管理员将 `guard` 检查设为分支合并的必需检查，并禁止强制推送；本地 hooks 和 CI 本身不能阻止管理员主动关闭保护。

默认包保存在 `config/g18-pro.config`，不能只修改被 Git 忽略的 `.config`。明确授权新增默认包时，可以仅更新预设的校验值，并审查后建立新的本地保护基准；不能借此更新驱动校验值。CI 允许新增非无线的软件包选项，要求原有配置逐行保留，并仍按父版本校验所有无线文件；无线驱动选择的新增或修改会被拒绝。普通提交 hooks 仍要求预设与当前已提交基准完全一致，因此修改默认预设属于需要明确授权和审查的维护操作，不是自动上游同步的一部分。

保护针对仓库中的构建输入，不能证明整套固件的射频行为，也不校验手动修改的 build_dir、外部工具链或已部署设备。内核其他代码、feeds 和其他未锁定部分仍可能变化，合并后仍需审查兼容性和验证。发现不兼容时停止升级，不替换受保护驱动来迁就新上游。

## 补充 feeds

本脚本只同步主系统，不更新独立 feeds。额外 feeds 和之前 Docker 中的本地适配需要另行保存及固定版本。`feeds update -a` 不受本脚本管理。
