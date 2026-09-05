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
Before clicking "Compile" in Inno Setup, your project root folder MUST contain 
the exact structure and files listed below:

<PROJECT_ROOT_DIRECTORY>\
|-- LaFirma_Setup.iss                <- Inno Setup compilation script
|-- Abrir_LaFirma_JANELA.vbs         <- Silent windowless launcher
|-- Abrir_LaFirma_JANELA.bat         <- Console launcher (diagnostic mode)
|-- LaFirma_JANELA.ps1               <- WPF Graphical Interface
|-- Converter_AUTO_DIRETO.ps1       <- Main engine script
|-- Converter_AUTO_DIRETO.bat       <- Direct console execution wrapper
|-- Corretor_Legenda.ps1            <- Subtitle post-processing script
|-- Reocr_Legenda.ps1               <- Re-OCR script powered by Tesseract
|-- LaFirma_PTBR_1.3M.dic.gz        <- Main PT-BR dictionary
|-- Auditor_OCR.dic.gz              <- Engine supporting dictionary
|-- HOW_TO_USE_EN.txt               <- English User Guide
|-- COMO_USAR_PT.txt                <- Portuguese User Guide
|-- Changelog.txt                   <- Version history
|
|-- icone\
|     |-- icone.ico                 <- Application icon
|
|-- redist\                         <- (Optional) Store .NET Runtime installer here
|     |-- windowsdesktop-runtime-8.0.30-win-x64.exe
|     |-- LEIA-ME.txt
|
|-- tools\                          <- TOOLS DIRECTORY (ASSEMBLED VIA SECTION 3)
|     |-- ffmpeg.exe
|     |-- ffprobe.exe
|     |-- dovi_tool.exe
|     |-- mkvmerge.exe
|     |-- mkvextract.exe
|     |-- MediaInfo.exe
|     |-- nvcuda.dll / nvcuvid.dll / LIBCURL.DLL
|     |
|     |-- SubtitleEdit\             <- Primary OCR Engine
|     |     |-- seconv.exe
|     |     |-- Latin.db
|     |     |-- libSkiaSharp.dll
|     |
|     |-- PgsToSrt\                 <- Secondary OCR Engine (.NET 8 x64)
|     |     |-- PgsToSrt.exe
|     |     |-- x64\
|     |     |-- tessdata\
|     |           |-- por.traineddata
|     |
|     |-- Tesseract\                <- Short-line Re-OCR Engine
|     |     |-- tesseract.exe
|     |     |-- tessdata\
|     |           |-- por.traineddata
|     |           |-- osd.traineddata
|     |
|     |-- DeeZy\                    <- TrueHD/Atmos to E-AC-3 Audio Converter
|           |-- deezy.exe
|           |-- apps\               <- Internal tools
|
|-- 00_Arquivos_Base\               <- Input directory for source media
|-- 01_Arquivos_Finalizados\        <- Output directory for processed media


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
