#!/usr/bin/env python3
"""Gera index.html e compositions/*.html a partir da lista de planos abaixo.

Os tempos ficam todos aqui: para ajustar à narração, mude `dur` de cada plano
e rode `python3 build.py`. Cada bloco do roteiro é uma sub-composição.
"""
import json
import pathlib

HERE = pathlib.Path(__file__).parent
XF = 0.7  # crossfade entre planos, em segundos

# Cada plano: id, dur (s), img (número do arquivo em assets/img) ou None,
# kb = (escala inicial, escala final, deslocamento x, deslocamento y) em px,
# lines = [(classe, texto, atraso em s)], pos = center | low | left
BLOCKS = {
    "gancho": [
        dict(id="email", dur=5.0, img=None, special="email"),
        dict(id="noite", dur=6.5, img=1, kb=(1.04, 1.14, -30, 0),
             lines=[("cap", "Meses de trabalho.", 0.8), ("cap", "Noites. Fins de semana. Paz.", 3.0)], pos="low"),
        dict(id="vitoria", dur=5.0, img=2, kb=(1.18, 1.04, 0, 20),
             lines=[("serif xl", "Você conseguiu.", 1.6)], pos="low"),
        dict(id="apaga", dur=3.8, img=None, special="dim",
             lines=[("serif lg", "E então, algo estranho começou.", 0.5)], pos="center"),
        dict(id="mensagens", dur=6.0, img=3, kb=(1.05, 1.16, 40, 0),
             lines=[("cap", "Parou de responder o que era importante.", 0.6),
                    ("cap", "Atrasou o que era simples.", 3.2)], pos="low"),
        dict(id="briga", dur=5.6, img=4, kb=(1.14, 1.04, 0, 0),
             lines=[("cap", "Brigou com quem estava do seu lado.", 0.5),
                    ("cap dim", "Ou simplesmente… parou.", 3.0)], pos="low"),
        dict(id="pausa", dur=2.0, img=None),
        dict(id="corredor", dur=4.2, img=5, kb=(1.02, 1.12, 0, 0),
             lines=[("serif lg", "Não foi azar.", 0.5), ("serif lg", "E não foi preguiça.", 2.0)], pos="low"),
        dict(id="estudio", dur=5.8, img=6, kb=(1.12, 1.03, -20, 0),
             lines=[("serif lg", "Há mais de cem anos,<br>um homem descreveu exatamente isso.", 0.8)], pos="low"),
    ],
    "promessa": [
        dict(id="livros", dur=14.0, img=14, kb=(1.04, 1.15, 30, 0),
             scrim=True,
             lines=[("kicker", "NESTE VÍDEO", 0.6),
                    ("item", "<b>01</b> O que Freud descobriu", 5.2),
                    ("item", "<b>02</b> O que a neurociência sugere", 7.6),
                    ("item", "<b>03</b> O que pode ajudar", 10.0)], pos="left"),
        dict(id="titulo", dur=7.5, img=16, kb=(1.03, 1.10, 0, 0), dimmer=0.72,
             lines=[("serif title", "Por que você se sabota<br>quando está tudo indo bem", 0.6),
                    ("cap dim", "Fique até o final.", 3.6)], pos="center"),
    ],
    "bloco1": [
        dict(id="def", dur=10.0, img=None, special="glow",
             lines=[("kicker", "AUTOSSABOTAGEM", 0.8),
                    ("serif lg", "Agir, sem perceber, contra um objetivo<br>que você diz querer.", 3.2)], pos="center"),
        dict(id="trabalho", dur=5.5, img=7, kb=(1.03, 1.12, 0, 0),
             lines=[("kicker amb", "TRABALHO", 0.6), ("cap", "É promovida. E começa a faltar.", 1.0)], pos="low"),
        dict(id="relacao", dur=5.0, img=8, kb=(1.12, 1.03, 20, 0),
             lines=[("kicker amb", "RELACIONAMENTO", 0.5), ("cap", "Vai bem. E ela inventa uma briga.", 0.9)], pos="low"),
        dict(id="corpo", dur=5.0, img=9, kb=(1.03, 1.12, -20, 0),
             lines=[("kicker amb", "CORPO", 0.5), ("cap", "Perto da meta, vem o descontrole.", 0.9)], pos="low"),
        dict(id="estudos", dur=5.0, img=10, kb=(1.12, 1.03, 0, 0),
             lines=[("kicker amb", "ESTUDOS", 0.5), ("cap", "A um passo. E deixa de estudar.", 0.9)], pos="low"),
        dict(id="escada", dur=7.0, img=11, kb=(1.02, 1.16, -40, 30),
             lines=[("serif lg", "Quanto mais perto,", 1.0), ("serif lg", "mais forte o impulso de estragar.", 2.6)], pos="low"),
        dict(id="linha", dur=9.5, img=None, special="line",
             lines=[("cap", "Não é fraqueza.", 4.2), ("cap", "Não é falta de força de vontade.", 5.6)], pos="low"),
        dict(id="aviso", dur=10.5, img=12, kb=(1.10, 1.02, 0, 0),
             lines=[("kicker", "UM AVISO", 0.6), ("serif lg", "Nada disso é diagnóstico.", 1.2),
                    ("cap dim", "É um padrão que muita gente reconhece em si.", 4.6)], pos="low"),
    ],
    "bloco2": [
        dict(id="manuscrito", dur=7.0, img=13, kb=(1.04, 1.16, -30, -10),
             lines=[("serif xl", "1916", 0.6), ("cap", "Freud escreve sobre tipos de caráter.", 2.2)], pos="low"),
        dict(id="ensaio", dur=7.0, img=6, kb=(1.14, 1.05, 20, 0), dimmer=0.7,
             lines=[("kicker", "SIGMUND FREUD · 1916", 0.6), ("serif title", "“Os arruinados pelo êxito”", 1.4)], pos="center"),
        dict(id="paradoxo", dur=17.0, img=None, special="glow",
             lines=[("kicker", "O ESPERADO", 0.8), ("row", "Desejo frustrado <i>→</i> adoecer", 1.4),
                    ("kicker amb", "O QUE FREUD VIU", 6.4), ("row", "Desejo realizado <i>→</i> adoecer", 7.0),
                    ("serif lg gap", "Parecia um paradoxo.", 14.0)], pos="center"),
        dict(id="culpa", dur=10.0, img=5, kb=(1.03, 1.14, 0, 0),
             lines=[("kicker", "A EXPLICAÇÃO", 0.6), ("serif xl", "Culpa.", 1.4),
                    ("cap dim", "Uma instância que julga: o Superego.", 5.0)], pos="low"),
        dict(id="proibidos", dur=11.0, img=None, special="glow",
             lines=[("kicker", "DESEJOS PROIBIDOS", 0.8), ("row", "Superar alguém.", 3.4),
                    ("row", "Deixar alguém para trás.", 5.4), ("row", "Ter o que um pai ou uma mãe nunca teve.", 7.4)], pos="center"),
        dict(id="merece", dur=9.5, img=5, kb=(1.30, 1.42, 0, 40), dimmer=0.35,
             lines=[("serif title", "“Você não merece isso.”", 3.0)], pos="center"),
        dict(id="macbeth", dur=9.0, img=15, kb=(1.04, 1.15, 0, -20),
             lines=[("kicker amb", "SHAKESPEARE", 0.6), ("serif lg", "Lady Macbeth", 1.2),
                    ("cap dim", "Desmorona depois de conseguir o que queria.", 4.2)], pos="low"),
        dict(id="leitura", dur=13.0, img=16, kb=(1.12, 1.03, 0, 0),
             lines=[("kicker", "IMPORTANTE", 0.6), ("cap", "É uma interpretação clínica,", 3.0),
                    ("cap dim", "não um fato medido em laboratório.", 5.2)], pos="low"),
    ],
    "bloco3": [
        dict(id="cerebro", dur=9.0, img=17, kb=(1.0, 1.10, 30, 0), shift=340, scrim=True,
             lines=[("kicker", "O QUE O CÉREBRO SUGERE", 0.6), ("serif lg", "Três ideias.", 3.6),
                    ("cap dim", "Todas são hipóteses.", 6.4)], pos="left"),
        dict(id="c1", dur=4.5, img=18, kb=(1.04, 1.12, 0, 0), dimmer=0.45,
             lines=[("num", "01", 0.4), ("serif lg", "O cérebro prefere o previsível.", 0.9)], pos="center"),
        dict(id="friston", dur=18.0, img=18, kb=(1.12, 1.26, 40, 0), scrim=True,
             lines=[("kicker", "KARL FRISTON · CÉREBRO PREDITIVO", 0.6), ("row", "Prever. Reduzir surpresas.", 2.6),
                    ("kicker amb gap", "MARK SOLMS · NEUROPSICANÁLISE", 9.0), ("row", "Sentimentos como sinais<br>do que importa.", 11.0)], pos="left"),
        dict(id="transito", dur=10.5, img=19, kb=(1.03, 1.14, -30, 0),
             lines=[("serif lg", "Imprevisível pode soar como risco.", 4.6), ("cap dim", "Mesmo quando é bom.", 8.0)], pos="low"),
        dict(id="c2", dur=4.5, img=20, kb=(1.04, 1.10, 0, 0), dimmer=0.4,
             lines=[("num", "02", 0.4), ("serif lg", "Buscar não é o mesmo que ter.", 0.9)], pos="center"),
        dict(id="querer", dur=17.0, img=None, special="glow",
             lines=[("kicker", "KENT BERRIDGE", 0.8), ("row big", "Querer <i>≠</i> Gostar", 2.6),
                    ("cap dim", "Dopamina: mais ligada à busca do que ao prazer de ter.", 6.4),
                    ("kicker amb gap", "JAAK PANKSEPP", 12.4), ("row big", "SEEKING", 13.4)], pos="center"),
        dict(id="topo", dur=17.0, img=20, kb=(1.10, 1.26, 0, 30),
             lines=[("cap", "Quando você chega lá, a busca termina.", 0.8),
                    ("cap dim", "O vazio pode empurrar a criar um novo problema,<br>só para voltar a buscar.", 8.6)], pos="low"),
        dict(id="c3", dur=4.5, img=21, kb=(1.04, 1.10, 0, 0), dimmer=0.4,
             lines=[("num", "03", 0.4), ("serif lg", "A imagem que você tem de si.", 0.9)], pos="center"),
        dict(id="swann", dur=21.0, img=21, kb=(1.10, 1.24, -60, 0), scrim=True,
             lines=[("kicker", "WILLIAM SWANN", 0.6), ("row big", "Autoverificação", 2.4),
                    ("cap dim", "Buscamos o que confirma a imagem<br>que temos de nós. Mesmo a negativa.", 5.0),
                    ("cap gap", "O sucesso cria um conflito.", 13.6), ("cap", "A sabotagem restaura a coerência.", 17.0)], pos="left"),
        dict(id="camadas", dur=8.0, img=22, kb=(1.02, 1.10, 60, 0), scrim=True,
             lines=[("kicker", "CAMADAS DA MESMA HISTÓRIA", 0.6), ("item", "<b>·</b>Culpa", 1.6),
                    ("item", "<b>·</b>Previsibilidade", 2.4), ("item", "<b>·</b>Autoimagem", 3.2)], pos="left"),
    ],
    "bloco4": [
        dict(id="abre", dur=6.0, img=23, kb=(1.03, 1.10, 0, 0), scrim=True,
             lines=[("kicker", "O QUE PODE AJUDAR", 0.6), ("serif lg", "Cinco passos<br>para se observar.", 1.4),
                    ("cap dim", "Isto não é uma cura.", 3.4)], pos="left"),
        dict(id="p1", dur=14.5, img=23, kb=(1.10, 1.24, 40, 0), scrim=True,
             lines=[("num", "01", 0.5), ("serif lg", "Dê nome ao padrão.", 1.0),
                    ("quote", "“Eu estou sabotando?”", 7.6), ("cap dim", "Nomear já cria distância.", 11.0)], pos="left"),
        dict(id="p2", dur=16.5, img=12, kb=(1.14, 1.26, 60, 0), scrim=True,
             lines=[("num", "02", 0.5), ("serif lg", "Faça duas perguntas.", 1.0),
                    ("quote", "“Quem eu decepciono se isso der certo?”", 3.6),
                    ("quote", "“O que eu perco se eu conseguir?”", 7.0),
                    ("cap dim", "Às vezes o preço do sucesso é invisível.", 10.6)], pos="left"),
        dict(id="p3", dur=9.0, img=24, kb=(1.03, 1.12, 0, 0), scrim=True,
             lines=[("num", "03", 0.5), ("serif lg", "Sucesso em doses pequenas.", 1.0),
                    ("cap dim", "Dê ao cérebro o novo aos poucos.", 4.6)], pos="left"),
        dict(id="p4", dur=11.0, img=25, kb=(1.12, 1.03, 0, 0), scrim=True,
             lines=[("num", "04", 0.5), ("serif lg", "Escreva a voz da culpa.", 1.0),
                    ("quote", "“Quem você pensa que é?”", 4.6), ("quote", "“Isso não vai durar.”", 6.4),
                    ("cap dim", "Escritas, elas perdem força.", 8.6)], pos="left"),
        dict(id="p5", dur=11.5, img=26, kb=(1.03, 1.12, 0, 0),
             lines=[("num", "05", 0.5), ("serif lg", "Procure um profissional.", 1.0),
                    ("cap dim", "Pedir ajuda não é fraqueza.", 8.4)], pos="low"),
    ],
    "fecho": [
        dict(id="email", dur=4.5, img=None, special="email2"),
        dict(id="pergunta", dur=13.5, img=21, kb=(1.20, 1.34, -80, 0), dimmer=0.62,
             lines=[("quote dim", "“O que há de errado comigo?”", 0.8),
                    ("serif lg", "O que esse sucesso significa<br>para a parte de mim<br>que eu ainda não conheço?", 4.6)], pos="center"),
        dict(id="coment", dur=7.5, img=None, special="glow",
             lines=[("serif lg", "Em que área da vida<br>isso acontece com você?", 0.8), ("cap dim", "Deixe nos comentários.", 3.6)], pos="center"),
        dict(id="proximo", dur=7.5, img=8, kb=(1.04, 1.14, 0, 0), dimmer=0.5,
             lines=[("kicker amb", "NO PRÓXIMO VÍDEO", 0.6),
                    ("serif lg", "Por que você repete<br>os mesmos relacionamentos", 1.2)], pos="center"),
        dict(id="final", dur=9.0, img=None, special="glow",
             lines=[("serif lg", "Inscreva-se no canal.", 0.8),
                    ("fine", "Este canal é educativo e não substitui acompanhamento psicológico ou médico.", 2.4)], pos="center"),
    ],
}

