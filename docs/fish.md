# fish

默认交互 shell，macOS 与 Linux 共用同一份配置（`dotfiles.json` 里 fish 条目没有限定 `os`）。

- `~/.config/fish/config.fish`（[仓库](../.config/fish/config.fish)）：只有交互 shell 才有意义的东西
- `~/.config/fish/conf.d/*.fish`（[仓库](../.config/fish/conf.d)）：环境准备，按文件名排序加载，先于 `config.fish`
- 重载：`exec fish`；只验证语法：`fish -n ~/.config/fish/config.fish`

## 拆分规则

一句话：**环境准备进 `conf.d/`，交互体验进 `config.fish`。**

| 内容 | 放哪 | 原因 |
|---|---|---|
| PATH 注入、代理变量、工具的 `env` 初始化 | `conf.d/<主题>.fish` | 非交互 shell（`fish -c`、脚本、编辑器调起的子进程）也需要 |
| 提示符、别名、键位、abbr | `config.fish` 的 `status is-interactive` 块里 | 只有交互 shell 用得上，早执行纯属浪费 |

注意 `conf.d` 片段**没有** `status is-interactive` 保护，所有片段都会在非交互 shell 里执行。所以：要么放在 `config.fish` 的交互块里，要么自己在片段里加这个判断。

不要按「一个工具一个文件」切太碎——PATH 类的琐碎注入全部集中到 `paths.fish` 的一张列表里，只有需要额外动作（探测端口、执行 `fnm env`）的才单独成文件。

## 现有片段

### conf.d/paths.fish

一张「目录列表 → PATH」的表，逐个 `test -d` 探测，只有存在的目录才会被 `fish_add_path --global --prepend` 加进去：

```fish
set -l tool_dirs \
    "$HOME/.local/bin" \
    "$HOME/.cargo/bin" \
    "$HOME/.opencode/bin" \
    "$HOME/.mimocode/bin" \
    "$HOME/.bun/bin"
```

- 列表顺序就是优先级，越靠前越先被找到；
- `fish_add_path` 自带去重，重复 source 也不会让 PATH 变长；
- 新增工具只加一行，不需要新建文件；
- `~/.cargo/bin` 以前靠 rustup 生成的 `conf.d/rustup.fish`（`source ~/.cargo/env.fish`），现在由这里统一管，那份生成物可以删掉；
- `BUN_INSTALL` 只在 `~/.bun` 存在时才导出。

### conf.d/fnm.fish

fnm 单独成文件，因为它不止加 PATH，还要执行 `fnm env`。

判断条件是**可执行文件**而不是目录，这是关键：

```fish
if test -x "$dir/fnm"
    fish_add_path --global --prepend "$dir"
```

不同安装方式的可执行文件位置：

| 安装方式 | `fnm` 在哪 | 需要额外加 PATH 吗 |
|---|---|---|
| Homebrew（macOS） | `/opt/homebrew/bin/fnm` | 不需要 |
| COPR `dnf install fnm`（Fedora） | `/usr/bin/fnm` | 不需要 |
| `cargo install fnm` | `~/.cargo/bin/fnm` | 不需要（`paths.fish` 已覆盖） |
| `curl -fsSL https://fnm.vercel.app/install \| bash` | `$XDG_DATA_HOME/fnm` 或 `~/.local/share/fnm` | **需要** |

官方的 curl 安装脚本会把二进制放进数据目录，并且自己往 `~/.config/fish/conf.d/fnm.fish` 写一段 `set PATH ...`。那段是脚本生成的，不是文档要求手写的；用 `test -x` 判断后，脚本方式仍然能用，brew 方式则自动跳过（`~/.local/share/fnm` 里只有 `node-versions/`、`aliases/` 这类数据）。

`fnm env --shell fish` 输出的第一行就是给当前版本用的 PATH：

```fish
set -gx PATH "/Users/you/.local/state/fnm_multishells/<pid>_<ts>/bin" $PATH;
```

