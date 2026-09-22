# Evidencia del despliegue

29 capturas de la consola de AWS tomadas durante el despliegue verificado del **18 de septiembre de 2026** (cuenta `334767299218`, región `us-east-1`), organizadas por etapa. A esto se suman 10 recortes en [`recortes-informe/`](recortes-informe/), derivados de estas mismas capturas para insertarlos en el informe.

Los recursos ya no existen: AWS Academy Learner Lab elimina la infraestructura al expirar la sesión. Estas capturas son el registro del estado verificado en esa fecha.

## Índice por etapa

| Carpeta | Capturas | Qué documenta | Requerimientos que respalda |
|---|---|---|---|
| [`01-vpc-subredes/`](01-vpc-subredes/) | 11 | VPC `10.0.0.0/22`, las 6 subredes /26 con su AZ, Internet Gateway, route tables pública y privada, NAT Gateway | R03, R05, R09 |
| [`02-security-groups/`](02-security-groups/) | 3 | Detalle de los 3 Security Groups encadenados, con el conteo de reglas de entrada por capa | R05, R06, R12 |
| [`03-ec2-mysql/`](03-ec2-mysql/) | 1 | EC2 de la capa Data: tipo, subred privada, ausencia de IP pública, volumen EBS cifrado | R06, R07 |
| [`04-ec2-app/`](04-ec2-app/) | 2 | Las dos EC2 de la capa App en AZs distintas, con 3/3 status checks y su pertenencia al Auto Scaling Group | R03, R04, R13 |
| [`05-ecr/`](05-ecr/) | 2 | Los 5 repositorios privados de imágenes y el detalle de las imágenes `latest` con su fecha de último `pull` | R04, R11 |
| [`06-alb-targetgroup/`](06-alb-targetgroup/) | 3 | Application Load Balancer internet-facing, Target Group y los 2 targets en estado `Healthy` | R01, R03 |
| [`07-validacion-crud/`](07-validacion-crud/) | 5 | Secuencia completa del CRUD en el frontend web, a través del DNS público del balanceador | R01, R02 |
| [`08-aws-backup/`](08-aws-backup/) | 2 | Regla del plan de respaldo diario con retención de 7 días y la asignación del recurso a la EC2 de datos | R08 |

## Figuras del informe y su origen

El informe usa 9 figuras. Esta tabla permite rastrear cada una hasta la captura original:

| Figura | Archivo insertado | Captura original |
|---|---|---|
| 1 | `diagramas/diagrama-arquitectura-tobe.png` | Elaboración propia (`.drawio` en `diagramas/`) |
| 2 | `recortes-informe/fig02-vpc-freshbox.png` | `01-vpc-subredes/01-vpc-freshbox.png` |
| 3 | `recortes-informe/fig03-targets-healthy.png` | `06-alb-targetgroup/03-targets-healthy.png` |
| 4 | `recortes-informe/fig04a-ec2-app-1a.png` | `04-ec2-app/01-ec2-app-1a-detalle.png` |
| 5 | `recortes-informe/fig05-backup-plan.png` | `08-aws-backup/01-backup-plan-regla-diaria.png` |
| 6 | `recortes-informe/fig06-ecr-repos.png` | `05-ecr/01-repositorios-listado.png` |
| 7 (a) y (b) | `recortes-informe/fig07a-route-table-privada.png`, `fig07b-nat-gateway.png` | `01-vpc-subredes/10-route-table-privada.png`, `11-nat-gateway.png` |
| 8 (a) y (b) | `recortes-informe/fig08a-sg-app.png`, `fig08b-sg-bd.png` | `02-security-groups/02-sg-app-detalle.png`, `03-sg-bd-detalle.png` |
| 9 (a), (b) y (c) | `07-validacion-crud/01-get-listado-inicial.png`, `03-post-producto-creado.png`, `05-delete-listado-final.png` | las mismas, sin recortar |

`recortes-informe/fig04b-ec2-app-1b.png` se preparó pero no se usó: la captura de la Figura 4 ya muestra las tres instancias con sus zonas y status checks, además del panel de detalle, por lo que el segundo recorte resultaba redundante.

## Sobre los recortes

Los archivos de `recortes-informe/` se generaron con [`herramientas/recortar_png.py`](../herramientas/recortar_png.py), una utilidad sin dependencias externas que decodifica el PNG, aplica el recorte pedido y lo vuelve a codificar. El objetivo es acotar cada captura a la región que su pie de figura describe, de modo que el texto de la consola resulte legible al ancho de página del informe:

```bash
python3 herramientas/recortar_png.py entrada.png salida.png IZQ ARRIBA DER ABAJO
```

Las capturas originales se conservan íntegras en las carpetas `01` a `08`, sin recortar ni reescalar, como registro completo del despliegue.
