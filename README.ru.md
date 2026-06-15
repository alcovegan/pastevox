# PasteVox

**Скажи. Вставь. Продолжай.** Нативная macOS-утилита в строке меню, которая превращает твой голос
в диктовку, промпты для кодинг-агентов, терминальные команды, сниппеты и заметки — и вставляет это
прямо в приложение, где ты уже работаешь.

🌐 **[pastevox.app](https://pastevox.app)** · 🇬🇧 **[English version](README.md)**

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-SwiftUI%20%2B%20AppKit-orange?logo=swift)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

PasteVox живёт в строке меню macOS. Зажми клавишу, скажи текст — и он вставится в активное
приложение через буфер обмена. Сделано на Swift, SwiftUI и AppKit, без Electron.

## Возможности

- **Зажми и говори** на Fn/Globe, правом Option или правом Command
- **Распознавание речи OpenAI**; ключ хранится в macOS Keychain
- **Режимы** (Fn+1…4): Raw Dictation · Agent Prompt · RALPH Prompt · Terminal Command
- **Стили письма** для режимов с постобработкой (Fn+5…0, Fn+-)
- **Защитный барьер** — рискованные терминальные команды показываются закомментированным
  предпросмотром, а не вставляются вслепую
- **Рабочее пространство Home**: История, Сниппеты, Словарь, Черновик
- **Локальные сниппеты** (без обращения к модели), импорт/экспорт через JSON
- **Интерфейс на EN и RU** (Настройки → Поведение → Язык; по умолчанию — как в системе)
- Метрики задержки, HUD-обратная связь, восстановление буфера обмена после вставки

## Как это работает

```text
зажми клавишу → запись → OpenAI STT → опц. переписывание → вставка / копирование
```

## Установка

### Скачать (рекомендуется)

Возьми последнюю сборку в
**[Releases](https://github.com/alcovegan/pastevox/releases/latest)**, распакуй и перенеси
**`PasteVox.app`** в `/Applications`.

Приложение подписано ad-hoc (пока без нотаризации), поэтому при первом запуске macOS предупредит.
Открой через правый клик → **Open**, либо сними карантинный флаг:

```bash
xattr -dr com.apple.quarantine /Applications/PasteVox.app
```

Затем выдай **Микрофон** и **Универсальный доступ** в Системных настройках → Конфиденциальность и
безопасность.

### Сборка из исходников

Нужны macOS 13+ и тулчейн Swift.

```bash
git clone https://github.com/alcovegan/pastevox.git
cd pastevox
swift run PasteVox            # быстрый dev-запуск
# …или собранный .app:
./scripts/build-app.sh        # → dist/PasteVox.app
./scripts/install-app.sh      # → /Applications/PasteVox.app
```

## Горячие клавиши (пока зажата клавиша записи)

- `1…4` — режим (Raw / Agent / RALPH / Command)
- `5…0`, `-` — стиль письма
- `` ` `` — пауза / возобновление режима удержания

HUD показывает выбранный режим/стиль; переключение во время удержания отменяет эту запись, а не
транскрибирует её.

## Приватность

Ключ OpenAI остаётся в Keychain. Сниппеты сопоставляются локально (без вызова модели). Аудио
отправляется в OpenAI только когда ты записываешь. История остаётся на твоём Mac. Подробнее —
на **[pastevox.app](https://pastevox.app)**.

## Локализация

В приложении есть EN (база) и RU; ES/FR/DE дополнительно живут на лендинге. Язык приложения
меняется в Настройки → Поведение → Язык. Детали: [`docs/app-i18n.md`](docs/app-i18n.md).

## Разработка

- **Приложение** — Swift Package Manager. Сборка: `swift build`. Тесты: `swift test`. Исходники в
  `Sources/PasteVox/`.
- **Лендинг** — Astro в [`landing/`](landing/): `npm run dev` / `npm run build` /
  `npm run validate:i18n`. Деплой на Cloudflare Pages.

## Лицензия

[MIT](LICENSE) © Alexander Sharabarov
