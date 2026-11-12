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

本地代理（Clash/Mihomo 默认 `127.0.0.1:7890`），设 `http_proxy` / `https_proxy` / `no_proxy`。

设之前先探测端口（`nc -z`，没有 `nc` 就用 bash 的 `/dev/tcp`），**连不上就不设**——挂一个连不上的代理，故障表现（curl 超时、pip 卡住）比没代理更难判断。

设上之后会往 stderr 打一行提示：

```
proxy on: http://127.0.0.1:7890
```

只在**交互 shell 且 stderr 是终端**时打印：`fish -c ...` 这类非交互调用、以及 stderr 被重定向到文件/管道的情况都不会多出这一行，所以脚本输出和 `$(...)` 捕获不会被污染。提示写 stderr 而不是 stdout，`fish -i -c 'cmd'` 的 stdout 仍然干净。

关闭方式：父进程已导出 `http_proxy` 时整段跳过，所以 `http_proxy= fish` 就能起一个不带代理的 shell。端口探测失败时也不会设，本机不开 Clash 就不会有残留变量。

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
- 代理没生效：确认 7890 端口在监听（`nc -z 127.0.0.1 7890`）、父进程没有带 `http_proxy`。
