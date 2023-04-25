local status, vscode = pcall(require, "vscode")
if not status then
	return
end

vscode.setup({
	transparent = true,
	disable_nvimtree_bg = true,
})
vscode.load()
