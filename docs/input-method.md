# 输入法：fcitx5 + Rime（雾凇拼音）

## 组件

- `fcitx5` — 输入法框架
- `fcitx5-rime` — Rime 前端
- `librime` / `brise` — Rime 引擎与默认方案数据
- `librime-lua` — 雾凇拼音的 Lua 功能
- `rime-ice` / 雾凇拼音 — 用户目录中的方案和词库
- `fcitx5-chinese-addons` — 自带拼音，作为备用输入法

## 安装

```bash
sudo dnf install fcitx5 fcitx5-chinese-addons fcitx5-configtool \
  fcitx5-gtk fcitx5-qt fcitx5-rime librime-lua
```

## 雾凇拼音

- 发布包：`https://github.com/iDvel/rime-ice/releases/latest/download/full.zip`
- 用户目录：`~/.local/share/fcitx5/rime/`
- 安装：清空用户目录后，将 `full.zip` 解压到该目录，重新部署
- 编译目录：`~/.local/share/fcitx5/rime/build/`，可删除，Rime 会重新生成
- 更新：重新覆盖 `full.zip`；自定义配置写入 `*.custom.yaml`，不要直接改方案文件

## fcitx5 输入法组

`~/.config/fcitx5/profile`：

```ini
[Groups/0]
Name=默认
Default Layout=us
DefaultIM=rime

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=rime
Layout=

[GroupOrder]
0=默认
```

## Classic UI

`~/.config/fcitx5/conf/classicui.conf`：

```ini
Theme=catppuccin-mocha-blue
Font=Noto Sans CJK SC 12
MenuFont=Noto Sans CJK SC 12
TrayFont=Noto Sans CJK SC 12
Vertical Candidate List=False
WheelForPaging=True
PreferTextIcon=False
ShowLayoutNameInIcon=True
UseInputMethodLanguageToDisplayText=True
UseDarkTheme=False
UseAccentColor=False
```

候选窗字体最终由 `classicui.conf` 的 `Font` 决定。

## 主题

Catppuccin for Fcitx5，Mocha + Blue：

- 仓库：`https://github.com/catppuccin/fcitx5`
- 主题目录：`~/.local/share/fcitx5/themes/catppuccin-mocha-blue/`
- 圆角：`enable-rounded.sh` 启用 `panel.svg` / `highlight.svg`
- 颜色：base `#1e1e2e`，surface `#313244`，blue `#89b4fa`，text `#cdd6f4`

安装：

```bash
git clone https://github.com/catppuccin/fcitx5.git
cd fcitx5
./enable-rounded.sh
mkdir -p ~/.local/share/fcitx5/themes
cp -r src/catppuccin-mocha-blue ~/.local/share/fcitx5/themes/
```

## 使用

- `Ctrl+Space` — 切换中英文
- `F4` — Rime 方案与选项菜单
- `fcitx5 -r` — 重载 / 重启
- `fcitx5-remote -n` — 当前输入法
- `fcitx5-remote -s rime` — 切到 Rime
- `fcitx5-diagnose` — 诊断环境变量、模块与前端

## niri 集成

环境变量与自启动见 [niri](./niri.md)。

```kdl
spawn-at-startup "fcitx5" "-d"
```

## 终端支持

- kitty 支持输入法，fcitx5 下可正常输入中文。

## 已知限制

- XWayland 应用依赖 `XMODIFIERS=@im=fcitx`，由 niri 的 `environment` 提供。

## IBus 备用

- `ibus`、`ibus-libpinyin` 仍然安装
- niri 下未启用，也没有自启动
- 需要时先停 fcitx5，再临时运行：

```bash
ibus start --type wayland
```
