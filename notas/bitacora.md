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

**IDs de recursos (completar tras `describe-stacks`):**

| Output | Valor |
|---|---|
| VpcId | _pendiente_ |
| SubnetWeb1AId | _pendiente_ |
| SubnetWeb1BId | _pendiente_ |
| SubnetApp1AId | _pendiente_ |
| SubnetApp1BId | _pendiente_ |
| SubnetData1AId | _pendiente_ |
| SubnetData1BId | _pendiente_ |
| NatGatewayId | _pendiente_ |

**Estado:** ⬜ Template listo y subido al repo — pendiente de ejecutar `create-stack` en el Lab y confirmar `CREATE_COMPLETE`

---

## 3. Security Groups

| SG | Reglas Inbound | Origen |
|---|---|---|
| `freshbox-sg-alb` | 80, 443 | 0.0.0.0/0 |
| `freshbox-sg-app` | 80, 443 | SG del ALB |
| `freshbox-sg-bd` | 3306 | SG de App |

**Estado:** ⬜ Pendiente

---

## 4. EC2 — Capa Data (MySQL)

| Campo | Valor |
|---|---|
| Nombre instancia | `freshbox-ec2-mysql` |
| Tipo | t4g.small |
| AMI | Amazon Linux 2023 ARM |
| Subred | `freshbox-sub-data-1a` |
| IP privada | _pendiente_ |
| Cifrado EBS | ⬜ |
| AWS Backup configurado | ⬜ |
| init.sql ejecutado | ⬜ |

**Estado:** ⬜ Pendiente

---

## 5. EC2 — Capa App

| Campo | Instancia 1 | Instancia 2 |
|---|---|---|
| Nombre | `freshbox-ec2-app-1a` | `freshbox-ec2-app-1b` |
| Subred | `freshbox-sub-app-1a` | `freshbox-sub-app-1b` |
| IP privada | _pendiente_ | _pendiente_ |
| Docker instalado | ⬜ | ⬜ |
| Cifrado EBS | ⬜ | ⬜ |

**Estado:** ⬜ Pendiente

---

## 6. Amazon ECR

| Repositorio | URI | Push realizado |
|---|---|---|
| freshbox-frontend | | ⬜ |
| freshbox-get-products | | ⬜ |
| freshbox-create-product | | ⬜ |
| freshbox-update-product | | ⬜ |
| freshbox-delete-product | | ⬜ |

**Estado:** ⬜ Pendiente

---

## 7. ALB + Target Group + Auto Scaling Group

| Campo | Valor |
|---|---|
| Nombre ALB | `freshbox-alb` |
| DNS del ALB | _pendiente_ |
| Target Group | `freshbox-tg-app` |
| Health check path | `/` |
| ASG mínimo/máximo | 2 / 4 |

**Estado:** ⬜ Pendiente

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
