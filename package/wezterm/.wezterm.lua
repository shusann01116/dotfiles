local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.font_size = 13
config.font = wezterm.font("JetBrains Mono")
config.default_prog = { "/bin/zsh", "-l", "-c", "tmux a -t 0 || tmux" }
config.enable_tab_bar = false
config.color_scheme = "Catppuccin Mocha"

return config
