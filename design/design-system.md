# PasteVox Design System

Draft design direction for the PasteVox macOS app. This is not final; use it as an iteration board while we tune sizes, density and component hierarchy. The goal is a native, calm, polished desktop utility — not a web dashboard and not default macOS Settings UI.

## Principles

1. **Native first**
   - Use SF typography.
   - Respect macOS density and window proportions.
   - Avoid flashy gradients, oversized controls, and web-app spacing.

2. **Home is a workspace**
   - Home is where users recover dictations, manage snippets/dictionary, and write notes.
   - It should feel warm, useful, and lightweight.

3. **Settings is configuration**
   - Settings can be denser and more utilitarian.
   - Debug/admin controls should not pollute Home.

4. **HUD is the product surface**
   - HUD must be readable in one glance.
   - Never wrap text in HUD.
   - Prefer short labels over full names.

5. **One primary action per block**
   - Primary buttons are rare.
   - Secondary/ghost buttons handle utilities.
   - Danger actions are terracotta, not system red.

## Typography

Use SF only.

### Fonts

| Role | Font | Notes |
| --- | --- | --- |
| Page titles | SF Pro Display | Large, clean, native |
| Card/stat titles | SF Pro Display or SF Pro Text | Depends on size |
| Body text | SF Pro Text | Rows, forms, explanations |
| Buttons | SF Pro Text | Semibold/bold, compact |
| Debug/time/latency | SF Mono | Only where monospaced values help |

### Sizes

| Token | Size | Weight | Use |
| --- | ---: | ---: | --- |
| `pageTitle` | 40 | 650–700 | Home page title |
| `sectionTitle` | 11 | 800 | Uppercase card label |
| `cardTitle` | 15 | 700 | Optional card heading |
| `body` | 14 | 500 | Main row text |
| `formBody` | 15 | 500–550 | Inputs and text editors |
| `bodyStrong` | 14 | 650 | Important row labels |
| `caption` | 12 | 500–650 | Metadata, helper text |
| `button` | 12.5–13 | 700 | Regular buttons |
| `tinyButton` | 11 | 700 | Inline row actions |
| `statLarge` | 38 | 650–720 | Dashboard numbers |

### Tracking

- Page titles: `-0.035em` equivalent.
- Body: default or slightly tight.
- Section labels: uppercase with `0.07–0.09em` tracking.

## Palette

Avoid default system blue/red/gray as the main visual language.

| Token | Hex | Use |
| --- | --- | --- |
| `bg` | `#f4f0e8` | App background |
| `surface` | `#fffdf8` | Cards/forms |
| `surface2` | `#f8f4ed` | Sidebar/soft cards |
| `ink` | `#1b1a19` | Primary text/actions |
| `muted` | `#77716a` | Secondary text |
| `faint` | `#aaa39a` | Disabled/placeholder |
| `line` | `rgba(35,31,27,0.10)` | Borders |
| `lineStrong` | `rgba(35,31,27,0.16)` | Input borders |
| `sand` | `#e9dfcf` | Secondary buttons/chips |
| `sandPressed` | `#ded0bb` | Pressed secondary state |
| `terracotta` | `#a8422f` | Danger text |
| `terracottaBg` | `#f4ddd6` | Danger background |
| `sage` | `#dfe7d6` | Success/status bg |
| `sageInk` | `#536341` | Success/status text |
| `blueBg` | `#dfe8ee` | Informational badge bg |
| `blueInk` | `#23384f` | Informational badge text |

## Radius

| Token | Value | Use |
| --- | ---: | --- |
| `radiusXL` | 26–30 | Main app shell/window mock |
| `radiusLG` | 18 | Cards |
| `radiusMD` | 12 | Inputs, nav rows |
| `radiusSM` | 9 | Small buttons/tags |
| `radiusPill` | 999 | Badges/HUD |

## Spacing

| Token | Value | Use |
| --- | ---: | --- |
| `pagePaddingX` | 42 | Home content horizontal padding |
| `pagePaddingTop` | 34 | Home top padding |
| `cardPadding` | 20 | Regular card |
| `cardGap` | 14–16 | Between cards |
| `rowPaddingY` | 14–15 | List rows |
| `rowGap` | 14 | History row columns |
| `formGap` | 10–14 | Input groups |
| `buttonGap` | 7–8 | Action groups |

