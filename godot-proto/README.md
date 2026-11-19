# A Vida na Floresta — protótipo em Godot

Teste pequeno para sentir como seria o jogo no Godot 4 (feito no 4.3, renderizador Compatibilidade).
Não substitui o jogo da web; é só uma amostra.

## O que tem (v23)
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
- **v23**: armas novas do Sketchfab (CC-BY): espada rúnica (G1), Excalibur (G3), espada maldita nos espadões (G2/G4), cetro mágico (M1/M2) e cajado de cristal (M3/M4); machado na mão do lenhador e picareta na do pedreiro; Excalibur na pedra no Salão do Rei. **Shaders** leves (`shaders/`, `scripts/efeitos.gd`): vento nas árvores e arbustos, luz de borda no herói (dourada) e no Minotauro (vermelha), grama do chão sem repetição.
- **v22**: modelos do Sketchfab (CC-BY, créditos em `models/CREDITOS.txt`): arqueiro com arco realista no lugar da besta; flecha realista; barril realista (aldeia e casas); céu com foto 360° de floresta e lago.
- **v21**: corrigido o "bloco" escuro dentro das casas (o barril e a fogueira eram medidos fora da cena e saíam gigantes); lobo sem o bug de deitar/torcer (as animações quebravam ao reexportar pelo Blender: agora só a cor é trocada direto no .glb, `scripts/pets/lobo_glb.py`) e maior (1,6 m).
- **v20**: urso sem "andar sozinho" nas animações (root motion removido no Blender), troca entre parado/andar/trote/corrida conforme a velocidade e, ao atacar, para, levanta nas patas de trás e dá a patada (dano no meio do golpe); lobo maior (1,3 m); fênix menor (2,4 m com a cauda).
- **v19**: lobo, urso e fênix com os modelos realistas do Sketchfab enviados pelo usuário, ajustados no Blender (`scripts/pets/ajustar_pets.py`): urso branco salpicado (andar, trote, corrida, ataque), lobo cinza (andar, correr, parado), fênix em cores de fogo com animação de voo criada no Blender. Créditos e licenças em `models/pets/LEIA-ME.txt` (o lobo é não comercial).
- **v18**: interior das casas sem nenhuma peça de madeira escura atravessada (verga, batentes, molduras das janelas, prateleira da lareira) e com teto claro e liso; exterior das casas e Salão do Rei sem mudança.
- **v17**: pets com modelos animados de verdade, feitos no Blender a partir de modelos livres do GitHub (`scripts/pets/fazer_pets.py`): lobo cinza e urso branco salpicado (a partir da raposa da Khronos, com andar/correr/parado), cavalo branco galopando com asas emplumadas, fênix batendo as asas com cauda e chamas de fogo. Créditos em `models/pets/LEIA-ME.txt`.
- **v16**: **pets** (`scripts/pet.gd`, `scripts/fenix.gd`): guerreiro = cavalo alado branco, lanceiro = urso branco malhado de cinza, arqueiro = lobo cinza, mago = fênix de fogo. Seguem o dono e, com inimigo a 6-7 m, avançam e dão um golpe de **5 de dano** (recarga 1,6 s). Corpos montados por código (elipsoides com pelo gerado); para modelos realistas de verdade, ponha `models/pets/<cavalo|urso|lobo|fenix>.glb` (ver `LEIA-ME.txt`). Casas com layout próprio: cama, lareira, quadros, sofá e mesa com 4 cadeiras (a forja mantém fornalha e bigorna).
- **v15**: todos os interiores (casas, estalagem, serraria, moinho, barraca) usam o layout da forja, só mudando as cores; os prédios construídos nos lotes (Casa, Estalagem, Serraria) e o Moinho e a Barraca agora também têm porta (antes só Casa1-3, Forja e Salão).
- **v14**: **fênix de fogo** só para os magos (`scripts/fenix.gd`): paira sobre a cabeça; quando o mago ataca, ou um inimigo chega a 7 m, mergulha como flecha de fogo (dano = 4× o dano do mago + 30, em área de 2,2 m; recarga 2,2 s) e volta. Casas/forja mais claras (materiais com brilho próprio, luzes extras, sem vigas). Machado do Minotauro posto em relação aos ombros reais do modelo, para as mãos sempre alcançarem o cabo.
- **v13**: casas refeitas (móveis baixos encostados nas paredes, faixa da porta livre, sem cabeceira/laje); Rei maior (2,9 m) com o assento sob a pélvis, deixando as pernas visíveis; mãos do Minotauro recuadas para o punho cair no cabo.
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
