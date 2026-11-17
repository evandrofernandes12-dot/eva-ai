# Eva · Criador 3D de Personagens e Monstros

Aplicativo web (React + Three.js + Vite + Tailwind CSS) para criar um personagem humanoide, customizar
proporções/cores, trocar de raça (Humano, Orc, Lobisomem), animar (Idle, Andar, Atacar, Defender) e
**exportar o resultado em `.glb` / `.gltf`** com esqueleto e animações, pronto para engines de jogo.

## Rodando

```bash
npm install
npm run assets   # (re)baixa os modelos 3D do GitHub para public/models/ – já vêm baixados
npm run dev      # http://localhost:5173
npm run build    # build de produção em dist/
```

## Estrutura

```
public/models/quaternius/   modelos baixados (corpo masculino/feminino, riggados) + texturas
scripts/download-assets.sh  download automático dos modelos (curl, sem passos manuais)
src/engine/
  CharacterEngine.js        cena, carregamento, materiais/cores, escala de ossos, animações, exportação
  rig.js                    pose de repouso do esqueleto, solver FK (aim/delta), escala "líquida" por osso
  poses.js                  clipes procedurais: Idle, Walk, Attack, Defend (viram AnimationClip)
  parts.js                  peças procedurais: cabelo, roupa, presas, focinho, orelhas, garras, cauda
  presets.js                raças, sliders, paletas
src/components/             Viewport (canvas) e componentes de UI
src/App.jsx                 painel de controle
```

## Como funciona

- **Modelos**: *Universal Base Characters* do Quaternius (CC0) – `Superhero_Male` e `Superhero_Female`,
  esqueleto humanoide com 65 ossos. Baixados de um espelho público no GitHub.
- **Proporções**: altura, massa muscular, peso, peito/ombros, cabeça, braços e pernas são aplicados como
  escala de ossos (não há morph targets nos modelos). A escala é calculada como "escala líquida" por osso,
  compensando a herança dos pais, e o quadril/pés são reajustados para tocar o chão.
- **Raças**: Orc e Lobisomem são o mesmo corpo base com preset de proporções, postura (corcunda),
  cor e peças procedurais (presas/sobrancelha/maxilar/orelhas; focinho/orelhas/garras/cauda/juba).
- **Animações**: os modelos não trazem clipes, então Idle/Andar/Atacar/Defender são gerados
  proceduralmente a partir da pose de repouso de cada esqueleto (e regenerados quando a raça/pernas mudam).
- **Cabelo e roupa** são "cascas" copiadas da própria malha do corpo (SkinnedMesh com o mesmo esqueleto),
  então deformam junto com as proporções e animações e são exportadas como malhas skinned normais.
- **Exportação**: `GLTFExporter` na pose de repouso, com os 4 clipes de animação, texturas embutidas e
  somente objetos visíveis. A cor da pele vai como `baseColorFactor` sobre uma textura em tons de cinza.

## Licenças

- Modelos: Quaternius, CC0 1.0 (domínio público). Ver `public/models/README.md`.
- Código: ver repositório.
