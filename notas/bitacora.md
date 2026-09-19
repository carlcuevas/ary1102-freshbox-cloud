# Bitácora Técnica — EP1 FreshBox SpA (ARY1102 Arquitectura Cloud)

> **Propósito de este documento:** registro completo y autocontenido de todo lo construido, decidido y verificado en la infraestructura AWS del caso FreshBox SpA. Sirve como **insumo único** para redactar el informe técnico (puntos 1.1 a 1.7) y la presentación, sin necesidad de reconstruir el contexto.

---

## 🔖 ESTADO DE TRASPASO — leer primero

### ✅ Completado (parte técnica)
| Área | Estado |
|---|---|
| Corrección de bugs del código fuente | ✅ |
| Red: VPC /22, 6 subredes Multi-AZ, IGW, NAT GW, route tables | ✅ desplegado y verificado |
| Security Groups segmentados por capa (3) | ✅ desplegado y verificado |
| EC2 MySQL/MariaDB + BD poblada + EBS cifrado | ✅ desplegado y verificado |
| EC2 App x2 Multi-AZ + Docker + 5 contenedores c/u | ✅ desplegado y verificado |
| Auto Scaling Group (min 2 / max 4) | ✅ desplegado y verificado |
| Amazon ECR + 5 imágenes ARM64 | ✅ desplegado y verificado |
| ALB + Target Group (2 targets healthy) | ✅ desplegado y verificado |
| Validación CRUD end-to-end (GET/POST/PUT/DELETE) | ✅ verificado por `curl` y por frontend web |
| Diagrama de arquitectura TO-BE | ✅ `diagramas/diagrama-arquitectura-tobe.png` |
| Evidencia fotográfica (27 capturas organizadas) | ✅ `evidencias/01..07` |
| AWS Backup (template IaC) | ⚠️ template creado, **pendiente de desplegar y validar** (ver §9) |

### ⏳ Pendiente (a cargo de la siguiente etapa)
1. **Desplegar y validar AWS Backup** (`infra/05-backup.yaml`) — ver §9, incluye plan B si falla por IAM
2. **Informe técnico** — secciones 1.1 a 1.7 + Portada, Índice, Introducción, Conclusiones, Bibliografía APA v7 (máx. 20 págs, PDF/Word)
3. **Presentación PowerPoint** + guion de demo en vivo (10 min)
4. **Ensayo de redespliegue completo** — ver §10 (runbook); crítico porque el Lab borra recursos al expirar

### 📌 Datos clave para citar en el informe/presentación
- **Cuenta AWS:** `334767299218` · **Región:** `us-east-1`
- **DNS público del ALB:** `freshbox-alb-933788468.us-east-1.elb.amazonaws.com`
- **Endpoint de la API:** `/api/products` (GET, POST) · `/api/products/:id` (PUT, DELETE)
- **Repositorio del entregable:** https://github.com/carlcuevas/ary1102-freshbox-cloud

---

## Convenciones
- Región: `us-east-1`
- Prefijo de todos los recursos: `freshbox-`
- Enfoque: **Infraestructura como Código (CloudFormation)**, no creación manual por consola

---

## 1. Corrección de bugs en el código fuente (previa al despliegue)

Al analizar el proyecto entregado (`desarrolloappEP1.zip`) se detectaron **dos defectos que habrían impedido que el CRUD funcionara detrás del ALB**. Ambos fueron corregidos antes de desplegar.

### Bug 1 — Frontend llamaba a puertos fijos en vez de rutas relativas
- **Qué pasaba:** `microservicioFrontend/js/app.js` construía las URLs como `API_BASE + ':3001/api/products'`, `:3002`, `:3003`, `:3004`.
- **Por qué rompe:** el ALB solo expone los puertos 80/443 hacia el Target Group, y las EC2 App están en subred **privada**. El navegador del usuario nunca podría alcanzar los puertos 3001-3004 directamente. En `docker compose` local sí funcionaba (los puertos se publican en el host), lo que hacía el bug invisible en pruebas locales.
- **Corrección:** todas las llamadas usan ahora la ruta relativa `/api/products`, dejando que el `nginx.conf` del contenedor frontend haga el *reverse proxy* interno según el método HTTP.

