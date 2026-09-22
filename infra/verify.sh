#!/usr/bin/env bash
# FreshBox SpA — verificación del despliegue (EP1 ARY1102)
#
# Uso:
#   ./verify.sh            comprueba el estado y sale con código 0 si todo está arriba
#   ./verify.sh --esperar  reintenta hasta 5 min mientras los contenedores levantan
#
# Comprueba, en orden: los 5 stacks, la salud de los targets y que el catálogo
# responda a través del balanceador.

set -uo pipefail
REGION="${AWS_REGION:-us-east-1}"
ESPERAR=0
[[ "${1:-}" == "--esperar" ]] && ESPERAR=1

ok()    { echo "  [ok]    $*"; }
falla() { echo "  [FALLA] $*"; PROBLEMAS=$((PROBLEMAS + 1)); }
PROBLEMAS=0

echo "── Stacks ──"
for s in freshbox-red freshbox-sg freshbox-compute freshbox-alb freshbox-backup; do
  estado="$(aws cloudformation describe-stacks --region "$REGION" --stack-name "$s" \
            --query 'Stacks[0].StackStatus' --output text 2>/dev/null)"
  case "$estado" in
    CREATE_COMPLETE|UPDATE_COMPLETE) ok "$s · $estado" ;;
    "")                              falla "$s · no existe" ;;
    *)                               falla "$s · $estado" ;;
  esac
done

DNS="$(aws elbv2 describe-load-balancers --region "$REGION" --names freshbox-alb \
       --query 'LoadBalancers[0].DNSName' --output text 2>/dev/null)"
TG="$(aws elbv2 describe-target-groups --region "$REGION" --names freshbox-tg-app \
      --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)"

if [[ -z "$TG" || "$TG" == "None" ]]; then
  echo; falla "no existe el Target Group freshbox-tg-app"
  exit 1
fi

intento=0
while :; do
  echo; echo "── Targets ──"
  aws elbv2 describe-target-health --region "$REGION" --target-group-arn "$TG" \
    --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State]' --output table
  sanos="$(aws elbv2 describe-target-health --region "$REGION" --target-group-arn "$TG" \
           --query 'length(TargetHealthDescriptions[?TargetHealth.State==`healthy`])' --output text)"

  echo "── Catálogo a través del balanceador ──"
  http="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://$DNS/api/products")"

  if [[ "$sanos" -ge 2 && "$http" == "200" ]]; then
    ok "$sanos targets healthy"
    ok "http://$DNS/api/products responde 200"
    productos="$(curl -s --max-time 10 "http://$DNS/api/products" \
                 | python3 -c 'import sys,json; print(len(json.load(sys.stdin)))' 2>/dev/null)"
    [[ -n "$productos" ]] && ok "$productos productos en el catálogo"
    break
  fi

  [[ "$sanos" -ge 2 ]] || falla "solo $sanos targets healthy (se esperan 2)"
  [[ "$http" == "200" ]] || falla "el catálogo respondió HTTP $http"

  if [[ $ESPERAR -eq 1 && $intento -lt 5 ]]; then
    intento=$((intento + 1))
    PROBLEMAS=0
    echo; echo "   reintento $intento/5 en 60 s (los contenedores tardan 2-3 min)…"
    sleep 60
    continue
  fi
  break
done

echo
echo "── Resumen ──"
echo "   Frontend : http://$DNS/"
echo "   API      : http://$DNS/api/products"
if [[ $PROBLEMAS -eq 0 ]]; then
  echo "   Todo arriba. Listo para la demo."
  exit 0
fi
echo "   $PROBLEMAS problema(s). Si el despliegue es reciente, prueba: ./verify.sh --esperar"
exit 1
