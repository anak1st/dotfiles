# fnm (Fast Node Manager) —— https://github.com/Schniz/fnm
#
# 先确保 fnm 这个命令能找到，再让它初始化。
#
# 只有 curl 安装脚本会把二进制塞进数据目录、需要自己加 PATH：
#   brew                      /opt/homebrew/bin/fnm          已有 PATH
#   dnf (COPR)                /usr/bin/fnm                   已有 PATH
#   cargo install fnm         ~/.cargo/bin/fnm               已有 PATH（paths.fish 管的）
#   curl 安装脚本             Linux  ~/.local/share/fnm/fnm
#                             macOS  ~/Library/Application Support/fnm/fnm
#                             这两个位置要自己加进 PATH
#
# 用 test -x 而不是 test -d：brew 装的 ~/.local/share/fnm 里只有 node-versions/、
# aliases/ 这类数据，没有可执行文件，test -d 会把数据目录当成 bin 目录。

if not type -q fnm
    if test -x "$HOME/.local/share/fnm/fnm"
        set -gx PATH "$HOME/.local/share/fnm" $PATH
    else if test -x "$HOME/Library/Application Support/fnm/fnm"
        set -gx PATH "$HOME/Library/Application Support/fnm" $PATH
    end
end

if type -q fnm
    # --use-on-cd：进入含 .node-version / .nvmrc / package.json 的目录时自动切版本。
    # 具体版本的目录（node-versions/<ver>/installation/bin）不要硬编码进 PATH：
    # 换版本就失效，还会和 fnm env 抢优先级。
    fnm env --use-on-cd --shell fish | source
end
