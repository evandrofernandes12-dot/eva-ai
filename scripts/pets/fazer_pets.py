"""Gera os pets do protótipo Godot a partir de modelos livres do GitHub, no Blender (bpy 5.x, sem tela).
Uso: python3.11 fazer_pets.py <pasta_dos_modelos_baixados> <pasta_de_saida>
  Fox.glb   (KhronosGroup/glTF-Sample-Assets: modelo PixelMannen CC0, rig/animação tomkranis CC-BY 4.0) -> lobo.glb e urso.glb
  Horse.glb (mrdoob/three.js examples: modelo de mirada, ro.me) -> cavalo.glb (branco; as asas são postas no Godot)
  Parrot.glb (mrdoob/three.js examples: mirada, ro.me) -> fenix.glb (cores de fogo; cauda e chamas no Godot)
"""
import bpy, bmesh, sys, os, math
import numpy as np

SRC, DST = sys.argv[1], sys.argv[2]
os.makedirs(DST, exist_ok=True)

def limpar():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def importar(nome):
    bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, nome))
    return [o for o in bpy.context.scene.objects if o.type == 'MESH' and len(o.data.vertices) > 100][0]

def suavizar(ob, subdividir):
    """Junta os vértices duplicados (malha facetada) e sombreia liso; opcionalmente subdivide (só sem shape keys)."""
    bpy.context.view_layer.objects.active = ob
    bm = bmesh.new(); bm.from_mesh(ob.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.05)
    bm.to_mesh(ob.data); bm.free()
    for p in ob.data.polygons:
        p.use_smooth = True
    if subdividir:
        m = ob.modifiers.new("sub", 'SUBSURF'); m.levels = 1; m.render_levels = 1
        while ob.modifiers[0].name != "sub":
            bpy.ops.object.modifier_move_up(modifier="sub")
        bpy.ops.object.modifier_apply(modifier="sub")

def exportar(nome):
    bpy.ops.export_scene.gltf(filepath=os.path.join(DST, nome), export_format='GLB', export_animations=True,
                              export_apply=False, export_yup=True)
    print("EXPORTADO", nome)

def textura(ob):
    mat = ob.data.materials[0]
    tex = [n for n in mat.node_tree.nodes if n.type == 'TEX_IMAGE'][0]
    img = tex.image
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32); img.pixels.foreach_get(px)
    return tex, img, px.reshape(h, w, 4), w, h

def nova_textura(tex, nome, arr, w, h):
    img = bpy.data.images.new(nome, w, h)
    img.pixels.foreach_set(arr.astype(np.float32).ravel())
    img.pack()
    tex.image = img

def _borrar(a, r):
    """Desfoque de caixa (duas passadas) via somas acumuladas, com borda repetida."""
    for _ in range(2):
        for eixo in (0, 1):
            p = np.pad(a, [(r + 1, r) if e == eixo else (0, 0) for e in (0, 1)], mode="wrap")
            c = np.cumsum(p, axis=eixo)
            a = (np.take(c, range(2 * r + 1, c.shape[eixo]), axis=eixo) - np.take(c, range(0, c.shape[eixo] - 2 * r - 1), axis=eixo)) / (2 * r + 1)
    return a

def manchas(h, w, celula, semente):
    """Manchas suaves (ruído desfocado), normalizadas para 0..1."""
    rng = np.random.default_rng(semente)
    a = _borrar(rng.random((h, w)), celula)
    return (a - a.min()) / max(a.max() - a.min(), 1e-6)

# ---------- lobo (raposa recolorida em cinza, lisa) ----------
limpar()
ob = importar("Fox.glb")
tex, img, px, w, h = textura(ob)
L = 0.3 * px[..., 0] + 0.59 * px[..., 1] + 0.11 * px[..., 2]
g = 0.16 + 0.64 * L
out = px.copy()
out[..., 0] = g; out[..., 1] = g; out[..., 2] = g * 1.04
nova_textura(tex, "lobo", np.clip(out, 0, 1), w, h)
suavizar(ob, True)
exportar("lobo.glb")

