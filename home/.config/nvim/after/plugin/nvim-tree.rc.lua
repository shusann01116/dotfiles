local status, tree = pcall(require, "nvim-tree")
if (not status) then
  print("nvim-tree is not installed")
  return
end

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

tree.setup({
  view = {
    mappings = {
      list = {
        { key = "s", action = "" }, -- remove system open action
        { key = "<Tab>", action = "" }, -- remove preview
      }
    }
  },
})