CSS = """
#root { position: absolute; inset: 0; background: #05060b; font-family: "Inter", sans-serif; color: #eef0f6; overflow: hidden; }
.shot { position: absolute; inset: 0; }
.in { position: absolute; inset: 0; }
.pic { position: absolute; left: 0; top: 0; width: 1920px; height: 1080px; }
.pic img { position: absolute; left: 0; top: 0; width: 1920px; height: 1080px; object-fit: cover; }
.shade { position: absolute; inset: 0; background: linear-gradient(180deg, rgba(5,6,11,0.25) 0%, rgba(5,6,11,0) 35%, rgba(5,6,11,0.82) 100%); }
.scrim { position: absolute; inset: 0; background: linear-gradient(90deg, rgba(5,6,11,0.88) 0%, rgba(5,6,11,0.6) 45%, rgba(5,6,11,0) 75%); }
.dimmer { position: absolute; inset: 0; background: #05060b; }
.txt { position: absolute; left: 192px; right: 192px; display: flex; flex-direction: column; gap: 22px; }
.txt.low { bottom: 150px; align-items: flex-start; text-align: left; }
.txt.center { top: 0; bottom: 0; justify-content: center; align-items: center; text-align: center; }
.txt.left { top: 0; bottom: 0; justify-content: center; align-items: flex-start; text-align: left; gap: 34px; }
.cap { font-size: 54px; font-weight: 700; line-height: 1.2; text-shadow: 0 2px 24px rgba(0,0,0,0.85); }
.dim { color: #b9b4d6; font-weight: 400; }
.serif { font-family: "Playfair Display", serif; font-weight: 700; line-height: 1.15; text-shadow: 0 2px 30px rgba(0,0,0,0.9); }
.lg { font-size: 76px; }
.xl { font-size: 132px; }
.title { font-size: 104px; }
.amb { color: #f5b453 !important; }
.gap { margin-top: 44px; }
.row { font-size: 64px; font-weight: 700; line-height: 1.2; text-shadow: 0 2px 24px rgba(0,0,0,0.85); }
.row i { font-style: normal; color: #b79bff; margin: 0 22px; }
.big { font-size: 96px; font-weight: 900; }
.num { font-size: 120px; font-weight: 900; color: #f5b453; line-height: 1; }
.quote { font-family: "Playfair Display", serif; font-style: italic; font-size: 60px; line-height: 1.25; color: #d9cffb; text-shadow: 0 2px 24px rgba(0,0,0,0.85); }
.fine { font-size: 34px; color: #a7a3c4; max-width: 1100px; line-height: 1.4; margin-top: 30px; }
.graph { position: absolute; left: 0; top: 0; width: 1920px; height: 1080px; }
.kicker { font-size: 30px; font-weight: 700; letter-spacing: 0.34em; color: #b79bff; }
.item { font-size: 64px; font-weight: 700; text-shadow: 0 2px 24px rgba(0,0,0,0.85); }
.item b { color: #f5b453; font-weight: 900; margin-right: 26px; }
.mail { position: absolute; left: 50%; top: 50%; width: 980px; margin-left: -490px; margin-top: -105px; height: 210px; border-radius: 34px;
  background: #14121f; border: 1px solid rgba(183,155,255,0.45); box-shadow: 0 0 120px rgba(140,100,255,0.55); display: flex; align-items: center; gap: 36px; padding: 0 48px; }
.mail-ic { width: 96px; height: 96px; border-radius: 26px; background: #7c5cff; display: flex; align-items: center; justify-content: center; flex: none; }
.mail-ic svg { width: 56px; height: 56px; }
.mail-a { font-size: 28px; color: #9d98bd; letter-spacing: 0.04em; }
.mail-b { font-size: 50px; font-weight: 700; margin-top: 10px; }
.glow { position: absolute; left: 50%; top: 50%; width: 1500px; height: 900px; margin-left: -750px; margin-top: -450px;
  background: radial-gradient(ellipse at center, rgba(124,92,255,0.42) 0%, rgba(124,92,255,0) 65%); }
"""

