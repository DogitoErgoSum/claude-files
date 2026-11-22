#!/bin/zsh
# Bottom pane of a tab: waits until yazi (pane id $1) picks a folder, then runs Claude there.
dir="$HOME/.cache/yazi-claude"
fifo="$dir/$1.fifo"
mkdir -p "$dir"; rm -f "$fifo"; mkfifo "$fifo"
# Remember this pane, so claude-here.sh finds it wherever it is. Claude replaces this script
# in the same pane (exec below), so the id stays Claude's.
print -r -- "$WEZTERM_PANE" > "$dir/$1.pane"
trap 'rm -f "$fifo"' EXIT HUP INT TERM
printf '\e]2;Claude\a\e[?25l'; clear
print -P "\n   %F{8}Pick a folder in yazi above and press%f %BC%b %F{8}to start Claude there.%f"
IFS= read -r target < "$fifo"
rm -f "$fifo"; trap - EXIT HUP INT TERM
printf '\e[?25h'; clear
cd -- "$target" || exit 1
# Find claude: on PATH, else on your login shell's PATH (npm, nvm, …), else the default install location
claude="$(whence -p claude || zsh -lic 'whence -p claude' 2>/dev/null | tail -1)"
[[ -x "$claude" ]] || claude="$HOME/.local/bin/claude"
if [[ ! -x "$claude" ]]; then
  print -P "\n   %F{red}Claude Code not found.%f Install it from https://claude.com/claude-code, then press C again.\n   Press Enter to close."
  read -r; exit 1
fi
exec "$claude"
