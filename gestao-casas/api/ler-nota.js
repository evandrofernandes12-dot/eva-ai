// Função de servidor (Vercel): lê uma nota fiscal por foto ou interpreta uma frase ditada
// e devolve os campos do lançamento. A chave da API fica só aqui, nunca no aparelho.
// Variáveis de ambiente: ANTHROPIC_API_KEY e APP_CODIGO (código de acesso digitado no app).
import Anthropic from '@anthropic-ai/sdk';
import { betaZodOutputFormat } from '@anthropic-ai/sdk/helpers/beta/zod';
import { z } from 'zod';
import { timingSafeEqual } from 'node:crypto';

export const CATEGORIAS = ['Supermercado', 'Feira / Hortifruti', 'Limpeza', 'Manutenção', 'Materiais', 'Funcionários',
  'Contas (luz, água, gás)', 'Jardim / Piscina', 'Farmácia', 'Transporte', 'Outros'];

const Nota = z.object({
  entendido: z.boolean().describe('false se a imagem não for uma nota/recibo legível ou a frase não descrever um gasto'),
  valor: z.number().nullable().describe('Valor total pago, em reais (ex.: 12.5). null se não der para saber'),
  data: z.string().nullable().describe('Data da compra no formato AAAA-MM-DD. null se não constar'),
  estabelecimento: z.string().nullable().describe('Nome do local, ex.: "Padaria Ipanema"'),
  categoria: z.enum(CATEGORIAS),
  descricao: z.string().describe('Resumo curto para o extrato, ex.: "Padaria Ipanema - pães e leite"'),
  itens: z.array(z.object({
    nome: z.string(),
    quantidade: z.string().nullable(),
    valor: z.number().nullable().describe('Valor total do item em reais')
  }))
});

const INSTRUCOES = `Você preenche lançamentos de despesas domésticas de uma casa no Brasil.
Receberá a foto de uma nota fiscal, cupom ou recibo, ou uma frase ditada pela governanta descrevendo uma compra.
Extraia os dados exatamente como constam; não invente valores. Em notas, use o valor total efetivamente pago
(depois de descontos). Escolha a categoria que melhor descreve a compra como um todo: padaria, mercado e açougue
são "Supermercado"; sacolão e feira são "Feira / Hortifruti". Escreva em português.`;

const mesmoCodigo = (a, b) => {
  const x = Buffer.from(String(a)), y = Buffer.from(String(b));
  return x.length === y.length && timingSafeEqual(x, y);
};

export default async function handler(req, res) {
  const codigo = process.env.APP_CODIGO;
  // O app consulta por GET se a leitura automática está ligada, para mostrar ou esconder os botões.
  if (req.method === 'GET') return res.status(200).json({ ativo: !!(codigo && process.env.ANTHROPIC_API_KEY) });
  if (req.method !== 'POST') return res.status(405).json({ erro: 'Método não permitido.' });
  if (!codigo || !process.env.ANTHROPIC_API_KEY) return res.status(503).json({ erro: 'A leitura automática ainda não foi configurada no servidor.' });
  if (!mesmoCodigo(req.headers['x-codigo'] || '', codigo)) return res.status(401).json({ erro: 'Código de acesso incorreto.' });

  const { imagem, texto, hoje } = req.body || {};
  const conteudo = [];
  if (typeof imagem === 'string') {
    const m = /^data:(image\/(?:jpeg|png|webp));base64,([A-Za-z0-9+/=]+)$/.exec(imagem);
    if (!m) return res.status(400).json({ erro: 'Imagem inválida.' });
    conteudo.push({ type: 'image', source: { type: 'base64', media_type: m[1], data: m[2] } });
    conteudo.push({ type: 'text', text: 'Leia esta nota e preencha o lançamento.' });
  } else if (typeof texto === 'string' && texto.trim() && texto.length <= 2000) {
    conteudo.push({ type: 'text', text: `Frase ditada: "${texto.trim()}"` });
  } else {
    return res.status(400).json({ erro: 'Envie uma foto ou uma frase.' });
  }
  if (/^\d{4}-\d{2}-\d{2}$/.test(hoje || '')) conteudo.push({ type: 'text', text: `Hoje é ${hoje}. Use isso para "hoje", "ontem" etc.; se a frase não citar data, use hoje.` });

  try {
    const client = new Anthropic();
    const r = await client.beta.messages.parse({
      model: 'claude-opus-5-5',
      max_tokens: 16000,
      betas: ['server-side-fallback-2026-07-01'],
      fallbacks: 'default',
      system: INSTRUCOES,
      output_config: { effort: 'low', format: betaZodOutputFormat(Nota) },
      messages: [{ role: 'user', content: conteudo }]
    });
    if (r.stop_reason === 'refusal' || !r.parsed_output) return res.status(422).json({ erro: 'Não foi possível interpretar. Preencha manualmente.' });
    return res.status(200).json(r.parsed_output);
  } catch (e) {
    if (e instanceof Anthropic.RateLimitError) return res.status(429).json({ erro: 'Muitas leituras em sequência. Tente de novo em instantes.' });
    if (e instanceof Anthropic.AuthenticationError) return res.status(503).json({ erro: 'A chave da API no servidor é inválida.' });
    if (e instanceof Anthropic.APIConnectionError) return res.status(502).json({ erro: 'Sem conexão com o serviço de leitura.' });
    console.error('ler-nota', e instanceof Anthropic.APIError ? `${e.status} ${e.message}` : e);
    return res.status(500).json({ erro: 'Erro ao interpretar. Preencha manualmente.' });
  }
}
