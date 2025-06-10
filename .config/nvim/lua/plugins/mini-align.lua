return {
  "echasnovski/mini.align",
  version = "*",
  keys = {
    { "ga", mode = { "n", "x" }, desc = "MiniAlign: Align" },
    { "gA", mode = { "n", "x" }, desc = "MiniAlign: Align with preview" },
  },
  config = function()
    local align = require("mini.align")
    align.setup()

    local map = vim.keymap.set
    map({ "n", "x" }, "ga", align.align, { desc = "MiniAlign: Align" })
    map({ "n", "x" }, "gA", align.align_with_preview, { desc = "MiniAlign: Align with preview" })
  end,
}
