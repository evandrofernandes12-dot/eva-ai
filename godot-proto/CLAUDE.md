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
- `scripts/painel_status.gd` (retrato + vida + energia), `scripts/escolha.gd` (escolha de personagem com prévia 3D), `scripts/botoes_acao.gd` (ATACAR/DEFESA/CORRER redondos com ícone). Mercado: dados em `LOJA` (`main.gd`), tela em `scripts/mercado.gd` (cartões com o item em 3D).
- `scripts/niveis.gd` (`Niveis`): níveis 0-100 (nomes por faixa, custo, visual com cor/enfeites, lendário turquesa e ouro, XP do personagem, força dos inimigos). Construções que evoluem: `predios` em `main.gd` (+ lotes do `plot.gd`), menu ALDEIA; ataques à aldeia: `alvo_na_aldeia`/`danificar_construcao`.
- `scripts/som.gd` (`Som`): música, ambientes e efeitos 3D (`Som.efeito(nome, pos)`); sons em `assets/sons/` (CC0). Lua cheia e ataque dos lobisomens: `_comecar_lua_cheia()` em `main.gd`.
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

## Exportar (APK e Web)
- `export_presets.cfg` tem os presets "Android" (APK arm64, sem gradle) e "Web" (sem threads, texturas de celular). Moldes: `~/.local/share/godot/export_templates/4.7.2.stable/` (baixar o .tpz do GitHub e extrair só android_*.apk e web_*). Android SDK falso em `/root/Android/Sdk` com `apksigner`, `zipalign` e `adb` do apt (o dl.google.com é bloqueado) e keystore de debug em `~/.local/share/godot/keystores/debug.keystore`.
- `ANDROID_HOME=/root/Android/Sdk xvfb-run -a godot --path . --headless --export-debug "Android" dist/VidaNaFloresta.apk` e `--export-release "Web" dist/web/index.html`.

## Atualização automática (patch)
- Primeira cena: `atualizador.tscn` (`scripts/atualizador.gd`, `BASE` = versão do APK). Ele lê `atualizacoes/versao.json` pela URL raw do GitHub (branch de trabalho) e baixa `patch` (pacote cumulativo em relação à base).
- Publicar atualização: gerar o pck da base a partir do commit `base_commit` de `versao.json` (`git worktree add /tmp/base <commit>`, depois `--export-pack "Android" base.pck` lá), e no projeto atual `--export-patch "Android" atualizacoes/patch_vXX.pck --patches base.pck`; apagar patches antigos, atualizar `versao.json` (`versao` = XX, `patch` = nome do arquivo), commit e push. Mudou a BASE (APK novo)? Atualize `BASE` e zere `versao.json` com o `base_commit` novo (tags não sobem: o proxy só aceita push no branch).

## Fluxo
- Branch de trabalho: `claude/godot-character-creator-fixes-hf5ksp`. Não criar PR sem pedido.
- Zip para teste: `cd godot-proto && zip -qr dist/godot-proto-vXX.zip . -x "dist/*" ".godot/*"` (a pasta `dist/` não é versionada).
- Economia de tokens: leia trechos (`grep -n` + intervalo de linhas) em vez de arquivos inteiros; responda curto.
