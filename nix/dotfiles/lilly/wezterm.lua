local wezterm = require "wezterm"
local config = wezterm.config_builder()

config.color_scheme = "Alabaster"
config.use_fancy_tab_bar = true
config.front_end = "WebGpu"
config.keys = {
{
    key = "E",
    mods = "CTRL",
    action = wezterm.action.SplitPane { direction = "Right" },
},
{
    key = "O",
    mods = "CTRL",
    action = wezterm.action.SplitPane { direction = "Down" }
},
{
    key = "RightArrow",
    mods = "ALT",
    action = wezterm.action.ActivatePaneDirection "Right",
},
{
    key = "LeftArrow",
    mods = "ALT",
    action = wezterm.action.ActivatePaneDirection "Left",
},
{
    key = "UpArrow",
    mods = "ALT",
    action = wezterm.action.ActivatePaneDirection "Up",
},
{
    key = "DownArrow",
    mods = "ALT",
    action = wezterm.action.ActivatePaneDirection "Down",
},
}

return config
