# A Vida na Floresta — protótipo em Godot

Teste pequeno para sentir como seria o jogo no Godot 4 (feito no 4.3, renderizador Compatibilidade).
Não substitui o jogo da web; é só uma amostra.

## O que tem (v12)
- Aldeia maior e espaçada: praça no centro, Salão do Chefe ao fundo (norte), casas, forja e moinho em volta (nó **Aldeia** da cena `main.tscn`).
- Cavaleiro animado: direcional na tela ou WASD; botão ATACAR ou Espaço.
- Coleta: árvores dão madeira, rochas dão pedra, arbustos dão comida. Os recursos renascem depois de 45 s.
- Lotes de construção (nó **Lotes**): CONSTRUIR e depois MELHORAR até o nível 3 (ou tecla E).
  - Casa: +25 de vida máxima e +2 vagas de aldeão por nível · Serraria: produz madeira · Torre: atira nos orcs · Estalagem: cura mais rápido.
- **16 personagens realistas** (botão CLASSE): escolha a classe (Guerreiro, Lanceiro, Arqueiro, Mago) e depois um dos 4 personagens dela, 2 masculinos e 2 femininos.
  Corpo e ~90 animações da Quaternius (CC0); roupas geradas no Blender (`scripts/personagens/` na raiz do repositório); armas presas nos ossos da mão (`scripts/hero.gd`).
  O escudo fica preso no antebraço por duas alças de couro. O mago golpeia com o **cajado** (a magia sai da ponta dele): explosão em área ou raio forte num alvo. O escudo gótico agora tem a ponta para baixo.
- **Combate v11**: arqueiro dispara flechas de verdade; lanceiro dá estocadas que avançam e atravessam inimigos em linha; botões **DEFESA** (recebe 1/4 do dano, anda devagar; atacar baixa a guarda; tecla Q) e **CORRER** (1,7× mais rápido; Shift) para todas as classes.
- **Pinça**: dois dedos na tela aproximam/afastam a câmera (bem de perto para ver o personagem); roda do mouse no computador.
- **Interiores**: perto de Casas, Forja e Salão do Rei aparece **ENTRAR** (e **SAIR** lá dentro). No Salão fale com o **Rei** para pegar as 8 missões do reino (`REI_QUESTS` em `scripts/main.gd`; salas em `scripts/interior.gd`). Os inimigos congelam enquanto você está dentro.
- **v12**: lanceiro golpeia com a PONTA (a lança se alinha para a frente na estocada); mago ganhou de volta o orbe flutuando na palma da mão; Minotauro segura o machado com as duas mãos (IK em `scripts/duas_maos.gd`) e o machado desce em arco até o peito do alvo; dentro dos prédios a câmera vai para a 1ª pessoa; interiores refeitos (teto, janelas, mobília) e o Salão do Rei tem altar com escada em 3 lados, trono dourado e o Rei sentado (corpo do herói G2, maior, com armadura e coroa de ouro — `Heroi.rei()`).
- Minotauro: o machado agora desce no adversário (ele se aproxima até `alcance_machado` do alvo, em `scripts/boss.gd`; ajuste no Inspetor se a lâmina cair antes/depois).
- Aldeões (botão ALDEÕES): Lenhador, Pedreiro e Coletor vão até o recurso, trabalham e entregam na aldeia.
- 15 missões em sequência, com recompensa.
- 4 Torres de Vigia (uma em cada canto) e a **Muralha**: paliçada em volta da aldeia com 4 portões de madeira. Os portões abrem para o jogador; os inimigos precisam derrubá-los a golpes (voltam consertados depois de 40 s).
- Botão **CÂMERA**: 3ª pessoa, 1ª pessoa e visão de águia. Na 3ª pessoa a câmera sobe quando uma construção tapa o boneco, e as árvores na frente ficam escondidas.
- **Minotauro Dark** (chefe): aparece depois de 6 orcs derrotados, com barra de vida no topo, e volta mais forte a cada derrota.
  - Fase 1: golpeia com o machado de duas lâminas em meia-lua (`models/Machado.glb`).
  - Quando ele fica com 50% da vida (`largar_machado_em` em `scripts/boss.gd`), o machado se despedaça e some.
  - Fase 2: dois socos; depois recua raspando o pé no chão e investe com os chifres.
  - O modelo (`models/Minotauro_Dark.glb`) foi reduzido de 663 mil para 42 mil faces, pintado por regiões e ganhou esqueleto e 10 animações
    no Blender por script (`scripts/rig-minotauro-blender.py`, na raiz do repositório). O machado é montado por código.
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
