# Orçamento do Zapier (100 tarefas por mês)

O plano gratuito tem 100 tarefas por mês. Cada chamada do Zapier que executa uma ação consome tarefas.
Em 11/11 a 18/11 o limite estourou (estimativa: ~100 tarefas em 8 dias), por falta de orçamento da minha parte.

## Custo por postagem (mínimo, sem conferência depois)
| Tipo | Tarefas | Como |
|---|---|---|
| Carrossel | 1 | publish_media_v2 (uma chamada) |
| Reel | 2 | publish_video (1) + 1 de margem se o vídeo ainda estiver processando |
| Story em vídeo | 3 | criar contêiner + ver status + publicar (API do Instagram) |
| Conferir o post depois | +1 | NÃO fazer, para economizar |

Regras para economizar: não conferir posts pelo Zapier; esperar 40 s antes de ver o status; nunca repetir chamada às cegas;
parar ao primeiro aviso de limite. Reservar ~10 tarefas de margem (usar no máximo 90 por mês).

## Planos possíveis para 30 dias (90 tarefas)
- **A (recomendado): carrossel todo dia + reel a cada 3 dias + stories só quando sobrar.**
  Carrossel 30 + reels 10 x 2 = 20 + 13 stories x 3 = 39 → 89 tarefas. Os demais stories o usuário posta à mão (custo zero).
- **B: sem reel.** Carrossel 5x/semana (22) + story da manhã 5x/semana (22 x 3 = 66) → 88 tarefas.
- **C: com reels.** Carrossel 4x/semana (17) + reel 3x/semana (13 x 2 = 26) + stories 3x/semana (13 x 3 = 39) → 82 tarefas.

Tudo que o usuário posta à mão não gasta tarefa. Quanto mais stories manuais, mais tarefas sobram para carrossel e reel.

## Enquanto os créditos não voltam (modo manual)
NÃO usar o Zapier. Às 19:00 de cada dia, preparar o pacote do DIA SEGUINTE e enviar ao usuário todos os arquivos
(slides PNG em ordem, vídeos dos stories e do reel) e as legendas completas para copiar e colar. O usuário posta à mão.
A entrega é UM ZIP por dia (`python3 carrossel/empacotar.py <pasta-do-dia> <saida.zip>`), para o usuário baixar uma vez e extrair no tablet,
em vez de salvar os arquivos um por um.
Voltar a publicar pelo Zapier só quando o usuário avisar que os créditos voltaram e escolher o plano.
