# Insumo para elaborar el Informe Técnico y la Presentación — EP1 ARY1102

> **Para quién es este documento:** para quien redacte el informe técnico y arme la presentación del EP1 (caso FreshBox SpA).
>
> **Qué es:** material estructurado y **trazable a lo que realmente se desplegó en AWS**. No es el informe redactado; es el insumo para escribirlo sin inventar nada genérico.
>
> **Documento complementario obligatorio:** [`bitacora.md`](./bitacora.md) — contiene IDs reales de recursos, decisiones técnicas, hallazgos y el runbook de redespliegue.

---

# PARTE 0 — Especificación de los entregables

## Entregable 1: Informe técnico (40% del EP1)

**Formato obligatorio según la pauta:**
- Archivo **único** en PDF o Word
- Extensión **máxima 20 páginas**
- Estructura obligatoria, en este orden:
  1. **Portada** — con nombre, **sección** y fecha
  2. **Índice**
  3. **Introducción**
  4. **Desarrollo** — debe contener los puntos 1.1 a 1.7
  5. **Conclusiones**
  6. **Bibliografía** en normativa **APA v7**
- Debe incluir evidencias gráficas y diagramas con nomenclatura legible
- Entrega individual por Blackboard (AVA)

⚠️ **Datos que hay que pedirle al estudiante para la portada:** nombre completo, **sección** (no está registrada en ningún lugar del repositorio) y fecha de entrega. Correo institucional conocido: `carl.cuevasn@duocuc.cl`.

## Entregable 2: Presentación + demo (60% del EP1)

- PowerPoint (presentación ejecutiva técnica)
- **Demo técnica en vivo** en la consola de AWS Academy Learner Lab
- Duración estricta: **10 minutos**
- Debe cubrir los puntos 2.1 a 2.5 de la pauta

---

# PARTE 1 — Mapa de la rúbrica (12 indicadores)

| # | Indicador | Peso | Dónde se evalúa | Insumo en este documento |
|---|---|---|---|---|
| 1 | Fundamenta el rol del arquitecto cloud | 5% | Informe 1.1 | §1.1 |
| 2 | Explica los pilares Well-Architected | 5% | Informe 1.2 | §1.2 |
| 3 | Analiza arquitectura e identifica mejoras por pilar | 5% | Informe 1.3 | §1.3 + bitácora §11 |
| 4 | Prioriza requerimientos técnicos y de negocio | 5% | Informe 1.4 | §1.4 |
| 5 | Compara nube pública / privada / híbrida | 5% | Informe 1.5 | §1.5 |
| 6 | Justifica la selección del modelo cloud | 5% | Informe 1.6 | §1.6 |
| 7 | Valida HA, escalabilidad y buenas prácticas | **10%** | Informe 1.7 | §1.7 |
| 8 | Analiza el caso empresarial y decisiones cloud | **10%** | Presentación | §2.1 |
| 9 | Levanta requerimientos funcionales y no funcionales | **10%** | Presentación | §2.2 |
| 10 | Diseña el diagrama TO-BE de 3 capas | **15%** | Ambos | §2.3 |
| 11 | Configura red y aislamiento de seguridad perimetral | **15%** | Demo en vivo | §2.4 |
| 12 | Despliega aplicación en contenedores | **10%** | Demo en vivo | §2.5 |

## ⚠️ Lo que la rúbrica castiga explícitamente

Leer estos descriptores antes de escribir, porque marcan la diferencia entre 100% y 60%:

- Indicador 2, nivel 60%: *"Explica solo algunos de los pilares con **ejemplos genéricos que no se vinculan de manera directa** a las necesidades de la organización"*
- Indicador 3, nivel 60%: *"Identifica **hallazgos superficiales**, proponiendo recomendaciones **genéricas o parciales**"*
- Indicador 5, nivel 30%: *"Menciona los modelos de nube, pero **se limita a listarlos** sin establecer un análisis comparativo"*
- Indicador 6, nivel 60%: *"Justifica el modelo cloud adecuado pero la descripción **es técnica y no estratégica** a los objetivos de negocio"*

**Regla práctica:** cada afirmación conceptual debe ir seguida de su anclaje concreto en este despliegue (nombre de recurso real, CIDR, ID, decisión tomada, o hallazgo documentado). Este documento está construido para permitir eso.

---

# PARTE 2 — Contexto del caso (base para todo)

**Empresa:** FreshBox SpA — venta online de productos orgánicos y saludables (frutas, verduras, snacks, bebidas naturales), con despacho a domicilio en la **Región Metropolitana**, Chile.

**Situación:** crecimiento sostenido del **40% trimestral**; necesita modernizar su plataforma tecnológica en la nube.

**Alcance de esta etapa (EP1):** catálogo online administrable de productos. Carrito de compras y procesamiento de órdenes quedan **explícitamente fuera**, para etapas posteriores.

**Necesidades declaradas por la organización:**
1. Visualización de productos
2. Administración de productos
3. Escalabilidad automática
4. Alta disponibilidad
5. Optimización operacional y financiera

**Implicancia clave del 40% trimestral** (útil para justificar casi todo): un crecimiento compuesto de 40% por trimestre implica multiplicar la carga aproximadamente **×3,8 en un año** (1,4⁴ ≈ 3,84). Esto hace que dimensionar infraestructura fija sea inviable: o se sobredimensiona (desperdicio de capital) o se subdimensiona (caídas en campañas). Es el argumento central para elasticidad y para el modelo OPEX.

---

# PARTE 3 — Insumo por sección del INFORME

## §1.1 — Fundamentación del Rol del Arquitecto Cloud (5%)

