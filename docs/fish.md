# fish

默认交互 shell，macOS 与 Linux 共用同一份配置（`dotfiles.json` 里 fish 条目没有限定 `os`）。

- `~/.config/fish/config.fish`（[仓库](../.config/fish/config.fish)）：只有交互 shell 才有意义的东西
- `~/.config/fish/conf.d/*.fish`（[仓库](../.config/fish/conf.d)）：环境准备，按文件名排序加载，先于 `config.fish`
- 重载：`exec fish`；只验证语法：`fish -n <文件>`

每个片段**头部的注释**就是它自己的说明书：用法、输出格式、为什么这么写，都放在文件里。这里只讲整体分工和排错。

## 拆分规则

一句话：**环境准备进 `conf.d/`，交互体验进 `config.fish`。**

| 内容 | 放哪 | 原因 |
|---|---|---|
| PATH 注入、代理变量、工具的 `env` 初始化 | `conf.d/<主题>.fish` | 非交互 shell（`fish -c`、脚本、编辑器调起的子进程）也需要 |
| 提示符、别名、键位、abbr | `config.fish` 的 `status is-interactive` 块里 | 只有交互 shell 用得上，早执行纯属浪费 |

注意 `conf.d` 片段**没有** `status is-interactive` 保护，所有片段都会在非交互 shell 里执行。所以：要么放在 `config.fish` 的交互块里，要么自己在片段里加这个判断。

不要按「一个工具一个文件」切太碎：PATH 类的琐碎注入集中到 `paths.fish`，只有需要额外动作（探测端口、执行 `fnm env`）的才单独成文件。

## 现有片段

### conf.d/paths.fish

一行一个目录，**目录存在、且 PATH 里还没有**才插到最前面，越靠下的行优先级越高。

加了第二个判断是因为嵌套 shell：从 fish 里启动的 GUI、IDE、tmux 会继承父进程的 PATH，
无条件 prepend 会让 `~/.local/bin` 这类目录出现好几次。代价是已经在 PATH 里的目录
不会被提到最前——原来的位置保持不变，所以优先级只对「本次新加的目录」生效。

### conf.d/fnm.fish

单独成文件，因为它不止加 PATH，还要执行 `fnm env`。先看 `fnm` 命令在不在，只有在找不到时才去数据目录里找二进制（只有 curl 安装才会那样）；brew / dnf / cargo 装的直接跳过。`--use-on-cd` 让进入项目目录时自动切 Node 版本。

### conf.d/proxy.fish

本地代理开关（Clash / Mihomo 默认 7890），四个模式 `on` / `off` / `auto` / `status`，输出一行 `k=v`。模式必填且必须写在第一个参数（单敲 `proxy` 是用法错误）。`auto` 用 `nc` 探测端口，没装 `nc` 就不探测、也不自动开；启动时自动跑一次 `auto`，父进程已有 `http_proxy` 就不覆盖。

## config.fish

只放交互内容：starship 提示符初始化，用 `status is-interactive` 包住、`type -q` 兜底。

## 排错

- 语法：`fish -n <文件>`
- 非交互 shell 的最终 PATH：`fish -c 'echo $PATH | tr " " "\n"'`
- 代理有没有设上：`fish -c 'echo $http_proxy $no_proxy'`，或者 `proxy status`
- 哪个 node 胜出：`fish -c 'type -a node'`
- PATH 顺序不对：优先级只看 `paths.fish` 里的行序（越靠下越靠前）。如果 `fish_variables` 里有 `fish_user_paths` 条目，它们会插到 PATH 前面：`fish -c 'set -S fish_user_paths'` 查看，`set -eU fish_user_paths` 清掉。
- 代理没生效：先跑 `proxy status` 看状态和探测结果；再确认 7890 端口在监听、`nc` 有没有装、父进程是不是已经带了 `http_proxy`。
