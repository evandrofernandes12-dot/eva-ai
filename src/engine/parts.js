import * as THREE from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';

const Y = new THREE.Vector3(0, 1, 0);
const V = (x, y, z) => new THREE.Vector3(x, y, z);

/** Âncoras anatômicas (espaço do modelo, pose de repouso) usadas para posicionar as partes. */
export function faceAnchors(rig) {
  const head = rig.restPos('Head');
  const A = rig.anchors || {};
  const top = rig.restPos('HeadTop_End') || (A.topY ? V(head.x, A.topY, head.z) : head.clone().add(V(0, 0.2, 0)));
  const h = Math.max(0.12, top.y - head.y);
  const le = rig.restPos('LeftEye');
  const re = rig.restPos('RightEye');
  let eye, d;
  if (le && re) {
    eye = le.clone().add(re).multiplyScalar(0.5);
    d = le.distanceTo(re);
  } else if (A.eye) {
    eye = A.eye.clone();
    d = A.eyeDist;
  } else {
    d = 0.062;
    eye = head.clone().add(V(0, h * 0.62, h * 0.4));
  }
  return { head, top, h, eye, d };
}

/** Cria rig.surfZ(x, y): z da superfície frontal do rosto (a partir dos vértices da cabeça na pose de repouso). */
export function buildFaceSurface(rig, bodyMesh) {
  const { head, eye } = faceAnchors(rig);
  bodyMesh.updateWorldMatrix(true, false);
  const pos = bodyMesh.geometry.attributes.position;
  const t = new THREE.Vector3();
  const pts = [];
  for (let i = 0; i < pos.count; i++) {
    bodyMesh.getVertexPosition(i, t).applyMatrix4(bodyMesh.matrixWorld);
    if (t.y > head.y - 0.03 && t.z > -0.02) pts.push(t.x, t.y, t.z);
  }
  rig.surfZ = (x, y, r = 0.014) => {
    let best = -Infinity;
    for (let i = 0; i < pts.length; i += 3) {
      if (Math.abs(pts[i] - x) < r && Math.abs(pts[i + 1] - y) < r && pts[i + 2] > best) best = pts[i + 2];
    }
    return best === -Infinity ? eye.z + 0.02 : best;
  };
}

/** Mescla as malhas de um grupo por material (menos draw calls / nós no arquivo exportado). */
function mergeByMaterial(group) {
  group.updateMatrix();
  const buckets = new Map();
  for (const child of [...group.children]) {
    if (!child.isMesh) continue;
    child.updateMatrix();
    const g = child.geometry.index ? child.geometry.toNonIndexed() : child.geometry.clone();
    g.applyMatrix4(child.matrix);
    for (const name of Object.keys(g.attributes)) if (!['position', 'normal', 'uv'].includes(name)) g.deleteAttribute(name);
    if (!buckets.has(child.material)) buckets.set(child.material, []);
    buckets.get(child.material).push(g);
    group.remove(child);
    child.geometry.dispose();
  }
  for (const [mat, geos] of buckets) {
    const merged = mergeGeometries(geos, false);
    const mesh = new THREE.Mesh(merged, mat);
    mesh.castShadow = true;
    group.add(mesh);
  }
  return group;
}

/** Converte um grupo criado em coordenadas do modelo para o espaço local do osso e o anexa. */
function attachGroup(rig, boneKey, group) {
  const bone = rig.bones[boneKey];
  bone.updateWorldMatrix(true, false);
  const inv = bone.matrixWorld.clone().invert();
  group.matrixAutoUpdate = true;
  inv.decompose(group.position, group.quaternion, group.scale);
  bone.add(group);
  return group;
}

const cone = (r, len, mat, seg = 12) => new THREE.Mesh(new THREE.ConeGeometry(r, len, seg), mat);
const ball = (r, mat) => new THREE.Mesh(new THREE.SphereGeometry(r, 20, 14), mat);

function pointCone(mesh, base, dir) {
  // cone cujo eixo +Y aponta na direção `dir`, com a base em `base`
  const d = dir.clone().normalize();
  const len = mesh.geometry.parameters.height;
  mesh.quaternion.setFromUnitVectors(Y, d);
  mesh.position.copy(base).addScaledVector(d, len / 2);
  return mesh;
}

export function createMaterials() {
  const std = (color, extra = {}) => new THREE.MeshStandardMaterial({ color, roughness: 0.7, metalness: 0, ...extra });
  return {
    hair: std('#3a2519', { roughness: 0.55 }),
    partSkin: std('#6f9a45', { roughness: 0.75 }),
    tusk: std('#e9e1c9', { roughness: 0.45 }),
    claw: std('#1b1612', { roughness: 0.4 }),
    nose: std('#0c0a09', { roughness: 0.35 }),
    inner: std('#3b2430', { roughness: 0.8 }),
    cloth: std('#2b3a55', { roughness: 0.85, side: THREE.DoubleSide }),
  };
}

/**
 * Roupa "casca": copia os triângulos do corpo dentro de uma região e os afasta ~6 mm pela normal.
 * É um SkinnedMesh que compartilha o esqueleto, então deforma junto com a escala/animação.
 */