La pauta pide tres cosas: definición del rol, responsabilidades técnicas y estratégicas, y alineación entre decisiones de arquitectura y objetivos del negocio.

**Definición sugerida (a redactar con palabras propias):** el arquitecto cloud es el responsable de traducir objetivos de negocio en una arquitectura técnica sostenible, definiendo estructura, estándares y restricciones de la solución, y actuando como puente entre la dirección (que fija metas de crecimiento, costo y riesgo) y los equipos de implementación.

**Responsabilidades técnicas — con evidencia de que se ejercieron en este proyecto:**

| Responsabilidad | Cómo se ejerció aquí (verificable) |
|---|---|
| Diseño de topología de red y aislamiento | VPC `10.0.0.0/22` segmentada en 3 capas y 6 subredes Multi-AZ |
| Definición del modelo de seguridad perimetral | 3 Security Groups encadenados por referencia de SG, no por IP |
| Selección de servicios y tipos de instancia | `t4g.small` (Graviton/ARM) por relación precio-rendimiento |
| Definición de la estrategia de despliegue | Contenedores Docker + Amazon ECR + user-data automatizado |
| Estandarización y reproducibilidad | Toda la infraestructura como código: 5 stacks CloudFormation |
| Gestión de riesgos técnicos | Detección y corrección de 2 defectos de la aplicación **antes** de desplegar (bitácora §1) |
| Adaptación a restricciones institucionales | Reutilización de `LabRole`/`LabInstanceProfile` ante la imposibilidad de crear roles IAM |

**Responsabilidades estratégicas:**
- Alinear la capacidad técnica con la meta de crecimiento (40% trimestral) sin comprometer capital
- Definir el modelo de costos (OPEX elástico en vez de CAPEX fijo)
- Gestionar el riesgo de continuidad operacional (HA Multi-AZ, respaldos)
- Establecer una base evolutiva: la etapa 1 (catálogo) debe poder crecer a carrito y órdenes sin rediseñar la red

**Alineación decisión ↔ objetivo de negocio (tabla de alto valor para este punto):**

| Objetivo del negocio | Decisión de arquitectura | Resultado medible |
|---|---|---|
| Soportar 40% de crecimiento trimestral | Auto Scaling Group `min 2 / max 4` | Capacidad duplicable sin intervención humana |
| Continuidad del servicio (no perder ventas) | ALB + 2 AZs + health checks | Auto-healing verificado: el ASG reemplazó instancias sin caída del servicio |
| Optimización financiera | `t4g.small` Graviton + pago por uso + elasticidad | Sin inversión en hardware; se paga la capacidad efectivamente usada |
| Protección de la información de productos | Cifrado EBS + segmentación en 3 capas + BD sin acceso desde Internet | La capa de datos solo acepta 3306 desde el SG de aplicación |
| Agilidad para las siguientes etapas | Microservicios en contenedores + ECR | Agregar el servicio de carrito no requiere tocar la red ni la BD |
| Reducir riesgo operacional humano | IaC (CloudFormation) + SSM Session Manager | Entorno reproducible en ~15-20 min; cero llaves SSH |

---

## §1.2 — Pilares del Well-Architected Framework (5%)

La pauta exige: describir los 6 pilares, **aplicar cada uno al contexto de FreshBox SpA**, y vincularlos con las necesidades empresariales del caso.

⚠️ No describir los pilares en abstracto. Usar esta tabla: cada pilar con su definición breve + **su aplicación concreta en este despliegue** + la necesidad del caso que atiende.

### 1. Excelencia Operativa
- **Aplicación real:** toda la infraestructura definida como código en 5 plantillas CloudFormation (`01-red`, `02-security-groups`, `03-compute`, `04-alb`, `05-backup`); AMI resuelta dinámicamente vía SSM Parameter Store (sin AMI ID hardcodeado); provisionamiento de la base de datos y de los 5 contenedores automatizado por `UserData`; administración vía **SSM Session Manager**, sin SSH ni llaves.
- **Necesidad del caso que atiende:** "optimización operacional" — el entorno completo se recrea de forma reproducible en ~15-20 minutos.

### 2. Seguridad
- **Aplicación real:** segmentación en 3 capas; Security Groups encadenados (`SG-alb` ← Internet 80/443; `SG-app` ← solo SG-alb; `SG-bd` ← solo SG-app en 3306) referenciando **SG de origen y no rangos de IP**, de modo que la regla sigue siendo válida cuando el ASG reemplaza instancias; volúmenes **EBS cifrados** en App y Data; base de datos sin ruta de entrada desde Internet; instancias con `LabInstanceProfile` cuya política de ECR es **solo lectura** (el `push` se hace con otra identidad).
- **Necesidad del caso:** proteger la información del catálogo y cumplir buenas prácticas.

### 3. Fiabilidad
- **Aplicación real:** despliegue Multi-AZ (`us-east-1a` y `us-east-1b`) en las 3 capas; ALB con health check en `/` y 2 targets *healthy*; Auto Scaling Group con mínimo 2 instancias; **auto-healing comprobado empíricamente** (el ASG reemplazó las instancias originales manteniendo el servicio operativo); AWS Backup con plan diario y retención de 7 días.
- **Necesidad del caso:** "alta disponibilidad".

### 4. Eficiencia del Rendimiento
- **Aplicación real:** instancias **Graviton (ARM64)** `t4g.small`, elegidas por su relación precio-rendimiento; distribución de carga por ALB entre AZs; arquitectura de microservicios en contenedores que permite escalar el catálogo (lectura) independientemente de las operaciones administrativas; nginx como reverse proxy resolviendo el enrutamiento por método HTTP dentro del host, sin saltos de red adicionales.
- **Necesidad del caso:** sostener el crecimiento sin degradar la experiencia.