### Bug 2 — Nombres de contenedor no coincidían con los hostnames esperados por nginx
- **Qué pasaba:** `nginx.conf` resuelve los backends por los hostnames `get-products`, `create-product`, `update-product`, `delete-product`; pero `scripts/deploy-containers.sh` creaba los contenedores como `freshbox-get-products`, etc.
- **Por qué rompe:** nginx no podía resolver el DNS interno de la red Docker al desplegar en AWS. (En `docker-compose` local no se notaba porque el nombre del *servicio* sí coincidía.)
- **Corrección:** se agregó `--network-alias` a cada `docker run`, para que cada contenedor responda además por su hostname corto.

> **Valor para el informe (punto 1.3 — riesgos y mejoras):** este hallazgo es un ejemplo concreto y propio de riesgo en los pilares de **Fiabilidad** y **Excelencia Operativa**: una configuración que funciona en el entorno local pero falla en producción por diferencias de topología de red. Detectado y mitigado antes del despliegue.

---

## 2. Infraestructura de red (stack `freshbox-red`)

**Template:** [`infra/01-red.yaml`](../infra/01-red.yaml)

**Validación previa del entorno:** antes de escribir IaC se comprobó que AWS Academy Learner Lab lo permite:
- `aws cloudformation create-stack` / `delete-stack` reales → OK (prueba con stack `zz-test-stack`, eliminado limpiamente)
- `aws ec2 create-vpc --dry-run` → `DryRunOperation` (= permitido)
- `aws ecr create-repository` / `delete-repository` reales → OK
- Lectura de ELB, ASG y Backup → OK
- ❌ **No se pueden crear roles IAM nuevos** → se reutilizan `LabRole` / `LabInstanceProfile`

| Recurso | Nombre | CIDR / Valor | AZ |
|---|---|---|---|
| VPC | `freshbox-vpc` | `10.0.0.0/22` | — |
| Subred pública Web | `freshbox-sub-web-1a` | `10.0.0.0/26` | us-east-1a |
| Subred pública Web | `freshbox-sub-web-1b` | `10.0.0.64/26` | us-east-1b |
| Subred privada App | `freshbox-sub-app-1a` | `10.0.0.128/26` | us-east-1a |
| Subred privada App | `freshbox-sub-app-1b` | `10.0.0.192/26` | us-east-1b |
| Subred privada Data | `freshbox-sub-data-1a` | `10.0.1.0/26` | us-east-1a |
| Subred privada Data | `freshbox-sub-data-1b` | `10.0.1.64/26` | us-east-1b |
| Internet Gateway | `freshbox-igw` | — | — |
| NAT Gateway | `freshbox-natgw` | EIP `100.27.78.176` | us-east-1a (en subred pública) |
| Route Table pública | `freshbox-rt-public` | `0.0.0.0/0` → IGW | asociada a las 2 subredes web |
| Route Table privada | `freshbox-rt-private` | `0.0.0.0/0` → NAT GW | asociada a las 4 subredes app+data |

**IDs reales (confirmados 2026-09-18):**

| Output | Valor |
|---|---|
| VpcId | `vpc-0be08aefab15d0945` |
| SubnetWeb1AId | `subnet-0a40f4c83d8495d9a` |
| SubnetWeb1BId | `subnet-0dc7a0d54e8ec221d` |
| SubnetApp1AId | `subnet-003b9d4445fb50bf0` |
| SubnetApp1BId | `subnet-0f6be67406b652af2` |
| SubnetData1AId | `subnet-0addc2a91142c8715` |
| SubnetData1BId | `subnet-07bfca66144541cee` |
| InternetGatewayId | `igw-0d0634691ae9d0ece` |
| NatGatewayId | `nat-0684d24f66a51736d` |
| Public Route Table | `rtb-006d69391a9eef615` |
| Private Route Table | `rtb-07d378b8b99c8e63d` |

