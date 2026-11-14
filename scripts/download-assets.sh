#!/usr/bin/env bash
# Baixa os modelos 3D (glTF) direto de um repositório público do GitHub para public/models/quaternius/.
# Origem: Quaternius "Universal Base Characters" (CC0 1.0) – espelhado em Deepak-negi11/Clario.
# Uso: npm run assets
set -euo pipefail

BASE="${ASSET_BASE_URL:-https://raw.githubusercontent.com/Deepak-negi11/Clario/main/apps/web/public/assets/3d/quaternius}"
DEST="$(cd "$(dirname "$0")/.." && pwd)/public/models/quaternius"
mkdir -p "$DEST"

FILES=(
  Superhero_Male.gltf   Superhero_Male.bin   T_Male_Light.jpg   T_Hair_1.jpg
  Superhero_Female.gltf Superhero_Female.bin T_Female_Light.jpg T_Hair_2.jpg
  T_Eye_Brown.png
)

for f in "${FILES[@]}"; do
  if [[ -s "$DEST/$f" && "${FORCE:-0}" != "1" ]]; then
    echo "ok   $f (já existe)"; continue
  fi
  echo "baixando $f"
  curl -fsSL --retry 3 -o "$DEST/$f" "$BASE/$f"
done
echo "Pronto: $DEST"
