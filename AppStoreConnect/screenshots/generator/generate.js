// Render localized App Store screenshots for Habit Core (1260x2736, 6.9" iPhone) with a real
// device frame, via headless Google Chrome (same pipeline as WalletLog).
// Inputs: ../raw/<screen>_<lang>.png (simulator captures, 1320x2868) and
//         ../raw/widget_{small,medium_all,medium_single}_<lang>.png (ImageRenderer, 3x).
// Usage: node generate.js [lang] [screen]
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const DIR = __dirname;
const frame = path.join(DIR, 'frames', 'iphone16promax_black.png');
const rawDir = path.join(DIR, '..', 'raw');
const outDir = path.join(DIR, '..', 'final');
fs.mkdirSync(outDir, { recursive: true });

const fileURL = (p) => 'file://' + encodeURI(p);
const tpl = fs.readFileSync(path.join(DIR, 'template.html'), 'utf8');
const tplWidgets = fs.readFileSync(path.join(DIR, 'template_widgets.html'), 'utf8');

const order = ['focus', 'tracker', 'allhabits', 'add', 'widgets'];
const a = (s) => `<span class="accent">${s}</span>`;
const captions = {
  en: {
    focus:     `Daily habits,<br>${a('one tap away')}`,
    tracker:   `See your<br>${a('progress grow')}`,
    allhabits: `All habits,<br>${a('one grid')}`,
    add:       `Daily, weekly<br>${a('or every N days')}`,
    widgets:   `Your progress<br>${a('on the Home Screen')}`,
  },
  pl: {
    focus:     `Codzienne nawyki,<br>${a('jedno dotknięcie')}`,
    tracker:   `Zobacz swój<br>${a('postęp')}`,
    allhabits: `Wszystkie nawyki,<br>${a('jedna siatka')}`,
    add:       `Codziennie, co tydzień<br>${a('lub co N dni')}`,
    widgets:   `Postępy<br>${a('na ekranie głównym')}`,
  },
};
// Longer captions get a smaller font so they stay on two lines.
const fontSize = (html) => (html.replace(/<[^>]+>/g, '\n').split('\n').some((l) => l.length > 17) ? 96 : 112);

const render = (html, out) => {
  const tmp = path.join(DIR, '_render.html');
  fs.writeFileSync(tmp, html);
  execFileSync(CHROME, [
    '--headless=new', '--disable-gpu', '--hide-scrollbars', '--no-sandbox',
    '--force-device-scale-factor=1', '--window-size=1260,2736',
    '--screenshot=' + out, fileURL(tmp),
  ], { stdio: 'ignore' });
  fs.unlinkSync(tmp);
  console.log('Rendered ' + out);
};

const langArg = process.argv[2];
const screenArg = process.argv[3];
const langs = langArg ? [langArg] : Object.keys(captions);

langs.forEach((lang) => {
  order.forEach((screen, i) => {
    if (screenArg && screen !== screenArg) return;
    const caption = captions[lang][screen];
    const out = path.join(outDir, `${String(i + 1).padStart(2, '0')}_${screen}_${lang}.png`);
    let html;
    if (screen === 'widgets') {
      html = tplWidgets
        .replace('{{WIDGET_MEDIUM_ALL}}', fileURL(path.join(rawDir, `widget_medium_all_${lang}.png`)))
        .replace('{{WIDGET_MEDIUM_SINGLE}}', fileURL(path.join(rawDir, `widget_medium_single_${lang}.png`)))
        .replace('{{WIDGET_SMALL}}', fileURL(path.join(rawDir, `widget_small_${lang}.png`)));
    } else {
      html = tpl
        .replace('{{SCREENSHOT}}', fileURL(path.join(rawDir, `${screen}_${lang}.png`)))
        .replace('{{FRAME}}', fileURL(frame));
    }
    render(html.replace('{{CAPTION}}', caption).replace('{{FONT_SIZE}}', fontSize(caption)), out);
  });
});
