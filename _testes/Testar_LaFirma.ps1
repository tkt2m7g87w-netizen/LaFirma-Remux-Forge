<#
================================================================================
 LaFirma - Testar_LaFirma.ps1
 Versao 1.3
 --------------------------------------------------------------------------
 POR QUE ISTO EXISTE (Diego, 27/08/2026)

   "vou ter q rodar os 03 filmes de novo pra ver se voce nao fez merda de
    novo? [...] nao faz sentido voce arrumar 1 coisinha e estragar 30"

 Ele esta certo, e ate aqui a unica rede era ele converter tres filmes de
 madrugada. Foi assim que o bloco quebrado do Se7en passou: eu corrigi a
 legenda e quebrei o formato dela, e so se descobriria assistindo.

 Esta bateria roda em SEGUNDOS, sem .mkv, sem converter nada. Ela nao
 substitui o teste real - substitui a PARTE do teste real que e mecanica e
 que eu tenho obrigacao de rodar antes de entregar qualquer coisa.

 REGRA: nenhum .ps1 sai daqui sem esta bateria passar inteira.

 COMO USAR
   .\Testar_LaFirma.ps1                       -> testa os .ps1 ao lado (ou C:\LaFirma)
   .\Testar_LaFirma.ps1 -Fonte "C:\LaFirma"   -> testa uma pasta especifica

 SAIDA: codigo 0 = tudo passou. Diferente de 0 = numero de testes reprovados.

 ENCODING DESTE ARQUIVO: UTF-8 COM BOM + CRLF
================================================================================
#>
[CmdletBinding()]
param([string]$Fonte = "")

$ErrorActionPreference = "Continue"
<#  2.4 - A BATERIA PASSAVA E GRITAVA AO MESMO TEMPO.

    No log de 08/09 ela terminou "TUDO PASSOU - 245 testes" e, no meio da
    tela, tinha um erro vermelho do PowerShell que ninguem contou: um
    comentario meu fechava cedo e a frase seguinte virava comando. Erro
    nao-terminante nao para o script, nao entra na contagem e NAO VAI PARA O
    LOG - entao o arquivo salvo dizia que estava tudo bem.

    Uma bateria que sai com erro na tela e diz "tudo passou" e pior que uma
    bateria que reprova: ela ensina a ignorar vermelho. Agora ela zera o
    historico de erros no comeco e, no fim, reprova se apareceu qualquer um. #>
$Error.Clear()
$Versao = "3.16"
<#  OS CONTADORES TEM NOME ESQUISITO DE PROPOSITO.
    Eles ja se chamaram $script:Passou e $script:Falhou. Na secao 5 havia um
    $falhou local - e $falhou E $Falhou, porque nome de variavel no PowerShell
    e INSENSIVEL A CAIXA. O contador virava um booleano no meio da bateria e
    ela terminava anunciando "TUDO PASSOU" com quatro testes reprovados na
    propria tela, saindo com codigo 0.
    Achado em 27/08 sabotando os fontes de proposito para ver se ela pegava:
    a primeira coisa que ela pegou foi um defeito nela mesma. E a mesma
    armadilha ja registrada no HANDOFF (o caso do $n contra o $N, 20/08).
    Nao renomear para nada parecido com "passou", "falhou" ou "erros". #>
$script:ContaBateriaOk  = 0
$script:ContaBateriaNao = 0
<#  1.4: TERCEIRO ESTADO - PULADO.
    Auditor_OCR.ps1 e Limpar_Testes.ps1 sao ferramentas de DESENVOLVIMENTO:
    nao vao no instalador e nem sempre estao na pasta que se esta testando.
    Ate a 1.3 a ausencia delas virava [FALHA] (e, no caso do Auditor, uma
    excecao de Get-Content no meio da bateria). As duas leituras estavam
    erradas: reprovar por arquivo que nao devia estar la e alarme falso, e
    alarme falso na rede de seguranca e pior que nao ter rede (licao 6).
    Passar calado seria pior ainda - seria verde mentindo (licao 10).
    Entao: PULADO aparece na tela, e contado a parte, e NAO entra no codigo
    de saida - que continua sendo o numero de reprovacoes. #>
$script:ContaBateriaPulou = 0

<#  LOG EM ARQUIVO (v1.1) - pedido do Diego em 27/08: "NAO GERA LOG ESSE TESTE?"
    Tudo que aparece na tela tambem vai para C:\LaFirma\_logs, do lado do log
    do motor. Serve para duas coisas: mandar no chat sem tirar print, e ter
    o historico de quando a bateria comecou a reprovar.
    COMO: em vez de trocar as ~40 chamadas de Write-Host uma a uma (e esquecer
    alguma), declaro aqui uma funcao com o MESMO NOME. No PowerShell a funcao
    do script tem prioridade sobre o cmdlet, entao toda chamada passa por aqui
    sem que nenhuma linha do corpo mude. A chamada real vai pelo nome completo
    (Microsoft.PowerShell.Utility\Write-Host), senao ela chamaria a si mesma. #>
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

function Titulo([string]$T) { Write-Host ""; Write-Host ("--- " + $T) -ForegroundColor Cyan }
function Pular([string]$Nome, [string]$Motivo) {
    $script:ContaBateriaPulou++
    Write-Host ("  [pulado] " + $Nome) -ForegroundColor DarkYellow
    if ($Motivo -ne "") { Write-Host ("            " + $Motivo) -ForegroundColor DarkGray }
}
function Checar([string]$Nome, [bool]$Ok, [string]$Detalhe = "") {
    if ($Ok) { $script:ContaBateriaOk++; Write-Host ("  [ok]    " + $Nome) -ForegroundColor Green }
    else     { $script:ContaBateriaNao++; Write-Host ("  [FALHA] " + $Nome) -ForegroundColor Red
               if ($Detalhe -ne "") { Write-Host ("            " + $Detalhe) -ForegroundColor Red } }
}

$raiz = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($raiz)) { $raiz = (Get-Location).Path }
if ($Fonte -eq "") {
    foreach ($cand in @((Join-Path (Split-Path -Parent $raiz) "fonte"), (Split-Path -Parent $raiz), "C:\LaFirma")) {
        if ((Test-Path -LiteralPath $cand) -and (Test-Path -LiteralPath (Join-Path $cand "LaFirma_JANELA.ps1"))) { $Fonte = $cand; break }
    }
}
Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host ("LaFirma - bateria de regressao v" + $Versao) -ForegroundColor Cyan
Write-Host ("fonte: " + $Fonte) -ForegroundColor DarkGray
Write-Host "==============================================================================" -ForegroundColor Cyan

# ============================================================ 1. SINTAXE
Titulo "1. SINTAXE E ESTRUTURA (o parser oficial do PowerShell)"
# A janela carrega o motor pela AST e espera este numero de funcoes. Se ele
# mudar sem querer (ja aconteceu: 101 -> 100 por causa de $n vs $N), a janela
# quebra em runtime, nao aqui. Por isso o numero e um teste.
# 1.4: motor 79 -> 80 (entrou Get-TipoCamadaDV, 2.0 / item 1) e janela
# 114 -> 121 (a contagem era da 16.64; o build validado e a 16.76).
# 1.5: motor 80 -> 81 (entrou Get-BrilhoDoContainer, 14.38).
# 1.6: janela 121 -> 123 (Fechar-MedicaoPendente e Test-SaidaCompleta, 16.79).
# 1.7: janela 123 -> 124 (Rotular-Audio, 16.80).
# 1.8: janela 124 -> 126 (Format-DolbyVision e Update-TextosDV, 16.84).
# 2.0: motor 81 -> 83 (ConvertFrom-PQ e Get-NomeDoFormato, 14.41).
# 3.2: motor 83 -> 85 (Convert-Perfil5ParaMp4 e Test-CodecCabeEmMp4 - o P5
#      deixou de ser so uma frase na tela e virou caminho executado, 14.45).
# 3.4: motor 85 -> 86 (Get-PontosDaAmostra - a janela pedia 3 pontos e o
#      motor usava 5, para a mesma pergunta sobre o mesmo arquivo, 14.47).
# 2.2: janela 126 -> 127 (Pintar-RotuloDV, 16.87).
# 2.9: janela 127 -> 131 (Carregar-Idioma, Traduzir, Traduzir-Arvore,
#      Set-Idioma - 16.92).
# 3.1: janela 131 -> 135 (Get-NomeCorEL, Get-CorEL, Get-ChipEL - a escala de
#      cor num lugar so - e Traduzir-Frase, para o texto montado - 16.94).
# 3.13: janela 145 -> 146 (Offer-ReinicioIdioma - 17.04)
# 3.12: janela 143 -> 145 (Get-VerboExibido e Get-VerboCanonico - 17.03)
# 3.10: janela 141 -> 143 (Get-PastaDados, Get-CaminhoIdioma - 17.02)
# 3.6: janela 136 -> 141 (Get-CaminhoCalibragem, Get-Percentil,
#      Registrar-Calibragem, Carregar-Calibragem e Fechar-MedidaDoVideo - a
#      estimativa de tempo passou a se calibrar sozinha, 16.99).
# 3.2: janela 135 -> 136 (Get-FatorDisco - o fator 1,6x/3,15x num lugar so,
#      porque o P5 tem seta na coluna e mesmo assim nao usa 3,15x - 16.95).
$esperado = @{ "Converter_AUTO_DIRETO.ps1" = 86; "LaFirma_JANELA.ps1" = 146
               "Corretor_Legenda.ps1" = 25; "Reocr_Legenda.ps1" = 20
               "Auditor_OCR.ps1" = 22; "Limpar_Testes.ps1" = 3 }
