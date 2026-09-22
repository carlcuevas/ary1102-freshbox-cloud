# Prompt de correcciones al Informe Técnico EP1 (v1 → v2)

> Copiar y pegar el bloque completo en la IA que redactó el informe, **junto con el archivo del informe v1**.
> Antes de pegarlo, rellenar los dos campos marcados `<<...>>`.

---

## PROMPT

Actúa como arquitecto cloud senior y revisor académico. Te entrego un **informe técnico ya redactado** (v1) para la asignatura ARY1102 Arquitectura Cloud de DuocUC, Evaluación Parcial n°1, caso FreshBox SpA. Tu tarea es **producir la versión 2 corregida y completa**, lista para entregar.

### Reglas generales

1. **Entrega el documento completo v2**, no una lista de cambios. Mismo formato, misma estructura, listo para convertir a PDF.
2. **Respeta el límite de 20 páginas.** Las correcciones agregan contenido; compensa recortando redundancia en la introducción y en los párrafos conceptuales, nunca en el punto 1.7.
3. **No toques nada que no esté en la lista de correcciones.** La parte técnica del v1 fue auditada contra las plantillas CloudFormation reales del despliegue y es correcta. En particular, **NO modifiques ni "corrijas"** estos datos, que están verificados:
   - Auto Scaling Group: mínimo 2, máximo 4, deseadas 2, `HealthCheckType: EC2`, grace period 120 s
   - Volúmenes EBS: `gp3`, 8 GB, `Encrypted: true`
   - Tipo de instancia: `t4g.small`, AMI resuelta vía parámetro SSM
   - Target Group: HTTP:80, health check path `/`, intervalo 30 s, timeout 10 s, umbral healthy 2 / unhealthy 3
   - ALB: solo listener HTTP:80 (sin HTTPS, brecha declarada)
   - AWS Backup: `cron(0 3 * * ? *)` (03:00 UTC diario), retención 7 días
4. **No inventes datos.** Si necesitas un dato que no tienes, márcalo como `[PENDIENTE: …]` en lugar de rellenarlo.

---

### CORRECCIÓN 1 — Portada: completar la sección (requisito formal obligatorio)

El campo `Sección: ___________` está en blanco. Reemplázalo por:

**`Sección: <<SECCIÓN — ej. 001D>>`**

Verifica también que la portada tenga nombre completo (**Carlos Cuevas**), asignatura (**ARY1102 Arquitectura Cloud**), y fecha de entrega (**22 de septiembre de 2026**).

---

### CORRECCIÓN 2 — Resolver la contradicción lógica sobre el auto-healing (la más importante)

**Problema.** En las páginas 6 y 12–13 el informe afirma dos cosas que, tal como están redactadas, se contradicen:

- que el ASG reemplazó automáticamente las instancias `i-0cfb5552cdf4faecc` e `i-0d22849f21e783c74` por `i-016e07318bb71bcbe` e `i-0dd7f85d9dfc342ea` (auto-healing observado), y
- que el ASG está configurado con `HealthCheckType: EC2`, es decir que **no** reacciona al estado del Target Group del ALB.

Se verificó además que la plantilla `03-compute.yaml` **no contiene `UpdatePolicy` ni `AutoScalingRollingUpdate`**, por lo que el reemplazo tampoco se originó en una actualización progresiva de CloudFormation. El documento nunca explica qué originó el reemplazo. Esa omisión es un flanco directo en la defensa oral.

**Corrección exigida.** Reescribe el pasaje distinguiendo explícitamente **dos niveles de salud**, y declarando la causa real del reemplazo. Usa esta estructura argumental:

