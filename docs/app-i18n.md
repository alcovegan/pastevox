# Локализация приложения PasteVox (macOS)

Дата: 2026-06-15. Языки: **EN** (база) + **RU**. Архитектура рассчитана на лёгкое добавление
других языков позже.

## Как это работает

SwiftPM-пакет (`swift build`, без Xcode-проекта). Локализация — рантайм-механизм с
**переключателем языка внутри приложения** (а не только системная локаль), потому что нужно
переопределять язык независимо от системы.

- **Каталоги строк:** `Sources/VoiceDock/Resources/<lang>.lproj/Localizable.strings`
  (`en.lproj`, `ru.lproj`). Подключены в `Package.swift` через `defaultLocalization: "en"` +
  `.process(...)`. Ключ строки — это **сам английский исходный текст** (`"Save Snippet" = "…";`).
- **Хелпер:** `Sources/VoiceDock/Core/Localization/Localization.swift`
  - `func T(_ key: String) -> String` — возвращает перевод для текущего языка; если перевода нет,
    отдаёт английский ключ (fallback). Использовать везде: `Text(T("Save Snippet"))`,
    `NSMenuItem(title: T("Quit PasteVox"), …)`, `String(format: T("Mode: %@"), x)`.
  - `enum L10n` — держит `languageCode` ("en"/"ru") и грузит нужный `.lproj` из `Bundle.module`.
  - `enum AppLanguage { case system, en, ru }` — выбор в Settings; `.system` резолвится в en/ru
    по `Locale.preferredLanguages`.
- **Хранение/переключение:** `AppSettings.appLanguage` (`@Published`, UserDefaults). При смене:
  обновляет `L10n.languageCode` и шлёт `.appLanguageChanged`.
- **Live-переключение без перезапуска:**
  - SwiftUI-окна (`SettingsView`, `HomeView`, `FloatingHUDView`) наблюдают `AppSettings` через
    `@ObservedObject` → перерисовываются, `T()` пересчитывается.
  - Статусное меню (`AppDelegate`) пересобирается по `$appLanguage` (Combine).
- **Переключатель в UI:** Settings → **Поведение/Behavior** → **Язык/Language** (System / English /
  Русский).

## Что переведено, а что оставлено по-английски

Переводится весь описательный UI. **Английскими осознанно оставлены** (как и на лендинге):

- бренд/тех: `PasteVox`, `OpenAI`, `Keychain`, `macOS`, `STT`, `LLM`, `HUD`, `JSON`, имена
  приложений (Cursor/VS Code/Xcode/Terminal/iTerm), `Home` (имя рабочего окна);
- названия режимов (`Raw Dictation`, `Agent Prompt`, `RALPH Prompt`, `Terminal Command`) и стилей
  (`Default…Email`) — продуктовые лейблы;
- хоткей-лейблы (`Fn+1 Raw`, `Fn+1…4` …) и технические debug/метрик-строки.

Такие ключи просто отсутствуют в `ru.lproj` → `T()` отдаёт английский оригинал.
Примечание: `Accessibility` в приложении переведено как **«Универсальный доступ»** — это реальный
русский лейбл macOS (на лендинге оставляли английским; в приложении уместнее термин системы).

## Как добавить новую строку

1. В коде оберни: `Text(T("New label"))` (для интерполяций — `String(format: T("Found %d"), n)`,
   сохраняя спецификаторы `%@`/`%d`).
2. Добавь ключ в `en.lproj` (`"New label" = "New label";`) и перевод в `ru.lproj`.
3. `swift build`.

Извлечь все ключи из исходников: regex `\bT\("(...)"\)` (см. как генерировались каталоги).

## Как добавить новый язык (например, ES)

1. Создай `Sources/VoiceDock/Resources/es.lproj/Localizable.strings`, добавь `.process(...)` в
   `Package.swift`.
2. Добавь `case es` в `AppLanguage` (+ `displayName`, `resolvedCode`).
3. Переведи каталог.

## Проверка

- Юнит-тесты: `Tests/VoiceDockTests/LocalizationTests.swift` — грузят RU из бандла, проверяют
  fallback и целостность format-строк. Запуск: `swift test`.
- Ручная проверка: запустить приложение, Settings → Поведение → Язык → **Русский** — UI, меню и
  HUD переключаются на лету.

## Объём

~290 ключей (UI + меню + HUD + enum-титулы). RU: 269 переведено, 21 оставлено английским
(бренд/тех/хоткеи/метрики). Каталоги: `*.lproj/Localizable.strings`.
