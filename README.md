# dotfiles

仓库根目录对应 `~`，但**安装由清单驱动**，不会把根目录整个复制到 home。

## 结构

```
dotfiles/
├── dotfiles.json          # 清单：source → target，可限定 os
├── install.py             # 安装/更新：仓库 → $HOME
├── sync.py                # 同步/回收：$HOME → 仓库
├── docs/                  # 每个软件一份说明（入口：docs/README.md）
├── .config/nvim/          # Neovim 配置（macOS / Linux 共用）
└── .config/ghostty/       # Ghostty 配置（仅 macOS）
```

各软件的配置归属、DMS 生成物边界、排错方式，见 [docs/README.md](./docs/README.md)。

## 用法

```bash
python3 install.py             # 安装或更新到 $HOME（覆盖前自动备份）
python3 install.py --dry-run   # 只看计划
python3 sync.py                # 把本机改动同步回仓库
python3 sync.py --prune        # 同时删掉仓库里本机已不存在的文件
```

两个脚本都支持 `--os macos|linux` 强制平台、`--home DIR` 指定目标根目录（测试用）。
默认按 `platform.system()` 自动识别。

- 按**文件**逐个比较：内容相同就跳过，不同才覆盖。
- 覆盖前备份到 `~/.dotfiles-backup/<时间戳>/<原路径>`，可用 `--no-backup` 关闭。
- `sync.py` 只处理清单里的条目，不会碰仓库里的其他文件。
- 脚本**不安装任何程序**（不跑 brew/apt），只负责 dotfiles 的复制。

## 新增一条 dotfile

编辑 `dotfiles.json`，`source` 是仓库内路径，`target` 相对 `~`，仓库路径直接镜像 home：

```json
{ "source": ".config/ghostty/config.ghostty",
  "target": ".config/ghostty/config.ghostty",
  "os": ["macos"] }
```

- 目录条目会展开成逐文件覆盖，适合整个目录都属于你的配置（比如 nvim）。
- 想精确到单个文件，就一条列一个文件。
- `os` 省略时默认 `["macos", "linux"]`。

## 平台差异

平台差异只写在条目的 `os` 字段里，不另建目录层。两个平台需要同一目标路径、
但内容不同时，用不同的 source 文件名区分即可：

```json
{ "source": ".config/ghostty/config.ghostty", "target": ".config/ghostty/config.ghostty", "os": ["macos"] },
{ "source": ".config/ghostty/config.linux",   "target": ".config/ghostty/config.ghostty", "os": ["linux"] }
```

## 测试

用临时根目录跑，不会动真实 home：

```bash
python3 install.py --home /tmp/fake-home --dry-run
```