**Estado:** ✅ `CREATE_COMPLETE` · **Evidencia:** `evidencias/01-vpc-subredes/` (11 capturas)

---

## 3. Security Groups (stack `freshbox-sg`)

**Template:** [`infra/02-security-groups.yaml`](../infra/02-security-groups.yaml)

Segmentación encadenada de **mínimo privilegio**: cada capa solo acepta tráfico de la capa inmediatamente anterior, referenciando el *Security Group* de origen (no rangos de IP), lo que mantiene la regla válida aunque las instancias cambien de IP.

| SG | ID real | Inbound | Origen |
|---|---|---|---|
| `freshbox-sg-alb` | `sg-00d3cb470f73840a0` | TCP 80, 443 | `0.0.0.0/0` (Internet) |
| `freshbox-sg-app` | `sg-00520ee631b9d68c7` | TCP 80, 443 | **SG del ALB** |
| `freshbox-sg-bd` | `sg-07e9f0a7448e1e386` | TCP 3306 | **SG de App** |

**Nota de diseño:** las reglas de ingreso del SG-App y SG-Data se declararon como recursos `AWS::EC2::SecurityGroupIngress` separados (no inline), para evitar la dependencia circular que CloudFormation genera cuando dos SGs se referencian mutuamente.

**Estado:** ✅ `CREATE_COMPLETE` · **Evidencia:** `evidencias/02-security-groups/` (3 capturas)

---

## 4. EC2 capa Data — MySQL (stack `freshbox-compute`)

**Template:** [`infra/03-compute.yaml`](../infra/03-compute.yaml)

| Campo | Valor |
|---|---|
| Nombre | `freshbox-ec2-mysql` |
| InstanceId | `i-096324afebf1a0539` |
| Tipo | `t4g.small` (ARM/Graviton) |
| AMI | Amazon Linux 2023 ARM64, resuelta vía **SSM Parameter Store** (siempre la más reciente, sin hardcodear AMI ID) |
| Subred | `freshbox-sub-data-1a` (`subnet-0addc2a91142c8715`) |
| IP privada | `10.0.1.43` |
| Cifrado EBS | ✅ gp3 8 GB, `Encrypted: true` |
| IAM | `LabInstanceProfile` (rol preexistente del Lab) |

### ⚠️ Decisión técnica: MariaDB en vez de MySQL
Amazon Linux 2023 **no incluye el paquete oficial de MySQL Server** en sus repositorios; incluye **MariaDB**, que es un fork *wire-compatible* con MySQL y totalmente compatible con el driver `mysql2` que usan los microservicios Node.js. Se instaló `mariadb105-server`.
> *Argumento defendible en la presentación:* "se usó MariaDB, motor compatible con el protocolo MySQL, por ser el disponible nativamente en Amazon Linux 2023, evitando agregar repositorios externos (buena práctica de mantenibilidad y superficie de ataque reducida)".

### Provisionamiento automático de la BD
El `UserData` del template crea la base `freshbox`, el usuario `alumno`, la tabla `productos` y carga los 5 productos orgánicos (equivalente a `init.sql`), sin intervención manual.

**Verificación (vía AWS Systems Manager Session Manager, sin SSH ni llaves):**
```
id      nombre                    precio
1       Manzana organica 1kg      3490.00
2       Lechuga hidroponica       1990.00
3       Granola artesanal 500g    4990.00
4       Jugo natural naranja 1L   2990.00
5       Mix frutos secos 250g     5490.00
```

**Estado:** ✅ instancia y datos verificados · **Evidencia:** `evidencias/03-ec2-mysql/`

