import * as THREE from 'three';

export const ANIMS = [
  { id: 'Idle', label: 'Idle', icon: '🧍' },
  { id: 'Walk', label: 'Andar', icon: '🚶' },
  { id: 'Attack', label: 'Atacar', icon: '⚔️' },
  { id: 'Defend', label: 'Defender', icon: '🛡️' },
];

const X = new THREE.Vector3(1, 0, 0);
const Y = new THREE.Vector3(0, 1, 0);
const Z = new THREE.Vector3(0, 0, 1);
const q = (axis, a) => new THREE.Quaternion().setFromAxisAngle(axis, a);

/**
 * Cria as definições de animação para um rig.
 * Convenção do espaço do modelo (glTF): +Z = frente, "esquerda" do personagem = lado `sideL` (±X).
 * posture: { spine, neck, head } = pitch extra (rad, + = para frente) por raça (corcunda do lobisomem etc.).
 * legDrop: queda extra do quadril (m) - não usado aqui; o ajuste de comprimento de perna entra por hipsBase.
 */
export function buildClipDefs(rig, { posture = {}, hipsBase = 0, bodyH = 1.8 }) {
  const sideL = Math.sign(rig.restPos('LeftArm').x - rig.restPos('RightArm').x) || 1;
  const sx = { Left: sideL, Right: -sideL };
  // v(side, out, up, fwd): vetor no espaço do modelo
  const v = (S, out, up, fwd) => new THREE.Vector3(sx[S] * out, up, fwd);
  const pitch = (a) => q(X, a);
  const yaw = (a) => q(Y, a * sideL); // + = virar para a esquerda do personagem
  const roll = (a) => q(Z, a * sideL);
  const u = bodyH / 1.8; // escala de metros

  const spec = () => ({});
  const torso = (s, p, y = 0, r = 0) => {
    for (const k of ['Spine', 'Spine1', 'Spine2']) {
      s[k] = { delta: yaw(y / 3).multiply(pitch(p / 3)).multiply(roll(r / 3)) };
    }
  };
  const arm = (s, S, up, fore) => {
    s[`${S}Arm`] = { aim: up };
    s[`${S}ForeArm`] = { aim: fore };
  };
  const leg = (s, S, thigh, shin) => {
    s[`${S}UpLeg`] = { aim: thigh };
    s[`${S}Leg`] = { aim: shin };
    const psi = Math.atan2(shin.z, -shin.y);
    s[`${S}Foot`] = { delta: pitch(psi) }; // mantém o pé plano
  };
  const straightLegs = (s, spread = 0.07) => {
    for (const S of ['Left', 'Right']) leg(s, S, v(S, spread, -1, 0), v(S, spread, -1, 0));
  };
  const relaxedArms = (s, sway = 0) => {
    for (const S of ['Left', 'Right']) arm(s, S, v(S, 0.16 + sway, -1, 0.04), v(S, 0.1 + sway, -1, 0.3));
  };
  const off = (x = 0, y = 0, z = 0) => new THREE.Vector3(sx.Left * x, y * u, z * u);

  const finish = (s) => {
    // postura racial (corcunda): soma pitch em Spine/Neck/Head
    const add = (k, delta) => {
      s[k] = { ...(s[k] || {}), delta: delta.multiply(s[k]?.delta || new THREE.Quaternion()) };
    };
    if (posture.spine) for (const k of ['Spine', 'Spine1', 'Spine2']) add(k, pitch(posture.spine / 3));
    if (posture.neck) add('Neck', pitch(posture.neck));
    if (posture.head) add('Head', pitch(posture.head));
    return s;
  };

  const defs = {};

  // ---------- IDLE ----------
  {
    const f = (t, k) => {
      const s = spec();
      torso(s, -0.025 * k, 0.03 * k);
      relaxedArms(s, 0.02 * k);
      straightLegs(s);
      s.Head = { delta: pitch(0.02 * k) };
      return { t, spec: finish(s), off: off(0, 0.004 * k + hipsBase) };
    };
    defs.Idle = { duration: 3.2, frames: [f(0, 0), f(1.6, 1), f(3.2, 0)] };
  }

  // ---------- WALK ----------
  {
    const N = 8;
    const frames = [];
    for (let i = 0; i <= N; i++) {
      const ph = (i / N) * Math.PI * 2;
      const s = spec();
      const A = 0.48;
      const th = { Left: A * Math.sin(ph), Right: A * Math.sin(ph + Math.PI) };
      for (const S of ['Left', 'Right']) {
        const t = th[S];
        const flex = 0.85 * Math.max(0, Math.cos(S === 'Left' ? ph : ph + Math.PI));
        const psi = t - flex;
        leg(s, S, v(S, 0.06, -Math.cos(t), Math.sin(t)), v(S, 0.06, -Math.cos(psi), Math.sin(psi)));
        const al = -0.8 * t;
        arm(s, S, v(S, 0.13, -Math.cos(al), Math.sin(al)), v(S, 0.08, -Math.cos(al + 0.5), Math.sin(al + 0.5)));
      }
      torso(s, 0.04, 0.16 * Math.sin(ph), 0.02 * Math.cos(ph));
      s.Hips = { delta: yaw(-0.1 * Math.sin(ph)) };
      s.Head = { delta: yaw(-0.04 * Math.sin(ph)) };
      frames.push({ t: i / N, spec: finish(s), off: off(0, 0.016 * Math.cos(2 * ph) - 0.012 + hipsBase) });
    }
    defs.Walk = { duration: 1, frames };
  }

  // ---------- ATTACK (soco/golpe com o braço direito) ----------
  {
    const stance = (s) => {
      leg(s, 'Left', v('Left', 0.22, -1, 0.4), v('Left', 0.2, -1, 0.1));
      leg(s, 'Right', v('Right', 0.28, -1, -0.3), v('Right', 0.25, -1, -0.12));
    };
    const mk = (t, o) => {
      const s = spec();
      stance(s);
      torso(s, o.pitch, o.yaw);
      arm(s, 'Right', v('Right', ...o.R[0]), v('Right', ...o.R[1]));
      arm(s, 'Left', v('Left', ...o.L[0]), v('Left', ...o.L[1]));
      s.Head = { delta: pitch(-0.08).multiply(yaw(-o.yaw * 0.6)) };
      return { t, spec: finish(s), off: off(0, -0.09 + hipsBase, o.z || 0) };
    };
    const guard = { pitch: 0.1, yaw: -0.18, R: [[0.35, -0.75, 0.5], [0.1, 0.55, 0.8]], L: [[0.35, -0.75, 0.45], [0.15, 0.55, 0.8]] };
    const wind = { pitch: 0.1, yaw: -0.6, z: -0.03, R: [[0.75, -0.2, -0.65], [0.4, 0.25, -0.9]], L: [[0.3, -0.7, 0.5], [0.05, 0.6, 0.8]] };
    const hit = { pitch: 0.2, yaw: 0.5, z: 0.1, R: [[0.12, 0.05, 1], [0.08, 0.05, 1]], L: [[0.4, -0.6, 0.4], [0.1, 0.7, 0.6]] };
    const hold = { pitch: 0.16, yaw: 0.35, z: 0.07, R: [[0.2, -0.2, 0.9], [0.1, 0.1, 1]], L: [[0.4, -0.65, 0.4], [0.12, 0.7, 0.6]] };
    defs.Attack = { duration: 1, frames: [mk(0, guard), mk(0.22, wind), mk(0.4, hit), mk(0.6, hold), mk(1, guard)] };
  }

  // ---------- DEFEND (guarda alta + impacto) ----------
  {
    const mk = (t, o) => {
      const s = spec();
      leg(s, 'Left', v('Left', 0.2, -1, 0.25), v('Left', 0.18, -1, 0.08));
      leg(s, 'Right', v('Right', 0.2, -1, -0.15), v('Right', 0.18, -1, -0.05));
      torso(s, o.pitch, 0.1);
      for (const S of ['Left', 'Right']) arm(s, S, v(S, ...o.up), v(S, ...o.fore));
      s.Head = { delta: pitch(o.head) };
      return { t, spec: finish(s), off: off(0, o.dy + hipsBase, o.dz || 0) };
    };
    const med = { pitch: 0.12, up: [0.35, -0.7, 0.4], fore: [-0.3, 0.8, 0.7], head: -0.05, dy: -0.07 };
    const high = { pitch: 0.18, up: [0.3, -0.4, 0.55], fore: [-0.55, 0.9, 0.5], head: -0.1, dy: -0.09 };
    const hit = { pitch: -0.08, up: [0.3, -0.4, 0.55], fore: [-0.55, 0.9, 0.5], head: 0.12, dy: -0.06, dz: -0.06 };
    defs.Defend = { duration: 1.2, frames: [mk(0, med), mk(0.3, high), mk(0.55, hit), mk(0.85, high), mk(1.2, med)] };
  }

  return defs;
}

