# Instalación — del proyecto del juego al juego en la consola

*(English: [INSTALL.md](INSTALL.md))*

## 0. Dónde se escriben estas órdenes

**PowerShell** para todo esto (pulsa **Windows**, escribe `powershell`, **Entrar**), en una ventana
**normal**: el certificado vive en el almacén de quien ejecuta la orden, así que «ejecutar como
administrador» rompe el paso de la firma. El `-ExecutionPolicy Bypass` de los ejemplos es porque un
Windows de fábrica no ejecuta un `.ps1`.

## 1. Haz funcionar primero el proyecto del juego en tu PC

Sigue [Spicywonda/castlevania-chronicles-recomp](https://github.com/Spicywonda/castlevania-chronicles-recomp)
`v0.3.9` al pie de la letra, con tu propio disco y la BIOS que pide. Ese proyecto descarga RecompOne
y le añade sus propios archivos C#. Si no corre en tu PC, nada de aquí va a ayudar.

## 2. Aplicar el parche — y cuidado con el orden

```powershell
git apply <este repo>\patches\01-recompone-uwp.patch
```

⚠ **Ejecútalo dentro del árbol de RecompOne que preparó el proyecto del juego**, no en un clon nuevo
de RecompOne. Nuestro parche va encima de los añadidos del propio proyecto, y aplicado al `main` de
RecompOne git te dirá que el parche está roto. No lo está: está en el sitio equivocado.

Medido el 2026-10-14: sobre el árbol preparado, el parche aplica limpio y reproduce, byte a byte,
los 22 archivos del árbol del que salió el paquete instalado.

## 3. Compilar el anfitrión con NativeAOT

El anfitrión de Xbox está en `src/`: copia los tres archivos al proyecto del juego como su objetivo
de Xbox y luego

```powershell
powershell -ExecutionPolicy Bypass -File tools\construir-uwp.ps1
```

NativeAOT compila el C# que produjo el recompilador a un binario nativo, que es lo que hace posible
publicar un juego de .NET como app UWP. Enlaza con las herramientas de C++ de Visual Studio, así que
hay que tenerlas instaladas aunque aquí no haya nada de C++.

## 4. Empaquetar, firmar e instalar

```powershell
powershell -ExecutionPolicy Bypass -File tools\empaquetar-uwp.ps1 -Huella <tu huella>
```

Primero van tus mosaicos ([`ASSETS.es.md`](ASSETS.es.md)); este repositorio no trae ninguno. El
`Publisher` de `package/Package.appxmanifest` tiene que ser **exactamente** el sujeto de tu
certificado.

Instala por el Device Portal (`https://<ip de la consola>:11443`, con el usuario y la
contraseña de Dev Home), con el appx de `Microsoft.VCLibs.140.00` para x64 como dependencia y
**un usuario conectado** en la consola.

## 5. El disco, que no cabe

```powershell
python tools\partir_disco.py <tu imagen de disco> --salida <carpeta>
```

Las subidas a la consola van por `D:\DevelopmentFiles`, que es pequeño (5 GB) y suele estar casi
lleno, y una imagen de disco de PS1 no cabe. El script la parte en trozos; el anfitrión los junta en
el primer arranque. Sube los trozos de uno en uno: los archivos subidos dentro de un `.zip` quedan
con permisos que el AppContainer no puede leer.

## 6. Cuando algo sale mal

| Lo que ves | Qué es |
|---|---|
| `git apply` dice que el parche no aplica | Lo estás aplicando a un RecompOne limpio en vez del árbol que preparó el proyecto del juego (apartado 2) |
| NativeAOT falla con `System.Text.Json` | El parche no está aplicado: eso lo sustituye por un lector que sobrevive al AOT |
| La subida del disco falla con HTTP 500 | La imagen no se partió (apartado 5) |
| La consola lo instala y al abrirlo no pasa nada | No hay usuario conectado en la consola |
| Se instala pero el juego es el viejo | No subió la versión del paquete |
| La imagen sale estirada | El 16:9 se apagó a propósito en la 0.1.0.4; el original es 4:3 |
