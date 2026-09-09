@echo off
chcp 65001 >nul
title LaFirma Remux Forge - Black Edition
powershell -NoProfile -Sta -ExecutionPolicy Bypass -Command "Get-ChildItem -LiteralPath '%~dp0.' -Filter *.ps1 -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue; & '%~dp0LaFirma_JANELA.ps1'"