### 5. Optimización de Costos
- **Aplicación real:** ausencia total de CAPEX (sin servidores ni datacenter); `t4g.small` (familia Graviton, más económica que su equivalente x86); ASG dimensionado en el mínimo necesario para HA (2) con techo controlado (4); una sola instancia de base de datos en esta etapa, coherente con el alcance real (catálogo, sin transacciones de compra).
- **Necesidad del caso:** "optimización financiera".

### 6. Sostenibilidad
- **Aplicación real:** procesadores Graviton, más eficientes en consumo energético por unidad de trabajo según AWS; *right-sizing* deliberado (`t4g.small`, no instancias sobredimensionadas); contenedores, que permiten mayor densidad de servicios por instancia (5 microservicios por host en lugar de 5 servidores); elasticidad que libera recursos cuando no se necesitan.
- **Necesidad del caso:** alineación con la identidad de la empresa (productos orgánicos / sostenibilidad).

> **Nota sobre cifras:** si se citan porcentajes de mejora de Graviton o de eficiencia energética, **verificar y citar la documentación oficial de AWS** con su fecha de acceso. No inventar cifras.

---

## §1.3 — Análisis de Arquitectura según Well-Architected (5%)

La pauta exige: riesgos identificados, oportunidades de mejora **por pilar**, y recomendaciones específicas.

**Fuente completa:** [`bitacora.md`](./bitacora.md) §11 contiene los 11 hallazgos reales del despliegue. Aquí la síntesis organizada por pilar:

### Riesgos detectados y ya mitigados (fortalece la credibilidad del análisis)

| Hallazgo | Pilar | Mitigación aplicada |
|---|---|---|
| El frontend llamaba a puertos fijos 3001-3004; funcionaba en local pero habría fallado detrás del ALB (las EC2 están en subred privada y el ALB solo expone 80/443) | Fiabilidad · Excelencia Operativa | Migración a rutas relativas `/api/products` con nginx como reverse proxy interno |
| Los nombres de contenedor no coincidían con los hostnames que nginx resuelve | Excelencia Operativa | `--network-alias` en el despliegue |
| Imágenes construidas para amd64 son incompatibles con instancias Graviton (ARM64) | Excelencia Operativa · Eficiencia | Build multiplataforma con emuladores QEMU + `docker buildx` |
| Amazon Linux 2023 no incluye MySQL Server en sus repositorios | Mantenibilidad | MariaDB (*wire-compatible* con MySQL), sin agregar repositorios externos |

### Riesgos vigentes y oportunidades de mejora (el núcleo de este punto)

| # | Riesgo / oportunidad | Pilar | Recomendación específica |
|---|---|---|---|
| 1 | El ALB no tiene listener HTTPS (solo 80); el tráfico viaja sin cifrar | **Seguridad** | Emitir certificado en **AWS Certificate Manager**, agregar listener 443 con política TLS ≥ 1.2 y redirección 80→443 |
| 2 | La contraseña de la base de datos está en el parámetro del template (mitigada con `NoEcho`, pero presente) | **Seguridad** | Migrar a **AWS Secrets Manager** (o SSM Parameter Store `SecureString`) con rotación automática, e inyectarla en tiempo de arranque |
| 3 | **Un solo NAT Gateway**, ubicado en `us-east-1a`: si falla esa AZ, las subredes privadas de ambas AZs pierden salida a Internet | **Fiabilidad** | Desplegar un NAT Gateway **por AZ**, con una route table privada por zona |
| 4 | Base de datos autoadministrada en EC2: los parches, respaldos y un eventual failover son responsabilidad del equipo | **Fiabilidad** · Excelencia Operativa | Migrar a **Amazon RDS for MySQL Multi-AZ**: failover automático, respaldos y parches gestionados, réplicas de lectura para el catálogo |
| 5 | Sin observabilidad: no hay métricas de aplicación, ni logs centralizados de los contenedores, ni alarmas | **Excelencia Operativa** · Fiabilidad | Instalar **CloudWatch Agent**, un log group por microservicio, y alarmas sobre `UnHealthyHostCount`, `HTTPCode_ELB_5XX_Count` y CPU del ASG |
| 6 | Escalado del ASG sin política dinámica: el rango 2-4 existe, pero no hay regla que dispare el escalado | Eficiencia · Fiabilidad | Definir **Target Tracking Scaling** (p. ej. CPU promedio 60% o `RequestCountPerTarget`) |
| 7 | ECR sin política de ciclo de vida: las imágenes antiguas se acumulan indefinidamente | Optimización de Costos | Configurar **lifecycle policy** (conservar las N últimas, expirar *untagged*) |
| 8 | Instancias on-demand sin compromiso de uso | Optimización de Costos | Evaluar **Savings Plans / Reserved Instances** para la capacidad base (las 2 instancias mínimas), manteniendo on-demand el pico |
| 9 | El frontend se sirve desde las instancias EC2, sin caché de borde | Eficiencia · Costos | Publicar los estáticos vía **Amazon CloudFront** (+ S3), reduciendo carga y latencia |
| 10 | Sin protección perimetral de capa 7 | Seguridad | Asociar **AWS WAF** al ALB (reglas gestionadas contra inyección SQL y bots) |

> Las filas 3, 4 y 5 son las más valiosas: son hallazgos **específicos de esta arquitectura**, detectados en el despliegue real, no observaciones de manual.