# Estas duas nao sao entregues ao usuario - ver o comentario do PULADO.
$soDesenvolvimento = @("Auditor_OCR.ps1", "Limpar_Testes.ps1")
foreach ($arq in $esperado.Keys) {
    $p = Join-Path $Fonte $arq
    if (-not (Test-Path -LiteralPath $p)) {
        if ($soDesenvolvimento -contains $arq) { Pular ("$arq - sintaxe e contagem de funcoes") "ferramenta de desenvolvimento, nao esta em $Fonte" }
        else { Checar ("$arq existe") $false "nao encontrado em $Fonte" }
        continue
    }
    $tok = $null; $err = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($p, [ref]$tok, [ref]$err)
    Checar ("$arq - sintaxe") ($err.Count -eq 0) $(if ($err.Count) { "$($err[0].Extent.StartLineNumber): $($err[0].Message)" } else { "" })
    $nf = @($ast.FindAll({ param($x) $x -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)).Count
    Checar ("$arq - $($esperado[$arq]) funcoes") ($nf -eq $esperado[$arq]) "achei $nf"
}

# ============================================================ 2. PS 5.1
Titulo "2. SINTAXE DE POWERSHELL 7 (o parser 7 aceita e o 5.1 do Diego quebra)"
<#  2.1 - A BATERIA ACUSAVA A SI MESMA (achado no log do Diego, 08/09).

    Este proprio teste PRECISA escrever os dois operadores para procura-los -
    um na mensagem, outro no padrao. Na minha pasta ele mora em _testes e a
    varredura nao o via; em C:\LaFirma esta tudo junto, entao ele se
    encontrava e REPROVAVA. Oito reprovacoes num build sadio, e a linha final
    dizendo "nao entregue assim" - a bateria mentindo, que e a coisa que ela
    existe para impedir.

    Correcao em duas partes: ela se exclui da varredura (nao vai no
    instalador, nao roda na maquina de ninguem alem da dele) e o padrao e
    montado por codigo, para o literal nao ficar no arquivo varrido. #>
$achou = @()
$sinal = [char]63   # '?'
$padrao = "\{0}\{0}|\{0}\." -f $sinal
foreach ($f in @(Get-ChildItem -LiteralPath $Fonte -Filter *.ps1 -ErrorAction SilentlyContinue)) {
    if ($f.Name -eq "Testar_LaFirma.ps1") { continue }
    $t = Get-Content -LiteralPath $f.FullName -Raw
    foreach ($m in [regex]::Matches($t, $padrao)) { $achou += ("{0}: {1}" -f $f.Name, $m.Value) }
}
Checar "nenhum ?? nem ?. nos fontes" ($achou.Count -eq 0) (($achou | Select-Object -First 3) -join "; ")

# ============================================================ 3. ENCODING
Titulo "3. ENCODING POR ARQUIVO (errar aqui vira mojibake mudo)"
$regras = @{
    "Converter_AUTO_DIRETO.ps1" = @{ Bom = $false; Crlf = $true;  Ascii = $true  }
    "Corretor_Legenda.ps1"      = @{ Bom = $true;  Crlf = $true;  Ascii = $false }
    "Reocr_Legenda.ps1"         = @{ Bom = $true;  Crlf = $true;  Ascii = $false }
    "Auditor_OCR.ps1"           = @{ Bom = $true;  Crlf = $true;  Ascii = $false }
    "LaFirma_JANELA.ps1"        = @{ Bom = $true;  Crlf = $false; Ascii = $false }
}
foreach ($arq in $regras.Keys) {
    $p = Join-Path $Fonte $arq
    if (-not (Test-Path -LiteralPath $p)) { continue }
    $bytes = [System.IO.File]::ReadAllBytes($p)
    $temBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    Checar ("$arq - BOM $($regras[$arq].Bom)") ($temBom -eq $regras[$arq].Bom)
    $txt = [System.IO.File]::ReadAllText($p)
    $lf = ([regex]::Matches($txt, "(?<!`r)`n")).Count
    if ($regras[$arq].Crlf) { Checar ("$arq - CRLF puro") ($lf -eq 0) "$lf linha(s) com LF solto" }
    if ($regras[$arq].Ascii) {
        $naoAscii = @([regex]::Matches($txt, '[^\x00-\x7F]'))
        Checar ("$arq - ASCII puro (o motor nao tem BOM)") ($naoAscii.Count -eq 0) "$($naoAscii.Count) caractere(s) acentuado(s)"
    }
}

# ============================================================ 4. VERSOES
Titulo "4. VERSOES - uma fonte por numero (ja divergiram 5 versoes)"
function VerDe([string]$arq, [string]$rxCab, [string]$rxVar) {
    $p = Join-Path $Fonte $arq
    if (-not (Test-Path -LiteralPath $p)) { return $null }
    $t = Get-Content -LiteralPath $p -Raw
    return [PSCustomObject]@{ Cab = [regex]::Match($t, $rxCab).Groups[1].Value
                              Var = [regex]::Match($t, $rxVar).Groups[1].Value }
}
$asp = [string][char]34
$pares = @(
  @("LaFirma_JANELA.ps1",       '(?m)^#  LaFirma - JANELA ([\d.]+)', ('(?m)^\$SCRIPT_VERSION\s*=\s*'+$asp+'([^'+$asp+']+)')),
  @("Converter_AUTO_DIRETO.ps1",'(?m)^#  VERSAO: ([\d.]+)',          ('(?m)^\$SCRIPT_VERSION\s*=\s*'+$asp+'([^'+$asp+']+)')),
  @("Corretor_Legenda.ps1",     '(?m)^ Versao ([\d.]+)',             ('(?m)^\$Versao\s*=\s*'+$asp+'([^'+$asp+']+)')),
  @("Reocr_Legenda.ps1",        '(?m)^ Versao ([\d.]+)',             ('(?m)^\$Versao\s*=\s*'+$asp+'([^'+$asp+']+)'))
)
foreach ($pr in $pares) {
    $v = VerDe $pr[0] $pr[1] $pr[2]
    if ($null -eq $v) { continue }
    Checar ("$($pr[0]) - cabecalho $($v.Cab) = variavel $($v.Var)") ($v.Cab -eq $v.Var -and $v.Cab -ne "")
}

# ============================================================ 5. CONTRATO SRT
Titulo "5. CONTRATO DO .SRT (o defeito que perdeu fala no Se7en)"
$aud = Join-Path $raiz "Auditar_SRT.ps1"
$fix = Join-Path $raiz "fixtures"
if ((Test-Path -LiteralPath $aud) -and (Test-Path -LiteralPath $fix)) {
    # Cada fixture tem um veredicto ESPERADO. Assim o proprio auditor fica sob
    # teste: se ele parar de achar o defeito conhecido, isto reprova.
    $casos = @(
        @{ Arq = "Se7en_REOCR_com_defeito.srt"; DeveFalhar = $true  ; Nota = "bloco 1084 sem linha de tempo (a fala perdida)" }
        @{ Arq = "Troy_REOCR_limpo.srt";        DeveFalhar = $false ; Nota = "saida limpa de verdade" }
        @{ Arq = "SpiderMan_CORRIGIDO.srt";     DeveFalhar = $false ; Nota = "tem bloco vazio, mas o formato esta integro" }
        @{ Arq = "Se7en_CORRIGIDO.srt";         DeveFalhar = $false ; Nota = "idem" }
    )
    foreach ($c in $casos) {
        $p = Join-Path $fix $c.Arq
        if (-not (Test-Path -LiteralPath $p)) { Checar ("fixture $($c.Arq)") $false "nao encontrada"; continue }
        & $aud -Caminho $p -Silencioso | Out-Null
        # Ver o comentario dos contadores la em cima: NAO chamar de $falhou.
        $reprovou = ($LASTEXITCODE -ne 0)
        Checar ("$($c.Arq) -> $(if($c.DeveFalhar){'deve reprovar'}else{'deve passar'})  ($($c.Nota))") ($reprovou -eq $c.DeveFalhar)
    }
} else {
    Pular "Contrato do .SRT (Auditar_SRT.ps1 + fixtures)" `
          "ferramenta de desenvolvimento, nao esta nesta pasta"
}

# ============================================================ 5b. FUNCOES POR NOME
Titulo "5b. FUNCOES CRITICAS PELO NOME (contar nao pega RENOMEAR nem APAGAR)"
<#  Contar funcoes pega funcao a mais ou a menos. NAO pega uma renomeada - e
    renomear (ou apagar) uma que outro arquivo chama so aparece em runtime, no
    meio de uma conversao de uma hora. Testado em 27/08: renomeei Format-GB de
    proposito e a bateria passou batido.
    A JANELA carrega o MOTOR pela AST e ja declara, no proprio codigo, as 14
    funcoes que exige dele - essa lista e lida daqui, nao copiada, senao ela
    envelhece sozinha. #>
function Tem-Funcao($ast, [string]$nome) {
    return (@($ast.FindAll({ param($x) $x -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $x.Name -eq $nome }, $true)).Count -gt 0)
}
$pJan = Join-Path $Fonte "LaFirma_JANELA.ps1"
$pMot = Join-Path $Fonte "Converter_AUTO_DIRETO.ps1"
if ((Test-Path -LiteralPath $pJan) -and (Test-Path -LiteralPath $pMot)) {
    $astJan = [System.Management.Automation.Language.Parser]::ParseFile($pJan, [ref]$null, [ref]$null)
    $astMot = [System.Management.Automation.Language.Parser]::ParseFile($pMot, [ref]$null, [ref]$null)
    $txtJan = Get-Content -LiteralPath $pJan -Raw
    <#  Nada de regex guloso: um '(?s)...(.*?)\)' aqui capturou o ARQUIVO
        INTEIRO no primeiro teste - 1189 "nomes", entre eles "Transparent" e
        "SemiBold". Corta-se um pedaco curto a partir do marcador e le-se so o
        que tem cara de Verbo-Substantivo. #>
    $iMarca = $txtJan.IndexOf('$exigidas = @(')
    $exig = @()
    if ($iMarca -ge 0) {
        $pedaco = $txtJan.Substring($iMarca, [math]::Min(700, $txtJan.Length - $iMarca))
        $iFecha = $pedaco.IndexOf(')')
        if ($iFecha -gt 0) { $pedaco = $pedaco.Substring(0, $iFecha) }
        $exig = @([regex]::Matches($pedaco, '"([A-Z][a-z]+-[A-Za-z]+)"') | ForEach-Object { $_.Groups[1].Value })
    }
    Checar ("a lista de funcoes exigidas foi lida da janela ($($exig.Count) nomes)") ($exig.Count -ge 10 -and $exig.Count -le 40)
    $semNoMotor = @($exig | Where-Object { -not (Tem-Funcao $astMot $_) })
    Checar "as funcoes que a janela exige existem no motor" ($semNoMotor.Count -eq 0) ("faltam: " + ($semNoMotor -join ", "))
    # Internas da janela que, se sumirem, quebram a tela e nao o carregamento.
    $internas = @("Set-Regua","Update-Progresso","Show-Resumo","Get-SelosResultado","Format-GB",
                  "Get-TamanhoEstimadoVideo","Get-PlanoDoVideo","Set-Estado")
    $semNaJanela = @($internas | Where-Object { -not (Tem-Funcao $astJan $_) })
    Checar "as funcoes internas criticas da janela existem" ($semNaJanela.Count -eq 0) ("faltam: " + ($semNaJanela -join ", "))
}

# ============================================================ 5c. LANCADORES
Titulo "5c. TODO .ps1 QUE O DIEGO ABRE TEM QUE TER .bat"
<#  Em 27/08 eu entreguei Testar_LaFirma.ps1 e Auditar_SRT.ps1 sem .bat
    nenhum. Todo o resto do projeto tem (Abrir_LaFirma_JANELA, Auditor_OCR,
    Converter_AUTO_DIRETO, Limpar_Testes, Reocr_Legenda) e ele so usa por ali.
    Ele tentou "Executar com PowerShell" e levou uma mensagem vermelha que
    fechou antes de dar para ler - ExecutionPolicy + arquivo marcado como
    "baixado da internet" + janela que fecha sozinha.
    Agora falta de lancador REPROVA, em vez de virar uma pergunta dele. #>
<#  2.1 - QUEM O DIEGO ABRE, E QUEM O MOTOR CHAMA (achado no log, 08/09).

    A regra estava certa e a lista, errada: o teste exigia .bat de TODO .ps1
    da pasta. Corretor_Legenda.ps1 e Reocr_Legenda.ps1 nunca sao abertos por
    ele - quem os chama e o motor - e nunca tiveram .bat em versao nenhuma.
    Eram duas reprovacoes eternas por um lancador que nao deve existir.

    E o lancador da janela se chama Abrir_LaFirma_JANELA.bat, nao
    LaFirma_JANELA.bat: o teste procurava pelo nome errado e reprovava um
    arquivo que esta la desde sempre. Conferido na pasta instalada. #>
$abrePeloBat = @{
    "LaFirma_JANELA.ps1"        = "Abrir_LaFirma_JANELA.bat"
    "Converter_AUTO_DIRETO.ps1" = "Converter_AUTO_DIRETO.bat"
    "Testar_LaFirma.ps1"        = "Testar_LaFirma.bat"
    "Auditor_OCR.ps1"           = "Auditor_OCR.bat"
    "Limpar_Testes.ps1"         = "Limpar_Testes.bat"
    "Reocr_Legenda.ps1"         = ""   # chamado pelo motor, sem lancador
    "Corretor_Legenda.ps1"      = ""   # idem
}
foreach ($ps1 in @(Get-ChildItem -LiteralPath $raiz -Filter *.ps1 -ErrorAction SilentlyContinue)) {
    $nomeBat = if ($abrePeloBat.ContainsKey($ps1.Name)) { $abrePeloBat[$ps1.Name] }
               else { $ps1.BaseName + ".bat" }
    if ($nomeBat -eq "") { continue }
    $bat = Join-Path $raiz $nomeBat
    Checar ("$($ps1.Name) tem lancador $nomeBat") (Test-Path -LiteralPath $bat)
    if (-not (Test-Path -LiteralPath $bat)) { continue }
    $ps1 = [PSCustomObject]@{ Name = $ps1.Name; BaseName = [System.IO.Path]::GetFileNameWithoutExtension($nomeBat) }
    $bytes = [System.IO.File]::ReadAllBytes($bat)
    $temBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    Checar ("$($ps1.BaseName).bat - sem BOM (regra do projeto para .bat)") (-not $temBom)
    $t = [System.IO.File]::ReadAllText($bat)
    Checar ("$($ps1.BaseName).bat - CRLF puro") (([regex]::Matches($t, "(?<!`r)`n")).Count -eq 0)
    # Os tres motivos pelos quais "Executar com PowerShell" falhou para ele.
    Checar ("$($ps1.BaseName).bat - usa -ExecutionPolicy Bypass") ($t -match '-ExecutionPolicy\s+Bypass')
    Checar ("$($ps1.BaseName).bat - desbloqueia (Unblock-File)")   ($t -match 'Unblock-File')
    <#  2.1: "pause" so faz sentido em .bat de CONSOLE. O lancador da janela
        abre uma GUI - segurar o console ali deixaria uma janela preta parada
        atras do programa, esperando uma tecla que ninguem vai apertar. #>
    if ($nomeBat -eq "Abrir_LaFirma_JANELA.bat") {
        Checar ("$($ps1.BaseName).bat - NAO segura a janela (e GUI, nao console)") ($t -notmatch '(?m)^\s*pause\s*$')
    } else {
        Checar ("$($ps1.BaseName).bat - segura a janela (pause)")      ($t -match '(?m)^\s*pause\s*$')
    }
}

# ============================================================ 6. DEFEITOS FECHADOS
Titulo "6. DEFEITOS JA CORRIGIDOS - nao podem voltar"
function Fonte-De([string]$a) {
    $p = Join-Path $Fonte $a
    if (Test-Path -LiteralPath $p) { return (Get-Content -LiteralPath $p -Raw) }
    return ""
}
$motor  = Fonte-De "Converter_AUTO_DIRETO.ps1"
$janela = Fonte-De "LaFirma_JANELA.ps1"
$reocr  = Fonte-De "Reocr_Legenda.ps1"
$corr   = Fonte-De "Corretor_Legenda.ps1"
$limpar = Fonte-De "Limpar_Testes.ps1"

Checar "Reocr: linha vazia sai da leitura nova (Se7en 27/08, perdia fala)" `
    ($reocr -match '\$linhasNovas\s*=\s*@\(\$novoTexto\s*-split' -and $reocr -match "Where-Object \{ \`$_\.Trim\(\) -ne " )
Checar "Reocr: #PROG# por leitura, nao por altura (o '87% travado')" `
    ($reocr -match 'instantes\.Count \* 4 \* 5')
Checar "Motor: EXCELENTE tem ramo proprio na sub-etapa (saia com a frase de RUIM)" `
    ($motor -match '\$reocrRes\.Veredicto -ceq "EXCELENTE"')
Checar "Motor: EXCELENTE tem ramo proprio no resumo do arquivo" `
    ($motor -match '\$script:NotaLegendaVeredicto -ceq "EXCELENTE"')
Checar "Motor: o motivo do erro vai para o log (Troy falhou mudo)" `
    ($motor -match 'Falha ao Processar Este Episodio:')
Checar "Motor: nao repete o seconv que ele mesmo recusou" `
    ($motor -match 'SeconvRecusadoNesteArquivo' -and $motor -match '-PularSegundaOpiniao')
Checar "Corretor: aceita a chave -PularSegundaOpiniao" `
    ($corr -match '\[switch\]\$PularSegundaOpiniao')
Checar "Janela: disco usa a MAIOR entre lote e por-episodio (dizia 'da' e o motor recusava)" `
    ($janela -match '\$preciso = \[math\]::Max\(\$precisoLote, \$picoEpisodio\)')
Checar "Janela: 'convertendo' so em rodando/pausado (linha ficava presa)" `
    ($janela -match '\$ehOAtual = \(\$Estado\.Atual -in @\("rodando","pausado"\)')
Checar "Janela: Set-Estado limpa VideoNome/Fase ao sair de rodando" `
    ($janela -match '\$Motor\.VideoNome = ""; \$Motor\.Fase = ""; \$Motor\.Nota = ""')
Checar "Janela: audio mantido a pedido nao e chamado de REAPROVEITADO" `
    ($janela -match 'Mantido a Pedido - CONVERS' )
Checar "Janela: os quatro veredictos tem cor (EXCELENTE/BOA/RAZOAVEL/RUIM)" `
    ($janela -match '"RAZOAVEL"\s*\{ \$Cores\.lar \}')
Checar "Janela: os dois pontos das fases existem" `
    ($janela -match 'pontoDiag' -and $janela -match 'pontoFim')
Checar "Corretor: 'Aii esta' (correcao pela metade do Se7en) tem conserto" `
    ($corr -match 'ehVogal' -and $corr -match 'c\.Length -eq 2 -and \$dobrada')
Checar "Corretor: ordinal nao deixa o lixo do OCR antes do 's' (o '2a?s')" `
    ($corr -match [regex]::Escape("(?:[\?\*](?=s))?"))
Checar "Corretor: regra A2 - ':' colado no meio de palavra (o 'O:i')" `
    ($corr -match 'REGRA A2' -and $corr -match "replace '\[:=\]', ''")
Checar "Corretor+Reocr: regra 6B (linha em caixa alta sem palavra de PT - o 'NF TOR')" `
    ($corr -match 'REGRA 6B' -and $reocr -match 'REGRA 6B' -and
     $corr -match 'soCaixa -and -not \$conhecida -and \$semVogal' -and
     $reocr -match 'soCaixa -and -not \$conhecida -and \$semVogal' -and
     $corr -match 'tokens\.Count -lt 2' -and $reocr -match 'tokens\.Count -lt 2')
Checar "Corretor+Reocr: a guarda de placa NAO pergunta palavra curta ao dicionario (o 'TOR')" `
    ($corr -match 'p\.Length -ge 4 -and \(Test-NoDicionario' -and
     $reocr -match 'p\.Length -ge 4 -and \(Test-NoDicionario' -and
     $corr -match 'elseif \(Test-CurtaComum \$p\)' -and
     $reocr -match 'elseif \(Test-CurtaComum \$p\)')
# --- 27/08 tarde: defeitos achados em AUDITORIA (nenhum apareceu em conversao)
$mot = Get-Content -Raw (Join-Path $Fonte "Converter_AUTO_DIRETO.ps1")
Checar "Motor: a trava 'ja existe na saida' usa -LiteralPath (nome com colchete)" `
    ($mot -match 'Test-Path -LiteralPath \$outFile' -and $mot -notmatch 'Test-Path \$outFile')
Checar "Motor: falha ao medir espaco em disco AVISA (o catch nao e mais vazio)" `
    ($mot -match 'Nao Foi Possivel Medir o Espaco Livre')
Checar "Corretor: 'fol' e 'urn' fora da lista de palavras curtas em portugues" `
    ($corr -match "'fiz', 'foi', 'for', 'fu'," -and $corr -match "'um', 'uma', 'un', 'uns',\r?\n" -and
     $corr -notmatch "'foi', 'fol'" -and $corr -notmatch "'uns', 'urn'")
Checar "Corretor: sigla curta em CAIXA ALTA nao vai ao dicionario de 1,3M" `
    ($corr -match '\$P -ceq \$P\.ToUpperInvariant\(\) -and \$P -cne \$P\.ToLowerInvariant\(\)\) \{ return \$true \}')
Checar "Corretor e Reocr: bloco vazio nao gera mais duas linhas em branco" `
    ($corr -match 'IsNullOrWhiteSpace\(\$txtBloco\)\) \{ \[void\]\$sb\.AppendLine\(\$txtBloco\)' -and
     $reocr -match 'IsNullOrWhiteSpace\(\$txtBloco\)\) \{ \[void\]\$sb\.AppendLine\(\$txtBloco\)')
$jan = Get-Content -Raw (Join-Path $Fonte "LaFirma_JANELA.ps1")
Checar "Janela: a LEGENDA e contada por bloco/duracao, nao por GB" `
    ($jan -match 'LegendaSegPorBloco' -and $jan -match 'LegendaSegPorMin' -and
     $jan -notmatch '\$pLeg = \$P\.Legenda\b')
Checar "Janela: a REMONTAGEM tem dois precos (com e sem video extraido)" `
    ($jan -match 'RemontagemSegPorGb' -and $jan -match 'RemontagemDiretoSegPorGb')
Checar "Janela: Get-PesoDeSegundos existe e nao divide por zero" `
    ($jan -match 'function Get-PesoDeSegundos' -and $jan -match 'if \(\$umPeso -le 0\) \{ return 0 \}')
Checar "Janela: Get-PesosDoVideo recebe o tamanho E a duracao do video" `
    ($jan -match 'function Get-PesosDoVideo\(\$v, \[double\]\$Gb = 0, \[double\]\$Min = 0\)' -and
     $jan -match 'Get-PesosDoVideo \$v \$gb \$min')
# --- 28/08: a rodada dos 12 logs de conversao + os pedidos de tela do Diego
# 1.4: era um Get-Content seco. Sem o arquivo, ele lancava excecao no meio
# da bateria e o teste seguinte recebia um array em vez de booleano.
$pAud = Join-Path $Fonte "Auditor_OCR.ps1"
$aud  = ""
if (Test-Path -LiteralPath $pAud) { $aud = Get-Content -Raw $pAud }
Checar "Janela: as caixas de pasta existem como TextBox (da para colar caminho)" `
    ($jan -match '<TextBox x:Name="txtOrigem"' -and $jan -match '<TextBox x:Name="txtSaida"')
<#  1.4: ESTE TESTE ESTAVA COBRANDO UMA DECISAO QUE FOI REVERTIDA.
    A 16.64 deixou as caixas editaveis com Enter/Esc. Vendo funcionando, o
    Diego pediu o contrario ("quando eu clicar la e pra abrir essa janela
    normal") e a 16.64b tornou as caixas somente-leitura, sem foco
    (Focusable="False"), com o clique abrindo o mesmo seletor do botao.
    O teste continuou exigindo o add_KeyDown que deixou de existir - ou
    seja, reprovava o comportamento CERTO. Teste que cobra o passado vira
    ruido e ensina a ignorar vermelho. O que ele passa a guardar e a
    decisao que vale hoje, e o motivo dela: sem foco nao ha
    LostKeyboardFocus, que era o caminho que podia derrubar o motor no meio
    da conversao. #>
Checar "Janela: as caixas de pasta nao pegam foco e o clique abre o seletor (16.64b)" `
    ($jan -match 'Focusable="False"' -and $jan -match 'function Abrir-SeletorOrigem' -and
     $jan -match 'function Abrir-SeletorSaida' -and $jan -notmatch '\$UI\.txtOrigem\.add_KeyDown')
Checar "Janela: caminho que nao existe nao e aplicado (borda vermelha)" `
    ($jan -match 'function Test-CaminhoDePasta' -and $jan -match 'Set-BordaPasta')
Checar "Janela: seletor de pasta MODERNO com queda para o antigo" `
    ($jan -match 'FOS_PICKFOLDERS' -and $jan -match 'IFileDialog' -and
     $jan -match 'FolderBrowserDialog')
Checar "Janela: o audio e estimado por MINUTO de filme, nao por GB" `
    ($jan -match 'AudioTrueHDSegPorMin' -and $jan -match 'AudioOutroSegPorMin' -and
     $jan -notmatch 'AudioTrueHD = 2520')
Checar "Janela: cada etapa tem sua propria conta (segundos, nao peso por GB)" `
    ($jan -match 'function Get-SegundosDasEtapas' -and $jan -match 'ExtracaoSegPorGb' -and
     $jan -match 'RemontagemSegPorGb' -and $jan -match 'RemontagemDiretoSegPorGb')
Checar "Janela: a velocidade do disco de origem e MEDIDA antes de estimar" `
    ($jan -match 'function Measure-VelocidadeOrigem' -and $jan -match 'function Get-FatorDisco' -and
     $jan -match 'SensibilidadeDisco')
Checar "Janela: o fator de disco fica preso entre 1x e 8x" `
    ($jan -match 'if \(\$f -lt 1\.0\) \{ return 1\.0 \}' -and $jan -match 'if \(\$f -gt 8\.0\) \{ return 8\.0 \}')
Checar "Janela: grava GB, duracao e tamanho da PGS no log (dado da proxima rodada)" `
    ($jan -match 'MEDIDA:' -and $jan -match 'PGS pt-BR')
Checar "Reocr: a trava de ACEITE nao pergunta palavra curta ao dicionario de 1,3M" `
    ($reocr -match 'if \(Test-CurtaComum \$p\) \{ \$boas\+\+; continue \}' -and
     $reocr -match '\$p\.Length -ge 4 -and \(Test-NoDicionario \$p \$Dicionario\)\) \{ \$boas\+\+ \}')
Checar "Reocr: o resumo explica que RECUSADO nao e o mesmo que DEFEITO" `
    ($reocr -match 'recusado NAO e o mesmo que defeito')
Checar "Corretor: a regra A2 usa a lista fechada, nao o dicionario de 1,3M" `
    ($corr -match 'if \(Test-PalavraPtBr \$limpa \$Dicionario\)' -and
     $corr -notmatch 'if \(Test-NoDicionario \$limpa \$Dicionario\)')
if ($aud -eq "") { Pular "Auditor: palavra com menos de 4 letras nao vai ao dicionario de 1,3M" "Auditor_OCR.ps1 nao esta nesta pasta" }
else {
Checar "Auditor: palavra com menos de 4 letras nao vai ao dicionario de 1,3M" `
    ([bool]($aud -match '\$p2\.Length -ge 4 -and \$script:Dicionario -and \$script:Dicionario\.Contains\(\$p2\)'))
}
<#  2.7 - ESTE TESTE ERA UM PLACEBO, e ficou assim por semanas.

    Ele procurava as versoes 16.64 / 2.26 / 1.28 - congeladas de agosto - e
    passava mesmo assim, porque a primeira condicao de cada lado era
    "ou o arquivo esta vazio". Sem o .iss na pasta, tudo virava $true. Um
    teste que passa por AUSENCIA nao guarda nada.

    Agora ele le a versao dos FONTES e cobra que o Changelog e o .iss digam a
    MESMA coisa. Se o arquivo nao estiver aqui, ele PULA - que e honesto - em
    vez de dar ok. #>
$verJanela = ""; $verMotor = ""; $verCorr = ""; $verReocr = ""
foreach ($parV in @(@("LaFirma_JANELA.ps1", [ref]$verJanela), @("Converter_AUTO_DIRETO.ps1", [ref]$verMotor),
                    @("Corretor_Legenda.ps1", [ref]$verCorr), @("Reocr_Legenda.ps1", [ref]$verReocr))) {
    $pV = Join-Path $Fonte $parV[0]
    if (Test-Path -LiteralPath $pV) {
        # A janela e o motor usam $SCRIPT_VERSION; o corretor e o reocr usam
        # $Versao. Ler so um dos dois deixava metade dos testes abaixo
        # comparando string vazia - ou seja, passando sem testar nada.
        $mV = [regex]::Match((Get-Content -Raw $pV), '\$(?:SCRIPT_VERSION|Versao)\s*=\s*"([0-9.]+)"')
        if ($mV.Success) { $parV[1].Value = $mV.Groups[1].Value }
    }
}
Checar "as quatro versoes dos fontes foram lidas (senao os testes abaixo sao placebo)" `
    (($verJanela -ne "") -and ($verMotor -ne "") -and ($verCorr -ne "") -and ($verReocr -ne "")) `
    ("janela=$verJanela motor=$verMotor corretor=$verCorr reocr=$verReocr")

$pChg = Join-Path $Fonte "Changelog.txt"
if (-not (Test-Path -LiteralPath $pChg)) {
    Pular "Changelog traz a versao atual de cada componente" "Changelog.txt nao esta nesta pasta"
} else {
    $chg = [System.IO.File]::ReadAllText($pChg, [System.Text.Encoding]::UTF8)
    <#  A entrada mais nova do changelog e a primeira linha "MOTOR x | JANELA
        y" ou "INSTALADOR z" do arquivo. Basta que as versoes de HOJE estejam
        escritas em algum lugar dele: entrada nova sem changelog e mudanca
        sem registro, que e o que este teste existe para pegar. #>
    Checar "Changelog: a JANELA de hoje ($verJanela) esta registrada" `
        (($verJanela -eq "") -or ($chg -match ("JANELA " + [regex]::Escape($verJanela))))
    Checar "Changelog: o MOTOR de hoje ($verMotor) esta registrado" `
        (($verMotor -eq "") -or ($chg -match ("MOTOR " + [regex]::Escape($verMotor))))
    Checar "Changelog: a entrada nova diz de qual dovi_tool ela depende" `
        ([bool]($chg -match 'dovi_tool 2\.3\.2 -> 2\.3\.3'))
    Checar "Changelog: a entrada nova assume o que a versao NAO faz" `
        ([bool]($chg -match 'AINDA NAO FAZ'))
}

$pIss = ""
foreach ($cand in @((Join-Path (Split-Path -Parent $Fonte) "instalador\LaFirma_Setup.iss"),
                    (Join-Path (Split-Path -Parent $Fonte) "raiz\LaFirma_Setup.iss"),
                    (Join-Path (Split-Path -Parent $Fonte) "LaFirma_Setup.iss"),
                    (Join-Path $Fonte "LaFirma_Setup.iss"))) {
    if (Test-Path -LiteralPath $cand) { $pIss = $cand; break }
}
if ($pIss -eq "") {
    Pular "Instalador: .iss bate com a versao dos fontes" "LaFirma_Setup.iss nao esta ao lado desta pasta"
} else {
    $iss = [System.IO.File]::ReadAllText($pIss, [System.Text.Encoding]::UTF8)
    Checar "Instalador: VersaoGui do .iss = versao da janela ($verJanela)" `
        (($verJanela -eq "") -or ($iss -match ('VersaoGui\s+"' + [regex]::Escape($verJanela) + '"')))
    Checar "Instalador: VersaoMotor do .iss = versao do motor ($verMotor)" `
        (($verMotor -eq "") -or ($iss -match ('VersaoMotor "' + [regex]::Escape($verMotor) + '"')))
    Checar "Instalador: VersaoCorretor do .iss = versao do corretor ($verCorr)" `
        (($verCorr -eq "") -or ($iss -match ('VersaoCorretor "' + [regex]::Escape($verCorr) + '"')))
    Checar "Instalador: VersaoReocr do .iss = versao do reocr ($verReocr)" `
        (($verReocr -eq "") -or ($iss -match ('VersaoReocr "' + [regex]::Escape($verReocr) + '"')))
    <#  O .iss leva "fonte\*" recursivo, entao todo arquivo novo em fonte\
        entra sozinho no instalador - inclusive o FAQ_PT.txt. Este teste
        guarda essa linha: se alguem trocar por uma lista de arquivos, o
        proximo arquivo novo fica de fora sem ninguem perceber. #>
    Checar "Instalador: leva a pasta fonte inteira (arquivo novo entra sozinho)" `
        ([bool]($iss -match 'Source: "fonte\\\*"[^\r\n]*recursesubdirs'))
    $pGuia = Join-Path (Split-Path -Parent $pIss) "LEIA-ME_INSTALADOR[PT-BR].txt"
    if (Test-Path -LiteralPath $pGuia) {
        $guia = [System.IO.File]::ReadAllText($pGuia, [System.Text.Encoding]::UTF8)
        Checar "Instalador: o guia diz a versao MINIMA do dovi_tool" `
            (($guia -match '2\.3\.3') -and ($guia -match 'M' + [char]0x00CD + 'NIMA|MINIMA'))
        Checar "Instalador: o guia explica o que acontece com a versao antiga" `
            ([bool]($guia -match 'nada quebra'))
    }
}
Checar "O instalador NAO leva a pasta _testes (decisao de 27/08)" `
    ($(  $iss = ""
         foreach ($cand in @((Join-Path (Split-Path -Parent $Fonte) "raiz\\LaFirma_Setup.iss"), (Join-Path (Split-Path -Parent $Fonte) "LaFirma_Setup.iss"), (Join-Path $Fonte "LaFirma_Setup.iss"))) {
             if (Test-Path -LiteralPath $cand) { $iss = Get-Content -Raw $cand; break }
         }
         if ($iss -eq "") { $true } else {
             ($iss -notmatch 'Source: "fonte\\_testes') -and ($iss -match '_testes\\\*')
         }))
Checar "Nenhum recado nosso vai junto no instalador (LEIA_ME.txt, README.md)" `
    ($(  $iss = ""
         foreach ($cand in @((Join-Path (Split-Path -Parent $Fonte) "raiz\\LaFirma_Setup.iss"), (Join-Path (Split-Path -Parent $Fonte) "LaFirma_Setup.iss"), (Join-Path $Fonte "LaFirma_Setup.iss"))) {
             if (Test-Path -LiteralPath $cand) { $iss = Get-Content -Raw $cand; break }
         }
         if ($iss -eq "") { $true } else {
             ($iss -match 'Excludes: "[^"]*LEIA_ME\.txt') -and ($iss -match 'Excludes: "[^"]*README\.md')
         }))
if ("$limpar" -eq "") {
    Pular "Limpador: log, familias de log e protecao da pasta _testes" "Limpar_Testes.ps1 nao esta nesta pasta"
} else {
Checar "Limpador grava LOG em _logs (inclusive quando voce cancela)" `
    ($limpar -match 'LaFirma_limpeza_' -and
     ([regex]::Matches($limpar, 'Gravar-LogLimpeza -Apagados')).Count -ge 3)
Checar "Limpador conhece os logs novos (senao eles se empilham pra sempre)" `
    ($limpar -match 'LaFirma_teste_\*\.txt' -and $limpar -match 'LaFirma_auditoria_srt_\*\.txt' -and
     $limpar -match 'LaFirma_limpeza_\*\.txt')
Checar "Limpador NUNCA pode encostar na pasta _testes" `
    ([bool]($limpar -match 'PastasProibidas\s*=\s*@\([^)]*"_testes"'))
}
<#  2.1 - FERRAMENTA DE DESENVOLVIMENTO AUSENTE E "PULADO", NAO "FALHA".

    O Auditar_SRT.ps1 nao vai no instalador e nao existe em C:\LaFirma - por
    decisao nossa. Mesmo assim tres testes sobre ele REPROVAVAM ali, do mesmo
    jeito que reprovariam se o arquivo estivesse quebrado. Ausencia proposital
    e falha de verdade sao coisas diferentes, e o resultado da bateria tem que
    saber a diferenca: o Limpador ja era tratado assim logo acima. #>
$pAud = Join-Path $raiz "Auditar_SRT.ps1"
if (-not (Test-Path -LiteralPath $pAud)) {
    Pular "Auditor: cegueira, separacao de grupos e log em _logs" `
          "Auditar_SRT.ps1 e ferramenta de desenvolvimento, nao esta nesta pasta"
} else {
$aud = Get-Content -Raw $pAud
Checar "Auditor nao grita 'auditor cegou' quando a amostra quebrada nem foi auditada" `
    ($aud -match 'quebradaNoLote')
Checar "Auditor separa SEU ARQUIVO FINAL de meio-do-caminho e amostra" `
    ($aud -match 'function Grupo-Do' -and
     $aud -match 'SEU ARQUIVO FINAL' -and
     $aud -match 'MEIO DO CAMINHO' -and
     $aud -match 'if \(\$reais\.Count -gt 0\) \{ exit \$falhasR\.Count \}')
Checar "Auditor grita se a amostra quebrada PARAR de reprovar (auditor cego)" `
    ($aud -match 'O auditor cegou')
Checar "As duas ferramentas de teste gravam LOG em _logs" `
    ((Get-Content -Raw (Join-Path $raiz "Testar_LaFirma.ps1")) -match 'LaFirma_teste_' -and
     $aud   -match 'LaFirma_auditoria_srt_')
}
Checar "Reocr: bloco vazio nao e contado 2x na nota (era 3 defeitos com 2 blocos)" `
    ($reocr -match 'recusadosVazios' -and
     $reocr -match 'recusados = \$recusados - \$recusadosVazios')
Checar "Corretor: tem a regra 6 (palavra LONGA de lixo na linha), igual ao Reocr" `
    ($corr -match 'REGRA 6 \(v2\.24\)' -and $corr -match 'temEstranha -and -not \$temConhecida')
Checar "Janela: o DIAGNOSTICO le a escolha manual (audio e legenda)" `
    ($janela -match 'function Get-DiagAudioComEscolha' -and
     $janela -match 'function Get-DiagLegendaComEscolha' -and
     $janela -match '\$escAu = Get-DiagAudioComEscolha \$v' -and
     $janela -match '\$escLg = Get-DiagLegendaComEscolha \$v')

# ============================================================ RESUMO

# ====================================================== 9. DOLBY VISION MEL x FEL
Titulo "9. DIAGNOSTICO DE DOLBY VISION - MEL x FEL (2.0 / item 1)"
<#  Estas asseroes existem para que a resposta a critica de 04/09 nao possa
    ser desfeita em silencio. Cada uma guarda uma decisao que custou
    discussao: quem classifica e o dovi_tool (nao nos), nao medir e um
    terceiro estado, P5 nao pode entrar no ramo "sem EL = limpa", e o L1 do
    DV nunca se compara com o MaxCLL do HDR10+ (reguas diferentes). #>
Checar "Motor: existe Get-TipoCamadaDV (a medicao de MEL x FEL)" `
    ($motor -match 'function Get-TipoCamadaDV')
Checar "Motor: quem classifica MEL x FEL e o dovi_tool, pelo el_type do RPU" `
    ($motor -match "7\\s\*\\\(\(MEL|FEL\)\\\)" -and $motor -match 'extract-rpu')
Checar "Motor: a amostra nao recodifica nada (o corte e -c copy)" `
    ($motor -match '\"-c\", \"copy\",[\s\S]{0,200}hevc_mp4toannexb')
<#  2.2: este teste EXIGIA que o motor citasse o DoVi_Scripts pelo nome. A
    janela ja tinha parado de citar ferramenta de terceiro na 16.79, a pedido
    do Diego; o motor continuou porque o teste TRAVAVA a frase antiga. Teste
    que congela um texto errado atrasa a correcao em vez de proteger. Agora
    ele exige o que importa: que o FEL nao saia como conversao limpa. #>
Checar "Motor: FEL nunca sai como conversao limpa" `
    ([bool]($mot -match '\$res\.Selo   = "RESSALVA"'))
<#  14.39: "FEL" sozinho nao e um veredicto - juntar o FEL comum (residual
    fino, so visivel em quadro parado) com o FEL de brightness expansion (o
    L1 apontando um pico que a base nao entrega) faz quem le entender
    "FEL = perda", que e falso na maioria esmagadora dos titulos. A frase
    tem que citar os DOIS casos, e tem que dizer que esta versao nao separa
    um do outro - senao ela vira uma acusacao que ninguem mediu. #>
Checar "Motor: a frase do FEL separa o caso comum do brightness expansion" `
    (($mot -match 'FEL com expansao de brilho') -and ($mot -match 'FEL sem expansao de brilho'))
<#  2.2: era o oposto - o teste garantia que a frase ADMITISSE nao separar os
    dois casos, o que virou falso na 14.43: agora ela separa, quando ha o pico
    do master para comparar. O que continua verdade, e o que o teste passa a
    cobrar, e que SEM regua ela nao afirma nada. #>
Checar "Motor: sem o pico do master, a frase do FEL nao afirma nem nega" `
    ([bool]($mot -match 'nao declara o pico do mastering display'))
Checar "Motor: MEL e o unico caminho que sai como conversao LIMPA" `
    ($motor -match 'if \(\$res\.Tipo -eq \"MEL\"\) \{[\s\S]{0,80}\$res\.Selo   = \"LIMPA\"')
Checar "Motor: MEL e FEL na mesma amostra caem para o lado seguro (RESSALVA)" `
    ($motor -match 'MISTO\"\) \{[\s\S]{0,80}\$res\.Selo   = \"RESSALVA\"')
Checar "Motor: nao medir NUNCA vira conversao limpa (e um terceiro estado)" `
    ($motor -match '\$res\.Selo = \"NAO MEDIDO\"' -and $motor -notmatch 'NAO_MEDIDO[\s\S]{0,120}Selo\s*=\s*\"LIMPA\"')
Checar 'Motor: Profile 5 nao entra no ramo (sem EL = conversao limpa)' `
    ($motor -match '\$dv\.Perfil -eq 5[\s\S]{0,400}re-encode')
Checar "Motor: o diagnostico imprime os tres selos por extenso" `
    ($motor -match '\[CONVERSAO LIMPA\]' -and $motor -match '\[CONVERSAO COM RESSALVA\]' -and
     $motor -match '\[NAO MEDIDO\]')
Checar "Motor: o L1 do DV nao pode ser comparado com HDR10+ (regua x regua)" `
    ($motor -match 'REGUA CONTRA REGUA' -and $motor -match 'HDR10\+')
Checar "Janela: exige Get-TipoCamadaDV do motor (senao a leitura segue cega)" `
    ($jan -match '\"Get-TipoCamadaDV\"')
Checar 'Janela: faz a ponte doviTool = dovi_tool (o nome que o motor usa por dentro)' `
    ($jan -match '\$doviTool\s*=\s*\$dovi_tool')
Checar "Janela: o cache de MEL x FEL e zerado a cada arquivo" `
    ($jan -match '\$script:CacheTipoELPath\s*=\s*\$null')
Checar "Janela: a coluna DV mostra o tipo de EL medido" `
    ($jan -match '\$\(\$el\.Tipo\) . 8\.1' -or $jan -match '\$\(\$el\.Tipo\)')
<#  3.1: a regra saiu do lugar - ela agora mora na Get-ChipEL, que le a
    escala unica (16.94). O que este teste garante continua sendo o mesmo:
    ressalva NAO pode sair verde, e a fila tem que usar a mesma funcao que a
    sigla do diagnostico usa. #>
Checar "Janela: chip verde nao aparece quando ha ressalva (verde e afirmacao)" `
    (($jan -match 'function Get-ChipEL') -and
     ($jan -match '(?s)function Get-ChipEL.{0,700}"laranja"') -and
     ($jan -match '(?s)function Get-ChipEL.{0,700}"vermelho"') -and
     ($jan -match 'else \{ Get-ChipEL \$v \}'))

Titulo "10. A MEDICAO SAIU DA LEITURA DA PASTA (16.77 / 14.38)"
<#  A 16.76 media MEL x FEL DENTRO da leitura da pasta, e isso custava de 2 a
    5 segundos POR ARQUIVO (medido: 4 arquivos em 17,57s; GOT de 20 GB em
    12,57s; Troy de 87 GB em ~9s - o tamanho quase nao pesa, o custo e fixo).
    Numa pasta de 20 filmes vira quase dois minutos de tela parada antes de
    poder clicar em Iniciar. A 16.77 move a medicao para uma FASE B, que roda
    depois da fila ja estar na tela. Estes testes existem para que ela nunca
    volte para dentro da leitura sem alguem perceber - e para que "ainda nao
    medi" nunca vire "esta limpo" no caminho. #>

Checar "Janela: a leitura da pasta NAO mede mais a camada (fase A instantanea)" `
    (-not ($jan -match '---- DOLBY VISION ----[\s\S]{0,3000}?\$el\s*=\s*Get-TipoCamadaDV'))

Checar "Janela: a fase B existe e enfileira o que precisa medir" `
    ([bool]($jan -match '\$pendentesEL\s*\+=') -and [bool]($jan -match 'T\s*=\s*"el";'))

Checar "Janela: so Profile 7 COM EL entra na fila de medicao" `
    ([bool]($jan -match '\$dv\.Perfil -eq 7 -and \$dv\.Camadas -match "EL"'))

Checar "Janela: o runspace NAO morre enquanto a fase B ainda mede" `
    ([bool]($jan -match '\$script:MedindoEL = \(\[int\]\$m\.MedirEL -gt 0\)[\s\S]{0,80}if \(-not \$script:MedindoEL\)'))

Checar "Janela: quem encerra o runspace depois de medir e o el_fim" `
    ([bool]($jan -match '"el_fim"\s*\{[\s\S]{0,700}?Stop-Motor'))

Checar "Janela: enquanto MEDE, a LINHA do diagnostico tambem nao e verde" `
    ([bool]($jan -match 'medindo a camada de melhoria \(MEL x FEL\)[\s\S]{0,900}?\$d\.DiagDVcor = "cinza"'))
Checar "Janela: enquanto MEDE, o chip do DV nao pode ser verde (nada a afirmar)" `
    ([bool]($jan -match '"MEDINDO"    \{ return "cinza" \}'))

Checar "Janela: arquivo por medir aparece como MEDINDO, nunca como limpo" `
    ([bool]($jan -match '\$d\.ELtipo = "MEDINDO"'))

Checar "Janela: a fase B manda o L1 medido junto (o log guarda o numero)" `
    ([bool]($jan -match 'L1 MaxCLL \{2:N2\} nits'))

Checar "Motor: existe Get-BrilhoDoContainer (o contexto que da sentido ao L1)" `
    ([bool]($mot -match 'function Get-BrilhoDoContainer'))

Checar "Motor: o contexto do brilho compara o L1 com o pico do MASTER" `
    ([bool]($mot -match 'Contexto do brilho') -and [bool]($mot -match 'ABAIXO do pico do master'))

Checar "Motor: o MaxCLL do container e marcado como regua diferente do L1" `
    ([bool]($mot -match 'histograma, nao se compara com o L1'))

Checar "Motor: Get-BrilhoDoContainer falha em silencio (nunca derruba a conversao)" `
    ([bool]($mot -match 'function Get-BrilhoDoContainer[\s\S]{0,4000}?\} catch \{ \}'))


Titulo "11. O QUE OS TESTES DE 04/09 A NOITE ACHARAM (16.79)"
<#  Cinco defeitos que so apareceram com o Diego usando o programa de verdade.
    Cada teste daqui existe porque UM deles passou despercebido por mim. #>

<#  1) A tela mostrava o NOME DA FAIXA no lugar do codec: no GOT a faixa se
    chama "Surround" e a janela dizia "AUDIO PRINCIPAL: Surround", enquanto o
    motor, no MESMO arquivo, dizia "Dolby TrueHD Atmos". #>
Checar "Janela: o audio e identificado pelo CODEC, nunca pelo nome da faixa" `
    (-not ($jan -match 'track_name\) \{ \$rot = '))
<#  16.80: a 16.79 consertou o ROTULO e deixou a RESPOSTA com o mesmo
    defeito - "[REAPROVEITADO] E-AC-3 Atmos" tambem era o track_name. Num
    arquivo ja convertido essa etiqueta foi o NOSSO motor que escreveu, e o
    programa estava lendo de volta a propria etiqueta em vez do codec.
    A regra de nomear faixa de audio agora mora em UMA funcao. Estes testes
    existem para que ninguem volte a consertar so metade. #>
Checar "Janela: existe UMA regra de nomear faixa de audio (Rotular-Audio)" `
    ([bool]($jan -match 'function Rotular-Audio'))
Checar "Janela: o rotulo do audio usa essa regra" `
    ([bool]($jan -match '\$rot = Rotular-Audio \$pr \$ehAtmos'))
Checar "Janela: a RESPOSTA do reaproveitamento usa a mesma regra" `
    ([bool]($jan -match '\$nomeP = Rotular-Audio \$pronta'))
Checar "Janela: nenhum lado do audio le o track_name de volta" `
    (-not ($jan -match '\$nomeP = if \(\$pronta\.properties\.track_name\)'))
Checar "Janela: a regra devolve Atmos e canais (o que muda a decisao)" `
    ([bool]($jan -match 'function Rotular-Audio[\s\S]{0,700}?r Atmos') -and [bool]($jan -match 'function Rotular-Audio[\s\S]{0,900}?\$r \$l'))

<#  2) O diagnostico previo prometia "OCR: seconv/BinaryOCR" - e no GOT o
    seconv foi RECUSADO pelo motor (8,4% dos caracteres como '*') e quem fez
    foi o PgsToSrt. A tela nao anuncia a ferramenta antes de o motor escolher. #>
Checar "Janela: o diagnostico de legenda nao promete a ferramenta de OCR" `
    (-not ($jan -match 'DiagLgres = "[^"]*OCR: '))

<#  3) A linha do DV virou paragrafo na 16.78. Ela e onde se DECIDE: sigla e
    numero medido, nao aula de tone mapping nem nome de ferramenta de terceiro
    - isso mora no manual e no log. #>
Checar "Janela: a linha do DV nao cita ferramenta de terceiro" `
    (-not ($jan -match 'DiagDVres = ". \[SERA|DiagDVres[^\r\n]{0,200}DoVi_Scripts'))
Checar "Janela: no FEL a linha traz o par L1/master (o numero que decide)" `
    (($jan -match 'o arquivo pede \{0:N0\} nits e o master \u00e9 \{1:N0\}') -and
     ($jan -match 'o arquivo pede \{0:N0\} nits, dentro dos \{1:N0\} do master'))
<#  16.81: o par de numeros sozinho era dado cru - "153 de 1.000" nao diz
    se e bom ou ruim, e essa era a pergunta inteira. A frase tem que
    concluir, nos dois sentidos. #>
Checar "Janela: o L1 abaixo do master conclui 'sem expansao de brilho'" `
    ([bool]($jan -match 'a camada extra tem imagem, descartada'))
Checar "Janela: o L1 no/acima do master conclui que a TV vai errar" `
    ([bool]($jan -match 'a camada extra levanta o brilho'))
Checar "Janela: no MEL a linha resolve em uma oracao" `
    ([bool]($jan -match 'EL sem imagem'))

<#  4) BUG MEDIDO (log de 04/09, 18:49:57 -> 18:50:01): a fase B comecou a
    medir, o Iniciar derrubou o runspace 3s depois, o "el_fim" nunca chegou -
    e a linha ficou escrita "medindo..." durante a conversao inteira. Tela
    travada numa frase que nao era mais verdade. #>
Checar "Janela: existe Fechar-MedicaoPendente (medicao interrompida nao trava a tela)" `
    ([bool]($jan -match 'function Fechar-MedicaoPendente'))
Checar "Janela: TODO fim de runspace fecha a medicao presa (Stop-Motor chama)" `
    ([bool]($jan -match 'function Stop-Motor \{[\s\S]{0,40}?Fechar-MedicaoPendente'))
Checar "Janela: medicao interrompida vira NAO MEDIDA em ambar, jamais limpa" `
    ([bool]($jan -match 'function Fechar-MedicaoPendente[\s\S]{0,2500}?NAO_MEDIDO[\s\S]{0,700}?DiagDVcor = "ambar"'))

<#  5) BUG RELATADO: o PC reiniciou no meio do mkvmerge; ao voltar, o .mkv
    truncado na pasta de saida foi lido como "Ja Existe na Saida" e travou o
    arquivo - o usuario perdia o filme achando que ja tinha feito.
    Existir nao e estar pronto. #>
Checar "Janela: existe Test-SaidaCompleta (existir nao e estar pronto)" `
    ([bool]($jan -match 'function Test-SaidaCompleta'))
Checar "Janela: a saida so conta como pronta se o tamanho fecha" `
    ([bool]($jan -match 'if \(Test-SaidaCompleta \$alvo \(\[double\]\$v\.Bytes\)\)'))
Checar "Janela: um arquivo truncado na saida NAO tira o video da fila" `
    ([bool]($jan -match 'arquivo INCOMPLETO na saida'))


Titulo "12. A TELA PROMETEU E O MOTOR NAO CUMPRIU (16.81 / 14.40)"
<#  BUG MEDIDO (Troy, 05/09): o Diego marcou MANTER na PGS pt-BR. A aba
    Faixas mostrou "MANTER [ESCOLHA MANUAL]", o diagnostico escreveu "PGS
    Mantida a Pedido - Conversao Desligada" - e a etapa 3/4 fez o OCR.

    Causa: marcar MANTER so acrescentava o id na lista de faixas mantidas. A
    chave LegendaPgs nao era enviada, e chave AUSENTE, para o motor, quer
    dizer "voce decide" - nao "nao converta". Ele decidia e convertia.

    E a licao da 16.31 (ausencia de chave nunca e uma ordem) repetida no ramo
    vizinho, um ano depois. Por isso estes testes: a proxima vez que alguem
    mexer aqui, a bateria cobra a ORDEM explicita. #>

Checar "Janela: recusar a PGS do OCR manda uma ORDEM (-1), nao silencio" `
    ([bool]($jan -match '\$e\["LegendaPgs"\] = -1'))
Checar "Janela: a ordem so sai quando o usuario tirou do OCR o que o automatico converteria" `
    ([bool]($jan -match '\$vb -eq "MANTER" -and "\$\(\$f\.VerboAuto\)" -eq "CONVERTER"'))
Checar "Janela: escolher OUTRA PGS para o OCR nao vira 'nao converta'" `
    ([bool]($jan -match '\$pgsRecusada -and -not \$e\.ContainsKey\("LegendaPgs"\)'))
Checar "Motor: LegendaPgs negativo desliga o OCR (devolve nenhuma faixa)" `
    ([bool]($mot -match '\[int\]\$escManual\[.LegendaPgs.\] -lt 0[\s\S]{0,60}?return \$null'))
Checar "Motor: a regra do -1 vem ANTES de procurar a faixa por conta propria" `
    ([bool]($mot -match '-lt 0[\s\S]{0,3000}?\$pgsEscolhida = @\(\$jm\.tracks'))

Titulo "13. O RUNSPACE E OUTRO MUNDO (16.82) - teste estrutural"
<#  ESTE TESTE EXISTE PORQUE EU COMETI O MESMO ERRO DUAS VEZES.

    16.76: o motor chama a ferramenta de $doviTool, a janela de $dovi_tool.
           Sem a ponte, Get-TipoCamadaDV nao achava nada - em silencio.
    16.79: escrevi Test-SaidaCompleta como funcao DA JANELA e chamei dentro
           do runspace de leitura. Resultado no log do Diego (05/09 01:19):
           "O termo 'Test-SaidaCompleta' nao e reconhecido" - e TODO arquivo
           com pasta de saida existente virou "Erro na Leitura".

    Os dois blocos $script:TrabalhoMotor e $script:TrabalhoLeitura rodam em
    OUTRO runspace: enxergam so o que e definido dentro deles mesmos, o que
    vem por parametro, e as funcoes que o motor exporta pela AST. Uma funcao
    da janela chamada la dentro nao existe - e o erro so aparece em runtime,
    no arquivo do usuario, nunca aqui.

    Entao a bateria confere isso por estrutura: nenhuma funcao definida FORA
    dos blocos pode ser chamada DENTRO deles. #>

$linhas = $jan -split "`r?`n"
$iniMotor = ($linhas | Select-String -SimpleMatch '$script:TrabalhoMotor = {' | Select-Object -First 1).LineNumber
$iniLeit  = ($linhas | Select-String -SimpleMatch '$script:TrabalhoLeitura = {' | Select-Object -First 1).LineNumber

function Get-BlocoRunspace([int]$Inicio) {
    # Fecha no primeiro "}" de coluna zero depois do inicio: e como os dois
    # blocos sao escritos neste arquivo (nao ha indentacao no fechamento).
    $fim = $Inicio
    for ($i = $Inicio; $i -lt $linhas.Count; $i++) {
        if ($linhas[$i] -match '^\}\s*$') { $fim = $i; break }
    }
    return ($linhas[($Inicio - 1)..$fim] -join "`n")
}
<#  Comentario NAO e chamada. A primeira versao deste teste reprovou em
    Fill-Fila, Update-Selecao, Get-TamanhoEstimadoVideo e ate no comentario
    que EXPLICA o bug do Test-SaidaCompleta - todos citados em prosa dentro
    dos blocos. Tirar comentario de linha e comentario de bloco antes de
    procurar. #>
function Remove-Comentarios([string]$Txt) {
    $s = [regex]::Replace($Txt, '(?s)<#.*?#>', ' ')
    return (($s -split "`n" | ForEach-Object { ($_ -replace '#.*$', '') }) -join "`n")
}
$blocoM = Remove-Comentarios (Get-BlocoRunspace $iniMotor)
$blocoL = Remove-Comentarios (Get-BlocoRunspace $iniLeit)
Checar "os dois blocos de runspace foram localizados no fonte" `
    ($iniMotor -gt 0 -and $iniLeit -gt $iniMotor -and $blocoL.Length -gt 5000)

# Funcoes da JANELA = as definidas fora dos dois blocos.
$todas = [regex]::Matches($jan, '(?m)^function\s+([A-Za-z][A-Za-z0-9-]*)') | ForEach-Object { $_.Groups[1].Value }
$dentro = @()
foreach ($b in @($blocoM, $blocoL)) {
    $dentro += [regex]::Matches($b, '(?m)^\s+function\s+([A-Za-z][A-Za-z0-9-]*)') | ForEach-Object { $_.Groups[1].Value }
}
$soDaJanela = @($todas | Where-Object { $dentro -notcontains $_ } | Sort-Object -Unique)
Checar "a lista de funcoes exclusivas da janela foi extraida ($($soDaJanela.Count) nomes)" `
    ($soDaJanela.Count -ge 20)

$vazadas = @()
foreach ($nome in $soDaJanela) {
    foreach ($par in @(@("motor", $blocoM), @("leitura", $blocoL))) {
        # Chamada = o nome como comando (inicio de linha ou depois de = ( { |).
        if ($par[1] -match ("(?m)(^|[=({|;]\s*|\s)" + [regex]::Escape($nome) + "(\s|\)|$)")) {
            $vazadas += ("{0} (chamada no bloco {1})" -f $nome, $par[0])
        }
    }
}
Checar "NENHUMA funcao da janela e chamada dentro dos runspaces" `
    ($vazadas.Count -eq 0) ("vazou: " + ($vazadas -join " | "))

<#  E o caso concreto que estourou: quem decide "ja existe na saida" tem que
    ser a janela, um lugar so - duplicar a regra nos dois lados foi o que
    causou o bug do audio da 16.79/16.80. #>
Checar "Janela: a leitura NAO decide 'ja existe na saida' (quem decide e Update-JaExiste)" `
    (-not ($blocoL -match 'Test-SaidaCompleta'))
Checar "Janela: 'Ja Existe na Saida' e decidido num lugar so" `
    (([regex]::Matches($jan, 'Test-SaidaCompleta')).Count -ge 2 -and
     [bool]($jan -match 'function Update-JaExiste[\s\S]{0,2000}?Test-SaidaCompleta'))
Checar "Janela: Update-JaExiste avisa quando o que esta na saida e restos" `
    ([bool]($jan -match 'function Update-JaExiste[\s\S]{0,3000}?arquivo INCOMPLETO na saida'))


Titulo "14. TESTE QUE EXECUTA DE VERDADE (16.83)"
<#  Ate aqui a bateria so LIA o fonte. Isso pega funcao ausente e frase
    errada, mas nao pega logica errada: Test-SaidaCompleta podia estar
    escrita, citada e importada e ainda assim decidir errado.

    Aqui a funcao e EXTRAIDA do fonte pela AST, carregada de verdade, e
    rodada contra arquivos reais criados na hora. E o unico jeito de provar
    que 19,4 GB de saida para um original de 20,6 GB conta como pronto e que
    3 GB nao conta. #>

$astJan = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $Fonte "LaFirma_JANELA.ps1"), [ref]$null, [ref]$null)
$fnSaida = $astJan.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                             $args[0].Name -eq "Test-SaidaCompleta" }, $true)
Checar "Test-SaidaCompleta pode ser extraida do fonte e carregada" ($fnSaida.Count -eq 1)
if ($fnSaida.Count -eq 1) {
    . ([scriptblock]::Create($fnSaida[0].Extent.Text))
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("lafirma_teste_" + [guid]::NewGuid().ToString("N").Substring(0,8))
    $null = New-Item -ItemType Directory -Path $tmp -Force
    try {
        # Proporcoes reais medidas: GOT 20,62 -> 19,48 GB (94%);
        # Troy 87,00 -> 81,7 GB (94%). O truncado do mkvmerge fica bem abaixo.
        $completo = Join-Path $tmp "completo.mkv"
        $truncado = Join-Path $tmp "truncado.mkv"
        [System.IO.File]::WriteAllBytes($completo, (New-Object byte[] 9400))   # 94% de 10000
        [System.IO.File]::WriteAllBytes($truncado, (New-Object byte[] 1200))   # 12% de 10000

        Checar "EXECUTANDO: saida com 94% do original conta como PRONTA" `
            (Test-SaidaCompleta $completo 10000)
        Checar "EXECUTANDO: saida com 12% do original NAO conta como pronta" `
            (-not (Test-SaidaCompleta $truncado 10000))
        Checar "EXECUTANDO: arquivo que nao existe nunca conta como pronto" `
            (-not (Test-SaidaCompleta (Join-Path $tmp "nao_existe.mkv") 10000))
        Checar "EXECUTANDO: sem tamanho de origem conhecido, aceita (nao inventa reprovacao)" `
            (Test-SaidaCompleta $truncado 0)
        # A fronteira: 60% e o corte declarado no comentario da funcao.
        [System.IO.File]::WriteAllBytes((Join-Path $tmp "no_limite.mkv"), (New-Object byte[] 6100))
        [System.IO.File]::WriteAllBytes((Join-Path $tmp "abaixo.mkv"),    (New-Object byte[] 5900))
        Checar "EXECUTANDO: 61% passa, 59% nao (o corte e 60%, como esta escrito)" `
            ((Test-SaidaCompleta (Join-Path $tmp "no_limite.mkv") 10000) -and
             (-not (Test-SaidaCompleta (Join-Path $tmp "abaixo.mkv") 10000)))
    } finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

<#  16.83: e o bug que este teste NAO pegaria sozinho - quem CHAMA a funcao.
    Eu tirei a marca da leitura na 16.82 e escrevi no comentario que
    Update-JaExiste "ja roda depois de toda leitura". Nao rodava: so era
    chamado na troca da pasta de saida. O GOT ja convertido deixou clicar
    Iniciar, e quem barrou foi o motor la na frente. #>
Checar "Janela: a leitura termina chamando Update-JaExiste" `
    ([bool]($jan -match '(?m)"leitura_fim" \{[\s\S]{0,3000}?^\s+Update-JaExiste\s*$'))
Checar "Janela: a fase B nao anuncia medicao quando ja foi cancelada" `
    ([bool]($jan -match '\$pendentesEL\.Count -gt 0 -and -not \$Controle\.Cancelar'))


Titulo "15. UMA COISA, UM TEXTO (16.84)"
<#  A queixa do Diego, repetida por semanas e finalmente atacada: a MESMA
    informacao de Dolby Vision saia escrita de oito jeitos, cada um num canto
    da tela. Oito lugares montando string na mao, e um deles sempre esquecido
    a cada mudanca - foi assim que a sigla MEL sumiu da linha de resposta.

    Agora quem escreve Dolby Vision e SO Format-DolbyVision. Estes testes a
    EXECUTAM, com os dados reais do GOT e do Troy. #>

$fnFmt = $astJan.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                           $args[0].Name -eq "Format-DolbyVision" }, $true)
Checar "Format-DolbyVision existe e pode ser carregada" ($fnFmt.Count -eq 1)
if ($fnFmt.Count -eq 1) {
    . ([scriptblock]::Create($fnFmt[0].Extent.Text))
    # Dados reais do GOT: Profile 7.6, dvhe.07.06, BL+EL+RPU, medido FEL.
    $got = Format-DolbyVision -Perfil 7 -Level "6" -Codec "dvhe.07.06" -Camadas "BL+EL+RPU" -ELtipo "FEL"
    $tro = Format-DolbyVision -Perfil 7 -Level "6" -Codec "dvhe.07.06" -Camadas "BL+EL+RPU" -ELtipo "MEL"
    $alv = Format-DolbyVision -Perfil 8 -Level "6" -Alvo

    Checar "EXECUTANDO: a sigla FEL aparece nas QUATRO formas" `
        (($got.Curto -match "FEL") -and ($got.Faixa -match "\[FEL\]") -and ($got.Longo -match "EL: FEL"))
    Checar "EXECUTANDO: a sigla MEL aparece nas QUATRO formas" `
        (($tro.Curto -match "MEL") -and ($tro.Faixa -match "\[MEL\]") -and ($tro.Longo -match "EL: MEL"))
    Checar "EXECUTANDO: MEL e FEL sao textos DIFERENTES (o container os escreve igual)" `
        (($got.Faixa -ne $tro.Faixa) -and ($got.Curto -ne $tro.Curto))
    Checar "EXECUTANDO: a forma da aba Faixas e a string oficial do MediaInfo" `
        ($got.Faixa -eq "Dolby Vision, Version 1.0, dvhe.07.06, BL+EL+RPU [FEL]")
    # 17.03: era "P7.6 FEL". O 06 do dvhe.07.06 e o NIVEL, nao parte do nome
    # do perfil - a Dolby nomeia Profile 5, 7 e 8. O ponto do 8.1 e outro
    # numero (o compat id) e continua valendo.
    Checar "EXECUTANDO: a coluna da fila fica curta e completa" `
        (($got.Curto -eq "P7 FEL") -and ($alv.Curto -eq "P8.1"))
    Checar "EXECUTANDO: o alvo 8.1 nunca sai 'seco'" `
        (($alv.Longo -match "dvhe\.08\.06") -and ($alv.Longo -match "BL\+RPU"))
    Checar "EXECUTANDO: sem medida, nenhuma sigla e inventada" `
        (-not ((Format-DolbyVision -Perfil 8 -Level "6" -Codec "dvhe.08.06" -Camadas "BL+RPU").Faixa -match "\[(MEL|FEL)\]"))
    Checar "EXECUTANDO: 'nao medida' aparece como tal, nunca em branco" `
        ((Format-DolbyVision -Perfil 7 -Level "6" -Codec "dvhe.07.06" -Camadas "BL+EL+RPU" -ELtipo "NAO_MEDIDO").Curto -match "não medida")
}

Checar "Janela: existe Update-TextosDV (o unico caminho que escreve na tela)" `
    ([bool]($jan -match 'function Update-TextosDV'))
Checar "Janela: a leitura e a medicao usam o MESMO caminho de texto" `
    (([regex]::Matches($jan, 'Update-TextosDV \$')).Count -ge 2)
Checar "Janela: a resposta do MEL traz a sigla, nao so 'EL vazia'" `
    ([bool]($jan -match 'MEL: EL vazia'))
Checar "Janela: a resposta do FEL traz a sigla" `
    ([bool]($jan -match 'FEL: EL com imagem'))
Checar "Janela: o nome da faixa de video so e preenchido quando o release nao nomeou" `
    ([bool]($jan -match '\$f\.Tipo -eq "video" -and \$nomeFx -eq "" -and'))

Titulo "16. CENSO DO L1 E AREA ATIVA - L5 (14.41 / 16.85)"
<#  A 2.3.3 do dovi_tool trouxe "export --levels level1,level5". Isso mudou a
    medicao de AMOSTRA para CENSO: em vez de um pico por trecho, o L1 de cada
    cena do mesmo RPU. E trouxe o L5 (area ativa) de graca.

    Estes testes EXECUTAM a conversao PQ -> nits e a classificacao de formato,
    contra numeros medidos de verdade na maquina do Diego em 08/09/2026. #>

$fnPq = $astMot.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                          $args[0].Name -eq "ConvertFrom-PQ" }, $true)
Checar "Motor: existe ConvertFrom-PQ" ($fnPq.Count -eq 1)
if ($fnPq.Count -eq 1) {
    . ([scriptblock]::Create($fnPq[0].Extent.Text))
    <#  Os pares abaixo NAO sao teoria: cada um saiu do mesmo trecho, lido
        pelo mesmo dovi_tool. O max_pq veio do L1_export.csv e o nits veio do
        "info --summary" do MESMO RPU. Se a conta divergir, quem esta errado
        somos nos, nao a ferramenta. #>
    foreach ($par in @(@(2384, 205.90), @(2712, 437.78), @(2472, 252.63),
                       @(3428, 2186.23), @(2941, 734.20), @(2081, 100.10),
                       @(3050, 937.65), @(2749, 476.11))) {
        $obtido = ConvertFrom-PQ -CodigoPQ ([double]$par[0])
        Checar ("EXECUTANDO: PQ {0} = {1:N2} nits (o proprio dovi_tool diz {2:N2})" -f $par[0], $obtido, $par[1]) `
            ([math]::Abs($obtido - [double]$par[1]) -lt 0.01)
    }
    Checar "EXECUTANDO: codigo zero nao vira nits negativo nem erro" `
        ((ConvertFrom-PQ -CodigoPQ 0) -eq 0.0)
    Checar "EXECUTANDO: o topo da escala PQ da 10.000 nits" `
        ([math]::Abs((ConvertFrom-PQ -CodigoPQ 4095) - 10000.0) -lt 1.0)
}

$fnFmt2 = $astMot.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                            $args[0].Name -eq "Get-NomeDoFormato" }, $true)
Checar "Motor: existe Get-NomeDoFormato" ($fnFmt2.Count -eq 1)
if ($fnFmt2.Count -eq 1) {
    . ([scriptblock]::Create($fnFmt2[0].Extent.Text))
    # Troy: 3840x2160 menos 277 em cima e embaixo = 3840x1606 = 2,39.
    Checar "EXECUTANDO: Troy (borda 277) e Scope 2,39:1" `
        ((Get-NomeDoFormato -Proporcao ([math]::Round(3840 / 1606.0, 2))) -eq "Scope 2,39:1")
    # Se7en: borda 280 = 3840x1600 = 2,40. Mesmo formato, master diferente.
    Checar "EXECUTANDO: Se7en (borda 280, da 2,40) tambem e Scope" `
        ((Get-NomeDoFormato -Proporcao 2.40) -eq "Scope 2,39:1")
    # GOT: sem borda nenhuma.
    Checar "EXECUTANDO: sem borda, 3840x2160 e 16:9" `
        ((Get-NomeDoFormato -Proporcao ([math]::Round(3840 / 2160.0, 2))) -eq "16:9")
    <#  O caso que justifica o aviso na tela: uma borda que nao resulta em
        formato nenhum e RPU com crop errado - o "bad cropped RPU" que o DDVT
        conserta. O LaFirma nao cria isso, mas precisa saber apontar. #>
    Checar "EXECUTANDO: proporcao impossivel e denunciada, nao arredondada para o vizinho" `
        ((Get-NomeDoFormato -Proporcao 3.20) -eq "fora dos formatos comuns")
}

Checar "Motor: o export roda em pasta propria (ele IGNORA o -o e grava no diretorio atual)" `
    ([bool]($mot -match 'Set-Location -LiteralPath \$pastaEx'))
Checar "Motor: e volta para a pasta de onde saiu, mesmo se o export falhar" `
    ([bool]($mot -match 'finally \{\s*\r?\n\s*Set-Location -LiteralPath \$voltarPara'))
Checar "Motor: o censo le max_pq do L1_export.csv" `
    (($mot -match 'L1_export\.csv') -and ($mot -match 'max_pq'))
Checar "Motor: o L5 le as quatro bordas do L5_export.csv" `
    (($mot -match 'L5_export\.csv') -and ($mot -match 'active_area_top_offset') -and
     ($mot -match 'active_area_left_offset'))
Checar "Motor: contar cena acima do master exige TER o master (sem regua, nao ha conta)" `
    ([bool]($mot -match '\$res\.MasterMax -gt 0 -and \$nits -gt \$res\.MasterMax'))
Checar "Motor: falha no export nao derruba a medicao MEL x FEL" `
    ([bool]($mot -match '(?s)\$csvL5.*?\}\s*\r?\n\s*\} catch \{ \}'))

Checar "Janela: a tela so conta cenas quando ha cena contada" `
    ([bool]($jan -match 'CenasAcimaDoMaster'))
Checar "Janela: o L5 so vira aviso quando o formato nao existe" `
    ([bool]($jan -match 'fora dos formatos comuns'))
Checar "Janela: o aviso de L5 diz que o defeito veio da origem, nao do LaFirma" `
    ([bool]($jan -match 'j\u00e1 vem assim da origem'))
Checar "Janela: o censo e o L5 vao para o log, nao so para a tela" `
    (($jan -match 'Censo do L1') -and ($jan -match '\u00c1rea ativa \(L5\)'))

<#  16.86 - TRES NIVEIS, TRES CORES. O Diego apontou o que os numeros ja
    diziam: GOT e Ryan sao os dois FEL, mas 153/1.000 e 1.608/1.000 nao sao
    o mesmo caso. Pintar os dois igual apaga a unica diferenca que decide. #>
Checar "Janela: 'laranja' existe como cor de diagnostico" `
    ([bool]($jan -match '"laranja"\s*\{\s*return \$Cores\.lar'))
Checar "Janela: FEL sem expansao e LARANJA (ressalva, nao alarme)" `
    ([bool]($jan -match '\$v\.DiagDVcor = "laranja"'))
<#  Este teste ja nasceu frouxo uma vez: escrevi uma alternancia cujo
    primeiro lado casava sozinho, entao ele passaria com o codigo errado.
    Teste que passa sempre e pior que teste nenhum - da confianca de graca.
    Agora ele exige a ORDEM: vermelho e o selo aparecem DENTRO do ramo do
    brilho expandido, antes da frase. #>
Checar "Janela: FEL COM expansao e VERMELHO (o unico caso que estraga)" `
    ([bool]($jan -match '(?s)\$m\.Expande -eq \$true.{0,200}\$v\.DiagDVcor = "vermelho"'))
Checar "Janela: so o caso que expande muda o selo para nao recomendado" `
    (([regex]::Matches($jan, 'CONVERS\u00c3O N\u00c3O RECOMENDADA')).Count -eq 1)
Checar "Janela: MEL continua verde (nao ha ressalva a fazer)" `
    ([bool]($jan -match 'MEL: EL vazia, descarte sem perda'))

<#  16.86 - ESPACO EM DISCO: SOBRA NEGATIVA NAO E SOBRA.
    A tela dizia "Espaco Insuficiente" na barra e, uma linha acima, prometia
    "-47,52 GB livres depois". Nao ha depois - a conversao nao comeca. #>
Checar "Janela: quando nao cabe, a linha diz quanto FALTA LIBERAR" `
    ([bool]($jan -match 'Falta Liberar'))
Checar "Janela: 'livre apos converter' so aparece quando sobra de verdade" `
    ([bool]($jan -match '(?s)if \(\$sobra -lt 0\).{0,200}Falta Liberar.{0,200}\} else \{.{0,120}Livre Ap\u00f3s Converter'))
Checar "Janela: as tres linhas do disco alinham os dois-pontos na mesma coluna" `
    ($(  $m1 = [regex]::Match($jan, 'Espa\u00e7o Necess\u00e1rio Estimado :')
         $m2 = [regex]::Match($jan, 'Falta Liberar\s+:')
         $m1.Success -and $m2.Success -and ($m1.Value.Length -eq $m2.Value.Length) ))

Titulo "17. O QUE O USUARIO LEU E NAO ENTENDEU (14.43 / 16.87)"
<#  Tudo nesta secao saiu de perguntas do Diego olhando a tela pronta - nao de
    ideia minha. Texto que precisa de explicacao depois nao esta pronto. #>

Checar "Motor: existe um veredicto unico de expansao (campo Expande)" `
    (($mot -match 'Expande\s*=\s*\$null') -and ($mot -match '\$res\.Expande = \(\[double\]\$res\.MaxCLL -ge \[double\]\$res\.MasterMax\)'))
Checar "Motor: sem master OU sem L1, Expande fica indefinido (nao vira 'false')" `
    ([bool]($mot -match '\$res\.MasterMax -gt 0 -and \$res\.MaxCLL -gt 0'))
Checar "Motor: o selo EXPANDE existe e tem resposta propria no console" `
    (($mot -match '\$res\.Selo   = "EXPANDE"') -and ($mot -match 'CONVERSAO NAO RECOMENDADA'))
Checar "Motor: NAO manda mais o usuario procurar outra ferramenta" `
    (-not ($mot -match 'DoVi_Scripts trata'))
Checar "Motor: o console ganhou o laranja da janela" `
    (($mot -match '"lar"\s*=\s*\(New-Cor') -and ($mot -match '"lar"\s*\{\s*"lar"\s*\}'))
Checar "Motor: 'alerta' e vermelho mas NAO usa o simbolo de falha" `
    ([bool]($mot -match '"alerta"\s*\{\s*\$script:SimWarn\s*\}'))

Checar "Janela: quem decide a expansao e o motor, nao a tela" `
    (($jan -match 'Expande = \$el\.Expande') -and ($jan -match '\$m\.Expande -eq \$true'))
Checar "Janela: a tela NAO refaz a conta de L1 x master por conta propria" `
    (-not ($jan -match 'if \(\$l1 -lt \$mst\)'))
Checar "Janela: existe Pintar-RotuloDV (a sigla da EL ganha cor)" `
    ([bool]($jan -match 'function Pintar-RotuloDV'))
Checar "Janela: a cor da sigla vem do tipo MEDIDO, nao da palavra na frase" `
    (($jan -match '(?s)function Get-NomeCorEL.{0,2600}switch \("\$\(\$v\.ELtipo\)"\)') -and
     ($jan -match '\$cor = Get-CorEL \$v'))
Checar "Janela: a sigla tem as quatro cores da escala" `
    ([bool]($jan -match '(?s)function Get-CorEL.{0,500}\$Cores\.ok.{0,120}\$Cores\.lar.{0,120}\$Cores\.err.{0,120}\$Cores\.warn'))
Checar "Janela: o rotulo sem [EL: ...] continua saindo inteiro" `
    ([bool]($jan -match '(?s)if \(-not \$m\.Success\).{0,200}Inlines\.Add'))
Checar "Janela: 'em N/M cenas' saiu da linha do diagnostico" `
    (-not ($jan -match '" em \{0\}/\{1\} cenas"'))
Checar "Janela: o censo no log diz que a amostra NAO e o filme inteiro" `
    ([bool]($jan -match 'n\u00e3o o filme inteiro'))
Checar "Janela: a resposta da legenda nao anuncia PGS (e o que deixa de existir)" `
    (($jan -match 'Legenda em Portugu\u00eas no formato \.SRT') -and
     (-not ($jan -match 'SER\u00c1 CONVERTIDA\] \$nomeSaidaLeg')))
Checar "Janela: descartar extras e VERDE (e acao, nao ausencia)" `
    ([bool]($jan -match '"\u00c1udios e Legendas Extras - DESCARTADOS", "ok"'))
Checar "Janela: nenhum dos quatro selos de descarte ficou cinza" `
    (-not ($jan -match 'Extras - DESCARTAD[OA]S[^"]*", "cinza"'))

Titulo "18. O BOTAO ENTENDA E O TEXTO DELE (16.88)"
<#  O programa decide muito sozinho. Ate aqui cada decisao era explicada em
    uma linha de tela - formato certo para decidir, errado para aprender.
    Estes testes cuidam de duas coisas: que o botao exista de verdade, e que
    o TEXTO nao volte a afirmar o que o projeto ja aprendeu a nao afirmar. #>

Checar "Janela: o botao Entenda existe no XAML" `
    ([bool]($jan -match 'x:Name="btnEntenda"'))
Checar "Janela: o botao Entenda tem acao" `
    ([bool]($jan -match '\$UI\.btnEntenda\.add_Click'))
Checar "Janela: o texto vive FORA do .ps1 (da para corrigir sem mexer em codigo)" `
    ([bool]($jan -match 'Join-Path \$script:PastaScript "FAQ_PT\.txt"'))
Checar "Janela: FAQ faltando avisa onde deveria estar (nao some com o botao)" `
    ([bool]($jan -match 'n\u00e3o foi encontrado'))
Checar "Janela: texto para LER abre no comeco; log continua abrindo no fim" `
    (($jan -match 'ScrollToHome') -and ($jan -match 'ScrollToEnd'))

$pFaq = Join-Path $Fonte "FAQ_PT.txt"
if (-not (Test-Path -LiteralPath $pFaq)) {
    Checar "FAQ_PT.txt existe ao lado do programa" $false "sem ele o botao Entenda abre vazio"
} else {
    $faq = [System.IO.File]::ReadAllText($pFaq, [System.Text.Encoding]::UTF8)
    $bytesFaq = [System.IO.File]::ReadAllBytes($pFaq)
    Checar "FAQ: tem BOM (o PowerShell 5.1 sem BOM come os acentos)" `
        ($bytesFaq.Length -ge 3 -and $bytesFaq[0] -eq 0xEF -and $bytesFaq[1] -eq 0xBB -and $bytesFaq[2] -eq 0xBF)
    Checar "FAQ: CRLF puro" `
        ((([regex]::Matches($faq, "(?<!`r)`n")).Count) -eq 0)
    <#  3.1: uma linha que e SO um endereco fica de fora da conta. Quebrar
        um link no meio para caber em 80 colunas deixa ele sem servir para
        copiar, que e a unica coisa que um link faz. Texto continua preso ao
        limite - a excecao vale para o endereco, nao para a frase. #>
    Checar "FAQ: nenhuma linha de TEXTO passa de 80 colunas (a janela tem largura fixa)" `
        ($(  $larga = @($faq -split "`r`n" | Where-Object { $_.Length -gt 80 -and ($_.Trim() -notmatch '^https?://\S+$') })
             $larga.Count -eq 0 ))
    <#  O conteudo tambem e testado. Nao por gosto de texto: cada item abaixo
        e uma afirmacao que este projeto ERROU antes e corrigiu. Se voltar
        para o FAQ, volta o erro - so que agora publicado. #>
    Checar "FAQ: nao repete 'a grande maioria' (afirmacao sem base, retirada em 08/09)" `
        (-not ($faq -match 'grande maioria'))
    Checar "FAQ: diz que a lista de players e relato, nao medicao nossa" `
        ([bool]($faq -match 'relato, n' + [char]0x00E3 + 'o medi' + [char]0x00E7 + [char]0x00E3 + 'o'))
    <#  2.4: a frase antiga era "nenhuma ferramenta publica faz" - absoluta,
        e com duplo sentido: dava a entender que medir brilho de video e
        impossivel, e que o LaFirma faria o que ninguem faz. Nada disso e
        verdade. O DaVinci Resolve mede brilho quadro a quadro, e quem colore
        HDR faz isso todo dia. O que nao existe e uma ferramenta de LINHA DE
        COMANDO que meca sozinha e devolva um numero para um script decidir.
        O teste agora cobra a versao exata, com o contra-exemplo escrito. #>
    Checar "FAQ: nao afirma que medir brilho e impossivel (cita o DaVinci)" `
        (($faq -match 'DaVinci Resolve') -and ($faq -match 'perfeitamente poss' + [char]0x00ED + 'vel'))
    Checar "FAQ: o limite e a AUTOMACAO, nao a medicao em si" `
        (($faq -match 'medi' + [char]0x00E7 + [char]0x00E3 + 'o autom' + [char]0x00E1 + 'tica, de linha de comando') -and
         ($faq -match 'Automatizar isso' + [char]0x00E9 + ' outro trabalho|Automatizar isso ' + [char]0x00E9 + ' outro trabalho'))
    <#  2.6: o teste antigo exigia a COMPARACAO com o dovi_convert. O Diego
        tirou o tom de comparacao do texto inteiro - "nao queremos competir;
        se usamos o de alguem, damos credito e agradecemos". O que continua
        obrigatorio e a honestidade sobre o nosso proprio limite. #>
    Checar "FAQ: assume o limite do proprio programa, sem comparar com ninguem" `
        (($faq -match 'n' + [char]0x00E3 + 'o mede o brilho real da camada base') -and
         ($faq -match 'um bom\s+ind' + [char]0x00ED + 'cio, n' + [char]0x00E3 + 'o uma prova'))

    <#  2.4: o audio saia generalizado - "preservando o Atmos quando ele
        existe", como se DTS tambem virasse Atmos. Nao vira, e nunca vai:
        DTS e Atmos sao de empresas diferentes e o DTS:X perde os objetos na
        conversao. O Diego pegou isso lendo o FAQ. Detalhe tecnico errado num
        texto que existe para ensinar e pior que nao ter o texto. #>
    Checar "FAQ: audio - TrueHD vai para E-AC-3 ATMOS pelo DeeZy" `
        ([bool]($faq -match 'TrueHD[^\r\n]*E-AC-3 Atmos, 1152 kbps, pelo DeeZy'))
    Checar "FAQ: audio - DTS vai para E-AC-3 COMUM pelo ffmpeg, 640k" `
        ([bool]($faq -match 'DTS:X[^\r\n]*E-AC-3 comum, 640 kbps, pelo ffmpeg'))
    Checar "FAQ: audio - diz explicitamente que DTS NAO sai com Atmos" `
        ([bool]($faq -match 'N' + [char]0x00C3 + 'O h' + [char]0x00E1 + ' Atmos na sa' + [char]0x00ED + 'da'))
    Checar "FAQ: audio - E-AC-3/AC-3/AAC nao sao convertidos" `
        ([bool]($faq -match 'E-AC-3, AC-3 e AAC[^\r\n]*n' + [char]0x00E3 + 'o converte'))
    Checar "FAQ: o texto do audio bate com a regra que esta no motor" `
        (($mot -match 'TrueHD -> converte para E-AC-3 Atmos') -and
         ($mot -match 'DTS/DTS-HD/DTS:X -> converte para E-AC-3 comum'))
    Checar "FAQ: explica que a amostra nao e o filme inteiro" `
        ([bool]($faq -match ('(?s)n' + [char]0x00E3 + 'o s' + [char]0x00E3 + 'o\s+o filme inteiro')))
    Checar "FAQ: diz que o vermelho nao significa que a conversao estraga" `
        ([bool]($faq -match 'N' + [char]0x00C3 + 'O QUER DIZER QUE A CONVERS' + [char]0x00C3 + 'O ESTRAGA'))
    Checar "FAQ: responde por que os binarios nao vao no GitHub" `
        (($faq -match 'POR QUE AS FERRAMENTAS N' + [char]0x00C3 + 'O V' + [char]0x00CA + 'M NO GITHUB') -and
         ($faq -match 'licen' + [char]0x00E7 + 'a'))
    Checar "FAQ: credita as ferramentas de terceiros pelo nome" `
        (($faq -match 'quietvoid') -and ($faq -match 'DonaldFaQ') -and ($faq -match 'MKVToolNix'))
    <#  2.4: credito nao e so listar o binario. O DDVT foi a ferramenta com
        que o Diego aprendeu o assunto e de onde veio a ideia do projeto; e a
        cobranca publica do autor do dovi_convert foi o que fez este programa
        parar de descartar a EL em silencio. Os dois estao no texto pelo
        nome, e o teste guarda isso - credito que some numa revisao futura e
        credito perdido. #>
    Checar "FAQ: o DDVT e creditado como a origem do projeto, nao so listado" `
        ([bool]($faq -match 'ensinou este\s+projeto a existir'))
    Checar "FAQ: o autor do dovi_convert e creditado pela critica que mudou o programa" `
        (($faq -match 'cryptochrome') -and ($faq -match 'come' + [char]0x00E7 + 'ar a medir'))
    Checar "FAQ: usa o vocabulario aprovado (MEL / Simple FEL / Complex FEL)" `
        (($faq -match 'SIMPLE FEL') -and ($faq -match 'COMPLEX FEL'))
    Checar "FAQ: os tres exemplos sao os arquivos que NOS medimos" `
        (($faq -match 'Troy') -and ($faq -match 'Game of Thrones') -and ($faq -match 'Saving Private Ryan'))
    <#  2.6 - O TOM DO TEXTO, cobrado pelo Diego: "comparar nao faz sentido,
        nao queremos competir; se usamos o de alguem, damos os creditos e
        agradecemos pelo aprendizado". A secao virou "DE ONDE VEIO O QUE
        SABEMOS" e nenhuma ferramenta e medida contra a nossa. #>
    Checar "FAQ: a secao de terceiros credita, nao compara" `
        (($faq -match 'DE ONDE VEIO O QUE SABEMOS') -and
         (-not ($faq -match 'COMPARANDO COM OUTRAS FERRAMENTAS')))
    Checar "FAQ: nao ha tabela nem placar de nos contra eles" `
        (-not ($faq -match 'Duas diferen' + [char]0x00E7 + 'as honestas'))
    Checar "FAQ: o DDVT e citado pelo que ensinou, sem ser diminuido" `
        (($faq -match 'ensinou este\s+projeto a existir') -and
         (-not ($faq -match 'N' + [char]0x00E3 + 'o trata\s+MEL x FEL nem brilho')))
    Checar "FAQ: a secao 5 e estruturada em blocos com titulo, nao um bloco unico" `
        (($faq -match 'O QUE O PROGRAMA FAZ') -and ($faq -match 'O LIMITE, DITO SEM RODEIO') -and
         ($faq -match 'QUANDO N' + [char]0x00C3 + 'O H' + [char]0x00C1 + ' R' + [char]0x00C9 + 'GUA'))
    Checar "FAQ: as cores do texto batem com as da tela" `
        (($faq -match 'MEL[^\r\n]*VERDE') -and ($faq -match 'SIMPLE FEL[^\r\n]*LARANJA') -and
         ($faq -match 'COMPLEX FEL[^\r\n]*VERMELHO'))
}

Titulo "19. TODO SELO DO MOTOR TEM RAMO NA JANELA (16.88)"
<#  A REGRESSAO QUE ESTE TESTE EXISTE PARA IMPEDIR, com nome e data:

    Em 08/09 criei no motor um selo novo, "EXPANDE", para o Complex FEL. Na
    janela continuei testando so "RESSALVA". Resultado: o Saving Private
    Ryan - o UNICO arquivo perigoso dos tres - caiu no ramo final, que nao
    mexe em nada, e apareceu VERDE, com "[SERÁ CONVERTIDO]" e nenhuma
    palavra sobre a camada de melhoria. O arquivo mais arriscado pintado
    como o mais seguro.

    A bateria da 2.2 nao pegou porque eu tinha testado o TEXTO das frases,
    nunca o CAMINHO ate elas. Texto certo em ramo que ninguem percorre passa
    em qualquer teste de string.

    Este teste e generico de proposito: ele LE do motor todos os selos que
    Get-TipoCamadaDV pode produzir e exige que cada um esteja escrito no
    handler "el" da janela. Selo novo no motor sem ramo na janela reprova,
    seja qual for o nome. #>

$selosDoMotor = @([regex]::Matches($mot, '\$res\.Selo\s*=\s*"([^"]+)"') |
                  ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique |
                  Where-Object { $_ -ne "-" })
Checar "Motor: os selos de Get-TipoCamadaDV foram localizados no fonte" `
    ($selosDoMotor.Count -ge 3) ("achei: " + ($selosDoMotor -join ", "))

$mHandler = [regex]::Match($jan, '(?s)"el"\s*\{.*?\n(\s{12})\}')
Checar "Janela: o handler 'el' foi localizado" ($mHandler.Success)
if ($mHandler.Success) {
    $trechoEl = $mHandler.Value
    <#  Nem todo selo e testado pelo NOME do selo: MEL e NAO MEDIDO a janela
        trata pelo Tipo, que e igualmente explicito. O que este teste cobra e
        que exista um ramo DEDICADO para cada estado que o motor produz - por
        qualquer um dos dois campos. O que nao pode e um estado do motor cair
        no ramo final por esquecimento, que foi o bug do Ryan. #>
    $porTipo = @{ "LIMPA" = 'Tipo -eq "MEL"'; "NAO MEDIDO" = 'Tipo -eq "NAO_MEDIDO"' }
    foreach ($selo in $selosDoMotor) {
        $achou = $trechoEl -match ('Selo -eq "' + [regex]::Escape($selo) + '"')
        if ((-not $achou) -and $porTipo.ContainsKey($selo)) {
            $achou = $trechoEl -match [regex]::Escape($porTipo[$selo])
        }
        Checar ("Janela: o estado '$selo' do motor tem ramo proprio no handler 'el'") ([bool]$achou)
    }
    <#  Nao basta ter ramo: o ramo tem que MUDAR alguma coisa. Um "elseif"
        vazio passaria no teste acima e deixaria a linha verde do mesmo
        jeito - foi exatamente esse o efeito do bug. #>
    Checar "Janela: EXPANDE muda a cor E o selo da linha (nao e ramo vazio)" `
        (($trechoEl -match ('(?s)Selo -eq "EXPANDE".{0,6000}CONVERS' + [char]0x00C3 + 'O N' + [char]0x00C3 + 'O RECOMENDADA')) -and
         ($trechoEl -match '(?s)Selo -eq "EXPANDE".{0,6000}DiagDVcor = "vermelho"'))
    Checar "Janela: nenhum arquivo MEDIDO como FEL pode terminar verde" `
        (-not ($trechoEl -match '(?s)Tipo -eq "FEL".{0,400}DiagDVcor = "verde"'))
}

Titulo "20. O ARQUIVO NAO PODE FECHAR O PROPRIO COMENTARIO CEDO (2.4)"
<#  A bateria QUEBROU na maquina do Diego e passou aqui - o pior tipo de
    falha. Causa: um comentario de bloco desta propria bateria continha a
    sequencia de FECHAR comentario escrita como exemplo, no meio da frase.
    O PowerShell fechou ali, e o resto da linha virou COMANDO: "antes : O
    termo 'antes' nao e reconhecido". Erro em execucao, nao em analise -
    por isso o teste de sintaxe nao pegou.

    E passou aqui porque eu filtrava a saida da bateria procurando "FALHA" e
    nao olhava o erro vermelho. Duas licoes, e as duas viraram teste: nenhum
    arquivo pode fechar o proprio comentario cedo, e a bateria tem que ser
    rodada olhando a saida inteira. #>
<#  Os fontes moram em $Fonte; a bateria mora em $raiz. Na primeira versao
    deste teste eu procurei tudo em $raiz - e ele deu "ok" alegremente para
    fontes que nem estava lendo. Teste que olha o lugar errado nao e teste. #>
$alvosC = @()
foreach ($nomeC in @("LaFirma_JANELA.ps1", "Converter_AUTO_DIRETO.ps1",
                     "Corretor_Legenda.ps1", "Reocr_Legenda.ps1")) {
    $alvosC += ,@($nomeC, (Join-Path $Fonte $nomeC))
}
$alvosC += ,@("Testar_LaFirma.ps1", (Join-Path $raiz "Testar_LaFirma.ps1"))
foreach ($parC in $alvosC) {
    $arqC = $parC[0]; $pC = $parC[1]
    if (-not (Test-Path -LiteralPath $pC)) { continue }
    $tC = Get-Content -Raw -LiteralPath $pC
    <#  Procura a sequencia de fechar comentario DENTRO de um bloco de
        comentario. Os dois marcadores sao montados por codigo para esta
        checagem nao acusar a si mesma - foi assim que o bug nasceu. #>
    <#  COMO SE DETECTA ISSO, e por que a primeira tentativa nao funcionou.

        Tentei procurar a sequencia de fechar DENTRO de um bloco casado por
        expressao regular. Nao funciona, e o motivo e o proprio bug: a busca
        nao-gulosa fecha no PRIMEIRO fechamento - que e justamente o
        intruso. O corpo casado sai limpo e o teste da "ok" no arquivo
        quebrado. Foi o que aconteceu quando testei o teste.

        A assinatura de verdade e outra: um fechamento de comentario com
        TEXTO depois dele na mesma linha. Fechamento legitimo termina a
        linha; o intruso tem prosa em seguida - e e essa prosa que o
        PowerShell tenta executar. Exigir uma LETRA depois evita o falso
        positivo obvio, que e a sequencia aparecendo dentro de uma string
        de expressao regular (ali o que vem depois e aspas e parenteses). #>
    $fe = [string][char]35 + [string][char]62
    $ruins = @()
    $nl = 0
    foreach ($linhaC in ($tC -split "`n")) {
        $nl++
        <#  Linha que COMECA com "#" e comentario de linha: o PowerShell
            ignora ela inteira, entao a sequencia ali dentro e so texto.
            Os cabecalhos dos dois fontes explicam a convencao de comentario
            exatamente assim, e nao ha nada de errado nisso. #>
        $semEsp = $linhaC.TrimStart()
        if ($semEsp.StartsWith([string][char]35) -and -not $semEsp.StartsWith($fe)) { continue }
        $posC = $linhaC.IndexOf($fe)
        if ($posC -lt 0) { continue }
        $depois = $linhaC.Substring($posC + 2)
        if ($depois -match '[A-Za-z]') { $ruins += ("linha " + $nl) }
    }
    Checar ("$arqC - nenhum comentario de bloco fecha cedo") ($ruins.Count -eq 0) ($ruins -join "; ")
}

Titulo "22. COMECAR SABENDO QUE NAO CABE (16.91) E O MANUAL EM DIA"
<#  A tela dizia "Espaco Insuficiente" em vermelho e o Iniciar comecava
    assim mesmo; o motor recusava arquivo por arquivo 23 segundos depois,
    com a MESMA conta que ja estava na tela. Agora a janela pergunta antes.

    E o manual (COMO_USAR / HOW_TO_USE) continuava com o texto de antes da
    medicao: prometia "a grande maioria" sem base, mandava procurar outra
    ferramenta e dizia que o programa NAO separava os dois FEL - o que
    deixou de ser verdade em 08/09. Manual desatualizado tambem mente. #>

Checar "Janela: Update-Disco guarda o quanto falta, para o Iniciar poder usar" `
    (($jan -match '\$script:DiscoFalta = \$\(if \(\$sobra -lt 0\)') -and
     ($jan -match '\$script:DiscoPreciso = \[double\]\$preciso'))
Checar "Janela: Test-PodeIniciar pergunta quando o disco nao comporta a fila" `
    (($jan -match '(?s)function Test-PodeIniciar.{0,4000}\$script:DiscoFalta -gt 0') -and
     ($jan -match 'falta espa' + [char]0x00E7 + 'o em disco'))
Checar "Janela: a pergunta vem com NAO pre-selecionado (regra da 16.12)" `
    ([bool]($jan -match '(?s)falta espa' + [char]0x00E7 + 'o em disco.{0,300}MessageBoxResult\]::No'))
Checar "Janela: ela AVISA, nao bloqueia (o usuario ainda pode comecar)" `
    ([bool]($jan -match '(?s)\$script:DiscoFalta -gt 0.{0,3000}MessageBoxResult\]::Yes'))
Checar "Janela: as duas respostas vao para o log (comecou ou desistiu)" `
    (($jan -match 'INICIO cancelado pelo usuario') -and ($jan -match 'INICIO mesmo faltando'))
Checar "Janela: sem falta de espaco, o Iniciar nao pergunta nada" `
    ([bool]($jan -match '(?s)function Test-PodeIniciar.{0,5000}\}\s*\r?\n\s*return \$true'))

foreach ($manual in @(@("COMO_USAR_PT.txt", "grande maioria"), @("HOW_TO_USE_EN.txt", "vast majority"))) {
    $pM = Join-Path $Fonte $manual[0]
    if (-not (Test-Path -LiteralPath $pM)) {
        Pular ("Manual $($manual[0])") "nao esta nesta pasta"
        continue
    }
    $tM = [System.IO.File]::ReadAllText($pM, [System.Text.Encoding]::UTF8)
    Checar ("$($manual[0]): sem a afirmacao sem base sobre a maioria dos Blu-rays") `
        (-not ($tM -match [regex]::Escape($manual[1])))
    Checar ("$($manual[0]): nao manda mais procurar outra ferramenta") `
        (-not ($tM -match 'DoVi_Scripts'))
    Checar ("$($manual[0]): usa o vocabulario da tela (Simple / Complex FEL)") `
        (($tM -match 'SIMPLE FEL') -and ($tM -match 'COMPLEX FEL'))
    Checar ("$($manual[0]): nao diz mais que o programa NAO separa os dois FEL") `
        (-not ($tM -match 'n' + [char]0x00E3 + 'o separa o FEL comum|cannot\s+separate ordinary FEL'))
    <#  3.1: o manual em ingles aponta o botao pelo nome que ele TEM em
        ingles (LEARN). Exigir "ENTENDA" nos dois obrigava o manual EN a
        citar um rotulo que o usuario dele nunca ve na tela. #>
    Checar ("$($manual[0]): aponta o botao Entenda/Learn para quem quiser o resto") `
        ([bool]($tM -match 'ENTENDA|LEARN'))
}

Titulo "23. IDIOMA PT / EN (16.92)"
<#  A traducao e uma CAMADA por cima, nunca a fonte: sem o arquivo, o
    programa continua em portugues, inteiro. Estes testes guardam essa
    propriedade e executam a carga da tabela de verdade. #>

Checar "Janela: o botao de idioma existe no XAML" `
    (($jan -match 'x:Name="btnIdioma"') -and ($jan -match 'x:Name="lblBandeira"'))
<#  3.13: o handler passou a guardar o alvo numa variavel, porque agora ele
    faz duas coisas - trocar e, so depois, oferecer o reinicio. O que este
    teste guarda continua sendo o mesmo: o botao existe, chama Set-Idioma, e
    o alvo e o OPOSTO da lingua atual (senao ele nao alterna, so vai). #>
Checar "Janela: o botao de idioma tem acao e alterna os dois" `
    (($jan -match '\$UI\.btnIdioma\.add_Click') -and
     ($jan -match '(?s)\$UI\.btnIdioma\.add_Click\(\{.{0,400}\$alvo = if \(\$script:Lang -eq "PT"\) \{ "EN" \} else \{ "PT" \}.{0,400}Set-Idioma \$alvo'))
Checar "Janela: a tabela vive FORA do .ps1 (traduzir nao e mexer em codigo)" `
    ([bool]($jan -match 'Join-Path \$script:PastaScript "IDIOMA_EN\.txt"'))
Checar "Janela: sem a tabela, o programa NAO troca e avisa (portugues nunca depende dela)" `
    ([bool]($jan -match '(?s)if \(-not \(Carregar-Idioma\)\).{0,600}return'))
Checar "Janela: existe o caminho de VOLTA (EN -> PT)" `
    (($jan -match '\$script:MapaPT\[\$en\] = \$pt') -and
     ($jan -match '\$mapa = if \(\$Novo -eq "EN"\) \{ \$script:MapaEN \} else \{ \$script:MapaPT \}'))
Checar "Janela: trocar de idioma redesenha o que e montado na hora" `
    (($jan -match '(?s)function Set-Idioma.{0,3000}Fill-Fila "idioma"') -and
     ($jan -match '(?s)function Set-Idioma.{0,3000}Update-Diagnostico'))
Checar "Janela: a varredura NAO mexe em caixa de texto (guarda caminho de pasta)" `
    (-not ($jan -match '(?s)function Traduzir-Arvore.{0,2500}System\.Windows\.Controls\.TextBox\]'))

$pIdi = Join-Path $Fonte "IDIOMA_EN.txt"
if (-not (Test-Path -LiteralPath $pIdi)) {
    Checar "IDIOMA_EN.txt existe ao lado do programa" $false "sem ele o botao de idioma nao tem o que aplicar"
} else {
    $bytesIdi = [System.IO.File]::ReadAllBytes($pIdi)
    Checar "IDIOMA_EN: tem BOM" `
        ($bytesIdi.Length -ge 3 -and $bytesIdi[0] -eq 0xEF -and $bytesIdi[1] -eq 0xBB -and $bytesIdi[2] -eq 0xBF)
    <#  EXECUTANDO: carrega a tabela de verdade e traduz, nos dois sentidos.
        Ler o fonte nao provaria que o arquivo esta bem formado - e o
        separador ser TAB e exatamente o tipo de detalhe que se perde numa
        edicao feita no Bloco de Notas. #>
    $fnCar = $astJan.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                               $args[0].Name -eq "Carregar-Idioma" }, $true)
    $fnTra = $astJan.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                               $args[0].Name -eq "Traduzir" }, $true)
    Checar "Janela: Carregar-Idioma e Traduzir podem ser extraidas e carregadas" `
        (($fnCar.Count -eq 1) -and ($fnTra.Count -eq 1))
    if ($fnCar.Count -eq 1 -and $fnTra.Count -eq 1) {
        . ([scriptblock]::Create($fnCar[0].Extent.Text))
        . ([scriptblock]::Create($fnTra[0].Extent.Text))
        $guardaPasta = $script:PastaScript
        $script:PastaScript = $Fonte
        $script:MapaEN = @{}; $script:MapaPT = @{}
        $carregou = Carregar-Idioma
        Checar "EXECUTANDO: a tabela carrega e tem pares dos dois lados" `
            ($carregou -and ($script:MapaEN.Count -ge 30) -and ($script:MapaPT.Count -eq $script:MapaEN.Count)) `
            ("pares: $($script:MapaEN.Count)")
        $script:Lang = "PT"
        Checar "EXECUTANDO: em portugues, o texto sai como esta escrito" `
            ((Traduzir "Iniciar F1") -eq "Iniciar F1")
        $script:Lang = "EN"
        Checar "EXECUTANDO: em ingles, o texto e traduzido" `
            ((Traduzir "Iniciar F1") -eq "Start F1")
        Checar "EXECUTANDO: frase sem traducao sai no original, nunca em branco" `
            ((Traduzir "Frase que nao existe na tabela") -eq "Frase que nao existe na tabela")
        Checar "EXECUTANDO: os cabecalhos das tabelas estao traduzidos" `
            (((Traduzir "VÍDEOS NA FILA") -ne "VÍDEOS NA FILA") -and
             ((Traduzir "LEGENDA PT-BR") -ne "LEGENDA PT-BR") -and
             ((Traduzir "SITUAÇÃO") -ne "SITUAÇÃO"))
        <#  Escrito errado na primeira vez: o pipe devolvia um array e o
            -notcontains ficava fora do parenteses do parametro, entao a
            funcao Checar recebia um Object[] onde espera um booleano. Quem
            pegou foi o teste 21 - a bateria olhando para si mesma. #>
        $faltando = @(@("Iniciar F1","Pausar F2","Cancelar ESC","Abrir Origem","Abrir Saída",
                        "Atualizar","Entenda","Ferramentas") |
                      Where-Object { -not $script:MapaEN.ContainsKey($_) })
        Checar "EXECUTANDO: os botoes da barra estao traduzidos" ($faltando.Count -eq 0) `
            ($faltando -join "; ")
        $script:Lang = "PT"
        $script:PastaScript = $guardaPasta
    }
}

Titulo "24. PROFILE 5 TEM RAMO PROPRIO (16.92)"
<#  A tela mandava o P5 para o mesmo ramo do Profile 7: a coluna dizia
    "5.0 -> 8.1" e a linha prometia "[SERA CONVERTIDO] Profile 8.1". O motor,
    no mesmo programa, ja dizia ha semanas que chegar a 8.1 a partir do P5
    RECODIFICA o video - e recodificar e o que este programa nao faz.
    A tela prometia o que o motor ia negar: a mesma familia do bug da
    legenda "MANTER" que fazia OCR assim mesmo. #>
Checar "Janela: Profile 5 tem ramo proprio na leitura" `
    ([bool]($jan -match '\} elseif \(\$dv\.Perfil -eq 5\) \{'))
<#  3.2 - ESTES DOIS TESTES INVERTERAM DE PROPOSITO (14.45 / 16.95).

    Ate a 16.94 o certo era o P5 NAO precisar de conversao: o motor nao fazia
    nada com ele, e marcar "precisa" seria a tela prometendo trabalho que
    ninguem ia fazer. Na 14.45 o motor passou a executar o remux para MP4 -
    entao agora o certo e o contrario, e o teste vira junto.
    O que NAO pode voltar, em nenhuma das duas epocas, e a tela dizer que o
    P5 vira 8.1. Isso continua proibido logo abaixo. #>
Checar "Janela: o P5 e marcado como 'precisa converter' (agora ha o que fazer)" `
    ([bool]($jan -match '(?s)\$dv\.Perfil -eq 5.{0,2600}\$d\.DVprecisa = \$true'))
Checar "Janela: a resposta do P5 diz o caminho que existe (MP4), nao o que nao existe" `
    (($jan -match 'SER' + [char]0x00C1 + ' REMUXADO\] Profile 5') -and
     ($jan -match 'o caminho dele ' + [char]0x00E9 + ' o MP4'))
<#  A janela de busca vai ATE o "} else {" que fecha o ramo do P5. Sem esse
    limite o teste lia o ramo do Profile 7 logo abaixo - que promete 8.1 com
    toda razao - e reprovava um codigo correto. Teste que reprova o certo e
    pior do que teste nenhum: ensina a ignorar o vermelho. #>
$ramoP5 = ""
$mP5 = [regex]::Match($jan, '(?s)\$dv\.Perfil -eq 5\).*?\} else \{')
if ($mP5.Success) { $ramoP5 = $mP5.Value }
Checar "Janela: o ramo do P5 foi isolado para conferencia" ($ramoP5 -ne "")
<#  E os COMENTARIOS saem antes de conferir. O bloco que explica o bug de
    16.92 cita "Profile 8.1" justamente para contar o que a tela dizia de
    errado - sem tirar o comentario, o teste reprovava a explicacao do
    conserto. O que vale aqui e o que a tela ESCREVE, nao o que o codigo
    conta sobre si. #>
$ramoP5Codigo = [regex]::Replace($ramoP5, '(?s)<#.*?#>', '')
Checar "Janela: a tela NUNCA promete que o P5 vira 8.1" `
    (($ramoP5 -ne "") -and (-not ($ramoP5Codigo -match 'Profile 8\.1')))
Checar "Janela: a coluna do P5 nao promete mais 8.1" `
    ([bool]($jan -match '\$d\.ColDV = "P5 ' + [char]0x2192 + ' MP4"'))
Checar "Motor: continua recusando P5 no ramo de MEL x FEL (as duas pontas concordam)" `
    ([bool]($mot -match 'Profile 5 nao tem Enhancement Layer'))

Titulo "24b. O MOTOR EXECUTA O P5 -> MP4 (14.45)"
<#  A 16.92 escreveu na tela "o caminho dele e o remux para MP4" e o motor
    nao tinha esse caminho. Ficou uma promessa por tres semanas.
    Agora existe: ramo proprio, uma passada de ffmpeg, video COPIADO.  #>

Checar "Motor: existe a funcao do caminho P5" `
    ([bool]($mot -match 'function Convert-Perfil5ParaMp4'))
Checar "Motor: existe a lista de codecs que cabem no MP4" `
    ([bool]($mot -match 'function Test-CodecCabeEmMp4'))
Checar "Motor: o P5 sai do laco por um ramo proprio, antes das 5 etapas" `
    ([bool]($mot -match '(?s)if \(\$infoDV\.Perfil -eq 5\) \{.{0,3000}Convert-Perfil5ParaMp4'))
Checar "Motor: o video e COPIADO - nada de recodificar" `
    ([bool]($mot -match '"-map", "0:v:0", "-c:v", "copy", "-tag:v", "dvh1"'))
Checar "Motor: a saida leva a tag dvh1 (sem ela o player nao ve Dolby Vision)" `
    ([bool]($mot -match '"-tag:v", "dvh1"'))
Checar "Motor: MP4 com faststart (comeca a tocar antes de baixar inteiro)" `
    ([bool]($mot -match '"-movflags", "\+faststart"'))
Checar "Motor: audio que nao cabe no MP4 vira E-AC-3 640k, nao derruba o arquivo" `
    ([bool]($mot -match '"-c:a", "eac3", "-b:a", "640k"'))
Checar "Motor: legenda de TEXTO vira mov_text" `
    ([bool]($mot -match '"-c:s", "mov_text"'))
Checar "Motor: legenda PGS e descartada COM AVISO (imagem nao existe em MP4)" `
    ([bool]($mot -match 'Legenda de Imagem Nao Tem Lugar no MP4'))
Checar "Motor: o .mp4 que ja existe na saida e pulado, nao refeito" `
    ([bool]($mot -match 'Ja Existe o \.mp4 na Pasta de Saida'))
Checar "Motor: saida do P5 conferida pela DURACAO, nao pelo tamanho" `
    (($mot -match 'o remux nao terminou') -and
     ($mot -match '\[math\]::Abs\(\$durSaida - \$DuracaoSegundos\) -gt 2\.0'))
Checar "Motor: MP4 que falhou e APAGADO (nao fica meia-saida na pasta)" `
    ([bool]($mot -match '(?s)Nao Foi Possivel Gerar o MP4.{0,300}Remove-Item -LiteralPath \$destinoMp4'))
Checar "Motor: a trava previa de disco nao cobra 3,15x de um P5" `
    ([bool]($mot -match '(?s)\$diretoPre = \(\$dvPre -and \(.{0,200}\$dvPre\.Perfil -eq 5\)\)'))

<#  EXECUTANDO: a regra de qual codec cabe no MP4. Errar aqui nao da erro
    bonito - da ffmpeg recusando o arquivo inteiro no fim do processo. #>
$fnMp4 = ([System.Management.Automation.Language.Parser]::ParseInput($mot, [ref]$null, [ref]$null)).FindAll(
    { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -eq "Test-CodecCabeEmMp4" }, $true)
if ($fnMp4.Count -eq 1) {
    . ([scriptblock]::Create($fnMp4[0].Extent.Text))
    foreach ($c in @("eac3","ac3","aac","mp3","alac","flac","opus")) {
        Checar ("EXECUTANDO: {0} cabe no MP4 (vai copiado)" -f $c) (Test-CodecCabeEmMp4 $c)
    }
    foreach ($c in @("truehd","dts","pcm_bluray","mlp")) {
        Checar ("EXECUTANDO: {0} NAO cabe no MP4 (tem que virar E-AC-3)" -f $c) (-not (Test-CodecCabeEmMp4 $c))
    }
} else {
    Checar "EXECUTANDO: Test-CodecCabeEmMp4 pode ser isolada e executada" $false
}

Titulo "24c. AS DUAS REGUAS, E QUAL DELAS FALOU (14.46 / 16.96)"
<#  Item de fila desde 04/09. A tentacao era usar o MaxCLL do container como
    regua de reserva quando o master nao e declarado - e isso e exatamente o
    erro que a licao 15 proibiu aqui: o L1 e MaxRGB, o MaxCLL do container e
    medido por HISTOGRAMA. Sao grandezas diferentes.

    Entao o que entrou nao foi uma segunda regua. Foi DIZER qual falou, e
    mostrar os numeros do container marcados como o que sao - contexto para
    decidir na mao, nunca resposta para "a EL levantava brilho?".

    Estes testes existem para impedir que uma revisao futura "melhore" isso
    passando a comparar as duas. #>

Checar "Motor: guarda QUAL regua respondeu" `
    ([bool]($mot -match 'ReguaUsada     = "nenhuma"'))
Checar "Motor: marca 'master' so quando o pico do master foi lido" `
    ([bool]($mot -match '(?s)\$brilhoCtx\.MasterMax -gt 0.{0,200}\$res\.ReguaUsada = "master"'))
Checar "Motor: guarda MaxCLL/MaxFALL do container como CONTEXTO" `
    (($mot -match '\$res\.CtnMaxCLL  = \[int\]\$brilhoCtx\.MaxCLL') -and
     ($mot -match 'nunca para comparar com o L1'))
Checar "Motor: o veredicto Expande continua saindo SO do master" `
    ([bool]($mot -match '(?s)if \(\$res\.MasterMax -gt 0 -and \$res\.MaxCLL -gt 0\) \{\s*\r?\n\s*\$res\.Expande = \(\[double\]\$res\.MaxCLL -ge \[double\]\$res\.MasterMax\)'))
Checar "Motor: o container NUNCA vira regua de reserva do Expande" `
    (-not ($mot -match '\$res\.Expande = .{0,80}CtnMaxCLL'))
Checar "Motor: sem regua, a frase traz o container marcado como outra regua" `
    (($mot -match 'outra regua \(histograma\)') -and
     ($mot -match 'nao com o L1 dele mesmo'))
Checar "Janela: recebe a regua e os numeros do container" `
    (($jan -match 'Regua = "\$\(\$el\.ReguaUsada\)"') -and ($jan -match '\$v\.ELctnMaxCLL = \[int\]\$m\.CtnMaxCLL'))
Checar "Janela: sem master, a linha diz que NAO HA REGUA (nao so 'nao declarado')" `
    ([bool]($jan -match 'o master n' + [char]0x00E3 + 'o ' + [char]0x00E9 + ' declarado, ent' + [char]0x00E3 + 'o n' + [char]0x00E3 + 'o h' + [char]0x00E1 + ' r' + [char]0x00E9 + 'gua'))
Checar "Janela: e mostra o container dizendo que e OUTRA regua" `
    ([bool]($jan -match 'por outra r' + [char]0x00E9 + 'gua \(histograma\)'))
Checar "Janela: a tela NUNCA escreve o container e o L1 como comparaveis" `
    (-not ($jan -match 'dentro dos \{1:N0\} do container'))
Checar "Idioma: as frases das duas reguas tem traducao" `
    ($(  $arqI = Join-Path $Fonte "IDIOMA_EN.txt"
         if (-not (Test-Path -LiteralPath $arqI)) { $false }
         else { $tI = Get-Content -Raw -LiteralPath $arqI
                ($tI -match 'there is no ruler') -and ($tI -match 'by a different ruler \(histogram\)') } ))

Titulo "24d. UMA AMOSTRA SO, E DO TAMANHO DO FILME (14.47 / 16.97)"
<#  A janela chamava Get-TipoCamadaDV com -Pontos 3 e o motor usava o padrao
    5. Mesmo arquivo, mesma pergunta, DUAS amostras - e portanto a
    possibilidade de duas respostas para o mesmo fato. O defeito que este
    projeto mais persegue, escondido num parametro que ninguem olhava.

    E 3 pontos, para o CENSO do L1, era pouco: lia 3 a 4 cenas de um filme
    inteiro. Tanto que a propria tela ja tinha tirado esse numero por nao
    significar nada. Para dizer MEL x FEL 3 bastam (o el_type nao muda ao
    longo do filme); para contar cenas acima do master, nao. #>

Checar "Motor: o tamanho da amostra mora numa funcao unica" `
    ([bool]($mot -match 'function Get-PontosDaAmostra'))
Checar "Motor: quem nao pede numero recebe o da duracao" `
    ([bool]($mot -match 'if \(\$Pontos -le 0\) \{ \$Pontos = Get-PontosDaAmostra -DuracaoSeg \$DuracaoSeg \}'))
<#  3.4: o comentario que EXPLICA o conserto cita "-Pontos 3" - e tem que
    citar, senao ninguem entende o que foi consertado. Entao o teste olha o
    CODIGO, sem os comentarios. Ja reprovei um codigo certo assim uma vez
    hoje; duas seria teimosia. #>
$janCodigo = [regex]::Replace($jan, '(?s)<#.*?#>', '')
$janCodigo = [regex]::Replace($janCodigo, '(?m)^\s*#.*$', '')
Checar "Janela: NAO pede mais um numero proprio de pontos" `
    (-not ($janCodigo -match 'Get-TipoCamadaDV.{0,120}-Pontos \d'))
Checar "Janela: continua passando a duracao (e ela que decide o tamanho)" `
    ([bool]($jan -match 'Get-TipoCamadaDV -MkvPath \$pe\.Path -DuracaoSeg'))
Checar "Motor: arquivo curto continua com um ponto so" `
    ([bool]($mot -match 'if \(\$DuracaoSeg -le 30\) \{ \$Pontos = 1 \}'))

<#  EXECUTANDO: a curva de tamanho da amostra. Ela tem que CRESCER com a
    duracao e ter teto - amostra que cresce sem limite transforma a leitura
    da pasta numa espera, que e o oposto do que ela existe para ser. #>
$fnPt = ([System.Management.Automation.Language.Parser]::ParseInput($mot, [ref]$null, [ref]$null)).FindAll(
    { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -eq "Get-PontosDaAmostra" }, $true)
if ($fnPt.Count -eq 1) {
    . ([scriptblock]::Create($fnPt[0].Extent.Text))
    Checar "EXECUTANDO: 20s (trecho de teste) -> 1 ponto" ((Get-PontosDaAmostra -DuracaoSeg 20) -eq 1)
    Checar "EXECUTANDO: 42 min (episodio) -> 5 pontos"     ((Get-PontosDaAmostra -DuracaoSeg 2520) -eq 5)
    Checar "EXECUTANDO: 1h56 (Ryan) -> 7 pontos"           ((Get-PontosDaAmostra -DuracaoSeg 6960) -eq 7)
    Checar "EXECUTANDO: 3h16 (Troy DC) -> 11 pontos"       ((Get-PontosDaAmostra -DuracaoSeg 11760) -eq 11)
    $antes = 0; $cresce = $true
    foreach ($d in @(20, 300, 900, 2520, 5000, 6960, 9000, 11760, 20000)) {
        $n = Get-PontosDaAmostra -DuracaoSeg $d
        if ($n -lt $antes) { $cresce = $false }
        $antes = $n
    }
    Checar "EXECUTANDO: a amostra nunca ENCOLHE quando o filme cresce" $cresce
    Checar "EXECUTANDO: e tem teto (leitura de pasta nao pode virar espera)" `
        ((Get-PontosDaAmostra -DuracaoSeg 100000) -le 12)
    Checar "EXECUTANDO: a amostra de hoje e MAIOR que os 3 pontos de antes" `
        ((Get-PontosDaAmostra -DuracaoSeg 6960) -gt 3)
} else {
    Checar "EXECUTANDO: Get-PontosDaAmostra pode ser isolada e executada" $false
}

Titulo "24e. 'AUDIO PRINCIPAL' SEGUNDO QUEM (16.98)"
<#  O rotulo dizia "AUDIO PRINCIPAL" e o usuario lia "a faixa que vai tocar".
    Nao e isso. A escolha aqui IGNORA de proposito a marca de padrao do
    arquivo, porque em remux Dual Audio essa marca costuma apontar a dublagem
    que o grupo escolheu, e o programa quer o TrueHD/Atmos.
    A regra esta certa. Errado era o nome - e o silencio sobre a divergencia,
    que e justamente quando o usuario se surpreende. #>

<#  3.15 - a linha do audio encolheu (17.06). A regra que ela guarda mudou
    de lugar, nao de conteudo: a divergencia de faixa padrao continua sendo
    detectada e continua sendo dita - so que no LOG, nao na tela.
    A ESQUERDA detecta, a DIREITA diz o que sera feito. #>
Checar "Janela: o rotulo do audio e curto, igual ao das linhas vizinhas" `
    ([bool]($jan -match ([char]0x00C1 + 'UDIO PRINCIPAL: \$rot \[DETECTADO\]')))
Checar "Janela: o parentese explicativo saiu do rotulo (era o que inchava)" `
    (-not ($jan -match ([char]0x00C1 + 'UDIO PRINCIPAL \(o que o programa converte\)')))
Checar "Janela: a justificativa NAO volta para a linha da tela" `
    (-not ($jan -match '\$d\.DiagAurot = "' + [char]0x00C1 + 'UDIO PRINCIPAL[^"]*pela marca'))
Checar "Janela: a divergencia de faixa padrao continua DETECTADA" `
    ([bool]($jan -match '\[int\]\$marcadaPadrao\.id -ne \[int\]\$pr\.id'))
Checar "Janela: e continua sendo dita - no log" `
    ([bool]($jan -match '(?s)\[int\]\$marcadaPadrao\.id -ne \[int\]\$pr\.id.{0,900}Avisar'))
<#  3.16 - o teste acima passou a exigir AVISAR, e nao Escrever-Log, por um
    motivo medido: a 17.06 escreveu a nota do audio com Escrever-Log DENTRO
    do runspace de leitura, onde as funcoes da janela nao existem. Cada
    arquivo morria com "O termo 'Escrever-Log' nao e reconhecido" e a fila
    inteira saiu como "Nao Foi Possivel Ler". A secao 13 pega isso de forma
    geral; este aqui pega no ponto exato. #>
Checar "Janela: a nota do audio usa a Avisar do runspace, NUNCA Escrever-Log" `
    (-not ($jan -match '(?s)\[int\]\$marcadaPadrao\.id -ne \[int\]\$pr\.id.{0,900}Escrever-Log'))
Checar "Janela: a linha do log diz o porque da escolha" `
    ([bool]($jan -match 'A escolha e pelo codec, nao pela marca'))
Checar "Janela: e nomeia as duas faixas, a escolhida e a marcada" `
    ([bool]($jan -match "escolhida a faixa \{1\}.{0,80}o arquivo marca a faixa \{3\}"))
Checar "Janela: nao le o arquivo de novo so para isso (usa o JSON ja lido)" `
    ([bool]($jan -match '\$marcadaPadrao = @\(@\(\$json\.tracks\)'))
Checar "Idioma: o rotulo curto do audio tem traducao" `
    ($(  $arqI2 = Join-Path $Fonte "IDIOMA_EN.txt"
         if (-not (Test-Path -LiteralPath $arqI2)) { $false }
         else { $tI2 = Get-Content -Raw -LiteralPath $arqI2
                ($tI2 -match 'MAIN AUDIO: ') } ))
Checar "Idioma: e a regra da frase antiga saiu junto (senao vira letra morta)" `
    ($(  $arqI2 = Join-Path $Fonte "IDIOMA_EN.txt"
         if (-not (Test-Path -LiteralPath $arqI2)) { $false }
         else { $tI2 = Get-Content -Raw -LiteralPath $arqI2
                -not ($tI2 -match 'the one the program converts') } ))

Titulo "24f. A LEGENDA PT-BR EM PGS - CONTRA LISTAS DE FAIXA REAIS (3.5)"
<#  A fila do projeto trazia, desde 08/08: "Find-PtBrPgsTrack tem falso
    negativo conhecido - Troy 2004 e Tomb Raider 2001, a faixa PGS em
    portugues EXISTE e a deteccao nao acha; so selecao manual encontra".

    Em 09/09 eu fui consertar isso e conferi antes (licao 7: medir a hipotese
    antes de implementa-la). A funcao ACERTA os dois. O defeito foi corrigido
    na v8.6 e a anotacao ficou para tras - eu quase reescrevi codigo certo em
    cima de um documento velho.

    A prova esta no MediaInfo do Troy convertido que o Diego mandou: a faixa
    29 ("Brazilian / PGS", pt-BR) foi encontrada, mantida, e o .SRT por OCR
    foi gerado ("Portugues (Brasil) [OCR]").

    Estes testes existem para que a funcao NAO possa regredir em silencio - e
    as listas de faixa abaixo sao as REAIS, tiradas do MediaInfo. Nao sao
    exemplo inventado. #>

$fnPgs = ([System.Management.Automation.Language.Parser]::ParseInput($mot, [ref]$null, [ref]$null)).FindAll(
    { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
      ($args[0].Name -eq "Find-PtBrPgsTrack" -or $args[0].Name -eq "Test-EhFaixaComentario") }, $true)
if ($fnPgs.Count -eq 2) {
    foreach ($f in $fnPgs) { . ([scriptblock]::Create($f.Extent.Text)) }
    $script:JsonPgsFalso = $null
    function Get-MkvJson { param($MkvPath) return $script:JsonPgsFalso }
    function Get-EscolhaManual { param($MkvPath) return $null }
    function FaixaLeg($id,$codec,$lang,$ietf,$nome) {
        [PSCustomObject]@{ id=$id; type="subtitles"; codec=$codec
            properties=[PSCustomObject]@{ language=$lang; language_ietf=$ietf; track_name=$nome; forced_track=$false } } }

    # Troy 2004 DC - as 21 faixas PGS reais, na ordem do arquivo
    $troyLeg = @(
      (FaixaLeg 6  "HDMV PGS" "eng" "en-US"   "PGS"),
      (FaixaLeg 8  "HDMV PGS" "eng" "en-US"   "SDH / PGS"),
      (FaixaLeg 9  "HDMV PGS" "eng" "en-US"   "SDH / Alternate / PGS"),
      (FaixaLeg 10 "HDMV PGS" "chi" "zh-Hant" "Traditional / PGS"),
      (FaixaLeg 12 "HDMV PGS" "dan" "da"      "PGS"),
      (FaixaLeg 14 "HDMV PGS" "nld" "nl"      "PGS"),
      (FaixaLeg 16 "HDMV PGS" "fin" "fi"      "PGS"),
      (FaixaLeg 18 "HDMV PGS" "fra" "fr-FR"   "Metropolitan / PGS"),
      (FaixaLeg 20 "HDMV PGS" "deu" "de"      "PGS"),
      (FaixaLeg 21 "HDMV PGS" "deu" "de"      "SDH / PGS"),
      (FaixaLeg 23 "HDMV PGS" "ita" "it"      "PGS"),
      (FaixaLeg 24 "HDMV PGS" "ita" "it"      "SDH / PGS"),
      (FaixaLeg 26 "HDMV PGS" "kor" "ko"      "PGS"),
      (FaixaLeg 28 "HDMV PGS" "nor" "no"      "PGS"),
      (FaixaLeg 29 "HDMV PGS" "por" "pt-BR"   "Brazilian / PGS"),
      (FaixaLeg 30 "HDMV PGS" "por" "pt-PT"   "European / PGS"),
      (FaixaLeg 32 "HDMV PGS" "spa" "es-ES"   "Castilian / PGS"),
      (FaixaLeg 34 "HDMV PGS" "spa" "es-419"  "Latin American / PGS"),
      (FaixaLeg 36 "HDMV PGS" "swe" "sv"      "PGS"))

    # Tomb Raider 2001 - as tres variantes de portugues no mesmo arquivo
    $tombLeg = @(
      (FaixaLeg 3 "HDMV PGS" "eng" "en"    "English"),
      (FaixaLeg 4 "HDMV PGS" "por" "pt-BR" "Brazilian"),
      (FaixaLeg 5 "HDMV PGS" "por" "pt-PT" "Iberian"),
      (FaixaLeg 6 "HDMV PGS" "por" "pt-BR" "Brazilian (Commentary)"))

    # A armadilha do The People vs Larry Flynt: pt-PT SEM NOME
    $flyntLeg = @(
      (FaixaLeg 3 "HDMV PGS" "eng" "en"    ""),
      (FaixaLeg 4 "HDMV PGS" "por" "pt-PT" ""))

    # Sem nome, mas o idioma resolve
    $soIdioma = @(
      (FaixaLeg 3 "HDMV PGS" "eng" "en" ""),
      (FaixaLeg 4 "HDMV PGS" "por" "pt" ""))

    $casosLeg = @(
      @{ N="Troy 2004 DC (19 PGS, pt-BR e pt-PT juntas)"; L=$troyLeg;  E=29 },
      @{ N="Tomb Raider 2001 (Brazilian x Iberian x Commentary)"; L=$tombLeg; E=4 },
      @{ N="pt-PT sem nome NAO pode virar a brasileira"; L=$flyntLeg; E=$null },
      @{ N="sem nome, mas o idioma resolve"; L=$soIdioma; E=4 })

    foreach ($c in $casosLeg) {
        $script:JsonPgsFalso = [PSCustomObject]@{ tracks = $c.L }
        $r = Find-PtBrPgsTrack -MkvPath "x.mkv"
        if ($null -eq $c.E) {
            Checar ("EXECUTANDO: {0} -> nao escolhe nenhuma" -f $c.N) ($null -eq $r)
        } else {
            Checar ("EXECUTANDO: {0} -> faixa {1}" -f $c.N, $c.E) ($r -and [int]$r.id -eq [int]$c.E)
        }
    }
    Checar "EXECUTANDO: a faixa de COMENTARIO nunca e a escolhida" `
        ($(  $script:JsonPgsFalso = [PSCustomObject]@{ tracks = $tombLeg }
             $rr = Find-PtBrPgsTrack -MkvPath "x.mkv"
             $rr -and ("$($rr.properties.track_name)" -notmatch "(?i)commentary") ))
} else {
    Checar "EXECUTANDO: Find-PtBrPgsTrack pode ser isolada e executada" $false
}

Titulo "24g. A ESTIMATIVA DE TEMPO SE CALIBRA SOZINHA (16.99)"
<#  Item de fila desde 03/09, e o de maior efeito visivel para o usuario: a
    estimativa do primeiro segundo erra e a barra da saltos.

      Troy         previsto 1697s   real 1091s   +56%
      Se7en        previsto  910s   real  655s   +39%
      Spider-Man   previsto 1200s   real 1121s    +7%

    Ja estava medido que trocar a constante NAO resolve (licao 7): a media
    melhora dois e faz o terceiro SUBESTIMAR 20%. Entao a constante deixou de
    ser constante - o programa grava o custo real de cada arquivo e a proxima
    estimativa usa o p75 das ultimas cinco rodadas.

    Estes testes existem por dois motivos: garantir que o historico sujo nao
    envenene a estimativa, e garantir que a escolha do p75 (em vez da mediana)
    nao seja "melhorada" de volta por alguem que so olhe o erro medio. #>

Checar "Janela: a constante virou valor de PARTIDA, nao verdade" `
    (($jan -match '\$script:SegPorGbPorPesoPadrao = 0\.0153') -and
     ($jan -match '\$script:SegPorGbPorPeso = 0\.0153'))
Checar "Janela: existem as quatro pecas da calibragem" `
    (($jan -match 'function Get-CaminhoCalibragem') -and ($jan -match 'function Get-Percentil') -and
     ($jan -match 'function Registrar-Calibragem') -and ($jan -match 'function Carregar-Calibragem'))
Checar "Janela: o historico e lido no arranque, DEPOIS que o log existe" `
    ([bool]($jan -match '(?s)Carregar-Calibragem\s*\r?\n\s*Escrever-Log \("Interface renderizada'))
Checar "Janela: o lote carrega Gb e SomaPesos (o que a calibragem precisa)" `
    ([bool]($jan -match 'SegEtapas = @\(\$segs\); Gb = \$gb; SomaPesos = \$soma'))
Checar "Janela: a medida fecha ao trocar de arquivo E no fim da fila" `
    ((@([regex]::Matches($jan, 'Fechar-MedidaDoVideo')).Count) -ge 3)
Checar "Janela: fila INTERROMPIDA nao vira calibragem" `
    ([bool]($jan -match 'Fechar-MedidaDoVideo -Concluido \(\$m\.Como -ne "interrompida"\)'))
Checar "Janela: a medida fecha ANTES de VideoIdx mudar (senao grava no nome errado)" `
    ($(  $mA = [regex]::Match($jan, '(?s)Fechar-MedidaDoVideo -Concluido \$true.{0,400}\$Motor\.VideoIdx = \$m\.Idx')
         $mA.Success ))
Checar "Janela: existem limites de sanidade nos dois lados" `
    (($jan -match '\$script:CalibMin = 0\.004') -and ($jan -match '\$script:CalibMax = 0\.060'))
Checar "Janela: usa p75, e o comentario diz por que nao e a mediana" `
    (($jan -match 'Get-Percentil \(\[double\[\]\]\$ult\) 0\.75') -and
     ($jan -match 'subestimar') -and ($jan -match 'erro medio 11,6%'))
Checar "Janela: avisa quando o espalhamento denuncia o modelo de pesos" `
    ([bool]($jan -match 'e o modelo de pesos descrevendo filmes diferentes'))
Checar "Janela: falha ao gravar a calibragem NAO derruba a conversao" `
    ([bool]($jan -match '(?s)AppendAllText.{0,400}\} catch \{'))
<#  16.99b: o defeito que eu mesmo plantei e achei na revisao. O T0Video ja e
    preenchido no INICIAR, antes de qualquer arquivo comecar - entao olhar so
    o relogio faria a funcao achar que o arquivo 0 terminou no primeiro
    anuncio da fila, e gravar 1,5s como tempo real dele. Os limites de
    sanidade recusariam o numero, mas a tela ganharia um aviso de calibragem
    recusada em TODA conversao. Ruido que aparece sempre e ruido que ninguem
    le mais - tambem e defeito. #>
Checar "Janela: existe o estado 'ha um arquivo em andamento'" `
    ([bool]($jan -match 'MedidaAberta = \$false'))
Checar "Janela: a medida so fecha se um arquivo tinha REALMENTE comecado" `
    ([bool]($jan -match '(?s)if \(\$Motor\.MedidaAberta -ne \$true\) \{ return \}'))
Checar "Janela: o Iniciar liga o relogio mas NAO abre medida" `
    ([bool]($jan -match '(?s)\$Motor\.T0Fila = \$agoraDt; \$Motor\.T0Video = \$agoraDt.{0,300}\$Motor\.MedidaAberta = \$false'))
Checar "Janela: quem abre a medida e o anuncio do arquivo" `
    ([bool]($jan -match '(?s)\$Motor\.T0Video = Get-Date.{0,300}\$Motor\.MedidaAberta = \$true'))
Checar "Janela: fila interrompida tambem FECHA o estado (nao fica aberto)" `
    ([bool]($jan -match 'if \(-not \$Concluido\) \{ \$Motor\.MedidaAberta = \$false'))

<#  EXECUTANDO: as funcoes de verdade, com os numeros REAIS dos tres filmes.
    Elas nao tocam na janela, entao podem ser isoladas e rodadas aqui. #>
$fnsCal = ([System.Management.Automation.Language.Parser]::ParseInput($jan, [ref]$null, [ref]$null)).FindAll(
    { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
      <#  17.02: Get-CaminhoCalibragem passou a chamar Get-PastaDados, que
          decide se a pasta do programa aceita escrita. Sem isolar as duas
          juntas, a funcao chamava um nome que nao existia neste escopo -
          erro que os Checar nao viam e a secao 21 pegou. #>
      $args[0].Name -in @("Get-PastaDados","Get-CaminhoCalibragem","Get-Percentil","Registrar-Calibragem","Carregar-Calibragem") }, $true)
if ($fnsCal.Count -eq 5) {
    $tmpCal = Join-Path ([System.IO.Path]::GetTempPath()) ("lafirma_cal_" + [guid]::NewGuid().ToString("N").Substring(0,8))
    [void][System.IO.Directory]::CreateDirectory($tmpCal)
    try {
        $guardaPastaCal = $script:PastaScript
        $script:PastaScript = $tmpCal
        $script:PastaDados  = $null   # 17.02: sem cache, a sonda decide de novo
        $script:SegPorGbPorPesoPadrao = 0.0153
        $script:SegPorGbPorPeso = 0.0153
        $script:CalibMin = 0.004; $script:CalibMax = 0.060
        $script:CalibArquivo = "CALIBRAGEM.txt"; $script:CalibUsadas = @()
        function Escrever-Log { param($Texto, $Tipo = "INFO") }   # silencia o log aqui
        foreach ($f in $fnsCal) { . ([scriptblock]::Create($f.Extent.Text)) }

        Carregar-Calibragem
        Checar "EXECUTANDO: sem historico, vale o numero de partida" ($script:SegPorGbPorPeso -eq 0.0153)

        # previsto = gb * soma * 0,0153  ->  soma = previsto / (gb * 0,0153)
        $filmesCal = @(
          @{ N="Troy";       Gb=87.00; Prev=1697.0; Real=1091.0 },
          @{ N="Se7en";      Gb=28.49; Prev=910.0;  Real=655.0  },
          @{ N="Spider-Man"; Gb=45.00; Prev=1200.0; Real=1121.0 })
        foreach ($f in $filmesCal) {
            $f.Soma = $f.Prev / ($f.Gb * 0.0153)
            Registrar-Calibragem -Gb $f.Gb -SomaPesos $f.Soma -SegReais $f.Real -Nome $f.N
        }
        Checar "EXECUTANDO: as tres rodadas foram gravadas" `
            ((@(Get-Content -LiteralPath (Join-Path $tmpCal "CALIBRAGEM.txt"))).Count -eq 3)

        Carregar-Calibragem
        $kNovo = $script:SegPorGbPorPeso
        Checar "EXECUTANDO: o p75 dos tres reais da 0,0127" `
            ([math]::Abs($kNovo - 0.01265) -lt 0.0002)
        Checar "EXECUTANDO: e ele e MENOR que o valor de partida (0,0153)" ($kNovo -lt 0.0153)

        # O ganho, arquivo por arquivo - e a regra de nao subestimar demais.
        $erroAntes = 0.0; $erroDepois = 0.0; $piorSub = 0.0
        foreach ($f in $filmesCal) {
            $pNovo = $f.Gb * $f.Soma * $kNovo
            $eA = [math]::Abs((($f.Prev - $f.Real) / $f.Real) * 100.0)
            $eD = (($pNovo - $f.Real) / $f.Real) * 100.0
            $erroAntes += $eA; $erroDepois += [math]::Abs($eD)
            if ($eD -lt $piorSub) { $piorSub = $eD }
        }
        Checar "EXECUTANDO: o erro medio CAI com a calibragem" (($erroDepois / 3) -lt ($erroAntes / 3))
        Checar "EXECUTANDO: e nenhum arquivo passa a subestimar mais de 15%" ($piorSub -gt -15.0)

        # Sujeira nao pode entrar.
        Registrar-Calibragem -Gb 80 -SomaPesos 1000 -SegReais 40 -Nome "cancelado no meio"
        Checar "EXECUTANDO: rodada absurda NAO e gravada" `
            ((@(Get-Content -LiteralPath (Join-Path $tmpCal "CALIBRAGEM.txt"))).Count -eq 3)
        Registrar-Calibragem -Gb 0 -SomaPesos 0 -SegReais 0 -Nome "sem dado"
        Checar "EXECUTANDO: rodada sem dado NAO e gravada" `
            ((@(Get-Content -LiteralPath (Join-Path $tmpCal "CALIBRAGEM.txt"))).Count -eq 3)

        # Historico ilegivel volta ao padrao em vez de quebrar.
        [System.IO.File]::WriteAllText((Join-Path $tmpCal "CALIBRAGEM.txt"), "lixo`r`nmais lixo`r`n")
        Carregar-Calibragem
        Checar "EXECUTANDO: historico corrompido volta ao valor de partida" ($script:SegPorGbPorPeso -eq 0.0153)

        # O percentil em si.
        Checar "EXECUTANDO: p75 de uma amostra so devolve ela mesma" `
            ((Get-Percentil ([double[]]@(0.01)) 0.75) -eq 0.01)
        Checar "EXECUTANDO: p50 de 1,2,3 e 2" ((Get-Percentil ([double[]]@(1.0,2.0,3.0)) 0.5) -eq 2.0)
        Checar "EXECUTANDO: p75 fica ACIMA da mediana (e a regra de nao subestimar)" `
            ((Get-Percentil ([double[]]@(1.0,2.0,10.0)) 0.75) -gt (Get-Percentil ([double[]]@(1.0,2.0,10.0)) 0.5))
    } finally {
        # Devolve o que foi emprestado: a bateria e um processo so, e secao
        # que deixa estado sujo estraga a proxima sem dar erro nenhum.
        if ($null -ne $guardaPastaCal) { $script:PastaScript = $guardaPastaCal }
        Remove-Item -LiteralPath $tmpCal -Recurse -Force -ErrorAction SilentlyContinue
    }
} else {
    Checar "EXECUTANDO: as funcoes de calibragem podem ser isoladas" $false
}

Titulo "30. OS EXCLUDES DO INSTALADOR X O QUE O CODIGO CHAMA (3.7)"
<#  RECONSTRUCAO de um teste que existia na bateria de 201 e se perdeu quando
    ela nao ficou guardada em lugar nenhum (registrado no STATUS_geral).

    Era o mais valioso da familia do instalador, e o motivo esta na historia:
    na limpeza de 297 MB, o "tools\DeeZy\apps\ffmpeg\" inteiro entrou nos
    Excludes ENQUANTO o motor ainda chamava o ffmpeg de dentro dele. Compilaria
    verde e o audio quebraria na maquina do usuario, longe daqui.

    A tecnica e o que importa: o teste NAO tem lista digitada a mao de "o que
    precisa entrar". Ele LE os .ps1, junta todo caminho sob tools\ que o codigo
    de fato usa, e cobra que nenhum deles esteja bloqueado. Lista digitada a
    mao envelhece calada; esta se atualiza sozinha quando o codigo muda.

    Vale reforcar a armadilha do Inno: Excludes e lista de BLOQUEIO, nao de
    permissao. Quem le rapido acha que esta declarando o que entra. #>

$pIss2 = ""
foreach ($cand in @((Join-Path (Split-Path -Parent $Fonte) "instalador\LaFirma_Setup.iss"),
                    (Join-Path (Split-Path -Parent $Fonte) "raiz\LaFirma_Setup.iss"),
                    (Join-Path (Split-Path -Parent $Fonte) "LaFirma_Setup.iss"),
                    (Join-Path $Fonte "LaFirma_Setup.iss"))) {
    if (Test-Path -LiteralPath $cand) { $pIss2 = $cand; break }
}
if ($pIss2 -eq "") {
    Pular "Instalador: os Excludes nao bloqueiam nada que o codigo chama" "LaFirma_Setup.iss nao esta ao lado desta pasta"
} else {
    $issTxt = [System.IO.File]::ReadAllText($pIss2, [System.Text.Encoding]::UTF8)

    # 1) O que o instalador BLOQUEIA, lido do proprio .iss.
    $blocos = @()
    foreach ($mE in [regex]::Matches($issTxt, 'Excludes:\s*"([^"]*)"')) {
        foreach ($e in ($mE.Groups[1].Value -split ',')) {
            $e = $e.Trim()
            if ($e -ne "") { $blocos += $e }
        }
    }
    Checar "Instalador: os Excludes foram lidos do .iss (nao digitados aqui)" ($blocos.Count -gt 0)

    # 2) O que o CODIGO chama debaixo de tools\, lido dos .ps1 de verdade.
    $usados = @()
    foreach ($arqPs in @("Converter_AUTO_DIRETO.ps1","LaFirma_JANELA.ps1","Corretor_Legenda.ps1","Reocr_Legenda.ps1")) {
        $cam = Join-Path $Fonte $arqPs
        if (-not (Test-Path -LiteralPath $cam)) { continue }
        $txtPs = Get-Content -Raw -LiteralPath $cam
        foreach ($mU in [regex]::Matches($txtPs, 'Join-Path\s+\$ToolsDir\s+"([^"]+)"')) {
            $usados += $mU.Groups[1].Value
        }
        foreach ($mU in [regex]::Matches($txtPs, 'Join-Path\s+\$script:ToolsDir\s+"([^"]+)"')) {
            $usados += $mU.Groups[1].Value
        }
    }
    $usados = @($usados | Sort-Object -Unique)
    Checar "Instalador: os caminhos usados foram lidos dos .ps1 (nao digitados aqui)" ($usados.Count -ge 10)

    <#  A comparacao. Um Exclude do Inno pode ser:
          "tools\DeeZy\apps\ffmpeg\*"   -> bloqueia a pasta inteira
          "tools\PgsToSrt\x86\*"        -> idem
        Entao um caminho usado esta bloqueado se ele COMECA com o prefixo do
        exclude (sem o *), ou se e exatamente igual a ele. #>
    $bloqueados = @()
    foreach ($u in $usados) {
        $alvo = ("tools\" + $u).ToLower().Replace("/", "\")
        foreach ($e in $blocos) {
            $pref = $e.ToLower().Replace("/", "\").TrimEnd('*')
            if ($pref -eq "") { continue }
            if (-not $pref.Contains("\")) { continue }   # exclude solto (ex: *.mkv) nao e caminho de tools
            if ($alvo -eq $pref.TrimEnd('\') -or $alvo.StartsWith($pref)) {
                $bloqueados += ("{0}  (bloqueado por '{1}')" -f $alvo, $e)
            }
        }
    }
    Checar ("Instalador: nenhum dos {0} caminhos de tools\ usados pelo codigo esta nos Excludes" -f $usados.Count) `
        ($bloqueados.Count -eq 0)
    if ($bloqueados.Count -gt 0) {
        foreach ($bq in $bloqueados) { Microsoft.PowerShell.Utility\Write-Host ("      -> " + $bq) -ForegroundColor Yellow }
    }

    <#  A prova de que o teste PEGA o defeito. Sem isto ele poderia estar
        comparando duas listas vazias e passando por vacuidade - que e
        exatamente o placebo que ja passou por aqui duas vezes (licao 10). #>
    $ffmpegUsado = @($usados | Where-Object { $_ -match '(?i)^ffmpeg\.exe$' })
    Checar "Instalador: o teste enxerga o ffmpeg.exe entre os caminhos usados" ($ffmpegUsado.Count -eq 1)
    $sabotagem = @("tools\ffmpeg.exe")
    $pegou = $false
    foreach ($u in $usados) {
        $alvo = ("tools\" + $u).ToLower()
        foreach ($e in $sabotagem) {
            $pref = $e.ToLower().TrimEnd('*')
            if ($alvo -eq $pref.TrimEnd('\') -or $alvo.StartsWith($pref)) { $pegou = $true }
        }
    }
    Checar "Instalador: SABOTAGEM - excluir o ffmpeg.exe seria reprovado" $pegou

    # E a regra que faz arquivo novo entrar sozinho continua valendo.
    Checar "Instalador: fonte\* continua recursivo (arquivo novo entra sozinho)" `
        ([bool]($issTxt -match 'Source: "fonte\\\*"[^\r\n]*recursesubdirs'))
    Checar "Instalador: o FAQ_EN.txt entra pelo fonte\* (nao precisa de linha propria)" `
        (Test-Path -LiteralPath (Join-Path $Fonte "FAQ_EN.txt"))
}

Titulo "23b. O QUE AINDA SAIA EM PORTUGUES NA TELA EM INGLES (17.01)"
<#  Print do Diego, 09/09 09:44, com a bandeira em EN. Ele perguntou "que
    lingua e essa?" olhando "VIDEOS IN QUEUE" - a frase esta certa, o que
    estava errado era a tela ser metade em cada lingua.

    O que ficava em portugues, e por que:

      Atualizar          o CODIGO reescreve este rotulo em dois pontos
                         (vira "Parar" na leitura e volta). A varredura da
                         arvore traduz UMA vez, quando a bandeira troca -
                         qualquer escrita depois desfaz em silencio.
      Modo: Automatico   o valor guardado nao tem acento, e a tabela tinha
                         "Modo: Automático". Nunca casava.
      titulo da janela   havia um SEGUNDO titulo ("... na Fila") que eu nao
                         tinha visto ao cobrir o primeiro ("... Selecionado(s)").
      painel de disco    quatro linhas montadas com numero dentro.
      Ja Convertido      ramo proprio da coluna SITUACAO, fora da traducao.
      DIAGNOSTICO - x    montado com o nome do arquivo.

    LICAO: rotulo que o codigo reescreve nao pode depender da varredura da
    arvore - tem que traduzir na hora em que e escrito. #>

Checar "Janela: o rotulo Atualizar/Parar traduz na HORA em que e escrito" `
    (($jan -match '\$UI\.lblReler\.Text = Traduzir "Parar"') -and
     ($jan -match '\$UI\.lblReler\.Text = Traduzir "Atualizar"'))
Checar "Janela: NENHUM titulo de janela escreve portugues direto" `
    ($(  $tit = @([regex]::Matches($janCodigo, '\$Janela\.Title = "\$NOME_APP[^"]*"'))
         $comPt = @($tit | Where-Object { $_.Value -match '(?i)convert|pausado|lendo|origem|cancelando|pronto' })
         $comPt.Count -eq 0 ))
Checar "Janela: o painel de espaco em disco passa pela traducao" `
    ([bool]($jan -match '(?s)\$UI\.txtDisco\.Text = \(\s*\r?\n\s*\(Traduzir-Frase'))
Checar "Janela: a frase da barra de disco passa pela traducao" `
    ([bool]($jan -match '\$msg = Traduzir-Frase \$\('))
Checar "Janela: o rotulo do ramo 'nao sera processado' passa pela traducao" `
    ([bool]($jan -match '\$rotulo = Traduzir-Frase \$\(switch'))
Checar "Janela: o titulo do diagnostico com o nome do arquivo traduz" `
    ([bool]($jan -match 'lblDiagTitulo\.Text = Traduzir-Frase'))
Checar "Janela: o Modo do video passa pelas regras (o valor nao tem acento)" `
    ([bool]($jan -match '\$UI\.txtModoVideo\.Text = Traduzir-Frase'))

<#  EXECUTANDO: as frases EXATAS do print, uma a uma. Se qualquer uma voltar
    a sair em portugues, este teste reprova antes de chegar na tela dele. #>
$fnsTrad = ([System.Management.Automation.Language.Parser]::ParseInput($jan, [ref]$null, [ref]$null)).FindAll(
    { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
      $args[0].Name -in @("Carregar-Idioma","Traduzir-Frase","Traduzir") }, $true)
if ($fnsTrad.Count -eq 3 -and (Test-Path -LiteralPath (Join-Path $Fonte "IDIOMA_EN.txt"))) {
    $guardaPastaT = $script:PastaScript
    try {
        $script:PastaScript = $Fonte
        $script:Lang = "EN"; $script:MapaEN = @{}; $script:MapaPT = @{}
        $script:RegrasEN = New-Object System.Collections.ArrayList
        foreach ($f in $fnsTrad) { . ([scriptblock]::Create($f.Extent.Text)) }
        [void](Carregar-Idioma)

        $doPrint = @(
          @{ Pt = "Atualizar";                                  En = "Refresh" },
          @{ Pt = "Parar";                                      En = "Stop" },
          @{ Pt = "Lendo a Pasta...";                           En = "Reading the Folder..." },
          @{ Pt = "Modo: Automatico";                           En = "Mode: Automatic" },
          @{ Pt = "Modo: Manual";                               En = "Mode: Manual" },
          @{ Pt = "Pronto para Converter - 2 Vídeo(s) na Fila"; En = "Ready to Convert - 2 Video(s) in Queue" },
          @{ Pt = "DIAGNÓSTICO - Troy.2004.mkv";                En = "DIAGNOSIS - Troy.2004.mkv" },
          @{ Pt = "Já Convertido";                              En = "Already Converted" },
          @{ Pt = "Falta Liberar              : 71,94 GB";      En = "Must Free Up               : 71,94 GB" },
          @{ Pt = "PAUSADO - 47% - Sem Consumir CPU/Disco";     En = "PAUSED - 47% - Not Using CPU/Disk" },
          @{ Pt = "Origem e Saída São a Mesma Pasta";           En = "Source and Output Are the Same Folder" })

        foreach ($c in $doPrint) {
            $r = Traduzir-Frase $c.Pt
            if ($r -eq $c.Pt) { $r = Traduzir $c.Pt }
            Checar ("EXECUTANDO EN: '{0}'" -f $c.Pt) ($r -eq $c.En)
        }

        <#  A ORDEM DAS REGRAS IMPORTA, e ja mordeu uma vez: a regra generica
            "...Convertido -> ...Converted" casava primeiro com "Já Convertido"
            e devolvia "Já Converted". A especifica tem que vir antes. #>
        Checar "EXECUTANDO EN: 'Já Convertido' nao vira o hibrido 'Já Converted'" `
            ((Traduzir-Frase "Já Convertido") -notmatch "Já")

        # E em portugues, NADA disso pode mudar.
        $script:Lang = "PT"
        $mudouPt = 0
        foreach ($c in $doPrint) { if ((Traduzir-Frase $c.Pt) -ne $c.Pt) { $mudouPt++ } }
        Checar "EXECUTANDO PT: nenhuma das frases do print e alterada" ($mudouPt -eq 0)
        $script:Lang = "EN"
    } finally {
        if ($null -ne $guardaPastaT) { $script:PastaScript = $guardaPastaT }
        $script:Lang = "PT"
    }
} else {
    Checar "EXECUTANDO: as funcoes de idioma e o IDIOMA_EN.txt estao disponiveis" $false
}

Titulo "25. A PERGUNTA DO DISCO DIZ O QUE ACONTECE COM ESTA FILA (16.93)"
<#  A 16.91 perguntava antes de comecar sem espaco, com a regra geral: "o
    motor vai converter o que couber e pular o que nao couber". Verdade, e
    inutil para decidir. O Diego comecou, viu um filme de 82 GB entrar em
    conversao e parou no meio achando que aquilo nunca terminaria.

    Ele estava certo em desconfiar e o programa estava certo em comecar: o
    Ryan CABIA sozinho (258 GB de pico contra 276 livres), quem nao cabia era
    o Troy, DEPOIS dele. A informacao existia e nao estava na tela. #>

Checar "Janela: a conta percorre a fila na ordem, como o motor decide" `
    (($jan -match '\$script:DiscoCabem') -and ($jan -match '\$script:DiscoNaoCabem') -and
     ($jan -match 'foreach \(\$v in \$ativos\) \{[\s\S]{0,200}\$precisaEste = \[double\]\$v\.Bytes \* \(Get-FatorDisco \$v\)'))
<#  3.2: o fator saiu de duas copias para uma funcao (16.95). O P5 forcou
    isso: a coluna dele tem seta e mesmo assim ele nao passa pelo dovi_tool. #>
Checar "Janela: o fator de disco mora numa funcao unica" `
    ([bool]($jan -match 'function Get-FatorDisco'))
Checar "Janela: o P5 nao paga 3,15x - ele nao passa pelo dovi_tool" `
    ([bool]($jan -match '(?s)function Get-FatorDisco.{0,900}if \(\$v\.P5 -eq \$true\) \{ return 1\.6 \}'))
Checar "Janela: as duas contas de disco usam a MESMA funcao" `
    ((@([regex]::Matches($jan, 'Get-FatorDisco \$v')).Count) -ge 2)
Checar "Janela: o que fica no disco depois e a SAIDA, nao o pico" `
    ([bool]($jan -match '\$sobrando = \$sobrando - \(Get-TamanhoEstimadoVideo \$v\)'))
Checar "Janela: guarda QUAL e o primeiro arquivo que fica de fora" `
    (($jan -match '\$script:DiscoPrimeiroFora') -and ($jan -match '\$script:DiscoFaltaNoPrimeiroFora'))
Checar "Janela: a pergunta mostra quantos cabem de quantos" `
    ([bool]($jan -match 'de \{1\} arquivo\(s\) cabem'))
Checar "Janela: a pergunta nomeia o primeiro que fica de fora e quanto falta" `
    (($jan -match 'primeiro que fica de fora') -and ($jan -match 'faltariam \{1\} na vez dele'))
Checar "Janela: nome longo e cortado (a caixa de mensagem nao rola)" `
    ([bool]($jan -match '\$nomeCurto\.Length -gt 60'))
Checar "Janela: continua dizendo que nada sai pela metade" `
    ([bool]($jan -match 'Nada sai pela metade'))

<#  EXECUTANDO: a mesma conta, com os numeros REAIS do log de 08/09 21:52.
    Se ela mudar e passar a discordar do motor, este teste reprova - e o
    motor e quem manda, porque e ele que recusa o arquivo na hora. #>
$simular = {
    param($livre, $arquivos)
    $cabem = 0; $naoCabem = 0; $primeiro = ""; $faltaPrim = 0.0
    $sobrando = [double]$livre
    foreach ($v in $arquivos) {
        $precisaEste = [double]$v.Bytes * 3.15
        if ($sobrando -ge $precisaEste) { $cabem++; $sobrando = $sobrando - [double]$v.Saida }
        else {
            $naoCabem++
            if ($primeiro -eq "") { $primeiro = $v.Nome; $faltaPrim = $precisaEste - $sobrando }
        }
    }
    return @{ Cabem = $cabem; NaoCabem = $naoCabem; Primeiro = $primeiro; Falta = $faltaPrim }
}
$r = & $simular 276.66GB @(
    [PSCustomObject]@{ Nome = "Ryan"; Bytes = 81.99GB; Saida = 76.39GB },
    [PSCustomObject]@{ Nome = "Troy"; Bytes = 87.00GB; Saida = 81.75GB })
Checar "EXECUTANDO: no caso real de 08/09, 1 de 2 cabe (foi o que o motor fez)" `
    (($r.Cabem -eq 1) -and ($r.NaoCabem -eq 1) -and ($r.Primeiro -eq "Troy"))
$r2 = & $simular 900GB @(
    [PSCustomObject]@{ Nome = "Ryan"; Bytes = 81.99GB; Saida = 76.39GB },
    [PSCustomObject]@{ Nome = "Troy"; Bytes = 87.00GB; Saida = 81.75GB })
Checar "EXECUTANDO: com disco sobrando, os dois cabem e ninguem fica de fora" `
    (($r2.Cabem -eq 2) -and ($r2.NaoCabem -eq 0) -and ($r2.Primeiro -eq ""))
$r3 = & $simular 10GB @([PSCustomObject]@{ Nome = "Ryan"; Bytes = 81.99GB; Saida = 76.39GB })
Checar "EXECUTANDO: sem espaco nenhum, nenhum cabe e o primeiro de fora e o unico" `
    (($r3.Cabem -eq 0) -and ($r3.Primeiro -eq "Ryan") -and ($r3.Falta -gt 0))

<#  17.02: a escolha deixou de ser gravada na pasta do script e passou a ir
    para a pasta de dados (Get-PastaDados). O teste segue o caminho novo -
    e continua exigindo o antigo na LEITURA, que e o que preserva a escolha
    de quem ja tinha o arquivo.  #>
Checar "Janela: a escolha de idioma fica guardada entre uma sessao e outra" `
    (($jan -match 'WriteAllText\(\(Join-Path \(Get-PastaDados\) "IDIOMA\.txt"\)') -and
     ($jan -match '(?s)Test-Path -LiteralPath \$arqPref.{0,300}Set-Idioma "EN"'))
Checar "Janela: preferencia ilegivel ou ausente abre em portugues, sem erro" `
    ([bool]($jan -match '(?s)\$arqPref = Get-CaminhoIdioma.{0,400}\} catch \{ \}'))

Titulo "26. O ARQUIVO QUE NAO CABE NEM COMECA (14.44)"
<#  Achado do Diego (08/09, ultimas fotos): "terminou o ryan mas começou o
    troy mesmo sabendo q nao ia ta espaço pra finalizar ele... isso tem q ser
    arrumado em q momento ele descobre isso?".

    O log prova que o motor SEMPRE recusou certo:
      [23:26:55] Convertendo 2/2: Troy...
      [23:27:15] Espaco Insuficiente ... Faltam ~72,67 GB. Pulando.
    Nada foi escrito errado. O defeito era de ORDEM: entre uma linha e outra
    passaram 20 segundos em que a tela dizia "Convertendo - Etapa 1/5" de um
    arquivo que nunca teve chance, e o diagnostico inteiro rodou a toa.

    A trava subiu para antes do anuncio. A trava antiga continua onde estava,
    como segunda linha de defesa - e por isso este teste exige AS DUAS.  #>

Checar "Motor: existe a trava previa, antes de abrir o bloco do arquivo" `
    ([bool]($motor -match '\$puloPorEspaco = \$false'))
Checar "Motor: a trava previa vem ANTES de criar a pasta temporaria" `
    ($motor.IndexOf('$puloPorEspaco = $false') -lt $motor.IndexOf('$WorkDir = Join-Path $f.DirectoryName') -and
     $motor.IndexOf('$puloPorEspaco = $false') -gt 0)
Checar "Motor: a trava previa vem ANTES do diagnostico (que custa ~20s)" `
    ($motor.IndexOf('$puloPorEspaco = $false') -lt $motor.IndexOf('O QUE FOI ENCONTRADO NESTE ARQUIVO') -and
     $motor.IndexOf('$puloPorEspaco = $false') -gt 0)
Checar "Motor: a trava previa usa o mesmo fator do resto (1,6x ou 3,15x)" `
    ([bool]($motor -match '(?s)\$fatorPre = if \(\$diretoPre\) \{ 1\.6 \} else \{ 3\.15 \}'))
Checar "Motor: quem nao cabe sai como PULADO, com o motivo escrito" `
    ([bool]($motor -match '(?s)\$puloPorEspaco = \$true'))
Checar "Motor: a tela diz que o arquivo NEM COMECOU (nao 'foi interrompido')" `
    ([bool]($motor -match 'NAO INICIADO'))
Checar "Motor: diz tambem que nenhuma pasta temporaria foi criada" `
    ([bool]($motor -match 'Nenhuma Pasta Temporaria Foi Criada'))
Checar "Motor: a trava ANTIGA continua viva, depois do diagnostico" `
    ($motor.IndexOf('para Converter Este Arquivo com Seguranca') -gt $motor.IndexOf('O QUE FOI ENCONTRADO NESTE ARQUIVO'))
Checar "Motor: sem conseguir medir o disco, a trava previa nao chuta - ela passa" `
    ([bool]($motor -match '(?s)\$livrePre = \$null.{0,400}if \(\$null -ne \$livrePre\)'))

<#  EXECUTANDO: a conta da trava previa, com os numeros reais do log de 08/09.
    Livre no C: no momento em que o Troy entrou = 276,66 GB menos o que o Ryan
    deixou gravado. O motor disse "faltam ~72,67 GB" - se esta conta deixar de
    dar isso, ela deixou de ser a mesma conta do motor.  #>
$travaPrevia = {
    param($livre, $bytes, $direto)
    $fator = if ($direto) { 1.6 } else { 3.15 }
    $precisa = [double]$bytes * $fator
    if ([double]$livre -lt $precisa) { return @{ Passa = $false; Falta = ($precisa - [double]$livre) } }
    return @{ Passa = $true; Falta = 0.0 }
}
$t1 = & $travaPrevia 201.4GB 87.0GB $false
Checar "EXECUTANDO: o Troy (87 GB, P7) e recusado e falta por volta de 72 GB" `
    ((-not $t1.Passa) -and ($t1.Falta -gt 70GB) -and ($t1.Falta -lt 76GB))
$t2 = & $travaPrevia 276.66GB 81.99GB $false
Checar "EXECUTANDO: o Ryan (82 GB, P7) passa - e passou mesmo, na vida real" `
    ($t2.Passa)
$t3 = & $travaPrevia 150GB 87.0GB $true
Checar "EXECUTANDO: o mesmo arquivo ja em 8.1 passa - so precisa de 1,6x" `
    ($t3.Passa)
$t4 = & $travaPrevia 150GB 87.0GB $false
Checar "EXECUTANDO: e o mesmo arquivo em P7, no mesmo disco, nao passa" `
    (-not $t4.Passa)

Titulo "27. UMA ESCALA DE COR SO, PARA TODA A TELA (16.94)"
<#  Achado do Diego (09/09): "vc ta se perdendo em todos lugares como sempre
    em padronizar ne?". A sigla [EL: FEL] do diagnostico ficava vermelha no
    Complex FEL e a coluna DOLBY VISION da MESMA linha ficava ambar - duas
    cores para o mesmo veredicto medido, porque a regra estava escrita dentro
    de uma funcao e copiada pela metade na outra.  #>

Checar "Janela: a escala mora numa funcao unica (Get-NomeCorEL)" `
    ([bool]($jan -match 'function Get-NomeCorEL'))
Checar "Janela: existem as duas saidas dela - cor de texto e chip" `
    (($jan -match 'function Get-CorEL') -and ($jan -match 'function Get-ChipEL'))
Checar "Janela: a sigla do diagnostico usa a funcao, nao uma regra propria" `
    (($jan -match '\$cor = Get-CorEL \$v') -and
     ($jan -notmatch '(?s)function Pintar-RotuloDV[\s\S]{0,900}\$nome = switch'))
Checar "Janela: a coluna DOLBY VISION usa a MESMA funcao" `
    (($jan -match '\$corDV      = if \(\$v\.ColDV -notmatch') -and ($jan -match 'else \{ Get-CorEL \$v \}'))
Checar "Janela: o chip da coluna tambem" `
    ([bool]($jan -match 'else \{ Get-ChipEL \$v \}'))
Checar "Janela: a escala tem as tres cores do vocabulario, e so elas" `
    (($jan -match '(?s)function Get-NomeCorEL[\s\S]{0,2600}"MEL"\s+\{ return "verde" \}') -and
     ($jan -match '(?s)function Get-NomeCorEL[\s\S]{0,2600}return "vermelho"') -and
     ($jan -match '(?s)function Get-NomeCorEL[\s\S]{0,2600}return "laranja"'))
Checar "Janela: NAO MEDIDO nao vira verde nem vermelho - vira ambar (duvida)" `
    ([bool]($jan -match '"NAO_MEDIDO" \{ return "ambar" \}'))

<#  EXECUTANDO: a funcao de verdade, com os tres filmes medidos aqui.  #>
$fnCor = ([System.Management.Automation.Language.Parser]::ParseInput($jan, [ref]$null, [ref]$null)).FindAll(
    { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -eq "Get-NomeCorEL" }, $true)
if ($fnCor.Count -eq 1) {
    . ([scriptblock]::Create($fnCor[0].Extent.Text))
    $casosCor = @(
        @{ T = "MEL";        E = $false; Cor = "verde";    Q = "Troy - MEL" },
        @{ T = "FEL";        E = $false; Cor = "laranja";  Q = "GoT S08E01 - Simple FEL" },
        @{ T = "FEL";        E = $true;  Cor = "vermelho"; Q = "Saving Private Ryan - Complex FEL" },
        @{ T = "MISTO";      E = $true;  Cor = "vermelho"; Q = "amostra mista, com expansao" },
        @{ T = "MISTO";      E = $false; Cor = "laranja";  Q = "amostra mista, sem expansao" },
        @{ T = "NAO_MEDIDO"; E = $null;  Cor = "ambar";    Q = "medicao interrompida" },
        @{ T = "MEDINDO";    E = $null;  Cor = "cinza";    Q = "ainda medindo" })
    foreach ($c in $casosCor) {
        $vv = [PSCustomObject]@{ ELtipo = $c.T; ELexpande = $c.E }
        Checar ("EXECUTANDO: {0} -> {1}" -f $c.Q, $c.Cor) ((Get-NomeCorEL $vv) -eq $c.Cor)
    }
} else {
    Checar "EXECUTANDO: Get-NomeCorEL pode ser isolada e executada" $false
}

Titulo "28. O TEXTO DO ENTENDA SEGUE A LINGUA ESCOLHIDA (16.94)"
<#  Achado do Diego (09/09): "se muda pra ingles no meio, o learn q muda mas o
    texto q abre nao". O rotulo do botao passava pela traducao; o conteudo
    nao. Clicar em "Learn" abria um texto inteiro em portugues.  #>

Checar "Existe o FAQ_EN.txt ao lado do FAQ_PT.txt" `
    (Test-Path -LiteralPath (Join-Path $Fonte "FAQ_EN.txt"))
Checar "Janela: o arquivo do FAQ e escolhido pela lingua ATUAL, no clique" `
    ([bool]($jan -match '(?s)\$ehEN   = \(\$script:Lang -eq "EN"\).{0,300}FAQ_EN\.txt'))
Checar "Janela: o titulo da janela do FAQ tambem muda de lingua" `
    ([bool]($jan -match 'Understand the Conversion'))
Checar "Janela: faltando o FAQ_EN, abre o PT avisando - nunca janela vazia" `
    ([bool]($jan -match '(?s)elseif \(\$ehEN -and \(Test-Path -LiteralPath \$arqPT\)\)'))

if (Test-Path -LiteralPath (Join-Path $Fonte "FAQ_EN.txt")) {
    $faqEn = Get-Content -Raw -LiteralPath (Join-Path $Fonte "FAQ_EN.txt")
    $faqPt = Get-Content -Raw -LiteralPath (Join-Path $Fonte "FAQ_PT.txt")
    Checar "FAQ_EN: tem as mesmas 14 secoes do portugues" `
        ((@([regex]::Matches($faqEn, '(?m)^ \d+\. ')).Count) -eq (@([regex]::Matches($faqPt, '(?m)^ \d+\. ')).Count))
    Checar "FAQ_EN: nao ficou pedaco em portugues no meio do ingles" `
        (($faqEn -notmatch 'camada de melhoria') -and ($faqEn -notmatch 'brilho') -and ($faqEn -notmatch 'arquivo final'))
    Checar "FAQ_EN: traz o vocabulario nas tres formas (MEL, Simple FEL, Complex FEL)" `
        (($faqEn -match 'MEL') -and ($faqEn -match 'SIMPLE FEL') -and ($faqEn -match 'COMPLEX FEL'))
    Checar "FAQ_EN: mantem a secao que diz que vermelho nao e estrago" `
        ([bool]($faqEn -match 'RED DOES NOT MEAN'))
    Checar "FAQ_EN: diz que DTS nao sai em Atmos (o erro que o Diego pegou no PT)" `
        ([bool]($faqEn -match '(?s)DTS.{0,400}NO Atmos'))
}

Titulo "29. O FAQ DIZ DE ONDE VEIO, E O CREDITO E LEGIVEL (16.94)"
<#  Pedido do Diego (09/09): os creditos estavam "tudo junto e minusculo",
    numa tabela de duas colunas que so funcionava em fonte fixa; e ele pediu
    um lugar onde o usuario possa conferir as fontes por conta propria.  #>

foreach ($par in @(@("FAQ_PT.txt","ONDE CONFERIR E APRENDER MAIS"), @("FAQ_EN.txt","WHERE TO CHECK AND LEARN MORE"))) {
    $arqF = Join-Path $Fonte $par[0]
    if (-not (Test-Path -LiteralPath $arqF)) { continue }
    $tx = Get-Content -Raw -LiteralPath $arqF
    Checar ("{0}: tem a secao 14 de fontes" -f $par[0]) ([bool]($tx -match [regex]::Escape($par[1])))
    Checar ("{0}: aponta o nosso repositorio" -f $par[0]) `
        ([bool]($tx -match 'github\.com/tkt2m7g87w-netizen/LaFirma-Remux-Forge'))
    Checar ("{0}: aponta o dovi_tool" -f $par[0]) ([bool]($tx -match 'github\.com/quietvoid/dovi_tool'))
    Checar ("{0}: aponta o suporte profissional da Dolby" -f $par[0]) `
        ([bool]($tx -match 'professionalsupport\.dolby\.com'))
    Checar ("{0}: aponta as duas planilhas da comunidade" -f $par[0]) `
        ((@([regex]::Matches($tx, 'docs\.google\.com/spreadsheets')).Count) -ge 2)
    Checar ("{0}: credito nao e mais tabela de duas colunas coladas" -f $par[0]) `
        ([bool]($tx -notmatch 'ffmpeg / ffprobe        '))
    Checar ("{0}: cada credito comeca em maiuscula, em linha propria" -f $par[0]) `
        ([bool]($tx -match '(?s)ffmpeg / ffprobe\r?\n   [A-Z]'))
    Checar ("{0}: diz que nenhum modo do dovi_tool recalcula o L1" -f $par[0]) `
        ([bool]($tx -match '(?i)(nenhum modo|no dovi_tool mode|none of its modes)'))
    Checar ("{0}: descreve o L5 como borda, na ordem esq/dir/topo/base" -f $par[0]) `
        ([bool]($tx -match '(?i)(esquerda, direita, topo,\s*\r?\n?\s*base|left, right, top, bottom)'))
}

Titulo "31. OS TRES DEFEITOS QUE O DIEGO ACHOU USANDO A 1.8 (17.02 / 14.48)"
<#  Ele instalou, usou e trouxe tres coisas: a escolha de idioma nao ficava
    guardada, o painel de disco voltava errado ao trocar de lingua, e a
    medicao ficou demorada. As tres tem conserto medido, e as tres tem
    teste aqui - senao voltam.  #>

# --- 1) A escolha de idioma tem que CHEGAR ao disco
Checar "Janela: existe uma funcao unica que decide ONDE gravar (Get-PastaDados)" `
    ([bool]($jan -match 'function Get-PastaDados'))
Checar "Janela: a pasta e testada com uma ESCRITA de verdade, nao pelo caminho" `
    ([bool]($jan -match '(?s)function Get-PastaDados.{0,1400}WriteAllText\(\$sonda'))
Checar "Janela: sem permissao, cai para %LOCALAPPDATA%" `
    ([bool]($jan -match '(?s)function Get-PastaDados.{0,1600}LOCALAPPDATA'))
Checar "Janela: o IDIOMA.txt e GRAVADO na pasta de dados, nao na do script" `
    ([bool]($jan -match 'WriteAllText\(\(Join-Path \(Get-PastaDados\) "IDIOMA\.txt"\)'))
Checar "Janela: falhar ao gravar o idioma NAO e mais silencio - vai para o log" `
    ([bool]($jan -match '(?s)WriteAllText\(\(Join-Path \(Get-PastaDados\) "IDIOMA\.txt"\).{0,400}Escrever-Log'))
Checar "Janela: a leitura olha os DOIS lugares (quem ja tinha nao perde)" `
    ([bool]($jan -match '(?s)function Get-CaminhoIdioma.{0,600}\$script:PastaScript "IDIOMA\.txt"'))
Checar "Janela: o arranque usa Get-CaminhoIdioma, nao o caminho fixo" `
    ([bool]($jan -match '\$arqPref = Get-CaminhoIdioma'))
Checar "Janela: a calibragem grava no MESMO lugar (tinha o mesmo defeito)" `
    ([bool]($jan -match 'Join-Path \(Get-PastaDados\) \$script:CalibArquivo'))

# --- 2) O painel de disco volta junto com a lingua
Checar "Janela: trocar de idioma REDESENHA o painel de disco" `
    ([bool]($jan -match '(?s)function Set-Idioma.{0,3000}Update-Disco'))
Checar "Janela: e continua redesenhando a fila e o diagnostico" `
    ([bool]($jan -match '(?s)function Set-Idioma.{0,3000}Fill-Fila "idioma".{0,900}Update-Diagnostico'))

# --- 3) A medicao so paga a amostra grande quando ela responde alguma coisa
Checar "Motor: sem regua do master, a amostra cai para tres pontos" `
    ([bool]($mot -match '(?s)\$res\.ReguaUsada -ne "master" -and \$Pontos -gt 3.{0,120}\$Pontos = 3'))
Checar "Motor: e o corte tambem corrige PontosPedidos (o log nao pode mentir)" `
    ([bool]($mot -match '(?s)\$Pontos = 3\s*\r?\n\s*\$res\.PontosPedidos = \$Pontos'))
Checar "Motor: COM regua, a amostra cheia continua valendo" `
    ([bool]($mot -match 'if \(\$Pontos -le 0\) \{ \$Pontos = Get-PontosDaAmostra'))
Checar "Motor: o tempo da medicao e MEDIDO, nao estimado" `
    ([bool]($mot -match 'SegundosMedindo') -and [bool]($mot -match '\$relogioMedida = \[System\.Diagnostics\.Stopwatch\]::StartNew\(\)'))
Checar "Motor: o relogio comeca ANTES do laco dos pontos" `
    ([bool]($mot -match '(?s)\$relogioMedida = \[System\.Diagnostics\.Stopwatch\]::StartNew\(\).{0,3000}for \(\$i = 0; \$i -lt \$Pontos'))
Checar "Motor: e o tempo e guardado no resultado, para ir ao log" `
    ([bool]($mot -match '\$res\.SegundosMedindo = \[math\]::Round\(\$relogioMedida'))
Checar "Motor: medir NUNCA derruba a conversao (o relogio tambem esta protegido)" `
    ([bool]($mot -match 'try \{ \$res\.SegundosMedindo'))

Titulo "32. O QUE A TELA ESCREVE, EM QUALQUER LINGUA (17.03 / 14.49)"
<#  Tres achados do Diego usando a 1.8 instalada:
    (a) "Perfil 7.6" - esse nome nao existe; o 06 do dvhe.07.06 e o NIVEL;
    (b) a coluna ACAO continuava MANTER/CONVERTER/EXCLUIR na tela em ingles;
    (c) os nomes das etapas vinham do motor e nunca passavam pela traducao.  #>

# --- (a) o nivel nao e nome de perfil
Checar "Motor: o nome do perfil NAO cola o nivel (nada de 'Profile 7.6')" `
    ([bool]($mot -match '\$nome = if \(\$perfil -eq 8\) \{ "Profile 8\.\$compat" \} else \{ "Profile \$perfil" \}'))
Checar "Motor: o Profile 8.1 continua com o ponto (ali o 1 e o compat id)" `
    ([bool]($mot -match '"Profile 8\.\$compat"'))
Checar "Motor: o nivel nao se perde - continua no campo Level" `
    ([bool]($mot -match 'Level   = \$level'))
Checar "Janela: a forma CURTA nao escreve o nivel" `
    ([bool]($jan -match '\$curto = "P\{0\}" -f \$Perfil'))
Checar "Janela: a forma LONGA nao escreve o nivel" `
    ([bool]($jan -match '\$longo = "Profile \{0\} \[\{1\}\] \[\{2\}\]" -f \$Perfil, \$cod, \$cam'))
Checar "Janela: o codec continua carregando o nivel (dvhe.07.06)" `
    ([bool]($jan -match 'dvhe\.\{0:D2\}\.\{1:D2\}" -f \$Perfil, \(\[int\]\$Level\)'))

if ($jan -match '(?s)(function Format-DolbyVision.*?\n\})') {
    $fnFmt = $Matches[1]
    try {
        $Cores = @{ dim2 = "#888888" }
        . ([scriptblock]::Create($fnFmt))
        $r7 = Format-DolbyVision -Perfil 7 -Level "6" -Codec "dvhe.07.06" -Camadas "BL+EL+RPU" -ELtipo "FEL"
        Checar "EXECUTANDO: Profile 7 FEL -> curto 'P7 FEL' (nao 'P7.6 FEL')" ($r7.Curto -eq "P7 FEL")
        # Sem -like aqui: em PowerShell os colchetes de "[dvhe...]" sao
        # curinga e o teste passaria/falharia por motivo errado.
        Checar "EXECUTANDO: e o longo diz 'Profile 7 [dvhe.07.06]'" `
            ($r7.Longo.StartsWith("Profile 7 [dvhe.07.06]"))
        Checar "EXECUTANDO: nenhuma das quatro formas contem '7.6'" `
            (-not (($r7.Codec + $r7.Curto + $r7.Faixa + $r7.Longo) -match '\bP?7\.6\b'))
        $r8 = Format-DolbyVision -Perfil 8 -Level "6" -Alvo
        Checar "EXECUTANDO: o alvo continua sendo 'P8.1' (o ponto ali e legitimo)" ($r8.Curto -eq "P8.1")
    } catch {
        Checar "EXECUTANDO: Format-DolbyVision pode ser isolada e executada" $false
    }
} else {
    Checar "EXECUTANDO: Format-DolbyVision pode ser isolada e executada" $false
}

# --- (b) o verbo da coluna ACAO
Checar "Janela: existe a tabela de verbos em ingles" `
    ([bool]($jan -match '\$script:VerbosEN = @\{'))
Checar "Janela: existe o caminho de ida (Get-VerboExibido)" `
    ([bool]($jan -match 'function Get-VerboExibido'))
Checar "Janela: e o de VOLTA (Get-VerboCanonico) - senao a escolha grava em ingles" `
    ([bool]($jan -match 'function Get-VerboCanonico'))
Checar "Janela: o dropdown mostra na lingua da tela" `
    ([bool]($jan -match '(?s)function Get-OpcoesVerbo.{0,400}Get-VerboExibido'))
Checar "Janela: quem le o clique converte para o valor canonico" `
    ([bool]($jan -match '\$novo = Get-VerboCanonico'))
Checar "Janela: a COR continua saindo do valor em portugues, nao do texto" `
    ([bool]($jan -match '\$corVerbo = if \(\$usaManual\) \{ \$Cores\.marca \} else \{ \(Cor-Verbo \$vb\) \}'))
Checar "Janela: os tres verbos EN tem DataTrigger proprio (senao a cor some)" `
    (([bool]($jan -match 'Value="KEEP"')) -and ([bool]($jan -match 'Value="CONVERT"')) -and ([bool]($jan -match 'Value="DROP"')))
Checar "Janela: os tres verbos PT continuam com DataTrigger" `
    (([bool]($jan -match 'Value="MANTER"')) -and ([bool]($jan -match 'Value="CONVERTER"')) -and ([bool]($jan -match 'Value="EXCLUIR"')))

if ($jan -match '(?s)(\$script:VerbosEN = @\{[^\r\n]*\})') {
    $tabVb = $Matches[1]
    . ([scriptblock]::Create($tabVb))
    if ($jan -match '(?s)(function Get-VerboExibido.*?\n\})') { . ([scriptblock]::Create($Matches[1])) }
    if ($jan -match '(?s)(function Get-VerboCanonico.*?\n\})') { . ([scriptblock]::Create($Matches[1])) }
    $script:Lang = "PT"
    Checar "EXECUTANDO PT: MANTER continua MANTER" ((Get-VerboExibido "MANTER") -eq "MANTER")
    $script:Lang = "EN"
    Checar "EXECUTANDO EN: MANTER -> KEEP"       ((Get-VerboExibido "MANTER") -eq "KEEP")
    Checar "EXECUTANDO EN: CONVERTER -> CONVERT" ((Get-VerboExibido "CONVERTER") -eq "CONVERT")
    Checar "EXECUTANDO EN: EXCLUIR -> DROP"      ((Get-VerboExibido "EXCLUIR") -eq "DROP")
    Checar "EXECUTANDO: KEEP volta a ser MANTER"      ((Get-VerboCanonico "KEEP") -eq "MANTER")
    Checar "EXECUTANDO: CONVERT volta a ser CONVERTER" ((Get-VerboCanonico "CONVERT") -eq "CONVERTER")
    Checar "EXECUTANDO: DROP volta a ser EXCLUIR"      ((Get-VerboCanonico "DROP") -eq "EXCLUIR")
    Checar "EXECUTANDO: o que ja esta em portugues passa intacto pela volta" `
        ((Get-VerboCanonico "MANTER") -eq "MANTER")
    $idaVolta = @("MANTER","CONVERTER","EXCLUIR") | ForEach-Object {
        (Get-VerboCanonico (Get-VerboExibido $_)) -eq $_ }
    Checar "EXECUTANDO: ida e volta fecham nos tres verbos" `
        (@($idaVolta) -notcontains $false)
    $script:Lang = "PT"
} else {
    Checar "EXECUTANDO: a tabela de verbos pode ser isolada" $false
}

# --- (c) os nomes das etapas e o resto da aba Faixas
Checar "Janela: o nome da etapa passa pela traducao (vem do motor, em PT)" `
    ([bool]($jan -match '\$nomeEtapa = "\$\(\$Sim\.Atual\) " \+ \(Traduzir-Frase \$Cfg\.Etapas\[\$iEt\]\)'))
Checar "Janela: a etapa PAUSADA tambem traduz" `
    ([bool]($jan -match 'Traduzir-Frase \$Cfg\.Etapas\[\$iP\]'))
Checar "Janela: a fase sem numero (diagnostico/limpeza) traduz" `
    ([bool]($jan -match 'Traduzir-Frase "\$\(\$d\.Fase\)"'))
Checar "Janela: 'Preparando o motor' traduz" `
    ([bool]($jan -match 'Traduzir-Frase "Preparando o motor\.\.\."'))
Checar "Janela: os cabecalhos de grupo da aba Faixas traduzem" `
    ([bool]($jan -match '(?s)function Add-CabecalhoGrupo.{0,300}\$Texto = Traduzir-Frase \$Texto'))
Checar "Janela: o rotulo PADRAO traduz" `
    ([bool]($jan -match 'Traduzir-Frase "PADRÃO"'))
Checar "Janela: Capitulos e Anexos traduzem" `
    (([bool]($jan -match 'Traduzir-Frase "Capítulos"')) -and ([bool]($jan -match 'Traduzir-Frase "Anexos"')))
Checar "Janela: o rodape do tamanho estimado traduz" `
    ([bool]($jan -match '\$UI\.txtRodapeTamanho\.Text = Traduzir-Frase'))
Checar "Janela: o detalhe do verbo traduz" `
    ([bool]($jan -match '\$det     = Traduzir-Frase \$det'))

$idi = ""
if (Test-Path -LiteralPath (Join-Path $Fonte "IDIOMA_EN.txt")) {
    $idi = Get-Content -Raw -LiteralPath (Join-Path $Fonte "IDIOMA_EN.txt")
}
foreach ($frase in @("VÍDEO","ÁUDIO","LEGENDAS","PADRÃO","Capítulos","Anexos",
                     "Extraindo Vídeo Puro do MKV (ffmpeg, Sem Recodificar)",
                     "Remontando MKV Final (mkvmerge)","Preparando o motor...")) {
    Checar ("Idioma: '{0}' tem traducao" -f $frase) ([bool]($idi -match [regex]::Escape($frase)))
}

# --- o aviso de reinicio ao trocar de idioma
Checar "Janela: trocar de idioma oferece reiniciar para completar" `
    ([bool]($jan -match '(?s)function Offer-ReinicioIdioma.{0,6000}Reiniciar o programa agora\?'))
Checar "Janela: com a fila RODANDO o reinicio nao e oferecido" `
    ([bool]($jan -match '(?s)function Offer-ReinicioIdioma.{0,6000}\$Estado\.Atual -in @\("rodando","pausado"\).{0,200}return'))
Checar "Janela: a pergunta vem com NAO pre-selecionado (regra da 16.12)" `
    ([bool]($jan -match '(?s)Reiniciar o programa agora\?.{0,900}"YesNo", "Question", "No"'))
Checar "Janela: a pergunta existe nas duas linguas" `
    ([bool]($jan -match 'Restart the program now\?'))
Checar "Janela: falhar ao reabrir NAO derruba o programa" `
    ([bool]($jan -match 'IDIOMA: nao consegui reabrir o programa'))

# --- os links do Entenda
Checar "Janela: o texto de LEITURA monta FlowDocument (link de verdade)" `
    ([bool]($jan -match 'New-Object System\.Windows\.Documents\.FlowDocument'))
Checar "Janela: os enderecos viram Hyperlink" `
    ([bool]($jan -match 'New-Object System\.Windows\.Documents\.Hyperlink'))
Checar "Janela: azul e sublinhado" `
    (([bool]($jan -match '\$lnk\.Foreground = \$azul')) -and ([bool]($jan -match 'TextDecorations\]::Underline')))
Checar "Janela: clicar abre no navegador" `
    ([bool]($jan -match '(?s)\$lnk\.add_Click.{0,300}Start-Process "\$\(\$s\.Tag\)"'))
Checar "Janela: o LOG continua no TextBox (la o que se quer e copiar)" `
    ([bool]($jan -match 'if \(\$DoTopo\) \{\s*\r?\n\s*try \{'))
Checar "Janela: falhar a montagem cai no texto simples, nunca em janela vazia" `
    ([bool]($jan -match 'FlowDocument falhou, usando o texto simples'))

if ($jan -match "(\`$reLink = \[regex\][^\r\n]+)") {
    . ([scriptblock]::Create($Matches[1]))
    Checar "EXECUTANDO: acha o endereco no meio da linha" `
        ((@($reLink.Matches("  Repositorio: https://github.com/x/y (o nosso)")).Count) -eq 1)
    Checar "EXECUTANDO: e nao engole o parentese que vem depois" `
        ($reLink.Matches("ver (https://a.com/b) aqui")[0].Value -eq "https://a.com/b")
    Checar "EXECUTANDO: linha sem endereco nao vira link" `
        ((@($reLink.Matches("texto qualquer sem endereco")).Count) -eq 0)
    Checar "EXECUTANDO: acha os dois enderecos de uma linha com dois" `
        ((@($reLink.Matches("a https://um.com b https://dois.com")).Count) -eq 2)
} else {
    Checar "EXECUTANDO: o regex de link pode ser isolado" $false
}

Titulo "33. A PERGUNTA DE REINICIO E DO CLIQUE, NUNCA DO ARRANQUE (17.04)"
<#  Defeito achado em uso na madrugada de 10/09, e ele nasceu na 17.03:
    a pergunta "reiniciar agora?" foi escrita DENTRO do Set-Idioma. So que
    o arranque tambem chama Set-Idioma, para aplicar o idioma guardado da
    sessao anterior. Entao quem tinha escolhido ingles abria o programa e
    era recebido pela pergunta - e responder Sim estourava:

      "Nao sera possivel definir Visibility nem chamar Show, ShowDialog ou
       WindowInteropHelper.EnsureHandle depois que uma Janela for fechada."

    Cinco sessoes do log de 01:26 terminam nessa linha. Estes testes nao
    guardam o sintoma: guardam a SEPARACAO que o resolve.  #>

Checar "Janela: existe Offer-ReinicioIdioma (a pergunta mora fora do Set-Idioma)" `
    ([bool]($jan -match 'function Offer-ReinicioIdioma'))

# O teste que importa: o Set-Idioma NAO pode mais conter a pergunta.
# Sem ele, um 'conserto' futuro que devolva o bloco para dentro do
# Set-Idioma passa despercebido e o defeito volta inteiro.
$corpoSetIdioma = ""
if ($jan -match '(?s)function Set-Idioma\(\[string\]\$Novo\) \{(.*?)\nfunction ') {
    $corpoSetIdioma = $Matches[1]
}
Checar "Janela: o corpo do Set-Idioma foi localizado" `
    ($corpoSetIdioma.Length -gt 500)
Checar "Janela: Set-Idioma NAO pergunta se quer reiniciar (era o defeito)" `
    (-not ($corpoSetIdioma -match 'Reiniciar o programa agora\?'))
Checar "Janela: Set-Idioma NAO fecha a janela" `
    (-not ($corpoSetIdioma -match '\$Janela\.Close\(\)'))
Checar "Janela: Set-Idioma NAO reabre o programa" `
    (-not ($corpoSetIdioma -match 'Start-Process'))

# Quem pergunta e o clique.
Checar "Janela: o clique no botao de idioma chama Offer-ReinicioIdioma" `
    ([bool]($jan -match '(?s)\$UI\.btnIdioma\.add_Click\(\{.{0,800}Offer-ReinicioIdioma'))
Checar "Janela: e so depois de o Set-Idioma ter trocado de verdade" `
    ([bool]($jan -match '(?s)Set-Idioma \$alvo.{0,400}\$script:Lang -eq \$alvo.{0,80}Offer-ReinicioIdioma'))

# E o arranque NAO pergunta.
$arranque = ""
if ($jan -match '(?s)(\$arqPref = Get-CaminhoIdioma.{0,900}?\n\} catch \{ \})') {
    $arranque = $Matches[1]
}
Checar "Janela: o bloco de arranque do idioma foi localizado" `
    ($arranque.Length -gt 100)
Checar "Janela: o arranque aplica o idioma guardado" `
    ([bool]($arranque -match 'Set-Idioma "EN"'))
Checar "Janela: o arranque NAO oferece reinicio (a causa do estouro)" `
    (-not ($arranque -match 'Offer-ReinicioIdioma'))

# Cinto e suspensorio: chamada cedo demais nao pode estourar.
Checar "Janela: Offer-ReinicioIdioma desiste se a janela ainda nao foi exibida" `
    ([bool]($jan -match '(?s)function Offer-ReinicioIdioma.{0,3000}-not \$Janela\.IsLoaded.{0,300}return'))
Checar "Janela: e diz no log por que nao ofereceu" `
    ([bool]($jan -match 'IDIOMA: janela ainda nao exibida - reinicio nao oferecido'))


Titulo "34. A TROCA AO VIVO ALCANCA A TELA INTEIRA (17.05)"
<#  Defeito visto nas fotos de 10/09: trocar de idioma ao vivo deixava a
    tela metade em cada lingua. Traduziam o titulo, a fila e as colunas;
    ficavam em portugues a barra de botoes, "Marcar Todos", os paineis
    DIAGNOSTICO e ESPACO EM DISCO, e a aba que nao estava selecionada.

    A causa: Traduzir-Arvore andava so no VisualTreeHelper, que contem
    apenas o que ja foi RENDERIZADO. Reiniciar "resolvia" porque a janela
    nasce montada de uma vez - a pergunta de reinicio era o remendo deste
    defeito.  #>

Checar "Janela: a varredura anda tambem na arvore LOGICA (nao so na visual)" `
    ([bool]($jan -match '(?s)function Traduzir-Arvore.{0,6000}\[System\.Windows\.LogicalTreeHelper\]::GetChildren'))
Checar "Janela: e continua andando na arvore visual" `
    ([bool]($jan -match '(?s)function Traduzir-Arvore.{0,6000}\[System\.Windows\.Media\.VisualTreeHelper\]::GetChildrenCount'))
Checar "Janela: nao visita o mesmo elemento duas vezes (as arvores se cruzam)" `
    ([bool]($jan -match '(?s)function Traduzir-Arvore.{0,4000}HashSet.{0,2000}-not \$vistos\.Add\(\$o\).{0,80}continue'))
Checar "Janela: alcanca o Content de ContentControl" `
    ([bool]($jan -match '(?s)function Traduzir-Arvore.{0,8000}\$o -is \[System\.Windows\.Controls\.ContentControl\]'))
Checar "Janela: alcanca os Items de ItemsControl ainda sem container" `
    ([bool]($jan -match '(?s)function Traduzir-Arvore.{0,8000}\$o -is \[System\.Windows\.Controls\.ItemsControl\]'))
Checar "Janela: a varredura DEVOLVE quantos rotulos trocou" `
    ([bool]($jan -match '(?s)function Traduzir-Arvore.{0,9000}return \$trocados'))
Checar "Janela: e o Set-Idioma guarda esse numero" `
    ([bool]($jan -match '\$trocados = Traduzir-Arvore \$Janela \$mapa'))
Checar "Janela: que vai para o LOG (sem ele, so foto da tela diz se pegou)" `
    ([bool]($jan -match 'rotulo\(s\) trocado\(s\) na tela'))
Checar "Janela: os tres tipos de rotulo continuam cobertos" `
    ((($jan -match '(?s)function Traduzir-Arvore.{0,4000}Controls\.TextBlock') -and
      ($jan -match '(?s)function Traduzir-Arvore.{0,4000}GridViewColumnHeader') -and
      ($jan -match '(?s)function Traduzir-Arvore.{0,4000}Controls\.TabItem')))
Checar "Janela: as colunas do GridView continuam trocadas fora da arvore" `
    ([bool]($jan -match '(?s)function Traduzir-Arvore.{0,9000}\$lst\.View\.Columns'))


Titulo "21. A PROPRIA BATERIA NAO PODE TER ERRO DE EXECUCAO (2.4)"
<#  Este teste olha para dentro: $Error junta todo erro nao-terminante que
    aconteceu enquanto a bateria rodava. Se ha um ali, alguma linha DESTE
    arquivo quebrou - e o resultado dos outros testes fica sob suspeita,
    porque nao da para saber o que deixou de rodar. #>
$errosMeus = @($Error | Where-Object { $null -ne $_ })
Checar "nenhum erro de execucao dentro da propria bateria" ($errosMeus.Count -eq 0) `
    ($(  if ($errosMeus.Count -eq 0) { "" }
         else {
            (@($errosMeus | Select-Object -First 3 | ForEach-Object {
                $li = ""
                if ($_.InvocationInfo -and $_.InvocationInfo.ScriptLineNumber) {
                    $li = "linha " + $_.InvocationInfo.ScriptLineNumber + ": "
                }
                $li + ($_.Exception.Message -replace "`r?`n", " ")
             }) -join " | ")
         }))

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Cyan
if ($script:ContaBateriaNao -eq 0) {
    Write-Host ("TUDO PASSOU - {0} teste(s)." -f $script:ContaBateriaOk) -ForegroundColor Green
    if ($script:ContaBateriaPulou -gt 0) {
        Write-Host ("({0} pulado(s) - ferramenta de desenvolvimento fora desta pasta)" -f $script:ContaBateriaPulou) -ForegroundColor DarkYellow
    }
} else {
    Write-Host ("{0} PASSARAM, {1} REPROVARAM, {2} PULADO(S) - nao entregue assim." -f $script:ContaBateriaOk, $script:ContaBateriaNao, $script:ContaBateriaPulou) -ForegroundColor Red
}
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host ""

<#  Grava o log. Se a pasta nao der para criar (permissao, disco), o teste NAO
    falha por causa disso - ele avisa e segue. O codigo de saida continua sendo
    o numero de reprovacoes, que e o contrato de quem chama a bateria. #>
try {
    $pastaLog = Join-Path $Fonte "_logs"
    if (-not (Test-Path -LiteralPath $pastaLog)) { New-Item -ItemType Directory -Path $pastaLog -Force | Out-Null }
    $arqLog = Join-Path $pastaLog ("LaFirma_teste_" + (Get-Date -Format "yyyy-MM-dd_HHmmss") + ".txt")
    $cab = @(
        "LaFirma - bateria de regressao v$Versao",
        ("Data  : " + (Get-Date -Format "dd/MM/yyyy HH:mm:ss")),
        ("Fonte : " + $Fonte),
        ("Maquina: " + $env:COMPUTERNAME + " | PowerShell " + $PSVersionTable.PSVersion),
        ("RESULTADO: " + $(if ($script:ContaBateriaNao -eq 0) { "TUDO PASSOU - $($script:ContaBateriaOk) teste(s)" } else { "$($script:ContaBateriaOk) passaram, $($script:ContaBateriaNao) REPROVARAM" })),
        "")
    [System.IO.File]::WriteAllLines($arqLog, ($cab + $script:LinhasLog), (New-Object System.Text.UTF8Encoding($true)))
    Microsoft.PowerShell.Utility\Write-Host ("Log desta bateria: " + $arqLog) -ForegroundColor DarkGray
    Microsoft.PowerShell.Utility\Write-Host ""
} catch {
    Microsoft.PowerShell.Utility\Write-Host ("[!] Nao consegui gravar o log: " + $_.Exception.Message) -ForegroundColor Yellow
}

exit $script:ContaBateriaNao
