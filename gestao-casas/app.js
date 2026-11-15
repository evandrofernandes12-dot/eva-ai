/* Gestão das Casas — app de uso pessoal. Todos os dados ficam no próprio aparelho (IndexedDB). */
const C = Calc;
const CATS_SAIDA = ['Supermercado', 'Feira / Hortifruti', 'Limpeza', 'Manutenção', 'Materiais', 'Funcionários',
  'Contas (luz, água, gás)', 'Jardim / Piscina', 'Farmácia', 'Transporte', 'Outros'];
const CATS_ENTRADA = ['Repasse do patrão', 'Reembolso', 'Outros'];
const TIPOS_OCORR = ['Falta', 'Folga', 'Hora extra', 'Vale / adiantamento', 'Outro'];
const MESES = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];

const $ = s => document.querySelector(s);
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const uid = () => Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
const hoje = () => C.iso(new Date());
const dataBR = s => s ? s.split('-').reverse().join('/') : '';
const mesLabel = m => `${MESES[Number(m.slice(5, 7)) - 1]} ${m.slice(0, 4)}`;
const valorInput = c => (c / 100).toFixed(2).replace('.', ',');

/* ---------- Armazenamento ---------- */
const DB = (() => {
  let p;
  const abrir = () => p || (p = new Promise((ok, erro) => {
    const r = indexedDB.open('gestao-casas', 1);
    r.onupgradeneeded = () => { r.result.createObjectStore('kv'); r.result.createObjectStore('fotos'); };
    r.onsuccess = () => ok(r.result);
    r.onerror = () => erro(r.error);
  }));
  const tx = (loja, modo, fn) => abrir().then(db => new Promise((ok, erro) => {
    const t = db.transaction(loja, modo), rq = fn(t.objectStore(loja));
    t.oncomplete = () => ok(rq && rq.result);
    t.onerror = t.onabort = () => erro(t.error);
  }));
  return {
    get: (l, k) => tx(l, 'readonly', o => o.get(k)),
    set: (l, k, v) => tx(l, 'readwrite', o => o.put(v, k)),
    del: (l, k) => tx(l, 'readwrite', o => o.delete(k)),
    limpar: l => tx(l, 'readwrite', o => o.clear()),
    chaves: l => tx(l, 'readonly', o => o.getAllKeys())
  };
})();

let S;
const ui = { tab: 'inicio', mes: hoje().slice(0, 7), sub: null };

function estadoInicial() {
  const a = uid(), b = uid();
  return {
    v: 1, casas: [{ id: a, nome: 'Casa 1' }, { id: b, nome: 'Casa 2' }], casaAtual: a,
    lanc: [], fixas: [], compras: [], func: [], orc: {}, marcas: {}, cfg: { diaDAE: 7 }
  };
}
function salvar() {
  return DB.set('kv', 'estado', S).catch(() => toast('Não foi possível salvar. Verifique o espaço do aparelho.'));
}

/* ---------- Consultas ---------- */
const casaNome = id => (S.casas.find(c => c.id === id) || {}).nome || '';
const doMes = (casa, mes) => S.lanc.filter(l => l.casa === casa && l.data.startsWith(mes));
const soma = (ls, tipo) => ls.filter(l => l.tipo === tipo).reduce((s, l) => s + l.valor, 0);
const saldo = (casa, antesDe) => S.lanc.filter(l => l.casa === casa && (!antesDe || l.data < antesDe))
  .reduce((s, l) => s + (l.tipo === 'entrada' ? l.valor : -l.valor), 0);
function porCategoria(ls) {
  const m = {};
  ls.filter(l => l.tipo === 'saida').forEach(l => { m[l.cat] = (m[l.cat] || 0) + l.valor; });
  return Object.entries(m).sort((a, b) => b[1] - a[1]);
}

/* ---------- Alertas do painel ---------- */
function alertas() {
  const h = hoje(), hd = C.parse(h), mes = h.slice(0, 7), ano = hd.getFullYear(), m = hd.getMonth() + 1, dia = hd.getDate();
  const out = [];
  const add = (nivel, casa, titulo, detalhe, acao) => out.push({ nivel, casa, titulo, detalhe, acao });

  // Contas fixas ainda não pagas neste mês
  S.fixas.forEach(f => {
    if (S.lanc.some(l => l.fixaId === f.id && l.data.startsWith(mes))) return;
    const falta = f.dia - dia;
    if (falta > 5) return;
    add(falta < 0 ? 'urgente' : 'aviso', f.casa, f.nome,
      (falta < 0 ? `Venceu dia ${f.dia}` : falta === 0 ? 'Vence hoje' : `Vence dia ${f.dia}`) + (f.valor ? ` · ${C.brl(f.valor)}` : ''),
      { rotulo: 'Pagar', act: 'pagar-fixa', id: f.id });
  });

  // Férias
  S.func.forEach(f => {
    C.periodosFerias(f.admissao, f.ferias, h).periodos.filter(p => p.restante > 0).forEach(p => {
      if (p.diasParaLimite < 0)
        add('urgente', f.casa, `Férias vencidas — ${f.nome}`, `${p.restante} dias deveriam ter sido tirados até ${dataBR(p.limite)}. Férias fora do prazo são pagas em dobro.`, { rotulo: 'Ver', act: 'abrir-func', id: f.id });
      else if (p.diasParaLimite <= 120)
        add(p.diasParaLimite <= 60 ? 'urgente' : 'aviso', f.casa, `Férias de ${f.nome}`, `${p.restante} dias a tirar até ${dataBR(p.limite)} (faltam ${p.diasParaLimite} dias).`, { rotulo: 'Ver', act: 'abrir-func', id: f.id });
    });
  });

  // 13º salário
  if (m >= 11) S.func.forEach(f => {
    const d = C.decimoTerceiro(f.admissao, f.salario, ano);
    if (!d.avos) return;
    const k1 = `13-${ano}-1-${f.id}`, k2 = `13-${ano}-2-${f.id}`;
    if (!S.marcas[k1])
      add(m === 12 ? 'urgente' : 'aviso', f.casa, `13º de ${f.nome} — 1ª parcela`, `Pagar até 30/11 · cerca de ${C.brl(d.parcela1)}`, { rotulo: 'Pago', act: 'marcar', id: k1 });
    if (m === 12 && !S.marcas[k2])
      add(dia > 20 ? 'urgente' : 'aviso', f.casa, `13º de ${f.nome} — 2ª parcela`, `Pagar até 20/12 · cerca de ${C.brl(d.parcela2)} bruto (menos INSS)`, { rotulo: 'Pago', act: 'marcar', id: k2 });
  });

  // Guia do eSocial (DAE), uma por casa que tenha funcionários
  const kd = `dae-${mes}`;
  S.casas.filter(c => S.func.some(f => f.casa === c.id)).forEach(c => {
    if (S.marcas[`${kd}-${c.id}`]) return;
    add(dia > S.cfg.diaDAE ? 'urgente' : 'aviso', c.id, 'Guia do eSocial (DAE)', `Referente ao mês anterior · pagar até o dia ${S.cfg.diaDAE}`, { rotulo: 'Paga', act: 'marcar', id: `${kd}-${c.id}` });
  });

  // Orçamento por categoria
  S.casas.forEach(c => {
    const gastos = Object.fromEntries(porCategoria(doMes(c.id, mes)));
    Object.entries(S.orc[c.id] || {}).forEach(([cat, lim]) => {
      const g = gastos[cat] || 0;
      if (!lim || g < lim * 0.9) return;
      add(g >= lim ? 'urgente' : 'aviso', c.id, `Orçamento de ${cat}`, `${C.brl(g)} de ${C.brl(lim)} (${Math.round(g / lim * 100)}%)`);
    });
  });

  const ordem = { urgente: 0, aviso: 1 };
  return out.sort((a, b) => ordem[a.nivel] - ordem[b.nivel]);
}