---

## §1.4 — Priorización de Requerimientos (5%)

La pauta exige: clasificación de requerimientos técnicos y de negocio, **criterios** y tabla de priorización (alta/media/baja), y propuesta de solución alineada a lo priorizado.

### Criterios de priorización utilizados (declararlos explícitamente en el informe)

| Criterio | Qué evalúa |
|---|---|
| **Impacto en el negocio** | Cuánto afecta la capacidad de vender o administrar el catálogo |
| **Riesgo de no implementarlo** | Consecuencia operacional, financiera o de seguridad de omitirlo |
| **Dependencia técnica** | Si otros componentes no pueden construirse sin él |
| **Alineación con el alcance del EP1** | Si corresponde a esta etapa (catálogo) o a etapas posteriores |

### Matriz de priorización

| ID | Requerimiento | Tipo | Impacto negocio | Riesgo si no se implementa | Dependencia | **Prioridad** | Componente que lo implementa |
|---|---|---|---|---|---|---|---|
| R01 | Consultar catálogo (listado y detalle) | Funcional / Negocio | Alto | No hay producto que mostrar | — | **Alta** | `get-products` + ALB |
| R02 | Administrar productos (crear, modificar, eliminar) | Funcional / Negocio | Alto | El catálogo queda estático | R01 | **Alta** | `create/update/delete-product` |
| R03 | Alta disponibilidad Multi-AZ | No funcional / Técnico | Alto | Caída de una AZ deja la tienda fuera de línea | Red | **Alta** | ALB + ASG en 2 AZs + 6 subredes |
| R04 | Escalabilidad automática | No funcional / Técnico | Alto | El crecimiento de 40% trimestral degrada el servicio | Cómputo | **Alta** | ASG `min 2 / max 4` |
| R05 | Aislamiento de red por capas | No funcional / Seguridad | Alto | Exposición directa de la base de datos | Red | **Alta** | 3 capas + 3 SGs encadenados |
| R06 | Base de datos no accesible desde Internet | No funcional / Seguridad | Alto | Riesgo de exfiltración de datos | R05 | **Alta** | Subred privada Data + `SG-bd` 3306 solo desde `SG-app` |
| R07 | Cifrado de datos en reposo | No funcional / Seguridad | Medio | Datos legibles ante acceso al volumen | Cómputo | **Alta** | EBS Encryption en App y Data |
| R08 | Respaldo y recuperación | No funcional / Continuidad | Alto | Pérdida irrecuperable del catálogo | Data | **Alta** | AWS Backup diario, retención 7 días |
| R09 | Salida controlada a Internet desde subredes privadas | No funcional / Técnico | Medio | Las instancias no pueden obtener imágenes ni parches | Red | **Alta** | NAT Gateway |
| R10 | Despliegue reproducible (IaC) | No funcional / Operacional | Medio | Configuración manual, no auditable, difícil de recrear | — | **Media** | 5 stacks CloudFormation |
| R11 | Portabilidad de la aplicación | No funcional / Técnico | Medio | Dependencia del host, despliegues inconsistentes | Cómputo | **Media** | Docker + Amazon ECR |
| R12 | Administración sin exponer SSH | No funcional / Seguridad | Medio | Superficie de ataque y gestión de llaves | Cómputo | **Media** | SSM Session Manager |
| R13 | Optimización de costos | No funcional / Negocio | Medio | Gasto superior al necesario | Cómputo | **Media** | Graviton `t4g.small` + elasticidad |
| R14 | Observabilidad (métricas, logs, alarmas) | No funcional / Operacional | Medio | Fallas detectadas por el cliente, no por el equipo | Cómputo | **Media** ⚠️ *no implementado* | CloudWatch (mejora propuesta) |
| R15 | Cifrado en tránsito (HTTPS) | No funcional / Seguridad | Medio | Tráfico sin cifrar | ALB + ACM | **Media** ⚠️ *no implementado* | Listener 443 (mejora propuesta) |
| R16 | Carrito de compras | Funcional / Negocio | Alto (futuro) | — | R01, R02 | **Baja** | Fuera del alcance del EP1 |
| R17 | Procesamiento de órdenes y pagos | Funcional / Negocio | Alto (futuro) | — | R16 | **Baja** | Fuera del alcance del EP1 |
| R18 | Multi-región / DR geográfico | No funcional | Bajo | Sobredimensionado para la etapa actual | — | **Baja** | No aplica en esta etapa |

**Honestidad recomendada:** marcar R14 y R15 como priorizados pero **no implementados en esta etapa**, con su justificación (observabilidad queda para la siguiente iteración; HTTPS requiere dominio y certificado ACM, fuera del alcance del entorno académico). Reconocer brechas de forma razonada suma credibilidad y conecta directamente con el punto 1.3.

---

## §1.5 — Comparación de Modelos de Nube (5%)

La pauta exige: comparación entre pública, privada e híbrida, bajo los criterios **costos, seguridad y escalabilidad**, con tabla de ventajas y desventajas **para FreshBox**.

⚠️ No basta con listar los modelos: hay que evaluarlos **frente a este caso**.

### Tabla comparativa aplicada a FreshBox SpA

