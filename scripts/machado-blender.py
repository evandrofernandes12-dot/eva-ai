import bpy, bmesh, sys, math
DST = sys.argv[-1]
bpy.ops.wm.read_factory_settings(use_empty=True)
me = bpy.data.meshes.new('Machado'); ob = bpy.data.objects.new('Machado', me); bpy.context.collection.objects.link(ob)
bm = bmesh.new(); col = bm.loops.layers.color.new('Col')
WOOD, IRON, STEEL, EDGE = (0.16, 0.08, 0.035, 1), (0.06, 0.06, 0.07, 1), (0.30, 0.33, 0.38, 1), (0.62, 0.66, 0.72, 1)
def paint(faces, c):
    for f in faces:
        for l in f.loops: l[col] = c
def cyl(r1, r2, z0, z1, c, seg=10):
    ring0 = [bm.verts.new((r1*math.cos(a), r1*math.sin(a), z0)) for a in [i*2*math.pi/seg for i in range(seg)]]
    ring1 = [bm.verts.new((r2*math.cos(a), r2*math.sin(a), z1)) for a in [i*2*math.pi/seg for i in range(seg)]]
    fs = [bm.faces.new((ring0[i], ring0[(i+1)%seg], ring1[(i+1)%seg], ring1[i])) for i in range(seg)]
    fs.append(bm.faces.new(ring0[::-1])); fs.append(bm.faces.new(ring1)); paint(fs, c)
# cabo, anéis de ferro, ponta de lança em cima e pino embaixo
cyl(0.030, 0.026, -0.55, 1.15, WOOD)
for z in (0.72, 1.02): cyl(0.043, 0.043, z, z + 0.07, IRON)
cyl(0.05, 0.05, 0.78, 1.01, IRON, 8)
cyl(0.036, 0.036, -0.25, -0.19, IRON); cyl(0.036, 0.036, 0.25, 0.31, IRON)
cyl(0.05, 0.0005, 1.15, 1.42, EDGE, 6); cyl(0.045, 0.045, 1.12, 1.16, IRON)
cyl(0.0005, 0.04, -0.72, -0.55, EDGE, 6)
# lâmina em meia-lua: contorno (x para fora, z ao longo do cabo); o fio é a parte de fora
C = 0.895
inner_top = [(0.04, C + 0.085), (0.13, C + 0.10), (0.22, C + 0.20), (0.29, C + 0.34)]
tip_top = (0.34, C + 0.44)
arc = [(0.34 + 0.115*math.cos(a) - 0.0, C + 0.44*math.sin(a) / math.sin(math.radians(78))) for a in [math.radians(d) for d in (78, 52, 26, 0, -26, -52, -78)]]
arc = [(0.33 + 0.13*math.cos(math.radians(d)), C + 0.45*math.sin(math.radians(d))) for d in (60, 40, 20, 0, -20, -40, -60)]
tip_bot = (0.34, C - 0.44)
inner_bot = [(0.29, C - 0.34), (0.22, C - 0.20), (0.13, C - 0.10), (0.04, C - 0.085)]
outline = inner_top + [tip_top] + arc + [tip_bot] + inner_bot
sharp = set(range(len(inner_top), len(inner_top) + 1 + len(arc) + 1))   # pontas + arco = fio fino
for sx in (1, -1):
    front = [bm.verts.new((sx*x, 0.004 if i in sharp else 0.024, z)) for i, (x, z) in enumerate(outline)]
    back = [bm.verts.new((sx*x, -0.004 if i in sharp else -0.024, z)) for i, (x, z) in enumerate(outline)]
    f1 = bm.faces.new(front if sx > 0 else front[::-1]); f2 = bm.faces.new(back[::-1] if sx > 0 else back)
    n = len(outline); side = []
    for i in range(n):
        j = (i + 1) % n
        q = (front[j], front[i], back[i], back[j]) if sx > 0 else (front[i], front[j], back[j], back[i])
        side.append(bm.faces.new(q))
    for f in (f1, f2):
        for l in f.loops:
            x = abs(l.vert.co.x); t = min(1.0, max(0.0, (x - 0.12) / 0.3))
            l[col] = tuple(STEEL[k] + (EDGE[k] - STEEL[k]) * t for k in range(4))
    paint(side, EDGE)
bmesh.ops.triangulate(bm, faces=bm.faces[:])
bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
bmesh.ops.scale(bm, vec=(0.8, 0.8, 0.8), verts=bm.verts[:])
bm.to_mesh(me); bm.free()
me.color_attributes.active_color = me.color_attributes['Col']
mat = bpy.data.materials.new('Machado'); me.materials.append(mat)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_yup=True, export_vertex_color='ACTIVE', export_active_vertex_color_when_no_material=True)
print('AXE OK', len(me.vertices))
