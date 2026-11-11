"""Gera Mapa_do_Eu_Workbook.pdf a partir de conteudo.py (HTML -> PDF via Chromium/Playwright).
Uso: python3 build.py && node render.js   (requer playwright + chromium)"""
import html, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from conteudo import *
e = html.escape
OUT = os.path.join(os.path.dirname(__file__), "..", "Mapa_do_Eu_Workbook.pdf")
HTML = os.path.join(os.path.dirname(__file__), "workbook.html")

def lines(n): return '<div class="lines">' + '<i></i>'*n + '</div>'

COMPASS = '''<svg viewBox="-100 -100 200 200" width="150" height="150">
<g fill="none" stroke="#e8b94a" stroke-width="1.2"><circle r="92" opacity=".5"/><circle r="78" opacity=".8"/></g>
<g fill="#e8b94a"><polygon points="0,-90 9,-9 0,0 -9,-9"/><polygon points="0,90 9,9 0,0 -9,9" opacity=".75"/>
<polygon points="90,0 9,9 0,0 9,-9" opacity=".75"/><polygon points="-90,0 -9,9 0,0 -9,-9" opacity=".75"/></g>
<g fill="#f6d77c"><polygon points="0,-52 5,-5 -5,-5" transform="rotate(45)"/><polygon points="0,-52 5,-5 -5,-5" transform="rotate(135)"/>
<polygon points="0,-52 5,-5 -5,-5" transform="rotate(225)"/><polygon points="0,-52 5,-5 -5,-5" transform="rotate(315)"/></g>
<circle r="4" fill="#07142b"/></svg>'''

p = []
# capa
p.append(f'''<section class="cover"><div class="cover-in">
<div class="kicker">Jornada de autoconhecimento</div>{COMPASS}
<h1>MAPA<br>DO <span>EU</span></h1>
<div class="rule"></div>
<h2>Uma jornada prática de autoconhecimento</h2>
<p>Compreenda suas emoções, reconheça seus padrões e construa uma relação mais consciente consigo mesmo.</p>
<div class="tags">Identidade • Emoções • Transformação</div>
<div class="tags2">8 módulos • Diário de 21 dias • Plano pessoal</div>
<div class="ed">Workbook digital • Edição 2026</div></div></section>''')

# boas-vindas + sumário
sumario = ''.join(f'<li><b>{m["n"]:02d}</b> {e(m["titulo"])}</li>' for m in MODULOS)
sumario += '<li><b>09</b> Diário prático de autoconhecimento — 21 dias</li><li><b>10</b> Plano pessoal de desenvolvimento</li>'
p.append(f'''<section class="page"><h1 class="pt">Boas-vindas à sua jornada</h1>
<p>Este workbook foi criado para ajudar você a observar a própria experiência com mais clareza. Ao longo das páginas, encontrará explicações acessíveis, perguntas de reflexão, exercícios e um percurso de 21 dias. Não é necessário responder tudo de uma vez: avance no seu ritmo e retorne às atividades quando fizer sentido.</p>
<h3>Como utilizar este material</h3><ul class="bul">
<li>Reserve de 10 a 20 minutos por atividade, em um ambiente no qual consiga pensar sem pressa.</li>
<li>Escreva com honestidade, sem tentar produzir respostas bonitas ou impressionar alguém.</li>
<li>Observe padrões ao longo do tempo. Uma resposta isolada não define sua personalidade.</li>
<li>Escolha uma ação pequena e realista para experimentar entre uma reflexão e outra.</li>
<li>Respeite seus limites. Se uma atividade provocar sofrimento intenso, interrompa-a e procure apoio profissional.</li></ul>
<h3>Uma nota de responsabilidade</h3>
<p>O Mapa do Eu é um material educativo e de desenvolvimento pessoal. Não realiza diagnóstico, não substitui psicoterapia, psicanálise, atendimento médico ou qualquer acompanhamento profissional. Conceitos psicológicos apresentados aqui são convites à reflexão, não rótulos para classificar você ou outras pessoas.</p>
<div class="quote">Autoconhecimento não é encontrar uma versão perfeita de si. É desenvolver curiosidade, responsabilidade e compaixão para compreender sua experiência e escolher como deseja agir.</div>
</section>
<section class="page"><h1 class="pt">Sumário</h1><ul class="toc">{sumario}</ul></section>''')