| Criterio | Nube Pública | Nube Privada | Nube Híbrida |
|---|---|---|---|
| **Costos** | OPEX puro, sin inversión inicial; se paga el consumo. Riesgo: costo variable requiere control. **Para FreshBox:** evita inmovilizar capital que la empresa necesita para operación y logística | CAPEX alto (hardware, licencias, espacio, energía) + personal especializado. **Para FreshBox:** inviable para una PyME en expansión | Costo mixto; se mantiene parte del CAPEX y se agrega complejidad de integración. **Para FreshBox:** no hay activos previos que justifiquen conservarlos |
| **Seguridad** | Modelo de responsabilidad compartida; AWS asegura la infraestructura, el cliente su configuración. Herramientas nativas (SGs, cifrado EBS, IAM). **Para FreshBox:** acceso a controles de nivel empresarial sin equipo de seguridad propio | Control físico total y aislamiento máximo; pero **toda** la seguridad depende del equipo interno. **Para FreshBox:** no cuenta con ese equipo; el control total se vuelve un riesgo, no una ventaja | Permite mantener datos sensibles en sitio; añade superficie de ataque en la interconexión (VPN/Direct Connect). **Para FreshBox:** el catálogo de productos no es dato sensible que exija residencia local |
| **Escalabilidad** | Elástica y casi inmediata; ASG ajusta capacidad automáticamente. **Para FreshBox:** responde al 40% trimestral sin planificación de compras | Limitada por el hardware adquirido; escalar implica comprar e instalar (semanas o meses). **Para FreshBox:** incompatible con su velocidad de crecimiento | Escalable en la porción pública; la privada mantiene el techo físico. **Para FreshBox:** complejidad sin beneficio proporcional |
| **Time-to-market** | Alto: infraestructura creada en minutos por código | Bajo: ciclo de adquisición e instalación | Medio |
| **Competencias requeridas** | Conocimiento del proveedor cloud | Administración de datacenter, redes, storage, virtualización | Ambas, más integración |
| **Veredicto para FreshBox** | ✅ **Recomendado** | ❌ No viable | ❌ Innecesario |

### Ventajas y desventajas por modelo, en el contexto del caso

**Pública** — *Ventajas:* sin CAPEX; elasticidad real; servicios gestionados (ALB, ECR, Backup); Multi-AZ nativo; pago por uso; despliegue en minutos. *Desventajas:* dependencia del proveedor (vendor lock-in); costo variable que exige gobernanza; la seguridad de la configuración sigue siendo responsabilidad propia.

**Privada** — *Ventajas:* control físico total; aislamiento máximo; útil cuando existe regulación de residencia de datos. *Desventajas:* CAPEX elevado; escalamiento lento; requiere equipo especializado; capacidad ociosa fuera de peaks; la alta disponibilidad Multi-AZ exigiría dos sitios físicos.

**Híbrida** — *Ventajas:* permite conservar inversiones existentes y ubicar datos sensibles en sitio; útil en migraciones graduales. *Desventajas:* complejidad operacional y de red; doble modelo de seguridad y monitoreo; mantiene parte del CAPEX. **Para FreshBox no aplica: no hay infraestructura previa que migrar ni requisito de residencia de datos.**

---

## §1.6 — Justificación del Modelo Cloud Seleccionado (5%)

La pauta exige tres justificaciones: **técnica**, **financiera (reducción de CAPEX por OPEX)** y **estratégica (alineación con objetivos del negocio)**. El nivel 60% de la rúbrica se obtiene cuando la justificación es solo técnica: hay que cubrir las tres.

**Modelo seleccionado: nube pública (AWS).**

### Justificación técnica
- Los 5 requerimientos declarados por la organización tienen servicio nativo directo: visualización/administración (EC2 + contenedores), escalabilidad automática (Auto Scaling Group), alta disponibilidad (ALB + Multi-AZ en 2 zonas), optimización operacional (CloudFormation, ECR, SSM, AWS Backup).
- La región `us-east-1` ofrece múltiples Availability Zones, condición necesaria para la HA exigida; replicar esto on-premise requeriría dos sitios físicos independientes.
- Ya está **demostrado empíricamente** en este proyecto: infraestructura completa desplegada, CRUD funcionando end-to-end a través del ALB, y auto-healing del ASG observado en operación.

### Justificación financiera (CAPEX → OPEX)

| Concepto | On-premise (CAPEX) | AWS (OPEX) — lo que se hizo |
|---|---|---|
| Servidores | Compra de al menos 3 equipos + redundancia | 3 instancias `t4g.small` bajo demanda |
| Balanceador | Appliance de balanceo (hardware o licencia) | ALB gestionado, cobrado por uso |
| Almacenamiento | Arreglo de discos | Volúmenes EBS gp3 de 8 GB, elásticos |
| Respaldos | Software + medios + custodia | AWS Backup, retención 7 días |
| Red y salida a Internet | Firewall, router, enlaces redundantes | Security Groups, IGW y NAT Gateway (servicios) |
| Redundancia geográfica | Segundo datacenter | Segunda Availability Zone, sin costo de sitio |
| Energía, climatización, espacio | Costo fijo mensual | Incluido en el servicio |
| Personal de infraestructura | Equipo dedicado | Servicios gestionados |
| **Inversión inicial** | **Alta** | **Cero** |
| Modelo de pago | Desembolso previo + depreciación | Gasto operacional mensual proporcional al uso |

**Argumentos financieros específicos a desarrollar:**
1. **Cero inversión inicial:** el capital queda disponible para operación, logística y marketing, no inmovilizado en hardware.
2. **Elasticidad como ahorro:** el ASG mantiene 2 instancias en operación normal y puede llegar a 4 en peaks; on-premise habría que comprar para el peak y mantenerlo ocioso el resto del tiempo.
3. **Graviton:** `t4g.small` (ARM) tiene mejor relación precio-rendimiento que su equivalente x86 — *verificar y citar el porcentaje en la documentación oficial de AWS antes de publicarlo*.
4. **Sin costo de obsolescencia:** no hay depreciación ni ciclo de renovación de hardware.
5. **Costo alineado al ingreso:** si la demanda crece 40%, el costo crece de forma proporcional, no en saltos por compra de equipos.

