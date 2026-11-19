"""Lote 1 de modelos do Sketchfab (todos CC-BY 4.0), ajustados no Blender para o jogo.
Uso: python3.11 lote1.py <pasta com os .glb> <pasta models/ do jogo>
  arco.glb (Francisco Fischer Pioner)  -> armas/Arco.glb   (só o arco: tira aljava e flechas; texturas 512)
  arrow.glb (Gwappa)                   -> armas/Flecha.glb (0,9 m, ponta em +X; texturas 256)
  barrel__-_low_poly.glb (Badders)     -> Barrel.glb       (substitui o barril antigo; base no chão; texturas 512)
"""
import bpy, bmesh, sys, os, math
from mathutils import Vector, Matrix

SRC, DST = sys.argv[1], sys.argv[2]

def abrir(nome):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, nome))
    for o in list(bpy.context.scene.objects):
        if o.name.startswith("Icosphere"):
            bpy.data.objects.remove(o, do_unlink=True)
    malhas = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    # aplica as transformações e junta tudo numa malha só
    for o in malhas:
        mw = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = mw
    for o in [o for o in bpy.context.scene.objects if o.type != 'MESH']:
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.object.select_all(action='DESELECT')
    for o in malhas:
        o.select_set(True)
    bpy.context.view_layer.objects.active = malhas[0]
    if len(malhas) > 1:
        bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return ob

def texturas(lado):
    for img in bpy.data.images:
        if img.size[0] > lado:
            img.scale(lado, lado * img.size[1] // img.size[0])
            img.pack()

def centralizar(ob, base_no_chao=False):
    pts = [v.co for v in ob.data.vertices]
    mn = Vector([min(p[k] for p in pts) for k in range(3)]); mx = Vector([max(p[k] for p in pts) for k in range(3)])
    c = (mn + mx) / 2
    if base_no_chao:
        c.z = mn.z
    for v in ob.data.vertices:
        v.co -= c
    return mx - mn

def escalar(ob, fator):
    for v in ob.data.vertices:
        v.co *= fator

def exportar(caminho):
    bpy.ops.export_scene.gltf(filepath=caminho, export_format='GLB', export_yup=True)
    print("EXPORTADO", caminho)

# ---------- arco: só o arco (corpo, enfeites e corda); aljava, flechas na aljava e flecha solta saem ----------
ob = abrir("arco.glb")
bm = bmesh.new(); bm.from_mesh(ob.data); bm.verts.ensure_lookup_table()
visto = set(); fora = []
for v in bm.verts:
    if v.index in visto:
        continue
    pilha = [v]; ilha = []
    while pilha:
        x = pilha.pop()
        if x.index in visto:
            continue
        visto.add(x.index); ilha.append(x)
        for e in x.link_edges:
            pilha.append(e.other_vert(x))
    ys = [x.co.y for x in ilha]
    if max(abs(min(ys)), abs(max(ys))) > 40.0:     # o arco fica no plano |y| < 40; o resto está fora dele
        fora += ilha
bmesh.ops.delete(bm, geom=fora, context='VERTS')
bm.to_mesh(ob.data); bm.free()
tam = centralizar(ob)
escalar(ob, 1.0 / max(tam))                        # comprimento 1 (o jogo ajusta para 1,3 m)
texturas(512)
print("arco tamanho", tuple(round(t, 1) for t in tam))
exportar(os.path.join(DST, "armas", "Arco.glb"))

# ---------- flecha: 0,9 m, ponta em +X (o jogo gira o modelo 90° para a ponta ir para -Z) ----------
ob = abrir("arrow.glb")
tam = centralizar(ob)
escalar(ob, 0.9 / max(tam))
texturas(256)
exportar(os.path.join(DST, "armas", "Flecha.glb"))

# ---------- barril: base no chão ----------
ob = abrir("barrel__-_low_poly.glb")
tam = centralizar(ob, True)
escalar(ob, 1.0 / tam.z)                           # 1 m de altura (o jogo ajusta)
texturas(512)
exportar(os.path.join(DST, "Barrel.glb"))
