# DMS（DankMaterialShell）

DMS 是这套桌面的「壳」：状态栏、启动器、通知、控制中心、壁纸、设置面板、锁屏全部由它提供。
它不是窗口管理器——窗口归 niri 管，DMS 通过 niri 的 IPC 和生成的 KDL 片段与之协作。

- 版本：2.1.2（Codename `Stormborn`）
- 组成：Go 二进制 `/usr/bin/dms` + Quickshell QML 界面
- 发行资产：`/usr/share/quickshell/dms/`（root 所有，升级即覆盖，**不要改**）
- 进程：`dms run --session`（后端）+ `qs -p /run/user/1000/dms-shell/<hash>`（界面）

```bash
pgrep -af "dms run|qs -p"        # 看两个进程
dms version                       # 2.1.2
dms doctor                        # 环境自检（安装、服务、字体、依赖）
```

## 四个目录

| 目录 | 性质 | 内容 |
|---|---|---|
| `/usr/share/quickshell/dms` | 发行层 | QML、matugen 模板、默认配置；包升级整体替换 |
| `~/.config/dms` | 配置 + 状态 | `settings.json`、`plugins.lock.json`、`.firstlaunch`、`.changelog-2.1`、`config.d/` |
| `~/.local/state/dms` | 会话状态 | `session.json`（壁纸、锁屏位置、启动器历史）、`appusage.json`、`wellbeing/` |
| `~/.cache/dms` | 缓存 | `cache.json`（界面偏好）、`launcher_cache.json`、`dms-colors.json`、`imagecache/` |

判断归属的规则：**能被删掉后自动重建的，是缓存/派生；能让「我的桌面长这样」的，是配置或状态。**

## settings.json 与 session.json 的区别

两者都长得像配置，但语义不同：

| | `~/.config/dms/settings.json` | `~/.local/state/dms/session.json` |
|---|---|---|
| 内容 | 声明式偏好：bar 布局、widget 列表、密度、主题参数、触摸板 | 运行时状态：当前壁纸路径、锁屏时钟位置、启动器搜索历史 |
| 谁写 | 界面/`dms ipc call settings set` | 运行时（选壁纸、拖锁屏时钟…） |
| 适合版本化吗 | 适合，但请用 `config.d` 而不是改这个文件 | 不适合，机器相关 |

两者都有 `configVersion`（当前 settings 42、session 7），升级时 DMS 会按它跑迁移。

### settings.json

结构（节选）：

```json
{
  "configVersion": 42,
  "density": "spacious",
  "barConfigs": [ { "id": "default", "leftWidgets": [...], "rightWidgets": [...], "island": true, ... } ],
  "builtInPluginSettings": { "dms_power": { "trigger": "pw" } },
  "terminalOpacity": 100
}
```

- 任何界面改动都会把**整份对象**序列化写回，`FileView` 带 `watchChanges` + `atomicWrites`；
- 手改会被下一次整份写回吞掉，且和界面并发时顺序不可控，所以**不要手改**；
- 本仓库目前跟踪这个文件（为了让状态栏/岛屿/主题参数可复现），因此**在界面里调设置后 `git diff` 里出现它属于正常现象**，确认无误后提交即可；
- 唯一例外：外部改写有时不会被热加载（`atomicWrites` 换 inode 后监听可能失效），这也是为什么改完壁纸要 `dms restart`。

### config.d：声明式覆盖

想固定某些值（而不是「当前状态」），用：

```
~/.config/dms/config.d/*.json
```

- 只加载 `*.json`，按文件名排序，全部排在 `settings.json` 之后；
- 合并方式是浅合并：**顶层键整体替换**，不做深合并。想覆盖 `barConfigs` 就得给完整数组；
- 适合放 `density`、固定主题参数、固定的 bar 配置。

```json
// ~/.config/dms/config.d/10-density.json
{ "density": "compact" }
```

注意：dropped-in 的键在界面里改会被「写回 settings.json」，两者同时存在时以文件顺序靠后的为准，容易困惑。固定项才用 `config.d`，其余交给界面。

## 主题管线（matugen）

```
壁纸 / 种子色
      │  Theme.qml / 后端
      ▼
dms matugen queue --shell-dir … --config-dir … --kind image --value <图片>
      │  可选参数：--terminal-opacity 85、--terminal-palette、--terminals-always-dark、
      │            --contrast、--seed-color、--spec、--run-user-templates=false
      ▼
SHELL_DIR/matugen/configs/*.toml 里声明的模板 → 写出一组文件
```

实际落盘（当前机器实测）：

| 输出 | 内容 |
|---|---|
| `~/.config/kitty/dank-theme.conf`、`dank-tabs.conf` | 终端 16 色 + 透明度 |
| `~/.config/dms/firefox.css` | Firefox userChrome 主题变量 |
| `~/.config/niri/dms/colors.kdl` | niri 的 focus-ring / border / shadow 颜色 |
| `~/.config/gtk-3.0/dank-colors.css`、`gtk-4.0/dank-colors.css` | GTK 配色 |
| `~/.config/zed/themes/dank-zed-theme.json` | Zed 主题 |
| `~/.local/share/fcitx5/themes/dms/{theme.conf,panel.svg,highlight.svg}` | fcitx5 候选窗主题 |

模板清单在 `/usr/share/quickshell/dms/matugen/configs/`（alacritty、foot、ghostty、wezterm、nvim、hyprland、qt5ct…），但只有当对应程序存在/被启用时才会真的写出。

### 终端透明度

设置里的「主题 → Opacity」（`terminalOpacity`，10–100，默认 100）不是直接改 `kitty.conf`，而是作为 `--terminal-opacity` 传给 matugen，由它在 `dank-theme.conf` 末尾追加：