### Justificación estratégica

| Objetivo estratégico de FreshBox | Cómo lo habilita el modelo elegido |
|---|---|
| Sostener 40% de crecimiento trimestral (≈ ×3,8 anual) | Escalado elástico sin ciclos de compra |
| No perder ventas por indisponibilidad | Multi-AZ + auto-healing verificado en operación |
| Priorizar inversión en el core del negocio (productos, logística) | Sin CAPEX en TI ni equipo de datacenter |
| Incorporar carrito y órdenes en etapas siguientes | Base de microservicios + red ya dimensionada (`/22` con espacio libre) |
| Coherencia con su identidad sostenible | Graviton y *right-sizing* reducen la huella energética |
| Expansión futura más allá de la RM | Infraestructura replicable por código en otras regiones |

---

## §1.7 — Validación del Diseño (10% — el de mayor peso del informe)

La pauta exige validar tres cosas: **alta disponibilidad (Multi-AZ, ALB, ASG)**, **escalabilidad (ASG, contenedores)** y **buenas prácticas (segmentación, cifrado, Security Groups por capa)**.

Esta sección debe apoyarse en las **29 capturas** de `evidencias/` y en los datos verificados de la bitácora.

### Validación de Alta Disponibilidad

| Criterio | Cómo se validó | Evidencia |
|---|---|---|
| Distribución Multi-AZ | Las 3 capas tienen subredes en `us-east-1a` y `us-east-1b` (6 subredes) | `evidencias/01-vpc-subredes/` (02 a 07) |
| ALB en múltiples zonas | ALB internet-facing asociado a las 2 subredes públicas | `evidencias/06-alb-targetgroup/01` |
| Health checks operativos | Target Group HTTP:80 en `/`, umbral 2 healthy / 3 unhealthy | `evidencias/06-alb-targetgroup/02` |
| Instancias sanas en 2 AZs | 2 targets en estado **healthy**, uno por AZ | `evidencias/06-alb-targetgroup/03` |
| Mínimo de instancias para HA | ASG con `MinSize: 2` — nunca opera con una sola instancia | `evidencias/04-ec2-app/` |
| **Auto-healing real** | El ASG reemplazó las instancias originales y las nuevas quedaron *healthy* y con los 5 contenedores operativos, sin interrupción del servicio | bitácora §5 |
| Continuidad de datos | AWS Backup, plan diario, retención 7 días; los *recovery points* son regionales, restaurables en `us-east-1b` | `evidencias/08-aws-backup/` |

### Validación de Escalabilidad

| Criterio | Cómo se validó | Evidencia |
|---|---|---|
| Escalado horizontal definido | ASG `freshbox-asg-app`, min 2 / max 4 / desired 2 | `evidencias/04-ec2-app/` |
| Capacidad de duplicar la capacidad | El rango permite pasar de 2 a 4 instancias sin cambios de arquitectura | bitácora §5 |
| Aprovisionamiento automático | El `UserData` del Launch Template instala Docker, autentica contra ECR y levanta los 5 contenedores: una instancia nueva entra en servicio sin intervención | `infra/03-compute.yaml` |
| Portabilidad e inmutabilidad | 5 imágenes versionadas en ECR, idénticas en todas las instancias | `evidencias/05-ecr/` |
| Escalado independiente por servicio | Arquitectura de microservicios: la lectura del catálogo puede escalarse aparte de las operaciones administrativas | diagrama TO-BE |
| Espacio de direccionamiento para crecer | VPC `/22` (1.024 IPs) con 6 subredes `/26`: queda capacidad libre para nuevas subredes y servicios | `evidencias/01-vpc-subredes/01` |

### Validación de Buenas Prácticas

| Práctica | Implementación verificada | Evidencia |
|---|---|---|
| Segmentación en 3 capas | Web pública / App privada / Data privada, con route tables distintas | `evidencias/01-vpc-subredes/09` y `10` |
| Exposición mínima | Solo el ALB es internet-facing; App y Data no tienen IP pública | `evidencias/01-vpc-subredes/` |
| Security Groups por capa | `SG-alb` ← 0.0.0.0/0 (80/443); `SG-app` ← solo SG-alb; `SG-bd` ← solo SG-app (3306) | `evidencias/02-security-groups/` |
| Encadenamiento por SG, no por IP | Las reglas referencian el SG de origen, por lo que siguen siendo válidas cuando el ASG reemplaza instancias | `infra/02-security-groups.yaml` |
| Cifrado en reposo | `Encrypted: true` en los volúmenes gp3 de App y Data | `evidencias/03-ec2-mysql/`, `04-ec2-app/` |
| Salida controlada | Subredes privadas salen por NAT Gateway; sin rutas de entrada desde Internet | `evidencias/01-vpc-subredes/10` y `11` |
| Sin llaves SSH | Administración exclusivamente por SSM Session Manager | bitácora §4 y §5 |
| Mínimo privilegio en ECR | Las instancias tienen permiso de solo lectura; el `push` usa otra identidad | bitácora §6 |
| Infraestructura como código | 5 stacks CloudFormation, reproducibles y auditables | `infra/` |
| Validación funcional end-to-end | CRUD completo (GET/POST/PUT/DELETE) a través del DNS del ALB, verificado por API y por interfaz web | `evidencias/07-validacion-crud/` |

