return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.highlight = opts.highlight or {}
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "bibtex", "latex" })
      end
      if type(opts.highlight.disable) == "table" then
        vim.list_extend(opts.highlight.disable, { "latex" })
      else
        opts.highlight.disable = { "latex" }
      end
    end,
  },
  {
    "lervag/vimtex",
    enabled = true,
    lazy = false, -- lazy-loading will disable inverse search
    config = function()
      vim.g.vimtex_imaps_leader = "!"
      vim.g.vimtex_mappings_disable = { ["n"] = { "K" } } -- disable `K` as it conflicts with LSP hover
      vim.g.vimtex_quickfix_method = vim.fn.executable("pplatex") == 1 and "pplatex" or "latexlog"
      vim.g.vimtex_view_method = "zathura"
      vim.o.foldmethod = "expr"
      vim.o.foldexpr = "vimtex#fold#level(v:lnum)"
      vim.o.foldtext = "vimtex#fold#text()"
      vim.g.vimtex_enabled = true
      vim.g.tex_flavor = "latex"
      vim.g.vimtex_format_enabled = true
    end,
    keys = {
      { "<localLeader>l", "", desc = "+vimtex", ft = "tex" },
      { "t", "", desc = "+vimtex", ft = "tex" }, -- enable t mappings
    },
  },
  {
    "neovim/nvim-lspconfig",
    optional = true,
    opts = {
      servers = {
        texlab = {
          keys = {
            { "<Leader>K", "<plug>(vimtex-doc-package)", desc = "Vimtex Docs", silent = true },
          },
        },
      },
    },
  },
}
