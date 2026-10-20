# Dependencias

*(English: [DEPENDENCIES.md](DEPENDENCIES.md))*

| | |
|---|---|
| El proyecto del juego | [Spicywonda/castlevania-chronicles-recomp](https://github.com/Spicywonda/castlevania-chronicles-recomp) `v0.3.9`. **Sin licencia**: aquí no se reproduce nada suyo |
| El framework | [RecompOne](https://github.com/BlackLabelHQ/RecompOne), **MIT** — es a lo que se aplica el parche, y la licencia con la que encaja este repositorio |
| Tu propio disco y la BIOS | Un volcado NTSC más la BIOS que pide el proyecto. Ninguno pasa por aquí |
| SDK de .NET | 8 o posterior, con NativeAOT y el identificador de runtime de UWP |
| Visual Studio 2022 | Por las herramientas de C++ con las que enlaza NativeAOT, y por `makeappx`/`signtool` |
| Python 3 | Para `partir_disco.py`. Solo biblioteca estándar |
| PowerShell | La 5.1 que trae Windows |
| Una Xbox Series X | En **modo desarrollador**, con un usuario conectado |

⚠ Aquí importa más la versión del **proyecto del juego** que la de RecompOne: el parche se genera
contra el árbol que prepara la `v0.3.9`. Una release posterior del proyecto puede mover los mismos
archivos de sitio, y entonces hay que regenerar el parche, que es menos trabajo de lo que parece
porque los cambios están descritos en `docs/HOW-IT-WORKS.es.md`.
