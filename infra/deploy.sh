#!/usr/bin/env bash
# FreshBox SpA — despliegue completo de la infraestructura (EP1 ARY1102)
#
# Uso:
#   ./deploy.sh                 despliegue completo (~15-20 min)
#   ./deploy.sh --sin-imagenes  omite el build y push a ECR (~6-8 min)
#
# Requiere AWS CLI y Docker autenticados. Pensado para AWS CloudShell.
# Los stacks que ya existen se omiten, así que el script se puede reejecutar.

set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODIGO="$(cd "$AQUI/../codigo" && pwd)"
SALTAR_IMAGENES=0
[[ "${1:-}" == "--sin-imagenes" ]] && SALTAR_IMAGENES=1

SERVICIOS=(get-products create-product update-product delete-product)
REPOS=(freshbox-frontend freshbox-get-products freshbox-create-product
       freshbox-update-product freshbox-delete-product)

paso()  { echo; echo "── $* ──"; }
info()  { echo "   $*"; }
morir() { echo "ERROR: $*" >&2; exit 1; }

existe_stack() {
  aws cloudformation describe-stacks --stack-name "$1" --region "$REGION" >/dev/null 2>&1
}

crear_stack() {
  local nombre="$1" plantilla="$2"
  if existe_stack "$nombre"; then
    info "$nombre ya existe — se omite"
    return 0
  fi
  info "creando $nombre …"
  aws cloudformation create-stack --region "$REGION" \
    --stack-name "$nombre" --template-body "file://$AQUI/$plantilla" >/dev/null
  aws cloudformation wait stack-create-complete --region "$REGION" --stack-name "$nombre" \
    || morir "$nombre falló. Revisa: aws cloudformation describe-stack-events --stack-name $nombre"
  info "$nombre listo"
}

salida() {
  aws cloudformation describe-stacks --region "$REGION" --stack-name "$1" \
    --query "Stacks[0].Outputs[?OutputKey=='$2'].OutputValue" --output text
}

command -v aws >/dev/null || morir "falta el AWS CLI"
CUENTA="$(aws sts get-caller-identity --query Account --output text)" \
  || morir "el AWS CLI no está autenticado"
echo "Cuenta $CUENTA · región $REGION"

# ── 1. Red ────────────────────────────────────────────────────────────────────
paso "1/6  Red: VPC, 6 subredes, IGW, NAT Gateway y route tables"
crear_stack freshbox-red 01-red.yaml

# ── 2. Security Groups ────────────────────────────────────────────────────────
paso "2/6  Security Groups encadenados por capa"
crear_stack freshbox-sg 02-security-groups.yaml

# ── 3. Imágenes en ECR ────────────────────────────────────────────────────────
paso "3/6  Imágenes Docker ARM64 en Amazon ECR"
if [[ $SALTAR_IMAGENES -eq 1 ]]; then
  info "omitido por --sin-imagenes"
else
  command -v docker >/dev/null || morir "falta Docker (necesario para construir las imágenes)"
  ECR="$CUENTA.dkr.ecr.$REGION.amazonaws.com"

  info "registrando emuladores QEMU (las instancias son Graviton/ARM64)"
  docker run --privileged --rm tonistiigi/binfmt --install all >/dev/null 2>&1 || true
  docker buildx create --name freshbox-builder --driver docker-container --use >/dev/null 2>&1 \
    || docker buildx use freshbox-builder
  docker buildx inspect --bootstrap >/dev/null

  info "autenticando contra ECR"
  aws ecr get-login-password --region "$REGION" \
    | docker login --username AWS --password-stdin "$ECR" >/dev/null

  for r in "${REPOS[@]}"; do
    aws ecr create-repository --repository-name "$r" --region "$REGION" >/dev/null 2>&1 \
      && info "repositorio $r creado" || info "repositorio $r ya existe"
  done

  info "construyendo freshbox-frontend (arm64)"
  docker buildx build --platform linux/arm64 --load \
    -t "$ECR/freshbox-frontend:latest" "$CODIGO/microservicioFrontend" >/dev/null
  docker push "$ECR/freshbox-frontend:latest" >/dev/null
  info "freshbox-frontend publicado"

  for s in "${SERVICIOS[@]}"; do
    info "construyendo freshbox-$s (arm64)"
    docker buildx build --platform linux/arm64 --load \
      -t "$ECR/freshbox-$s:latest" "$CODIGO/microserviciosBackend/$s" >/dev/null
    docker push "$ECR/freshbox-$s:latest" >/dev/null
    info "freshbox-$s publicado"
  done
fi

# ── 4. Cómputo ────────────────────────────────────────────────────────────────
paso "4/6  Cómputo: EC2 MariaDB + Launch Template + Auto Scaling Group"
crear_stack freshbox-compute 03-compute.yaml

# ── 5. Balanceador y conexión con el ASG ──────────────────────────────────────
paso "5/6  Application Load Balancer y Target Group"
crear_stack freshbox-alb 04-alb.yaml

TG="$(salida freshbox-alb TargetGroupArn)"
DNS="$(salida freshbox-alb AlbDnsName)"
[[ -n "$TG" && "$TG" != "None" ]] || morir "no se obtuvo el ARN del Target Group"

info "conectando el Auto Scaling Group al Target Group"
aws cloudformation update-stack --region "$REGION" \
  --stack-name freshbox-compute --template-body "file://$AQUI/03-compute.yaml" \
  --parameters \
    ParameterKey=TargetGroupArn,ParameterValue="$TG" \
    ParameterKey=NetworkStackName,UsePreviousValue=true \
    ParameterKey=SecurityGroupsStackName,UsePreviousValue=true \
    ParameterKey=LatestAmiId,UsePreviousValue=true \
    ParameterKey=InstanceType,UsePreviousValue=true \
    ParameterKey=DBName,UsePreviousValue=true \
    ParameterKey=DBUser,UsePreviousValue=true \
    ParameterKey=DBPassword,UsePreviousValue=true >/dev/null 2>&1 \
  && aws cloudformation wait stack-update-complete --region "$REGION" --stack-name freshbox-compute \
  || info "sin cambios que aplicar en freshbox-compute"

# Un update-stack no registra las instancias que ya estaban corriendo.
info "registrando las instancias del grupo en el Target Group"
for i in $(aws autoscaling describe-auto-scaling-groups --region "$REGION" \
             --auto-scaling-group-names freshbox-asg-app \
             --query 'AutoScalingGroups[0].Instances[].InstanceId' --output text); do
  aws elbv2 register-targets --region "$REGION" --target-group-arn "$TG" --targets "Id=$i" >/dev/null
  info "registrado $i"
done

# ── 6. Respaldo ───────────────────────────────────────────────────────────────
paso "6/6  AWS Backup: vault, plan diario y asignación del recurso"
crear_stack freshbox-backup 05-backup.yaml

# ── Cierre ────────────────────────────────────────────────────────────────────
paso "Despliegue completo"
echo "   Frontend : http://$DNS/"
echo "   API      : http://$DNS/api/products"
echo
echo "   Los contenedores tardan 2-3 min en quedar arriba. Para comprobarlo:"
echo "     ./verify.sh"
