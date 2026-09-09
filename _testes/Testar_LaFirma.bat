@echo off
REM ============================================================================
REM  LaFirma - Testar_LaFirma.bat
REM  Abre a bateria de regressao (86 testes) numa janela que NAO fecha sozinha.
REM
REM  POR QUE ESTE .bat EXISTE:
REM    "Executar com PowerShell" no menu do Windows faz duas coisas ruins aqui:
REM    respeita a ExecutionPolicy da maquina (que costuma recusar script solto)
REM    e FECHA a janela no fim - a mensagem de erro pisca e some. Alem disso,
REM    arquivo extraido de um .zip BAIXADO vem marcado como "da internet" e o
REM    PowerShell recusa antes de ler a primeira linha. E dai que vem a
REM    "mensagem vermelha que fecha rapidao".
REM    Este .bat resolve os tres: desbloqueia, ignora a policy so nesta
REM    execucao (-ExecutionPolicy Bypass vale so para este processo, nao muda
REM    nada na maquina) e segura a janela com o pause.
REM ============================================================================
chcp 65001 >nul
cd /d "%~dp0"
echo.
echo  Desbloqueando os arquivos (marca de "baixado da internet")...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -LiteralPath '%~dp0' -Recurse -File | Unblock-File -ErrorAction SilentlyContinue"
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Testar_LaFirma.ps1" %*
echo.
if errorlevel 1 (
  echo  ############################################################
  echo   REPROVOU. Nao use estes arquivos - me mande esta tela.
  echo  ############################################################
) else (
  echo  Tudo passou.
)
echo.
pause
