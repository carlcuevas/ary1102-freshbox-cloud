# Prompt para generar el Informe Técnico del EP1

> Copiar y pegar el bloque completo en la otra IA. Si esa IA **no puede leer URLs**, pegarle además el contenido de los dos documentos indicados.

---

## PROMPT

Actúa como arquitecto cloud senior redactando un informe técnico académico para la asignatura **ARY1102 Arquitectura Cloud** de DuocUC (Evaluación Parcial n°1).

### Tu tarea
Redactar el **informe técnico completo** del caso **FreshBox SpA** (plataforma de catálogo online de productos orgánicos en AWS), listo para entregar.

### Material de trabajo obligatorio
Toda la información técnica que necesitas está en este repositorio público:
`https://github.com/carlcuevas/ary1102-freshbox-cloud`

Lee **obligatoriamente** estos dos documentos antes de escribir una sola línea:

1. `notas/insumo-informe-y-presentacion.md` — material estructurado indicador por indicador contra la rúbrica. **Es tu fuente principal**; contiene las tablas de requerimientos, la comparativa de modelos de nube, el análisis CAPEX/OPEX, los 6 pilares aplicados al caso y los hallazgos por pilar.
2. `notas/bitacora.md` — bitácora técnica con los IDs reales de todos los recursos AWS desplegados, las decisiones técnicas con su justificación, y los 11 hallazgos del despliegue.

Material de apoyo en el mismo repositorio:
- `infra/*.yaml` — las 5 plantillas CloudFormation de la arquitectura real
- `diagramas/diagrama-arquitectura-tobe.png` — diagrama de arquitectura TO-BE (debes insertarlo/referenciarlo)
- `evidencias/01..08/` — 29 capturas de pantalla de la consola AWS, organizadas por etapa
- `codigo/` — la aplicación desplegada (frontend nginx + 4 microservicios Node.js)

### Formato exigido por la pauta (no negociable)
- **Un solo archivo**, en Word (.docx) o PDF
- **Máximo 20 páginas**
- Estructura obligatoria, en este orden exacto:
  1. **Portada** — con nombre del estudiante, **sección** y fecha
  2. **Índice**
  3. **Introducción**
  4. **Desarrollo** — con los 7 puntos siguientes, claramente titulados:
     - 1.1 Fundamentación del Rol del Arquitecto Cloud
     - 1.2 Pilares del Well-Architected Framework
     - 1.3 Análisis de Arquitectura según Well-Architected
     - 1.4 Priorización de Requerimientos
     - 1.5 Comparación de Modelos de Nube
     - 1.6 Justificación del Modelo Cloud
     - 1.7 Validación del Diseño
  5. **Conclusiones**
  6. **Bibliografía** en normativa **APA v7**
- Incluir evidencias gráficas y diagramas con nomenclatura legible y pie de figura

### Ponderación de cada punto (para dosificar la extensión)
| Punto | Peso |
|---|---|
| 1.1 | 5% |
| 1.2 | 5% |
| 1.3 | 5% |
| 1.4 | 5% |
| 1.5 | 5% |
| 1.6 | 5% |
| **1.7** | **10%** |

El punto **1.7 tiene el doble de peso**: desarróllalo con mayor profundidad y apóyalo en las capturas de evidencia.

### Reglas críticas de redacción

**1. Nada genérico.** La rúbrica castiga explícitamente los "ejemplos genéricos que no se vinculan de manera directa a las necesidades de la organización" y los "hallazgos superficiales con recomendaciones genéricas". Cada afirmación conceptual debe ir seguida de su anclaje concreto en este despliegue real: nombre del recurso (`freshbox-vpc`, `freshbox-asg-app`, etc.), CIDR, ID de instancia, puerto, o hallazgo documentado en la bitácora.

**2. No inventes datos.** Usa exclusivamente los valores reales del repositorio (CIDRs, IDs, DNS del ALB, nombres de recursos). Si necesitas una cifra que no está ahí (por ejemplo, un porcentaje de ahorro de Graviton o un precio), **cítala desde documentación oficial de AWS** o formúlala de manera cualitativa. No inventes autores, años, números de página ni estadísticas.

**3. El punto 1.6 debe cubrir tres dimensiones.** La rúbrica baja a 60% si la justificación es "técnica y no estratégica". Desarrolla las tres: técnica, financiera (reducción de CAPEX por OPEX) y estratégica (alineación con los objetivos del negocio).

**4. El punto 1.5 debe comparar, no listar.** La rúbrica baja a 30% si "se limita a listarlos sin establecer un análisis comparativo". Evalúa los tres modelos bajo costos, seguridad y escalabilidad, **aplicados al caso FreshBox**, y cierra con un veredicto justificado.

**5. Declara las brechas, no las esconda.** El despliegue real tiene limitaciones conocidas y documentadas (ALB sin listener HTTPS por falta de certificado ACM en el entorno académico; un solo NAT Gateway; sin observabilidad; base de datos autoadministrada en EC2 en lugar de RDS). Inclúyelas en 1.3 y 1.7 con su recomendación de mejora: reconocerlas de forma razonada demuestra criterio de arquitecto y conecta ambos puntos.

**6. Verifica las URLs de la bibliografía** y registra su fecha de acceso. La documentación de AWS cambia de ruta con frecuencia.

### Dato que debes solicitar antes de empezar
La **sección** del estudiante no está registrada en el repositorio y es obligatoria en la portada. Pregúntala. Datos conocidos: correo institucional `carl.cuevasn@duocuc.cl`, usuario GitHub `carlcuevas`.

### Contexto resumido del caso (el detalle completo está en el repositorio)
FreshBox SpA vende productos orgánicos online con despacho en la Región Metropolitana (Chile) y crece **40% trimestral** (≈ ×3,8 al año), lo que hace inviable dimensionar infraestructura fija. Esta primera etapa cubre **solo el catálogo administrable**; carrito y órdenes quedan para etapas posteriores.

La solución implementada y **verificada en funcionamiento** es una arquitectura AWS de 3 capas: VPC `10.0.0.0/22` con 6 subredes Multi-AZ, Application Load Balancer, 2 instancias EC2 `t4g.small` con Docker ejecutando 5 contenedores cada una (frontend nginx + 4 microservicios Node.js) bajo un Auto Scaling Group (mín. 2 / máx. 4), imágenes en Amazon ECR, EC2 con MySQL/MariaDB en subred privada, AWS Backup con plan diario, Security Groups encadenados por capa y cifrado EBS. El CRUD completo (GET/POST/PUT/DELETE) fue validado end-to-end a través del DNS público del ALB, tanto por API como por interfaz web.

### Entrega esperada
El informe completo redactado, en español, con tono técnico-profesional, listo para convertir a PDF y subir a Blackboard. Indica claramente dónde debe insertarse cada figura (diagrama y capturas) con su referencia al archivo del repositorio.

---

## FIN DEL PROMPT
