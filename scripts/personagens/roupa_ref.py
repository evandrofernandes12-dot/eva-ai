# Roupas a partir das referências do usuário, editando o herói pronto (mesmo esqueleto; animações continuam valendo).
#   M3: maga das runas (manto cinza-azulado com bordas vermelho-alaranjadas, capuz, peitoral de cobre, tabardo vermelho).
#   M1: mago azul-marinho e ouro (pelerine, pingente e fivela turquesa). M2: casaco cinza com runas ciano, colar de pedras.
#   A1: arqueiro verde ornamentado (capuz/capa verdes com borda verde-clara, couraça de couro com tiras cruzadas,
#       ombreiras e braçadeiras de aço, tabardo verde com faixa clara, joelheiras de aço).
# Uso: blender -b --python roupa_ref.py -- HEROI entrada.gltf pasta_saida
import bpy, bmesh, sys, math
from mathutils import Vector
args = sys.argv[sys.argv.index('--') + 1:]
HID, ENT, OUT = args[0], args[1], args[2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=ENT)
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
O = {o.name: o for o in bpy.data.objects if o.type == 'MESH'}
if 'Icosphere' in O: bpy.data.objects.remove(O.pop('Icosphere'))
P = lambda b: arm.matrix_world @ arm.data.bones[b].head_local
T = lambda b: arm.matrix_world @ arm.data.bones[b].tail_local

def mat(nome, cor, metal=0.0, rough=0.8, emit=None):
    m = bpy.data.materials.new(nome); m.use_backface_culling = False
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*cor, 1); b.inputs['Metallic'].default_value = metal; b.inputs['Roughness'].default_value = rough
    if emit:
        b.inputs['Emission Color'].default_value = (*emit, 1); b.inputs['Emission Strength'].default_value = 2.0
    return m
def troca(nome, m):
    if nome in O: o = O[nome]; o.data.materials.clear(); o.data.materials.append(m)
def remove(nome):
    if nome in O: bpy.data.objects.remove(O.pop(nome))
def fatia(src, nome, keep, off, m, toca=False):
    o = src.copy(); o.data = src.data.copy(); o.name = nome; bpy.context.collection.objects.link(o)
    bm = bmesh.new(); bm.from_mesh(o.data)
    if toca:
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if not any(keep(o.matrix_world @ v.co) for v in f.verts)], context='FACES')
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
    else:
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not keep(o.matrix_world @ v.co)], context='VERTS')
    bm.normal_update()
    for v in bm.verts: v.co += v.normal * off
    bm.to_mesh(o.data); bm.free(); o.data.materials.clear(); o.data.materials.append(m)
    return o
def borda(src, nome, off, m, filtro=None):
    """faixa nas bordas abertas da peça (capa, capuz, barra)"""
    o = src.copy(); o.data = src.data.copy(); o.name = nome; bpy.context.collection.objects.link(o)
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bd = {v for e in bm.edges if e.is_boundary for v in e.verts if filtro is None or filtro(o.matrix_world @ v.co)}
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if not any(v in bd for v in f.verts)], context='FACES')
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
    bm.normal_update()
    for v in bm.verts: v.co += v.normal * off
    bm.to_mesh(o.data); bm.free(); o.data.materials.clear(); o.data.materials.append(m)
    return o
def novo(nome, bm, m, pesos):
    """objeto novo preso ao esqueleto; pesos(p) -> {osso: peso}"""
    me = bpy.data.meshes.new(nome); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(nome, me); bpy.context.collection.objects.link(o); me.materials.append(m)
    o.parent = arm
    for v in me.vertices:
        for b, x in pesos(o.matrix_world @ v.co).items():
            if x > 0: (o.vertex_groups.get(b) or o.vertex_groups.new(name=b)).add([v.index], x, 'REPLACE')
    md = o.modifiers.new('Armature', 'ARMATURE'); md.object = arm
    return o
def capuz(m, ponta=0.06):
    c = (P('Head') + T('Head')) / 2 + Vector((0, 0.012, 0.02))
    bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=16, radius=0.14)
    for v in bm.verts:
        v.co.y *= 1.12; v.co.z *= 1.18
        if v.co.z > 0.05 and v.co.y > 0.0: v.co += Vector((0, ponta * v.co.z / 0.16, ponta * 0.6 * v.co.z / 0.16))
        v.co += c
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.calc_center_median().y < c.y - 0.06 and c.z - 0.12 < f.calc_center_median().z < c.z + 0.075], context='FACES')
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.calc_center_median().z < c.z - 0.13], context='FACES')
    return novo('Capuz', bm, m, lambda p: {'Head': 1.0} if p.z > P('neck_01').z + 0.03 else {'Head': 0.5, 'neck_01': 0.5})
