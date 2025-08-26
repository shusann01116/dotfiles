local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.font_size = 13
config.font = wezterm.font_with_fallback({ "JetBrains Mono", "Noto Sans JP" })
config.default_prog = { "/bin/zsh", "-l", "-c", "tmux a -t 0 || tmux" }
config.enable_tab_bar = false
config.color_scheme = "Catppuccin Mocha"
config.audible_bell = "Disabled"

return config
