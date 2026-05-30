# RALPH-промпт: macOS Voice-to-Agent Prompt App

## Название проекта

Рабочее название: **VoiceDock**  
Суть: маленькое macOS-приложение в стиле Wispr Flow / Superwhisper, которое висит поверх/снизу экрана, включается по hotkey/Fn, слушает микрофон, распознаёт речь через OpenAI STT, optionally полирует текст под coding-agent prompt и вставляет результат в активное поле через clipboard + Cmd+V.

---

## Роль агента

Ты senior macOS engineer + product-minded fullstack/devtools engineer.  
Твоя задача — разработать MVP macOS-приложения для голосового ввода промптов в Claude Code, Codex CLI, терминал, браузерные чаты и IDE.

Ты работаешь итеративно, по версиям `0.0.x`.  
После каждой версии ты обязан остановиться, кратко объяснить что сделано, как запустить, как проверить, какие ограничения остались, и дождаться ручной проверки пользователя.

---

## Общие принципы

1. Не пытайся сразу сделать “клон Wispr Flow”.
2. Сначала делай минимальный end-to-end путь:
   `hotkey -> mic recording -> OpenAI transcription -> paste into focused app`.
3. Важнее измеримая задержка, стабильность вставки и простота UX, чем красота UI.
4. Все чувствительные данные храни безопасно:
   - OpenAI API key — только в macOS Keychain.
   - Не логируй аудио и полные тексты по умолчанию.
   - Логи должны быть локальными и отключаемыми.
5. Сразу проектируй архитектуру с провайдерами:
   - `OpenAIFileTranscriber`
   - `OpenAIRealtimeTranscriber` как экспериментальная ветка
   - `AppleSpeechTranscriber` как future provider
   - `LocalWhisperTranscriber` как future provider
6. Не используй Electron.
7. Предпочтительный стек:
   - Swift
   - SwiftUI
   - AppKit where needed
   - AVFoundation для записи
   - KeyboardShortcuts или нативный Carbon/EventTap подход для hotkey
   - Keychain Services для секретов
8. Приложение должно быть menu bar app + lightweight floating HUD.
9. Режим Fn как единственный hotkey может быть проблемным: сначала реализуй конфигурируемый hotkey, например `Option+Space`, `Control+Space`, `Fn+Space` или другой доступный вариант. Отдельно исследуй, можно ли надёжно использовать чистый Fn/Globe.
10. Вставку делай сначала через clipboard:
    - сохранить текущий clipboard
    - положить распознанный текст
    - сымитировать Cmd+V
    - через короткую задержку восстановить clipboard
11. Не вставляй потенциально опасные shell-команды напрямую в command mode без preview/confirmation.

---

## Целевой UX

Пользователь видит маленький floating HUD внизу экрана или menu bar icon.

Основной сценарий:

1. Пользователь ставит курсор в Claude Code / terminal / browser textarea / Cursor.
2. Зажимает hotkey.
3. HUD показывает состояние `Listening...`.
4. Пользователь говорит задачу.
5. Отпускает hotkey.
6. HUD показывает `Transcribing...`.
7. Текст вставляется в активное поле.
8. HUD кратко показывает `Pasted`.

Варианты режимов:

- `Raw Dictation` — только распознавание, без LLM-полировки.
- `Agent Prompt` — распознавание + приведение к аккуратному промпту для coding agent.
- `RALPH Prompt` — распознавание + структурирование в RALPH-задачу.
- `Terminal Command` — распознавание + превращение в shell-команду, но только через preview и safety-check.
- `Fix Last` — future: исправить последний вставленный текст.

---

## Архитектура

Ожидаемая структура проекта:

```text
VoiceDock/
  VoiceDockApp.swift
  AppDelegate.swift
  Core/
    Audio/
      AudioRecorder.swift
      AudioSessionState.swift
      AudioFileWriter.swift
    Hotkeys/
      HotkeyManager.swift
      HotkeyEvent.swift
    Transcription/
      Transcriber.swift
      TranscriptionResult.swift
      OpenAIFileTranscriber.swift
      OpenAIRealtimeTranscriber.swift
    PostProcessing/
      PromptMode.swift
      PromptPostProcessor.swift
      SafetyClassifier.swift
    Paste/
      PasteService.swift
      ClipboardBackup.swift
      KeyboardEventSender.swift
    Settings/
      AppSettings.swift
      KeychainStore.swift
      PermissionsManager.swift
    HUD/
      FloatingHUDController.swift
      FloatingHUDView.swift
    Logging/
      LocalLogger.swift
  UI/
    SettingsView.swift
    OnboardingView.swift
    PromptModePicker.swift
  Tests/
    ...
```

