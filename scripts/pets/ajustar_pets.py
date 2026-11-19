"""Ajusta no Blender (bpy 5.x, sem tela) os modelos do Sketchfab enviados pelo usuário e exporta para o Godot.
Uso: python3.11 ajustar_pets.py <pasta com fenix/ lobo/ urso/> <pasta de saída>
  fenix: real-time_bones_demo_phoenix_bird.glb (CC-BY 4.0)  -> ganha animação de voo (bater de asas e cauda)
  lobo:  wolf_with_animations.glb (3DHaupt, CC-BY-NC-SA 4.0) -> sem a placa de chão
  urso:  realistic_animated_bear_3d_model.glb (WildMesh 3D, CC-BY 4.0) -> pelo branco salpicado de cinza, só as animações usadas
Todos ficam com a frente em -Y do Blender (= +Z no glTF), como o jogo espera.
"""
import bpy, sys, os, math, glob
import numpy as np
from mathutils import Quaternion, Vector, Matrix

SRC, DST = sys.argv[1], sys.argv[2]
os.makedirs(DST, exist_ok=True)

def abrir(pasta):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=glob.glob(os.path.join(SRC, pasta, "*.glb"))[0])
    for o in list(bpy.context.scene.objects):   # forma de exibição de osso criada pelo importador
        if o.name.startswith("Icosphere"):
            bpy.data.objects.remove(o, do_unlink=True)
    return [o for o in bpy.context.scene.objects if o.type == 'ARMATURE'][0]

def virar_para_frente(arm, osso_cabeca, osso_traseiro):
    """Gira tudo para a cabeça apontar para -Y do Blender."""
    M = arm.matrix_world
    d = (M @ arm.data.bones[osso_cabeca].head_local) - (M @ arm.data.bones[osso_traseiro].head_local)
    d.z = 0
    ang = math.atan2(d.y, d.x) - math.atan2(-1.0, 0.0)
    raizes = [o for o in bpy.context.scene.objects if o.parent is None]
    R = Matrix.Rotation(-ang, 4, 'Z')
    for o in raizes:
        o.matrix_world = R @ o.matrix_world
    print("girado", round(math.degrees(-ang), 1))

def osso_com(arm, *partes):
    for b in arm.data.bones:
        n = b.name.lower()
        if all(p in n for p in partes):
            return b.name
    return None

def textura_base(mat):
    """Primeira imagem que alimenta a Cor Base (atravessa nós Mix, como no lobo)."""
    def subir(sock, prof):
        for l in sock.links:
            n = l.from_node
            if n.type == 'TEX_IMAGE':
                return n
            if prof < 3:
                for i in n.inputs:
                    if i.type in ('RGBA', 'VECTOR') and i.links:
                        r = subir(i, prof + 1)
                        if r is not None:
                            return r
        return None
    for n in mat.node_tree.nodes:
        if n.type == 'BSDF_PRINCIPLED':
            return subir(n.inputs['Base Color'], 0)
    return None

def _borrar(a, r):
    for _ in range(2):
        for eixo in (0, 1):
            p = np.pad(a, [(r + 1, r) if e == eixo else (0, 0) for e in (0, 1)], mode="wrap")
            c = np.cumsum(p, axis=eixo)
            a = (np.take(c, range(2 * r + 1, c.shape[eixo]), axis=eixo) - np.take(c, range(0, c.shape[eixo] - 2 * r - 1), axis=eixo)) / (2 * r + 1)
    return a

def manchas(h, w, r, semente):
    a = _borrar(np.random.default_rng(semente).random((h, w)), r)
    return (a - a.min()) / max(a.max() - a.min(), 1e-6)

