# 桌面配置文档

记录当前 Linux 桌面的组成、每层配置的归属，以及各软件的维护方式。

## 环境

| 组件 | 版本 / 形态 |
|---|---|
| 系统 | Fedora Linux 45 |
| 合成器 | niri 26.04（Wayland） |
| 桌面壳 | DankMaterialShell（DMS）2.1.2 |
| 终端 | kitty（Linux）、Ghostty（macOS） |
| 输入法 | fcitx5 5.1.23 + Rime（雾凇拼音） |
| Shell | fish |
| 编辑器 | Neovim + LazyVim |

## 四层模型

判断一个文件「该不该改、该不该进仓库」，只需要问两个问题：**谁写它**、**升级后会不会被覆盖**。

```
/usr/share/quickshell/dms/     发行层：包管理器管理，升级即覆盖
        │ 读取
        ▼
~/.config/dms/                 状态层：DMS 自己读写的运行时配置与状态
        │ 派生
        ▼
~/.config/niri/dms/*.kdl       派生层：由状态与主题生成，文件头写着 DO NOT EDIT
~/.config/kitty/dank-*.conf
~/.config/dms/firefox.css
        ▲ 参照
        │
~/.config/niri/config.kdl      源层：手写的配置（= 本仓库管理的那一层）
~/.config/kitty/kitty.conf
~/.config/fcitx5/config
```

| 层 | 代表路径 | 能不能改 | 进仓库吗 |
|---|---|---|---|
| 发行层 | `/usr/share/quickshell/dms` | 不改，升级会被覆盖 | 否 |
| 状态层 | `~/.config/dms/settings.json` | 通过 DMS 界面或 `dms ipc` 改 | 有例外：`settings.json` 已跟踪（固定栏布局）；`session.json`/缓存不跟踪 |
| 派生层 | `~/.config/niri/dms/`、`dank-*.conf` | 不手改，由 DMS 重写 | **否** |
| 源层 | 本文档索引里各软件的配置 | 随便改，改完同步回仓库 | 是 |

## 文档索引

| 文档 | 内容 |
|---|---|
| [niri](./niri.md) | 主配置结构、环境变量、窗口规则、include 机制、已知问题 |
| [dms](./dms.md) | DMS 架构、settings/session 的区别、主题管线、生成物清单、IPC 命令 |
| [kitty](./kitty.md) | 终端配置、颜色与透明度的来源、键位、重载方式 |
| [fcitx5](./fcitx5.md) | 输入法框架、Rime 雾凇、Win+Space 两层机制、共享输入状态 |
| [fish](./fish.md) | shell 配置、conf.d 片段、PATH 注入 |
| [ghostty](./ghostty.md) | macOS 终端配置、与 Linux 侧的差异 |
| [neovim](./neovim.md) | LazyVim 目录结构、锁文件、与 DMS 主题的关系 |
| [字体](./fonts.md) | kitty 与 fcitx5 的字体选择与匹配 |

## 仓库约定

本仓库根目录对应 `~`，但**安装由清单驱动**：`dotfiles.json` 里没登记的路径，安装和同步都不会碰。

```bash
python3 install.py             # 仓库 -> $HOME，全部 app（覆盖前备份到 ~/.dotfiles-backup）
python3 install.py fish nvim   # 只装点名的 app
python3 install.py --list      # 清单里有哪些 app、各几个文件、支持哪些平台
python3 install.py --dry-run   # 只看计划
python3 sync.py                # $HOME -> 仓库，全部 app（只处理清单里的条目）
python3 sync.py dms            # 只回收某个 app 的改动
python3 sync.py --prune        # 顺便删除仓库里已不存在的文件
```

每条 entry 都带一个 `app` 字段，命令行按它选择处理哪几个软件；不传就是全部。

两条硬规则：

1. **只跟踪源文件**。DMS 生成的 `dms/*.kdl`、`dank-*.conf`、`firefox.css` 等一律不进仓库，否则换主题时会出现无法解释的 diff。
2. **一个文件一条 entry**。目录条目会把目录下所有文件都算进去，容易把生成物卷进来（见 [neovim](./neovim.md) 里的隐患）。

另外：**一个文件只属于一个 app**。想同时归到两类（比如「shell 相关」和「fish」）时，
说明分组粒度选错了——`app` 是选择安装范围的单位，不是分类标签。

## 常用命令速查

```bash
niri validate                              # 校验 niri 配置（改完必跑）
niri msg outputs                           # 显示器名称与模式
dms doctor                                 # DMS 安装/依赖自检
dms restart                                # 重启 DMS（改状态文件后用）
dms keybinds show niri                     # 导出全部键位（JSON）
pkill -SIGUSR1 -x kitty                    # 让 kitty 重载配置
fcitx5-remote -t                           # 切换输入法
fcitx5-remote -r                           # 重载 fcitx5 配置
```

## 一次改动的完整流程

1. 改**仓库里**的文件（`~/.config/...` 是安装后的副本，直接改会丢）；
2. 跑 `python3 install.py <app> --dry-run` 确认计划，再正式安装；
3. 按软件要求重载（niri 自动监听 `config.kdl`，kitty 发 `SIGUSR1`，fcitx5 `-r`，DMS `dms restart`）；
4. 用 `python3 sync.py <app>` 把运行时又调过的内容收回仓库；
5. `git add -A && git commit`。
