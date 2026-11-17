// Rebaixa os modelos listados em public/assets/MANIFEST.json direto do GitHub (raw URLs) se algum arquivo estiver faltando.
// (as texturas PBR foram redimensionadas localmente para 1024px e ficam versionadas no projeto)
// Uso: node scripts/fetch-world-assets.mjs [--force]
import fs from 'node:fs';
import path from 'node:path';
const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '../public');
const m = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/MANIFEST.json'), 'utf8')), force = process.argv.includes('--force');
let ok = 0, skipped = 0;
for (const a of m.assets) {
  if (a.category === 'texture') continue;
  const dest = path.join(ROOT, a.path);
  if (!force && fs.existsSync(dest) && fs.statSync(dest).size > 10 * 1024) { skipped++; continue; }
  const url = `https://raw.githubusercontent.com/${a.source.github}/HEAD/${a.source.file}`;
  const r = await fetch(url); if (!r.ok) { console.error('FALHOU', r.status, url); process.exitCode = 1; continue; }
  const buf = Buffer.from(await r.arrayBuffer()); if (buf.length < 10 * 1024) { console.error('arquivo suspeito (<10KB):', url); process.exitCode = 1; continue; }
  fs.mkdirSync(path.dirname(dest), { recursive: true }); fs.writeFileSync(dest, buf); ok++; console.log('baixado', a.path);
}
console.log(`pronto: ${ok} baixados, ${skipped} já existiam`);
