#!/bin/zsh
# Bottom pane of a tab: waits until yazi (pane id $1) picks a folder, then runs Claude there.
fifo="$HOME/.cache/yazi-claude/$1.fifo"
mkdir -p "${fifo:h}"; rm -f "$fifo"; mkfifo "$fifo"
trap 'rm -f "$fifo"' EXIT HUP INT TERM
printf '\e]2;Claude\a\e[?25l'; clear
print -P "\n   %F{8}Pick a folder in yazi above and press%f %BC%b %F{8}to start Claude there.%f"
IFS= read -r target < "$fifo"
rm -f "$fifo"; trap - EXIT HUP INT TERM
printf '\e[?25h'; clear
cd -- "$target" || exit 1
exec "$HOME/.local/bin/claude"
