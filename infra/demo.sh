#!/usr/bin/env bash
# FreshBox SpA — recorrido de demostración en vivo (EP1 ARY1102)
#
# Uso:
#   ./demo.sh red            aislamiento de red: VPC, subredes, rutas, sin IP pública
#   ./demo.sh seguridad      Security Groups encadenados, sin SSH, cifrado en reposo
#   ./demo.sh ha             alta disponibilidad: targets, Auto Scaling Group
#   ./demo.sh contenedores   Amazon ECR y los 5 contenedores corriendo
#   ./demo.sh crud           CRUD completo a través del balanceador
#   ./demo.sh backup         plan de respaldo diario
#   ./demo.sh todo           los seis bloques, uno tras otro
#
# Cada comando se imprime antes de ejecutarse, para que se vea qué se está
# consultando. Todo se filtra por NOMBRE de recurso, así que funciona igual
# después de un redespliegue, cuando los identificadores cambian.

set -uo pipefail
REGION="${AWS_REGION:-us-east-1}"
BLOQUE="${1:-}"

titulo() { echo; echo "═══ $* ═══"; echo; }
correr() { echo "\$ $*"; echo; eval "$@"; echo; }

VPC="$(aws ec2 describe-vpcs --region "$REGION" --filters Name=tag:Name,Values=freshbox-vpc \
       --query 'Vpcs[0].VpcId' --output text 2>/dev/null)"
DNS="$(aws elbv2 describe-load-balancers --region "$REGION" --names freshbox-alb \
       --query 'LoadBalancers[0].DNSName' --output text 2>/dev/null)"
TG="$(aws elbv2 describe-target-groups --region "$REGION" --names freshbox-tg-app \
      --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)"

bloque_red() {
  titulo "1 · Aislamiento de red"
  echo "La VPC del proyecto, su rango y su estado:"
  correr "aws ec2 describe-vpcs --filters Name=tag:Name,Values=freshbox-vpc \
    --query 'Vpcs[0].[VpcId,CidrBlock,State]' --output table"

  echo "Las 6 subredes /26, dos por capa, repartidas en dos zonas de disponibilidad:"
  correr "aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC \
    --query 'sort_by(Subnets,&AvailabilityZone)[].[Tags[?Key==\`Name\`].Value|[0],CidrBlock,AvailabilityZone]' \
    --output table"

  echo "Route table privada: cuántas subredes tiene asociadas y por dónde sale a Internet (NAT):"
  correr "aws ec2 describe-route-tables --filters Name=tag:Name,Values=freshbox-rt-private \
    --query 'RouteTables[0].[length(Associations),Routes[?DestinationCidrBlock==\`0.0.0.0/0\`].NatGatewayId|[0]]' \
    --output table"

  echo "Route table pública: sale directo por el Internet Gateway:"
  correr "aws ec2 describe-route-tables --filters Name=tag:Name,Values=freshbox-rt-public \
    --query 'RouteTables[0].[length(Associations),Routes[?DestinationCidrBlock==\`0.0.0.0/0\`].GatewayId|[0]]' \
    --output table"

  echo "Y la prueba del aislamiento: la columna de IP pública está vacía en todas las instancias."
  correr "aws ec2 describe-instances \
    --filters Name=vpc-id,Values=$VPC Name=instance-state-name,Values=running \
    --query 'Reservations[].Instances[].[Tags[?Key==\`Name\`].Value|[0],InstanceType,PrivateIpAddress,PublicIpAddress,Placement.AvailabilityZone]' \
    --output table"
}

bloque_seguridad() {
  titulo "2 · Seguridad perimetral encadenada"
  echo "Reglas de entrada del SG de la capa App. La 3ª columna es el SG de ORIGEN;"
  echo "la 4ª sería un rango de IP, y viene vacía a propósito:"
  correr "aws ec2 describe-security-groups --filters Name=tag:Name,Values=freshbox-sg-app \
    --query 'SecurityGroups[0].IpPermissions[].[FromPort,IpProtocol,UserIdGroupPairs[0].GroupId,IpRanges[0].CidrIp]' \
    --output table"

  echo "La capa de datos acepta una sola regla: 3306 desde el SG de App:"
  correr "aws ec2 describe-security-groups --filters Name=tag:Name,Values=freshbox-sg-bd \
    --query 'SecurityGroups[0].IpPermissions[].[FromPort,UserIdGroupPairs[0].GroupId]' --output table"

  echo "¿Existe alguna regla al puerto 22 en toda la VPC? Sin salida = no hay SSH en ninguna parte:"
  correr "aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC \
    --query 'SecurityGroups[].IpPermissions[?FromPort==\`22\`]' --output text"

  echo "Cifrado en reposo de los volúmenes de App y Data:"
  correr "aws ec2 describe-volumes --volume-ids \
    \$(aws ec2 describe-instances --filters Name=vpc-id,Values=$VPC \
      --query 'Reservations[].Instances[].BlockDeviceMappings[].Ebs.VolumeId' --output text) \
    --query 'Volumes[].[VolumeId,Encrypted,VolumeType,Size]' --output table"
}

