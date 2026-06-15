# Лендинг PasteVox — ревью и правки переводов (i18n)

**Дата:** 2026-06-15
**Файл переводов:** `VoiceDock/landing/src/i18n.ts`
**Локали:** `en` (база), `ru`, `es`, `fr`, `de`
**Особый фокус (по запросу):** EN и RU

## Как проверяли

Многоагентный лингвистический QA: по одному нативному ревьюеру-копирайтеру на каждый язык
(EN и RU — с углублённым промптом), плюс независимая adversarial-перепроверка предложенных
правок для EN и RU вторым экспертом (он подтверждал/правил/отклонял находки первого редактора и
добавлял пропущенное). Итоговое решение по каждой находке принималось вручную: часть применена,
часть отклонена или уточнена ради точности смысла и кросс-локальной консистентности.

После правок: `npm run validate:i18n` (build + smoke-валидатор) — **проходит, 5/5 локалей**.

## Принцип: что трогали, а что нет

Лендинг ориентирован на **разработчиков**, и переводы намеренно сделаны как
**локально-адаптированный маркетинг**, а не дословное зеркало EN. Часть англоязычных
технических/UI-терминов оставлена сознательно, и мы её **не меняли**, потому что она отражает
реальный интерфейс приложения:

- продукт и UI-метки: `PasteVox`, `Settings`, `Home`, `Keychain`, `Save to Keychain`,
  `/Applications`, `Privacy & Security → Microphone/Accessibility`, `OpenAI`, `API key`, `HUD`;
- названия режимов и стилей, хоткеи: `Raw Dictation`, `Agent Prompt`, `RALPH Prompt`,
  `Terminal Command`, `Default/Concise/Friendly/Formal/Coding/Chat/Email`, `Fn+1…0`, `Fn+-`;
- строка структуры RALPH: `Role → Goal → Context → Constraints → Acceptance criteria`.

**Чинили:** реально непереведённые куски, грамматику/падежи/пунктуацию, «переводизмы»,
неестественные/устаревшие или неуместные слова, рассогласование регистра и терминов,
слабые с точки зрения внимания формулировки.

## Итоговая оценка по языкам

- **EN** — родной, чистый, ритмичный; правки косметические (живее CTA и пара корявых оборотов).
- **RU** — крепкая локаль в едином неформальном регистре на «ты»; основные проблемы — один
  непереведённый футер, нестандартное «транскрибация», пара разговорных/калькированных мест.
- **ES** — естественный es-ES, без «translationese»; точечные правки выбора слова и смысла.
- **FR** — качественный, единый формальный регистр на «vous»; одна **критическая** лексическая
  ошибка (`utilité` вместо `utilitaire`) и рассинхрон термина.
- **DE** — в целом хороший, единый «du»; были **сломанное предложение** и пропущенные запятые
  перед `ohne … zu`.

---

## Применённые изменения

Всего применена **31 правка**. Ниже — по локалям (поле → было → стало → почему).

### EN (5)

| Поле | Было → Стало | Почему |
|---|---|---|
| `workflow.cards[1].title` | «Speak the messy version» → «Speak the messy first draft» | «version» расплывчато; «first draft» конкретнее и точнее («наговори черновик, не вылизывая»). |
| `modes.title` | «Switch the output shape…» → «Reshape the output…» | «switch the output shape» — калькированный оборот; «reshape» компактнее и активнее. |
| `setup.ctaCopy` | «Download packaging is coming together.» → «…is on the way.» | «coming together» расплывчато-разговорно и ослабляет CTA; «on the way» прямее и увереннее. |
| `privacy.rows[3]` (title) | «Reviewed before danger.» → «Checked before they run.» | «before danger» как существительное звучит неестественно; новый вариант — родная формулировка, параллельная соседним строкам таблицы. |
| `proof[3]` (copy) | «…blocked from blind auto-paste.» → «…never blind-pasted automatically.» | «blocked from … auto-paste» читается коряво; новый вариант естественнее при том же смысле. |

