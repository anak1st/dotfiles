# niri

niri 是 Wayland 合成器（滚动式平铺），也是整个会话的入口：DMS、fcitx5、kitty 都跑在它上面。

- 版本：26.04
- 主配置：`~/.config/niri/config.kdl`（仓库：[`.config/niri/config.kdl`](../.config/niri/config.kdl)）
- 生成配置：`~/.config/niri/dms/*.kdl`（DMS 写的，**不手改、不进仓库**）
- 校验：`niri validate`

## 目录关系

```
~/.config/niri/
├── config.kdl          # 唯一手写的文件，仓库跟踪
└── dms/                # DMS 生成，仓库不跟踪
    ├── colors.kdl      # matugen 生成
    ├── layout.kdl      # DMS 布局 GUI 生成
    ├── alttab.kdl
    ├── binds.kdl       # DMS 键位管理，GUI/CLI 写
    ├── outputs.kdl
    ├── cursor.kdl
    ├── input.kdl
    ├── windowrules.kdl
    └── wpblur.kdl
```

`config.kdl` 用 7 行 include 把 DMS 的生成文件接进来：

```kdl
include optional=true "dms/colors.kdl"
include optional=true "dms/layout.kdl"
include optional=true "dms/alttab.kdl"
include optional=true "dms/binds.kdl"
include optional=true "dms/outputs.kdl"
include optional=true "dms/cursor.kdl"
include optional=true "dms/input.kdl"
```

`optional=true` 的意义是文件不存在也不报错，所以首次启动、或者删掉某个生成文件，niri 仍然能起来。

## 配置分区

### 启动与输入

```kdl
config-notification { disable-failed }
gestures { hot-corners { off } }

input {
    keyboard {
        xkb { }        # 留空 = 从 org.freedesktop.locale1 读取（localectl）
        numlock
    }
}
```

- `xkb` 块留空，布局由 `localectl` 决定；想改布局用 `localectl set-x11-keymap`，不要在 niri 里写死。
- `config-notification { disable-failed }` 关掉「配置加载失败」的通知条——注意它只关通知，配置错误仍然会拒绝加载并保留旧配置。

### 布局

```kdl
layout {
    background-color "transparent"      # 背景透明，交给 DMS 画壁纸
    center-focused-column "never"
    preset-column-widths { proportion 0.33333; proportion 0.5; proportion 0.66667 }
    default-column-width { proportion 0.5 }
    border { off; width 4; ... }
    shadow { softness 30; spread 5; offset x=0 y=5; color "#0007" }
    struts { }
}
```

- `background-color "transparent"`：niri 不画背景，壁纸由 DMS（layer-shell）渲染，这也是 `layer-rule { match namespace="^quickshell$"; place-within-backdrop true }` 存在的原因。
- `border { off }` 只是关掉默认边框；`dms/colors.kdl` 里会重新给 focus-ring/border 上色。

### 环境变量与自启动

```kdl
environment {
  XDG_CURRENT_DESKTOP "niri"
  XMODIFIERS "@im=fcitx"
  GTK_IM_MODULE "fcitx"
  QT_IM_MODULE "fcitx"
  SDL_IM_MODULE "fcitx"
}
spawn-at-startup "fcitx5" "-d"
```

- 这几个 `*_IM_MODULE` 决定 GTK/Qt/SDL 程序走 fcitx5 的输入法插件；漏掉会导致某些程序无法输入中文。
- fcitx5 由 niri 直接拉起；其他程序优先走 `~/.config/autostart/`（niri 作为 session 时支持 xdg autostart，改完记得 `systemctl --user daemon-reload`）。

### 其他全局项

| 配置 | 值 | 作用 |
|---|---|---|
| `hotkey-overlay { skip-at-startup }` | 开 | 开机不弹快捷键提示 |
| `prefer-no-csd` | 开 | 尽量让客户端不用 CSD，边框/圆角交给合成器 |
| `screenshot-path` | `~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png` | niri 自带截图保存路径 |
| `debug { honor-xdg-activation-with-invalid-serial }` | 开 | 兼容部分客户端的激活请求 |

### 动画

```kdl
animations {
    workspace-switch         { spring damping-ratio=0.80 stiffness=523 epsilon=0.0001 }
    window-open              { duration-ms 150; curve "ease-out-expo" }
    window-close             { duration-ms 150; curve "ease-out-quad" }
    horizontal-view-movement { spring damping-ratio=0.85 stiffness=423 epsilon=0.0001 }
    window-movement          { spring damping-ratio=0.75 stiffness=323 epsilon=0.0001 }
    window-resize            { spring damping-ratio=0.85 stiffness=423 epsilon=0.0001 }
    overview-open-close      { spring damping-ratio=0.85 stiffness=800 epsilon=0.0001 }
}
```

