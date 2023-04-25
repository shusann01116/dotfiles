local status, bufferline = pcall(require, "bufferline")
if not status then
	return
end
local status2, c = pcall(require, "vscode.colors")
if not status then
	return
end

bufferline.setup({
	options = {
		mode = "tabs",
		separator_style = "thin",
		diagnostics = "nvim_lsp",
		diagnostics_indicator = function(count, level, diagnostics_dict, context)
			return "(" .. count .. ")"
		end,
		offsets = {
			{
				filetype = "NvimTree",
				text = "File Explorer",
				text_align = "center",
				separator = true,
			},
		},
		color_icons = true,
		show_buffer_close_icons = false,
		show_close_icon = false,
		show_tab_indicators = false,
		always_show_bufferline = true,
		hover = {
			enabled = true,
			delay = 200,
			reveal = { "close" },
		},
	},
})

vim.cmd("highlight BufferLineFill guibg=none")

vim.keymap.set("n", "]b", "<Cmd>BufferLineCycleNext<CR>", {})
vim.keymap.set("n", "[b", "<Cmd>BufferLineCyclePrev<CR>", {})
