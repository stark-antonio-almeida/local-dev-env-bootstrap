-- since this is just an example spec, don't actually load anything here and return an empty spec
-- stylua: ignore
if true then return {
{
    "akinsho/bufferline.nvim",
    init = function()
      local bufline = require("catppuccin.special.bufferline")
      function bufline.get()
        return bufline.get_theme()
      end
    end,
  },
  {
  'stevearc/conform.nvim',
  opts = {
      formatters_by_ft = {
          xml = { "customxml" },
      },
      formatters = {
        customxml = {
          command = "yq",
          args = { "-p", "xml", "-o", "xml"},
        },
      },
    },
  },
  -- install without yarn or npm
  -- {
  --     "iamcco/markdown-preview.nvim",
  --     cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  --     ft = { "markdown" },
  --     build = function() vim.fn["mkdp#util#install"]() end,
  -- },
 -- Modify which-key keys
  {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts_extend = { "spec" },
  opts = {
    preset = "modern",
    defaults = {},
    spec = {
      {
        -- better descriptions
        { "gx", desc = "Open with system app" },
        { "<leader>m", group = "Markdown", icon = "" },
        { "<leader>r", group = "Run", icon = ""},
        { "<leader>rt", group = "Tests" , icon = "󰙨" },
        { "<leader>t", group = "Terminal" },
      },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Keymaps (which-key)",
    },
    {
      "<c-w><space>",
      function()
        require("which-key").show({ keys = "<c-w>", loop = true })
      end,
      desc = "Window Hydra Mode (which-key)",
    },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)
    if not vim.tbl_isempty(opts.defaults) then
      LazyVim.warn("which-key: opts.defaults is deprecated. Please use opts.spec instead.")
      wk.register(opts.defaults)
    end
  end,
},
  -- {
  --   "folke/which-key.nvim",
  --   opts = function()
  --     local wk = require("which-key")
  --     wk.add({
  --       -- ["<leader>xl"] = {
  --       --   name = "+LSP (Telescope)",
  --       -- },
  --       { "<leader>m", group = "Markdown", icon = "" },
  --       { "<leader>r", group = "Run", icon = ""},
  --       { "<leader>rt", group = "Tests" , icon = "󰙨" },
  --       { "<leader>t", group = "Terminal" },
  --     })
  --   end,
  -- },
-- { "Hoffs/omnisharp-extended-lsp.nvim", lazy = true }, -- Add back if omnisharp is required
-- {
--   "neovim/nvim-lspconfig",
--   opts = {
--     servers = {
--       fsautocomplete = {},
--       omnisharp = {
--         handlers = {
--           ["textDocument/definition"] = function(...)
--             return require("omnisharp_extended").handler(...)
--           end,
--         },
--         keys = {
--           {
--             "gd",
--             LazyVim.has("telescope.nvim") and function()
--               require("omnisharp_extended").telescope_lsp_definitions()
--             end or function()
--               require("omnisharp_extended").lsp_definitions()
--             end,
--             desc = "Goto Definition",
--           },
--         },
--         enable_roslyn_analyzers = true,
--         organize_imports_on_format = true,
--         enable_import_completion = true,
--       },
--     },
--   },
-- },
}
else
  return {}
end

-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {
  -- add gruvbox
  { "ellisonleao/gruvbox.nvim" },

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "ayu_mirage",
    },
  },

  -- change trouble config
  {
    "folke/trouble.nvim",
    -- opts will be merged with the parent spec
    opts = { use_diagnostic_signs = true },
  },

  -- disable trouble
  { "folke/trouble.nvim", enabled = false },

  -- override nvim-cmp and add cmp-emoji
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-emoji" },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      table.insert(opts.sources, { name = "emoji" })
    end,
  },

  -- change some telescope options and a keymap to browse plugin files
  {
    "nvim-telescope/telescope.nvim",
    keys = {
        -- add a keymap to browse plugin files
        -- stylua: ignore
        {
          "<leader>fp",
          function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
          desc = "Find Plugin File",
        },
    },
    -- change some options
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
      },
    },
  },

  -- add pyright to lspconfig
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- pyright will be automatically installed with mason and loaded with lspconfig
        pyright = {},
      },
    },
  },
  -- add tsserver and setup with typescript.nvim instead of lspconfig
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
        -- tsserver will be automatically installed with mason and loaded with lspconfig
        tsserver = {},
        -- nushell = {},
      },
      -- you can do any additional lsp server setup here
      -- return true if you don't want this server to be setup with lspconfig
      ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
      setup = {
        -- example to setup with typescript.nvim
        tsserver = function(_, opts)
          require("typescript").setup({ server = opts })
          return true
        end,
        -- Specify * to use this function as a fallback for any server
        -- ["*"] = function(server, opts) end,
      },
    },
  },

  -- for typescript, LazyVim also includes extra specs to properly setup lspconfig,
  -- treesitter, mason and typescript.nvim. So instead of the above, you can use:
  { import = "lazyvim.plugins.extras.lang.typescript" },

  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "c_sharp",
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        -- "nu",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      },
    },
  },

  -- since `vim.tbl_deep_extend`, can only merge tables and not lists, the code above
  -- would overwrite `ensure_installed` with the new value.
  -- If you'd rather extend the default config, use the code below instead:
  {
    "nvim-treesitter/nvim-treesitter",
    -- dependencies = {
    --   { "nushell/tree-sitter-nu" },
    -- },
    opts = function(_, opts)
      -- --@diagnostic disable-next-line: inject-field
      -- require("nvim-treesitter.parsers").get_parser_configs().nu = {
      --   install_info = {
      --     url = "https://github.com/nushell/tree-sitter-nu",
      --     files = { "src/parser.c" },
      --     branch = "main",
      --   },
      --   filetype = "nu",
      -- }

      -- if type(opts.ensure_installed) == "table" then
      --   vim.list_extend(opts.ensure_installed, { "nu" })
      -- end

      -- add tsx and treesitter
      vim.list_extend(opts.ensure_installed, {
        "tsx",
        "typescript",
      })
    end,
  },

  -- Nushell
  -- { "nushell/tree-sitter-nu" },
  -- the opts function can also be used to change the default opts:
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, "😄")
    end,
  },

  -- or you can return new options to override all the defaults
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      return {
        --[[add your custom lualine config here]]
      }
    end,
  },

  -- use mini.starter instead of alpha
  { import = "lazyvim.plugins.extras.ui.mini-starter" },

  -- add jsonls and schemastore packages, and setup treesitter for json, json5 and jsonc
  { import = "lazyvim.plugins.extras.lang.json" },

  -- add any tools you want to have installed below
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "csharpier",
        "stylua",
        "shellcheck",
        "shfmt",
        "flake8",
      },
    },
  },

  -- Use <tab> for completion and snippets (supertab)
  -- first: disable default <tab> and <s-tab> behavior in LuaSnip
  {
    "L3MON4D3/LuaSnip",
    keys = function()
      return {}
    end,
  },
  -- then: setup supertab in cmp
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-emoji",
    },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      local luasnip = require("luasnip")
      local cmp = require("cmp")

      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
            -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
            -- this way you will only jump inside the snippet region
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      })
    end,
  },
}
