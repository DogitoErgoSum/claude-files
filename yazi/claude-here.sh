#!/bin/zsh
# Called by yazi's `C` key with the hovered path. Fixes this tab's Claude to that folder.
target="${1:-$PWD}"
[[ -d "$target" ]] || target="${target:h}"
target="${target:A}"
name="${target:t}"; [[ "$target" == "$HOME" ]] && name="~"
W=/Applications/WezTerm.app/Contents/MacOS/wezterm
claude="$(whence -p claude || zsh -lic 'whence -p claude' 2>/dev/null | tail -1)"
[[ -x "$claude" ]] || claude="$HOME/.local/bin/claude"

if [[ -z "$WEZTERM_PANE" ]]; then
  # Not inside WezTerm: open Claude in a new Terminal window instead
  osascript - "$target" "$claude" <<'OSA'
on run argv
  tell application "Terminal"
    do script "cd " & quoted form of (item 1 of argv) & " && " & quoted form of (item 2 of argv)
    activate
  end tell
end run
OSA
  exit
fi

fifo="$HOME/.cache/yazi-claude/$WEZTERM_PANE.fifo"
below="$($W cli get-pane-direction Down --pane-id "$WEZTERM_PANE" 2>/dev/null)"

if [[ -p "$fifo" && -n "$below" ]]; then
  # Bottom pane is waiting: start Claude in it
  print -r -- "$target" > "$fifo"
  $W cli set-tab-title --pane-id "$WEZTERM_PANE" "$name"
  $W cli activate-pane --pane-id "$below"
elif [[ -n "$below" ]]; then
  # Claude already fixed for this tab: just jump to it
  $W cli activate-pane --pane-id "$below"
else
  # Claude pane was closed: open a fresh one below
  rm -f "$fifo"
  $W cli split-pane --pane-id "$WEZTERM_PANE" --bottom --percent 50 --cwd "$target" -- "$claude" >/dev/null
  $W cli set-tab-title --pane-id "$WEZTERM_PANE" "$name"
fi
