-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Setup pytest keymaps for Python files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.keymap.set("n", "<leader>t", "<nop>", { desc = "Tests", buffer = true })

    vim.keymap.set("n", "<leader>tp", function()
      local dap = require("dap")
      local config = vim.deepcopy({
        type = "python",
        request = "launch",
        name = "Pytest: Current File",
        module = "pytest",
        args = { vim.fn.expand("%:p"), "-v", "-s" },
        justMyCode = false,
      })
      dap.run(config)
    end, { desc = "Debug pytest current file", buffer = true })

    vim.keymap.set("n", "<leader>tP", function()
      local dap = require("dap")
      local config = vim.deepcopy({
        type = "python",
        request = "launch",
        name = "Pytest: All",
        module = "pytest",
        args = { "tests/", "-v", "-s" },
        justMyCode = false,
      })
      dap.run(config)
    end, { desc = "Debug pytest all tests", buffer = true })

    vim.keymap.set("n", "<leader>tt", function()
      local dap = require("dap")
      local file = vim.fn.expand("%:p")
      local line = vim.fn.line(".")

      -- Find test function name at or before cursor
      local test_name = nil
      for i = line, 1, -1 do
        local text = vim.fn.getline(i)
        local match = string.match(text, "^%s*def%s+(test_[%w_]+)")
        if match then
          test_name = match
          break
        end
      end

      if not test_name then
        vim.notify("No test function found before cursor", vim.log.levels.ERROR)
        return
      end

      local config = vim.deepcopy({
        type = "python",
        request = "launch",
        name = "Pytest: Current Test",
        module = "pytest",
        args = { file .. "::" .. test_name, "-v", "-s" },
        justMyCode = false,
      })
      dap.run(config)
    end, { desc = "Debug pytest at cursor", buffer = true })
  end,
})

vim.api.nvim_create_autocmd({
  "BufNewFile",
  "BufRead",
}, {
  pattern = "*.typ",
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_option(buf, "filetype", "typst")
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "tex",
  callback = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 5000
  end,
})