/** Converte as definições em THREE.AnimationClip (tracks de rotação por osso + posição do quadril). */
export function buildClips(rig, defs) {
  const clips = {};
  // união de ossos que recebem keyframes (todos os clipes usam o mesmo conjunto)
  const used = new Set(['Hips']);
  for (const d of Object.values(defs)) for (const f of d.frames) for (const k of Object.keys(f.spec)) used.add(k);
  for (const [name, d] of Object.entries(defs)) {
    const solved = d.frames.map((f) => rig.solve(f.spec, f.off));
    const times = d.frames.map((f) => f.t);
    const tracks = [];
    for (const key of used) {
      if (!rig.has(key)) continue;
      const bone = rig.bones[key];
      const vals = [];
      for (const sv of solved) vals.push(...sv.quats[key].toArray());
      tracks.push(new THREE.QuaternionKeyframeTrack(`${bone.name}.quaternion`, times, vals));
    }
    const pv = [];
    for (const sv of solved) pv.push(...sv.hipsPos.toArray());
    tracks.push(new THREE.VectorKeyframeTrack(`${rig.bones.Hips.name}.position`, times, pv));
    const clip = new THREE.AnimationClip(name, d.duration, tracks);
    clips[name] = clip;
  }
  return clips;
}

export { X as AXIS_X, Y as AXIS_Y, Z as AXIS_Z };
