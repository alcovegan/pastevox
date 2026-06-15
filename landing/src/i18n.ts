export const languages = [
  { code: 'en', label: 'English', shortLabel: 'EN', flag: '🇺🇸', path: '/' },
  { code: 'ru', label: 'Русский', shortLabel: 'RU', flag: '🇷🇺', path: '/ru/' },
  { code: 'es', label: 'Español', shortLabel: 'ES', flag: '🇪🇸', path: '/es/' },
  { code: 'fr', label: 'Français', shortLabel: 'FR', flag: '🇫🇷', path: '/fr/' },
  { code: 'de', label: 'Deutsch', shortLabel: 'DE', flag: '🇩🇪', path: '/de/' }
] as const;

export type Locale = typeof languages[number]['code'];

export const pages = {
  en: {
    lang: 'en',
    title: 'PasteVox — Speak. Paste. Keep moving.',
    description: 'PasteVox is a macOS menu bar app that turns your voice into dictation, coding-agent prompts, terminal commands, snippets, and scratchpad notes.',
    nav: { workflow: 'Workflow', modes: 'Modes', features: 'Features', privacy: 'Privacy', setup: 'Setup', download: 'Download', language: 'Language' },
    hero: {
      eyebrow: 'macOS menu bar voice utility',
      title: ['Speak.', 'Paste.', 'Keep moving.'],
      copy: 'PasteVox turns your voice into dictation, coding-agent prompts, terminal commands, snippets, and scratchpad notes — directly inside the macOS app you are already using.',
      primary: 'Build from source',
      secondary: 'View setup',
      badges: ['macOS 13+', 'OpenAI STT', 'Keychain key', 'No Electron', 'Open-source'],
      screenAlt: 'PasteVox Home history screen',
      hudAlt: 'PasteVox listening HUD'
    },
    proof: [
      ['Open-source', 'Inspect the app, build locally, and keep the workflow understandable.'],
      ['Native macOS', 'Menu bar utility built with Swift, SwiftUI and AppKit. No Electron shell.'],
      ['Modes & styles', 'Fn or your selected hold key changes modes and writing styles without opening Settings.'],
      ['Safety gates', 'Risky terminal commands are never blind-pasted automatically.']
    ],
    workflow: {
      kicker: 'Workflow',
      title: 'Your voice, in the active app.',
      copy: 'Hold Fn, Right Option or Right Command, speak naturally, and it pastes into the active app. PasteVox lives in the menu bar — Settings stay out of the way until you need them.',
      cards: [
        ['1', 'Hold your chosen key', 'Start recording with Fn/Globe, Right Option or Right Command. The HUD shows when PasteVox is listening.'],
        ['2', 'Speak the messy first draft', 'Dictate naturally. Use raw dictation, agent prompts, RALPH prompts or terminal command mode.'],
        ['3', 'Paste and move on', 'PasteVox transcribes, optionally rewrites, expands snippets and pastes into the frontmost app.']
      ]
    },
    modes: {
      kicker: 'Modes',
      title: 'Reshape the output without opening a window.',
      copy: 'Fn+1…4 switches modes. Fn+5…0 switches writing styles for post-processed modes; Fn+- selects Email. The selected hold key works too.',
      cards: [
        { label: 'Mode 01', hotkey: 'Fn+1', title: 'Raw Dictation', copy: 'Plain transcription. No rewrite. Styles intentionally stay off.', style: 'style off', example: 'exactly what you said, cleaned only by transcription' },
        { label: 'Mode 02', hotkey: 'Fn+2', title: 'Agent Prompt', copy: 'Turns rough speech into a clear coding-agent task.', style: 'Fn+5…0 styles', example: 'implement this UI change, verify it, then run the app' },
        { label: 'Mode 03', hotkey: 'Fn+3', title: 'RALPH Prompt', copy: 'Structured prompt with role, goal, context, constraints and acceptance criteria.', style: 'structured', example: 'Role → Goal → Context → Constraints → Acceptance criteria' },
        { label: 'Mode 04', hotkey: 'Fn+4', title: 'Terminal Command', copy: 'Generates commands, but risky output is blocked and shown as a commented preview.', style: 'safety gate', example: 'safe command, or commented preview if destructive' }
      ],
      output: 'Output'
    },
    styles: {
      kicker: 'Writing styles',
      title: 'Keep the mode, change the tone.',
      copy: 'Styles are quick modifiers for post-processed modes. Switch from concise to friendly, formal, coding-agent, chat, or email without opening Settings. Raw dictation stays raw.',
      hotkeys: ['Fn+5 Default', 'Fn+6 Concise', 'Fn+7 Friendly', 'Fn+8 Formal', 'Fn+9 Coding', 'Fn+0 Chat', 'Fn+- Email'],
      cards: [
        ['Example: Agent · Concise', 'Turns a rough spoken task into a shorter coding-agent instruction without changing the selected mode.', true],
        ['Friendly', 'Useful for Slack, chat replies and lighter product notes.'],
        ['Formal', 'Useful for email, reviews and more careful wording.'],
        ['Coding', 'Biases rewrites toward precise implementation instructions.'],
        ['Style off in Raw', 'Raw Dictation intentionally ignores style so transcription remains unprocessed.']
      ]
    },
    features: {
      kicker: 'Workspace',
      title: 'History, snippets, dictionary and scratchpad in one Home window.',
      copy: 'Home is for recovery and writing. Settings are only for configuration and debugging.',
      rows: [
        { kind: 'History', title: 'History for every paste.', copy: 'Recover recent dictations, inspect the target app, see delivery status and copy or paste the result again.', points: ['Recent outputs grouped by day', 'Delivery stats and top apps', 'Quick recovery after failed paste'], image: '/assets/screen-history.png', alt: 'PasteVox history dashboard' },
        { kind: 'Snippets', title: 'Snippets without waiting.', copy: 'Say a short trigger and PasteVox inserts the exact replacement locally, without sending the snippet to an LLM.', points: ['Multiple trigger phrases', 'Deterministic local matching', 'JSON import and export'], image: '/assets/screen-snippets.png', alt: 'PasteVox snippets screen', reverse: true },
        { kind: 'Dictionary', title: 'Your vocabulary, spelled right.', copy: 'Add project names, acronyms, emails and product terms so speech recognition gets the important words right.', points: ['Names, acronyms and spellings', 'Context for transcription', 'Useful for teams and products'], image: '/assets/screen-dictionary.png', alt: 'PasteVox dictionary screen' },
        { kind: 'Scratchpad', title: 'A scratchpad for rough thoughts.', copy: 'Capture longer notes and prompts first, then copy or paste them when they are ready.', points: ['Save longer dictated drafts', 'Edit before pasting', 'Keep workspace separate from settings'], image: '/assets/screen-scratchpad.png', alt: 'PasteVox scratchpad screen', reverse: true }
      ]
    },
    privacy: {
      kicker: 'Privacy & control',
      title: 'Your key stays in Keychain. Your shortcuts stay local.',
      copy: 'PasteVox is designed as a small open-source macOS utility, not a hosted writing platform.',
      posterKicker: 'Privacy, plainly',
      posterTitle: ['No account.', 'No sync.', 'No surprises.'],
      posterCopy: 'Open-source and explicit about the sensitive parts: where the key lives, when audio is sent, and what stays on your Mac.',
      rows: [
        ['API key', 'secured', 'Saved to Keychain.', 'Used when you ask PasteVox to transcribe or post-process. Not read just to start the app.'],
        ['Snippets', 'local', 'Matched locally.', 'Trigger phrases expand deterministically on your Mac. No model call is needed.'],
        ['History', 'visible', 'Kept for recovery.', 'Recent outputs, target apps and delivery status stay in Home so failed paste is recoverable.'],
        ['Commands', 'gated', 'Checked before they run.', 'Risky terminal commands are stopped and shown as comments instead of being pasted blindly.']
      ]
    },
    setup: {
      kicker: 'Setup',
      title: 'Practical macOS permissions, step by step.',
      copy: 'Install into',
      copyTail: 'for stable Accessibility permissions, then grant the permissions PasteVox needs to record and paste.',
      steps: [
        ['01', 'Install to /Applications', 'Keep macOS permissions stable by running the packaged app from the normal Applications path.', 'Release build', 'Use the packaged app from /Applications for stable macOS permissions.'],
        ['02', 'Add OpenAI API key', 'PasteVox stores the key in macOS Keychain and keeps Settings separate from the Home workspace.', 'Where it goes', 'Settings → OpenAI → Save to Keychain'],
        ['03', 'Grant Microphone', 'Allow recording so hold-to-talk can capture voice and send it for transcription.', 'macOS permission', 'Privacy & Security → Microphone'],
        ['04', 'Grant Accessibility', 'Required for reliable global shortcuts and paste into the frontmost macOS app.', 'macOS permission', 'Privacy & Security → Accessibility']
      ],
      ctaTitle: 'Ready to try PasteVox?',
      ctaCopy: 'Download packaging is on the way. For now, build from source or use the local app bundle generated by the project scripts.',
      build: 'Build from source',
      top: 'Back to top'
    },
    footer: ['© PasteVox', 'Open-source native macOS voice-to-agent utility.']
  },
  ru: {
    lang: 'ru',
    title: 'PasteVox — Скажи. Вставь. Продолжай.',
    description: 'PasteVox — голосовая macOS-утилита в строке меню: превращает голос в диктовку, промпты для кодинг-агентов, терминальные команды, сниппеты и заметки.',
    nav: { workflow: 'Процесс', modes: 'Режимы', features: 'Home', privacy: 'Приватность', setup: 'Установка', download: 'Скачать', language: 'Язык' },
    hero: {
      eyebrow: 'голосовая macOS-утилита в строке меню',
      title: ['Скажи.', 'Вставь.', 'Продолжай.'],
      copy: 'PasteVox превращает голос в диктовку, промпты для кодинг-агентов, терминальные команды, сниппеты и заметки — прямо в том macOS-приложении, где ты уже работаешь.',
      primary: 'Собрать из исходников',
      secondary: 'Как настроить',
      badges: ['macOS 13+', 'OpenAI STT', 'ключ в Keychain', 'без Electron', 'open-source'],
      screenAlt: 'экран истории PasteVox Home',
      hudAlt: 'HUD PasteVox во время записи'
    },
    proof: [
      ['Open-source', 'Можно посмотреть код, собрать локально и понять, что именно делает приложение.'],
      ['Нативный macOS', 'Утилита для строки меню на Swift, SwiftUI и AppKit. Без оболочки Electron.'],
      ['Режимы и стили', 'Fn или выбранная клавиша удержания переключает режимы и стили, не открывая настройки.'],
      ['Защитные барьеры', 'Опасные терминальные команды не вставляются вслепую.']
    ],
    workflow: {
      kicker: 'Процесс',
      title: 'Твой голос — в активном приложении.',
      copy: 'Зажми Fn, правый Option или правый Command, скажи текст — и он вставится в активное приложение. PasteVox живёт в строке меню, а настройки не мешают, пока не нужны.',
      cards: [
        ['1', 'Зажми выбранную клавишу', 'Запускай запись через Fn/Globe, правый Option или правый Command. HUD показывает, когда PasteVox слушает.'],
        ['2', 'Скажи черновую версию', 'Говори естественно. Выбирай режим: Raw Dictation, Agent Prompt, RALPH Prompt или Terminal Command.'],
        ['3', 'Вставь и продолжай', 'PasteVox распознаёт, при необходимости переписывает, раскрывает сниппеты и вставляет результат в активное приложение.']
      ]
    },
    modes: {
      kicker: 'Режимы',
      title: 'Меняй форму результата без открытия окна.',
      copy: 'Fn+1…4 переключает режимы. Fn+5…0 — стили постобработки; Fn+- выбирает Email. Выбранная клавиша удержания тоже работает.',
      cards: [
        { label: 'Режим 01', hotkey: 'Fn+1', title: 'Raw Dictation', copy: 'Чистая транскрипция. Без переписывания. Стили намеренно выключены.', style: 'без стиля', example: 'то, что ты сказал, очищенное только распознаванием' },
        { label: 'Режим 02', hotkey: 'Fn+2', title: 'Agent Prompt', copy: 'Превращает черновую речь в понятную задачу для кодинг-агента.', style: 'стили Fn+5…0', example: 'реализуй это изменение UI, проверь его и запусти приложение' },
        { label: 'Режим 03', hotkey: 'Fn+3', title: 'RALPH Prompt', copy: 'Структурированный промпт с ролью, целью, контекстом, ограничениями и критериями приёмки.', style: 'структура', example: 'Role → Goal → Context → Constraints → Acceptance criteria' },
        { label: 'Режим 04', hotkey: 'Fn+4', title: 'Terminal Command', copy: 'Генерирует команды, но рискованный результат блокирует и показывает как закомментированный предпросмотр.', style: 'защита', example: 'безопасная команда или закомментированный предпросмотр для опасных действий' }
      ],
      output: 'Результат'
    },
    styles: {
      kicker: 'Стили письма',
      title: 'Оставь режим, поменяй тон.',
      copy: 'Стили — быстрые модификаторы для режимов с постобработкой. Переключай Concise, Friendly, Formal, Coding, Chat или Email, не открывая настройки. Raw Dictation остаётся без обработки.',
      hotkeys: ['Fn+5 Default', 'Fn+6 Concise', 'Fn+7 Friendly', 'Fn+8 Formal', 'Fn+9 Coding', 'Fn+0 Chat', 'Fn+- Email'],
      cards: [
        ['Пример: Agent · Concise', 'Сжимает черновую голосовую задачу в короткую инструкцию для кодинг-агента, не меняя выбранный режим.', true],
        ['Friendly', 'Для Slack, ответов в чатах и более лёгких заметок о продукте.'],
        ['Formal', 'Для писем, ревью и более аккуратных формулировок.'],
        ['Coding', 'Сдвигает переписывание в сторону точных инструкций по реализации.'],
        ['Без стиля в Raw', 'Raw Dictation намеренно игнорирует стиль, чтобы транскрипция оставалась необработанной.']
      ]
    },
    features: {
      kicker: 'Рабочее пространство',
      title: 'История, сниппеты, словарь и черновик — в одном окне Home.',
      copy: 'Home — для восстановления и письма. Настройки — только для конфигурации и отладки.',
      rows: [
        { kind: 'История', title: 'История каждой вставки.', copy: 'Восстанавливай последние диктовки, смотри целевое приложение и статус доставки, копируй или вставляй результат заново.', points: ['Результаты сгруппированы по дням', 'Статистика доставки и частые приложения', 'Быстрое восстановление после неудачной вставки'], image: '/assets/screen-history.png', alt: 'история PasteVox' },
        { kind: 'Сниппеты', title: 'Сниппеты без ожидания.', copy: 'Скажи короткую фразу-триггер — PasteVox локально вставит точную замену, не отправляя сниппет в модель.', points: ['Несколько фраз-триггеров', 'Детерминированный поиск совпадений локально', 'Импорт и экспорт через JSON'], image: '/assets/screen-snippets.png', alt: 'экран сниппетов PasteVox', reverse: true },
        { kind: 'Словарь', title: 'Твой словарь — с правильным написанием.', copy: 'Добавляй названия проектов, аббревиатуры, адреса и продуктовые термины, чтобы важные слова распознавались правильно.', points: ['Имена, аббревиатуры и написание', 'Контекст для транскрипции', 'Полезно для команд и продуктов'], image: '/assets/screen-dictionary.png', alt: 'экран словаря PasteVox' },
        { kind: 'Черновик', title: 'Черновик для сырых мыслей.', copy: 'Записывай длинные заметки и промпты сначала сюда, а потом копируй или вставляй, когда они готовы.', points: ['Сохраняй длинные надиктованные черновики', 'Редактируй перед вставкой', 'Рабочее пространство отдельно от настроек'], image: '/assets/screen-scratchpad.png', alt: 'черновик PasteVox', reverse: true }
      ]
    },
    privacy: {
      kicker: 'Приватность и контроль',
      title: 'Ключ остаётся в Keychain. Горячие клавиши остаются локальными.',
      copy: 'PasteVox задуман как маленькая open-source-утилита для macOS, а не облачная платформа для письма.',
      posterKicker: 'Коротко о приватности',
      posterTitle: ['Без аккаунта.', 'Без синхронизации.', 'Без сюрпризов.'],
      posterCopy: 'Open-source и прямо о чувствительных вещах: где лежит ключ, когда отправляется аудио и что остаётся на твоём Mac.',
      rows: [
        ['API-ключ', 'защищён', 'Хранится в Keychain.', 'Используется, когда ты просишь PasteVox распознать или обработать текст. Не читается просто для запуска приложения.'],
        ['Сниппеты', 'локально', 'Сопоставляются локально.', 'Фразы-триггеры раскрываются детерминированно на твоём Mac. Обращение к модели не нужно.'],
        ['История', 'на виду', 'Хранится для восстановления.', 'Последние результаты, целевые приложения и статус доставки остаются в Home, чтобы можно было восстановить неудачную вставку.'],
        ['Команды', 'с проверкой', 'Проверяются до запуска.', 'Рискованные терминальные команды останавливаются и показываются комментариями, а не вставляются вслепую.']
      ]
    },
    setup: {
      kicker: 'Установка',
      title: 'Понятная настройка разрешений в macOS.',
      copy: 'Установи в',
      copyTail: 'для стабильных разрешений Accessibility, затем выдай права, которые нужны PasteVox для записи и вставки.',
      steps: [
        ['01', 'Установи в /Applications', 'Чтобы разрешения macOS не слетали, запускай собранное приложение из обычной папки Applications.', 'Релизная сборка', 'Запускай собранное приложение из /Applications — так разрешения macOS стабильнее.'],
        ['02', 'Добавь API-ключ OpenAI', 'PasteVox хранит ключ в macOS Keychain и держит настройки отдельно от рабочего пространства Home.', 'Где это', 'Settings → OpenAI → Save to Keychain'],
        ['03', 'Дай доступ к микрофону', 'Разреши запись, чтобы режим «зажми и говори» мог захватывать голос и отправлять его на распознавание.', 'Разрешение macOS', 'Privacy & Security → Microphone'],
        ['04', 'Дай доступ к Accessibility', 'Нужно для надёжных глобальных горячих клавиш и вставки в активное macOS-приложение.', 'Разрешение macOS', 'Privacy & Security → Accessibility']
      ],
      ctaTitle: 'Готов попробовать PasteVox?',
      ctaCopy: 'Готовый установщик ещё в работе. Пока можно собрать из исходников или запустить локально собранное приложение — его создают скрипты проекта.',
      build: 'Собрать из исходников',
      top: 'Наверх'
    },
    footer: ['© PasteVox', 'Open-source нативная macOS-утилита для голоса и кодинг-агентов.']
  },
  es: {
    lang: 'es',
    title: 'PasteVox — Habla. Pega. Sigue.',
    description: 'PasteVox es una utilidad para la barra de menús de macOS que convierte tu voz en dictado, prompts para agentes de código, comandos de terminal, snippets y notas.',
    nav: { workflow: 'Flujo', modes: 'Modos', features: 'Home', privacy: 'Privacidad', setup: 'Instalación', download: 'Descargar', language: 'Idioma' },
    hero: {
      eyebrow: 'utilidad de voz para la barra de menús de macOS',
      title: ['Habla.', 'Pega.', 'Sigue.'],
      copy: 'PasteVox convierte tu voz en dictado, prompts para agentes de código, comandos de terminal, snippets y notas — directamente en la app de macOS en la que ya estás trabajando.',
      primary: 'Compilar desde el código',
      secondary: 'Ver instalación',
      badges: ['macOS 13+', 'OpenAI STT', 'clave en Keychain', 'sin Electron', 'open-source'],
      screenAlt: 'pantalla de historial de PasteVox Home',
      hudAlt: 'HUD de PasteVox mientras escucha'
    },
    proof: [
      ['Open-source', 'Revisa el código, compílalo localmente y mantén claro el flujo de trabajo.'],
      ['Nativo de macOS', 'Utilidad de barra de menús hecha con Swift, SwiftUI y AppKit. Sin carcasa Electron.'],
      ['Modos y estilos', 'Fn o la tecla de mantener pulsado elegida cambia modos y estilos sin abrir Ajustes.'],
      ['Controles de seguridad', 'Los comandos de terminal arriesgados no se pegan a ciegas.']
    ],
    workflow: {
      kicker: 'Flujo',
      title: 'Tu voz, en la app activa.',
      copy: 'Mantén pulsado Fn, Option derecho o Command derecho, habla con naturalidad y se pega en la app activa. PasteVox vive en la barra de menús — los ajustes no aparecen hasta que los necesitas.',
      cards: [
        ['1', 'Mantén pulsada tu tecla', 'Empieza a grabar con Fn/Globe, Option derecho o Command derecho. El HUD muestra cuándo PasteVox está escuchando.'],
        ['2', 'Di la versión en bruto', 'Dicta como hablas. Usa dictado sin procesar, prompts de agente, prompts RALPH o modo de comandos de terminal.'],
        ['3', 'Pega y sigue', 'PasteVox transcribe, reescribe si hace falta, expande snippets y pega en la app en primer plano.']
      ]
    },
    modes: {
      kicker: 'Modos',
      title: 'Cambia la forma del resultado sin abrir una ventana.',
      copy: 'Fn+1…4 cambia de modo. Fn+5…0 cambia estilos para modos con postprocesado; Fn+- selecciona Email. La tecla elegida también sirve.',
      cards: [
        { label: 'Modo 01', hotkey: 'Fn+1', title: 'Raw Dictation', copy: 'Transcripción directa. Sin reescritura. Los estilos quedan desactivados a propósito.', style: 'sin estilo', example: 'lo que dijiste, limpiado solo por la transcripción' },
        { label: 'Modo 02', hotkey: 'Fn+2', title: 'Agent Prompt', copy: 'Convierte una idea hablada en una tarea clara para un agente de código.', style: 'estilos Fn+5…0', example: 'implementa este cambio de interfaz, verifícalo y ejecuta la app' },
        { label: 'Modo 03', hotkey: 'Fn+3', title: 'RALPH Prompt', copy: 'Prompt estructurado con rol, objetivo, contexto, restricciones y criterios de aceptación.', style: 'estructurado', example: 'Role → Goal → Context → Constraints → Acceptance criteria' },
        { label: 'Modo 04', hotkey: 'Fn+4', title: 'Terminal Command', copy: 'Genera comandos, pero bloquea los peligrosos y los muestra como una vista previa comentada.', style: 'control de riesgo', example: 'comando seguro o vista previa comentada si es destructivo' }
      ],
      output: 'Resultado'
    },
    styles: {
      kicker: 'Estilos de escritura',
      title: 'Mantén el modo, cambia el tono.',
      copy: 'Los estilos son modificadores rápidos para modos con postprocesado. Pasa de conciso a cercano, formal, orientado a código, chat o email sin abrir Ajustes. Raw Dictation sigue intacto.',
      hotkeys: ['Fn+5 Default', 'Fn+6 Concise', 'Fn+7 Friendly', 'Fn+8 Formal', 'Fn+9 Coding', 'Fn+0 Chat', 'Fn+- Email'],
      cards: [
        ['Ejemplo: Agent · Concise', 'Convierte una tarea hablada y desordenada en una instrucción más corta para un agente de código sin cambiar de modo.', true],
        ['Friendly', 'Útil para Slack, respuestas de chat y notas de producto menos rígidas.'],
        ['Formal', 'Útil para emails, revisiones y textos que necesitan más cuidado.'],
        ['Coding', 'Orienta la reescritura hacia instrucciones de implementación precisas.'],
        ['Sin estilo en Raw', 'Raw Dictation ignora el estilo para mantener la transcripción sin procesar.']
      ]
    },
    features: {
      kicker: 'Espacio de trabajo',
      title: 'Historial, snippets, diccionario y borrador en una sola ventana Home.',
      copy: 'Home es para recuperar y escribir. Los ajustes quedan para configuración y depuración.',
      rows: [
        { kind: 'Historial', title: 'Historial de cada pegado.', copy: 'Recupera dictados recientes, revisa la app de destino, ve el estado de entrega y copia o pega otra vez.', points: ['Resultados recientes agrupados por día', 'Estadísticas de entrega y apps principales', 'Recuperación rápida tras un pegado fallido'], image: '/assets/screen-history.png', alt: 'panel de historial de PasteVox' },
        { kind: 'Snippets', title: 'Snippets sin esperar.', copy: 'Di un disparador corto y PasteVox inserta la sustitución exacta localmente, sin enviar el snippet a un LLM.', points: ['Varias frases disparadoras', 'Coincidencia local determinista', 'Importación y exportación JSON'], image: '/assets/screen-snippets.png', alt: 'pantalla de snippets de PasteVox', reverse: true },
        { kind: 'Diccionario', title: 'Tu vocabulario, bien escrito.', copy: 'Añade nombres de proyectos, siglas, emails y términos de producto para que las palabras importantes salgan bien.', points: ['Nombres, siglas y grafías', 'Contexto para la transcripción', 'Útil para equipos y productos'], image: '/assets/screen-dictionary.png', alt: 'pantalla de diccionario de PasteVox' },
        { kind: 'Borrador', title: 'Un borrador para ideas en bruto.', copy: 'Captura notas y prompts más largos primero; cópialos o pégalos cuando estén listos.', points: ['Guarda borradores dictados largos', 'Edita antes de pegar', 'Espacio de trabajo separado de los ajustes'], image: '/assets/screen-scratchpad.png', alt: 'scratchpad de PasteVox', reverse: true }
      ]
    },
    privacy: {
      kicker: 'Privacidad y control',
      title: 'Tu clave se queda en Keychain. Tus atajos se quedan en local.',
      copy: 'PasteVox está pensado como una pequeña utilidad open-source para macOS, no como una plataforma de escritura alojada.',
      posterKicker: 'Privacidad, sin rodeos',
      posterTitle: ['Sin cuenta.', 'Sin sincronización.', 'Sin sorpresas.'],
      posterCopy: 'Open-source y claro con las partes sensibles: dónde vive la clave, cuándo se envía audio y qué se queda en tu Mac.',
      rows: [
        ['Clave API', 'segura', 'Guardada en Keychain.', 'Se usa cuando pides a PasteVox transcribir o postprocesar. No se lee solo por iniciar la app.'],
        ['Snippets', 'local', 'Coincidencia local.', 'Las frases disparadoras se expanden de forma determinista en tu Mac. No hace falta llamar a un modelo.'],
        ['Historial', 'visible', 'Guardado para recuperar.', 'Los resultados recientes, apps de destino y estados de entrega quedan en Home para recuperar un pegado fallido.'],
        ['Comandos', 'protegido', 'Revisados antes de ejecutarse.', 'Los comandos peligrosos se detienen y se muestran como comentarios en vez de pegarse a ciegas.']
      ]
    },
    setup: {
      kicker: 'Instalación',
      title: 'Un flujo de permisos práctico para macOS.',
      copy: 'Instala en',
      copyTail: 'para mantener estables los permisos de Accessibility; luego concede lo que PasteVox necesita para grabar y pegar.',
      steps: [
        ['01', 'Instala en /Applications', 'Mantén estables los permisos de macOS ejecutando la app empaquetada desde la ruta normal de Applications.', 'Versión de publicación', 'Usa el paquete de la app desde /Applications para permisos de macOS más estables.'],
        ['02', 'Añade la API key de OpenAI', 'PasteVox guarda la clave en macOS Keychain y separa los ajustes del espacio de trabajo Home.', 'Dónde está', 'Settings → OpenAI → Save to Keychain'],
        ['03', 'Concede el micrófono', 'Permite grabar para que el modo «mantener para hablar» capture tu voz y la envíe a transcripción.', 'Permiso de macOS', 'Privacy & Security → Microphone'],
        ['04', 'Concede Accessibility', 'Necesario para atajos globales fiables y para pegar en la app de macOS en primer plano.', 'Permiso de macOS', 'Privacy & Security → Accessibility']
      ],
      ctaTitle: '¿Listo para probar PasteVox?',
      ctaCopy: 'El paquete descargable está en camino. Por ahora, compílalo desde el código o usa el paquete local de la app generado por los scripts del proyecto.',
      build: 'Compilar desde el código',
      top: 'Volver arriba'
    },
    footer: ['© PasteVox', 'Utilidad open-source nativa de macOS para voz y agentes de código.']
  },
  fr: {
    lang: 'fr',
    title: 'PasteVox — Parlez. Collez. Continuez.',
    description: 'PasteVox est un utilitaire macOS dans la barre de menus qui transforme votre voix en dictées, prompts pour agents de code, commandes de terminal, snippets et notes.',
    nav: { workflow: 'Flux', modes: 'Modes', features: 'Home', privacy: 'Confidentialité', setup: 'Installation', download: 'Télécharger', language: 'Langue' },
    hero: {
      eyebrow: 'utilitaire vocal macOS dans la barre de menus',
      title: ['Parlez.', 'Collez.', 'Continuez.'],
      copy: 'PasteVox transforme votre voix en dictées, prompts pour agents de code, commandes de terminal, snippets et notes — directement dans l’app macOS où vous travaillez déjà.',
      primary: 'Compiler depuis les sources',
      secondary: 'Voir l’installation',
      badges: ['macOS 13+', 'OpenAI STT', 'clé dans Keychain', 'sans Electron', 'open-source'],
      screenAlt: 'écran d’historique de PasteVox Home',
      hudAlt: 'HUD PasteVox en écoute'
    },
    proof: [
      ['Open-source', 'Inspectez le code, compilez localement et gardez un flux compréhensible.'],
      ['Natif macOS', 'Utilitaire de barre de menus construit avec Swift, SwiftUI et AppKit. Pas de shell Electron.'],
      ['Modes et styles', 'Fn ou la touche de maintien choisie change les modes et les styles d’écriture sans ouvrir les Réglages.'],
      ['Garde-fous', 'Les commandes de terminal risquées ne sont pas collées à l’aveugle.']
    ],
    workflow: {
      kicker: 'Flux',
      title: 'Votre voix, dans l’app active.',
      copy: 'Maintenez Fn, Option droit ou Command droit, parlez naturellement, et le texte se colle dans l’app active. PasteVox vit dans la barre de menus — les Réglages restent hors de vue tant que vous n’en avez pas besoin.',
      cards: [
        ['1', 'Maintenez la touche choisie', 'Démarrez l’enregistrement avec Fn/Globe, Option droit ou Command droit. Le HUD indique quand PasteVox écoute.'],
        ['2', 'Dictez la version brute', 'Parlez naturellement. Utilisez la dictée brute, les prompts d’agent, les prompts RALPH ou le mode commande terminal.'],
        ['3', 'Collez et continuez', 'PasteVox transcrit, reformule si besoin, développe les snippets et colle dans l’app au premier plan.']
      ]
    },
    modes: {
      kicker: 'Modes',
      title: 'Changez la forme du résultat sans ouvrir de fenêtre.',
      copy: 'Fn+1…4 change de mode. Fn+5…0 change le style pour les modes post-traités ; Fn+- choisit Email. La touche de maintien choisie fonctionne aussi.',
      cards: [
        { label: 'Mode 01', hotkey: 'Fn+1', title: 'Raw Dictation', copy: 'Transcription simple. Pas de reformulation. Les styles restent volontairement désactivés.', style: 'style désactivé', example: 'ce que vous avez dit, nettoyé seulement par la transcription' },
        { label: 'Mode 02', hotkey: 'Fn+2', title: 'Agent Prompt', copy: 'Transforme une parole brute en tâche claire pour un agent de code.', style: 'styles Fn+5…0', example: 'implémente ce changement d’interface, vérifie-le, puis lance l’app' },
        { label: 'Mode 03', hotkey: 'Fn+3', title: 'RALPH Prompt', copy: 'Prompt structuré avec rôle, objectif, contexte, contraintes et critères d’acceptation.', style: 'structuré', example: 'Role → Goal → Context → Constraints → Acceptance criteria' },
        { label: 'Mode 04', hotkey: 'Fn+4', title: 'Terminal Command', copy: 'Génère des commandes, mais bloque les sorties risquées et les affiche en aperçu commenté.', style: 'garde-fou', example: 'commande sûre, ou aperçu commenté si elle est destructive' }
      ],
      output: 'Résultat'
    },
    styles: {
      kicker: 'Styles d’écriture',
      title: 'Gardez le mode, changez le ton.',
      copy: 'Les styles sont des modificateurs rapides pour les modes post-traités. Passez de concis à amical, formel, orienté code, chat ou email sans ouvrir les Réglages. Raw Dictation reste brut.',
      hotkeys: ['Fn+5 Default', 'Fn+6 Concise', 'Fn+7 Friendly', 'Fn+8 Formal', 'Fn+9 Coding', 'Fn+0 Chat', 'Fn+- Email'],
      cards: [
        ['Exemple : Agent · Concise', 'Transforme une tâche dictée et brouillonne en instruction plus courte pour un agent de code, sans changer de mode.', true],
        ['Friendly', 'Pratique pour Slack, les réponses de chat et les notes produit plus légères.'],
        ['Formal', 'Pratique pour les emails, les revues et les formulations plus soignées.'],
        ['Coding', 'Oriente la reformulation vers des instructions d’implémentation précises.'],
        ['Pas de style en Raw', 'Raw Dictation ignore volontairement le style afin de rester une transcription non traitée.']
      ]
    },
    features: {
      kicker: 'Espace de travail',
      title: 'Historique, snippets, dictionnaire et bloc-notes dans une seule fenêtre Home.',
      copy: 'Home sert à récupérer et écrire. Les Réglages restent dédiés à la configuration et au débogage.',
      rows: [
        { kind: 'Historique', title: 'Un historique pour chaque collage.', copy: 'Retrouvez les dictées récentes, vérifiez l’app cible, voyez l’état de livraison et copiez ou collez à nouveau.', points: ['Résultats récents regroupés par jour', 'Statistiques de livraison et apps principales', 'Récupération rapide après un collage raté'], image: '/assets/screen-history.png', alt: 'tableau d’historique PasteVox' },
        { kind: 'Snippets', title: 'Des snippets sans attente.', copy: 'Dites un déclencheur court et PasteVox insère localement le remplacement exact, sans envoyer le snippet à un LLM.', points: ['Plusieurs phrases déclencheuses', 'Correspondance locale déterministe', 'Import et export JSON'], image: '/assets/screen-snippets.png', alt: 'écran des snippets PasteVox', reverse: true },
        { kind: 'Dictionnaire', title: 'Votre vocabulaire, bien orthographié.', copy: 'Ajoutez noms de projets, acronymes, emails et termes produit pour que les mots importants sortent correctement.', points: ['Noms, acronymes et graphies', 'Contexte pour la transcription', 'Utile pour les équipes et produits'], image: '/assets/screen-dictionary.png', alt: 'écran du dictionnaire PasteVox' },
        { kind: 'Bloc-notes', title: 'Un brouillon pour les idées brutes.', copy: 'Capturez d’abord les notes et prompts longs, puis copiez ou collez-les quand ils sont prêts.', points: ['Sauvegarder de longs brouillons dictés', 'Modifier avant de coller', 'Espace de travail séparé des Réglages'], image: '/assets/screen-scratchpad.png', alt: 'scratchpad PasteVox', reverse: true }
      ]
    },
    privacy: {
      kicker: 'Confidentialité et contrôle',
      title: 'Votre clé reste dans Keychain. Vos raccourcis restent locaux.',
      copy: 'PasteVox est pensé comme un petit utilitaire macOS open-source, pas comme une plateforme d’écriture hébergée.',
      posterKicker: 'Confidentialité, clairement',
      posterTitle: ['Pas de compte.', 'Pas de synchronisation.', 'Pas de surprise.'],
      posterCopy: 'Open-source et explicite sur les points sensibles : où vit la clé, quand l’audio est envoyé et ce qui reste sur votre Mac.',
      rows: [
        ['Clé API', 'sécurisée', 'Enregistrée dans Keychain.', 'Utilisée quand vous demandez à PasteVox de transcrire ou post-traiter. Elle n’est pas lue au simple démarrage de l’app.'],
        ['Snippets', 'local', 'Correspondance locale.', 'Les phrases déclencheuses s’étendent de façon déterministe sur votre Mac. Aucun appel modèle nécessaire.'],
        ['Historique', 'visible', 'Conservé pour récupérer.', 'Les résultats récents, apps cibles et statuts restent dans Home pour récupérer un collage échoué.'],
        ['Commandes', 'protégées', 'Vérifiées avant exécution.', 'Les commandes terminal risquées sont stoppées et affichées en commentaires au lieu d’être collées à l’aveugle.']
      ]
    },
    setup: {
      kicker: 'Installation',
      title: 'Un parcours de permissions macOS concret.',
      copy: 'Installez dans',
      copyTail: 'pour stabiliser les permissions Accessibility, puis accordez les droits nécessaires à l’enregistrement et au collage.',
      steps: [
        ['01', 'Installer dans /Applications', 'Gardez les permissions macOS stables en lançant l’app empaquetée depuis le chemin Applications habituel.', 'Version de publication', 'Utilisez l’app empaquetée depuis /Applications pour des permissions macOS plus stables.'],
        ['02', 'Ajouter la clé API OpenAI', 'PasteVox stocke la clé dans macOS Keychain et garde les Réglages séparés de l’espace de travail Home.', 'Où aller', 'Settings → OpenAI → Save to Keychain'],
        ['03', 'Autoriser Microphone', 'Autorisez l’enregistrement pour que le maintien-pour-parler capture la voix et l’envoie à la transcription.', 'Permission macOS', 'Privacy & Security → Microphone'],
        ['04', 'Autoriser Accessibility', 'Nécessaire pour des raccourcis globaux fiables et pour coller dans l’app macOS au premier plan.', 'Permission macOS', 'Privacy & Security → Accessibility']
      ],
      ctaTitle: 'Prêt à essayer PasteVox ?',
      ctaCopy: 'Le paquet téléchargeable arrive. Pour l’instant, compilez depuis les sources ou utilisez l’app empaquetée locale générée par les scripts du projet.',
      build: 'Compiler depuis les sources',
      top: 'Retour en haut'
    },
    footer: ['© PasteVox', 'Utilitaire macOS natif open-source pour la voix et les agents de code.']
  },
  de: {
    lang: 'de',
    title: 'PasteVox — Sprich. Füge ein. Mach weiter.',
    description: 'PasteVox ist ein macOS-Menüleisten-Tool, das Sprache in Diktat, Prompts für Coding-Agents, Terminalbefehle, Snippets und Notizen verwandelt.',
    nav: { workflow: 'Ablauf', modes: 'Modi', features: 'Home', privacy: 'Datenschutz', setup: 'Einrichtung', download: 'Download', language: 'Sprache' },
    hero: {
      eyebrow: 'Sprach-Tool für die macOS-Menüleiste',
      title: ['Sprich.', 'Füge ein.', 'Mach weiter.'],
      copy: 'PasteVox verwandelt deine Stimme in Diktat, Prompts für Coding-Agents, Terminalbefehle, Snippets und Notizen — direkt in der macOS-App, in der du gerade arbeitest.',
      primary: 'Aus Quellcode bauen',
      secondary: 'Einrichtung ansehen',
      badges: ['macOS 13+', 'OpenAI STT', 'Keychain-Schlüssel', 'kein Electron', 'open-source'],
      screenAlt: 'PasteVox Home-Verlauf',
      hudAlt: 'PasteVox HUD beim Zuhören'
    },
    proof: [
      ['Open-source', 'Code prüfen, lokal bauen und nachvollziehbar behalten, was passiert.'],
      ['Natives macOS', 'Menüleisten-Tool mit Swift, SwiftUI und AppKit. Keine Electron-Hülle.'],
      ['Modi & Stile', 'Fn oder die gewählte Haltetaste wechselt Modi und Schreibstile, ohne die Einstellungen zu öffnen.'],
      ['Sicherheitsgrenzen', 'Riskante Terminalbefehle werden nicht blind eingefügt.']
    ],
    workflow: {
      kicker: 'Ablauf',
      title: 'Deine Stimme — in der aktiven App.',
      copy: 'Halte Fn, rechte Option oder rechte Command-Taste, sprich natürlich — und es landet in der aktiven App. PasteVox lebt in der Menüleiste, die Einstellungen bleiben aus dem Weg, bis du sie brauchst.',
      cards: [
        ['1', 'Halte deine gewählte Taste', 'Starte die Aufnahme mit Fn/Globe, rechter Option oder rechter Command-Taste. Das HUD zeigt an, wann PasteVox zuhört.'],
        ['2', 'Sprich die Rohfassung', 'Diktiere natürlich. Nutze Raw Dictation, Agent Prompts, RALPH Prompts oder den Terminal-Command-Modus.'],
        ['3', 'Einfügen und weiter', 'PasteVox transkribiert, schreibt optional um, erweitert Snippets und fügt in die vorderste App ein.']
      ]
    },
    modes: {
      kicker: 'Modi',
      title: 'Ändere die Ausgabeform, ohne ein Fenster zu öffnen.',
      copy: 'Fn+1…4 wechselt Modi. Fn+5…0 wechselt Schreibstile für nachbearbeitete Modi; Fn+- wählt Email. Die gewählte Haltetaste funktioniert ebenfalls.',
      cards: [
        { label: 'Modus 01', hotkey: 'Fn+1', title: 'Raw Dictation', copy: 'Reine Transkription. Kein Umschreiben. Stile bleiben bewusst aus.', style: 'Stil aus', example: 'genau das Gesagte, nur durch die Transkription bereinigt' },
        { label: 'Modus 02', hotkey: 'Fn+2', title: 'Agent Prompt', copy: 'Macht aus grober Sprache eine klare Aufgabe für einen Coding-Agent.', style: 'Fn+5…0 Stile', example: 'setze diese UI-Änderung um, prüfe sie und starte die App' },
        { label: 'Modus 03', hotkey: 'Fn+3', title: 'RALPH Prompt', copy: 'Strukturierter Prompt mit Rolle, Ziel, Kontext, Einschränkungen und Akzeptanzkriterien.', style: 'strukturiert', example: 'Role → Goal → Context → Constraints → Acceptance criteria' },
        { label: 'Modus 04', hotkey: 'Fn+4', title: 'Terminal Command', copy: 'Erzeugt Befehle, blockiert aber riskante Ausgaben und zeigt sie als kommentierte Vorschau.', style: 'Sicherheitscheck', example: 'sicherer Befehl oder kommentierte Vorschau, wenn destruktiv' }
      ],
      output: 'Ausgabe'
    },
    styles: {
      kicker: 'Schreibstile',
      title: 'Modus behalten, Ton ändern.',
      copy: 'Stile sind schnelle Modifikatoren für nachbearbeitete Modi. Wechsle zwischen knapp, freundlich, formal, coding-orientiert, Chat oder Email, ohne die Einstellungen zu öffnen. Raw Dictation bleibt roh.',
      hotkeys: ['Fn+5 Default', 'Fn+6 Concise', 'Fn+7 Friendly', 'Fn+8 Formal', 'Fn+9 Coding', 'Fn+0 Chat', 'Fn+- Email'],
      cards: [
        ['Beispiel: Agent · Concise', 'Verdichtet eine grobe gesprochene Aufgabe zu einer kürzeren Anweisung für einen Coding-Agent, ohne den Modus zu wechseln.', true],
        ['Friendly', 'Gut für Slack, Chat-Antworten und lockerere Produktnotizen.'],
        ['Formal', 'Gut für E-Mails, Reviews und sorgfältigere Formulierungen.'],
        ['Coding', 'Lenkt das Umschreiben auf präzise Implementierungsanweisungen.'],
        ['Kein Stil in Raw', 'Raw Dictation ignoriert den Stil bewusst, damit die Transkription unverarbeitet bleibt.']
      ]
    },
    features: {
      kicker: 'Arbeitsbereich',
      title: 'Verlauf, Snippets, Wörterbuch und Notizfeld in einem Home-Fenster.',
      copy: 'Home ist für Wiederherstellung und Schreiben da. Die Einstellungen sind für Konfiguration und Fehlersuche.',
      rows: [
        { kind: 'Verlauf', title: 'Verlauf für jedes Einfügen.', copy: 'Hole aktuelle Diktate zurück, prüfe die Ziel-App, sieh den Lieferstatus und kopiere oder füge erneut ein.', points: ['Aktuelle Ausgaben nach Tagen gruppiert', 'Lieferstatistiken und wichtigste Apps', 'Schnelle Wiederherstellung nach fehlgeschlagenem Einfügen'], image: '/assets/screen-history.png', alt: 'PasteVox Verlaufs-Dashboard' },
        { kind: 'Snippets', title: 'Snippets ohne Wartezeit.', copy: 'Sag einen kurzen Auslöser und PasteVox fügt lokal die exakte Ersetzung ein, ohne das Snippet an ein LLM zu senden.', points: ['Mehrere Auslösephrasen', 'Deterministisches lokales Matching', 'JSON-Import und -Export'], image: '/assets/screen-snippets.png', alt: 'PasteVox Snippets-Ansicht', reverse: true },
        { kind: 'Wörterbuch', title: 'Dein Vokabular, richtig geschrieben.', copy: 'Füge Projektnamen, Akronyme, E-Mails und Produktbegriffe hinzu, damit wichtige Wörter korrekt erkannt werden.', points: ['Namen, Akronyme und Schreibweisen', 'Kontext für Transkription', 'Nützlich für Teams und Produkte'], image: '/assets/screen-dictionary.png', alt: 'PasteVox Wörterbuch-Ansicht' },
        { kind: 'Notizfeld', title: 'Ein Notizfeld für rohe Gedanken.', copy: 'Sammle längere Notizen und Prompts zuerst hier und kopiere oder füge sie ein, wenn sie bereit sind.', points: ['Längere diktierte Entwürfe speichern', 'Vor dem Einfügen bearbeiten', 'Arbeitsbereich getrennt von den Einstellungen'], image: '/assets/screen-scratchpad.png', alt: 'PasteVox Scratchpad', reverse: true }
      ]
    },
    privacy: {
      kicker: 'Datenschutz & Kontrolle',
      title: 'Dein Schlüssel bleibt in Keychain. Deine Kurzbefehle bleiben lokal.',
      copy: 'PasteVox ist als kleines open-source macOS-Tool gedacht, nicht als gehostete Schreibplattform.',
      posterKicker: 'Datenschutz, klar gesagt',
      posterTitle: ['Kein Konto.', 'Keine Synchronisierung.', 'Keine Überraschungen.'],
      posterCopy: 'Open-source und klar bei sensiblen Teilen: wo der Schlüssel liegt, wann Audio gesendet wird und was auf deinem Mac bleibt.',
      rows: [
        ['API-Schlüssel', 'gesichert', 'In Keychain gespeichert.', 'Wird genutzt, wenn PasteVox transkribieren oder nachbearbeiten soll. Nicht schon beim Start der App gelesen.'],
        ['Snippets', 'lokal', 'Lokal abgeglichen.', 'Auslösephrasen werden deterministisch auf deinem Mac erweitert. Kein Modellaufruf nötig.'],
        ['Verlauf', 'sichtbar', 'Zur Wiederherstellung behalten.', 'Aktuelle Ausgaben, Ziel-Apps und Status bleiben in Home, damit ein fehlgeschlagenes Einfügen wiederherstellbar ist.'],
        ['Befehle', 'geprüft', 'Vor Gefahr geprüft.', 'Riskante Terminalbefehle werden gestoppt und als Kommentare gezeigt, statt blind eingefügt zu werden.']
      ]
    },
    setup: {
      kicker: 'Einrichtung',
      title: 'Ein praktischer Ablauf für macOS-Berechtigungen.',
      copy: 'Installiere in',
      copyTail: 'für stabile Accessibility-Berechtigungen und gib danach die Rechte frei, die PasteVox zum Aufnehmen und Einfügen braucht.',
      steps: [
        ['01', 'Nach /Applications installieren', 'Halte macOS-Berechtigungen stabil, indem du die gepackte App aus dem normalen Applications-Pfad startest.', 'Release-Build', 'Nutze das App-Bundle aus /Applications für stabilere macOS-Berechtigungen.'],
        ['02', 'OpenAI API key hinzufügen', 'PasteVox speichert den Schlüssel in macOS Keychain und trennt die Einstellungen vom Home-Arbeitsbereich.', 'Wo es ist', 'Settings → OpenAI → Save to Keychain'],
        ['03', 'Microphone erlauben', 'Erlaube Aufnahmen, damit „Halten und sprechen“ die Stimme erfassen und zur Transkription senden kann.', 'macOS-Berechtigung', 'Privacy & Security → Microphone'],
        ['04', 'Accessibility erlauben', 'Nötig für zuverlässige globale Kurzbefehle und das Einfügen in die vorderste macOS-App.', 'macOS-Berechtigung', 'Privacy & Security → Accessibility']
      ],
      ctaTitle: 'Bereit, PasteVox auszuprobieren?',
      ctaCopy: 'Das Download-Paket ist in Arbeit. Bis dahin kannst du aus dem Quellcode bauen oder das lokale App-Bundle aus den Projektskripten nutzen.',
      build: 'Aus Quellcode bauen',
      top: 'Nach oben'
    },
    footer: ['© PasteVox', 'Open-source natives macOS-Tool für Sprache und Coding-Agents.']
  }
} as const;
