-- 极简模式：只要“编辑器 + 语法高亮”，关掉补全和 LSP
-- 以后想启用：把对应项的 enabled 改成 true（或整行删掉），再执行 :Lazy sync
return {
  -- 补全引擎（LazyVim 默认会通过 extras 自动启用 blink.cmp）
  { "saghen/blink.cmp", enabled = false },

  -- LSP 客户端、自动启用与自动安装
  { "neovim/nvim-lspconfig", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },

  -- 给 Lua 用的轻量 LSP 辅助
  { "folke/lazydev.nvim", enabled = false },
}