# módulos
for m in MODULOS:
    secs = ''.join(f'<h3>{e(t)}</h3><p>{e(x)}</p>' for t,x in m["secoes"])
    perg = ''.join(f'<div class="q"><b>{i}. {e(q)}</b>{lines(2)}</div>' for i,q in enumerate(m["perguntas"],1))
    p.append(f'''<section class="page"><div class="mk">Módulo {m["n"]}</div><h1 class="pt">{e(m["titulo"])}</h1>
<div class="sub">{e(m["sub"])}</div>{secs}</section>
<section class="page"><h3 class="cap">Exercício de reflexão</h3>{perg}
<h3 class="cap">Desafio prático</h3><p>{e(m["desafio"])}</p></section>
<section class="page"><h3 class="cap">Folha de trabalho — {e(m["folha"])}</h3>
<div class="ws">''' + ''.join(f'<div class="q"><b>{t}</b>{lines(4)}</div>' for t in ["O que observei:","O que senti ou pensei:","O que aprendi:","Qual será meu próximo passo:"]) + '</div></section>')

# diário
p.append(f'''<section class="page"><div class="mk">Parte 9</div><h1 class="pt">Diário prático de autoconhecimento</h1>
<div class="sub">21 dias para observar, refletir e experimentar pequenas mudanças</div><p>{e(DIARIO_INTRO)}</p>
<h3>Como usar</h3><ul class="bul"><li>Dedique alguns minutos por dia, sempre que possível no mesmo horário.</li><li>Cada dia traz uma prática breve, uma pergunta e espaço para suas anotações.</li><li>Marque os dias concluídos abaixo.</li></ul>
<div class="track">''' + ''.join(f'<span>{i}</span>' for i in range(1,22)) + '</div></section>')
for i in range(0,21,3):
    blk = ''
    for d in range(i,min(i+3,21)):
        t,pr,q = DIARIO[d]
        blk += f'<div class="day"><h3>Dia {d+1} — {e(t)}</h3><p>{e(pr)}</p><p class="pd"><b>Pergunta do dia:</b> {e(q)}</p><div class="an">Minhas anotações:</div>{lines(3)}</div>'
    p.append(f'<section class="page days">{blk}</section>')

# plano
pl = ''.join(f'<div class="q"><b>{i}. {e(t)}</b><span class="hint">{e(h)}</span>{lines(2)}</div>' for i,(t,h) in enumerate(PLANO,1))
chk = ''.join(f'<li>{e(c)}</li>' for c in CHECKLIST)
p.append(f'''<section class="page plan"><div class="mk">Parte 10</div><h1 class="pt">Meu plano pessoal de desenvolvimento</h1>
<div class="sub">Transforme descobertas em compromissos observáveis</div><p>{e(PLANO_INTRO)}</p>{pl}</section>
<section class="page"><h3 class="cap">Checklist de continuidade</h3><ul class="chk">{chk}</ul>
<div class="end"><div class="rule"></div><p>Conhecer a si mesmo é um processo.<br>Continue fazendo perguntas melhores.</p><small>Mapa do Eu • Workbook de autoconhecimento<br>Material educativo e de desenvolvimento pessoal. Não substitui acompanhamento psicológico, psicanalítico ou médico.</small></div></section>''')

