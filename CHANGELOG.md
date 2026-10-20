# Changelog

All notable changes to this recipe. Dates are `YYYY-MM-DD`.

## 1.0.2 — 2026-10-20

### Changed

- **The README now says which console this was tested on, and which one it was not.** Everything here
  was built and measured on an **Xbox Series X** in Developer Mode; a **Series S has never been tried**,
  so nothing here says anything about one. The wording used to say "Xbox Series", which reads as if it
  covered both, and it does not.

## 1.0.1 — 2026-10-16

### Fixed

- **`LICENSE`: the explanatory block named the wrong project.** Everything after the MIT text had
  been copied from the `dkr-xbox` repository and never adapted: it said this was a derivative of
  Golden Balloon, denied granting rights in Diddy Kong Racing, quoted "the 57 lines of the upstream
  project", and listed folders this repository does not have. The MIT grant itself was correct all
  along, and `NOTICE.md` always had the right figures. The block now names BlackLabelHQ/RecompOne (MIT) and the game project, which has no license and
  Castlevania Chronicles, and points at `NOTICE.md` for the measurements instead of repeating a number.

## 1.0.0 — 2026-10-14

First release. The package built this way has been on two Xbox Series X consoles since 2026-10-02.

### Included

- `patches/01-recompone-uwp.patch`: 468 added lines over RecompOne.Runtime — the UWP host window,
  the SDL2 audio and input paths, and a JSON reader that survives NativeAOT.
- `src/`: the Xbox host (`XboxProgram.cs`), the NativeAOT project file and its build properties.
- `tools/`: `construir-uwp.ps1`, `empaquetar-uwp.ps1` and `partir_disco.py`, which splits the disc
  image so the Device Portal will accept it.
- `package/Package.appxmanifest` with `CHANGE-ME` identity, and documentation in English and
  Spanish.

### Verified before release

On a clone of the tree the game project prepares: the patch **applies clean** and the result is
**22 of 22 files identical, byte for byte**, to the tree the shipped package was built from.

⚠ The patch does **not** apply to a clean clone of RecompOne — it goes on top of the C# files the
game project adds. `docs/INSTALL.md` has the order, and getting it wrong is what makes git report a
broken patch.
