# PasteVox

**Speak. Paste. Keep moving.** A native macOS menu-bar utility that turns your voice into
dictation, coding-agent prompts, terminal commands, snippets, and scratchpad notes — pasted
straight into the app you're already using.

🌐 **[pastevox.app](https://pastevox.app)** · 🇷🇺 **[Русская версия](README.ru.md)**

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-SwiftUI%20%2B%20AppKit-orange?logo=swift)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

PasteVox lives in the macOS menu bar. Hold a key, speak, and the text lands in the frontmost app
via the clipboard. Built with Swift, SwiftUI and AppKit — no Electron.

## Features

- **Hold-to-talk** on Fn/Globe, Right Option or Right Command
- **OpenAI speech-to-text**; the API key is stored in the macOS Keychain
- **Modes** (Fn+1…4): Raw Dictation · Agent Prompt · RALPH Prompt · Terminal Command
- **Writing styles** for post-processed modes (Fn+5…0, Fn+-)
- **Safety gate** — risky terminal commands are shown as a commented preview, never blind-pasted
- **Home workspace**: History, Snippets, Dictionary, Scratchpad
- **Local snippet expansion** (no LLM call), with JSON import/export
- **English & Russian UI** (Settings → Behavior → Language; defaults to system)
- Latency metrics, HUD feedback, and clipboard restore after paste

## How it works

```text
Hold key → record → OpenAI STT → optional rewrite → paste / copy
```

## Install

### Download (recommended)

Grab the latest build from **[Releases](https://github.com/alcovegan/pastevox/releases/latest)**,
unzip, and move **`PasteVox.app`** into `/Applications`.

The app is ad-hoc signed (not yet notarized), so on first launch macOS will warn. Right-click the
app → **Open**, or clear the quarantine flag:

```bash
xattr -dr com.apple.quarantine /Applications/PasteVox.app
```

Then grant **Microphone** and **Accessibility** in System Settings → Privacy & Security.

### Build from source

Requires macOS 13+ and a Swift toolchain.

```bash
git clone https://github.com/alcovegan/pastevox.git
cd pastevox
swift run PasteVox            # quick dev run
# …or a packaged .app:
./scripts/build-app.sh        # → dist/PasteVox.app
./scripts/install-app.sh      # → /Applications/PasteVox.app
```

## Hotkeys (while holding the record key)

- `1…4` — switch mode (Raw / Agent / RALPH / Command)
- `5…0`, `-` — switch writing style
- `` ` `` — pause / resume hold-to-record

The HUD shows the selected mode/style; switching during a hold cancels that recording instead of
transcribing it.

## Privacy

Your OpenAI key stays in the Keychain. Snippets are matched locally (no model call). Audio is sent
to OpenAI only when you record. History stays on your Mac. More on
**[pastevox.app](https://pastevox.app)**.

## Localization

EN (base) and RU ship in the app; ES/FR/DE also exist on the landing page. Change the app language
in Settings → Behavior → Language. Details: [`docs/app-i18n.md`](docs/app-i18n.md).

## Development

- **App** — Swift Package Manager. Build: `swift build`. Test: `swift test`. Sources in
  `Sources/PasteVox/`.
- **Landing** — Astro in [`landing/`](landing/): `npm run dev` / `npm run build` /
  `npm run validate:i18n`. Deployed to Cloudflare Pages.

## License

[MIT](LICENSE) © Alexander Sharabarov
