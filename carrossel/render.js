// Gera os slides (PNG 1080x1440) do carrossel no estilo azul-marinho e dourado.
// Uso: node carrossel/render.js <slides.json> <pasta-de-saida>
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const [, , inputFile, outDir] = process.argv;
if (!inputFile || !outDir) {
  console.error('Uso: node carrossel/render.js <slides.json> <pasta-de-saida>');
  process.exit(1);
}

// Fontes Lora (baixadas na primeira execução)
const fontDir = path.join(__dirname, '.fonts');
function ensureFonts() {
  const marker = path.join(fontDir, 'fonts.css');
  if (fs.existsSync(marker)) return fs.readFileSync(marker, 'utf8');
  fs.mkdirSync(fontDir, { recursive: true });
  const css = execFileSync('curl', ['-sS', '-m', '30',
    'https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400;0,600;1,400;1,600&display=swap'],
    { encoding: 'utf8' });
  let out = '';
  for (const m of css.matchAll(/@font-face \{([\s\S]*?)\}/g)) {
    const b = m[1];
    const url = /url\((.*?)\)/.exec(b)[1];
    const style = /font-style: (\w+)/.exec(b)[1];
    const weight = /font-weight: (\d+)/.exec(b)[1];
    const fn = `lora-${style}-${weight}.ttf`;
    execFileSync('curl', ['-sS', '-m', '60', '-o', path.join(fontDir, fn), url]);
    out += `@font-face{font-family:'LoraL';font-style:${style};font-weight:${weight};src:url('file://${fontDir}/${fn}');}\n`;
  }
  fs.writeFileSync(marker, out);
  return out;
}

const data = JSON.parse(fs.readFileSync(inputFile, 'utf8'));
const footer = data.footer || 'EVANDRO FERNANDES &nbsp;·&nbsp; PSICANALISTA CLÍNICO';
const slides = data.slides;
const total = slides.length;

const block = (b) => {
  switch (b.type) {
    case 'orn': return '<div class="orn"></div>';
    case 'box': {
      const icon = b.icon === 'send'
        ? '<path fill="#d4a853" d="M2 12 22 3l-5 18-5-7z"/>'
        : '<path fill="#d4a853" d="M6 2h12v20l-6-5-6 5z"/>';
      return `<div class="box"><svg viewBox="0 0 24 24" width="60" height="60">${icon}</svg><div><b>${b.title}</b><span>${b.html}</span></div></div>`;
    }
    default: return `<p class="${b.type}">${b.html}</p>`;
  }
};

