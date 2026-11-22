# Máscara de chamas (referência do usuário): preta, borda azul (lado direito do rosto) e vermelha (esquerdo),
# labaredas no topo e chama no meio. Feita com curvas (contorno liso), furos dos olhos, curvada em volta do rosto.
# Coordenadas do osso da cabeça dos heróis: olhos a ~0,10 m acima do osso, frente do rosto a ~0,105 m.
# Uso: blender -b --python mascara.py -- saida.glb
import bpy, bmesh, sys, math
from mathutils import Vector
OUT = sys.argv[sys.argv.index('--') + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
R, F = 0.115, 0.108          # raio da curvatura e distância da frente do rosto
def mat(n, c, emit=0.0, metal=0.3, rough=0.35):
    m = bpy.data.materials.new(n); b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*c, 1); b.inputs['Metallic'].default_value = metal; b.inputs['Roughness'].default_value = rough
    if emit: b.inputs['Emission Color'].default_value = (*c, 1); b.inputs['Emission Strength'].default_value = emit
    return m
PRETO = mat('mascara_preta', (0.025, 0.025, 0.03))
AZUL = mat('borda_azul', (0.02, 0.12, 0.9), 0.35, 0.2, 0.3)
VERM = mat('borda_vermelha', (0.9, 0.05, 0.01), 0.35, 0.2, 0.3)
FOGO = mat('chama', (1.0, 0.3, 0.02), 0.8, 0.0, 0.4)
def espelha(meio):   # meio: pontos do centro-topo ao centro-baixo pelo lado direito (x>0); devolve contorno fechado
    return meio + [(-x, y) for x, y in reversed(meio[1:-1])]
topo_baixo = [(0.0, 0.205), (0.008, 0.16), (0.02, 0.15), (0.03, 0.172), (0.042, 0.142), (0.058, 0.185), (0.068, 0.14),
              (0.082, 0.168), (0.09, 0.128), (0.1, 0.112), (0.094, 0.092), (0.08, 0.08), (0.06, 0.074), (0.04, 0.078),
              (0.022, 0.072), (0.01, 0.062), (0.0, 0.05)]
contorno = espelha(topo_baixo)
def olho(cx):
    pts = []
    for k in range(16):
        a = 2 * math.pi * k / 16
        x = math.cos(a); y = math.sin(a) * (0.62 if x * cx > 0 else 0.8)   # amêndoa: ponta para fora
        pts.append((cx + x * 0.019, 0.101 + y * 0.012 * (1 - 0.25 * max(0, x * math.copysign(1, cx)))))
    return pts
chama_meio = [(0.0, 0.19), (0.01, 0.155), (0.018, 0.125), (0.008, 0.112), (0.0, 0.118), (-0.008, 0.112), (-0.018, 0.125), (-0.01, 0.155)]
def reamostra(pts, passo=0.004, fechado=True):
    out = []
    n = len(pts)
    for i in range(n if fechado else n - 1):
        a, b = Vector(pts[i]), Vector(pts[(i + 1) % n])
        k = max(1, int((b - a).length / passo))
        out += [a.lerp(b, t / k) for t in range(k)]
    return out
def curva(nome, splines, preenche, bevel, extrude, m):
    cu = bpy.data.curves.new(nome, 'CURVE'); cu.dimensions = '2D' if preenche else '3D'
    cu.fill_mode = 'BOTH' if preenche else 'FULL'; cu.bevel_depth = bevel; cu.extrude = extrude; cu.bevel_resolution = 2
    for pts in splines:
        sp = cu.splines.new('POLY'); pp = reamostra(pts)
        sp.points.add(len(pp) - 1)
        for p, q in zip(sp.points, pp): p.co = (q.x, q.y, 0, 1)
        sp.use_cyclic_u = True
    o = bpy.data.objects.new(nome, cu); bpy.context.collection.objects.link(o); o.data.materials.append(m)
    return o
def para_malha(o):
    bpy.context.view_layer.objects.active = o
    for x in bpy.context.selected_objects: x.select_set(False)
    o.select_set(True); bpy.ops.object.convert(target='MESH')
    bm = bmesh.new(); bm.from_mesh(o.data)
    for k in range(-26, 27):   # cortes verticais: vértices a cada ~4 mm para a curvatura ficar lisa
        g = bm.verts[:] + bm.edges[:] + bm.faces[:]
        bmesh.ops.bisect_plane(bm, geom=g, plane_co=(k * 0.004, 0, 0), plane_no=(1, 0, 0))
    bm.to_mesh(o.data); bm.free()
    return o
def curvar(o, frente=0.0):
    """x (largura) vira arco em volta do rosto; y vira altura; z (espessura) vira profundidade radial"""
    for v in o.data.vertices:
        x, y, z = v.co
        a = x / R; r = R + z + frente + max(0.0, y - 0.125) * 0.45   # topo inclinado para a frente (passa por cima da borda do capuz)
        v.co = Vector((r * math.sin(a), -((F - R) + r * math.cos(a)), y))
base = para_malha(curva('Mascara', [contorno, olho(0.034), olho(-0.034)], True, 0.0012, 0.002, PRETO)); curvar(base)
aro = para_malha(curva('Mascara_Borda', [contorno, olho(0.034), olho(-0.034)], False, 0.0026, 0.0, VERM)); curvar(aro, 0.002)
aro.data.materials.append(AZUL)
for f in aro.data.polygons:   # lado direito do rosto (x<0) azul, esquerdo vermelho
    c = sum((aro.data.vertices[i].co for i in f.vertices), Vector()) / len(f.vertices)
    f.material_index = 1 if c.x < 0 else 0
ch = para_malha(curva('Mascara_Chama', [chama_meio], True, 0.0008, 0.001, VERM)); curvar(ch, 0.003)
bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=10, v_segments=8, radius=0.012)
for v in bm.verts:
    v.co.z *= 2.2
    if v.co.z > 0: v.co.x *= 1 - v.co.z / 0.03; v.co.y *= 1 - v.co.z / 0.03
    v.co += Vector((0, -(F + 0.006), 0.215))
me = bpy.data.meshes.new('Chama_Topo'); bm.to_mesh(me); bm.free()
o = bpy.data.objects.new('Chama_Topo', me); bpy.context.collection.objects.link(o); me.materials.append(FOGO)
for x in bpy.data.objects: x.select_set(True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True, export_yup=True)
print('OK mascara', [x.name for x in bpy.data.objects], sum(len(x.data.vertices) for x in bpy.data.objects))
