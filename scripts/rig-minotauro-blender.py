import bpy, sys, math
from mathutils import Vector, Matrix, Quaternion
SRC, DST = sys.argv[-2], sys.argv[-1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
mesh = [o for o in bpy.data.objects if o.type == 'MESH'][0]
# aplica transformações para a malha ficar em coordenadas do mundo
bpy.context.view_layer.objects.active = mesh; mesh.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
def B(x, y, z):  # glTF (x, y cima, z frente) -> Blender (x, -z, y)
    return Vector((x, -z, y))
J = {
 'Hips': (B(0.02,-0.30,0.03), B(0.02,-0.05,0.08), None),
 'Spine': (B(0.02,-0.05,0.08), B(0.02,0.25,-0.02), 'Hips'),
 'Chest': (B(0.02,0.25,-0.02), B(0.02,0.55,0.0), 'Spine'),
 'Head': (B(0.02,0.55,0.0), B(0.02,0.9,0.1), 'Chest'),
 'ArmA': (B(-0.36,0.48,0.0), B(-0.48,0.12,0.12), 'Chest'),
 'ForeA': (B(-0.48,0.12,0.12), B(-0.46,-0.18,0.18), 'ArmA'),
 'HandA': (B(-0.46,-0.18,0.18), B(-0.43,-0.33,0.18), 'ForeA'),
 'ArmB': (B(0.36,0.48,-0.08), B(0.47,0.12,-0.22), 'Chest'),
 'ForeB': (B(0.47,0.12,-0.22), B(0.49,-0.15,-0.16), 'ArmB'),
 'HandB': (B(0.49,-0.15,-0.16), B(0.47,-0.30,-0.14), 'ForeB'),
 'ThighA': (B(-0.17,-0.38,0.02), B(-0.21,-0.63,0.04), 'Hips'),
 'ShinA': (B(-0.21,-0.63,0.04), B(-0.22,-0.85,-0.01), 'ThighA'),
 'FootA': (B(-0.22,-0.85,-0.01), B(-0.24,-0.93,0.2), 'ShinA'),
 'ThighB': (B(0.18,-0.38,-0.05), B(0.17,-0.63,-0.15), 'Hips'),
 'ShinB': (B(0.17,-0.63,-0.15), B(0.2,-0.85,-0.16), 'ThighB'),
 'FootB': (B(0.2,-0.85,-0.16), B(0.27,-0.93,0.02), 'ShinB'),
}
ORDER = list(J.keys())
arm_data = bpy.data.armatures.new('Rig'); arm = bpy.data.objects.new('Minotauro', arm_data)
bpy.context.collection.objects.link(arm)
bpy.ops.object.select_all(action='DESELECT'); bpy.context.view_layer.objects.active = arm; arm.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for n in ORDER:
    h, t, p = J[n]; eb = arm_data.edit_bones.new(n); eb.head = h; eb.tail = t
    if p: eb.parent = arm_data.edit_bones[p]; eb.use_connect = False
bpy.ops.object.mode_set(mode='OBJECT')
# pesos automáticos (bone heat); se falhar, o script acusa
bpy.ops.object.select_all(action='DESELECT'); mesh.select_set(True); arm.select_set(True); bpy.context.view_layer.objects.active = arm
bpy.ops.object.parent_set(type='ARMATURE_AUTO')
w = sum(1 for v in mesh.data.vertices if len(v.groups) > 0)
print('WEIGHTED', w, 'of', len(mesh.data.vertices))
if w < len(mesh.data.vertices) * 0.9:
    # reserva: peso pela distância ao osso (2 ossos mais próximos)
    print('FALLBACK distance weights')
    for g in list(mesh.vertex_groups): mesh.vertex_groups.remove(g)
    groups = {n: mesh.vertex_groups.new(name=n) for n in ORDER}
    def dist(p, a, b):
        ab = b - a; t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared)); return (p - (a + ab * t)).length
    for v in mesh.data.vertices:
        ds = sorted((dist(v.co, J[n][0], J[n][1]), n) for n in ORDER)[:2]
        ws = [1.0 / (d + 1e-4) ** 4 for d, _ in ds]; tot = sum(ws)
        for (d, n), wv in zip(ds, ws): groups[n].add([v.index], wv / tot, 'REPLACE')
    if not any(m.type == 'ARMATURE' for m in mesh.modifiers):
        mesh.parent = arm; md = mesh.modifiers.new('Armature', 'ARMATURE'); md.object = arm
