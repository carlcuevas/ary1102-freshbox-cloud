# Infraestructura como código — CloudFormation

Las cinco plantillas de este directorio despliegan la arquitectura completa de FreshBox SpA en `us-east-1`. Están pensadas para ejecutarse **en orden**, comunicándose entre sí mediante *exports* de CloudFormation: cada stack publica sus identificadores y el siguiente los importa por nombre de stack, sin valores copiados a mano.

Todos los recursos usan el prefijo `freshbox-`. Un redespliegue completo toma entre 15 y 20 minutos, de los cuales la mayor parte corresponde al NAT Gateway y a la construcción de imágenes ARM64.

## Las cinco plantillas

| Orden | Stack | Plantilla | Qué crea |
|---|---|---|---|
| 1 | `freshbox-red` | [`01-red.yaml`](01-red.yaml) | VPC `10.0.0.0/22`, 6 subredes /26 en 2 AZs, Internet Gateway, NAT Gateway con EIP, route tables pública y privada |
| 2 | `freshbox-sg` | [`02-security-groups.yaml`](02-security-groups.yaml) | Los 3 Security Groups encadenados por capa (ALB → App → BD) |
| 3 | `freshbox-compute` | [`03-compute.yaml`](03-compute.yaml) | EC2 con MariaDB en la capa Data, Launch Template y Auto Scaling Group de la capa App |
| 4 | `freshbox-alb` | [`04-alb.yaml`](04-alb.yaml) | Application Load Balancer internet-facing, Target Group y listener HTTP:80 |
| 5 | `freshbox-backup` | [`05-backup.yaml`](05-backup.yaml) | Backup Vault, plan diario a las 03:00 UTC y asignación de la instancia de datos |

Entre los pasos 2 y 3 hay que publicar las **imágenes Docker en Amazon ECR**: el UserData del Launch Template hace `docker pull` durante el arranque, de modo que las imágenes deben existir antes de crear el stack de cómputo. El procedimiento está en [`../codigo/README.md`](../codigo/README.md) y en la sección §10 de [`../notas/bitacora.md`](../notas/bitacora.md).

## Parámetros

Todas las plantillas traen valores por defecto funcionales; en un despliegue limpio no hace falta pasar ningún parámetro salvo los dos casos señalados.

| Plantilla | Parámetro | Valor por defecto | Para qué sirve |
|---|---|---|---|
| `02`, `03`, `04` | `NetworkStackName` | `freshbox-red` | Nombre del stack de red desde el que se importan VPC y subredes |
| `03`, `04` | `SecurityGroupsStackName` | `freshbox-sg` | Nombre del stack de Security Groups |
| `03` | `LatestAmiId` | parámetro SSM de Amazon Linux 2023 ARM64 | Resuelve la AMI más reciente en tiempo de despliegue, sin AMI ID fijo |
| `03` | `InstanceType` | `t4g.small` | Tipo de instancia de las tres EC2 (familia Graviton/ARM64) |
| `03` | `DBName` / `DBUser` / `DBPassword` | `freshbox` / `alumno` / credencial de laboratorio | Aprovisionamiento de la base de datos. `DBPassword` usa `NoEcho`; en producción debe migrar a Secrets Manager (brecha declarada en el informe) |
| `03` | `TargetGroupArn` | `""` | Se completa **después** de crear el ALB, con un `update-stack`, para evitar la dependencia circular ASG ↔ ALB |
| `05` | `ComputeStackName` | `freshbox-compute` | Stack desde el que se importa la instancia a respaldar |
| `05` | `BackupRoleArn` | `""` | Si se deja vacío usa `LabRole`; AWS Academy Learner Lab no permite crear roles IAM nuevos |
| `05` | `RetentionDays` | `7` | Días de retención de los puntos de recuperación |

## Despliegue

