# Need for Speed Underground на Mac (Apple Silicon)

Скрипт ставить усе, щоб NFS Underground (2003) працювала на Mac з процесором Apple (M1–M4), швидко й на весь екран:

- **Wine Staging 11.6**: запускає Windows-гру. Саме 11.6, бо новіші прибрали підтримку rosettax87.
- **d9vk**: перекладає DirectX 9 гри у Vulkan, а через MoltenVK у Metal. Це дає ~50–120 к/с замість 15–23 через стандартний перекладач Wine (wined3d).
- **rosettax87**: швидка емуляція старих математичних інструкцій x87, якими гра користується постійно.
- **WidescreenFix** (ThirteenAG): широкий екран без розтягування і повноекранний режим без рамки. Без нього гра на Mac не стартує.
- **Пропатчений MoltenVK**: потрібен на macOS 26+, ставиться автоматично. Без нього на macOS 27 кожна зміна сцени зависала на ~20 с. Патчі лежать у `vendor/moltenvk/`.
- **HD-моди** (необов'язково): HD-текстури трас і ASI-моди з Nexus Mods (див. нижче).

Самої гри й модів з Nexus у репозиторії немає: їх кожен бере сам.

## Що потрібно

- Mac з Apple M1/M2/M3/M4. На Intel не працюватиме.
- macOS 15 або новіша. Перевірено на 15.8.1 (M1 Pro) і 27.0.1 (M4 Pro).
- Гра **Need for Speed Underground, US, версія 1.4, NoCD** (`Speed.exe` без захисту від копіювання). Скрипт звіряє `Speed.exe` і з іншою версією відмовиться ставити.
- ~2 ГБ вільного місця під Wine та інше, плюс ~3,5 ГБ, якщо ставите HD-текстури.

## Встановлення

1. Покладіть теку з грою в `~/Games/NFSU`, тобто щоб був файл `~/Games/NFSU/Speed.exe`. Можна й в інше місце, тоді вкажіть шлях у кроці 3.
2. (Необов'язково) Завантажте моди з Nexus Mods у `~/Downloads`, архіви розпаковувати не треба:
   - **HD-текстури трас**: [Nexus: NFS Underground, мод 4](https://www.nexusmods.com/needforspeedunderground/mods/4). Скрипт бере з архіву 31 файл `Tracks/TEX….TRACK.BIN`.
   - **ASI-моди** (HD-відбиття, додаткові налаштування, розширений тюнінг): пакет *Photorealistic Need for Speed Underground* у [розділі NFS Underground на Nexus](https://www.nexusmods.com/needforspeedunderground/mods/). З нього беруться лише `NFSUHDReflections`, `NFSUExtraOptions` і `NFSU_ExtendedCustomization`. ReShade і старий WidescreenFix з цього пакета під Mac не працюють, тому скрипт їх не чіпає.
3. Відкрийте **Термінал**, перейдіть у теку цього репозиторію і запустіть:
   ```
   zsh install.sh
   ```
   або, якщо гра лежить деінде:
   ```
   zsh install.sh "/шлях/до/NFSU"
   ```
   Скрипт сам визначить процесор і версію macOS, за потреби поставить Rosetta 2, завантажить Wine (~320 МБ) і решту, звірить контрольні суми й створить на робочому столі іконку **NFSU**.

Оригінальні файли гри, які скрипт замінює, зберігаються в `<тека гри>/_mac-backup/`.

## Гра

- Запуск: іконка **NFSU** на робочому столі, або `~/Games/NFSU-mac/nfsu.sh`.
- Перший запуск і перші заїзди можуть пригальмовувати: d9vk компілює шейдери, далі бере їх з кешу.
- На macOS 27 при першому запуску система може спитати дозвіл на налагодження (*authorize debugging*). Його потребує rosettax87, треба дозволити.
- Лічильник FPS: `DXVK_HUD=fps ~/Games/NFSU-mac/nfsu.sh`.
- Роздільність вибирається в налаштуваннях самої гри (розділ Display).
- Якщо гра «застигла», а Mac працює: клацніть на інше вікно і назад у гру. Неактивне вікно гра ставить на паузу.

## Моди: увімкнути / вимкнути

```
~/Games/NFSU-mac/mods.sh status
~/Games/NFSU-mac/mods.sh hd off        # оригінальні текстури трас (hd on - повернути HD)
~/Games/NFSU-mac/mods.sh asi off       # вимкнути ASI-моди (якщо FPS замалий)
~/Games/NFSU-mac/mods.sh install       # якщо архіви модів завантажили вже після встановлення
```

Зміни діють з наступного запуску гри.

## Видалення

```
zsh uninstall.sh            # повертає оригінальні файли гри, прибирає Wine й іконку; wine-префікс лишається
zsh uninstall.sh --all      # те саме разом із префіксом
```

## Налаштування для досвідчених

| Змінна | Що робить |
|---|---|
| `NFSU_MAC_HOME` | куди ставити Wine/префікс/запускалку (типово `~/Games/NFSU-mac`) |
| `NFSU_MODS` | де шукати архіви модів (типово `~/Downloads`) |
| `NFSU_MVK=patched` / `orig` | примусово пропатчений або штатний MoltenVK |
| `NFSU_NO_APP=1` | не створювати іконку |
| `NFSU_ANY_EXE=1` | не перевіряти версію `Speed.exe` (на свій ризик) |

## Ліцензії сторонніх компонентів

- `vendor/rosettax87/`: [rosettax87_jit](https://github.com/Lifeisawful/rosettax87_jit), MIT, файли релізу без змін.
- `vendor/moltenvk/`: [MoltenVK](https://github.com/KhronosGroup/MoltenVK) 1.4.1, Apache 2.0, зібраний із двома патчами, що лежать поруч.
- Завантажуються з офіційних релізів: [Wine](https://github.com/aitorciki/macOS_Wine_builds) (LGPL), [d9vk](https://github.com/Sikarugir-App/d9vk) (zlib), [WidescreenFix](https://github.com/ThirteenAG/WidescreenFixesPack).
