# tools/

*(Español: [README.es.md](README.es.md))*

| | |
|---|---|
| `construir-uwp.ps1` | Builds the host with NativeAOT for the UWP runtime identifier |
| `empaquetar-uwp.ps1` | Packages and signs. The certificate thumbprint is a parameter — `-Huella` — and not a value baked into the script |
| `partir_disco.py` | Splits the disc image into parts the Device Portal will accept, because uploads go through a 5 GB partition that is usually nearly full. The host rejoins them on first boot |

Every path is a parameter. The scripts are in English; `partir_disco.py` is plain Python 3 with
nothing but the standard library.
