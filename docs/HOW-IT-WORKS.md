# How it works

*(Español: [HOW-IT-WORKS.es.md](HOW-IT-WORKS.es.md))*

## A PlayStation game that is C#

RecompOne does not emulate: it translates the MIPS code off the disc into **C#** and compiles it.
That makes this port unlike every other one in this family — the thing that has to run on the
console is a .NET application.

A packaged UWP app cannot JIT, so the answer is **NativeAOT**: the C# is compiled ahead of time into
a native binary, and `src/XboxProgram.cs` gives that binary the WinRT entry point. It links through
Visual Studio's C++ toolchain, which is why that has to be installed for a project with no C++ in
it.

## What the patch changes, and why each one

- **The host window** moves to SDL2 over Mesa: there is no Vulkan on an Xbox.
- **Audio and input** are reworked for the console: the desktop paths assume devices and APIs that
  are not there.
- **`System.Text.Json` goes away.** It does not survive NativeAOT here, so the config is read by a
  small generated reader (`RecompOneJson.cs`). This is the change most likely to look arbitrary and
  is the one that unblocks the build.
- **The asset pack and the config manager** learn where a packaged app may write, which is the app
  data folder and nothing else.

## Where the patch goes

On the RecompOne tree **the game project prepares** — RecompOne plus the C# files that project adds.
Not on a clean clone. Measured on 2026-10-14: on the prepared tree it applies clean and gives 22 of
22 files identical to the tree the shipped package was built from; on RecompOne's `main` it fails on
`Audio.cs` and the project file, which reads like a broken patch and is an ordering mistake.

## The disc that does not fit

The Device Portal uploads through `D:\DevelopmentFiles` on the console: 5 GB, usually nearly full.
A PlayStation disc image does not fit, and the failure is an HTTP 500 with no explanation.
`tools/partir_disco.py` splits the image; the host rejoins the parts on first boot. The same trick
is used by the psxrecomp ports in this family.

## 16:9 was switched off, on purpose

The port had an experimental widescreen from 0.1.0.2. It was **switched off on 2026-10-11** because
it looked wrong — the original is a 4:3 game and stretching it is not an improvement. Worth writing
down, because "the widescreen is missing" looks like a regression and is a decision.

## A note on language

The scripts and their messages are in English. A few comments in the patch are in Spanish, which is
where they were written, and they are published as they were compiled and verified.
