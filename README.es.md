# Castlevania Chronicles en la Xbox — el port UWP

Cómo coger la recompilación estática [RecompOne](https://github.com/BlackLabelHQ/RecompOne) de
*Castlevania Chronicles* (PlayStation, 2001) y hacerla correr **en una Xbox Series X en modo
desarrollador**.

*(English: [README.md](README.md))*

Este fue el primer juego de RecompOne que corrió en una consola: el recompilador convierte el código
MIPS de la PlayStation en **C#**, así que el port es una aplicación .NET compilada con **NativeAOT
para UWP**, sobre SDL2 y Mesa. Llega a la pantalla de la tarjeta de memoria a 1080p y se juega con
mando, y está en dos consolas desde el 2026-10-02.

## En qué consola se probó

**En una Xbox Series X**, en modo desarrollador. Las dos consolas en las que se construyó y se probó esto
son Series X, así que es el único hardware al que se refiere cualquier cosa que se afirme aquí.

**En una Series S no se ha probado nunca, ni una vez.** Es otra máquina: menos memoria disponible para un
juego y una GPU más floja. Puede que funcione en una, puede que vaya más despacio, o puede que no
arranque; nada de aquí se ha medido en ella. Si lo ejecutas en una Series S, lo que obtengas no es lo que
dice este README, y ninguna de las cifras de aquí es una promesa sobre esa consola.

## Qué es este repositorio

**Una receta.** Un parche a `RecompOne.Runtime` —el framework, que es MIT— más el anfitrión de Xbox,
que es nuestro: un `Program.cs` para el punto de entrada de UWP, el archivo de proyecto que lo
compila con NativeAOT, y los scripts que compilan, empaquetan y firman.

⚠ **Dónde va el parche es lo que hay que acertar.** **No** se aplica a un clon limpio de RecompOne:
se aplica al árbol que prepara el *proyecto del juego*, que es RecompOne más los archivos C# que ese
proyecto le añade (su carpeta `patches/`). Aplícalo sobre el `main` de RecompOne y git te dirá que el
parche está roto, cuando lo que está mal es el orden. En [`docs/INSTALL.es.md`](docs/INSTALL.es.md)
está la secuencia.

## Qué **no** es

Ninguna imagen de disco, ninguna BIOS, ningún código recompilado del juego, ningún ejecutable, ningún
paquete, ningún arte y **ni una línea del proyecto del juego**, que no tiene licencia ninguna: lo que
hace se describe, nunca se copia. Ver [`NOTICE.es.md`](NOTICE.es.md).

## Qué hace falta antes

| | |
|---|---|
| El proyecto del juego | [Spicywonda/castlevania-chronicles-recomp](https://github.com/Spicywonda/castlevania-chronicles-recomp) `v0.3.9`, **compilando y corriendo antes en tu PC** |
| Tu propio disco | Un volcado NTSC de Castlevania Chronicles, más la BIOS que pide el proyecto |
| SDK de .NET | 8 o posterior, con la carga de NativeAOT y el identificador de runtime de UWP |
| Visual Studio 2022 | Por las herramientas de C++ con las que enlaza NativeAOT, y por `makeappx`/`signtool` |
| Python 3 | Para `partir_disco.py`, que parte el disco para que el Device Portal lo acepte |
| Una Xbox en modo desarrollador | Y un certificado para firmar |

## Qué hubo que resolver

| | Síntoma | Arreglo |
|---|---|---|
| 1 | Un juego de .NET no puede ser una app UWP tal cual | NativeAOT lo compila a un binario nativo, y el anfitrión de `src/` le da el punto de entrada de WinRT |
| 2 | `System.Text.Json` no compila con AOT aquí | Sustituido por un lector pequeño generado para la configuración (`RecompOneJson.cs`, en el parche) |
| 3 | Las capas de audio y de entrada dan por hecho un escritorio | Rehechas sobre SDL2 para la consola, en `Audio.cs` y `InputManager.cs` |
| 4 | En una Xbox no hay Vulkan | El renderizador pasa por Mesa, como en los demás ports de esta familia |
| 5 | El disco no se podía subir: HTTP 500 | Las subidas van por `D:\DevelopmentFiles`, que es pequeño y suele estar casi lleno. `tools/partir_disco.py` parte la imagen y el anfitrión la junta en el primer arranque |
| 6 | El 16:9 se veía mal, así que se apagó | Lo que va desde el 2026-10-11 es el 4:3 del original. No todo panorámico es una mejora |

## Cómo se verificó

Sobre un clon del árbol que prepara el proyecto del juego, el 2026-10-14: el parche **aplica
limpio**, y el resultado son **22 de 22 archivos idénticos, byte a byte**, al árbol del que salió el
paquete instalado.

Lo que **no** se vuelve a medir aquí es la compilación con NativeAOT: eso necesita el toolchain
completo de .NET y la compilación del propio proyecto del juego. Lo que se afirma es la receta.

## Créditos y licencia

Port y herramientas de **Recompilaciones**, bajo la [licencia MIT](LICENSE) — la de RecompOne, que
es lo que esto parchea.

*Castlevania Chronicles* es © Konami. Sin afiliación con ellos, ni con Microsoft, ni con los autores
de RecompOne o del proyecto del juego. El detalle está en [`NOTICE.es.md`](NOTICE.es.md); los
titulares de derechos pueden escribir a **jajdpmail@gmail.com**.
