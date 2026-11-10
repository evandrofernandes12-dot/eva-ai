import * as THREE from 'three';
import { mergeByMaterial } from './parts.js';

/**
 * Construtores de itens procedurais. Convenção de cada item (espaço local):
 * origem = centro da empunhadura, ponta/eixo longo = +Y, largura = X, espessura = Z.
 * `m` é o conjunto de materiais compartilhados (metal, couro, madeira, gema, joia, papel, corda).
 */

const mesh = (geo, mat) => {
  const o = new THREE.Mesh(geo, mat);
  o.castShadow = true;
  return o;
};
const cyl = (r0, r1, h, mat, y = 0, seg = 16) => {
  const o = mesh(new THREE.CylinderGeometry(r1, r0, h, seg), mat); // r0 embaixo, r1 em cima
  o.position.y = y;
  return o;
};

export function gem(r, m) {
  const g = new THREE.IcosahedronGeometry(r, 0);
  g.scale(1, 1.2, 1);
  return mesh(g, m.gem);
}

function flat(shape, depth, mat, bevel = 0) {
  const g = new THREE.ExtrudeGeometry(shape, {
    depth, bevelEnabled: bevel > 0, bevelSize: bevel, bevelThickness: bevel, bevelSegments: 1, curveSegments: 12,
  });
  g.translate(0, 0, -depth / 2);
  return mesh(g, mat);
}

function bladeShape(len, w, tip) {
  const s = new THREE.Shape();
  s.moveTo(-w / 2, 0);
  s.lineTo(-w / 2, len - tip);
  s.lineTo(0, len);
  s.lineTo(w / 2, len - tip);
  s.lineTo(w / 2, 0);
  s.closePath();
  return s;
}

function blade({ len, w, tip, guard, grip, gemmed }, m) {
  const g = new THREE.Group();
  g.add(cyl(grip.r, grip.r, grip.len, m.leather, 0));
  const pommel = mesh(new THREE.SphereGeometry(grip.r * 1.5, 14, 10), m.metal);
  pommel.position.y = -grip.len / 2 - 0.004;
  g.add(pommel);
  const gy = grip.len / 2 + 0.008;
  const guardMesh = mesh(new THREE.BoxGeometry(guard, 0.016, 0.026), m.metal);
  guardMesh.position.y = gy;
  g.add(guardMesh);
  const b = flat(bladeShape(len, w, tip), 0.008, m.metal, 0.0015);
  b.position.y = gy + 0.008;
  g.add(b);
  if (gemmed) {
    const gm = gem(0.011, m);
    gm.position.set(0, gy, 0.016);
    g.add(gm);
  }
  return g;
}

