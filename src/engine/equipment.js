import * as THREE from 'three';
import { attachGroup, bodyShell, mergeByMaterial, restPoints } from './parts.js';
import { ITEMS, gem, helmetCrest, pauldron } from './items.js';

const V = (x, y, z) => new THREE.Vector3(x, y, z);

/** distância e parâmetro t do ponto p ao segmento a→b */
function seg(p, a, b) {
  const ab = b.clone().sub(a);
  const t = p.clone().sub(a).dot(ab) / ab.lengthSq();
  const c = a.clone().addScaledVector(ab, Math.min(1, Math.max(0, t)));
  return { t, d: p.distanceTo(c) };
}

export function createEquipMaterials() {
  const std = (color, extra = {}) => new THREE.MeshStandardMaterial({ color, roughness: 0.6, metalness: 0, ...extra });
  const m = {
    metal: std('#b8bcc4', { roughness: 0.32, metalness: 0.92, side: THREE.DoubleSide }),
    leather: std('#6b4a2f', { roughness: 0.8, side: THREE.DoubleSide }),
    jewel: std('#d4af37', { roughness: 0.28, metalness: 1 }),
    gem: new THREE.MeshPhysicalMaterial({ color: '#d62f5b', roughness: 0.08, metalness: 0.1, clearcoat: 1, emissive: '#d62f5b', emissiveIntensity: 0.25 }),
    gemGlow: std('#d62f5b', { roughness: 0.15, emissive: '#d62f5b', emissiveIntensity: 0.9 }),
    wood: std('#5b3d22', { roughness: 0.85 }),
    paper: std('#e9dfc4', { roughness: 0.95 }),
    string: std('#d8d2c0', { roughness: 0.6 }),
    feather: std('#e8e8e2', { roughness: 0.9, side: THREE.DoubleSide }),
    book: std('#6a2a2a', { roughness: 0.75 }),
  };
  m.leatherTwoSided = m.leather;
  return m;
}

const SLOT_BONE_OFFSET = {
  // offsets (m) da casca por estilo
  head: { leather: 0.013, plate: 0.021 },
  chest: { leather: 0.013, plate: 0.022 },
  shoulders: { leather: 0.016, plate: 0.0 },
  arms: { leather: 0.011, plate: 0.019 },
  hands: { leather: 0.008, plate: 0.013 },
  legs: { leather: 0.012, plate: 0.02 },
  feet: { leather: 0.011, plate: 0.017 },
};

export class Equipment {
  constructor(rig, bodyMesh, mats, equipMats, cloth) {
    this.rig = rig;
    this.body = bodyMesh;
    this.mats = mats; // materiais base (hair, cloth...)
    this.m = equipMats;
    this.cache = new Map();
    this.regions = this._regions();
    restPoints(bodyMesh);
    this.cloth = cloth; // { basic: [...], }
  }

