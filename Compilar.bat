@echo off
chcp 65001 >nul
title Compilar o instalador - LaFirma Remux Forge
setlocal

set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if not exist "%ISCC%" set "ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"

if not exist "%ISCC%" (
  echo.
  echo   NAO ACHEI O INNO SETUP.
  echo   Baixe em https://jrsoftware.org/isdl.php e instale ^(padrao, next-next^).
  echo   Depois rode este arquivo de novo.
  echo.
  pause
  exit /b 1
)

REM 1.4: checava "fonte\LaFirma_MOTOR.ps1" - esse arquivo NUNCA existiu com
REM esse nome. O motor sempre foi Converter_AUTO_DIRETO.ps1 e a janela sempre
REM foi LaFirma_JANELA.ps1 (confirme no #define Motor/Janela do proprio .iss).
REM Como a checagem antiga procurava um nome que nao existe, ela travava
REM SEMPRE, mesmo com a fonte\ completa e correta - por isso foi trocada pelo
REM nome real do motor.
if not exist "%~dp0fonte\Converter_AUTO_DIRETO.ps1" (
  echo.
  echo   A PASTA fonte\ ESTA VAZIA OU INCOMPLETA.
  echo   Copie TODO o conteudo da pasta do programa para dentro de fonte\
  echo   ^(LaFirma_JANELA.ps1, Converter_AUTO_DIRETO.ps1, Corretor_Legenda.ps1,
  echo   Reocr_Legenda.ps1, Auditor_OCR.ps1, os dois .dic.gz, os .bat e a
  echo   pasta tools\^).
  echo.
  pause
  exit /b 1
)

echo.
echo   Compilando... isso pode levar varios minutos ^(a pasta tools e grande^).
echo.
"%ISCC%" "%~dp0LaFirma_Setup.iss"
if errorlevel 1 (
  echo.
  echo   FALHOU. A mensagem de erro esta acima.
) else (
  echo.
  echo   PRONTO. O instalador esta em:  %~dp0Saida\
)
echo.
pause
