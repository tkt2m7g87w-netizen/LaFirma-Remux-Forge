@echo off
chcp 65001 >nul
title LaFirma - Motor no Console - DV 8.1 + Legenda PGS + Audio E-AC-3
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -LiteralPath '%~dp0.' -Filter *.ps1 -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue; & '%~dp0Converter_AUTO_DIRETO.ps1'"
echo.
echo (fim - se a janela nao fechou sozinha, pode fechar manualmente)
pause
