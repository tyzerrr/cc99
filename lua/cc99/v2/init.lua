local api = require("cc99.v2.api")
local M = {}

M.setup = function()
  vim.api.nvim_create_user_command("CC99V2Open", function()
    api.open_float()
  end, {})

  vim.api.nvim_create_user_command("CC99V2Close", function()
    api.close_float()
  end, {})

  vim.api.nvim_create_user_command("CC99V2Exec", function()
    api.cc_exec()
  end, {})

  vim.keymap.set(
    "v",
    "<leader>ccm",
    "<cmd>CC99V2Open<CR>",
    { noremap = true, silent = true, desc = "Open cc99 v2 float" }
  )
  vim.keymap.set(
    "n",
    "<leader>ccq",
    "<cmd>CC99V2Close<CR>",
    { noremap = true, silent = true, desc = "Close cc99 v2 float" }
  )

  vim.keymap.set(
    "n",
    "<leader>ccx",
    "<cmd>CC99V2Exec<CR>",
    { noremap = true, silent = true, desc = "Execute cc99 v2 command" }
  )
end

return M