> EN-строки, от которых зависит build-валидатор (`Speak.`, `Language`, строка футера), намеренно не трогали.

### RU (12) — приоритетный язык

| Поле | Было → Стало | Почему |
|---|---|---|
| `footer[1]` | англ. «Open-source native macOS voice-to-agent utility.» → «Open-source нативная macOS-утилита для голоса и кодинг-агентов.» | **Критично:** футер RU оставался полностью на английском (в es/fr/de переведён). Переведён по образцу других локалей. |
| `modes.cards[0].copy` | «Чистая транскрибация…» → «Чистая транскрипция…» | «Транскрибация» — нестандартная калька; нормативный термин — «транскрипция». |
| `styles.cards[4].copy` | «…транскрибация оставалась…» → «…транскрипция оставалась…» | То же; единообразие по странице. |
| `features.rows[2].points[1]` | «Контекст для транскрибации» → «Контекст для транскрипции» | То же; единообразие. |
| `privacy.posterTitle` | «Без синка.» → «Без синхронизации.» | «Синк» — слишком сленгово для крупного заголовка-постера рядом с нейтральными «аккаунта/сюрпризов». |
| `modes.cards[1].copy` | «Превращает небрежную речь…» → «Превращает черновую речь…» | EN «rough speech» — про черновую речь; «небрежную» звучит как упрёк юзеру. «Черновую» совпадает с терминологией страницы. |
| `privacy.rows[0]` (copy) | «Не читается просто при старте приложения.» → «…просто для запуска приложения.» | Ближе к EN «Not read just to start the app»; «запуск» вместо кальки «старт». |
| `modes.cards[3].copy` | «…как comment preview.» → «…как закомментированный preview.» | Сырой англицизм «comment preview»; в `example` той же карточки уже «закомментированный preview». |
| `proof[3]` (title) | «Safety gates» → «Защитные барьеры» | Маркетинговый заголовок (не UI-лейбл), в es/fr/de переведён; RU был единственным англоязычным среди переведённых proof-заголовков. |
| `privacy.title` | «…Shortcuts остаются локальными.» → «…Хоткеи остаются локальными.» | Полу-английская фраза (англ. подлежащее + рус. сказуемое) читается неуклюже; «хоткеи» — естественный для dev-аудитории термин. |
| `privacy.posterCopy` | «…честность про чувствительные части…» → «…прямо о чувствительных вещах…» | «Честность про X» + «части» = «translationese»; «прямо о … вещах» чисто и в одном регистре (ср. es/fr/de). |
| `features.rows[2].title` | «Твой словарь, правильное написание.» → «Твой словарь — с правильным написанием.» | Два несвязанных существительных через запятую звучат обрублено (калька «Your vocabulary, spelled right»); тире и предлог связывают фразу. |

### ES (4)

| Поле | Было → Стало | Почему |
|---|---|---|
| `proof[2].copy` | «tecla de pulsación elegida» → «tecla de mantener pulsado elegida» | «hold key» — клавиша **удержания** (hold-to-talk); «pulsación» теряет этот смысл. Согласовано с `workflow.title` («Mantén pulsado»). |
| `modes.cards[3].copy` | «bloquea los riesgosos» → «bloquea los peligrosos» | «riesgosos» характернее для Лат. Америки; для es-ES естественнее «peligrosos», как уже в `privacy.rows`. |
| `privacy.rows[3]` (title) | «Revisión antes del riesgo.» → «Revisados antes del riesgo.» | Параллелизм с другими строками таблицы (Guardada/Coincidencia/Guardado) и ближе к смыслу EN. |
| `setup.steps[0]` (бейдж) | «Build local» → «Build de publicación» | EN — «Release build» (релизная сборка), а «Build local» меняло смысл на «локальная». См. примечание про этот бейдж ниже. |

### FR (5)

