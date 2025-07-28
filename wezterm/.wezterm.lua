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
-- config.font = wezterm.font("Menlo", {weight="Regular", stretch="Normal", style="Normal"})
config.font = wezterm.font_with_fallback({
  "JetBrains Mono",            -- 英語
  "HackGen Console NF",        -- 日本語
})

config.font_size = 14.0
-- config.use_ime = true
config.freetype_load_target = "Light"

config.default_cursor_style = "BlinkingBlock"

config.color_scheme = 'nord'
-- config.color_scheme = 'Edge Dark (base16)'
-- config.color_scheme = 'AdventureTime'
config.window_background_opacity = 0.8
config.macos_window_background_blur = 20

config.window_decorations = "RESIZE"

config.scrollback_lines = 10000

-- タブバーの透過
config.window_frame = {
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
}

-- タブバーを背景色に合わせる
-- config.window_background_gradient = {
--   colors = { "#1f1d45" }, -- AdventureTime
-- }

config.hide_tab_bar_if_only_one_tab = true
-- タブの追加ボタンを非表示
config.show_new_tab_button_in_tab_bar = false
-- タブの閉じるボタンを非表示
config.show_close_tab_button_in_tabs = false

-- タブ同士の境界線を非表示
-- config.colors = {
--   tab_bar = {
--     inactive_tab_edge = "none",
--   },
-- }

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local background = "#5c6d74"
  local foreground = "#FFFFFF"

  if tab.is_active then
    background = "#ae8b2d"
    foreground = "#FFFFFF"
  end

  -- Get the current working directory
  local cwd = tab.active_pane.current_working_dir
  local title = ""
  
  if cwd then
    -- Convert file URI to path
    local path = cwd.file_path
    
    -- Check if it's a GitHub repository by looking for github.com in the path
    local github_match = string.match(path, "github%.com/[^/]+/([^/]+)")
    
    if github_match then
      -- Use the repository name as title
      title = github_match
    else
      -- Check if it's in any git repository
      local home = os.getenv("HOME")
      if home and path:sub(1, #home) == home then
        -- Replace home directory with ~
        path = "~" .. path:sub(#home + 1)
      end
      
      -- Get the last directory name
      title = string.match(path, "([^/]+)/?$") or path
    end
  else
    -- Fallback to pane title if cwd is not available
    title = tab.active_pane.title
  end

  title = "   " .. wezterm.truncate_right(title, max_width - 1) .. "   "

  return {
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
  }
end)

config.disable_default_key_bindings = true
config.keys = require("keybinds").keys
config.key_tables = require("keybinds").key_tables
config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }

-- and finally, return the configuration to wezterm
return config