/* ---------- Telas ---------- */
function render() {
  const abas = [['inicio', 'Início', '⌂'], ['financas', 'Finanças', '$'], ['compras', 'Compras', '✓'], ['equipe', 'Equipe', '☺'], ['mais', 'Mais', '≡']];
  const telas = { inicio: telaInicio, financas: telaFinancas, compras: telaCompras, equipe: telaEquipe, mais: telaMais };
  const corpo = ui.sub ? telaFuncionario(ui.sub) : telas[ui.tab]();
  $('#app').innerHTML = `
    <header>
      ${ui.sub ? `<button class="voltar" data-act="voltar">‹ Voltar</button>` : `<h1>${abas.find(a => a[0] === ui.tab)[1]}</h1>`}
      ${ui.tab !== 'inicio' && !ui.sub ? `<div class="casas">${S.casas.map(c =>
        `<button class="${c.id === S.casaAtual ? 'on' : ''}" data-act="casa" data-id="${c.id}">${esc(c.nome)}</button>`).join('')}</div>` : ''}
    </header>
    <main>${corpo}</main>
    <nav>${abas.map(([id, nome, ic]) => `<button class="${ui.tab === id && !ui.sub ? 'on' : ''}" data-act="aba" data-id="${id}"><i>${ic}</i>${nome}</button>`).join('')}</nav>`;
}

function telaInicio() {
  const mes = hoje().slice(0, 7), al = alertas();
  return `
    <div class="grade2">${S.casas.map(c => {
      const ls = doMes(c.id, mes);
      return `<button class="cartao casa-cartao" data-act="ir-casa" data-id="${c.id}">
        <small>${esc(c.nome)}</small><b class="${saldo(c.id) < 0 ? 'neg' : ''}">${C.brl(saldo(c.id))}</b>
        <span>saldo da verba</span><span>Gasto em ${MESES[Number(mes.slice(5)) - 1].toLowerCase()}: ${C.brl(soma(ls, 'saida'))}</span></button>`;
    }).join('')}</div>
    <div class="grade2">
      <button class="botao" data-act="novo-lanc" data-id="saida">+ Registrar gasto</button>
      <button class="botao sec" data-act="novo-lanc" data-id="entrada">+ Entrada de verba</button>
    </div>
    <h2>Precisa de atenção ${al.length ? `<em>${al.length}</em>` : ''}</h2>
    ${al.length ? al.map(a => `<div class="alerta ${a.nivel}">
        <div><b>${esc(a.titulo)}</b><p>${esc(a.detalhe)}</p><small>${esc(casaNome(a.casa))}</small></div>
        ${a.acao ? `<button data-act="${a.acao.act}" data-id="${a.acao.id}">${a.acao.rotulo}</button>` : ''}</div>`).join('')
      : `<p class="vazio">Tudo em dia. Nenhum vencimento próximo.</p>`}`;
}

function navMes() {
  return `<div class="mes"><button data-act="mes" data-id="-1">‹</button><b>${mesLabel(ui.mes)}</b><button data-act="mes" data-id="1">›</button></div>`;
}

