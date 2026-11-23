# Gera a "foto" (impostor) de cada árvore: vista de lado, fundo transparente, 256x512.
# No jogo, de longe a árvore vira dois planos cruzados com essa imagem (bem mais leve).
# Uso: blender -b --python impostores.py -- pasta_gltf pasta_saida NOME1 NOME2 ...
import bpy, sys, math, mathutils, os
a = sys.argv[sys.argv.index('--') + 1:]
ENT, OUT, NOMES = a[0], a[1], a[2:]
for nome in NOMES:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(ENT, nome + '.gltf'))
    objs = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    pts = [o.matrix_world @ mathutils.Vector(c) for o in objs for c in o.bound_box]
    mn = mathutils.Vector([min(p[i] for p in pts) for i in range(3)]); mx = mathutils.Vector([max(p[i] for p in pts) for i in range(3)])
    larg = max(mx.x - mn.x, mx.y - mn.y); alt = mx.z - mn.z
    scn = bpy.context.scene
    cam = bpy.data.objects.new('c', bpy.data.cameras.new('c')); scn.collection.objects.link(cam); scn.camera = cam
    cam.data.type = 'ORTHO'; cam.data.ortho_scale = max(alt, larg * 2.0) * 1.02
    c = (mn + mx) / 2
    cam.location = (c.x, mn.y - 30, c.z); cam.rotation_euler = (math.pi / 2, 0, 0)
    sun = bpy.data.objects.new('s', bpy.data.lights.new('s', 'SUN')); sun.data.energy = 3.5; sun.rotation_euler = (0.9, 0.2, -0.5); scn.collection.objects.link(sun)
    w = bpy.data.worlds.new('w'); scn.world = w; w.use_nodes = True
    w.node_tree.nodes['Background'].inputs[0].default_value = (0.55, 0.6, 0.7, 1); w.node_tree.nodes['Background'].inputs[1].default_value = 0.9
    scn.render.engine = 'CYCLES'; scn.cycles.samples = 24; scn.render.film_transparent = True
    scn.render.resolution_x = 256; scn.render.resolution_y = 512
    scn.render.image_settings.file_format = 'PNG'; scn.render.image_settings.color_mode = 'RGBA'
    scn.render.filepath = os.path.join(OUT, nome + '.png')
    bpy.ops.render.render(write_still=True)
    # proporção usada no jogo: largura/altura da imagem em metros relativos
    print('IMP', nome, round(cam.data.ortho_scale / alt, 4), round(-(mn.z - (c.z - cam.data.ortho_scale / 2)) / alt, 4))