def ombreira(lado, m, r=0.12):
    c = P('upperarm_' + lado) + Vector((0.04 * (1 if lado == 'l' else -1), 0, 0.035))
    bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=r)
    for v in bm.verts: v.co.z *= 0.6
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.calc_center_median().z < -0.015], context='FACES')
    for v in bm.verts: v.co += c
    return novo('Ombreira_' + lado, bm, m, lambda p: {'upperarm_' + lado: 0.6, 'clavicle_' + lado: 0.4})
def joelheira(lado, m):
    c = P('calf_' + lado) + Vector((0, -0.06, 0.0))
    bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=12, v_segments=8, radius=0.055)
    for v in bm.verts: v.co.y *= 0.55; v.co.z *= 1.15
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.calc_center_median().y > 0.0], context='FACES')
    for v in bm.verts: v.co += c
    return novo('Joelheira_' + lado, bm, m, lambda p: {'calf_' + lado: 1.0})
def frente_em(src, z):
    pts = [src.matrix_world @ v.co for v in src.data.vertices]
    pts = [p for p in pts if abs(p.z - z) < 0.03 and abs(p.x) < 0.05]
    return min(p.y for p in pts) if pts else None
def tabardo(nome, srcs, z0, z1, larg, m, off=0.012, pontas=1):
    """painel pendurado na frente, da cintura (z0) até z1, com ponta(s) embaixo; acompanha a frente das roupas"""
    bm = bmesh.new(); nx, nz = 6, 14; rows = []
    for i in range(nz + 1):
        t = i / nz; z = z0 + (z1 - z0) * t
        ys = [y for y in (frente_em(s, z) for s in srcs) if y is not None]
        y = (min(ys) if ys else -0.15) - off
        row = []
        for j in range(nx + 1):
            u = j / nx - 0.5
            dz = 0.0
            if i == nz: dz = -0.08 * (1 - abs(u) * 2) if pontas == 1 else -0.05 * abs(math.sin(u * math.pi * 2))
            row.append(bm.verts.new((u * larg, y, z + dz)))
        rows.append(row)
    for i in range(nz):
        for j in range(nx): bm.faces.new((rows[i][j], rows[i][j + 1], rows[i + 1][j + 1], rows[i + 1][j]))
    zc = P('calf_l').z
    def w(p):
        t = max(0.0, min(1.0, (z0 - p.z) / max(z0 - z1, 1e-3)))
        L = 0.5 * t
        return {'pelvis': 1 - L, 'thigh_l': L * 0.5, 'thigh_r': L * 0.5}
    return novo(nome, bm, m, w)
def broche(nome, pos, r, m, osso):
    bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=12, v_segments=8, radius=r)
    for v in bm.verts: v.co.y *= 0.5; v.co += pos
    return novo(nome, bm, m, lambda p: {osso: 1.0})

def anel(nome, src, z, h, filtro, osso, folga, m):
    pts = [src.matrix_world @ v.co for v in src.data.vertices]
    pts = [p for p in pts if abs(p.z - z) < 0.015 and filtro(p)]
    cx = (max(p.x for p in pts) + min(p.x for p in pts)) / 2; rx = (max(p.x for p in pts) - min(p.x for p in pts)) / 2 + folga
    cy = (max(p.y for p in pts) + min(p.y for p in pts)) / 2; ry = (max(p.y for p in pts) - min(p.y for p in pts)) / 2 + folga
    bm = bmesh.new(); seg = 28; rr = []
    for dz in (-h / 2, h / 2):
        rr.append([bm.verts.new((cx + math.cos(2 * math.pi * j / seg) * rx, cy + math.sin(2 * math.pi * j / seg) * ry, z + dz)) for j in range(seg)])
    for j in range(seg): bm.faces.new((rr[0][j], rr[0][(j + 1) % seg], rr[1][(j + 1) % seg], rr[1][j]))
    return novo(nome, bm, m, lambda p: {osso: 1.0})