| Поле | Было → Стало | Почему |
|---|---|---|
| `description` | «une **utilité** macOS … transforme **la** voix en **dictée**» → «un **utilitaire** macOS … transforme **votre** voix en **dictées**» | **Критично:** «utilité» = «полезность» (абстракция), а не программа-утилита; правильно «utilitaire» (как в `hero.eyebrow`). Плюс «votre voix» (ср. EN «your voice») и множ. число для параллелизма. |
| `proof[2].copy` | «les modes et **le ton**» → «les modes et **les styles d’écriture**» | EN — «modes and writing styles»; заголовок карточки тоже «Modes et styles». «le ton» искажал смысл и рассинхронил термин. |
| `hero.copy` | «votre voix en **dictée**, prompts» → «votre voix en **dictées**, prompts» | Параллелизм перечисления (остальные пункты во множ. числе) и согласование с `description`. |
| `modes.cards[1].copy` | «une idée dictée à la volée» → «une parole brute» | EN — «rough speech»; «à la volée» добавляло отсутствующий в оригинале смысл «на лету» и звучало как переводизм. |
| `setup.steps[0]` (бейдж) | «Build local» → «Build de publication» | Та же правка «release vs local», что и в ES. |

### DE (5)

| Поле | Было → Стало | Почему |
|---|---|---|
| `modes.cards[3].copy` | «…blockiert riskante Ausgaben **aber** als kommentierte Vorschau.» → «…blockiert **aber** riskante Ausgaben **und zeigt sie** als kommentierte Vorschau.» | **Критично:** сломанный порядок слов и потеря смысла. EN: «blocked **and shown** as a commented preview». «aber» должно идти сразу после глагола. |
| `proof[2].copy` | «…Schreibstile ohne Settings zu öffnen.» → «…Schreibstile**,** ohne Settings zu öffnen.» | Пунктуация: в немецком перед инфинитивным оборотом `ohne … zu` обязательна запятая. |
| `modes.cards[0].style` (бейдж) | «style off» → «Stil aus» | В этой карточке текст уже немецкий («Stile bleiben bewusst aus»); бейдж приведён к немецкому для единообразия (рядом уже «strukturiert», «Sicherheitscheck»). |
| `setup.copy` | «Installiere **nach**» → «Installiere **in**» | «nach» для папки звучит как калька; для «установить в каталог» естественно «in /Applications». |
| `setup.steps[0]` (бейдж) | «Lokaler Build» → «Release-Build» | Та же правка «release vs local»; «Release-Build» — естественный немецкий dev-термин. |

---

## Что сознательно НЕ менял

- **Намеренный билингвальный стиль** (UI-термины, названия режимов/стилей, хоткеи) — оставлен
  как есть во всех локалях (см. раздел «Принцип» выше).
- **EN-строки, от которых зависит валидатор** (`Speak.`, `Language`, строка футера) — не трогал.
- **Чисто стилистические замены равного качества** — пропускал, чтобы не плодить churn:
  - ES `hero.copy` («en la que ya estás trabajando» → «que ya tienes abierta») — оригинал
    корректен и естественен;
  - ES `footer[1]` («para voz **y** agentes» → «para voz **a** agentes») — вариант «y»
    благозвучнее и консистентен с fr/de («et»/«und»).

## Открытые вопросы / опции (решение за тобой)

1. **DE-герой** `hero.title` = `['Sprich.', 'Füge ein.', 'Mach weiter.']`.
   Один из ревьюеров предлагал «Füge ein.» → «Einfügen.», но это смешало бы императив
   («Sprich.», «Mach weiter.») с инфинитивом и **рассогласовало бы** три строки. Поэтому
   **оставил как есть**. Если хочется более «ударного» героя — корректнее перевести все три строки
   в инфинитив: **«Sprechen. Einfügen. Weitermachen.»** (тогда нужно синхронно поправить и
   `title` страницы). Скажи, если делать.

