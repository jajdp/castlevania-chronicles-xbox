using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Text;
using RecompOne.Runtime;
using RecompOne.Runtime.Config;
using RecompOne.Runtime.Memory;
using GameRuntime = RecompOne.Runtime.Runtime;

namespace Chronicles.Xbox;

// Entrada de Castlevania Chronicles en la Xbox (UWP + NativeAOT), en lugar de Program.cs.
// SDL2 (worleydl/uwp-dep) se queda con la CoreApplication: Main le cede el control con SDL_WinRTRunApp y el
// juego corre dentro de SdlMain, en el hilo de la CoreWindow, igual que Program.cs en el hilo principal.
// Todo lo que el runtime escribe con rutas relativas (settings.json, interface.ini, carda.sav, cardb.sav)
// va a LocalState, que pasa a ser el directorio actual; el disco va en LocalState\disc\chronicles.cue.
internal static unsafe class XboxProgram
{
    private const string Title = "Castlevania Chronicles";
    private const string CueName = "chronicles.cue";
    private const int SdlWinRtPathLocalFolder = 1;

    private static int _exitCode;

    [DllImport("SDL2", CallingConvention = CallingConvention.Cdecl)]
    private static extern int SDL_WinRTRunApp(delegate* unmanaged[Cdecl]<int, byte**, int> mainFunction,
        void* reserved);

    [DllImport("SDL2", CallingConvention = CallingConvention.Cdecl)]
    private static extern byte* SDL_WinRTGetFSPathUTF8(int pathType);

    [DllImport("SDL2", CallingConvention = CallingConvention.Cdecl)]
    private static extern int SDL_SetHint(byte* name, byte* value);

    private static int Main(string[] args)
    {
#if XBOX_UWP
        // En la Xbox, B es «atrás»: sin esto SDL deja que el sistema cierre la app.
        SetHint("SDL_WINRT_HANDLE_BACK_BUTTON", "1");
        return SDL_WinRTRunApp(&SdlMain, null);
#else
        // Prueba en el PC: el mismo código sin WinRT; «LocalState» es la carpeta local\ junto al .exe.
        return Run(Path.Combine(AppContext.BaseDirectory, "local"), args.Length > 0 ? Path.GetFullPath(args[0]) : null);
#endif
    }

    [UnmanagedCallersOnly(CallConvs = [typeof(CallConvCdecl)])]
    private static int SdlMain(int argc, byte** argv)
    {
        var local = Marshal.PtrToStringUTF8((nint)SDL_WinRTGetFSPathUTF8(SdlWinRtPathLocalFolder));
        return Run(string.IsNullOrEmpty(local) ? AppContext.BaseDirectory : local, null);
    }