z_pel = P('pelvis').z; z_sp1 = P('spine_01').z; z_sp3 = P('spine_03').z
if HID == 'M3':
    ARD = mat('ardosia', (0.03, 0.035, 0.05), 0, 0.9)
    RUBRO = mat('runa_vermelha', (0.4, 0.045, 0.01), 0, 0.6, emit=(0.08, 0.012, 0.0))
    COBRE = mat('cobre', (0.42, 0.17, 0.06), 0.85, 0.35)
    COURO = mat('couro_bota', (0.07, 0.035, 0.018), 0.05, 0.5)
    LARANJA = mat('brilho_runa', (1.0, 0.45, 0.08), 0, 0.3, emit=(1.0, 0.4, 0.05))
    troca('Tunica', ARD); troca('Saia', ARD); troca('Capa', ARD); troca('Barra', RUBRO)
    troca('Cinto', RUBRO); troca('Braceletes', COBRE); troca('Botas', COURO)
    tun = O['Tunica']
    fatia(tun, 'Peitoral', lambda p: z_sp1 - 0.02 < p.z < z_sp3 + 0.1 and abs(p.x) < 0.17 and p.y < 0.02, 0.02, COBRE)
    yf = frente_em(tun, z_sp3 + 0.12) or -0.13
    broche('Broche', Vector((0, yf - 0.03, z_sp3 + 0.12)), 0.03, LARANJA, 'spine_03')
    borda(O['Capa'], 'Capa_Borda', 0.006, RUBRO)
    fatia(O['Saia'], 'Saia_Faixa', lambda p: 0.2 < p.z < 0.26, 0.008, RUBRO, True)
    cz = capuz(ARD); borda(cz, 'Capuz_Borda', 0.004, RUBRO)
    tabardo('Tabardo', [O['Saia']], z_pel + 0.04, P('calf_l').z - 0.12, 0.26, RUBRO, 0.015, pontas=2)
    tabardo('Tabardo_Runa', [O['Saia']], z_pel - 0.12, z_pel - 0.3, 0.08, LARANJA, 0.024, pontas=1)
elif HID == 'A1':
    VERDE = mat('verde_capa', (0.03, 0.09, 0.02), 0, 0.9)
    VERDE_ESC = mat('verde_calca', (0.022, 0.05, 0.016), 0, 0.9)
    CLARO = mat('ornamento_verde', (0.22, 0.42, 0.12), 0.1, 0.6)
    COURO = mat('couro_couraca', (0.09, 0.045, 0.02), 0.1, 0.5)
    TIRA = mat('couro_tiras', (0.05, 0.026, 0.012), 0.1, 0.55)
    ACO = mat('aco', (0.5, 0.52, 0.55), 0.9, 0.3)
    troca('Capuz', VERDE); troca('Capa', VERDE); troca('Tunica', VERDE_ESC); troca('Calca', VERDE_ESC)
    troca('Saiote', COURO); troca('Botas', COURO); troca('Braceletes', ACO); troca('Cinto', TIRA)
    tun = O['Tunica']
    fatia(tun, 'Couraca', lambda p: z_pel + 0.02 < p.z < z_sp3 + 0.13 and abs(p.x) < 0.19, 0.016, COURO)
    for s in (1, -1):   # tiras cruzadas no peito e nas costas
        fatia(tun, 'Tira_X', lambda p, s=s: z_sp1 < p.z < z_sp3 + 0.15 and abs(p.x - s * (p.z - (z_sp1 + z_sp3) / 2 - 0.05) * 0.9) < 0.018, 0.024, TIRA, True)
    borda(O['Capa'], 'Capa_Borda', 0.006, CLARO)
    borda(O['Capuz'], 'Capuz_Borda', 0.004, CLARO)
    for lado in ('l', 'r'):
        ombreira(lado, ACO); joelheira(lado, ACO)
    tabardo('Tabardo', [O['Saiote'], O['Calca']], z_pel + 0.04, P('calf_l').z + 0.08, 0.22, VERDE, 0.014, pontas=1)
    tabardo('Tabardo_Faixa', [O['Saiote'], O['Calca']], z_pel + 0.0, P('calf_l').z + 0.12, 0.08, CLARO, 0.022, pontas=1)