function telaFinancas() {
  const casa = S.casaAtual, ls = doMes(casa, ui.mes).sort((a, b) => b.data.localeCompare(a.data));
  const ent = soma(ls, 'entrada'), sai = soma(ls, 'saida'), cats = porCategoria(ls), orc = S.orc[casa] || {};
  const maior = Math.max(1, ...cats.map(c => Math.max(c[1], orc[c[0]] || 0)));
  return `${navMes()}
    <div class="cartao resumo">
      <div><small>Entradas</small><b class="pos">${C.brl(ent)}</b></div>
      <div><small>Saídas</small><b>${C.brl(sai)}</b></div>
      <div><small>Saldo atual</small><b class="${saldo(casa) < 0 ? 'neg' : ''}">${C.brl(saldo(casa))}</b></div>
    </div>
    ${cats.length ? `<h2>Gastos por categoria</h2><div class="cartao">${cats.map(([cat, v]) => {
      const lim = orc[cat];
      return `<div class="barra"><div><span>${esc(cat)}</span><span>${C.brl(v)}${lim ? ` <small>de ${C.brl(lim)}</small>` : ''}</span></div>
        <i><u class="${lim && v >= lim ? 'estouro' : ''}" style="width:${Math.round(v / maior * 100)}%"></u></i></div>`;
    }).join('')}</div>` : ''}
    <h2>Lançamentos</h2>
    ${ls.length ? `<div class="lista">${ls.map(l => `<button data-act="editar-lanc" data-id="${l.id}">
        <div><b>${esc(l.desc || l.cat)}</b><small>${dataBR(l.data)} · ${esc(l.cat)}${l.foto ? ' · 📎 nota' : ''}</small></div>
        <span class="${l.tipo === 'entrada' ? 'pos' : ''}">${l.tipo === 'entrada' ? '+' : '−'} ${C.brl(l.valor)}</span></button>`).join('')}</div>`
      : `<p class="vazio">Nenhum lançamento neste mês.</p>`}
    <button class="fab" data-act="novo-lanc" data-id="saida">+</button>`;
}

function telaCompras() {
  const casa = S.casaAtual, todos = S.compras.filter(i => i.casa === casa);
  const lista = todos.filter(i => i.naLista), fora = todos.filter(i => !i.naLista), marcados = lista.filter(i => i.feito).length;
  return `
    <form class="linha-add" data-form="add-compra">
      <input name="nome" placeholder="Adicionar item…" autocomplete="off" enterkeyhint="done">
      <button class="botao">Adicionar</button>
    </form>
    ${lista.length ? `<div class="lista compras">${lista.map(i => `<div class="${i.feito ? 'feito' : ''}">
        <button class="check" data-act="check" data-id="${i.id}">${i.feito ? '✓' : ''}</button>
        <button class="nome" data-act="editar-compra" data-id="${i.id}"><b>${esc(i.nome)}</b>
          <small>${[i.qtd, i.recorrente ? 'recorrente' : ''].filter(Boolean).map(esc).join(' · ')}</small></button></div>`).join('')}</div>
      ${marcados ? `<button class="botao largo" data-act="concluir-compra">Concluir compra (${marcados} ${marcados > 1 ? 'itens' : 'item'})</button>` : ''}`
      : `<p class="vazio">A lista está vazia.</p>`}
    ${fora.length ? `<h2>Itens recorrentes <button class="link" data-act="add-recorrentes">Adicionar todos</button></h2>
      <div class="chips">${fora.map(i => `<button data-act="voltar-lista" data-id="${i.id}">+ ${esc(i.nome)}</button>`).join('')}</div>` : ''}`;
}

function telaEquipe() {
  const fs = S.func.filter(f => f.casa === S.casaAtual), h = hoje();
  return `${fs.length ? `<div class="lista">${fs.map(f => {
      const pend = C.periodosFerias(f.admissao, f.ferias, h).periodos.filter(p => p.restante > 0);
      return `<button data-act="abrir-func" data-id="${f.id}">
        <div><b>${esc(f.nome)}</b><small>${esc(f.funcao || 'Funcionário')} · desde ${dataBR(f.admissao)}</small>
        <small>${pend.length ? `Férias: ${pend.reduce((s, p) => s + p.restante, 0)} dias a tirar` : 'Férias em dia'}</small></div><span>›</span></button>`;
    }).join('')}</div>` : `<p class="vazio">Nenhum funcionário cadastrado nesta casa.</p>`}
    <button class="botao largo" data-act="novo-func">+ Cadastrar funcionário</button>`;
}

function telaFuncionario(id) {
  const f = S.func.find(x => x.id === id);
  if (!f) { ui.sub = null; return telaEquipe(); }
  const h = hoje(), fe = C.periodosFerias(f.admissao, f.ferias, h), ano = Number(h.slice(0, 4));
  const d13 = C.decimoTerceiro(f.admissao, f.salario, ano);
  const oc = (f.ocorr || []).slice().sort((a, b) => b.data.localeCompare(a.data));
  return `
    <div class="cartao perfil"><b>${esc(f.nome)}</b>
      <p>${esc(f.funcao || 'Funcionário')} · ${esc(casaNome(f.casa))}</p>
      <p>Admissão: ${dataBR(f.admissao)} · Salário: ${C.brl(f.salario)}</p>
      ${f.obs ? `<p>${esc(f.obs)}</p>` : ''}
      <button class="link" data-act="editar-func" data-id="${f.id}">Editar cadastro</button></div>

    <h2>Férias</h2>
    <div class="cartao">
      ${fe.periodos.filter(p => p.restante > 0).map(p => `<div class="periodo ${p.diasParaLimite < 0 ? 'urgente' : p.diasParaLimite <= 120 ? 'aviso' : ''}">
          <b>${p.restante} dias a tirar</b>
          <p>Período ${dataBR(p.inicio)} a ${dataBR(p.fim)}</p>
          <p>${p.diasParaLimite < 0 ? `Prazo vencido em ${dataBR(p.limite)}` : `Tirar até ${dataBR(p.limite)}`} · cerca de ${C.brl(C.valorFerias(f.salario, p.restante))} com 1/3</p></div>`).join('')
        || `<p>Nenhum período pendente.</p>`}
      <p class="nota">Próximo direito a férias em ${dataBR(fe.proximoDireito)}.</p>
      ${(f.ferias || []).length ? `<h3>Férias já tiradas</h3>${f.ferias.map(x => `<div class="item"><span>${dataBR(x.inicio)} · ${x.dias} dias</span>
        <button class="link perigo" data-act="del-ferias" data-id="${x.id}">Excluir</button></div>`).join('')}` : ''}
      <button class="botao sec largo" data-act="add-ferias">Registrar férias tiradas</button>
    </div>

    <h2>13º salário de ${ano}</h2>
    <div class="cartao">
      <p>${d13.avos}/12 avos · total bruto estimado <b>${C.brl(d13.total)}</b></p>
      <div class="item"><span>1ª parcela (até 30/11): ${C.brl(d13.parcela1)}</span>${marca(`13-${ano}-1-${f.id}`)}</div>
      <div class="item"><span>2ª parcela (até 20/12): ${C.brl(d13.parcela2)}</span>${marca(`13-${ano}-2-${f.id}`)}</div>
      <p class="nota">Valores estimados, sem descontos. O valor oficial é o da folha do eSocial.</p>
    </div>

    <h2>Ocorrências</h2>
    <div class="cartao">
      ${oc.length ? oc.map(o => `<div class="item"><span><b>${esc(o.tipo)}</b> · ${dataBR(o.data)}${o.valor ? ` · ${C.brl(o.valor)}` : ''}${o.obs ? `<br><small>${esc(o.obs)}</small>` : ''}</span>
        <button class="link perigo" data-act="del-ocorr" data-id="${o.id}">Excluir</button></div>`).join('') : `<p>Nenhuma falta, folga, hora extra ou vale registrado.</p>`}
      <button class="botao sec largo" data-act="add-ocorr">Registrar ocorrência</button>
    </div>`;
}
const marca = k => `<button class="link" data-act="marcar" data-id="${k}">${S.marcas[k] ? '✓ Pago' : 'Marcar pago'}</button>`;

