# wezterm-yazi-claude

A WezTerm setup for macOS with Chrome-style tabs. Each tab is split in two:

- **Top:** [yazi](https://github.com/sxyazi/yazi), for moving around your files.
- **Bottom:** a [Claude Code](https://claude.com/claude-code) session. Hover a folder in yazi and press `C` to start Claude in that folder.

A small **keys panel** next to yazi lists the important keys. It stays open until you click its ✕; `Cmd+I` brings it back.

The **+** button (or `Cmd+T`) opens a new tab with the same layout.

![A tab: yazi on top with the keys panel on the right, Claude waiting below](docs/overview.png)

![After pressing C on a folder: Claude runs in that folder while yazi shows its files](docs/claude.png)

## Why it's useful

- **Claude starts in the right folder.** You find the project in yazi, press `C`, and Claude opens there. You don't need to `cd` or type paths, and you can't start Claude in the wrong folder by mistake.
- **You can see what Claude is doing.** The files Claude creates or edits appear in yazi as it works, and yazi's preview shows their contents. You can check its work without leaving the window.
- **One tab per project.** Each tab has its own yazi and its own Claude, so several projects can run side by side with no mix-ups. Tabs work like Chrome's (`Cmd+T`, the **+** button).
- **No switching apps.** Copy, paste, rename, trash, search and preview files in the same window you're talking to Claude in. `Cmd+C`, `Cmd+V` and `Cmd+X` work on files the way they do in Finder.
- **Easy to learn.** The keys panel keeps the important keys on screen, so you don't need to know yazi before you start.

## Keys

| Where | Key | What it does |
|---|---|---|
| yazi | `C` | Start this tab's Claude in the hovered folder (or jump to it if it's already running) |
| yazi | `T` | Open a Terminal window in the current folder |
| yazi | `!` | Drop into a shell here; `exit` returns to yazi |
| yazi | `Cmd+C` / `Cmd+V` | Copy / paste files (same as `y` / `p`; in other panes they copy and paste text) |
| yazi | `Cmd+X` | Move the selected files to Trash (same as `d`; does nothing in other panes) |
| yazi | `Cmd+O` | Open the hovered file (or the selected ones) in its Mac app, like double-clicking in Finder: TextEdit, Preview, … A folder opens in Finder |
| WezTerm | `Cmd+I` | Show / hide the keys panel |
| WezTerm | `Cmd+T` / **+** | New tab |
| WezTerm | `Cmd+Option+↑` / `↓` | Switch between yazi and Claude |

Quitting yazi (`q`) leaves a shell in the folder you were in. Closing the Claude pane and pressing `C` again opens a fresh one.

## yazi cheat sheet

In WezTerm, the most important of these are always on screen in a small **keys panel** next to yazi. Click its ✕ (or press `q` in it) to close it, and `Cmd+I` to bring it back. Edit `yazi/keys-panel.sh` to change what it lists.

yazi's built-in keys (v26.9.1). Press `~` inside yazi for the full list. Keys written `g h` mean press `g`, then `h`.

### Moving around

| Key | What it does |
|---|---|
| `↑` `↓` or `k` `j` | Previous / next file |
| `←` or `h` | Go up to the parent folder |
| `→` or `l` | Enter the folder |
| `g g` / `G` | Jump to the top / bottom of the list |
| `H` / `L` | Back / forward through folders you visited |
| `g h` | Go to your home folder |
| `g d` | Go to Downloads |
| `g c` | Go to `~/.config` |
| `g Space` | Type a path to jump to |
| `z` | Find a file or folder by fuzzy search (fzf) |
| `Z` | Jump to a folder you use often (zoxide) |

### Files

| Key | What it does |
|---|---|
| `Enter` or `o` | Open the file (text files open in `vi` inside yazi unless `$EDITOR` is set; `Cmd+O` opens them in their Mac app) |
| `Cmd+O` or `Ctrl+O` | Open in the Mac app (this setup) |
| `O` | Open with… (choose the app) |
| `Cmd+C` or `y` | Copy the selected files |
| `x` | Cut the selected files |
| `Cmd+V` or `p` | Paste here |
| `P` | Paste and overwrite files with the same name |
| `Y` or `X` | Cancel copy / cut |
| `a` | New file (end the name with `/` for a folder) |
| `r` | Rename |
| `Cmd+X` or `d` | Move to Trash |
| `D` | Delete permanently |
| `-` | Create a symlink to the copied files |
| `.` | Show / hide hidden files |
| `Tab` | Show file details |

### Selecting several files

| Key | What it does |
|---|---|
| `Space` | Select / unselect the file, then move down |
| `v` | Visual mode: move to select a range |
| `Ctrl+A` | Select all |
| `Ctrl+R` | Invert the selection |
| `Esc` | Clear the selection |

### Search, filter and sort

| Key | What it does |
|---|---|
| `s` | Search file names in this folder and below |
| `S` | Search inside files (ripgrep) |
| `f` | Filter the list as you type |
| `/` / `?` | Find the next / previous match in the list |
| `n` / `N` | Next / previous match |
| `, m` | Sort by date modified (`, M` reverses) |
| `, s` | Sort by size (`, S` reverses) |
| `, a` | Sort by name (`, A` reverses) |
| `, e` | Sort by extension |

### Copy paths to the clipboard

| Key | What it copies |
|---|---|
| `c c` | Full path of the file |
| `c d` | Path of its folder |
| `c f` | File name |
| `c n` | File name without the extension |

### Other

| Key | What it does |
|---|---|
| `;` | Run a shell command here |
| `w` | Show running tasks (big copies, deletes) |
| `g t` | Open the Trash |
| `~` or `F1` | Help: every key binding |
| `q` | Quit |

yazi has its own tabs too (`t t` new, `1`–`9` switch, `[` `]` previous / next), but in this setup the WezTerm tabs do that job.

### Claude pane

| Key | What it does |
|---|---|
| type `/exit` or press `Ctrl+C` twice | End the Claude session |
| `Cmd+Option+↑` | Go back to yazi |

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
