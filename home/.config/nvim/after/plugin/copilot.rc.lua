vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("\\<CR>")', { silent = true, script = true, expr = true })
vim.api.nvim_set_var("copilot_no_tab_map", true)
