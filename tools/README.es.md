# tools/

*(English: [README.md](README.md))*

| | |
|---|---|
| `construir-uwp.ps1` | Compila el anfitrión con NativeAOT para el identificador de runtime de UWP |
| `empaquetar-uwp.ps1` | Empaqueta y firma. La huella del certificado es un parámetro —`-Huella`— y no un valor metido dentro del script |
| `partir_disco.py` | Parte la imagen de disco en trozos que el Device Portal acepte, porque las subidas pasan por una partición de 5 GB que suele estar casi llena. El anfitrión los junta en el primer arranque |

Cada ruta es un parámetro. Los scripts están en inglés; `partir_disco.py` es Python 3 pelado, solo
con la biblioteca estándar.
