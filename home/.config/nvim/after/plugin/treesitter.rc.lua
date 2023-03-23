local status, ts = pcall(require, "nvim-treesitter.configs")
if not status then
	return
end

-- This is required to not have cue files marked as `cuesheet`
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	pattern = { "*.cue" },
	command = "set filetype=cue",
})

local parse_config = require("nvim-treesitter.parsers").get_parser_configs()
parse_config.cue = {
	install_info = {
		url = "https://github.com/eonpatapon/tree-sitter-cue",
		files = { "src/parser.c", "src/scanner.c" },
		branch = "main",
	},
	filetype = "cue",
}

ts.setup({
	highlight = {
		enable = true,
		disable = {},
	},
	indent = {
		enable = true,
		disable = {},
	},
	ensure_installed = {
		"tsx",
		"lua",
		"json",
		"css",
		"hcl",
		"cue",
		"c_sharp",
		"yaml",
		"bash",
		"go",
		"markdown",
		"markdown_inline",
		"terraform",
	},
	autotag = {
		enable = true,
	},
})
