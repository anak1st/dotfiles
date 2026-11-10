# fnm (Fast Node Manager) —— https://github.com/Schniz/fnm
#
# 要不要往 PATH 里加目录，取决于「fnm 可执行文件在哪」，而不是「数据目录在不在」：
#   brew / dnf(COPR) / cargo   二进制已经在 PATH 里 -> 只需要 fnm env
#   curl 安装脚本 / 手动解压     二进制就在 FNM_DIR 里   -> 得先把该目录加进 PATH
# 所以这里用 test -x 而不是 test -d：brew 安装时 ~/.local/share/fnm 只有
# node-versions/ 这类数据，没有可执行文件，不该被当成 bin 目录。

set -l fnm_dirs
if set -q XDG_DATA_HOME; and test -n "$XDG_DATA_HOME"
    set -a fnm_dirs "$XDG_DATA_HOME/fnm"
end
# 后两个是 Linux 与 macOS 上 curl 安装脚本的默认位置
set -a fnm_dirs "$HOME/.local/share/fnm" "$HOME/Library/Application Support/fnm"

for dir in $fnm_dirs
    if test -x "$dir/fnm"
        fish_add_path --global --prepend "$dir"
        break
    end
end

if type -q fnm
    # --use-on-cd：进入含 .node-version / .nvmrc / package.json 的目录时自动切换版本
    fnm env --use-on-cd --shell fish | source
end
