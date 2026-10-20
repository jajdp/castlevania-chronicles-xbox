# Dependencies

*(Español: [DEPENDENCIES.es.md](DEPENDENCIES.es.md))*

| | |
|---|---|
| The game project | [Spicywonda/castlevania-chronicles-recomp](https://github.com/Spicywonda/castlevania-chronicles-recomp) `v0.3.9`. **No license**: nothing of it is reproduced here |
| The framework | [RecompOne](https://github.com/BlackLabelHQ/RecompOne), **MIT** — this is what the patch applies to, and the license this repository matches |
| Your own disc and BIOS | An NTSC dump plus the BIOS the project asks for. Neither travels through here |
| .NET SDK | 8 or newer, with NativeAOT and the UWP runtime identifier |
| Visual Studio 2022 | For the C++ tools NativeAOT links through, and for `makeappx`/`signtool` |
| Python 3 | For `partir_disco.py`. Standard library only |
| PowerShell | The 5.1 that Windows ships |
| An Xbox Series X | In **Developer Mode**, with a user signed in |

⚠ The version of the **game project** matters more than RecompOne's: the patch is generated against
the tree `v0.3.9` prepares. A later release of the game project may move the same files around, and
then the patch has to be regenerated — which is a smaller job than it sounds, because the changes
are described in `docs/HOW-IT-WORKS.md`.