Ключевые интерфейсы:

```swift
protocol Transcriber {
    func transcribe(audioURL: URL, context: TranscriptionContext) async throws -> TranscriptionResult
}

struct TranscriptionResult {
    let text: String
    let durationMs: Int
    let model: String
    let isPartial: Bool
}

enum PromptMode: String, Codable {
    case rawDictation
    case agentPrompt
    case ralphPrompt
    case terminalCommand
}

protocol PasteService {
    func pasteText(_ text: String) async throws
}
```

---

## Метрики, которые нужно логировать локально

Для каждой диктовки:

```text
recording_duration_ms
audio_file_size_bytes
transcription_duration_ms
postprocess_duration_ms
paste_duration_ms
total_release_to_visible_ms
model
prompt_mode
success/failure
error_type
```

Важно: по умолчанию НЕ логировать полный текст и НЕ сохранять аудио.  
Добавить dev setting: `Enable debug text logs`.

---

## Версии и фазы разработки

# 0.0.1 — Project skeleton + menu bar app

## Цель

Создать минимальное macOS SwiftUI menu bar приложение с настройками и заглушкой HUD.

## Задачи

- Создать новый macOS Swift/SwiftUI проект.
- Настроить menu bar app.
- Добавить окно Settings.
- Добавить floating HUD снизу экрана:
  - hidden
  - listening
  - transcribing
  - pasted
  - error
- Добавить простую модель настроек:
  - selected hotkey placeholder
  - selected prompt mode
  - selected OpenAI STT model
- Добавить README с запуском проекта.

## Acceptance criteria

- Приложение запускается.
- Видна иконка в menu bar.
- Можно открыть Settings.
- Можно вручную переключить HUD states в dev/debug UI.
- Нет микрофона, нет hotkey, нет OpenAI.

## Stop point

Остановись после 0.0.1.  
Попроси пользователя вручную проверить:

```text
1. Приложение запускается?
2. Иконка в menu bar видна?
3. Settings открываются?
4. HUD появляется снизу и не мешает другим окнам?
5. UI не выглядит мерзко?
```

---

# 0.0.2 — OpenAI API key + Keychain + file transcription smoke test

## Цель

Добавить хранение OpenAI API key и проверить, что можно отправить заранее выбранный audio file в OpenAI transcription API.

## Задачи

- Добавить ввод OpenAI API key в Settings.
- Сохранять ключ только в Keychain.
- Не хранить ключ в UserDefaults.
- Добавить кнопку `Test OpenAI`.
- Добавить кнопку `Transcribe Sample Audio`.
- Реализовать `OpenAIFileTranscriber`.
- Поддержать модели:
  - `gpt-4o-mini-transcribe` как default
  - `gpt-4o-transcribe`
  - `whisper-1` как fallback
- Для MVP использовать `/v1/audio/transcriptions`.
- Response format: `text` или `json`, выбрать самый простой стабильный вариант.
- Добавить обработку ошибок:
  - missing API key
  - invalid API key
  - network error
  - unsupported audio
  - rate limit
  - empty transcript

## Acceptance criteria

- API key сохраняется и переживает перезапуск приложения.
- Кнопка test показывает успех/ошибку.
- Можно выбрать sample audio file и получить текст.
- Ошибки показываются понятно.

## Stop point

Остановись после 0.0.2.  
Попроси пользователя проверить:

```text
1. Ключ сохраняется?
2. После перезапуска ключ на месте?
3. Тест OpenAI проходит?
4. Sample audio распознаётся?
5. Ошибки нормальные, а не stack trace?
```

---

# 0.0.3 — Microphone recording

## Цель

Научиться записывать аудио с микрофона в локальный temp file.

## Задачи

- Запросить microphone permission.
- Реализовать `AudioRecorder`.
- Запись начинается/останавливается кнопками в Settings или debug panel:
  - Start recording
  - Stop recording
  - Play last recording
  - Transcribe last recording
- Формат аудио:
  - WAV или M4A
  - выбрать формат, который OpenAI принимает стабильно.
