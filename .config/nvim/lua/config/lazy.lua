local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- 引入 LazyVim 及其插件
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- 引入/覆盖自己的 plugins
    { import = "plugins" },
  },
  defaults = {
    -- 默认只有 LazyVim 的插件懒加载，自定义插件在启动时加载。
    -- 清楚后果的话可以设为 true，让自定义插件也默认懒加载。
    lazy = false,
    -- 暂时建议保持 version=false：支持版本管理的插件里不少发版过旧，
    -- 装上可能直接弄坏 Neovim。
    version = false, -- 始终用最新 git commit
    -- version = "*", -- 想用稳定版就改成这个（仅对支持 semver 的插件有效）
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true, -- 定期检查插件更新
    notify = false, -- 有更新时是否弹通知
  }, -- 自动检查插件更新
  performance = {
    rtp = {
      -- 关掉一些用不到的 rtp 插件
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
