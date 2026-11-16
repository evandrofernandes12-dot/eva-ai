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
# ---------- cores por região (pintura de vértices) ----------
names = {g.index: g.name for g in mesh.vertex_groups}
SKIN, IVORY, STEEL_B, STEEL, LEATHER, HOOF = (0.33, 0.15, 0.07), (0.72, 0.62, 0.42), (0.10, 0.20, 0.34), (0.22, 0.23, 0.26), (0.07, 0.035, 0.02), (0.05, 0.045, 0.04)
vcol = {}
for v in mesh.data.vertices:
    x, y, z = v.co.x, v.co.z, -v.co.y          # volta para (x, cima, frente)
    dom = names[max(v.groups, key=lambda g: g.weight).group] if v.groups else 'Hips'
    c = SKIN
    if dom == 'Head' and y > 0.745 and abs(x - 0.02) > 0.085: c = IVORY
    elif dom in ('ArmA', 'ArmB', 'Chest') and y > 0.40 and abs(x) > 0.25: c = STEEL_B
    elif dom in ('ForeA', 'ForeB'): c = STEEL
    elif dom in ('FootA', 'FootB') or y < -0.80: c = HOOF
    elif dom in ('ShinA', 'ShinB'): c = STEEL
    elif -0.44 < y < -0.27: c = LEATHER
    elif y <= -0.44 and y > -0.82 and dom in ('Hips', 'ThighA', 'ThighB') and abs(x - 0.02) < 0.13 and z > 0.05: c = LEATHER
    vcol[v.index] = c
ca = mesh.data.color_attributes.new(name='Col', type='BYTE_COLOR', domain='CORNER')
for loop in mesh.data.loops:
    ca.data[loop.index].color = (*vcol[loop.vertex_index], 1.0)
mesh.data.color_attributes.active_color = ca
mesh.data.color_attributes.render_color_index = 0
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
    return {'ThighA': [(X, -32*s)], 'ShinA': [(X, 26*max(0.0, s) + 4)], 'ThighB': [(X, 32*s)], 'ShinB': [(X, 26*max(0.0, -s) + 4)],
            'ArmA': [(X, 20*s)], 'ArmB': [(X, -20*s)], 'ForeA': [(X, -10)], 'ForeB': [(X, -10)],
            'Spine': [(Z, 5*s), (X, 5)], 'Chest': [(Z, 4*s)], 'Head': [(Z, -6*s)]}
action('Idle', [(1, {}, 0.0), (30, {'Spine': [(X, -2)], 'Chest': [(X, -3)], 'ArmA': [(Y, 3)], 'ArmB': [(Y, -3)], 'Head': [(X, 3)]}, -0.006), (60, {}, 0.0)])
def passo(lado):   # meio da passada: a perna que vem para a frente dobra o joelho e sai do chão
    d = walk(0, 1)
    if lado > 0: d.update({'ThighA': [(X, -22)], 'ShinA': [(X, 48)]})
    else: d.update({'ThighB': [(X, -22)], 'ShinB': [(X, 48)]})
    return d
DZ = -0.075          # quanto o quadril desce com as pernas abertas
action('Walk', [(1, walk(1, 1), DZ), (9, passo(-1), 0.0), (17, walk(-1, 1), DZ), (25, passo(1), 0.0), (33, walk(1, 1), DZ)])
up = {'Spine': [(X, -12)], 'Chest': [(X, -14)], 'ArmA': [(X, -120)], 'ArmB': [(X, -120)], 'ForeA': [(X, -30)], 'ForeB': [(X, -30)], 'Head': [(X, -10)]}
down = {'Spine': [(X, 22)], 'Chest': [(X, 24)], 'ArmA': [(X, -45)], 'ArmB': [(X, -45)], 'ForeA': [(X, -20)], 'ForeB': [(X, -20)], 'Head': [(X, 8)], 'ThighA': [(X, -18)], 'ShinA': [(X, 26)], 'ThighB': [(X, -18)], 'ShinB': [(X, 26)]}
action('Attack', [(1, {}, 0.0), (14, up, 0.02), (20, down, -0.06), (26, down, -0.06), (40, {}, 0.0)])
def mix(a, b):
    d = dict(a); d.update(b); return d
