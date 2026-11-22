#!/bin/zsh
# Symlinks this repo's config into place. Existing files are backed up with a .bak suffix.
set -e
repo="${0:A:h}"

# Warn about anything missing (the README's Install section has the brew commands)
missing=()
[[ -d /Applications/WezTerm.app ]] || missing+=(WezTerm)
(( $+commands[yazi] )) || missing+=(yazi)
(( $+commands[jq] )) || missing+=(jq) # claude-here.sh uses it to find this tab's Claude pane
(( $+commands[claude] )) || [[ -x "$HOME/.local/bin/claude" ]] || missing+=('Claude Code')
if (( $#missing )); then
  echo "Not installed yet: ${(j:, :)missing}. The config is linked anyway; install them before you open WezTerm."
fi
if [[ -e "$HOME/.config/wezterm/wezterm.lua" ]]; then
  echo "Note: you also have ~/.config/wezterm/wezterm.lua. WezTerm uses only one config file, so rename that one to make sure this setup is used."
fi

link() {
  local src="$1" dst="$2"
  mkdir -p "${dst:h}"
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    mv "$dst" "$dst.bak"
    echo "backed up $dst -> $dst.bak"
  fi
  ln -s "$src" "$dst"
  echo "linked $dst -> $src"
}

link "$repo/wezterm.lua" "$HOME/.wezterm.lua"
for f in yazi.toml init.lua theme.toml keymap.toml claude-here.sh claude-waiter.sh keys-panel.sh; do
  link "$repo/yazi/$f" "$HOME/.config/yazi/$f"
done
for p in video-play fit-preview; do
  link "$repo/yazi/plugins/$p.yazi" "$HOME/.config/yazi/plugins/$p.yazi"
done

if ! grep -q 'zsh/y.zsh' "$HOME/.zshrc" 2>/dev/null && ! grep -q '^function y()' "$HOME/.zshrc" 2>/dev/null; then
  print -r -- "source \"$repo/zsh/y.zsh\"" >> "$HOME/.zshrc"
  echo "added the y function to ~/.zshrc"
fi
