#!/bin/zsh
# Моди NFSU з Nexus Mods: HD-текстури трас і ASI-моди (HDReflections, ExtraOptions, ExtendedCustomization).
# Їх не можна викладати на GitHub (права авторів модів), тому архіви кожен завантажує сам.
#
#   mods.sh install [тека гри] [тека з архівами]   знайти архіви (zip/7z/rar або розпаковані теки) і встановити
#   mods.sh hd  on|off [тека гри]                  HD-текстури трас / оригінальні
#   mods.sh asi on|off [тека гри]                  ASI-моди увімк./вимк.
#   mods.sh status [тека гри]
# Зміни діють з наступного запуску гри.
emulate -L zsh
set -e -o pipefail
setopt extendedglob nullglob
HERE=${0:A:h}
[[ -f "$HERE/config.sh" ]] && source "$HERE/config.sh"

CMD=$1; shift || true
case $CMD in
  install) GAME=${1:-${GAME:-$HOME/Games/NFSU}}; MODS=${2:-$HOME/Downloads} ;;
  hd|asi)  ARG=$1; GAME=${2:-${GAME:-$HOME/Games/NFSU}} ;;
  status)  GAME=${1:-${GAME:-$HOME/Games/NFSU}} ;;
  *) sed -n '2,10p' "$0"; exit 1 ;;
esac
GAME=${GAME:A}; BK=$GAME/_mac-backup
ASI=(NFSUExtraOptions.asi NFSUExtraOptionsSettings.ini NFSUHDReflections.asi NFSUHDReflections.ini
     NFSU_ExtendedCustomization.asi NFSU_ExtendedCustomization.ini)
TRACKRE='(^|/)TEX[0-9][0-9][0-9][0-9]TRACK\.BIN$'

say()  { print -P "%F{cyan}==>%f $*"; }
warn() { print -P "%F{yellow}Увага:%f $*"; }
die()  { print -P "%F{red}Помилка:%f $*" >&2; exit 1; }
ccp()  { cp -c "$@" 2>/dev/null || cp "$@"; }   # APFS-клон: копія майже не займає місця

# Знайти файли: спершу розпаковані (найбільша тека з потрібними файлами), потім в архівах.
# find_src <regex-для-grep -E> <мін. кількість>  ->  REPLY = тека з файлами (архів розпаковується в тимчасову)
find_src() {  # find_src <regex: за чим шукати> <мін. кількість> [regex: що розпакувати з архіву, типово = перший]
  local re=$1 min=$2 xre=${3:-$1} d a n
  for d in ${(f)"$(find "$MODS" -maxdepth 6 -type f 2>/dev/null | grep -E "$re" | grep -vF "$GAME/" | xargs -I{} dirname {} | sort | uniq -c | sort -rn | head -1)"}; do
    n=${${d## #}%% *}; d=${d## #}; d=${d#* }
    (( n >= min )) && { REPLY=$d; return 0; }
  done
  for a in "$MODS"/*.(#i)(zip|7z|rar); do
    local all=$(bsdtar -tf "$a" 2>/dev/null)
    local list=(${(f)"$(print -r -- "$all" | grep -E "$re")"})
    (( ${#list} >= min )) || continue
    local xlist=(${(f)"$(print -r -- "$all" | grep -E "$xre")"})
    say "розпаковую потрібне з ${a:t}"
    TMPX=$(mktemp -d "$GAME/_mac-backup/tmp.XXXX")
    bsdtar -xf "$a" -C "$TMPX" "${xlist[@]}" || die "не вдалось розпакувати ${a:t} (розпакуйте вручну в $MODS)"
    REPLY=$TMPX/${list[1]:h}; [[ ${list[1]} == */* ]] || REPLY=$TMPX; return 0
  done
  return 1
}

hd_set() {
  local src
  case $1 in
    on)  [[ -d "$BK/hd-tracks" ]] || die "HD-текстури ще не встановлені (mods.sh install)"; src=$BK/hd-tracks ;;
    off) [[ -d "$BK/orig/Tracks" ]] || { say "оригінальні треки вже стоять"; return; }; src=$BK/orig/Tracks ;;
    *) die "hd on|off" ;;
  esac
  ccp -p "$src"/TEX*TRACK.BIN "$GAME/Tracks/"
  say "текстури трас: $1"
}
asi_set() {
  local f
  for f in "$GAME"/scripts/${^ASI:#*.ini}{,.off}; do
    [[ -f $f ]] || continue
    case $1 in
      on)  [[ $f == *.off ]] && mv "$f" "${f%.off}" ;;
      off) [[ $f == *.asi ]] && mv "$f" "$f.off" ;;
      *) die "asi on|off" ;;
    esac
  done
  say "ASI-моди: $1"
}

