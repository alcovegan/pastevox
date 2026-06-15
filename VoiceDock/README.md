# PasteVox

PasteVox — macOS menu bar app для голосового ввода промптов в coding agents.

## Version 0.0.9

Текущий стабильный MVP-flow:

```text
Fn/Globe, Right Option or Right Command hold → microphone recording → OpenAI STT → optional post-processing → paste/copy
```

## Что работает

- App запускается как tray/menu bar приложение.
- Settings не открываются на старте, только через menu bar.
- Menu bar icon — компактная waveform template icon.
- Hold-to-record работает через Fn/Globe, Right Option или Right Command.
- OpenAI API key хранится в macOS Keychain.
- File upload transcription — recommended/default path.
- Prompt modes:
  - Raw Dictation
  - Agent Prompt
  - RALPH Prompt
  - Terminal Command
- Paste через clipboard + Cmd+V.
- Clipboard восстанавливается после paste.
- Risky terminal commands не auto-paste'ятся и показываются как shell-comment preview.
- Copy/Paste Last Result доступны из menu bar и Settings.
- Latency metrics доступны в Settings.
- HUD снизу:
  - idle collapsed bar
  - Listening с waveform
  - Transcribing/Pasted/Error compact status
  - Pasted/Error auto-collapse обратно в idle

## Transcription modes

### Recommended

`File upload after release`

Самый стабильный режим и лучшее качество русского в текущих тестах.

### Experimental

`Streaming completed recording`

Работает, но стабильного выигрыша по latency не показал.

`Realtime microphone streaming experimental`

GA websocket технически подключён и transcript events приходят, но качество русского/lifecycle хуже file upload. Оставлен strictly experimental с fallback.

## Speed preset

`Prefer speed over quality` использует:

- `File upload after release`
- `gpt-4o-mini-transcribe`
- post-processing off

## Запуск для разработки

```bash
cd VoiceDock
swift run PasteVox
```

После запуска ищи waveform icon в menu bar. Settings: click icon → `Settings`.

## Проверка

1. Сохрани OpenAI API key в Settings → OpenAI.
2. Проверь permissions в Settings → Permissions.
3. Поставь курсор в TextEdit/iTerm/Sublime/browser.
4. Зажми Fn/Globe, скажи фразу, отпусти.
5. Текст должен вставиться в активное поле.
6. Старый clipboard должен восстановиться.
7. Settings → Metrics показывает latency.

## Ограничения 0.0.9

- Запуск через `swift run` не является полноценным `.app`; Dock icon будет нормально решаться в packaging.
- Accessibility prompt через dev-run может вести себя неидеально.
- Realtime mode experimental и не рекомендуется для everyday use.
- HUD пока bottom-center fixed, без draggable position.

## 0.0.10 packaging groundwork

### Build `.app`

```bash
cd VoiceDock
./scripts/build-app.sh
open dist/PasteVox.app
```

The script creates an ad-hoc signed local app bundle with generated `AppIcon.icns` at:

```text
VoiceDock/dist/PasteVox.app
```

### Install to Applications

```bash
cd VoiceDock
./scripts/build-app.sh
./scripts/install-app.sh
open /Applications/PasteVox.app
```

Installing to `/Applications/PasteVox.app` gives macOS Accessibility permissions a more stable app path than `dist/PasteVox.app`.

### Hold key quick switches

While holding Fn/Globe or the selected hold key, press:

- `1` → Raw Dictation
- `2` → Agent Prompt
- `3` → RALPH Prompt
- `4` → Terminal Command
- `5…0` / `-` → Writing style
- `` ` `` → pause/resume hold-to-record

HUD shows the selected mode/style and collapses automatically. Mode/style switching during hold cancels the temporary recording instead of transcribing it.

## Landing page

Landing page source lives in `landing/` and is built with Astro. It has English and Russian static routes:

```bash
cd VoiceDock/landing
npm install
npm run dev
npm run build
npm run validate:i18n
```

Routes:

- `/` — English
- `/ru/` — Russian
- `/es/` — Spanish
- `/fr/` — French
- `/de/` — German

## 0.0.10 status

Done:

- local `.app` bundle script
- ad-hoc signing
- generated Dock/app `.icns`
- Fn+1/2/3/4 quick mode switch
- reset app settings button
- separate Home window with History, Dictionary, Snippets and Scratchpad
- snippet search, JSON import/export and record-test preview
- optional app-aware mode switching
- install script for `/Applications/PasteVox.app`

Still TODO:

- first-run onboarding
- permissions onboarding
- troubleshooting docs
