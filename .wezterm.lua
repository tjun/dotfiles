-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices
-- config.font = wezterm.font 'JetBrains Mono'
config.font = wezterm.font("Menlo", {weight="Regular", stretch="Normal", style="Normal"})
-- config.font = wezterm.font("Cica", {weight="Regular", stretch="Normal", style="Normal"})
config.font_size = 13.0
config.color_scheme = 'Flatland'
config.color_scheme = 'Edge Dark (base16)'



-- and finally, return the configuration to wezterm
return config
