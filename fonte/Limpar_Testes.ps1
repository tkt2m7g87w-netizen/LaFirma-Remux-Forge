# ============================================================================
#  LaFirma - LIMPAR TESTES 1.9
#  1.9: o cabecalho dizia 1.8 desde que as mudancas da 1.9 entraram no corpo
#  (log em arquivo, familias de log de _testes\, protecao da pasta _testes\).
#  Numero de versao que nao acompanha o arquivo e a mesma mentira dos titulos
#  de .bat que ficaram parados em GUI 16.33 - corrigido em 02/09.
#  1.8: agora limpa a pasta _corretor\ tambem - era o lixo que mais crescia
#  sem ninguem olhar. Cada conversao que cai no PgsToSrt deixa la:
#     tmp_<carimbo>\        pasta com o .srt inteiro da 2a opiniao do seconv
#     relatorio_corretor_*.txt
#     *_CORRIGIDO.srt
#  As pastas tmp_* sao lixo puro e vao SEMPRE (o conteudo delas ja foi usado
#  e descartado na hora). O relatorio e o _CORRIGIDO seguem a mesma regra dos
#  logs, criada na 1.2: os 3 mais recentes de cada um ficam, pra voce sempre
#  ter o material da ultima sessao pra mandar pro Claude.
#  O _CORRIGIDO.srt e a UNICA excecao a protecao de .srt, e so dentro de
#  _corretor\: ele e subproduto: o resultado dele ja foi pro .mkv final e
#  ja tem copia solta em 01_Arquivos_Finalizados. Video e legenda em qualquer
#  outro lugar continuam intocaveis, e mesmo esse vai pra LIXEIRA, nao pro
#  vazio.
#  1.7: Corretor_Legenda.ps1 entrou na lista de PROTEGIDOS. Ele deixou de
#  ser ferramenta avulsa: desde o motor 14.1 o proprio
#  Converter_AUTO_DIRETO.ps1 chama ele sozinho dentro da etapa [5/7]. Se um
#  dia ele sumir da raiz, a rede de seguranca de legenda some junto e sem
#  aviso - o motor so deixa de chamar. Mesma logica que ja tinha protegido
#  a LaFirma_JANELA na 1.1 e o Auditor_OCR/Reocr_Legenda na 1.5.
#  (Ele ja estava seguro na pratica, por nao casar com nenhum padrao de
#  exclusao. Agora esta seguro POR REGRA, que e diferente.)
#  A pasta _corretor\ NAO entrou na lista de limpaveis de proposito: e onde
#  ficam os relatorios do Corretor, que sao o material que voce manda pra
#  analise. Se um dia quiser limpa-la, e so somar "_corretor" em
#  $PadroesPasta, do lado de _reocr e _auditoria_ocr.
#  1.6: LaFirma_MOTOR.ps1 (a janela) virou LaFirma_JANELA.ps1 - nome antigo
#  confundia com o motor de verdade (Converter_AUTO_DIRETO.ps1). Lista de
#  protecao atualizada pros nomes novos (.ps1, .bat E .vbs - o lancador vbs
#  nunca tinha entrado na lista antes, corrigido de brinde).
#  1.5: conhece as pastas de saida do Auditor_OCR (_auditoria_ocr\) e do
#  Reocr_Legenda (_reocr\) - agora limpaveis igual _retratos. Os PROGRAMAS
#  em si (Auditor_OCR.*, Reocr_Legenda.*) ficaram protegidos, mesma logica
#  que ja protegia LaFirma_JANELA.ps1 desde a 1.1 - viraram ferramentas
#  permanentes, nao prototipo de teste.
#  1.4: modo TUDO. Por padrao ele POUPA os 3 logs mais recentes de cada tipo
#  (pra voce sempre ter a ultima sessao pra mandar). Se voce quer a pasta
#  limpa de verdade, rode:  Limpar_Testes.bat TUDO
#  Remove os arquivos que EU gerei durante o desenvolvimento
#  1.3: a GUI 16.24 / motor 13.5 tiraram os logs da raiz e da pasta de saida
#  e passaram a gravar tudo em _logs\. Este limpador agora varre a raiz E a
#  _logs\ pelos mesmos padroes - sem isso ele nao encontraria mais nada.
# ============================================================================
#
#  COMO ELE E SEGURO:
#    1. Lista fechada. So mexe em nomes que eu mesmo criei (sonda, GUI,
#       logs da GUI, retratos, zips de entrega). Qualquer coisa fora da
#       lista e invisivel para ele.
#    2. Vai para a LIXEIRA, nao para o vazio. Se eu errei um padrao, voce
#       recupera com dois cliques.
#    3. Mostra tudo e pergunta antes. Nada some sem voce digitar SIM.
#
#  O QUE ELE NUNCA TOCA (protecao explicita, checada arquivo por arquivo):
#    - qualquer .mkv, .mp4, .m2ts, .hevc, .ec3, .thd, .dts, .srt, .sup
#    - Converter_AUTO_DIRETO.ps1  (o motor)
#    - Corretor_Legenda.ps1       (1.7 - o motor chama ele sozinho no [5/7])
#    - a pasta tools\ inteira  (inclui SubtitleEdit\seconv.exe + Latin.db)
#    - 00_Arquivos_Base\ e 01_Arquivos_Finalizados\
#    - log_conversao_*.txt  (log real do motor - isso e material bom)
#    - qualquer arquivo com BACKUP no nome  (1.1 - e a sua volta atras)
#    - por.traineddata*     (1.1 - o modelo de OCR, e o backup dele)
#    - LaFirma_JANELA.ps1 e Abrir_LaFirma_JANELA.bat  (1.1 - a JANELA saiu da
#      lista de apagaveis: ela deixou de ser prototipo e virou o programa
#      que voce usa. Se quiser ela de volta na lista, me fala.)
# ============================================================================

