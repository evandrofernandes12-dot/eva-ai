// Confere se carrossel, stories e reel do dia são do MESMO tema e se o banner 3 do story da manhã cita o tema certo.
// Uso: node carrossel/conferir.js <carrossel.json> <story-manha.json> <story-noite.json> [reel.json]
const fs = require('fs');
const [, , carrossel, manha, noite, reel] = process.argv;
if (!carrossel || !manha || !noite) { console.error('Uso: node carrossel/conferir.js <carrossel.json> <story-manha.json> <story-noite.json> [reel.json]'); process.exit(1); }
const ler = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const arqs = { carrossel, 'story-manha': manha, 'story-noite': noite, ...(reel ? { reel } : {}) };
const dados = Object.fromEntries(Object.entries(arqs).map(([k, f]) => [k, ler(f)]));
const erros = [];
const tema = (dados.carrossel.tema || '').trim().toLowerCase();
if (!tema) erros.push('carrossel sem o campo "tema"');
for (const [k, d] of Object.entries(dados)) {
  if ((d.tema || '').trim().toLowerCase() !== tema) erros.push(`${k}: tema "${d.tema}" diferente do carrossel "${dados.carrossel.tema}"`);
}
const m = dados['story-manha'];
const b3 = JSON.stringify(m.slides[m.slides.length - 1]);
if (!/HOJE NO FEED/i.test(b3)) erros.push('story da manhã: o último banner deve ter o rótulo "HOJE NO FEED"');
if (!b3.includes('{{tema}}')) erros.push('story da manhã: o banner "HOJE NO FEED" deve usar {{tema}}, e não um tema escrito à mão');
for (const [k, d] of Object.entries(dados)) {
  const texto = JSON.stringify(d.slides);
  if (/falso self/i.test(texto) && !/falso self/.test(tema)) erros.push(`${k}: cita "falso self" mas o tema do dia é "${dados.carrossel.tema}" (texto sobrando de exemplo?)`);
}
if (erros.length) { console.error('PROBLEMAS:\n- ' + erros.join('\n- ')); process.exit(1); }
console.log(`ok: tudo no tema "${dados.carrossel.tema}"`);
