local status, null_ls = pcall(require, "null-ls")
if not status then
	return
end

null_ls.setup({
	on_attach = function(client, bufnr)
		if client.server_capabilities.documentFormattingProvider then
			vim.api.nvim_command([[augroup Format]])
			vim.api.nvim_command([[autocmd! * <buffer>]])
			vim.api.nvim_command([[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()]])
			vim.api.nvim_command([[augroup END]])
		end
	end,
	sources = {
		null_ls.builtins.diagnostics.eslint_d.with({
			diagnostics_format = "[eslint] #{m}\n(#{c]})",
		}),
		null_ls.builtins.diagnostics.markdownlint,
		null_ls.builtins.diagnostics.cfn_lint.with({
			filetypes = { "yml", "yaml", "json" },
		}),
		null_ls.builtins.code_actions.shellcheck,
		null_ls.builtins.formatting.shfmt,
		null_ls.builtins.formatting.prettierd.with({
			filetypes = {
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"vue",
				"css",
				"scss",
				"less",
				"html",
				"json",
				"jsonc",
				"yml",
				"yaml",
				"markdown",
				"markdown.mdx",
				"graphql",
				"handlebars",
			},
		}),
		null_ls.builtins.formatting.isort,
		null_ls.builtins.formatting.black,
		null_ls.builtins.formatting.stylua,
	},
})
