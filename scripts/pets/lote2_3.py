"""Lotes 2 e 3 (Sketchfab, CC-BY 4.0): armas e ferramentas normalizadas para o jogo.
Cada peça sai com o comprimento 1 no eixo Y do glTF (Z do Blender), centrada; cajados e ferramentas com a ponta pesada
(cristal/cabeça) para cima; espadas com o cabo para baixo. Malhas pesadas são simplificadas e texturas vão a 512.
Uso: python3.11 lote2_3.py <pasta com lote2/ e lote3/> <pasta models/ do jogo>
"""
import bpy, bmesh, sys, os, math
import numpy as np
from mathutils import Vector, Matrix

SRC, DST = sys.argv[1], sys.argv[2]

def abrir(arq, manter=None):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, arq))
    malhas = [o for o in bpy.context.scene.objects if o.type == 'MESH' and not o.name.startswith("Icosphere")]
    for o in malhas:
        mw = o.matrix_world.copy(); o.parent = None; o.matrix_world = mw
    if manter is not None:
        for o in list(malhas):
            if not manter(o):
                bpy.data.objects.remove(o, do_unlink=True); malhas.remove(o)
    for o in [o for o in bpy.context.scene.objects if o not in malhas]:
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.object.select_all(action='DESELECT')
    for o in malhas: o.select_set(True)
    bpy.context.view_layer.objects.active = malhas[0]
    if len(malhas) > 1: bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return ob

def pts(ob):
    a = np.empty(len(ob.data.vertices) * 3); ob.data.vertices.foreach_get("co", a); return a.reshape(-1, 3)

def girar(ob, R):
    for v in ob.data.vertices: v.co = R @ v.co

def normalizar(ob, pesado_em_cima=True, inverter=False, tris_max=12000):
    P = pts(ob); c = P.mean(0); Q = P - c
    w, V = np.linalg.eigh(np.cov(Q.T)); eixo = Vector(V[:, np.argmax(w)])
    girar(ob, eixo.rotation_difference(Vector((0, 0, 1))).to_matrix())
    P = pts(ob); z = P[:, 2]; lo, hi = z.min(), z.max(); L = hi - lo
    r = np.hypot(P[:, 0] - np.median(P[:, 0]), P[:, 1] - np.median(P[:, 1]))
    baixo = r[z < lo + 0.3 * L].max(); cima = r[z > hi - 0.3 * L].max()
    vira = (cima < baixo) if pesado_em_cima else (cima > baixo)
    if inverter: vira = not vira
    if vira: girar(ob, Matrix.Rotation(math.pi, 3, 'X'))
    P = pts(ob); mn, mx = P.min(0), P.max(0); c = Vector((mn + mx) / 2)
    for v in ob.data.vertices: v.co = (v.co - c) / (mx[2] - mn[2])
    tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
    if tris > tris_max:
        m = ob.modifiers.new("dec", 'DECIMATE'); m.ratio = tris_max / tris
        bpy.ops.object.modifier_apply(modifier="dec")
    for img in bpy.data.images:
        if img.size[0] > 512: img.scale(512, max(1, 512 * img.size[1] // img.size[0])); img.pack()
    print("normalizado: tris", tris, "->", sum(len(p.vertices) - 2 for p in ob.data.polygons))

def exportar(nome):
    bpy.ops.export_scene.gltf(filepath=os.path.join(DST, nome), export_format='GLB', export_yup=True)
    print("EXPORTADO", nome)

# cajados dos magos (cristal para cima)
normalizar(abrir("lote2/cetrocajado_magico_-_scepterwand.glb"), True); exportar("armas/Cetro_Magico.glb")
normalizar(abrir("lote3/cajado_1.glb"), True); exportar("armas/Cajado_Cristal.glb")
# espadas (cabo para baixo: a guarda larga fica perto do cabo)
normalizar(abrir("lote3/espada_runica_desgastada__runed_sword_3d.glb"), False); exportar("armas/Espada_Runica.glb")
normalizar(abrir("lote2/espada_excalibur.glb", lambda o: "piedra" not in o.data.materials[0].name), False); exportar("armas/Excalibur.glb")
normalizar(abrir("lote2/dark_cursed_sword.glb"), False, inverter=True); exportar("armas/Espada_Maldita.glb")   # a lâmina larga enganava a regra
# ferramentas dos aldeões: cada ferramenta do pacote é um grupo de peças na mesma posição (x)
def grupo(x):
    return lambda o: abs(o.matrix_world.translation.x - x) < 0.3 and o.data.materials and o.data.materials[0].name in ("ToolsWoodHandle", "IronTools", "ReinforcerRope")
normalizar(abrir("lote2/survivalmedieval_asset_tools.glb", grupo(-2.8)), True); exportar("armas/Picareta.glb")
normalizar(abrir("lote2/survivalmedieval_asset_tools.glb", grupo(-1.58)), True); exportar("armas/Machado_Lenhador.glb")
# Excalibur na pedra (enfeite do Salão do Rei): pé no chão, altura 1
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, "lote2/espada_excalibur.glb"))
for img in bpy.data.images:
    if img.size[0] > 512: img.scale(512, max(1, 512 * img.size[1] // img.size[0])); img.pack()
exportar("Excalibur_Pedra.glb")
