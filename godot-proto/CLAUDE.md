# Projeto Godot: A Vida na Floresta (protótipo)

Godot 4.3, renderizador Compatibilidade, testado em tablet Android. Idioma do código, comentários e textos do jogo: **português**.

## Mapa rápido (leia só o que a tarefa pedir)
- `scripts/main.gd`: cena principal. Classes (`CLASSES`), missões (`QUESTS`, `REI_QUESTS`), HUD, câmera/zoom, combate, projéteis, interiores, save.
- `scripts/hero.gd` (`Heroi`): 16 personagens, armas presas nos ossos, animações por classe (`ANIMS`), `Heroi.rei()`.
- `scripts/player.gd`: movimento, ataque, defesa, corrida, estocada da lança.
- `scripts/boss.gd` + `scripts/duas_maos.gd`: Minotauro (machado por código, IK das duas mãos).
- `scripts/interior.gd` (`Interior`): casas, forja e Salão do Rei gerados por código.
- `scripts/vila.gd` (`Vila`): aldeia funcionando — armazéns, cozinha, artesã, horta, curral, animais, trabalhadores, guardas, refeições.
- `scripts/trabalhador.gd` (`Trabalhador`, 8 ofícios m/f, fila de tarefas), `guarda.gd` (`Guarda`), `animal.gd` (`Animal`).
- `scripts/mundo.gd` (`Mundo`): mapa aberto 1800 m — Floresta da Escuridão (lobisomens), Cemitério Maldito (caveiras KayKit), Golems de Pedra (neve), Ilha dos Orcs (barco); regiões somem de longe; árvores em MultiMesh.
- `scripts/painel_status.gd` (retrato + vida + energia), `scripts/escolha.gd` (escolha de personagem com prévia 3D). Mercado: `LOJA` em `main.gd`.
- `scripts/ceu.gd` (dia/noite/chuva; `reg_*` = neblina da região), `lago.gd`, `fogueira.gd`, `construcoes.gd` (peças por código).
- `scripts/enemy.gd`, `villager.gd` (antigo, sem uso), `plot.gd`, `fit.gd`, `joystick.gd`: inimigos, lotes, utilidades, direcional.
- `models/` (GLB/glTF), `models/armas/`, `models/herois/`. Scripts do Blender ficam em `../scripts/`.

## Regras
- O Godot 4.7.2 pode ser baixado do GitHub (godotengine/godot, releases) e rodado aqui com `xvfb-run` (renderizador Compatibilidade, Mesa llvmpipe): importar com `--editor --quit`, e tirar prints com um script `-s` que carrega `main.tscn`, move o jogador e salva `get_viewport().get_texture().get_image()`. Mesmo assim, revise o GDScript com cuidado (tipagem com `:=` só quando o tipo é inferível; `Variant` precisa de tipo explícito). Laço sobre lista literal deve ter tipo: `for x: float in [-1.0, 1.0]` (senão `var y := x * 2` não compila). O usuário roda Godot 4.7.
- Mudanças pequenas e focadas. Não reescreva arquivos grandes; use edição pontual.
- Valores ajustáveis ficam em `const`/`@export` com comentário (ex.: `alcance_machado`, `ZOOM_MIN`).
- Compatibilidade (tablet): evite muitas luzes por sala (máx. ~6) e sombras extras.
- Ao mudar comportamento visível, atualize a lista "O que tem" do `README.md` e a `VERSAO` em `main.gd`.
- Salvamento: `user://save_v4.json`. Campos novos precisam de valor padrão no `_load()`.

## Ferramentas (opcional, mas recomendado)
- `pip install -r requirements-dev.txt` instala o `gdtoolkit`. O hook `.claude/hooks/gdparse.sh` roda `gdparse` a cada edição de `.gd` e devolve erros de sintaxe na hora (não pega erros de tipo/API do Godot).
- `/zip vXX` gera e envia o zip de teste.

## Fluxo
- Branch de trabalho: `claude/godot-character-creator-fixes-hf5ksp`. Não criar PR sem pedido.
- Zip para teste: `cd godot-proto && zip -qr dist/godot-proto-vXX.zip . -x "dist/*" ".godot/*"` (a pasta `dist/` não é versionada).
- Economia de tokens: leia trechos (`grep -n` + intervalo de linhas) em vez de arquivos inteiros; responda curto.
