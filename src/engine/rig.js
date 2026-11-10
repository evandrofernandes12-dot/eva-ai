import * as THREE from 'three';

const UE_BASE = {
  root: 'Root', pelvis: 'Hips', spine_01: 'Spine', spine_02: 'Spine1', spine_03: 'Spine2',
  neck_01: 'Neck', head: 'Head',
};
const UE_LIMB = {
  clavicle: 'Shoulder', upperarm: 'Arm', lowerarm: 'ForeArm', hand: 'Hand',
  thigh: 'UpLeg', calf: 'Leg', foot: 'Foot', ball: 'ToeBase',
};
const cap = (s) => s[0].toUpperCase() + s.slice(1);

/**
 * Nome canônico do osso. Aceita esqueletos Mixamo ("mixamorig:LeftArm") e estilo UE/Quaternius
 * ("upperarm_l", "index_02_r", "thigh_l"...), que são mapeados para a nomenclatura Mixamo.
 */
export function canon(name) {
  const n = name.replace(/^mixamorig:?/, '');
  const l = n.toLowerCase();
  if (UE_BASE[l]) return UE_BASE[l];
  let m = l.match(/^(clavicle|upperarm|lowerarm|hand|thigh|calf|foot|ball)_(l|r)$/);
  if (m) return `${m[2] === 'l' ? 'Left' : 'Right'}${UE_LIMB[m[1]]}`;
  m = l.match(/^ball_leaf_(l|r)$/);
  if (m) return `${m[1] === 'l' ? 'Left' : 'Right'}Toe_End`;
  m = l.match(/^(thumb|index|middle|ring|pinky)_0(\d)(_leaf)?_(l|r)$/);
  if (m) return `${m[4] === 'l' ? 'Left' : 'Right'}Hand${cap(m[1])}${m[2]}`;
  return n;
}

const AIM_CHILD = {
  LeftArm: 'LeftForeArm', LeftForeArm: 'LeftHand',
  RightArm: 'RightForeArm', RightForeArm: 'RightHand',
  LeftUpLeg: 'LeftLeg', LeftLeg: 'LeftFoot',
  RightUpLeg: 'RightLeg', RightLeg: 'RightFoot',
};

/**
 * Rig: guarda a pose de repouso (bind) de um esqueleto Mixamo/RPM e oferece
 *  - solve(): cinemática direta a partir de "aim" (direção) e "delta" (rotação no espaço do modelo)
 *  - applyScales(): escala de ossos por "escala líquida" (compensa a herança dos pais)
 */
export class Rig {
  constructor(root) {
    this.root = root;
    this.bones = {};
    this.order = [];
    this.rest = {};
    root.updateMatrixWorld(true);
    root.traverse((o) => {
      if (!o.isBone) return;
      const key = canon(o.name);
      this.bones[key] = o;
      this.order.push(key);
    });
    const p = new THREE.Vector3();
    const s = new THREE.Vector3();
    for (const key of this.order) {
      const b = this.bones[key];
      const r = { q: b.quaternion.clone(), p: b.position.clone(), s: b.scale.clone() };
      this.rest[key] = r;
      r.mw = b.matrixWorld.clone();
      b.matrixWorld.decompose(p, (r.wq = new THREE.Quaternion()), s);
      r.wp = p.clone();
      const par = b.parent;
      r.parentKey = par && par.isBone ? canon(par.name) : null;
      r.parentMatrix = par ? par.matrixWorld.clone() : new THREE.Matrix4();
      r.parentWQ = new THREE.Quaternion();
      r.parentMatrix.decompose(new THREE.Vector3(), r.parentWQ, new THREE.Vector3());
      // eixo do comprimento = componente dominante da posição do primeiro filho-osso
      const child = b.children.find((c) => c.isBone);
      r.lenAxis = 1;
      if (child) {
        const a = [Math.abs(child.position.x), Math.abs(child.position.y), Math.abs(child.position.z)];
        r.lenAxis = a.indexOf(Math.max(...a));
      }
      // permutação eixos do osso -> eixos do pai
      const e = new THREE.Matrix4().makeRotationFromQuaternion(r.q).elements;
      r.perm = [0, 1, 2].map((i) => {
        const col = [Math.abs(e[i * 4]), Math.abs(e[i * 4 + 1]), Math.abs(e[i * 4 + 2])];
        return col.indexOf(Math.max(...col));
      });
    }
    for (const key of this.order) {
      const ck = AIM_CHILD[key];
      if (ck && this.rest[ck]) this.rest[key].dir = this.rest[ck].wp.clone().sub(this.rest[key].wp).normalize();
    }
    this.net = {};
  }

  has(k) { return !!this.bones[k]; }

