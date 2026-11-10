# xdg-desktop-portal

应用要「另存为 / 打开文件 / 分享屏幕」时，不是自己画窗口，而是通过 D-Bus 找门户（portal）代办。
本机这一层链条是：

```
应用（QQ / Chrome / …）
  │  org.freedesktop.portal.FileChooser
  ▼
xdg-desktop-portal 1.22.1            前端，按配置挑后端
  │  org.freedesktop.impl.portal.FileChooser
  ▼
xdg-desktop-portal-gnome             后端（发行版给的默认）
  │  委托
  ▼
Nautilus（GTK4）                     真正画对话框的进程
```

后端不是写死的，由配置文件按 `XDG_CURRENT_DESKTOP` 选：

- 发行版：`/usr/share/xdg-desktop-portal/niri-portals.conf`（`niri` 包提供），内容 `default=gnome;gtk;`
- 用户覆盖：`~/.config/xdg-desktop-portal/niri-portals.conf`（本仓库管理），优先级最高，**整体替换**发行版那份。
  用 `niri-` 前缀是刻意的：通用名 `portals.conf` 在所有会话里都会被读（包括 GNOME 会是后者），
  桌面专属文件名只在 `XDG_CURRENT_DESKTOP` 含该桌面时生效，见 `man 5 portals.conf`
- 每个后端能提供哪些接口，写在 `/usr/share/xdg-desktop-portal/portals/*.portal` 里；FileChooser 由 `gnome` 和 `gtk` 两个后端声明

## 为什么用 gtk 后端接 FileChooser

这是针对 niri 26.04 一个崩溃的**临时绕过**，不是修复。

崩溃链（`coredumpctl` 有 core，栈里有 `wl_proxy_get_version ← gxdp_wayland_set_x11_parent`）：

1. niri 26.04 的 `org.gnome.Mutter.ServiceChannel` 是桩实现，只接受 `service_client_type == 1`（见 niri `src/dbus/mutter_service_channel.rs`）；
2. Nautilus 作为 GNOME 后端的文件选择器实现，经 libgxdp 请求类型 2（`GXDP_SERVICE_CLIENT_TYPE_FILE_CHOOSER`），被 niri 以 `InvalidArgs: Invalid service client type` 拒绝；
3. libgxdp 落到 `init_gtk_wayland_fallback()`，但回退路径没有 `init_x11_interop()`，随后仍调用 `mutter_x11_interop_set_x11_parent(NULL, …)` → 空指针 → Nautilus 崩；
4. 门户报 `Delegated FileChooser call failed: Remote peer disconnected`，应用侧拿不到对话框（表现为「点了没反应」）。

只有 **X11 应用**会走到第 3 步（要给对话框设 X11 父窗口）；Wayland 原生的 GTK 应用只会得到一句 `portal dialogs may misbehave` 的警告，不崩。
QQ 是 XWayland 应用，且 Chromium 144 自带 `org.freedesktop.portal.FileChooser` 客户端，所以它是稳定触发者。

`gtk` 后端（`xdg-desktop-portal-gtk`）在自己的进程里用 GTK3 直接弹 `GtkFileChooserDialog`，不委托 Nautilus、不碰 libgxdp，因此绕开整条崩溃路径。

## 配置与生效（手动维护，不进清单）

这两个文件是 **bug 专用**的，**故意不登记在 `dotfiles.json`**：`install.py` / `sync.py`
都不会碰它们，需要手动复制、手动改，等 niri 修好后再手动删掉。

```
仓库                                         → 本机
.config/xdg-desktop-portal/niri-portals.conf → ~/.config/xdg-desktop-portal/niri-portals.conf
.config/gtk-3.0/gtk.css                      → ~/.config/gtk-3.0/gtk.css
```

```bash
cp .config/xdg-desktop-portal/niri-portals.conf ~/.config/xdg-desktop-portal/
cp .config/gtk-3.0/gtk.css                      ~/.config/gtk-3.0/
systemctl --user restart xdg-desktop-portal.service
```

重启门户只影响正在进行的门户会话（录屏、已打开的文件对话框），不影响已运行的应用。
`gtk.css` 要重启对应的 GTK3 应用才生效（门户后端已重启过）。

## 验证

点一次「另存为」，同时看日志：

```bash
journalctl --user -f | grep -E 'portal|nautilus'
```

- 正常：几秒内出现 GTK 文件对话框，日志里没有 `Delegated FileChooser` / `Failed to open service channel`；
- 仍然崩：日志里会再出现 `Invalid service client type` 和 nautilus 的 core，说明配置没生效（检查是否整体替换掉了发行版那三行，或 portal 没重启）。

## 外观上的两个坑（gtk 兜底对话框）

换成 gtk 后端后，对话框是 GTK3 的 `GtkFileChooserDialog`，有两个不是 niri 造成的毛病：

1. **窗口太大**：尺寸是 GTK 自己记在 `org.gtk.Settings.FileChooser window-size` 里的（[niri #1222](https://github.com/niri-wm/niri/issues/1222) 的结论：niri 只是照它给的尺寸放窗口）。重置即可：
   ```bash
   gsettings reset org.gtk.Settings.FileChooser window-size
   ```
2. **边框和对话框之间空一圈**：那是 GTK3 CSD 的阴影边距（Adwaita 的 `decoration` 规则留了 10px `margin`），画在 X11 窗口内部；niri 只能围着窗口画边框，没法从外面裁掉它。用 [`gtk.css`](../.config/gtk-3.0/gtk.css) 把阴影去掉：
   ```css
   decoration { margin: 0; box-shadow: none; }
   ```
   注意它是 GTK3 的**用户级全局样式**：只要你登进任何桌面，所有 GTK3 应用都会没有 CSD 阴影（GNOME Shell 自己的主题、GTK4 应用如 Nautilus 不受影响）。GTK CSS 没有按桌面条件化的机制，介意就删掉这个文件。

真正干净的终态还是升级 niri 后回退到 gnome 后端（Nautilus 对话框）。

## 移除条件

带 `d054395225`（niri 上游，2026-10-15，“Add new types to Mutter.ServiceChannel”，晚于 v26.04）的 niri 进 Fedora 后：

1. 删掉 `niri-portals.conf` 里 `FileChooser=gtk` 一行（其余三行保留，它们本来就在 `niri-portals.conf` 里）；
2. 重启 portal，再试一次「另存为」；
3. 仍然正常 → 根因已修，这份用户配置可以整个删掉；又崩 → 把这一行加回来。

## 与 DMS 的边界

DMS 不实现任何 portal 后端（`dms` 包里没有 `xdg-desktop-portal` 相关文件，二进制里也没有 `org.freedesktop.impl.portal`）。
它只把 portal 当客户端用（Settings、Documents、AppPicker），并且用 `systemd-run` 起应用，所以 journal 里会出现
`app-dms-qq-….scope`——那说明的是「DMS 启动了 QQ」，不是「DMS 画了对话框」。