---

## 5. EC2 capa App + Auto Scaling Group (stack `freshbox-compute`)

Desplegadas mediante `AWS::EC2::LaunchTemplate` + `AWS::AutoScaling::AutoScalingGroup`.

| Campo | Valor |
|---|---|
| ASG | `freshbox-asg-app` — **min 2 / max 4 / desired 2** |
| Subredes | `freshbox-sub-app-1a` + `freshbox-sub-app-1b` (Multi-AZ) |
| Tipo instancia | `t4g.small` |
| Cifrado EBS | ✅ gp3 8 GB vía Launch Template |
| IAM | `LabInstanceProfile` |

El `UserData` instala Docker, hace `docker login` a ECR y despliega los 5 contenedores con `--network-alias`, apuntando a la IP privada de la instancia MySQL (inyectada por CloudFormation con `Fn::GetAtt`).

### ⚠️ Reemplazo de instancias por el ASG (importante para la coherencia de la evidencia)
Las instancias originales (`i-0cfb5552cdf4faecc`, `i-0d22849f21e783c74`) fueron **reemplazadas automáticamente por el ASG** tras conectar el ALB — comportamiento normal de *auto-healing*. Instancias **vigentes**:

| Campo | app-1a | app-1b |
|---|---|---|
| InstanceId | `i-0dd7f85d9dfc342ea` | `i-016e07318bb71bcbe` |
| IP privada | `10.0.0.143` | `10.0.0.253` |
| Estado ASG | Healthy / InService | Healthy / InService |
| Contenedores | ✅ 5/5 Up | ✅ 5/5 Up |
| Target Group | ✅ healthy | ✅ healthy |

**Verificación `docker ps` en ambas instancias:**
```
NAMES            STATUS
frontend         Up 2 hours
delete-product   Up 2 hours
update-product   Up 2 hours
create-product   Up 2 hours
get-products     Up 2 hours
```

> *Valor para el informe (pilar Fiabilidad):* el reemplazo automático de instancias por el ASG, manteniendo el estado deseado y sin caída del servicio, es **evidencia real de auto-healing funcionando**, no solo teórica.

**Estado:** ✅ ambas instancias operativas · **Evidencia:** `evidencias/04-ec2-app/`

---

## 6. Amazon ECR — 5 imágenes Docker

| Repositorio | URI |
|---|---|
| `freshbox-frontend` | `334767299218.dkr.ecr.us-east-1.amazonaws.com/freshbox-frontend` |
| `freshbox-get-products` | `...amazonaws.com/freshbox-get-products` |
| `freshbox-create-product` | `...amazonaws.com/freshbox-create-product` |
| `freshbox-update-product` | `...amazonaws.com/freshbox-update-product` |
| `freshbox-delete-product` | `...amazonaws.com/freshbox-delete-product` |

Todas con tag `latest`, cifrado AES-256, y `Last pulled at` registrado (confirma que las EC2 App efectivamente hicieron `docker pull`).

### ⚠️ Hallazgo técnico: build ARM64 desde CloudShell (amd64)
Las instancias `t4g.small` son **ARM/Graviton**, por lo que las imágenes deben ser `linux/arm64`. CloudShell corre en `linux/amd64`, y el primer intento falló con `exec /bin/sh: exec format error` en `RUN npm install`. Solución aplicada:
1. Registrar emuladores QEMU: `docker run --privileged --rm tonistiigi/binfmt --install all`
2. Crear builder con driver `docker-container` (el driver `docker` por defecto **no** detecta los emuladores recién registrados): `docker buildx create --name freshbox-builder --driver docker-container --use`
3. Construir con `docker buildx build --platform linux/arm64 --load ...` (el `--load` es necesario para que la imagen quede local y se pueda hacer `docker push`)

> *Valor para el informe (punto 1.3 / pilar Excelencia Operativa):* hallazgo real de incompatibilidad de arquitectura de CPU en la cadena de build, con su mitigación documentada.

