"""Remodela a malha "Capa" dos heróis (glTF + .bin) direto nos bytes: pano fino, curvado nas costas,
mais largo embaixo, afastado das pernas e com dobras. Mantém pesos/ossos. Uso: python3 capa.py pasta_herois [origem]"""
import json, sys, glob, os, numpy as np
CT = {5126: np.float32, 5123: np.uint16, 5121: np.uint8, 5125: np.uint32}
NC = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}
def vista(j, i):
    a = j['accessors'][i]; v = j['bufferViews'][a['bufferView']]
    return a, v.get('byteOffset', 0) + a.get('byteOffset', 0), CT[a['componentType']], NC[a['type']]
pasta = sys.argv[1]; origem = sys.argv[2] if len(sys.argv) > 2 else pasta
for f in sorted(glob.glob(os.path.join(pasta, '*.gltf'))):
    nome = os.path.basename(f)
    j = json.load(open(os.path.join(origem, nome)))
    ms = [m for m in j['meshes'] if m['name'] == 'Capa']
    if not ms: continue
    binf = j['buffers'][0]['uri']
    b = bytearray(open(os.path.join(origem, binf), 'rb').read())
    p = ms[0]['primitives'][0]
    ap, op, dt, n = vista(j, p['attributes']['POSITION'])
    P = np.frombuffer(b, dt, ap['count'] * 3, op).reshape(-1, 3).astype(np.float64)
    ai, oi, dti, _ = vista(j, p['indices'])
    I = np.frombuffer(b, dti, ai['count'], oi).reshape(-1, 3).astype(np.int64)
    x, y, z = P[:, 0], P[:, 1], P[:, 2]
    ytop, ybot, hw = y.max(), y.min(), np.abs(x).max()
    zc = (z.max() + z.min()) / 2
    t = (ytop - y) / (ytop - ybot)            # 0 nos ombros, 1 na barra
    u = x / hw
    xn = x * (0.80 + 0.55 * t)                # estreita nos ombros, abre embaixo
    zn = (zc + 0.015) + (z - zc) * 0.22       # pano fino (era uma tábua de 9 cm)
    zn -= 0.11 * t ** 1.4                      # cai afastada das pernas
    zn += 0.09 * u ** 2 * (1.0 - 0.6 * t)      # abraça as costas/ombros
    zn += 0.028 * np.sin(u * np.pi * 3.5) * (0.2 + t)   # dobras verticais
    yn = y + 0.03 * u ** 2 * (1 - t)           # borda sobe um pouco nos ombros
    Q = np.stack([xn, yn, zn], 1)
    # folga: cada ponto fica atrás da roupa/corpo naquela altura (o manto do mago aparecia através da capa)
    corpo = []
    for me in j['meshes']:
        if me['name'] in ('Capa', 'Capuz'): continue
        for pr in me['primitives']:
            a2, o2, d2, _ = vista(j, pr['attributes']['POSITION'])
            corpo.append(np.frombuffer(b, d2, a2['count'] * 3, o2).reshape(-1, 3))
    C = np.concatenate(corpo).astype(np.float64)
    C = C[C[:, 2] < 0.05]
    empurra = np.zeros(len(Q))
    for k in range(len(Q)):
        perto = C[(np.abs(C[:, 1] - Q[k, 1]) < 0.06) & (np.abs(C[:, 0] - Q[k, 0]) < 0.10)]
        if len(perto):
            folga = 0.035 + 0.09 * t[k]
            empurra[k] = max(0.0, Q[k, 2] - (perto[:, 2].min() - folga))
    viz = np.linalg.norm(Q[:, None, :2] - Q[None, :, :2], axis=2) < 0.07
    empurra = np.array([empurra[viz[k]].max() for k in range(len(Q))])   # as duas faces do pano andam juntas
    Q[:, 2] -= empurra
    N = np.zeros_like(Q)
    fn = np.cross(Q[I[:, 1]] - Q[I[:, 0]], Q[I[:, 2]] - Q[I[:, 0]])
    for k in range(3): np.add.at(N, I[:, k], fn)
    N /= np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-9)
    an, on, _, _ = vista(j, p['attributes']['NORMAL'])
    b[op:op + Q.size * 4] = Q.astype(np.float32).tobytes()
    b[on:on + N.size * 4] = N.astype(np.float32).tobytes()
    ap['min'] = Q.min(0).tolist(); ap['max'] = Q.max(0).tolist()
    open(os.path.join(pasta, binf), 'wb').write(b)
    json.dump(j, open(f, 'w'))
    print(nome, 'ok', Q.min(0).round(3), Q.max(0).round(3))
