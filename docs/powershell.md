# PowerShell 7（Windows）

`~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`（`$PROFILE`）是 Windows 侧唯一的配置文件。

仓库里是 [.config/powershell/Microsoft.PowerShell_profile.ps1](../.config/powershell/Microsoft.PowerShell_profile.ps1)，清单里映射到上面那个路径（`"app": "powershell"`、`"os": ["windows"]`）。

PowerShell 只有一个 `$PROFILE` 入口，所以 ReadLine、代理、Node、提示符四段都写在这一个文件里，用注释分节。

## 安装与回收

和其它 app 一样走清单：

```powershell
# 用仓库里的文件覆盖 $PROFILE（覆盖前备份到 ~\.dotfiles-backup\<时间戳>\）
uv run python install.py powershell

# 把本机改过的 profile 收回仓库
uv run python sync.py powershell
```

Windows 上通常没有 `python3`：`install.py` / `sync.py` 任意 3.9+ 解释器都能跑，`uv run python`、`py -3`、`python` 都行。

## 加载顺序

| # | 小节 | 做什么 | 为什么在这个位置 |
|---|---|---|---|
| 1 | PSReadLine | 上下键按前缀搜历史 | 纯键位，不依赖后面任何东西 |
| 2 | 代理 | 探测 7890 端口，活着才挂 | 只要环境变量，和后面互不依赖 |
| 3 | Node | `fnm env` | 依赖 PATH 里能找到 `fnm` |
| 4 | 提示符 | `starship init` | 官方文档要求放 profile 末尾；它定义 `prompt` 函数 |

## 代理

本机跑的是 FlClash（Clash.Meta 内核），混合端口 `127.0.0.1:7890`。

行为三条：

1. **先探测再挂**：TCP 连接 300 ms 超时，端口没监听就不设。挂一个连不上的代理，故障表现（curl 超时、pip 卡住）比没挂更难排查；
2. **尊重父进程**：环境里已经有 `http_proxy` 就整段跳过。想开一个干净 shell：`$env:http_proxy=''; pwsh`（Windows 上变量名不区分大小写，设 `HTTP_PROXY` 同样算数）；
3. **只设三个小写变量**：

| 变量 | 谁读 | 值 |
|---|---|---|
| `http_proxy` | git、curl、npm、pip、rustup、`Invoke-WebRequest` | `http://127.0.0.1:7890` |
| `https_proxy` | 同上 | 同上 |
| `no_proxy` | 同上 | `localhost,127.0.0.1,::1` |

不写大写 `HTTP_PROXY`，因为 Windows 的环境变量名**不区分大小写**，`$env:HTTP_PROXY` 和 `$env:http_proxy` 是同一条记录，写两遍只是自己骗自己。

实测：把小写 `http_proxy` 指向死端口，`Invoke-WebRequest` 立即失败；补上 `no_proxy` 后恢复 200。git、curl、.NET、PowerShell 读的是同一套变量。

函数：

```powershell
Set-Proxy                                # 挂默认代理，打印一行提示
Set-Proxy -ProxyUrl http://127.0.0.1:7891 -Quiet
Clear-Proxy                              # 删变量
```

`Clear-Proxy` 用 `Remove-Item` 删变量，而不是 `[Environment]::SetEnvironmentVariable($n, $null)`：后者在 PowerShell 里只把值改成空串，变量本身还在，`Test-Path Env:http_proxy` 仍为真，下次开机判断「父进程已设置」就会误判。

注意 `Clear-Proxy` 只对之后新启动的进程一定生效；当前会话里已经建立过的 .NET 连接可能沿用旧代理，重开一个窗口最稳。

## Node（fnm）

```powershell
fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
```

- `--shell powershell` 显式指定语法：官方 README 建议这样，比让 fnm 猜进程树快一点，也不会在奇怪的环境里误判成 cmd；
- `--use-on-cd` 的版本切换在 1.38+ 不是 prompt hook，而是把 `cd` 重定义成 `cd_with_fnm`（`Set-Alias -Option AllScope cd`），所以和 starship 的 `prompt` 不冲突，先后顺序无所谓；
- 每次执行 `fnm env` 都会新建一个 `fnm_multishells\<pid>_<ts>` 目录，所以**手动重复** `. $PROFILE` 会让 PATH 多一项。这是 fnm 的行为，新开窗口不受影响，别把它当成配置 bug；
- `fnm list` 看已装版本，`fnm default 24` 改默认，`fnm current` 看当前生效版本。

## 提示符（starship）

```powershell
Invoke-Expression (&starship init powershell)
```

和 starship 官方文档给出的 PowerShell 片段完全一致，没有改。外面包了一层 `Get-Command` 判断，没装 starship 的机器不会报错。

主题文件是 `~\.config\starship.toml`（当前只有 `[conda] ignore_base=false`）。

启动开销：`starship init` 约 320 ms（scoop 的 shim 多套一层进程），整个 profile 约 0.66 s。

## PSReadLine

- 上下键改成 `HistorySearchBackward` / `HistorySearchForward`：按已输入的前缀过滤历史，默认的 `PreviousHistory` 只是逐条翻。
