================================================================================
           INNO SETUP COMPILATION & INSTALLATION GUIDE (.ISS)
                      LaFirma Remux Forge - Black Edition
================================================================================

THIS GUIDE IS FOR DEVELOPERS / BUILD CREATORS.
If you are the end user, simply run the 'LaFirma_Setup.exe' file.

--------------------------------------------------------------------------------
1. OVERVIEW & REPOSITORY PHILOSOPHY (GITHUB)
--------------------------------------------------------------------------------
Due to copyright policies and repository size limitations, heavy binary files 
and third-party tools contained in the 'tools\' directory ARE NOT UPLOADED 
TO GITHUB.

THIS RULE HAS BEEN AUTOMATED SINCE 09/09/2026: there is a .gitignore at the
project root that blocks fonte\tools\, the runtime .exe in redist\, the
compiled installer in Saida\, and everything the program creates while it
runs. It exists because "remember not to drag the tools folder" is the kind of
rule that fails once and pushes 1.16 GB of third-party binaries into a public
repository.

The repository contains only source scripts (.ps1, .bat, .vbs), configuration 
files, dictionaries, and this Inno Setup compilation script (.iss).

To compile the installer (.exe) from the repository root, YOU MUST MANUALLY
OBTAIN THE THIRD-PARTY TOOLS AND ASSEMBLE THE 'tools\' DIRECTORY before 
running the .iss compilation.


--------------------------------------------------------------------------------
2. PREREQUISITES FOR COMPILING
--------------------------------------------------------------------------------
1. Inno Setup 6 (or higher) installed on Windows.
   - Official Download: https://jrsoftware.org/isdl.php
2. (Optional, but recommended) .NET Dependency in the redist\ directory:
   - Download the "Windows Desktop Runtime 8.0.30 (x64)" installer from Microsoft.
   - Official Link: https://dotnet.microsoft.com/download/dotnet/8.0
   - Place the .exe installer inside the 'redist\' folder.
   - Note: If 'redist\' is empty, Inno Setup will compile normally (~58 MB smaller),
     but the final installer will attempt to download .NET from the web if missing 
     on the target machine.


--------------------------------------------------------------------------------
3. WHERE TO OBTAIN EACH TOOL FOR THE 'tools\' DIRECTORY
--------------------------------------------------------------------------------
Download the compressed archives from the links below and extract the 
executables/folders directly into the 'tools\' structure:

1. FFmpeg and FFprobe (ffmpeg.exe, ffprobe.exe):
   - Source: Gyan.dev or BtbN builds on GitHub.
   - Link: https://www.gyan.dev/ffmpeg/builds/ (Download 'ffmpeg-git-full.7z')
   - Action: Copy 'ffmpeg.exe' and 'ffprobe.exe' from the 'bin' folder into the 'tools\' root.

2. dovi_tool (dovi_tool.exe):
   - Source: quietvoid/dovi_tool repository on GitHub.
   - Link: https://github.com/quietvoid/dovi_tool/releases
   - Action: Download 'dovi_tool-x.x.x-x86_64-pc-windows-msvc.zip', extract, and 
     place 'dovi_tool.exe' directly in the 'tools\' root.
   - MINIMUM VERSION: 2.3.3. From 1.8 on, the program uses
     'export --levels level1,level5', which only exists from 2.3.3 onward. With
     2.3.2 nothing breaks - MEL x FEL detection still works, since it uses a
     different command - but the per-scene L1 census and the active area (L5)
     reading simply do not appear.
     The change was validated on our own bench: 5 files, 3 profiles, 2 CM
     versions, zero divergence in reading between 2.3.2 and 2.3.3.

3. MKVToolNix (mkvmerge.exe, mkvextract.exe):
   - Source: Official MKVToolNix downloads.
   - Link: https://mkvtoolnix.download/downloads.html#windows
   - Action: Download the portable version (.7z or .zip), extract, and copy 
     'mkvmerge.exe' and 'mkvextract.exe' into the 'tools\' root.

