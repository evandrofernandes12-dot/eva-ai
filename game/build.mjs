// Monta o jogo em game/dist/ (index.html único + three.min.js + arquivos do PWA).
// Uso: node game/build.mjs   (na Vercel: Build Command "node game/build.mjs", Output Directory "game/dist")
import fs from 'node:fs';
import path from 'node:path';
const D = path.dirname(new URL(import.meta.url).pathname), rd = (f) => fs.readFileSync(path.join(D, f), 'utf8');
const OUT = path.join(D, 'dist');
fs.rmSync(OUT, { recursive: true, force: true }); fs.mkdirSync(OUT, { recursive: true });
let main = rd('main.js');
for (const k of ['NATDATA', 'KITDATA']) { const mark = `/*@@${k}*/`; if (!main.includes(mark)) throw new Error('marcador ausente: ' + mark); main = main.replace(mark, () => rd(`data/${k.toLowerCase()}.js`)); }
const html = rd('head.html') + '<script>' + rd('data/chars.js') + '</script>\n<script>' + rd('data/anims.js') + '</script>\n<script>' + main + '</script>\n</html>';
fs.writeFileSync(path.join(OUT, 'index.html'), html);
fs.cpSync(path.join(D, 'pwa'), OUT, { recursive: true });
console.log('game/dist/index.html', (html.length / 1e6).toFixed(2) + ' M caracteres');