param([string]$Modo = "NORMAL")

$ErrorActionPreference = "Stop"
$Raiz = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $PSCommandPath }
# 1.3: onde os logs moram agora. Se a pasta nao existir ainda (programa nunca
# rodado), o Get-ChildItem so retorna vazio - nao precisa checar Test-Path.
$PastaLogs = Join-Path $Raiz "_logs"

<#  LOG EM ARQUIVO (1.9) - as outras ferramentas ja gravavam; esta faltava.
    Aqui o log importa MAIS que nas outras: e o unico registro do que foi
    mandado para a Lixeira. Se sumir um arquivo que fazia falta, e neste log
    que se descobre quando ele saiu e por qual padrao.
    COMO: funcao com o MESMO NOME do cmdlet. No PowerShell a funcao do script
    tem prioridade, entao as chamadas de Write-Host do corpo passam por aqui
    sem que nenhuma linha delas mude. A chamada de verdade vai pelo nome
    completo, senao ela chamaria a si mesma. #>
$script:LinhasLog = New-Object 'System.Collections.Generic.List[string]'
function Write-Host {
    param(
        [Parameter(Position=0, ValueFromPipeline=$true)] $Object = "",
        [System.ConsoleColor] $ForegroundColor,
        [switch] $NoNewline
    )
    [void]$script:LinhasLog.Add([string]$Object)
    $p = @{ Object = $Object }
    if ($PSBoundParameters.ContainsKey('ForegroundColor')) { $p['ForegroundColor'] = $ForegroundColor }
    if ($NoNewline) { $p['NoNewline'] = $true }
    Microsoft.PowerShell.Utility\Write-Host @p
}
function Gravar-LogLimpeza {
    param([int]$Apagados = 0, [int]$Falhas = 0, [double]$Mb = 0.0)
    try {
        if (-not (Test-Path -LiteralPath $PastaLogs)) { New-Item -ItemType Directory -Path $PastaLogs -Force | Out-Null }
        $arq = Join-Path $PastaLogs ("LaFirma_limpeza_" + (Get-Date -Format "yyyy-MM-dd_HHmmss") + ".txt")
        $cab = @(
            "LaFirma - Limpar_Testes",
            ("Data  : " + (Get-Date -Format "dd/MM/yyyy HH:mm:ss")),
            ("Pasta : " + $Raiz),
            ("Modo  : " + $Modo),
            ("RESULTADO: " + $Apagados + " para a Lixeira, " + $Falhas + " falha(s), " + ("{0:N2}" -f $Mb) + " MB liberados"),
            "NOTA: nada foi apagado de verdade - tudo foi para a Lixeira do Windows.",
            "")
        [System.IO.File]::WriteAllLines($arq, ($cab + $script:LinhasLog), (New-Object System.Text.UTF8Encoding($true)))
        Microsoft.PowerShell.Utility\Write-Host ("  Log desta limpeza: " + $arq) -ForegroundColor DarkGray
    } catch {
        Microsoft.PowerShell.Utility\Write-Host ("  [!] Nao consegui gravar o log: " + $_.Exception.Message) -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "  LaFirma - Limpar arquivos de teste" -ForegroundColor Cyan
Write-Host "  Pasta: $Raiz" -ForegroundColor DarkGray
Write-Host ""

# ---- Lista fechada do que EU gerei -----------------------------------------
$PadroesArquivo = @(
    "Sonda_Motor.ps1", "Rodar_Sonda.bat", "Sonda_Motor_relatorio_*.txt",
    "Sonda_Manual.ps1", "Rodar_Sonda_Manual.bat", "sonda_manual_relatorio_*.txt",
    "sonda_entrega_relatorio_*.txt",
    "LaFirma_GUI_Previa.ps1", "Abrir_LaFirma_GUI.bat",
    "LaFirma_motor_log_*.txt", "LaFirma_previa_log_*.txt",
    # 1.9: as ferramentas de _testes\ passaram a gravar log em _logs\ em
    # 27/08, e este limpador nao conhecia essas familias - elas iam se
    # empilhar em _logs para sempre, que e exatamente o entupimento que ele
    # existe para evitar. Entram aqui E na lista dos "3 mais recentes".
    "LaFirma_teste_*.txt", "LaFirma_auditoria_srt_*.txt", "LaFirma_limpeza_*.txt",
    "LEIA-ME.txt",
    "LaFirma_*.zip", "LaFirma_*.rar", "retratos.zip", "retratos.rar",
    "*.mkvmerge.json", "*.mediainfo.json",
    "faixas.json", "mediainfo.json", "mediainfo_avatar.json", "TLOU_convertido.json",
    "Retrato_Audio.ps1", "Retrato_Audio.bat", "retrato_audio_*.txt",
    "Auditor_Legendas.ps1", "Auditor_Legendas.bat", "Auditor_Legendas_relatorio_*.txt",
    "Sonda_Ponte.ps1", "Sonda_Ponte.bat", "sonda_ponte_*.txt",
    "Sonda_Conversao.ps1", "Sonda_Conversao.bat", "sonda_conversao_*.txt",
    "LEIA-ME_Sonda_Conversao.txt", "validar.py", "auditar.py",
    "LEIA-ME_Auditor.txt", "LEIA-ME_Retrato_Audio.txt", "LEIA-ME_Sonda_Ponte.txt",
    "LEIA-PRIMEIRO.txt"
)
$PadroesPasta = @("_retratos", "_auditoria_ocr", "_reocr")
# 1.8: a pasta _corretor\ NAO entra aqui - ela e criada pelo instalador com
# permissao de escrita, e apagar a pasta inteira levaria junto o relatorio da
# rodada de agora. O que se limpa la dentro esta logo abaixo.
$PastaCorretor        = Join-Path $Raiz "_corretor"
$PadroesNoCorretor    = @("relatorio_corretor_*.txt", "*_CORRIGIDO.srt")
$PadroesPastaCorretor = @("tmp_*")

# ---- Protecoes que valem mesmo se algum padrao acima casar por acidente ----
$ExtensoesProibidas = @(".mkv",".mp4",".m2ts",".ts",".hevc",".h265",".ec3",".eac3",
                        ".thd",".mlp",".dts",".ac3",".srt",".sup",".exe",".dll")
$NomesProibidos     = @("Converter_AUTO_DIRETO.ps1", "Limpar_Testes.ps1",
                        "LaFirma_JANELA.ps1", "Abrir_LaFirma_JANELA.bat",
                        "Abrir_LaFirma_JANELA.vbs",
                        # 1.2: a Sonda_Entrega esta EM USO na rodada de agora.
                        # Quando ela sair de cena eu tiro daqui.
                        "Sonda_Entrega.ps1", "Rodar_Sonda_Entrega.bat",
                        # 1.5: igual a LaFirma_JANELA na 1.1 - Auditor_OCR e
                        # Reocr_Legenda deixaram de ser prototipo de teste e
                        # viraram ferramentas permanentes. As pastas de SAIDA
                        # delas (_auditoria_ocr\, _reocr\) continuam limpaveis
                        # normalmente - so os PROGRAMAS em si ficam protegidos.
                        "Auditor_OCR.ps1", "Auditor_OCR.bat", "Auditor_OCR.dic.gz",
                        "Reocr_Legenda.ps1", "Reocr_Legenda.bat",
                        # 1.7: o motor CHAMA este aqui sozinho no [5/7] desde
                        # a v14.1. Sem ele, a rede de seguranca de legenda
                        # some sem avisar - o motor so deixa de chamar.
                        "Corretor_Legenda.ps1")
# 1.9: _testes\ entra na lista. La dentro moram a bateria de regressao, o
# auditor de .srt e as AMOSTRAS congeladas - material que nao se regenera
# sozinho e que e a unica coisa que impede uma correcao de quebrar trinta
# outras. Hoje nenhum padrao casa com o que tem la, entao a protecao e
# teorica; e assim que ela tem que ficar, porque padrao novo se acrescenta
# sem ninguem lembrar dessa pasta.
$PastasProibidas    = @("tools", "00_Arquivos_Base", "01_Arquivos_Finalizados", "_testes")

function Eh-Protegido {
    param([System.IO.FileSystemInfo]$Item)
    if ($NomesProibidos -contains $Item.Name) { return $true }
    if ($Item -is [System.IO.FileInfo] -and $ExtensoesProibidas -contains $Item.Extension.ToLower()) { return $true }
    if ($Item.Name -like "log_conversao_*") { return $true }
    # 1.1: backup e a rede de seguranca - se eu errar um padrao, e dele que
    # voce se recupera. Nunca entra na lista, nem por acidente.
    if ($Item.Name -like "*BACKUP*") { return $true }
    if ($Item.Name -like "por.traineddata*") { return $true }
    $p = $Item.FullName
    foreach ($pasta in $PastasProibidas) {
        if ($p -like "*\$pasta\*") { return $true }
    }
    return $false
}

# ---- Levantar candidatos (raiz + _logs\, sem descer em mais nada) ---------
# 1.3: LaFirma_motor_log_* agora nasce em _logs\ (GUI 16.24+). Varrer as duas
# pastas com o MESMO padrao cobre quem ja converteu com a 16.24/13.5 (log em
# _logs) e quem ainda tem log velho solto na raiz de uma sessao anterior.
# LaFirma_previa_log_* e do prototipo antigo (LaFirma_GUI_Previa.ps1, ja
# obsoleto) - continua so na raiz, nunca existiu em _logs.
$alvos = New-Object System.Collections.Generic.List[object]
$PastasParaVarrer = @($Raiz, $PastaLogs)
foreach ($padrao in $PadroesArquivo) {
    foreach ($pasta in $PastasParaVarrer) {
        if (-not (Test-Path -LiteralPath $pasta)) { continue }
        foreach ($f in @(Get-ChildItem -LiteralPath $pasta -Filter $padrao -File -ErrorAction SilentlyContinue)) {
            if (-not (Eh-Protegido $f)) { $alvos.Add($f) }
        }
    }
}
foreach ($padrao in $PadroesPasta) {
    foreach ($d in @(Get-ChildItem -LiteralPath $Raiz -Filter $padrao -Directory -ErrorAction SilentlyContinue)) {
        if (-not (Eh-Protegido $d)) { $alvos.Add($d) }
    }
}

# ---- 1.8: dentro de _corretor\ -------------------------------------------
# As pastas tmp_* entram direto (lixo puro, sem historico que valha guardar).
# Os arquivos entram e depois passam pela regra dos "3 mais recentes", igual
# aos logs. A checagem Eh-Protegido NAO e usada nos arquivos daqui de
# proposito: ela barraria o _CORRIGIDO.srt pela extensao, e e justamente ele
# que precisa sair. Nada fora de _corretor\ e alcancado por este bloco.
if (Test-Path -LiteralPath $PastaCorretor) {
    foreach ($padrao in $PadroesPastaCorretor) {
        foreach ($d in @(Get-ChildItem -LiteralPath $PastaCorretor -Filter $padrao -Directory -ErrorAction SilentlyContinue)) {
            $alvos.Add($d)
        }
    }
    foreach ($padrao in $PadroesNoCorretor) {
        foreach ($f in @(Get-ChildItem -LiteralPath $PastaCorretor -Filter $padrao -File -ErrorAction SilentlyContinue)) {
            $alvos.Add($f)
        }
    }
}
$alvos = @($alvos | Sort-Object FullName -Unique)

# ---- 1.2: log e relatorio nao se apaga inteiro ----------------------------
# Apagar TODOS os logs de uma vez ja me deixou sem o arquivo justamente da
# rodada que eu precisava olhar. Destas familias, os {0} mais RECENTES de
# cada uma ficam - o resto vai. Assim a pasta nao entope e o material da
# ultima sessao continua ali pra mandar pro Claude.
$FamiliasComHistorico = @("LaFirma_motor_log_*.txt", "LaFirma_previa_log_*.txt",
                          "sonda_manual_relatorio_*.txt", "sonda_entrega_relatorio_*.txt",
                          "Sonda_Motor_relatorio_*.txt", "retrato_audio_*.txt",
                          "Auditor_Legendas_relatorio_*.txt",
                          "relatorio_corretor_*.txt", "*_CORRIGIDO.srt",
                          # 1.9: ver o comentario na lista de padroes.
                          "LaFirma_teste_*.txt", "LaFirma_auditoria_srt_*.txt",
                          "LaFirma_limpeza_*.txt")
# 1.4: no modo TUDO nao poupa nada. Era isso que dava a impressao de que o
# limpador "deixava coisas para tras" - ele estava poupando de proposito.
$QuantosGuardar = if ($Modo -eq "TUDO") { 0 } else { 3 }
$poupados = New-Object System.Collections.Generic.List[string]
foreach ($fam in $FamiliasComHistorico) {
    $daFamilia = @($alvos | Where-Object { $_ -is [System.IO.FileInfo] -and $_.Name -like $fam } |
                  Sort-Object LastWriteTime -Descending)
    if ($daFamilia.Count -le $QuantosGuardar) { continue }
    foreach ($manter in @($daFamilia | Select-Object -First $QuantosGuardar)) {
        $poupados.Add($manter.FullName) | Out-Null
    }
}
if ($poupados.Count -gt 0) {
    $alvos = @($alvos | Where-Object { $poupados -notcontains $_.FullName })
    Write-Host ("  Guardando os {0} mais recentes de cada tipo de log/relatorio ({1} arquivo(s) poupado(s))." -f $QuantosGuardar, $poupados.Count) -ForegroundColor DarkCyan
    Write-Host "  Quer levar TODOS? Rode:  Limpar_Testes.bat TUDO" -ForegroundColor DarkGray
    Write-Host ""
}
if ($Modo -eq "TUDO") {
    Write-Host "  MODO TUDO: nenhum log vai ser poupado." -ForegroundColor Yellow
    Write-Host ""
}

if ($alvos.Count -eq 0) {
    Write-Host "  Nada para limpar - a pasta ja esta arrumada." -ForegroundColor Green
    Write-Host ""
    Gravar-LogLimpeza -Apagados 0 -Falhas 0 -Mb 0.0
    Write-Host ""
    Write-Host "  Pressione ENTER para fechar..." -ForegroundColor DarkGray
    [void][System.Console]::ReadLine()
    return
}

# ---- Mostrar antes de mexer ------------------------------------------------
$totalBytes = 0
Write-Host "  Encontrei isto para mandar para a Lixeira:" -ForegroundColor Yellow
Write-Host ""
foreach ($a in $alvos) {
    if ($a -is [System.IO.DirectoryInfo]) {
        $tam = (Get-ChildItem -LiteralPath $a.FullName -Recurse -File -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
        if (-not $tam) { $tam = 0 }
        $qtd = @(Get-ChildItem -LiteralPath $a.FullName -Recurse -File -ErrorAction SilentlyContinue).Count
        Write-Host ("    [pasta]   {0,-46} {1,10:N0} KB  ({2} arquivos)" -f $a.Name, ($tam/1KB), $qtd)
    } else {
        $tam = $a.Length
        Write-Host ("    [arquivo] {0,-46} {1,10:N0} KB" -f $a.Name, ($tam/1KB))
    }
    $totalBytes += $tam
}
Write-Host ""
Write-Host ("  Total: {0} item(ns), {1:N2} MB" -f $alvos.Count, ($totalBytes/1MB)) -ForegroundColor Yellow
Write-Host ""
Write-Host "  Vai para a LIXEIRA do Windows - da para recuperar depois." -ForegroundColor DarkGray
Write-Host "  Nenhum video, nenhuma ferramenta e o motor NAO estao nesta lista." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Digite SIM para confirmar (qualquer outra coisa cancela): " -ForegroundColor Cyan -NoNewline
$resposta = [System.Console]::ReadLine()

if ($resposta -ne "SIM") {
    Write-Host ""
    Write-Host "  Cancelado. Nada foi tocado." -ForegroundColor Green
    Write-Host ""
    <#  1.9: o cancelamento tambem grava. A lista do que ELE IA levar e
        justamente a informacao mais util para conferir antes de deixar
        rodar de verdade - e some da tela quando a janela fecha. #>
    Gravar-LogLimpeza -Apagados 0 -Falhas 0 -Mb 0.0
    Write-Host "  Pressione ENTER para fechar..." -ForegroundColor DarkGray
    [void][System.Console]::ReadLine()
    return
}

# ---- Mandar para a Lixeira -------------------------------------------------
# Microsoft.VisualBasic.FileIO tem o unico caminho nativo do .NET que usa a
# Lixeira de verdade. Remove-Item apagaria direto, sem volta.
Add-Type -AssemblyName Microsoft.VisualBasic

$ok = 0; $falhou = 0
foreach ($a in $alvos) {
    try {
        if ($a -is [System.IO.DirectoryInfo]) {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(
                $a.FullName,
                [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
                [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin)
        } else {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
                $a.FullName,
                [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
                [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin)
        }
        Write-Host ("    [OK]    {0}" -f $a.Name) -ForegroundColor Green
        $ok++
    } catch {
        Write-Host ("    [FALHA] {0} - {1}" -f $a.Name, $_.Exception.Message) -ForegroundColor Red
        $falhou++
    }
}

Write-Host ""
Write-Host ("  Pronto: {0} para a Lixeira, {1} falha(s), {2:N2} MB liberados." -f $ok, $falhou, ($totalBytes/1MB)) -ForegroundColor Cyan
Write-Host ""
Gravar-LogLimpeza -Apagados $ok -Falhas $falhou -Mb ($totalBytes/1MB)
Write-Host ""
Write-Host "  Pressione ENTER para fechar..." -ForegroundColor DarkGray
[void][System.Console]::ReadLine()
