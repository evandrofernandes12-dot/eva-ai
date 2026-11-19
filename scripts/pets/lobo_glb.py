"""Lobo: edita o .glb original do Sketchfab SEM reexportar pelo Blender (a reexportação quebrava as animações de
andar/sentar). Troca só as texturas de cor (pelo marrom -> cinza) e tira a placa de chão da cena.
Uso: python3 -I lobo_glb.py <wolf_with_animations.glb> <saida/lobo.glb>
"""
import json, struct, sys, io
import numpy as np
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
d = open(src, 'rb').read()
jl = struct.unpack('<I', d[12:16])[0]
j = json.loads(d[20:20 + jl])
bin0 = 20 + jl
bl = struct.unpack('<I', d[bin0:bin0 + 4])[0]
binc = d[bin0 + 8:bin0 + 8 + bl]

# imagens de cor base dos materiais de pelo (olhos, dentes e unhas ficam como estão)
alvos = set()
for m in j['materials']:
    if m.get('name', '').startswith(('fur', 'Material__wolf')):
        t = m.get('pbrMetallicRoughness', {}).get('baseColorTexture') or \
            m.get('extensions', {}).get('KHR_materials_pbrSpecularGlossiness', {}).get('diffuseTexture')
        if t is not None:
            alvos.add(j['textures'][t['index']]['source'])
print('imagens recoloridas:', sorted(alvos))

def cinza(raw):
    im = Image.open(io.BytesIO(raw)).convert('RGBA')
    a = np.asarray(im).astype(np.float32) / 255.0
    L = 0.3 * a[..., 0] + 0.59 * a[..., 1] + 0.11 * a[..., 2]
    g = np.clip(0.2 + L * 1.7, 0, 0.92)
    a[..., 0] = g; a[..., 1] = g; a[..., 2] = np.clip(g * 1.04, 0, 1)
    out = io.BytesIO()
    Image.fromarray((a * 255).astype(np.uint8), 'RGBA').save(out, 'PNG')
    return out.getvalue()

# remonta o buffer binário, bufferView por bufferView
novos = []
for i, bv in enumerate(j['bufferViews']):
    s = bv.get('byteOffset', 0)
    novos.append(binc[s:s + bv['byteLength']])
for idx in alvos:
    img = j['images'][idx]
    novos[img['bufferView']] = cinza(novos[img['bufferView']])
    img['mimeType'] = 'image/png'
buf = bytearray()
for i, b in enumerate(novos):
    while len(buf) % 4:
        buf += b'\0'
    j['bufferViews'][i]['byteOffset'] = len(buf)
    j['bufferViews'][i]['byteLength'] = len(b)
    buf += b
while len(buf) % 4:
    buf += b'\0'
j['buffers'][0]['byteLength'] = len(buf)

# tira a placa de chão (nó de malha "Plane...") de onde estiver pendurada
planos = {i for i, n in enumerate(j['nodes']) if n.get('name', '').startswith('Plane')}
for n in j['nodes']:
    if 'children' in n:
        n['children'] = [c for c in n['children'] if c not in planos]
for sc in j['scenes']:
    sc['nodes'] = [c for c in sc['nodes'] if c not in planos]
print('placas removidas:', [j['nodes'][i]['name'] for i in planos])

js = json.dumps(j, separators=(',', ':')).encode()
while len(js) % 4:
    js += b' '
total = 12 + 8 + len(js) + 8 + len(buf)
with open(dst, 'wb') as f:
    f.write(struct.pack('<III', 0x46546C67, 2, total))
    f.write(struct.pack('<II', len(js), 0x4E4F534A)); f.write(js)
    f.write(struct.pack('<II', len(buf), 0x004E4942)); f.write(buf)
print('ok', dst, total)
