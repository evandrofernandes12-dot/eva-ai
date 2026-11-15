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
            js.append(f'tl.fromTo("#{p}-pic", {{ scale: {a}, x: 0, y: 0 }}, {{ scale: {b}, x: {dx}, y: {dy}, duration: {win:.2f}, ease: "none" }}, {t:.2f});')
        if s.get("scrim"):
            inner.append('<div class="scrim" data-layout-ignore></div>')
        if "dimmer" in s:
            inner.append(f'<div class="dimmer" id="{p}-dm" data-layout-ignore></div>')
            js.append(f'tl.fromTo("#{p}-dm", {{ opacity: 0.2 }}, {{ opacity: {s["dimmer"]}, duration: 1.4, ease: "power2.out" }}, {t:.2f});')
        sp = s.get("special")
        if sp in ("email", "dim"):
            inner.append(MAIL.format(p=p))
            if sp == "email":
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