elif HID == 'M1':   # mago azul-marinho e ouro com pedras turquesa
    MARINHO = mat('marinho', (0.012, 0.02, 0.06), 0, 0.85)
    OURO = mat('ouro', (0.6, 0.42, 0.13), 0.9, 0.3)
    TURQ = mat('turquesa', (0.05, 0.6, 0.65), 0.2, 0.15, emit=(0.02, 0.35, 0.4))
    TEAL = mat('azul_turquesa', (0.015, 0.09, 0.12), 0, 0.7)
    for n in ('Tunica', 'Saia', 'Capa', 'Capuz'): troca(n, MARINHO)
    troca('Barra', OURO); troca('Cinto', OURO); troca('Braceletes', OURO)
    borda(O['Capa'], 'Capa_Borda', 0.006, OURO); borda(O['Capuz'], 'Capuz_Borda', 0.004, OURO)
    tun = O['Tunica']
    manto = fatia(tun, 'Pelerine', lambda p: p.z > z_sp3 + 0.07 and abs(p.x) < 0.32, 0.035, MARINHO)
    borda(manto, 'Pelerine_Borda', 0.006, OURO)
    for xs in (-0.12, 0.12):
        fatia(O['Saia'], 'Saia_Friso', lambda p, xs=xs: abs(p.x - xs) < 0.012 and p.y < -0.05, 0.01, OURO, True)
    yf = frente_em(tun, z_sp3 + 0.02) or -0.13
    broche('Pingente', Vector((0, yf - 0.025, z_sp3 + 0.02)), 0.026, TURQ, 'spine_03')
    anel('Corrente', tun, P('neck_01').z - 0.01, 0.012, lambda p: True, 'spine_03', 0.012, OURO)
    yc = frente_em(O['Cinto'], z_pel + 0.075) or -0.16
    broche('Fivela', Vector((0, yc - 0.015, z_pel + 0.075)), 0.03, TURQ, 'pelvis')
    tabardo('Tabardo', [O['Saia']], z_pel + 0.03, P('calf_l').z - 0.2, 0.22, TEAL, 0.014, pontas=1)
    tabardo('Tabardo_Ouro', [O['Saia']], z_pel - 0.05, P('calf_l').z - 0.1, 0.05, OURO, 0.02, pontas=1)
elif HID == 'M2':   # mago das runas de gelo: casaco cinza com runas ciano brilhantes
    CINZA = mat('cinza_casaco', (0.11, 0.115, 0.125), 0, 0.85)
    ESCURO = mat('azul_noite', (0.015, 0.02, 0.04), 0, 0.85)
    CIANO = mat('runa_ciano', (0.1, 0.65, 1.0), 0, 0.3, emit=(0.08, 0.55, 1.0))
    COURO = mat('couro_cinto', (0.08, 0.045, 0.022), 0.1, 0.5)
    PEDRA = mat('pedra_runa', (0.6, 0.6, 0.58), 0, 0.7)
    LUVA = mat('luva', (0.02, 0.022, 0.03), 0, 0.6)
    for n in ('Capa', 'Capuz', 'Saia', 'Ombreira_l', 'Ombreira_r'): troca(n, CINZA)
    troca('Tunica', ESCURO); troca('Barra', CIANO); troca('Cinto', COURO)
    borda(O['Capa'], 'Capa_Borda', 0.006, CIANO); borda(O['Capuz'], 'Capuz_Borda', 0.004, CIANO)
    tun = O['Tunica']
    yf = frente_em(tun, z_sp3) or -0.13
    fatia(tun, 'Runa_Peito', lambda p: z_sp1 + 0.05 < p.z < z_sp3 + 0.08 and abs(p.x) < 0.006 and p.y < yf + 0.05, 0.014, CIANO, True)
    for dz in (0.0, 0.06):
        fatia(tun, 'Runa_Peito_H', lambda p, dz=dz: abs(p.z - (z_sp3 - 0.03 + dz)) < 0.006 and abs(p.x) < 0.05 and p.y < yf + 0.05, 0.014, CIANO, True)
    for xs in (-0.14, 0.14):   # faixas de runas na frente do casaco
        fatia(O['Saia'], 'Saia_Runas', lambda p, xs=xs: abs(p.x - xs) < 0.01 and p.y < -0.05, 0.01, CIANO, True)
    for k in range(9):   # colar de pedras com runas
        a = math.pi * (0.15 + 0.7 * k / 8)
        c = Vector((math.cos(a) * 0.1, -0.02 - math.sin(a) * 0.1, P('neck_01').z - 0.05 - 0.04 * math.sin(a)))
        broche('Pedra_%d' % k, c, 0.018, PEDRA, 'spine_03')
    body = O.get('SuperHero_Male')
    if body:
        fatia(body, 'Luvas', lambda p: abs(p.x) > 0.6, 0.004, LUVA)
    tabardo('Tabardo', [O['Saia']], z_pel + 0.03, P('calf_l').z - 0.15, 0.22, CINZA, 0.014, pontas=1)
    tabardo('Tabardo_Runa', [O['Saia']], z_pel - 0.1, P('calf_l').z - 0.05, 0.035, CIANO, 0.02, pontas=1)
for o in bpy.data.objects:
    o.select_set(o.type in ('MESH', 'ARMATURE'))
bpy.ops.export_scene.gltf(filepath=OUT + '/' + HID + '.gltf', export_format='GLTF_SEPARATE', export_texture_dir='tex', use_selection=True,
                          export_skins=True, export_animations=False, export_yup=True)
print('OK', HID, sorted(o.name for o in bpy.data.objects if o.type == 'MESH'))