`spring` 用阻尼/刚度描述，`duration-ms + curve` 是传统缓动，两种二选一。想整体关动画可以加 `animations { off }`。

### 窗口规则

按顺序匹配，先匹配先生效：

| 匹配 | 规则 | 目的 |
|---|---|---|
| `wezterm` | `default-column-width {}` | 绕开 WezTerm 初次 configure 的 bug |
| `^org\.gnome\.` | `draw-border-with-background false`、圆角 12、`clip-to-geometry true` | GNOME 系应用统一圆角 |
| `gnome-control-center` / `pavucontrol` / `nm-connection-editor` | 宽度 50%、不浮动 | 设置类窗口 |
| 计算器 / blueman / `xdg-desktop-portal` | `open-floating true` | 小工具浮动 |
| `steam` 通知 toast | 右下角浮动、`open-focused false` | 不抢焦点 |
| wezterm / Alacritty / zen / ghostty / **kitty** | `draw-border-with-background false` | 终端透明时边框不画在窗口后面 |
| firefox 画中画 / zoom | 浮动 | — |

终端那条很关键：没有 `draw-border-with-background false` 时，语义透明窗口后面会透出合成器画的边框方块。

### 输入法绑定

```kdl
binds {
    Mod+Space hotkey-overlay-title="Toggle Input Method" { spawn "fcitx5-remote" "-t"; }
}
```

这是 `config.kdl` 里唯一的自写 bind。`dms/binds.kdl` 里同名键已删除（启动器移到了 `Mod+Ctrl+Return`），所以不会重复定义。详见 [fcitx5](./fcitx5.md)。

## include 语义（踩过的坑）

- `include` **只在顶层生效**，不能写进 `input { }` 之类块里；
- 不支持 glob；
- 路径相对当前文件，也接受绝对路径和 `~/`；
- 有顺序：后面的同名键覆盖前面的；
- 只对 `binds` 这类「键 → 值」结构做覆盖；`window-rule`、`output`、`workspace` 是按位置插入，不合并；
- 可选文件一定写 `optional=true`，否则文件缺失会导致整个配置加载失败。

## 键位

完整列表随时看：`Mod+Shift+Slash` 调出 DMS 的快捷键面板，或 `dms keybinds show niri`（JSON，122 条）。

日常最常用：

| 键 | 动作 |
|---|---|
| `Mod+Return` / `Mod+T` | 终端 |
| `Mod+Ctrl+Return` | 启动器（Spotlight） |
| `Mod+Space` | 输入法切换 |
| `Mod+Q` | 关窗口 |
| `Mod+O` / `Mod+Tab` | 总览 |
| `Mod+H/J/K/L`、`Mod+方向键` | 焦点 |
| `Mod+1…9` | 切工作区 |
| `Mod+F` / `Mod+R` | 最大化 / 预设宽度 |
| `Mod+Shift+E` | 退出 niri |
| `Mod+Shift+Slash` | 快捷键面板 |

来源区分：绝大多数来自 `dms/binds.kdl`（DMS 的默认绑定，GUI 里可改）；`Alt+Tab` 系列在 `config.kdl` 的 `recent-windows` 里覆盖；`Mod+Space` 是本仓库新增。

## 校验与调试

```bash
niri validate                # 语法与语义校验，改完必跑
niri msg outputs             # 显示器名/模式（配 outputs 用）
niri msg workspaces          # 当前工作区
niri msg action <action>     # 直接触发一个动作，例如 do-screen-transition
```

niri 会监听 `config.kdl`，保存后自动重载，日志里能看到：

```
niri_config: loaded config from "/home/anak1st/.config/niri/config.kdl"
```

配置写错时 niri 拒绝加载并继续用旧配置，同时（若没关）弹配置错误通知——这正是 `config-notification { disable-failed }` 想关掉的东西。

## 已知问题

`windowrules.kdl` 和 `wpblur.kdl` 目前**没有被 include**，所以：

- DMS 设置里添加的窗口规则不会生效；
- 视频壁纸的模糊层规则（`layer-rule { match namespace="dms:blurwallpaper" }`）不会生效。

可以用 DMS 自带的检查器确认：

```bash
dms config resolve-include niri windowrules.kdl   # {"exists":true,"included":false}
dms config resolve-include niri wpblur.kdl        # {"exists":true,"included":false}
```

修法是往 `config.kdl` 的 include 区补两行：

```kdl
include optional=true "dms/windowrules.kdl"
include optional=true "dms/wpblur.kdl"
```

补之前请确认 `dms/windowrules.kdl` 内容符合预期（DMS 会重写它）。
