# 本地代理（Clash / Mihomo 默认 7890）
#
#   proxy on        开启（不探测，nc 没装时也能用）
#   proxy off       关闭
#   proxy status    看当前状态（默认，直接敲 proxy 也是它）
#   proxy auto      探测后按结果开关
#   -q / --quiet    不输出，只执行（可以放在任意位置）
#
# 启动时自动探测一次（内部就是 `proxy auto`）；父进程已有 http_proxy 就不动。
# 探测依赖 nc（macOS 自带；Fedora 需要 `dnf install nmap-ncat`），没装就不探测、
# 也不自动开，避免给 curl / git 挂上一个未必存在的代理。
#
# 输出一律一行 k=v：
#   proxy=on http_proxy=http://127.0.0.1:7890
#   proxy=off probe=closed / probe=nc-missing

set -g __proxy_host 127.0.0.1
set -g __proxy_port 7890
set -g __proxy_url "http://$__proxy_host:$__proxy_port"

function __proxy_on --description 'proxy: 开启'
    set -gx http_proxy $__proxy_url
    set -gx https_proxy $__proxy_url
    # 本机回环不走代理，避免本地服务被绕一圈
    set -gx no_proxy "localhost,127.0.0.1,::1"
end

function __proxy_off --description 'proxy: 关闭'
    set -e http_proxy
    set -e https_proxy
    set -e no_proxy
end

function __proxy_probe --description 'proxy: 检测端口，监听返回 0，nc 不可用返回 2'
    type -q nc; or return 2
    nc -z -w 1 $__proxy_host $__proxy_port >/dev/null 2>&1
end

function proxy --description '总入口：proxy [on|off|auto|status] [-q]'
    # 参数解析：子命令一个，-q/--quiet 可放任意位置
    set -l cmd
    set -l quiet 0
    for arg in $argv
        switch $arg
            case -q --quiet
                set quiet 1
            case '*'
                if set -q cmd[1]
                    echo "usage: proxy [on|off|auto|status] [-q]" >&2
                    return 1
                end
                set cmd $arg
        end
    end

    set -l out
    switch "$cmd"
        case on
            __proxy_on
            set out "proxy=on http_proxy=$__proxy_url"
        case off
            __proxy_off
            set out "proxy=off"
        case auto
            __proxy_probe
            switch $status
                case 0
                    __proxy_on
                    set out "proxy=on probe=open http_proxy=$__proxy_url"
                case 2
                    __proxy_off
                    set out "proxy=off probe=nc-missing"
                case '*'
                    __proxy_off
                    set out "proxy=off probe=closed"
            end
        case status ''
            if set -q http_proxy
                set out "proxy=on http_proxy=$http_proxy"
            else
                set out "proxy=off"
            end
        case '*'
            echo "usage: proxy [on|off|auto|status] [-q]" >&2
            return 1
    end

    if test -n "$out"; and test $quiet -eq 0
        echo $out
    end
end

# 启动时跑一次 `proxy auto`：交互终端里显示结果（写 stderr），
# 其它情况用 -q 静默执行；父进程已经给了 http_proxy 就尊重它，不覆盖。
if not set -q http_proxy
    if status is-interactive; and isatty stderr
        proxy auto >&2
    else
        proxy auto -q
    end
end
