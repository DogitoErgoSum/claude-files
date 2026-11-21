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
local KEYS_PANEL_WIDTH = 23 -- columns

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

-- In yazi, Cmd+C / Cmd+V copy and paste files (yazi's y / p), Cmd+X moves them to Trash (d)
-- and Cmd+O opens them in their Mac app (Ctrl+O, see yazi/keymap.toml). Everywhere else Cmd+C / Cmd+V copy and paste text.
local function in_yazi(pane)
  return (pane:get_foreground_process_name() or ''):match('yazi$') ~= nil
end

local function yazi_or(yazi_key, fallback, yazi_mods)
  return wezterm.action_callback(function(window, pane)
    if in_yazi(pane) then
      window:perform_action(wezterm.action.SendKey { key = yazi_key, mods = yazi_mods }, pane)
    else
      window:perform_action(fallback, pane)
    end
  end)
end

config.keys = {
  { key = 'c', mods = 'CMD', action = yazi_or('y', wezterm.action.CopyTo 'Clipboard') },
  { key = 'v', mods = 'CMD', action = yazi_or('p', wezterm.action.PasteFrom 'Clipboard') },
  { key = 'x', mods = 'CMD', action = yazi_or('d', wezterm.action.Nop) }, -- Move to Trash in yazi
  { key = 'o', mods = 'CMD', action = yazi_or('o', wezterm.action.Nop, 'CTRL') }, -- Open in Mac app in yazi
  { key = 'i', mods = 'CMD', action = toggle_keys_panel },
  { key = 't', mods = 'CMD', action = wezterm.action_callback(function(window) new_tab(window:mux_window()) end) },
  -- Switch between yazi and Claude
  { key = 'UpArrow',   mods = 'CMD|ALT', action = wezterm.action.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'CMD|ALT', action = wezterm.action.ActivatePaneDirection 'Down' },
}

return config
