vim.keymap.set("n", "<Tab>", "<cmd>WhichKey<CR>", { desc = "Call yourself…" })

vim.keymap.set({ "n", "v" }, "p", '"0p', { noremap = true })
vim.keymap.set({ "n", "v" }, "p", '"0P', { noremap = true })
