#!/bin/zsh
# Встановлення обв'язки для Need for Speed Underground (US 1.4, NoCD) на Mac з Apple Silicon:
# Wine Staging 11.6 + d9vk (D3D9 -> Vulkan -> Metal) + rosettax87 (швидкий x87) + WidescreenFix (+ HD-мод, ASI-моди).
#
#   zsh install.sh [тека гри]          типово ~/Games/NFSU
#
# Змінні (необов'язкові):
#   NFSU_MAC_HOME  куди ставити Wine, префікс і запускалку (типово ~/Games/NFSU-mac)
#   NFSU_MODS      де шукати завантажені архіви HD-моду й ASI-модів (типово ~/Downloads)
#   NFSU_MVK       patched | orig  - примусово вибрати MoltenVK (типово: patched на macOS 26+, orig на 15 і старших)
#   NFSU_NO_APP=1  не створювати іконку на робочому столі
#   NFSU_ANY_EXE=1 не перевіряти Speed.exe (на свій ризик)
emulate -L zsh
set -e -o pipefail

HERE=${0:A:h}
GAME=${1:-$HOME/Games/NFSU}; GAME=${GAME:A}
BASE=${NFSU_MAC_HOME:-$HOME/Games/NFSU-mac}; mkdir -p "$BASE"; BASE=${BASE:A}
MODS=${NFSU_MODS:-$HOME/Downloads}
CACHE=$BASE/cache
APP="$BASE/Wine Staging 11.6.app"
WINEBIN="$APP/Contents/Resources/wine/bin"
PFX=$BASE/prefix
BK=$GAME/_mac-backup

# Закріплені версії (перевірено на M1 Pro / macOS 15.8.1 і M4 Pro / macOS 27.0.1, 2026-11)
WINE_URL=https://github.com/aitorciki/macOS_Wine_builds/releases/download/11.6/wine-staging-11.6-osx64.tar.xz
WINE_SHA=054113ce6d9322ccb2444df2a89abad3c7a8fee12b836ae0f400e00e6398eb70
D9VK_URL=https://github.com/Sikarugir-App/d9vk/releases/download/v1.10.3-20250511/d9vk-macOS-async-v1.10.3-20250511.tar.gz
D9VK_SHA=13a088e96c90501705c26326044ccc57e2b03adda3ed0dd7061e89249d4c176e
WSF_URL=https://github.com/ThirteenAG/WidescreenFixesPack/releases/download/nfsu/NFSUnderground.WidescreenFix.zip
WSF_SHA=c4ea2a23caa5f34f52afd35a8a1e4da58a439eafe45dc605ceaa6685fc7e69b9   # реліз оновлюється на місці: інша сума = нова версія
EXE_NOCD=c0fad450912952f53809a54690d235aa8b4e25b9f46650693c7cbee1b4c074b7      # Speed.exe US 1.4 NoCD
EXE_NOCD_LAA=813ff41b8b042871df3302b737f4a190cfc84b7e748aa8f34ea1d9deea9f017d  # той самий з прапорцем Large Address Aware

say()  { print -P "%F{cyan}==>%f $*"; }
warn() { print -P "%F{yellow}Увага:%f $*"; }
die()  { print -P "%F{red}Помилка:%f $*" >&2; exit 1; }
sha()  { shasum -a 256 "$1" | awk '{print $1}'; }
fetch() {  # fetch URL SHA FILE [soft]
  local url=$1 want=$2 out=$CACHE/${1:t}
  mkdir -p "$CACHE"
  if [[ ! -f "$out" ]] || [[ "$(sha "$out")" != "$want" && -z "$3" ]]; then
    say "завантажую ${url:t}"
    curl -fL --progress-bar -o "$out.part" "$url" || die "не вдалось завантажити $url"
    mv "$out.part" "$out"
  fi
  local got=$(sha "$out")
  if [[ "$got" != "$want" ]]; then
    [[ -n "$3" ]] && warn "${url:t}: контрольна сума інша (оновлена версія?), ставлю як є" \
                  || { rm -f "$out"; die "${url:t}: контрольна сума не збігається"; }
  fi
  REPLY=$out
}
backup() {  # backup <шлях відносно гри>: перший оригінал зберігається один раз
  local f=$1
  if [[ -e "$GAME/$f" ]]; then
    [[ -e "$BK/orig/$f" ]] || { mkdir -p "$BK/orig/${f:h}"; cp -pR "$GAME/$f" "$BK/orig/$f"; }
  else
    grep -qxF "$f" "$BK/added.txt" 2>/dev/null || print -r -- "$f" >> "$BK/added.txt"
  fi
}

