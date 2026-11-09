# kitty

Linux 上的主终端。配置文件只有一份，但**颜色和透明度由 DMS 生成后 include 进来**，所以它同时属于「源层」和「派生层」。

- 主配置：`~/.config/kitty/kitty.conf`（仓库：[`.config/kitty/kitty.conf`](../.config/kitty/kitty.conf)）
- 生成配置：`~/.config/kitty/dank-theme.conf`、`dank-tabs.conf`（DMS 写，**不手改、不进仓库**）
- 重载：`pkill -SIGUSR1 -x kitty`（或 `kill -SIGUSR1 <pid>`）

## 文件结构

```
~/.config/kitty/
├── kitty.conf          # 手写，仓库跟踪
├── dank-theme.conf     # DMS/matugen 生成：16 色 + 透明度
└── dank-tabs.conf      # DMS/matugen 生成：标签栏配色
```

`kitty.conf` 末尾两行把生成文件接进来：

```conf
# Dank color generation
include dank-tabs.conf
include dank-theme.conf
```

**include 在最后，后加载优先**：所以 `dank-theme.conf` 里的值会覆盖前面手写的同名项。想调颜色/透明度，改的是 DMS 的设置，不是 `kitty.conf`。

## 当前配置逐项

```conf
font_family Maple Mono NF CN
font_size 12.0
```

等宽 + Nerd Font 图标 + 中文，字体安装见 [字体](./fonts.md)。

```conf
window_padding_width 12
hide_window_decorations yes
remember_window_size no
```

- 无边框 + 内边距，配合 niri 的 `prefer-no-csd` 和窗口规则的 `draw-border-with-background false`；
- `remember_window_size no`：每次由 niri 决定初始尺寸（列宽），避免窗口自己记一个奇怪的大小。

```conf
background_opacity 1.0
background_blur 0
```

- 这两行是「无 DMS 时」的默认值。实际透明度由 DMS 的 `terminalOpacity` 决定并写进 `dank-theme.conf`，覆盖这里；
- `background_blur` 显式设 0：kitty 的模糊要求平台支持，niri 没有窗口模糊，设成 32 也只是无效配置。

```conf
cursor_shape block
cursor_blink_interval 1
scrollback_lines 3000
copy_on_select yes
strip_trailing_spaces smart
shell_integration enabled
```

`shell_integration` 让 kitty 能识别 shell 提示符、支持 `ctrl+shift+←/→` 按提示符跳转、以及 `kitten` 的部分能力。

```conf
map ctrl+shift+n new_window
map ctrl+t new_tab
map ctrl+plus  change_font_size all +1.0
map ctrl+minus change_font_size all -1.0
map ctrl+0     change_font_size all 0
```

`ctrl+shift+n` 是 kitty 默认的新窗口键（默认就有，写出来是为了显式）；`ctrl+t` 新标签页；字号可用 `ctrl+0` 复位。

## 颜色与透明度从哪来

```
DMS 壁纸/主题  →  matugen  →  ~/.config/kitty/dank-theme.conf  →  kitty include
```

- 换壁纸 → DMS 重算调色板 → 重写 `dank-theme.conf` → kitty 重新加载（DMS 写文件后 kitty 会自行重载，必要时 `SIGUSR1`）；
- 透明度：设置 → 主题 → Opacity（`terminalOpacity` 10–100），DMS 会写入 `background_opacity 0.xx` + `dynamic_background_opacity yes`；
- `dynamic_background_opacity yes` 允许程序运行时用 OSC 序列再调透明度（例如某些 TUI 壁纸工具）。

## 模糊：在 niri 上做不到

kitty 手册：`background_blur` 只在「支持模糊的平台」且 `background_opacity < 1` 时生效。niri 26.04 没有窗口级模糊：

```bash
# 直接验证：blur 不是合法的 window-rule 节点
niri validate -c <(echo 'window-rule { match app-id="kitty"; blur }')
# Error: unexpected node
```

所以这里只能「透明」，不会「磨砂」。真要模糊需要换支持窗口模糊的合成器（Hyprland/KWin），在 KWin 下 kitty 的 `background_blur` 才有效。

## 与 niri / DMS 的配合

- niri 窗口规则里给 kitty 开了 `draw-border-with-background false`：透明时不会在窗口后面透出合成器画的边框块；
- 启动器 `Mod+Ctrl+Return` 和 `Mod+T` 都调用 `kitty`（见 [niri](./niri.md)）；
- DMS 的窗口规则、`dms/binds.kdl` 不需要改 kitty 配置。

## 常用命令

```bash
pkill -SIGUSR1 -x kitty          # 重载配置
kitty +kitten themes --help      # 浏览/切换内置主题（颜色仍会被 DMS 覆盖，仅参考）
kitten @ ls                      # 需要 allow_remote_control，列出窗口/标签
```

kitty 没有「导出最终合并配置」的开关，排查覆盖问题时直接比对两个文件里的同名项：
`kitty.conf` 在前、`dank-theme.conf` 在 include 之后，后者优先。
