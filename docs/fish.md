# fish

默认交互 shell。仓库里只有三个文件，都是「放东西进 PATH」这类环境准备。

- `~/.config/fish/config.fish`（仓库：[`.config/fish/config.fish`](../.config/fish/config.fish)）
- `~/.config/fish/conf.d/*.fish`（按文件名排序加载，先于 `config.fish`）
- 重载：`exec fish`，或 `source ~/.config/fish/config.fish`

## 加载顺序

fish 启动时先按字母序 source `conf.d/` 下的所有 `.fish`，再 source `config.fish`。

所以：**工具的环境准备放 `conf.d/<工具名>.fish`，全局的交互设置放 `config.fish`**。这样每个工具一个文件，增删互不影响，也不需要在 `config.fish` 里堆 if。

## config.fish

```fish
if status is-interactive
# Commands to run in interactive sessions can go here
end
```

目前是空的骨架。`status is-interactive` 保证只在交互 shell 里执行——注意 fish 的 `conf.d` 片段**没有**这个保护，写提示符、别名之类要自己判断。

## conf.d/fnm.fish

```fish
set -l fnm_dir "$HOME/.local/share/fnm"
if test -d "$fnm_dir"
    fish_add_path --global --prepend "$fnm_dir"
end

if type -q fnm
    fnm env --use-on-cd --shell fish | source
end
```

- `fish_add_path --global --prepend`：写入全局 `fish_user_paths`，只添加一次，不会重复堆叠；
- `--use-on-cd`：进入含 `.node-version` / `.nvmrc` / `package.json` 的目录时自动 `fnm use`，切换 Node 版本；
- `type -q fnm` 先判断再执行，没装 fnm 的机器不会报错。

## conf.d/opencode.fish

```fish
if test -d "$HOME/.opencode/bin"
    fish_add_path --global --prepend "$HOME/.opencode/bin"
end
```

只在目录存在时把 opencode 加进 PATH。

## 排错

```bash
fish -n ~/.config/fish/conf.d/fnm.fish      # 语法检查
fish -c 'echo $PATH | tr " " "\n"'          # 看最终 PATH
fish -c 'set -S fish_user_paths'            # 看 fish 自己维护的路径
```

PATH 重复/顺序不对时，先确认是不是同一个目录被加了两次（`fish_add_path` 会去重，手写 `set -x PATH` 不会）。

## 与桌面其他部分的关系

- 终端是 kitty（见 [kitty](./kitty.md)），fish 由 kitty 的 `shell_integration` 增强提示符识别；
- fish 不参与输入法配置，但 `SDL_IM_MODULE` 等变量来自 niri 的 `environment {}`，不是 fish。
