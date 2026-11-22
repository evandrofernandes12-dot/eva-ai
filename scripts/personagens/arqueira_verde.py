# Roupa da arqueira A4 a partir da referência do usuário (verde-oliva + couro marrom + dourado):
# túnica de malha verde, corpete de couro com friso dourado e esmeralda, braçadeiras douradas,
# saia longa aberta na frente com pontas, legging marrom com tiras douradas, botas de couro, capuz com borda dourada.
# Uso: blender -b --python arqueira_verde.py -- entrada.gltf pasta_saida
import bpy, bmesh, sys, math
from mathutils import Vector
args = sys.argv[sys.argv.index('--') + 1:]
ENT, OUT = args[0], args[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=ENT)
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
O = {o.name: o for o in bpy.data.objects if o.type == 'MESH'}
for n in ('Icosphere',):
    if n in O: bpy.data.objects.remove(O.pop(n))
P = lambda b: arm.matrix_world @ arm.data.bones[b].head_local

def mat(nome, cor, metal=0.0, rough=0.8):
    m = bpy.data.materials.new(nome); m.use_backface_culling = False
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*cor, 1); b.inputs['Metallic'].default_value = metal; b.inputs['Roughness'].default_value = rough
    return m
VERDE = mat('verde_malha', (0.055, 0.085, 0.022), 0, 0.95)
VERDE_SAIA = mat('verde_la', (0.05, 0.075, 0.02), 0, 0.95)
COURO = mat('couro_corpete', (0.075, 0.042, 0.02), 0.1, 0.5)
COURO_BOTA = mat('couro_bota', (0.06, 0.034, 0.016), 0.05, 0.45)
LEGGING = mat('legging', (0.028, 0.018, 0.012), 0, 0.9)
OURO = mat('dourado', (0.55, 0.38, 0.12), 0.85, 0.35)
ESMERALDA = mat('esmeralda', (0.02, 0.35, 0.08), 0.3, 0.15)

def troca(nome, m):
    o = O[nome]; o.data.materials.clear(); o.data.materials.append(m)
troca('Tunica', VERDE); troca('Calca', LEGGING); troca('Botas', COURO_BOTA)
troca('Capuz', VERDE); troca('Braceletes', OURO); troca('Cinto', COURO)
for n in ('Capa', 'Saiote'):   # a referência não tem capa; o saiote vira a saia longa
    bpy.data.objects.remove(O.pop(n))

def copia_pesos(dst, src):
    """pesos do mais próximo em `src` (mesmo esqueleto)"""
    dst.parent = arm
    md = dst.modifiers.new('Armature', 'ARMATURE'); md.object = arm
    dt = dst.modifiers.new('DT', 'DATA_TRANSFER'); dt.object = src
    dt.use_vert_data = True; dt.data_types_verts = {'VGROUP_WEIGHTS'}
    dt.vert_mapping = 'POLYINTERP_NEAREST'; dt.layers_vgroup_select_src = 'ALL'; dt.layers_vgroup_select_dst = 'NAME'
    bpy.context.view_layer.objects.active = dst
    for o in bpy.context.selected_objects: o.select_set(False)
    dst.select_set(True)
    bpy.ops.object.datalayout_transfer(modifier='DT')
    bpy.ops.object.modifier_apply(modifier='DT')
    bpy.ops.object.modifier_move_to_index(modifier='Armature', index=0)

def fatia(src, nome, keep, off, m, toca=False):
    """casca: cópia dos vértices de `src` que passam em keep(p), empurrada pela normal.
    toca=True: mantém as faces que têm pelo menos um vértice na faixa (faixas finas: frisos, tiras)"""
    o = src.copy(); o.data = src.data.copy(); o.name = nome; bpy.context.collection.objects.link(o)
    bm = bmesh.new(); bm.from_mesh(o.data)
    if toca:
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if not any(keep(o.matrix_world @ v.co) for v in f.verts)], context='FACES')
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
    else:
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not keep(o.matrix_world @ v.co)], context='VERTS')
    bm.normal_update()
    for v in bm.verts: v.co += v.normal * off
    bm.to_mesh(o.data); bm.free()
    o.data.materials.clear(); o.data.materials.append(m)
    return o

