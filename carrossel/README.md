# Carrossel diário de psicanálise (Instagram)

## Fluxo
1. Escolher um tema novo (ver `historico.md`) e escrever `slides.json` (formato em `exemplos/falso-self.json`).
2. Renderizar: `node carrossel/render.js slides.json <pasta-de-saida>` (PNG 1080x1440, azul-marinho e dourado).
3. Conferir visualmente os slides (nenhum texto cortado, sem linhas órfãs) e mostrar ao usuário com a legenda.
4. Só publicar depois da aprovação explícita ("pode postar").
5. Publicar: subir os PNGs numa pasta de nome aleatório (`media-<hex>`) na branch de trabalho, usar as URLs
   `https://raw.githubusercontent.com/<dono>/<repo>/<branch>/<pasta>/slide-NN.png` na ação
   `publish_media_v2` do Zapier (Instagram for Business), conta `17841401082763268`
   ("Evandro Fernandes | Psicanalista"), conexão "#2" (`024a3d45-f321-8b91-b4af-e3c2864fa55d`).
6. Conferir o post com a ação `new_media`, apagar a pasta de mídia e registrar o tema em `historico.md`.

## Regras de conteúdo
- Gancho curto e provocativo; combater o viés de concordância (mostrar o ganho inconsciente).
- Linguagem neutra em gênero; sem tom de coach; sem promessas de cura nem diagnóstico.
- Fidelidade teórica: atribuir cada ideia ao autor certo e incluir nuances.
- Neurociência só com linguagem cautelosa ("estudos sugerem").
- Legenda com pergunta final, aviso "Conteúdo educativo, não substitui acompanhamento psicológico." e 8 a 10 hashtags de nicho.
- 8 a 9 slides, no máximo ~30 palavras por slide.

## Tipos de slide (`kind`)
`cover` (capa com anéis e "ARRASTE"), `text`, `quote`, `cta` (cartões SALVE e ENVIE).
Blocos: `h1`, `h2`, `p`, `s`, `big`, `orn`, `box`. Destaque dourado: `<b class="g">`.
