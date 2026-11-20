# Chavinho's Kart (Godot 4.3+ / GDScript)

Kart arcade 3D inspirado em *El Chavo del Ocho* e em *Mario Kart*. MVP jogável: menu → seleção de piloto →
corrida de 3 voltas contra 7 pilotos de IA (Circuito da Vila) → pódio.

## Como rodar
1. Abra **Godot 4.3+** → *Import* → selecione `chavinhos-kart/project.godot`.
2. Aperte **F5**. (Renderer: *Mobile*, janela 1280x720.)

## Controles
| Ação | Teclas |
|---|---|
| Acelerar / Frear (ré) | W S ou ↑ ↓ |
| Virar | A D ou ← → |
| Drift (segure em curva, solte p/ mini-turbo azul → laranja → roxo) | Espaço / Shift |
| Usar item | E / Enter |
| Voltar à pista | R |
| Pausa | Esc |

**Tablet/celular:** os controles de toque aparecem sozinhos (◀ ▶ à esquerda; ACEL, FREIO, DRIFT, ITEM à direita; VOLTAR e pausa). Multitoque suportado.

## Conteúdo
- **11 pilotos** (`resources/racers/*.tres`, `RacerStats`): Chaves, Chiquinha, Quico, Nhonho, Popis, Seu Madruga,
  Jaiminho, Dona Florinda, Prof. Girafales, Seu Barriga e Bruxa do 71 — cada um com kart e visual procedural próprios.
- **Itens**: Sanduíche de Presunto (turbo), Bola Quadrada e Chinelo da Dona Florinda (teleguiados),
  Balde de Água e Barril (obstáculos). Caixas de item sorteiam por posição (quem está atrás recebe mais ofensivos).
- **Pista**: Circuito da Vila (917 m, curvas de até ~30 m de raio, paredes com colisão, zona off-road que reduz a velocidade).
- **Áudio 100% procedural**: motor via `AudioStreamGenerator` (pitch segue a velocidade), SFX sintetizados em `AudioManager`.

## Arquitetura
```
scripts/autoload/  Global (estado/navegação), AudioManager (áudio procedural)
scripts/kart/      KartController (física arcade), KartVisuals (modelos procedurais), KartAI, FollowCamera,
                   RacerStats (Resource), ProcMesh (fábrica de primitivas)
scripts/items/     ItemDefs (tipos/sorteio), ItemBase + derivados, ItemBox
scripts/track/     TrackBase/TrackVila (pista procedural), TrackPath (linha central), CheckpointSystem,
                   LapManager (contagem, voltas, ranking), GameManager (orquestra a corrida)
scripts/ui/        HUDController, MenuController, CharacterSelect, Podium, KartPreview, UIStyle
```
Camadas de física: 1 mundo · 2 paredes · 3 karts · 4 itens · 5 gatilhos (caixas de item).

## Trocar por assets 3D reais
- **Karts/pilotos**: em `KartVisuals.build()` instancie um `PackedScene` `.glb` em vez de chamar `_build_kart/_build_driver`
  (mantenha os nós de roda se quiser a animação) — `KartController` não depende da malha.
- **Itens**: substitua o conteúdo de `_build_visual()` em cada item.
- **Pista**: crie uma nova cena herdando `TrackBase` e implemente `_make_centerline()` / `_build_scenery()`.

## Ajuste fino da direção
Constantes em `KartController.gd`: aderência (`grip` normal 9.0 / drift 4.0), `turn` (usa `RacerStats.handling`),
ângulo de derrapagem (`0.45` rad), tempos de nível do drift (`DRIFT_LEVEL_TIMES`) e `OFFROAD_FACTOR`.
