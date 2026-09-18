# Bitácora Técnica — EP1 FreshBox SpA

> Registro de decisiones, recursos creados y datos técnicos a medida que se construye la arquitectura en AWS Academy Learner Lab. Este documento es el insumo base para redactar el informe técnico (puntos 1.1 a 1.7) y la presentación.

## Convenciones
- Región: `us-east-1`
- Prefijo de nombres de recursos: `freshbox-`

---

## 1. Corrección de código previa al despliegue

- **Problema detectado:** `app.js` (frontend) llamaba directo a los puertos 3001-3004 en vez de usar rutas relativas. Esto rompe el flujo detrás del ALB, que solo expone el puerto 80/443.
- **Solución aplicada:** rutas relativas `/api/products` + nginx como reverse proxy interno (ver `codigo/microservicioFrontend/nginx.conf`).
- **Segundo ajuste:** `deploy-containers.sh` ahora usa `--network-alias` para que los contenedores respondan a los hostnames esperados por nginx (`get-products`, `create-product`, `update-product`, `delete-product`).

---

## 2. Infraestructura de red (VPC)

**Enfoque:** Infraestructura como Código (IaC) con **AWS CloudFormation**, en vez de creación manual por consola. Se validó previamente que AWS Academy Learner Lab permite crear/eliminar stacks CloudFormation reales (prueba con stack `zz-test-stack`, resultado `CREATE_IN_PROGRESS` → eliminado limpiamente) y que los servicios EC2/VPC/ELB/ASG/Backup/ECR están permitidos (confirmado con `--dry-run` en EC2 y create/delete real en ECR).

- **Template:** [`infra/01-red.yaml`](../infra/01-red.yaml)
- **Nombre del stack:** `freshbox-red`
- **Comando de despliegue (ejecutado en AWS CloudShell):**
  ```bash
  aws cloudformation create-stack --stack-name freshbox-red --template-body file://01-red.yaml
  ```

| Recurso | Nombre | Valor / CIDR | AZ | Notas |
|---|---|---|---|---|
| VPC | `freshbox-vpc` | 10.0.0.0/22 | - | |
| Subred pública Web | `freshbox-sub-web-1a` | 10.0.0.0/26 | us-east-1a | Auto-assign IP pública ON (`MapPublicIpOnLaunch: true`) |
| Subred pública Web | `freshbox-sub-web-1b` | 10.0.0.64/26 | us-east-1b | Auto-assign IP pública ON |
| Subred privada App | `freshbox-sub-app-1a` | 10.0.0.128/26 | us-east-1a | |
| Subred privada App | `freshbox-sub-app-1b` | 10.0.0.192/26 | us-east-1b | |
| Subred privada Data | `freshbox-sub-data-1a` | 10.0.1.0/26 | us-east-1a | |
| Subred privada Data | `freshbox-sub-data-1b` | 10.0.1.64/26 | us-east-1b | |
| Internet Gateway | `freshbox-igw` | - | - | Atado a `freshbox-vpc` |
| NAT Gateway | `freshbox-natgw` | - | us-east-1a (en subred pública) | Elastic IP: _pendiente de confirmar tras despliegue_ |
| Route Table pública | `freshbox-rt-public` | ruta 0.0.0.0/0 → IGW | - | Asociada a subredes web |
| Route Table privada | `freshbox-rt-private` | ruta 0.0.0.0/0 → NAT GW | - | Asociada a subredes app + data |

**IDs de recursos (confirmados tras `describe-stacks`, 2026-09-18):**

| Output | Valor |
|---|---|
| VpcId | `vpc-0be08aefab15d0945` |
| SubnetWeb1AId | `subnet-0a40f4c83d8495d9a` |
| SubnetWeb1BId | `subnet-0dc7a0d54e8ec221d` |
| SubnetApp1AId | `subnet-003b9d4445fb50bf0` |
| SubnetApp1BId | `subnet-0f6be67406b652af2` |
| SubnetData1AId | `subnet-0addc2a91142c8715` |
| SubnetData1BId | `subnet-07bfca66144541cee` |
| NatGatewayId | `nat-0684d24f66a51736d` |
| Internet Gateway | `igw-0d0634691ae9d0ece` |
| NAT Elastic IP | `100.27.78.176` |
| Public Route Table | `rtb-006d69391a9eef615` |
| Private Route Table | `rtb-07d378b8b99c8e63d` |

**Estado:** ✅ **CREATE_COMPLETE** — Stack `freshbox-red` desplegado exitosamente en AWS Academy Learner Lab el 2026-09-18.

---

## 3. Security Groups

| SG | Reglas Inbound | Origen |
|---|---|---|
| `freshbox-sg-alb` | 80, 443 | 0.0.0.0/0 |
| `freshbox-sg-app` | 80, 443 | SG del ALB |
| `freshbox-sg-bd` | 3306 | SG de App |

**Estado:** ⬜ Pendiente

---

## 4. EC2 — Capa Data (MySQL/MariaDB)