  /** Referencial da mão no repouso (T-pose, palma para baixo): f = dedos, l = linha dos nós, n = normal da palma. */
  handFrame(S) {
    const P = (k) => this.rest[k].wp;
    const hand = P(`${S}Hand`);
    const f = P(`${S}HandMiddle1`).clone().sub(hand).normalize();
    const l = P(`${S}HandThumb1`).clone().sub(P(`${S}HandPinky1`)).normalize();
    const n = new THREE.Vector3().crossVectors(f, l).normalize();
    if (n.y > 0) n.negate();
    const lf = l.clone();
    if (lf.z < 0) lf.negate();
    const grip = hand.clone().addScaledVector(f, 0.05).addScaledVector(n, 0.012);
    return { hand, f, l, lf, n, grip };
  }

  /** Eixo de flexão (no espaço local do osso) de cada falange, para fechar a mão. */
  curlAxes(S) {
    const { n } = this.handFrame(S);
    const out = {};
    for (const F of ['Thumb', 'Index', 'Middle', 'Ring', 'Pinky']) {
      for (let i = 1; i <= 3; i++) {
        const k = `${S}Hand${F}${i}`;
        const next = `${S}Hand${F}${i + 1}`;
        if (!this.rest[k] || !this.rest[next]) continue;
        const f = this.rest[next].wp.clone().sub(this.rest[k].wp).normalize();
        const a = new THREE.Vector3().crossVectors(f, n).normalize();
        out[k] = a.applyQuaternion(this.rest[k].wq.clone().invert());
      }
    }
    return out;
  }

  /** Posição de repouso (espaço do modelo) de um osso. */
  restPos(key) { return this.rest[key]?.wp.clone(); }

  /**
   * Resolve uma pose. spec: { Osso: { aim?: Vector3, delta?: Quaternion } }, hipsOffset: Vector3 (m).
   * Devolve { quats: {osso: Quaternion local}, hipsPos: Vector3 local }.
   */
  solve(spec, hipsOffset) {
    const quats = {};
    const wq = {};
    for (const key of this.order) {
      const r = this.rest[key];
      const pw = r.parentKey ? wq[r.parentKey] : r.parentWQ;
      const inh = pw.clone().multiply(r.q);
      let target = inh;
      const s = spec[key];
      if (s) {
        if (s.aim && r.dir) {
          const cur = r.dir.clone().applyQuaternion(inh.clone().multiply(r.wq.clone().invert()));
          target = new THREE.Quaternion().setFromUnitVectors(cur, s.aim.clone().normalize()).multiply(inh);
        }
        if (s.local) target = pw.clone().multiply(r.q).multiply(s.local);
        if (s.delta) target = s.delta.clone().multiply(target);
      }
      wq[key] = target;
      quats[key] = pw.clone().invert().multiply(target);
    }
    const h = this.rest.Hips;
    const inv = new THREE.Matrix3().setFromMatrix4(h.parentMatrix).invert();
    const hipsPos = h.p.clone().add((hipsOffset || new THREE.Vector3()).clone().applyMatrix3(inv));
    return { quats, hipsPos };
  }

  /** Aplica uma pose diretamente nos ossos (sem mixer). */
  applyPose(solved) {
    for (const key of this.order) this.bones[key].quaternion.copy(solved.quats[key]);
    this.bones.Hips.position.copy(solved.hipsPos);
    this.root.updateMatrixWorld(true);
  }

  /** Restaura a pose de repouso (T/A-pose original). */
  resetPose() {
    for (const key of this.order) {
      const b = this.bones[key];
      b.quaternion.copy(this.rest[key].q);
      b.position.copy(this.rest[key].p);
    }
    this.root.updateMatrixWorld(true);
  }

  /**
   * Define escalas "líquidas" (acumuladas) por osso. explicit: { Osso: [nx,ny,nz] } nos eixos do osso.
   * Ossos sem entrada herdam a escala líquida do pai (escala local = repouso).
   */
  applyScales(explicit) {
    const net = {};
    for (const key of this.order) {
      const r = this.rest[key];
      const parentNet = r.parentKey ? net[r.parentKey] : [1, 1, 1];
      const mapped = r.perm.map((j) => parentNet[j]);
      const b = this.bones[key];
      const e = explicit[key];
      if (e) {
        net[key] = e;
        b.scale.set(r.s.x * (e[0] / mapped[0]), r.s.y * (e[1] / mapped[1]), r.s.z * (e[2] / mapped[2]));
      } else {
        net[key] = mapped;
        b.scale.copy(r.s);
      }
    }
    this.net = net;
  }

  /** Escala líquida [x,y,z] para um membro: len no eixo do comprimento, thick nos demais. */
  limbNet(key, len, thick) {
    const a = this.rest[key].lenAxis;
    return [0, 1, 2].map((i) => (i === a ? len : thick));
  }
}
