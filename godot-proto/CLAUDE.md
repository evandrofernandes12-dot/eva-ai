# Projeto Godot: A Vida na Floresta (protótipo)

Godot 4.3, renderizador Compatibilidade, testado em tablet Android. Idioma do código, comentários e textos do jogo: **português**.

## Mapa rápido (leia só o que a tarefa pedir)
- `scripts/main.gd`: cena principal. Classes (`CLASSES`), missões (`QUESTS`, `REI_QUESTS`), HUD, câmera/zoom, combate, projéteis, interiores, save.
- `scripts/hero.gd` (`Heroi`): 16 personagens, armas presas nos ossos, animações por classe (`ANIMS`), `Heroi.rei()`.
- `scripts/player.gd`: movimento, ataque, defesa, corrida, estocada da lança.
- `scripts/boss.gd` + `scripts/duas_maos.gd`: Minotauro (machado por código, IK das duas mãos).
- `scripts/interior.gd` (`Interior`): casas, forja e Salão do Rei gerados por código.
- `scripts/enemy.gd`, `villager.gd`, `plot.gd`, `fit.gd`, `joystick.gd`: inimigos, aldeões, lotes, utilidades, direcional.
- `models/` (GLB/glTF), `models/armas/`, `models/herois/`. Scripts do Blender ficam em `../scripts/`.

## Regras
- Não dá para rodar o Godot neste ambiente: revise o GDScript com cuidado (tipagem com `:=` só quando o tipo é inferível; `Variant` precisa de tipo explícito).
- Mudanças pequenas e focadas. Não reescreva arquivos grandes; use edição pontual.
- Valores ajustáveis ficam em `const`/`@export` com comentário (ex.: `alcance_machado`, `ZOOM_MIN`).
- Compatibilidade (tablet): evite muitas luzes por sala (máx. ~6) e sombras extras.
- Ao mudar comportamento visível, atualize a lista "O que tem" do `README.md` e a `VERSAO` em `main.gd`.
- Salvamento: `user://save_v4.json`. Campos novos precisam de valor padrão no `_load()`.

## Fluxo
- Branch de trabalho: `claude/godot-character-creator-fixes-hf5ksp`. Não criar PR sem pedido.
- Zip para teste: `cd godot-proto && zip -qr dist/godot-proto-vXX.zip . -x "dist/*" ".godot/*"` (a pasta `dist/` não é versionada).
- Economia de tokens: leia trechos (`grep -n` + intervalo de linhas) em vez de arquivos inteiros; responda curto.
