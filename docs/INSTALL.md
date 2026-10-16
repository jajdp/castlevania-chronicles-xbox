# Install — from the game project to the game on the console

*(Español: [INSTALL.es.md](INSTALL.es.md))*

## 0. Where you type these commands

**PowerShell** for everything here (press **Windows**, type `powershell`, **Enter**), in an
**ordinary** window: the certificate lives in the store of whoever runs the command, so "run as
administrator" breaks the signing step. The `-ExecutionPolicy Bypass` in the examples is because a
stock Windows will not run a `.ps1` at all.

## 1. Get the game project working on your PC first

Follow [Spicywonda/castlevania-chronicles-recomp](https://github.com/Spicywonda/castlevania-chronicles-recomp)
`v0.3.9` to the letter, with your own disc and the BIOS it asks for. That project fetches RecompOne
and adds its own C# files to it. If it does not run on your PC, nothing here will help.

## 2. Apply the patch — and mind the order

```powershell
git apply <this repo>\patches\01-recompone-uwp.patch
```

⚠ **Run it inside the RecompOne tree that the game project prepared**, not a fresh clone of
RecompOne. Our patch sits on top of the game project's own additions, and applied to RecompOne's
`main` git will tell you the patch is broken. It is not: it is in the wrong place.

Measured on 2026-10-14: on the prepared tree the patch applies clean and reproduces, byte for byte,
the 22 files of the tree the shipped package was built from.

## 3. Build the host with NativeAOT

The Xbox host is in `src/`: copy the three files into the game project as its Xbox target, then

```powershell
powershell -ExecutionPolicy Bypass -File tools\construir-uwp.ps1
```

NativeAOT compiles the C# the recompiler produced into a native binary, which is what makes a .NET
game publishable as a UWP app at all. It links through Visual Studio's C++ tools, so those have to
be installed even though nothing here is C++.

## 4. Package, sign and install

```powershell
powershell -ExecutionPolicy Bypass -File tools\empaquetar-uwp.ps1 -Huella <your thumbprint>
```

Your own tiles go in first ([`ASSETS.md`](ASSETS.md)); this repository ships none. `Publisher` in
`package/Package.appxmanifest` must be **exactly** the subject of your certificate.

Install through the Device Portal (`https://<console ip>:11443`, with your Dev Home username
and password), with the `Microsoft.VCLibs.140.00` x64 appx as a dependency, and **a user signed
in** on the console.

## 5. The disc, which does not fit

```powershell
python tools\partir_disco.py <your disc image> --salida <folder>
```

Uploads to the console go through `D:\DevelopmentFiles`, which is small (5 GB) and usually nearly
full, and a PS1 disc image does not fit. The script splits it into parts; the host joins them on
first boot. Upload the parts one at a time — files uploaded inside a `.zip` come out with
permissions the AppContainer cannot read.

## 6. When something goes wrong

| What you see | What it is |
|---|---|
| `git apply` says the patch does not apply | You are applying it to a clean RecompOne instead of the tree the game project prepared (section 2) |
| NativeAOT fails on `System.Text.Json` | The patch is not applied: it replaces that with a reader that survives AOT |
| The upload of the disc fails with HTTP 500 | The image was not split (section 5) |
| The console installs it and nothing happens on open | No user signed in on the console |
| It installs but the game is the old build | The package version did not go up |
| The picture is stretched | 16:9 was switched off on purpose in 0.1.0.4; the original is 4:3 |
