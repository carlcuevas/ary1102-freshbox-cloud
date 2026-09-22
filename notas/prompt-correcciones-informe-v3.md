# Prompt de correcciones al Informe Técnico EP1 (v2 → v3)

> Copiar y pegar el bloque completo en la IA que redactó el informe, **junto con el archivo del informe v2**.
> Los datos de portada ya están rellenados.

---

## PROMPT

El informe v2 quedó bien en general. Corrige solo estos 6 puntos y entrega el documento v3 completo. No modifiques nada más: el resto del contenido técnico está auditado y es correcto.

### 1. BLOQUEANTE — Eliminar los marcadores `[PENDIENTE: ...]` visibles en el texto

Quedaron dos marcadores en rojo, en las páginas 8 y 13: `[PENDIENTE: confirmar y elegir una causa — (A) se terminó manualmente una instancia para provocar la falla, o (B) las instancias se detuvieron por el cierre del entorno de laboratorio]`. Son notas de trabajo y no deben aparecer en el documento entregado.

Reemplaza **ambos** pasajes por esta redacción única y coherente:

> Las instancias originalmente lanzadas por el grupo (`i-0cfb5552cdf4faecc` e `i-0d22849f21e783c74`) fueron reemplazadas por instancias nuevas (`i-016e07318bb71bcbe` e `i-0dd7f85d9dfc342ea`) sin intervención manual, restituyendo la capacidad deseada de dos instancias healthy, una por zona de disponibilidad. El mecanismo responsable es el health check de tipo EC2 del Auto Scaling Group, que retira de servicio toda instancia que deja de estar en estado `running`. El evento específico que lo disparó no quedó capturado, precisamente por la brecha de observabilidad declarada en el punto 1.3: sin CloudWatch ni logs centralizados, el único registro del disparador es el historial de actividad del propio grupo. Esta limitación es, en sí misma, un argumento a favor de la recomendación de instrumentar la plataforma antes de pasar a producción.

Mantén la frase que aclara que no se terminó una instancia a propósito, y conserva la mención de que `03-compute.yaml` no define `UpdatePolicy` ni `AutoScalingRollingUpdate`. **No afirmes ninguna causa que no esté verificada.**

### 2. BLOQUEANTE — Generar el índice real

La página 2 tiene solo el título "Índice" y una nota en cursiva que explica cómo actualizar campos en Word. No hay índice. Genera la tabla de contenidos real, con todos los títulos y su paginación, y **elimina** la nota `Nota: el índice se genera a partir de los títulos del documento. En Word, clic derecho...`: es una instrucción interna que no debe verse en el documento entregado.

### 3. Portada — completar los datos faltantes

- Reemplaza `Sección: ______` por **`Sección: ARY1102`**
- El campo Docente hoy dice `ARY1102 — Arquitectura Cloud`, que es el nombre de la asignatura. Reemplázalo por **`Docente: Rodrigo Horacio Aguilar González`**
- Quita el resaltado amarillo del campo Sección

### 4. Coherencia del argumento de auto-healing (hoy 1.1 y 1.2 contradicen a 1.3 y 1.7)

Corrige las dos menciones que atribuyen el reemplazo de instancias al Target Group:

- **Tabla de 1.1**, fila "Continuidad del servicio": cambia `ALB + 2 AZs + health checks en Target Group` por `ALB + 2 AZs + Auto Scaling Group con health check de instancia`, y el resultado medible por `Reemplazo automático de instancias por falla de instancia, observado en el despliegue (ver 1.7)`.
- **Pilar Fiabilidad de 1.2**: elimina la expresión "tras conectar el Target Group" como si fuera la causa del reemplazo. Redacta: *"La bitácora registra que las instancias App originales fueron reemplazadas automáticamente por el Auto Scaling Group, quedando las nuevas en estado healthy con sus 5 contenedores operativos. El punto 1.3 detalla el mecanismo exacto y su límite actual."*

Revisa que las cuatro menciones al reemplazo (1.1, 1.2, 1.3 y 1.7) cuenten la misma historia.

### 5. Figuras — la corrección se declaró en el texto pero no se aplicó a las imágenes

- **Figura 1**: la página sigue en vertical y el diagrama está **recortado por el margen derecho**; se pierden el cuadro de datos verificados y la leyenda. Insértala en una página con orientación horizontal real, a ancho completo, con el diagrama entero visible incluyendo la leyenda. Si no cabe completo, divídelo en dos figuras (vista de red / vista de flujo de tráfico).
- **Figura 3 — CRÍTICO**: el texto afirma "2 targets en estado healthy, uno en cada zona", pero la captura solo muestra los encabezados de la tabla `Registered targets (2)`: las dos filas con la columna Health status no son visibles. Indica explícitamente que esa captura debe retomarse mostrando las dos filas con su estado `healthy` y su zona de disponibilidad. Si no puede retomarse, ajusta el texto para afirmar solo lo que la imagen prueba.
- **Figuras 3, 7 y 8**: están cortadas por el borde izquierdo (se lee "rget groups", "outer tables", "iAT gateways", "ecurity Groups"). Recórtalas al área útil, sin barras de scroll ni bordes cortados.

### 6. Menor — aclaración sobre el puerto 443

En el pilar Seguridad de 1.2 dice "freshbox-sg-alb recibe tráfico público en 80/443". Aclara ahí mismo que el Security Group permite 443 pero el ALB solo tiene listener HTTP:80, para que no parezca una contradicción con la brecha declarada en 1.3 y 1.7.

### 7. Barrido final antes de entregar

Antes de dar el documento por terminado, recórrelo completo y verifica:

- No queda ningún marcador interno visible: `[PENDIENTE`, `<<`, `>>`, corchetes con instrucciones, texto resaltado en amarillo, ni notas dirigidas al autor o al redactor.
- Todas las figuras tienen pie numerado y al menos una referencia desde el texto.
- La estructura está completa y en orden: Portada · Índice · Introducción · 1.1 a 1.7 · Conclusiones · Bibliografía.
- Cada entrada de la bibliografía está citada en el texto, y cada cita tiene su entrada.
- El documento es un archivo único, listo para exportar a PDF, de máximo 20 páginas.

---

### Restricciones

Mantén el límite de 20 páginas y no alteres ningún dato técnico verificado: ASG min 2 / max 4, `HealthCheckType: EC2`, EBS gp3 8 GB `Encrypted: true`, `t4g.small`, Target Group HTTP:80 con umbral healthy 2, listener solo HTTP:80, AWS Backup `cron(0 3 * * ? *)` con retención 7 días.

---

## FIN DEL PROMPT
