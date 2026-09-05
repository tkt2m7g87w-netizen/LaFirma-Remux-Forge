@echo off
chcp 65001 >nul
title LaFirma - Limpar arquivos de teste 1.9
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Limpar_Testes.ps1" %1
