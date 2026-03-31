local api = require("cc99.v2.api")
local M = {}

M.setup = function()
  vim.api.nvim_create_user_command("CC99V2Open", function()
    api.open_float()
  end, { range = true })

  vim.api.nvim_create_user_command("CC99V2Close", function()
    api.close_float()
  end, { range = true })

  vim.api.nvim_create_user_command("CC99V2Exec", function()
    api.cc_exec()
  end, { range = true })

  vim.keymap.set("v", "<leader>ccm", ":CC99V2Open<CR>", { noremap = true, silent = true, desc = "Open cc99 v2 float" })
  vim.keymap.set(
    "n",
    "<leader>ccq",
    ":CC99V2Close<CR>",
    { noremap = true, silent = true, desc = "Close cc99 v2 float" }
  )

  vim.keymap.set(
    "n",
    "<leader>ccx",
    ":CC99V2Exec<CR>",
    { noremap = true, silent = true, desc = "Execute cc99 v2 command" }
  )
end

return M
