# 本地代理（Clash / Mihomo 默认端口 7890）
#
# 先探测端口，连不上就不设：给 curl / git / pip 挂一个连不上的 http_proxy，
# 比完全不挂代理更难排查。
#
# 只负责「本机有代理就设上」这一件事：
#   - 父进程已导出 http_proxy 时整段跳过，尊重外部设置（`http_proxy= fish` 即可临时关掉）
#   - 既没有 nc 也没有 bash 可以探测时，假定代理在，保持旧行为

set -l proxy_host 127.0.0.1
set -l proxy_port 7890
set -l proxy_url "http://$proxy_host:$proxy_port"

if not set -q http_proxy
    set -l alive 0
    if type -q nc
        nc -z -w 1 $proxy_host $proxy_port >/dev/null 2>&1; and set alive 1
    else if type -q bash
        # bash 的 /dev/tcp 是内建能力，不需要额外装探测工具
        bash -c "exec 3<>/dev/tcp/$proxy_host/$proxy_port" >/dev/null 2>&1; and set alive 1
    else
        set alive 1
    end

    if test $alive = 1
        set -gx http_proxy $proxy_url
        set -gx https_proxy $proxy_url
        # 本机回环不走代理，避免本地服务被绕一圈
        set -gx no_proxy "localhost,127.0.0.1,::1"

        # 开启代理留一句提示，免得「为什么这台机器能联网」变成悬案。
        # 两个条件都要：非交互 shell 不需要提示；stderr 不是终端时（管道、
        # 重定向到文件）也不要往别人的输出里塞字。提示本身写 stderr，
        # 这样 fish -i -c 的 stdout 仍然是干净的。
        if status is-interactive; and isatty stderr
            echo "proxy on: $proxy_url" >&2
        end
    end
end