const render = (s, i, fontsCss) => {
  const cover = s.kind === 'cover';
  const right = s.right || (cover ? 'ARRASTE →' : `${String(i + 1).padStart(2, '0')} / ${String(total).padStart(2, '0')}`);
  let body = s.blocks.map(block).join('');
  if (s.kind === 'quote') body = `<div class="qm">“</div>` + body;
  if (s.kind === 'cta') body = body.replace(/(<div class="box">[\s\S]*<\/div>)$/, '<div class="boxes">$1</div>');
  return `<!doctype html><html><head><meta charset="utf-8"><style>
${fontsCss}
*{margin:0;padding:0;box-sizing:border-box}
body{width:1080px;height:1440px;background:radial-gradient(ellipse at 50% 45%,#12294f 0%,#0a1630 45%,#050d22 100%);font-family:'LoraL',serif;color:#f5efe6;position:relative;overflow:hidden}
.frame{position:absolute;inset:44px;border:1.5px solid rgba(212,168,83,.45)}
.c{position:absolute;width:48px;height:48px;border:4px solid #d4a853}
.c.tl{left:42px;top:42px;border-right:0;border-bottom:0}.c.tr{right:42px;top:42px;border-left:0;border-bottom:0}
.c.bl{left:42px;bottom:42px;border-right:0;border-top:0}.c.br{right:42px;bottom:42px;border-left:0;border-top:0}
.top{position:absolute;top:118px;width:100%;text-align:center;font:600 24px 'Inter',sans-serif;letter-spacing:7px;color:#d4a853}
.tl2{position:absolute;top:158px;left:450px;width:180px;height:30px}
.tl2:before,.tl2:after{content:"";position:absolute;top:14px;width:72px;height:1.5px;background:#d4a853}.tl2:before{left:0}.tl2:after{right:0}
.tl2 i{position:absolute;left:84px;top:7px;width:13px;height:13px;background:#d4a853;transform:rotate(45deg)}
.main{position:absolute;left:100px;right:100px;top:300px;bottom:230px;display:flex;flex-direction:column;justify-content:center;align-items:center;text-align:center;gap:34px}
.main.cover{top:380px}
.h1{font-size:76px;line-height:1.28;font-weight:400}.h2{font-size:56px;line-height:1.3;font-weight:400}
.p{font-size:46px;line-height:1.35}.s{font-size:38px;line-height:1.45;color:#8f9bb8}
.big{font-size:110px;line-height:1.15}.q{font-size:70px}
.g{color:#d4a853;font-weight:600;font-style:normal}i.g{font-style:italic;font-weight:600}
.s i{color:#8f9bb8}
.orn{position:relative;width:100px;height:2px;background:#d4a853;margin:6px 0}.orn:after{content:"";position:absolute;left:44px;top:-6px;width:12px;height:12px;background:#d4a853;transform:rotate(45deg)}
.foot{position:absolute;left:110px;right:110px;top:1312px;height:64px;border-top:1.5px solid #d4a853;display:flex;justify-content:space-between;align-items:center;font:500 21px 'Inter',sans-serif;letter-spacing:3px;color:#9aa6c4}
.foot .r{color:#d4a853;font-weight:600;letter-spacing:2px}
.rings{position:absolute;right:-160px;top:-110px;width:640px;height:640px}
.rings div{position:absolute;border:1.5px solid rgba(212,168,83,.28);border-radius:50%}
.qm{font-size:230px;line-height:.6;color:#d4a853;font-weight:600;margin-bottom:10px}
.boxes{width:100%;margin-top:40px;display:flex;flex-direction:column;gap:30px}
.box{display:flex;align-items:center;gap:36px;border:2.5px solid #d4a853;border-radius:34px;padding:34px 44px;background:#071329;text-align:left}
.box b{display:block;font:700 34px 'Inter',sans-serif;color:#d4a853;margin-bottom:8px;letter-spacing:1px}
.box span{font-size:36px;line-height:1.35}
</style></head><body>
<div class="frame"></div><div class="c tl"></div><div class="c tr"></div><div class="c bl"></div><div class="c br"></div>
${cover ? '<div class="rings"><div style="inset:0"></div><div style="inset:100px"></div><div style="inset:200px"></div></div>' : ''}
<div class="top">${s.label}</div>${cover ? '' : '<div class="tl2"><i></i></div>'}
<div class="main ${cover ? 'cover' : ''}">${body}</div>
<div class="foot"><span>${footer}</span><span class="r">${right}</span></div>
</body></html>`;
};

(async () => {
  const fontsCss = ensureFonts();
  fs.mkdirSync(outDir, { recursive: true });
  const tmp = fs.mkdtempSync('/tmp/carrossel-');
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1080, height: 1440 }, deviceScaleFactor: 1 });
  for (let i = 0; i < total; i++) {
    const f = path.join(tmp, `s${i + 1}.html`);
    fs.writeFileSync(f, render(slides[i], i, fontsCss));
    await p.goto('file://' + f);
    await p.evaluate(() => document.fonts.ready);
    await p.screenshot({ path: path.join(outDir, `slide-${String(i + 1).padStart(2, '0')}.png`) });
  }
  await b.close();
  console.log(`ok: ${total} slides em ${outDir}`);
})();
