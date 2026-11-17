# 工具目录 -> PATH
#
# 两重探测、再添加：目录不存在就整段跳过，所以同一份配置可以同时用在 macOS
# 和 Fedora 上，没装的工具不会报错，也不会把不存在的路径塞进 PATH。
# PATH 里已经有了也跳过：嵌套 shell（从 fish 里启动的 GUI、IDE、tmux）会继承
# 父进程的 PATH，无条件 prepend 会让同一个目录出现好几次。
#
# 越靠下写的行优先级越高（每行都插到 PATH 最前面），~/.local/bin 写在最下面。
# 新增工具就是复制三行、改个路径。

if test -d "$HOME/.bun/bin"
    and not contains "$HOME/.bun/bin" $PATH
    set -gx PATH "$HOME/.bun/bin" $PATH
end

if test -d "$HOME/.mimocode/bin"
    and not contains "$HOME/.mimocode/bin" $PATH
    set -gx PATH "$HOME/.mimocode/bin" $PATH
end

if test -d "$HOME/.opencode/bin"
    and not contains "$HOME/.opencode/bin" $PATH
    set -gx PATH "$HOME/.opencode/bin" $PATH
end

if test -d "$HOME/.cargo/bin"
    and not contains "$HOME/.cargo/bin" $PATH
    set -gx PATH "$HOME/.cargo/bin" $PATH
end

if test -d "$HOME/.local/bin"
    and not contains "$HOME/.local/bin" $PATH
    set -gx PATH "$HOME/.local/bin" $PATH
end
