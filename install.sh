#!/bin/zsh
# Symlinks this repo's config into place. Existing files are backed up with a .bak suffix.
set -e
repo="${0:A:h}"

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
for f in theme.toml keymap.toml claude-here.sh claude-waiter.sh keys-panel.sh; do
  link "$repo/yazi/$f" "$HOME/.config/yazi/$f"
done

if ! grep -q 'zsh/y.zsh' "$HOME/.zshrc" 2>/dev/null && ! grep -q '^function y()' "$HOME/.zshrc" 2>/dev/null; then
  print -r -- "source \"$repo/zsh/y.zsh\"" >> "$HOME/.zshrc"
  echo "added the y function to ~/.zshrc"
fi
