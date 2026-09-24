redist\ FOLDER  -  .NET DESKTOP RUNTIME 8.0 (OPTIONAL)
================================================================================

THIS FOLDER SHIPS EMPTY ON PURPOSE, and the installer compiles either way.

WHAT GOES HERE

    windowsdesktop-runtime-8.0.30-win-x64.exe   (~58 MB)

    https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/8.0.30/windowsdesktop-runtime-8.0.30-win-x64.exe

    It must be the WINDOWS DESKTOP RUNTIME, x64. The "ASP.NET Core Runtime"
    or the plain ".NET Runtime" will not do - PgsToSrt uses the desktop part.

WHAT IT IS FOR

    PgsToSrt (the subtitle OCR - since 2.0 the ONLY one, seconv is gone)
    needs the .NET Desktop Runtime 8.0 installed on Windows.

    WITH the file here:    the installer carries the runtime inside and
                           installs it by itself if the machine needs it.
                           Works offline.

    WITHOUT the file:      the installer is built the same, 58 MB smaller. If
                           the target machine lacks .NET 8, it offers to
                           DOWNLOAD it from Microsoft during installation -
                           which needs internet at that moment.

    In neither case does the program stop converting video. But without
    .NET 8 the PGS subtitle does NOT become .SRT: video and audio come out
    normally and the original PGS stays in the MKV.

WHICH VERSION WORKS - AND HOW TO CHECK WITHOUT INSTALLING ANYTHING

    Any 8.0.x. PgsToSrt.runtimeconfig.json requests:

        "framework": { "name": "Microsoft.NETCore.App", "version": "8.0.0" }

    with no rollForward declared. .NET rolls forward WITHIN the same MAJOR
    version, never across majors: a net8.0 app accepts 8.0.29, 8.0.31, any
    8.0.x - and REJECTS 6.0, 9.0 and 10.0, even though they are newer.

    To see what is already installed on the machine:

        dir "C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App"

    Each installed version is a FOLDER named after its number. If an 8.0.*
    folder shows up, PgsToSrt works on that machine.

PAY ATTENTION TO THE FILENAME

    The .iss looks for the EXACT NAME set in its "#define Runtime" -
    currently "windowsdesktop-runtime-8.0.30-win-x64.exe". If you download a
    different 8.0.x, the file has a DIFFERENT name and the installer compiles
    without the runtime inside - the compiler SHOWS a warning about it on the
    Inno screen. If you see that warning and want the runtime embedded, edit
    the "#define Runtime" line at the top of LaFirma_Setup.iss to match the
    file you downloaded.