> El Auto Scaling Group opera con `HealthCheckType: EC2`, que evalúa la salud **a nivel de instancia**: estado de la instancia y status checks de EC2. Bajo esa configuración, una instancia que deja de estar en estado `running` es marcada como no saludable y reemplazada automáticamente. Esto es exactamente lo que se observó durante el período de pruebas: <<CAUSA — elegir una y borrar la otra: (A) "al terminar manualmente una instancia para provocar la falla" / (B) "al detenerse las instancias por el cierre del entorno de laboratorio">>, el grupo detectó la pérdida de capacidad y lanzó instancias de reemplazo en ambas zonas de disponibilidad, restituyendo la capacidad deseada de dos instancias sin intervención manual.
>
> La limitación de esta configuración es que **no cubre la salud a nivel de aplicación**. Si el contenedor del microservicio deja de responder pero la instancia permanece en estado `running`, el ALB la retira de la rotación del Target Group —protegiendo al usuario final— pero el ASG la mantiene activa indefinidamente, operando con capacidad efectiva degradada. La mejora propuesta es migrar a `HealthCheckType: ELB` y apuntar el health check del Target Group a un endpoint de aplicación real (`/api/products`) en lugar de la raíz `/`, de modo que la verificación atraviese efectivamente la capa de microservicios y no solo el servidor web.

Este argumento debe aparecer coherentemente en **1.3** (como hallazgo del pilar de Fiabilidad, con su recomendación) y en **1.7** (como resultado de la validación de alta disponibilidad). Asegúrate de que ambas secciones digan lo mismo y no se contradigan entre sí.

---

### CORRECCIÓN 3 — Bibliografía: 5 referencias no citadas en el texto (viola APA 7)

La bibliografía tiene 12 entradas, pero estas cinco **no aparecen citadas en ningún párrafo del cuerpo**, lo que rompe la correspondencia 1:1 que exige APA 7:

| Entrada sin citar | Dónde debe citarse |
|---|---|
| ALB / Elastic Load Balancing | En el párrafo que describe el Application Load Balancer y su función de distribución de tráfico (1.7 y/o 1.3) |
| Health checks de EC2 Auto Scaling | En el pasaje de la Corrección 2, al fundamentar la diferencia entre health check EC2 y ELB |
| AWS Backup | En el párrafo de respaldo y continuidad operacional (1.3 / 1.7) |
| Amazon ECR | En el párrafo sobre portabilidad, imágenes de contenedor y registro privado |
| AWS CloudFormation | En el párrafo sobre infraestructura como código y despliegue reproducible |

**Acción:** insertar la cita en el texto en cada una de esas cinco ubicaciones (formato `(Amazon Web Services, s.f.-x)`), manteniendo las letras de desambiguación ya asignadas. Si alguna no encaja de forma natural en el argumento, elimínala de la bibliografía en lugar de forzarla. Verifica al final que **cada entrada de la bibliografía tenga al menos una cita en el texto y viceversa**.

---

### CORRECCIÓN 4 — Legibilidad de las figuras (el diagrama pesa 15% de la nota total)

1. **Figura 1 — diagrama de arquitectura TO-BE.** El lienzo original mide 1980 px de ancho y al insertarse en página vertical las etiquetas de subredes y CIDRs quedan ilegibles. Corrige con **una** de estas dos opciones:
   - insertar la figura en una página con orientación **horizontal (apaisada)** dedicada, o
   - dividir el diagrama en **dos figuras complementarias**: (1a) vista de red — VPC, AZs, las 6 subredes con sus CIDRs, IGW y NAT Gateway; (1b) vista de flujo de tráfico — Internet → ALB → Target Group → ASG con las 2 EC2 y sus 5 contenedores → EC2 MariaDB.

   Deja indicado explícitamente en el documento el ancho de imagen recomendado y la orientación de página.

2. **Figuras 3, 7 y 8.** Son capturas de la consola AWS que se insertaron con **barras de scroll visibles y tablas cortadas a media columna**. Indica que deben recortarse al área útil (sin scrollbars, sin cromo del navegador) y, si el contenido queda incompleto, retomarse con la tabla completa visible.

3. **Todas las figuras** deben tener pie de figura numerado, descripción del contenido, y **al menos una referencia explícita desde el texto** ("como se observa en la Figura 5…"). Una captura que nadie menciona en el cuerpo no cuenta como evidencia.

---

### CORRECCIÓN 5 — Punto 1.4: tabular los 18 requerimientos, no solo los de prioridad Alta

