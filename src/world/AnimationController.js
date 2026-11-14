import * as THREE from 'three';

/** Palavras-chave de cada estado; o clipe é escolhido pelos nomes REAIS listados em MANIFEST.json (animations[]). */
const PATTERNS = {
  idle: [/^(.*\|)?idle$/i, /idle(?!_?(sword|hit|2|headlow))/i, /idle/i, /sleep_loop|crouch/i],
  walk: [/walk(ing)?$|walk1/i, /walk/i],
  run: [/^(.*\|)?run$|velociraptor_run/i, /gallop$/i, /run/i, /walk/i],
  attack: [/run_swordattack/i, /attack$|_attack$/i, /punch|bite|attack/i],
  hit: [/hitreact$|damage/i, /hit/i],
  death: [/death/i],
  jump: [/^(.*\|)?jump$|jump_?in/i, /jump/i],
};
const ONCE = new Set(['attack', 'hit', 'death', 'jump']);

export class AnimationController {
  /**
   * @param {THREE.Object3D} object raiz da instância (a mesma que está na cena)
   * @param {THREE.AnimationClip[]} clips clipes do glTF
   * @param {{animations:string[]}} [meta] entrada do MANIFEST (para validar/ordenar os nomes)
   */
  constructor(object, clips, meta = null) {
    this.mixer = new THREE.AnimationMixer(object);
    this.actions = new Map(); this.states = {}; this.current = null; this.stateName = null; this.locked = false;
    const names = (meta && meta.animations && meta.animations.length ? meta.animations : clips.map((c) => c.name));
    for (const c of clips) if (names.includes(c.name)) this.actions.set(c.name, this.mixer.clipAction(c));
    for (const st of Object.keys(PATTERNS)) {
      for (const re of PATTERNS[st]) { const n = [...this.actions.keys()].find((k) => re.test(k)); if (n) { this.states[st] = n; break; } }
    }
  }

  has(state) { return !!this.states[state]; }

  /** Troca de estado com crossfade suave. Estados "once" (attack/hit/death/jump) tocam uma vez e voltam ao anterior. */
  play(state, { fade = 0.25, speed = 1 } = {}) {
    const name = this.states[state]; if (!name) return false;
    if (this.locked && state !== 'death' && state !== 'hit') return false;
    if (this.stateName === state && this.current && !ONCE.has(state)) return true;
    const next = this.actions.get(name);
    next.reset().setEffectiveTimeScale(speed).setEffectiveWeight(1);
    if (ONCE.has(state)) {
      next.setLoop(THREE.LoopOnce, 1); next.clampWhenFinished = true; this.locked = true;
      this.after = this.stateName && !ONCE.has(this.stateName) ? this.stateName : 'idle';
    } else { next.setLoop(THREE.LoopRepeat, Infinity); next.clampWhenFinished = false; }
    if (this.current && this.current !== next) next.crossFadeFrom(this.current, fade, false);
    next.play(); this.current = next; this.stateName = state; return true;
  }

  update(dt) {
    this.mixer.update(dt);
    // estados de uso único (attack/hit/jump): ao terminar o clipe, volta com crossfade ao estado anterior (a morte fica congelada)
    const c = this.current;
    if (this.locked && c && this.stateName !== 'death' && c.time >= c.getClip().duration - 0.03) { this.locked = false; this.play(this.after || 'idle', { fade: 0.2 }); }
  }
  dispose() { this.mixer.stopAllAction(); }
}