# ---------- animações ----------
bpy.context.view_layer.objects.active = arm; bpy.ops.object.mode_set(mode='POSE')
for pb in arm.pose.bones: pb.rotation_mode = 'QUATERNION'
X, Y, Z = Vector((1,0,0)), Vector((0,1,0)), Vector((0,0,1))
def pose(rots, hips_dz=0.0):
    for pb in arm.pose.bones:
        pb.rotation_quaternion = Quaternion(); pb.location = (0,0,0)
    bpy.context.view_layer.update()
    for n in ORDER:   # pais primeiro
        if n in rots:
            pb = arm.pose.bones[n]
            for axis, deg in rots[n]:
                h = pb.matrix.to_translation()
                pb.matrix = Matrix.Translation(h) @ Matrix.Rotation(math.radians(deg), 4, axis) @ Matrix.Translation(-h) @ pb.matrix
                bpy.context.view_layer.update()
    if hips_dz:
        pb = arm.pose.bones['Hips']; m = pb.matrix.copy(); m.translation.z += hips_dz; pb.matrix = m; bpy.context.view_layer.update()
def key(f):
    for pb in arm.pose.bones:
        pb.keyframe_insert('rotation_quaternion', frame=f)
    arm.pose.bones['Hips'].keyframe_insert('location', frame=f)
def action(name, frames):
    arm.animation_data_create(); act = bpy.data.actions.new(name); arm.animation_data.action = act
    for f, rots, dz in frames:
        pose(rots, dz); key(f)
    act.use_fake_user = True
    tr = arm.animation_data.nla_tracks.new(); tr.name = name
    st = tr.strips.new(name, 1, act)
    arm.animation_data.action = None
    return act
# X negativo = balança para a frente
def walk(s, k):   # s = fase (-1..1), k = quanto dobra
    return {'ThighA': [(X, -26*s)], 'ShinA': [(X, 30*max(0.0, s) + 6)], 'ThighB': [(X, 26*s)], 'ShinB': [(X, 30*max(0.0, -s) + 6)],
            'ArmA': [(X, 20*s)], 'ArmB': [(X, -20*s)], 'ForeA': [(X, -10)], 'ForeB': [(X, -10)],
            'Spine': [(Z, 5*s), (X, 5)], 'Chest': [(Z, 4*s)], 'Head': [(Z, -6*s)]}
action('Idle', [(1, {}, 0.0), (30, {'Spine': [(X, -2)], 'Chest': [(X, -3)], 'ArmA': [(Y, 3)], 'ArmB': [(Y, -3)], 'Head': [(X, 3)]}, -0.006), (60, {}, 0.0)])
action('Walk', [(1, walk(1, 1), 0.0), (9, walk(0, 1), 0.03), (17, walk(-1, 1), 0.0), (25, walk(0, 1), 0.03), (33, walk(1, 1), 0.0)])
up = {'Spine': [(X, -12)], 'Chest': [(X, -14)], 'ArmA': [(X, -120)], 'ArmB': [(X, -120)], 'ForeA': [(X, -30)], 'ForeB': [(X, -30)], 'Head': [(X, -10)]}
down = {'Spine': [(X, 22)], 'Chest': [(X, 24)], 'ArmA': [(X, -45)], 'ArmB': [(X, -45)], 'ForeA': [(X, -20)], 'ForeB': [(X, -20)], 'Head': [(X, 8)], 'ThighA': [(X, -18)], 'ShinA': [(X, 26)], 'ThighB': [(X, -18)], 'ShinB': [(X, 26)]}
action('Attack', [(1, {}, 0.0), (14, up, 0.02), (20, down, -0.06), (26, down, -0.06), (40, {}, 0.0)])
action('Hit', [(1, {}, 0.0), (5, {'Spine': [(X, -14)], 'Chest': [(X, -10)], 'Head': [(X, -14)]}, 0.0), (14, {}, 0.0)])
pose({}); bpy.ops.object.mode_set(mode='OBJECT')
# material escuro
mat = bpy.data.materials.new('MinotauroDark'); mat.use_nodes = True
bsdf = mat.node_tree.nodes.get('Principled BSDF')
bsdf.inputs['Base Color'].default_value = (0.02, 0.018, 0.028, 1); bsdf.inputs['Metallic'].default_value = 0.45; bsdf.inputs['Roughness'].default_value = 0.5
mesh.data.materials.clear(); mesh.data.materials.append(mat)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_animations=True, export_animation_mode='NLA_TRACKS', export_skins=True, export_yup=True, export_apply=False)
print('EXPORTED', [a.name for a in bpy.data.actions])
