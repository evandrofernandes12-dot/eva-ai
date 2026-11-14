# A Vida na Floresta — código-fonte do jogo

Reconstruído a partir do pacote PWA v29 (dados: personagens, animações, natureza, kit medieval) + o código do jogo publicado
(versão `1794617888-6c1c` do artefato). `node game/build.mjs` gera `game/dist/` (um `index.html` único + `three.min.js` + PWA) —
o resultado é idêntico, byte a byte, ao arquivo testado.

```
head.html        HTML + CSS + elementos da interface
main.js          o jogo (marcadores /*@@NATDATA*/ e /*@@KITDATA*/ recebem os dados abaixo)
data/            chars.js (personagens e texturas), anims.js (animações), natdata.js (natureza), kitdata.js (kit medieval)
pwa/             three.min.js (r128), manifest.webmanifest, sw.js, ícones
```

Teste local: `node game/build.mjs && npx serve game/dist` (ou qualquer servidor estático) e abra `index.html#leve` para a qualidade leve.
O modo online (salas) só existe no artefato do Claude e não funciona fora dele.
