# Conteúdo diário de psicanálise (Instagram)

Conta: `evandro_fernandes.fe_psique` (ID Instagram `17841401082763268`). Conexão Zapier "#2":
`024a3d45-f321-8b91-b4af-e3c2864fa55d` (app Instagram for Business, `InstagramBusinessCLIAPI`).

## Calendário
| Dia | Carrossel | Story manhã | Story noite | Reel |
|---|---|---|---|---|
| Seg | psicanálise | psicanálise | psicanálise | não |
| Ter | psicanálise | psicanálise | psicanálise | sim |
| Qua | **psicanálise e fé** | fé | fé | não |
| Qui | psicanálise | psicanálise | psicanálise | sim |
| Sex | psicanálise | psicanálise | psicanálise | não |
| Sáb | psicanálise | psicanálise | psicanálise | sim |
| Dom | **psicanálise e fé** | fé | fé | não |

Dias comuns: `temas-psicanalise.md` (30 temas, em ordem). Dias de fé: `temas-fe.md` (17 temas, em ordem, com regras).
O controle de rotação e os temas já publicados ficam em `historico.md`.
Os stories do dia seguem o tema do carrossel do mesmo dia. O Reel dos dias Ter/Qui/Sáb usa o tema do carrossel do dia.

## Ferramentas
- Carrossel: `node carrossel/render.js slides.json <pasta>` (PNG 1080x1440). Exemplo: `exemplos/falso-self.json`.
- Story: mesmo script com `"format": "vertical"` e um único slide (PNG 1080x1920). Exemplos: `exemplos/story-manha.json`
  (rótulo "BOM DIA · ...", frase curta provocativa) e `exemplos/story-noite.json` (rótulo "PARA A NOITE", uma pergunta).
- Reel: `node carrossel/reel.js reel.json saida.mp4` (mp4 1080x1920, 30 a 45 s, sem voz, transições suaves, com trilha
  instrumental original gerada por `musica.js`, sem direitos de terceiros). Campo `"musica"` do reel.json: `"reflexivo"`
  (tom menor, dias comuns), `"esperanca"` (tom maior, dias de fé) ou `"nenhuma"`.
  Exemplo: `exemplos/reel.json` (`segundos` = duração de cada cena). Fica dentro da zona segura do Instagram.

## Publicação (somente após aprovação explícita do usuário)
Subir mídia numa pasta `media-<hex aleatório>` na branch de trabalho e usar as URLs
`https://raw.githubusercontent.com/<dono>/<repo>/<branch>/<pasta>/<arquivo>`. Depois de postar, apagar a pasta.

- **Carrossel:** ação `publish_media_v2` (1 a 10 imagens, `caption`, `instagramPageId`).
- **Reel:** ação `publish_video` (`video` = URL do mp4, `caption`).
- **Story:** não há ação pronta, usar a API do Instagram pelo Zapier (testado, funciona):
  1. POST `https://graph.facebook.com/v21.0/17841401082763268/media` com `media_type=STORIES` e `image_url=<URL>`
     (ação `_zap_raw_request` mutating, `querystring`). Retorna `id` do contêiner.
  2. Conferir com GET `https://graph.facebook.com/v21.0/<id>?fields=status_code` até `FINISHED`.
  3. POST `https://graph.facebook.com/v21.0/17841401082763268/media_publish` com `creation_id=<id>`.
  Se algo falhar, entregar a imagem do story ao usuário (caminho completo do PNG) para postar manualmente.
- Depois, conferir com a ação `new_media`, apagar a pasta de mídia e atualizar `historico.md` (commit e push).

## Regras de conteúdo
- Gancho curto e provocativo; combater o viés de concordância (mostrar o ganho inconsciente).
- Linguagem neutra em gênero; sem tom de coach; sem promessas de cura nem diagnóstico.
- Fidelidade teórica: atribuir cada ideia ao autor certo e incluir nuances.
- Neurociência só com linguagem cautelosa ("estudos sugerem").
- Legenda com pergunta final, aviso "Conteúdo educativo, não substitui acompanhamento psicológico." e 8 a 10 hashtags de nicho.
- Carrossel: 8 a 9 slides, no máximo ~30 palavras por slide. Story: no máximo ~15 palavras. Reel: 6 a 8 cenas.
- Dias de fé: seguir as regras de `temas-fe.md` (sem substituir terapia, sem culpar falta de fé, no máximo um versículo com referência).

## Tipos de slide (`kind`) e blocos
`cover`, `text`, `quote`, `cta`. Blocos: `h1`, `h2`, `p`, `s`, `big`, `orn`, `box`. Destaque dourado: `<b class="g">`.