```bash
cd infra

# 1. Red — el NAT Gateway es el recurso más lento (3-5 min)
aws cloudformation create-stack --stack-name freshbox-red --template-body file://01-red.yaml
aws cloudformation wait stack-create-complete --stack-name freshbox-red

# 2. Security Groups (~30 s)
aws cloudformation create-stack --stack-name freshbox-sg --template-body file://02-security-groups.yaml
aws cloudformation wait stack-create-complete --stack-name freshbox-sg

# 3. Publicar las 5 imágenes ARM64 en ECR  →  ver ../codigo/README.md

# 4. Cómputo: EC2 MariaDB + Launch Template + Auto Scaling Group (4-6 min)
aws cloudformation create-stack --stack-name freshbox-compute --template-body file://03-compute.yaml
aws cloudformation wait stack-create-complete --stack-name freshbox-compute

# 5. ALB + Target Group (~2 min)
aws cloudformation create-stack --stack-name freshbox-alb --template-body file://04-alb.yaml
aws cloudformation wait stack-create-complete --stack-name freshbox-alb

# 6. Conectar el ASG al Target Group y registrar las instancias en ejecución
TG=$(aws cloudformation describe-stacks --stack-name freshbox-alb \
  --query "Stacks[0].Outputs[?OutputKey=='TargetGroupArn'].OutputValue" --output text)
aws cloudformation update-stack --stack-name freshbox-compute --template-body file://03-compute.yaml \
  --parameters ParameterKey=TargetGroupArn,ParameterValue="$TG" \
    ParameterKey=NetworkStackName,UsePreviousValue=true \
    ParameterKey=SecurityGroupsStackName,UsePreviousValue=true \
    ParameterKey=LatestAmiId,UsePreviousValue=true \
    ParameterKey=InstanceType,UsePreviousValue=true \
    ParameterKey=DBName,UsePreviousValue=true \
    ParameterKey=DBUser,UsePreviousValue=true \
    ParameterKey=DBPassword,UsePreviousValue=true
aws cloudformation wait stack-update-complete --stack-name freshbox-compute

IDS=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names freshbox-asg-app \
  --query 'AutoScalingGroups[0].Instances[*].InstanceId' --output text)
for I in $IDS; do aws elbv2 register-targets --target-group-arn "$TG" --targets Id=$I; done

# 7. AWS Backup (1-2 min)
aws cloudformation create-stack --stack-name freshbox-backup --template-body file://05-backup.yaml
aws cloudformation wait stack-create-complete --stack-name freshbox-backup
```

## Verificación

```bash
# Los 2 targets deben quedar healthy, uno por zona de disponibilidad
aws elbv2 describe-target-health --target-group-arn "$TG" \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' --output table

# El catálogo debe responder los 5 productos a través del balanceador
DNS=$(aws cloudformation describe-stacks --stack-name freshbox-alb \
  --query "Stacks[0].Outputs[?OutputKey=='AlbDnsName'].OutputValue" --output text)
curl "http://$DNS/api/products"
echo "Frontend: http://$DNS/"
```

Los contenedores se inspeccionan sin SSH, por Session Manager: `aws ssm start-session --target <instance-id>` y luego `docker ps`. No existe ninguna regla de entrada al puerto 22 en los Security Groups.

## Desmontaje

En orden inverso, esperando que cada stack termine antes de continuar:

```bash
for S in freshbox-backup freshbox-alb freshbox-compute freshbox-sg freshbox-red; do
  aws cloudformation delete-stack --stack-name $S
  aws cloudformation wait stack-delete-complete --stack-name $S
done
```

## Notas de diseño

- **Dependencia circular ASG ↔ ALB.** La plantilla del ALB no registra instancias y la de cómputo recibe el ARN del Target Group como parámetro opcional. Eso permite un orden de despliegue lineal; el `update-stack` del paso 6 cierra el vínculo. Un `update-stack` no registra instancias que ya estaban en ejecución, por lo que el `register-targets` posterior es necesario.
- **Reglas de ingreso como recursos separados.** Las reglas de `freshbox-sg-app` y `freshbox-sg-bd` se declaran como `AWS::EC2::SecurityGroupIngress` independientes en lugar de inline, para evitar la dependencia circular que CloudFormation genera cuando dos Security Groups se referencian mutuamente.
- **Restricciones de AWS Academy Learner Lab.** No se pueden crear roles IAM nuevos, por lo que las plantillas reutilizan `LabRole` y `LabInstanceProfile`. Se verificó que la *trust policy* de `LabRole` admite `backup.amazonaws.com`, condición necesaria para el `BackupSelection` del stack de respaldo.
- **Arquitectura ARM64.** Las instancias son Graviton, así que las imágenes deben construirse para `linux/arm64`. Construirlas desde CloudShell (que es `amd64`) requiere emuladores QEMU y `docker buildx` con driver `docker-container`.
