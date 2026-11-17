#!/usr/bin/env bash
# Hook PostToolUse (Edit|Write): confere a sintaxe de arquivos .gd com o gdparse (gdtoolkit).
# Se houver erro, sai com código 2 e o texto volta para o Claude corrigir na hora.
f=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)
case "$f" in *.gd) ;; *) exit 0 ;; esac
command -v gdparse >/dev/null 2>&1 || exit 0   # sem gdtoolkit instalado: não faz nada
[ -f "$f" ] || exit 0
out=$(gdparse "$f" 2>&1) || { echo "Erro de sintaxe em $f:" >&2; echo "$out" | tail -8 >&2; exit 2; }
exit 0
