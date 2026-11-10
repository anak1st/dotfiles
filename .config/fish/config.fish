# fish 全局配置
#
# 分工（详见 docs/fish.md）：
#   conf.d/*.fish  环境准备：PATH、代理、工具初始化。启动时先于本文件执行，
#                  对非交互 shell 也生效。
#   本文件         只有交互 shell 才有意义的东西：提示符、别名、键位。
#
# conf.d 里的片段没有 status is-interactive 保护，所以交互专属内容放这里。

if status is-interactive
    # starship 提示符 —— 没装就跳过，不影响启动
    if type -q starship
        starship init fish | source
    end
end