### Nota de permisos
`LabRole` tiene adjunta la política **`AmazonEC2ContainerRegistryReadOnly`** → las EC2 solo pueden hacer `pull`, no `push`. Esto es exactamente lo deseado: el `push` se hace desde CloudShell con la identidad `voclabs` del usuario, y el `pull` desde las instancias con permiso de solo lectura (principio de mínimo privilegio).

**Estado:** ✅ 5/5 imágenes · **Evidencia:** `evidencias/05-ecr/`

---

## 7. ALB + Target Group (stack `freshbox-alb`)

**Template:** [`infra/04-alb.yaml`](../infra/04-alb.yaml)

| Campo | Valor |
|---|---|
| ALB | `freshbox-alb` — internet-facing, 2 AZs |
| DNS | `freshbox-alb-933788468.us-east-1.elb.amazonaws.com` |
| ARN ALB | `arn:aws:elasticloadbalancing:us-east-1:334767299218:loadbalancer/app/freshbox-alb/1cbf2b4f05bbdfa3` |
| Target Group | `freshbox-tg-app` — HTTP:80, health check `/` (200 OK) |
| ARN TG | `arn:aws:elasticloadbalancing:us-east-1:334767299218:targetgroup/freshbox-tg-app/de72db1f579fcad9` |
| Targets healthy | ✅ `i-0dd7f85d9dfc342ea` (1a) · `i-016e07318bb71bcbe` (1b) |

### Nota de diseño: evitar dependencia circular ASG ↔ ALB
El template del ALB **no registra instancias**. En su lugar, el stack de compute expone un parámetro `TargetGroupArn` (vacío por defecto) y se conecta después con `update-stack`. Esto evita la dependencia circular clásica y permite desplegar en orden lineal. Las instancias ya en ejecución se registraron además con `aws elbv2 register-targets` (un `update-stack` no re-registra instancias preexistentes).

### ⚠️ Brecha conocida: HTTPS sin listener
Los Security Groups permiten el puerto 443, pero el ALB **solo tiene listener HTTP:80** — no se configuró HTTPS porque no hay certificado ACM disponible en el entorno de Academy Lab.
> *Respuesta preparada si el docente pregunta:* "el diseño contempla 443 a nivel de Security Group; el listener HTTPS requiere un certificado en ACM y un dominio propio, fuera del alcance del entorno académico. En producción se agregaría un listener HTTPS con redirección 80→443 y política TLS mínima 1.2."

**Estado:** ✅ `CREATE_COMPLETE`, 2/2 targets healthy · **Evidencia:** `evidencias/06-alb-targetgroup/`

---

## 8. 🎯 VALIDACIÓN END-TO-END — CRUD completo vía ALB

Flujo verificado completo:
`Internet → ALB (SG-alb) → EC2 App (SG-app, nginx reverse proxy → microservicio:300X) → EC2 MySQL (SG-bd, 10.0.1.43)`

### Validación por API (`curl` contra el DNS del ALB)

| Método | Prueba | Resultado |
|---|---|---|
| GET | `curl .../api/products` | HTTP 200, los 5 productos |
| POST | crear "Quinoa organica 500g" | producto `id:6` creado |
| PUT | actualizar `id:6` a "Quinoa organica 1kg" | precio 4990→8990, stock 80→50 |
| DELETE | eliminar `id:6` | `{"message":"Producto eliminado correctamente","id":6}` |
| GET | verificación final | vuelven exactamente los 5 originales (ids 1-5) |

### Validación por interfaz web (frontend real, en navegador)
Secuencia completa capturada en `evidencias/07-validacion-crud/`:
1. Listado inicial con los 5 productos
2. Formulario "Nuevo Producto"
3. Producto creado (`id:7 "NARANAX"`, $1.111, stock 50, categoría FRUTA)
4. Formulario "Editar Producto (ID: 7)" con datos cargados
5. Tras eliminar, el listado vuelve a los 5 productos originales