4. MediaInfo CLI (MediaInfo.exe, DLLs nvcuda/nvcuvid/LIBCURL):
   - Source: Official MediaInfo downloads (CLI release).
   - Link: https://mediaarea.net/en/MediaInfo/Download/Windows
   - Action: Download the 64-bit "Command Line Interface (CLI)" package and extract 
     'MediaInfo.exe' along with its supporting DLLs into the 'tools\' root.

5. SubtitleEdit (SubtitleEdit\ Subfolder):
   - Source: SubtitleEdit repository on GitHub.
   - Link: https://github.com/SubtitleEdit/subtitleedit/releases
   - Action: Download the portable package 'SE3xx.zip' and extract its contents into 
     'tools\SubtitleEdit\'.
     *IMPORTANT*: Ensure 'libSkiaSharp.dll' and 'Latin.db' are present in this subfolder 
     alongside 'seconv.exe'.

6. PgsToSrt (PgsToSrt\ Subfolder):
   - Source: Tensai75/PgsToSrt repository on GitHub.
   - Link: https://github.com/Tensai75/PgsToSrt/releases
   - Action: Extract the portable release into 'tools\PgsToSrt\'. Ensure the 
     'tessdata\' subfolder contains 'por.traineddata' (Portuguese language data).

7. Tesseract OCR (Tesseract\ Subfolder):
   - Source: tesseract-ocr/tesseract or UB-Mannheim binaries.
   - Link: https://github.com/UB-Mannheim/tesseract/wiki
   - Action: Install/Extract files into 'tools\Tesseract\', ensuring 'tesseract.exe' 
     is present and that 'por.traineddata' and 'osd.traineddata' are placed inside 
     'tools\Tesseract\tessdata\'.

8. DeeZy (DeeZy\ Subfolder):
   - Source: JessieLW/DeeZy repository on GitHub.
   - Link: https://jessielw.github.io/DeeZy/ or https://github.com/JessieLW/DeeZy
   - Action: Extract 'deezy.exe' and the 'apps\' folder into 'tools\DeeZy\'.


--------------------------------------------------------------------------------
4. REQUIRED DIRECTORY TREE (PRE-COMPILATION STRUCTURE)
--------------------------------------------------------------------------------
CORRECTED ON 09/09/2026. The previous version of this guide showed the .ps1
files at the project ROOT - they live inside 'fonte\', and that is where the
.iss packs them from (Source: "fonte\*", recursive). Anyone assembling the
folder from the old tree would compile an installer with no program in it.

Before clicking "Compile" in Inno Setup, your project root folder MUST contain
exactly the structure below:

