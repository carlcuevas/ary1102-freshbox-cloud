# ARY1102 - Arquitectura Cloud | EP1

**Caso:** FreshBox SpA — Plataforma de Catálogo Online de Productos Orgánicos
**Evaluación:** EP1 - Encargo con Presentación (40% de la asignatura)

Este repositorio reúne el entregable completo de la Evaluación Parcial n°1: código fuente de la aplicación, evidencias del despliegue en AWS y las notas técnicas que sirven de base para el informe y la presentación.

## Estructura del repositorio

```
├── codigo/                      Proyecto FreshBox (frontend + 4 microservicios + scripts de despliegue)
├── evidencias/                  Capturas de pantalla de la consola AWS, organizadas por etapa
│   ├── 01-vpc-subredes/         VPC, subredes Multi-AZ, route tables, IGW, NAT Gateway
│   ├── 02-security-groups/      Security Groups segmentados por capa (ALB, App, BD)
│   ├── 03-ec2-mysql/            EC2 capa Data, cifrado EBS, AWS Backup
│   ├── 04-ec2-app/               EC2 capa App (Multi-AZ), Docker, Auto Scaling Group
│   ├── 05-ecr/                   Repositorios ECR con las 5 imágenes Docker
│   ├── 06-alb-targetgroup/       Application Load Balancer y Target Group (health checks)
│   └── 07-validacion-crud/       CRUD funcionando end-to-end vía DNS del ALB
├── notas/
│   └── bitacora.md               Registro técnico de decisiones, recursos creados e IPs/DNS relevantes
└── README.md
```

## Estado del proyecto

- [x] Código corregido (fix de CRUD vía rutas relativas + network-alias)
- [ ] Infraestructura de red (VPC, subredes, IGW, NAT Gateway)
- [ ] Security Groups por capa
- [ ] EC2 MySQL + AWS Backup
- [ ] EC2 App (Multi-AZ) + Docker
- [ ] Imágenes en ECR
- [ ] ALB + Target Group + Auto Scaling Group
- [ ] Validación CRUD end-to-end
- [ ] Informe técnico (secciones 1.1 a 1.7)
- [ ] Presentación + demo en vivo

## Nota

El informe técnico y la presentación se elaborarán **al final**, una vez reunida toda la evidencia en `evidencias/` y la bitácora en `notas/bitacora.md`. Esa documentación es el insumo base para redactar ambos entregables.

---
2026 - FreshBox SpA / DuocUC ARY1102