export const ITEMS = {
  knife: (m) => blade({ len: 0.17, w: 0.03, tip: 0.06, guard: 0.05, grip: { r: 0.012, len: 0.095 } }, m),
  shortsword: (m) => blade({ len: 0.5, w: 0.05, tip: 0.1, guard: 0.11, grip: { r: 0.0135, len: 0.11 }, gemmed: true }, m),
  longsword: (m) => blade({ len: 0.88, w: 0.058, tip: 0.14, guard: 0.17, grip: { r: 0.0145, len: 0.15 }, gemmed: true }, m),

  spear: (m) => {
    const g = new THREE.Group();
    g.add(cyl(0.013, 0.013, 1.75, m.wood, 0.32));
    const leaf = new THREE.Shape();
    leaf.moveTo(0, 0);
    leaf.quadraticCurveTo(0.045, 0.05, 0, 0.26);
    leaf.quadraticCurveTo(-0.045, 0.05, 0, 0);
    const head = flat(leaf, 0.012, m.metal, 0.002);
    head.position.y = 1.2;
    g.add(head);
    g.add(cyl(0.02, 0.02, 0.05, m.metal, 1.2));
    g.add(cyl(0.017, 0.017, 0.04, m.metal, -0.55));
    return g;
  },

  staff: (m) => {
    const g = new THREE.Group();
    g.add(cyl(0.018, 0.016, 1.65, m.wood, 0.3));
    // garra que segura o orbe
    for (let i = 0; i < 3; i++) {
      const a = (i / 3) * Math.PI * 2;
      const claw = mesh(new THREE.TorusGeometry(0.05, 0.007, 8, 16, Math.PI * 0.85), m.jewel);
      claw.position.y = 1.18;
      claw.rotation.set(0, a, Math.PI / 2 + 0.2);
      g.add(claw);
    }
    const orb = mesh(new THREE.IcosahedronGeometry(0.042, 1), m.gemGlow);
    orb.position.y = 1.22;
    g.add(orb);
    g.add(cyl(0.024, 0.02, 0.05, m.jewel, 1.14));
    return g;
  },

  bow: (m) => {
    const g = new THREE.Group();
    const curve = new THREE.CatmullRomCurve3([
      new THREE.Vector3(0, -0.58, -0.13), new THREE.Vector3(0, -0.32, -0.04), new THREE.Vector3(0, 0, 0.02),
      new THREE.Vector3(0, 0.32, -0.04), new THREE.Vector3(0, 0.58, -0.13),
    ]);
    g.add(mesh(new THREE.TubeGeometry(curve, 32, 0.012, 8), m.wood));
    g.add(cyl(0.02, 0.02, 0.11, m.leather, 0.0));
    const str = cyl(0.0022, 0.0022, 1.16, m.string, 0, 4);
    str.position.z = -0.13;
    g.add(str);
    return g;
  },

  shield_round: (m) => {
    const g = new THREE.Group();
    const r = 0.27;
    const dome = mesh(new THREE.SphereGeometry(r, 36, 12, 0, Math.PI * 2, 0, Math.PI * 0.2), m.metal);
    dome.scale.set(1, 0.38, 1);
    dome.rotation.x = Math.PI / 2;
    dome.position.z = 0.014;
    g.add(dome);
    const body = mesh(new THREE.CylinderGeometry(r, r, 0.022, 40), m.wood);
    body.rotation.x = Math.PI / 2;
    g.add(body);
    const rim = mesh(new THREE.TorusGeometry(r, 0.013, 10, 48), m.metal);
    g.add(rim);
    const boss = mesh(new THREE.SphereGeometry(0.05, 20, 12), m.metal);
    boss.position.z = 0.04;
    g.add(boss);
    const gm = gem(0.022, m);
    gm.position.z = 0.085;
    g.add(gm);
    return g;
  },

  shield_kite: (m) => {
    const g = new THREE.Group();
    const w = 0.2, h = 0.42;
    const s = new THREE.Shape();
    s.moveTo(-w, h * 0.55);
    s.lineTo(w, h * 0.55);
    s.lineTo(w, h * 0.05);
    s.quadraticCurveTo(w * 0.85, -h * 0.4, 0, -h * 0.62);
    s.quadraticCurveTo(-w * 0.85, -h * 0.4, -w, h * 0.05);
    s.closePath();
    g.add(flat(s, 0.026, m.wood, 0.01));
    const trim = new THREE.Shape();
    trim.moveTo(-0.018, h * 0.52); trim.lineTo(0.018, h * 0.52); trim.lineTo(0.018, -h * 0.55); trim.lineTo(-0.018, -h * 0.55); trim.closePath();
    const bar = flat(trim, 0.01, m.metal, 0.004);
    bar.position.z = 0.02;
    g.add(bar);
    const cross = mesh(new THREE.BoxGeometry(w * 1.7, 0.035, 0.012), m.metal);
    cross.position.set(0, h * 0.18, 0.03);
    g.add(cross);
    const gm = gem(0.024, m);
    gm.position.set(0, h * 0.18, 0.05);
    g.add(gm);
    return g;
  },

  book: (m) => {
    const g = new THREE.Group();
    const cover = mesh(new THREE.BoxGeometry(0.2, 0.28, 0.046), m.book);
    g.add(cover);
    const pages = mesh(new THREE.BoxGeometry(0.188, 0.268, 0.034), m.paper);
    pages.position.x = 0.006;
    g.add(pages);
    const spine = mesh(new THREE.BoxGeometry(0.018, 0.288, 0.052), m.leather);
    spine.position.x = -0.1;
    g.add(spine);
    const clasp = mesh(new THREE.BoxGeometry(0.03, 0.05, 0.052), m.jewel);
    clasp.position.set(0.1, 0, 0);
    g.add(clasp);
    const gm = gem(0.026, m);
    gm.position.set(0, 0, 0.034);
    g.add(gm);
    const frame = mesh(new THREE.TorusGeometry(0.045, 0.004, 6, 24), m.jewel);
    frame.position.z = 0.025;
    g.add(frame);
    return g;
  },

  quiver: (m) => {
    const g = new THREE.Group();
    const tube = mesh(new THREE.CylinderGeometry(0.06, 0.05, 0.5, 20, 1, true), m.leather);
    tube.material = m.leatherTwoSided;
    g.add(tube);
    g.add(cyl(0.05, 0.05, 0.02, m.leather, -0.25));
    const band = mesh(new THREE.TorusGeometry(0.06, 0.006, 6, 20), m.jewel);
    band.rotation.x = Math.PI / 2;
    band.position.y = 0.2;
    g.add(band);
    const offs = [[0, 0], [0.025, 0.01], [-0.025, 0.012], [0.01, -0.025], [-0.012, -0.022], [0.03, -0.02]];
    offs.forEach(([x, z], i) => {
      const a = new THREE.Group();
      a.add(cyl(0.004, 0.004, 0.62, m.wood, 0, 6));
      const tip = mesh(new THREE.ConeGeometry(0.011, 0.04, 6), m.metal);
      tip.position.y = 0.33;
      a.add(tip);
      for (let k = 0; k < 3; k++) {
        const f = mesh(new THREE.BoxGeometry(0.002, 0.07, 0.022), m.feather);
        f.position.y = -0.27;
        f.rotation.y = (k / 3) * Math.PI;
        a.add(f);
      }
      a.position.set(x, 0.2 + i * 0.01, z);
      a.rotation.z = (i - 2.5) * 0.025;
      g.add(a);
    });
    return g;
  },
};

