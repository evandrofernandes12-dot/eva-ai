# Cajados com cristal brilhante e aljava (gerados aqui).
import bpy, bmesh, sys, math, random
OUT = sys.argv[sys.argv.index('--') + 1]
def mat(n, c, metal=0, rough=0.8, emit=None):
    m = bpy.data.materials.new(n); b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*c, 1); b.inputs['Metallic'].default_value = metal; b.inputs['Roughness'].default_value = rough
    if emit: b.inputs['Emission Color'].default_value = (*emit, 1); b.inputs['Emission Strength'].default_value = 1.2
    return m
def cajado(nome, cor):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    random.seed(3)
    madeira = mat('Madeira', (0.09, 0.05, 0.025), 0, 0.9)
    # cabo torcido: 1,75 m, de y=0 (chão) a y=1.75 (Blender Z)
    bm = bmesh.new(); seg, an = 8, 40; rings = []
    for i in range(an + 1):
        t = i / an; z = 1.6 * t; r = 0.022 - 0.006 * t
        ox = 0.012 * math.sin(t * 9.0) + random.uniform(-0.002, 0.002); oy = 0.012 * math.cos(t * 7.0)
        rings.append([bm.verts.new((ox + r * math.cos(a + t * 6), oy + r * math.sin(a + t * 6), z)) for a in [j * 2 * math.pi / seg for j in range(seg)]])
    for i in range(an):
        for j in range(seg): bm.faces.new((rings[i][j], rings[i][(j + 1) % seg], rings[i + 1][(j + 1) % seg], rings[i + 1][j]))
    # galhos que abraçam o cristal
    for k in range(4):
        a0 = k * math.pi / 2; prev = None
        pts = []
        for i in range(10):
            t = i / 9; z = 1.55 + 0.25 * t; r = 0.02 + 0.07 * math.sin(t * math.pi) 
            pts.append((r * math.cos(a0 + t * 1.2), r * math.sin(a0 + t * 1.2), z))
        for i in range(len(pts) - 1):
            rr = 0.009 * (1 - i / 10)
            p0, p1 = pts[i], pts[i + 1]
            q = [bm.verts.new((p0[0] + rr * math.cos(a), p0[1] + rr * math.sin(a), p0[2])) for a in [j * 2 * math.pi / 5 for j in range(5)]]
            w = [bm.verts.new((p1[0] + rr * math.cos(a), p1[1] + rr * math.sin(a), p1[2])) for a in [j * 2 * math.pi / 5 for j in range(5)]]
            for j in range(5): bm.faces.new((q[j], q[(j + 1) % 5], w[(j + 1) % 5], w[j]))
    me = bpy.data.meshes.new('Cabo'); bm.to_mesh(me); bm.free(); o = bpy.data.objects.new('Cabo', me); bpy.context.collection.objects.link(o); me.materials.append(madeira)
    # cristal
    bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.06)
    for v in bm.verts: v.co.z *= 2.0; v.co.z += 1.7
    me = bpy.data.meshes.new('Cristal'); bm.to_mesh(me); bm.free(); o = bpy.data.objects.new('Cristal', me); bpy.context.collection.objects.link(o)
    me.materials.append(mat('Cristal', cor, 0, 0.1, cor))
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=OUT + '/' + nome + '.glb', export_format='GLB', export_yup=True)
def aljava():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    couro = mat('Couro', (0.12, 0.06, 0.025), 0, 0.8); pena = mat('Pena', (0.6, 0.58, 0.52), 0, 0.9); haste = mat('Haste', (0.25, 0.16, 0.08), 0, 0.8)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.055, depth=0.55, location=(0, 0, 0.275)); c = bpy.context.object; c.data.materials.append(couro)
    for k in range(6):
        a = k * 1.05; x, y = 0.025 * math.cos(a), 0.025 * math.sin(a)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.004, depth=0.2, location=(x, y, 0.62)); bpy.context.object.data.materials.append(haste)
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, 0.68)); f = bpy.context.object; f.scale = (0.004, 0.02, 0.05); f.data.materials.append(pena)
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=OUT + '/Aljava.glb', export_format='GLB', export_yup=True)
cajado('Cajado_Azul', (0.2, 0.6, 1.0)); cajado('Cajado_Roxo', (0.6, 0.15, 1.0)); cajado('Cajado_Rubi', (1.0, 0.25, 0.08)); aljava()
print('PROPS OK')
