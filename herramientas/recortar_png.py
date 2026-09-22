#!/usr/bin/env python3
"""Recorte de capturas PNG sin dependencias externas (solo stdlib).

Las capturas de la consola AWS de este proyecto son PNG RGBA de 8 bits, no
entrelazadas. Este script las decodifica, aplica el recorte pedido y las vuelve
a codificar usando filtro 0 (None) en cada scanline.

Uso:
    python3 recortar_png.py entrada.png salida.png IZQ ARRIBA DER ABAJO
"""

import struct
import sys
import zlib


def leer_png(ruta):
    datos = open(ruta, "rb").read()
    if datos[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{ruta}: no es un PNG")

    pos = 8
    cabecera = None
    idat = bytearray()

    while pos < len(datos):
        (largo,) = struct.unpack(">I", datos[pos:pos + 4])
        tipo = datos[pos + 4:pos + 8]
        cuerpo = datos[pos + 8:pos + 8 + largo]
        pos += 12 + largo

        if tipo == b"IHDR":
            ancho, alto, prof, color, comp, filtro, entrelazado = struct.unpack(
                ">IIBBBBB", cuerpo
            )
            if prof != 8:
                raise ValueError(f"{ruta}: profundidad {prof} no soportada")
            if color not in (2, 6):
                raise ValueError(f"{ruta}: tipo de color {color} no soportado")
            if entrelazado:
                raise ValueError(f"{ruta}: PNG entrelazado no soportado")
            cabecera = (ancho, alto, color)
        elif tipo == b"IDAT":
            idat += cuerpo
        elif tipo == b"IEND":
            break

    if cabecera is None:
        raise ValueError(f"{ruta}: sin IHDR")

    ancho, alto, color = cabecera
    canales = 4 if color == 6 else 3
    return ancho, alto, canales, zlib.decompress(bytes(idat))


def desfiltrar(ancho, alto, canales, crudo):
    """Revierte los filtros PNG y devuelve las filas como bytearrays planos."""
    paso = ancho * canales
    filas = []
    previa = bytearray(paso)
    pos = 0

    for _ in range(alto):
        filtro = crudo[pos]
        pos += 1
        linea = bytearray(crudo[pos:pos + paso])
        pos += paso

        if filtro == 0:
            pass
        elif filtro == 1:
            for i in range(canales, paso):
                linea[i] = (linea[i] + linea[i - canales]) & 0xFF
        elif filtro == 2:
            for i in range(paso):
                linea[i] = (linea[i] + previa[i]) & 0xFF
        elif filtro == 3:
            for i in range(paso):
                izq = linea[i - canales] if i >= canales else 0
                linea[i] = (linea[i] + ((izq + previa[i]) >> 1)) & 0xFF
        elif filtro == 4:
            for i in range(paso):
                a = linea[i - canales] if i >= canales else 0
                b = previa[i]
                c = previa[i - canales] if i >= canales else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pred = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                linea[i] = (linea[i] + pred) & 0xFF
        else:
            raise ValueError(f"filtro {filtro} desconocido")

        filas.append(linea)
        previa = linea

    return filas


def escribir_png(ruta, ancho, alto, canales, filas):
    color = 6 if canales == 4 else 2
    crudo = bytearray()
    for fila in filas:
        crudo.append(0)  # filtro None
        crudo += fila

    def bloque(tipo, cuerpo):
        return (
            struct.pack(">I", len(cuerpo))
            + tipo
            + cuerpo
            + struct.pack(">I", zlib.crc32(tipo + cuerpo) & 0xFFFFFFFF)
        )

    with open(ruta, "wb") as fh:
        fh.write(b"\x89PNG\r\n\x1a\n")
        fh.write(bloque(b"IHDR", struct.pack(">IIBBBBB", ancho, alto, 8, color, 0, 0, 0)))
        fh.write(bloque(b"IDAT", zlib.compress(bytes(crudo), 9)))
        fh.write(bloque(b"IEND", b""))


def recortar(entrada, salida, izq, arriba, der, abajo):
    ancho, alto, canales, crudo = leer_png(entrada)

    izq = max(0, min(izq, ancho))
    der = max(izq + 1, min(der, ancho))
    arriba = max(0, min(arriba, alto))
    abajo = max(arriba + 1, min(abajo, alto))

    filas = desfiltrar(ancho, alto, canales, crudo)
    recortadas = [
        filas[y][izq * canales:der * canales] for y in range(arriba, abajo)
    ]

    escribir_png(salida, der - izq, abajo - arriba, canales, recortadas)
    return der - izq, abajo - arriba


if __name__ == "__main__":
    if len(sys.argv) != 7:
        print(__doc__)
        sys.exit(1)

    ent, sal = sys.argv[1], sys.argv[2]
    caja = [int(v) for v in sys.argv[3:7]]
    w, h = recortar(ent, sal, *caja)
    print(f"{sal}: {w}x{h} px")
