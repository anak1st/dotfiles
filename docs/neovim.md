# Neovim

编辑器基于 LazyVim 发行版，仓库整体跟踪 `.config/nvim` 目录。

- 入口：`init.lua` → `require("config.lazy")`
- 发行版：LazyVim（`lazyvim.json` 里 `version: 8`）
- 插件锁：`lazy-lock.json`（入库，保证换机器插件版本一致）
- 配置根：`~/.config/nvim`

## 目录结构

```
~/.config/nvim/
├── init.lua                 # 只做一件事：加载 config.lazy
├── lazy-lock.json           # 插件版本锁，入库
├── lazyvim.json             # LazyVim 自身状态（extras、news）
├── stylua.toml              # Lua 格式化配置
├── .neoconf.json            # lua-language-server 的 neoconf 配置
├── lua/
│   ├── config/
│   │   ├── lazy.lua         # lazy.nvim 引导 + LazyVim 组装
│   │   ├── options.lua      # 自定义 vim.opt（当前为空，用 LazyVim 默认）
│   │   ├── keymaps.lua      # 自定义键位（当前为空）
│   │   └── autocmds.lua     # 自定义自动命令（当前为空）
│   └── plugins/
│       ├── example.lua      # LazyVim 模板示例，开头 `if true then return {} end` 直接禁用
│       └── minimal.lua      # 「极简模式」开关
└── README.md / LICENSE
```

## 引导流程

`lua/config/lazy.lua`：

1. 检查 `stdpath("data")/lazy/lazy.nvim` 是否存在，不存在就 `git clone --filter=blob:none --branch=stable`；
2. `vim.opt.rtp:prepend(lazypath)` 把 lazy.nvim 放进 runtimepath；
3. `require("lazy").setup{ spec = { { "LazyVim/LazyVim", import = "lazyvim.plugins" }, { import = "plugins" } } }`。

`{ import = "plugins" }` 会自动加载 `lua/plugins/` 下所有 `.lua` 文件——加插件不需要改 `init.lua`，新建一个文件即可。

值得注意的几个默认值：

| 配置 | 值 | 影响 |
|---|---|---|
| `defaults.lazy` | `false` | 自定义插件在启动时加载（LazyVim 自带的仍然按需加载） |
| `defaults.version` | `false` | 始终跟随最新 commit，配合 `lazy-lock.json` 锁定 |
| `install.colorscheme` | `tokyonight`、`habamax` | 首次安装时的兜底配色 |
| `checker.enabled` | `true` | 定期检查插件更新，不弹通知 |
| `performance.rtp.disabled_plugins` | gzip/tar/tohtml/tutor/zipPlugin | 关掉不用的内置插件 |

## 极简模式

`lua/plugins/minimal.lua` 通过 `enabled = false` 关掉四类东西：

```lua
{ "saghen/blink.cmp",            enabled = false },  -- 补全
{ "neovim/nvim-lspconfig",       enabled = false },  -- LSP
{ "mason-org/mason-lspconfig.nvim", enabled = false }, -- LSP 自动安装
{ "folke/lazydev.nvim",          enabled = false },  -- Lua LSP 辅助
```

想恢复完整 LazyVim：把对应项的 `enabled = false` 改成 `true`（或删掉整行），然后 `:Lazy sync`。

## 常用命令

```vim
:Lazy            " 插件管理界面
:Lazy sync       " 安装/更新/清理，配合 lazy-lock.json
:LazyExtras      " 启用 LazyVim 的 language extras
:LazyHealth      " 插件健康检查
:checkhealth     " 整体健康检查
```

## 与 DMS 主题的关系（隐患）

DMS 的 matugen 模板里有两条指向 nvim：

```
CONFIG_DIR/nvim/colors/dms.lua
CONFIG_DIR/nvim/lua/lualine/themes/dms.lua
```

当前机器上这两个文件**不存在**（模板没被触发），但风险是结构性的：

`dotfiles.json` 里 `.config/nvim` 是**目录条目**，安装/同步会展开目录下所有文件。一旦 DMS 写入 `colors/dms.lua`，`sync.py` 就会把它当成仓库文件收进来，`install.py` 又会把它覆盖回去。

处理建议（二选一）：

1. 把 `.config/nvim` 从目录条目改成逐文件枚举——符合「一个文件一条 entry」，也杜绝生成物混入；
2. 保持目录条目，但在 DMS 里确认 neovim 模板不启用，并在 `colors/`、`lua/lualine/themes/` 出现新文件时手动剔除。

出现 `dms.lua` 后再处理也可以，但那时最容易误提交。

## 字体与终端

Neovim 在 kitty 里运行，字体由 kitty 决定（Maple Mono NF CN，见 [字体](./fonts.md)），Nerd Font 图标依赖同一个字体。