**Enfoque:** desplegado vía CloudFormation ([`infra/03-compute.yaml`](../infra/03-compute.yaml)), stack `freshbox-compute`, usando MariaDB (wire-compatible con MySQL, paquete nativo de Amazon Linux 2023 — ver nota técnica sección 6).

| Campo | Valor |
|---|---|
| Nombre instancia | `freshbox-ec2-mysql` |
| InstanceId | `i-096324afebf1a0539` |
| Tipo | t4g.small |
| AMI | Amazon Linux 2023 ARM64 (resuelta vía SSM Parameter Store, siempre la más reciente) |
| Subred | `freshbox-sub-data-1a` (`subnet-0addc2a91142c8715`) |
| IP privada | `10.0.1.43` |
| Cifrado EBS | ✅ (gp3, 8GB) |
| Base de datos poblada | ✅ Verificado vía Session Manager (`SELECT * FROM productos` → 5 registros correctos) |
| AWS Backup configurado | ⬜ Pendiente (Tarea 6, no incluido aún en el template) |

**Verificación (2026-09-18, vía AWS Systems Manager, sin SSH):**
```
id      nombre                    precio
1       Manzana organica 1kg      3490.00
2       Lechuga hidroponica       1990.00
3       Granola artesanal 500g    4990.00
4       Jugo natural naranja 1L   2990.00
5       Mix frutos secos 250g     5490.00
```

**Estado:** ✅ Instancia y datos verificados — ⬜ AWS Backup pendiente

---

## 5. EC2 — Capa App

**Enfoque:** desplegadas vía CloudFormation ([`infra/03-compute.yaml`](../infra/03-compute.yaml)), a través de un `AWS::EC2::LaunchTemplate` + `AWS::AutoScaling::AutoScalingGroup` (`freshbox-asg-app`, min 2 / max 4, Multi-AZ sobre subredes `freshbox-sub-app-1a`/`1b`).

**⚠️ Nota importante — reemplazo de instancias por el ASG:** las instancias originales (`i-0cfb5552cdf4faecc`, `i-0d22849f21e783c74`) fueron reemplazadas por el Auto Scaling Group en algún momento tras conectar el ALB (comportamiento normal de auto-healing/mantenimiento del ASG). Las instancias **actuales y vigentes** son las siguientes:

| Campo | Instancia 1 (app-1a) | Instancia 2 (app-1b) |
|---|---|---|
| InstanceId actual | `i-0dd7f85d9dfc342ea` | `i-016e07318bb71bcbe` |
| Estado ASG | Healthy / InService | Healthy / InService |
| Docker + 5 contenedores | ✅ Verificado (`docker ps`, 5/5 Up, 2h) | ✅ Verificado (`docker ps`, 5/5 Up, 2h) |
| Registrado en Target Group ALB | ✅ Healthy | ✅ Healthy |
| Cifrado EBS | ✅ (gp3, 8GB, vía Launch Template) | ✅ (mismo Launch Template) |

**Verificación instancia i-016e07318bb71bcbe (2026-09-18, vía Session Manager):**
```
NAMES            STATUS
frontend         Up 2 hours
delete-product   Up 2 hours
update-product   Up 2 hours
create-product   Up 2 hours
get-products     Up 2 hours
```

**Verificación instancia i-0dd7f85d9dfc342ea (2026-09-18, vía Session Manager):**
```
NAMES            STATUS
frontend         Up 2 hours
delete-product   Up 2 hours
update-product   Up 2 hours
create-product   Up 2 hours
get-products     Up 2 hours
```

**Estado:** ✅ Ambas instancias vigentes con 5/5 contenedores operativos — Multi-AZ y auto-healing del ASG confirmados

---

## 6. Amazon ECR

Repositorios creados y las 5 imágenes construidas y subidas desde AWS CloudShell (2026-09-18). Cuenta AWS: `334767299218`, región `us-east-1`.

| Repositorio | URI | Push realizado |
|---|---|---|
| freshbox-frontend | `334767299218.dkr.ecr.us-east-1.amazonaws.com/freshbox-frontend` | ✅ |
| freshbox-get-products | `334767299218.dkr.ecr.us-east-1.amazonaws.com/freshbox-get-products` | ✅ |
| freshbox-create-product | `334767299218.dkr.ecr.us-east-1.amazonaws.com/freshbox-create-product` | ✅ |
| freshbox-update-product | `334767299218.dkr.ecr.us-east-1.amazonaws.com/freshbox-update-product` | ✅ |
| freshbox-delete-product | `334767299218.dkr.ecr.us-east-1.amazonaws.com/freshbox-delete-product` | ✅ |

**Nota técnica (hallazgo, punto 1.3 del informe):** CloudShell corre en `linux/amd64`; para construir imágenes `linux/arm64` (requeridas por las instancias `t4g.small`/Graviton) fue necesario:
1. Registrar emuladores QEMU: `docker run --privileged --rm tonistiigi/binfmt --install all`
2. Crear un builder con driver `docker-container` (el driver `docker` por defecto no detecta los emuladores registrados): `docker buildx create --name freshbox-builder --driver docker-container --use`
3. Construir con `docker buildx build --platform linux/arm64 --load ...` en vez de `docker build`

