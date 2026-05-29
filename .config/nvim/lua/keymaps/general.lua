vim.keymap.set("n", "<Tab>", "<cmd>WhichKey<CR>", { desc = "Call yourself…" })
vim.keymap.set("n", "<leader>cL", function()
  vim.fn.setreg("+", vim.fn.expand("%:p") .. ":" .. vim.fn.line("."))
end, { desc = "Copy file path with line number" })

-- DAP restart
vim.keymap.set("n", "<leader>dR", function()
  local dap = require("dap")
  dap.restart()
end, { desc = "Restart debugger" })
