# wezterm-yazi-claude

[Claude Code](https://claude.com/claude-code) with a file manager above it, for macOS. Each WezTerm tab has [yazi](https://github.com/sxyazi/yazi) on top and Claude Code below.

![yazi on top shows src/units.ts, the file Claude just created; Claude's summary is below; the keys panel is on the right](docs/screenshot.png)

## Why not just run Claude Code in a terminal?

On its own, Claude Code is a chat. It can't show you your files, so you open Finder or an editor to see what it changed, and you `cd` into a project before you start it. This setup puts the files and Claude in the same window:

- **You see the files while Claude works.** yazi shows the folder Claude is working in, and its preview shows a file as soon as Claude writes it. In the screenshot, Claude has just created `units.ts`, and yazi shows it above.
- **Starting Claude takes one key.** Find the project in yazi and press `C`. Claude starts in that folder, so you don't type paths or `cd`.
- **One tab per project.** Each tab has its own yazi and its own Claude. `Cmd+T` or the **+** button opens another tab.
- **You manage files in the same window.** `Cmd+C`, `Cmd+V`, `Cmd+X` and `Cmd+O` copy, paste, trash and open files, as in Finder.
- **You don't need to know yazi.** The keys panel on the right lists the important keys. Click its ✕ to close it; `Cmd+I` brings it back.

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