function telaMais() {
  const fx = S.fixas.filter(f => f.casa === S.casaAtual).sort((a, b) => a.dia - b.dia);
  return `
    <button class="botao largo" data-act="relatorio">Gerar relatório mensal em PDF</button>
    <h2>Contas fixas — ${esc(casaNome(S.casaAtual))}</h2>
    ${fx.length ? `<div class="lista">${fx.map(f => `<button data-act="editar-fixa" data-id="${f.id}">
        <div><b>${esc(f.nome)}</b><small>Todo dia ${f.dia} · ${esc(f.cat)}</small></div><span>${f.valor ? C.brl(f.valor) : ''}</span></button>`).join('')}</div>` : ''}
    <button class="botao sec largo" data-act="nova-fixa">+ Nova conta fixa</button>
    <h2>Configurações</h2>
    <div class="lista">
      <button data-act="orcamento"><div><b>Orçamento mensal por categoria</b><small>${esc(casaNome(S.casaAtual))}</small></div><span>›</span></button>
      <button data-act="casas"><div><b>Nomes das casas</b><small>${S.casas.map(c => esc(c.nome)).join(' · ')}</small></div><span>›</span></button>
      <button data-act="dae"><div><b>Lembrete da guia do eSocial</b><small>Avisar até o dia ${S.cfg.diaDAE} de cada mês</small></div><span>›</span></button>
    </div>
    <h2>Cópia de segurança</h2>
    <p class="nota">Os dados ficam só neste aparelho. Guarde uma cópia de tempos em tempos (no iCloud ou enviando para você mesma).</p>
    <div class="grade2">
      <button class="botao sec" data-act="exportar">Salvar cópia</button>
      <button class="botao sec" data-act="importar">Restaurar cópia</button>
    </div>
    <input type="file" id="arq-backup" accept=".json,application/json" hidden>`;
}

/* ---------- Folha de formulário (modal) ---------- */
function folha(titulo, corpo, { aoSalvar, aoExcluir, rotulo = 'Salvar' } = {}) {
  const raiz = $('#sheet-root');
  raiz.innerHTML = `<div class="fundo"><form class="folha" novalidate>
      <div class="topo"><button type="button" class="link" data-fechar>Cancelar</button><b>${esc(titulo)}</b><span></span></div>
      <div class="corpo">${corpo}</div>
      ${aoSalvar ? `<button class="botao largo">${rotulo}</button>` : ''}
      ${aoExcluir ? `<button type="button" class="link perigo largo" data-excluir>Excluir</button>` : ''}
    </form></div>`;
  const form = raiz.querySelector('form'), fechar = () => { raiz.innerHTML = ''; };
  raiz.querySelector('.fundo').addEventListener('click', e => { if (e.target.classList.contains('fundo') || e.target.hasAttribute('data-fechar')) fechar(); });
  form.addEventListener('submit', async e => {
    e.preventDefault();
    if (!aoSalvar) return;
    const erro = await aoSalvar(Object.fromEntries(new FormData(form)), form);
    if (erro) return toast(erro);
    fechar(); render(); await salvar();
  });
  if (aoExcluir) raiz.querySelector('[data-excluir]').addEventListener('click', async () => {
    if (!confirm('Excluir definitivamente?')) return;
    await aoExcluir(); fechar(); render(); await salvar();
  });
  return { form, fechar };
}
const campo = (rotulo, html) => `<label><span>${rotulo}</span>${html}</label>`;
const opcoes = (lista, sel) => lista.map(o => Array.isArray(o) ? o : [o, o]).map(([v, t]) => `<option value="${esc(v)}" ${v === sel ? 'selected' : ''}>${esc(t)}</option>`).join('');
const selCasa = sel => campo('Casa', `<select name="casa">${opcoes(S.casas.map(c => [c.id, c.nome]), sel)}</select>`);
function toast(msg) {
  const t = $('#toast'); t.textContent = msg; t.className = 'on';
  clearTimeout(toast.t); toast.t = setTimeout(() => { t.className = ''; }, 3200);
}