### Brechas reconocidas (incluirlas fortalece esta sección)
- **HTTPS:** los SGs permiten 443, pero el ALB solo tiene listener HTTP:80 — no hay certificado ACM disponible en el entorno académico. En producción: listener 443, TLS ≥ 1.2 y redirección 80→443.
- **NAT Gateway único:** punto único de falla para el egress de las subredes privadas. En producción: uno por AZ.
- **Sin política de escalado dinámico:** el rango 2-4 está definido, pero falta la regla que dispare el escalado (Target Tracking).
- **Sin observabilidad:** falta CloudWatch Agent, logs centralizados y alarmas.

---

# PARTE 4 — Insumo por sección de la PRESENTACIÓN

**Duración total: 10 minutos.** Distribución sugerida:

| Bloque | Contenido | Tiempo |
|---|---|---|
| 2.1 | Análisis del caso y decisiones cloud | 1:30 |
| 2.2 | Requerimientos | 1:30 |
| 2.3 | Diagrama de arquitectura TO-BE | 2:00 |
| 2.4 | Demo: red, seguridad y HA en consola | 2:30 |
| 2.5 | Demo: contenedores y CRUD funcionando | 2:30 |

## §2.1 — Análisis del Caso (10%)
Exige: diagnóstico empresarial y necesidades tecnológicas, decisiones cloud alineadas al negocio, propuesta inicial y beneficios esperados.

**Contenido:** usar la Parte 2 (contexto) + la tabla de alineación decisión↔objetivo de §1.1. El dato central es el **40% trimestral ≈ ×3,8 anual**, que hace inviable la infraestructura fija.

**Beneficios esperados a declarar:** elasticidad sin compra de hardware; continuidad ante falla de una AZ; cero CAPEX; entorno reproducible en ~15-20 min; base preparada para carrito y órdenes.

## §2.2 — Requerimientos (10%)
Exige: levantamiento funcional y no funcional, clasificación y priorización, y vinculación con la solución propuesta.

**Contenido:** la matriz de §1.4. Para la diapositiva conviene una versión reducida: solo los de prioridad **Alta**, con la columna "componente que lo implementa" — eso cubre el "vincular requerimientos con la solución", que es exactamente lo que pide el descriptor de 100%.

## §2.3 — Diagrama de Arquitectura (15% — el indicador de mayor peso)
Exige: diagrama TO-BE de 3 capas, componentes obligatorios (VPC, subredes, ALB, EC2+Docker, MySQL, Security Groups) y **flujos de comunicación entre capas**.

**Archivo listo:** `diagramas/diagrama-arquitectura-tobe.png` (editable: `.drawio` y `PEGAR-EN-EDIT-DIAGRAM.xml`).

El descriptor de 100% exige: las 6 subredes Multi-AZ, el ALB en zona pública, las pasarelas IGW/NAT, las instancias de cómputo/datos y **flechas de comunicación direccional**. El diagrama ya incluye todo eso, más los puertos rotulados (80/443, 3306), los badges de Security Group y la leyenda.

**Al exponerlo, recorrer el flujo en voz alta:** Internet → ALB (80/443) → EC2 App en 2 AZs (80) → nginx enruta por método HTTP al microservicio (3001-3004) → EC2 MySQL (3306). Y mencionar los flujos de gestión: `docker pull` desde ECR y respaldo diario hacia AWS Backup.

## §2.4 — Configuración de Red / Seguridad / HA (15%)
Exige **demo en vivo**: servicios de red (VPC, subredes, IGW, NAT GW), Security Groups segmentados por capa, y componentes de HA (ALB, Multi-AZ, ASG).

**Guion de clics (en este orden):**
1. **VPC → Your VPCs** → `freshbox-vpc`, mostrar CIDR `10.0.0.0/22`
2. **Subnets** → filtrar por la VPC → mostrar las 6 subredes y sus AZ (señalar la simetría 1a/1b)
3. **Route Tables** → `freshbox-rt-public` (0.0.0.0/0 → IGW, 2 subredes) y `freshbox-rt-private` (0.0.0.0/0 → NAT, 4 subredes)
4. **Internet Gateways** → `freshbox-igw` (Attached) · **NAT Gateways** → `freshbox-natgw` (Available)
5. **Security Groups** → los 3, abriendo **Inbound rules**: recalcar que el origen de `SG-app` es el SG del ALB y el de `SG-bd` es el SG de App (no rangos de IP)
6. **EC2 → Load Balancers** → `freshbox-alb` (2 AZs) → **Target Groups** → `freshbox-tg-app` → pestaña **Targets**: 2 *healthy* en AZs distintas
7. **Auto Scaling Groups** → `freshbox-asg-app` → min 2 / max 4, instancias en 2 AZs

## §2.5 — Despliegue de 5 Contenedores (10%)
Exige: 5 contenedores Docker funcionales (frontend + 4 backend), CRUD operativo vía ALB, y conectividad end-to-end (ALB → EC2 → MySQL).

**Guion de demo:**
1. **Contenedores corriendo** — vía Session Manager en una instancia App:
   `docker ps --format "table {{.Names}}\t{{.Status}}"` → deben aparecer los 5
2. **Frontend por el ALB** — abrir `http://freshbox-alb-933788468.us-east-1.elb.amazonaws.com/` y cargar los productos (**GET**)
3. **Crear** un producto en el formulario (**POST**)
4. **Editar** ese producto (**PUT**)
5. **Eliminar** ese producto (**DELETE**) y mostrar que el listado vuelve a su estado original
6. *(Si sobra tiempo)* Explicar la ruta del tráfico: el navegador llama a `/api/products`, nginx enruta según el método al microservicio correspondiente, y este consulta MySQL en `10.0.1.43`