  // ------------------------------------------------------------------ regiões do corpo (repouso)
  _regions() {
    const r = this.rig;
    const P = (k) => r.restPos(k);
    const armX = Math.abs(P('LeftArm').x);
    const spineY = P('Spine').y;
    const neckY = P('Neck').y;
    const hipsY = P('Hips').y;
    const footY = P('LeftFoot').y;
    const head = P('Head');
    const eyeY = r.anchors.eye.y;
    const sides = ['Left', 'Right'];
    const bones = (S) => ({
      arm: P(`${S}Arm`), fore: P(`${S}ForeArm`), hand: P(`${S}Hand`),
      tip: P(`${S}HandMiddle4`) || P(`${S}HandMiddle3`),
    });
    return {
      head: (p) => p.y > eyeY - 0.11 && p.y > head.y - 0.03 && !(p.z > 0.025 && p.y < eyeY + 0.045),
      hood: (p) => p.y > eyeY - 0.13 && p.y > head.y - 0.06 && !(p.z > 0.0 && p.y < eyeY + 0.06),
      chest: (p) => p.y > spineY - 0.03 && p.y < neckY - 0.005 && Math.abs(p.x) < armX - 0.03,
      tunic: (p) => {
        if (p.y > hipsY - 0.1 && p.y < neckY + 0.0 && Math.abs(p.x) < armX - 0.03) return true;
        for (const S of sides) {
          const b = bones(S);
          const q = seg(p, b.arm, b.fore);
          if (q.d < 0.1 && q.t > -0.1 && q.t < 0.62) return true;
        }
        return false;
      },
      shoulders: (p) => {
        for (const S of sides) {
          const b = bones(S);
          if (p.distanceTo(b.arm.clone().add(V(0, 0.02, 0))) < 0.11 && p.y > b.arm.y - 0.1) return true;
        }
        return false;
      },
      arms: (p) => {
        for (const S of sides) {
          const b = bones(S);
          const q = seg(p, b.fore, b.hand);
          if (q.d < 0.085 && q.t > 0.08 && q.t < 0.92) return true;
        }
        return false;
      },
      hands: (p) => {
        for (const S of sides) {
          const b = bones(S);
          const q = seg(p, b.hand, b.tip);
          if (q.d < 0.075 && q.t > -0.25 && q.t < 1.15) return true;
        }
        return false;
      },
      legs: (p) => p.y < hipsY + 0.02 && p.y > footY + 0.05,
      pants: (p) => p.y < hipsY + 0.06 && p.y > footY + 0.04,
      feet: (p) => p.y < footY + 0.105,
    };
  }

  /** Cria (uma vez) e devolve uma casca de região/estilo. */
  shell(slot, style) {
    const key = `shell:${slot}:${style}`;
    if (this.cache.has(key)) return this.cache.get(key);
    const m = style === 'plate' ? this.m.metal : this.m.leather;
    let test = this.regions[slot];
    let off = SLOT_BONE_OFFSET[slot]?.[style] ?? 0.014;
    if (slot === 'head' && style === 'leather') test = this.regions.hood;
    if (slot === 'shoulders' && style === 'plate') { this.cache.set(key, []); return []; }
    const mesh = bodyShell(this.body, test, m, off);
    const arr = mesh ? [mesh] : [];
    this.cache.set(key, arr);
    return arr;
  }

  /** Peças rígidas extras (pauldrons, crista, gema do peitoral). */
  extras(slot, style) {
    const key = `extra:${slot}:${style}`;
    if (this.cache.has(key)) return this.cache.get(key);
    const r = this.rig;
    const out = [];
    if (style === 'plate' && slot === 'shoulders') {
      for (const S of ['Left', 'Right']) {
        const out_ = r.restPos(`${S}Arm`).x > 0 ? 1 : -1;
        const g = new THREE.Group();
        const pd = pauldron(this.m, out_);
        pd.position.copy(r.restPos(`${S}Arm`)).add(V(out_ * 0.01, 0.025, 0));
        g.add(pd);
        mergeByMaterial(g);
        attachGroup(r, `${S}Arm`, g);
        out.push(g);
      }
    }
    if (style === 'plate' && slot === 'head') {
      const g = new THREE.Group();
      const c = helmetCrest(this.m);
      c.position.set(r.restPos('Head').x, r.anchors.topY - 0.004, r.restPos('Head').z - 0.012);
      g.add(c);
      mergeByMaterial(g);
      attachGroup(r, 'Head', g);
      out.push(g);
    }
    if (style === 'plate' && slot === 'chest') {
      const pts = restPoints(this.body);
      const y = r.restPos('Spine2').y;
      let z = -1;
      for (let i = 0; i < pts.length; i += 3) {
        if (Math.abs(pts[i]) < 0.02 && Math.abs(pts[i + 1] - y) < 0.02 && pts[i + 2] > z) z = pts[i + 2];
      }
      const g = new THREE.Group();
      const gm = gem(0.026, this.m);
      gm.position.set(0, y, z + 0.026);
      g.add(gm);
      const ring = new THREE.Mesh(new THREE.TorusGeometry(0.035, 0.006, 8, 24), this.m.jewel);
      ring.position.set(0, y, z + 0.02);
      g.add(ring);
      mergeByMaterial(g);
      attachGroup(r, 'Spine2', g);
      out.push(g);
    }
    this.cache.set(key, out);
    return out;
  }

