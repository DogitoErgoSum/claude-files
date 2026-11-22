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

dir="$HOME/.cache/yazi-claude"
fifo="$dir/$WEZTERM_PANE.fifo"
saved="$dir/$WEZTERM_PANE.pane" # this tab's Claude pane, saved by claude-waiter.sh or below
claude_pane=""; [[ -r "$saved" ]] && claude_pane="$(<"$saved")"

# Is pane $1 still open, and in the same tab as yazi? (Checking the tab matters because
# pane ids start again from 0 when WezTerm restarts, so an old saved id could be another pane.)
in_this_tab() {
  [[ "$1" == <-> ]] || return 1
  $W cli list --format json 2>/dev/null | jq -e --argjson me "$WEZTERM_PANE" --argjson p "$1" \
    '(.[] | select(.pane_id == $me) | .tab_id) as $tab | any(.[]; .pane_id == $p and .tab_id == $tab)' >/dev/null
}

if in_this_tab "$claude_pane"; then
  if [[ -p "$fifo" ]]; then
    # Claude's pane is still waiting: start Claude in it
    print -r -- "$target" > "$fifo"
    $W cli set-tab-title --pane-id "$WEZTERM_PANE" "$name"
  fi
  # Jump to it (if Claude was already running, that's all `C` does)
  $W cli activate-pane --pane-id "$claude_pane"
else
  # Claude's pane was closed: open a fresh one below yazi, and remember it
  rm -f "$fifo"
  new="$($W cli split-pane --pane-id "$WEZTERM_PANE" --bottom --percent 50 --cwd "$target" -- "$claude")"
  [[ -n "$new" ]] && print -r -- "$new" > "$saved"
  $W cli set-tab-title --pane-id "$WEZTERM_PANE" "$name"
fi