# ---------- 1. Перевірки ----------
[[ "$(sysctl -n hw.optional.arm64 2>/dev/null)" == 1 ]] || die "потрібен Mac з процесором Apple (M1 і новіші). На Intel цей рецепт не перевірявся."
OSV=$(sw_vers -productVersion); OSMAJ=${OSV%%.*}
say "macOS $OSV, $(sysctl -n machdep.cpu.brand_string)"
(( OSMAJ >= 11 )) || die "потрібна macOS 11 або новіша (MoltenVK не працює на старших)"
# rosettax87 (швидкий x87) підтримує лише macOS 15+; на старших гра піде без нього: працює, але повільніше
X87=1
if (( OSMAJ < 15 )); then
  X87=0
  warn "macOS $OSV: rosettax87 потребує macOS 15+, ставлю без нього (FPS буде нижчим). Цю версію macOS не перевіряли."
fi
[[ -f "$GAME/Speed.exe" ]] || die "не знайдено $GAME/Speed.exe. Покладіть файли гри в цю теку або вкажіть теку: zsh install.sh /шлях/до/NFSU"
[[ -d "$GAME/Tracks" ]] || die "у $GAME немає теки Tracks: це не повна тека гри"

if ! arch -x86_64 /usr/bin/true 2>/dev/null; then
  say "ставлю Rosetta 2 (Wine працює через неї)"
  softwareupdate --install-rosetta --agree-to-license || die "Rosetta не встановилась"
fi

EXE_SHA=$(sha "$GAME/Speed.exe")
if [[ "$EXE_SHA" != "$EXE_NOCD" && "$EXE_SHA" != "$EXE_NOCD_LAA" ]]; then
  [[ -n "$NFSU_ANY_EXE" ]] || die "Speed.exe не той, з яким це перевірялось (потрібен US 1.4 NoCD; sha256 $EXE_SHA).
  Якщо впевнені, запустіть з NFSU_ANY_EXE=1."
  warn "Speed.exe невідомої версії, продовжую (NFSU_ANY_EXE=1)"
fi
mkdir -p "$BK"

# ---------- 2. Speed.exe: Large Address Aware (гра бачить 4 ГБ пам'яті замість 2, потрібно для HD-текстур) ----------
LFA=$(od -An -tu4 -j60 -N4 "$GAME/Speed.exe" | tr -d ' ')
CH=$(od -An -tu2 -j$((LFA+22)) -N2 "$GAME/Speed.exe" | tr -d ' ')
if (( (CH & 0x20) == 0 )); then
  backup Speed.exe
  printf "\\x$(printf %02x $(( (CH | 0x20) & 0xFF )))" | dd of="$GAME/Speed.exe" bs=1 seek=$((LFA+22)) conv=notrunc 2>/dev/null
  say "Speed.exe: увімкнено Large Address Aware (оригінал у _mac-backup/orig)"
fi

# ---------- 3. Wine 11.6 ----------
# Саме 11.6: у 11.7+ прибрали підтримку ROSETTA_X87_PATH (rosettax87), а без неї гра повільна.
if [[ ! -x "$WINEBIN/wine" ]]; then
  fetch $WINE_URL $WINE_SHA
  T=$(mktemp -d "$BASE/tmp.XXXX"); tar xJf "$REPLY" -C "$T"
  rm -rf "$APP"; mv "$T/Wine Staging.app" "$APP"; rm -rf "$T"
  xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true
  say "Wine Staging 11.6 -> $APP"
fi

# ---------- 4. MoltenVK ----------
# На macOS 27 штатний MoltenVK давав паузи ~20 с на кожній зміні сцени (перший запис 32-бітного коду в пам'ять,
# спільну з Metal, іде через обробник Rosetta). Пропатчений (vendor/moltenvk, патчі поруч) це прибирає.
# На macOS 15 пауз немає, там лишається штатний. macOS 26 не перевірялась: типово як 27.
MVK="$APP/Contents/Resources/wine/lib/libMoltenVK.dylib"
[[ -f "$MVK.orig" ]] || cp -p "$MVK" "$MVK.orig"
MVK_MODE=${NFSU_MVK:-$( (( OSMAJ >= 26 )) && echo patched || echo orig )}
if [[ "$MVK_MODE" == patched ]]; then
  cp "$HERE/vendor/moltenvk/libMoltenVK-1.4.1-fan+prefault-x86_64.dylib" "$MVK"
  say "MoltenVK: пропатчений 1.4.1 (macOS $OSMAJ)"
else
  cp -p "$MVK.orig" "$MVK"
  say "MoltenVK: штатний"
fi
codesign -f -s - "$MVK" 2>/dev/null || true