- Файлы хранить в temp directory.
- После успешной transcription удалять temp audio по умолчанию.
- Добавить setting `Keep last audio for debugging`.

## Acceptance criteria

- macOS спрашивает microphone permission.
- Запись стартует и останавливается.
- Можно воспроизвести последний audio.
- Можно отправить его в OpenAI и получить текст.
- Temp files чистятся.

## Stop point

Остановись после 0.0.3.  
Попроси пользователя проверить:

```text
1. macOS permission запрошен корректно?
2. Микрофон пишет?
3. Звук воспроизводится?
4. OpenAI распознаёт запись?
5. После нескольких записей temp не засирается?
```

---

# 0.0.4 — Hotkey hold-to-record

## Цель

Сделать основной UX: зажал hotkey — запись началась, отпустил — запись остановилась и ушла на распознавание.

## Задачи

- Реализовать `HotkeyManager`.
- Начать с конфигурируемого хоткея, не упираться в чистый Fn.
- Поддержать минимум:
  - press starts recording
  - release stops recording
- Добавить HUD states:
  - `Listening...`
  - `Transcribing...`
  - `Error`
- Защититься от повторного старта записи, если запись уже идёт.
- Добавить timeout максимальной записи, например 120 секунд.
- Добавить minimum recording duration, например 300 ms.
- Добавить cancel gesture/key later, если удобно.

## Acceptance criteria

- Hotkey работает из разных приложений.
- Recording начинается по press.
- Recording заканчивается по release.
- После release запускается transcription.
- HUD отражает state.
- Приложение не падает при быстром tap/tap/tap.

## Stop point

Остановись после 0.0.4.  
Попроси пользователя проверить в:

```text
1. TextEdit
2. Terminal.app или iTerm
3. Browser textarea
4. VS Code/Cursor
5. Claude Code/Codex input
```

---

# 0.0.5 — Paste into active app

## Цель

После распознавания вставлять текст туда, где сейчас курсор.

## Задачи

- Реализовать `ClipboardBackup`.
- Реализовать `PasteService`:
  - сохранить текущий clipboard
  - положить generated text
  - отправить Cmd+V
  - подождать 300–1000 ms
  - восстановить clipboard
- Запросить Accessibility permission, если нужен synthetic key event.
- Добавить onboarding screen для permissions:
  - Microphone
  - Accessibility
  - optional Input Monitoring, если понадобится
- Добавить настройку:
  - `Paste automatically`
  - `Copy only`
- Если paste failed — оставить текст в clipboard и показать `Copied, paste manually`.

## Acceptance criteria

- Вставка работает в TextEdit.
- Вставка работает в браузерном textarea.
- Вставка работает в terminal/Claude Code input.
- Clipboard пользователя восстанавливается.
- Если Accessibility permission не выдан, приложение понятно объясняет что делать.

## Stop point

Остановись после 0.0.5.  
Попроси пользователя проверить:

```text
1. Был ли восстановлен старый clipboard?
2. Вставилось ли в iTerm?
3. Вставилось ли в Claude Code?
4. Не вставилось ли дважды?
5. Что происходит при отсутствии Accessibility permission?
```

---

# 0.0.6 — Prompt modes + LLM post-processing

## Цель

Добавить режимы обработки текста после STT.

## Задачи

- Реализовать `PromptPostProcessor`.
- Поддержать режимы:
  - Raw Dictation
  - Agent Prompt
  - RALPH Prompt
  - Terminal Command
- Для post-processing использовать OpenAI text model через Responses API или Chat Completions, выбрать самый простой стабильный путь.
- Настройки:
  - enable/disable post-processing
  - model for post-processing
  - temperature 0
  - max output length
- Не полировать текст в Raw Dictation.
- Сохранять технические термины, пути, команды, URL, имена файлов.
- Для RALPH Prompt output должен быть markdown.
- Для Agent Prompt output должен быть compact task brief.
- Для Terminal Command output должен идти в preview, а не auto-paste.

## Agent Prompt system instruction

```text
Ты преобразуешь сырую расшифровку голоса в чёткий промпт для coding agent.
Пиши на русском.
Не выдумывай факты.
Сохраняй технические термины, имена файлов, пути, команды, URL и версии.
Убирай оговорки и мусор.
Структурируй только если это помогает.
Не превращай текст в email.
```

## RALPH Prompt system instruction

