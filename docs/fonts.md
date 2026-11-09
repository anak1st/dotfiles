# 字体

## kitty

`~/.config/kitty/kitty.conf`：

```conf
font_family Maple Mono NF CN
font_size 12
```

- 字体目录：`~/.local/share/fonts/maple-mono-nf-cn/`
- 安装后刷新缓存：`fc-cache -f`
- Maple Mono 是等宽字体，适合终端，不用于输入法候选窗

## fcitx5

- 候选窗字体：`Noto Sans CJK SC 12`（思源黑体）
- 配置位置：`~/.config/fcitx5/conf/classicui.conf`
- `Font`、`MenuFont`、`TrayFont` 都使用该字体
- 主题文件 `[InputPanel] Font` / `[Menu] Font` 同步为相同字号

选择理由：

- Noto Sans CJK SC 是 Linux 中文社区最常用的常规 UI 字体，中英文比例正常
- 等宽字体（Maple、Sarasa 等）中文会显得偏宽，不适合候选窗

其他可选：

- MiSans（小米，官网下载）
- HarmonyOS Sans SC（官网下载）
- LXGW WenKai / 霞鹜文楷（开源，偏阅读风格）
- Source Han Sans SC 与 Noto Sans CJK SC 是同一套设计

## 查看与匹配

```bash
fc-list :lang=zh family | sort -u
fc-match "Noto Sans CJK SC"
```
