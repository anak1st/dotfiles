# fcitx5 + Rime

输入法框架是 fcitx5，中文输入用 Rime（雾凇拼音），候选窗走 fcitx5 的 Classic UI。

- fcitx5 5.1.23，Rime 前端 `fcitx5-rime`，备用 `fcitx5-chinese-addons`
- 启动方式：niri 的 `spawn-at-startup "fcitx5" "-d"`
- 触发键：**Win+Space**（两层都配，见下）
- 输入法组：`键盘 - 英语 (us)` + `rime`

## 文件分布

| 路径 | 作用 | 进仓库 |
|---|---|---|
| `~/.config/fcitx5/config` | 全局配置（触发键、共享状态等） | ✅ |
| `~/.config/fcitx5/profile` | 输入法组与顺序 | ✅ |
| `~/.config/fcitx5/conf/pinyin.conf` | 拼音插件参数（当前全是默认注释） | ✅ |
| `~/.config/fcitx5/conf/chttrans.conf` | 简繁转换（默认关闭） | ✅ |
| `~/.config/fcitx5/conf/punctuation.conf` | 标点行为（默认） | ✅ |
| `~/.config/fcitx5/conf/notifications.conf` | 输入法通知 | ✅ |
| `~/.config/fcitx5/conf/classicui.conf` | 候选窗主题与字体 | ❌ 尚未纳入 |
| `~/.local/share/fcitx5/rime/` | Rime 用户数据、方案、词库 | ❌（体积大、可重建） |
| `~/.local/share/fcitx5/themes/dms/` | DMS 生成的主题 | ❌（派生） |

`classicui.conf` 目前只在 `~` 里存在、仓库没管。里面是 `Theme=catppuccin-mocha-blue`、`Font=Noto Sans CJK SC 12` 这类稳定选择，建议补进 `dotfiles.json`。

## 全局配置（`~/.config/fcitx5/config`）

当前完整内容只有 12 行：

```ini
[Hotkey]
EnumerateWithTriggerKeys=True

[Hotkey/TriggerKeys]
0=Super+space

[Hotkey/EnumerateGroupForwardKeys]

[Hotkey/AltTriggerKeys]

[Behavior]
ShareInputState=All
```

逐项解释：

| 键 | 值 | 含义 |
|---|---|---|
| `TriggerKeys` | 只有 `Super+space` | 激活/停用输入法的唯一热键。默认的 `Control+space`、`Zenkaku_Hankaku`、`Hangul` 已删掉 |
| `EnumerateGroupForwardKeys` | 空 | 默认是 `Super+space`（切换输入法**组**），会和触发键抢同一个组合，清空 |
| `AltTriggerKeys` | 空 | 默认 `Shift_L`（单按 Shift 约 250ms 切换）。清掉是为了只有一条路径 |
| `ShareInputState` | `All` | 所有窗口共享输入法状态，切一次全局生效 |
| `EnumerateWithTriggerKeys` | `True` | 用触发键也能翻页选词 |

`ShareInputState` 三档：`No`（每个窗口独立，默认）、`Program`（同一程序共享）、`All`（所有窗口共享）。要「对每个窗口同时生效」就是 `All`；想「同程序多窗口共享、不同程序独立」用 `Program`。

## Win+Space 的两层机制

这是本配置里唯一「故意重复」的地方：

| 层 | 位置 | 行为 |
|---|---|---|
| compositor | niri `config.kdl` 的 `binds { Mod+Space { spawn "fcitx5-remote" "-t"; } }` | 按键先被 niri 截获，执行切换命令 |
| 输入法 | fcitx5 `TriggerKeys = Super+space` | 按键没被 niri 截走时（例如快捷键被 inhibit），由 fcitx5 自己处理 |

**不会双触发**：niri 的绑定默认消费按键（只有显式 `--pass-through` 才会继续转发），所以正常路径下 fcitx5 根本收不到这个组合。

副作用：如果给 niri 的绑定加 `--pass-through`，就会变成「按一下切两次」，别加。

## 生效条件：环境变量

niri 的 `environment {}` 已经设好：

```kdl
XMODIFIERS "@im=fcitx"
GTK_IM_MODULE "fcitx"
QT_IM_MODULE "fcitx"
SDL_IM_MODULE "fcitx"
```

- GTK/Qt/SDL 程序靠这些变量加载 fcitx5 的输入法模块；
- 漏掉时典型症状：程序能显示中文但无法输入，或只有部分程序能打中文；
- Wayland 原生程序还可能走 `zwp_input_method_v2`（`fcitx5-diagnose` 里显示 `frontend:wayland_v2`），此时按键由合成器转交。

## 候选窗主题与字体

- 主题：`~/.local/share/fcitx5/themes/` 下（`catppuccin-mocha-blue`，以及 DMS 生成的 `dms`）；
- 字体：`~/.config/fcitx5/conf/classicui.conf` 里 `Font/MenuFont/TrayFont` 都是 `Noto Sans CJK SC 12`；
- 切换主题/字体后：`fcitx5-remote -r`，或重启 fcitx5；
- 为什么不用等宽字体做候选窗：中文在等宽字体里会显得偏宽，混排观感差。详见 [字体](./fonts.md)。

## Rime 雾凇拼音

- 发布包：`https://github.com/iDvel/rime-ice/releases/latest/download/full.zip`
- 用户目录：`~/.local/share/fcitx5/rime/`；解压后重新部署
- 编译产物：`~/.local/share/fcitx5/rime/build/`，可删，会自动重建
- 更新：重新覆盖 `full.zip`；自定义写进 `*.custom.yaml`，**不要直接改方案文件**

## 验证与排错

```bash
fcitx5-remote              # 0 关闭 / 1 未激活 / 2 激活
fcitx5-remote -n           # 当前输入法名
fcitx5-remote -t           # 切换激活状态
fcitx5-remote -r           # 重载配置
fcitx5-diagnose            # 完整诊断（前端、模块、环境变量、插件）

# 读回运行中的全局配置，确认 TriggerKeys / ShareInputState
gdbus call --session --dest org.fcitx.Fcitx5 --object-path /controller \
  --method org.fcitx.Fcitx.Controller1.GetConfig "fcitx://config/global"
```

改配置的推荐姿势：改文件 → `fcitx5-remote -r` → 用 `GetConfig` 确认读进去了。fcitx5 在运行中也会自己写回配置（`Controller1.Save`），所以改完记得同步回仓库。

常见问题：

| 现象 | 原因 |
|---|---|
| 按 Win+Space 没反应 | niri 绑定被删/被覆盖；或 fcitx5 没运行（`pgrep fcitx5`） |
| 按一下切两次 | niri 绑定带了 `--pass-through` |
| 某个窗口不跟随 | `ShareInputState` 不是 `All`，或该窗口还没重新获得焦点 |
| 候选窗字体不对 | 改的是 `classicui.conf` 但没 `-r` 重载 |
| 换主题后候选窗没变色 | DMS 的主题生成还没跑完，或 fcitx5 主题没指向 `dms` |

## 与其他组件的关系

- 键位：`Mod+Space` 在 [niri](./niri.md) 里也有说明；
- 主题：DMS 会往 `~/.local/share/fcitx5/themes/dms/` 写主题（见 [dms](./dms.md)）；
- 仓库：`config`、`profile`、`conf/*.conf` 由 `dotfiles.json` 逐文件登记；Rime 用户数据不进仓库。
