#!/bin/zsh
# Прибрати обв'язку: повернути оригінальні файли гри з _mac-backup, видалити Wine, rosettax87 та іконку.
#   zsh uninstall.sh [тека гри]          wine-префікс (там можуть бути збереження гри) лишається
#   zsh uninstall.sh --all [тека гри]    видалити й префікс
emulate -L zsh
set -e
ALL=0; [[ "$1" == --all ]] && { ALL=1; shift; }
BASE=${NFSU_MAC_HOME:-$HOME/Games/NFSU-mac}
[[ -f "$BASE/config.sh" ]] && source "$BASE/config.sh"
GAME=${1:-${GAME:-$HOME/Games/NFSU}}; BK=$GAME/_mac-backup
if ps -axo command | grep -q '[S]peed\.exe$'; then print "Спершу закрийте гру."; exit 1; fi

if [[ -d "$BK/orig" ]]; then
  (cd "$BK/orig" && find . -type f) | while read -r f; do cp -p "$BK/orig/$f" "$GAME/$f"; done
  print "Оригінальні файли гри повернуто."
fi
if [[ -f "$BK/added.txt" ]]; then
  while read -r f; do [[ -n "$f" ]] && rm -f "$GAME/$f" "$GAME/$f.off"; done < "$BK/added.txt"
fi
rm -rf "$BK" "$HOME/Desktop/NFSU.app" "$BASE/Wine Staging 11.6.app" "$BASE/rosettax87" "$BASE/cache" \
       "$BASE"/{nfsu.sh,mods.sh,config.sh}
if (( ALL )); then rm -rf "$BASE"; print "Видалено все, включно з префіксом."
else print "Готово. Wine-префікс лишився в $BASE/prefix (видалити: uninstall.sh --all)."; fi
