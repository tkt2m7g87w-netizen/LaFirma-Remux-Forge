@echo off
setlocal
chcp 65001 >nul
title LaFirma - Limpar arquivos de teste 1.9
cd /d "%~dp0"

if not exist "%~dp0Limpar_Testes.ps1" (
    echo.
    echo  ERRO: Limpar_Testes.ps1 nao esta nesta pasta.
    echo  Coloque os dois arquivos juntos e rode de novo.
    echo.
    pause
    exit /b 1
)

rem 09/09: desbloqueia o .ps1 antes de rodar (Mark of the Web), igual aos
rem outros .bat do projeto.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -LiteralPath '%~dp0.' -Filter *.ps1 -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Limpar_Testes.ps1" %1

rem 09/09: a janela fica aberta no fim. Este script APAGA arquivos - fechar
rem sozinho e nao deixar ler o que foi apagado e o pior fim possivel para ele.
echo.
pause
endlocal
