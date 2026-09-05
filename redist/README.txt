redist\ FOLDER - .NET DESKTOP RUNTIME 8.0 (OPTIONAL)
================================================================================

THIS FOLDER IS INTENTIONALLY EMPTY, and the installer compiles either way.

WHAT GOES HERE

    windowsdesktop-runtime-8.0.30-win-x64.exe   (~58 MB)

    https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/8.0.30/windowsdesktop-runtime-8.0.30-win-x64.exe

    It MUST be the WINDOWS DESKTOP RUNTIME, x64. The "ASP.NET Core Runtime" 
    or plain ".NET Runtime" will NOT work - PgsToSrt requires the desktop component.

WHICH VERSION WORKS - AND HOW TO FIND OUT WITHOUT INSTALLING ANYTHING

    Diego, Sep 03: "the day I ran this test I installed every version of this 
    crap and only one worked [...] how on earth are we supposed to know without 
    doing a whole build, wasting time installing, uninstalling, etc.?"

    YOU DON'T HAVE TO. The answer is on the machine itself:

        dir "C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App"

    Each installed version is a FOLDER with the version number as its name. 
    The 8.0.* folder that appears there is the working one. On Diego's machine, on Sep 03:

        6.0.24    8.0.29    9.0.5    10.0.10    11.0.0-preview

    Only one 8.0.x: 8.0.29. Starting from 1.7.3, the project default became 
    8.0.30 by Diego's choice — same family, same effect.

    WHY ONLY ONE WORKED. It's not a magic version. PgsToSrt.runtimeconfig.json requests:

        "framework": { "name": "Microsoft.NETCore.App", "version": "8.0.0" }

    without a declared rollForward setting. .NET rolls forward WITHIN the same 
    MAJOR version, never across major versions: a net8.0 app accepts 8.0.29, 8.0.31, 
    or any 8.0.x — and REJECTS 6.0, 9.0, and 10.0, even if they are newer. 
    Out of all the versions installed that day, only the 8.0 family could work.

    In short: any 8.0.x works. A different version family will not.


PAY ATTENTION TO THE FILENAME

    The .iss script searches for the EXACT FILENAME specified in its "#define Runtime" 
    directive — currently "windowsdesktop-runtime-8.0.30-win-x64.exe". If you download 
    a different 8.0.x version, the file will have a DIFFERENT name, and the installer 
    will compile SILENTLY without embedding the runtime.

    Starting from v1.7.1, Inno Setup displays a WARNING on screen during compilation 
    if the expected file is missing. If you see this warning and want the embedded runtime, 
    edit the "#define Runtime" line at the top of LaFirma_Setup.iss to match the 
    filename you downloaded.

    Any 8.0.x works: PgsToSrt requests "net8.0" in runtimeconfig, and .NET rolls 
    forward within the same major version.

    Where 8.0.29 came from: it was the file already inside this folder before the 
    flawed instructions I gave caused Diego to delete it. Version 8.0.30 is his 
    choice moving forward.


WHAT IT IS USED FOR

    PgsToSrt (the BACKUP subtitle OCR engine, used when seconv fails) requires 
    the .NET Desktop Runtime 8.0 installed on Windows.

    WITH the file here:     The installer embeds the runtime inside itself and installs 
                            it automatically if needed on the target machine. Works offline.

    WITHOUT the file:      The installer is generated normally, ~58 MB smaller. If the 
                            target machine lacks .NET 8, it offers to DOWNLOAD it 
                            from Microsoft during installation — requiring an internet 
                            connection at that moment.

    In neither case does the program fail to convert videos: without .NET 8, OCR 
    continues to function via seconv (the primary engine, which requires no 
    installed dependencies). You only lose the secondary fallback path.

WHY THIS FILE EXISTS

    v1.7.1 - The step-by-step guide I (Claude) gave Diego said "delete everything 
    inside LaFirma_Setup except the source folder, then paste the zip over it". 
    The redist\ folder was part of "everything", and his runtime file was deleted along 
    with it. The zip package I send does not carry the 58 MB runtime file — and I 
    had never mentioned that.

    Now this folder comes inside the zip with this note inside. Overwriting with 
    the zip will never make the folder disappear without explanation again.