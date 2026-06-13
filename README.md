# ╔══════════════════════════════════════════════════════════════╗
# ║              zapret-desacratio                              ║
# ║     Красивая TUI панель управления обходом блокировок DPI    ║
# ╚══════════════════════════════════════════════════════════════╝

![Nord Theme](https://img.shields.io/badge/theme-Nord-81a1c1)
![License](https://img.shields.io/badge/license-GPLv3-blue)
![Platform](https://img.shields.io/badge/platform-Linux-88c0d0)

**zapret-desacratio** — это удобная обёртка над [bol-van/zapret](https://github.com/bol-van/zapret) с красивым TUI-интерфейсом в стиле Nord. Упрощает установку, настройку и ежедневное использование DPI-обхода для обычных пользователей.

## ✨ Особенности

- **Красивый TUI** — стильный интерфейс с Nord-палитрой, рамками и анимациями
- **Простая установка** — одна команда для любого дистрибутива
- **Готовые стратегии** — default, discord, youtube, general + кастомные
- **Списки доменов** — категоризированные списки для разных сервисов
- **Управление сервисом** — запуск/остановка/перезапуск через TUI
- **Смена темы** — Nord, Catppuccin, Dark Red на выбор
- **AUR пакет** — для Arch-производных
- **Проверка доменов** — тест доступности прямо из TUI

## 🚀 Установка

### Через curl (любой дистрибутив)

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/kall1shnik0vv/zapret-desacratio/main/installer.sh)"
```

### Через AUR (Arch, CachyOS, Manjaro и др.)

```bash
yay -S zapret-desacratio
# или
paru -S zapret-desacratio
```

### Вручную

```bash
git clone https://github.com/kall1shnik0vv/zapret-desacratio.git
cd zapret-desacratio
chmod +x installer.sh
sudo ./installer.sh
```

## 🎮 Использование

После установки просто введи в терминале:

```bash
zapret
```

Или с sudo (нужны права для управления сервисом):

```bash
sudo zapret
```

### Главное меню

```
┌────────────────── ГЛАВНОЕ МЕНЮ ──────────────────┐
                                                    │
  1)  Запустить / Остановить / Перезапустить        │
  2)  Статус сервиса                                │
  3)  Выбрать стратегию                             │
  4)  Создать кастомную стратегию                   │
  5)  Редактировать текущую стратегию               │
  6)  Управление списками доменов                   │
  7)  Проверить доступ к домену                     │
  8)  Сменить тему оформления                       │
  9)  Просмотреть логи                              │
  10) Обновить стратегии и списки                   │
  11) Настройки                                     │
  12) Удалить zapret                                │
  13) Выход                                         │
                                                    │
└──────────────────────────────────────────────────┘
```

## 📂 Структура

```
/opt/zapret/
├── bin/                    # Бинарные файлы zapret
│   ├── nfqws              # NFQUEUE обработчик
│   ├── tpws               # Transparent proxy
│   ├── ip2net             # IP range converter
│   └── mdig               # DNS dig tool
├── lib/                    # Библиотеки TUI
│   ├── common.sh          # Общие функции и цвета
│   ├── config.sh          # Управление конфигом
│   ├── detect.sh          # Детект дистрибутива
│   ├── install.sh         # Установка/удаление
│   ├── lists.sh           # Управление списками
│   ├── service.sh         # Управление сервисом
│   ├── strategies.sh      # Управление стратегиями
│   └── themes.sh          # Смена темы
├── strategies/             # Конфиги стратегий
├── lists/                  # Списки доменов
├── themes/                 # Файлы тем
└── config/                 # Конфигурация

/etc/zapret/
└── config.sh               # Основной конфиг

/usr/bin/zapret             # TUI панель управления
```

## 🎨 Темы оформления

| Тема | Цвет рамки | Акцент | Настроение |
|------|-----------|--------|-----------|
| **Nord** | `#81a1c1` | `#88c0d0` | ❄️ Спокойная |
| **Catppuccin** | `#b4befe` | `#cba6f7` | 🌸 Тёплая |
| **Dark Red** | `#ef4444` | `#dc2626` | 🔥 Агрессивная |

## 📋 Стратегии обхода

| Стратегия | Описание | Метод |
|-----------|----------|-------|
| **default** | Универсальная для большинства случаев | fake |
| **discord** | Оптимизирована для Discord | fake + any-protocol |
| **youtube** | Для YouTube без буферизации | fake + ttl=7 |
| **general** | Агрессивный режим | fake + badseq |
| **custom** | Твоя собственная настройка | любой |

## 🤝 Поддержка дистрибутивов

- ✅ Arch Linux (и производные: CachyOS, Manjaro, Endeavour, Garuda)
- ✅ Debian / Ubuntu / Mint
- ✅ Fedora / Nobara
- ✅ RHEL / CentOS / Rocky / Alma
- ✅ OpenSUSE
- ✅ Gentoo
- ✅ Alpine Linux
- ✅ Void Linux
- ✅ Alt Linux
- ⬜ Windows (планируется)

## 🛠 Разработка

```bash
git clone https://github.com/kall1shnik0vv/zapret-desacratio.git
cd zapret-desacratio

# Режим разработки — скрипт сам найдёт библиотеки в ./src/lib/
chmod +x src/zapret
./src/zapret
```

## ⚖️ Лицензия

GNU General Public License v3.0 — см. [LICENSE](LICENSE).

## 🙏 Благодарности

- [bol-van/zapret](https://github.com/bol-van/zapret) — основа проекта
- [Snowy-Fluffy/zapret.installer](https://github.com/Snowy-Fluffy/zapret.installer) — вдохновение
- [Nord Theme](https://www.nordtheme.com/) — цветовая палитра
- [Catppuccin](https://github.com/catppuccin) — альтернативная палитра