function bodyShell(src, test, mat, offset = 0.006) {
  src.updateWorldMatrix(true, false);
  const g = src.geometry;
  const pos = g.attributes.position;
  const t = new THREE.Vector3();
  const ok = new Uint8Array(pos.count);
  for (let i = 0; i < pos.count; i++) {
    src.getVertexPosition(i, t).applyMatrix4(src.matrixWorld);
    ok[i] = test(t) ? 1 : 0;
  }
  const idx = g.index.array;
  const keep = [];
  for (let i = 0; i < idx.length; i += 3) {
    if (ok[idx[i]] && ok[idx[i + 1]] && ok[idx[i + 2]]) keep.push(idx[i], idx[i + 1], idx[i + 2]);
  }
  if (!keep.length) return null;
  const ng = g.clone();
  const p = ng.attributes.position;
  const n = ng.attributes.normal;
  for (let i = 0; i < p.count; i++) p.setXYZ(i, p.getX(i) + n.getX(i) * offset, p.getY(i) + n.getY(i) * offset, p.getZ(i) + n.getZ(i) * offset);
  ng.setIndex(keep);
  const m = new THREE.SkinnedMesh(ng, mat);
  m.position.copy(src.position); m.quaternion.copy(src.quaternion); m.scale.copy(src.scale);
  src.parent.add(m);
  m.bind(src.skeleton, src.bindMatrix);
  m.frustumCulled = false;
  m.castShadow = true;
  m.receiveShadow = true;
  return m;
}

export function buildClothing(rig, bodyMesh, mats, female) {
  const hips = rig.restPos('Hips');
  const chest = rig.restPos('Spine2');
  const out = [];
  out.push(bodyShell(bodyMesh, (p) => p.y < hips.y + 0.07 && p.y > hips.y - 0.31, mats.cloth, 0.007));
  if (female) {
    out.push(bodyShell(bodyMesh, (p) => Math.abs(p.x) < 0.155 && p.y > chest.y - 0.07 && p.y < chest.y + 0.12 && p.z > -0.2, mats.cloth, 0.008));
  }
  return out.filter(Boolean);
}

/**
 * Cabelo: casca copiada do couro cabeludo da malha do corpo (linha do cabelo por região),
 * mais painéis traseiros/laterais no estilo "longo". Tudo segue o osso da cabeça.
 */
export function buildHair(rig, mats, bodyMesh) {
  const { head, top, eye, d } = faceAnchors(rig);
  const ey = eye.y;
  const lerp = (a, b, t) => a + (b - a) * Math.min(1, Math.max(0, t));
  const make = (backDrop) => (p) => {
    if (p.y < ey - 0.2) return false;
    const x = Math.abs(p.x);
    // altura mínima do cabelo em função de z (testa → têmpora → nuca)
    let thr;
    if (p.z >= 0.06) thr = ey + 0.066;
    else if (p.z >= -0.02) thr = ey + lerp(0.034, 0.066, (p.z + 0.02) / 0.08);
    else thr = ey + lerp(backDrop, 0.034, (p.z + 0.1) / 0.08);
    thr += x > 0.075 ? 0.004 : 0; // contorno das orelhas
    return p.y > thr && p.z < 0.115 && (p.y > ey + 0.02 || x < 0.095) && p.y > head.y - 0.02;
  };
  const long = new THREE.Group();
  const sm = bodyShell(bodyMesh, make(-0.05), mats.hair, 0.011);
  const lm = bodyShell(bodyMesh, make(-0.13), mats.hair, 0.012);
  // painéis do cabelo longo (atrás da cabeça e dos lados do pescoço)
  const rx = Math.max(0.09, d * 1.4);
  const back = ball(1, mats.hair);
  back.scale.set(rx * 0.95, 0.2, 0.034);
  back.position.set(head.x, ey - 0.2, head.z - 0.085);
  long.add(back);
  for (const s of [-1, 1]) {
    const side = ball(1, mats.hair);
    side.scale.set(0.022, 0.17, 0.06);
    side.position.set(head.x + s * (rx * 0.88), ey - 0.13, head.z - 0.055);
    long.add(side);
  }
  mergeByMaterial(long);
  attachGroup(rig, 'Head', long);
  return { short: [sm].filter(Boolean), long: [lm, long].filter(Boolean) };
}

