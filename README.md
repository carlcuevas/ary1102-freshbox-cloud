# FreshBox SpA — Arquitectura Cloud de tres capas en AWS

Entregable completo de la **Evaluación Parcial N°1** de ARY1102 (Arquitectura Cloud), Escuela de Informática y Telecomunicaciones, DuocUC.

El caso pide diseñar y desplegar la plataforma de catálogo online de **FreshBox SpA**, una empresa chilena de productos orgánicos con despacho a domicilio que crece un 40% trimestral. Este repositorio contiene el informe técnico, la infraestructura como código, el código de la aplicación y la evidencia del despliegue real en AWS.

El alcance de esta etapa es el **catálogo administrable de productos**. El carrito de compras y el procesamiento de órdenes quedan explícitamente fuera y se abordarán en etapas posteriores.

---

## Desplegar

Desde **AWS CloudShell**, con el laboratorio activo. Una línea, sin clonar nada a mano:

```bash
curl -sL https://raw.githubusercontent.com/carlcuevas/ary1102-freshbox-cloud/main/bootstrap.sh | bash
```

Eso clona el repositorio y levanta la arquitectura completa: los 5 stacks de CloudFormation, las 5 imágenes Docker compiladas para ARM64 y publicadas en Amazon ECR, el Auto Scaling Group conectado al balanceador y el respaldo diario configurado. Termina imprimiendo el DNS público del catálogo. Toma unos 18 minutos y no requiere interacción.

Si prefieres clonar primero:

```bash
git clone https://github.com/carlcuevas/ary1102-freshbox-cloud.git
cd ary1102-freshbox-cloud
./up.sh
```

El resto del ciclo de vida:

| Comando | Qué hace |
|---|---|
| `./up.sh` | Despliega todo y verifica que quede operativo (~18 min) |
| `./up.sh --sin-imagenes` | Igual, pero reutiliza las imágenes ya publicadas en ECR (~7 min) |
| `./infra/verify.sh` | Comprueba stacks, targets *healthy* y que el catálogo responda |
| `./infra/demo.sh todo` | Recorrido de demostración: red, seguridad, alta disponibilidad, contenedores, CRUD |
| `./infra/teardown.sh` | Elimina toda la infraestructura |

Con `make` disponible: `make up`, `make check`, `make demo`, `make down`, y `make local` para levantar la aplicación en Docker Compose sin tocar AWS. `make help` lista todo.

Los scripts resuelven cada recurso **por nombre y no por identificador**, así que funcionan igual después de cada redespliegue: el laboratorio académico borra los recursos al expirar y los IDs cambian, los nombres lógicos no.

---

## Dónde está cada cosa

| Si buscas | Ve a |
|---|---|
| **El informe entregado** — 20 páginas, puntos 1.1 a 1.7, 9 figuras, bibliografía APA v7 | [`informe/Informe-EP1-FreshBox-Carlos-Cuevas.pdf`](informe/Informe-EP1-FreshBox-Carlos-Cuevas.pdf) |
| **La presentación de defensa** — 13 diapositivas más 3 anexos, con notas del orador | [`presentacion/`](presentacion/) |
| **Cómo se despliega, paso a paso** — plantillas, parámetros, verificación y desmontaje | [`infra/README.md`](infra/README.md) |
| **La evidencia del despliegue** — 29 capturas de la consola AWS, por etapa | [`evidencias/README.md`](evidencias/README.md) |
| **La aplicación y cómo correrla en local** — frontend y 4 microservicios | [`codigo/README.md`](codigo/README.md) |
| **Decisiones, hallazgos y runbook** — identificadores reales y 11 hallazgos por pilar | [`notas/bitacora.md`](notas/bitacora.md) |
| **El diagrama de arquitectura** — editable en `.drawio` | [`diagramas/`](diagramas/) |
| La fuente versionada del informe, en Markdown | [`informe/informe-ep1-freshbox.md`](informe/informe-ep1-freshbox.md) |

---

## Arquitectura implementada

![Arquitectura TO-BE](diagramas/diagrama-arquitectura-tobe.png)

Arquitectura de tres capas sobre una VPC `10.0.0.0/22`, con seis subredes /26 distribuidas en dos zonas de disponibilidad de `us-east-1`.

| Capa | Componentes | Aislamiento |
|---|---|---|
| **Web** (pública) | Application Load Balancer `freshbox-alb`, internet-facing en 2 AZs | `freshbox-sg-alb`: 80/443 desde Internet |
| **App** (privada) | 2 × EC2 `t4g.small` bajo Auto Scaling Group `freshbox-asg-app` (mín. 2 / máx. 4), 5 contenedores Docker cada una | `freshbox-sg-app`: solo tráfico cuyo origen es el SG del ALB |
| **Data** (privada) | EC2 `t4g.small` con MariaDB, volumen EBS cifrado, respaldo diario vía AWS Backup | `freshbox-sg-bd`: solo 3306 desde el SG de App |

Servicios de soporte: **Amazon ECR** (5 repositorios de imágenes ARM64), **NAT Gateway** para la salida controlada de las subredes privadas, **AWS Systems Manager Session Manager** para administración sin SSH ni llaves, **AWS Backup** con retención de 7 días y **AWS CloudFormation** para la totalidad de la infraestructura.

**Decisiones de diseño relevantes**

