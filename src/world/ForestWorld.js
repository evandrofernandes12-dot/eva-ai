import * as THREE from 'three';
import { RoomEnvironment } from 'three/examples/jsm/environments/RoomEnvironment.js';
import { AssetLoader } from './AssetLoader.js';
import { AnimationController } from './AnimationController.js';

/** PRNG determinístico (a floresta fica igual a cada carga). */
function rng(seed) { let s = seed >>> 0; return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296); }

const VILLAGE_R = 30;
/** Relevo suave; plano dentro da aldeia. */
export function heightAt(x, z) {
  const d = Math.hypot(x, z), flat = THREE.MathUtils.smoothstep(d, VILLAGE_R, VILLAGE_R + 22);
  const h = Math.sin(x * 0.045) * 2.2 + Math.cos(z * 0.05) * 2.0 + Math.sin((x + z) * 0.11) * 0.7 + Math.cos(x * 0.19 - z * 0.13) * 0.35;
  return h * flat;
}

export class ForestWorld {
  constructor(container) {
    this.container = container;
    const w = container.clientWidth || 800, h = container.clientHeight || 600;
    this.renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.5));
    this.renderer.setSize(w, h);
    this.renderer.shadowMap.enabled = true; this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping; this.renderer.toneMappingExposure = 1.0;
    container.appendChild(this.renderer.domElement);
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0xa8cfe8);
    this.scene.fog = new THREE.Fog(0xa8cfe8, 60, 190);
    this.camera = new THREE.PerspectiveCamera(60, w / h, 0.1, 500);
    this.clock = new THREE.Clock();
    this.assets = new AssetLoader({ renderer: this.renderer });
    this.actors = []; this.keys = {}; this.hero = null; this.disposed = false;
    this.camPos = new THREE.Vector3(); this.camYaw = 0;
    this.onKey = (e) => { this.keys[e.code] = e.type === 'keydown'; if (e.code === 'Space') e.preventDefault(); if (e.type === 'keydown' && e.code === 'Space') this.hero?.anim.play('attack', { fade: 0.1 }); };
    window.addEventListener('keydown', this.onKey); window.addEventListener('keyup', this.onKey);
    this.onResize = () => { const W = container.clientWidth, H = container.clientHeight; this.renderer.setSize(W, H); this.camera.aspect = W / H; this.camera.updateProjectionMatrix(); };
    window.addEventListener('resize', this.onResize);
  }

  /** Luz direcional com sombras + luz hemisférica (céu/chão). */
  buildLights() {
    const pm = new THREE.PMREMGenerator(this.renderer); this.scene.environment = pm.fromScene(new RoomEnvironment(), 0.04).texture; this.scene.environmentIntensity = 0.55; pm.dispose();
    const hemi = new THREE.HemisphereLight(0xcfe8ff, 0x5b7a3a, 0.85); this.scene.add(hemi);
    const sun = new THREE.DirectionalLight(0xfff0d0, 2.2);
    sun.position.set(40, 70, 30); sun.castShadow = true;
    sun.shadow.mapSize.set(2048, 2048); sun.shadow.bias = -0.0004; sun.shadow.normalBias = 0.05;
    const c = sun.shadow.camera; c.left = -45; c.right = 45; c.top = 45; c.bottom = -45; c.near = 1; c.far = 200;
    this.scene.add(sun, sun.target); this.sun = sun;
  }

  async buildTerrain() {
    const SIZE = 300, SEG = 150, g = new THREE.PlaneGeometry(SIZE, SIZE, SEG, SEG); g.rotateX(-Math.PI / 2);
    const p = g.attributes.position; for (let i = 0; i < p.count; i++) p.setY(i, heightAt(p.getX(i), p.getZ(i)));
    g.computeVertexNormals();
    const mat = await this.assets.pbr('grass', { repeat: [70, 70], color: 0xb8d8a0 });
    // textura de grama só tem albedo: rugosidade alta para parecer fosca
    mat.roughness = 0.95;
    const ground = new THREE.Mesh(g, mat); ground.receiveShadow = true; this.scene.add(ground);
    // praça da aldeia em pedra (PBR completo: albedo + normal + roughness)
    const stone = await this.assets.pbr('stone_path', { repeat: [9, 9] });
    const plaza = new THREE.Mesh(new THREE.CircleGeometry(17, 48).rotateX(-Math.PI / 2), stone); plaza.position.y = 0.04; plaza.receiveShadow = true; this.scene.add(plaza);
  }

  place(obj, x, z, { yaw = 0, y = 0 } = {}) { obj.position.set(x, heightAt(x, z) + y, z); obj.rotation.y = yaw; this.scene.add(obj); return obj; }

  async buildVillage() {
    const A = this.assets, R = rng(7);
    const house = async (id, w, ang, r) => { const { object } = await A.instance(id, { width: w }); this.place(object, Math.cos(ang) * r, Math.sin(ang) * r, { yaw: Math.atan2(-Math.cos(ang), -Math.sin(ang)) }); };
    const ring = [['House_1', 8], ['House_2', 9], ['House_3', 8], ['House_4', 7.5], ['Inn', 11], ['Blacksmith', 10], ['Mill', 10], ['Sawmill', 10], ['Stable', 10], ['House_1', 8], ['House_3', 8], ['Bell_Tower', 6]];
    await Promise.all(ring.map(([id, w], i) => house(id, w, (i / ring.length) * Math.PI * 2 + 0.2, 24 + (i % 2) * 3)));
    const props = [['Well', 3, 0, 0], ['Bonfire_Lit', 1.6, 5, 4], ['MarketStand_1', 3.4, -9, 5], ['MarketStand_2', 3.4, 9, -4], ['Cart', 3.2, -6, -9], ['Hay', 1.8, 11, 8], ['Hay', 1.8, 12.5, 9.5], ['Barrel', 1, -10.5, 8], ['Barrel', 1, -11.6, 8.8], ['Crate', 1.1, 10, -9], ['Crate', 1.1, 11.2, -9.6], ['Gazebo', 5, -14, -5]];
    await Promise.all(props.map(async ([id, w, x, z]) => { const { object } = await A.instance(id, { width: w }); this.place(object, x, z, { yaw: R() * 6 }); }));
    // cerca em arco em volta da aldeia (deixa a entrada sul aberta)
    const fence = await A.load('Fence'); void fence;
    const n = 46; const jobs = [];
    for (let i = 0; i < n; i++) { const a = (i / n) * Math.PI * 2; if (Math.abs(Math.atan2(Math.sin(a - Math.PI / 2), Math.cos(a - Math.PI / 2))) < 0.3) continue; jobs.push(A.instance('Fence', { width: 3.3 }).then(({ object }) => this.place(object, Math.cos(a) * 33.5, Math.sin(a) * 33.5, { yaw: -a + Math.PI / 2 }))); }
    await Promise.all(jobs);
  }

  async buildForest() {
    const A = this.assets, R = rng(42), trees = ['CommonTree_1', 'CommonTree_2', 'CommonTree_3', 'PineTree_1', 'PineTree_2', 'PineTree_3', 'BirchTree_1', 'BirchTree_2', 'Willow_1', 'CommonTree_Dead_1'];
    const small = ['Bush_1', 'Bush_2', 'BushBerries_1', 'Plant_1', 'Plant_2', 'Flowers', 'Grass', 'Grass_2'], rocks = ['Resource_Rock_1', 'Resource_Rock_2', 'Resource_Rock_3', 'Rock_Group'], logs = ['TreeStump', 'WoodLog'];
    const spots = (count, rmin, rmax) => { const o = []; while (o.length < count) { const a = R() * Math.PI * 2, r = rmin + R() * (rmax - rmin); o.push([Math.cos(a) * r, Math.sin(a) * r]); } return o; };
    const jobs = [];
    for (const [x, z] of spots(170, VILLAGE_R + 8, 135)) { const id = trees[Math.floor(R() * trees.length)]; jobs.push(A.instance(id, { height: 7 + R() * 6 }).then(({ object }) => this.place(object, x, z, { yaw: R() * 6.28 }))); }
    for (const [x, z] of spots(150, VILLAGE_R + 4, 125)) { const id = small[Math.floor(R() * small.length)]; jobs.push(A.instance(id, { width: 1.2 + R() * 1.4 }).then(({ object }) => this.place(object, x, z, { yaw: R() * 6.28 }))); }
    for (const [x, z] of spots(26, VILLAGE_R + 4, 120)) { const id = rocks[Math.floor(R() * rocks.length)]; jobs.push(A.instance(id, { width: 2 + R() * 3 }).then(({ object }) => this.place(object, x, z, { yaw: R() * 6.28 }))); }
    for (const [x, z] of spots(14, VILLAGE_R + 4, 90)) { const id = logs[Math.floor(R() * logs.length)]; jobs.push(A.instance(id, { width: 1.8 }).then(({ object }) => this.place(object, x, z, { yaw: R() * 6.28 }))); }
    await Promise.all(jobs);
  }

  /** Cria um ator animado: { object, anim, speed, ... }. */
  async spawn(id, { height, x, z, yaw = 0 }) {
    const { object, clips, meta } = await this.assets.instance(id, { height });
    this.place(object, x, z, { yaw });
    const anim = new AnimationController(object, clips, meta); anim.play('idle');
    const actor = { id, object, anim, meta, x, z, yaw, vel: 0, patrol: null, wp: 0 };
    this.actors.push(actor); return actor;
  }

  async buildActors() {
    this.hero = await this.spawn('Knight', { height: 1.85, x: 0, z: 18, yaw: Math.PI });
    const orc = await this.spawn('Orc', { height: 2.3, x: -22, z: 40, yaw: 0 });
    orc.patrol = [[-22, 40], [22, 44], [40, 10], [-30, 30]]; orc.speed = 1.6;
    const wolf = await this.spawn('Wolf', { height: 1.1, x: 30, z: -35 }); wolf.patrol = [[30, -35], [48, -20], [34, -52]]; wolf.speed = 2.2;
    await this.spawn('Demon', { height: 2.4, x: -34, z: -26, yaw: 0.8 });
    await this.spawn('Spider', { height: 0.9, x: 18, z: -40, yaw: 2.3 });
    await this.spawn('BlueDemon', { height: 2.2, x: -48, z: 20, yaw: 1.2 });
    await this.spawn('Velociraptor', { height: 1.6, x: 45, z: 30, yaw: -2 });
  }

  async init(onProgress = () => {}) {
    await this.assets.init();
    this.buildLights();
    onProgress('Terreno e texturas PBR…'); await this.buildTerrain();
    onProgress('Aldeia…'); await this.buildVillage();
    onProgress('Floresta…'); await this.buildForest();
    onProgress('Personagens e monstros…'); await this.buildActors();
    this.renderer.setAnimationLoop(() => this.frame());
    return this;
  }

  updateHero(dt) {
    const h = this.hero; if (!h) return;
    const k = this.keys, dx = (k.KeyD || k.ArrowRight ? 1 : 0) - (k.KeyA || k.ArrowLeft ? 1 : 0), dz = (k.KeyS || k.ArrowDown ? 1 : 0) - (k.KeyW || k.ArrowUp ? 1 : 0);
    const moving = dx || dz, run = k.ShiftLeft || k.ShiftRight;
    if (moving) {
      // direção relativa à câmera (que olha para -Z do herói)
      const f = new THREE.Vector3(0, 0, 1).applyAxisAngle(new THREE.Vector3(0, 1, 0), this.camYaw), r = new THREE.Vector3(-f.z, 0, f.x).multiplyScalar(-1);
      const dir = f.multiplyScalar(-dz).add(r.multiplyScalar(-dx)).normalize(), sp = run ? 6.5 : 3;
      h.x += dir.x * sp * dt; h.z += dir.z * sp * dt; h.yaw = Math.atan2(dir.x, dir.z);
      h.anim.play(run ? 'run' : 'walk');
    } else h.anim.play('idle');
    h.x = THREE.MathUtils.clamp(h.x, -140, 140); h.z = THREE.MathUtils.clamp(h.z, -140, 140);
    h.object.position.set(h.x, heightAt(h.x, h.z), h.z);
    h.object.rotation.y = h.yaw;
  }

  updatePatrols(dt) {
    for (const a of this.actors) {
      if (a === this.hero || !a.patrol) continue;
      const [tx, tz] = a.patrol[a.wp], dx = tx - a.x, dz = tz - a.z, d = Math.hypot(dx, dz);
      const near = this.hero && Math.hypot(this.hero.x - a.x, this.hero.z - a.z) < 6;
      if (near) { a.anim.play('attack'); a.yaw = Math.atan2(this.hero.x - a.x, this.hero.z - a.z); }
      else if (d < 0.8) { a.wp = (a.wp + 1) % a.patrol.length; a.anim.play('idle'); }
      else { a.x += (dx / d) * a.speed * dt; a.z += (dz / d) * a.speed * dt; a.yaw = Math.atan2(dx, dz); a.anim.play('walk'); }
      a.object.position.set(a.x, heightAt(a.x, a.z), a.z);
      a.object.rotation.y = a.yaw;
    }
  }

  frame() {
    if (this.disposed) return;
    const dt = Math.min(this.clock.getDelta(), 0.05);
    this.updateHero(dt); this.updatePatrols(dt);
    for (const a of this.actors) a.anim.update(dt);
    if (this.keys.KeyQ) this.camYaw += dt * 1.8; if (this.keys.KeyE) this.camYaw -= dt * 1.8;
    const h = this.hero;
    if (h) {
      if (!this.camInit) { this.camInit = true; this.camPos.set(h.x, h.object.position.y + 4.2, h.z - 8.5); }
      const hp = h.object.position, back = new THREE.Vector3(Math.sin(this.camYaw), 0, Math.cos(this.camYaw)).multiplyScalar(-8.5);
      const want = new THREE.Vector3(hp.x + back.x, hp.y + 4.2, hp.z + back.z);
      this.camPos.lerp(want, 1 - Math.pow(0.001, dt));
      this.camera.position.copy(this.camPos); this.camera.lookAt(hp.x, hp.y + 1.4, hp.z);
      this.sun.position.set(hp.x + 40, 70, hp.z + 30); this.sun.target.position.copy(hp); this.sun.target.updateMatrixWorld();
    }
    this.renderer.render(this.scene, this.camera);
  }

  dispose() {
    this.disposed = true; this.renderer.setAnimationLoop(null);
    window.removeEventListener('keydown', this.onKey); window.removeEventListener('keyup', this.onKey); window.removeEventListener('resize', this.onResize);
    this.renderer.dispose(); this.renderer.domElement.remove();
  }
}