⚠️ **El DNS del ALB cambia si se redespliega el entorno.** Verificarlo antes de presentar:
```bash
aws cloudformation describe-stacks --stack-name freshbox-alb \
  --query "Stacks[0].Outputs[?OutputKey=='AlbDnsName'].OutputValue" --output text
```

---

# PARTE 5 — Bibliografía (APA v7)

La bibliografía es **requisito formal obligatorio**. Fuentes pertinentes y reales para este trabajo:

- Documentación oficial del **AWS Well-Architected Framework** y de sus 6 pilares (fuente principal para §1.2 y §1.3)
- Guías de usuario de **Amazon VPC**, **Elastic Load Balancing (ALB)**, **Amazon EC2 Auto Scaling**, **Amazon ECR**, **AWS Backup** y **AWS CloudFormation**
- Documentación de **AWS Graviton** (para las afirmaciones de precio-rendimiento y eficiencia energética)
- Definiciones de modelos de servicio y despliegue en la nube del **NIST** (*The NIST Definition of Cloud Computing*, SP 800-145) — respaldo académico sólido para §1.5
- Bibliografía del módulo ARY1102 y material de AWS Academy Cloud Architecting

⚠️ **Instrucciones para quien redacte:**
1. **Verificar cada URL y registrar la fecha de acceso** antes de incluirla; la documentación de AWS cambia de ruta con frecuencia.
2. **No inventar** autores, años ni números de página.
3. Toda cifra cuantitativa (porcentajes de ahorro, mejoras de rendimiento, precios) debe provenir de una fuente citada, o bien formularse de modo cualitativo.
4. Formato APA v7: sangría francesa, orden alfabético, y correspondencia entre cada entrada y su cita en el texto.

---

# PARTE 6 — Checklist final antes de entregar

## Informe
- [ ] Archivo único PDF o Word, **máximo 20 páginas**
- [ ] Portada con **nombre, sección y fecha** *(pedir la sección al estudiante)*
- [ ] Índice
- [ ] Introducción
- [ ] Desarrollo con los 7 puntos (1.1 a 1.7) claramente titulados
- [ ] Conclusiones
- [ ] Bibliografía APA v7, con URLs verificadas
- [ ] Diagrama de arquitectura insertado y **legible** al tamaño de página
- [ ] Capturas de evidencia insertadas con su pie de figura
- [ ] Cada punto conceptual anclado a un dato real del despliegue (no teoría genérica)
- [ ] Brechas reconocidas con su recomendación (no ocultarlas)

## Presentación
- [ ] PowerPoint cubriendo 2.1 a 2.5
- [ ] Diagrama TO-BE en diapositiva propia, legible en proyección
- [ ] Ensayada en **10 minutos** o menos
- [ ] **Laboratorio AWS encendido** y verificado antes de exponer
- [ ] DNS del ALB verificado el mismo día
- [ ] CRUD probado en el navegador minutos antes (los 4 métodos)
- [ ] Session Manager probado (para mostrar `docker ps`)
- [ ] Respuestas preparadas para: ¿por qué MariaDB y no MySQL? · ¿por qué no hay HTTPS? · ¿por qué EC2 y no RDS? · ¿qué pasa si cae una AZ?

## Riesgo operativo crítico
- [ ] **Verificar que los recursos siguen existiendo.** El Learner Lab los elimina al expirar. Si desaparecieron, ejecutar el runbook de `bitacora.md` §10 (~15-20 min) y **actualizar los IDs y el DNS citados en el informe y la presentación**.

---

# PARTE 7 — Índice de archivos del repositorio

| Ruta | Contenido |
|---|---|
| `notas/bitacora.md` | Bitácora técnica: IDs reales, decisiones, 11 hallazgos, runbook de redespliegue |
| `notas/insumo-informe-y-presentacion.md` | **Este documento** |
| `infra/01-red.yaml` | VPC, 6 subredes, IGW, NAT GW, route tables |
| `infra/02-security-groups.yaml` | Los 3 Security Groups encadenados |
| `infra/03-compute.yaml` | EC2 MySQL + Launch Template + Auto Scaling Group |
| `infra/04-alb.yaml` | ALB + Target Group + Listener |
| `infra/05-backup.yaml` | Backup Vault + Plan diario + Selection |
| `codigo/` | Aplicación FreshBox con los 2 defectos corregidos |
| `diagramas/diagrama-arquitectura-tobe.png` | Diagrama TO-BE (insertar en informe y PPT) |
| `diagramas/freshbox-arquitectura-tobe.drawio` | Diagrama editable (File → Open en draw.io) |
| `diagramas/PEGAR-EN-EDIT-DIAGRAM.xml` | Versión para Extras → Edit Diagram en draw.io |
| `evidencias/01-vpc-subredes/` | 11 capturas: VPC, 6 subredes, IGW, 2 route tables, NAT |
| `evidencias/02-security-groups/` | 3 capturas: los SGs por capa |
| `evidencias/03-ec2-mysql/` | 1 captura: EC2 capa Data |
| `evidencias/04-ec2-app/` | 2 capturas: EC2 App Multi-AZ |
| `evidencias/05-ecr/` | 2 capturas: repositorios e imágenes |
| `evidencias/06-alb-targetgroup/` | 3 capturas: ALB, Target Group, targets healthy |
| `evidencias/07-validacion-crud/` | 5 capturas: CRUD completo en el frontend |
| `evidencias/08-aws-backup/` | 2 capturas: plan de respaldo y asignación del recurso |
