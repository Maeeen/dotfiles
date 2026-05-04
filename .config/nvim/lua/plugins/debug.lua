return {
  "mfussenegger/nvim-dap-python",
  config = function()
    require("dap-python").setup("python")

    local dap = require("dap")

    -- ensure we don't duplicate
    for _, c in ipairs(dap.configurations.python) do
      if c.name == "Python: Debug (all code)" then
        return
      end
    end

    table.insert(dap.configurations.python, 1, {
      type = "python",
      request = "launch",
      name = "Python: Debug (all code)",
      program = "${file}",
      justMyCode = false,
    })
  end,
}