  // ------------------------------------------------------------------ itens segurados
  /** Posiciona um item na mão `S` ('Left'|'Right'), segundo o tipo de pegada. */
  held(S, id) {
    const key = `held:${S}:${id}`;
    if (this.cache.has(key)) return this.cache.get(key);
    const r = this.rig;
    const hf = r.handFrame(S);
    const item = ITEMS[id](this.m);
    // tip (eixo Y do item) e normal de espessura (eixo Z), no espaço do modelo
    let tip, thick;
    if (id === 'knife' || id === 'shortsword' || id === 'longsword') {
      tip = hf.lf.clone().multiplyScalar(0.85).addScaledVector(hf.f, 0.5).normalize();
      thick = hf.n.clone();
    } else if (id === 'spear' || id === 'staff') {
      tip = hf.f.clone().multiplyScalar(-0.85).addScaledVector(hf.lf, 0.35).normalize();
      thick = hf.n.clone();
    } else if (id === 'bow') {
      tip = hf.f.clone().multiplyScalar(-1);
      thick = hf.lf.clone();
    } else if (id === 'book') {
      tip = hf.f.clone();
      thick = hf.n.clone().negate();
    } else {
      tip = hf.f.clone();
      thick = hf.n.clone();
    }
    const grip = hf.grip.clone();
    if (id === 'book') grip.addScaledVector(hf.f, 0.05);
    const z = thick.clone().sub(tip.clone().multiplyScalar(thick.dot(tip))).normalize();
    const x = new THREE.Vector3().crossVectors(tip, z).normalize();
    const mx = new THREE.Matrix4().makeBasis(x, tip, z);
    const wrap = new THREE.Group();
    item.quaternion.setFromRotationMatrix(mx);
    item.position.copy(grip);
    wrap.add(item);
    attachGroup(r, `${S}Hand`, wrap);
    this.cache.set(key, [wrap]);
    return [wrap];
  }

  /**
   * Escudo preso ao antebraço. No repouso (T-pose) o antebraço é horizontal e vira para baixo na pose relaxada,
   * então o item é definido no referencial do osso: eixo longo ao longo do antebraço e face voltada para
   * +Y no repouso (= "para fora do corpo" quando o braço pende).
   */
  strapped(S, id) {
    const key = `strap:${S}:${id}`;
    if (this.cache.has(key)) return this.cache.get(key);
    const r = this.rig;
    const item = ITEMS[id](this.m);
    const a = r.restPos(`${S}ForeArm`);
    const b = r.restPos(`${S}Hand`);
    const d = b.clone().sub(a).normalize();
    const z = V(0, 1, 0);
    const x = new THREE.Vector3().crossVectors(d, z).normalize();
    item.quaternion.setFromRotationMatrix(new THREE.Matrix4().makeBasis(x, d, z));
    item.scale.setScalar(id === 'shield_kite' ? 0.78 : 0.85);
    item.position.copy(a.clone().lerp(b, 0.4)).addScaledVector(z, 0.085);
    const wrap = new THREE.Group();
    wrap.add(item);
    attachGroup(r, `${S}ForeArm`, wrap);
    this.cache.set(key, [wrap]);
    return [wrap];
  }