El v1 tabula únicamente los requerimientos de prioridad Alta y deja Media y Baja en prosa, lo que debilita el indicador (5%). Reemplaza esa sección por los **criterios de priorización declarados explícitamente** más la **matriz completa de los 18 requerimientos**, en una sola tabla:

**Criterios de priorización:** impacto en el negocio · riesgo de no implementarlo · dependencia técnica · alineación con el alcance del EP1 (etapa de catálogo).

| ID | Requerimiento | Tipo | Impacto negocio | Riesgo si no se implementa | Dependencia | Prioridad | Componente que lo implementa |
|---|---|---|---|---|---|---|---|
| R01 | Consultar catálogo (listado y detalle) | Funcional / Negocio | Alto | No hay producto que mostrar | — | Alta | `get-products` + ALB |
| R02 | Administrar productos (crear, modificar, eliminar) | Funcional / Negocio | Alto | El catálogo queda estático | R01 | Alta | `create/update/delete-product` |
| R03 | Alta disponibilidad Multi-AZ | No funcional / Técnico | Alto | Caída de una AZ deja la tienda fuera de línea | Red | Alta | ALB + ASG en 2 AZs + 6 subredes |
| R04 | Escalabilidad automática | No funcional / Técnico | Alto | El crecimiento de 40% trimestral degrada el servicio | Cómputo | Alta | ASG mín. 2 / máx. 4 |
| R05 | Aislamiento de red por capas | No funcional / Seguridad | Alto | Exposición directa de la base de datos | Red | Alta | 3 capas + 3 SGs encadenados |
| R06 | Base de datos no accesible desde Internet | No funcional / Seguridad | Alto | Riesgo de exfiltración de datos | R05 | Alta | Subred privada de datos + `SG-bd` 3306 solo desde `SG-app` |
| R07 | Cifrado de datos en reposo | No funcional / Seguridad | Medio | Datos legibles ante acceso al volumen | Cómputo | Alta | Cifrado EBS en App y Data |
| R08 | Respaldo y recuperación | No funcional / Continuidad | Alto | Pérdida irrecuperable del catálogo | Data | Alta | AWS Backup diario, retención 7 días |
| R09 | Salida controlada a Internet desde subredes privadas | No funcional / Técnico | Medio | Las instancias no pueden obtener imágenes ni parches | Red | Alta | NAT Gateway |
| R10 | Despliegue reproducible (IaC) | No funcional / Operacional | Medio | Configuración manual, no auditable, difícil de recrear | — | Media | 5 stacks CloudFormation |
| R11 | Portabilidad de la aplicación | No funcional / Técnico | Medio | Dependencia del host, despliegues inconsistentes | Cómputo | Media | Docker + Amazon ECR |
| R12 | Administración sin exponer SSH | No funcional / Seguridad | Medio | Superficie de ataque y gestión de llaves | Cómputo | Media | SSM Session Manager |
| R13 | Optimización de costos | No funcional / Negocio | Medio | Gasto superior al necesario | Cómputo | Media | Graviton `t4g.small` + elasticidad |
| R14 | Observabilidad (métricas, logs, alarmas) | No funcional / Operacional | Medio | Fallas detectadas por el cliente, no por el equipo | Cómputo | Media — *no implementado* | CloudWatch (mejora propuesta) |
| R15 | Cifrado en tránsito (HTTPS) | No funcional / Seguridad | Medio | Tráfico sin cifrar | ALB + ACM | Media — *no implementado* | Listener 443 (mejora propuesta) |
| R16 | Carrito de compras | Funcional / Negocio | Alto (futuro) | — | R01, R02 | Baja | Fuera del alcance del EP1 |
| R17 | Procesamiento de órdenes y pagos | Funcional / Negocio | Alto (futuro) | — | R16 | Baja | Fuera del alcance del EP1 |
| R18 | Multi-región / DR geográfico | No funcional | Bajo | Sobredimensionado para la etapa actual | — | Baja | No aplica en esta etapa |

Cierra la sección con un párrafo que justifique **por qué R14 y R15 quedan priorizados pero no implementados** (observabilidad diferida a la siguiente iteración; HTTPS requiere dominio y certificado ACM, fuera del alcance del entorno académico) y conecte ese reconocimiento con los hallazgos del punto 1.3.

