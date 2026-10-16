<#
.SYNOPSIS
  Construye desde cero Castlevania Chronicles Recomp para la Xbox (NativeAOT + UWP) y lo empaqueta.

.DESCRIPTION
  Todo sale de lo que guarda el subproyecto:
    pc\espejo\castlevania-chronicles-recomp-v0.3.9-source.zip   el proyecto del juego (Spicywonda)
    xbox\espejo\RecompOne-d81dec8.zip                            el runtime, en el commit que fija el juego
    xbox\espejo\uwp-dep-0ec87d2-x64.zip                          SDL2 WinRT, Mesa 25.1.1 y libuwp (worleydl)
    xbox\espejo\cimgui-1.90.8-7c16d31.zip                        cimgui de ImGui.NET 1.90.8.1
    xbox\fuentes\recompone-uwp-v039.patch                        la variante UWP del runtime (RECOMPONE_UWP)
    xbox\fuentes\anfitrion\                                      el ejecutable de Xbox (XboxProgram.cs) y su csproj

  Con -Fuente y -ParcheUwp se puede volver a una versión anterior del juego (la v0.1.0 y su
  recompone-uwp.patch siguen en el espejo). Cada versión del recomp lleva su parche: los parches
  del proyecto tocan los mismos archivos del runtime que la variante UWP.
  y del disco del usuario (USA SLUS-01384), del que se genera el C# del juego.

  Pasos: 1) SDK de .NET 10.0.401 portátil en <tree>;  2) árbol en <Raiz>\xb con los 5 parches del
  proyecto y el parche UWP;  3) C# del juego generado desde el disco + parche de sprites;  4) cimgui para
  UWP (CMake, WindowsStore);  5) dotnet publish con NativeAOT;  6) empaquetar-uwp.ps1 (makeappx + firma).
  Necesita Visual Studio 2022 con C++ (link.exe y el SDK de Windows), CMake, Git y Python 3.13 (py).
  Con -Reusar (desde la 0.1.0.2, 2026-10-03) y un árbol <Raiz>\xb ya construido, solo copia el anfitrión de
  xbox\fuentes\anfitrion\ y hace los pasos 5 y 6, con el cimgui más reciente de <Raiz>: el C# del juego no cambia.

.EXAMPLE
  pwsh -File construir-uwp.ps1 -Cue 'D:\juegos\Castlevania Chronicles\chronicles.cue' -Version 0.1.0.1
  pwsh -File construir-uwp.ps1 -Reusar -Version 0.1.0.2
#>
[CmdletBinding()]
param(
  [string]$Cue = '',
  [string]$Raiz = '<tree>',
  [string]$Version = '',
  [string]$Fuente = '',
  [string]$ParcheUwp = '',
  [switch]$SinEmpaquetar,
  [switch]$Reusar
)
if (-not $Reusar -and -not $Cue) { throw 'falta -Cue (o -Reusar con un árbol ya construido)' }
$ErrorActionPreference = 'Stop'
$xbox = Split-Path $PSScriptRoot -Parent
$sub = Split-Path $xbox -Parent
$espejo = Join-Path $xbox 'espejo'

# El recomp del juego sube de versión a menudo (v0.1.0 el 2026-10-02, v0.3.9 el 2026-10-10), y cada
# una lleva su parche UWP porque los parches del proyecto tocan los mismos archivos del runtime.
# Por defecto, la última pareja conocida; -Fuente y -ParcheUwp sirven para volver a una anterior.
if (-not $Fuente) { $Fuente = Join-Path $sub 'pc\espejo\castlevania-chronicles-recomp-v0.3.9-source.zip' }
if (-not $ParcheUwp) { $ParcheUwp = Join-Path $xbox 'fuentes\recompone-uwp-v039.patch' }
foreach ($f in @($Fuente, $ParcheUwp)) {
  if (-not $Reusar -and -not (Test-Path -LiteralPath $f)) { throw "no está: $f" }
}
$t = [Diagnostics.Stopwatch]::StartNew()
function Paso([string]$s) { Write-Host ("=== {0}  ({1:N0} s)" -f $s, $t.Elapsed.TotalSeconds) }
function Nativo([scriptblock]$b, [string]$que) { & $b; if ($LASTEXITCODE -ne 0) { throw "falló: $que ($LASTEXITCODE)" } }

