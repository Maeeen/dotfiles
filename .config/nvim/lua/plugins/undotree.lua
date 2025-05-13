return {
  "mbbill/undotree",
  keys = {
    -- One handed keymap recommended, you will be using the mouse
    {
      "<leader>sU",
      function()
        vim.cmd("UndotreeToggle")
      end,
      desc = "Toggle undo tree",
    },
  },
}
