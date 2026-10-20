# Castlevania Chronicles on Xbox — the UWP port

How to take the [RecompOne](https://github.com/BlackLabelHQ/RecompOne) static recompilation of
*Castlevania Chronicles* (PlayStation, 2001) and run it **on an Xbox Series X in Developer Mode**.

*(Español: [README.es.md](README.es.md))*

This was the first RecompOne game to run on a console: the recompiler turns the PlayStation's MIPS
code into **C#**, so the port is a .NET application compiled with **NativeAOT for UWP**, on SDL2 and
Mesa. It reaches the memory-card screen at 1080p and plays with a controller, and it has been on two
consoles since 2026-10-02.

## Which console this was tested on

**An Xbox Series X**, in Developer Mode. Both of the consoles this was built and tested on are Series X,
so that is the only hardware anything claimed here covers.

**A Series S has never been tried — not once.** It is a different machine: less memory available to a
game and a weaker GPU. This may work on one, it may run slower, or it may not start at all; nothing here
has been measured on it. If you run it on a Series S, what you get is not what this README reports, and
none of the numbers here are a promise about that console.

## What this repository is

**A recipe.** One patch to `RecompOne.Runtime` — the framework, which is MIT — plus the Xbox host of
our own: a `Program.cs` for the UWP entry point, the project file that builds it with NativeAOT, and
the scripts that build, package and sign it.

⚠ **Where the patch goes is the thing to get right.** It does **not** apply to a clean clone of
RecompOne: it applies to the tree the *game project* prepares, which is RecompOne plus the C# files
that project adds to it (its `patches/` folder). Apply it to RecompOne's `main` and git will tell
you the patch is broken, when what is wrong is the order. [`docs/INSTALL.md`](docs/INSTALL.md) has
the sequence.

## What this repository is **not**

No disc image, no BIOS, no recompiled game code, no built executable, no package, no artwork, and
**no line of the game project**, which has no license at all: what it does is described, never
copied. See [`NOTICE.md`](NOTICE.md).

## What you need first

| | |
|---|---|
| The game project | [Spicywonda/castlevania-chronicles-recomp](https://github.com/Spicywonda/castlevania-chronicles-recomp) `v0.3.9`, **building and running on your PC first** |
| Your own disc | An NTSC dump of Castlevania Chronicles, plus the BIOS the project asks for |
| .NET SDK | 8 or newer, with the NativeAOT workload and the UWP runtime identifier |
| Visual Studio 2022 | For the C++ build tools NativeAOT links through, and for `makeappx`/`signtool` |
| Python 3 | For `partir_disco.py`, which splits the disc so the Device Portal will accept it |
| An Xbox in Developer Mode | And a certificate to sign with |

## What it had to solve

| | Symptom | Fix |
|---|---|---|
| 1 | A .NET game cannot be a UWP app as it is | NativeAOT compiles it to a native binary, and the host in `src/` gives it the WinRT entry point |
| 2 | `System.Text.Json` will not AOT-compile here | Replaced with a small reader generated for the config (`RecompOneJson.cs` in the patch) |
| 3 | The audio and input layers assume a desktop | Reworked over SDL2 for the console in `Audio.cs` and `InputManager.cs` |
| 4 | There is no Vulkan on an Xbox | The renderer goes through Mesa, as in the other ports of this family |
| 5 | The disc will not upload: HTTP 500 | Uploads go through `D:\DevelopmentFiles`, which is small and usually nearly full. `tools/partir_disco.py` splits the image and the host joins it on first boot |
| 6 | 16:9 looked wrong, so it was switched off | The 4:3 of the original is what ships since 2026-10-11. Not every widescreen is an improvement |

## How it was verified

On a clone of the tree the game project prepares, on 2026-10-14: the patch **applies clean**, and
the result is **22 of 22 files identical, byte for byte**, to the tree the shipped package was built
from.

What is **not** re-measured here is the NativeAOT build itself: that needs the full .NET toolchain
and the game project's own build. The claim is the recipe.

## Credits and license

Port and tooling by **Recompilaciones**, under the [MIT License](LICENSE) — the license of
RecompOne, which is what this patches.

*Castlevania Chronicles* is © Konami. Not affiliated with them, with Microsoft, or with the authors
of RecompOne or of the game project. Details in [`NOTICE.md`](NOTICE.md); rights holders can write
to **jajdpmail@gmail.com**.
