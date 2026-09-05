@echo off
chcp 65001 >nul
title LaFirma - Motor no Console (v14.36) - DV 8.1 + Legenda PGS + Audio E-AC-3
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Converter_AUTO_DIRETO.ps1"
echo.
echo (fim - se a janela nao fechou sozinha, pode fechar manualmente)
pause
