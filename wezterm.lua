-- WezTerm: Chrome-style tabs. Each tab = yazi on top, Claude on the bottom.
local wezterm = require 'wezterm'
local mux = wezterm.mux
local home = wezterm.home_dir
local config = wezterm.config_builder()

config.set_environment_variables = {
  PATH = '/Applications/WezTerm.app/Contents/MacOS:/opt/homebrew/bin:' .. home
    .. '/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
}

-- Look
config.color_scheme = 'Catppuccin Mocha'
config.font_size = 14
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE' -- tabs in the title bar, like Chrome
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32
config.window_padding = { left = 8, right = 8, top = 6, bottom = 4 }
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.6 } -- dim the pane you're not in
config.window_frame = { font_size = 13 }

-- Top: yazi (quitting it leaves a shell in the folder you were in)
local YAZI = { '/bin/zsh', '-l', '-i', '-c', 'y ~; exec /bin/zsh -l -i' }
local WAITER = home .. '/.config/yazi/claude-waiter.sh'

local function setup_tab(tab, top)
  top:split { direction = 'Bottom', size = 0.5, cwd = home, args = { WAITER, tostring(top:pane_id()) } }
  tab:set_title 'New tab'
  top:activate()
end

local function new_tab(mux_window)
  local tab, top = mux_window:spawn_tab { cwd = home, args = YAZI }
  setup_tab(tab, top)
end

wezterm.on('gui-startup', function()
  local tab, top = mux.spawn_window { cwd = home, args = YAZI }
  setup_tab(tab, top)
end)

-- The + button
wezterm.on('new-tab-button-click', function(window, pane, button)
  if button == 'Left' then
    new_tab(window:mux_window())
    return false
  end
end)

config.keys = {
  { key = 't', mods = 'CMD', action = wezterm.action_callback(function(window) new_tab(window:mux_window()) end) },
  -- Switch between yazi and Claude
  { key = 'UpArrow',   mods = 'CMD|ALT', action = wezterm.action.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'CMD|ALT', action = wezterm.action.ActivatePaneDirection 'Down' },
}

return config