  quiver() {
    if (this.cache.has('quiver')) return this.cache.get('quiver');
    const r = this.rig;
    const item = ITEMS.quiver(this.m);
    const c = r.restPos('Spine2');
    const wrap = new THREE.Group();
    item.position.copy(c).add(V(0.02, 0.0, -0.13));
    item.rotation.z = -0.38;
    item.rotation.x = -0.12;
    wrap.add(item);
    attachGroup(r, 'Spine2', wrap);
    // alça
    const strap = new THREE.Mesh(new THREE.TorusGeometry(0.19, 0.008, 6, 40, Math.PI * 1.1), this.m.leather);
    strap.position.copy(c).add(V(0, -0.05, 0.0));
    strap.rotation.set(Math.PI / 2, 0.5, 0.9);
    const w2 = new THREE.Group();
    w2.add(strap);
    attachGroup(r, 'Spine2', w2);
    this.cache.set('quiver', [wrap, w2]);
    return [wrap, w2];
  }

  // ------------------------------------------------------------------ joias
  jewelry(kind) {
    const key = `jewel:${kind}`;
    if (this.cache.has(key)) return this.cache.get(key);
    const r = this.rig;
    const m = this.m;
    const out = [];
    const ringMesh = (rad, tube) => new THREE.Mesh(new THREE.TorusGeometry(rad, tube, 10, 36), m.jewel);
    const orient = (obj, axis) => obj.quaternion.setFromUnitVectors(V(0, 0, 1), axis.clone().normalize());
    if (kind === 'ring') {
      for (const S of ['Left', 'Right']) {
        const a = r.restPos(`${S}HandRing1`);
        const b = r.restPos(`${S}HandRing2`);
        if (!a || !b) continue;
        const g = new THREE.Group();
        const axis = b.clone().sub(a);
        const rg = ringMesh(0.0105, 0.0032);
        rg.position.copy(a.clone().lerp(b, 0.5));
        orient(rg, axis);
        g.add(rg);
        const gm = gem(0.0075, m);
        gm.position.copy(rg.position).add(V(0, 0.011, 0.0));
        g.add(gm);
        mergeByMaterial(g);
        attachGroup(r, `${S}HandRing1`, g);
        out.push(g);
      }
    }
    if (kind === 'bracelet') {
      for (const S of ['Left', 'Right']) {
        const a = r.restPos(`${S}ForeArm`);
        const b = r.restPos(`${S}Hand`);
        const axis = b.clone().sub(a);
        const g = new THREE.Group();
        const c = a.clone().lerp(b, 0.9);
        const rg = ringMesh(0.034, 0.006);
        rg.position.copy(c);
        orient(rg, axis);
        g.add(rg);
        const rg2 = ringMesh(0.034, 0.003);
        rg2.position.copy(a.clone().lerp(b, 0.82));
        orient(rg2, axis);
        g.add(rg2);
        const gm = gem(0.014, m);
        gm.position.copy(c).add(V(0, 0.04, 0));
        g.add(gm);
        mergeByMaterial(g);
        attachGroup(r, `${S}ForeArm`, g);
        out.push(g);
      }
    }
    if (kind === 'necklace') {
      const n = r.restPos('Neck');
      const g = new THREE.Group();
      const chain = new THREE.Mesh(new THREE.TorusGeometry(0.085, 0.0035, 8, 48), m.jewel);
      chain.position.copy(n).add(V(0, -0.075, 0.02));
      chain.rotation.x = Math.PI / 2 - 0.5;
      chain.scale.set(1, 1.05, 1);
      g.add(chain);
      const pend = gem(0.022, m);
      pend.position.copy(n).add(V(0, -0.145, 0.088));
      g.add(pend);
      const bail = new THREE.Mesh(new THREE.TorusGeometry(0.013, 0.003, 6, 16), m.jewel);
      bail.position.copy(n).add(V(0, -0.118, 0.082));
      g.add(bail);
      mergeByMaterial(g);
      attachGroup(r, 'Spine2', g);
      out.push(g);
    }
    if (kind === 'crown') {
      const { head, h, eye } = { head: r.restPos('Head'), h: 0.2, eye: r.anchors.eye };
      const g = new THREE.Group();
      const y = eye.y + 0.058;
      const band = new THREE.Mesh(new THREE.TorusGeometry(1, 0.0075, 8, 56), m.jewel);
      band.rotation.x = Math.PI / 2;
      band.scale.set(0.098, 0.108, 1); // x largura, y profundidade (antes de girar)
      band.position.set(head.x, y, head.z - 0.012);
      g.add(band);
      for (let i = 0; i < 7; i++) {
        const a = Math.PI * (0.12 + (i / 6) * 0.76); // arco frontal
        const sp = new THREE.Mesh(new THREE.ConeGeometry(0.0095, 0.034 + (i === 3 ? 0.02 : 0), 6), m.jewel);
        sp.position.set(head.x + Math.cos(a) * 0.1, y + 0.02, head.z - 0.012 + Math.sin(a) * 0.112);
        g.add(sp);
      }
      const gm = gem(0.0165, m);
      gm.position.set(head.x, y + 0.002, head.z - 0.012 + 0.114);
      g.add(gm);
      mergeByMaterial(g);
      attachGroup(r, 'Head', g);
      out.push(g);
    }
    this.cache.set(key, out);
    return out;
  }