CSS = '''
@page{size:A4;margin:22mm 20mm 22mm 20mm;@bottom-left{content:"MAPA DO EU  •  WORKBOOK DE AUTOCONHECIMENTO";font:7.5pt Inter;color:#7a8699;border-top:.6pt solid #e8b94a;padding-top:4mm;width:100%}
 @bottom-right{content:counter(page);font:7.5pt Inter;color:#7a8699;border-top:.6pt solid #e8b94a;padding-top:4mm}}
@page cover{margin:0;@bottom-left{content:none;border:0}@bottom-right{content:none;border:0}}
*{box-sizing:border-box;margin:0;padding:0}
body{font:10.2pt/1.6 Inter,sans-serif;color:#1d2a3d}
.cover{page:cover;break-after:page;height:297mm;background:radial-gradient(120% 70% at 50% 0%,#17386f,#07142b 65%);color:#fff;position:relative;display:flex;align-items:center;justify-content:center;text-align:center}
.cover::after{content:"";position:absolute;inset:10mm;border:.8pt solid #e8b94a;opacity:.7;pointer-events:none}
.cover-in{padding:0 28mm}.kicker{font-size:8.5pt;letter-spacing:.35em;text-transform:uppercase;color:#5fd4e8;margin-bottom:12mm}
.cover svg{margin:0 auto 10mm;display:block}
.cover h1{font:700 62pt/1.02 "Bitstream Charter",serif;letter-spacing:.02em}.cover h1 span{color:#e8b94a}
.rule{width:60mm;height:.8pt;background:#e8b94a;margin:10mm auto}
.cover h2{font:italic 400 17pt/1.3 "Bitstream Charter",serif;color:#f6d77c;margin-bottom:6mm}
.cover p{font-size:11pt;color:#cfe0f3;max-width:120mm;margin:0 auto 14mm}
.tags{font-size:8.5pt;letter-spacing:.25em;text-transform:uppercase;color:#e8b94a;font-weight:600}.tags2{font-size:8pt;color:#9fb4d1;margin-top:3mm;letter-spacing:.08em}
.ed{position:absolute;bottom:20mm;left:0;right:0;font-size:7.5pt;letter-spacing:.2em;text-transform:uppercase;color:#7f95b5}
.page{break-before:page}.cover+.page{break-before:auto}
h1.pt{font:700 21pt/1.2 "Bitstream Charter",serif;color:#07142b;margin-bottom:3mm}
.mk{font-size:8.5pt;letter-spacing:.3em;text-transform:uppercase;color:#0e7c90;font-weight:700;margin-bottom:2mm}
.sub{font:italic 12pt "Bitstream Charter",serif;color:#8a6a14;margin-bottom:7mm;padding-bottom:4mm;border-bottom:.6pt solid #e8b94a}
h3{font:700 12pt "Bitstream Charter",serif;color:#0e7c90;margin:6mm 0 1.5mm;break-after:avoid}
h3.cap{font:700 10pt Inter;letter-spacing:.14em;text-transform:uppercase;color:#0e7c90;margin-top:0;margin-bottom:4mm}
h3.cap:not(:first-child){margin-top:9mm}
p{margin-bottom:2mm}
.bul{margin:2mm 0 0 5mm}.bul li{margin-bottom:1.5mm}
.quote{margin-top:9mm;padding:6mm 7mm;border-left:2pt solid #e8b94a;background:#f6f1e2;font:italic 12pt/1.5 "Bitstream Charter",serif;color:#07142b}
.toc{list-style:none;margin-top:8mm}.toc li{padding:3.2mm 0;border-bottom:.5pt solid #e1e6ee;font-size:11pt}.toc b{color:#e8b94a;background:#07142b;border-radius:50%;display:inline-block;width:8mm;height:8mm;line-height:8mm;text-align:center;font-size:8.5pt;margin-right:4mm}
.q{break-inside:avoid;margin-bottom:5mm}.q b{font-size:10pt}.hint{display:block;font-size:8.8pt;color:#6b778a;margin:.5mm 0 0}
.lines i{display:block;height:8.2mm;border-bottom:.6pt solid #aeb8c7}
.ws{border:.8pt solid #e8b94a;border-radius:3mm;padding:8mm 8mm 3mm}
.track{display:flex;flex-wrap:wrap;gap:3mm;margin-top:8mm}.track span{width:11mm;height:11mm;border:.8pt solid #e8b94a;border-radius:50%;text-align:center;line-height:10mm;font-size:9pt;color:#07142b}
.days .day{break-inside:avoid;margin-bottom:5mm;padding-bottom:1mm;border-bottom:.5pt dashed #c9d1de}.days h3{margin-top:0;font-size:11pt}.days p{font-size:9.4pt;margin-bottom:1mm}.pd{color:#07142b}.an{font-size:8.5pt;color:#6b778a;margin-top:1.5mm}
.days .lines i{height:6.6mm}
.plan .q{margin-bottom:3mm}.plan .lines i{height:6.6mm}.plan .sub{margin-bottom:4mm}.plan h1.pt{font-size:19pt}
.chk{list-style:none}.chk li{padding:3.2mm 0 3.2mm 9mm;position:relative;border-bottom:.5pt solid #e1e6ee}.chk li::before{content:"";position:absolute;left:0;top:3.6mm;width:4.5mm;height:4.5mm;border:.8pt solid #0e7c90;border-radius:1mm}
.end{text-align:center;margin-top:22mm}.end p{font:italic 14pt/1.5 "Bitstream Charter",serif;color:#07142b}.end small{display:block;margin-top:12mm;font-size:7.8pt;color:#6b778a;line-height:1.5}
'''
open(HTML,"w",encoding="utf-8").write(f'<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8"><title>Mapa do Eu — Workbook</title><style>{CSS}</style></head><body>{"".join(p)}</body></html>')

print("html ok", HTML)