---

### CORRECCIÓN 6 — Precisión en las cifras de AWS Graviton

El informe afirma "hasta 20% menor costo y hasta 60% menos consumo energético". Ambas cifras son reales y están publicadas por AWS, pero **atribuidas a la familia Graviton en general** (y la de eficiencia energética se asocia principalmente a generaciones posteriores). El informe usa `t4g.small`, que es **Graviton2**.

**Corrección:** reformula para que la atribución sea precisa — "la familia de procesadores AWS Graviton reporta hasta un 20% menos de costo frente a instancias x86 comparables y hasta un 60% menos de consumo energético para el mismo rendimiento" — y cita la documentación oficial de Graviton y su página de sostenibilidad, con fecha de acceso. No atribuyas esas cifras específicamente a `t4g.small`.

---

### CORRECCIÓN 7 — Agregar tabla de trazabilidad en el punto 1.7 (mejora de puntaje)

El punto 1.7 vale el doble que los demás (10%). Agrega una tabla que cierre el círculo entre requerimiento, componente y prueba, con este formato:

| Requerimiento | Componente AWS que lo implementa | Cómo se validó | Evidencia |
|---|---|---|---|
| R03 Alta disponibilidad | ALB + ASG en us-east-1a / us-east-1b | Target Group con 2 targets healthy en AZs distintas | `evidencias/06-alb-targetgroup/` |
| R01/R02 CRUD del catálogo | 4 microservicios Node.js tras el ALB | GET/POST/PUT/DELETE end-to-end por DNS público, vía API e interfaz web | `evidencias/07-validacion-crud/` |
| R06 BD aislada | Subred privada + `SG-bd` 3306 solo desde `SG-app` | Reglas de los security groups | `evidencias/02-security-groups/` |
| R08 Respaldo | Plan `freshbox-backup-plan-mysql` en `freshbox-backup-vault` | Regla diaria y punto de recuperación | `evidencias/08-aws-backup/` |

Complétala con las filas restantes usando las evidencias disponibles. Es el argumento más directo de que el diseño responde al caso y no es un catálogo de servicios.

---

### CORRECCIÓN 8 — Contextualizar temporalmente los identificadores volátiles

El informe cita identificadores concretos del despliegue (DNS del ALB `freshbox-alb-933788468.us-east-1.elb.amazonaws.com`, IDs de instancia, IDs de VPC/subredes). El entorno es un laboratorio académico que puede obligar a recrear los recursos, lo que cambiaría esos valores y dejaría el documento desactualizado.

**Corrección:** al primer uso de identificadores concretos, introdúcelos con una fórmula del tipo *"en el despliegue verificado el 18 de septiembre de 2026"*, y deja los identificadores efímeros preferentemente en las capturas y sus pies de figura, más que en el cuerpo argumental. Los valores estables de diseño (CIDR `10.0.0.0/22`, nombres de recursos, puertos, región `us-east-1`) sí pueden ir en el texto sin reserva.

---

### Verificación final antes de entregar

- [ ] Sección completada en la portada
- [ ] El argumento de auto-healing es coherente entre 1.3 y 1.7, y explica la causa del reemplazo
- [ ] Cada entrada de la bibliografía está citada en el texto, y cada cita tiene su entrada
- [ ] Figura 1 legible (página horizontal o dividida en dos vistas)
- [ ] Figuras 3, 7 y 8 recortadas, sin scrollbars ni tablas cortadas
- [ ] Todas las figuras tienen pie numerado y referencia desde el texto
- [ ] Los 18 requerimientos están en la matriz de 1.4, con criterios declarados
- [ ] Cifras de Graviton atribuidas a la familia, con fuente citada
- [ ] Tabla de trazabilidad presente en 1.7
- [ ] Estructura completa: Portada · Índice · Introducción · 1.1 a 1.7 · Conclusiones · Bibliografía
- [ ] Máximo 20 páginas
- [ ] Ningún dato técnico verificado fue alterado (ver Regla 3)

---

## FIN DEL PROMPT
