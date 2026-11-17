---
description: Gera o zip do projeto Godot para testar no tablet (uso: /zip v13)
argument-hint: [versão, ex.: v13]
---
Gere o zip do projeto Godot em `godot-proto/dist/godot-proto-$ARGUMENTS.zip` (se não houver argumento, use a `VERSAO` de `godot-proto/scripts/main.gd`).

1. Rode `gdparse` em todos os `godot-proto/scripts/*.gd`; se algum falhar, pare e mostre o erro.
2. `cd godot-proto && zip -qr dist/godot-proto-<versão>.zip . -x "dist/*" ".godot/*"`
3. Confira com `unzip -l` (total de arquivos) e envie o zip ao usuário com SendUserFile.
Não faça commit do zip (a pasta `dist/` é ignorada pelo git). Responda em uma ou duas linhas.
