# Coroa de galhos dourada com rubi (referência do usuário). Coordenadas do osso da cabeça (glTF: Y cima, Z frente).
# Uso: blender -b --python coroa_galhos.py -- saida.glb
import bpy, bmesh, sys, math
from mathutils import Vector
OUT = sys.argv[sys.argv.index('--') + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
def mat(n, c, metal, rough, emit=0.0):
    m = bpy.data.materials.new(n); b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*c, 1); b.inputs['Metallic'].default_value = metal; b.inputs['Roughness'].default_value = rough
    if emit: b.inputs['Emission Color'].default_value = (*c, 1); b.inputs['Emission Strength'].default_value = emit
    return m
OURO = mat('ouro_coroa', (0.95, 0.68, 0.22), 0.9, 0.25)
RUBI = mat('rubi', (0.75, 0.02, 0.04), 0.2, 0.08, 0.6)
G = lambda x, y, z: (x, -z, y)          # glTF (x, cima, frente) -> Blender
def galho(nome, pts, r0, r1):
    cu = bpy.data.curves.new(nome, 'CURVE'); cu.dimensions = '3D'; cu.bevel_depth = 1.0; cu.bevel_resolution = 3
    sp = cu.splines.new('NURBS'); sp.points.add(len(pts) - 1); sp.order_u = min(4, len(pts)); sp.use_endpoint_u = True
    for k, (p, q) in enumerate(zip(sp.points, pts)):
        t = k / (len(pts) - 1); p.co = (*G(*q), 1); p.radius = r0 + (r1 - r0) * t
    o = bpy.data.objects.new(nome, cu); bpy.context.collection.objects.link(o); cu.materials.append(OURO)
    return o
R, Y = 0.112, 0.168
# aro: duas faixas finas na testa e laterais, com ondas
for k, dy in enumerate((-0.007, 0.007)):
    pts = [(math.sin(a) * R, Y + dy + (0.004 * math.cos(a * 6) if k else 0), math.cos(a) * R - 0.012) for a in [-1.75 + 3.5 * i / 30 for i in range(31)]]
    galho('Aro_%d' % k, pts, 0.0035, 0.0035)
for s in (-1, 1):
    # galho principal: sai da têmpora, sobe abrindo para fora e para trás, com pontas
    base = Vector((s * 0.085, Y + 0.005, 0.06))
    meio = Vector((s * 0.12, Y + 0.09, 0.03)); alto = Vector((s * 0.16, Y + 0.2, -0.02))
    galho('Galho_%d' % s, [base, base + Vector((s * 0.02, 0.03, 0.005)), meio, meio + Vector((s * 0.02, 0.06, -0.02)), alto], 0.008, 0.0012)
    for t, d in ((0.3, (s * 0.05, 0.055, 0.02)), (0.55, (s * 0.04, 0.07, 0.03)), (0.8, (s * 0.03, 0.06, 0.02))):
        p = base.lerp(meio, t * 1.6) if t < 0.6 else meio.lerp(alto, (t - 0.5) * 2)
        galho('Ponta_%d_%d' % (s, int(t * 10)), [p, p + Vector(d) * 0.5 + Vector((0, 0.01, 0)), p + Vector(d)], 0.0045, 0.0008)
    # galhinhos do meio que abraçam o rubi
    c = Vector((s * 0.012, Y + 0.008, R - 0.006))
    galho('Meio_%d' % s, [c, c + Vector((s * 0.012, 0.03, 0.004)), c + Vector((s * 0.03, 0.06, -0.004)), c + Vector((s * 0.026, 0.085, -0.01))], 0.005, 0.001)
    galho('Meio2_%d' % s, [c, c + Vector((s * 0.025, 0.015, -0.002)), c + Vector((s * 0.05, 0.03, -0.008))], 0.004, 0.001)
# rubi lapidado (losango alongado) na testa
bm = bmesh.new(); bmesh.ops.create_cone(bm, cap_ends=True, segments=6, radius1=0.011, radius2=0.0, depth=0.022)
for v in bm.verts: v.co.z += 0.011
top = bm.verts[:]
bm2 = [v.co.copy() for v in top]
for co in bm2: bm.verts.new((co.x, co.y, -co.z))
bmesh.ops.convex_hull(bm, input=bm.verts[:])
for v in bm.verts: v.co = Vector((v.co.x, v.co.y * 0.45, v.co.z * 1.4)) + Vector(G(0, Y + 0.022, R + 0.004))
me = bpy.data.meshes.new('Rubi'); bm.to_mesh(me); bm.free()
o = bpy.data.objects.new('Rubi', me); bpy.context.collection.objects.link(o); me.materials.append(RUBI)
for x in bpy.data.objects: x.select_set(True)
bpy.context.view_layer.objects.active = o
bpy.ops.object.convert(target='MESH')
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True, export_yup=True)
print('OK coroa', len(bpy.data.objects))
