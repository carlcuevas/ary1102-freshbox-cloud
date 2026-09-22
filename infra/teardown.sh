#!/usr/bin/env bash
# FreshBox SpA — eliminación de la infraestructura (EP1 ARY1102)
#
# Uso:
#   ./teardown.sh          pide confirmación y elimina los 5 stacks
#   ./teardown.sh --si     sin confirmación
#
# Elimina en orden inverso al despliegue. Los repositorios de ECR y sus imágenes
# NO se eliminan: no los crea CloudFormation y conviene conservarlos para no
# repetir el build ARM64, que es el paso más lento.

set -uo pipefail
REGION="${AWS_REGION:-us-east-1}"

if [[ "${1:-}" != "--si" ]]; then
  echo "Se eliminarán los stacks: freshbox-backup, freshbox-alb, freshbox-compute,"
  echo "freshbox-sg y freshbox-red en la región $REGION."
  read -r -p "¿Continuar? (escribe 'si'): " r
  [[ "$r" == "si" ]] || { echo "Cancelado."; exit 1; }
fi

for s in freshbox-backup freshbox-alb freshbox-compute freshbox-sg freshbox-red; do
  if ! aws cloudformation describe-stacks --region "$REGION" --stack-name "$s" >/dev/null 2>&1; then
    echo "── $s no existe, se omite"
    continue
  fi
  echo "── eliminando $s …"
  aws cloudformation delete-stack --region "$REGION" --stack-name "$s"
  aws cloudformation wait stack-delete-complete --region "$REGION" --stack-name "$s" \
    && echo "   $s eliminado" \
    || echo "   ATENCIÓN: $s no terminó de eliminarse; revisa la consola"
done

echo
echo "Listo. Los repositorios de ECR se conservaron. Para eliminarlos también:"
echo "  for r in freshbox-frontend freshbox-get-products freshbox-create-product \\"
echo "           freshbox-update-product freshbox-delete-product; do"
echo "    aws ecr delete-repository --repository-name \$r --force --region $REGION"
echo "  done"