export function buildOrc(rig, mats) {
  const { eye, d } = faceAnchors(rig);
  const g = new THREE.Group();
  const mouthY = eye.y - 0.068;
  for (const s of [-1, 1]) {
    // presas (saem do lábio inferior, apontando para cima)
    const x = s * 0.027;
    g.add(pointCone(cone(0.0105, 0.052, mats.tusk), V(x, mouthY, rig.surfZ(x, mouthY) - 0.014), V(s * 0.08, 1, 0.22)));
    // orelhas pontudas
    g.add(pointCone(cone(0.02, 0.085, mats.partSkin), eye.clone().add(V(s * d * 1.18, -d * 0.1, -d * 0.45)), V(s * 1, 0.5, -0.45)));
  }
  // crista das sobrancelhas
  const by = eye.y + 0.024;
  const brow = ball(1, mats.partSkin);
  brow.scale.set(d * 1.0, 0.012, 0.02);
  brow.position.set(eye.x, by, rig.surfZ(0, by) - 0.009);
  g.add(brow);
  // maxilar inferior pesado
  const jy = eye.y - 0.092;
  const jaw = ball(1, mats.partSkin);
  jaw.scale.set(0.04, 0.017, 0.03);
  jaw.position.set(eye.x, jy, rig.surfZ(0, jy + 0.01) - 0.016);
  g.add(jaw);
  mergeByMaterial(g);
  attachGroup(rig, 'Head', g);
  return [g];
}

export function buildWolf(rig, mats) {
  const { head, eye, d, h } = faceAnchors(rig);
  const g = new THREE.Group();
  // focinho
  const L = 0.125;
  const z0 = rig.surfZ(0, eye.y - 0.045) - 0.03;
  const snout = new THREE.Mesh(new THREE.CylinderGeometry(0.021, 0.05, L, 24), mats.partSkin);
  snout.rotation.x = Math.PI / 2;
  snout.scale.set(1.1, 1, 0.82);
  snout.position.set(eye.x, eye.y - 0.052, z0 + L / 2);
  g.add(snout);
  const nose = ball(0.0135, mats.nose);
  nose.scale.set(1.25, 0.85, 1);
  nose.position.set(eye.x, eye.y - 0.04, z0 + L + 0.004);
  g.add(nose);
  const lowerJaw = new THREE.Mesh(new THREE.CylinderGeometry(0.016, 0.034, 0.09, 18), mats.partSkin);
  lowerJaw.rotation.x = Math.PI / 2;
  lowerJaw.scale.set(1.1, 1, 0.55);
  lowerJaw.position.set(eye.x, eye.y - 0.092, z0 + 0.05);
  g.add(lowerJaw);
  for (const s of [-1, 1]) {
    // presas
    g.add(pointCone(cone(0.006, 0.026, mats.tusk, 8), V(s * 0.02, eye.y - 0.086, z0 + L - 0.035), V(0, 1, 0.1)));
    // orelhas altas
    g.add(pointCone(cone(0.03, 0.09, mats.partSkin), eye.clone().add(V(s * d * 0.86, d * 0.6, -d * 0.45)), V(s * 0.3, 1, -0.2)));
    g.add(pointCone(cone(0.016, 0.055, mats.inner), eye.clone().add(V(s * d * 0.84, d * 0.64, -d * 0.36)), V(s * 0.3, 1, -0.2)));
  }
  mergeByMaterial(g);
  attachGroup(rig, 'Head', g);

  // juba de pelos no pescoço/ombros
  const mane = new THREE.Group();
  const neck = rig.restPos('Neck') || head;
  const n = 22;
  for (let i = 0; i < n; i++) {
    const a = (i / n) * Math.PI * 2;
    const dir = V(Math.sin(a), -0.35, Math.cos(a) * 0.9 - 0.1);
    mane.add(pointCone(cone(0.013, 0.06, mats.partSkin, 5), neck.clone().add(V(Math.sin(a) * 0.07, -0.005, Math.cos(a) * 0.065 - 0.015)), dir));
  }
  mergeByMaterial(mane);
  attachGroup(rig, 'Spine2', mane);

  // garras (cada uma presa ao osso da mão correspondente)
  const handClaws = { Left: new THREE.Group(), Right: new THREE.Group() };
  for (const S of ['Left', 'Right']) {
    for (const f of ['Thumb', 'Index', 'Middle', 'Ring', 'Pinky']) {
      const a = rig.restPos(`${S}Hand${f}3`);
      const b = rig.restPos(`${S}Hand${f}4`);
      if (!a || !b) continue;
      const dir = b.clone().sub(a).normalize();
      handClaws[S].add(pointCone(cone(0.0068, 0.04, mats.claw, 8), b.clone().addScaledVector(dir, -0.004), dir));
    }
    mergeByMaterial(handClaws[S]);
    attachGroup(rig, `${S}Hand`, handClaws[S]);
  }

  // cauda (esferas decrescentes ao longo de uma curva)
  const hips = rig.restPos('Hips');
  const tail = new THREE.Group();
  const curve = new THREE.CatmullRomCurve3([
    hips.clone().add(V(0, -0.03, -0.08)),
    hips.clone().add(V(0, -0.1, -0.22)),
    hips.clone().add(V(0, -0.26, -0.32)),
    hips.clone().add(V(0, -0.46, -0.3)),
  ]);
  const seg = 14;
  for (let i = 0; i < seg; i++) {
    const t = i / (seg - 1);
    const s = ball(0.036 * (1 - t) + 0.012, mats.partSkin);
    s.position.copy(curve.getPoint(t));
    tail.add(s);
  }
  mergeByMaterial(tail);
  attachGroup(rig, 'Hips', tail);

  return [g, mane, handClaws.Left, handClaws.Right, tail];
}