    private static int Run(string local, string? cueArgument)
    {
        Directory.CreateDirectory(local);
        Directory.SetCurrentDirectory(local);

        var log = new StreamWriter(
            new FileStream(Path.Combine(local, "run.log"), FileMode.Create, FileAccess.Write, FileShare.ReadWrite),
            new UTF8Encoding(false)) { AutoFlush = true };
        Console.SetOut(log);
        Console.SetError(log);
        Console.WriteLine($"[Xbox] {Title} {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
        Console.WriteLine($"[Xbox] LocalState: {local}");
        SetEnvironment(local);

        try
        {
            var cue = cueArgument ?? PrepareDisc(Path.Combine(local, "disc"));
            Console.WriteLine($"[Xbox] disc: {cue}");

            ConfigManager.Load();
            GameRuntime.Defaults(view =>
            {
                view.Language = "en";
#if XBOX_UWP
                // La barra de menú se abre con F1 y se maneja con ratón: en la consola no sirve.
                view.HideTopBar = true;
                // Sin interface.ini —el caso de la consola, donde nunca se ha abierto el menú— ViewConfig.VSync cae
                // en «false» y la vista se crea con intervalo de intercambio 0: el juego presenta a mitad de barrido
                // y se ve el desgarro (run.log: «[Host] swap interval: 0»). Va encendida de fábrica; si el usuario la
                // apaga desde los ajustes, su interface.ini manda.
                if (!view.Values.ContainsKey("VSync")) view.VSync = true;
#endif
            });
            ConfigManager.Game.CdPath = cue;
            ConfigManager.SaveGame();
            Widescreen.Initialize();
            GameRuntime.Run(() =>
            {
                var memory = new PSMemory();
                try
                {
                    Recompiled.Entry.Run(memory, cue, Title);
                }
                catch (HardResetSignal)
                {
                    throw;
                }
                catch (Exception error)
                {
                    _exitCode = 1;
                    Console.Error.WriteLine(error);
                }
            });
            Console.WriteLine($"[Xbox] exit {_exitCode}");
            return _exitCode;
        }
        catch (Exception error)
        {
            Console.Error.WriteLine($"[Xbox] fatal: {error}");
            return 1;
        }
    }

    // Un proceso UWP no recibe variables de entorno: las pone el port. La pantalla ancha experimental del proyecto
    // (Widescreen.cs: 16:9 solo en la primera etapa) va APAGADA de fábrica desde el 2026-10-11, a pedido del
    // usuario: se ve mal —bordes y objetos que entran tarde— y no hay ninguna versión panorámica mejor publicada,
    // ni en el proyecto ni fuera de él. Hasta esa fecha iba encendida, porque en la consola no hay teclado para F8.
    // LocalState\entorno.txt añade o cambia variables, una NOMBRE=valor por línea («#» comenta):
    // CHRONICLES_WIDESCREEN=1 la recupera. Receta del Monster Hunter de la zona IA (Recompilaciones, 2026-10-03).
    private static void SetEnvironment(string local)
    {
        if (Environment.GetEnvironmentVariable("CHRONICLES_WIDESCREEN") == null)
            Environment.SetEnvironmentVariable("CHRONICLES_WIDESCREEN", "0");
        var file = Path.Combine(local, "entorno.txt");
        if (File.Exists(file))
            foreach (var raw in File.ReadAllLines(file))
            {
                var line = raw.Trim();
                var eq = line.IndexOf('=');
                if (line.Length == 0 || line.StartsWith('#') || eq <= 0) continue;
                Environment.SetEnvironmentVariable(line[..eq].Trim(), line[(eq + 1)..].Trim());
            }
        Console.WriteLine($"[Xbox] CHRONICLES_WIDESCREEN={Environment.GetEnvironmentVariable("CHRONICLES_WIDESCREEN")}");
    }

    // El Device Portal no acepta el .bin entero (528 MB pasan por D:\DevelopmentFiles, casi lleno): se sube en
    // partes «<bin>.partNN» y aquí se unen la primera vez. Las partes se borran solo si la suma cuadra.
    private static string PrepareDisc(string discDir)
    {
        Directory.CreateDirectory(discDir);
        var cue = Path.Combine(discDir, CueName);
        if (!File.Exists(cue))
        {
            Console.Error.WriteLine($"[Xbox] missing {cue}");
            return cue;
        }

        foreach (var line in File.ReadAllLines(cue))
        {
            var text = line.Trim();
            if (!text.StartsWith("FILE ", StringComparison.OrdinalIgnoreCase)) continue;
            var open = text.IndexOf('"');
            var close = text.LastIndexOf('"');
            if (open < 0 || close <= open) continue;
            JoinParts(Path.Combine(discDir, text.Substring(open + 1, close - open - 1)));
        }

        return cue;
    }

    private static void JoinParts(string bin)
    {
        var parts = Directory.GetFiles(Path.GetDirectoryName(bin)!, Path.GetFileName(bin) + ".part*")
            .Order(StringComparer.Ordinal).ToArray();
        if (parts.Length == 0)
        {
            Console.WriteLine(File.Exists(bin)
                ? $"[Xbox] {Path.GetFileName(bin)}: {new FileInfo(bin).Length} bytes"
                : $"[Xbox] missing {bin}");
            return;
        }

        var expected = parts.Sum(p => new FileInfo(p).Length);
        var joining = bin + ".joining";
        using (var output = new FileStream(joining, FileMode.Create, FileAccess.Write))
        {
            foreach (var part in parts)
            {
                using var input = File.OpenRead(part);
                input.CopyTo(output, 1 << 20);
            }
        }

        var joined = new FileInfo(joining).Length;
        if (joined != expected)
        {
            Console.Error.WriteLine($"[Xbox] join of {Path.GetFileName(bin)} gave {joined} bytes, expected {expected}");
            return;
        }

        File.Move(joining, bin, true);
        foreach (var part in parts) File.Delete(part);
        Console.WriteLine($"[Xbox] {Path.GetFileName(bin)}: joined {parts.Length} parts, {joined} bytes");
    }

    private static void SetHint(string name, string value)
    {
        var n = Encoding.UTF8.GetBytes(name + "\0");
        var v = Encoding.UTF8.GetBytes(value + "\0");
        fixed (byte* pn = n, pv = v)
        {
            SDL_SetHint(pn, pv);
        }
    }
}