## Buttons

Buttons should be compact. Previous large/pill buttons felt wrong for desktop density.

### Sizes

| Size | Height | Horizontal padding | Font | Use |
| --- | ---: | ---: | ---: | --- |
| `tiny` | 24 | 7 | 11 | Inline micro-actions |
| `small` | 28 | 9 | 11.5 | Row actions |
| `regular` | 34 | 13 | 12.5 | Forms/cards |
| `large` | 38 | 16 | 13 | Main setup/onboarding CTA |

### Variants

| Variant | Use |
| --- | --- |
| `primary` | The one main action in a block |
| `secondary` | Normal utility action |
| `ghost` | Low-emphasis action, delete in rows if danger is too loud |
| `danger` | Destructive/write-heavy actions |

### Rules

- Do not put many primary buttons in one card.
- Row actions should usually be `small`.
- Inline utility actions can be `tiny`.
- Danger should be terracotta, not system red.
- Avoid full-width buttons except onboarding/checklists.

## Cards

### Standard card

Use for main Home sections:

- background: `surface`
- border: `line`
- radius: `18`
- padding: `20`
- subtle shadow

### Soft card

Use for secondary/dashboard sections:

- background: `surface2` with slight opacity
- same border/radius
- less visual weight

### Card title

Uppercase micro-label:

- 11pt
- weight 800
- tracking 0.07–0.09em
- color `muted`

## Rows

Use one shared row language across History, Dictionary, Snippets, Scratchpad.

### History row

Layout:

```text
time | text + metadata | status/action
```

Rules:

- time uses SF Mono 12pt.
- transcript text uses 14pt body.
- metadata uses 12pt muted.
- status badge is compact, not a big colored pill.

### Snippet row

Layout:

```text
trigger chips + replacement preview | actions
```

Rules:

- triggers are sand chips.
- replacement preview is muted body text.
- actions are small secondary/ghost buttons.

### Dictionary row

Layout:

```text
term chip/name + note | actions
```

Rules:

- term should be visually stronger than note.
- notes are muted and optional.

### Scratchpad row

Layout:

```text
time/created | title + text preview | actions
```

Rules:

- title strong.
- preview max 1–2 lines.

## Inputs

Inputs should not look like raw AppKit defaults.

### TextField

- height: about 34–36
- radius: 12
- border: `lineStrong`
- background: `surface`
- horizontal padding: 10–12
- font: 15pt SF Pro Text

### TextEditor

- min height depends on context:
  - snippet replacement: 140–150
  - scratchpad note: 180–220
- same radius/border/background as TextField.
- avoid huge empty text areas unless Scratchpad.

### Search field

- height: 34
- radius: 999 or 12
- muted placeholder
- optional magnifier icon

### Error/focus states

- focus border: subtle ink/sand emphasis, not blue.
- error border: terracotta with light bg tint.

## Tags and badges

### Tags/chips

Use for snippet triggers, mode labels, app names.

- background: `sand`
- text: `ink`
- radius: pill
- font: 12 semibold
- padding: 5x9

### Status badges

| Status | Background | Text |
| --- | --- | --- |
| Pasted | sage | sageInk |
| Copied | blueBg | blueInk |
| Ignored | sand | muted/ink |
| Error | terracottaBg | terracotta |

## Sidebar

Sidebar should feel like navigation, not settings.

- width: ~232
- background: `surface2`
- right border: subtle `line`
- nav item height: ~40
- active nav: ink at low opacity background
- icons should be low-detail and monochrome

## Home tabs

### History

Purpose: recovery and confidence.

Sections:

1. Header with active mode/style pill.
2. Summary stat cards.
3. Delivery + Top Apps dashboard.
4. Recent history grouped by day.

### Dictionary

Purpose: improve STT spelling/context.

Sections:

1. Add/edit term card.
2. Search.
3. Term list.
4. Optional warnings for snippet conflicts.

### Snippets

Purpose: local deterministic replacement.

Sections:

1. Create snippet builder.
2. Test snippet card.
3. Saved snippets.
4. Import/export as secondary actions.

### Scratchpad

Purpose: longer text capture without immediate paste.

Sections:

1. Current note editor.
2. Saved notes.
3. Copy/Paste actions.

## Settings

Settings should be denser than Home.

Recommended groups:

