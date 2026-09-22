# Presentación de defensa

[`Presentacion-EP1-FreshBox.pptx`](Presentacion-EP1-FreshBox.pptx) — 16 diapositivas en 16:9: 13 de exposición y 3 anexos que no se exponen, reservados para responder preguntas. Todas traen notas del orador.

Duración objetivo: **10 minutos**. Cubre los cinco bloques de la pauta de exposición.

## Mapa de diapositivas

| # | Bloque | Contenido | Tiempo |
|---|---|---|---|
| 1 | — | Portada | 0:10 |
| 2-3 | 2.1 Análisis del caso | Diagnóstico, tensión de capacidad y decisiones ancladas a objetivos de negocio | 1:30 |
| 4-5 | 2.2 Requerimientos | Criterios de priorización, distribución de los 18, y los 9 de prioridad Alta con el componente que los implementa | 1:30 |
| 6 | 2.3 Diagrama TO-BE | Arquitectura completa a pantalla llena, recorrida siguiendo el flujo de tráfico | 2:00 |
| 7-9 | 2.4 Red, seguridad y HA | VPC y enrutamiento · Security Groups encadenados · Multi-AZ y recuperación automática | 2:30 |
| 10-11 | 2.5 Contenedores | Los 5 contenedores y el enrutamiento por método HTTP · CRUD validado end-to-end | 2:30 |
| 12-13 | — | Brechas declaradas y cierre | 0:30 |
| 14-16 | Anexos | Preguntas probables · identificadores del despliegue · defectos corregidos | — |

## Los dos modos de exposición

Las diapositivas de los bloques 2.4 y 2.5 llevan la captura ya insertada, y sus notas traen dos guiones. La presentación funciona en ambos escenarios sin tocar el archivo:

| Modo | Cuándo | Narración medida |
|---|---|---|
| **A — demo en vivo** | El laboratorio está operativo | 6:45, dejando ~3:15 para navegar la consola |
| **B — evidencia registrada** | El laboratorio expiró | 9:50 |

En modo B se expone la evidencia del despliegue verificado el 18 de septiembre de 2026, declarándolo con naturalidad. El margen es de apenas 13 segundos, así que conviene ensayar con cronómetro; la diapositiva 6 es la más larga de narrar.

## Antes de exponer

**Si vas por el modo A**, con el laboratorio arriba:

- [ ] Ejecutar el runbook de [`../infra/README.md`](../infra/README.md) si los recursos no existen (15-20 min)
- [ ] Obtener el DNS del balanceador del día y verificar que el catálogo responde:
      `aws cloudformation describe-stacks --stack-name freshbox-alb --query "Stacks[0].Outputs[?OutputKey=='AlbDnsName'].OutputValue" --output text`
- [ ] Comprobar que el Target Group tiene sus 2 targets healthy
- [ ] Probar el CRUD completo en el navegador, los cuatro métodos
- [ ] Tener abiertas y ordenadas las pestañas de la consola: VPC, Security Groups, Target Group, EC2
- [ ] Recordar que los identificadores citados en el informe corresponden al despliegue original: si se recreó el entorno, los IDs y el DNS son otros

**En cualquiera de los dos modos:**

- [ ] Ensayar una vez completo con cronómetro
- [ ] Revisar los anexos: las cuatro preguntas probables ya tienen respuesta preparada
- [ ] Llevar el PDF del informe abierto por si piden precisión sobre algún dato

## Preguntas anticipadas

El anexo A1 trae la respuesta preparada para las cuatro que más se repiten: por qué MariaDB y no MySQL, por qué no hay HTTPS, por qué EC2 y no RDS, y qué pasa si se cae una zona de disponibilidad. El anexo A2 tiene los identificadores del despliegue y el A3 los defectos detectados y corregidos antes de desplegar.
