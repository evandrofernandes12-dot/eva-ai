// Gera um Reel (mp4 1080x1920, sem áudio) com transições suaves entre cenas.
// Uso: node carrossel/reel.js <reel.json> <arquivo-saida.mp4>
// O reel.json é igual ao de stories (format: "vertical") e aceita "segundos": [duração de cada cena].
const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFileSync } = require('child_process');

const [, , input, output] = process.argv;
if (!input || !output) { console.error('Uso: node carrossel/reel.js <reel.json> <saida.mp4>'); process.exit(1); }

const data = JSON.parse(fs.readFileSync(input, 'utf8'));
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'reel-'));
execFileSync('node', [path.join(__dirname, 'render.js'), input, dir], { stdio: 'inherit' });

const { gerarMusica, gerarMusicaMelodica } = require('./musica');
const n = data.slides.length;
const dur = data.segundos || Array(n).fill(5);
const T = 0.6; // duração da transição
const args = ['-y', '-loglevel', 'error'];
for (let i = 0; i < n; i++) {
  args.push('-loop', '1', '-t', String(dur[i] + T), '-i', path.join(dir, `slide-${String(i + 1).padStart(2, '0')}.png`));
}
const total = dur.reduce((a, b) => a + b, 0);
const clima = data.musica === undefined ? 'reflexivo' : data.musica; // "reflexivo", "esperanca" ou "nenhuma"
if (clima === 'nenhuma') {
  args.push('-f', 'lavfi', '-i', 'anullsrc=channel_layout=stereo:sample_rate=44100');
} else {
  const wav = path.join(dir, 'trilha.wav');
  (data.estilo === 'calmo' ? gerarMusica : gerarMusicaMelodica)(wav, total, clima);
  args.push('-i', wav);
}
let filter = '';
for (let i = 0; i < n; i++) filter += `[${i}:v]scale=1080:1920,setsar=1,fps=30,format=yuv420p[v${i}];`;
let last = 'v0', acc = 0;
for (let i = 1; i < n; i++) {
  acc += dur[i - 1];
  const out = i === n - 1 ? 'vout' : `x${i}`;
  filter += `[${last}][v${i}]xfade=transition=fade:duration=${T}:offset=${(acc - 0.0).toFixed(2)}[${out}];`;
  last = out;
}
filter = filter.replace(/;$/, '');
args.push('-filter_complex', filter + (clima === 'nenhuma' ? '' : `;[${n}:a]aecho=0.8:0.65:60|130|190:0.3|0.2|0.1,lowpass=f=6500,volume=0.9,afade=t=in:st=0:d=1.5,afade=t=out:st=${Math.max(0, total - 3)}:d=3[aout]`), '-map', '[vout]', '-map', clima === 'nenhuma' ? `${n}:a` : '[aout]', '-t', String(total),
  '-c:v', 'libx264', '-profile:v', 'high', '-pix_fmt', 'yuv420p', '-r', '30', '-crf', '23', '-preset', 'medium',
  '-c:a', 'aac', '-b:a', '96k', '-shortest', '-movflags', '+faststart', output);
execFileSync('ffmpeg', args, { stdio: ['ignore', 'ignore', 'inherit'] });
console.log(`ok: ${output} (${total}s)`);