/* ---------- Fotos de notas ---------- */
function reduzirFoto(arquivo) {
  return new Promise((ok, erro) => {
    const img = new Image(), url = URL.createObjectURL(arquivo);
    img.onload = () => {
      const k = Math.min(1, 1400 / Math.max(img.width, img.height));
      const cv = document.createElement('canvas');
      cv.width = Math.round(img.width * k); cv.height = Math.round(img.height * k);
      cv.getContext('2d').drawImage(img, 0, 0, cv.width, cv.height);
      URL.revokeObjectURL(url);
      ok(cv.toDataURL('image/jpeg', 0.72));
    };
    img.onerror = () => erro(new Error('foto'));
    img.src = url;
  });
}

/* ---------- Formulários ---------- */
function formLanc(l) {
  const novo = !l.id;
  let removerFoto = false;
  const { form } = folha(novo ? (l.tipo === 'entrada' ? 'Nova entrada' : 'Novo gasto') : 'Editar lançamento', `
    <div class="seg"><label><input type="radio" name="tipo" value="saida" ${l.tipo !== 'entrada' ? 'checked' : ''}><span>Gasto</span></label>
      <label><input type="radio" name="tipo" value="entrada" ${l.tipo === 'entrada' ? 'checked' : ''}><span>Entrada</span></label></div>
    ${campo('Valor (R$)', `<input name="valor" inputmode="decimal" placeholder="0,00" value="${l.valor ? valorInput(l.valor) : ''}" class="grande">`)}
    ${selCasa(l.casa)}
    ${campo('Categoria', `<select name="cat"></select>`)}
    ${campo('Descrição', `<input name="desc" placeholder="Ex.: compra da semana" value="${esc(l.desc)}" autocomplete="off">`)}
    ${campo('Data', `<input type="date" name="data" value="${l.data}">`)}
    ${campo('Foto da nota', `<input type="file" name="arq" accept="image/*">`)}
    <div id="previa"></div>`, {
    aoSalvar: async (d) => {
      const valor = C.parseValor(d.valor);
      if (!(valor > 0)) return 'Informe um valor válido.';
      if (!d.data) return 'Informe a data.';
      let foto = l.foto || null;
      if (d.arq && d.arq.size) {
        let dados;
        try { dados = await reduzirFoto(d.arq); } catch (e) { return 'Não foi possível ler a foto.'; }
        if (foto) await DB.del('fotos', foto);
        foto = uid(); await DB.set('fotos', foto, dados);
      } else if (removerFoto && foto) { await DB.del('fotos', foto); foto = null; }
      const reg = { id: l.id || uid(), casa: d.casa, tipo: d.tipo, valor, data: d.data, cat: d.cat, desc: d.desc.trim(), foto };
      if (l.fixaId) reg.fixaId = l.fixaId;
      if (novo) S.lanc.push(reg); else S.lanc[S.lanc.findIndex(x => x.id === l.id)] = reg;
      ui.mes = d.data.slice(0, 7);
    },
    aoExcluir: novo ? null : async () => {
      if (l.foto) await DB.del('fotos', l.foto);
      S.lanc = S.lanc.filter(x => x.id !== l.id);
    }
  });
  const cats = () => {
    const ent = form.tipo.value === 'entrada';
    form.cat.innerHTML = opcoes(ent ? CATS_ENTRADA : CATS_SAIDA, l.cat);
  };
  form.querySelectorAll('[name=tipo]').forEach(r => r.addEventListener('change', cats));
  cats();
  if (l.foto) DB.get('fotos', l.foto).then(src => {
    if (!src || !form.isConnected) return;
    form.querySelector('#previa').innerHTML = `<img src="${src}" alt="Nota"><button type="button" class="link perigo">Remover foto</button>`;
    form.querySelector('#previa button').addEventListener('click', () => { removerFoto = true; form.querySelector('#previa').innerHTML = '<p class="nota">A foto será removida ao salvar.</p>'; });
  });
}

function formFunc(f) {
  const novo = !f.id;
  folha(novo ? 'Novo funcionário' : 'Editar funcionário', `
    ${campo('Nome', `<input name="nome" value="${esc(f.nome)}" autocomplete="off">`)}
    ${campo('Função', `<input name="funcao" placeholder="Ex.: cozinheira, motorista" value="${esc(f.funcao)}" autocomplete="off">`)}
    ${selCasa(f.casa)}
    ${campo('Data de admissão', `<input type="date" name="admissao" value="${f.admissao || ''}">`)}
    ${campo('Salário mensal (R$)', `<input name="salario" inputmode="decimal" placeholder="0,00" value="${f.salario ? valorInput(f.salario) : ''}">`)}
    ${campo('Observações', `<textarea name="obs" rows="2" placeholder="Telefone, dias de trabalho…">${esc(f.obs)}</textarea>`)}`, {
    aoSalvar: d => {
      const salario = C.parseValor(d.salario);
      if (!d.nome.trim()) return 'Informe o nome.';
      if (!d.admissao) return 'Informe a data de admissão.';
      if (d.admissao > hoje()) return 'A admissão não pode ser no futuro.';
      if (!(salario > 0)) return 'Informe o salário.';
      const reg = { ...f, id: f.id || uid(), nome: d.nome.trim(), funcao: d.funcao.trim(), casa: d.casa, admissao: d.admissao, salario, obs: d.obs.trim(), ferias: f.ferias || [], ocorr: f.ocorr || [] };
      if (novo) S.func.push(reg); else S.func[S.func.findIndex(x => x.id === f.id)] = reg;
    },
    aoExcluir: novo ? null : () => { S.func = S.func.filter(x => x.id !== f.id); ui.sub = null; }
  });
}