def recolorir(fn, minimo=0.3):
    """Aplica fn(px, L) nas texturas de cor base das malhas grandes (olhos, dentes e unhas ficam como estão)."""
    feitas = set()
    for o in bpy.context.scene.objects:
        if o.type != 'MESH' or max(o.dimensions) < minimo:
            continue
        for mat in o.data.materials:
            tex = textura_base(mat) if mat and mat.node_tree else None
            if tex is None or tex.image.name in feitas:
                continue
            img = tex.image; w, h = img.size
            px = np.empty(w * h * 4, dtype=np.float32); img.pixels.foreach_get(px); px = px.reshape(h, w, 4)
            L = 0.3 * px[..., 0] + 0.59 * px[..., 1] + 0.11 * px[..., 2]
            out = fn(px.copy(), L)
            img.pixels.foreach_set(np.clip(out, 0, 1).astype(np.float32).ravel()); img.pack()
            feitas.add(img.name)
    print("recoloridas", feitas)

def exportar(nome):
    bpy.ops.export_scene.gltf(filepath=os.path.join(DST, nome), export_format='GLB', export_animations=True, export_yup=True)
    print("EXPORTADO", nome)

# ---------- urso: branco com manchas cinza-claro e salpicos cinza-escuro ----------
arm = abrir("urso")
virar_para_frente(arm, osso_com(arm, "head") or osso_com(arm, "neck"), osso_com(arm, "pelvis") or osso_com(arm, "hip") or osso_com(arm, "tail"))
manter = {"Stand_Idle_01", "Walk", "Trot", "Run", "Attack_StandAngry_01_High"}   # parado, andar, trote, correr, levantar e dar patada
for a in list(bpy.data.actions):
    if a.name not in manter:
        bpy.data.actions.remove(a)
def fcurves(acao):
    for layer in acao.layers:
        for strip in layer.strips:
            for cb in strip.channelbags:
                yield from cb.fcurves

# As animações de locomoção do urso andam para a frente sozinhas (root motion): no jogo ele ia correr e voltar
# de repente a cada ciclo. Tira a deriva das curvas de posição (mantém o balanço) — quem anda é o código do pet.
for acao in bpy.data.actions:
    for fc in fcurves(acao):
        if not fc.data_path.endswith("location") or len(fc.keyframe_points) < 2:
            continue
        kp = fc.keyframe_points
        t0, t1 = kp[0].co.x, kp[-1].co.x
        v0, v1 = kp[0].co.y, kp[-1].co.y
        faixa = max(k.co.y for k in kp) - min(k.co.y for k in kp)
        if faixa > 1e-4 and abs(v1 - v0) > 0.5 * faixa and t1 > t0:
            for k in kp:
                dv = (v1 - v0) * (k.co.x - t0) / (t1 - t0)
                k.co.y -= dv; k.handle_left.y -= dv; k.handle_right.y -= dv
            print("sem deriva:", acao.name, fc.data_path, fc.array_index, round(v1 - v0, 2))
feitas = set()
for o in bpy.context.scene.objects:
    if o.type != 'MESH' or max(o.dimensions) < 0.3:   # olhos/dentes ficam como estão
        continue
    for mat in o.data.materials:
        tex = textura_base(mat)
        if tex is None or tex.image.name in feitas:
            continue
        img = tex.image; w, h = img.size
        px = np.empty(w * h * 4, dtype=np.float32); img.pixels.foreach_get(px); px = px.reshape(h, w, 4)
        L = 0.3 * px[..., 0] + 0.59 * px[..., 1] + 0.11 * px[..., 2]
        n = (L - np.percentile(L, 5)) / max(np.percentile(L, 95) - np.percentile(L, 5), 1e-4)
        v = 0.74 + 0.24 * np.clip(n, 0, 1)                      # pelo branco, mantendo o desenho dos fios
        m1 = manchas(h, w, 12, 2); m2 = manchas(h, w, 5, 3)
        v = np.where(m1 > 0.64, v - (m1 - 0.64) * 1.3, v)       # manchas cinza-claro
        v = np.where(m2 > 0.72, v - (m2 - 0.72) * 3.0, v)       # salpicos cinza-escuro
        v = np.where(L < 0.06, L * 1.4, v)                      # nariz, unhas e boca continuam escuros
        out = px.copy(); out[..., 0] = v; out[..., 1] = v; out[..., 2] = v * 1.01
        img.pixels.foreach_set(np.clip(out, 0, 1).astype(np.float32).ravel()); img.pack()
        feitas.add(img.name)
print("urso texturas", feitas)
exportar("urso.glb")

