import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { DRACOLoader } from 'three/examples/jsm/loaders/DRACOLoader.js';
import * as SkeletonUtils from 'three/examples/jsm/utils/SkeletonUtils.js';

/**
 * Gerenciador de recursos: lê public/assets/MANIFEST.json, carrega GLB/glTF e texturas PBR de forma assíncrona,
 * guarda tudo em cache (uma única requisição por arquivo) e configura sombras/materiais automaticamente.
 */
export class AssetLoader {
  constructor({ base = import.meta.env.BASE_URL, renderer = null } = {}) {
    this.base = base.endsWith('/') ? base : base + '/';
    this.renderer = renderer;
    this.manifest = null;
    this.byId = new Map();
    this.models = new Map();   // id -> Promise<gltf>
    this.textures = new Map(); // id -> Promise<Texture>
    this.gltf = new GLTFLoader();
    const draco = new DRACOLoader(); // só é usado se algum arquivo vier comprimido (KHR_draco_mesh_compression)
    draco.setDecoderPath('https://www.gstatic.com/draco/versioned/decoders/1.5.7/');
    this.gltf.setDRACOLoader(draco);
    this.tex = new THREE.TextureLoader();
    this.maxAniso = renderer ? renderer.capabilities.getMaxAnisotropy() : 8;
  }

  async init() {
    const res = await fetch(this.base + 'assets/MANIFEST.json');
    if (!res.ok) throw new Error('MANIFEST.json não encontrado (' + res.status + ')');
    this.manifest = await res.json();
    for (const a of this.manifest.assets) this.byId.set(a.id, a);
    return this;
  }

  meta(id) { const m = this.byId.get(id); if (!m) throw new Error('Asset desconhecido: ' + id); return m; }
  list(category) { return this.manifest.assets.filter((a) => a.category === category); }

  /** Carrega (com cache) e devolve o glTF original. */
  load(id) {
    if (!this.models.has(id)) {
      const m = this.meta(id);
      this.models.set(id, this.gltf.loadAsync(this.base + m.path).then((g) => { this.prepare(g.scene); return g; }));
    }
    return this.models.get(id);
  }

  /** Cria uma instância independente (SkeletonUtils.clone preserva esqueleto e skin). Devolve { object, clips, meta }. */
  async instance(id, { height = null, width = null } = {}) {
    const g = await this.load(id), meta = this.meta(id);
    const object = SkeletonUtils.clone(g.scene);
    const wrap = new THREE.Group(); wrap.add(object); wrap.name = id;
    wrap.updateMatrixWorld(true);
    const box = AssetLoader.measure(wrap), size = box.getSize(new THREE.Vector3());
    const k = height ? height / (size.y || 1) : width ? width / (Math.max(size.x, size.z) || 1) : 1;
    object.scale.multiplyScalar(k); wrap.updateMatrixWorld(true);
    box.copy(AssetLoader.measure(wrap)); object.position.y -= box.min.y; // apoia o modelo no chão (y = 0)
    return { object: wrap, clips: g.animations, meta };
  }

  /** Caixa envolvente REAL: para malhas com esqueleto aplica os ossos aos vértices (modelos FBX2glTF vêm em centímetros). */
  static measure(root) {
    const box = new THREE.Box3(), v = new THREE.Vector3();
    root.traverse((o) => {
      if (o.isSkinnedMesh) {
        o.skeleton.update(); const pos = o.geometry.attributes.position, step = Math.max(1, Math.floor(pos.count / 3000));
        for (let i = 0; i < pos.count; i += step) { v.fromBufferAttribute(pos, i); o.applyBoneTransform(i, v); v.applyMatrix4(o.matrixWorld); box.expandByPoint(v); }
      } else if (o.isMesh) { box.expandByObject(o, true); }
    });
    return box;
  }

  /** Sombras e materiais PBR: todos os meshes projetam/recebem sombra, texturas com anisotropia e espaço de cor correto. */
  prepare(root) {
    root.traverse((o) => {
      if (!o.isMesh) return;
      o.castShadow = true; o.receiveShadow = true;
      if (o.isSkinnedMesh) o.frustumCulled = false;
      const mats = Array.isArray(o.material) ? o.material : [o.material];
      for (const m of mats) {
        if (m.map) { m.map.colorSpace = THREE.SRGBColorSpace; m.map.anisotropy = this.maxAniso; }
        if (m.isMeshStandardMaterial) { m.envMapIntensity = 0.7; if (m.metalness > 0.2) m.metalness = 0.15; if (m.roughness < 0.6) m.roughness = 0.7; } // evita o aspecto "preto" de metais sem reflexo
        if (m.transparent && m.alphaTest === 0 && m.opacity > 0.99) m.alphaTest = 0.4; // folhagem com recorte
      }
    });
  }

  texture(id, { repeat = [1, 1], srgb = false } = {}) {
    if (!this.textures.has(id)) {
      const m = this.meta(id);
      this.textures.set(id, this.tex.loadAsync(this.base + m.path));
    }
    return this.textures.get(id).then((t) => {
      const c = t.clone(); c.needsUpdate = true;
      c.wrapS = c.wrapT = THREE.RepeatWrapping; c.repeat.set(repeat[0], repeat[1]);
      c.anisotropy = this.maxAniso; c.colorSpace = srgb ? THREE.SRGBColorSpace : THREE.NoColorSpace;
      return c;
    });
  }

  /** Monta um MeshStandardMaterial a partir de um conjunto <nome>_albedo/_normal/_roughness/_bump do manifesto. */
  async pbr(name, { repeat = [1, 1], color = 0xffffff } = {}) {
    const has = (s) => this.byId.has(name + '_' + s);
    const mat = new THREE.MeshStandardMaterial({ color, roughness: 1, metalness: 0 });
    const jobs = [];
    if (has('albedo')) jobs.push(this.texture(name + '_albedo', { repeat, srgb: true }).then((t) => { mat.map = t; }));
    if (has('normal')) jobs.push(this.texture(name + '_normal', { repeat }).then((t) => { mat.normalMap = t; mat.normalScale.set(1, 1); }));
    if (has('roughness')) jobs.push(this.texture(name + '_roughness', { repeat }).then((t) => { mat.roughnessMap = t; }));
    if (has('bump')) jobs.push(this.texture(name + '_bump', { repeat }).then((t) => { mat.bumpMap = t; mat.bumpScale = 1.5; }));
    await Promise.all(jobs); mat.needsUpdate = true; return mat;
  }
}