2. **Бейдж шага 01 «Release build».** EN использует `Release build` (конфигурация сборки Xcode —
   осмысленно для dev-аудитории: packaged Release → стабильная подпись → стабильные permissions).
   `ru` уже хранил английское `Release build`; `es/fr/de` рендерили его как «локальная сборка», что
   меняло смысл. Я выровнял все по смыслу EN (`Build de publicación` / `Build de publication` /
   `Release-Build`). Если предпочтительнее формулировка «локальная сборка» (т.к. официального
   релиза пока нет и пользователь собирает локально), могу вернуть/переформулировать во всех
   локалях единообразно — скажи.

## Доп. итерация: переосмысление заголовка секции Workflow

Длинное предложение-перечисление (`Hold Fn, Right Option or Right Command, speak naturally,
paste into the active app.`) плохо смотрелось как H2 во всех языках. Реструктурировали секцию:
короткий выразительный `title` про **результат**, а перечисление клавиш уехало в `copy` (субтекст),
куда подмешали и прежнюю строку про менюбар — ничего не потеряли.

Новые заголовки нативно адаптированы (не дословно) и проверены нативными редакторами по каждому
языку (RU/ES/FR одобрены без правок, DE — короткое тире `–` заменено на длинное `—` для
единообразия).

| Локаль | Новый `title` | Новый `copy` (субтекст) |
|---|---|---|
| **EN** | Your voice, in the active app. | Hold Fn, Right Option or Right Command, speak naturally, and it pastes into the active app. PasteVox lives in the menu bar — Settings stay out of the way until you need them. |
| **RU** | Твой голос — в активном приложении. | Зажми Fn, правый Option или правый Command, скажи текст — и он вставится в активное приложение. PasteVox живёт в менюбаре, а Settings не мешают, пока не нужны. |
| **ES** | Tu voz, en la app activa. | Mantén pulsado Fn, Option derecho o Command derecho, habla con naturalidad y se pega en la app activa. PasteVox vive en la barra de menús — Settings no aparece hasta que lo necesitas. |
| **FR** | Votre voix, dans l’app active. | Maintenez Fn, Option droit ou Command droit, parlez naturellement, et le texte se colle dans l’app active. PasteVox vit dans la barre de menus — Settings reste hors de vue tant que vous n’en avez pas besoin. |
| **DE** | Deine Stimme — in der aktiven App. | Halte Fn, rechte Option oder rechte Command-Taste, sprich natürlich — und es landet in der aktiven App. PasteVox lebt in der Menüleiste, Settings bleibt aus dem Weg, bis du es brauchst. |

> Направление заголовка («про результат, а не механику») выбрано пользователем из трёх вариантов.

## Доп. итерация 2: чистка Runglish + переносы (по фидбэку)

Фидбэк: русский был перемешан с английским (Runglish), а EN-слово «flow» уродски
переносилось на отдельную строку. Раньше ревью слишком буквально трактовало «намеренный
билингвальный стиль» и оставило кучу англицизмов в прозе. Это переделано по-настоящему.

**Политика теперь:** в прозе остаются по-английски ТОЛЬКО имена собственные и реальные UI-метки —
`PasteVox`, `macOS`, `OpenAI`, `Keychain`, `Swift/SwiftUI/AppKit/Electron`, `open-source`, имена
клавиш (`Fn`, `Option`, `Command`, `Globe`), хоткеи, названия режимов (`Raw Dictation`,
`Agent Prompt`, `RALPH Prompt`, `Terminal Command`) и стилей (`Default…Email`), окно `Home`,
строка `Snippets` как продуктовый термин, и буквальные клик-пути (`Settings → OpenAI → Save to
Keychain`, `Privacy & Security → Microphone/Accessibility`). Всё остальное — чистый целевой язык.

**RU — переписан целиком** (был худшим по Runglish). Примеры замен:
- `permission flow` → «настройка разрешений»; `Держи macOS permissions стабильными` → «Чтобы
  разрешения macOS не слетали…»; `Нормальный permission flow для macOS` → «Понятная настройка
  разрешений в macOS».
