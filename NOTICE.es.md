# Aviso

*(English: [NOTICE.md](NOTICE.md))*

## Sin afiliación

Proyecto de aficionado, no oficial y sin ánimo de lucro. **No está afiliado, patrocinado ni
relacionado** con los titulares de *Castlevania Chronicles*, con Microsoft ni con los autores de los proyectos
sobre los que se construye. *Castlevania Chronicles*, *Xbox* y todos los nombres y marcas relacionados son de
sus respectivos propietarios. Aquí no se vende nada.

## Qué NO se distribuye en este repositorio

Ninguna ROM ni imagen de disco, ninguna BIOS, ningún dato extraído, ningún binario compilado, ningún
paquete, ninguna partida, ningún mosaico (se hicieron con el arte del propio juego) y ningún
certificado de firma. El `.gitignore` bloquea todo eso por extensión.

## Qué contiene de trabajo ajeno

| | Líneas | Qué es | Licencia |
|---|---|---|---|
| Líneas propias del parche | 468 | Lo que `01-recompone-uwp.patch` añade a RecompOne.Runtime | nuestras, MIT |
| Citado de RecompOne | 344 | Las líneas de contexto que lleva un diff unificado, más las que sustituye | MIT |
| `src/` | 283 | El anfitrión de Xbox: el punto de entrada de UWP, el proyecto de NativeAOT y sus propiedades | nuestro, MIT |
| `tools/` | 310 | Compilar, empaquetar y el partidor de disco | nuestras, MIT |
| Del proyecto del juego | **0** | No tiene licencia. Lo que hace se describe en la documentación, nunca se copia | — |

La imagen de disco y la BIOS las pones tú y nunca pasan por aquí. Lo que la receta lleva sobre el disco es lo que `partir_disco.py` necesita para partirlo y volver a juntarlo, y nada de su contenido.

## Retirada

Escribe a **jajdpmail@gmail.com** y se retira. Sin discusión y sin demora.
