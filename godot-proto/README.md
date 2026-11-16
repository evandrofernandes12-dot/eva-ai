# A Vida na Floresta — protótipo em Godot

Teste pequeno para sentir como seria o jogo no Godot 4 (feito no 4.3, renderizador Compatibilidade).
Não substitui o jogo da web; é só uma amostra.

## O que tem (v5)
- Aldeia com casas, forja, poço, fogueira (nó **Aldeia** da cena `main.tscn`).
- Cavaleiro animado: direcional na tela ou WASD; botão ATACAR ou Espaço.
- Coleta: árvores dão madeira, rochas dão pedra, arbustos dão comida. Os recursos renascem depois de 45 s.
- Lotes de construção (nó **Lotes**): CONSTRUIR e depois MELHORAR até o nível 3 (ou tecla E).
  - Casa: +25 de vida máxima e +2 vagas de aldeão por nível · Serraria: produz madeira · Torre: atira nos orcs · Estalagem: cura mais rápido.
- Classes (botão CLASSE): Guerreiro (de perto), Arqueiro (flechas), Mago (orbes em área). Arma evolui até o nível 3.
- Aldeões (botão ALDEÕES): Lenhador, Pedreiro e Coletor vão até o recurso, trabalham e entregam na aldeia.
- 13 missões em sequência, com recompensa.
- **Minotauro Dark** (chefe): aparece depois de 6 orcs derrotados, tem barra de vida no topo e volta mais forte a cada derrota.
  O modelo (`models/Minotauro_Dark.glb`) foi reduzido de 663 mil para 42 mil faces. Ele não tem esqueleto, então o movimento é feito por código em `scripts/boss.gd`.
- Orcs ficam mais fortes conforme você derrota mais deles.
- Salva sozinho a cada 10 s; botão **Novo jogo** apaga o progresso.

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
- Em cada lote de **Lotes**: `nome`, `modelo`, custos e `efeito` ficam no Inspetor. Duplique um lote para criar outro.
- As missões ficam na lista `QUESTS` e as classes em `CLASSES`, no começo de `scripts/main.gd`.

Modelos: Quaternius (CC0), os mesmos de `public/assets` deste repositório.