```conf
background_opacity 0.85
dynamic_background_opacity yes
```

所以**想调透明度就调这个滑块**，手改 `kitty.conf` 会被 include 覆盖。

### 模糊

DMS 的模糊设置（`blurEnabled`、`blurStrength`、`blurForegroundLayers`、`blurredWallpaperLayer`）只作用于 **DMS 自己渲染的 surface**（bar、弹窗、设置窗口）以及视频壁纸的 layer 模糊。

niri 没有窗口级模糊（`window-rule { blur }` 直接 parse error），所以**终端窗口的模糊做不了**，kitty 的 `background_blur` 在这里恒为无效，已设为 0。

## 生成物清单（不要编辑）

DMS 会重写这些文件，文件头通常写着 `DO NOT EDIT` / `AUTO-GENERATED`：

```
~/.config/niri/dms/colors.kdl        # matugen
~/.config/niri/dms/layout.kdl        # 布局 GUI
~/.config/niri/dms/input.kdl         # 触摸板/键盘设置
~/.config/niri/dms/alttab.kdl        # Alt-Tab 设置
~/.config/niri/dms/outputs.kdl       # 显示器设置
~/.config/niri/dms/cursor.kdl        # 光标
~/.config/niri/dms/wpblur.kdl        # 视频壁纸模糊层
~/.config/niri/dms/windowrules.kdl   # 窗口规则
~/.config/niri/dms/binds.kdl         # 键位（GUI/CLI 写）
~/.config/kitty/dank-theme.conf
~/.config/kitty/dank-tabs.conf
~/.config/dms/firefox.css
~/.config/gtk-3.0/dank-colors.css
~/.config/gtk-4.0/dank-colors.css
~/.config/zed/themes/dank-zed-theme.json
```

`~/.config/niri/config.kdl` 只负责 include 它们（见 [niri](./niri.md)）。

## 命令与 IPC

`dms` 的子命令按域拆分，界面上的操作基本都能找到对应 CLI：

```bash
dms ipc call <target> <function> [args...]   # 与运行中的 shell 通信
dms ipc call settings set terminalOpacity 85
dms ipc call settings set density compact
dms ipc call dash toggle                     # 打开 Dash
dms ipc call file browse wallpaper           # 打开「选择壁纸」文件对话框
dms ipc call keybinds toggle niri            # 快捷键面板
dms ipc call toast info "构建完成"            # 发一条 toast
```

常用顶层命令：

| 命令 | 用途 |
|---|---|
| `dms keybinds show/set/remove/reset <provider>` | 键位（provider 为 `niri`/`hyprland`/`mangowc`；niri 写 `dms/binds.kdl`） |
| `dms setup binds/layout/colors/cursor/outputs/windowrules/alttab/input` | 重新部署对应的 niri 片段（会覆盖 `dms/*.kdl`） |
| `dms matugen queue --…` | 触发一次主题生成（一般不用手调） |
| `dms screenshot full/region/window --json` | 截图（niri 下可用） |
| `dms restart` / `dms kill` | 重启 / 结束 shell |
| `dms doctor` | 自检：二进制、服务、portal、字体 |
| `dms backup` / `dms migrate` | 配置备份与一次性迁移 |
| `dms plugins` | 插件安装/启用（锁文件 `plugins.lock.json`） |

`dms keybinds set` 的典型用法（本次改启动器就是它）：

```bash
dms keybinds set niri "Mod+Ctrl+Return" "spawn dms ipc call spotlight toggle" \
  --desc "Application Launcher" --replace-key "Mod+Space"
```

## 插件

- 锁文件：`~/.config/dms/plugins.lock.json`（当前 `{"lockfileVersion":1,"plugins":{}}`）
- 安装/启用：`dms plugins …`，或设置 → 插件
- 插件代码不在 dotfiles 管理范围；换机器时重装即可，锁文件可作为依赖记录

## 升级与迁移

- `settings.json` 的 `configVersion`（42）和 `~/.config/dms/.changelog-2.1` 是迁移标记；
- 升级后第一次启动会按版本跑迁移，可能整体改写 `settings.json`；
- `.firstlaunch` 存在时表示还没走完首次引导（Greeter），删掉它会让欢迎界面再次出现；
- 升级前建议 `dms backup`。

## 排错

```bash
dms doctor                                   # 先看这个
journalctl --user -f | grep -E "dms\[|qml:" # 实时日志（qml: 前缀是界面侧）
dms restart                                  # 状态文件改过、界面卡死时
```

常见现象：

| 现象 | 原因 / 处理 |
|---|---|
| 换了壁纸不生效 | 直接改 `session.json` 不会被热加载，`dms restart` |
| 设置改了没反应 | 看 `dms ipc call settings set …` 是否返回 `SETTINGS_SET_SUCCESS`；被 `config.d` 覆盖时以文件为准 |
| 生成文件被改回 | 正常：那是派生层，改源头（设置/主题） |
| 键位改了又变回去 | `dms setup binds` 或 GUI 覆盖了 `dms/binds.kdl`；自定义键应写在 `config.kdl` |

## 与 dotfiles 的边界

| 进仓库 | 不进仓库 |
|---|---|
| `~/.config/dms/settings.json`（固定栏、岛屿、主题参数） | `session.json`、`cache.json`、`plugins.lock.json`、`.firstlaunch` |
| 想固定设置也可以写 `config.d/*.json` | 所有生成物（见上表） |
| 想固定设置就提交 `config.d/*.json` | 所有生成物（见上表） |

`settings.json` 是这里唯一的例外：它的栏布局、岛屿形态、主题参数都是手工调出来的，值得版本化；代价是每次在界面里动设置都会产生 diff。`session.json` 和缓存仍然不进仓库——它们随机器、壁纸、使用习惯变化，版本化只会制造噪音。
