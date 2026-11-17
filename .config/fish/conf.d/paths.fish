# 工具目录 -> PATH
#
# 先探测、再添加：目录不存在就整段跳过，所以同一份配置可以同时用在 macOS
# 和 Fedora 上，没装的工具不会报错，也不会把不存在的路径塞进 PATH。
#
# 越靠下写的行优先级越高（每行都插到 PATH 最前面），~/.local/bin 写在最下面。
# 新增工具就是复制三行、改个路径。

if test -d "$HOME/.bun/bin"
    set -gx PATH "$HOME/.bun/bin" $PATH
end

if test -d "$HOME/.mimocode/bin"
    set -gx PATH "$HOME/.mimocode/bin" $PATH
end

if test -d "$HOME/.opencode/bin"
    set -gx PATH "$HOME/.opencode/bin" $PATH
end

if test -d "$HOME/.cargo/bin"
    set -gx PATH "$HOME/.cargo/bin" $PATH
end

if test -d "$HOME/.local/bin"
    set -gx PATH "$HOME/.local/bin" $PATH
end
