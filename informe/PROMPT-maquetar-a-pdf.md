# Prompt para maquetar el informe a PDF

> El contenido del informe ya está escrito y cerrado. Este prompt es **solo de maquetación**.
> Adjuntar a la otra IA el archivo `informe-ep1-freshbox.md` y las 13 imágenes que referencia.

---

## PROMPT

Tu tarea es **maquetar** un documento académico ya redactado y entregarlo como **un único archivo PDF** (o Word listo para exportar a PDF). El contenido está terminado y validado.

**Regla absoluta: no reescribas, no resumas, no reordenes ni "mejores" el texto.** No agregues secciones, no cambies cifras, identificadores de recursos ni redacción. Tu trabajo es formato e inserción de imágenes, nada más. Si algo te parece un error de contenido, déjalo tal cual y menciónalo al final de tu respuesta, fuera del documento.

### Archivo fuente

`informe-ep1-freshbox.md` — Markdown con la estructura completa: portada, índice, introducción, desarrollo 1.1 a 1.7, conclusiones y bibliografía.

### Formato requerido

- **Un solo archivo**, máximo **20 páginas**. Si te excedes, reduce el tamaño de las figuras y los márgenes antes de tocar el texto. **Nunca recortes contenido para que quepa.**
- Tamaño carta o A4, márgenes de 2,5 cm, texto justificado.
- Fuente serif o sans-serif legible, cuerpo 11 pt, interlineado 1,15.
- **Portada en página propia**, sin encabezado ni número de página, con los datos tal como están en el archivo fuente. El campo `Sección: ARY1102` y el campo `Docente: Rodrigo Horacio Aguilar González` van visibles y sin resaltado de color.
- **Índice en página propia**, inmediatamente después de la portada. Debe incluir el número de página real de cada sección. El índice de figuras va a continuación, en la misma página si cabe.
- Encabezado en todas las páginas salvo la portada: `FreshBox SpA — ARY1102 EP1`. Pie de página con `Página X de Y`.
- Títulos jerarquizados y consistentes: nivel 1 para Introducción, Desarrollo, Conclusiones y Bibliografía; nivel 2 para los puntos 1.1 a 1.7; nivel 3 para los subtítulos internos.
- Tablas con encabezado de color sólido, texto de encabezado en blanco, bordes finos y filas alternadas si ayuda a la lectura. Ninguna tabla debe quedar cortada entre dos páginas si puede evitarse; si una tabla larga debe partirse, repite la fila de encabezado en la página siguiente.
- Bibliografía en APA 7: **sangría francesa**, orden alfabético, sin numeración ni viñetas. Las URL pueden quedar como texto, sin subrayado de hipervínculo.

### Figuras — la parte crítica

Las imágenes ya vienen recortadas y legibles. **No las recortes de nuevo ni las comprimas.** Insértalas en el orden en que aparecen en el Markdown, y respeta lo siguiente:

1. **Figura 1** (el diagrama de arquitectura, `diagrama-arquitectura-tobe.png`, 1862 × 1191 px) va en una **página con orientación horizontal (apaisada) dedicada**, a ancho completo de página. Debe quedar **completa**: el cuadro de datos verificados del borde derecho y la leyenda del margen inferior derecho tienen que ser legibles. Si al ajustar a la página se pierde algún borde, reduce la escala hasta que entre entera. Ninguna parte del diagrama puede quedar fuera del área imprimible.
2. Las demás figuras (2 a 9) van en **orientación vertical normal**, a ancho completo de la caja de texto, manteniendo la proporción original.
3. Las figuras 7a y 7b van juntas, en ese orden, bajo el mismo bloque de texto. Lo mismo para 8a y 8b. Las tres imágenes de la Figura 9 van una debajo de la otra, en el orden a, b, c, y comparten un solo pie de figura.
4. Cada figura lleva el **pie de figura exactamente como está en el archivo fuente**, en cursiva, cuerpo 9 pt, centrado, inmediatamente debajo de la imagen. No inventes ni reformules pies de figura.
5. Ninguna figura debe quedar separada de su pie por un salto de página.

### Verificación antes de entregar

- [ ] El documento tiene 20 páginas o menos
- [ ] La portada muestra sección y docente, sin resaltado
- [ ] El índice tiene números de página reales
- [ ] La Figura 1 está completa y legible en página horizontal
- [ ] Las 13 imágenes están insertadas, con su pie correspondiente
- [ ] No hay texto en corchetes, notas al redactor, marcadores ni resaltados de color en ninguna página
- [ ] La bibliografía tiene sangría francesa
- [ ] El texto del informe es idéntico al del archivo fuente

---

## FIN DEL PROMPT
