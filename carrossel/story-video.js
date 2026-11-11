// Gera um story em vídeo (mp4 1080x1920, ~12 s) a partir de um story.json de um slide, com trilha instrumental.
// Uso: node carrossel/story-video.js <story.json> <saida.mp4> [segundos]
const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFileSync } = require('child_process');
const { gerarMusica, gerarMusicaMelodica } = require('./musica');

const [, , input, output, segArg] = process.argv;
if (!input || !output) { console.error('Uso: node carrossel/story-video.js <story.json> <saida.mp4> [segundos]'); process.exit(1); }
const data = JSON.parse(fs.readFileSync(input, 'utf8'));
const seg = Number(segArg || data.segundos || 12);
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'story-'));
execFileSync('node', [path.join(__dirname, 'render.js'), input, dir], { stdio: 'inherit' });

const clima = data.musica === undefined ? 'reflexivo' : data.musica;
const args = ['-y', '-loglevel', 'error', '-i', path.join(dir, 'slide-01.png')];
const frames = Math.round(seg * 30);
let vf = `zoompan=z='1+0.00011*on':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=${frames}:s=1080x1920:fps=30,fade=t=in:st=0:d=0.8,fade=t=out:st=${seg - 0.6}:d=0.6,format=yuv420p`;
if (clima === 'nenhuma') {
  args.push('-f', 'lavfi', '-i', 'anullsrc=channel_layout=stereo:sample_rate=44100');
  args.push('-filter_complex', `[0:v]${vf}[v]`, '-map', '[v]', '-map', '1:a');
} else {
  const wav = path.join(dir, 'trilha.wav');
  (data.estilo === 'melodico' ? gerarMusicaMelodica : gerarMusica)(wav, seg, clima);
  args.push('-i', wav);
  args.push('-filter_complex', `[0:v]${vf}[v];[1:a]aecho=0.8:0.6:70|140:0.25|0.15,lowpass=f=4500,volume=0.9,afade=t=in:st=0:d=1,afade=t=out:st=${seg - 2.5}:d=2.5[a]`, '-map', '[v]', '-map', '[a]');
}
args.push('-t', String(seg), '-c:v', 'libx264', '-profile:v', 'high', '-pix_fmt', 'yuv420p', '-r', '30', '-crf', '22', '-preset', 'medium',
  '-c:a', 'aac', '-b:a', '128k', '-shortest', '-movflags', '+faststart', output);
execFileSync('ffmpeg', args, { stdio: ['ignore', 'ignore', 'inherit'] });
console.log(`ok: ${output} (${seg}s)`);
