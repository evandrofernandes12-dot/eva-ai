// Gera uma trilha instrumental original (pad suave + arpejo de teclado), sem direitos autorais de terceiros.
// Uso programático: gerarMusica(arquivoWav, segundos, clima)  | clima: "reflexivo" (menor) ou "esperanca" (maior)
const fs = require('fs');

const SR = 44100;
const N = {
  A2: 110, C3: 130.81, D3: 146.83, E3: 164.81, F3: 174.61, G3: 196, A3: 220, B3: 246.94,
  C4: 261.63, D4: 293.66, E4: 329.63, F4: 349.23, G4: 392, A4: 440, B4: 493.88, C5: 523.25, E5: 659.25,
  F2: 87.31, G2: 98
};
const PROGRESSOES = {
  reflexivo: [ // Lá menor: Am - F - C - G
    { baixo: N.A2, pad: [N.E3, N.A3, N.C4, N.E4], arp: [N.A3, N.C4, N.E4, N.A4, N.E4, N.C4] },
    { baixo: N.F2, pad: [N.C3, N.F3, N.A3, N.C4], arp: [N.F3, N.A3, N.C4, N.F4, N.C4, N.A3] },
    { baixo: N.C3, pad: [N.G3, N.C4, N.E4, N.G4], arp: [N.C4, N.E4, N.G4, N.C5, N.G4, N.E4] },
    { baixo: N.G2, pad: [N.D3, N.G3, N.B3, N.D4], arp: [N.G3, N.B3, N.D4, N.G4, N.D4, N.B3] },
  ],
  esperanca: [ // Dó maior: C - G - Am - F
    { baixo: N.C3, pad: [N.G3, N.C4, N.E4, N.G4], arp: [N.C4, N.E4, N.G4, N.C5, N.G4, N.E4] },
    { baixo: N.G2, pad: [N.D3, N.G3, N.B3, N.D4], arp: [N.G3, N.B3, N.D4, N.G4, N.D4, N.B3] },
    { baixo: N.A2, pad: [N.E3, N.A3, N.C4, N.E4], arp: [N.A3, N.C4, N.E4, N.A4, N.E4, N.C4] },
    { baixo: N.F2, pad: [N.C3, N.F3, N.A3, N.C4], arp: [N.F3, N.A3, N.C4, N.F4, N.C4, N.A3] },
  ],
};

function gerarMusica(arquivo, segundos, clima = 'reflexivo') {
  const prog = PROGRESSOES[clima] || PROGRESSOES.reflexivo;
  const total = Math.ceil((segundos + 2) * SR);
  const L = new Float32Array(total), R = new Float32Array(total);
  const acorde = 8; // segundos por acorde
  const nAcordes = Math.ceil((segundos + 2) / acorde);

  const nota = (f, ini, dur, amp, ataque, soltar, pan, harm) => {
    const i0 = Math.floor(ini * SR), n = Math.floor(dur * SR);
    for (let k = 0; k < n && i0 + k < total; k++) {
      const t = k / SR;
      const env = Math.min(1, t / ataque) * Math.min(1, (dur - t) / soltar);
      if (env <= 0) continue;
      let v = 0;
      for (let h = 0; h < harm.length; h++) v += harm[h] * Math.sin(2 * Math.PI * f * (h + 1) * t);
      v *= amp * env;
      L[i0 + k] += v * (1 - pan); R[i0 + k] += v * pan;
    }
  };
  const pluck = (f, ini, amp, pan) => {
    const i0 = Math.floor(ini * SR), n = Math.floor(2.2 * SR);
    for (let k = 0; k < n && i0 + k < total; k++) {
      const t = k / SR;
      const env = Math.exp(-2.6 * t) * Math.min(1, t / 0.006);
      const v = amp * env * (Math.sin(2 * Math.PI * f * t) + 0.35 * Math.sin(2 * Math.PI * f * 2 * t) * Math.exp(-4 * t) + 0.12 * Math.sin(2 * Math.PI * f * 3 * t) * Math.exp(-6 * t));
      L[i0 + k] += v * (1 - pan); R[i0 + k] += v * pan;
    }
  };

  for (let c = 0; c < nAcordes; c++) {
    const a = prog[c % prog.length];
    const ini = c * acorde;
    // pad: duas vozes levemente desafinadas para efeito de coral
    nota(a.baixo, ini, acorde + 2.5, 0.16, 2.0, 2.5, 0.5, [1, 0.3]);
    a.pad.forEach((f, i) => {
      nota(f * 0.998, ini, acorde + 2.5, 0.07, 2.0, 2.5, 0.35 + 0.1 * i, [1, 0.25, 0.08]);
      nota(f * 1.002, ini, acorde + 2.5, 0.07, 2.0, 2.5, 0.65 - 0.1 * i, [1, 0.25, 0.08]);
    });
    // arpejo lento (uma nota a cada 1,33 s), como teclado/piano suave
    const passo = acorde / 6;
    a.arp.forEach((f, i) => pluck(f, ini + 1 + i * passo, 0.13, 0.3 + 0.4 * (i % 3) / 2));
  }

  // normaliza e grava WAV 16 bits estéreo
  let pico = 0;
  for (let i = 0; i < total; i++) pico = Math.max(pico, Math.abs(L[i]), Math.abs(R[i]));
  const g = 0.8 / (pico || 1);
  const buf = Buffer.alloc(44 + total * 4);
  buf.write('RIFF', 0); buf.writeUInt32LE(36 + total * 4, 4); buf.write('WAVEfmt ', 8);
  buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(2, 22);
  buf.writeUInt32LE(SR, 24); buf.writeUInt32LE(SR * 4, 28); buf.writeUInt16LE(4, 32); buf.writeUInt16LE(16, 34);
  buf.write('data', 36); buf.writeUInt32LE(total * 4, 40);
  for (let i = 0; i < total; i++) {
    buf.writeInt16LE(Math.max(-32768, Math.min(32767, Math.round(L[i] * g * 32767))), 44 + i * 4);
    buf.writeInt16LE(Math.max(-32768, Math.min(32767, Math.round(R[i] * g * 32767))), 46 + i * 4);
  }
  fs.writeFileSync(arquivo, buf);
}

