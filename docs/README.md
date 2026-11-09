# 桌面配置文档

记录当前 Linux 桌面的最终配置与维护方式。

## 环境

- Fedora Linux 45
- niri 26.04
- DankMaterialShell（DMS）
- 终端：kitty
- 输入法：fcitx5 + Rime（雾凇拼音）
- 候选窗字体：Noto Sans CJK SC

## 文档

- [niri](./niri.md) — 主配置、环境变量、自启动、DMS 生成文件
- [输入法](./input-method.md) — fcitx5 + Rime 雾凇拼音、主题、使用与限制
- [字体](./fonts.md) — kitty 与 fcitx5 的字体选择

## 配置落地

本仓库通过 `dotfiles.json` 清单安装，仓库根目录对应 `~`：

```bash
python3 install.py     # 仓库 -> $HOME
python3 sync.py        # $HOME -> 仓库
```

`dms/` 等自动生成文件不纳入本仓库。