# ---------- lobo: só tira a placa de chão ----------
arm = abrir("lobo")
for o in list(bpy.context.scene.objects):
    if o.type == 'MESH' and o.name.startswith("Plane"):
        bpy.data.objects.remove(o, do_unlink=True)
cab = osso_com(arm, "head") or osso_com(arm, "kopf_03"); tras = osso_com(arm, "pelvis") or osso_com(arm, "becken") or osso_com(arm, "schwanz")   # ossos em alemão (Kopf = cabeça, Becken = bacia)
print("lobo ossos", cab, tras)
def cinza(px, L):   # lobo cinza: clareia e tira a cor, mantendo os pelos; barriga/focinho claros continuam mais claros
    g = np.clip(0.2 + L * 1.7, 0, 0.92)
    px[..., 0] = g; px[..., 1] = g; px[..., 2] = g * 1.04
    return px
recolorir(cinza, 0.5)
if cab and tras:
    virar_para_frente(arm, cab, tras)
exportar("lobo.glb")

# ---------- fênix: cria a animação de voo ----------
arm = abrir("fenix")
virar_para_frente(arm, "b_Head_06", "B_Pelvis_028")
def fogo(px, L):   # fênix flamejante: troca as cores por um degradê de fogo pela luminosidade (mantém as penas e o alfa)
    n = np.clip((L - np.percentile(L, 3)) / max(np.percentile(L, 97) - np.percentile(L, 3), 1e-4), 0, 1)
    xs = [0.0, 0.35, 0.65, 0.85, 1.0]
    cs = np.array([[0.22, 0.02, 0.0], [0.85, 0.12, 0.02], [1.0, 0.45, 0.04], [1.0, 0.72, 0.15], [1.0, 0.95, 0.6]])
    for k in range(3):
        px[..., k] = np.interp(n, xs, cs[:, k])
    return px
recolorir(fogo, 0.5)
bpy.context.view_layer.update()
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')
M = arm.matrix_world.to_3x3()
frente = (M @ (arm.data.bones["b_Head_06"].head_local - arm.data.bones["B_Pelvis_028"].head_local)); frente.z = 0; frente.normalize()
cima = Vector((0, 0, 1))
asas = [b for b in arm.data.bones if "Wing" in b.name]
raizes = [b for b in asas if b.parent is None or "Wing" not in b.parent.name]
caudas = [b for b in arm.data.bones if "Tail" in b.name]
act = bpy.data.actions.new("Voo")
arm.animation_data_create(); arm.animation_data.action = act
def girar(pb, eixo_mundo, ang):
    """Rotação em torno de um eixo do espaço do armature, convertida para o espaço do osso (relativo ao repouso)."""
    R = pb.bone.matrix_local.to_quaternion()
    eixo = M.inverted() @ eixo_mundo
    return R.inverted() @ Quaternion(eixo, ang) @ R
N = 24
for f in range(N + 1):
    t = 2 * math.pi * f / N
    for b in asas:
        pb = arm.pose.bones[b.name]; pb.rotation_mode = 'QUATERNION'
        lado = 1.0 if (M @ b.head_local).dot(frente.cross(cima)) < 0 else -1.0   # esquerda/direita
        if b in raizes:
            ang = math.radians(10 + 38 * math.sin(t))
        else:
            ang = math.radians(16 * math.sin(t - 0.7))
        pb.rotation_quaternion = girar(pb, frente, ang * lado)
        pb.keyframe_insert("rotation_quaternion", frame=f + 1)
    for i, b in enumerate(caudas):
        pb = arm.pose.bones[b.name]; pb.rotation_mode = 'QUATERNION'
        pb.rotation_quaternion = girar(pb, cima, math.radians(5 * math.sin(t * 0.5 - i * 0.4)))
        pb.keyframe_insert("rotation_quaternion", frame=f + 1)
bpy.ops.object.mode_set(mode='OBJECT')
bpy.context.scene.frame_start = 1; bpy.context.scene.frame_end = N
print("fenix asas", len(asas), "raizes", [b.name for b in raizes])
exportar("fenix.glb")