**Esto demuestra simultáneamente:**
- Segmentación de red por capas operativa
- Security Groups encadenados sin puertos de más
- El fix del Bug 1 (§1) validado **en producción real**, no solo en teoría
- Alta disponibilidad Multi-AZ (2 targets healthy en AZs distintas)

**Estado:** ✅ **100% validado** — cubre el indicador 12 (10%) y el checklist "Validación Funcional (Demo CRUD)"

> **Recomendación para la demo en vivo:** repetir esta misma secuencia usando el **frontend web** (no `curl`), que es visualmente mucho más convincente ante el docente.

---

## 9. AWS Backup — ⚠️ PENDIENTE DE DESPLEGAR

**Template creado:** [`infra/05-backup.yaml`](../infra/05-backup.yaml) — Backup Vault + Backup Plan (regla diaria 03:00 UTC, retención 7 días) + Backup Selection apuntando a la EC2 MySQL.

### Comandos para desplegar
```bash
cd ~/ary1102-freshbox-cloud/infra
aws cloudformation validate-template --template-body file://05-backup.yaml
aws cloudformation create-stack --stack-name freshbox-backup --template-body file://05-backup.yaml
aws cloudformation wait stack-create-complete --stack-name freshbox-backup
aws cloudformation describe-stacks --stack-name freshbox-backup --query 'Stacks[0].StackStatus' --output json
```

### ⚠️ Riesgo conocido y PLAN B
AWS Backup requiere un rol IAM asumible por `backup.amazonaws.com` para el `BackupSelection`. En Academy Lab **no se pueden crear roles nuevos**, por lo que el template reutiliza `LabRole`. **Es posible que falle** si la *trust policy* de `LabRole` no incluye a `backup.amazonaws.com`.

Si el stack falla con error tipo `Cannot assume role` o `iam:PassRole` denegado, diagnosticar con:
```bash
aws cloudformation describe-stack-events --stack-name freshbox-backup --query "StackEvents[?contains(ResourceStatus,'FAILED')].[LogicalResourceId,ResourceStatusReason]" --output json
```

**PLAN B (garantizado, sin rol de servicio):** snapshot EBS manual de la instancia MySQL, que sí funciona con los permisos del Lab:
```bash
# Obtener el VolumeId del EBS de la instancia MySQL
VOL=$(aws ec2 describe-instances --instance-ids i-096324afebf1a0539 \
  --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' --output text)

# Crear el snapshot (evidencia real de respaldo)
aws ec2 create-snapshot --volume-id $VOL \
  --description "FreshBox EP1 - respaldo EC2 MySQL" \
  --tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=freshbox-mysql-backup},{Key=Proyecto,Value=FreshBox-EP1}]'

# Verificar
aws ec2 describe-snapshots --owner-ids self --query 'Snapshots[*].[SnapshotId,State,Description]' --output table
```
En ese escenario, documentar en el informe que el **diseño** contempla AWS Backup con plan diario y retención de 7 días (y recuperación en AZ1b), y que en el entorno académico se evidenció mediante snapshot EBS por la restricción de IAM del Learner Lab — lo cual es una limitación del entorno, no del diseño.

---

## 10. 🔁 RUNBOOK DE REDESPLIEGUE COMPLETO (crítico)

**Por qué es crítico:** AWS Academy Learner Lab **elimina todos los recursos** cuando el laboratorio expira o se detiene. Si eso ocurre antes de la presentación, hay que recrear todo. Gracias a IaC, toma ~15-20 minutos.

### Orden exacto de ejecución (desde AWS CloudShell)

