# PasteVox Test Plan

## 0.0.9 — HUD + menu bar polish

### Launch/menu bar

- [ ] App starts without opening Settings automatically
- [ ] Menu bar waveform icon is visible and sized consistently with nearby icons
- [ ] Menu bar opens product menu
- [ ] `Settings` opens Settings
- [ ] Mode submenu switches prompt mode and checkmark updates
- [ ] `Copy Last Result` works
- [ ] `Paste Last Result` works

### HUD

- [ ] Idle HUD is visible as a small collapsed bar above Dock
- [ ] HUD does not jump vertically between states
- [ ] Listening HUD expands and shows waveform
- [ ] Transcribing HUD is readable and compact
- [ ] Pasted HUD is readable and auto-collapses
- [ ] Error HUD is readable and auto-collapses
- [ ] HUD does not steal focus/clicks

### Stable dictation flow

- [ ] File upload after release is default/recommended
- [ ] Fn/Globe press starts recording
- [ ] Fn/Globe release stops recording and starts transcription
- [ ] Raw Dictation pastes transcript
- [ ] Clipboard restores after paste
- [ ] Metrics row appears after dictation

### Prompt modes

- [ ] Raw Dictation works
- [ ] Agent Prompt works
- [ ] RALPH Prompt works
- [ ] Terminal Command safe command works
- [ ] Terminal Command risky command does not auto-paste
- [ ] Risky preview is shell-commented

### Experimental transcription modes

- [ ] Streaming completed recording works or falls back safely
- [ ] Realtime microphone streaming works or falls back safely
- [ ] Effective mode in Metrics reflects fallback correctly
- [ ] Realtime remains marked experimental/unstable in UI

## Previous accepted checks

- [x] 0.0.8 streaming research completed; file upload remains recommended
- [x] 0.0.7.1 Copy/Paste Last Result works
- [x] 0.0.7 Dock/Alt-Tab and metrics work
- [x] 0.0.6 Prompt modes work
- [x] 0.0.5 Paste works
- [x] 0.0.4 Fn/Globe hotkey works
- [x] 0.0.3 Microphone recording works
- [x] 0.0.2 OpenAI/Keychain works
- [x] 0.0.1 Skeleton works

## 0.0.10 — packaging groundwork + Fn mode switch

- [x] Build `.app` via `./scripts/build-app.sh`
- [x] Local ad-hoc signing
- [ ] Launch `dist/PasteVox.app` manually
- [ ] Dock icon polish for packaged app
- [ ] Fn+1 switches to Raw Dictation and shows HUD feedback
- [ ] Fn+2 switches to Agent Prompt and shows HUD feedback
- [ ] Fn+3 switches to RALPH Prompt and shows HUD feedback
- [ ] Fn+4 switches to Terminal Command and shows HUD feedback
- [ ] Mode switch during Fn hold does not transcribe accidental short recording
- [ ] first-run onboarding
- [ ] permissions onboarding
- [ ] reset settings
- [ ] install/troubleshooting docs