  // ------------------------------------------------------------------ aplicar estado
  setVisible(list, v) { for (const o of list) o.visible = v; }

  apply(state) {
    const e = state.equip;
    const c = state.colors;
    const m = this.m;
    m.metal.color.set(c.metal);
    m.leather.color.set(c.leather);
    m.jewel.color.set(c.jewelry);
    m.gem.color.set(c.gem); m.gem.emissive.set(c.gem);
    m.gemGlow.color.set(c.gem); m.gemGlow.emissive.set(c.gem);
    m.book.color.set(c.cloth);

    // armadura por peça
    for (const slot of Object.keys(SLOT_BONE_OFFSET)) {
      for (const style of ['leather', 'plate']) {
        const want = e.armor[slot] === style;
        const exists = this.cache.has(`shell:${slot}:${style}`) && this.cache.has(`extra:${slot}:${style}`);
        if (!want && !exists) continue;
        this.setVisible(this.shell(slot, style), want);
        this.setVisible(this.extras(slot, style), want);
      }
    }
    // roupas (túnica/calça adicionais ao conjunto básico em parts.buildClothing)
    for (const k of ['tunic', 'pants']) {
      const want = e.outfit === 'tunic';
      const key = `cloth:${k}`;
      if (!want && !this.cache.has(key)) continue;
      if (!this.cache.has(key)) {
        const mesh = bodyShell(this.body, this.regions[k], this.mats.cloth, k === 'tunic' ? 0.009 : 0.008);
        this.cache.set(key, mesh ? [mesh] : []);
      }
      this.setVisible(this.cache.get(key), want);
    }

    // mão direita / esquerda
    const hand = (S, id) => {
      for (const k of this.cache.keys()) if (k.startsWith(`held:${S}:`) || k.startsWith(`strap:${S}:`)) this.setVisible(this.cache.get(k), false);
      if (!id || id === 'none') return;
      const list = id.startsWith('shield') ? this.strapped(S, id) : this.held(S, id);
      this.setVisible(list, true);
    };
    hand('Right', e.main);
    hand('Left', e.off);
    const quiver = e.quiver || e.off === 'bow';
    if (quiver || this.cache.has('quiver')) this.setVisible(this.quiver(), quiver);

    for (const k of ['ring', 'necklace', 'bracelet', 'crown']) {
      const want = !!e.jewelry[k];
      if (!want && !this.cache.has(`jewel:${k}`)) continue;
      this.setVisible(this.jewelry(k), want);
    }
  }

  /** Quais mãos seguram algo (para fechar os dedos). */
  grip(state) {
    const e = state.equip;
    return { Right: e.main && e.main !== 'none', Left: !!e.off && e.off !== 'none' && !e.off.startsWith('shield') };
  }
}
