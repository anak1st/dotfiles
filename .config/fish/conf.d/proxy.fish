# 本地代理（Clash / Mihomo 默认 127.0.0.1:7890）
#
#   proxy on        设 http_proxy / https_proxy / no_proxy，不探测
#   proxy off       清掉这三个变量
#   proxy status    只读当前状态，不探测
#   proxy auto      nc 探测 127.0.0.1:7890，通就开、不通就关
#   -q / --quiet    不输出，只执行；写在模式之后
#
# 模式必填，且必须是第一个参数；否则打 usage 并返回 1。
#
# 输出一行 k=v：
#   proxy=on http_proxy=http://127.0.0.1:7890
#   proxy=off
#   proxy=on probe=open http_proxy=http://127.0.0.1:7890
#   proxy=off probe=closed          auto：端口没开
#   proxy=off probe=nc-missing      auto：没装 nc
#
# 探测只用 nc -z -w 1。没装 nc 就既不探测也不自动开：挂一个未必存在的代理，
# 故障表现（curl 超时、pip 卡住）比不设更难查。
#
# 启动时自动跑一次 proxy auto：父进程已有 http_proxy 就跳过；交互终端里把结果
# 写 stderr，其它情况用 -q 静默执行。

function proxy --description '本地代理：proxy <on|off|auto|status> [-q]'
    set -l url http://127.0.0.1:7890

    # 模式是第一个参数；后面任何位置出现 -q 都算安静模式
    set -l cmd $argv[1]
    set -l quiet 0
    if contains -- -q $argv; or contains -- --quiet $argv
        set quiet 1
    end

    # auto 先探测，结果折成 on / off，和手动开关走同一段
    set -l probe
    if test "$cmd" = auto
        if not type -q nc
            set probe nc-missing
            set cmd off
        else if nc -z -w 1 127.0.0.1 7890 >/dev/null 2>&1
            set probe open
            set cmd on
        else
            set probe closed
            set cmd off
        end
    end

    switch $cmd
        case on
            set -gx http_proxy $url
            set -gx https_proxy $url
            set -gx no_proxy localhost,127.0.0.1,::1
        case off
            set -e http_proxy
            set -e https_proxy
            set -e no_proxy
        case status
            if set -q http_proxy
                set cmd on
            else
                set cmd off
            end
        case '*'
            echo "usage: proxy <on|off|auto|status> [-q]" >&2
            return 1
    end

    # 拼一行 k=v：proxy=off / proxy=on http_proxy=... / 带 probe 的只有 auto
    set -l out "proxy=$cmd"
    if test -n "$probe"
        set out "$out probe=$probe"
    end
    if test "$cmd" = on
        set out "$out http_proxy=$http_proxy"
    end

    if test $quiet -eq 0
        echo $out
    end
end

if not set -q http_proxy
    if status is-interactive; and isatty stderr
        proxy auto >&2
    else
        proxy auto -q
    end
end
