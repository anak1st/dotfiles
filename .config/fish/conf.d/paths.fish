# 工具目录 -> PATH
#
# 原则：先探测、再添加。目录不存在就整个跳过，所以同一份配置可以同时用在
# macOS 和 Fedora 上：没装的工具不会报错，也不会把不存在的路径塞进 PATH。
#
# 顺序即优先级，越靠前越先被找到（fish_add_path 保持参数顺序）。
# 想换某个工具的优先级，改这个列表即可。

set -l tool_dirs \
    "$HOME/.local/bin" \
    "$HOME/.cargo/bin" \
    "$HOME/.opencode/bin" \
    "$HOME/.mimocode/bin" \
    "$HOME/.bun/bin"

set -l found
for dir in $tool_dirs
    if test -d "$dir"
        set -a found "$dir"
    end
end

# fish_add_path 自带去重：本文件被重复 source 也不会让 PATH 变长。
if set -q found[1]
    fish_add_path --global --prepend $found
end

# bun 靠 BUN_INSTALL 定位自己的安装根目录
if test -d "$HOME/.bun"
    set -gx BUN_INSTALL "$HOME/.bun"
end
