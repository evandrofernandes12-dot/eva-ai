# A Vida na Floresta — protótipo em Godot

Teste pequeno para sentir como seria o jogo no Godot 4 (feito no 4.3, renderizador Compatibilidade).
Não substitui o jogo da web; é só uma amostra.

## O que tem
- Aldeia com casas, forja, poço, fogueira (nó **Aldeia** da cena `main.tscn`).
- Cavaleiro animado: direcional na tela ou WASD; botão ATACAR ou Espaço.
- Orcs que aparecem na borda da aldeia, perseguem e batem.
- Árvores: bata nelas para ganhar madeira.

## Como abrir no tablet
1. Extraia o zip numa pasta.
2. No Godot: **Importar** → escolha o `project.godot` → **Importar e Editar**.
3. Espere a importação dos modelos e aperte ▶ (Rodar).

## O que experimentar no editor
- Abra `main.tscn`, selecione uma casa em **Aldeia** e arraste.
- No Inspetor da casa, o metadado `altura` muda o tamanho (em metros).
- No nó **Main**: `tree_count`, `max_enemies`, `forest_radius`.
- No nó **Jogador**: `speed`, `damage`, `max_hp`.
- Para pôr outra construção: arraste um `.glb` de `models/` para dentro de **Aldeia**.

Modelos: Quaternius (CC0), os mesmos de `public/assets` deste repositório.
