import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { GLTFExporter } from 'three/examples/jsm/exporters/GLTFExporter.js';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { Rig } from './rig.js';
import { buildClipDefs, buildClips } from './poses.js';
import { createMaterials, buildHair, buildOrc, buildWolf, buildClothing, buildFaceSurface } from './parts.js';
import { BASES, RACES } from './presets.js';
import { Equipment, createEquipMaterials } from './equipment.js';
import { RoomEnvironment } from 'three/examples/jsm/environments/RoomEnvironment.js';

const TARGET_HEIGHT = 1.8;
const clamp = (v, a, b) => Math.min(b, Math.max(a, v));

/** Normaliza uma textura de cor para luminância (mantém detalhes, permite tingir com qualquer cor). */
function lumaTexture(tex, mean = 0.82) {
  const img = tex.image;
  const w = img.width, h = img.height;
  const c = document.createElement('canvas');
  c.width = w; c.height = h;
  const ctx = c.getContext('2d');
  ctx.drawImage(img, 0, 0);
  const data = ctx.getImageData(0, 0, w, h);
  const px = data.data;
  let sum = 0;
  const lum = new Float32Array(w * h);
  for (let i = 0; i < w * h; i++) {
    const l = (0.2126 * px[i * 4] + 0.7152 * px[i * 4 + 1] + 0.0722 * px[i * 4 + 2]) / 255;
    lum[i] = l; sum += l;
  }
  const k = mean / (sum / (w * h) || 1);
  for (let i = 0; i < w * h; i++) {
    const v = clamp(lum[i] * k, 0, 1) * 255;
    px[i * 4] = px[i * 4 + 1] = px[i * 4 + 2] = v;
  }
  ctx.putImageData(data, 0, 0);
  const t = new THREE.CanvasTexture(c);
  t.flipY = tex.flipY; t.colorSpace = THREE.SRGBColorSpace; t.wrapS = tex.wrapS; t.wrapT = tex.wrapT;
  t.anisotropy = 8;
  return t;
}

/** Troca a cor da íris preservando esclera/pupila/sombras: só pixels saturados mudam de matiz. */
function recolorEye(srcTex, color) {
  const img = srcTex.image;
  const w = img.width, h = img.height;
  const c = document.createElement('canvas');
  c.width = w; c.height = h;
  const ctx = c.getContext('2d');
  ctx.drawImage(img, 0, 0);
  const data = ctx.getImageData(0, 0, w, h);
  const px = data.data;
  const target = {}; new THREE.Color(color).getHSL(target);
  const tmp = new THREE.Color();
  const hsl = {};
  for (let i = 0; i < w * h; i++) {
    tmp.setRGB(px[i * 4] / 255, px[i * 4 + 1] / 255, px[i * 4 + 2] / 255, THREE.SRGBColorSpace);
    tmp.getHSL(hsl, THREE.SRGBColorSpace);
    if (hsl.s > 0.22 && hsl.l > 0.04) {
      const k = clamp((hsl.s - 0.22) / 0.2, 0, 1); // mistura suave nas bordas da íris
      const ns = clamp(hsl.s * (target.s / 0.5), 0, 1);
      const nl = clamp(hsl.l * (target.l / 0.4), 0, 0.95);
      tmp.setHSL(target.h, ns, nl, THREE.SRGBColorSpace);
      px[i * 4] = Math.round((px[i * 4] + (tmp.r * 255 - px[i * 4]) * k));
      px[i * 4 + 1] = Math.round((px[i * 4 + 1] + (tmp.g * 255 - px[i * 4 + 1]) * k));
      px[i * 4 + 2] = Math.round((px[i * 4 + 2] + (tmp.b * 255 - px[i * 4 + 2]) * k));
    }
  }
  ctx.putImageData(data, 0, 0);
  const t = new THREE.CanvasTexture(c);
  t.flipY = srcTex.flipY; t.colorSpace = THREE.SRGBColorSpace; t.anisotropy = 8;
  t.wrapS = srcTex.wrapS; t.wrapT = srcTex.wrapT;
  return t;
}

