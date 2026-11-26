#!/usr/bin/env python3
"""Junta o pacote do dia em um ZIP para o usuário baixar de uma vez e extrair no tablet.
Uso: python3 carrossel/empacotar.py <pasta-do-dia> <saida.zip>
A pasta do dia tem: carrossel-png/slide-NN.png, reel.mp4 (opcional), story-manha.mp4, story-noite.mp4,
legenda-carrossel.txt e legenda-reel.txt (opcional)."""
import os, sys, zipfile

if len(sys.argv) != 3:
    sys.exit(__doc__)
dia, saida = os.path.abspath(sys.argv[1]), sys.argv[2]
nome = "Instagram-" + os.path.basename(dia).replace("dia-", "")
itens = []
slides = os.path.join(dia, "carrossel-png")
if os.path.isdir(slides):
    for f in sorted(os.listdir(slides)):
        if f.endswith(".png"):
            itens.append((os.path.join(slides, f), f"1-carrossel/{f}"))
for src, dst in [("reel.mp4", "2-reel/reel.mp4"), ("story-manha.mp4", "3-story-manha.mp4"),
                 ("story-noite.mp4", "4-story-noite.mp4"), ("legenda-carrossel.txt", "legenda-carrossel.txt"),
                 ("legenda-reel.txt", "legenda-reel.txt")]:
    p = os.path.join(dia, src)
    if os.path.exists(p):
        itens.append((p, dst))
with zipfile.ZipFile(saida, "w", zipfile.ZIP_STORED) as z:  # sem compressão: PNG e MP4 já são comprimidos
    for src, dst in itens:
        z.write(src, f"{nome}/{dst}")
print(f"ok: {saida} ({len(itens)} arquivos, {os.path.getsize(saida)/1e6:.1f} MB)")
