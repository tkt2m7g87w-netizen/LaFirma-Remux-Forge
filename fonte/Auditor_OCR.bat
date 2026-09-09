@echo off
setlocal
chcp 65001 >nul
title LaFirma - Auditor de OCR de Legenda 1.1.10
cd /d "%~dp0"

if not exist "%~dp0Auditor_OCR.ps1" (
    echo.
    echo  ERRO: Auditor_OCR.ps1 nao esta nesta pasta.
    echo  Coloque os dois arquivos juntos e rode de novo.
    echo.
    pause
    exit /b 1
)

rem 09/09: desbloqueia o .ps1 antes de rodar. Arquivo que veio de download ou
rem de .zip chega com a "Mark of the Web" e o PowerShell recusa executar - e o
rem erro que aparece nao diz isso, diz so que o script nao pode ser carregado.
rem Os outros .bat do projeto ja faziam isso; estes dois ficaram para tras.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -LiteralPath '%~dp0.' -Filter *.ps1 -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Auditor_OCR.ps1" %*

if errorlevel 1 (
    echo.
    echo  O PowerShell saiu com erro. A janela fica aberta para voce ler.
    pause
)
endlocal
