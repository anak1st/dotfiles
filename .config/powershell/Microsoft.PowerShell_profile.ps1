# Windows PowerShell 7 配置 —— 单文件，所有逻辑都在这里
#
#   安装位置：$PROFILE = ~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
#   仓库位置：.config/powershell/Microsoft.PowerShell_profile.ps1（os = windows）
#   重载：    . $PROFILE
#   语法检查：$null = [ScriptBlock]::Create((Get-Content $PROFILE -Raw))
#
# 加载顺序：ReadLine -> 代理 -> fnm -> 提示符。

# ── PSReadLine：历史检索与补全 ─────────────────────────────────────────
if (Get-Module -Name PSReadLine) {
    # 上下键按已输入的前缀搜历史；默认的 PreviousHistory 不会按前缀过滤
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

# ── 代理：FlClash / Clash 默认 127.0.0.1:7890 ──────────────────────────
# Windows 的环境变量名不区分大小写，所以只设小写一套就够：git、curl、npm、
# pip、rustup 读 http_proxy / https_proxy，PowerShell 7 的 Invoke-WebRequest
# （.NET）读到的也是同一个变量，大写 HTTP_PROXY 与它是同一条记录。

function Test-ProxyListening {
    param([string] $ProxyUrl = 'http://127.0.0.1:7890', [int] $TimeoutMs = 300)

    $uri = [uri] $ProxyUrl
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        return $client.ConnectAsync($uri.Host, $uri.Port).Wait($TimeoutMs)
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
}

function Set-Proxy {
    param(
        [string] $ProxyUrl = 'http://127.0.0.1:7890',
        [string[]] $Bypass = @('localhost', '127.0.0.1', '::1'),
        [switch] $Quiet
    )

    foreach ($name in 'http_proxy', 'https_proxy') {
        Set-Item -Path "Env:$name" -Value $ProxyUrl
    }
    # 本机回环不走代理，免得本地服务被绕一圈
    Set-Item -Path Env:no_proxy -Value ($Bypass -join ',')

    if (-not $Quiet) { Write-Host "proxy on: $ProxyUrl" }
}

function Clear-Proxy {
    # 注意：用 Remove-Item 而不是 SetEnvironmentVariable($name, $null)，
    # 后者在这里只会把变量置空，变量本身还在，`Test-Path Env:` 仍为真。
    foreach ($name in 'http_proxy', 'https_proxy', 'no_proxy') {
        if (Test-Path "Env:$name") { Remove-Item -Path "Env:$name" }
    }
}

# 自动挂载：父进程已经导出过 http_proxy 就完全不动（`$env:http_proxy='' pwsh` 可以起一个干净 shell，
# Windows 上变量名大小写不敏感，所以这一个检查也覆盖了 HTTP_PROXY）；
# 端口没监听就干脆不设 —— 挂一个连不上的代理，故障表现（curl 超时、pip 卡住）比没挂更难查。
if (-not (Test-Path Env:http_proxy) -and (Test-ProxyListening)) {
    Set-Proxy
}

# 注意：Clear-Proxy 只对之后新启动的进程一定生效；当前会话里已经建立的 .NET 连接可能沿用旧代理。

# ── Node：fnm ─────────────────────────────────────────────────────────
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    # --shell powershell 明确指定语法，比让 fnm 猜进程树快，也不会误判成别的 shell
    fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
    # 每次执行都会新建一个 multishell 目录，所以手动重复 source 时 PATH 会多一项；
    # 这是 fnm 的行为，不是本文件造成的（新开窗口不受影响）。
}

# ── 提示符：starship（放最后，和官方文档一致）──────────────────────────
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
