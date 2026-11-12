# Need for Speed Underground на Mac (Apple Silicon)

Один скрипт: NFS Underground (2003) на Mac з M1–M4, на весь екран, 50–120 к/с.

## Вимоги

- Mac з Apple M1 або новішим. Intel не підтримується.
- macOS 15+ (перевірено на 15.8.1 і 27.0.1). На 11–14 ставиться без rosettax87: FPS нижчий, не перевірено.
- Гра NFSU US: образи двох дисків + патч 1.4 + NoCD `Speed.exe`, або готова тека гри 1.4 NoCD.
- ~3 ГБ на диску (+3,5 ГБ з HD-текстурами, і ще стільки ж тимчасово під час встановлення).
- Інтернет під час встановлення (~330 МБ). Homebrew і Xcode не потрібні.

## Встановлення

0. Гра: [завантажити](https://shorturl.at/Wc9G0).
1. Покладіть теку з роздачі як є (`Disc 1`, `Disc 2`, `NFSU_US_Patch_1.4`, `NFSU_US_Crack_1.4`) у `~/Games/NFSU`.
   Замість дисків можна покласти готову теку гри з `Speed.exe`.
2. Необов'язково: моди з Nexus. Завантажте **Manual download** у `~/Downloads`, не розпаковуйте:
   - HD-текстури трас: [мод 4](https://www.nexusmods.com/needforspeedunderground/mods/4);
   - ASI-моди: пакет *Photorealistic Need for Speed Underground* у [розділі NFSU](https://www.nexusmods.com/needforspeedunderground/mods/).
3. Завантажте цей репозиторій (**Code → Download ZIP** або `git clone`), відкрийте Термінал у його теці:
   ```
   zsh install.sh
   ```
   Якщо диски чи гра лежать деінде (наприклад, на зовнішньому диску): `zsh install.sh "/шлях/до/теки"`.

Скрипт сам:
- перевірить Mac і macOS, за потреби поставить Rosetta 2;
- збере гру з дисків у `~/Games/NFSU/Game` (образи → файли, патч 1.4, NoCD; ~1 хв, без кліків);
- завантажить Wine 11.6, d9vk, WidescreenFix і звірить контрольні суми;
- на macOS 26+ поставить пропатчений MoltenVK (без нього на 27 зависання ~20 с на кожній зміні сцени);
- поставить моди, якщо знайде їх у `~/Downloads` (zip, 7z, rar або розпаковані; перевірено лише zip);
- створить іконку **NFSU** на робочому столі.

Замінені файли гри зберігаються в `<тека гри>/_mac-backup/`.

## Гра

- Запуск: іконка **NFSU** або `~/Games/NFSU-mac/nfsu.sh`.
- Лічильник FPS: `DXVK_HUD=fps ~/Games/NFSU-mac/nfsu.sh`.
- Роздільність: у налаштуваннях гри (Display).
- Перші заїзди можуть пригальмовувати: компілюються шейдери.
- macOS 27, перший запуск: дозвольте *authorize debugging* (потрібно rosettax87).
- Гра застигла: клацніть на інше вікно і назад у гру (неактивне вікно гра ставить на паузу).

## Моди

```
~/Games/NFSU-mac/mods.sh install     # поставити моди, докачані пізніше
~/Games/NFSU-mac/mods.sh status
~/Games/NFSU-mac/mods.sh hd on|off   # HD-текстури трас
~/Games/NFSU-mac/mods.sh asi on|off  # ASI-моди (вимкнути, якщо FPS замалий)
```

Діє з наступного запуску гри. Архів не розпізнався: розпакуйте його в `~/Downloads` і повторіть `install`.
З ASI-пакета беруться лише `NFSUHDReflections`, `NFSUExtraOptions`, `NFSU_ExtendedCustomization`; ReShade і старий WidescreenFix з нього під Mac не працюють.

## Видалення

```
zsh uninstall.sh          # повернути файли гри, прибрати Wine й іконку (префікс лишається)
zsh uninstall.sh --all    # разом із префіксом
```

## Змінні

| Змінна | Що робить |
|---|---|
| `NFSU_GAME` | куди збирати гру з дисків (типово `~/Games/NFSU`; якщо диски там же, то `~/Games/NFSU/Game`) |
| `NFSU_MAC_HOME` | куди ставити Wine, префікс, запускалку (типово `~/Games/NFSU-mac`) |
| `NFSU_MODS` | де шукати архіви модів (типово `~/Downloads`) |
| `NFSU_MVK=patched\|orig` | примусово вибрати MoltenVK |
| `NFSU_NO_APP=1` | без іконки |
| `NFSU_ANY_EXE=1` | не перевіряти версію `Speed.exe` |

## Що всередині

- [Wine Staging 11.6](https://github.com/aitorciki/macOS_Wine_builds) (LGPL): новіші не підтримують rosettax87.
- [d9vk](https://github.com/Sikarugir-App/d9vk) (zlib): DirectX 9 → Vulkan → Metal, 50–120 к/с замість 15–23 через wined3d.
- [rosettax87](https://github.com/Lifeisawful/rosettax87_jit) (MIT, `vendor/rosettax87/`, без змін): швидкі x87-інструкції.
- [WidescreenFix](https://github.com/ThirteenAG/WidescreenFixesPack): широкий екран і безрамковий режим; без нього гра на Mac не стартує.
- [MoltenVK](https://github.com/KhronosGroup/MoltenVK) 1.4.1 (Apache 2.0, `vendor/moltenvk/`): збірка з двома патчами, що лежать поруч.

Гри й модів з Nexus у репозиторії немає.