```text
Ты преобразуешь сырую расшифровку голоса в RALPH-промпт для coding agent.
Пиши на русском.
Структура:
- Роль
- Цель
- Контекст
- Ограничения
- Фазы
- Acceptance criteria
- Stop points для ручной проверки
Не выдумывай неизвестные детали.
Если пользователь говорит грубо или хаотично, сохрани смысл, но сделай задачу исполнимой.
```

## Terminal Command safety instruction

```text
Ты преобразуешь речь в shell-команду или короткий набор команд.
Если команда может удалить данные, изменить систему, снести контейнеры/volumes, отправить секреты, поменять remote state или выполнить network/destructive action — не выдавай команду для автопаста.
Вместо этого верни:
RISKY_COMMAND_PREVIEW
<команда>
<почему рискованно>
```

## Acceptance criteria

- Raw Dictation быстро вставляет обычный transcript.
- Agent Prompt делает аккуратный task prompt.
- RALPH Prompt делает markdown-структуру.
- Terminal Command не вставляет опасные команды напрямую.
- Можно переключать режимы из HUD/menu.

## Stop point

Остановись после 0.0.6.  
Попроси пользователя надиктовать 5 реальных задач:

```text
1. Хаотичная задача для Claude Code
2. Задача с путями/файлами
3. Задача с shell-командами
4. RALPH-промпт
5. Смешанный ru/en/code текст
```

---

# 0.0.7 — Latency instrumentation + UX polish

## Цель

Сделать приложение не просто рабочим, а измеримо удобным.

## Задачи

- Добавить latency metrics:
  - hotkey_down_to_recording_started
  - hotkey_up_to_audio_finalized
  - transcription_duration
  - postprocess_duration
  - paste_duration
  - total_release_to_paste
- Показывать в debug panel последние N сессий.
- Добавить понятные статусы HUD.
- Добавить sound/haptic-like feedback optional:
  - start
  - stop
  - pasted
  - error
- Добавить cancel during recording.
- Добавить retry transcription.
- Добавить copy last result.
- Добавить paste last result.
- Добавить setting `Prefer speed over quality`:
  - true: `gpt-4o-mini-transcribe`, no post-processing
  - false: selected model + post-processing

## Acceptance criteria

- Видно, где теряется время.
- Можно понять, почему “медленно”.
- Приложение не раздражает при 20 диктовках подряд.
- Есть retry/copy-last fallback.

## Stop point

Остановись после 0.0.7.  
Попроси пользователя сделать latency-тест:

```text
10 коротких диктовок
5 длинных диктовок
5 Agent Prompt диктовок
5 RALPH Prompt диктовок
```

Выведи таблицу min/avg/max для total_release_to_paste.

---

# 0.0.8 — Experimental streaming transcription

## Цель

Попробовать потоковое распознавание, но не ломать стабильный file-based path.

## Важное решение

Streaming — экспериментальная ветка.  
Не удаляй file transcription path.  
В settings должен быть переключатель:

```text
Transcription mode:
- File upload after release
- Streaming completed recording
- Realtime microphone streaming experimental
```

## Задачи

- Исследовать OpenAI Realtime transcription актуальную документацию.
- Добавить `OpenAIRealtimeTranscriber`.
- Поток аудио должен начинаться при hotkey down.
- Partial transcript должен обновлять HUD/preview.
- При hotkey up финализировать session и вставить final transcript.
- Если streaming падает — fallback to file transcription.
- Добавить explicit logging для streaming errors.
- Не делать LLM post-processing на partial transcript.
- Post-processing только после final transcript.

## Acceptance criteria

- Streaming mode можно включить/выключить.
- При включённом streaming есть partial text.
- При release вставляется final text.
- При ошибке streaming fallback работает.
- File mode не сломан.

## Stop point

Остановись после 0.0.8.  
Попроси пользователя сравнить:

```text
1. File upload mode latency
2. Streaming completed recording latency
3. Realtime microphone streaming latency
4. Accuracy на русском
5. Accuracy на ru/en/code
```

---

# 0.0.9 — Floating HUD like Wispr Flow

## Цель

Сделать приятный floating UI “внизу экрана”.

## Задачи

- HUD должен быть маленьким и аккуратным.
- Позиция:
  - bottom center default
  - draggable
  - remember position
- Состояния:
  - idle hidden
  - listening waveform/pulse
  - transcribing spinner
  - preview text
  - error