case $CMD in
  hd)  hd_set $ARG ;;
  asi) asi_set $ARG ;;
  status)
    if [[ -d "$BK/hd-tracks" ]] && cmp -s "$BK/hd-tracks/TEX1001TRACK.BIN" "$GAME/Tracks/TEX1001TRACK.BIN"; then print "HD-текстури трас: on"
    elif [[ -d "$BK/hd-tracks" ]]; then print "HD-текстури трас: off"; else print "HD-текстури трас: не встановлені"; fi
    if [[ -f "$GAME/scripts/NFSUHDReflections.asi" ]]; then print "ASI-моди: on"
    elif [[ -f "$GAME/scripts/NFSUHDReflections.asi.off" ]]; then print "ASI-моди: off"; else print "ASI-моди: не встановлені"; fi ;;
  install)
    mkdir -p "$BK"; TMPX=
    trap '[[ -n "$TMPX" ]] && rm -rf "$TMPX"' EXIT
    # --- HD-текстури трас (Nexus: NFSU, мод 4) ---
    if [[ -d "$BK/hd-tracks" ]]; then
      say "HD-текстури трас уже встановлені"
    elif find_src "$TRACKRE" 20; then
      SRC=$REPLY; files=("$SRC"/(#i)TEX[0-9](#c4)TRACK.BIN)
      mkdir -p "$BK/hd-tracks" "$BK/orig/Tracks"
      for f in $files; do
        n=${f:t:u}
        [[ -f "$GAME/Tracks/$n" && ! -f "$BK/orig/Tracks/$n" ]] && ccp -p "$GAME/Tracks/$n" "$BK/orig/Tracks/$n"
        ccp -p "$f" "$BK/hd-tracks/$n"
      done
      if [[ -f "$HERE/config/hd-tracks.sha256" ]]; then
        ok=$( (cd "$BK/hd-tracks" && shasum -a 256 -c "$HERE/config/hd-tracks.sha256" 2>/dev/null) | grep -c ': OK$' || true)
        (( ok == 31 )) && say "HD-текстури: 31 файл, усі збігаються з перевіреною версією" \
                       || warn "HD-текстури: збіглося $ok з 31 (інша версія моду?), ставлю як є"
      fi
      [[ -n "$TMPX" ]] && rm -rf "$TMPX"; TMPX=
      hd_set on
    else
      warn "HD-текстури трас не знайдено в $MODS (архів або тека з файлами TEX....TRACK.BIN). Гра працюватиме з оригінальними."
    fi
    # --- ASI-моди (з пакета Photorealistic Need for Speed Underground, Nexus) ---
    if [[ -f "$GAME/scripts/NFSUHDReflections.asi" || -f "$GAME/scripts/NFSUHDReflections.asi.off" ]]; then
      say "ASI-моди вже встановлені"
    elif find_src '(^|/)NFSU(HDReflections|ExtraOptions|_ExtendedCustomization)\.asi$' 3 \
                  "(^|/)(${(j:|:)${ASI//./\\.}})\$"; then
      SRC=$REPLY; mkdir -p "$BK/orig/scripts"
      for f in $ASI; do
        [[ -f "$SRC/$f" ]] || { warn "у пакеті немає $f"; continue; }
        if [[ -f "$GAME/scripts/$f" ]]; then [[ -f "$BK/orig/scripts/$f" ]] || cp -p "$GAME/scripts/$f" "$BK/orig/scripts/$f"
        else print -r -- "scripts/$f" >> "$BK/added.txt"; fi
        cp -p "$SRC/$f" "$GAME/scripts/$f"
      done
      # Свідомо НЕ беремо з пакета: старі dinput8.dll і WidescreenFix (ламають віконний режим), ReShade (d3d9.dll:
      # під Wine ефекти не компілюються і він замінив би d9vk), modupdater.asi (сам оновлює файли з інтернету).
      say "ASI-моди встановлено (вимкнути: mods.sh asi off)"
    else
      warn "ASI-моди не знайдено в $MODS. Гра працюватиме без них."
    fi ;;
esac
