-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- 中文不做拼写检查：LazyVim 的 lazyvim_wrap_spell 会在这些 filetype 里设
-- spell=true，中文没有词典会被整篇标红。这里复用它同一组 filetype，只把
-- spell 关掉；wrap 仍由 LazyVim 负责。同是 FileType 事件，后注册的生效。
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.spell = false
  end,
})