export class CharacterEngine {
  constructor(container, { onStatus } = {}) {
    this.container = container;
    this.onStatus = onStatus || (() => {});
    this.loader = new GLTFLoader();
    this._last = performance.now();
    this.model = null;
    this.mixer = null;
    this.actions = {};
    this.current = 'Idle';
    this.state = null;
    this.baseId = null;
    this.disposed = false;
    this._initScene();
    this._loop = this._loop.bind(this);
    this.renderer.setAnimationLoop(this._loop);
  }

  // ------------------------------------------------------------------ cena
  _initScene() {
    const w = this.container.clientWidth || 800;
    const h = this.container.clientHeight || 600;
    this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false, preserveDrawingBuffer: true });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.setSize(w, h);
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.05;
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFShadowMap;
    this.container.appendChild(this.renderer.domElement);

    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color('#0e1118');
    this.scene.fog = new THREE.Fog('#0e1118', 8, 18);
    const pmrem = new THREE.PMREMGenerator(this.renderer);
    this.scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;
    this.scene.environmentIntensity = 0.5;

    this.camera = new THREE.PerspectiveCamera(32, w / h, 0.05, 60);
    this.camera.position.set(0.6, 1.35, 4.4);

    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    this.controls.target.set(0, 0.95, 0);
    this.controls.enableDamping = true;
    this.controls.minDistance = 1.2;
    this.controls.maxDistance = 9;
    this.controls.maxPolarAngle = Math.PI * 0.52;
    this.controls.update();

    this.scene.add(new THREE.HemisphereLight('#bcd0ff', '#2a2230', 0.9));
    const key = new THREE.DirectionalLight('#fff1dd', 2.6);
    key.position.set(2.8, 4.5, 3.2);
    key.castShadow = true;
    key.shadow.mapSize.set(2048, 2048);
    Object.assign(key.shadow.camera, { left: -2.5, right: 2.5, top: 3, bottom: -1, near: 0.5, far: 14 });
    key.shadow.bias = -0.0004;
    this.scene.add(key);
    const rim = new THREE.DirectionalLight('#7c9cff', 1.6);
    rim.position.set(-3, 2.5, -3);
    this.scene.add(rim);

    const floor = new THREE.Mesh(
      new THREE.CircleGeometry(3.2, 64),
      new THREE.MeshStandardMaterial({ color: '#171b25', roughness: 0.9, metalness: 0 }),
    );
    floor.rotation.x = -Math.PI / 2;
    floor.receiveShadow = true;
    this.scene.add(floor);
    const ring = new THREE.Mesh(
      new THREE.RingGeometry(1.0, 1.015, 96),
      new THREE.MeshBasicMaterial({ color: '#7c5cff', transparent: true, opacity: 0.55 }),
    );
    ring.rotation.x = -Math.PI / 2;
    ring.position.y = 0.002;
    this.scene.add(ring);

    this._ro = new ResizeObserver(() => this.resize());
    this._ro.observe(this.container);
  }

  resize() {
    const w = this.container.clientWidth, h = this.container.clientHeight;
    if (!w || !h) return;
    this.renderer.setSize(w, h);
    this.camera.aspect = w / h;
    this.camera.updateProjectionMatrix();
  }

  _loop() {
    const now = performance.now();
    const dt = Math.min((now - this._last) / 1000, 0.1);
    this._last = now;
    if (this.mixer) this.mixer.update(dt);
    this.controls.update();
    this.renderer.render(this.scene, this.camera);
  }

  dispose() {
    this.disposed = true;
    this.renderer.setAnimationLoop(null);
    this._ro.disconnect();
    this._unloadModel();
    this.controls.dispose();
    this.renderer.dispose();
    this.renderer.domElement.remove();
  }

  // ------------------------------------------------------------------ modelo
  _unloadModel() {
    if (!this.model) return;
    this.mixer?.stopAllAction();
    this.scene.remove(this.holder);
    this.holder.traverse((o) => {
      if (o.isMesh) {
        o.geometry?.dispose?.();
      }
    });
    this.model = null; this.holder = null; this.rig = null; this.mixer = null; this.actions = {};
  }

  async loadBase(baseId) {
    this.onStatus({ loading: true, message: 'Carregando modelo 3D…' });
    const cfg = BASES[baseId];
    const gltf = await this.loader.loadAsync(cfg.url);
    if (this.disposed) return;
    this._unloadModel();
    this.baseId = baseId;

    const model = gltf.scene;
    const holder = new THREE.Group();
    holder.add(model);
    this.scene.add(holder);
    model.traverse((o) => {
      if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; o.frustumCulled = false; }
    });

    // 1) normaliza a escala para ~1,8 m e apoia os pés no chão
    const meshes = [];
    model.traverse((o) => o.isSkinnedMesh && meshes.push(o));
    const measure = () => {
      holder.updateMatrixWorld(true);
      const box = new THREE.Box3();
      for (const m of meshes) {
        m.computeBoundingBox();
        box.union(m.boundingBox.clone().applyMatrix4(m.matrixWorld));
      }
      return box;
    };
    let box = measure();
    model.scale.multiplyScalar(TARGET_HEIGHT / (box.max.y - box.min.y));
    box = measure();
    model.position.y -= box.min.y;
    holder.updateMatrixWorld(true);

    this.model = model;
    this.holder = holder;
    this.rig = new Rig(model);
    this.rig.anchors = this._faceAnchorsFromMeshes(meshes, box);
    // distância do osso do pé até a sola (para o ajuste de contato com o chão)
    this.soleOffset = this._footY() - 0;
    this.meshes = meshes;
    this._setupMaterials();
    this.mats = createMaterials();
    const body = this.slots.skin.find((x) => x.mesh.isSkinnedMesh)?.mesh;
    buildFaceSurface(this.rig, body);
    this.orcParts = buildOrc(this.rig, this.mats);
    this.wolfParts = buildWolf(this.rig, this.mats);
    this.hair = buildHair(this.rig, this.mats, body);
    this.clothes = body ? buildClothing(this.rig, body, this.mats, baseId === 'female') : [];
    this.equipment = new Equipment(this.rig, body, this.mats, createEquipMaterials());
    this.mixer = new THREE.AnimationMixer(model);
    this.actions = {};
    this._clipKey = null;
    this.onStatus({ loading: false, message: '' });
  }

  _footY() {
    const r = this.rig;
    let y = Infinity;
    const wp = new THREE.Vector3();
    for (const k of ['LeftToeBase', 'RightToeBase', 'LeftFoot', 'RightFoot', 'LeftToe_End', 'RightToe_End']) {
      if (!r.has(k)) continue;
      r.bones[k].getWorldPosition(wp);
      y = Math.min(y, wp.y);
    }
    return y;
  }

  // ------------------------------------------------------------------ materiais
  _setupMaterials() {
    this.slots = { skin: [], eyes: [], brows: [] };
    const seen = new Set();
    for (const m of this.meshes) {
      const arr = Array.isArray(m.material) ? m.material : [m.material];
      for (const mat of arr) {
        if (seen.has(mat)) continue;
        seen.add(mat);
        const n = mat.name || '';
        if (/^MI_Superhero/.test(n)) this.slots.skin.push({ mat, mesh: m });
        else if (n === 'MI_Eyes') this.slots.eyes.push({ mat, mesh: m, src: mat.map });
        else if (/^MI_Hair/.test(n)) this.slots.brows.push({ mat, mesh: m });
      }
    }
    for (const s of this.slots.skin) {
      if (s.mat.map) s.mat.map = lumaTexture(s.mat.map);
      s.mat.needsUpdate = true;
    }
    this._eyeColor = null;
  }

  /** Posição dos olhos / topo da cabeça a partir das malhas (o esqueleto UE não tem ossos de olhos). */
  _faceAnchorsFromMeshes(meshes, bodyBox) {
    const eyes = meshes.find((m) => m.material?.name === 'MI_Eyes');
    const out = { topY: bodyBox.max.y };
    if (eyes) {
      eyes.computeBoundingBox();
      const b = eyes.boundingBox.clone().applyMatrix4(eyes.matrixWorld);
      const size = b.getSize(new THREE.Vector3());
      out.eye = b.getCenter(new THREE.Vector3());
      out.eyeDist = Math.max(0.045, size.x - size.y);
    }
    return out;
  }

  // ------------------------------------------------------------------ aplicar estado
  /** Aplica o estado completo da UI ao personagem. */
  apply(state) {
    if (!this.model) return;
    const prev = this.state;
    this.state = state;
    const race = RACES[state.race];

    // cores
    const skin = new THREE.Color(state.colors.skin);
    for (const s of this.slots.skin) s.mat.color.copy(skin);
    this.mats.partSkin.color.copy(skin);
    this.mats.hair.color.set(state.colors.hair);
    for (const s of this.slots.brows) s.mat.color.set(state.colors.hair).multiplyScalar(1.4);
    if (this.slots.eyes.length && this._eyeColor !== state.colors.eyes) {
      this._eyeColor = state.colors.eyes;
      for (const s of this.slots.eyes) {
        if (!s.src?.image) continue;
        const tex = recolorEye(s.src, state.colors.eyes);
        if (s.mat.map && s.mat.map !== s.src) s.mat.map.dispose();
        s.mat.map = tex; s.mat.needsUpdate = true;
      }
    }

    // visibilidade das peças
    for (const c of this.clothes) c.visible = state.equip.outfit === 'basic';
    this.equipment.apply(state);
    this.mats.cloth.color.set(state.colors.cloth);
    for (const o of this.hair.short) o.visible = state.hair === 'short';
    for (const o of this.hair.long) o.visible = state.hair === 'long';
    for (const g of this.orcParts) g.visible = race.parts.includes('orc');
    for (const g of this.wolfParts) g.visible = race.parts.includes('wolf');

    // proporções
    const eff = this._effective(state);
    this._applyBody(eff);
    this._frame(eff.height);

    // animações (reconstrói se a postura/pernas mudaram)
    const grip = this.equipment.grip(state);
    const key = JSON.stringify([state.race, eff.legs.toFixed(3), eff.hipsBase.toFixed(3), !!grip.Left, !!grip.Right]);
    if (key !== this._clipKey) {
      this._clipKey = key;
      this._buildActions(race.posture, eff.hipsBase, grip);
    }
    this.play(state.anim, !prev);
    this._fitGround();
  }

  _effective(state) {
    const s = state.sliders;
    const m = RACES[state.race].mods;
    const eff = {
      height: s.height * m.height,
      muscle: clamp(s.muscle + m.muscle, 0, 1.4),
      fat: clamp(s.fat + m.fat, 0, 1.2),
      chest: s.chest * m.chest,
      head: s.head * m.head,
      arms: s.arms * m.arms,
      legs: s.legs * m.legs,
    };
    // quando as pernas ficam mais longas/curtas o quadril precisa subir/descer para os pés tocarem o chão
    const hipsY = this.rig.restPos('Hips').y;
    eff.hipsBase = (hipsY - this.soleOffset) * (eff.legs - 1);
    return eff;
  }

  /** Mantém a câmera enquadrando o personagem quando a altura muda (preserva a órbita do usuário). */
  _frame(height) {
    const ty = 0.53 * TARGET_HEIGHT * height;
    const dy = ty - this.controls.target.y;
    if (Math.abs(dy) < 1e-4) return;
    this.controls.target.y += dy;
    this.camera.position.y += dy;
    this.controls.update();
  }

  _applyBody(eff) {
    const r = this.rig;
    const { muscle: m, fat: f } = eff;
    const nets = {};
    const iso = (v) => [v, v, v];
    const hip = 1 + 0.1 * f + 0.05 * m;
    nets.Hips = iso(hip);
    nets.Spine2 = iso((1 + 0.12 * m + 0.06 * f) * eff.chest);
    nets.Neck = iso(1 + 0.12 * m);
    nets.Head = iso(eff.head);
    const tArm = 1 + 0.38 * m + 0.14 * f;
    const tLeg = 1 + 0.28 * m + 0.22 * f;
    for (const S of ['Left', 'Right']) {
      if (r.has(`${S}Arm`)) nets[`${S}Arm`] = r.limbNet(`${S}Arm`, eff.arms, tArm);
      if (r.has(`${S}Hand`)) nets[`${S}Hand`] = iso(1 + 0.12 * m);
      if (r.has(`${S}UpLeg`)) nets[`${S}UpLeg`] = r.limbNet(`${S}UpLeg`, eff.legs, tLeg);
      if (r.has(`${S}Foot`)) nets[`${S}Foot`] = iso(1);
    }
    r.applyScales(nets);
    this.holder.scale.setScalar(eff.height);
  }

  /** Encosta a sola no chão considerando a escala atual (pose Idle estática). */
  _fitGround() {
    const r = this.rig;
    // mede a altura do pé na pose de repouso das pernas retas (quadril já compensado)
    const idle = this.defs?.Idle;
    if (!idle) return;
    const saved = [];
    for (const k of r.order) saved.push([r.bones[k].quaternion.clone()]);
    const savedPos = r.bones.Hips.position.clone();
    this.holder.position.y = 0;
    r.applyPose(r.solve(idle.frames[0].spec, idle.frames[0].off));
    const y = this._footY();
    r.order.forEach((k, i) => r.bones[k].quaternion.copy(saved[i][0]));
    r.bones.Hips.position.copy(savedPos);
    this.holder.position.y = -(y - this.soleOffset * this.holder.scale.y);
    this.holder.updateMatrixWorld(true);
  }

  // ------------------------------------------------------------------ animações
  _buildActions(posture, hipsBase, grip) {
    const time = this.actions[this.current]?.time || 0;
    this.mixer.stopAllAction();
    for (const c of Object.values(this.clips || {})) this.mixer.uncacheClip(c);
    this.defs = buildClipDefs(this.rig, { posture, hipsBase, bodyH: TARGET_HEIGHT, grip });
    this.clips = buildClips(this.rig, this.defs);
    this.actions = {};
    for (const [name, clip] of Object.entries(this.clips)) {
      const a = this.mixer.clipAction(clip);
      a.setLoop(THREE.LoopRepeat, Infinity);
      this.actions[name] = a;
    }
    const cur = this.actions[this.current];
    if (cur) { cur.reset().play(); cur.time = time % cur.getClip().duration; }
  }

  play(name, immediate = false) {
    const next = this.actions[name];
    if (!next) return;
    if (name === this.current && next.isRunning()) return;
    const prev = this.actions[this.current];
    next.reset().play();
    if (prev && prev !== next && !immediate) next.crossFadeFrom(prev, 0.3, false);
    else if (prev && prev !== next) prev.stop();
    this.current = name;
  }

  // ------------------------------------------------------------------ exportação
  /**
   * Exporta o personagem final (malha + esqueleto + 4 animações) em GLB ou GLTF.
   * @param {'glb'|'gltf'} format
   * @returns {Promise<Blob>}
   */
  async export(format = 'glb') {
    if (!this.model) throw new Error('Modelo não carregado');
    // exporta na pose de repouso (bind) com as animações como clipes separados
    this.mixer.stopAllAction();
    this.rig.resetPose();
    const hips = this.rig.rest.Hips;
    this.rig.bones.Hips.position.copy(hips.p);
    this.holder.updateMatrixWorld(true);

    const exporter = new GLTFExporter();
    const clips = Object.values(this.clips);
    // o grupo exportado leva a escala/altura atual do personagem
    const target = this.holder;
    try {
      const result = await exporter.parseAsync(target, {
        binary: format === 'glb',
        animations: clips,
        onlyVisible: true,
        trs: false,
        maxTextureSize: 2048,
      });
      if (format === 'glb') return new Blob([result], { type: 'model/gltf-binary' });
      return new Blob([JSON.stringify(result)], { type: 'model/gltf+json' });
    } finally {
      // retoma a animação
      const cur = this.actions[this.current];
      cur?.reset().play();
      this._fitGround();
    }
  }
}