MAIL = """<div class="glow" id="{p}-glow" data-layout-ignore></div>
        <div class="mail" id="{p}-mail">
          <div class="mail-ic"><svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="M3.5 7.5 12 13l8.5-5.5"/></svg></div>
          <div><div class="mail-a">NOVO E-MAIL · agora</div><div class="mail-b">Parabéns, você foi aprovado.</div></div>
        </div>"""


def build_block(name, shots):
    html, js, t = [], [], 0.0
    for z, s in enumerate(shots, 1):
        p = f"{name}-{s['id']}"
        last = z == len(shots)
        win = s["dur"] + (0 if last else XF)
        inner = []
        if s.get("img"):
            inner.append(f'<div class="pic" id="{p}-pic" data-layout-ignore><img src="assets/img/{s["img"]:02d}.jpg" alt="" /></div>')
            inner.append('<div class="shade" data-layout-ignore></div>')
            a, b, dx, dy = s["kb"]
            sh = s.get("shift", 0)
            js.append(f'tl.fromTo("#{p}-pic", {{ scale: {a}, x: {sh}, y: 0 }}, {{ scale: {b}, x: {sh + dx}, y: {dy}, duration: {win:.2f}, ease: "none" }}, {t:.2f});')
        if s.get("scrim"):
            inner.append('<div class="scrim" data-layout-ignore></div>')
        if "dimmer" in s:
            inner.append(f'<div class="dimmer" id="{p}-dm" data-layout-ignore></div>')
            js.append(f'tl.fromTo("#{p}-dm", {{ opacity: 0.2 }}, {{ opacity: {s["dimmer"]}, duration: 1.4, ease: "power2.out" }}, {t:.2f});')
        sp = s.get("special")
        if sp == "glow":
            inner.append(f'<div class="glow" id="{p}-glow" data-layout-ignore></div>')
            js.append(f'tl.fromTo("#{p}-glow", {{ opacity: 0.35, scale: 0.8 }}, {{ opacity: 0.75, scale: 1.25, duration: {win:.2f}, ease: "sine.inOut" }}, {t:.2f});')
        if sp == "line":
            inner.append(f'''<div class="glow" id="{p}-glow" data-layout-ignore></div>
        <svg class="graph" id="{p}-g" viewBox="0 0 1920 1080" data-layout-ignore aria-hidden="true">
          <path id="{p}-up" d="M 260 760 L 560 690 L 860 590 L 1160 450 L 1460 250" fill="none" stroke="#b79bff" stroke-width="8" stroke-linecap="round" stroke-linejoin="round" stroke-dasharray="1330" stroke-dashoffset="1330"/>
          <path id="{p}-down" d="M 1460 250 L 1540 430 L 1500 560 L 1600 760" fill="none" stroke="#f5b453" stroke-width="8" stroke-linecap="round" stroke-linejoin="round" stroke-dasharray="560" stroke-dashoffset="560"/>
          <circle id="{p}-dot" cx="1460" cy="250" r="16" fill="#f5b453"/>
        </svg>''')
            js.append(f'tl.fromTo("#{p}-glow", {{ opacity: 0.3, scale: 0.9 }}, {{ opacity: 0.6, scale: 1.2, duration: {win:.2f}, ease: "sine.inOut" }}, {t:.2f});')
            js.append(f'tl.fromTo("#{p}-up", {{ strokeDashoffset: 1330 }}, {{ strokeDashoffset: 0, duration: 3.0, ease: "power1.in" }}, {t + 0.5:.2f});')
            js.append(f'tl.fromTo("#{p}-dot", {{ opacity: 0, scale: 0.2, transformOrigin: "50% 50%" }}, {{ opacity: 1, scale: 1.6, duration: 0.35, ease: "back.out(3)" }}, {t + 3.5:.2f});')
            js.append(f'tl.fromTo("#{p}-down", {{ strokeDashoffset: 560 }}, {{ strokeDashoffset: 0, duration: 0.9, ease: "power2.in" }}, {t + 3.8:.2f});')
            js.append(f'tl.to("#{p}-g", {{ opacity: 0.45, duration: 1.2 }}, {t + 5.0:.2f});')
        if sp in ("email", "email2", "dim"):
            inner.append(MAIL.format(p=p))
            if sp == "email2":
                js.append(f'tl.fromTo("#{p}-mail", {{ opacity: 0, scale: 0.9, y: 0 }}, {{ opacity: 1, scale: 1.06, y: 0, duration: 1.0, ease: "power2.out" }}, {t + 0.5:.2f});')
                js.append(f'tl.fromTo("#{p}-glow", {{ opacity: 0, scale: 0.6 }}, {{ opacity: 1, scale: 1.7, duration: {s["dur"] - 0.5:.2f}, ease: "power2.out" }}, {t + 0.5:.2f});')
            elif sp == "email":
                js.append(f'tl.fromTo("#{p}-mail", {{ opacity: 0, y: -70, scale: 0.94 }}, {{ opacity: 1, y: 0, scale: 1, duration: 0.7, ease: "back.out(1.4)" }}, {t + 1.3:.2f});')
                js.append(f'tl.fromTo("#{p}-glow", {{ opacity: 0, scale: 0.6 }}, {{ opacity: 1, scale: 1, duration: 1.6, ease: "power2.out" }}, {t + 1.3:.2f});')
                js.append(f'tl.to("#{p}-glow", {{ scale: 1.12, duration: {s["dur"] - 2.9:.2f}, ease: "sine.inOut" }}, {t + 2.9:.2f});')
            else:
                js.append(f'tl.fromTo("#{p}-mail", {{ opacity: 0.9, scale: 1, y: 0 }}, {{ opacity: 0.12, scale: 0.9, y: -250, duration: 2.6, ease: "power2.inOut" }}, {t:.2f});')
                js.append(f'tl.fromTo("#{p}-glow", {{ opacity: 0.8, scale: 1 }}, {{ opacity: 0, scale: 0.7, duration: 2.6, ease: "power2.inOut" }}, {t:.2f});')
        if s.get("lines"):
            rows = []
            for i, (cls, text, delay) in enumerate(s["lines"]):
                rows.append(f'<div class="{cls}" id="{p}-l{i}">{text}</div>')
                js.append(f'tl.fromTo("#{p}-l{i}", {{ opacity: 0, y: 34, filter: "blur(10px)" }}, {{ opacity: 1, y: 0, filter: "blur(0px)", duration: 0.8, ease: "power3.out" }}, {t + delay:.2f});')
            inner.append(f'<div class="txt {s.get("pos", "low")}" id="{p}-txt">' + "".join(rows) + "</div>")
            if not last:
                js.append(f'tl.to("#{p}-txt", {{ opacity: 0, duration: 0.45, ease: "power1.in" }}, {t + s["dur"] - 0.5:.2f});')
        # entrada: crossfade sobre o plano anterior; o último plano do bloco some no fim
        js.append(f'tl.fromTo("#{p}-in", {{ opacity: 0 }}, {{ opacity: 1, duration: {XF}, ease: "power1.inOut" }}, {t:.2f});')
        if last:
            js.append(f'tl.to("#{p}-in", {{ opacity: 0, duration: 0.6, ease: "power1.in" }}, {t + s["dur"] - 0.65:.2f});')
        body = "\n        ".join(inner)
        html.append(
            f'<div id="{p}" class="clip shot" style="z-index:{z}" data-start="{t:.2f}" data-duration="{win:.2f}" data-track-index="{z}">\n'
            f'      <div class="in" id="{p}-in">\n        {body}\n      </div>\n    </div>'
        )
        t += s["dur"]
    doc = (
        "<template>\n  <style>" + CSS.replace("#root", "#root") + "  </style>\n"
        f'  <div id="root" data-composition-id="{name}" data-width="1920" data-height="1080">\n    '
        + "\n    ".join(html)
        + "\n  </div>\n  <script>\n    const tl = gsap.timeline({ paused: true });\n    "
        + "\n    ".join(js)
        + f'\n    window.__timelines["{name}"] = tl;\n  </script>\n</template>\n'
    )
    (HERE / "compositions" / f"{name}.html").write_text(doc, encoding="utf-8")
    return t