def anel(nome, src, z, h, filtro, osso, folga, m, eixo='z'):
    """anel liso (elipse) em volta da seção de `src` na altura z (ou em x, para o braço), preso a um osso"""
    k = 2 if eixo == 'z' else 0
    pts = [src.matrix_world @ v.co for v in src.data.vertices]
    pts = [p for p in pts if abs(p[k] - z) < 0.015 and filtro(p)]
    a1, a2 = (0, 1) if eixo == 'z' else (1, 2)
    c1 = (max(p[a1] for p in pts) + min(p[a1] for p in pts)) / 2; r1 = (max(p[a1] for p in pts) - min(p[a1] for p in pts)) / 2 + folga
    c2 = (max(p[a2] for p in pts) + min(p[a2] for p in pts)) / 2; r2 = (max(p[a2] for p in pts) - min(p[a2] for p in pts)) / 2 + folga
    bm = bmesh.new(); seg = 28; rr = []
    for dz in (-h / 2, h / 2):
        ring = []
        for j in range(seg):
            a = 2 * math.pi * j / seg; co = [0.0, 0.0, 0.0]
            co[a1] = c1 + math.cos(a) * r1; co[a2] = c2 + math.sin(a) * r2; co[k] = z + dz
            ring.append(bm.verts.new(co))
        rr.append(ring)
    for j in range(seg): bm.faces.new((rr[0][j], rr[0][(j + 1) % seg], rr[1][(j + 1) % seg], rr[1][j]))
    me = bpy.data.meshes.new(nome); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(nome, me); bpy.context.collection.objects.link(o); me.materials.append(m)
    o.parent = arm; g = o.vertex_groups.new(name=osso); g.add(list(range(len(me.vertices))), 1.0, 'REPLACE')
    md = o.modifiers.new('Armature', 'ARMATURE'); md.object = arm
    return o

z_pel = P('pelvis').z; z_sp3 = P('spine_03').z
tun = O['Tunica']
# corpete: da cintura até logo abaixo do busto, mais justo e por cima da túnica
z0c, z1c = z_pel + 0.03, z_sp3 + 0.02
torso = lambda p: abs(p.x) < 0.2
fatia(tun, 'Corpete', lambda p: z0c < p.z < z1c and torso(p), 0.012, COURO)
anel('Corpete_Friso_Baixo', tun, z0c + 0.008, 0.016, torso, 'spine_01', 0.016, OURO)
anel('Corpete_Friso_Alto', tun, z1c - 0.008, 0.016, torso, 'spine_03', 0.016, OURO)
# braçadeiras douradas no meio do braço (braço em T, ao longo de X)
for lado, s in (('l', 1), ('r', -1)):
    xa = (P('upperarm_' + lado).x + P('lowerarm_' + lado).x) / 2
    fatia(tun, 'Bracadeira_' + lado, lambda p, xa=xa, s=s: abs(p.x - xa) < 0.025 and p.x * s > 0, 0.012, OURO)
# tiras douradas nas pernas (coxa x2, joelho, canela)
leg = O['Calca']
for k, z in enumerate((z_pel - 0.27, P('calf_l').z + 0.03, P('calf_l').z - 0.16)):
    for lado, sg in (('l', 1), ('r', -1)):
        osso = ('thigh_' if z > P('calf_l').z + 0.06 else 'calf_') + lado
        anel('Tira_%d_%s' % (k, lado), leg, z, 0.022, lambda p, sg=sg: p.x * sg > 0.01, osso, 0.008, OURO)
