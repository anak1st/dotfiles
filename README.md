# dotfiles

仓库根目录对应 `~`，但**安装由清单驱动**，不会把根目录整个复制到 home。

## 结构

```
dotfiles/
├── dotfiles.json          # 清单：app + source → target，可限定 os
├── install.py             # 安装/更新：仓库 → $HOME
├── sync.py                # 同步/回收：$HOME → 仓库
├── docs/                  # 每个软件一份说明（入口：docs/README.md）
├── .config/nvim/          # Neovim 配置（macOS / Linux 共用）
├── .config/fish/          # fish 配置（macOS / Linux 共用）
└── .config/ghostty/       # Ghostty 配置（仅 macOS）
```

各软件的配置归属、DMS 生成物边界、排错方式，见 [docs/README.md](./docs/README.md)。

## 用法

```bash
python3 install.py              # 安装或更新所有 app 到 $HOME（覆盖前自动备份）
python3 install.py fish nvim    # 只装点名的 app
python3 install.py --list       # 列出清单里的 app、文件数和适用平台
python3 install.py --dry-run    # 只看计划
python3 sync.py                 # 把所有本机改动同步回仓库
python3 sync.py dms             # 只把 dms 的改动回收进仓库
python3 sync.py --prune         # 同时删掉仓库里本机已不存在的文件
```

两个脚本都支持 `--os macos|linux` 强制平台、`--home DIR` 指定目标根目录（测试用）。
默认按 `platform.system()` 自动识别。

- **按 app 选择**：位置参数就是 app 名，不传等于全部；`--list` 可查有哪些。
  打错名字会直接报错并列出可用名字；点名了但在当前平台没有条目的 app 也会报错，
  避免“看起来成功、其实什么都没干”。
- 按**文件**逐个比较：内容相同就跳过，不同才覆盖。
- 覆盖前备份到 `~/.dotfiles-backup/<时间戳>/<原路径>`，可用 `--no-backup` 关闭。
- `sync.py` 只处理清单里的条目，不会碰仓库里的其他文件。
- 脚本**不安装任何程序**（不跑 brew/apt），只负责 dotfiles 的复制。

## 新增一条 dotfile

编辑 `dotfiles.json`：`app` 是所属软件，`source` 是仓库内路径，`target` 相对 `~`，仓库路径直接镜像 home：

```json
{ "app": "ghostty",
  "source": ".config/ghostty/config.ghostty",
  "target": ".config/ghostty/config.ghostty",
  "os": ["macos"] }
```

- `app` 必填，会直接当命令行参数用，所以只允许字母、数字和 `._-`，不能有空格。
- 一个文件只属于一个 app；新软件就起个新名字，装/同步时可以单独点名。
- 目录条目会展开成逐文件覆盖，适合整个目录都属于你的配置（比如 nvim）。
- 想精确到单个文件，就一条列一个文件。
- `os` 省略时默认 `["macos", "linux"]`。
- 清单按 app 字母序分组；组内按平台（`["macos", "linux"]` → `["macos"]` → `["linux"]`）、
  再按 `source` 字母序排序，方便扫读和 diff。

## 平台差异

平台差异只写在条目的 `os` 字段里，不另建目录层。两个平台需要同一目标路径、
但内容不同时，用不同的 source 文件名区分即可：

```json
{ "app": "ghostty", "source": ".config/ghostty/config.ghostty",
  "target": ".config/ghostty/config.ghostty", "os": ["macos"] },
{ "app": "ghostty", "source": ".config/ghostty/config.linux",
  "target": ".config/ghostty/config.ghostty", "os": ["linux"] }
```

## 测试

用临时根目录跑，不会动真实 home：

```bash
python3 install.py --home /tmp/fake-home --dry-run
```