HOLD = {'ArmA': [(X, -35)], 'ForeA': [(X, -60)]}          # braço da frente segura o machado erguido
action('AxeIdle', [(1, HOLD, 0.0), (30, mix({'Spine': [(X, -2)], 'Chest': [(X, -3)], 'Head': [(X, 3)]}, {'ArmA': [(X, -38)], 'ForeA': [(X, -62)]}), -0.006), (60, HOLD, 0.0)])
action('AxeWalk', [(1, mix(walk(1, 1), HOLD), DZ), (9, mix(passo(-1), HOLD), 0.0), (17, mix(walk(-1, 1), HOLD), DZ), (25, mix(passo(1), HOLD), 0.0), (33, mix(walk(1, 1), HOLD), DZ)])
a_up = {'Spine': [(X, -12)], 'Chest': [(X, -10), (Z, -12)], 'ArmA': [(X, -165)], 'ForeA': [(X, -25)], 'Head': [(X, -8)], 'ArmB': [(X, 20)]}
a_dn = {'Spine': [(X, 24)], 'Chest': [(X, 16), (Z, 10)], 'ArmA': [(X, -42)], 'ForeA': [(X, -8)], 'Head': [(X, 6)], 'ArmB': [(X, 25)], 'ThighA': [(X, -16)], 'ShinA': [(X, 22)], 'ThighB': [(X, 8)], 'ShinB': [(X, 10)]}
action('AxeAttack', [(1, HOLD, 0.0), (12, a_up, 0.02), (18, a_dn, -0.05), (25, a_dn, -0.05), (38, HOLD, 0.0)])
pB0 = {'ArmB': [(X, 30)], 'ForeB': [(X, -70)], 'Chest': [(Z, -14)], 'ArmA': [(X, -20)], 'ForeA': [(X, -70)]}
pB1 = {'ArmB': [(X, -88)], 'ForeB': [(X, -6)], 'Chest': [(Z, 16), (X, 8)], 'Spine': [(X, 8)], 'ArmA': [(X, 10)], 'ForeA': [(X, -80)]}
pA0 = {'ArmA': [(X, 30)], 'ForeA': [(X, -70)], 'Chest': [(Z, 14)], 'ArmB': [(X, -20)], 'ForeB': [(X, -70)]}
pA1 = {'ArmA': [(X, -88)], 'ForeA': [(X, -6)], 'Chest': [(Z, -16), (X, 8)], 'Spine': [(X, 8)], 'ArmB': [(X, 10)], 'ForeB': [(X, -80)]}
action('Punch', [(1, {}, 0.0), (6, pB0, 0.0), (10, pB1, -0.02), (15, pA0, 0.0), (19, pA1, -0.02), (24, pA1, -0.02), (32, {}, 0.0)])
lean = {'Spine': [(X, 22)], 'Chest': [(X, 12)], 'Head': [(X, 22)], 'ArmA': [(X, 18)], 'ArmB': [(X, 18)], 'ThighB': [(X, -14)], 'ShinB': [(X, 22)]}
fwd = mix(lean, {'ThighA': [(X, -34)], 'ShinA': [(X, 12)]})
back = mix(lean, {'ThighA': [(X, 26)], 'ShinA': [(X, 46)]})
action('Paw', [(1, {}, 0.0), (6, fwd, -0.03), (11, back, -0.03), (16, fwd, -0.03), (21, back, -0.03), (26, fwd, -0.03), (31, back, -0.03), (36, lean, -0.03)])
def run(s):
    return {'ThighA': [(X, -38*s)], 'ShinA': [(X, 44*max(0.0, s) + 8)], 'ThighB': [(X, 38*s)], 'ShinB': [(X, 44*max(0.0, -s) + 8)],
            'Spine': [(X, 30)], 'Chest': [(X, 14)], 'Head': [(X, 26)], 'ArmA': [(X, 30 + 12*s)], 'ArmB': [(X, 30 - 12*s)], 'ForeA': [(X, -30)], 'ForeB': [(X, -30)]}
action('Charge', [(1, run(1), -0.11), (5, run(0), -0.02), (9, run(-1), -0.11), (13, run(0), -0.02), (17, run(1), -0.11)])
action('Hit', [(1, {}, 0.0), (5, {'Spine': [(X, -14)], 'Chest': [(X, -10)], 'Head': [(X, -14)]}, 0.0), (14, {}, 0.0)])
pose({}); bpy.ops.object.mode_set(mode='OBJECT')
# material escuro
mat = bpy.data.materials.new('MinotauroDark'); mat.use_nodes = True
bsdf = mat.node_tree.nodes.get('Principled BSDF')
bsdf.inputs['Base Color'].default_value = (0.02, 0.018, 0.028, 1); bsdf.inputs['Metallic'].default_value = 0.45; bsdf.inputs['Roughness'].default_value = 0.5
mesh.data.materials.clear(); mesh.data.materials.append(mat)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_animations=True, export_animation_mode='NLA_TRACKS', export_skins=True, export_yup=True, export_apply=False, export_vertex_color='ACTIVE', export_active_vertex_color_when_no_material=True)
print('EXPORTED', [a.name for a in bpy.data.actions])