function formFixa(f) {
  const novo = !f.id;
  folha(novo ? 'Nova conta fixa' : 'Editar conta fixa', `
    ${campo('Nome', `<input name="nome" placeholder="Ex.: Luz, Jardineiro" value="${esc(f.nome)}" autocomplete="off">`)}
    ${selCasa(f.casa)}
    ${campo('Dia do vencimento', `<input name="dia" inputmode="numeric" placeholder="1 a 31" value="${f.dia || ''}">`)}
    ${campo('Valor aproximado (R$) — opcional', `<input name="valor" inputmode="decimal" placeholder="0,00" value="${f.valor ? valorInput(f.valor) : ''}">`)}
    ${campo('Categoria', `<select name="cat">${opcoes(CATS_SAIDA, f.cat || 'Contas (luz, água, gás)')}</select>`)}`, {
    aoSalvar: d => {
      const dia = Number(d.dia), valor = d.valor.trim() ? C.parseValor(d.valor) : 0;
      if (!d.nome.trim()) return 'Informe o nome.';
      if (!(dia >= 1 && dia <= 31 && Number.isInteger(dia))) return 'O dia deve ser de 1 a 31.';
      if (!(valor >= 0)) return 'Valor inválido.';
      const reg = { id: f.id || uid(), nome: d.nome.trim(), casa: d.casa, dia, valor, cat: d.cat };
      if (novo) S.fixas.push(reg); else S.fixas[S.fixas.findIndex(x => x.id === f.id)] = reg;
    },
    aoExcluir: novo ? null : () => { S.fixas = S.fixas.filter(x => x.id !== f.id); }
  });
}

function formCompra(i) {
  folha('Item da lista', `
    ${campo('Item', `<input name="nome" value="${esc(i.nome)}" autocomplete="off">`)}
    ${campo('Quantidade / observação', `<input name="qtd" placeholder="Ex.: 2 kg, marca X" value="${esc(i.qtd)}" autocomplete="off">`)}
    <label class="caixa"><input type="checkbox" name="rec" ${i.recorrente ? 'checked' : ''}><span>Item recorrente (volta para a lista com um toque)</span></label>`, {
    aoSalvar: d => {
      if (!d.nome.trim()) return 'Informe o item.';
      Object.assign(i, { nome: d.nome.trim(), qtd: d.qtd.trim(), recorrente: !!d.rec });
    },
    aoExcluir: () => { S.compras = S.compras.filter(x => x.id !== i.id); }
  });
}

/* ---------- Relatório em PDF ---------- */
function carregarScript(src) {
  return new Promise((ok, erro) => {
    if (document.querySelector(`script[src="${src}"]`)) return ok();
    const s = document.createElement('script'); s.src = src; s.onload = ok; s.onerror = () => erro(new Error(src));
    document.head.appendChild(s);
  });
}

async function gerarPDF(casa, mes, comFotos) {
  await carregarScript('vendor/jspdf.umd.min.js');
  await carregarScript('vendor/jspdf.plugin.autotable.min.js');
  const doc = new window.jspdf.jsPDF({ unit: 'mm', format: 'a4' });
  const ls = doMes(casa, mes).sort((a, b) => a.data.localeCompare(b.data));
  const anterior = saldo(casa, mes + '-01'), ent = soma(ls, 'entrada'), sai = soma(ls, 'saida');
  const verde = [31, 92, 77];

  doc.setFont('helvetica', 'bold').setFontSize(16).text('Prestação de contas', 14, 18);
  doc.setFont('helvetica', 'normal').setFontSize(11).text(`${casaNome(casa)} — ${mesLabel(mes)}`, 14, 25);
  doc.setFontSize(9).setTextColor(110).text(`Emitido em ${dataBR(hoje())}`, 14, 30).setTextColor(0);

  const estilo = { styles: { fontSize: 9, cellPadding: 2 }, headStyles: { fillColor: verde }, margin: { left: 14, right: 14 } };
  doc.autoTable({ ...estilo, startY: 36, theme: 'grid', head: [['Resumo do mês', 'Valor']],
    body: [['Saldo anterior', C.brl(anterior)], ['Entradas', C.brl(ent)], ['Saídas', C.brl(sai)], ['Saldo final', C.brl(anterior + ent - sai)]],
    columnStyles: { 1: { halign: 'right' } },
    didParseCell: c => { if (c.section === 'body' && c.row.index === 3) c.cell.styles.fontStyle = 'bold'; } });

  const cats = porCategoria(ls);
  if (cats.length) doc.autoTable({ ...estilo, startY: doc.lastAutoTable.finalY + 6, theme: 'striped', head: [['Gastos por categoria', 'Valor', '%']],
    body: cats.map(([c, v]) => [c, C.brl(v), Math.round(v / sai * 100) + '%']), columnStyles: { 1: { halign: 'right' }, 2: { halign: 'right' } } });

  let n = 0;
  const comNota = [];
  doc.autoTable({ ...estilo, startY: doc.lastAutoTable.finalY + 6, theme: 'striped',
    head: [['Data', 'Descrição', 'Categoria', 'Nota', 'Valor']],
    body: ls.length ? ls.map(l => {
      let ref = '';
      if (l.foto) { n++; ref = comFotos ? `nº ${n}` : 'sim'; comNota.push({ n, l }); }
      return [dataBR(l.data), l.desc || '—', l.cat, ref, (l.tipo === 'entrada' ? '+ ' : '- ') + C.brl(l.valor)];
    }) : [['', 'Nenhum lançamento no mês', '', '', '']],
    columnStyles: { 0: { cellWidth: 22 }, 3: { cellWidth: 14, halign: 'center' }, 4: { halign: 'right', cellWidth: 30 } } });

  if (comFotos) for (const { n: num, l } of comNota) {
    const src = await DB.get('fotos', l.foto);
    if (!src) continue;
    const p = doc.getImageProperties(src), k = Math.min(182 / p.width, 255 / p.height);
    doc.addPage();
    doc.setFontSize(10).text(`Nota nº ${num} — ${dataBR(l.data)} — ${l.desc || l.cat} — ${C.brl(l.valor)}`, 14, 14);
    doc.addImage(src, 'JPEG', 14, 20, p.width * k, p.height * k);
  }
  const total = doc.getNumberOfPages();
  for (let i = 1; i <= total; i++) doc.setPage(i).setFontSize(8).setTextColor(130).text(`Página ${i} de ${total}`, 196, 290, { align: 'right' });
  return doc.output('blob');
}