- Los Security Groups se encadenan **referenciando el SG de origen**, no rangos de IP, de modo que las reglas siguen siendo válidas cuando el Auto Scaling Group reemplaza instancias.
- Las instancias usan **AWS Graviton (ARM64)** por relación precio-rendimiento, lo que obligó a construir las imágenes Docker para `linux/arm64` con `docker buildx` y emuladores QEMU.
- La AMI se resuelve dinámicamente vía **SSM Parameter Store**, sin AMI ID fijo en las plantillas.
- Se instaló **MariaDB** en lugar de MySQL Server: es el motor *wire-compatible* disponible nativamente en Amazon Linux 2023, y evita agregar repositorios externos.

---

## Estructura del repositorio

```
.
├── bootstrap.sh               Clona y despliega en una línea (curl … | bash)
├── up.sh                      Despliegue completo con un comando
├── Makefile                   Atajos: make up · check · demo · down · local
├── codigo/                    Aplicación: frontend nginx + 4 microservicios Node.js
│   ├── microservicioFrontend/   HTML/CSS/JS + nginx como reverse proxy interno
│   ├── microserviciosBackend/   get / create / update / delete-product
│   ├── scripts/                 Push a ECR, despliegue de contenedores, user-data
│   ├── docker-compose.yml       Entorno local de prueba
│   └── init.sql                 Esquema y datos iniciales del catálogo
├── infra/                     Infraestructura como código (CloudFormation)
│   ├── 01-red.yaml              VPC, 6 subredes, IGW, NAT Gateway, route tables
│   ├── 02-security-groups.yaml  3 Security Groups encadenados por capa
│   ├── 03-compute.yaml          EC2 MariaDB + Launch Template + Auto Scaling Group
│   ├── 04-alb.yaml              Application Load Balancer + Target Group
│   └── 05-backup.yaml           Vault, plan diario y asignación de recurso
├── evidencias/                Capturas de la consola AWS, por etapa del despliegue
├── diagramas/                 Diagrama de arquitectura TO-BE
├── informe/                   Informe técnico (PDF entregado + fuente Markdown)
├── presentacion/              Presentación de defensa (PowerPoint con notas del orador)
├── notas/bitacora.md          Bitácora técnica y runbook de redespliegue
└── herramientas/              Utilidad para recortar capturas (stdlib, sin dependencias)
```

---

## Hallazgos y brechas declaradas

El informe declara explícitamente las limitaciones del diseño en lugar de presentarlo como cerrado. Resumen de las brechas vigentes y su ruta de mejora (desarrolladas en el punto 1.3 del informe):

| Brecha | Pilar afectado | Mejora propuesta |
|---|---|---|
| ALB sin listener HTTPS (solo puerto 80) | Seguridad | Certificado ACM + listener 443, TLS ≥ 1.2 y redirección 80→443 |
| Contraseña de BD como parámetro del template (`NoEcho`) | Seguridad | AWS Secrets Manager o SSM Parameter Store `SecureString` con rotación |
| NAT Gateway único en `us-east-1a` | Fiabilidad | Un NAT Gateway por AZ, con route table privada por zona |
| Base de datos autoadministrada en EC2, sin réplica | Fiabilidad / Excelencia operativa | Amazon RDS for MySQL Multi-AZ |
| Sin observabilidad (métricas, logs centralizados, alarmas) | Excelencia operativa | CloudWatch Agent, un log group por microservicio, alarmas de 5XX y CPU |
| ASG sin política de escalado dinámico | Eficiencia del rendimiento | Target Tracking Scaling sobre CPU o `RequestCountPerTarget` |
| `HealthCheckType: EC2` en el ASG, no `ELB` | Fiabilidad | Cambiar a `ELB` y apuntar el health check a `/api/products` |
| IP privada de la BD inyectada en el UserData | Fiabilidad | Resolución por DNS privado (Route 53) o endpoint gestionado de RDS |

Durante el desarrollo se detectaron y corrigieron además cuatro defectos reales: el frontend llamaba a puertos fijos en lugar de rutas relativas (habría fallado detrás del ALB), los nombres de contenedor no coincidían con los hostnames que resuelve nginx, las imágenes `amd64` eran incompatibles con las instancias Graviton, y MySQL Server no está disponible en los repositorios de Amazon Linux 2023. Cada uno está documentado con su causa y su mitigación en [`notas/bitacora.md`](notas/bitacora.md).

---

## Despliegue verificado

| | |
|---|---|
| Cuenta AWS | `334767299218` (AWS Academy Learner Lab) |
| Región | `us-east-1` |
| Fecha de verificación | 18 de septiembre de 2026 |
| DNS del balanceador | `freshbox-alb-933788468.us-east-1.elb.amazonaws.com` |
| Validación funcional | CRUD completo (GET/POST/PUT/DELETE) end-to-end a través del ALB |

> **Los recursos ya no existen.** AWS Academy Learner Lab elimina la infraestructura al expirar la sesión del laboratorio, por lo que el DNS y los identificadores citados corresponden al despliegue verificado en la fecha indicada y no a un entorno activo. El repositorio conserva la infraestructura como código y el runbook necesarios para recrear el entorno completo; al hacerlo, los identificadores y el DNS cambian, mientras que los nombres lógicos y los CIDR se mantienen.

---

## Autoría

**Carlos Cuevas** — carl.cuevasn@duocuc.cl · Sección ARY1102 · Docente: Rodrigo Horacio Aguilar González

La aplicación de catálogo fue entregada como base por la asignatura — diseñador: Ignacio A. Pastenet M. El trabajo de arquitectura cloud, la infraestructura como código, la corrección de los defectos del código, el despliegue en AWS y la documentación corresponden a este entregable.

Material académico desarrollado para DuocUC. Las credenciales presentes en el código y en las plantillas son de laboratorio, no productivas; su gestión adecuada está declarada como brecha de seguridad en el informe.
