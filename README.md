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
├── infra/                       Plantillas CloudFormation (IaC) de toda la arquitectura
├── diagramas/                   Diagrama de arquitectura TO-BE (.drawio, .xml y .png)
├── notas/
│   ├── bitacora.md               Registro técnico: IDs reales, decisiones, hallazgos y runbook de redespliegue
│   └── insumo-informe-y-presentacion.md   Material estructurado para redactar el informe y armar la presentación
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

## Documentos clave

| Documento | Para qué sirve |
|---|---|
| [`notas/bitacora.md`](notas/bitacora.md) | Bitácora técnica: IDs reales de todos los recursos, decisiones justificadas, 11 hallazgos mapeados a pilares Well-Architected, y el **runbook de redespliegue** completo |
| [`notas/insumo-informe-y-presentacion.md`](notas/insumo-informe-y-presentacion.md) | Material estructurado e indicador por indicador para **redactar el informe técnico (1.1 a 1.7) y armar la presentación (2.1 a 2.5)** |

## Estado

La **parte técnica está completa y verificada**: los 16 componentes de la arquitectura TO-BE exigida por el caso están desplegados en AWS, con 29 capturas de evidencia y validación CRUD end-to-end.

Pendiente: informe técnico (PDF/Word, máx. 20 págs), presentación PowerPoint y ensayo de redespliegue.

⚠️ **AWS Academy Learner Lab elimina los recursos al expirar.** Si eso ocurre, el runbook de `notas/bitacora.md` §10 recrea todo en ~15-20 minutos — pero los IDs y el DNS del ALB cambiarán.

---
2026 - FreshBox SpA / DuocUC ARY1102
