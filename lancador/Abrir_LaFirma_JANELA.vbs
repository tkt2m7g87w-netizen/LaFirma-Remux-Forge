' ============================================================================
'  LaFirma Remux Forge - Black Edition
'  Abre a janela sem NENHUM console atras, nem "flash" de terminal.
'
'  POR QUE ISSO EXISTE:
'  "-WindowStyle Hidden" no powershell.exe conta com o CONHOST classico do
'  Windows pra esconder a janela de texto. A partir do Windows 11 24H2/25H2,
'  o Terminal Host Windows Terminal virou o padrao pra hospedar processos de
'  console - e ele tem janela e ciclo de vida proprios, que nem sempre
'  obedecem o -WindowStyle Hidden do jeito esperado. Resultado: um icone a
'  mais na barra de tarefas, "Windows PowerShell", do lado do programa.
'
'  O metodo WScript.Shell.Run com o parametro 0 (janela escondida) chama o
'  Windows diretamente no nivel de processo (CreateProcess com SW_HIDE),
'  sem passar pelo Terminal Host - por isso funciona em qualquer versao do
'  Windows, independente de qual terminal esta configurado como padrao.
' ============================================================================

Dim objFSO, objShell, pastaAtual, comando

Set objFSO = CreateObject("Scripting.FileSystemObject")
pastaAtual = objFSO.GetParentFolderName(WScript.ScriptFullName)

Set objShell = CreateObject("WScript.Shell")

comando = "powershell.exe -NoProfile -Sta -ExecutionPolicy Bypass -File """ & _
          pastaAtual & "\LaFirma_JANELA.ps1"""

'  -Sta: o WPF SO funciona em thread STA. Sem esse parametro a janela
'  detecta que nao esta em STA e se RELANCA sozinha com Start-Process -
'  e esse relancamento abre um console VISIVEL, desfazendo justamente o
'  que este lancador existe para evitar. Com -Sta aqui, a guarda nunca
'  precisa disparar.

' 0 = janela escondida | False = nao espera o programa terminar pra continuar
objShell.Run comando, 0, False
