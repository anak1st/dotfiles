# 字体

两个场景，两套字体：终端用等宽，输入法候选窗用中文 UI 字体。

## kitty（终端）

`~/.config/kitty/kitty.conf`：

```conf
font_family Maple Mono NF CN
font_size 12.0
```

- 字体目录：`~/.local/share/fonts/maple-mono-nf-cn/`
- 安装后刷新缓存：`fc-cache -f`
- Maple Mono 是等宽字体，带 Nerd Font 图标和中文回退，适合终端，不用于候选窗

终端其余配置见 [kitty](./kitty.md)。

## fcitx5（候选窗）

`~/.config/fcitx5/conf/classicui.conf`：

```ini
Theme=catppuccin-mocha-blue
Font=Noto Sans CJK SC 12
MenuFont=Noto Sans CJK SC 12
TrayFont=Noto Sans CJK SC 12
```

- `Font`、`MenuFont`、`TrayFont` 统一用 Noto Sans CJK SC（思源黑体），字号 12；
- 主题 `catppuccin-mocha-blue` 与 DMS 生成的 `dms` 主题并存，切换后需要 `fcitx5-remote -r`；
- 这个文件目前**还没有纳入仓库**（`dotfiles.json` 里只登记了 `profile` 和 `conf/` 下另外四个文件），换机器会丢，建议补一条 entry。

输入法整体配置见 [fcitx5](./fcitx5.md)。

## 选择理由

- Noto Sans CJK SC 是 Linux 中文社区最常用的常规 UI 字体，中英文比例正常；
- 等宽字体（Maple、Sarasa 等）中文会显得偏宽，不适合候选窗；
- 终端反而需要等宽 + 图标，所以两者不共用字体是正确的。

其他可选（候选窗）：

- MiSans（小米，官网下载）
- HarmonyOS Sans SC（官网下载）
- LXGW WenKai / 霞鹜文楷（开源，偏阅读风格）
- Source Han Sans SC 与 Noto Sans CJK SC 是同一套设计

## 查看与匹配

```bash
fc-list :lang=zh family | sort -u    # 系统中所有中文字体族
fc-match "Noto Sans CJK SC"          # 实际匹配到的文件
fc-match monospace                   # 等宽回退
```

## Ghostty（macOS）

同一套 Maple Mono NF CN，字号 15，配置见 [ghostty](./ghostty.md)。