// ---------- Estilo "melodico": ritmo mais vivo, arpejo em colcheias, baixo e melodia ----------
function gerarMusicaMelodica(arquivo, segundos, clima = 'reflexivo') {
  const menor = clima !== 'esperanca';
  const BPM = menor ? 92 : 96;
  const beat = 60 / BPM, compasso = beat * 4;
  const total = Math.ceil((segundos + 2) * SR);
  const L = new Float32Array(total), R = new Float32Array(total);
  let seed = menor ? 7 : 11;
  const rnd = () => { seed |= 0; seed = (seed + 0x6D2B79F5) | 0; let t = Math.imul(seed ^ (seed >>> 15), 1 | seed); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
  const f = (m) => 440 * Math.pow(2, (m - 69) / 12);

  const tonica = menor ? 69 : 60; // lá ou dó
  const escala = (menor ? [0, 2, 3, 5, 7, 8, 10] : [0, 2, 4, 5, 7, 9, 11]);
  // acordes: [raiz MIDI do baixo, notas do tríade em MIDI (oitava 4)]
  const prog = menor
    ? [[45, [57, 60, 64]], [41, [57, 60, 65]], [48, [55, 60, 64]], [43, [55, 59, 62]]]   // Am F C G
    : [[48, [55, 60, 64]], [43, [55, 59, 62]], [45, [57, 60, 64]], [41, [57, 60, 65]]]; // C G Am F
  const notasEscala = [];
  for (let m = 60; m <= 83; m++) if (escala.includes((m - tonica % 12 + 120) % 12) || escala.includes(((m - tonica) % 12 + 12) % 12)) notasEscala.push(m);

  const add = (arr, i, v) => { if (i >= 0 && i < total) arr[i] += v; };
  const tocar = (freq, ini, dur, amp, pan, tipo) => {
    const i0 = Math.floor(ini * SR), n = Math.floor(dur * SR);
    for (let k = 0; k < n && i0 + k < total; k++) {
      const t = k / SR;
      let v;
      if (tipo === 'piano') {
        const env = Math.exp(-2.2 * t) * Math.min(1, t / 0.004);
        v = env * (Math.sin(2 * Math.PI * freq * t) + 0.5 * Math.sin(2 * Math.PI * freq * 2 * t) * Math.exp(-3 * t) + 0.25 * Math.sin(2 * Math.PI * freq * 3 * t) * Math.exp(-5 * t) + 0.1 * Math.sin(2 * Math.PI * freq * 4 * t) * Math.exp(-7 * t));
      } else if (tipo === 'lead') { // som de sino/flauta suave com vibrato leve
        const vib = 1 + 0.003 * Math.sin(2 * Math.PI * 5.2 * t) * Math.min(1, t / 0.4);
        const env = Math.min(1, t / 0.03) * Math.exp(-1.4 * t) * Math.min(1, (dur - t) / 0.15);
        v = env * (Math.sin(2 * Math.PI * freq * vib * t) + 0.3 * Math.sin(2 * Math.PI * freq * 2 * vib * t) + 0.08 * Math.sin(2 * Math.PI * freq * 3 * t));
      } else if (tipo === 'baixo') {
        const env = Math.exp(-1.6 * t) * Math.min(1, t / 0.01);
        v = env * (Math.sin(2 * Math.PI * freq * t) + 0.35 * Math.sin(2 * Math.PI * freq * 2 * t));
      } else { // pad
        const env = Math.min(1, t / 0.9) * Math.min(1, (dur - t) / 1.2);
        v = env * (Math.sin(2 * Math.PI * freq * 0.998 * t) + Math.sin(2 * Math.PI * freq * 1.002 * t)) * 0.5;
      }
      v *= amp;
      L[i0 + k] += v * (1 - pan); R[i0 + k] += v * pan;
    }
  };
  const shaker = (ini, amp) => {
    const i0 = Math.floor(ini * SR), n = Math.floor(0.09 * SR);
    let prev = 0;
    for (let k = 0; k < n && i0 + k < total; k++) {
      const x = rnd() * 2 - 1, hp = x - prev; prev = x;
      const v = hp * amp * Math.exp(-45 * (k / SR));
      add(L, i0 + k, v * 0.6); add(R, i0 + k, v * 0.4);
    }
  };

  const nCompassos = Math.ceil((segundos + 2) / compasso);
  const arpA = [0, 1, 2, 1, 2, 1, 2, 1], arpB = [0, 2, 1, 2, 1, 2, 3, 2];
  const ritmosMel = [ // duração em tempos de cada nota da frase (soma 4)
    [1, 1, 2], [2, 1, 1], [1, 0.5, 0.5, 2], [1.5, 0.5, 2], [1, 1, 1, 1], [0.5, 0.5, 1, 2], [2, 2], [1, 2, 1]
  ];
  let ultimaMel = notasEscala.find(m => m >= 72) || 72;

  for (let c = 0; c < nCompassos; c++) {
    const [raiz, tri] = prog[c % prog.length];
    const t0 = c * compasso;
    const acorde = [tri[0], tri[1], tri[2], tri[0] + 12]; // 4 notas ascendentes
    const volta = Math.floor(c / prog.length);
    // pad (a partir do 2º compasso fica mais cheio)
    tri.forEach((m, i) => tocar(f(m - 12), t0, compasso + 0.6, c < 2 ? 0.035 : 0.05, 0.3 + 0.2 * i, 'pad'));
    // baixo: tempos 1 e 3
    tocar(f(raiz), t0, beat * 2, 0.17, 0.5, 'baixo');
    tocar(f(raiz + (c % 2 ? 7 : 0)), t0 + beat * 2, beat * 2, 0.12, 0.5, 'baixo');
    // arpejo em colcheias (piano)
    const pad = c % 2 ? arpB : arpA;
    for (let i = 0; i < 8; i++) {
      const m = acorde[pad[i]] + (i >= 6 ? 12 : 0);
      tocar(f(m), t0 + i * beat / 2, 1.4, 0.075 + (i % 2 === 0 ? 0.02 : 0), 0.25 + 0.5 * (i / 7), 'piano');
    }
    // chocalho suave nos contratempos (a partir do 3º compasso)
    if (c >= 2) for (let i = 0; i < 8; i++) shaker(t0 + i * beat / 2, i % 2 ? 0.05 : 0.025);
    // melodia a partir do 3º compasso, em frases de um compasso
    if (c >= 2 && c < nCompassos - 1) {
      const ritmo = ritmosMel[Math.floor(rnd() * ritmosMel.length)];
      let t = t0;
      ritmo.forEach((dur, i) => {
        const fortes = notasEscala.filter(m => m >= 67 && m <= 81 && tri.some(x => (m - x) % 12 === 0));
        const proximas = notasEscala.filter(m => m >= 67 && m <= 81 && Math.abs(m - ultimaMel) <= 4);
        const pool = (t - t0) % (beat * 2) < 0.01 ? (fortes.filter(m => Math.abs(m - ultimaMel) <= 5).concat(fortes)) : proximas;
        const m = pool[Math.floor(rnd() * pool.length)] || ultimaMel;
        ultimaMel = m;
        tocar(f(m), t, dur * beat * 0.95, 0.12, 0.6, 'lead');
        t += dur * beat;
      });
    }
    if (c === nCompassos - 1) tocar(f(tri[2] + 12), t0, compasso, 0.1, 0.5, 'lead');
  }

  let pico = 0;
  for (let i = 0; i < total; i++) pico = Math.max(pico, Math.abs(L[i]), Math.abs(R[i]));
  const g = 0.8 / (pico || 1);
  const buf = Buffer.alloc(44 + total * 4);
  buf.write('RIFF', 0); buf.writeUInt32LE(36 + total * 4, 4); buf.write('WAVEfmt ', 8);
  buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(2, 22);
  buf.writeUInt32LE(SR, 24); buf.writeUInt32LE(SR * 4, 28); buf.writeUInt16LE(4, 32); buf.writeUInt16LE(16, 34);
  buf.write('data', 36); buf.writeUInt32LE(total * 4, 40);
  for (let i = 0; i < total; i++) {
    buf.writeInt16LE(Math.max(-32768, Math.min(32767, Math.round(L[i] * g * 32767))), 44 + i * 4);
    buf.writeInt16LE(Math.max(-32768, Math.min(32767, Math.round(R[i] * g * 32767))), 46 + i * 4);
  }
  fs.writeFileSync(arquivo, buf);
}
module.exports = { gerarMusica, gerarMusicaMelodica };
