# dotfiles

仓库根目录对应 `~`，但**安装由清单驱动**，不会把根目录整个复制到 home。

## 结构

```
dotfiles/
├── dotfiles.json        # 清单：source(仓库内) → target(相对 ~)，可限定 os
├── install.py           # 安装/更新：仓库 → $HOME
├── sync.py              # 同步/回收：$HOME → 仓库
└── .config/nvim/        # 当前唯一一份配置，macOS / Linux 共用
```

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

编辑 `dotfiles.json`，`source` 是仓库内路径，`target` 相对 `~`：

```json
{
  "source": ".config/nvim",
  "target": ".config/nvim",
  "os": ["macos", "linux"]
}
```

- 目录条目会展开成逐文件覆盖，适合整个目录都属于你的配置（比如 nvim）。
- 想精确到单个文件，就一条列一个文件；`source` 也可以直接指向 `os/<平台>/...`。
- `os` 省略时默认 `["macos", "linux"]`。

## 平台专属文件

约定放在 `os/<平台>/` 下，路径仍按 home 镜像：

```json
{ "source": "os/linux/.bashrc",     "target": ".bashrc",     "os": ["linux"] },
{ "source": "os/macos/.tmux.conf",  "target": ".tmux.conf",  "os": ["macos"] }
```

同一 target 在通用和平台专属里都出现时，后写的条目会覆盖前面的（按清单顺序）。

## 测试

用临时根目录跑，不会动真实 home：

```bash
python3 install.py --home /tmp/fake-home --dry-run
```