- Добавить quick mode switch:
  - Raw
  - Agent
  - RALPH
  - Command
- Добавить preview для длинных результатов.
- Добавить кнопки:
  - Paste
  - Copy
  - Retry
  - Cancel
- HUD не должен перехватывать фокус без необходимости.
- HUD не должен ломать активное приложение.

## Acceptance criteria

- HUD выглядит как отдельный компактный voice input overlay.
- Не мешает печатать.
- Не перекрывает критичные элементы.
- Можно выбрать mode без Settings.
- Можно отменить результат.

## Stop point

Остановись после 0.0.9.  
Попроси пользователя проверить UX на реальном рабочем цикле 30 минут.

---

# 0.0.10 — Packaging, permissions onboarding, first distributable build

## Цель

Собрать первый распространяемый билд.

## Задачи

- Настроить app icon placeholder.
- Настроить signing для local build.
- Сформировать `.app`.
- Добавить first-run onboarding:
  - Microphone permission
  - Accessibility permission
  - OpenAI API key
  - Hotkey setup
  - Test recording
  - Test paste
- Добавить README:
  - install
  - permissions
  - troubleshooting
  - known limitations
- Добавить crash-safe behavior:
  - если приложение упало, clipboard не должен остаться сломанным по возможности
  - temp files clean on launch
- Добавить `Reset app settings`.

## Acceptance criteria

- `.app` можно запустить вне Xcode.
- First-run setup понятен.
- Можно удалить API key.
- Можно сбросить настройки.
- Пользователь понимает, почему нужны permissions.

## Stop point

Остановись после 0.0.10.  
Попроси пользователя установить приложение как обычную macOS app и пройти onboarding с нуля.

---

## Технические запреты

Не делай:

- Electron.
- Backend server как обязательную часть MVP.
- Аккаунты пользователей.
- Облачное хранение истории.
- Автообновления.
- Сложную биллинговую систему.
- Локальный Whisper в первых версиях.
- Сложную интеграцию с Claude Code API.
- Прямое изменение текста через Accessibility API до тех пор, пока clipboard paste работает.
- Автоматическую вставку рискованных shell-команд.

---

## Технические допущения

Можно:

- Использовать Swift Package Manager.
- Использовать маленькие open-source helper packages для hotkeys/menubar, если они живые и не тащат огромный стек.
- Использовать clipboard-based paste.
- Использовать OpenAI `/v1/audio/transcriptions` для file mode.
- Использовать OpenAI realtime transcription только после стабильного MVP.
- Использовать `gpt-4o-mini-transcribe` как default speed/cost option.
- Использовать `gpt-4o-transcribe` как quality option.
- Использовать обычную text model для prompt post-processing.

---

## Минимальный тестовый набор

После каждой версии обновляй `TEST_PLAN.md`.

Кейсы:

```text
TextEdit:
- короткий русский текст
- длинный русский текст
- mixed ru/en

Browser:
- textarea
- ChatGPT/Claude input

Terminal/iTerm:
- обычный текст
- многострочный prompt
- shell command preview

Cursor/VS Code:
- input panel
- markdown prompt

Claude Code/Codex CLI:
- однострочная задача
- многострочный RALPH prompt
- задача с файлами и путями
```

---

## Definition of Done для всего MVP

MVP считается готовым, когда:

1. Приложение запускается как macOS menu bar app.
2. Можно задать OpenAI API key.
3. Можно выбрать hotkey.
4. Можно зажать hotkey и надиктовать текст.
5. После отпускания hotkey текст распознаётся.
6. Результат вставляется в активное приложение.
7. Clipboard восстанавливается.
8. Есть Raw Dictation и Agent Prompt mode.
9. Есть RALPH Prompt mode.
10. Есть basic safety для Terminal Command mode.
11. Есть latency logs.
12. Есть понятный onboarding permissions.
13. Есть fallback `copy only`, если paste не сработал.
14. Приложение не хранит аудио/тексты без явного debug setting.
15. После каждой версии есть ручная проверка пользователем.

---

## Начни работу

Начни с версии `0.0.1`.

Перед кодом выведи короткий план:

```text
Version: 0.0.1
Goal:
Files to create/change:
How to run:
How I will stop:
```

Затем реализуй только `0.0.1`.

После реализации остановись и не переходи к `0.0.2`, пока пользователь не проверит и не разрешит продолжать.
