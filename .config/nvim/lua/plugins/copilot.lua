return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  opts = function()
    require("copilot.api").status = require("copilot.status")
  end,
  config = function()
    require("copilot").setup({
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
