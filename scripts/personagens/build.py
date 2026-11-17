# Monta personagens realistas: corpo Quaternius UBC (CC0) + roupas geradas aqui + cabelo.
import bpy, bmesh, sys, math, json
from mathutils import Vector
args = sys.argv[sys.argv.index('--') + 1:]
U, SPEC, OUT = args[0], json.loads(open(args[1]).read()), args[2]
BODY = {'m': 'Superhero_Male_FullBody.gltf', 'f': 'Superhero_Female_FullBody.gltf'}

def build(spec):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=U + 'Base Characters/Godot - UE/' + BODY[spec['corpo']])
    arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
    body = [o for o in bpy.data.objects if o.type == 'MESH' and o.name.lower().startswith('superhero')][0]
    for o in list(bpy.data.objects):
        if o.name.startswith('Icosphere'): bpy.data.objects.remove(o)
    P = lambda b: arm.matrix_world @ arm.data.bones[b].head_local
    T = lambda b: arm.matrix_world @ arm.data.bones[b].tail_local
    names = {g.index: g.name for g in body.vertex_groups}
    dom = {}
    for v in body.data.vertices:
        if v.groups: dom[v.index] = names[max(v.groups, key=lambda g: g.weight).group]
    def grp(*pre):
        return lambda n: any(n.startswith(p) for p in pre)
    def mat(nome, cor, metal=0.0, rough=0.7, emit=None):
        m = bpy.data.materials.new(nome); m.use_backface_culling = False
        b = m.node_tree.nodes['Principled BSDF']
        b.inputs['Base Color'].default_value = (*cor, 1); b.inputs['Metallic'].default_value = metal; b.inputs['Roughness'].default_value = rough
        if emit:
            b.inputs['Emission Color'].default_value = (*emit, 1); b.inputs['Emission Strength'].default_value = 3.0
        return m
    def bind(o, weights):
        """weights: lista por vértice de {osso: peso}"""
        o.parent = arm
        for v, w in zip(o.data.vertices, weights):
            for b, x in w.items():
                if x <= 0: continue
                g = o.vertex_groups.get(b) or o.vertex_groups.new(name=b)
                g.add([v.index], x, 'REPLACE')
        md = o.modifiers.new('Armature', 'ARMATURE'); md.object = arm
    cobre = []
    def shell(nome, keep, off, m, extra=None, liso=0, esconde=True):
        if esconde: cobre.append((keep, extra))
        o = body.copy(); o.data = body.data.copy(); o.name = nome; bpy.context.collection.objects.link(o)
        bm = bmesh.new(); bm.from_mesh(o.data); bm.verts.ensure_lookup_table()
        dele = [v for v in bm.verts if not (v.index in dom and keep(dom[v.index]) and (extra is None or extra(o.matrix_world @ v.co)))]
        bmesh.ops.delete(bm, geom=dele, context='VERTS')
        bm.normal_update()
        for v in bm.verts: v.co += v.normal * off
        if liso:   # alisa músculos: roupa larga não marca o corpo
            bord = [v for v in bm.verts if v.is_boundary]
            for _ in range(liso):
                bmesh.ops.smooth_vert(bm, verts=[v for v in bm.verts if not v.is_boundary], factor=0.5, use_axis_x=True, use_axis_y=True, use_axis_z=True)
            bm.normal_update()
            for v in bm.verts: v.co += v.normal * off * 0.6
        bm.to_mesh(o.data); bm.free()
        o.data.materials.clear(); o.data.materials.append(m)
        return o
    def mesh_obj(nome, bm, m, wfun):
        me = bpy.data.meshes.new(nome); bm.to_mesh(me); bm.free()
        o = bpy.data.objects.new(nome, me); bpy.context.collection.objects.link(o)
        me.materials.append(m)
        bind(o, [wfun(o.matrix_world @ v.co) for v in me.vertices])
        return o
    def secao(z, keep):
        vs = [body.matrix_world @ v.co for v in body.data.vertices if v.index in dom and keep(dom[v.index]) and abs((body.matrix_world @ v.co).z - z) < 0.02]
        xs = [v.x for v in vs]; ys = [v.y for v in vs]
        return (max(xs) - min(xs)) / 2, (max(ys) - min(ys)) / 2, (max(ys) + min(ys)) / 2
    def saia(nome, z0, z1, alarga, m, fecha_frente=True):
        """cone aberto do quadril (z0) até z1, preso à pelve e às pernas"""
        rx, ry, cy = secao(z0, grp('pelvis', 'thigh', 'spine_01'))
        bm = bmesh.new(); seg, an = 28, 14
        rings = []
        for i in range(an + 1):
            t = i / an; z = z0 + (z1 - z0) * t
            k = 1.0 + alarga * t
            rings.append([bm.verts.new((math.cos(a) * (rx + 0.02) * k, cy + math.sin(a) * (ry + 0.03) * k, z)) for a in [j * 2 * math.pi / seg for j in range(seg)]])
        for i in range(an):
            for j in range(seg):
                bm.faces.new((rings[i][j], rings[i][(j + 1) % seg], rings[i + 1][(j + 1) % seg], rings[i + 1][j]))
        def w(p):
            t = max(0.0, min(1.0, (z0 - p.z) / (z0 - z1)))
            side = max(-1.0, min(1.0, p.x / (rx * (1 + alarga * t) + 1e-4)))
            L = 0.85 * t * min(1.0, abs(side) * 1.3)
            perna = ('thigh_l', 'calf_l') if side > 0 else ('thigh_r', 'calf_r')
            kj = 0.0 if p.z > P('calf_l').z else min(1.0, (P('calf_l').z - p.z) / 0.3) * 0.5
            return {'pelvis': 1 - L, perna[0]: L * (1 - kj), perna[1]: L * kj}
        coords = [[v.co.copy() for v in r] for r in rings]
        return mesh_obj(nome, bm, m, w), coords, w
    def faixa(nome, z, h, keep, m, folga=0.03, osso='spine_01'):
        rx, ry, cy = secao(z, keep)
        bm = bmesh.new(); seg = 28
        r0 = [bm.verts.new((math.cos(a) * (rx + folga), cy + math.sin(a) * (ry + folga), z - h / 2)) for a in [j * 2 * math.pi / seg for j in range(seg)]]
        r1 = [bm.verts.new((math.cos(a) * (rx + folga), cy + math.sin(a) * (ry + folga), z + h / 2)) for a in [j * 2 * math.pi / seg for j in range(seg)]]
        for j in range(seg): bm.faces.new((r0[j], r0[(j + 1) % seg], r1[(j + 1) % seg], r1[j]))
        return mesh_obj(nome, bm, m, lambda p: {osso: 1.0})
    def capuz(m, ponta=0.06):
        c = (P('Head') + T('Head')) / 2 + Vector((0, 0.012, 0.02))
        bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=16, radius=0.135)
        for v in bm.verts:
            v.co.x *= 1.0; v.co.y *= 1.12; v.co.z *= 1.18
            if v.co.z > 0.05 and v.co.y > 0.0: v.co += Vector((0, ponta * v.co.z / 0.16, ponta * 0.6 * v.co.z / 0.16))
            v.co += c
        rosto = [f for f in bm.faces if f.calc_center_median().y < c.y - 0.06 and c.z - 0.12 < f.calc_center_median().z < c.z + 0.075]
        bmesh.ops.delete(bm, geom=rosto, context='FACES')
        baixo = [f for f in bm.faces if f.calc_center_median().z < c.z - 0.13]
        bmesh.ops.delete(bm, geom=baixo, context='FACES')
        return mesh_obj('Capuz', bm, m, lambda p: {'Head': 1.0} if p.z > P('neck_01').z + 0.03 else {'Head': 0.5, 'neck_01': 0.5})
    def capa(m, comp=0.15, larg=0.25):
        top = P('spine_03').z + 0.17; bot = comp
        rx, ry, cy = secao(P('spine_03').z + 0.05, grp('spine', 'clavicle'))
        bm = bmesh.new(); nx, nz = 10, 16; rows = []
        for i in range(nz + 1):
            t = i / nz; z = top + (bot - top) * t; w = larg + 0.12 * t
            rows.append([bm.verts.new((-w + 2 * w * j / nx, cy + ry + 0.04 + 0.06 * t + 0.03 * math.cos((j / nx - 0.5) * math.pi), z)) for j in range(nx + 1)])
        for i in range(nz):
            for j in range(nx): bm.faces.new((rows[i][j], rows[i][j + 1], rows[i + 1][j + 1], rows[i + 1][j]))
        def w(p):
            if p.z > P('spine_01').z: return {'spine_03': 1.0}
            if p.z > P('pelvis').z: return {'spine_01': 1.0}
            return {'pelvis': 1.0}
        return mesh_obj('Capa', bm, m, w)
    def ombreira(lado, m, r=0.115):
        c = P('upperarm_' + lado) + Vector((0.035 * (1 if lado == 'l' else -1), 0, 0.03))
        bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=r)
        for v in bm.verts: v.co.z *= 0.65
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.calc_center_median().z < -0.02], context='FACES')
        for v in bm.verts: v.co += c
        return mesh_obj('Ombreira_' + lado, bm, m, lambda p: {'upperarm_' + lado: 0.6, 'clavicle_' + lado: 0.4})
    def cabelo(nome, cor):
        bpy.ops.import_scene.gltf(filepath=U + 'Hairstyles/Origin at 0/glTF (Godot)/' + nome + '.gltf')
        o = bpy.context.selected_objects[0]
        o.data.materials.clear(); o.data.materials.append(mat('Cabelo', cor, 0, 0.85))
        bind(o, [{'Head': 1.0} for v in o.data.vertices])
    def detalhe_em(obj, m_trim, rings, idxs):
        pass
    C = spec
    pele = body.data.materials[0]
    # ---------- roupas ----------
    TOR = grp('pelvis', 'spine', 'clavicle'); NECK = grp('neck')
    ARM = grp('upperarm', 'lowerarm'); UP = grp('upperarm'); LOW = grp('lowerarm')
    HAND = grp('hand', 'index', 'middle', 'pinky', 'ring', 'thumb')
    TH = grp('thigh'); CA = grp('calf'); FT = grp('foot', 'ball')
    zneck = P('neck_01').z + 0.03
    for peca in C['pecas']:
        tipo = peca[0]; cor = tuple(peca[1]); m = mat(tipo, cor, *peca[2:4]) if len(peca) > 2 else mat(tipo, cor)
        if tipo == 'tunica':      # tronco + braços (mangas compridas ou curtas)
            mangas = peca[4] if len(peca) > 4 else 'longa'
            keep = lambda n, mg=mangas: TOR(n) or NECK(n) or UP(n) or (mg == 'longa' and LOW(n))
            shell('Tunica', keep, 0.022 if mangas == 'longa' else 0.014, m, lambda p: p.z < zneck, liso=peca[5] if len(peca) > 5 else 0)
        elif tipo == 'couraca':   # placa de metal no tronco
            shell('Couraca', TOR, 0.05, m, lambda p: p.z > P('pelvis').z - 0.05 and p.z < zneck - 0.02)
        elif tipo == 'calca':
            shell('Calca', lambda n: TH(n) or CA(n) or n == 'pelvis', 0.009, m, lambda p: p.z < P('pelvis').z + 0.06)
        elif tipo == 'botas':
            shell('Botas', lambda n: CA(n) or FT(n), 0.016, m, lambda p: p.z < P('calf_l').z - 0.18)
        elif tipo == 'grevas':
            shell('Grevas', lambda n: CA(n) or FT(n), 0.022, m, lambda p: p.z < P('calf_l').z + 0.05)
        elif tipo == 'luvas':
            shell('Luvas', lambda n: HAND(n) or LOW(n), 0.012, m, lambda p: abs(p.x) > abs(P('lowerarm_l').x) + 0.12)
        elif tipo == 'manoplas':
            shell('Manoplas', lambda n: HAND(n) or LOW(n), 0.02, m, lambda p: abs(p.x) > abs(P('lowerarm_l').x) + 0.05)
        elif tipo == 'braceletes':
            shell('Braceletes', LOW, 0.045, m, lambda p: abs(p.x) > abs(P('lowerarm_l').x) + 0.09)
        elif tipo == 'elmo':      # cobre a cabeça, deixa o rosto
            c = P('Head')
            shell('Elmo', grp('Head'), 0.03, m, lambda p, c=c: not (p.y < c.y - 0.04 and p.z < c.z + 0.12))
        elif tipo == 'capuz':
            capuz(m)
        elif tipo == 'capa':
            capa(m, *(peca[4:] if len(peca) > 4 else []))
        elif tipo == 'ombreiras':
            ombreira('l', m); ombreira('r', m)
        elif tipo == 'saia':      # robe longo, tabardo ou saiote
            fim = {'longa': 0.07, 'joelho': P('calf_l').z - 0.06, 'curta': P('calf_l').z + 0.22}[peca[4]]
            alarga = {'longa': 0.75, 'joelho': 0.35, 'curta': 0.25}[peca[4]]
            o, rings, sw = saia('Saia', P('pelvis').z + 0.07, fim, alarga, m)
            if peca[4] == 'longa':   # pernas ficam escondidas dentro do robe
                cobre.append((lambda n: TH(n) or CA(n), lambda p: p.z > P('calf_l').z - 0.3))
            elif peca[4] == 'joelho':
                cobre.append((lambda n: TH(n), lambda p: p.z > P('calf_l').z + 0.04))
            if len(peca) > 5:     # barra decorativa
                mt = mat('Barra', tuple(peca[5]), 0.6, 0.35)
                bm = bmesh.new(); seg = len(rings[-1]); rr = []
                for k, ring in enumerate((rings[-2], rings[-1])):
                    rr.append([bm.verts.new(c * Vector((1.025, 1.025, 1))) for c in ring])
                for j in range(seg): bm.faces.new((rr[0][j], rr[0][(j + 1) % seg], rr[1][(j + 1) % seg], rr[1][j]))
                mesh_obj('Barra', bm, mt, sw)
        elif tipo == 'cinto':
            faixa('Cinto', P('pelvis').z + 0.075, 0.07, grp('pelvis', 'spine_01', 'thigh'), m, 0.062, 'pelvis')
        elif tipo == 'cabelo':
            cabelo(peca[4], cor)
        elif tipo == 'saiote':     # saia curta de couro/tecido sobre calça
            o, rings, sw = saia('Saiote', P('pelvis').z + 0.07, P('calf_l').z + 0.25, 0.2, m)
    # apaga a pele coberta (com uma pequena margem nas bordas)
    if cobre:
        bm = bmesh.new(); bm.from_mesh(body.data); bm.verts.ensure_lookup_table()
        dentro = set()
        for v in bm.verts:
            if v.index not in dom: continue
            p = body.matrix_world @ v.co
            if any(k(dom[v.index]) and (e is None or e(p)) for k, e in cobre): dentro.add(v.index)
        apagar = [f for f in bm.faces if all(v.index in dentro for v in f.verts) and all(all(e.other_vert(v).index in dentro for e in v.link_edges) for v in f.verts)]
        bmesh.ops.delete(bm, geom=apagar, context='FACES_ONLY')
        bm.to_mesh(body.data); bm.free()
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=OUT + '/' + C['id'] + '.glb', export_format='GLB', export_skins=True, export_animations=False, export_yup=True)
    print('OK', C['id'], len(bpy.data.objects))

for s in SPEC: build(s)