# ---------- urso (raposa encorpada: mais larga e alta, cauda e orelhas curtas, focinho menor; branco salpicado) ----------
limpar()
ob = importar("Fox.glb")
arm = [o for o in bpy.context.scene.objects if o.type == 'ARMATURE'][0]
grupos = {g.index: g.name for g in ob.vertex_groups}
cauda0 = arm.data.bones["b_Tail01_012"].head_local
cab = arm.data.bones["b_Head_05"].head_local
for v in ob.data.vertices:
    dom = max(v.groups, key=lambda x: x.weight) if v.groups else None
    nome = grupos[dom.group] if dom else ""
    co = v.co
    if "Tail" in nome:                      # cauda curtinha
        co.x, co.y, co.z = cauda0.x + (co.x - cauda0.x) * 0.25, cauda0.y + (co.y - cauda0.y) * 0.2, cauda0.z + (co.z - cauda0.z) * 0.25
        continue
    if "Head" in nome:
        if co.z > cab.z + 9:                # orelhas baixas e redondas
            co.z = cab.z + 9 + (co.z - cab.z - 9) * 0.35
        if co.y < cab.y - 8:                # focinho mais curto
            co.y = cab.y - 8 + (co.y - cab.y + 8) * 0.6
    co.x *= 1.55                             # corpo e patas mais largos
    if co.z > 30 and "Head" not in nome and "Neck" not in nome:
        co.z = 30 + (co.z - 30) * 1.3        # corpo mais alto (cernelha)
tex, img, px, w, h = textura(ob)
L = 0.3 * px[..., 0] + 0.59 * px[..., 1] + 0.11 * px[..., 2]
base = 0.86 + 0.12 * L
m1 = manchas(h, w, 10, 2)
m2 = manchas(h, w, 4, 3)
v = base.copy()
v = np.where(m1 > 0.62, v - (m1 - 0.62) * 1.5, v)            # manchas cinza-claro
v = np.where(m2 > 0.7, v - (m2 - 0.7) * 3.2, v)           # salpicos cinza-escuro
v = np.clip(v, 0.3, 1.0)
out = px.copy(); out[..., 0] = v; out[..., 1] = v; out[..., 2] = v * 1.01
nova_textura(tex, "urso", np.clip(out, 0, 1), w, h)
suavizar(ob, True)
exportar("urso.glb")

def cores(ob, fn):
    ca = ob.data.color_attributes[0]
    n = len(ca.data)
    c = np.empty(n * 4, dtype=np.float32); ca.data.foreach_get("color", c)
    c = fn(c.reshape(n, 4)); ca.data.foreach_set("color", c.astype(np.float32).ravel())

def frente(ob, pontos):
    """Direção (sinal em Y do Blender) em que fica a frente do bicho, a partir de um conjunto de vértices."""
    ys = np.array([ob.data.vertices[i].co.y for i in pontos]); todos = np.array([v.co.y for v in ob.data.vertices])
    return "-Y" if ys.mean() < todos.mean() else "+Y"

# ---------- cavalo (branco; crina e cascos cinza) ----------
limpar()
ob = importar("Horse.glb")
def branco(c):
    L = 0.3 * c[:, 0] + 0.59 * c[:, 1] + 0.11 * c[:, 2]
    out = c.copy()
    g = np.where(L < 0.15, 0.62 + L, 0.9 + 0.08 * np.clip(L, 0, 1))   # crina e cascos prateados
    out[:, 0] = g; out[:, 1] = g; out[:, 2] = g * 1.02
    return out
cores(ob, branco)
zs = np.array([v.co.z for v in ob.data.vertices])
print("FRENTE cavalo", frente(ob, np.where(zs > np.percentile(zs, 95))[0]))
suavizar(ob, False)
exportar("cavalo.glb")

# ---------- fênix (arara com cores de fogo) ----------
limpar()
ob = importar("Parrot.glb")
ca = ob.data.color_attributes[0]
claros = []
if ca.domain == 'POINT':
    for i, d in enumerate(ca.data):
        if sum(d.color[:3]) / 3 > 0.75: claros.append(i)
def fogo(c):
    out = c.copy()
    mx = c[:, :3].max(1); mn = c[:, :3].min(1)
    sat = (mx - mn) / np.maximum(mx, 1e-4)
    azul_verde = (c[:, 2] > c[:, 0]) | (c[:, 1] > c[:, 0])
    out[azul_verde, :3] = [1.0, 0.62, 0.08]                     # asas: ouro/laranja
    vermelho = (~azul_verde) & (sat > 0.4)
    out[vermelho, :3] = [0.95, 0.22, 0.03]                      # corpo: rubro
    claro = (sat < 0.25) & (mx > 0.6)
    out[claro, :3] = [1.0, 0.85, 0.3]                           # rosto e bico: dourado
    return out
cores(ob, fogo)
if claros:
    print("FRENTE fenix", frente(ob, claros))
suavizar(ob, False)
exportar("fenix.glb")
