local wezterm = require "wezterm"
local config = wezterm.config_builder()

-- wezterm.gui is not available to the mux server, so take care to
-- do something reasonable when this config is evaluated by the mux
function get_appearance()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return "Light"
end

function scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return 'WildCherry'
  else
    return 'Alabaster'
  end
end


config.color_scheme = scheme_for_appearance(get_appearance())
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