1. Workflow
   - Transcription mode.
   - Prompt mode.
   - Writing style.
   - App-aware behavior.
   - Post-processing per mode.

2. Permissions
   - Microphone.
   - Accessibility.
   - Install path `/Applications/PasteVox.app`.

3. Hotkey
   - Fn hold-to-record.
   - Fn+1…4 modes.
   - Fn+5…0 styles.
   - Event tap status.

4. Metrics
   - Last transcription duration.
   - Last post-processing duration.
   - Paste status.

5. Debug
   - Log path.
   - Last error.
   - Copy diagnostics.
   - Reset settings.

6. OpenAI
   - API key save/delete.
   - masked key only.
   - model selection.

## HUD

HUD is the most important visible surface.

### Hard rules

- Fixed size.
- No wrapping.
- Short labels only.
- One-line mode/style label.
- Auto-collapse for success/error states.

### Labels

Mode short labels:

| Mode | HUD label |
| --- | --- |
| Raw Dictation | Raw |
| Agent Prompt | Agent |
| RALPH Prompt | RALPH |
| Terminal Command | Command |

Style short labels:

| Style | HUD label |
| --- | --- |
| Default | hidden |
| Concise | Concise |
| Friendly | Friendly |
| Formal | Formal |
| Coding Agent | Coding |
| Chat | Chat |
| Email | Email |

Examples:

```text
Listening
Agent · Coding
```

```text
Listening
Raw · style off
```

```text
Style: Friendly inactive
```

### HUD states

| State | Title | Detail |
| --- | --- | --- |
| Idle | none/collapsed | none |
| Listening | Listening | `Mode · Style` or `Mode · style off` |
| Transcribing | Transcribing | optional mode |
| Pasted | Pasted | short success |
| Copied | Copied | when paste failed but clipboard has result |
| Error | Error | short error only |
| No voice | No voice | not generic Error |
| Too short | Too short | not generic Error |

## Empty states

Every Home tab needs a good empty state.

### History empty

Title: `No dictations yet`

Body: `Hold Fn and speak. Your recent results will appear here for recovery.`

CTA: `Test Dictation` or no CTA.

### Dictionary empty

Title: `No dictionary terms yet`

Body: `Add names, project terms, emails and product spellings to improve transcription.`

CTA: `Add Term`

### Snippets empty

Title: `No snippets yet`

Body: `Create local voice shortcuts like “my email” → your address.`

CTA: `Create Snippet`

### Scratchpad empty

Title: `No notes yet`

Body: `Use Scratchpad for longer dictated drafts before pasting.`

CTA: `New Note`

## SwiftUI implementation map

Create or refactor toward these reusable components.

### Tokens

```swift
enum VDColor {
    static let bg = Color(...)
    static let surface = Color(...)
    static let surface2 = Color(...)
    static let ink = Color(...)
    static let muted = Color(...)
    static let line = Color(...)
    static let sand = Color(...)
    static let terracotta = Color(...)
}
```

```swift
enum VDRadius {
    static let card: CGFloat = 18
    static let control: CGFloat = 12
    static let small: CGFloat = 9
}
```

```swift
enum VDSpacing {
    static let pageX: CGFloat = 42
    static let pageTop: CGFloat = 34
    static let card: CGFloat = 20
    static let gap: CGFloat = 14
}
```

### Components

- `VDCard`
- `VDSoftCard`
- `VDButtonStyle`
- `VDTextFieldStyle`
- `VDTextEditorContainer`
- `VDTag`
- `VDStatusBadge`
- `VDSectionTitle`
- `VDEmptyState`
- `VDHistoryRow`
- `VDSnippetRow`
- `VDDictionaryRow`
- `VDScratchpadRow`

## Migration order

1. Extract tokens and reusable components.
2. Replace Home buttons with `VDButtonStyle`.
3. Replace Home cards with `VDCard` / `VDSoftCard`.
4. Normalize rows across all Home tabs.
5. Normalize inputs.
6. Add empty states.
7. Polish Settings separately.
8. Final HUD label/spacing check.

## Reference

HTML sketches:

```text
PasteVox/design/home-redesign.html       # default neutral variant
PasteVox/design/home-redesign-warm.html  # warm/sand variant
```

Open with:

```bash
open PasteVox/design/home-redesign.html
```

Use the top switcher to compare Neutral and Warm.
