return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      copilot_node_command = vim.fn.expand("$HOME") .. "/.nvm/versions/node/v18.20.6/bin/node", -- Ensure Node.js version > 18.x
      suggestion = { enabled = true },
      panel = { enabled = true },
      copilot_filetypes = { yaml = true, yml = true, markdown = true },
      filetypes = {
        yaml = true,
        markdown = true,
        help = true,
        gitcommit = true,
        gitrebase = true,
        hgcommit = true,
        svn = true,
        cvs = false,
        ["."] = true,
      },
    })
  end,
}
