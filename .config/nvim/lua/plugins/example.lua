-- 这只是示例 spec：什么都不加载，直接返回空表
-- stylua: ignore
if true then return {} end

-- plugins/ 下的每个 spec 文件都会被 lazy.nvim 自动加载
--
-- 在这些文件里可以：
-- * 追加插件
-- * 禁用/启用 LazyVim 的插件
-- * 覆盖 LazyVim 插件的配置
return {
  -- 加 gruvbox
  { "ellisonleao/gruvbox.nvim" },

  -- 让 LazyVim 用 gruvbox 配色
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },

  -- 改 trouble 的配置
  {
    "folke/trouble.nvim",
    -- opts 会和父 spec 合并
    opts = { use_diagnostic_signs = true },
  },

  -- 禁用 trouble
  { "folke/trouble.nvim", enabled = false },

  -- 覆盖 nvim-cmp，加 cmp-emoji
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-emoji" },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      table.insert(opts.sources, { name = "emoji" })
    end,
  },

  -- 改 telescope 的选项，并加一个浏览插件文件的键位
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      -- 加一个浏览插件文件的键位
      -- stylua: ignore
      {
        "<leader>fp",
        function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
        desc = "Find Plugin File",
      },
    },
    -- 改一些选项
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
      },
    },
  },

  -- 给 lspconfig 加 pyright
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- pyright 由 mason 自动安装，lspconfig 负责加载
        pyright = {},
      },
    },
  },

  -- 加 tsserver，改由 typescript.nvim 接管而不是 lspconfig
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "jose-elias-alvarez/typescript.nvim",
      init = function()
        require("lazyvim.util").lsp.on_attach(function(_, buffer)
          -- stylua: ignore
          vim.keymap.set( "n", "<leader>co", "TypescriptOrganizeImports", { buffer = buffer, desc = "Organize Imports" })
          vim.keymap.set("n", "<leader>cR", "TypescriptRenameFile", { desc = "Rename File", buffer = buffer })
        end)
      end,
    },
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- tsserver 同样由 mason 自动安装
        tsserver = {},
      },
      -- 单个 lsp server 的额外设置写这里
      -- 返回 true 表示这个 server 不交给 lspconfig 处理
      ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
      setup = {
        -- 用 typescript.nvim 接管 tsserver 的示例
        tsserver = function(_, opts)
          require("typescript").setup({ server = opts })
          return true
        end,
        -- 用 "*" 给所有 server 兜底
        -- ["*"] = function(server, opts) end,
      },
    },
  },

  -- TypeScript 也有现成的 extra：lspconfig、treesitter、mason、typescript.nvim
  -- 一次配好，所以上面那一大段可以换成：
  { import = "lazyvim.plugins.extras.lang.typescript" },

  -- 加更多 treesitter parser
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      },
    },
  },

  -- vim.tbl_deep_extend 只合并表、不合并列表，上面那种写法会整个替换
  -- ensure_installed。想“追加”默认列表就用下面这段：
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- 追加 tsx 和 typescript
      vim.list_extend(opts.ensure_installed, {
        "tsx",
        "typescript",
      })
    end,
  },

  -- opts 函数也可以用来改默认值
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, {
        function()
          return "😄"
        end,
      })
    end,
  },

  -- 或者直接返回一整套新选项，覆盖全部默认值
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      return {
        --[[自定义 lualine 配置写在这里]]
      }
    end,
  },

  -- 用 mini.starter 代替 alpha
  { import = "lazyvim.plugins.extras.ui.mini-starter" },

  -- 加 jsonls 和 schemastore，并给 json / json5 / jsonc 配 treesitter
  { import = "lazyvim.plugins.extras.lang.json" },

  -- 想让 mason 装别的工具就写在这里
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "flake8",
      },
    },
  },
}