# borda dourada do capuz: faces que encostam na borda aberta (rosto e base)
cap = O['Capuz']
o = cap.copy(); o.data = cap.data.copy(); o.name = 'Capuz_Borda'; bpy.context.collection.objects.link(o)
bm = bmesh.new(); bm.from_mesh(o.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)   # a malha vem com vértices soltos
borda = {v for e in bm.edges if e.is_boundary for v in e.verts}
bmesh.ops.delete(bm, geom=[f for f in bm.faces if not any(v in borda for v in f.verts)], context='FACES')
bm.normal_update()
for v in bm.verts: v.co += v.normal * 0.004
bm.to_mesh(o.data); bm.free(); o.data.materials.clear(); o.data.materials.append(OURO)
# esmeralda no peito
bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=10, v_segments=6, radius=0.014)
for v in bm.verts: v.co.y *= 0.5; v.co += Vector((0, -0.135, z1c + 0.01))
ys = [ (tun.matrix_world @ v.co) for v in tun.data.vertices if abs((tun.matrix_world @ v.co).z - (z1c + 0.01)) < 0.02 and abs((tun.matrix_world @ v.co).x) < 0.03]
yf = min(p.y for p in ys) - 0.02 if ys else -0.14
for v in bm.verts: v.co.y += yf + 0.135
me = bpy.data.meshes.new('Esmeralda'); bm.to_mesh(me); bm.free()
gem = bpy.data.objects.new('Esmeralda', me); bpy.context.collection.objects.link(gem); me.materials.append(ESMERALDA)
# saia longa: aberta na frente (-Y), pontas nos lados e uma ponta longa atrás
rx, ry = 0.0, 0.0
cs = [tun.matrix_world @ v.co for v in tun.data.vertices if abs((tun.matrix_world @ v.co).z - (z_pel + 0.06)) < 0.02]
rx = (max(p.x for p in cs) - min(p.x for p in cs)) / 2 + 0.02
ry = (max(p.y for p in cs) - min(p.y for p in cs)) / 2 + 0.025
cy = (max(p.y for p in cs) + min(p.y for p in cs)) / 2
z0 = z_pel + 0.06
bm = bmesh.new(); seg, an = 36, 18
abre = math.radians(50)   # meia-abertura na frente
angs = [(-math.pi / 2 + abre) + (2 * math.pi - 2 * abre) * j / seg for j in range(seg + 1)]
def comprimento(a):
    t = (a - (-math.pi / 2 + abre)) / (2 * math.pi - 2 * abre)        # 0..1 de um lado da abertura ao outro
    base = 0.35 + 0.45 * math.sin(math.pi * t)                          # mais longa atrás
    pontas = 0.12 * abs(math.sin(3 * math.pi * t))                       # bicos da barra
    return base + pontas
rings = []
for i in range(an + 1):
    t = i / an
    ring = []
    for a in angs:
        L = comprimento(a); z = z0 - L * t * (z0 - 0.15) / 0.92
        k = 1.0 + 0.55 * t
        ring.append(bm.verts.new((math.cos(a) * rx * k, cy + math.sin(a) * ry * k, z)))
    rings.append(ring)
for i in range(an):
    for j in range(seg):
        bm.faces.new((rings[i][j], rings[i][j + 1], rings[i + 1][j + 1], rings[i + 1][j]))
me = bpy.data.meshes.new('Saia'); bm.to_mesh(me); bm.free()
saia = bpy.data.objects.new('Saia', me); bpy.context.collection.objects.link(saia); me.materials.append(VERDE_SAIA)
# pesos da saia: pelve em cima, coxa/canela do lado embaixo (como em build.py)
saia.parent = arm
for b in ('pelvis', 'thigh_l', 'thigh_r', 'calf_l', 'calf_r'): saia.vertex_groups.new(name=b)
zc = P('calf_l').z
for v in me.vertices:
    p = saia.matrix_world @ v.co
    t = max(0.0, min(1.0, (z0 - p.z) / (z0 - 0.15)))
    side = max(-1.0, min(1.0, p.x / (rx * (1 + 0.55 * t) + 1e-4)))
    L = 0.8 * t * min(1.0, abs(side) * 1.3)
    s = 'l' if side > 0 else 'r'
    kj = 0.0 if p.z > zc else min(1.0, (zc - p.z) / 0.3) * 0.5
    saia.vertex_groups['pelvis'].add([v.index], 1 - L, 'REPLACE')
    saia.vertex_groups['thigh_' + s].add([v.index], L * (1 - kj), 'REPLACE')
    saia.vertex_groups['calf_' + s].add([v.index], L * kj, 'REPLACE')
md = saia.modifiers.new('Armature', 'ARMATURE'); md.object = arm
# esmeralda presa ao peito
gem.parent = arm; g = gem.vertex_groups.new(name='spine_03'); g.add([v.index for v in me.vertices] if False else list(range(len(gem.data.vertices))), 1.0, 'REPLACE')
md = gem.modifiers.new('Armature', 'ARMATURE'); md.object = arm
for o in bpy.data.objects:
    o.select_set(o.type in ('MESH', 'ARMATURE'))
bpy.ops.export_scene.gltf(filepath=OUT + '/A4.gltf', export_format='GLTF_SEPARATE', export_texture_dir='tex', use_selection=True,
                          export_skins=True, export_animations=False, export_yup=True)
print('OK A4', sorted(o.name for o in bpy.data.objects if o.type == 'MESH'))
