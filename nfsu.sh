#!/bin/zsh
# Запуск NFS Underground: Wine 11.6 + d9vk + rosettax87. Якщо гра вже йде, лише виводить її вікно вперед.
#   DXVK_HUD=fps nfsu.sh   лічильник FPS у кутку
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
BASE=${0:A:h}
source "$BASE/config.sh"     # GAME=...
WINE="$BASE/Wine Staging 11.6.app/Contents/Resources/wine/bin/wine"

if ps -axo command | grep -q '[S]peed\.exe$'; then
  osascript -e 'tell application "System Events" to set frontmost of (first process whose name is "wine") to true' >/dev/null 2>&1
  exit 0
fi

cd "$GAME" || exit 1
[[ "${X87:-1}" == 1 ]] && export ROSETTA_X87_PATH="$BASE/rosettax87/runtime_loader"   # лише macOS 15+
WINEPREFIX="$BASE/prefix" \
WINEDLLOVERRIDES="d3d9=n;dinput8=n,b" \
DXVK_ASYNC="${DXVK_ASYNC-1}" \
DXVK_HUD="${DXVK_HUD-}" \
exec "$WINE" ./Speed.exe