# --- 1. SDK de .NET 10 portátil ---------------------------------------------
Paso '1. SDK de .NET 10.0.401'
$dotnet = '<tree>'
if (-not (Test-Path -LiteralPath $dotnet)) {
  $inst = Join-Path $env:TEMP 'dotnet-install.ps1'
  Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile $inst -UseBasicParsing
  & $inst -Version 10.0.401 -InstallDir '<tree>' -NoPath
}
# vswhere: lo llaman los targets de NativeAOT para encontrar link.exe.
$env:PATH = '<tree>;' + ${env:ProgramFiles(x86)} + '\Microsoft Visual Studio\Installer;' + $env:PATH
$env:DOTNET_ROOT = '<tree>'; $env:DOTNET_MULTILEVEL_LOOKUP = '0'; $env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
$env:DOTNET_NOLOGO = '1'; $env:NUGET_PACKAGES = Join-Path $Raiz 'nuget'
& $dotnet --version

$xb = Join-Path $Raiz 'xb'
$anf = Join-Path $xbox 'fuentes\anfitrion'
if ($Reusar) {
  # --- 2 a 4, sin rehacer: el anfitrión nuevo sobre el árbol que ya está --------
  Paso '2-4. árbol ya construido (-Reusar)'
  if (-not (Test-Path -LiteralPath (Join-Path $xb 'xbox\CastlevaniaChronicles.Xbox.csproj'))) { throw "-Reusar: no hay árbol en $xb" }
  Copy-Item -LiteralPath (Join-Path $anf 'CastlevaniaChronicles.Xbox.csproj'), (Join-Path $anf 'XboxProgram.cs') -Destination (Join-Path $xb 'xbox') -Force
  Copy-Item -LiteralPath (Join-Path $anf 'Directory.Build.props') -Destination $xb -Force
  $cimgui = Get-ChildItem -LiteralPath $Raiz -Directory -Filter 'cimgui-uwp*' |
    ForEach-Object { Join-Path $_.FullName 'Release\cimgui.dll' } | Where-Object { Test-Path -LiteralPath $_ } |
    Sort-Object { (Get-Item -LiteralPath $_).LastWriteTime } | Select-Object -Last 1
  if (-not $cimgui) { throw "-Reusar: no hay cimgui.dll compilado en $Raiz" }
  Write-Host "  anfitrión copiado; cimgui: $cimgui"
} else {
# --- 2. árbol ----------------------------------------------------------------
Paso '2. árbol'
if (Test-Path -LiteralPath $xb) { throw "ya existe ${xb}; usa otra -Raiz, aparta ese árbol o usa -Reusar" }
$tmp = Join-Path $Raiz ("tmp-{0:yyyyMMddHHmmss}" -f (Get-Date))
Expand-Archive -LiteralPath $Fuente -DestinationPath $tmp
# La carpeta de dentro lleva la versión en el nombre: no se da por supuesta.
$dentro = Get-ChildItem -LiteralPath $tmp -Directory -Filter 'castlevania-chronicles-recomp-*' | Select-Object -First 1
if (-not $dentro) { throw "el zip no trae una carpeta castlevania-chronicles-recomp-*: $Fuente" }
Write-Host "  juego: $($dentro.Name)"
Move-Item -LiteralPath $dentro.FullName -Destination $xb
$vendor = Join-Path $xb 'vendor'
if (-not (Test-Path -LiteralPath $vendor)) { New-Item -ItemType Directory -Path $vendor | Out-Null }
Expand-Archive -LiteralPath (Join-Path $espejo 'RecompOne-d81dec8.zip') -DestinationPath $tmp
# El submódulo puede venir como carpeta vacía o no venir: las dos formas valen.
$hueco = Join-Path $vendor 'RecompOne'
if (Test-Path -LiteralPath $hueco) { Move-Item -LiteralPath $hueco -Destination (Join-Path $tmp 'RecompOne-vacio') }
Move-Item -LiteralPath (Join-Path $tmp 'RecompOne') -Destination $hueco
$ro = Join-Path $vendor 'RecompOne'
foreach ($p in (Get-ChildItem -LiteralPath (Join-Path $xb 'patches\runtime') -Filter *.patch | Sort-Object Name)) {
  Nativo { git -C $ro apply --whitespace=nowarn $p.FullName } "parche $($p.Name)"
  Write-Host "  parche del proyecto: $($p.Name)"
}
Nativo { git -C $ro apply --whitespace=nowarn $ParcheUwp } 'parche UWP'
Write-Host "  parche UWP: $(Split-Path -Leaf $ParcheUwp)"
New-Item -ItemType Directory -Force (Join-Path $xb 'xbox') | Out-Null
Copy-Item -LiteralPath (Join-Path $anf 'CastlevaniaChronicles.Xbox.csproj'), (Join-Path $anf 'XboxProgram.cs') -Destination (Join-Path $xb 'xbox')
Copy-Item -LiteralPath (Join-Path $anf 'Directory.Build.props') -Destination $xb

# --- 3. C# del juego desde el disco ------------------------------------------
Paso '3. C# del juego (recompone)'
$config = Join-Path $xb 'config\CastlevaniaChronicles.json'
$json = [IO.File]::ReadAllText($config)
$cueJson = (Resolve-Path -LiteralPath $Cue).Path.Replace('\', '/')
$json = [regex]::Replace($json, '"cue"\s*:\s*"[^"]*"', '"cue": "' + $cueJson + '"')
[IO.File]::WriteAllText($config, $json, [Text.UTF8Encoding]::new($false))
Nativo { & $dotnet build (Join-Path $ro 'RecompOne.Recompiler') -c Release -v q -nologo } 'compilar el recompilador'
$rc = Get-ChildItem (Join-Path $ro 'RecompOne.Recompiler\bin\Release') -Recurse -Filter recompone.dll | Select-Object -First 1
Push-Location (Join-Path $xb 'config')
try { Nativo { & $dotnet $rc.FullName CastlevaniaChronicles.json } 'recompone' } finally { Pop-Location }
# Lo hace el csproj de PC antes de compilar (RequireGeneratedGame); el de Xbox no lo hereda.
Nativo { py -3.13 -X utf8 (Join-Path $xb 'scripts\patch-sprite-visibility.py') } 'patch-sprite-visibility.py'

# --- 4. cimgui para UWP ------------------------------------------------------
Paso '4. cimgui 1.90.8 para UWP'
$cimguiSrc = Join-Path $Raiz 'cimgui-src'
if (-not (Test-Path -LiteralPath $cimguiSrc)) { Expand-Archive -LiteralPath (Join-Path $espejo 'cimgui-1.90.8-7c16d31.zip') -DestinationPath $cimguiSrc }
$cimguiBuild = Join-Path $Raiz ("cimgui-uwp-{0:yyyyMMddHHmmss}" -f (Get-Date))
# Entre comillas: PowerShell parte «-DVAR=10.0» en «-DVAR=10» y «.0»; sin portapapeles ni IME de Win32.
Nativo { cmake -S (Join-Path $cimguiSrc 'cimgui') -B $cimguiBuild -G 'Visual Studio 17 2022' -A x64 '-DCMAKE_SYSTEM_NAME=WindowsStore' '-DCMAKE_SYSTEM_VERSION=10.0' '-DCMAKE_CXX_FLAGS=/DIMGUI_DISABLE_WIN32_FUNCTIONS /EHsc' | Out-Null } 'cmake de cimgui'
Nativo { cmake --build $cimguiBuild --config Release | Out-Null } 'compilar cimgui'
$cimgui = Join-Path $cimguiBuild 'Release\cimgui.dll'
}

# --- 5. NativeAOT ------------------------------------------------------------
Paso '5. dotnet publish (NativeAOT, UWP)'
$out = Join-Path $Raiz 'out\uwp'
Nativo { & $dotnet publish (Join-Path $xb 'xbox\CastlevaniaChronicles.Xbox.csproj') -c Release '-p:XboxUwp=true' -o $out -nologo -v q } 'dotnet publish'
$exe = Join-Path $out 'CastlevaniaChronicles.exe'
Write-Host ("  {0} ({1:N0} B)" -f $exe, (Get-Item -LiteralPath $exe).Length)

# --- 6. paquete --------------------------------------------------------------
if (-not $SinEmpaquetar) {
  Paso '6. paquete'
  if (-not $Version) { throw 'falta -Version (sube en cada ciclo)' }
  $dep = Join-Path $Raiz 'uwp-dep-espejo'
  if (-not (Test-Path -LiteralPath $dep)) { Expand-Archive -LiteralPath (Join-Path $espejo 'uwp-dep-0ec87d2-x64.zip') -DestinationPath $dep }
  & (Join-Path $PSScriptRoot 'empaquetar-uwp.ps1') -Version $Version -Exe $exe -Cimgui $cimgui `
      -UwpDep (Join-Path $dep 'uwp-dep\x64\bin') -Layouts (Join-Path $Raiz 'layout')
}
Paso 'fin'