`--use-on-cd` 让进入含 `.node-version` / `.nvmrc` / `package.json` 的目录时自动切版本。`type -q fnm` 保证没装 fnm 的机器不报错。

**不要**把某个具体版本的目录硬编码进 PATH（例如 `~/.local/share/fnm/node-versions/v24.18.0/installation/bin`）：换版本就失效，还会和 `fnm env` 抢优先级。

### conf.d/proxy.fish

本地代理（Clash/Mihomo 默认 `127.0.0.1:7890`），设 `http_proxy` / `https_proxy` / `no_proxy`，同时提供一个 `proxy` 命令手动开关。

| 命令 | 作用 |
|---|---|
| `proxy on` | 强制开启，不探测（`nc` 没装时也能用） |
| `proxy off` | 清掉 `http_proxy` / `https_proxy` / `no_proxy` |
| `proxy` / `proxy status` | 当前状态，不探测 |
| `proxy auto` | 重新探测一次并按结果开关 |
| `-q` / `--quiet` | 不输出，只执行；可放在任意位置（`proxy -q auto`、`proxy auto -q` 都行） |

输出统一为一行 `key=value` 字段：

```console
$ proxy status
proxy=on http_proxy=http://127.0.0.1:7890

$ proxy auto
proxy=on probe=open http_proxy=http://127.0.0.1:7890

$ proxy auto          # 端口没开
proxy=off probe=closed

$ proxy -q off        # 不输出
```

字段含义：

| 字段 | 取值 |
|---|---|
| `proxy` | `on` / `off`，当前 shell 的状态 |
| `probe` | `open` / `closed` / `nc-missing`，仅 `proxy auto` 里有 |
| `http_proxy` | 代理地址，`proxy` 为 `on` 时才有 |

探测只依赖 `nc`（`nc -z -w 1`）：macOS 自带，Fedora 需要 `dnf install nmap-ncat`。**没装 `nc` 就不探测、也不自动开**（`probe=nc-missing`），避免给 curl / git / pip 挂上一个未必存在的代理——那种故障（超时、卡住）比不设更难查。

启动时跑的就是 `proxy auto`：父进程已有 `http_proxy` 就跳过，不覆盖；交互终端里显示结果（写 stderr），其它情况用 `-q` 静默执行。也就是说每个新开终端会看到一行 `proxy=...`。

`fish -c ...` 这类非交互调用完全静默，不会往脚本输出里塞字；提示写 stderr，`fish -i -c 'cmd'` 的 stdout 仍然干净。手动跑 `proxy ...` 时输出走 stdout，管道、重定向都照常。

临时不要代理：`http_proxy= fish`（父进程已带就整段跳过，自动探测不会覆盖）。

## config.fish

只放交互内容：

```fish
if status is-interactive
    if type -q starship
        starship init fish | source
    end
end
```

`starship init` 是提示符初始化，非交互 shell 里没有任何意义，所以放在这个块里、并用 `type -q` 兜底。

## 排错

```bash
fish -n ~/.config/fish/config.fish              # 语法检查（也可以对 conf.d 下的文件跑）
fish -c 'echo $PATH | tr " " "\n"'              # 非交互 shell 的最终 PATH
fish -c 'set -S fish_user_paths'                # fish 自己维护的路径，看 scope 和顺序
fish -c 'echo $http_proxy $no_proxy'            # 代理是否被设上
fish -c 'type -a node'                          # 哪个 node 胜出
```

- PATH 顺序不对：先看 `fish_user_paths` 里的顺序（`fish_add_path` 保持参数顺序），再看是不是 `fish_variables` 里还留着旧条目——universal 变量会一直存在，`set -U fish_user_paths <保留下来的条目...>` 可以清掉。
- 代理没生效：先跑 `proxy status` 看状态和探测结果；再确认 7890 端口在监听、`nc` 有没有装、父进程是不是已经带了 `http_proxy`。