// O compartilhamento no iPhone precisa partir de um toque direto; por isso há um botão final.
function entregar(blob, nome, tipo, msg) {
  const arq = new File([blob], nome, { type: tipo });
  const { form, fechar } = folha('Arquivo pronto', `<p>${esc(msg)}</p><p class="nota">${esc(nome)}</p>
    <button type="button" class="botao largo" id="enviar">Compartilhar ou salvar</button>`);
  form.querySelector('#enviar').addEventListener('click', async () => {
    if (navigator.canShare && navigator.canShare({ files: [arq] })) {
      try { await navigator.share({ files: [arq], title: nome }); fechar(); return; }
      catch (e) { if (e.name === 'AbortError') return; }
    }
    const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = nome; a.click(); fechar();
  });
}

async function exportar() {
  const fotos = {};
  for (const k of await DB.chaves('fotos')) fotos[k] = await DB.get('fotos', k);
  const blob = new Blob([JSON.stringify({ app: 'gestao-casas', quando: new Date().toISOString(), estado: S, fotos })], { type: 'application/json' });
  entregar(blob, `casas-copia-${hoje()}.json`, 'application/json', 'Cópia de segurança criada com todos os lançamentos, funcionários e fotos.');
}
async function importar(arquivo) {
  let d;
  try { d = JSON.parse(await arquivo.text()); } catch (e) { return toast('Arquivo inválido.'); }
  if (d.app !== 'gestao-casas' || !d.estado || !Array.isArray(d.estado.casas)) return toast('Este arquivo não é uma cópia deste aplicativo.');
  if (!confirm(`Restaurar a cópia de ${dataBR(String(d.quando).slice(0, 10))}?\n\nTodos os dados atuais deste aparelho serão substituídos.`)) return;
  await DB.limpar('fotos');
  for (const [k, v] of Object.entries(d.fotos || {})) await DB.set('fotos', k, v);
  S = { ...estadoInicial(), ...d.estado };
  await salvar(); ui.sub = null; render(); toast('Cópia restaurada.');
}

