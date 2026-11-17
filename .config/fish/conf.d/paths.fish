# 工具目录 -> PATH
#
# 目录存在、PATH 里还没有，才插到最前面。
# 越靠下的行优先级越高，~/.local/bin 写在最下面。
# 新增工具：复制三行、改路径。

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
