# Assets do mundo (floresta + aldeia)

Estrutura (servida em `/assets/`):

```
models/characters/   Knight.glb (animado: Idle, Walking, Run, Run_swordAttack, Death, ...)
models/monsters/     Orc, Demon, BlueDemon (.gltf), Wolf, Spider, Velociraptor (.glb) – todos animados
models/environment/forest/   árvores, arbustos, rochas, grama, flores, troncos
models/environment/village/  casas, estalagem, moinho, ferreiro, serraria, poço, cercas, barracas, ...
textures/pbr/        grama, pedra, tijolo, reboco, madeira (albedo/normal/roughness/bump, 1024px)
MANIFEST.json        origem (GitHub), licença e nomes exatos dos clipes (animations[]) de cada arquivo
```

Origem e licença (detalhe por arquivo no MANIFEST.json):

- Modelos Quaternius (CC0-1.0) espelhados em `trebeljahr/quaternius-showcase` (packs: Animated Knight, Ultimate Nature, Medieval Village, Ultimate Fantasy RTS, Animated Animals, Easy Enemies, Dinosaurs).
- Orc / Demon / BlueDemon: Quaternius Ultimate Monsters (CC0) via `511action/descent-3d-assets` (o repo não traz arquivo de licença; CC0 segundo a descrição).
- Texturas de parede e pedra: ambientCG (CC0) via `itz019/tls-textures`; grama e madeira: exemplos do `mrdoob/three.js` (MIT).

Scripts: `npm run assets:manifest` (revalida e regera o MANIFEST), `npm run assets:world` (rebaixa os modelos do GitHub).
Página de demonstração: `world.html` (código em `src/world/`: `AssetLoader`, `AnimationController`, `ForestWorld`).
