vim.opt.clipboard:prepend { 'unnamed', 'unnamedplus' }
vim.g.clipboard = {
  'name': 'win32yank-wsl',
  'copy': {
    '+': 'win32yank.exe -i --crlf',
    '*': 'win32yank.exe -i --crlf',
  },
  'paste': {
    '+': 'win32yank.exe -o --crlf',
    '*': 'win32yank.exe -o --crlf',
  },
  'cache_enabled': 0,
}