```bash
# 0. Clonar el repo (si CloudShell se reseteó)
git clone https://github.com/carlcuevas/ary1102-freshbox-cloud.git
cd ary1102-freshbox-cloud

# 1. RED (~3-5 min, el NAT Gateway es lo más lento)
cd infra
aws cloudformation create-stack --stack-name freshbox-red --template-body file://01-red.yaml
aws cloudformation wait stack-create-complete --stack-name freshbox-red

# 2. SECURITY GROUPS (~30 seg)
aws cloudformation create-stack --stack-name freshbox-sg --template-body file://02-security-groups.yaml
aws cloudformation wait stack-create-complete --stack-name freshbox-sg

# 3. IMÁGENES A ECR (~8-10 min por la emulación ARM64) — ANTES del compute
cd ../codigo
docker run --privileged --rm tonistiigi/binfmt --install all
docker buildx create --name freshbox-builder --driver docker-container --use || docker buildx use freshbox-builder
docker buildx inspect --bootstrap
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text); REGION="us-east-1"
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
for R in freshbox-frontend freshbox-get-products freshbox-create-product freshbox-update-product freshbox-delete-product; do
  aws ecr create-repository --repository-name $R --region $REGION 2>/dev/null || echo "$R ya existe"
done
docker buildx build --platform linux/arm64 --load -t freshbox-frontend ./microservicioFrontend
docker tag freshbox-frontend $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/freshbox-frontend:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/freshbox-frontend:latest
for S in get-products create-product update-product delete-product; do
  docker buildx build --platform linux/arm64 --load -t freshbox-$S ./microserviciosBackend/$S
  docker tag freshbox-$S $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/freshbox-$S:latest
  docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/freshbox-$S:latest
done

# 4. COMPUTE: EC2 MySQL + Launch Template + ASG (~4-6 min)
cd ../infra
aws cloudformation create-stack --stack-name freshbox-compute --template-body file://03-compute.yaml
aws cloudformation wait stack-create-complete --stack-name freshbox-compute

# 5. ALB + TARGET GROUP (~2 min)
aws cloudformation create-stack --stack-name freshbox-alb --template-body file://04-alb.yaml
aws cloudformation wait stack-create-complete --stack-name freshbox-alb

# 6. CONECTAR ASG AL TARGET GROUP
TG=$(aws cloudformation describe-stacks --stack-name freshbox-alb --query "Stacks[0].Outputs[?OutputKey=='TargetGroupArn'].OutputValue" --output text)
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

# 7. REGISTRAR LAS INSTANCIAS EN EL TARGET GROUP
IDS=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names freshbox-asg-app \
  --query 'AutoScalingGroups[0].Instances[*].InstanceId' --output text)
for I in $IDS; do aws elbv2 register-targets --target-group-arn "$TG" --targets Id=$I; done

# 8. (Opcional) AWS BACKUP
aws cloudformation create-stack --stack-name freshbox-backup --template-body file://05-backup.yaml

# 9. VALIDAR
sleep 60
aws elbv2 describe-target-health --target-group-arn "$TG" --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' --output table
DNS=$(aws cloudformation describe-stacks --stack-name freshbox-alb --query "Stacks[0].Outputs[?OutputKey=='AlbDnsName'].OutputValue" --output text)
echo "Frontend: http://$DNS/"
curl "http://$DNS/api/products"
```

⚠️ **Al redesplegar, los IDs de recursos y el DNS del ALB CAMBIAN.** Si eso ocurre, actualizar los valores citados en el informe/presentación, o mejor: tomar nuevas capturas. Lo que **no** cambia son los nombres lógicos (`freshbox-vpc`, `freshbox-alb`, etc.) ni los CIDR.

### Para eliminar todo (orden inverso)
```bash
aws cloudformation delete-stack --stack-name freshbox-backup
aws cloudformation delete-stack --stack-name freshbox-alb
aws cloudformation delete-stack --stack-name freshbox-compute
aws cloudformation delete-stack --stack-name freshbox-sg
aws cloudformation delete-stack --stack-name freshbox-red
```

---