bloque_ha() {
  titulo "3 · Alta disponibilidad"
  echo "Salud de los targets según el balanceador:"
  correr "aws elbv2 describe-target-health --target-group-arn $TG \
    --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State]' --output table"

  echo "Las instancias del grupo y su zona de disponibilidad:"
  correr "aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names freshbox-asg-app \
    --query 'AutoScalingGroups[0].Instances[].[InstanceId,AvailabilityZone,HealthStatus,LifecycleState]' \
    --output table"

  echo "Rango de escalado y tipo de health check (EC2, declarado como brecha en el informe):"
  correr "aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names freshbox-asg-app \
    --query 'AutoScalingGroups[0].[MinSize,DesiredCapacity,MaxSize,HealthCheckType]' --output table"

  echo "Historial del grupo: acá queda el registro del auto-healing:"
  correr "aws autoscaling describe-scaling-activities --auto-scaling-group-name freshbox-asg-app \
    --max-items 5 --query 'Activities[].[StartTime,StatusCode,Cause]' --output text | cut -c1-150"
}

bloque_contenedores() {
  titulo "4 · Contenedores e imágenes"
  echo "Los 5 repositorios privados de imágenes:"
  correr "aws ecr describe-repositories --query 'repositories[].repositoryName' --output table"

  echo "Imágenes publicadas en uno de ellos, con su fecha de push:"
  correr "aws ecr describe-images --repository-name freshbox-get-products \
    --query 'imageDetails[].[imageTags[0],imagePushedAt]' --output table"

  local inst
  inst="$(aws autoscaling describe-auto-scaling-groups --region "$REGION" \
          --auto-scaling-group-names freshbox-asg-app \
          --query 'AutoScalingGroups[0].Instances[0].InstanceId' --output text)"
  echo "Los 5 contenedores corriendo en $inst, consultados por Systems Manager"
  echo "(sin SSH, sin llaves y sin el puerto 22 abierto):"
  local cmd
  cmd="$(aws ssm send-command --region "$REGION" --instance-ids "$inst" \
        --document-name AWS-RunShellScript \
        --parameters 'commands=["docker ps --format \"{{.Names}} :: {{.Status}}\""]' \
        --query 'Command.CommandId' --output text 2>/dev/null)"
  if [[ -n "$cmd" ]]; then
    sleep 6
    aws ssm list-command-invocations --region "$REGION" --command-id "$cmd" --details \
      --query 'CommandInvocations[0].CommandPlugins[0].Output' --output text
  else
    echo "   (no se pudo enviar el comando; entra a mano con:"
    echo "    aws ssm start-session --target $inst   →   sudo docker ps)"
  fi
  echo
}

bloque_crud() {
  titulo "5 · CRUD de extremo a extremo por el balanceador"
  echo "Todo entra por http://$DNS/api/products sobre el puerto 80."
  echo "nginx, dentro de la instancia, enruta al microservicio según el método HTTP."
  echo

  echo "GET — listado inicial:"
  correr "curl -s http://$DNS/api/products \
    | python3 -c 'import sys,json; d=json.load(sys.stdin); print(len(d),\"productos\"); [print(\" \",p[\"id\"],p[\"nombre\"]) for p in d]'"

  echo "POST — crear un producto (nginx lo manda a create-product, puerto 3002):"
  local nuevo id
  nuevo="$(curl -s -X POST "http://$DNS/api/products" -H 'Content-Type: application/json' \
    -d '{"nombre":"Quinoa organica 500g","descripcion":"Quinoa premium","precio":4990,"stock":80,"categoria":"Granos"}')"
  echo "$nuevo" | python3 -m json.tool 2>/dev/null || echo "$nuevo"
  id="$(echo "$nuevo" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))' 2>/dev/null)"
  echo

  if [[ -n "$id" ]]; then
    echo "PUT — editar el producto $id (va a update-product, puerto 3003):"
    correr "curl -s -X PUT http://$DNS/api/products/$id -H 'Content-Type: application/json' \
      -d '{\"nombre\":\"Quinoa organica 1kg\",\"descripcion\":\"Quinoa premium\",\"precio\":8990,\"stock\":50,\"categoria\":\"Granos\"}' \
      | python3 -m json.tool"

    echo "DELETE — eliminarlo (va a delete-product, puerto 3004):"
    correr "curl -s -X DELETE http://$DNS/api/products/$id | python3 -m json.tool"
  fi

  echo "GET — listado final: vuelve al estado original:"
  correr "curl -s http://$DNS/api/products \
    | python3 -c 'import sys,json; print(len(json.load(sys.stdin)),\"productos\")'"
}

bloque_backup() {
  titulo "6 · Respaldo automatizado"
  local plan
  plan="$(aws backup list-backup-plans --region "$REGION" \
         --query \"BackupPlansList[?BackupPlanName=='freshbox-backup-plan-mysql'].BackupPlanId|[0]\" \
         --output text 2>/dev/null)"
  echo "Regla del plan de respaldo: frecuencia, retención y vault de destino:"
  correr "aws backup get-backup-plan --backup-plan-id $plan \
    --query 'BackupPlan.Rules[].[RuleName,ScheduleExpression,Lifecycle.DeleteAfterDays,TargetBackupVaultName]' \
    --output table"
  echo "Los recovery points de AWS Backup son regionales, no zonales: este respaldo"
  echo "puede restaurarse en la otra zona de disponibilidad."
  echo
}

case "$BLOQUE" in
  red)          bloque_red ;;
  seguridad)    bloque_seguridad ;;
  ha)           bloque_ha ;;
  contenedores) bloque_contenedores ;;
  crud)         bloque_crud ;;
  backup)       bloque_backup ;;
  todo)         bloque_red; bloque_seguridad; bloque_ha
                bloque_contenedores; bloque_crud; bloque_backup ;;
  *)            sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
                exit 1 ;;
esac
