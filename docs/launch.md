# PasteVox — launch notes

Ready-to-post copy for a small, honest launch. **Post manually from your own account** — do **not**
automate posting to HN / Reddit / Product Hunt (they forbid bot self-promo; it gets banned and reads
as spam). The only legit "automation" here is GitHub's auto-generated release notes.

## Before you post

- [ ] **Attach `pastevox.app`** to the Cloudflare Pages project (otherwise links 404 — until then use
      `pastevox.pages.dev` or the GitHub repo).
- [ ] Sanity-check the latest release downloads and launches on a clean Mac (right-click → Open).
- [ ] Decide channels and **space them out** (don't blast all at once); reply to comments yourself.
- [ ] Optional: a short screen-recording / GIF helps a lot on PH and Reddit.

## Channels (highest leverage first)

- **Show HN** (Hacker News) — best fit for a dev tool. Post as `Show HN: …`, be present in comments.
- **r/macapps** (and maybe r/swift, r/SideProject) — read each sub's self-promo rules first.
- **Product Hunt** — one shot; prep tagline + description + a first comment + media.
- **X/Twitter** — short post, link to the site.

## Drafts

### Show HN

> **Show HN: PasteVox – voice → dictation & coding-agent prompts in the macOS menu bar**
>
> I built a small native macOS menu-bar app (Swift/SwiftUI, no Electron). Hold Fn/Globe (or Right
> Option/Command), speak, and the text lands in the frontmost app. Beyond raw dictation it can shape
> speech into a coding-agent task, a RALPH prompt, or a terminal command — with a safety gate that
> comments out risky commands instead of blind-pasting. Snippets match locally (no LLM), plus a
> dictionary, history and scratchpad. UI in EN/RU.
>
> Bring your own OpenAI key (stored in Keychain). Open-source (MIT). It's early (v0.1.0) and ad-hoc
> signed — not notarized yet, so first launch needs right-click → Open.
>
> Repo: https://github.com/alcovegan/pastevox · Site: https://pastevox.app

### r/macapps

Title: `PasteVox — voice-to-text + coding-agent prompts in the menu bar (free, open-source, BYO OpenAI key)`

> Native menu-bar app, no Electron. Hold a key → speak → it pastes into whatever app you're in. Modes
> for raw dictation, coding-agent prompts and terminal commands (risky ones are gated). Local
> snippets, dictionary, history, scratchpad. EN/RU. Your OpenAI key stays in Keychain. MIT-licensed.
> Early build, feedback welcome.
>
> https://github.com/alcovegan/pastevox · https://pastevox.app

### Product Hunt

- Tagline: `Speak. Paste. Keep moving — voice for the macOS menu bar`
- Description: PasteVox turns your voice into dictation, coding-agent prompts, terminal commands and
  snippets — pasted straight into the app you're using. Native Swift, open-source, your OpenAI key
  stays in Keychain.

### X / Twitter

> Shipped PasteVox 🎙️ — a native macOS menu-bar app: hold a key, talk, and it pastes into whatever
> you're in. Dictation, coding-agent prompts, terminal commands (with a safety gate), snippets.
> Swift, open-source, BYO OpenAI key. EN/RU.
> → https://pastevox.app

## Honesty notes (keep these in answers)

- Early (v0.1.0), ad-hoc signed (not notarized) — first launch via right-click → Open.
- Needs your own OpenAI API key; audio is sent to OpenAI only while recording.
- Apple Silicon + Intel (universal build).