- privacy-карточка: `target apps` → «целевые приложения», `delivery status` → «статус доставки»,
  `failed paste` → «неудачную вставку», `terminal commands` → «терминальные команды»,
  `Trigger-фразы` → «фразы-триггеры», `Матчатся локально` → «Сопоставляются локально»; пилюли
  статусов и лейблы строк — на русском (`API-ключ/Сниппеты/История/Команды`,
  `защищён/локально/на виду/с проверкой`).
- прочее: `post-processing` → «постобработка», `hold-to-talk` → «режим „зажми и говори“»,
  `Workspace` → «Рабочее пространство», `Writing styles` → «Стили письма», `comment preview` →
  «закомментированный предпросмотр», `менюбар` → «строка меню», `Shortcuts` → «Горячие клавиши»,
  и т.д. `Settings` в прозе → «настройки» (оставлен только в клик-пути).

**ES/FR/DE** — тот же класс правок применён нативными редакторами (по ~16–19 правок на язык):
generic `Settings` → `Ajustes`/`Réglages`/`Einstellungen` (вне клик-пути), `Workspace` →
`Espacio de trabajo`/`Espace de travail`/`Arbeitsbereich`, лейблы строк фич и privacy → нативные
(`Historial/Diccionario/Borrador`, `Historique/Dictionnaire/Bloc-notes`,
`Verlauf/Wörterbuch/Notizfeld`, `Befehle`…), убран жаргон (`hold-to-talk`, `app bundle`, `debug`,
`sync`, `Hold-Taste`, `Modifier`, `Shortcuts`). DE: `Kein Account.` → `Kein Konto.` (валидатор
обновлён), `App-Bundle` оставлен как устоявшийся термин.

**Переносы слов (системный фикс):** в `landing.css` добавлен `text-wrap: balance` для всех
заголовков (`h1–h4`). Это убирает осиротевшие слова на отдельной строке (EN «flow» и т.п.) и
балансирует длинные строки во всех языках. EN-заголовок секции Setup переформулирован:
`A practical macOS permission flow.` → `Practical macOS permissions, step by step.`

**Проверка:** `npm run validate:i18n` — зелёный (5/5). Сквозной grep по собранному HTML: остаточного
Runglish нет, `Settings` встречается ровно 1 раз на локаль (клик-путь). Визуально подтверждено
скриншотами (Playwright) для EN setup-заголовка и RU privacy/setup секций.

**Осталось на заметку (не критично):** некоторые `aria-label`/alt в `LandingPage.astro`
захардкожены по-английски (напр. `aria-label="Minimal workspace layout without cards"`) и не
локализованы — они только для скринридеров и не видны на странице. Можно вынести в i18n при желании.

## Доп. итерация 3: перенос в постере приватности (длинное «синхронизация»)

Фидбэк: в RU-постере «Без аккаунта. / Без синхронизации. / Без сюрпризов.» средняя строка
переносила «Без» на отдельную строку. Замер (Playwright) показал, что это касается не только RU:
слово «синхронизация» длинное и в FR (`synchronisation`) и DE (`Synchronisierung`, + ещё
`Überraschungen`) — постер при 56px не вмещает эти строки (RU нужно ≤48.6px, FR ≤44.4px, DE ≤43.1px);
EN и ES помещаются.

**Фикс — без подмены слов на сленг:** в `landing.css` добавлены пер-язык переопределения размера
шрифта постера `html[lang="ru|fr|de"] .receipt-poster h3` (RU 46px, FR 42px, DE 41px через `clamp`),
EN/ES остаются на 56px. Теперь каждая строка постера во всех языках помещается в одну строку
(подтверждено замером и скриншотом).

## Как пересобрать и посмотреть

```bash
cd VoiceDock/landing
npm run validate:i18n     # build + smoke-валидатор i18n (сейчас проходит)
npm run dev               # локальный просмотр (Astro, host 127.0.0.1)
```

Языки на странице переключаются меню в навбаре; маршруты: `/`, `/ru/`, `/es/`, `/fr/`, `/de/`.
