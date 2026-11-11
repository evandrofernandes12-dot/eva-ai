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
module.exports = { gerarMusica };
