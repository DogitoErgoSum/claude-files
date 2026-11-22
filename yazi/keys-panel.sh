#!/bin/zsh
# Small panel listing the important keys. Click the ✕ (top line) or press q here to close it.

printf '\e]1337;SetUserVar=keys_panel=%s\a' "$(print -n 1 | base64)" # lets Cmd+I find this pane
printf '\e]2;Keys\a'

cleanup() { printf '\e[?1000l\e[?1006l\e[?25h' }
trap cleanup EXIT

k() { print -P " %B%F{blue}${(r:6:)1}%f%b %F{white}$2%f" }   # key, what it does
h() { print -P "\n %F{magenta}%B$1%b%f" }                      # section heading

draw() {
  local cols=${${(z)$(stty size </dev/tty)}[2]}
  printf '\e[?25l\e[H\e[2J'
  print -nP " %B%F{yellow}Keys%f%b"
  printf '\e[%dG' $(( cols - 2 ))
  print -P "%F{red}%B✕%b%f"
  h 'This setup'
  k 'C'      'Claude here'
  k 'T'      'Terminal here'
  k '⌘T'     'New tab'
  k '⌘⌥↑↓'   'yazi ⇄ Claude'
  k '⌘I'     'Hide panel'
  h 'Files'
  k '⌘O'     'Open in app'
  k 'Click'  'Play video'
  k '⌘C ⌘V'  'Copy / paste'
  k 'x'      'Cut'
  k 'a'      'New (/ = dir)'
  k 'r'      'Rename'
  k 'u'      'Unzip'
  k '⌘X d'   'Trash'
  k 'Space'  'Select'
  k '.'      'Hidden files'
  k 'c c'    'Copy path'
  h 'Find & go'
  k 's S'    'Find name/text'
  k 'z'      'Fuzzy jump'
  k 'g h'    'Home'
  k 'g d'    'Downloads'
  k '~'      'All keys'
  k '/exit'  'Close Claude'
}

trap draw WINCH
draw
printf '\e[?1000h\e[?1006h' # report mouse clicks (SGR format)

while true; do
  read -rs -k 1 c || continue
  if [[ $c == q ]]; then
    exit
  elif [[ $c == $'\e' ]]; then
    read -rs -k 1 -t 0.1 c || continue; [[ $c == '[' ]] || continue
    read -rs -k 1 -t 0.1 c || continue; [[ $c == '<' ]] || continue
    seq=''
    while read -rs -k 1 -t 0.1 c && [[ $c != [Mm] ]]; do seq+=$c; done
    parts=(${(s:;:)seq})              # button ; column ; row
    [[ $c == M && $parts[1] == 0 && $parts[3] == 1 ]] && exit  # left click on the top line
  fi
done
