// Gera public/assets/MANIFEST.json: valida cada arquivo (tamanho > 10KB, cabeçalho glTF) e extrai os nomes exatos dos clipes de animação.
// Uso: node scripts/build-manifest.mjs
import fs from 'node:fs';
import path from 'node:path';
const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '../public/assets');
const SRC = {
  quaternius: { repo: 'trebeljahr/quaternius-showcase', base: 'public/glb/', license: 'CC0-1.0', note: 'Pacotes Quaternius (CC0), espelhados no repo (código MIT); ver LICENSES.md do repo.' },
  descent: { repo: '511action/descent-3d-assets', base: 'models/', license: 'CC0-1.0', note: 'Quaternius "Ultimate Monsters" (CC0) segundo a descrição do repo; o repo não traz arquivo de licença próprio.' },
  tls: { repo: 'itz019/tls-textures', base: '', license: 'CC0-1.0', note: 'Texturas ambientCG (CC0 1.0), redimensionadas para 1024px.' },
  three: { repo: 'mrdoob/three.js', base: 'examples/textures/', license: 'MIT', note: 'Texturas dos exemplos oficiais do three.js (repositório MIT), redimensionadas para 1024px.' },
};
const QSRC = { Knight: 'single_knight_pack/KnightCharacter.glb', Wolf: 'animals_pack/Wolf.glb', Spider: 'easy_enemies_pack/Spider.glb', Velociraptor: 'dinosaurs_pack/Velociraptor.glb' };
function glbInfo(p) {
  const b = fs.readFileSync(p); let j;
  if (p.endsWith('.glb')) { if (b.readUInt32LE(0) !== 0x46546C67) throw new Error('cabeçalho GLB inválido: ' + p); j = JSON.parse(b.slice(20, 20 + b.readUInt32LE(12)).toString()); }
  else j = JSON.parse(b.toString());
  if (b.length < 10 * 1024) throw new Error('arquivo pequeno demais: ' + p);
  return { size: b.length, animations: (j.animations || []).map(a => a.name), skinned: (j.skins || []).length > 0 };
}
const out = { generated: new Date().toISOString(), note: 'Todos os modelos são CC0/MIT. Caminhos relativos a public/assets/ (servidos em /assets/).', assets: [] };
function add(category, file, srcKey, srcPath) {
  const full = path.join(ROOT, file), s = SRC[srcKey], info = /\.(glb|gltf)$/.test(file) ? glbInfo(full) : { size: fs.statSync(full).size };
  if (info.size < 10 * 1024) throw new Error('muito pequeno: ' + file);
  out.assets.push({ id: path.basename(file).replace(/\.[^.]+$/, ''), category, path: 'assets/' + file, source: { github: s.repo, file: s.base + srcPath }, license: s.license, licenseNote: s.note, bytes: info.size, skinned: info.skinned, animations: info.animations });
}
const walk = d => fs.readdirSync(path.join(ROOT, d)).filter(f => !f.startsWith('.')).sort();
for (const f of walk('models/characters')) add('character', 'models/characters/' + f, 'quaternius', QSRC[f.replace(/\.\w+$/, '')]);
for (const f of walk('models/monsters')) { const id = f.replace(/\.\w+$/, ''); QSRC[id] ? add('monster', 'models/monsters/' + f, 'quaternius', QSRC[id]) : add('monster', 'models/monsters/' + f, 'descent', f); }
for (const f of walk('models/environment/forest')) add('forest', 'models/environment/forest/' + f, 'quaternius', (/^(Resource_Rock|Rock_Group)/.test(f) ? 'real_time_strategy_pack/' : 'nature_pack/') + f);
for (const f of walk('models/environment/village')) add('village', 'models/environment/village/' + f, 'quaternius', 'medieval_village_pack/' + f);
const TEX3 = { grass_albedo: 'terrain/grasslight-big.jpg', wood_albedo: 'hardwood2_diffuse.jpg', wood_roughness: 'hardwood2_roughness.jpg', wood_bump: 'hardwood2_bump.jpg' };
const TLS = { stone_path: 'sidewalk_concrete', brick_wall: 'wall_brick', plaster_wall: 'wall_plaster_dirty' };
for (const f of walk('textures/pbr')) { const id = f.replace('.jpg', ''), base = id.replace(/_(albedo|normal|roughness|bump)$/, ''); TEX3[id] ? add('texture', 'textures/pbr/' + f, 'three', TEX3[id]) : add('texture', 'textures/pbr/' + f, 'tls', TLS[base] + '_*'); }
fs.writeFileSync(path.join(ROOT, 'MANIFEST.json'), JSON.stringify(out, null, 1));
console.log('MANIFEST.json:', out.assets.length, 'assets');
