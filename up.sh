#!/usr/bin/env bash
# FreshBox SpA — levanta toda la infraestructura en AWS con un solo comando.
#
#   git clone https://github.com/carlcuevas/ary1102-freshbox-cloud.git
#   cd ary1102-freshbox-cloud
#   ./up.sh
#
# Opciones:
#   ./up.sh --sin-imagenes   omite el build ARM64 y el push a ECR (si ya están
#                            publicadas las imágenes). Baja de ~18 a ~7 minutos.
#   ./up.sh --rapido         no espera a que los contenedores queden healthy.
#
# Pensado para AWS CloudShell. Despliega los 5 stacks de CloudFormation, publica
# las imágenes Docker en Amazon ECR, conecta el Auto Scaling Group al balanceador
# y deja el catálogo respondiendo por el DNS público.

set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGION="${AWS_REGION:-us-east-1}"
export AWS_REGION="$REGION"
INICIO=$(date +%s)
ARGS_DEPLOY=()
ESPERAR="--esperar"

for a in "$@"; do
  case "$a" in
    --sin-imagenes) ARGS_DEPLOY+=(--sin-imagenes) ;;
    --rapido)       ESPERAR="" ;;
    -h|--help)      awk 'NR>1 && /^#/ {sub(/^# ?/,""); print; next} NR>1 {exit}' \
                      "${BASH_SOURCE[0]}"; exit 0 ;;
    *)              echo "Opción desconocida: $a (usa --help)"; exit 1 ;;
  esac
done

linea() { printf '%s\n' "────────────────────────────────────────────────────────────"; }
morir() { echo; echo "✗ $*" >&2; exit 1; }

transcurrido() {
  local s=$(( $(date +%s) - INICIO ))
  printf '%dm %02ds' $((s / 60)) $((s % 60))
}

linea
echo " FreshBox SpA · Arquitectura Cloud EP1 · ARY1102"
echo " Despliegue completo en AWS — región $REGION"
linea

# ── Comprobaciones previas ────────────────────────────────────────────────────
echo
echo "Comprobando requisitos…"

command -v aws >/dev/null || morir "no se encontró el AWS CLI."
CUENTA="$(aws sts get-caller-identity --query Account --output text 2>/dev/null)" \
  || morir "el AWS CLI no está autenticado. En AWS Academy: abre el Learner Lab, espera el punto verde y usa CloudShell."
echo "  ✓ AWS CLI autenticado · cuenta $CUENTA"

if [[ " ${ARGS_DEPLOY[*]:-} " != *"--sin-imagenes"* ]]; then
  if ! command -v docker >/dev/null; then
    echo "  ! Docker no está disponible: se omitirá el build de imágenes."
    echo "    Si las imágenes ya están en ECR esto es correcto; si no, el despliegue"
    echo "    quedará sin contenedores."
    ARGS_DEPLOY+=(--sin-imagenes)
  else
    docker info >/dev/null 2>&1 || morir "Docker está instalado pero no responde."
    echo "  ✓ Docker operativo"
  fi
fi

[[ -x "$RAIZ/infra/deploy.sh" ]] || morir "falta infra/deploy.sh (¿clonaste el repositorio completo?)"
echo "  ✓ Plantillas y scripts presentes"

# ── Despliegue ────────────────────────────────────────────────────────────────
echo
linea
echo " Desplegando. Toma entre 7 y 20 minutos según si hay que construir imágenes."
echo " Puedes dejarlo corriendo: no requiere interacción."
linea

"$RAIZ/infra/deploy.sh" "${ARGS_DEPLOY[@]:-}" || morir "el despliegue falló tras $(transcurrido). Revisa el mensaje anterior."

# ── Verificación ──────────────────────────────────────────────────────────────
echo
linea
echo " Verificando el despliegue  ·  $(transcurrido)"
linea
echo
"$RAIZ/infra/verify.sh" $ESPERAR
RESULTADO=$?

# ── Cierre ────────────────────────────────────────────────────────────────────
DNS="$(aws elbv2 describe-load-balancers --names freshbox-alb \
       --query 'LoadBalancers[0].DNSName' --output text 2>/dev/null)"

echo
linea
if [[ $RESULTADO -eq 0 ]]; then
  echo " ✓ Infraestructura lista en $(transcurrido)"
else
  echo " ! Infraestructura desplegada en $(transcurrido), con observaciones arriba"
fi
linea
echo
echo "  Frontend        http://$DNS/"
echo "  API             http://$DNS/api/products"
echo
echo "  Demostración    ./infra/demo.sh todo"
echo "  Revisar estado  ./infra/verify.sh"
echo "  Eliminar todo   ./infra/teardown.sh"
echo
[[ $RESULTADO -eq 0 ]] || echo "  Si los targets aún no están healthy, espera 2 min y corre ./infra/verify.sh"
exit $RESULTADO
