# fnm (Fast Node Manager)
# https://github.com/Schniz/fnm

set -l fnm_dir "$HOME/.local/share/fnm"
if test -d "$fnm_dir"
    fish_add_path --global --prepend "$fnm_dir"
end

if type -q fnm
    # 自动切换 Node 版本：进入包含 .node-version / .nvmrc / package.json 的目录时执行 fnm use
    fnm env --use-on-cd --shell fish | source
end