**Estado:** ✅ Completo — 5/5 imágenes en ECR

---

## 7. ALB + Target Group + Auto Scaling Group

**Enfoque:** desplegado vía CloudFormation ([`infra/04-alb.yaml`](../infra/04-alb.yaml)), stack `freshbox-alb`. El ASG del stack `freshbox-compute` se conectó al Target Group mediante `update-stack` (parámetro `TargetGroupArn`), y las 2 instancias existentes se registraron manualmente con `aws elbv2 register-targets` (el update de CloudFormation no re-registra instancias ya corriendo).

| Campo | Valor |
|---|---|
| Nombre ALB | `freshbox-alb` |
| DNS del ALB | `freshbox-alb-933788468.us-east-1.elb.amazonaws.com` |
| ARN ALB | `arn:aws:elasticloadbalancing:us-east-1:334767299218:loadbalancer/app/freshbox-alb/1cbf2b4f05bbdfa3` |
| Target Group | `freshbox-tg-app` |
| ARN Target Group | `arn:aws:elasticloadbalancing:us-east-1:334767299218:targetgroup/freshbox-tg-app/de72db1f579fcad9` |
| Health check path | `/` (200 OK) |
| ASG mínimo/máximo | 2 / 4 |
| Targets healthy | ✅ `i-0cfb5552cdf4faecc` (healthy), `i-0d22849f21e783c74` (healthy) |

**Estado:** ✅ CREATE_COMPLETE + ambos targets healthy

---

## 8bis. 🎯 VALIDACIÓN END-TO-END (ALB → EC2 → MySQL) — HITO CRÍTICO

**Comando ejecutado (2026-09-18):**
```bash
curl http://freshbox-alb-933788468.us-east-1.elb.amazonaws.com/api/products
```

**Resultado:** HTTP 200, JSON con los 5 productos reales, consultados en vivo desde MySQL a través de todo el flujo:
`Internet → ALB (SG-ALB) → EC2 App (SG-App, nginx proxy → get-products:3001) → EC2 MySQL (SG-Data, 10.0.1.43)`

```json
[
  {"id":5,"nombre":"Mix frutos secos 250g", ...},
  {"id":4,"nombre":"Jugo natural naranja 1L", ...},
  {"id":3,"nombre":"Granola artesanal 500g", ...},
  {"id":2,"nombre":"Lechuga hidroponica", ...},
  {"id":1,"nombre":"Manzana organica 1kg", ...}
]
```

**Esto confirma:**
- Segmentación de red por capas funcionando (tráfico pasó por las 3 capas correctamente)
- Security Groups encadenados correctamente (ALB→App→Data, sin abrir puertos de más)
- nginx haciendo reverse proxy interno correctamente (fix de la Tarea 1 validado en producción)
- Alta disponibilidad Multi-AZ operativa (2 targets healthy en 2 AZs distintas)

**CRUD completo validado (2026-09-18)** — las 4 operaciones probadas vía `curl` contra el DNS del ALB:

| Método | Comando | Resultado |
|---|---|---|
| GET | `curl .../api/products` | 5 productos listados |
| POST | `curl -X POST .../api/products -d '{"nombre":"Quinoa organica 500g",...}'` | Producto `id:6` creado, HTTP 200 |
| PUT | `curl -X PUT .../api/products/6 -d '{"nombre":"Quinoa organica 1kg",...}'` | Producto `id:6` actualizado (precio 4990→8990, stock 80→50) |
| DELETE | `curl -X DELETE .../api/products/6` | `{"message":"Producto eliminado correctamente","id":6}` |
| GET (verificación) | `curl .../api/products` | Vuelven a aparecer exactamente los 5 productos originales (ids 1-5) |

**✅ Tarea 11 (Validación end-to-end) — 100% COMPLETA.** Este es el bloque de evidencia principal para el indicador 12 (10%) y el checklist "Validación Funcional (Demo CRUD)" de la pauta EP1 — recomendado repetir esta misma secuencia en vivo durante la presentación/demo, usando el frontend web (`http://<ALB-DNS>/`) en vez de `curl` para una demostración más visual.

---

## 8. Validación funcional

- [ ] `curl http://<ALB-DNS>/api/products` devuelve los 5 productos
- [ ] Frontend accesible vía ALB, CRUD operativo (GET, POST, PUT, DELETE)
- [ ] Ambas EC2 App con 5 contenedores corriendo (`docker ps`)
- [ ] AWS Backup con plan activo

---

## 9. Riesgos / hallazgos para el informe (punto 1.3)

- Bug de red original (URLs con puerto fijo) documentado como hallazgo de Fiabilidad y Excelencia Operativa — corregido antes del despliegue.
- _(agregar aquí cualquier otro hallazgo durante el despliegue)_
