<#
.SYNOPSIS
  Empaqueta y firma Castlevania Chronicles Recomp (NativeAOT + UWP) como .msix para la Xbox Series.

.DESCRIPTION
  No hay proyecto de Visual Studio que empaquete: el ejecutable sale de `dotnet publish` con NativeAOT
  (xbox\herramientas\construir-uwp.ps1) y el paquete se arma a mano con makeappx, como Animal Crossing.
  Contenido: CastlevaniaChronicles.exe, las DLL de worleydl/uwp-dep (SDL2 para WinRT, Mesa 25.1.1 y
  libuwp), cimgui.dll compilado para UWP, el manifiesto y los mosaicos de xbox\package\.
  EL DISCO NO VA DENTRO (528 MB): se sube aparte a LocalState\disc\ en partes de 150 MiB.

  Deja en xbox\paquete\: el .msix firmado con CN=Decompilaciones, su .cer, VCLibs en Dependencies\ y
  SHA256SUMS.txt. Los paquetes de versiones anteriores NO se borran aquí.

.PARAMETER Version
  Sube en cada ciclo: la consola no reemplaza un paquete por otro de la MISMA versión.
#>
[CmdletBinding()]
param(
  [string]$Version = '0.1.0.0',
  [string]$Huella  = 'CHANGE-ME',   # CN=Decompilaciones
  [string]$Exe     = '<tree>',
  [string]$UwpDep  = '<tree>',                  # worleydl/uwp-dep 0ec87d2
  [string]$Cimgui  = '<tree>',  # cimgui 1.90.8 para UWP
  [string]$Layouts = '<tree>'
)
$ErrorActionPreference = 'Stop'

$xbox    = Split-Path $PSScriptRoot -Parent
$package = Join-Path $xbox 'package'
$paquete = Join-Path $xbox 'paquete'

foreach ($f in @($Exe, $Cimgui, (Join-Path $package 'Package.appxmanifest'))) {
  if (-not (Test-Path -LiteralPath $f)) { throw "falta $f" }
}

# --- herramientas del SDK -------------------------------------------------
$sdkVer = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin' -Directory |
  Where-Object { Test-Path (Join-Path $_.FullName 'x64\makeappx.exe') } |
  Sort-Object Name -Descending | Select-Object -First 1
if (-not $sdkVer) { throw 'no encuentro makeappx.exe en el SDK de Windows' }
$makeappx = Join-Path $sdkVer.FullName 'x64\makeappx.exe'
$signtool = Join-Path $sdkVer.FullName 'x64\signtool.exe'
Write-Host "  SDK: $($sdkVer.Name)"

# --- 1. layout (carpeta nueva en cada vuelta) -----------------------------
Write-Host '=== 1. layout ==='
$layout = Join-Path $Layouts ("{0}-{1:yyyyMMdd-HHmmss}" -f $Version, (Get-Date))
New-Item -ItemType Directory -Force -Path $layout | Out-Null
Copy-Item -LiteralPath $Exe -Destination $layout
# glfw3.dll se queda fuera: la ventana es de SDL.
foreach ($d in 'SDL2.dll', 'opengl32.dll', 'libgallium_wgl.dll', 'dxil.dll', 'libuwp.dll', 'z-1.dll') {
  Copy-Item -LiteralPath (Join-Path $UwpDep $d) -Destination $layout
}
Copy-Item -LiteralPath $Cimgui -Destination $layout
Copy-Item -LiteralPath (Join-Path $package 'Assets') -Destination $layout -Recurse

$manifiesto = [IO.File]::ReadAllText((Join-Path $package 'Package.appxmanifest'))
$manifiesto = [regex]::Replace($manifiesto, '(<Identity\b[^>]*?\bVersion=")[^"]+(")', "`${1}$Version`${2}")
[IO.File]::WriteAllText((Join-Path $layout 'AppxManifest.xml'), $manifiesto, [Text.UTF8Encoding]::new($false))

$archivos = Get-ChildItem -LiteralPath $layout -Recurse -File
Write-Host ("  {0} archivos, {1:N1} MB en {2}" -f $archivos.Count, (($archivos | Measure-Object Length -Sum).Sum / 1MB), $layout)

# --- 2. makeappx ----------------------------------------------------------
Write-Host '=== 2. makeappx ==='
New-Item -ItemType Directory -Force -Path $paquete | Out-Null
$msix = Join-Path $paquete "CastlevaniaChronicles-Recomp_${Version}_x64.msix"
if (Test-Path -LiteralPath $msix) { throw "ya existe ${msix}; sube la versión" }
& $makeappx pack /d $layout /p $msix /o | Select-Object -Last 2
if ($LASTEXITCODE -ne 0) { throw 'falló makeappx' }

# --- 3. firma, certificado y dependencias ---------------------------------
Write-Host '=== 3. firma ==='
& $signtool sign /fd SHA256 /sha1 $Huella $msix | Select-Object -Last 1
if ($LASTEXITCODE -ne 0) { throw 'falló la firma' }
$cer = [IO.Path]::ChangeExtension($msix, '.cer')
Export-Certificate -Cert "Cert:\CurrentUser\My\$Huella" -FilePath $cer | Out-Null

$deps = Join-Path $paquete 'Dependencies'
New-Item -ItemType Directory -Force -Path $deps | Out-Null
$vclibs = 'C:\Program Files (x86)\Microsoft SDKs\Windows Kits\10\ExtensionSDKs\Microsoft.VCLibs\14.0\Appx\Retail\x64\Microsoft.VCLibs.x64.14.00.appx'
if (-not (Test-Path -LiteralPath (Join-Path $deps 'Microsoft.VCLibs.x64.14.00.appx'))) { Copy-Item -LiteralPath $vclibs -Destination $deps }

# --- 4. sumas --------------------------------------------------------------
$sumas = Get-ChildItem -LiteralPath $paquete -Recurse -File | Where-Object Name -ne 'SHA256SUMS.txt' | Sort-Object FullName | ForEach-Object {
  '{0}  {1}' -f (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLower(), $_.FullName.Substring($paquete.Length + 1).Replace('\', '/')
}
[IO.File]::WriteAllLines((Join-Path $paquete 'SHA256SUMS.txt'), [string[]]$sumas, [Text.UTF8Encoding]::new($false))

Write-Host ("OK: {0} ({1:N0} B)" -f $msix, (Get-Item -LiteralPath $msix).Length)
