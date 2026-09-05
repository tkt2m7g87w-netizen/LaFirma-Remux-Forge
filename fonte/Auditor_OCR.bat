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

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Auditor_OCR.ps1" %*

if errorlevel 1 (
    echo.
    echo  O PowerShell saiu com erro. A janela fica aberta para voce ler.
    pause
)
endlocal
