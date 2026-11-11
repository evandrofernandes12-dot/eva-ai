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

const n = data.slides.length;
const dur = data.segundos || Array(n).fill(5);
const T = 0.6; // duração da transição
const args = ['-y', '-loglevel', 'error'];
for (let i = 0; i < n; i++) {
  args.push('-loop', '1', '-t', String(dur[i] + T), '-i', path.join(dir, `slide-${String(i + 1).padStart(2, '0')}.png`));
}
args.push('-f', 'lavfi', '-i', 'anullsrc=channel_layout=stereo:sample_rate=44100');
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
const total = dur.reduce((a, b) => a + b, 0);
args.push('-filter_complex', filter, '-map', '[vout]', '-map', `${n}:a`, '-t', String(total),
  '-c:v', 'libx264', '-profile:v', 'high', '-pix_fmt', 'yuv420p', '-r', '30', '-crf', '23', '-preset', 'medium',
  '-c:a', 'aac', '-b:a', '96k', '-shortest', '-movflags', '+faststart', output);
execFileSync('ffmpeg', args, { stdio: ['ignore', 'ignore', 'inherit'] });
console.log(`ok: ${output} (${total}s)`);
