// Gera um story em vídeo (mp4 1080x1920) com 1 ou mais banners que passam um para o outro, com trilha instrumental.
// Uso: node carrossel/story-video.js <story.json> <saida.mp4>
// story.json: igual ao dos slides (format "vertical"); "segundos": [duração de cada banner] (padrão 6 s cada, 1º banner 6 e os demais 8).
const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFileSync } = require('child_process');
const { gerarMusica, gerarMusicaMelodica } = require('./musica');

const [, , input, output] = process.argv;
if (!input || !output) { console.error('Uso: node carrossel/story-video.js <story.json> <saida.mp4>'); process.exit(1); }
const data = JSON.parse(fs.readFileSync(input, 'utf8'));
const n = data.slides.length;
const dur = data.segundos || data.slides.map((_, i) => (i === 0 ? 6 : 8));
const T = 0.9; // transição entre banners
const total = dur.reduce((a, b) => a + b, 0);
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'story-'));
execFileSync('node', [path.join(__dirname, 'render.js'), input, dir], { stdio: 'inherit' });

const clima = data.musica === undefined ? 'reflexivo' : data.musica;
const args = ['-y', '-loglevel', 'error'];
for (let i = 0; i < n; i++) args.push('-i', path.join(dir, `slide-${String(i + 1).padStart(2, '0')}.png`));
if (clima === 'nenhuma') {
  args.push('-f', 'lavfi', '-i', 'anullsrc=channel_layout=stereo:sample_rate=44100');
} else {
  const wav = path.join(dir, 'trilha.wav');
  (data.estilo === 'melodico' ? gerarMusicaMelodica : gerarMusica)(wav, total, clima);
  args.push('-i', wav);
}
let filter = '';
for (let i = 0; i < n; i++) {
  const frames = Math.round((dur[i] + T) * 30);
  filter += `[${i}:v]zoompan=z='1+0.00011*on':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=${frames}:s=1080x1920:fps=30,setsar=1,format=yuv420p[v${i}];`;
}
let last = 'v0', acc = 0;
for (let i = 1; i < n; i++) {
  acc += dur[i - 1];
  filter += `[${last}][v${i}]xfade=transition=fadeblack:duration=${T}:offset=${acc.toFixed(2)}[x${i}];`;
  last = `x${i}`;
}
filter += `[${last}]fade=t=in:st=0:d=0.8,fade=t=out:st=${(total - 0.6).toFixed(2)}:d=0.6[vout]`;
if (clima !== 'nenhuma') {
  filter += `;[${n}:a]aecho=0.8:0.6:70|140:0.25|0.15,lowpass=f=4500,volume=0.9,afade=t=in:st=0:d=1,afade=t=out:st=${Math.max(0, total - 2.5)}:d=2.5[aout]`;
}
args.push('-filter_complex', filter, '-map', '[vout]', '-map', clima === 'nenhuma' ? `${n}:a` : '[aout]',
  '-t', String(total), '-c:v', 'libx264', '-profile:v', 'high', '-pix_fmt', 'yuv420p', '-r', '30', '-crf', '22', '-preset', 'medium',
  '-c:a', 'aac', '-b:a', '128k', '-shortest', '-movflags', '+faststart', output);
execFileSync('ffmpeg', args, { stdio: ['ignore', 'ignore', 'inherit'] });
console.log(`ok: ${output} (${total}s, ${n} banners)`);
