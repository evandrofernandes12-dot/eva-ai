// Cálculos de datas, dinheiro, férias e 13º. Sem dependência de tela, para poder ser testado à parte.
// Os valores trabalhistas são ESTIMATIVAS brutas para planejamento; o valor oficial sai do eSocial.
(function (root) {
  const pad = n => String(n).padStart(2, '0');
  const iso = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
  const parse = s => { const [y, m, d] = s.split('-').map(Number); return new Date(y, m - 1, d || 1); };
  const addAnos = (d, n) => new Date(d.getFullYear() + n, d.getMonth(), d.getDate());
  const addDias = (d, n) => new Date(d.getFullYear(), d.getMonth(), d.getDate() + n);
  const diasEntre = (a, b) => Math.round((b - a) / 86400000);

  // "1.234,56" / "1234.56" / "R$ 50" -> centavos (inteiro). Retorna NaN se inválido.
  function parseValor(txt) {
    let s = String(txt || '').replace(/[^\d.,-]/g, '');
    if (!s) return NaN;
    if (s.includes(',')) s = s.replace(/\./g, '').replace(',', '.');
    const n = Number(s);
    return isFinite(n) ? Math.round(n * 100) : NaN;
  }
  const brl = c => (c / 100).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });

  // Férias: a cada 12 meses de trabalho (período aquisitivo) nasce o direito a 30 dias,
  // que devem ser gozados dentro dos 12 meses seguintes (período concessivo).
  // Os dias já tirados são abatidos dos períodos mais antigos primeiro.
  function periodosFerias(admissaoISO, feriasTiradas, hojeISO) {
    const adm = parse(admissaoISO), hoje = parse(hojeISO);
    let tirados = (feriasTiradas || []).reduce((s, f) => s + Number(f.dias || 0), 0);
    const periodos = [];
    for (let i = 0; addAnos(adm, i + 1) <= hoje && i < 60; i++) {
      const usados = Math.min(30, tirados); tirados -= usados;
      const limite = addDias(addAnos(adm, i + 2), -1); // último dia para terminar as férias
      periodos.push({
        inicio: iso(addAnos(adm, i)), fim: iso(addDias(addAnos(adm, i + 1), -1)),
        limite: iso(limite), restante: 30 - usados,
        diasParaLimite: diasEntre(hoje, limite)
      });
    }
    return { periodos, proximoDireito: iso(addAnos(adm, periodos.length + 1)) };
  }

  // Valor bruto estimado de férias: salário proporcional aos dias + 1/3 constitucional.
  const valorFerias = (salario, dias) => Math.round(salario * dias / 30 * 4 / 3);

  // 13º: 1/12 do salário por mês trabalhado no ano (conta o mês com 15 dias ou mais).
  function decimoTerceiro(admissaoISO, salario, ano) {
    const adm = parse(admissaoISO);
    let avos = 0;
    for (let m = 0; m < 12; m++) {
      const ultimo = new Date(ano, m + 1, 0);
      if (adm > ultimo) continue;
      const primeiro = new Date(ano, m, 1);
      const dias = adm > primeiro ? ultimo.getDate() - adm.getDate() + 1 : ultimo.getDate();
      if (dias >= 15) avos++;
    }
    const total = Math.round(salario * avos / 12);
    const parcela1 = Math.round(total / 2);
    return { avos, total, parcela1, parcela2: total - parcela1 };
  }

  const api = { pad, iso, parse, addAnos, addDias, diasEntre, parseValor, brl, periodosFerias, valorFerias, decimoTerceiro };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  root.Calc = api;
})(typeof window !== 'undefined' ? window : globalThis);