<PROJECT_ROOT_FOLDER>\
|-- LaFirma_Setup.iss                <- The Inno Setup compilation script
|-- Compilar.bat                     <- Shortcut to compile without the IDE
|-- README.md                        <- The GitHub landing page
|-- .gitignore                       <- What does NOT go to GitHub (see 1)
|-- LEIA-ME_INSTALADOR[PT-BR].txt    <- This guide, in Portuguese
|-- README_INSTALLER[ENGLISH].txt    <- This guide
|
|-- fonte\                           <- EVERYTHING THAT BECOMES THE PROGRAM
|     |-- LaFirma_JANELA.ps1         <- WPF graphical interface
|     |-- Abrir_LaFirma_JANELA.bat   <- Shortcut with visible console
|     |-- Converter_AUTO_DIRETO.ps1  <- The engine
|     |-- Converter_AUTO_DIRETO.bat  <- Direct console launcher
|     |-- Corretor_Legenda.ps1       <- Subtitle post-processing
|     |-- Reocr_Legenda.ps1          <- Re-OCR with Tesseract
|     |-- Reocr_Legenda.bat          <- (dev tool, NOT shipped in the installer)
|     |-- Auditor_OCR.ps1 / .bat     <- (dev tool, NOT shipped)
|     |-- Auditor_OCR.dic.gz         <- Auditor support dictionary
|     |-- Limpar_Testes.ps1 / .bat   <- (dev tool, NOT shipped)
|     |-- LaFirma_PTBR_1.3M.dic.gz   <- Main PT-BR dictionary
|     |-- COMO_USAR_PT.txt           <- User manual, Portuguese
|     |-- HOW_TO_USE_EN.txt          <- User manual, English
|     |-- FAQ_PT.txt                 <- Text behind the ENTENDA button
|     |-- FAQ_EN.txt                 <- Text behind the LEARN button
|     |-- IDIOMA_EN.txt              <- PT -> EN translation table and rules
|     |-- Changelog.txt              <- Changelog, Portuguese
|     |-- CHANGELOG_EN.txt           <- Changelog, English
|     |
|     |-- tools\                     <- TOOLS FOLDER (ASSEMBLED VIA STEP 3)
|           |-- ffmpeg.exe
|           |-- ffprobe.exe
|           |-- dovi_tool.exe        <- MINIMUM VERSION 2.3.3
|           |-- mkvmerge.exe
|           |-- mkvextract.exe
|           |-- MediaInfo.exe
|           |-- nvcuda.dll / nvcuvid.dll / LIBCURL.DLL
|           |
|           |-- SubtitleEdit\        <- Preferred OCR engine
|           |     |-- seconv.exe
|           |     |-- Latin.db
|           |     |-- libSkiaSharp.dll / libHarfBuzzSharp.dll
|           |
|           |-- PgsToSrt\            <- Secondary OCR (.NET 8 x64)
|           |     |-- PgsToSrt.exe
|           |     |-- x64\
|           |     |-- tessdata\
|           |           |-- por.traineddata
|           |
|           |-- Tesseract\           <- Re-OCR for short lines
|           |     |-- tesseract.exe
|           |     |-- tessdata\
|           |           |-- por.traineddata
|           |           |-- osd.traineddata
|           |
|           |-- DeeZy\               <- TrueHD/Atmos -> E-AC-3 converter
|                 |-- deezy.exe
|                 |-- apps\          <- dee\ and truehdd\
|
|-- icone\
|     |-- LaFirmaRemuxForge.ico      <- Program icon
|
|-- lancador\
|     |-- Abrir_LaFirma_JANELA.vbs   <- Direct launcher, no console
|
|-- redist\                          <- (Optional) .NET runtime
|     |-- windowsdesktop-runtime-8.0.30-win-x64.exe
|     |-- LEIA-ME.txt
|     |-- README.txt
|
|-- _testes\                         <- Regression battery (NOT shipped in the
|     |-- Testar_LaFirma.ps1            installer; it is a dev tool)
|     |-- Testar_LaFirma.bat
|
|-- Saida\                           <- The compiled installer lands here


TWO DETAILS THAT HAVE ALREADY COST TIME:

  1) The 00_Arquivos_Base\ and 01_Arquivos_Finalizados\ folders do NOT belong
     here. The INSTALLER creates them on the user's machine. If they exist
     inside fonte\, the .iss excludes them - but one forgotten .mkv in there
     would become an 80 GB installer, which is why that exclusion exists.

  2) The fonte\tools\ folder is about 1.16 GB and it is OTHER PEOPLE'S
     software. It NEVER goes to GitHub - the .gitignore at the root handles
     that. Without it, the whole repository is around 5 MB.


--------------------------------------------------------------------------------

5. STEP-BY-STEP COMPILATION PROCEDURE (.ISS)
--------------------------------------------------------------------------------
1. Ensure all tools listed in Section 3 have been downloaded and properly 
   positioned inside the 'tools\' folder.

2. Open Inno Setup Compiler on your Windows system.

3. Select "File" -> "Open..." and load the 'LaFirma_Setup.iss' file.

4. Click "Build" -> "Compile" (or press Ctrl + F9).

5. Inno Setup will read the scripts from the root directory, package all binary 
   executables from 'tools\', include dependencies from 'redist\' (if present), 
   and generate the final installer inside the 'Output\' folder 
   (e.g., Output\LaFirma_Setup.exe).

6. Done! The generated 'LaFirma_Setup.exe' is fully standalone and ready for 
   distribution. When executed on an end-user machine, it will automatically deploy 
   the complete environment without requiring them to download any tools manually.
================================================================================
