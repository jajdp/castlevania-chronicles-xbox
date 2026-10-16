# Cómo funciona

*(English: [HOW-IT-WORKS.md](HOW-IT-WORKS.md))*

## Un juego de PlayStation que es C#

RecompOne no emula: traduce el código MIPS del disco a **C#** y lo compila. Eso hace que este port
no se parezca a ningún otro de esta familia: lo que tiene que correr en la consola es una aplicación
.NET.

Una app UWP empaquetada no puede compilar al vuelo, así que la respuesta es **NativeAOT**: el C# se
compila por adelantado a un binario nativo, y `src/XboxProgram.cs` le da a ese binario el punto de
entrada de WinRT. Enlaza con el toolchain de C++ de Visual Studio, que es por lo que hay que
tenerlo instalado en un proyecto que no tiene nada de C++.

## Qué cambia el parche, y por qué cada cosa

- **La ventana del host** pasa a SDL2 sobre Mesa: en una Xbox no hay Vulkan.
- **El audio y la entrada** se rehacen para la consola: los caminos de escritorio dan por hechos
  dispositivos y API que no están.
- **`System.Text.Json` se va.** Aquí no sobrevive a NativeAOT, así que la configuración la lee un
  lector pequeño generado (`RecompOneJson.cs`). Es el cambio que más parece arbitrario y es el que
  desatasca la compilación.
- **El paquete de datos y el gestor de configuración** aprenden dónde puede escribir una app
  empaquetada, que es la carpeta de datos de la app y nada más.

## Dónde va el parche

Sobre el árbol de RecompOne **que prepara el proyecto del juego** —RecompOne más los archivos C# que
ese proyecto le añade—. No sobre un clon limpio. Medido el 2026-10-14: sobre el árbol preparado
aplica limpio y da 22 de 22 archivos idénticos al árbol del que salió el paquete instalado; sobre el
`main` de RecompOne falla en `Audio.cs` y en el archivo de proyecto, lo que parece un parche roto y
es un error de orden.

## El disco que no cabe

El Device Portal sube por `D:\DevelopmentFiles` en la consola: 5 GB, normalmente casi lleno. Una
imagen de disco de PlayStation no cabe, y el fallo es un HTTP 500 sin explicación.
`tools/partir_disco.py` parte la imagen; el anfitrión junta los trozos en el primer arranque. El
mismo truco lo usan los ports de psxrecomp de esta familia.

## El 16:9 se apagó, a propósito

El port tuvo un panorámico experimental desde la 0.1.0.2. Se **apagó el 2026-10-11** porque se veía
mal: el original es un juego 4:3 y estirarlo no es una mejora. Merece quedar escrito, porque «falta
el panorámico» parece una regresión y es una decisión.

## Sobre el idioma

Los scripts y sus mensajes están en inglés. Algunos comentarios del parche están en español, que es
donde se escribieron, y se publican tal como se compilaron y se verificaron.
