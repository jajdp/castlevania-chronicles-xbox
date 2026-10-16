# Notice

*(Español: [NOTICE.es.md](NOTICE.es.md))*

## Not affiliated

Unofficial, noncommercial fan project. **Not affiliated with, endorsed by or connected to** the
rights holders of *Castlevania Chronicles*, with Microsoft, or with the authors of the projects it builds on.
*Castlevania Chronicles*, *Xbox* and all related names and marks belong to their respective owners. Nothing here
is for sale.

## What this repository does not distribute

No ROM or disc image, no BIOS, no extracted assets, no built binary, no package, no save data, no
package tiles (those were made from the game's own artwork) and no signing certificate. The
`.gitignore` blocks all of it by extension.

## What it does contain of other people's work

| | Lines | What it is | License |
|---|---|---|---|
| Our own patch lines | 468 | What `01-recompone-uwp.patch` adds to RecompOne.Runtime | ours, MIT |
| Quoted from RecompOne | 344 | The context lines a unified diff carries, plus the lines it replaces | MIT |
| `src/` | 283 | The Xbox host: the UWP entry point, the NativeAOT project file and its build properties | ours, MIT |
| `tools/` | 310 | Build, package and the disc splitter | ours, MIT |
| From the game project | **0** | It has no license. What it does is described in the docs, never copied | — |

The disc image and the BIOS are yours to supply and never travel through here. What the recipe carries about the disc is what `partir_disco.py` needs to split and rejoin it, and nothing of its content.

## Takedown

Write to **jajdpmail@gmail.com** and it comes down. No argument, no delay.
