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

-- Cheat sheet (Cmd+/): a searchable list of keys. Picking one presses it in this tab's yazi.
-- { group, key as shown, what it does, keys to send to yazi (nil = just a reminder) }
local KEYS = {
  { 'This setup', 'C',            'Start Claude in the hovered folder', 'C' },
  { 'This setup', 'T',            'Open a Terminal window here', 'T' },
  { 'This setup', '!',            'Open a shell here (exit returns to yazi)', '!' },
  { 'This setup', 'Cmd+T',        'New tab' },
  { 'This setup', 'Cmd+Opt+Up',   'Go to yazi (top)' },
  { 'This setup', 'Cmd+Opt+Down', 'Go to Claude (bottom)' },
  { 'Claude',     '/exit',        'End the Claude session (or Ctrl+C twice)' },

  { 'Move',   'Up / Down',  'Previous / next file' },
  { 'Move',   'Left',       'Go up to the parent folder', 'h' },
  { 'Move',   'Right',      'Enter the folder', 'l' },
  { 'Move',   'g g',        'Jump to the top of the list', 'gg' },
  { 'Move',   'G',          'Jump to the bottom of the list', 'G' },
  { 'Move',   'H',          'Back to the previous folder', 'H' },
  { 'Move',   'L',          'Forward to the next folder', 'L' },
  { 'Go to',  'g h',        'Home folder', 'gh' },
  { 'Go to',  'g d',        'Downloads', 'gd' },
  { 'Go to',  'g c',        '~/.config', 'gc' },
  { 'Go to',  'g t',        'Trash', 'gt' },
  { 'Go to',  'g Space',    'Type a path to jump to', 'g ' },
  { 'Go to',  'z',          'Find a file or folder (fuzzy search)', 'z' },
  { 'Go to',  'Z',          'Jump to a folder you use often', 'Z' },

  { 'Files',  'Enter / o',  'Open the file', 'o' },
  { 'Files',  'O',          'Open with... (choose the app)', 'O' },
  { 'Files',  'y',          'Copy the selected files', 'y' },
  { 'Files',  'x',          'Cut the selected files', 'x' },
  { 'Files',  'p',          'Paste here', 'p' },
  { 'Files',  'P',          'Paste and overwrite same-named files', 'P' },
  { 'Files',  'Y',          'Cancel copy / cut', 'Y' },
  { 'Files',  'a',          'New file (end with / for a folder)', 'a' },
  { 'Files',  'r',          'Rename', 'r' },
  { 'Files',  'd',          'Move to Trash', 'd' },
  { 'Files',  'D',          'Delete permanently', 'D' },
  { 'Files',  '-',          'Create a symlink to the copied files', '-' },
  { 'Files',  '.',          'Show / hide hidden files', '.' },
  { 'Files',  'Tab',        'Show file details', '\t' },

  { 'Select', 'Space',      'Select / unselect, then move down', ' ' },
  { 'Select', 'v',          'Visual mode: move to select a range', 'v' },
  { 'Select', 'Ctrl+A',     'Select all', '\x01' },
  { 'Select', 'Ctrl+R',     'Invert the selection', '\x12' },
  { 'Select', 'Esc',        'Clear the selection / cancel', '\x1b' },

  { 'Search', 's',          'Search file names (this folder and below)', 's' },
  { 'Search', 'S',          'Search inside files', 'S' },
  { 'Search', 'f',          'Filter the list as you type', 'f' },
  { 'Search', '/  ?',       'Find next / previous match in the list', '/' },
  { 'Search', 'n  N',       'Next / previous match' },
  { 'Sort',   ', m',        'Sort by date modified (, M reverses)', ',m' },
  { 'Sort',   ', s',        'Sort by size (, S reverses)', ',s' },
  { 'Sort',   ', a',        'Sort by name (, A reverses)', ',a' },
  { 'Sort',   ', e',        'Sort by extension', ',e' },

  { 'Copy',   'c c',        'Copy the full path', 'cc' },
  { 'Copy',   'c d',        "Copy the folder's path", 'cd' },
  { 'Copy',   'c f',        'Copy the file name', 'cf' },
  { 'Copy',   'c n',        'Copy the file name without extension', 'cn' },

  { 'Other',  ';',          'Run a shell command here', ';' },
  { 'Other',  'w',          'Show running tasks (big copies, deletes)', 'w' },
  { 'Other',  '~',          "yazi's full help", '~' },
  { 'Other',  'q',          'Quit yazi', 'q' },
}

local function yazi_pane(tab)
  for _, info in ipairs(tab:panes_with_info()) do
    if info.top == 0 and (info.pane:get_foreground_process_name() or ''):find('yazi') then
      return info.pane
    end
  end
end

local show_keys = wezterm.action_callback(function(window, pane)
  local choices = {}
  for i, k in ipairs(KEYS) do
    choices[i] = { id = tostring(i), label = string.format('%-11s %-14s %s', k[1], k[2], k[3]) }
  end
  window:perform_action(wezterm.action.InputSelector {
    title = 'Keys: type to search · Enter presses it in yazi · Esc closes',
    fuzzy = true,
    fuzzy_description = 'Search keys (e.g. copy, sort, trash): ',
    choices = choices,
    action = wezterm.action_callback(function(win, _, id)
      local k = id and KEYS[tonumber(id)]
      if not (k and k[4]) then return end
      local top = yazi_pane(win:active_tab())
      if not top then return end
      top:activate()
      win:perform_action(wezterm.action.SendString(k[4]), top)
    end),
  }, pane)
end)

-- Hint in the tab bar
wezterm.on('update-right-status', function(window)
  window:set_right_status(wezterm.format { { Foreground = { AnsiColor = 'Grey' } }, { Text = '⌘/ keys  ' } })
end)

config.keys = {
  { key = '/', mods = 'CMD', action = show_keys },
  { key = 't', mods = 'CMD', action = wezterm.action_callback(function(window) new_tab(window:mux_window()) end) },
  -- Switch between yazi and Claude
  { key = 'UpArrow',   mods = 'CMD|ALT', action = wezterm.action.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'CMD|ALT', action = wezterm.action.ActivatePaneDirection 'Down' },
}

return config