/** Pauldrons (ombreiras) de placas: domo + aro, centrados em `c`, voltados para `out` (+X ou -X). */
export function pauldron(m, out) {
  const g = new THREE.Group();
  const inner = new THREE.Group();
  const dome = mesh(new THREE.SphereGeometry(0.118, 28, 14, 0, Math.PI * 2, 0, Math.PI * 0.56), m.metal);
  dome.scale.set(1.1, 0.9, 1);
  inner.add(dome);
  const rim = mesh(new THREE.TorusGeometry(0.116, 0.011, 8, 32), m.jewel);
  rim.rotation.x = Math.PI / 2;
  rim.position.y = 0.006;
  rim.scale.set(1.1, 1.1, 1);
  inner.add(rim);
  const st = mesh(new THREE.ConeGeometry(0.02, 0.06, 8), m.metal);
  st.position.y = 0.105;
  inner.add(st);
  inner.rotation.z = -out * 0.3;
  g.add(inner);
  return g;
}

/** Cristas de capacete de placas. */
export function helmetCrest(m) {
  const g = new THREE.Group();
  const s = new THREE.Shape();
  s.moveTo(-0.11, 0);
  s.quadraticCurveTo(-0.07, 0.07, 0.0, 0.075);
  s.quadraticCurveTo(0.07, 0.07, 0.11, 0);
  s.closePath();
  const f = flat(s, 0.012, m.metal, 0.003);
  f.rotation.y = Math.PI / 2;
  g.add(f);
  return g;
}

export function finalize(group) {
  return mergeByMaterial(group);
}
