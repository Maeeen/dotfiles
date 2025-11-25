return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    vscode = true,
    ---@type Flash.Config
    opts = {},
    keys = {
      { "s", mode = { "x", "o" }, enabled = false },
    },
  },
}