/* ---------- Ações ---------- */
const acoes = {
  aba: id => { ui.tab = id; ui.sub = null; window.scrollTo(0, 0); },
  voltar: () => { ui.sub = null; },
  casa: id => { S.casaAtual = id; salvar(); },
  'ir-casa': id => { S.casaAtual = id; ui.tab = 'financas'; ui.mes = hoje().slice(0, 7); salvar(); },
  mes: d => { const x = C.parse(ui.mes + '-01'); x.setMonth(x.getMonth() + Number(d)); ui.mes = C.iso(x).slice(0, 7); },
  'novo-lanc': tipo => formLanc({ tipo, casa: S.casaAtual, data: hoje(), desc: '' }),
  'editar-lanc': id => formLanc(S.lanc.find(l => l.id === id)),
  'pagar-fixa': id => { const f = S.fixas.find(x => x.id === id); formLanc({ tipo: 'saida', casa: f.casa, data: hoje(), desc: f.nome, cat: f.cat, valor: f.valor, fixaId: f.id }); },
  marcar: k => { if (S.marcas[k]) delete S.marcas[k]; else S.marcas[k] = true; salvar(); },

  check: id => { const i = S.compras.find(x => x.id === id); i.feito = !i.feito; salvar(); },
  'editar-compra': id => formCompra(S.compras.find(x => x.id === id)),
  'voltar-lista': id => { Object.assign(S.compras.find(x => x.id === id), { naLista: true, feito: false }); salvar(); },
  'add-recorrentes': () => { S.compras.filter(i => i.casa === S.casaAtual && !i.naLista).forEach(i => Object.assign(i, { naLista: true, feito: false })); salvar(); },
  'concluir-compra': () => {
    const casa = S.casaAtual;
    S.compras = S.compras.filter(i => !(i.casa === casa && i.naLista && i.feito && !i.recorrente));
    S.compras.filter(i => i.casa === casa && i.naLista && i.feito).forEach(i => Object.assign(i, { naLista: false, feito: false }));
    salvar();
    setTimeout(() => { if (confirm('Compra concluída. Registrar o valor gasto agora?')) formLanc({ tipo: 'saida', casa, data: hoje(), desc: 'Compras', cat: 'Supermercado' }); }, 50);
  },

  'novo-func': () => formFunc({ casa: S.casaAtual, nome: '', funcao: '', obs: '' }),
  'abrir-func': id => { const f = S.func.find(x => x.id === id); S.casaAtual = f.casa; ui.tab = 'equipe'; ui.sub = id; window.scrollTo(0, 0); },
  'editar-func': id => formFunc(S.func.find(x => x.id === id)),
  'add-ferias': () => {
    const f = S.func.find(x => x.id === ui.sub);
    folha('Registrar férias', `${campo('Início das férias', `<input type="date" name="inicio" value="${hoje()}">`)}
      ${campo('Quantidade de dias', `<input name="dias" inputmode="numeric" value="30">`)}`, {
      aoSalvar: d => {
        const dias = Number(d.dias);
        if (!d.inicio) return 'Informe a data de início.';
        if (!(Number.isInteger(dias) && dias >= 1 && dias <= 30)) return 'Informe de 1 a 30 dias.';
        (f.ferias = f.ferias || []).push({ id: uid(), inicio: d.inicio, dias });
      }
    });
  },
  'del-ferias': id => { if (!confirm('Excluir este registro de férias?')) return; const f = S.func.find(x => x.id === ui.sub); f.ferias = f.ferias.filter(x => x.id !== id); salvar(); },
  'add-ocorr': () => {
    const f = S.func.find(x => x.id === ui.sub);
    folha('Registrar ocorrência', `${campo('Tipo', `<select name="tipo">${opcoes(TIPOS_OCORR)}</select>`)}
      ${campo('Data', `<input type="date" name="data" value="${hoje()}">`)}
      ${campo('Valor (R$) — se houver', `<input name="valor" inputmode="decimal" placeholder="0,00">`)}
      ${campo('Observação', `<input name="obs" placeholder="Ex.: 3 horas extras" autocomplete="off">`)}`, {
      aoSalvar: d => {
        const valor = d.valor.trim() ? C.parseValor(d.valor) : 0;
        if (!d.data) return 'Informe a data.';
        if (!(valor >= 0)) return 'Valor inválido.';
        (f.ocorr = f.ocorr || []).push({ id: uid(), tipo: d.tipo, data: d.data, valor, obs: d.obs.trim() });
      }
    });
  },
  'del-ocorr': id => { if (!confirm('Excluir esta ocorrência?')) return; const f = S.func.find(x => x.id === ui.sub); f.ocorr = f.ocorr.filter(x => x.id !== id); salvar(); },

  'nova-fixa': () => formFixa({ casa: S.casaAtual, nome: '' }),
  'editar-fixa': id => formFixa(S.fixas.find(x => x.id === id)),
  orcamento: () => {
    const casa = S.casaAtual, o = S.orc[casa] || {};
    folha(`Orçamento — ${casaNome(casa)}`, `<p class="nota">Limite mensal por categoria. Deixe em branco para não controlar.</p>
      ${CATS_SAIDA.map((c, i) => campo(c, `<input name="c${i}" inputmode="decimal" placeholder="sem limite" value="${o[c] ? valorInput(o[c]) : ''}">`)).join('')}`, {
      aoSalvar: d => {
        const novo = {};
        for (let i = 0; i < CATS_SAIDA.length; i++) {
          const t = d['c' + i].trim(); if (!t) continue;
          const v = C.parseValor(t); if (!(v > 0)) return `Valor inválido em ${CATS_SAIDA[i]}.`;
          novo[CATS_SAIDA[i]] = v;
        }
        S.orc[casa] = novo;
      }
    });
  },
  casas: () => folha('Nomes das casas', S.casas.map((c, i) => campo(`Casa ${i + 1}`, `<input name="n${i}" value="${esc(c.nome)}" autocomplete="off">`)).join(''), {
    aoSalvar: d => {
      if (S.casas.some((c, i) => !d['n' + i].trim())) return 'Informe o nome das duas casas.';
      S.casas.forEach((c, i) => { c.nome = d['n' + i].trim(); });
    }
  }),
  dae: () => folha('Lembrete do eSocial', `<p class="nota">Dia limite para pagar a guia mensal (DAE) dos funcionários. Confira a data na própria guia.</p>
      ${campo('Dia do mês', `<input name="dia" inputmode="numeric" value="${S.cfg.diaDAE}">`)}`, {
    aoSalvar: d => { const n = Number(d.dia); if (!(Number.isInteger(n) && n >= 1 && n <= 28)) return 'Informe um dia de 1 a 28.'; S.cfg.diaDAE = n; }
  }),
  relatorio: () => {
    const { form, fechar } = folha('Relatório mensal', `${selCasa(S.casaAtual)}
      ${campo('Mês', `<select name="mes">${opcoes(mesesComDados().map(m => [m, mesLabel(m)]), ui.mes)}</select>`)}
      <label class="caixa"><input type="checkbox" name="fotos" checked><span>Anexar as fotos das notas</span></label>
      <button type="button" class="botao largo" id="gerar">Gerar PDF</button>`);
    form.querySelector('#gerar').addEventListener('click', async e => {
      e.target.disabled = true; e.target.textContent = 'Gerando…';
      try {
        const blob = await gerarPDF(form.casa.value, form.mes.value, form.fotos.checked);
        const nome = `prestacao-${casaNome(form.casa.value).toLowerCase().replace(/[^a-z0-9]+/g, '-')}-${form.mes.value}.pdf`;
        fechar(); entregar(blob, nome, 'application/pdf', `Relatório de ${mesLabel(form.mes.value)} — ${casaNome(form.casa.value)}.`);
      } catch (err) { console.error(err); e.target.disabled = false; e.target.textContent = 'Gerar PDF'; toast('Não foi possível gerar o PDF.'); }
    });
  },
  exportar: () => exportar(),
  importar: () => $('#arq-backup').click()
};
function mesesComDados() {
  const s = new Set(S.lanc.map(l => l.data.slice(0, 7))); s.add(hoje().slice(0, 7)); s.add(ui.mes);
  return [...s].sort().reverse();
}

document.addEventListener('click', e => {
  const el = e.target.closest('[data-act]');
  if (!el || !acoes[el.dataset.act]) return;
  acoes[el.dataset.act](el.dataset.id);
  if (!$('#sheet-root').firstChild) render();
});
document.addEventListener('submit', e => {
  if (e.target.dataset.form !== 'add-compra') return;
  e.preventDefault();
  const nome = e.target.nome.value.trim();
  if (!nome) return;
  S.compras.push({ id: uid(), casa: S.casaAtual, nome, qtd: '', recorrente: false, naLista: true, feito: false });
  salvar(); render(); $('.linha-add input').focus();
});
document.addEventListener('change', e => {
  if (e.target.id === 'arq-backup' && e.target.files[0]) importar(e.target.files[0]);
});

/* ---------- Início ---------- */
(async function iniciar() {
  try { S = { ...estadoInicial(), ...(await DB.get('kv', 'estado') || {}) }; }
  catch (e) { S = estadoInicial(); toast('Não foi possível abrir os dados salvos.'); }
  if (!S.casas.some(c => c.id === S.casaAtual)) S.casaAtual = S.casas[0].id;
  render();
  if (navigator.storage && navigator.storage.persist) navigator.storage.persist();
  if ('serviceWorker' in navigator && location.protocol.startsWith('http')) navigator.serviceWorker.register('sw.js').catch(() => {});
})();
