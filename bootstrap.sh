#!/usr/bin/env bash
# FreshBox SpA — clona el repositorio y despliega la infraestructura completa.
#
# Desde AWS CloudShell, con el laboratorio activo, una sola línea:
#
#   curl -sL https://raw.githubusercontent.com/carlcuevas/ary1102-freshbox-cloud/main/bootstrap.sh | bash
#
# Para omitir el build de imágenes (si ya están en ECR), pasa la opción así:
#
#   curl -sL .../bootstrap.sh | bash -s -- --sin-imagenes
#
# Si el repositorio ya está clonado, lo actualiza en lugar de volver a clonarlo.

set -uo pipefail

REPO="https://github.com/carlcuevas/ary1102-freshbox-cloud.git"
DIR="ary1102-freshbox-cloud"

echo "── FreshBox SpA · Arquitectura Cloud EP1 ──"

command -v git >/dev/null || { echo "ERROR: falta git" >&2; exit 1; }

if [[ -d "$DIR/.git" ]]; then
  echo "   El repositorio ya está clonado; actualizando…"
  git -C "$DIR" pull --ff-only --quiet || echo "   (no se pudo actualizar; se usa la copia local)"
else
  echo "   Clonando el repositorio…"
  git clone --quiet "$REPO" "$DIR" || { echo "ERROR: no se pudo clonar" >&2; exit 1; }
fi

cd "$DIR" || exit 1
chmod +x up.sh infra/*.sh 2>/dev/null

echo "   Listo. Iniciando el despliegue."
exec ./up.sh "$@"
