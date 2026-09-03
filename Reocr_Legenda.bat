@echo off
setlocal
chcp 65001 >nul
title LaFirma - Reocr_Legenda 1.29
cd /d "%~dp0"

if not exist "%~dp0Reocr_Legenda.ps1" (
    echo.
    echo  ERRO: Reocr_Legenda.ps1 nao esta nesta pasta.
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Reocr_Legenda.ps1" %*

if errorlevel 1 (
    echo.
    echo  O PowerShell saiu com erro. A janela fica aberta para voce ler.
    pause
)
endlocal
