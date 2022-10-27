local status, mason = pcall(require, "mason")
if not status then
	return
end
local status2, mason_lspconfig = pcall(require, "mason-lspconfig")
if not status2 then
	return
end

mason.setup({})
mason_lspconfig.setup({
	ensure_installed = {
		"sumneko_lua",
		"tailwindcss",
		"csharp_ls",
		"dagger",
		"dockerls",
		"yamlls",
		"terraformls",
		"tsserver",
		"pylsp",
	},
})

vim.g.coq_settings = {
	auto_start = true,
}

local status3, coq = pcall(require, "coq")
if not status3 then
	return
end

local lspconfig = require("lspconfig")

lspconfig.tailwindcss.setup(coq.lsp_ensure_capabilities())
lspconfig.dagger.setup(coq.lsp_ensure_capabilities())
lspconfig.dockerls.setup(coq.lsp_ensure_capabilities())
lspconfig.yamlls.setup({
	coq.lsp_ensure_capabilities({
		settings = {
			yaml = {
				customTags = {
					"!Base64 scalar",
					"!Cidr scalar",
					"!And sequence",
					"!Equals sequence",
					"!If sequence",
					"!Not sequence",
					"!Or sequence",
					"!Condition scalar",
					"!FindInMap sequence",
					"!GetAtt scalar",
					"!GetAtt sequence",
					"!GetAZs scalar",
					"!ImportValue scalar",
					"!Join sequence",
					"!Select sequence",
					"!Split sequence",
					"!Sub scalar",
					"!Transform mapping",
					"!Ref scalar",
				},
				schemas = {
					["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "**/*docker-compose.yml",
					["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/all.json"] = "**/kube-manifests/*",
				},
			},
		},
	}),
})
lspconfig.terraformls.setup(coq.lsp_ensure_capabilities())
lspconfig.pylsp.setup(coq.lsp_ensure_capabilities())
lspconfig.tsserver.setup(coq.lsp_ensure_capabilities({
	filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
	cmd = { "typescript-language-server", "--stdio" },
}))
lspconfig.sumneko_lua.setup(coq.lsp_ensure_capabilities({
	settings = {
		Lua = {
			diagnostics = {
				-- Get the language server to recognize the 'vim' global
				globals = { "vim" },
			},
			workspace = {
				-- Make the server aware of Neovim runtime files
				library = vim.api.nvim_get_runtime_file("", true),
				checkThirdParty = false,
			},
		},
	},
}))

vim.cmd([[
  augroup COQ
    autocmd!
    autocmd VimEnter * COQnow -s
  augroup END
]])
