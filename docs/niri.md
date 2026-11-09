# niri

## 配置文件

- 主配置：`~/.config/niri/config.kdl`
- 仓库内路径：`.config/niri/config.kdl`
- DMS 自动生成：`~/.config/niri/dms/*.kdl`，文件头标注 `DO NOT EDIT`，不纳入 dotfiles

## 主配置结构

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

DMS 的 include 放在配置末尾：

```kdl
include optional=true "dms/colors.kdl"
include optional=true "dms/layout.kdl"
include optional=true "dms/alttab.kdl"
include optional=true "dms/binds.kdl"
include optional=true "dms/outputs.kdl"
include optional=true "dms/cursor.kdl"
include optional=true "dms/input.kdl"
```

## 自启动

- fcitx5：使用 niri 的 `spawn-at-startup "fcitx5" "-d"`
- 其他 xdg autostart：放在 `~/.config/autostart/`

niri 通过 systemd 的 `xdg-desktop-autostart.target` 处理 xdg autostart。新增或修改 `.desktop` 后需要：

```bash
systemctl --user daemon-reload
```

## 校验

```bash
niri validate
```

## 是否拆分

当前保持单个 `config.kdl`。DMS 已经把生成配置分到 `dms/`，再拆收益不大。

需要拆分时注意：

- `include` 只在顶层生效，不能写在 `input { }` 等块里
- 不支持 glob
- 路径相对当前文件，也支持绝对路径和 `~/`
- include 有位置顺序，后面的覆盖前面的
- `binds` 后面的同名键覆盖前面的
- `window-rule` / `output` / `workspace` 按位置插入，不合并
- `struts`、`preset-column-widths`、`animations` 子段、`input` 指针设备段不合并
- 可选文件使用 `include optional=true "x.kdl"`

## dotfiles

- 只跟踪 `.config/niri/config.kdl`
- `dms/` 不进入仓库