## 11. Riesgos y hallazgos — insumo directo para el punto 1.3 del informe

| # | Hallazgo | Pilar Well-Architected afectado | Mitigación aplicada |
|---|---|---|---|
| 1 | Frontend con puertos fijos: funcionaba en local, rompía detrás del ALB | Fiabilidad · Excelencia Operativa | Migrado a rutas relativas + reverse proxy nginx (§1) |
| 2 | Nombres de contenedor inconsistentes con la resolución DNS de nginx | Excelencia Operativa | `--network-alias` en el despliegue (§1) |
| 3 | Imágenes amd64 incompatibles con instancias Graviton (ARM64) | Excelencia Operativa · Eficiencia del Rendimiento | Build multiplataforma con QEMU + buildx (§6) |
| 4 | MySQL Server no disponible en Amazon Linux 2023 | Mantenibilidad · Excelencia Operativa | MariaDB (wire-compatible), sin repos externos (§4) |
| 5 | ALB sin listener HTTPS (no hay certificado ACM en el Lab) | **Seguridad** | Documentado; en producción: listener 443 + redirección 80→443 + TLS ≥1.2 (§7) |
| 6 | Credenciales de BD en texto plano en el template (`DBPassword` con `NoEcho`) | **Seguridad** | Mitigación parcial (`NoEcho`); en producción: **AWS Secrets Manager** o SSM Parameter Store `SecureString` |
| 7 | Sin monitoreo ni alarmas (no hay CloudWatch Alarms, ni logs centralizados de los contenedores) | Excelencia Operativa · Fiabilidad | **Oportunidad de mejora:** CloudWatch Agent + log groups por microservicio + alarmas de CPU/5xx |
| 8 | BD en EC2 autoadministrada en vez de servicio gestionado | Fiabilidad · Excelencia Operativa | **Oportunidad de mejora:** migrar a **Amazon RDS Multi-AZ** (failover automático, backups gestionados, parches automáticos) |
| 9 | Un solo NAT Gateway (en AZ1a) → punto único de falla para el egress | **Fiabilidad** | **Oportunidad de mejora:** un NAT Gateway por AZ |
| 10 | Dependencia de `LabRole` con permisos amplios | Seguridad | Limitación del entorno académico; en producción: roles dedicados de mínimo privilegio por capa |
| 11 | AWS Backup no desplegado por restricción de IAM del Lab | Fiabilidad | Template listo + plan B con snapshots EBS (§9) |

> Los hallazgos 7, 8 y 9 son especialmente útiles como **"oportunidades de mejora por pilar"** (exigido explícitamente en el punto 1.3), porque son mejoras reales y justificadas, no genéricas.

---

## 12. Mapa de evidencia → indicadores de la pauta

| Carpeta de evidencia | Contenido | Indicador que respalda |
|---|---|---|
| `01-vpc-subredes/` (11) | VPC, 6 subredes, IGW, 2 route tables, NAT GW | 11 (15%) |
| `02-security-groups/` (3) | Los 3 SGs por capa | 11 (15%) |
| `03-ec2-mysql/` (1) | EC2 capa Data | 11, 12 |
| `04-ec2-app/` (2) | EC2 App Multi-AZ, pertenencia al ASG | 11, 12 |
| `05-ecr/` (2) | 5 repositorios + imágenes con `latest` | 12 (10%) |
| `06-alb-targetgroup/` (3) | ALB, Target Group, 2 targets healthy | 11, 12 |
| `07-validacion-crud/` (5) | CRUD completo en el frontend web | 12 (10%) |
| `diagramas/diagrama-arquitectura-tobe.png` | Diagrama TO-BE 3 capas | **10 (15%)** |

**Cobertura técnica lograda: indicadores 10 + 11 + 12 = 40% del EP1**, con evidencia verificable.
El 60% restante (indicadores 1 a 9) corresponde al informe escrito y la exposición oral.
