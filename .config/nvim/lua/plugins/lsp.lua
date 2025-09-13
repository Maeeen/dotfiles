return {
  -- requires tinymist
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "tinymist",
        "kotlin-lsp",
      },
    },
  },
  -- add tinymist to lspconfig
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
    ---@class PluginLspOpts
    opts = {
      setup = {
        rust_analyzer = function()
          return true
        end,
      },
      servers = {
        kotlin_language_server = {
          mason = false,
          enabled = false,
        },
        qmlls = {
          cmd = { "qmlls6", "-E" },
          filetypes = { "qml", "qmljs" },
          root_dir = function()
            return vim.fn.getcwd()
          end,
        },
        tinymist = {
          --- todo: these configuration from lspconfig maybe broken
          single_file_support = true,
          root_dir = function()
            return vim.fn.getcwd()
          end,
          offset_encoding = "utf-8",
          --- See [Tinymist Server Configuration](https://github.com/Myriad-Dreamin/tinymist/blob/main/Configuration.md) for references.
          settings = {
            formatterMode = "typstyle",
            exportPdf = "onType",
          },
        },
      },
    },
  },
}
