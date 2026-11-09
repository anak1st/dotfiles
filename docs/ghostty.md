# Ghostty

macOS 上的终端，只在 macOS 条目里安装。

- 源文件：`.config/ghostty/config.ghostty`（仓库内）
- 安装目标：`~/.config/ghostty/config.ghostty`
- 平台：`os: ["macos"]`，Linux 上不安装

## 当前配置

```conf
font-size = 15
font-family = Maple Mono NF CN

# 透明度与背景模糊
background-opacity = 0.8
background-blur = 20
background-opacity-cells = true
```

| 项 | 含义 |
|---|---|
| `font-size 15` | 比 Linux 侧 kitty 的 12 大，macOS 的 HiDPI 下 15 更接近实际观感 |
| `font-family` | 与 kitty 同一套 Maple Mono NF CN（含中文与 Nerd Font 图标） |
| `background-opacity 0.8` | 窗口 80% 不透明 |
| `background-blur 20` | macOS 原生毛玻璃。**这是与 Linux 侧最大的区别**：niri 没有窗口模糊，kitty 那条 `background_blur` 只能设 0 |
| `background-opacity-cells` | 让单元格背景也半透明，否则有背景色的单元格会挡掉透明效果 |

## 与 Linux 侧的差异

| | Linux（kitty + niri） | macOS（Ghostty） |
|---|---|---|
| 主配置 | `~/.config/kitty/kitty.conf` | `~/.config/ghostty/config.ghostty` |
| 颜色来源 | DMS/matugen 生成 `dank-theme.conf` 后 include | 手动配置，无 DMS |
| 透明度 | DMS 设置 → 主题 → Opacity | `background-opacity` |
| 模糊 | 不可用（niri 无窗口模糊） | 可用（macOS 原生） |

macOS 上没有 DMS，所以 Ghostty 的颜色不会被任何东西覆盖；想统一配色只能手写进这个文件。

## 需要确认的一点

Ghostty 默认读的文件名是 `config`，不是 `config.ghostty`：

- Linux：`$XDG_CONFIG_HOME/ghostty/config`（即 `~/.config/ghostty/config`）
- macOS：`~/Library/Application Support/com.mitchellh.ghostty/config`

而本仓库安装出来的是 `~/.config/ghostty/config.ghostty`。如果 macOS 上的 Ghostty 没有读到这份配置，用下面任一方式确认/修正：

```bash
ghostty +show-config        # 看 Ghostty 实际加载的配置
ghostty --config-file ~/.config/ghostty/config.ghostty   # 显式指定文件启动
```

（Ghostty 不在当前 Linux 机器上，这两条命令未在本机验证，以 macOS 上 `ghostty +show-config` 的输出为准。）

或者把目标改成 `config`（需要同时改 `dotfiles.json` 的 target 和文件名）。这是一个待核实的点，不影响 Linux 侧。

## 重载

Ghostty 支持运行时重载配置：`Cmd+Shift+,`（macOS），或重新打开窗口。