# ---------- 5. rosettax87 ----------
mkdir -p "$BASE/rosettax87"
cp "$HERE"/vendor/rosettax87/{runtime_loader,libRuntimeRosettax87,LICENSE} "$BASE/rosettax87/"
chmod +x "$BASE/rosettax87/runtime_loader"
xattr -dr com.apple.quarantine "$BASE/rosettax87" 2>/dev/null || true

# ---------- 6. Wine-префікс ----------
export WINEPREFIX=$PFX
if [[ ! -f "$PFX/system.reg" ]]; then
  say "створюю wine-префікс (перший раз до кількох хвилин)"
  WINEDLLOVERRIDES="mscoree,mshtml=" "$WINEBIN/wine" wineboot -i >/dev/null 2>&1 || true
  "$WINEBIN/wineserver" -w || true
  [[ -f "$PFX/system.reg" ]] || die "wine-префікс не створився ($PFX)"
fi
# Без RetinaMode меню й HUD малюються крихітними в куті (Retina-екран)
"$WINEBIN/wine" reg add 'HKCU\Software\Wine\Mac Driver' /v RetinaMode /t REG_SZ /d y /f >/dev/null 2>&1
"$WINEBIN/wineserver" -w || true
grep -q '"RetinaMode"="y"' "$PFX/user.reg" || die "не вдалось записати RetinaMode у реєстр префікса"

# ---------- 7. d9vk ----------
fetch $D9VK_URL $D9VK_SHA
T=$(mktemp -d "$BASE/tmp.XXXX"); tar xzf "$REPLY" -C "$T"
backup d3d9.dll; cp "$T"/*/x32/d3d9.dll "$GAME/d3d9.dll"; rm -rf "$T"
say "d9vk 1.10.3 (32 біт) -> гра/d3d9.dll"
if [[ ! -f "$GAME/dxvk.conf" ]]; then
  backup dxvk.conf; cp "$HERE/config/dxvk.conf" "$GAME/dxvk.conf"
fi

# ---------- 8. WidescreenFix ----------
fetch $WSF_URL $WSF_SHA soft
WSF_INI=scripts/NFSUnderground.WidescreenFix.ini
NEW_INI=0; [[ -f "$GAME/$WSF_INI" ]] || NEW_INI=1
for f in dinput8.dll scripts/NFSUnderground.WidescreenFix.{asi,dat,tpk,ini}; do backup $f; done
unzip -oq "$REPLY" -x "$WSF_INI" -d "$GAME"
if (( NEW_INI )); then
  unzip -oq "$REPLY" "$WSF_INI" -d "$GAME"
  # 4 = безрамковий повний екран; без віконного режиму гра падає (macOS не має режиму 800x600x32)
  sed -i '' -E 's/^(WindowedMode = )[0-9]+/\14/' "$GAME/$WSF_INI"
fi
grep -q '^WindowedMode = [1-5]' "$GAME/$WSF_INI" || warn "у $WSF_INI WindowedMode = 0: гра, ймовірно, не запуститься (потрібно 1-5)"
say "WidescreenFix (ThirteenAG) встановлено"

# ---------- 9. Моди з Nexus (якщо архіви завантажено) ----------
"$HERE/mods.sh" install "$GAME" "$MODS" || warn "моди не встановлено (див. вище); гра працюватиме й без них"

# ---------- 10. Запускалка й іконка ----------
cp "$HERE/nfsu.sh" "$HERE/mods.sh" "$BASE/"; chmod +x "$BASE/nfsu.sh" "$BASE/mods.sh"
print -r -- "GAME=${(q)GAME}" > "$BASE/config.sh"
print -r -- "X87=$X87" >> "$BASE/config.sh"
if [[ -z "$NFSU_NO_APP" ]]; then
  DAPP="$HOME/Desktop/NFSU.app"
  rm -rf "$DAPP"
  osacompile -o "$DAPP" -e "do shell script quoted form of \"$BASE/nfsu.sh\" & \" >/dev/null 2>&1 &\"" >/dev/null
  # іконка з файлів самої гри (у репозиторії її немає: це графіка EA)
  [[ -f "$GAME/NFSU_icon.ico" ]] && sips -s format icns "$GAME/NFSU_icon.ico" --out "$DAPP/Contents/Resources/applet.icns" >/dev/null 2>&1 || true
  touch "$DAPP"; codesign -f -s - "$DAPP" >/dev/null 2>&1 || true
  say "іконка: ~/Desktop/NFSU.app"
fi

say "готово. Запуск: іконка NFSU на робочому столі або $BASE/nfsu.sh"
say "лічильник FPS: DXVK_HUD=fps $BASE/nfsu.sh"