def main(only=None):
    hosts, t, report = [], 0.0, []
    for i, (name, shots) in enumerate(BLOCKS.items(), 1):
        if only and name not in only:
            continue
        d = build_block(name, shots)
        hosts.append(
            f'<div id="{name}" data-composition-id="{name}" data-composition-src="compositions/{name}.html" data-track-kind="graphics" '
            f'data-start="{t:.2f}" data-duration="{d:.2f}" data-track-index="{i}" data-width="1920" data-height="1080"></div>'
        )
        report.append((name, t, d))
        t += d
    index = f"""<!doctype html>
<html lang="pt-BR">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=1920, height=1080" />
    <script src="https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/gsap.min.js"></script>
    <style>
      * {{ margin: 0; padding: 0; box-sizing: border-box; }}
      html, body {{ margin: 0; width: 1920px; height: 1080px; overflow: hidden; background: #05060b; }}
    </style>
  </head>
  <body>
    <div id="root" data-composition-id="main" data-start="0" data-duration="{t:.2f}" data-width="1920" data-height="1080">
      {chr(10).join('      ' + h for h in hosts).strip()}
    </div>
    <script>
      window.__timelines["main"] = gsap.timeline({{ paused: true }});
    </script>
  </body>
</html>
"""
    (HERE / "index.html").write_text(index, encoding="utf-8")
    print(json.dumps({"total_s": round(t, 2), "blocks": [(n, round(a, 2), round(d, 2)) for n, a, d in report]}))


if __name__ == "__main__":
    import sys
    main(set(sys.argv[1:]) or None)
