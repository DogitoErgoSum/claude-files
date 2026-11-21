-- WezTerm: Chrome-style tabs. Each tab = yazi on top, Claude on the bottom,
-- and a small keys panel next to yazi (click its ✕ to close, Cmd+I to bring it back).
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
local KEYS_PANEL = home .. '/.config/yazi/keys-panel.sh'
local KEYS_PANEL_WIDTH = 30 -- columns

local function open_keys_panel(top)
  top:split { direction = 'Right', size = KEYS_PANEL_WIDTH, cwd = home, args = { KEYS_PANEL } }
end

local function setup_tab(tab, top)
  top:split { direction = 'Bottom', size = 0.5, cwd = home, args = { WAITER, tostring(top:pane_id()) } }
  open_keys_panel(top)
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

-- Cmd+I: show or hide this tab's keys panel
local toggle_keys_panel = wezterm.action_callback(function(window, pane)
  local panes = pane:tab():panes_with_info()
  for _, info in ipairs(panes) do
    if info.pane:get_user_vars().keys_panel then
      window:perform_action(wezterm.action.CloseCurrentPane { confirm = false }, info.pane)
      return
    end
  end
  for _, info in ipairs(panes) do -- reopen it next to the top-left pane (yazi)
    if info.top == 0 and info.left == 0 then
      open_keys_panel(info.pane)
      info.pane:activate()
      return
    end
  end
end)

config.keys = {
  { key = 'i', mods = 'CMD', action = toggle_keys_panel },
  { key = 't', mods = 'CMD', action = wezterm.action_callback(function(window) new_tab(window:mux_window()) end) },
  -- Switch between yazi and Claude
  { key = 'UpArrow',   mods = 'CMD|ALT', action = wezterm.action.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'CMD|ALT', action = wezterm.action.ActivatePaneDirection 'Down' },
}

return config
