import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { randomUUID } from 'node:crypto';

const runId = randomUUID();
const startedAt = Date.now();
const log = (level, message) => {
  console.log(`[${new Date().toISOString()}] run_id=${runId} level=${level} ${message}`);
};

const locales = [
  { code: 'en', path: 'index.html', required: ['Speak.', 'Language', 'Open-source native macOS voice-to-agent utility.'] },
  { code: 'ru', path: 'ru/index.html', required: ['Скажи.', 'Язык', 'Без аккаунта.'] },
  { code: 'es', path: 'es/index.html', required: ['Habla.', 'Idioma', 'Sin cuenta.'] },
  { code: 'fr', path: 'fr/index.html', required: ['Parlez.', 'Langue', 'Pas de compte.'] },
  { code: 'de', path: 'de/index.html', required: ['Sprich.', 'Sprache', 'Kein Konto.'] }
];

const forbiddenEnglish = [
  'Speak. Paste. Keep moving.',
  'Hold Fn, Right Option or Right Command, speak naturally',
  'Ready to try PasteVox?',
  'Privacy &amp; control',
  'Practical macOS permissions, step by step.',
  'Build from source'
];

log('info', 'startup script=validate-i18n purpose=static_locale_smoke_check');

for (const locale of locales) {
  const filePath = join('dist', locale.path);
  if (!existsSync(filePath)) {
    log('error', `missing_route locale=${locale.code} path=${filePath}`);
    process.exit(1);
  }

  const html = readFileSync(filePath, 'utf8');
  for (const expected of locale.required) {
    if (!html.includes(expected)) {
      log('error', `missing_expected_copy locale=${locale.code} expected=${JSON.stringify(expected)}`);
      process.exit(1);
    }
  }

  for (const alternate of locales) {
    const expectedHref = alternate.code === 'en' ? '/' : `/${alternate.code}/`;
    const expectedTag = `hreflang="${alternate.code}" href="https://pastevox.app${expectedHref}"`;
    if (!html.includes(expectedTag)) {
      log('error', `missing_hreflang locale=${locale.code} expected=${expectedTag}`);
      process.exit(1);
    }
  }

  if (locale.code !== 'en') {
    for (const phrase of forbiddenEnglish) {
      if (html.includes(phrase)) {
        log('error', `untranslated_english_phrase locale=${locale.code} phrase=${JSON.stringify(phrase)}`);
        process.exit(1);
      }
    }
  }

  log('info', `validated locale=${locale.code} path=${filePath}`);
}

log('info', 'manual_review_note=translations_were_written_as_locale_adapted_marketing_copy_not_word_for_word_en_mirror');
log('info', `summary status=success duration_ms=${Date.now() - startedAt} locales=${locales.length}`);
