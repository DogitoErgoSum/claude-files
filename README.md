# wezterm-yazi-claude

A WezTerm setup for macOS with Chrome-style tabs. Each tab is split in two:

- **Top:** [yazi](https://github.com/sxyazi/yazi), for moving around your files.
- **Bottom:** a [Claude Code](https://claude.com/claude-code) session. Hover a folder in yazi and press `C` to start Claude in that folder.

The **+** button (or `Cmd+T`) opens a new tab with the same layout.

## Keys

| Where | Key | What it does |
|---|---|---|
| yazi | `C` | Start this tab's Claude in the hovered folder (or jump to it if it's already running) |
| yazi | `T` | Open a Terminal window in the current folder |
| yazi | `!` | Drop into a shell here; `exit` returns to yazi |
| WezTerm | `Cmd+T` / **+** | New tab |
| WezTerm | `Cmd+Option+↑` / `↓` | Switch between yazi and Claude |

Quitting yazi (`q`) leaves a shell in the folder you were in. Closing the Claude pane and pressing `C` again opens a fresh one.

## Install

Requirements: macOS, [Homebrew](https://brew.sh) and [Claude Code](https://claude.com/claude-code) installed at `~/.local/bin/claude`.

```sh
brew install --cask wezterm
brew install yazi ffmpeg sevenzip jq poppler fd ripgrep fzf zoxide resvg imagemagick font-symbols-only-nerd-font
git clone https://github.com/DogitoErgoSum/wezterm-yazi-claude.git
cd wezterm-yazi-claude && ./install.sh
```

`install.sh` symlinks the config into place and backs up any existing files with a `.bak` suffix:

| Repo file | Linked to |
|---|---|
| `wezterm.lua` | `~/.wezterm.lua` |
| `yazi/*` | `~/.config/yazi/*` |
| `zsh/y.zsh` | sourced from `~/.zshrc` (the `y` command: yazi that changes your shell's folder on quit) |

## How it works

Each new tab runs yazi on top and `claude-waiter.sh` on the bottom. The waiter creates a named pipe and waits. Pressing `C` in yazi runs `claude-here.sh` with the hovered path, which writes the folder into the pipe. The waiter then `cd`s there and starts Claude.
