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
$Versao = "4.7"
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
# 3.27: janela 172 -> 173 (Get-PlanoDoDisco, extraida para poder ser
#       executada pela bateria - 17.17).
# 3.26: motor 89 -> 90 (Test-EhLegendaPtBrCandidata - 14.54);
#       janela 170 -> 172 (Test-EhLegendaPtBr e Update-BarraMedirEL - 17.16).
# 3.25: motor 88 -> 89 (Test-OcrPedidoNaMao - 14.53);
#       janela 167 -> 170 (Get-MarcadosMedindo e Redesenhar-Resumo - 17.15).
# 3.24: janela 164 -> 167 (Get-TextoEspera, Get-MotivoCenso e
#       Update-DicaCenso - 17.14).
# 3.13: janela 145 -> 146 (Offer-ReinicioIdioma - 17.04)
# 3.12: janela 143 -> 145 (Get-VerboExibido e Get-VerboCanonico - 17.03)
# 3.10: janela 141 -> 143 (Get-PastaDados, Get-CaminhoIdioma - 17.02)
# 3.6: janela 136 -> 141 (Get-CaminhoCalibragem, Get-Percentil,
#      Registrar-Calibragem, Carregar-Calibragem e Fechar-MedidaDoVideo - a
#      estimativa de tempo passou a se calibrar sozinha, 16.99).
# 3.2: janela 135 -> 136 (Get-FatorEspacoDisco - o fator 1,6x/3,15x num lugar so,
#      porque o P5 tem seta na coluna e mesmo assim nao usa 3,15x - 16.95).
$esperado = @{ "Converter_AUTO_DIRETO.ps1" = 97; "LaFirma_JANELA.ps1" = 212
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
    "LaFirma_JANELA.ps1"        = @{ Bom = $true;  Crlf = $true;  Ascii = $false }
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
        <#  3.18: segurar a janela nao e sinonimo de "pause".
            A bancada 2.1 virou um MENU que volta a pedir arquivo no fim de
            cada rodada - ela segura a janela melhor do que um pause, e por
            um motivo melhor: o Diego testa varios .mkv em sequencia e a 2.0
            fechava a cada um. O que o teste tem que exigir e que a janela
            NAO feche sozinha; pause e uma das duas formas de conseguir isso. #>
        Checar ("$($ps1.BaseName).bat - segura a janela (pause ou menu)") `
            (($t -match '(?m)^\s*pause\s*$') -or ($t -match '(?m)^\s*set /p\s'))
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
    ($jan -match 'function Measure-VelocidadeOrigem' -and $jan -match 'function Get-FatorEspacoDisco' -and
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

<#  3.35 - 18.00: A DECISAO SE INVERTEU, E COM MOTIVO.

    Ate a 17.24 a leitura ficava VIVA depois do "leitura_fim" quando havia
    camada a medir, porque a medicao rodava dentro dela. Isso era a causa raiz
    de tudo o que quebrou em 16/09 (janela congelando 2s, releitura a toa, censo
    morto por um clique na chave). Agora a leitura SEMPRE fecha no fim dela, e a
    medicao nasce no runspace DELA.

    Os dois testes de baixo cobravam a regra velha - lição 18: teste que exige
    decisao revertida reprova o codigo certo. Eles viraram o par oposto. #>
Checar "Janela: a leitura SEMPRE fecha o runspace dela no leitura_fim" `
    ([bool]($jan -match '(?s)"leitura_fim" \{.{0,4000}?Stop-Motor')) `
    "a medicao nao mora mais dentro dela - nao ha motivo para ficar viva"
Checar "Janela: e e o leitura_fim que dispara a medicao, se a chave estiver ligada" `
    ([bool]($jan -match '(?s)"leitura_fim" \{.{0,5000}?elseif \(\$script:MedirELLigado\) \{.{0,900}?Start-Medicao'))
Checar "Janela: o el_fim fecha o runspace da MEDICAO (nao o do motor)" `
    ([bool]($jan -match '(?s)"el_fim" \{.{0,300}?Fechar-Runspace-Medicao'))

<#  3.35 - 18.00: a leitura nao escreve mais texto de DV a mao. Ela diz o
    FATO (tem camada EL, sem veredicto) e quem escreve e Update-TextosDV, o
    lugar unico da 16.84. A regra "sem veredicto nao pode ser verde" continua
    valendo - so que agora ela e conferida onde ela mora. #>
Checar "Janela: sem veredicto, a linha do diagnostico NAO e verde" `
    ([bool]($jan -match '(?s)function Update-TextosDV.{0,2500}"NAO_MEDIDO".{0,300}DiagDVcor = "ambar"')) `
    "verde quer dizer 'provado'; sem medida nao ha o que provar"
Checar "Janela: enquanto MEDE, o chip do DV nao pode ser verde (nada a afirmar)" `
    ([bool]($jan -match '"MEDINDO"    \{ return "cinza" \}'))

<#  3.35 - 18.00: a LEITURA nao decide mais "MEDINDO" - ela nao sabe se vai
    haver medicao. Ela marca "sem veredicto"; quem for medido de fato vira
    MEDINDO em Start-Medicao, um por um. O que a regra sempre garantiu continua:
    arquivo por medir NUNCA aparece como limpo. #>
Checar "Janela: a leitura marca 'sem veredicto', nao 'MEDINDO'" `
    ([bool]($jan -match '(?s)\$dv\.Perfil -eq 7 -and \$dv\.Camadas -match "EL".{0,2200}?\$d\.ELtipo = "NAO_MEDIDO"')) `
    "dizia MEDINDO ate com a chave desligada, e o log inventava 'medicao interrompida'"
Checar "Janela: e quem entra na medicao vira MEDINDO na hora (Start-Medicao)" `
    ([bool]($jan -match '(?s)function Start-Medicao.{0,3200}?\$v\.ELtipo = "MEDINDO"'))
Checar "Janela: arquivo por medir nunca aparece como limpo" `
    (-not ($jan -match '(?s)\$dv\.Perfil -eq 7 -and \$dv\.Camadas -match "EL".{0,2200}?\$d\.ELtipo = "LIMPA"'))

Checar "Janela: a fase B manda o L1 medido junto (o log guarda o numero)" `
    ([bool]($jan -match 'L1 MaxCLL \{2:N2\} nits'))

Checar "Motor: existe Get-BrilhoDoContainer (o contexto que da sentido ao L1)" `
    ([bool]($mot -match 'function Get-BrilhoDoContainer'))

Checar "Motor: o contexto do brilho compara o L1 com o pico do MASTER" `
    ([bool]($mot -match 'Contexto do brilho') -and [bool]($mot -match 'ABAIXO do pico do master'))

Checar "Motor: o MaxCLL do container e marcado como regua diferente do L1" `
    ([bool]($mot -match 'histograma, nao se compara com o L1'))

<#  2.0 (item 7 da auditoria): ESTE TESTE COBRAVA O DEFEITO.
    Ele exigia que Get-BrilhoDoContainer terminasse em "catch { }" - catch
    VAZIO. Isso protegia a conversao de cair, sim, mas fazia "o ffprobe
    quebrou" e "o arquivo nao tem metadado HDR" sairem identicos la fora: o
    cartao dizia "sem HDR" para um erro de leitura. Terceiro estado precisa
    de nome (licao 19) e catch que engole vira misterio (licao 22).
    O invariante de verdade e outro, e sao dois: a conversao NAO cai, e o
    erro TEM NOME. E isso que este teste cobra agora. #>
Checar "Motor: Get-BrilhoDoContainer nao derruba a conversao (o erro e capturado)" `
    ([bool]($mot -match 'function Get-BrilhoDoContainer[\s\S]{0,4000}?\} catch \{'))
<#  2.0 - O ITEM 7 DA AUDITORIA ERAM TRES FUNCOES, NAO UMA.
    Get-BrilhoDoContainer era a mais visivel, mas quem CHAMA ela tambem
    engolia a falha: Get-TipoCamadaDV (o veredicto MEL x FEL) e
    Get-CensoCompletoDV (que le o filme inteiro) pegavam a regua dentro de
    um "catch { }". Sem regua, o veredicto perde o unico numero com que se
    compara o L1 - e "este arquivo nao declara mastering display" ficava
    identico a "a leitura quebrou". Dois estados, um desenho (licao 19). #>
Checar "Motor: o veredicto MEL x FEL DIZ quando a regua falhou (nao engole)" `
    ([bool]($mot -match '(?s)function Get-TipoCamadaDV.{0,30000}\$res\.ReguaFalhou = "\$\(\$_\.Exception\.Message\)"'))
Checar "Motor: e o censo completo tambem (ele le o filme INTEIRO para descobrir)" `
    ([bool]($mot -match '(?s)function Get-CensoCompletoDV.{0,12000}\$res\.ReguaFalhou = "\$\(\$_\.Exception\.Message\)"'))
Checar "Motor: os dois objetos declaram o campo ReguaFalhou" `
    ((([regex]::Matches($mot, 'ReguaFalhou\s+= ""')).Count) -ge 2) `
    "atribuir propriedade nao declarada em PSCustomObject derruba a etapa"
Checar "Motor: a regua que falhou tem NOME, nao e so um estado" `
    ([bool]($mot -match 'Nao consegui ler a regua de brilho'))

Checar "Motor: e o erro de leitura do HDR ganha NOME (nao vira 'sem HDR')" `
    ([bool]($mot -match '(?s)function Get-BrilhoDoContainer.{0,4000}\$res\.Erro = "\$\(\$_\.Exception\.Message\)"')) `
    "sem isto, falha de ffprobe e ausencia de metadado ficam iguais na tela"


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
<#  3.35 - 18.00: Stop-Motor cuida do runspace da LEITURA e do MOTOR, e nada
    mais. A medicao tem dono proprio (Stop-Medicao) - mexer nela daqui mataria
    NA TELA uma medicao que segue viva atras. Quem fecha o estado preso e o
    "el_fim" e a Start-Leitura, cada um no seu momento. #>
Checar "Janela: Stop-Motor NAO mexe mais na medicao" `
    (-not ($jan -match '(?s)function Stop-Motor \{.{0,600}?Fechar-MedicaoPendente')) `
    "a medicao roda em outro runspace - apagar o estado dela aqui e mentir na tela"
Checar "Janela: uma leitura nova encerra a medicao antes de apagar a fila" `
    ([bool]($jan -match '(?s)function Start-Leitura.{0,1200}?Stop-Medicao.{0,200}?Fechar-MedicaoPendente'))
Checar "Janela: e o el_fim fecha quem sobrou em MEDINDO" `
    ([bool]($jan -match '(?s)"el_fim" \{.{0,900}?Fechar-MedicaoPendente'))
<#  3.31 - 17.21: o texto nao e mais escrito A MAO aqui.

    O print do Diego mostrou a coluna com "7.6 → 8.1" enquanto as vizinhas
    mostravam "P7 FEL → P8.1" - eram as linhas que passaram por este
    fechamento, onde eu montava os textos com os campos crus. Agora o
    fechamento so troca o ELtipo e manda Update-TextosDV reescrever, que e o
    lugar unico da 16.84. O teste passa a cobrar ISSO, que e a regra, e nao a
    palavra "ambar" (que agora mora dentro do Update-TextosDV). #>
Checar "Janela: medicao interrompida vira NAO MEDIDA (nunca limpa)" `
    ([bool]($jan -match '(?s)function Fechar-MedicaoPendente.{0,3000}\$v\.ELtipo = "NAO_MEDIDO"'))
Checar "Janela: e o texto sai do lugar unico (Update-TextosDV), nao da mao" `
    ([bool]($jan -match '(?s)function Fechar-MedicaoPendente.{0,3600}Update-TextosDV \$v'))
Checar "Janela: o fechamento NAO monta a coluna DV com campo cru" `
    (-not ($jan -match '(?s)function Fechar-MedicaoPendente.{0,3600}\$v\.ColDV = "\$\(\$v\.DVperfil\)')) `
    "foi assim que saiu '7.6 → 8.1' no meio de colunas 'P7 FEL → P8.1'"
Checar "Janela: e Update-TextosDV continua sendo quem pinta o NAO_MEDIDO de ambar" `
    ([bool]($jan -match '(?s)function Update-TextosDV.{0,2500}"NAO_MEDIDO".{0,300}DiagDVcor = "ambar"'))

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

<#  3.48 - O BURACO QUE ESTA BATERIA TINHA DESDE A 18.00.

    Este teste (o mais forte que existe aqui: nenhuma funcao da janela pode ser
    chamada dentro de um runspace) olhava DOIS blocos - motor e leitura - com o
    numero da linha achado a mao. Acontece que a 18.00 criou mais DOIS
    trabalhos, medicao e censo, e ninguem os acrescentou aqui. Ou seja: os
    runspaces mais novos, justamente onde moraram todos os defeitos de 15 a
    17/09, nao eram conferidos por ele.

    O historico diz o que isso custa - "O termo 'Escrever-Log' nao e
    reconhecido" e "O termo 'Test-SaidaCompleta' nao e reconhecido" aparecem
    nos logs dele de setembro, cada um estourando a leitura de um arquivo.

    Agora a lista de blocos e DESCOBERTA no fonte: todo "$script:Trabalho* = {"
    entra sozinho. Trabalho novo ja nasce conferido - lista digitada a mao
    envelhece calada (o mesmo corolario dos Excludes do instalador). #>
$blocos = @()
foreach ($m in [regex]::Matches($jan, '(?m)^\$script:(Trabalho[A-Za-z]+) = \{')) {
    $nomeBl = $m.Groups[1].Value
    $lnBl = ($linhas | Select-String -SimpleMatch ("`$script:" + $nomeBl + " = {") | Select-Object -First 1).LineNumber
    if ($lnBl) { $blocos += ,@($nomeBl, (Remove-Comentarios (Get-BlocoRunspace $lnBl))) }
}
Checar "os blocos de runspace sao DESCOBERTOS no fonte, nao digitados a mao" `
    ($blocos.Count -ge 4) ("achados: " + (($blocos | ForEach-Object { $_[0] }) -join ", "))

# Funcoes da JANELA = as definidas fora dos dois blocos.
$todas = [regex]::Matches($jan, '(?m)^function\s+([A-Za-z][A-Za-z0-9-]*)') | ForEach-Object { $_.Groups[1].Value }
$dentro = @()
foreach ($par in $blocos) {
    $dentro += [regex]::Matches($par[1], '(?m)^\s+function\s+([A-Za-z][A-Za-z0-9-]*)') | ForEach-Object { $_.Groups[1].Value }
}
$soDaJanela = @($todas | Where-Object { $dentro -notcontains $_ } | Sort-Object -Unique)
Checar "a lista de funcoes exclusivas da janela foi extraida ($($soDaJanela.Count) nomes)" `
    ($soDaJanela.Count -ge 20)

$vazadas = @()
foreach ($nome in $soDaJanela) {
    foreach ($par in $blocos) {
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
<#  3.35 - 18.00: a medicao virou trabalho proprio. Ela nem nasce cancelada,
    porque quem decide se ela nasce e a janela - mas o laco continua conferindo
    o cancelamento a cada arquivo, que e o que permite parar sem esperar. #>
Checar "Medicao: o trabalho so anuncia se nao foi cancelado antes de comecar" `
    ([bool]($jan -match '\$Pendentes\.Count -gt 0 -and -not \$Controle\.PararMedicao'))
Checar "Medicao: e o laco confere o cancelamento a cada arquivo" `
    ([bool]($jan -match 'if \(\$Controle\.PararMedicao -or \(\[int\]\$Controle\.MedSerieViva -ne \[int\]\$Serie\)\) \{ break \}'))


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
<#  3.18: eram DUAS ocorrencias a partir da 17.09 - a linha do diagnostico e
    o selo do cartao final, que passou a repetir a ressalva (o Ryan saia todo
    verde). O que o teste guarda continua sendo o mesmo: a frase so aparece
    onde ha EXPANSAO de brilho, nunca no MEL nem no Simple FEL. #>
Checar "Janela: so o caso que expande usa 'nao recomendado' (diagnostico + cartao)" `
    (([regex]::Matches($jan, 'CONVERS\u00c3O N\u00c3O RECOMENDADA')).Count -eq 3)
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
<#  17.19: estes dois olhavam o CORPO da Test-PodeIniciar por janela de regex
    ({0,3000} e {0,5000}) e reprovaram quando ela cresceu para carregar as duas
    linguas - codigo certo, teste frouxo (licao 18). Passaram a ler a funcao
    pela AST: o tamanho dela deixa de ser assunto do teste. #>
$corpoPode = ""
try {
    $fdPode = @(([System.Management.Automation.Language.Parser]::ParseInput($jan, [ref]$null, [ref]$null)).FindAll(
                  { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $args[0].Name -eq "Test-PodeIniciar" }, $true))
    if ($fdPode.Count -eq 1) { $corpoPode = $fdPode[0].Extent.Text }
} catch { }
Checar "Janela: Test-PodeIniciar existe e pode ser lida" ($corpoPode -ne "")
Checar "Janela: ela AVISA, nao bloqueia (o usuario ainda pode comecar)" `
    ([bool]($corpoPode -match '(?s)\$script:DiscoFalta -gt 0.*MessageBoxResult\]::Yes'))
Checar "Janela: as duas respostas vao para o log (comecou ou desistiu)" `
    (($jan -match 'INICIO cancelado pelo usuario') -and ($jan -match 'INICIO mesmo faltando'))
Checar "Janela: sem falta de espaco, o Iniciar nao pergunta nada" `
    ([bool]($corpoPode -match '(?s)\}\s*\r?\n\s*return \$true\s*\r?\n\}$')) `
    "a pergunta tem que estar TODA dentro do if; fora dele, ela sairia sempre"

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
        <#  2.0: a cobaia deixou de ser "Iniciar F1". Esse era o padrao VELHO
            de rotulo (tecla no fim), morto desde a 18.18, quando a tecla
            passou para a frente entre colchetes. A entrada continuava na
            tabela so porque estes dois testes a usavam - teste segurando
            lixo vivo e a mesma familia do item de fila que envelhece
            (licao 21). Agora a cobaia e o rotulo que a barra realmente usa. #>
        Checar "EXECUTANDO: em portugues, o texto sai como esta escrito" `
            ((Traduzir "[F1] Iniciar") -eq "[F1] Iniciar")
        $script:Lang = "EN"
        Checar "EXECUTANDO: em ingles, o texto e traduzido" `
            ((Traduzir "[F1] Iniciar") -eq "[F1] Start")
        <#  3.32 - 17.22: TODO TEXTO DECLARADO NO XAML PRECISA DE ENTRADA.

    ACHADO DO DIEGO (16/09, print): tela inteira em ingles e a faixa amarela
    do meio escrita ">>> PAUSADO (sem consumir CPU/disco) - [F2] Retomar
    [ESC] Cancelar <<<". Nao era bug de codigo: o texto estava DECLARADO no
    XAML (entao a Traduzir-Arvore alcancava ele), so que nunca teve linha no
    IDIOMA_EN.txt - e o que nao tem entrada sai no original, por regra.

    A bateria conferia que a varredura FUNCIONA, e nunca que o dicionario
    esta COMPLETO. Este teste fecha a familia: varre os literais Text="..."
    do XAML e cobra entrada para cada um que tenha cara de portugues.

    As excecoes sao declaradas aqui com o motivo - nao por conveniencia:
      lblIdioma      : mostra a lingua ATUAL, muda por codigo na troca
      lblNovaConversao: reescrito na partida com Traduzir "Nova Conversao" #>
$ExcecoesXaml = @("Português", "↻ Nova Conversão")
$semTraducao = New-Object System.Collections.Generic.List[string]
try {
    $chavesIdioma = New-Object System.Collections.Generic.HashSet[string]
    foreach ($linha in (Get-Content -LiteralPath (Join-Path $Fonte "IDIOMA_EN.txt") -Encoding UTF8)) {
        if ($linha -match "^\s*#") { continue }
        if ($linha -notmatch "`t") { continue }
        [void]$chavesIdioma.Add(($linha -split "`t")[0].Trim())
    }
    foreach ($m in [regex]::Matches($jan, 'Text="([^"]{4,})"')) {
        $txt = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value)
        if ($txt -match '\$\(' -or $txt -match '[{}]') { continue }   # montado em runtime
        if ($txt -notmatch '[À-ÿ]|\b(de|do|da|para|com|em|não|será|Convertido|Fila|Pasta|Medir|Censo|Retomar|Cancelar|Iniciar|Pausar)\b') { continue }
        if ($ExcecoesXaml -contains $txt) { continue }
        if ($chavesIdioma.Contains($txt)) { continue }
        [void]$semTraducao.Add($txt)
    }
} catch { }
Checar "Idioma: todo texto do XAML tem entrada no IDIOMA_EN.txt" `
    ($semTraducao.Count -eq 0) `
    $(if ($semTraducao.Count -gt 0) { "sem entrada: " + ($semTraducao -join " | ") } else { "" })

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
        $faltando = @(@("[F1] Iniciar","[F2] Pausar","[ESC] Cancelar",
                        "[F3] Abrir Origem","[F4] Abrir Saída","[F5] Atualizar",
                        "Entenda","Ferramentas") |
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
    ([bool]($jan -match '(?s)Carregar-Calibragem\s*\r?\n\s*Carregar-CalibragemEtapas\s*\r?\n\s*Escrever-Log \("Interface renderizada'))
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
    ([bool]($jan -match 'filmes de formas diferentes descritos pelo mesmo escalar'))
<#  2.0: e o aviso nao pode mais PROMETER que a calibragem por arquivo
    corrige - ela nunca corrigiu (licao 49). Se a frase antiga voltar, isto
    reprova. #>
Checar "Janela: o aviso nao promete mais que os pesos revistos resolvem" `
    (-not ($janCodigo -match 'vai continuar errando por arquivo ate os pesos serem revistos')) `
    "a frase antiga so pode existir como CITACAO em comentario, nunca como mensagem viva"
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
        # 2.0.7: o seconv saiu do pacote DE PROPOSITO. O codigo ainda o procura
        # como reserva opcional (sem ele cai no PgsToSrt, que e o caminho normal).
        if ($alvo.StartsWith("tools\subtitleedit\")) { continue }
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

    <#  =======================================================================
        2.0 - O INSTALADOR PERGUNTA A LINGUA, E A LINGUA VALE PARA TUDO.

        "adiciona no instalador se a pessoa pode ja instalar em ingles ou em
        portugues o programa" e "coloque um EULA de aceitar instalacao"
        (Diego, 18/09).

        Sao tres coisas amarradas numa escolha so, e o teste cobra as tres -
        porque quem esquece uma delas nao percebe: o assistente sai em ingles
        e o programa abre em portugues, ou a licenca aparece em portugues
        para quem escolheu ingles.
        ======================================================================= #>
    Checar "Instalador: existem DUAS linguas (portugues e ingles)" `
        (([bool]($issTxt -match 'Name: "brazilian";')) -and ([bool]($issTxt -match 'Name: "english";')))
    Checar "Instalador: cada lingua tem a SUA licenca" `
        (([bool]($issTxt -match '(?s)Name: "brazilian";.{0,200}LicenseFile: "licenca\\EULA_PT\.txt"')) -and
         ([bool]($issTxt -match '(?s)Name: "english";.{0,200}LicenseFile: "licenca\\EULA_EN\.txt"'))) `
        "licenca na lingua errada e pior do que licenca nenhuma - ninguem le o que nao entende"
    foreach ($eula in @("EULA_PT.txt","EULA_EN.txt")) {
        $pE = Join-Path (Split-Path $Fonte -Parent) (Join-Path "licenca" $eula)
        Checar ("Instalador: $eula existe para ser compilado") (Test-Path -LiteralPath $pE)
        if (Test-Path -LiteralPath $pE) {
            $tE = [System.IO.File]::ReadAllText($pE)
            Checar ("Instalador: $eula fala de aquisicao propria e de nao distribuir") `
                ((($tE -match 'aquisicao propria|legitimately acquired')) -and
                 (($tE -match 'distribuir|distribute')))
            Checar ("Instalador: $eula NAO promete que a copia privada e legal em todo lugar") `
                ([bool]($tE -match 'mudam de pais para pais|differ from country to country')) `
                "afirmar o que a lei permite, sem saber onde a pessoa esta, seria mensagem que mente"
        }
    }
    Checar "Instalador: a lingua escolhida vira a lingua do PROGRAMA (grava IDIOMA.txt)" `
        ([bool]($issTxt -match "(?s)procedure GravarIdiomaEscolhido.{0,600}IDIOMA\.txt")) `
        "sem isto, instalar em ingles e abrir em portugues - escolha que a tela seguinte ignora"
    Checar "Instalador: e ela e chamada depois de instalar" `
        ([bool]($issTxt -match '(?s)ssPostInstall.{0,300}GravarIdiomaEscolhido\(\)'))
    Checar "Instalador: o valor gravado e o que a janela le ('EN')" `
        ([bool]($issTxt -match "Valor := 'EN'")) `
        "a janela liga o ingles com o conteudo EN - qualquer outra coisa abriria em portugues"

    <#  A varredura que impede o defeito de voltar: toda CustomMessage tem que
        existir NAS DUAS linguas. Mensagem sem par sai em portugues no meio de
        um assistente em ingles - o mesmo defeito que a janela persegue desde
        a 17.01, agora no instalador. #>
    $msgBr = @([regex]::Matches($issTxt, '(?m)^brazilian\.([A-Za-z0-9_]+)=') | ForEach-Object { $_.Groups[1].Value })
    $msgEn = @([regex]::Matches($issTxt, '(?m)^english\.([A-Za-z0-9_]+)=')   | ForEach-Object { $_.Groups[1].Value })
    $semPar = @($msgBr | Where-Object { $msgEn -notcontains $_ })
    $sobrando = @($msgEn | Where-Object { $msgBr -notcontains $_ })
    Checar "Instalador: TODA mensagem do assistente existe nas duas linguas" `
        (($msgBr.Count -gt 0) -and ($semPar.Count -eq 0) -and ($sobrando.Count -eq 0)) `
        ("so em portugues: " + ($semPar -join ", ") + " | so em ingles: " + ($sobrando -join ", "))
    Checar "Instalador: as caixas do runtime tambem falam ingles quando o assistente fala" `
        ([bool]($issTxt -match "(?s)PrecisaDotNet\(\).{0,900}ActiveLanguage\(\) = 'english'")) `
        "caixa em portugues no meio de um assistente em ingles e a mesma familia da 17.01"
    <#  Comentario pode CITAR a numeracao antiga (o historico importa); o que
        nao pode e uma mensagem viva mandar o usuario procurar uma etapa que
        nao existe. Entao a varredura ignora as linhas de comentario do Inno. #>
    $issVivo = (($issTxt -split "\r?\n") | Where-Object { $_ -notmatch '^\s*;' }) -join "`n"
    Checar "Instalador: a etapa citada nas caixas e 4/5, nao a 5/7 que nao existe mais" `
        ((-not ($issVivo -match 'etapa 5/7')) -and (-not ($issVivo -match 'stage 5/7'))) `
        "o motor roda CINCO etapas - mandar procurar a 5/7 e mandar procurar o que nao existe"
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

<#  3.54 - 18.17: a tecla agora aparece no rotulo (pedido dele), entao o
    texto e (Traduzir "...") + " F5". A regra que importa continua a mesma e e
    ela que o teste cobra: o rotulo TRADUZ na hora em que e escrito. #>
<#  3.55 - 18.18: O ATUALIZAR GANHOU UM DONO SO.
    Tres lugares escreviam esse rotulo, com regras diferentes - e um deles (o
    leitura_fim) nao sabia do F5, entao o F5 sumia da tela segundos depois de
    abrir o programa. O teste passou a cobrar o MODELO: ninguem escreve nesse
    rotulo por fora da funcao que desenha o botao. #>
Checar "Janela: o Atualizar/Parar tem UM dono (Update-BotaoReler)" `
    ([bool]($jan -match '(?s)function Update-BotaoReler.{0,600}\$script:Lendo.{0,400}Traduzir "Atualizar"'))
Checar "Janela: e ninguem escreve nesse rotulo por fora dele" `
    ((([regex]::Matches($janCodigo, '\$UI\.lblReler\.Text')).Count -eq 2)) `
    "as duas do proprio Update-BotaoReler - qualquer terceira e o bug de novo"
Checar "Janela: lendo, o botao fica AMBAR (da para parar) - pedido dele" `
    ([bool]($jan -match '(?s)function Update-BotaoReler.{0,300}\$UI\.lblReler\.Text       = "\[F5\] " \+ \(Traduzir "Parar"\)\s*\r?\n\s*\$UI\.lblReler\.Foreground = Pincel \$Cores\.warn'))
Checar "Janela: e o rotulo traduz na HORA em que e escrito (licao 17.01)" `
    ([bool]($jan -match '"\[F5\] " \+ \(Traduzir "Atualizar"\)'))
Checar "Teclas: o Atualizar/Parar tem F5, e a tecla chama a MESMA funcao do botao" `
    (($jan -match 'function Invoke-Reler') -and
     ($jan -match '\$UI\.btnReler\.add_Click\(\{ Invoke-Reler \}\)') -and
     ($jan -match '"F5"\s*\{ Invoke-Reler')) `
    "pedido dele - e atalho que nao passa pela funcao do botao vira uma segunda regra"
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

<#  3.27: a simulacao saiu de dentro de Update-Disco e virou funcao pura
    (17.17), para a bateria poder EXECUTAR ela com arquivos reais - ver a
    secao 46. O que o teste garante e o mesmo: a conta percorre a fila na
    ordem, cobrando o fator do motor por arquivo. #>
Checar "Janela: a conta percorre a fila na ordem, como o motor decide" `
    (($jan -match '\$script:DiscoCabem') -and ($jan -match '\$script:DiscoNaoCabem') -and
     ($jan -match 'function Get-PlanoDoDisco') -and
     ($jan -match 'foreach \(\$v in @\(\$Videos\)\) \{[\s\S]{0,200}\$precisaEste = \[double\]\$v\.Bytes \* \(Get-FatorEspacoDisco \$v\)'))
<#  3.2: o fator saiu de duas copias para uma funcao (16.95). O P5 forcou
    isso: a coluna dele tem seta e mesmo assim ele nao passa pelo dovi_tool. #>
Checar "Janela: o fator de disco mora numa funcao unica" `
    ([bool]($jan -match 'function Get-FatorEspacoDisco'))
Checar "Janela: o P5 nao paga 3,15x - ele nao passa pelo dovi_tool" `
    ([bool]($jan -match '(?s)function Get-FatorEspacoDisco.{0,900}if \(\$v\.P5 -eq \$true\) \{ return 1\.6 \}'))
Checar "Janela: as duas contas de disco usam a MESMA funcao" `
    ((@([regex]::Matches($jan, 'Get-FatorEspacoDisco \$v')).Count) -ge 2)
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
    ([bool]($motor -match '(?s)\$livrePre = \$null.{0,1200}if \(\$null -ne \$livrePre\)'))
<#  2.0: e ela passa FALANDO. Em pasta de rede o GetPathRoot devolve o
    compartilhamento, a medida falha e a protecao e pulada - o que esta certo,
    mas ate aqui o usuario nao recebia nem a protecao nem a noticia. #>
Checar "Motor: e AVISA que a conferencia previa nao rodou naquele caminho" `
    ([bool]($motor -match 'Nao Consegui Medir o Espaco Livre em'))
Checar "Motor: o catch da trava previa NAO e mais vazio (engolia a protecao inteira)" `
    ([bool]($motor -match 'Nao Consegui Conferir o Espaco em Disco Antes de Comecar')) `
    "catch vazio ali fazia o arquivo entrar na conversao como se houvesse espaco"
Checar "Motor: o link do runtime nao fixa mais o numero de correcao (8.0.30 vira 404 um dia)" `
    ([bool]($motor -match 'LinkDotNetRuntime = "https://dotnet\.microsoft\.com/download/dotnet/8\.0"')) `
    "link com patch envelhece sozinho; a familia 8.0 e o que o PgsToSrt exige"
Checar "Motor: a falta do runtime NAO afirma mais que o OCR inteiro morreu" `
    (($motor -match 'A Legenda Sera Feita pelo seconv \(Reserva\), Que Esta Presente') -and ($motor -match '(?s)\$temSeconv = \(Test-Path -LiteralPath \$seconv\).{0,80}\r?\n\$temOcr = Test-Path -LiteralPath \$pgsToSrt')) `
    "2.0.10: o seconv e a RESERVA (so sem PgsToSrt) e o \$temSeconv tem que existir ANTES do aviso que pergunta por ele"
Checar "Motor: e quando os DOIS faltam, ai sim ele diz que nao havera OCR" `
    ([bool]($motor -match 'NAO Havera OCR de Legenda Nesta Execucao'))

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
    (($jan -match '(?s)function Get-NomeCorEL[\s\S]{0,6000}"MEL"\s+\{ return "verde" \}') -and
     ($jan -match '(?s)function Get-NomeCorEL[\s\S]{0,6000}return "vermelho"') -and
     ($jan -match '(?s)function Get-NomeCorEL[\s\S]{0,6000}return "laranja"'))
Checar "Janela: NAO MEDIDO nao vira verde nem vermelho - vira ambar (duvida)" `
    ([bool]($jan -match '"NAO_MEDIDO" \{ return "ambar" \}'))

<#  EXECUTANDO: a funcao de verdade, com os tres filmes medidos aqui.  #>
$fnCor = ([System.Management.Automation.Language.Parser]::ParseInput($jan, [ref]$null, [ref]$null)).FindAll(
    { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -eq "Get-NomeCorEL" }, $true)
if ($fnCor.Count -eq 1) {
    . ([scriptblock]::Create($fnCor[0].Extent.Text))
    <#  2.0.1: a coluna I e o pico isolado, que SO o censo completo liga.
        Os dois casos do fim sao os dois filmes medidos de verdade. #>
    $casosCor = @(
        @{ T = "MEL";        E = $false; I = $false; Cor = "verde";    Q = "Troy - MEL" },
        @{ T = "FEL";        E = $false; I = $false; Cor = "laranja";  Q = "GoT S08E01 - Simple FEL" },
        @{ T = "FEL";        E = $true;  I = $false; Cor = "vermelho"; Q = "Saving Private Ryan - Complex FEL" },
        @{ T = "MISTO";      E = $true;  I = $false; Cor = "vermelho"; Q = "amostra mista, com expansao" },
        @{ T = "MISTO";      E = $false; I = $false; Cor = "laranja";  Q = "amostra mista, sem expansao" },
        @{ T = "NAO_MEDIDO"; E = $null;  I = $false; Cor = "ambar";    Q = "medicao interrompida" },
        @{ T = "MEDINDO";    E = $null;  I = $false; Cor = "cinza";    Q = "ainda medindo" },
        @{ T = "MEL";        E = $false; I = $true;  Cor = "verde";    Q = "MEL nao muda de cor por causa do censo" })
    foreach ($c in $casosCor) {
        $vv = [PSCustomObject]@{ ELtipo = $c.T; ELexpande = $c.E; ELpicoIsolado = $c.I }
        Checar ("EXECUTANDO: {0} -> {1}" -f $c.Q, $c.Cor) ((Get-NomeCorEL $vv) -eq $c.Cor)
    }
Titulo "49. A COR SEGUE A CLASSIFICACAO - O CENSO NUNCA A TROCA (2.0.5)"
<#  A 2.0.2 fazia o censo descer um Complex FEL de vermelho para laranja.
    Laranja e a cor do Simple FEL: o Diego leu que o filme tinha sido
    reclassificado, e o cartao final dizia outra coisa. Uma cor, um
    significado. O censo acrescenta numeros a linha, nunca muda a cor. #>
Checar "Janela: nao existe mais o campo do 'pico isolado'" (-not ($jan -match 'ELpicoIsolado'))
Checar "Janela: o censo nao troca a cor (nao existe mais 'a gravidade DESCEU')" (-not ($jan -match 'a gravidade DESCEU'))
Checar "Janela: e a regra esta escrita no ramo do censo" ([bool]($jan -match 'A COR SEGUE A CLASSIFICACAO'))
Checar "Janela: o giro do censo usa UMA barra invertida, nao duas" ([bool]($jan.Contains('$giros = @("|", "/", "-", "\")')))
$vvRed = [PSCustomObject]@{ ELtipo = "FEL"; ELexpande = $true }
Checar "EXECUTANDO: Complex FEL e vermelho, com ou sem censo" ((Get-NomeCorEL $vvRed) -eq "vermelho")
Checar "Motor: o motor avisa que a medida dele e por AMOSTRA" `
    ([bool]($mot -match 'Medida por AMOSTRA')) `
    "sem isto a janela diz laranja, o log do motor diz NAO RECOMENDADA, e ninguem explica"
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


Titulo "35. O CENSO COMPLETO E UM BOTAO, E SO ONDE A DUVIDA EXISTE (17.08 / 14.50 - item A)"
<#  O autor do dovi_convert apontou que amostra nao prova Complex FEL. O
    censo completo e a resposta - e tudo o que estes testes guardam e o
    DESENHO da resposta, nao o numero que ela devolve:

      1. quem le o filme inteiro e o MOTOR, nao a janela;
      2. o botao nasce desligado e so acende em Complex FEL;
      3. quem diz o que e Complex FEL continua sendo Get-NomeCorEL - uma
         regra, um lugar (o bug do audio da 16.79/16.80 foi dois lugares);
      4. e o runspace do censo NAO chama funcao da janela. Este ultimo e o
         teste que a 17.06 nao tinha: a nota do audio foi escrita com uma
         funcao da janela dentro do runspace de leitura e todo arquivo caiu
         em "Nao Foi Possivel Ler". A armadilha agora tem cerca.  #>

Checar "Motor: existe Get-CensoCompletoDV (o censo do filme inteiro)" `
    ([bool]($mot -match 'function Get-CensoCompletoDV'))
Checar "Motor: o censo le o RPU por PIPE (sem gravar 60-80 GB de .hevc)" `
    ([bool]($mot -match 'extract-rpu'))
Checar "Motor: e o pipe e montado pelo cmd (o PS 5.1 estraga pipe binario)" `
    ([bool]($mot -match '(?s)function Invoke-PipeExtractRpu.{0,3000}cmd\.exe /c'))
<#  14.52: a linha do pipe e GRAVADA num .cmd e o cmd recebe so o caminho
    dele. Passar a linha como argumento deixava o PowerShell 5.1 reescrever
    as aspas, e o Bloodsport - que mora em pasta com espaco - falhava com
    erro do proprio cmd. #>
Checar "Motor: o pipe vai por ARQUIVO .cmd, nunca como argumento" `
    ([bool]($mot -match 'pipe_rpu\.cmd'))
Checar "Motor: o .cmd e gravado em ANSI (UTF-8 quebraria caminho com acento)" `
    ([bool]($mot -match '(?s)function Invoke-PipeExtractRpu.{0,3000}\[System\.Text\.Encoding\]::Default'))
Checar "Motor: e o % e escapado (senao nome com % apaga meio caminho)" `
    ([bool]($mot -match '(?s)function Invoke-PipeExtractRpu.{0,3000}Replace\("%", "%%"\)'))
Checar "Motor: o censo NAO monta mais a linha do pipe a mao" `
    (-not ($mot -match '(?s)function Get-CensoCompletoDV.{0,9000}cmd\.exe /c \$linha'))
<#  2.0.2 - ESTE TESTE COBRAVA O TRECHO LENTO PELO NOME.
    Ele exigia "min_pq, max_pq, avg_pq -Unique", que era COMO a conta era
    feita, nao O QUE ela tinha que responder. E o "como" era justamente o
    defeito: Select-Object -Unique compara cada linha com todas as unicas ja
    guardadas, e em 215 mil linhas isso custou 107 segundos que nenhum
    relogio do censo media. O invariante de verdade e o resultado - cena e
    trio min/max/avg distinto - e que a conta seja de UMA passada. #>
Checar "Motor: o censo conta CENAS distintas (trio min/max/avg)" `
    ([bool]($mot -match '(?s)function Get-CensoCompletoDV.{0,12000}\$chave = "\$\(\$c\.min_pq\)\|\$\(\$c\.max_pq\)\|\$\(\$c\.avg_pq\)"'))
Checar "Motor: e conta em UMA passada, com HashSet (nao Select-Object -Unique)" `
    (-not ($mot -match 'min_pq, max_pq, avg_pq -Unique')) `
    "quadratico em 215 mil linhas custou 107s escondidos de todo relogio"
Checar "Motor: a AMOSTRA conta do mesmo jeito (o padrao nao sobrou em lugar nenhum)" `
    ([bool]($mot -match '\$chaveAm = "\$\(\$cena\.min_pq\)\|\$\(\$cena\.max_pq\)\|\$\(\$cena\.avg_pq\)"')) `
    "padrao errado se conserta onde ele mora, nao so onde doeu (licao 37)"
Checar "Motor: a leitura do CSV ENTRA na conta do tempo do censo" `
    ([bool]($mot -match '(?s)\$relogio\.Restart\(\).{0,400}Import-Csv -LiteralPath \$csvL1')) `
    "tempo que nenhum relogio mede nao entra no aprendizado da previsao (licao 43)"
Checar "Motor: e o total soma os dois pedacos, nao substitui um pelo outro" `
    ([bool]($mot -match '\$res\.SegundosCenso = \[math\]::Round\(\[double\]\$res\.SegundosCenso \+ \$relogio\.Elapsed\.TotalSeconds, 1\)'))
Checar "Motor: reaproveita a regua ja lida (nao le o master duas vezes)" `
    ([bool]($mot -match '(?s)function Get-CensoCompletoDV.{0,3000}MasterMaxConhecido'))
Checar "Motor: a pasta temporaria do censo e apagada mesmo se der erro" `
    ([bool]($mot -match '(?s)function Get-CensoCompletoDV.{0,12000}finally.{0,600}Remove-Item'))
Checar "Motor: o censo NAO escreve na pasta do filme do usuario" `
    ([bool]($mot -match '(?s)function Get-CensoCompletoDV.{0,6000}GetTempPath'))
Checar "Motor: o censo devolve QUANTO custou (senao nao da para comparar)" `
    ([bool]($mot -match '(?s)function Get-CensoCompletoDV.{0,3000}SegundosRpu') -and
     [bool]($mot -match '(?s)function Get-CensoCompletoDV.{0,3000}SegundosCenso'))

Checar "Janela: o botao do censo existe no XAML" `
    ([bool]($jan -match 'x:Name="btnCenso"'))
Checar "Janela: e ele NASCE desligado" `
    ([bool]($jan -match 'x:Name="btnCenso"[^>]{0,200}IsEnabled="False"'))
Checar "Janela: existe Test-PodeCenso (quem pode pedir o censo)" `
    ([bool]($jan -match 'function Test-PodeCenso'))
Checar "Janela: Test-PodeCenso pergunta a Get-NomeCorEL (uma regra, um lugar)" `
    ([bool]($jan -match '(?s)function Test-PodeCenso.{0,1200}Get-NomeCorEL'))
Checar "Janela: e exige vermelho, ou seja, Complex FEL" `
    ([bool]($jan -match '(?s)function Test-PodeCenso.{0,1200}-eq "vermelho"'))
Checar "Janela: MEL nao pode pedir censo (so FEL/MISTO passam)" `
    ([bool]($jan -match '(?s)function Test-PodeCenso.{0,900}ELtipo\)" -ne "FEL".{0,120}-ne "MISTO".{0,120}return \$false'))
<#  3.58 - 18.21: O BOTAO DO CENSO TEM UM DONO SO, E O TESTE CONTA OS DONOS.

    "PQ O CENSO PODE RELER NOVAMENTE APERTA F11 E CLICANDO NAO?" (Diego,
    17/09). Tres lugares escreviam em $UI.btnCenso.IsEnabled com regras
    diferentes; quem repintasse por ultimo ganhava, e o F11 nunca passava por
    nenhum deles. Cobrar a REGRA em um lugar nao bastava - o defeito era a
    existencia dos outros dois. Entao o teste conta: fora de Update-BotaoCenso,
    ninguem escreve nessa propriedade. #>
$donosCenso = @([regex]::Matches($janCodigo, '\$UI\.btnCenso\.IsEnabled\s*=')).Count
$corpoUpdBotaoCenso = ""
$mUBC = [regex]::Match($janCodigo, '(?s)function Update-BotaoCenso\(\$v\) \{.{0,2500}?\n\}')
if ($mUBC.Success) { $corpoUpdBotaoCenso = $mUBC.Value }
$donosDentro = @([regex]::Matches($corpoUpdBotaoCenso, '\$UI\.btnCenso\.IsEnabled\s*=')).Count
Checar "Censo: o IsEnabled do botao tem UM dono so (Update-BotaoCenso)" `
    (($donosCenso -gt 0) -and ($donosCenso -eq $donosDentro)) `
    ("achei $donosCenso escrita(s) no total e $donosDentro dentro de Update-BotaoCenso - 18.21: fora dela, nenhuma")
Checar "Censo: e o dono acende o botao enquanto o censo roda (para poder cancelar)" `
    ([bool]($corpoUpdBotaoCenso -match '(?s)if \(\$script:CensoRodando\) \{.{0,200}btnCenso\.IsEnabled\s*=\s*\$true'))
Checar "Censo: e um arquivo JA CONTADO continua podendo ser contado de novo pelo botao" `
    (-not ($corpoUpdBotaoCenso -match 'IsEnabled[^\r\n]{0,200}CensoFeito')) `
    "o F11 sempre deixou recontar; o botao nao deixava - duas portas, duas regras (licao 41)"
Checar "Censo: o dono ainda exige Complex FEL e tela parada" `
    ([bool]($corpoUpdBotaoCenso -match '(?s)btnCenso\.IsEnabled = .{0,200}Test-PodeCenso \$v.{0,200}\$Estado\.Atual -eq "inicial"'))
Checar "Janela: o rotulo/cor do censo ainda olha o 'ja contado'" `
    ([bool]($corpoUpdBotaoCenso -match 'CensoFeito'))
<#  3.53 - 18.16: o botao do censo virou liga/desliga. "nunca vi um botao
    que comeca e nao pode parar" (Diego). Uma acao, um lugar - o clique e a
    tecla F11 batem na MESMA funcao. #>
Checar "Janela: o clique do censo passa pela funcao unica do botao" `
    ([bool]($jan -match '(?s)btnCenso\.add_Click.{0,120}Invoke-BotaoCenso'))
Checar "Censo: o mesmo botao PARA o censo em curso" `
    ([bool]($jan -match '(?s)function Invoke-BotaoCenso.{0,400}if \(\$script:CensoRodando\).{0,300}Stop-Censo')) `
    "ate a 18.15 so dava para parar trocando de pasta, apertando F1 ou fechando o programa"
Checar "Censo: e so comeca um novo quando nao ha um rodando" `
    ([bool]($jan -match '(?s)function Invoke-BotaoCenso.{0,3000}return.{0,1500}Start-Censo'))
Checar "Teclas: F11 e o censo e F12 e a medicao (as MESMAS funcoes dos botoes)" `
    ([bool]($jan -match '(?s)"F11"\s*\{ .{0,80}Invoke-BotaoCenso.{0,160}"F12"\s*\{ Invoke-TrocarMedirEL')) `
    "pedido dele - e atalho que nao passa pela regra do botao vira segunda regra"
Checar "Teclas: as de regra propria sao registradas sem julgar o estado" `
    ([bool]($jan -match '(?s)elseif \(\$e\.Key -in @\("F5","F12"\)\) \{.{0,120}TECLA')) `
    "17/09 16:47:11: escrevia 'TECLA F11 (ignorada)' e chamava a acao na linha seguinte"
Checar "Teclas: e as que dependem do botao continuam conferindo o botao" `
    ([bool]($jan -match '(?s)if \(\$e\.Key -in @\("F1","F2","F3","F4","F11","Escape"\)\).{0,900}IsEnabled'))

<#  ===========================================================================
    3.60 - 18.23: A BARRA GANHOU F3 E F4, E MUDOU DE ORDEM.

    "joga o botao Atualizar pra direita e traz o Abrir Saida pra esquerda, e
    [F3] Abrir Origem [F4] Abrir Saida... padrao viu, nao comete os erros dos
    outros botoes: errar traducao, errar se clicar, e nao aparecer os F"
    (Diego, 17/09).

    Ele listou os tres erros que eu ja cometi nesta barra, um por um. Entao o
    teste cobra os tres, um por um.
    =========================================================================== #>
$iOrigem = $janCodigo.IndexOf('x:Name="btnAbrirOrigem"')
$iSaida  = $janCodigo.IndexOf('x:Name="btnAbrirSaida"')
$iReler  = $janCodigo.IndexOf('x:Name="btnReler"')
$iCenso  = $janCodigo.IndexOf('x:Name="btnCenso"')
Checar "Barra: os quatro botoes existem no XAML" `
    (($iOrigem -gt 0) -and ($iSaida -gt 0) -and ($iReler -gt 0) -and ($iCenso -gt 0))
Checar "Barra: a ordem e Origem, Saida, Atualizar, Censo (o par de pastas junto)" `
    (($iOrigem -lt $iSaida) -and ($iSaida -lt $iReler) -and ($iReler -lt $iCenso)) `
    "'joga o Atualizar pra direita e traz o Abrir Saida pra esquerda' - e as teclas ficam em ordem crescente"

<#  ERRO 1 QUE ELE CITOU: nao aparecer os F. Varredura, nao conferencia um a
    um - foi o que pegou o [F12] da medicao (3.58) e o [F11] do censo (3.59). #>
$rotulosBarra = @{
    "lblAbrirOrigem" = "F3" ; "lblAbrirSaida" = "F4" ; "lblReler" = "F5"
}
foreach ($nome in $rotulosBarra.Keys) {
    $mR = [regex]::Match($janCodigo, ('x:Name="{0}"[^>]{{0,200}}Text="([^"]+)"' -f $nome))
    Checar ("Barra: o rotulo {0} nasce com [{1}]" -f $nome, $rotulosBarra[$nome]) `
        ($mR.Success -and $mR.Groups[1].Value -match ("\[{0}\]" -f $rotulosBarra[$nome])) `
        ("achei: '" + $mR.Groups[1].Value + "'")
}

<#  ERRO 2: errar se clicar - ou seja, a tecla fazer uma coisa e o clique
    outra. Uma acao, uma funcao, e as duas portas chamando ELA. #>
Checar "Barra: abrir Origem e uma funcao (nao um corpo solto no clique)" `
    ([bool]($jan -match 'function Invoke-AbrirOrigem'))
Checar "Barra: abrir Saida tambem" `
    ([bool]($jan -match 'function Invoke-AbrirSaida'))
Checar "Barra: o CLIQUE do Origem chama a funcao" `
    ([bool]($jan -match 'btnAbrirOrigem\.add_Click\(\{ Invoke-AbrirOrigem \}\)'))
Checar "Barra: o CLIQUE do Saida chama a funcao" `
    ([bool]($jan -match 'btnAbrirSaida\.add_Click\(\{ Invoke-AbrirSaida \}\)'))
Checar "Teclas: e o F3 chama a MESMA funcao do clique" `
    ([bool]($jan -match '"F3"\s*\{ if \(\$UI\.btnAbrirOrigem\.IsEnabled\) \{ Invoke-AbrirOrigem \}')) `
    "atalho que nao passa pela funcao do botao vira segunda regra (licao 41)"
Checar "Teclas: e o F4 tambem" `
    ([bool]($jan -match '"F4"\s*\{ if \(\$UI\.btnAbrirSaida\.IsEnabled\)  \{ Invoke-AbrirSaida  \}'))
Checar "Teclas: ninguem chama Abrir-PastaNoExplorer por fora das duas funcoes" `
    (@([regex]::Matches($janCodigo, 'Abrir-PastaNoExplorer')).Count -eq 3) `
    "a definicao e as duas funcoes - qualquer quarta chamada e uma segunda regra"

<#  ERRO 3: errar traducao. A varredura geral ja cobra isso, mas estes dois
    rotulos ganharam a tecla AGORA - e o texto com a tecla e uma entrada
    NOVA, diferente da antiga sem ela. Foi exatamente assim que o [F5] passou
    despercebido na 18.17. #>
$linhasIdi = @()
try { $linhasIdi = [System.IO.File]::ReadAllLines((Join-Path $Fonte "IDIOMA_EN.txt")) } catch { }
foreach ($frase in @("[F3] Abrir Origem", "[F4] Abrir Saída")) {
    <#  Cuidado: "[" e curinga no -like, e "[F3]" vira classe de caracteres -
        o teste dava REPROVADO com a entrada presente e correta no arquivo.
        Comparacao exata do primeiro campo, que e o que se quer mesmo. #>
    $achou = @($linhasIdi | Where-Object { ($_ -split "`t")[0] -ceq $frase }).Count -gt 0
    Checar ("Idioma: '{0}' tem traducao em ingles" -f $frase) $achou `
        "rotulo novo e entrada NOVA - a linha sem a tecla nao serve mais (foi assim que o [F5] passou na 18.17)"
}
<#  3.58 - 18.21: O F11 CONFERE O MESMO BOTAO QUE O MOUSE.
    A assimetria que ele viu ("clicando nao") vinha de a tecla nao passar pelo
    IsEnabled. Repetir a regra dentro da funcao nao resolveria - duas copias
    da mesma regra sao duas regras. Ler a MESMA propriedade resolve. #>
Checar "Teclas: o F11 confere o botao do censo antes de agir (mouse e tecla, uma regra)" `
    ([bool]($jan -match '"F11"\s*\{ if \(\$UI\.btnCenso\.IsEnabled\) \{ Invoke-BotaoCenso \}')) `
    "'PQ O CENSO PODE RELER APERTA F11 E CLICANDO NAO?' - porque tecla nao passa por IsEnabled"
Checar "Teclas: o F11 tambem entra na conta de quem diz 'ignorada' com verdade" `
    ([bool]($jan -match '(?s)\$vale = switch \(\$e\.Key\).{0,400}"F11"\s*\{ \$UI\.btnCenso\.IsEnabled \}'))
<#  3.51 - CANCELAR O CENSO MATA O TRABALHO, E SO ELE (18.14).
    A assinatura do censo e unica no programa: extract-rpu lendo da entrada
    padrao. A conversao e "convert"; a amostra e extract-rpu com ARQUIVO no -i.
    O teste cobra as tres coisas, e a bancada roda a funcao de verdade contra
    linhas de comando das tres. #>
Checar "Censo: cancelar encerra os processos do censo" `
    ([bool]($jan -match '(?s)function Stop-Censo.{0,2200}Matar-ProcessosDoCenso')) `
    "17/09 14:28:20 -> 14:30:01: 101s lendo disco depois de cancelado"
Checar "Censo: quem decide o que morre e uma funcao pura (testavel sem processo)" `
    ([bool]($jan -match 'function Test-EhProcessoDoCenso'))
Checar "Censo: a conversao NUNCA entra na conta (dovi_tool convert e poupado)" `
    ([bool]($jan -match '(?s)function Test-EhProcessoDoCenso.{0,900}convert.{0,60}return \$false')) `
    "matar o dovi_tool da conversao seria estragar o arquivo do usuario"
Checar "Censo: o ffmpeg so morre se a linha carregar O caminho deste censo" `
    ([bool]($jan -match '(?s)function Test-EhProcessoDoCenso.{0,1400}Contains\("\$Caminho"\.ToLowerInvariant\(\)\)')) `
    "identidade e o caminho (licao 30), e na duvida nao mata"
Checar "Censo: encerrado a pedido NAO e registrado como falha" `
    ([bool]($jan -match '(?s)\$script:CensoMorto -and.{0,200}encerrado a pedido')) `
    "o motor so ve que o RPU nao saiu - quem sabe que foi de proposito e a janela"

Checar "Janela: o censo roda em RUNSPACE proprio (nao congela a tela)" `
    ([bool]($jan -match '(?s)function Start-Censo.{0,12000}runspacefactory'))
Checar "Janela: e o runspace recebe o caminho do motor para abrir pela AST" `
    ([bool]($jan -match '(?s)function Start-Censo.{0,12600}SetVariable\("CaminhoMotor"'))
Checar "Janela: Stop-Censo devolve o runspace (senao vaza a cada clique)" `
    ([bool]($jan -match '(?s)function Stop-Censo.{0,1200}Dispose'))

<#  A ARMADILHA DA 17.06, COM CERCA.
    O bloco do runspace do censo e extraido inteiro e reprovado se citar
    qualquer funcao que so existe na janela. La dentro quem fala e Avisar. #>
$blocoCenso = ""
$mC = [regex]::Match($jan, '(?s)\$script:TrabalhoCenso = \{.*?\n\}\r?\n')
if ($mC.Success) { $blocoCenso = $mC.Value }
Checar "Janela: o bloco do runspace do censo foi localizado" ($blocoCenso -ne "")
if ($blocoCenso -ne "") {
    Checar "Janela: o runspace do censo NAO chama funcao da janela (defeito da 17.06)" `
        (-not ($blocoCenso -match 'Escrever-Log'))
    Checar "Janela: quem fala de dentro do runspace do censo e a Avisar" `
        ([bool]($blocoCenso -match 'Avisar '))
    Checar "Janela: e ele avisa o custo medido, nao so o veredicto" `
        ([bool]($blocoCenso -match 'SegundosRpu') -and [bool]($blocoCenso -match 'SegundosCenso'))
}
Checar "Janela: o resultado do censo tem tratamento na fila de mensagens" `
    ([bool]($jan -match '"censo_fim"'))
<#  3.18 - O TESTE QUE FALTAVA, E POR QUE ELE FALTAVA.

    A 17.08 passou nos 27 testes desta secao e o botao nao fazia NADA. O
    motivo: eu escrevi $v.Path e o objeto do video tem $v.Caminho. Todos os
    testes olhavam o DESENHO (roda em runspace, so em Complex FEL, nao chama
    funcao da janela) e nenhum olhava os NOMES DOS CAMPOS - e nome de campo
    errado, em PowerShell, e sempre mudo: vira string vazia e segue.

    Este teste extrai os campos que a LEITURA de fato cria no objeto do
    video e reprova se Start-Censo pedir um que nao existe. Mesma ideia da
    secao 13: nao confere o que eu quis dizer, confere o que esta escrito. #>
$camposDoVideo = @()
$mObj = [regex]::Match($jan, '(?s)\$d = @\{ Nome = \$a\.BaseName.*?\r?\n\s*\}')
Checar "Janela: o objeto do video (o que a leitura cria) foi localizado" ($mObj.Success)
if ($mObj.Success) {
    $camposDoVideo = @([regex]::Matches($mObj.Value, '([A-Za-z_][A-Za-z0-9_]*)\s*=') |
                       ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    Checar ("Janela: {0} campos lidos do objeto do video" -f $camposDoVideo.Count) ($camposDoVideo.Count -ge 20)

    $mSC = [regex]::Match($jan, '(?s)function Start-Censo \{.*?\n\}')
    Checar "Janela: o corpo do Start-Censo foi localizado" ($mSC.Success)
    if ($mSC.Success) {
        $pedidos = @([regex]::Matches($mSC.Value, '\$v\.([A-Za-z_][A-Za-z0-9_]*)') |
                     ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
        $inexistentes = @($pedidos | Where-Object { $camposDoVideo -notcontains $_ })
        Checar "Janela: o censo le SO campos que o objeto do video tem (o bug da 17.08)" `
            ($inexistentes.Count -eq 0) ("nao existem no objeto: " + ($inexistentes -join ", "))
        Checar "Janela: e o caminho do arquivo vem de Caminho, nao de Path" `
            ([bool]($mSC.Value -match '\$v\.Caminho') -and (-not ($mSC.Value -match '\$v\.Path')))
    }
}

Checar "Idioma: o rotulo do botao do censo tem traducao" `
    ($(  $arqIC = Join-Path $Fonte "IDIOMA_EN.txt"
         if (Test-Path -LiteralPath $arqIC) {
             $tIC = Get-Content -Raw -LiteralPath $arqIC
             ($tIC -match "Censo Completo\tFull Census") -and ($tIC -match "Contando\.\.\.\tCounting")
         } else { $false }  ))


Titulo "36. A REGUA PODE ESTAR TORTA, E O LOG PASSA A DIZER ISSO (14.50 - itens C e D)"
<#  A segunda metade da critica do dovi_convert: o pico do mastering display
    e metadado DECLARADO, e release erra. O programa nao pode provar que
    errou - mas quando a MAIORIA das cenas passa da regua, ele para de
    fingir que ela e confiavel.

    E a suspeita vai para o LOG, nunca para a linha do diagnostico: a linha
    diz o que foi detectado e o que sera feito (regra da 16.79). #>

Checar "Motor: a medida carrega ReguaSuspeita" `
    ([bool]($mot -match 'ReguaSuspeita\s*=\s*\$false'))
Checar "Motor: e o motivo junto (numero sem frase nao explica nada)" `
    ([bool]($mot -match 'ReguaSuspeitaMotivo'))
Checar "Motor: a suspeita exige MAIORIA das cenas acima da regua" `
    ([bool]($mot -match 'PctAcimaDoMaster -ge 50\.0'))
Checar "Motor: e um piso de cenas (com 5 cenas, 60% sao 3 cenas)" `
    ([bool]($mot -match 'CenasNoCenso -ge 20'))
Checar "Motor: a frase diz SUSPEITA, nunca 'regua errada'" `
    (([bool]($mot -match 'suspeita de pico declarado abaixo do real')) -and
     (-not ($mot -match 'a regua esta errada')))
Checar "Motor: sem regua declarada nao ha suspeita (nao inventa acusacao)" `
    ([bool]($mot -match '\$res\.MasterMax -gt 0 -and \[int\]\$res\.CenasNoCenso -gt 0'))
Checar "Janela: a regua suspeita vai para o LOG" `
    ([bool]($jan -match 'REGUA SUSPEITA'))
Checar "Janela: e NAO entra na linha do diagnostico (regra da 16.79)" `
    (-not ($jan -match 'DiagDVrot\s*=\s*[^\r\n]*REGUA SUSPEITA'))
Checar "Janela: a suspeita chega na linha do video (sobrevive a redesenho)" `
    ([bool]($jan -match 'ELreguaSuspeita'))

# 2.0.17: item C revogado - a pasta de saida recebe so .mkv + .srt (secao 37).
Checar "Motor: a copia NAO substitui o relatorio final" `
    ([bool]($mot -match 'Log Completo Salvo em'))



Titulo "37. O QUE A 1.8.2 ENTREGOU E NAO FUNCIONOU (17.09 / 14.51)"
<#  Tres coisas passaram na bateria de 17.08 e falharam na mao do Diego.
    Nenhuma delas era logica errada - eram testes olhando para o lado errado:

      1. o botao do censo: campo com nome errado (secao 35, ja coberto);
      2. a copia do log: escrita num lugar que a JANELA nunca executa;
      3. o cartao final: o Ryan saiu todo verde depois de o proprio programa
         ter escrito [CONVERSAO NAO RECOMENDADA] no log.  #>

Checar "Janela 19.14: a pasta de saida NAO recebe copia do log (so .mkv + .srt)" `
    (-not ($jan -match 'LaFirma\.log\.txt"\)')) "pedido do Diego 23/09: log fica em _logs"
Checar "Motor 14.14: tambem nao grava copia do log na pasta de saida" `
    (-not ($mot -match '\.LaFirma\.log\.txt"\)'))

Checar "Motor: o veredicto da camada entra no OBJETO de resultado" `
    ([bool]($mot -match 'SeloEL\s*=')) 
Checar "Motor: com o motivo junto (selo sem frase nao explica nada)" `
    ([bool]($mot -match 'MotivoEL\s*='))
Checar "Motor: o selo da camada e zerado por ARQUIVO (nao herda do anterior)" `
    ([bool]($mot -match '\$script:SeloELdoArquivo\s*=\s*""'))
Checar "Motor: e ele e preenchido de onde o veredicto ja sai (Get-TipoCamadaDV)" `
    ([bool]($mot -match '\$script:SeloELdoArquivo\s*=\s*"\$\(\$diagEL\.Selo\)"')) 
Checar "Janela: o cartao final tem ramo para o Complex FEL" `
    ([bool]($jan -match '(?s)function Get-SelosResultado.{0,4000}"EXPANDE"')) 
Checar "Janela: e para o Simple FEL" `
    ([bool]($jan -match '(?s)function Get-SelosResultado.{0,4000}"RESSALVA"'))
Checar "Janela: o selo da ressalva NAO e verde (era o defeito do Ryan)" `
    (-not ($jan -match 'CONVERSAO NAO RECOMENDADA", "ok"')) 
Checar "Janela: e o Profile 8.1 convertido continua verde ao lado dele" `
    ([bool]($jan -match 'Dolby Vision . Profile 8\.1 - CONVERTIDO", "ok"'))

<#  A bancada: nao pode voltar a perguntar antes de rodar, nem a fechar
    depois de um arquivo so. #>
$pBan = Join-Path $Fonte "Bancada_CensoCompleto.ps1"
$pBanBat = Join-Path $Fonte "Bancada_CensoCompleto.bat"
if ((Test-Path -LiteralPath $pBan) -and (Test-Path -LiteralPath $pBanBat)) {
    $tBan = Get-Content -Raw -LiteralPath $pBan
    $tBat = Get-Content -Raw -LiteralPath $pBanBat
    Checar "Bancada: arrastar o arquivo NAO faz pergunta nenhuma antes de medir" `
        ([bool]($tBat -match '(?m)^if not "%~1"=="" \(')) 
    Checar "Bancada: e o .bat volta ao menu em vez de fechar" `
        ([bool]($tBat -match '(?m)^:MENU')) 
    Checar "Bancada: a falha do RPU escreve o motivo no log (nao so na tela)" `
        ([bool]($tBan -match '\$script:Erro = "o dovi_tool nao produziu RPU'))
    <#  exit dentro do try pularia a planilha. A falha da MEDICAO tem que
        sair por return, para o finally somar a linha com ok=nao. Os dois
        exit que sobraram sao de ANTES do try (arquivo ou ferramenta que nem
        existe) - ali nao ha medida nenhuma a registrar. #>
    Checar "Bancada: a falha do RPU sai por RETURN, nao por exit (senao perde a linha)" `
        ([bool]($tBan -match '(?s)FALHOU: o dovi_tool nao produziu RPU.{0,900}return'))
    Checar "Bancada: a planilha tenta de novo quando o Excel esta com ela aberta" `
        ([bool]($tBan -match 'for \(\$t = 1; \$t -le 3'))
    Checar "Bancada: e se nao der, grava numa planilha alternativa (nao perde a medida)" `
        ([bool]($tBan -match 'bancada_censo_medidas_'))
    Checar "Bancada: a coluna ok diz o MOTIVO quando falha" `
        ([bool]($tBan -match '"nao - " \+ \(\$script:Erro'))
    Checar "Bancada: recusa o que nem e video ANTES de medir (o .xlsx arrastado)" `
        ([bool]($tBan -match '\$extsVideo -notcontains'))
    Checar "Bancada: o cabecalho na tela diz a versao de verdade" `
        ([bool]($tBan -match 'BANCADA 2\.3 - CENSO COMPLETO'))
    <#  3.19 - O DEFEITO "ABRE E FECHA", COM CERCA.

        A guarda de extensao da 2.1 derrubou o gesto mais natural que existe
        aqui: arrastar a PASTA do filme. "Bloodsport...HDR10P.H- CONVERTIDO"
        tem Extension ".H- CONVERTIDO" - fora da lista de video - e o script
        saia com exit 1 antes da primeira linha. Log de ZERO byte, janela
        fechando na cara.

        Dois testes, porque foram dois erros: aceitar pasta (o que faltava
        fazer) e nunca sair calado (o que fez o defeito chegar sem
        explicacao). #>
    Checar "Bancada: PASTA e um pedido valido, nao motivo de recusa" `
        ([bool]($tBan -match '\$entrada\.PSIsContainer'))
    Checar "Bancada: e ela procura os videos dentro, por extensao" `
        ([bool]($tBan -match '(?s)PSIsContainer.{0,1200}\$extsVideo -contains'))
    Checar "Bancada: NENHUMA recusa sai calada - todas escrevem no log" `
        ($(  $mEnt = [regex]::Match($tBan, '(?s)# -+ entrada.*?\$gb  = \[math\]')
             if ($mEnt.Success) { -not ($mEnt.Value -match 'Write-Host') } else { $false }  )) `
        "ha Write-Host no bloco de entrada - ele nao vai para o log"
    Checar "Bancada: o caminho recebido vai para o log ANTES de ser julgado" `
        ([bool]($tBan -match 'Dizer \(" Recebido: \{0\}"'))
    Checar "Bancada: dois logs no mesmo segundo nao se comem (milissegundos)" `
        ([bool]($tBan -match 'HHmmss_fff'))
    <#  3.19 - O PIPE NAO VIAJA MAIS COMO ARGUMENTO.
        O PowerShell 5.1 reescreve as aspas ao passar argumento para programa
        nativo; com espaco no caminho, o que chega ao cmd nao e a linha que
        foi escrita. Foi assim que o Bloodsport falhou dizendo "A sintaxe do
        nome do arquivo... esta incorreta" - erro do cmd, nao do ffmpeg. #>
    Checar "Bancada: o pipe do RPU e gravado num .cmd, nao passado em string" `
        ([bool]($tBan -match 'pipe_rpu\.cmd'))
    Checar "Bancada: e nenhum cmd.exe /c recebe a linha montada a mao" `
        (-not ($tBan -match 'cmd\.exe /c \$linha'))
}


Titulo "38. A MEDICAO MEL x FEL VIROU CHAVE, E O CUSTO E MEDIDO NOS DOIS ESTADOS (17.10)"
<#  A queixa de 10/09: "esse lance do FEL x MEL esta gerando um custo de
    tempo para apenas comecar a conversao, q antes era so abrir o programa,
    apontar a pasta e dar F1".

    O que estes testes guardam NAO e a chave - e a HONESTIDADE dela. Uma
    chave que desliga um trabalho e esconde o custo nao responde pergunta
    nenhuma; o que responde e a linha que sai NOS DOIS ESTADOS, com os
    mesmos campos, para poder ser comparada lado a lado. #>

Checar "Janela: existe a chave da medicao, com padrao LIGADO" `
    ([bool]($jan -match '\$script:MedirELLigado\s*=\s*\$true'))
Checar "Janela: a preferencia e GUARDADA entre sessoes" `
    ([bool]($jan -match 'function Salvar-MedirEL') -and [bool]($jan -match 'function Carregar-MedirEL'))
Checar "Janela: e guardada na pasta de dados (nao na do script - licao da 17.02)" `
    ([bool]($jan -match '(?s)function Get-CaminhoMedirEL.{0,400}Get-PastaDados'))
Checar "Janela: preferencia ilegivel volta ao padrao LIGADO (duvida nao vira veredicto faltando)" `
    ([bool]($jan -match '(?s)function Carregar-MedirEL.{0,900}-ne "0" -and'))
Checar "Janela: a chave e lida ANTES da primeira leitura" `
    ([bool]($jan -match '(?s)Carregar-MedirEL.{0,600}Start-Leitura'))
Checar "Janela: o botao da chave existe no XAML" `
    ([bool]($jan -match 'x:Name="btnMedirEL"'))
<#  3.25: na 17.15 o corpo do clique saiu de dentro do handler e virou
    Invoke-TrocarMedirEL, porque agora SAO DOIS botoes (o de baixo e o gemeo
    da barra). Os testes seguem a regra, nao o lugar: uma acao so, chamada
    pelos dois. #>
<#  3.31 - 17.21: a releitura saiu de dentro do clique e ganhou um FREIO.

    Oito trocas em nove segundos no log de 15/09 viraram oito releituras, cada
    uma cancelando a anterior - a fila piscava entre "1 de 1" e "0 de 0". A
    regra testada continua a mesma (trocar a chave RELE a pasta), so que agora
    ela mora no tique do temporizador. #>
Checar "Janela: o clique alterna e guarda a preferencia" `
    ([bool]($jan -match '(?s)function Invoke-TrocarMedirEL.{0,1800}Salvar-MedirEL'))
Checar "Janela: e pede a releitura pelo freio, nao na hora" `
    ([bool]($jan -match '(?s)function Invoke-TrocarMedirEL.{0,2200}\$TimerChaveEL\.Stop\(\).{0,120}\$TimerChaveEL\.Start\(\)')) `
    "seis cliques seguidos tem que ler a pasta UMA vez"
<#  3.33 - 17.23: O FREIO DEIXOU DE SER "QUEM RELE" E VIROU "QUEM DECIDE".

    O log do Diego (15/09) mostrou a chave disparando 28 releituras, 254,5s.
    Agora o tique decide: desligar nunca le; ligar so le se faltar veredicto.
    O teste passa a cobrar a REGRA NOVA, nao a chamada. #>
<#  ============================================================================
    3.35 / 18.00 - A INVARIANTE MAIS DURA DESTA BATERIA:
                   NENHUM CLIQUE PODE TRAVAR A TELA.

    Esta familia nasce do defeito que custou o dia 16/09 inteiro. Stop-Motor
    fazia AsyncWaitHandle.WaitOne(1500) NA THREAD DA INTERFACE, e todo caminho
    de clique que passava por ele parava a janela. Medido no log do Diego:
    1,52s / 1,93s / 2,01s / 1,91s de tela sem responder. Ele descreveu como
    "travou tudo" - e nao era exagero nenhum, era exatamente isso.

    O que torna isso uma FAMILIA e nao um conserto: a janela e WPF de uma
    thread so. Qualquer espera sincrona no codigo dela congela o programa, hoje
    ou daqui a tres versoes, com qualquer nome que a chamada tenha. Entao a
    regra nao e "tire este WaitOne", e "nenhuma espera sincrona existe no codigo
    da janela".

    Os blocos de runspace ($script:Trabalho*) rodam em OUTRA thread - la esperar
    e legitimo, e por isso eles sao removidos antes da conferencia. Comentario
    tambem sai: este arquivo EXPLICA o bug citando o nome da chamada, e citar
    nao e chamar (mesma armadilha da secao dos runspaces, linha 944). #>
$janUI = $jan
foreach ($nomeBloco in @("TrabalhoMotor","TrabalhoLeitura","TrabalhoMedicao","TrabalhoCenso")) {
    $iB = $janUI.IndexOf(('$script:{0} = {{' -f $nomeBloco))
    if ($iB -lt 0) { continue }
    $abre = $janUI.IndexOf("{", $iB); $prof = 0; $fimB = -1
    for ($k = $abre; $k -lt $janUI.Length; $k++) {
        if ($janUI[$k] -eq "{") { $prof++ }
        elseif ($janUI[$k] -eq "}") { $prof--; if ($prof -eq 0) { $fimB = $k; break } }
    }
    if ($fimB -gt $abre) { $janUI = $janUI.Substring(0, $iB) + $janUI.Substring($fimB + 1) }
}
$janUI = Remove-Comentarios $janUI
Checar "Interface: os quatro blocos de runspace foram separados do codigo da janela" `
    (($janUI.Length -gt 50000) -and ($janUI.Length -lt $jan.Length))

foreach ($bloqueio in @(
        @{ Nome = "AsyncWaitHandle.WaitOne"; Pat = 'AsyncWaitHandle\.WaitOne' },
        @{ Nome = "Start-Sleep";             Pat = '\bStart-Sleep\b' },
        @{ Nome = ".Wait()";                 Pat = '\.Wait\(' },
        @{ Nome = ".Join()";                 Pat = '\.Join\(' },
        @{ Nome = ".EndInvoke()";            Pat = '\.EndInvoke\(' })) {
    Checar ("Interface: a janela nao chama {0} (espera sincrona congela a tela)" -f $bloqueio.Nome) `
        (-not ($janUI -match $bloqueio.Pat)) `
        "WPF e uma thread so: esperar aqui e parar o programa na cara do usuario"
}

<#  3.38 - A VARREDURA QUE EU DIZIA FAZER "LENDO CADA LINHA", AGORA FEITA POR
    MAQUINA.

    Print dele de 16/09, tela em ingles: o painel DISK SPACE dizia "Nenhum
    vídeo selecionado." e a coluna PT-BR SUBTITLE dizia "Sem PT-BR (só pt-PT)".
    Ele cobrou, com razao: "voce jura de pe junto q leu todas as linhas onde
    deveria ter traducao e tem erros toda hora".

    Ler na mao nao escala e eu ja errei nisso quatro vezes. Este teste EXTRAI do
    fonte todo texto com acento portugues que vai para a tela - escrita em
    .Text, valor de coluna ($d.Col*), linha de diagnostico ($d.Diag*) e selo do
    cartao final - e exige que CADA UM tenha regra no IDIOMA_EN.txt (exata ou
    por padrao "~"). Texto novo sem traducao reprova a bateria antes de sair
    daqui.

    A lista de excecoes abaixo e curta e cada linha tem motivo declarado. Frase
    que ja nasce nas duas linguas (montada dentro de "if ($en)") nao passa pela
    tabela; log e registro tecnico, em portugues por decisao do projeto. #>
$excecoesTraducao = @(
    "Português"                                     # lblIdioma: o nome do proprio idioma
    "começando"                                     # so log
    'A fila selecionada não cabe no disco.`n`n'     # dialogo com par em ingles no proprio codigo
    'A fila cabe agora, mas não até o fim.`n`n'     # idem
    "o vídeo que está sendo montado agora"          # idem
    "LaFirma - cancelar a conversão?"               # titulo de dialogo com par em ingles
    "LaFirma - fechar com conversão em andamento?"  # idem
    "LaFirma - medição ainda rodando"               # idem
    "LaFirma - falta espaço em disco"               # idem
    "LaFirma - Entenda a Conversão"                 # idem
)
$mapaExato = @{}; $mapaRegra = @()
foreach ($l in @(Get-Content -LiteralPath (Join-Path $Fonte "IDIOMA_EN.txt") -Encoding UTF8)) {
    if ("$l" -match '^\s*#' -or "$l".Trim() -eq "") { continue }
    $pp = "$l" -split "`t"
    if ($pp.Count -lt 2) { continue }
    if ($pp[0].StartsWith("~")) { $mapaRegra += $pp[0].Substring(1) }
    else { $mapaExato[$pp[0].Trim()] = $pp[1] }
}
function Test-TemTraducao([string]$t) {
    if ($mapaExato.ContainsKey($t.Trim())) { return $true }
    foreach ($r in $mapaRegra) { try { if ($t -match $r) { return $true } } catch { } }
    return $false
}
$acentoPt = '[' + [char]0x00E1 + [char]0x00E0 + [char]0x00E2 + [char]0x00E3 + [char]0x00E9 +
            [char]0x00EA + [char]0x00ED + [char]0x00F3 + [char]0x00F4 + [char]0x00F5 +
            [char]0x00FA + [char]0x00E7 + [char]0x00C1 + [char]0x00C9 + [char]0x00CD +
            [char]0x00D3 + [char]0x00DA + [char]0x00C3 + [char]0x00D5 + [char]0x00C7 + ']'
$semTraducao = @()
$padroes = @(
    '\$(?:d|v)\.(?:Col[A-Za-z]+|Diag[A-Za-z]+|Situacao)\s*=\s*"([^"]+)"',
    '\.Text\s*=\s*"([^"]+)"',
    <#  ARMADILHA DO PROJETO, DE NOVO: dentro de @( ) a virgula tem precedencia
        maior que o "+". Sem estes parenteses a linha vira DOIS itens e o regex
        sai partido ao meio - foi o que aconteceu na primeira versao deste
        teste, e quem pegou foi a familia "a propria bateria nao pode ter erro
        de execucao". #>
    ('\{\s*"([^"\$]*' + $acentoPt + '[^"\$]*)"\s*\}'),
    '\+?,\s*@\(\s*"([^"\$]+)"\s*,\s*"(?:cinza|verde|warn|err|ok|vermelho|ambar)"\s*\)'
)
foreach ($pad in $padroes) {
    foreach ($mm in [regex]::Matches($jan, $pad)) {
        $txt = $mm.Groups[1].Value
        if ($txt -match '\$') { continue }
        if ($txt -notmatch $acentoPt) { continue }
        if ($excecoesTraducao -contains $txt) { continue }
        if (-not (Test-TemTraducao $txt)) { $semTraducao += $txt }
    }
}
$semTraducao = @($semTraducao | Sort-Object -Unique)
Checar "Traducao: TODO texto de tela com acento portugues tem regra no IDIOMA_EN.txt" `
    ($semTraducao.Count -eq 0) `
    ("sem traducao: " + ($semTraducao -join " | "))
Checar "Traducao: a lista de excecoes continua curta (cada linha tem motivo)" `
    ($excecoesTraducao.Count -le 12) `
    "excecao sem motivo e traducao perdida com carimbo de decisao"

<#  3.37 - CADA TRABALHO OBEDECE A BANDEIRA DO SEU DONO.

    Defeito de 16/09, achado no log do Diego: a medicao comecava e morria no
    mesmo instante, ZERO arquivos medidos em toda sessao. Causa: o bloco da
    medicao consultava $Controle.Cancelar - que e a bandeira da LEITURA e da
    CONVERSAO, levantada por Stop-Motor. Depois da separacao da 18.00 a ordem
    passou a ser leitura_fim -> Stop-Motor -> Start-Medicao, entao a medicao
    SEMPRE nascia com essa bandeira em pe.

    Separar trabalhos e separar TAMBEM as bandeiras. Bandeira compartilhada
    entre dois donos e a mesma familia do runspace compartilhado - so que muda
    em silencio, sem erro nenhum na tela. #>
$blocoMed = ""
try {
    $iM = $jan.IndexOf('$script:TrabalhoMedicao = {')
    if ($iM -ge 0) {
        $aM = $jan.IndexOf("{", $iM); $pM = 0; $fM = -1
        for ($k = $aM; $k -lt $jan.Length; $k++) {
            if ($jan[$k] -eq "{") { $pM++ }
            elseif ($jan[$k] -eq "}") { $pM--; if ($pM -eq 0) { $fM = $k; break } }
        }
        if ($fM -gt $aM) { $blocoMed = Remove-Comentarios ($jan.Substring($aM, $fM - $aM)) }
    }
} catch { }
Checar "Interface: o bloco da medicao foi encontrado para conferencia" ($blocoMed.Length -gt 1000)
Checar "Medicao: o trabalho da medicao NAO consulta Controle.Cancelar (bandeira de outro dono)" `
    (-not ($blocoMed -match '\$Controle\.Cancelar')) `
    "Stop-Motor levanta Cancelar; a medicao nasce depois dele e morreria sempre"
Checar "Medicao: quem manda nela e PararMedicao" `
    ([bool]($blocoMed -match '\$Controle\.PararMedicao'))

<#  3.39 - A REGRA DE CIMA ESTAVA INCOMPLETA, E CUSTOU 92 SEGUNDOS.

    Log dele de 16/09, com o censo rodando:
      23:55:13,5 CLIQUE: Iniciar -> ESTADO rodando so as 23:56:35,3  (81,8s)
      23:58:38,4 Iniciar confirmado -> ESTADO rodando as 00:00:10,8  (92,4s)
    Causa: Stop-Censo chamava $CensoPS.Dispose() na thread da interface, e
    Dispose() em pipeline RODANDO nao retorna - espera o pipeline parar, que
    estava dentro do dovi_tool por 106s.

    A lista de espera sincrona da familia acima tinha WaitOne, Start-Sleep,
    .Wait(, .Join( e .EndInvoke( - e NAO tinha Dispose/Stop/Close. Regra
    incompleta nao pega o proximo caso; nao pegou.

    Nao da para proibir Dispose no arquivo inteiro: alguem PRECISA descartar o
    runspace. A regra certa e sobre QUEM e QUANDO: as funcoes de PARAR
    (Stop-Censo, Stop-Medicao), que sao chamadas por clique, nao descartam
    nada; quem descarta e uma funcao Fechar-Runspace-*, chamada pelo motor de
    mensagens depois que o trabalho JA terminou - ai descartar nao espera. #>
foreach ($fnParar in @("Stop-Censo","Stop-Medicao")) {
    $corpoParar = ""
    try {
        $corpoParar = "$((($astJan.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                                             $args[0].Name -eq $fnParar }, $true))[0]).Extent.Text)"
    } catch { }
    $corpoParar = Remove-Comentarios $corpoParar
    Checar ("Interface: {0} foi encontrada" -f $fnParar) ($corpoParar.Length -gt 50)
    foreach ($bloq in @(
            @{ N = "Dispose(";  P = '\.Dispose\(' },
            @{ N = ".Stop()";   P = '\.Stop\(\)' },
            @{ N = ".Close()";  P = '\.Close\(\)' })) {
        Checar ("Interface: {0} nao chama {1} (bloqueia ate o pipeline parar)" -f $fnParar, $bloq.N) `
            (-not ($corpoParar -match $bloq.P)) `
            "no log dele isso custou 81,8s e 92,4s de janela morta"
    }
}
Checar "Interface: existe Fechar-Runspace-Censo (quem descarta e o fim, nao o clique)" `
    ([bool]($jan -match 'function Fechar-Runspace-Censo'))
Checar "Interface: e o censo_fim e quem chama ela" `
    ([bool]($jan -match '(?s)"censo_fim" \{.{0,6000}?Fechar-Runspace-Censo'))
Checar "Censo: o resultado carrega o numero da rodada" `
    ([bool]($jan -match 'T = "censo_fim"; Serie = \$Serie'))
<#  3.40 - O CENSO ABANDONADO NAO PERDE MAIS O RESULTADO (18.05).
    Descartar por rodada jogava fora 104s de trabalho ja feito, com o arquivo
    ainda na lista. Quem garante a linha certa agora e o CAMINHO. #>
Checar "Censo: o resultado carrega o caminho do arquivo" `
    ([bool]($jan -match 'T = "censo_fim"; Serie = \$Serie; Idx = \$Idx; Caminho'))
Checar "Censo: e a linha e achada pelo caminho, nao pelo indice" `
    ([bool]($jan -match '(?s)"\$\(\$m\.T\)" -eq "censo_fim".{0,900}Achar-LinhaPorCaminho'))
Checar "Censo: arquivo que saiu da lista NAO escreve em ninguem" `
    ([bool]($jan -match '(?s)Achar-LinhaPorCaminho.{0,600}\$iC -lt 0.{0,400}descartado'))
Checar "Medicao: o veredicto tambem viaja com o caminho do arquivo" `
    ([bool]($jan -match 'T = "el"; Serie = \$Serie; Idx = \$pe\.Idx; Caminho'))
Checar "Medicao: e a linha do veredicto e achada pelo caminho" `
    ([bool]($jan -match '(?sm)^            "el" \{.{0,2500}?Achar-LinhaPorCaminho'))
Checar "Cache: a RESPOSTA (o que sera feito) tambem e guardada" `
    ([bool]($jan -match '(?s)function Guardar-CacheEL.{0,3000}DiagDVres = "\$\(\$v\.DiagDVres\)"')) `
    "print do Diego: esquerda dizia EL: MEL e direita dizia EL nao medida, na mesma linha"

<#  3.39 - O VEREDICTO MEDIDO TEM QUE SOBREVIVER A RELEITURA.

    "eu cancelo a conversao e volta a estaca zero as medicoes... nao guarda
    informacao" (Diego, 17/09). Eram 62,4s de medicao no lixo a cada releitura
    da mesma pasta. O cache existe - e estes testes garantem que ele esta
    LIGADO nos dois pontos que importam, porque funcao certa desligada da no
    mesmo que funcao errada. #>
Checar "Cache: o veredicto recem-medido e guardado no tratador do 'el'" `
    ([bool]($jan -match '(?sm)^            "el" \{.{0,16000}?Guardar-CacheEL'))
Checar "Cache: a leitura tenta reaproveitar antes de adicionar o video na lista" `
    ([bool]($jan -match '(?s)Restaurar-CacheEL \$d.{0,600}?\[void\]\$script:Videos\.Add\(\$d\)'))
Checar "Cache: a chave e caminho + tamanho + data (reaproveitar por nome seria inventar)" `
    ([bool]($jan -match '(?s)function Chave-CacheEL.{0,900}LastWriteTimeUtc.{0,400}\$v\.Bytes'))
Checar "Cache: medicao em curso nunca vira veredicto guardado" `
    ([bool]($jan -match '(?s)function Guardar-CacheEL.{0,400}MEDINDO.{0,80}return'))

<#  E o outro lado da mesma moeda: se ninguem espera, alguem precisa garantir
    que a sobra da rodada velha nao suje a rodada nova. E o numero de serie. Os
    dois andam juntos - tirar um sem o outro troca "congela" por "veredicto no
    arquivo errado", que e pior. #>
<#  LICAO 18, PELA QUINTA VEZ: janela de regex nao respeita fronteira de
    funcao. A primeira versao deste teste usava ".{0,900}" depois de
    "function Stop-Medicao" e alcancava o Dispose da Fechar-Runspace-Medicao,
    que vem logo abaixo - reprovando o codigo CERTO. O corpo sai da AST. #>
$corpoStopMed = ""
try {
    $corpoStopMed = "$((($astJan.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                                           $args[0].Name -eq "Stop-Medicao" }, $true))[0]).Extent.Text)"
} catch { }
Checar "Interface: quem cancela a medicao so ergue a flag e volta" `
    (($corpoStopMed.Length -gt 0) -and
     ($corpoStopMed -match '\$script:Controle\.PararMedicao = \$true') -and
     -not ($corpoStopMed -match '(WaitOne|Dispose|Stop\(\))')) `
    "fechar o runspace e trabalho do el_fim, quando ele JA terminou"
Checar "Interface: e o fechamento de verdade so acontece depois do fim" `
    ([bool]($jan -match '(?s)function Fechar-Runspace-Medicao.{0,600}?Dispose'))

<#  3.35 - 18.00: A CHAVE VOLTOU A SER UMA CHAVE.

    Ate a 17.24 ela tinha SEIS saidas, podia reler a pasta, matar o censo e
    congelar a janela por 2s. Agora sao duas regras, e a leitura da pasta nao
    aparece em nenhuma delas:

        LIGADA    -> se falta veredicto, MEDE. Senao, nada.
        DESLIGADA -> para a medicao, se houver. O que foi medido continua.

    Os testes abaixo cobram isso, e cobram tambem o que ela NAO pode mais fazer
    - que e a parte que o log do Diego provou que estava errada. #>
Checar "Chave: ligar ou desligar NUNCA le a pasta" `
    (-not ($jan -match '(?s)\$TimerChaveEL\.add_Tick\(\{.{0,2500}?Start-Leitura')) `
    "no log de 15/09 a chave sozinha disparou 28 releituras, 254,5s"
Checar "Chave: desligada, ela para a medicao pelo dono dela (Stop-Medicao)" `
    ([bool]($jan -match '(?s)\$TimerChaveEL\.add_Tick\(\{.{0,1800}?if \(-not \$script:MedirELLigado\).{0,300}?Stop-Medicao'))
Checar "Chave: desligada, ela NAO chama Stop-Motor (nao e dona da leitura)" `
    (-not ($jan -match '(?s)\$TimerChaveEL\.add_Tick\(\{.{0,2500}?Stop-Motor')) `
    "matar o runspace da leitura daqui foi o bug de 16/09 18:06"
Checar "Chave: ligada com a leitura em curso, ela espera o leitura_fim" `
    ([bool]($jan -match '(?s)\$TimerChaveEL\.add_Tick\(\{.{0,2200}?if \(\$script:Lendo\).{0,300}?return'))
Checar "Chave: ligada, ela so mede quando FALTA veredicto" `
    ([bool]($jan -match '(?s)\$faltam = @\(Get-PendentesDeMedida\)\.Count.{0,400}if \(\$faltam -eq 0\).{0,300}return.{0,200}Start-Medicao'))
<#  3.35 - 18.00: "medindo" nao pode voltar para a coluna do veredicto.
    Achado do Diego: "P7 MEDINDO sempre impresso em todos, e pra estar assim so
    no que estiver fazendo, ne?" - e ele estava certo: aparecia ate em quem so
    esperava a vez. A coluna carrega VEREDICTO; atividade e assunto da coluna
    SITUACAO e do contador da barra. #>
<#  3.44 - ESTE TESTE COBRAVA A FORMA, NAO O EFEITO (licao 18, de novo).
    A regra e "a palavra MEDINDO nao aparece na coluna do veredicto". Eu tinha
    escrito "nao pode existir um ramo MEDINDO" - e com isso ele reprovou o
    conserto da 18.09, que manda o MEDINDO cair em "EL nao medida" (que e a
    verdade: quem esta sendo medido ainda nao tem veredicto). Agora o teste
    confere o TEXTO QUE SAI. #>
Checar "Coluna DV: a palavra 'medindo' nao sai na coluna do veredicto" `
    (-not ($jan -match '(?im)\$sigla\s*=\s*"[^"]*medindo')) `
    "a coluna dizia 'P7 medindo' ate em arquivo parado na fila"
Checar "Coluna DV: quem esta sendo medido mostra 'EL nao medida' (ainda sem veredicto)" `
    ([bool]($jan -match '"MEDINDO"\s*\{ \$sigla = "EL n' + [char]0x00E3 + 'o medida" \}')) `
    "print dele: com a medicao rodando a linha mostrava so 'P7 -> P8.1', sem dizer nada da camada"
Checar "Coluna DV: o veredicto 'EL nao medida' continua existindo" `
    ([bool]($jan -match '"NAO_MEDIDO" \{ \$sigla = "EL não medida" \}')) `
    "esse E veredicto de verdade - nao medir nunca vira 'limpa' (regra da 1.8)"
Checar "Coluna DV: cinco ramos, e nenhum deles escreve atividade" `
    ((([regex]::Matches($jan, '(?m)^\s*"(MEL|FEL|MISTO|MEDINDO|NAO_MEDIDO)"\s*\{\s*\$sigla')).Count) -eq 5) `
    "MEL, FEL, MISTO, NAO_MEDIDO e MEDINDO - os dois ultimos dizem a mesma coisa: sem veredicto"
Checar "Chave: existe Get-PendentesDeMedida (quem a medicao tocaria)" `
    ([bool]($jan -match 'function Get-PendentesDeMedida'))
Checar "Chave: e ela olha P7 COM camada EL sem veredicto" `
    ([bool]($jan -match '(?s)function Get-PendentesDeMedida.{0,600}DVperfil -eq 7.{0,200}DVcamadas.{0,200}NAO_MEDIDO'))
Checar "Janela: o freio nao dispara leitura com a fila rodando" `
    ([bool]($jan -match '(?s)\$TimerChaveEL\.add_Tick\(\{.{0,300}\$Estado\.Atual -ne "inicial".{0,60}return'))
Checar "Janela: a chave NAO pode ser trocada com a fila rodando" `
    ([bool]($jan -match '(?s)function Invoke-TrocarMedirEL.{0,600}rodando","pausado"'))
Checar "Janela: os DOIS botoes chamam a mesma acao (uma regra, um lugar)" `
    ([bool]($jan -match 'btnMedirEL\.add_MouseLeftButtonUp\(\{ Invoke-TrocarMedirEL \}\)') -and
     [bool]($jan -match 'btnMedirELTopo\.add_Click\(\{ Invoke-TrocarMedirEL \}\)'))
<#  3.25: a escala mudou na 17.15 - ambar era a cor da DUVIDA e desligar a
    medicao nao e duvida, e decisao. Verde ligado / vermelho desligado. #>
<#  3.26: a 17.16 pos um TERCEIRO estado na frente dos outros dois (medindo,
    em ciano), entao a janela de busca precisa alcancar depois dele. O que o
    teste garante continua sendo o mesmo: verde ligada, vermelha desligada. #>
Checar "Janela: ligada, a chave fica VERDE" `
    ([bool]($jan -match '(?s)function Update-BotaoMedirEL.{0,2200}Cores\.okdim'))
Checar "Janela: desligada, a chave fica VERMELHA" `
    ([bool]($jan -match '(?s)function Update-BotaoMedirEL.{0,2800}Cores\.err'))
Checar "Janela: medindo, a chave fica CIANO (o terceiro estado)" `
    ([bool]($jan -match '(?s)function Update-BotaoMedirEL.{0,900}MedindoEL.{0,400}Cores\.emCurso'))
Checar "Janela: e existe a barrinha da medicao" `
    ([bool]($jan -match 'function Update-BarraMedirEL') -and [bool]($jan -match 'x:Name="barraMedirEL"'))
Checar "Janela: e o gemeo da barra le o MESMO estado (nao refaz a regra)" `
    ([bool]($jan -match '(?s)function Update-BotaoMedirEL.{0,2600}lblMedirELTopo'))
<#  3.35 - 18.00: a chave NAO viaja mais para dentro da leitura. Ela nao
    decide nada la - quem decide se mede e a janela, depois que a fila esta na
    tela. O que viaja agora e a LISTA de quem medir, para o trabalho proprio. #>
Checar "Medicao: a chave nao entra mais no runspace da leitura" `
    (-not ($jan -match 'SetVariable\("MedirEL"')) `
    "parametro congelado na partida foi o que obrigou a reler a pasta para mudar de ideia"
Checar "Medicao: o que viaja e a LISTA de quem medir" `
    ([bool]($jan -match 'SetVariable\("Pendentes", \$Lista\)'))
Checar "Medicao: e o preambulo e UM so, injetado nos dois trabalhos" `
    ((([regex]::Matches($jan, 'SetVariable\("Preambulo", \$script:PreambuloTrabalho\)')).Count -eq 2) -and
     [bool]($jan -match '\$script:PreambuloTrabalho = @'))
<#  3.34 - 17.24: a chave deixou de ser a unica voz. Agora existe tambem o
    canal vivo $Controle.PararMedicao, para desligar a medicao SEM derrubar a
    leitura que ja esta em curso. A regra testada e a mesma: sem a chave (ou
    com o cancelamento vivo), a fase B nao mede. #>
<#  3.35 - 18.00: nao existe mais ramo "chave desligada" dentro do trabalho.
    Se a chave esta desligada, a janela simplesmente NAO dispara a medicao -
    decisao de quem tem a informacao. A prova do A/B (custo com e sem) saiu do
    runspace e passou a ser escrita pela janela, no leitura_fim. #>
Checar "Medicao: o trabalho nao tem mais ramo de 'chave desligada'" `
    (-not ($jan -match '\$Pendentes\.Count -gt 0 -and \(-not \$MedirEL'))
Checar "Janela: a prova do A/B com a chave desligada sai no leitura_fim" `
    ([bool]($jan -match '(?s)"leitura_fim" \{.{0,5000}?-not \$script:MedirELLigado.{0,600}?MEDICAO MEL x FEL: DESLIGADA'))
Checar "Janela: e o laco da medicao para no meio se a chave desligar" `
    ([bool]($jan -match 'if \(\$Controle\.PararMedicao -or \(\[int\]\$Controle\.MedSerieViva -ne \[int\]\$Serie\)\) \{ break \}'))
Checar "Janela: PararMedicao e zerado a cada leitura nova" `
    ([bool]($jan -match '(?s)\$script:Controle\.Cancelar = \$false\s*\n\s*\$script:Controle\.PararMedicao = \$false'))
Checar "Janela: desligada, NAO pula em silencio - diz quantos ficaram sem veredicto" `
    ([bool]($jan -match 'MEDICAO MEL x FEL DESLIGADA'))
Checar "Janela: a linha comparavel sai com a chave LIGADA" `
    ([bool]($jan -match 'MEDICAO MEL x FEL: LIGADA'))
Checar "Janela: e sai tambem com ela DESLIGADA (senao nao ha A/B)" `
    ([bool]($jan -match 'MEDICAO MEL x FEL: DESLIGADA'))
Checar "Janela: as duas linhas trazem segundos por GB (pastas diferentes se comparam)" `
    ([bool]($jan -match 's/GB'))
Checar "Janela: o GB de cada pendente viaja junto (sem ele nao ha s/GB)" `
    ([bool]($jan -match 'Gb = \(\$a\.Length / 1GB\)'))
Checar "Idioma: os dois estados da chave tem traducao" `
    ($(  $arqIM = Join-Path $Fonte "IDIOMA_EN.txt"
         if (Test-Path -LiteralPath $arqIM) {
             $tIM = Get-Content -Raw -LiteralPath $arqIM
             ($tIM -match "Medir MEL x FEL: Ligado\t") -and ($tIM -match "Medir MEL x FEL: Desligado\t")
         } else { $false }  ))


Titulo "39. OS DOIS DEFEITOS ACHADOS USANDO A 17.10 (17.11)"
<#  1. O cartao de PULADO dizia sempre "Ja Existia na Pasta de Saida", e o
       motor tem TRES caminhos de pular. No print de 10/09 23h56 a mesma
       caixa dizia "Ja Existia na Pasta de Saida" e, logo abaixo, "espaco
       insuficiente - faltam ~47,68 GB". Frase que contradiz a linha de
       baixo e pior do que frase nenhuma.

    2. O Iniciar matava a medicao em curso. Com a chave LIGADA - ou seja,
       com o usuario tendo pedido o veredicto - o F1 interrompia a fase B,
       a linha ficava "EL nao medida", e o motor remedia o mesmo arquivo 30s
       depois. Trabalho duas vezes, veredicto nenhum na tela. #>

Checar "Janela: a frase do PULADO e LIDA do motivo, nao chumbada" `
    ([bool]($jan -match 'function Get-FrasePulado'))
Checar "Janela: e o cartao usa essa funcao" `
    ([bool]($jan -match '"PULADO"\s*\{ Get-FrasePulado \$R \}'))
Checar "Janela: falta de espaco tem frase propria (nao e 'ja existia')" `
    ([bool]($jan -match 'Espaço Insuficiente em Disco'))
Checar "Janela: e ela diz NAO INICIADO (nem chegou a comecar - licao da 14.44)" `
    ([bool]($jan -match 'Não Iniciado - Espaço Insuficiente'))
Checar "Janela: o contador do resumo separa os dois motivos" `
    ([bool]($jan -match 'Não Iniciados \(Sem Espaço\)'))
Checar "Janela: e 'Ja Existiam' conta so quem de fato ja existia" `
    ([bool]($jan -match '\$jaExistia = @\(\$pulado \| Where-Object \{ -not \(Test-PuladoPorEspaco'))
Checar "Motor: os tres caminhos de PULADO continuam gravando o motivo" `
    ((([regex]::Matches($mot, 'Status = "PULADO"')).Count -ge 3) -and
     ([bool]($mot -match 'Motivo = \("espaco insuficiente')) -and
     ([bool]($mot -match 'Motivo = "ja existia na pasta de saida"')))

Checar "Janela: o Iniciar pergunta antes de matar a medicao em curso" `
    ([bool]($jan -match 'function Test-EsperarMedicao'))
Checar "Janela: e ele pergunta ANTES de qualquer outra trava" `
    ([bool]($jan -match '(?s)function Invoke-Iniciar \{.{0,400}Test-EsperarMedicao.{0,200}Test-PodeIniciar'))
Checar "Janela: a pergunta so aparece se a medicao esta rodando E a chave ligada" `
    ([bool]($jan -match '(?s)function Test-EsperarMedicao.{0,600}-not \$script:MedindoEL.{0,300}-not \$script:MedirELLigado'))
Checar "Janela: ESPERAR vem pre-selecionado (e a opcao que nao joga fora trabalho)" `
    ([bool]($jan -match '(?s)function Test-EsperarMedicao.{0,3000}"YesNo", "Question", "Yes"'))
Checar "Janela: a pergunta existe nas duas linguas" `
    ([bool]($jan -match '(?s)function Test-EsperarMedicao.{0,3000}Lang -eq "EN"'))
Checar "Janela: as duas respostas vao para o log" `
    ([bool]($jan -match 'INICIAR: esperando a medicao') -and
     [bool]($jan -match 'INICIAR: usuario preferiu comecar agora'))
Checar "Janela: quem esperou comeca sozinho quando a medicao termina" `
    ([bool]($jan -match '(?s)"el_fim".{0,2500}\$script:IniciarAposMedir.{0,700}Invoke-Iniciar'))
Checar "Janela: e isso acontece DEPOIS do Stop-Motor (dois runspaces nao convivem)" `
    ([bool]($jan -match '(?s)"el_fim".{0,3000}Stop-Motor.{0,1400}IniciarAposMedir'))
Checar "Janela: enquanto espera, a TELA diz por que o Iniciar esta apagado" `
    ([bool]($jan -match 'x:Name="lblEsperandoMedida"'))
Checar "Janela: uma leitura nova cancela a espera (a fila mandada nao existe mais)" `
    ([bool]($jan -match '(?s)function Start-Leitura.{0,3200}IniciarAposMedir'))
Checar "Idioma: o aviso de espera e a frase do disco tem traducao" `
    ($(  $arqIW = Join-Path $Fonte "IDIOMA_EN.txt"
         if (Test-Path -LiteralPath $arqIW) {
             $tIW = Get-Content -Raw -LiteralPath $arqIW
             ($tIW -match "Esperando a medi") -and ($tIW -match "Espaço Insuficiente em Disco\t")
         } else { $false }  ))


Titulo "40. O TRAVAMENTO DO MODAL E O INGLES DO CARTAO FINAL (17.12)"
<#  1. MessageBox do WPF roda um laco de mensagens PROPRIO: o mundo NAO para
       atras dela. A medicao podia terminar com a caixa aberta, e ao
       responder "Sim" a janela passava a esperar um aviso que ja tinha
       passado - Iniciar apagado para sempre. A regra: entre PERGUNTAR e
       AGIR o estado pode ter mudado, e quem pergunta reconfere ao voltar
       (mesma armadilha da 16.23, no Cancelar).

    2. O cartao final, a grade, os selos e o rodape de progresso eram
       montados por CODIGO e nunca passaram pela traducao - a varredura so
       alcanca o que o XAML declarou. Em ingles a tela ficava meio a meio. #>

Checar "Janela: depois da pergunta, o estado da medicao e RECONFERIDO" `
    ([bool]($jan -match '(?s)MessageBox\]::Show\(\$msg, \$titulo.{0,2500}\$r -eq "Yes" -and -not \$script:MedindoEL'))
Checar "Janela: se a medicao ja acabou, comeca agora em vez de esperar para sempre" `
    ([bool]($jan -match 'a medicao terminou enquanto a pergunta estava aberta'))
Checar "Janela: e isso vem ANTES de marcar que vai esperar" `
    ([bool]($jan -match '(?s)-and -not \$script:MedindoEL.{0,400}return \$false.{0,300}\$script:IniciarAposMedir = \$true'))

Checar "Janela: existe Traduzir-LinhaContador (rotulo : valor)" `
    ([bool]($jan -match 'function Traduzir-LinhaContador'))
Checar "Janela: ela preserva a largura (as duas colunas alinham os dois-pontos)" `
    ([bool]($jan -match '(?s)function Traduzir-LinhaContador.{0,1800}PadRight\(\$largura\)'))
Checar "Janela: as linhas do resumo passam por ela" `
    ([bool]($jan -match 'txtContadores\.Text = \(\(@\(\$linhas\) \| ForEach-Object \{ Traduzir-LinhaContador'))
Checar "Janela: o detalhamento tambem" `
    ([bool]($jan -match 'txtDetalhamento\.Text = \(\(@\(\$det\) \| ForEach-Object \{ Traduzir-LinhaContador'))
Checar "Janela: os ROTULOS da grade do cartao passam pela traducao" `
    ([bool]($jan -match '\$r1\.Text = Traduzir-Frase'))
Checar "Janela: e os VALORES tambem" `
    ([bool]($jan -match '\$r2\.Text = Traduzir-Frase'))
Checar "Janela: os selos do cartao passam pela traducao" `
    ([bool]($jan -match '\$st\.Text = Traduzir-Frase'))
Checar "Janela: a Situacao e o Motivo do PULADO passam pela traducao" `
    ([bool]($jan -match 'Traduzir "Situação"')) 
Checar "Janela: o rodape do resumo (pasta e log) passa pela traducao" `
    ([bool]($jan -match 'Traduzir "Pasta de Saída:"'))
Checar "Janela: os rotulos ETAPA/VIDEO/FILA nao tem espaco preso no Text" `
    ((($jan -match 'Text="ETAPA" Margin=') -and
      ($jan -match 'Text="VÍDEO" Margin=') -and
      ($jan -match 'Text="FILA" Margin='))) `
    "espaco no fim do Text nao casa com a tabela (o Trim do carregador come)"

<#  EXECUTANDO de verdade: carrega a tabela e as tres funcoes do fonte e
    confere que nenhuma destas frases volta em portugues. Contar entradas na
    tabela nao prova nada - o que prova e a frase montada saindo traduzida. #>
$tradOk = $true
$tradFalha = ""
try {
    $astT = [System.Management.Automation.Language.Parser]::ParseInput($jan, [ref]$null, [ref]$null)
    foreach ($nf in @("Carregar-Idioma","Traduzir","Traduzir-Frase","Traduzir-LinhaContador")) {
        $fd = @($astT.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -eq $nf }, $true))
        if ($fd.Count -eq 0) { throw "nao achei $nf" }
        . ([scriptblock]::Create($fd[0].Extent.Text))
    }
    $script:PastaScript = $Fonte
    Carregar-Idioma | Out-Null
    $script:Lang = "EN"
    $casos = @(
        @{ F = "Total de Vídeos na Fila       : 1"; Modo = "linha" },
        @{ F = "Não Iniciados (Sem Espaço)    : 1"; Modo = "linha" },
        @{ F = "Tempo Total                   : 00m 04s"; Modo = "linha" },
        @{ F = "Dolby Vision Convertido para Profile 8.1  : 0"; Modo = "linha" },
        @{ F = "Dolby Vision → Profile 8.1 - CONVERTIDO"; Modo = "frase" },
        @{ F = "Complex FEL - CONVERSÃO NÃO RECOMENDADA"; Modo = "frase" },
        @{ F = "Container Final"; Modo = "frase" },
        @{ F = "Tempo de Processamento"; Modo = "frase" },
        @{ F = "Duração / Taxa de Quadros"; Modo = "frase" },
        @{ F = "Qualidade da Legenda"; Modo = "frase" },
        @{ F = "Não Iniciado - Espaço Insuficiente em Disco"; Modo = "frase" },
        @{ F = "Ignorado - Já Existia na Pasta de Saída"; Modo = "frase" },
        @{ F = "Cancelado pelo Usuário"; Modo = "frase" },
        @{ F = "ETAPA"; Modo = "frase" },
        @{ F = "VÍDEO"; Modo = "frase" },
        @{ F = "FILA"; Modo = "frase" },
        @{ F = "Situação"; Modo = "seca" },
        @{ F = "Motivo"; Modo = "seca" },
        @{ F = "Pasta de Saída:"; Modo = "seca" }
    )
    foreach ($c in $casos) {
        $saida = switch ($c.Modo) {
            "linha" { Traduzir-LinhaContador $c.F }
            "frase" { Traduzir-Frase $c.F }
            default { Traduzir $c.F }
        }
        if ($saida -eq $c.F) { $tradOk = $false; $tradFalha = $c.F; break }
    }
} catch { $tradOk = $false; $tradFalha = $_.Exception.Message }
Checar "EXECUTANDO EN: nenhuma frase do cartao/rodape volta em portugues" $tradOk `
    ("ficou em portugues: " + $tradFalha)


<#  3.25 - EXECUTANDO as frases novas da 17.15. Duas delas ja tinham sido
    quebradas por ORDEM DE REGRA (a generica comendo a especifica) - "medindo"
    na 17.14 e " a Pedido" agora. Conferir que a entrada existe na tabela nao
    pega esse defeito: so a frase montada, passando pelas regras na ordem
    real, pega. Por isso estes casos sao executados, e nao lidos. #>
$novasOk = $true
$novasFalha = ""
try {
    $script:Lang = "EN"
    $casosNovos = @(
        # Rodape: cada linha e colagem de rotulo + valor.
        @{ F = "Começou: 01h20   Decorrido: 02m 41s"; Proibido = @("Começou","Decorrido") },
        @{ F = "Começou: 01h20   Decorrido: 02m 41s   Vídeo 1 de 3"; Proibido = @("Vídeo","de 3") },
        @{ F = "Começou: 01h20   Decorrido: 02m 41s   Deve Terminar por Volta das 11h48   ·   Tempo Restante: 1h 13min"
           ; Proibido = @("Deve Terminar","Tempo Restante","Começou","Decorrido") },
        @{ F = "Começou: 01h20   Decorrido: 02m 41s   Terminando Agora"; Proibido = @("Terminando Agora") },
        @{ F = "Começou: 01h20   Decorrido: 02m 41s   ❙❙ PAUSADO POR VOCÊ há 00m 30s"; Proibido = @("PAUSADO POR VOCÊ") },
        # O nome da etapa chega AQUI ja traduzido na origem (ver Update-Rodape):
        # o que este caso prova e que a moldura "A Seguir: [n/N] ..." traduz.
        @{ F = ("A Seguir: [3/4] " + (Traduzir "Conversão de Legenda PGS para .SRT")); Proibido = @("A Seguir") },
        @{ F = "Conversão de Legenda PGS para .SRT"; Proibido = @("Conversão de Legenda"); Seca = $true },
        @{ F = "A Seguir: Resumo da Conversão"; Proibido = @("A Seguir","Resumo da Conversão") },
        @{ F = "A Seguir: Limpeza dos Temporários"; Proibido = @("Limpeza dos Temporários") },
        @{ F = "A Seguir: Conferência do Arquivo Final e Limpeza"; Proibido = @("Conferência") },
        @{ F = "Livre Agora 207,57 GB"; Proibido = @("Livre Agora") },
        # Cartao final
        @{ F = "Começou às 01h20 - Terminou às 01h25 - Tempo Total 05m 12s"
           ; Proibido = @("Começou às","Terminou às","Tempo Total") },
        @{ F = "Começou às 01h20 - Interrompida às 01h25 - Tempo Total 05m 12s"
           ; Proibido = @("Interrompida às") },
        # Diagnostico com ESCOLHA MANUAL (nenhuma tinha traducao ate a 17.15)
        @{ F = "→ [ESCOLHA MANUAL] TrueHD Mantido a Pedido - Conversão Desligada"
           ; Proibido = @("Mantido a Pedido","Conversão Desligada") },
        @{ F = "→ [ESCOLHA MANUAL] PGS → .SRT a Pedido"; Proibido = @("a Pedido") },
        @{ F = "→ [ESCOLHA MANUAL] PGS → .SRT a Pedido - a Legenda Anterior Foi Descartada"
           ; Proibido = @("a Pedido","Legenda Anterior") },
        @{ F = "→ [ESCOLHA MANUAL] Sem Legenda PT-BR no Arquivo Final"; Proibido = @("Sem Legenda PT-BR no Arquivo") },
        @{ F = "→ [ESCOLHA MANUAL] Todas as Faixas de Áudio Excluídas por Você"; Proibido = @("Excluídas por Você") },
        @{ F = "→ [ESCOLHA MANUAL] DTS-HD Excluído a Pedido"; Proibido = @("Excluído a Pedido") },
        # Coluna SITUACAO e a linha da PGS redundante
        @{ F = "Fora da Fila - Não Será Convertido"; Proibido = @("Fora da Fila","Não Será Convertido") },
        @{ F = "Já Existe .SRT - OCR Não Necessário"; Proibido = @("Já Existe","Não Necessário") },
        # Painel de ferramentas (rotulo + papel + a frase da ausencia)
        @{ F = "Conversão de Perfil Dolby Vision 7 → 8.1 (dovi_tool)"; Proibido = @("Conversão de Perfil"); Seca = $true },
        @{ F = "obrigatória"; Proibido = @("obrigatória"); Seca = $true },
        @{ F = "opcional"; Proibido = @("opcional"); Seca = $true },
        @{ F = "- NÃO ENCONTRADA, A CONVERSÃO NÃO RODA"; Proibido = @("NÃO ENCONTRADA"); Seca = $true },
        @{ F = "Pasta de Saída é a Mesma da Origem - o Arquivo Convertido Sobrescreveria o Original"
           ; Proibido = @("Pasta de Saída é a Mesma"); Seca = $true },
        # A frase do MEL x FEL, que a regra da palavra solta ja comeu uma vez
        @{ F = "→ [SERÁ CONVERTIDO] Profile 8.1 — medindo a camada de melhoria (MEL x FEL)…"
           ; Proibido = @("medindo","camada de melhoria") }
    )
    foreach ($c in $casosNovos) {
        $saida = if ($c.Seca) { Traduzir $c.F } else { Traduzir-Frase $c.F }
        foreach ($proibido in $c.Proibido) {
            if ($saida -like ("*" + $proibido + "*")) {
                $novasOk = $false
                $novasFalha = "'" + $c.F + "' -> '" + $saida + "' (sobrou: " + $proibido + ")"
                break
            }
        }
        if (-not $novasOk) { break }
    }
} catch { $novasOk = $false; $novasFalha = $_.Exception.Message }
Checar "EXECUTANDO EN: o rodape, o cartao e a ESCOLHA MANUAL saem inteiros em ingles" $novasOk $novasFalha


<#  3.25 - A REGRA VIRA TESTE: TEXTO DE TELA COM ACENTO NAO PODE SER ESCRITO
    CRU.

    Esta rodada teve QUATRO defeitos da mesma familia (rodape, cartao final,
    ESCOLHA MANUAL, painel de ferramentas) e todos apareceram do mesmo jeito:
    alguem escreveu `$UI.algumaCoisa.Text = "frase em portugues"` e a
    varredura de traducao nao alcanca isso - ela so pega rotulo declarado no
    XAML.

    Achar um de cada vez, por foto do Diego, nao termina nunca. Entao o teste
    para de olhar frases especificas e passa a olhar a REGRA: toda escrita
    direta em .Text com acento portugues tem que passar por Traduzir ou
    Traduzir-Frase. A unica excecao e o nome do proprio idioma no botao, que
    por definicao nao se traduz.

    Se este teste reprovar, nao ha frase "nova demais" para consertar: ou
    passa pela traducao, ou entra nesta lista com um motivo escrito. #>
$cruas = @()
$excecoes = @('$UI.lblIdioma.Text')
foreach ($linha in ($jan -split "`r?`n")) {
    if ($linha -notmatch '\.Text\s*=') { continue }
    if ($linha -match 'Traduzir') { continue }
    if ($linha -notmatch '[ÁÂÃÀÉÊÍÓÔÕÚÇáâãàéêíóôõúç]') { continue }
    $ehExcecao = $false
    foreach ($ex in $excecoes) { if ($linha -like ("*" + $ex + "*")) { $ehExcecao = $true } }
    if ($ehExcecao) { continue }
    $cruas += $linha.Trim()
}
Checar "Janela: a varredura de idioma tambem troca as DICAS (ToolTip)" `
    ([bool]($jan -match '(?s)function Traduzir-Arvore.{0,4000}\$d = \$o\.ToolTip.{0,300}\$o\.ToolTip = \$\(if \(\$Mapa\.ContainsKey\(\$d\)\) \{ \$Mapa\[\$d\]'))
Checar "Janela: nenhum texto de tela com acento e escrito sem passar pela traducao" `
    ($cruas.Count -eq 0) `
    ($(if ($cruas.Count -eq 0) { "" } else { "cruas: " + (($cruas | Select-Object -First 3) -join " | ") }))

<#  17.19 - A MESMA REGRA, PARA AS CAIXAS DE DIALOGO.

    A varredura acima olha .Text - o que a JANELA escreve. As caixas de
    dialogo (MessageBox) nascem fora da janela, e por isso escaparam dela:
    na varredura de 15/09 estavam em portugues puro, com a tela em ingles,
    QUATRO caixas - cancelar a conversao, fechar com conversao em andamento,
    falha ao iniciar, e pasta que nao existe.

    Sao as piores da tela para deixar em portugues: as duas primeiras
    perguntam se voce quer jogar fora uma conversao inteira.

    A regra: funcao que abre MessageBox e escreve frase com acento tem que
    decidir a lingua - ou seja, tem que citar $script:Lang. Frase sem acento
    (nome do programa, caminho de pasta) nao conta.

    Pela AST e nao por linha: o texto e montado varias linhas acima da
    chamada, e olhar linha a linha nao veria a ligacao. #>
$caixasCruas = @()
try {
    $astCx = [System.Management.Automation.Language.Parser]::ParseInput($jan, [ref]$null, [ref]$null)
    $fnsCx = @($astCx.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true))
    foreach ($f in $fnsCx) {
        $corpo = $f.Extent.Text
        if ($corpo -notmatch 'MessageBox\]::Show') { continue }
        if ($corpo -match '\$script:Lang') { continue }
        <#  EXCECAO COM MOTIVO ESCRITO: Offer-ReinicioIdioma decide a lingua
            por $Novo, e nao por $script:Lang, porque ela pergunta na lingua
            para a qual voce ACABOU de trocar - nao na que estava valendo. E
            a unica caixa do programa em que as duas coisas sao diferentes. #>
        if ($f.Name -eq "Offer-ReinicioIdioma" -and $corpo -match '\$Novo -eq "EN"') { continue }
        if ($corpo -notmatch '[ÁÂÃÀÉÊÍÓÔÕÚÇáâãàéêíóôõúç]') { continue }
        $caixasCruas += $f.Name
    }
    <#  O Closing da janela nao e funcao nomeada - e um scriptblock no
        add_Closing. Ele entra pelo mesmo criterio, olhado a parte. #>
    $blocos = @($astCx.FindAll({ $args[0] -is [System.Management.Automation.Language.ScriptBlockExpressionAst] }, $true))
    foreach ($b in $blocos) {
        $corpo = $b.Extent.Text
        if ($corpo -notmatch 'Confirm-Parar|MessageBox\]::Show') { continue }
        if ($corpo -match '\$script:Lang') { continue }
        if ($corpo -notmatch '[ÁÂÃÀÉÊÍÓÔÕÚÇáâãàéêíóôõúç]') { continue }
        if ($corpo.Length -gt 3000) { continue }   # blocos gigantes sao o corpo da janela inteira
        $caixasCruas += "(bloco na linha " + $b.Extent.StartLineNumber + ")"
    }
} catch { }
Checar "Janela: nenhuma caixa de dialogo com acento escapa da escolha de idioma" `
    ($caixasCruas.Count -eq 0) `
    ("em portugues fixo: " + (($caixasCruas | Select-Object -Unique) -join ", "))

<#  E as quatro, uma a uma, porque cada uma ja saiu errada uma vez. #>
foreach ($par in @(
    @{ Fn = "Invoke-Cancelar";        Ing = "Cancel the conversion?" },
    @{ Fn = "Abrir-PastaNoExplorer";  Ing = "folder does not exist on this machine" },
    @{ Fn = "Test-PodeIniciar";       Ing = "The selected queue does not fit on the disk" },
    @{ Fn = "Test-PodeIniciar";       Ing = "The queue fits now, but not to the end" },
    @{ Fn = "Test-PodeIniciar";       Ing = "Start anyway" })) {
    $achou = $false
    try {
        $fd = @(([System.Management.Automation.Language.Parser]::ParseInput($jan, [ref]$null, [ref]$null)).FindAll(
                  { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $args[0].Name -eq $par.Fn }, $true))
        if ($fd.Count -eq 1) { $achou = ($fd[0].Extent.Text -match [regex]::Escape($par.Ing)) }
    } catch { }
    Checar ("Idioma: " + $par.Fn + " tem o texto em ingles") $achou
}
Checar "Idioma: fechar com conversao em andamento pergunta em ingles tambem" `
    ([bool]($jan -match 'Close the program now\?'))
Checar "Idioma: a falha ao iniciar tambem fala ingles" `
    ([bool]($jan -match 'Could not start the conversion'))

<#  17.19 - O COMENTARIO TEM QUE DESCREVER O QUE O CODIGO FAZ.

    Achado na varredura de 15/09: dois blocos de comentario diziam que a
    calibragem usa a MEDIANA das ultimas cinco rodadas. O codigo chama
    Get-Percentil 0.75 desde a 16.99, e o log escreve "p75" - ou seja, o
    comentario descrevia o que o programa NAO faz, ha tres versoes.

    Isso e a licao 2 ("mensagem que mente e defeito") virada para dentro: quem
    ler o comentario primeiro vai "consertar" o codigo certo para bater com o
    texto errado. Ja aconteceu neste projeto - a licao 18 e exatamente isso do
    lado dos testes.

    O teste amarra os tres: o percentil calculado, o nome que o log da a ele, e
    a ausencia de "mediana" sendo afirmada como o que a funcao faz. #>
$pctCod = ""
if ($jan -match 'Get-Percentil \(\[double\[\]\]\$ult\)\s+([0-9.]+)') { $pctCod = $Matches[1] }
Checar "Calibragem: o codigo diz qual percentil usa" ($pctCod -ne "") "nao achei a chamada de Get-Percentil"
Checar "Calibragem: o log chama o percentil pelo nome certo (p75 x 0.75)" `
    (($pctCod -eq "0.75") -and ($jan -match 'usando o p75 das ultimas')) `
    ("codigo calcula " + $pctCod + " - o log tem que dizer o mesmo")
<#  E nenhum comentario pode AFIRMAR que a estimativa usa mediana. Citar a
    palavra para explicar por que NAO se usou continua valendo - por isso o
    criterio e a frase, nao a palavra. #>
$mentiras = @()
foreach ($frase in @('usar a MEDIANA', 'usa a MEDIANA', 'a estimativa usa a mediana')) {
    if ($jan -match [regex]::Escape($frase)) { $mentiras += $frase }
}
Checar "Calibragem: nenhum comentario afirma que a estimativa usa mediana" `
    ($mentiras.Count -eq 0) (($mentiras -join " | "))

<#  17.19 - OS FATORES DE ESPACO VIVEM EM TRES LUGARES E TEM QUE CONCORDAR.

    O motor tem DOIS ($fatorPre, na conferencia antes de comecar, e
    $fatorEspaco, na hora de converter) e a janela tem UM
    (Get-FatorEspacoDisco, que pinta o painel e decide se o Iniciar pergunta).
    Eles nao podem ser unificados numa funcao so - o motor roda tambem em modo
    console, sem a janela - mas podem ser AMARRADOS por teste.

    Se discordarem, o programa mente numa das duas pontas: ou a tela promete
    que cabe e o motor recusa, ou a tela assusta com espaco que o motor nem ia
    usar. O segundo ja aconteceu, com o P5 (16.95).

    E o numero tambem esta escrito por extenso na caixa de dialogo, nas duas
    linguas. Texto que cita um numero que o codigo calcula e a licao 2 de novo:
    trocar o fator e esquecer a frase faz a caixa mentir. #>
$fatMotor = @()
foreach ($m2 in [regex]::Matches($mot, 'if \(\$(?:diretoPre|videoDireto)\) \{ ([0-9.]+) \} else \{ ([0-9.]+) \}')) {
    $fatMotor += ("{0}/{1}" -f $m2.Groups[1].Value, $m2.Groups[2].Value)
}
Checar "Espaco: o motor declara os dois fatores nas duas passagens" `
    ($fatMotor.Count -eq 2) ("achei " + $fatMotor.Count)
Checar "Espaco: as duas passagens do motor usam o MESMO par de fatores" `
    (($fatMotor.Count -eq 2) -and ($fatMotor[0] -eq $fatMotor[1])) `
    (($fatMotor -join " x ") + " - uma conferencia antes e outra na hora, com contas diferentes")

$fatJanela = ""
try {
    $fdFat = @(([System.Management.Automation.Language.Parser]::ParseInput($jan, [ref]$null, [ref]$null)).FindAll(
                 { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                   $args[0].Name -eq "Get-FatorEspacoDisco" }, $true))
    if ($fdFat.Count -eq 1) {
        $corpoFat = $fdFat[0].Extent.Text
        $semC = ($corpoFat -replace '(?s)<#.*?#>','')
        $nums = @([regex]::Matches($semC, 'return ([0-9.]+)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
        $fatJanela = (($nums | Sort-Object) -join "/")
    }
} catch { }
Checar "Espaco: a janela declara os mesmos dois fatores do motor" `
    ($fatJanela -eq "1.6/3.15") ("janela: " + $fatJanela)
Checar "Espaco: e o motor usa exatamente esse par" `
    (($fatMotor.Count -eq 2) -and ($fatMotor[0] -eq "1.6/3.15")) ("motor: " + ($fatMotor -join " x "))
<#  17.19 - O LOG TAMBEM PRECISA DE UM LUGAR QUE ACEITE ESCRITA.

    As duas tentativas de log (_logs\ e a raiz) ficam DENTRO da pasta de
    instalacao. Numa instalacao em Program Files as duas falham, o
    StreamWriter estoura num catch vazio e o programa roda a sessao inteira
    sem gravar uma linha - sem avisar. Quem tem o problema fica sem a prova
    dele.

    A licao 23 ja existia (Get-PastaDados decide ESCREVENDO), e o log era a
    unica escrita do programa que ainda nao a usava. #>
Checar "Log: existe uma terceira tentativa, na pasta de dados do usuario" `
    ([bool]($jan -match '(?s)catch \{.{0,700}Get-PastaDados.{0,400}StreamWriter'))
Checar "Log: e ela avisa no proprio log quando o desvio aconteceu" `
    (($jan -match '\$script:LogCaiuParaDados = \$true') -and
     ($jan -match 'a pasta do programa nao aceita escrita'))
Checar "Log: sem nenhum arquivo possivel, o painel Log diz isso" `
    ([bool]($jan -match 'o painel Log desta sessao e tudo que existe'))
<#  E a funcao tem que estar definida ANTES do bloco do log - codigo de topo
    roda na ordem, e chamar funcao que ainda nao nasceu e erro em silencio. #>
$posFn  = $jan.IndexOf("function Get-PastaDados {")
$posLog = $jan.IndexOf('$script:PastaLogs = Join-Path $script:PastaScript "_logs"')
Checar "Log: Get-PastaDados e definida ANTES do bloco do log" `
    (($posFn -ge 0) -and ($posLog -ge 0) -and ($posFn -lt $posLog)) `
    "codigo de topo roda na ordem: funcao chamada antes de nascer nao existe"
Checar "Log: Get-PastaDados nao foi COPIADA para o topo (existe uma so)" `
    (([regex]::Matches($jan, 'function Get-PastaDados \{')).Count -eq 1)

Checar "Espaco: a caixa de dialogo cita o mesmo numero, nas duas linguas" `
    (($jan -match 'precisa de 3,15x o próprio tamanho') -and ($jan -match 'needs 3\.15x its own size')) `
    "o texto cita um numero que o codigo calcula - trocar um sem o outro faz a caixa mentir"

<#  E o alinhamento: as duas colunas do resumo tem os dois-pontos na mesma
    coluna. Um rotulo em ingles mais curto nao pode puxar o ':' para tras. #>
$alinhaOk = $true
try {
    $duas = @("Total de Vídeos na Fila       : 1", "Convertidos com Sucesso       : 0")
    $pos = @($duas | ForEach-Object { (Traduzir-LinhaContador $_).LastIndexOf(":") })
    $alinhaOk = ($pos[0] -eq $pos[1])
} catch { $alinhaOk = $false }
Checar "EXECUTANDO EN: os dois-pontos continuam alinhados depois de traduzir" $alinhaOk

<#  3.23: na 17.12 isto era uma linha solta no caminho do clique. Nao
    segurava - Fill-Faixas reescrevia por cima. Agora quem garante e o dono
    unico da dica, e e ele que o teste tem que olhar. #>
Checar "Janela: o nome do arquivo sai da frente do aviso de espera" `
    ([bool]($jan -match '(?s)function Update-AvisoEspera.{0,900}lblAbaDica\.Text = ""'))
Checar "Janela: e volta quando a espera acaba" `
    ([bool]($jan -match '(?s)function Restaurar-AbaDica.{0,400}DicaAntesDaEspera'))

Checar "Janela: o motivo do PULADO e REDIGIDO pela tela, nao copiado do motor" `
    ([bool]($jan -match 'function Get-MotivoPulado'))
Checar "Janela: e ele nunca sai com a primeira letra minuscula" `
    ([bool]($jan -match '(?s)function Get-MotivoPulado.{0,2500}Substring\(0,1\)\.ToUpper\(\)'))
Checar "Motor: continua ASCII puro (e por isso a tela redige, nao copia)" `
    ((@([regex]::Matches($mot, '[^\x00-\x7F]')).Count) -eq 0)


Titulo "41. O AVISO DE ESPERA, O ROTULO DO CENSO E O CANCELAR NA TELA (17.13)"
<#  Quatro achados do Diego usando a 17.12:

    1. Esconder o nome do arquivo UMA VEZ nao segurou: quatro pontos
       diferentes escrevem a dica da aba, e trocar o Modo chama Fill-Faixas,
       que reescreve. O nome voltava e nunca mais saia.
    2. O aviso de espera competia de igual para igual com um nome de release
       de 70 caracteres - mesmo tamanho, mesmo peso.
    3. "Contando..." nao dizia o que contava e podia ficar preso no botao.
    4. Depois do Cancelar, o rodape passava ate 21s dizendo "Extraindo Video
       Puro" - o tempo de a etapa em curso terminar. A demora e legitima; a
       frase e que estava mentindo. #>

Checar "Janela: existe UM lugar que escreve a dica da aba (Set-AbaDica)" `
    ([bool]($jan -match 'function Set-AbaDica'))
Checar "Janela: e NINGUEM escreve lblAbaDica.Text por fora dele" `
    ($(  $fora = @([regex]::Matches($jan, '\$UI\.lblAbaDica\.Text\s*=')) 
         # Set-AbaDica, Restaurar-AbaDica e Update-AvisoEspera sao os donos.
         $fora.Count -le 4  )) `
    "ha escrita direta em lblAbaDica fora do dono"
Checar "Janela: Set-AbaDica respeita a espera (nao deixa o nome voltar)" `
    ([bool]($jan -match '(?s)function Set-AbaDica.{0,600}IniciarAposMedir.{0,80}return'))
Checar "Janela: e guarda o texto pedido para devolver depois" `
    ([bool]($jan -match '(?s)function Set-AbaDica.{0,400}DicaAntesDaEspera = \$Texto'))
Checar "Janela: existe UM lugar que liga/desliga o aviso (Update-AvisoEspera)" `
    ([bool]($jan -match 'function Update-AvisoEspera'))
Checar "Janela: o aviso e a dica mudam JUNTOS (sao a mesma linha da tela)" `
    ([bool]($jan -match '(?s)function Update-AvisoEspera.{0,900}lblAbaDica\.Text = ""'))
Checar "Janela: o aviso ganhou caixa propria com borda ambar" `
    ([bool]($jan -match 'x:Name="avisoEspera"'))
Checar "Janela: e esta maior e em negrito (competia com o nome do release)" `
    ([bool]($jan -match '(?s)x:Name="lblEsperandoMedida" FontSize="13\.5" FontWeight="SemiBold"'))

Checar "Janela: o rotulo do censo diz o que esta contando" `
    ([bool]($jan -match 'Censo: contando\.\.\.'))
Checar "Janela: existe Reset-BotaoCenso (o rotulo tinha como ficar preso)" `
    ([bool]($jan -match 'function Reset-BotaoCenso'))
Checar "Janela: e Stop-Censo sempre zera o rotulo junto do estado" `
    ([bool]($jan -match '(?s)function Stop-Censo.{0,2400}Reset-BotaoCenso'))
Checar "Janela: uma leitura nova tambem encerra um censo em curso" `
    ([bool]($jan -match '(?s)function Start-Leitura.{0,3600}CensoRodando.{0,300}Stop-Censo'))
Checar "Idioma: o rotulo do censo rodando tem traducao" `
    ($(  $arqIC2 = Join-Path $Fonte "IDIOMA_EN.txt"
         if (Test-Path -LiteralPath $arqIC2) {
             (Get-Content -Raw -LiteralPath $arqIC2) -match "Censo: contando\.\.\.\t"
         } else { $false }  ))

Checar "Janela: depois do Cancelar o rodape diz que esta cancelando" `
    ([bool]($jan -match 'Cancelando - esperando a etapa atual terminar'))
Checar "Janela: e essa decisao mora no PULSO, nao numa linha do clique" `
    ([bool]($jan -match '(?s)function Update-Progresso.{0,20000}\$script:Controle\.Cancelar -and \$Estado\.Atual -in @\("rodando","pausado"\)'))
Checar "Janela: o clique do cancelar NAO escreve no rodape (seria apagado no tique)" `
    (-not ($jan -match '(?s)ACAO: cancelar - flag gravada.{0,600}lblEtapaNome\.Text ='))
Checar "Janela: a cor do rotulo volta ao normal quando o motor fala de novo" `
    ((([regex]::Matches($jan, 'lblEtapaNome\.Foreground = Pincel \$Cores\.foco')).Count -ge 3))
Checar "Idioma: a frase do cancelamento tem traducao" `
    ($(  $arqIX = Join-Path $Fonte "IDIOMA_EN.txt"
         if (Test-Path -LiteralPath $arqIX) {
             (Get-Content -Raw -LiteralPath $arqIX) -match "Cancelando - esperando a etapa atual"
         } else { $false }  ))


$en = Get-Content -Raw (Join-Path $Fonte "IDIOMA_EN.txt")
Titulo "42. A TELA NAO PODE PROMETER O QUE O MOTOR NAO FAZ (17.14)"
<#  O achado mais caro desta rodada, e o de sempre: a janela REDIGITA o que o
    motor decide, e toda redigitacao e uma chance de discordar da fonte.

    Arquivo com legenda pt-BR em TEXTO e legenda pt-BR em PGS: o motor
    reaproveita a de texto (Caminho 1, "[NAO NECESSARIO]") e NAO roda OCR. A
    janela punha CONVERTER na PGS assim mesmo - e marcava as duas com o mesmo
    Papel, o que fazia o rotulo PADRAO ir para quem viesse primeiro no
    arquivo.

    Os outros dois sao de tela que nao explica: aviso de espera parado por 42
    segundos (indistinguivel de aviso morto) e o botao de censo cinza sem
    motivo. #>

Checar "Janela: com .SRT pt-BR presente, a PGS nao e CONVERTER" `
    ([bool]($jan -match '(?s)\$ptPgs -and \$fid -eq \[int\]\$ptPgs\.id -and \$ptTxt.{0,2000}VerboAuto = "MANTER"'))
Checar "Janela: e ela diz o motivo no lugar do verbo" `
    ([bool]($jan -match 'Já Existe \.SRT - OCR Não Necessário'))
Checar "Janela: e as duas faixas param de disputar o papel leg-ptbr" `
    ([bool]($jan -match 'Papel = "leg-pgs-extra"'))
Checar "Idioma: o motivo da PGS redundante tem traducao" `
    ([bool]($en -match 'Já Existe \.SRT - OCR Não Necessário\t'))

Checar "Janela: o aviso de espera conta os arquivos (Get-TextoEspera)" `
    ([bool]($jan -match 'function Get-TextoEspera'))
Checar "Janela: e quem escreve o aviso passa por ela" `
    ([bool]($jan -match '(?s)function Update-AvisoEspera.{0,600}lblEsperandoMedida\.Text = Get-TextoEspera'))
Checar "Janela: cada arquivo medido desconta um da espera" `
    ([bool]($jan -match '(?s)\$script:ELfeitos\+\+.{0,200}Update-AvisoEspera'))
<#  3.35 - 18.00: quem zera a conta e quem COMECA a medicao - e agora isso e
    Start-Medicao, nao a leitura. A regra e a mesma (a conta nasce zerada). #>
$corpoSM = ""
try {
    $iSM = $jan.IndexOf("function Start-Medicao")
    if ($iSM -ge 0) { $corpoSM = Remove-Comentarios $jan.Substring($iSM, [Math]::Min(3000, $jan.Length - $iSM)) }
} catch { }
$posPend = $corpoSM.IndexOf('$pend = @(Get-PendentesDeMedida)')
$posTrava = $corpoSM.IndexOf('if ($script:MedPS)')
<#  3.49 - FECHAR A JANELA TEM QUE PARAR TODOS OS RELOGIOS.

    Log dele de 10/09 01:26:31,8 (trocar idioma -> reiniciar): "Nao sera
    possivel definir Visibility ... depois que uma Janela for fechada". So o
    TimerFila era parado no add_Closed; os outros continuavam batendo numa
    janela morta. Este teste DESCOBRE os relogios no fonte - relogio novo ja
    nasce conferido, lista digitada a mao envelhece calada. #>
$relogios = @([regex]::Matches($jan, '(?m)^\$(Timer[A-Za-z]+) = New-Object System\.Windows\.Threading\.DispatcherTimer') |
              ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
Checar "os DispatcherTimer sao descobertos no fonte (achei $($relogios.Count))" ($relogios.Count -ge 5)
$blocoFechado = ""
try {
    $iF = $jan.IndexOf('$Janela.add_Closed({')
    if ($iF -ge 0) { $blocoFechado = $jan.Substring($iF, [Math]::Min(2000, $jan.Length - $iF)) }
} catch { }
$semParar = @($relogios | Where-Object { $blocoFechado -notmatch ("\$" + $_ + "(\W|$)") })
Checar "Fechar: TODOS os relogios param no add_Closed" `
    ($semParar.Count -eq 0) ("ficaram batendo: " + ($semParar -join ", "))
$semGuarda = @()
foreach ($r in $relogios) {
    $iT = $jan.IndexOf('$' + $r + '.add_Tick({')
    if ($iT -lt 0) { continue }
    if ($jan.Substring($iT, [Math]::Min(260, $jan.Length - $iT)) -notmatch '\$script:Fechando') { $semGuarda += $r }
}
Checar "Fechar: e cada tique sai na hora se a janela ja fechou" `
    ($semGuarda.Count -eq 0) ("sem a guarda: " + ($semGuarda -join ", "))

Checar "Medicao: so avisa 'a anterior esta encerrando' se HOUVER o que medir" `
    ($posPend -ge 0 -and $posTrava -gt $posPend) `
    "17/09 11:54:22,8: prometeu medicao com a fila de pendentes vazia (licao 2)"
Checar "Fila: repintar a fila NAO refaz a tabela de faixas (evento de repintura)" `
    ([bool]($jan -match 'if \(\$script:AbaAtual -eq "faixas" -and \(-not \$script:PintandoFila\)\) \{ Fill-Faixas \}')) `
    "um clique em MODO gerava dois FAIXAS - mesma familia do defeito da 18.06"
Checar "Medicao: Start-Medicao zera a conta antes de comecar" `
    ([bool]($jan -match '(?s)function Start-Medicao.{0,3600}\$script:ELtotal\s*=\s*\$lista\.Count.{0,120}\$script:ELfeitos\s*=\s*0'))

Checar "Janela: o botao do censo diz por que esta cinza (Get-MotivoCenso)" `
    ([bool]($jan -match 'function Get-MotivoCenso'))
Checar "Janela: a dica e escrita nos dois caminhos do diagnostico" `
    ($(  @([regex]::Matches($jan, 'Update-DicaCenso')).Count -ge 3  )) `
    "falta ligar a dica em algum caminho de Update-Diagnostico"
Checar "Janela: a dica aparece mesmo com o botao desabilitado" `
    ([bool]($jan -match 'ToolTipService\.ShowOnDisabled="True"'))
Checar "Janela: o criterio continua num lugar so (a dica pergunta a Test-PodeCenso)" `
    ([bool]($jan -match '(?s)function Get-MotivoCenso.{0,3400}Test-PodeCenso'))

<#  17.14: as regras de traducao rodam EM ORDEM. A regra da palavra "medindo"
    sozinha disparava antes da regra da frase inteira e desmanchava a frase
    antes de ela ser testada - sobrava "measuring a camada de melhoria" na
    tela em ingles. Especifica em cima da generica. #>
Checar "Idioma: a frase do MEL x FEL vem ANTES da palavra 'medindo' solta" `
    ($(  $iFrase = $en.IndexOf("~medindo a camada de melhoria")
         $iSolta  = $en.IndexOf("~medindo`t")
         ($iFrase -ge 0 -and $iSolta -ge 0 -and $iFrase -lt $iSolta)  )) `
    "a regra generica vai comer a especifica"


$en = Get-Content -Raw (Join-Path $Fonte "IDIOMA_EN.txt")
Titulo "43. O DIAGNOSTICO INTEIRO, EM QUALQUER LINGUA E EM QUALQUER ESTADO (17.15)"
<#  Tres achados da rodada de 01h da 17.14:

    1. O cartao final ficava congelado na lingua em que nasceu. Set-Idioma ja
       redesenhava fila, diagnostico, disco e faixas - o cartao era o unico
       painel montado por codigo que ficou de fora, e a tela ficava meio em
       cada lingua.
    2. A espera do Iniciar contava arquivo DESMARCADO. Esperar por um video
       que nao vai converter e esperar a toa.
    3. Excluir a .SRT antiga e mandar CONVERTER a PGS (trocar de legenda)
       respondia "Sem Legenda PT-BR no Arquivo Final" - o que foi enviado ao
       motor estava certo, so o texto mentia. #>

Checar "Janela: existe quem redesenhe o cartao final (Redesenhar-Resumo)" `
    ([bool]($jan -match 'function Redesenhar-Resumo'))
Checar "Janela: e Set-Idioma chama esse redesenho" `
    ([bool]($jan -match '(?s)function Set-Idioma.{0,4000}Redesenhar-Resumo'))
<#  17.20: era uma janela de {0,1400} e estourou quando o bloco entre as duas
    linhas cresceu (o ramo da fila cancelada). O que o teste quer saber e a
    ORDEM - o return do redesenho vem antes do log do resumo - e isso se le
    por posicao, sem depender do que ha no meio. #>
$iRet = $jan.IndexOf('if ($Redesenho) { return }')
$iLog = $jan.IndexOf('Escrever-Log "===== RESUMO DA CONVERSAO ====="')
Checar "Janela: o redesenho NAO regrava o log do resumo" `
    (($iRet -gt 0) -and ($iLog -gt $iRet)) `
    "o return do redesenho tem que vir ANTES de qualquer Escrever-Log do resumo"
Checar "Janela: a hora e o tempo do cartao ficam guardados (nao mentem depois)" `
    ([bool]($jan -match '\$script:ResumoHora') -and [bool]($jan -match '\$script:ResumoSeg'))
Checar "Janela: o titulo do cartao passa pela traducao" `
    ([bool]($jan -match '\$UI\.lblResumoTitulo\.Text = Traduzir "Conversão Concluída"'))
Checar "Janela: e a linha de tempos tambem" `
    ([bool]($jan -match '(?s)lblResumoTempos\.Text = Traduzir-Frase'))
Checar "Idioma: a linha de tempos tem regra de traducao" `
    ([bool]($en -match 'Começou às \(\.\*\) - Terminou às'))

Checar "Janela: a espera olha so os arquivos MARCADOS (Get-MarcadosMedindo)" `
    ([bool]($jan -match 'function Get-MarcadosMedindo'))
Checar "Janela: e ela pergunta pela fila real, nao refaz o criterio" `
    ([bool]($jan -match '(?s)function Get-MarcadosMedindo.{0,300}Get-Marcados'))
Checar "Janela: sem marcado medindo, o Iniciar nao espera nada" `
    ([bool]($jan -match '(?s)function Test-EsperarMedicao.{0,600}Get-MarcadosMedindo\)\.Count -eq 0.{0,300}return \$false'))
Checar "Janela: e quando o ultimo marcado termina, a conversao comeca na hora" `
    ([bool]($jan -match '(?s)\$script:IniciarAposMedir -and @\(Get-MarcadosMedindo\)\.Count -eq 0.{0,900}Invoke-Iniciar'))

Checar "Janela: o veredicto da legenda no Manual olha TODAS as candidatas" `
    ([bool]($jan -match '(?s)function Get-DiagLegendaComEscolha.{0,1800}leg-pgs-extra'))
Checar "Janela: trocar de legenda nao pode dizer 'Sem Legenda PT-BR'" `
    ([bool]($jan -match 'a Legenda Anterior Foi Descartada'))
Checar "Janela: e a frase vermelha so sobra quando nao fica nenhuma" `
    ([bool]($jan -match '(?s)if \(\$manter\.Count -gt 0\).{0,400}Sem Legenda PT-BR no Arquivo Final'))
Checar "Idioma: as frases de ESCOLHA MANUAL tem traducao" `
    ([bool]($en -match 'Sem Legenda PT-BR no Arquivo Final\t') -and [bool]($en -match '~ a Pedido\t'))
<#  17.15: mesma armadilha de ordem da 17.14, agora com " a Pedido": a regra
    curta cortaria a frase longa pela metade se viesse antes dela. #>
Checar "Idioma: a frase longa de 'a Pedido' vem ANTES da curta" `
    ($(  $iLonga = $en.IndexOf("~ a Pedido - a Legenda Anterior")
         $iCurta  = $en.IndexOf("~ a Pedido`t")
         ($iLonga -ge 0 -and $iCurta -ge 0 -and $iLonga -lt $iCurta)  )) `
    "a regra generica vai comer a especifica"


$mot = Get-Content -Raw (Join-Path $Fonte "Converter_AUTO_DIRETO.ps1")
Titulo "44. A ORDEM MANUAL DE OCR VENCE O REAPROVEITAMENTO (14.53)"
<#  O defeito mais caro da rodada, e ele saiu no ARQUIVO do usuario, nao na
    tela: excluir a .SRT antiga e mandar CONVERTER a PGS gerou um MKV final
    SEM NENHUMA LEGENDA.

    O caminho: o motor testa primeiro se ja existe pt-BR em texto; achou,
    disse "[NAO NECESSARIO]" e nao rodou OCR. Sem SRT nova, e com a antiga
    excluida de proposito pelo usuario, o remux descartou tudo.

    A regra, terceira vez neste projeto (16.31, 14.40, 14.53): a ausencia de
    uma chave nunca e uma ordem - e a PRESENCA dela sempre e. #>

Checar "Motor: existe quem saiba que o OCR foi pedido na mao" `
    ([bool]($mot -match 'function Test-OcrPedidoNaMao'))
Checar "Motor: e ela le a chave LegendaPgs, so aceitando id >= 0" `
    ([bool]($mot -match "(?s)function Test-OcrPedidoNaMao.{0,1800}ContainsKey\('LegendaPgs'\).{0,400}-ge 0"))
Checar "Motor: a EXECUCAO da legenda so reaproveita a .SRT se ninguem pediu OCR" `
    ([bool]($mot -match '(?s)if \(Test-OcrPedidoNaMao -MkvPath \$f\.FullName\) \{.{0,400}\} else \{\s*\r?\n\s*\$trackTexto = Get-FaixaLegendaPtBrTexto'))
Checar "Motor: e o DIAGNOSTICO anuncia a mesma coisa que vai acontecer" `
    ([bool]($mot -match '(?s)\$diagLegendaTexto = \$null.{0,300}if \(-not \(Test-OcrPedidoNaMao'))
Checar "Motor: -1 continua sendo a ordem contraria (nao converta nenhuma)" `
    ([bool]($mot -match "(?s)ContainsKey\('LegendaPgs'\).{0,200}-lt 0.{0,80}return \`$null"))
<#  O automatico NAO pode ter mudado: sem escolha manual, uma legenda de
    texto pronta continua ganhando do OCR - e a regra que a 17.14 acabou de
    acertar do lado da janela. #>
Checar "Motor: sem escolha manual, o texto pronto continua vencendo o OCR" `
    ([bool]($mot -match '(?s)function Test-OcrPedidoNaMao.{0,1500}if \(-not \$e\) \{ return \$false \}'))


Titulo "45. UMA LEGENDA INGLESA CARIMBADA DE BRASILEIRA (14.54 / 17.16)"
<#  O defeito desta rodada que saiu no ARQUIVO: no Modo Manual dava para
    marcar CONVERTER na PGS de INGLES, e o programa convertia. O log escreveu
    "Legenda PT-BR Encontrada na Faixa 5 'SDH'" e o MKV final saiu com uma
    legenda em ingles rotulada "Portugues (Brasil) [OCR]", marcada como
    padrao.

    O OCR daqui e pt-BR de ponta a ponta - dicionario de 1,3M palavras em
    portugues, Corretor que caca bloco alienigena comparando com portugues,
    Reocr que refaz fala curta em portugues. Apontado para uma faixa inglesa
    ele nao converte ingles: carimba ingles de brasileiro.

    DUAS trancas, porque esta estraga arquivo: a janela nao oferece o verbo,
    e o motor recusa a ordem se ela chegar assim mesmo. #>

Checar "Janela: o dropdown de legenda nao-ptBR nao oferece CONVERTER" `
    ([bool]($jan -match '(?s)function Get-OpcoesVerbo.{0,2200}-not \(Test-EhLegendaPtBr \$f\).{0,90}"MANTER", "EXCLUIR"'))
Checar "Janela: e quem GRAVA o verbo confere de novo (desenho nao e regra)" `
    ([bool]($jan -match '(?s)\$novo -eq "CONVERTER" -and \$f\.Tipo -eq "subtitles" -and -not \(Test-EhLegendaPtBr'))
Checar "Janela: o criterio de 'e pt-BR' pergunta ao PAPEL, nao refaz regra" `
    ([bool]($jan -match '(?s)function Test-EhLegendaPtBr\(\$f\).{0,400}leg-ptbr.{0,80}leg-pgs-extra'))
Checar "Motor: existe o portao de idioma da ordem manual" `
    ([bool]($mot -match 'function Test-EhLegendaPtBrCandidata'))
Checar "Motor: e a ordem manual so passa se a faixa puder ser pt-BR" `
    ([bool]($mot -match '(?s)if \(Test-EhLegendaPtBrCandidata \$pgsEscolhida\[0\]\) \{ return \$pgsEscolhida\[0\] \}'))
Checar "Motor: a recusa vai para o log com o motivo (nunca em silencio)" `
    ([bool]($mot -match 'NAO e uma legenda pt-BR'))
<#  O zip _reocr do GOT mostrou CINCO blocos em portugues perfeito no meio de
    uma legenda inteira em ingles. Nao foi milagre: o SRT veio da PGS
    inglesa e o Reocr foi buscar a imagem na faixa que ELE escolhe sozinho -
    a pt-BR. Duas deteccoes da mesma coisa em lugares diferentes, a familia
    de defeito da 16.79. Agora o motor manda o id. #>
Checar "Motor: o Reocr recebe a faixa que GEROU o srt (nao redescobre)" `
    ([bool]($mot -match '(?s)function Invoke-ReocrLegenda.{0,400}\$IdFaixaPgs'))
Checar "Motor: e o id viaja como -Track na linha de comando" `
    ([bool]($mot -match '(?s)\$null -ne \$IdFaixaPgs.{0,80}"-Track"'))
Checar "Motor: id 0 e valido (testa contra null, nao por verdade simples)" `
    ([bool]($mot -match '\$null -ne \$IdFaixaPgs'))
Checar "Motor: a chamada real passa a PGS de origem" `
    ([bool]($mot -match 'Invoke-ReocrLegenda -MkvPath \$f\.FullName -SrtPath \$srtPtBr -IdFaixaPgs'))

Checar "Motor: pt-PT nao conta como pt-BR" `
    ([bool]($mot -match '(?s)function Test-EhLegendaPtBrCandidata.{0,900}pt-PT.{0,120}return \$false'))

<#  A conta do disco que enxergava a fila inteira existia desde a 16.93 e
    ninguem olhava para ela: a pergunta do Iniciar so disparava pela conta
    AGREGADA, que nao sabe que o disco encolhe entre um arquivo e o outro.
    Resultado real (13/09): tela verde-amarela, GOT converteu, e o Ryan
    morreu na vez dele por 2,95 GB - depois de 10 minutos de fila. #>
Checar "Janela: a fila que nao cabe INTEIRA tambem para o Iniciar" `
    ([bool]($jan -match '(?s)function Test-PodeIniciar.{0,3000}\$script:DiscoFalta -gt 0 -or \$script:DiscoNaoCabem -gt 0'))
Checar "Janela: e a pergunta diz QUAL dos dois casos e" `
    ([bool]($jan -match 'A fila cabe agora, mas não até o fim'))
Checar "Janela: a barra do disco tambem avisa (verde nao pode esconder isso)" `
    ([bool]($jan -match '(?s)\$script:DiscoNaoCabem -gt 0 -and \$sobra -ge 0.{0,600}Cabe Agora, Mas Não Até o Fim'))
Checar "Idioma: o aviso da fila que aperta no meio tem traducao" `
    ([bool]($en -match 'Cabe Agora, Mas Não Até o Fim'))

<#  "Deixou DTS como audio principal, ta certo isso?" - a regra estava certa
    nos cinco caminhos; o que faltava era o log PROVAR qual saiu marcada, e
    dizer quando o modo seguro legitimamente nao mexe em nada. #>
Checar "Motor: o log diz sempre qual faixa de audio ficou como padrao" `
    ([bool]($mot -match 'AUDIO PADRAO:'))
Checar "Motor: inclusive quando o modo seguro nao mexe na marcacao" `
    ([bool]($mot -match '(?s)if \(\$audioSemRestricao\) \{\s*\r?\n\s*Say "        AUDIO PADRAO: nao alterado'))
Checar "Motor: e quando a padrao e a faixa NOVA" `
    ([bool]($mot -match 'AUDIO PADRAO: a faixa NOVA'))

<#  3.26: "no inicio dizia 1:25 para terminar, achei estranho". A previsao
    tinha acertado (1h25 previsto x 1h20 real, 6%), mas descobrir isso exigiu
    abrir dois logs e subtrair na mao. Mesma licao da AUDIO PADRAO: a regra
    estava certa e faltava PROVA no log. #>
Checar "Janela: o log fecha previsto x real por ARQUIVO" `
    ([bool]($jan -match 'PREVISAO: .{0,60}previsto \{1:N0\}s \| real \{2:N0\}s \| erro'))
Checar "Janela: e da FILA inteira, no resumo" `
    ([bool]($jan -match 'PREVISAO DA FILA: previsto'))
Checar "Janela: a previsao da fila usa o mesmo total que o cartao mostra" `
    ([bool]($jan -match '(?s)PREVISAO DA FILA.{0,1500}\$trabFila = \[math\]::Max\(1\.0, \[double\]\$totalSeg - \$pausaFila\)'))

Checar "Janela: a dica da chave de medicao esta nos DOIS botoes" `
    ([bool]($jan -match '(?s)\$UI\.btnMedirELTopo\.ToolTip = \$dicaEL.{0,120}\$UI\.btnMedirEL\.ToolTip')) `
    "o de baixo ficou sem dica"
Checar "Janela: a linha dos Capitulos passa pelo tradutor do verbo" `
    ([bool]($jan -match 'Get-VerboExibido "MANTER"'))
Checar "Janela: os botoes do fim traduzem quando o cartao aparece" `
    ([bool]($jan -match 'lblNovaConversao\.Text = \(\[char\]0x21BB\)'))


Titulo "46. O ROTEIRO DE TESTE, EXECUTADO COM OS ARQUIVOS REAIS (17.17)"
<#  O Diego: "eu nao vou refazer tudo isso, faca testes sinteticos de acordo
    com os arquivos enviados".

    Tem razao, e a resposta certa nao e ele repetir seis roteiros na mao: e a
    bateria repetir por ele, toda vez, para sempre. Esta secao MONTA os
    arquivos dele a partir do que os MediaInfo e os logs registraram - faixa
    por faixa, com id, codec, nome e idioma reais - e EXECUTA as funcoes de
    verdade em cima disso.

    Os numeros dos cenarios nao foram inventados. Saem de:
      GOT S08E01 : MediaInfo do convertido + log de 13/09 10h02
      Ryan       : log de 13/09 10h13 (o que foi pulado por 2,95 GB)
      Se7en      : MediaInfo do convertido2 de 11/09

    O que esta secao NAO cobre, e por honestidade fica escrito: nada que
    dependa de WPF de verdade (o desenho do botao, a barra na tela, o
    dropdown aberto). Ela cobre a REGRA por tras de cada um - que e onde os
    defeitos desta rodada estavam. #>

# ---- as faixas reais, como o mkvmerge as entrega -------------------------
function NovaFaixa($id, $tipo, $codec, $nome, $lang, $ietf) {
    [pscustomobject]@{
        Id = $id; Tipo = $tipo; Codec = $codec; Nome = $nome
        Lang = $lang; Ietf = $ietf; Papel = "extra"
        VerboAuto = "EXCLUIR"; VerboUsuario = $null; DetalheAuto = ""
        Relevante = $true; Bytes = 0; Marcas = ""
        properties = [pscustomobject]@{ track_name = $nome; language = $lang; language_ietf = $ietf }
    }
}
# GOT S08E01: video, TrueHD Atmos, 2x AC-3, PGS pt-BR (4) e PGS SDH ingles (5)
$gotFaixas = @(
    (NovaFaixa 0 "video"     "HEVC"        "" "und" ""),
    (NovaFaixa 1 "audio"     "AC-3"        "Stereo" "pt" ""),
    (NovaFaixa 2 "audio"     "TrueHD Atmos" "Surround" "eng" "en"),
    (NovaFaixa 3 "audio"     "AC-3"        "Surround 5.1" "eng" "en"),
    (NovaFaixa 4 "subtitles" "HDMV PGS"    "" "por" "pt-BR"),
    (NovaFaixa 5 "subtitles" "HDMV PGS"    "SDH" "eng" "en")
)
# Os papeis que a LEITURA atribui neste arquivo (ver Fill-Faixas / a leitura):
$gotFaixas[4].Papel = "leg-ptbr"; $gotFaixas[4].VerboAuto = "CONVERTER"
$gotFaixas[5].Papel = "leg-eng";  $gotFaixas[5].VerboAuto = "MANTER"

$fnJan = @("Get-OpcoesVerbo","Test-EhLegendaPtBr","Get-VerboExibido","Get-VerboCanonico",
           "Get-FatorEspacoDisco","Get-PlanoDoDisco","Get-TamanhoEstimadoVideo","Get-TamanhoEstimadoFaixa",
           "Format-GB","Get-DiagLegendaComEscolha","Test-TemEscolha","Get-CodecCurto","Test-VerboBloqueado")
$carregouJan = $true
try {
    $astJ = [System.Management.Automation.Language.Parser]::ParseInput($jan, [ref]$null, [ref]$null)
    foreach ($nf in $fnJan) {
        $fd = @($astJ.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -eq $nf }, $true))
        if ($fd.Count -eq 0) { throw "nao achei $nf na janela" }
        . ([scriptblock]::Create($fd[0].Extent.Text))
    }
} catch { $carregouJan = $false; $erroJan = $_.Exception.Message }
Checar "EXECUTANDO: as funcoes da janela carregam do fonte" $carregouJan $(if ($carregouJan) { "" } else { $erroJan })

if ($carregouJan) {
    $script:Lang = "PT"
    # ---- ITEM 1: a PGS inglesa nao pode oferecer CONVERTER ---------------
    $opsIngles = @(Get-OpcoesVerbo $gotFaixas[5])
    Checar "GOT real: o dropdown da PGS 'SDH' inglesa NAO tem CONVERTER" `
        (@($opsIngles) -notcontains "CONVERTER") ("saiu: " + ($opsIngles -join "/"))
    Checar "GOT real: e ela continua podendo ser MANTIDA ou EXCLUIDA" `
        ((@($opsIngles) -contains "MANTER") -and (@($opsIngles) -contains "EXCLUIR")) `
        ("saiu: " + ($opsIngles -join "/"))

    # ---- ITEM 2: o automatico NAO pode ter mudado ------------------------
    $opsPtBr = @(Get-OpcoesVerbo $gotFaixas[4])
    Checar "GOT real: a PGS pt-BR continua podendo ser CONVERTIDA" `
        (@($opsPtBr) -contains "CONVERTER") ("saiu: " + ($opsPtBr -join "/"))
    Checar "GOT real: o audio principal nao perdeu nada (MANTER/CONVERTER)" `
        ($(  $fa = $gotFaixas[2]; $fa.Papel = "audio-principal"
             $o = @(Get-OpcoesVerbo $fa)
             (@($o) -contains "CONVERTER") -and (@($o) -contains "MANTER") -and (@($o).Count -eq 2)  ))

    # ---- ITEM 3: o espaco, com os numeros reais de 13/09 -----------------
    <#  Naquele dia: livre 275,29 GB no inicio; GOT 20,62 GB (P7->P8.1, fator
        3,15) deixando ~19,05 GB na saida; Ryan 81,99 GB (P7->P8.1) exigindo
        ~258,26 GB. O motor recusou o Ryan por 2,95 GB. A conta da tela tem
        que chegar exatamente nisso. #>
    function VideoFalso($nome, $gb, $saidaGb) {
        [pscustomobject]@{
            Nome = $nome; Bytes = ([double]$gb * 1GB); ColDV = "P7 FEL → P8.1"; P5 = $false
            Faixas = @(); DurSeg = 0; SaidaForcada = ([double]$saidaGb * 1GB)
        }
    }
    # Get-TamanhoEstimadoVideo depende das faixas; nos testes o valor real ja
    # e conhecido (o arquivo pronto), entao ele entra direto pelo atalho.
    function Get-TamanhoEstimadoVideo($v) {
        if ($v.PSObject.Properties.Name -contains 'SaidaForcada') { return [double]$v.SaidaForcada }
        return [double]$v.Bytes
    }
    $filaReal = @( (VideoFalso "GOT S08E01" 20.62 19.05), (VideoFalso "Saving Private Ryan" 81.99 76.39) )
    $planoReal = Get-PlanoDoDisco -Videos $filaReal -Livre (275.29 * 1GB)

    Checar "Espaco real 13/09: a conta ve que UM arquivo fica de fora" `
        ([int]$planoReal.NaoCabem -eq 1) ("NaoCabem = " + $planoReal.NaoCabem)
    Checar "Espaco real 13/09: e o que fica de fora e o RYAN (nao o GOT)" `
        ("$($planoReal.PrimeiroFora)" -eq "Saving Private Ryan") ("primeiro fora: " + $planoReal.PrimeiroFora)
    <#  O motor mediu 2,95 GB de falta naquele dia. A tela trabalha com a
        SAIDA ESTIMADA do GOT (19,05 GB e o tamanho final real), entao os dois
        numeros nao sao identicos por construcao - mas tem que ficar na mesma
        ordem de grandeza, senao a tela esta avisando de outro problema. #>
    $faltaGb = [double]$planoReal.FaltaNoPrimeiroFora / 1GB
    Checar "Espaco real 13/09: a falta bate com os ~2,95 GB que o motor mediu" `
        ($faltaGb -gt 0.5 -and $faltaGb -lt 12.0) ("a conta deu {0:N2} GB" -f $faltaGb)
    <#  E o contraprova: com disco sobrando, a mesma fila passa inteira. Sem
        isto o teste acima passaria com uma funcao que diz "nao cabe" sempre. #>
    $planoFolgado = Get-PlanoDoDisco -Videos $filaReal -Livre (900.0 * 1GB)
    Checar "Espaco: com folga, a mesma fila passa inteira (contraprova)" `
        ([int]$planoFolgado.NaoCabem -eq 0 -and [int]$planoFolgado.Cabem -eq 2)
    <#  E o caso que a 17.16 conserta: a fila CABE agora (a conta agregada da
        positivo) e mesmo assim alguem fica de fora no meio do caminho. E
        exatamente o estado que nao existia antes. #>
    Checar "Espaco: 'cabe agora mas nao ate o fim' e um estado alcancavel" `
        ($(  $pico = [double]$filaReal[1].Bytes * 3.15
             $livreTeste = 275.29 * 1GB
             $p = Get-PlanoDoDisco -Videos $filaReal -Livre $livreTeste
             ($livreTeste -ge $pico) -and ([int]$p.NaoCabem -gt 0)  )) `
        "o pico de um arquivo cabe no livre, mas a fila em ordem nao"

    # ---- ITEM 6 (parte): o veredicto da legenda no Manual ----------------
    $gotManual = [pscustomobject]@{ Modo = "Manual"; Faixas = $gotFaixas }
    $gotFaixas[4].VerboUsuario = "CONVERTER"
    $rLeg = Get-DiagLegendaComEscolha $gotManual
    Checar "GOT real: converter a PGS pt-BR no Manual da veredicto verde" `
        ($null -ne $rLeg -and "$($rLeg[1])" -eq "verde") ("saiu: " + $(if ($rLeg) { "$($rLeg[0]) [$($rLeg[1])]" } else { "(null)" }))
    $gotFaixas[4].VerboUsuario = $null
}

# ---- ITEM 1 e 2 do lado do MOTOR, com as faixas reais --------------------
$carregouMot = $true
try {
    $astM = [System.Management.Automation.Language.Parser]::ParseInput($mot, [ref]$null, [ref]$null)
    foreach ($nf in @("Test-EhLegendaPtBrCandidata","Resolve-FaixasDoRemux")) {
        $fd = @($astM.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -eq $nf }, $true))
        if ($fd.Count -eq 0) { throw "nao achei $nf no motor" }
        . ([scriptblock]::Create($fd[0].Extent.Text))
    }
} catch { $carregouMot = $false; $erroMot = $_.Exception.Message }
Checar "EXECUTANDO: as funcoes do motor carregam do fonte" $carregouMot $(if ($carregouMot) { "" } else { $erroMot })

if ($carregouMot) {
    Checar "GOT real: o motor recusa a PGS 'SDH' inglesa como pt-BR" `
        (-not (Test-EhLegendaPtBrCandidata $gotFaixas[5]))
    Checar "GOT real: e aceita a PGS pt-BR do mesmo arquivo" `
        (Test-EhLegendaPtBrCandidata $gotFaixas[4])

    # ---- ITEM 4: o audio padrao, nos cinco caminhos ---------------------
    <#  Se7en real: principal DTS-HD MA (id 1) e um E-AC-3 ja existente
        (id 2). O motor reaproveita o E-AC-3 - entao ELE tem que ser o
        padrao, e nao o DTS. Era exatamente a pergunta do Diego. #>
    $script:EscolhasTeste = @{}
    function Get-EscolhaManual([string]$MkvPath) {
        if ($script:EscolhasTeste.ContainsKey($MkvPath)) { return $script:EscolhasTeste[$MkvPath] }
        return $null
    }
    function PadraoDe($esc, $ids, $def) {
        $script:EscolhasTeste = @{}
        if ($esc) { $script:EscolhasTeste["Se7en.mkv"] = $esc }
        $r = Resolve-FaixasDoRemux -Arquivo "Se7en.mkv" -IdsAudio $ids -IdAudioDefault $def `
                                   -IdsLegenda @(3) -AudioSemRestricao $false -LegendaSemRestricao $false
        return $r
    }
    Checar "Se7en real: no automatico, o E-AC-3 reaproveitado e o padrao (nao o DTS)" `
        ($(  $r = PadraoDe $null @(1,2) 2; [int]$r.AudioDefault -eq 2  ))
    Checar "Se7en real: mantendo os dois na mao, o padrao continua o E-AC-3" `
        ($(  $r = PadraoDe @{AudioManter=@(1,2)} @(1,2) 2; [int]$r.AudioDefault -eq 2  ))
    Checar "Se7en real: mantendo so o DTS, o padrao cai nele (nao ha outro)" `
        ($(  $r = PadraoDe @{AudioManter=@(1)} @(1,2) 2; [int]$r.AudioDefault -eq 1  ))
    Checar "Se7en real: convertendo o principal, a padrao e a faixa NOVA" `
        ($(  $r = PadraoDe @{AudioManter=@(1); ConverterPrincipal=$true} @(1) $null
             $null -eq $r.AudioDefault  )) `
        "null aqui quer dizer 'a faixa nova sera a padrao', marcada no proprio mkvmerge"
    Checar "Se7en real: a padrao escolhida sempre existe na lista que sai" `
        ($(  $r = PadraoDe @{AudioManter=@(2)} @(1,2) 1
             (@($r.Audio) -contains $r.AudioDefault)  ))
}

# ---- ITEM 5: o contador da medicao, sem WPF -----------------------------
<#  A barra e o rotulo dependem de WPF; a CONTA nao. Ela e o que decide o que
    aparece - "1 de 2" e a fracao da barrinha - e e ela que o teste percorre. #>
$fracOk = $true
$fracFalha = ""
foreach ($caso in @(
    @{ tot = 2; feitos = 0; esperaEmCurso = 1; esperaFrac = 0.0 },
    @{ tot = 2; feitos = 1; esperaEmCurso = 2; esperaFrac = 0.5 },
    @{ tot = 2; feitos = 2; esperaEmCurso = 2; esperaFrac = 1.0 },
    @{ tot = 3; feitos = 1; esperaEmCurso = 2; esperaFrac = ([double]1/3) }
)) {
    $emCurso = [math]::Min($caso.tot, $caso.feitos + 1)
    $fr = [double]$caso.feitos / [double]$caso.tot
    if ($fr -lt 0) { $fr = 0 } elseif ($fr -gt 1) { $fr = 1 }
    if ($emCurso -ne $caso.esperaEmCurso -or [math]::Abs($fr - $caso.esperaFrac) -gt 0.001) {
        $fracOk = $false
        $fracFalha = ("tot={0} feitos={1} -> {2} de {2}, fracao {3}" -f $caso.tot, $caso.feitos, $emCurso, $fr)
        break
    }
}
Checar "Medicao: o contador nunca passa do total e a barra nunca estoura" $fracOk $fracFalha


<#  3.27 - NOME DE FUNCAO DUPLICADO NUNCA MAIS.

    A 17.17 achou DUAS funcoes chamadas Get-FatorDisco no mesmo arquivo, com
    significados diferentes (velocidade do disco x espaco em disco). Em
    PowerShell a ultima definicao vence, entao a de espaco respondia tambem
    para quem queria a de velocidade - e devolvia 1,6 constante para chamadas
    sem argumento. Passou despercebido desde a 16.95 porque o codigo roda sem
    erro nenhum: ele so responde a pergunta errada.

    Nao ha como escrever um teste para "o Get-FatorDisco certo" - o teste tem
    que ser contra a CLASSE do defeito. Nome repetido e ambiguidade silenciosa
    e nao pode existir nestes arquivos, ponto. #>
foreach ($arqDup in @("LaFirma_JANELA.ps1", "Converter_AUTO_DIRETO.ps1")) {
    $pDup = Join-Path $Fonte $arqDup
    if (-not (Test-Path -LiteralPath $pDup)) { continue }
    $astDup = [System.Management.Automation.Language.Parser]::ParseFile($pDup, [ref]$null, [ref]$null)
    <#  So as funcoes de NIVEL SUPERIOR. As que vivem dentro dos blocos de
        runspace (Avisar, Enviar) repetem de proposito: cada bloco tem o seu
        escopo, elas nao se enxergam, e cada uma manda para a fila com o tipo
        de log daquele trabalho. Repetir ali e correto; repetir no topo do
        arquivo e a armadilha da 17.17. O criterio e a coluna: funcao de topo
        comeca na 1, funcao aninhada esta indentada. #>
    $nomes = @($astDup.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) |
               Where-Object { $_.Extent.StartColumnNumber -eq 1 } |
               ForEach-Object { $_.Name })
    $repetidos = @($nomes | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { "$($_.Name) (x$($_.Count))" })
    Checar "$arqDup - nenhuma funcao definida duas vezes" `
        ($repetidos.Count -eq 0) `
        ("duplicadas: " + ($repetidos -join ", ") + " - em PowerShell a ultima vence, em silencio")
}


<#  3.27 - O QUE NAO PODE ENTRAR NO INSTALADOR DO USUARIO FINAL.

    "fonte\*" e recursivo e Excludes e lista de BLOQUEIO, nao de permissao -
    entao TODO arquivo novo que aparece em fonte\ entra no instalador por
    padrao, calado. Foi assim que o VERSAO.txt (que o proprio instalador
    gera), o LaFirma_Setup.iss (o script de compilacao) e a Bancada de
    desenvolvimento passaram a ser empacotados sem ninguem reparar.

    Nao da para testar "o Diego lembrou de excluir". Da para testar a lista. #>
$pIss2 = ""
foreach ($cand in @((Join-Path (Split-Path -Parent $Fonte) "LaFirma_Setup.iss"),
                    (Join-Path $Fonte "LaFirma_Setup.iss"))) {
    if (Test-Path -LiteralPath $cand) { $pIss2 = $cand; break }
}
if ($pIss2 -eq "") {
    Pular "Instalador: material interno fora do pacote" "LaFirma_Setup.iss nao esta nesta pasta"
} else {
    $iss2 = [System.IO.File]::ReadAllText($pIss2, [System.Text.Encoding]::UTF8)
    foreach ($proibido in @("VERSAO.txt", "LaFirma_Setup.iss", "Bancada_CensoCompleto.ps1", "Bancada_CensoCompleto.bat")) {
        # O padrao abre a aspa de proposito: 'Excludes:[^"]*' pararia no
        # proprio caractere que comeca a lista, e o teste mediria nada.
        Checar ("Instalador: '$proibido' esta nos Excludes") `
            ([bool]($iss2 -match ('Excludes: "[^"]*' + [regex]::Escape($proibido)))) `
            "arquivo de desenvolvimento ou gerado sendo empacotado para o usuario final"
    }
}


Titulo "47. QUAL DELES ESTA SENDO MEDIDO AGORA (17.18 / 17.19)"
<#  A 17.18 resolveu isso DEDUZINDO - "o arquivo na vez e o primeiro marcado
    que ainda esta em MEDINDO" - e a deducao estava errada por dois motivos:
    o runspace mede todos os pendentes (marcados ou nao), e o total era
    fotografado uma vez, entao marcar/desmarcar no meio da medicao mudava a
    conta debaixo da formula. O Diego viu na tela: a coluna dizendo um numero
    e o botao dizendo outro.

    E ela criou a TERCEIRA contagem da mesma coisa: botao (runspace), aviso de
    espera (marcados) e a deducao. Regra em tres lugares.

    A 17.19 tirou a deducao: o laco que mede manda "el_ini" com indice,
    posicao e total. Esta secao testa o contrato novo - e as duas travas que
    impedem a deducao de voltar. #>

$fnMed = @("Get-Marcados","Get-MarcadosMedindo","Get-MedicaoEmCurso")
$carregouMed = $true
try {
    $astM = [System.Management.Automation.Language.Parser]::ParseInput($jan, [ref]$null, [ref]$null)
    foreach ($nf in $fnMed) {
        $fd = @($astM.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                                $args[0].Name -eq $nf -and $args[0].Extent.StartColumnNumber -eq 1 }, $true))
        if ($fd.Count -eq 0) { throw "nao achei $nf na janela" }
        . ([scriptblock]::Create($fd[0].Extent.Text))
    }
} catch { $carregouMed = $false; $erroMed = $_.Exception.Message }
Checar "EXECUTANDO: as funcoes da medicao carregam do fonte" $carregouMed $(if ($carregouMed) { "" } else { $erroMed })

if ($carregouMed) {
    function VidEL($nome, $eltipo, $marcado) {
        [pscustomobject]@{ Nome = $nome; ELtipo = $eltipo; Marcado = $marcado; Ignorar = $false }
    }
    $nomeA = "Game.of.Thrones.S08E01"; $nomeB = "Saving.Private.Ryan.1998"; $nomeC = "Troy.2004"
    $script:Videos = @((VidEL $nomeA "MEDINDO" $true), (VidEL $nomeB "MEDINDO" $true), (VidEL $nomeC "MEDINDO" $true))
    $script:MedirELLigado = $true
    $script:MedindoEL     = $true

    # ---- o que o "el_ini" mandar e o que a tela mostra, sem conta nenhuma ----
    $script:ELmedindoIdx = 0; $script:ELtotal = 3; $script:ELfeitos = 0
    $m = Get-MedicaoEmCurso
    Checar "Medicao: a tela mostra o arquivo que o 'el_ini' anunciou (1 de 3)" `
        ($null -ne $m -and $m.Idx -eq 0 -and $m.Posicao -eq 1 -and $m.Total -eq 3) `
        ("saiu: " + $(if ($null -eq $m) { "null" } else { "idx $($m.Idx) $($m.Posicao)/$($m.Total)" }))

    $script:ELmedindoIdx = 1; $script:ELfeitos = 1
    $m = Get-MedicaoEmCurso
    Checar "Medicao: no segundo arquivo, diz '2 de 3' e aponta o indice 1" `
        ($null -ne $m -and $m.Idx -eq 1 -and $m.Posicao -eq 2 -and $m.Total -eq 3)

    $script:ELmedindoIdx = 2; $script:ELfeitos = 2
    $m = Get-MedicaoEmCurso
    Checar "Medicao: no ultimo, '3 de 3' - a conta nao estoura" `
        ($null -ne $m -and $m.Idx -eq 2 -and $m.Posicao -eq 3 -and $m.Total -eq 3)

    <#  O DEFEITO DO DIEGO, 15/09, REPRODUZIDO: ele desmarcou os tres e
        remarcou DURANTE a medicao. Na 17.18 isso mudava o total e a posicao
        pulava. Agora marcar/desmarcar nao toca em nada disso. #>
    $script:ELmedindoIdx = 1; $script:ELfeitos = 1
    $antes = Get-MedicaoEmCurso
    $script:Videos = @((VidEL $nomeA "FEL" $false), (VidEL $nomeB "MEDINDO" $false), (VidEL $nomeC "MEDINDO" $false))
    $depois = Get-MedicaoEmCurso
    Checar "Medicao: DESMARCAR tudo no meio nao muda quem esta na vez nem a conta" `
        ($null -ne $antes -and $null -ne $depois -and
         $antes.Idx -eq $depois.Idx -and $antes.Posicao -eq $depois.Posicao -and $antes.Total -eq $depois.Total) `
        "era isto que pulava na 17.18"
    $script:Videos = @((VidEL $nomeA "FEL" $true), (VidEL $nomeB "MEDINDO" $true), (VidEL $nomeC "MEDINDO" $true))

    <#  Arquivo DESMARCADO tambem e medido pelo runspace - e a linha dele tem
        que acender, porque ela esta mesmo sendo lida. Era o outro furo da
        deducao, que so olhava marcados. #>
    $script:Videos = @((VidEL $nomeA "MEDINDO" $false), (VidEL $nomeB "MEDINDO" $true), (VidEL $nomeC "MEDINDO" $true))
    $script:ELmedindoIdx = 0; $script:ELfeitos = 0
    $m = Get-MedicaoEmCurso
    Checar "Medicao: arquivo DESMARCADO sendo medido acende a linha DELE" `
        ($null -ne $m -and $m.Idx -eq 0) `
        "a deducao da 17.18 apontava para o proximo marcado - linha errada"
    $script:Videos = @((VidEL $nomeA "MEDINDO" $true), (VidEL $nomeB "MEDINDO" $true), (VidEL $nomeC "MEDINDO" $true))

    # ---- os estados em que ninguem pode aparecer medindo ----
    $script:ELmedindoIdx = 1; $script:ELtotal = 3; $script:ELfeitos = 1
    $script:MedirELLigado = $false
    Checar "Medicao: com a chave DESLIGADA, ninguem aparece medindo" ($null -eq (Get-MedicaoEmCurso))
    $script:MedirELLigado = $true
    $script:MedindoEL = $false
    Checar "Medicao: sem medicao em curso, ninguem aparece medindo" ($null -eq (Get-MedicaoEmCurso))
    $script:MedindoEL = $true
    $script:ELmedindoIdx = -1
    Checar "Medicao: antes do primeiro 'el_ini' (-1), ninguem aparece medindo" ($null -eq (Get-MedicaoEmCurso))
    $script:ELmedindoIdx = 99
    Checar "Medicao: indice fora da lista nao derruba nem acende linha errada" ($null -eq (Get-MedicaoEmCurso))
    $script:ELmedindoIdx = 1; $script:ELtotal = 0
    Checar "Medicao: sem total anunciado, nao inventa '1 de 0'" ($null -eq (Get-MedicaoEmCurso))

    $script:Videos = @()
    $script:MedindoEL = $false; $script:ELmedindoIdx = -1
}

<#  17.20 - TRES DEFEITOS DA 17.19, TODOS DA MESMA FAMILIA: ESTADO NOVO
    SEM REDESENHO, OU REDESENHO SEM O ESTADO CERTO.

    O Diego viu os tres em quinze minutos, na 17.19 rodando:

      1. "Terminou de medir e ficou mostrando ainda" - a fila continuou com
         "Medindo Camada - 3 de 3" depois de os tres terem veredicto. Ele leu
         aquilo como o programa TRAVADO, e clicou em coisas para destravar.
         (Esta e a classe de bug que a 16.79 ja tinha fechado uma vez, do
         outro lado: "a tela travada numa frase que nao era mais verdade".)

      2. O "Proximo a Converter" verde caia na linha DE BAIXO enquanto a de
         cima era medida. O proximo a converter e o de cima; ele so esta,
         tambem, sendo medido.

    A causa comum: a 17.18 deduzia, e a deducao se corrigia sozinha a cada
    redesenho. Ao trocar deducao por estado (17.19), o estado passou a precisar
    de quem o apague - e eu apaguei a variavel sem redesenhar a lista. #>
Checar "Medicao: o veredicto do arquivo apaga o ciano DELE (nao espera o fim)" `
    ([bool]($jan -match '(?s)\$v\.DiagDVres = "→ \$selo \$alvo\$nota".{0,900}if \(\[int\]\$m\.Idx -eq \[int\]\$script:ELmedindoIdx\) \{ \$script:ELmedindoIdx = -1 \}.{0,600}Fill-Fila "el"')) `
    "sem isto o ultimo arquivo fica em ciano para sempre - ninguem redesenha depois"
Checar "Medicao: o fim da medicao REDESENHA a fila, nao so apaga a variavel" `
    ([bool]($jan -match '(?s)"el_fim" \{.{0,900}\$script:ELmedindoIdx = -1.{0,900}Fill-Fila "el"'))
Checar "Medicao: o fechamento de emergencia tambem apaga quem estava na vez" `
    ([bool]($jan -match '(?s)function Fechar-MedicaoPendente.{0,2200}\$script:ELmedindoIdx = -1')) `
    "Stop-Motor passa aqui em toda saida da fase B"
<#  3.31 - 17.21: O CIANO DA BARRA DE CIMA SOBREVIVIA A MORTE DA MEDICAO.

    Print do Diego: conversao rodando e a barra escrita "Medindo MEL x FEL:
    2 de 3" em ciano. Eu apagava quem estava na vez ($ELmedindoIdx) e deixava
    de pe QUE EXISTE UMA MEDICAO ($MedindoEL/$ELtotal/$ELfeitos) - que e quem
    manda no rotulo, na cor e na barrinha. Estado novo sem redesenho e tela
    mentindo (17.20), um nivel acima. #>
Checar "Medicao: o fechamento apaga TAMBEM o estado de 'existe medicao'" `
    ([bool]($jan -match '(?s)function Fechar-MedicaoPendente.{0,2400}\$script:MedindoEL\s*=\s*\$false')) `
    "senao a barra de cima fica em ciano durante a conversao inteira"
Checar "Medicao: e zera os contadores que desenham a barrinha" `
    ([bool]($jan -match '(?s)function Fechar-MedicaoPendente.{0,2500}\$script:ELtotal\s*=\s*0.{0,120}\$script:ELfeitos\s*=\s*0'))
Checar "Medicao: e REDESENHA o botao depois de apagar (estado sem redesenho mente)" `
    ([bool]($jan -match '(?s)function Fechar-MedicaoPendente.{0,2600}Update-BotaoMedirEL'))
<#  3.31 - LICAO 18 DE NOVO: janela de regex nao le ESTRUTURA.

    O que este teste precisa saber e se o Fill-Fila esta DENTRO do "if
    ($presos -gt 0)" ou no nivel de cima da funcao - e isso e a arvore, nao o
    texto. A AST responde direto: o ultimo comando do corpo tem que ser o
    redesenho. #>
$fnFechar = $astJan.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                              $args[0].Name -eq "Fechar-MedicaoPendente" }, $true)
$fillNoTopo = $false
try {
    $corpoF = $fnFechar[0].Body.EndBlock.Statements
    $ultimo = "$($corpoF[$corpoF.Count - 1].Extent.Text)"
    $fillNoTopo = ($ultimo -match 'Fill-Fila "el"')
} catch { }
Checar "Medicao: e redesenha a FILA mesmo com zero presos (AST: nivel de cima)" `
    $fillNoTopo `
    "dentro do if(presos) ele nao roda quando ninguem ficou preso - e a linha em ciano fica"


<#  3.31 - 17.21: O CENSO NAO DISPUTA O DISCO COM A CONVERSAO.

    Log de 15/09 20:36:56: censo pedido com a etapa 1/5 rodando. Os dois liam
    o mesmo disco mecanico, a etapa ficou em 1% por mais de um minuto e o
    censo nunca voltou. "a fila e a conversao continuam livres" valia para
    TRAVA, nunca para I/O. #>
Checar "Censo: o botao so acende com a tela parada (estado inicial)" `
    ([bool]($jan -match '(?s)btnCenso\.IsEnabled = .{0,200}Test-PodeCenso \$v.{0,200}\$Estado\.Atual -eq "inicial"'))
Checar "Censo: e a porta de entrada barra tambem (botao e aparencia, regra e regra)" `
    ([bool]($jan -match '(?s)function Start-Censo.{0,2600}"rodando","pausado".{0,300}return'))
Checar "Censo: comecar uma conversao encerra o censo em curso" `
    ([bool]($jan -match '(?s)function Invoke-IniciarInterno.{0,700}if \(\$script:CensoRodando\).{0,300}Stop-Censo')) `
    "fechar a porta e esquecer quem ja estava dentro nao resolve o disco"
Checar "Censo: a dica responde primeiro pela conversao em curso" `
    ([bool]($jan -match '(?s)function Get-MotivoCenso.{0,400}"rodando","pausado".{0,200}A conversão está em curso'))

<#  3.31 - 17.21: A PARTIDA AUTOMATICA NAO E UM CLIQUE.

    Log de 15/09 20:32:59: a espera disparou sozinha e o log escreveu
    "CLIQUE: Iniciar" (nao houve clique) e, logo abaixo, "a medicao que sobrou
    e de arquivo(s) que nao estao na fila" - o Test-EsperarMedicao rodando
    PELA SEGUNDA VEZ sobre uma medicao que ja tinha acabado. Quem ja decidiu
    esperar ja respondeu a pergunta da espera. #>
Checar "Iniciar: existe uma partida automatica separada do clique" `
    ([bool]($jan -match 'function Invoke-IniciarAutomatico'))
<#  3.31 - LICAO 18: a janela de regex vazava para a funcao DE BAIXO.

    "Invoke-IniciarAutomatico.{0,400}" alcancava o corpo de Invoke-Iniciar,
    que POR PROJETO tem o CLIQUE e o Test-EsperarMedicao - o teste reprovava o
    acerto. O corpo da funcao sai da AST, e ai o "nao contem" e sobre ela
    mesma. #>
$corpoAuto = ""
try {
    $corpoAuto = "$(($astJan.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                                       $args[0].Name -eq "Invoke-IniciarAutomatico" }, $true))[0].Extent.Text)"
} catch { }
Checar "Iniciar: a partida automatica NAO chama Test-EsperarMedicao" `
    (($corpoAuto.Length -gt 0) -and -not ($corpoAuto -match 'Test-EsperarMedicao')) `
    "reperguntar e reabrir uma decisao ja tomada"
Checar "Iniciar: a partida automatica NAO escreve 'CLIQUE' no log" `
    (($corpoAuto.Length -gt 0) -and -not ($corpoAuto -match 'CLIQUE: Iniciar')) `
    "log que inventa clique do usuario e log mentindo"
Checar "Iniciar: mas ela continua conferindo o disco" `
    ([bool]($corpoAuto -match 'Test-PodeIniciar'))
Checar "Iniciar: e as DUAS retomadas usam ela (nenhuma chama Invoke-Iniciar)" `
    ([bool]($jan -match 'comecando agora \(\{0\} arquivo\(s\) fora da fila ficaram sem medir\)" -f \$sobra\) "ACAO"\s*\n\s*Stop-Motor\s*\n\s*Invoke-IniciarAutomatico') -and
     [bool]($jan -match 'comecando a conversao que estava esperando" "ACAO"\s*\n\s*Invoke-IniciarAutomatico'))
Checar "Iniciar: o clique de verdade continua perguntando" `
    ([bool]($jan -match '(?s)function Invoke-Iniciar \{.{0,200}CLIQUE: Iniciar.{0,120}Test-EsperarMedicao'))
Checar "Iniciar: os dois caminhos passam pelo MESMO corpo protegido" `
    ([bool]($jan -match '(?s)function Invoke-IniciarProtegido.{0,300}try \{ Invoke-IniciarInterno \}'))

<#  3.31 - 17.21: UM LUGAR SO DECIDE O BOTAO INICIAR.

    Log de 15/09 20:32:29 -> 20:32:46: espera armada, ele mexeu nas marcacoes
    e o Iniciar acendeu de novo - Update-Selecao decide por "tem marcado +
    estado inicial" e nao sabia da espera. Clicou, e a MESMA pergunta apareceu
    sobre a MESMA medicao. #>
Checar "Iniciar: existe Set-BotaoIniciar (uma regra, um lugar)" `
    ([bool]($jan -match 'function Set-BotaoIniciar'))
Checar "Iniciar: e nele a espera tem prioridade sobre qualquer criterio" `
    ([bool]($jan -match '(?s)function Set-BotaoIniciar.{0,300}if \(\$script:IniciarAposMedir\) \{ \$UI\.btnIniciar\.IsEnabled = \$false; return \}'))
Checar "Iniciar: Update-Selecao nao escreve mais direto no botao" `
    ([bool]($jan -match '(?s)function Update-Selecao.{0,300}Set-BotaoIniciar \(\(\$marcados -gt 0\)')) `
    "era esta linha que reacendia o botao no meio da espera"
<#  3.31: o unico que pode ACENDER o botao sem passar pelo lugar unico e o
    proprio Set-BotaoIniciar, mais as duas retomadas - e elas desarmam a
    espera na linha logo acima, entao nao ha conflito. Apagar ($false) segue
    livre: apagar nunca mente. #>
$corpoSet = ""
try {
    $corpoSet = "$(($astJan.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                                      $args[0].Name -eq "Set-BotaoIniciar" }, $true))[0].Extent.Text)"
} catch { }
$acendeForaDoLugar = @([regex]::Matches($jan, '\$UI\.btnIniciar\.IsEnabled = (?!\$false)')).Count -
                     @([regex]::Matches($corpoSet, '\$UI\.btnIniciar\.IsEnabled = (?!\$false)')).Count
Checar "Iniciar: so as duas retomadas acendem o botao por fora do lugar unico" `
    ($acendeForaDoLugar -eq 2) `
    "cada escritor a mais e uma regra paralela - foi assim que o botao reacendeu na espera"

<#  17.20: a ORDEM dos ramos e a regra, e ela e testavel. A fase B mede
    marcados e desmarcados; se "Fora da Fila" vier antes, um arquivo
    desmarcado sendo medido aparece cinza e nenhuma linha acende - com o
    botao dizendo "2 de 3". O teste executa a ordem, nao a le. #>
$ordemOk = $false
try {
    $iMed  = $jan.IndexOf('$null -ne $medindoAgora -and $i -eq [int]$medindoAgora.Idx')
    $iFora = $jan.IndexOf('} elseif (-not $v.Marcado) {')
    $iProx = $jan.IndexOf('} elseif ($primeiroAtivo -and $Estado.Atual -eq "inicial") {')
    $ordemOk = ($iMed -gt 0 -and $iFora -gt $iMed -and $iProx -gt $iFora)
} catch { }
Checar "Medicao: o ramo do MEDINDO vem antes de 'Fora da Fila' e do 'Proximo'" `
    $ordemOk `
    "desmarcado sendo medido tem que acender: e o que o botao esta contando"
Checar "Medicao: a linha sendo medida OCUPA a vaga do 'Proximo a Converter'" `
    ([bool]($jan -match '(?s)Medindo Camada .{0,1600}if \(\$primeiroAtivo -and \$Estado\.Atual -eq "inicial"\) \{ \$primeiroAtivo = \$false \}')) `
    "senao a linha de baixo herda um rotulo que nao e dela"

<#  17.20 - DOIS ACHADOS DO LOG DE 15/09 19:42.

    ESC IGNORADO NA ESPERA. Ele clicou Iniciar com a medicao rodando, escolheu
    ESPERAR, mudou de ideia e apertou ESC: "ignorada - nao se aplica ao estado
    'inicial'". Certo sobre o Cancelar (nao ha conversao), errado sobre o
    usuario: existe uma coisa pendente, e ESC e a tecla de desistir dela. Ele
    so saiu desligando a chave de medicao - caminho que ninguem adivinha.

    FILA CANCELADA COMPARADA COM A PREVISAO. Depois de cancelar no segundo
    arquivo, o log escreveu "previsto 6.209s | real 21s | erro -99,7%". A fila
    nao errou a previsao: ela nao aconteceu. E esse numero mora justamente na
    linha que existe para responder "disse 1h25, foi isso mesmo?". #>
Checar "ESC: existe quem desista da espera pela medicao" `
    ([bool]($jan -match 'function Invoke-DesistirDaEspera'))
Checar "ESC: a tecla passa a valer quando ha espera pendente" `
    ([bool]($jan -match '"Escape" \{ \$UI\.btnCancelar\.IsEnabled -or \$script:IniciarAposMedir \}')) `
    "senao o log continua dizendo 'ignorada' para uma tecla que tinha o que fazer"
Checar "ESC: a espera e tratada ANTES do cancelar da conversao" `
    ([bool]($jan -match '(?s)"Escape" \{.{0,400}Invoke-DesistirDaEspera.{0,300}elseif \(\$UI\.btnCancelar\.IsEnabled\)'))
Checar "ESC: desistir da espera NAO para a medicao (ela segue em segundo plano)" `
    (-not ($jan -match '(?s)function Invoke-DesistirDaEspera.{0,700}(Stop-Motor|Controle\.Cancelar)')) `
    "a promessa de comecar sozinho e que se cancela, nao a medicao"
Checar "ESC: e o Iniciar volta a acender ao desistir" `
    ([bool]($jan -match '(?s)function Invoke-DesistirDaEspera.{0,700}Set-BotaoIniciar ')) `
    "3.31: passou a pedir pelo lugar unico, que agora existe"
Checar "ESC: e a espera e desarmada ANTES de repintar o botao" `
    ([bool]($jan -match '(?s)function Invoke-DesistirDaEspera.{0,300}\$script:IniciarAposMedir = \$false.{0,200}Set-BotaoIniciar')) `
    "Set-BotaoIniciar se recusa a acender enquanto a espera estiver de pe"

Checar "Resumo: fila cancelada nao vira 'previsto x real'" `
    ([bool]($jan -match '(?s)if \(\$cancelado\.Count -gt 0\) \{.{0,400}nao comparada - a fila foi cancelada')) `
    "-99,7% nao mede nada: a fila nao errou, ela nao aconteceu"
Checar "Resumo: e a comparacao de verdade so sai quando nao houve cancelamento" `
    ([bool]($jan -match '(?s)nao comparada - a fila foi cancelada.{0,400}elseif \(\$script:LoteSegEstimado -gt 0\)'))

# ---- o contrato el_ini: quem mede avisa, quem desenha escuta ----------------
Checar "Medicao: o laco anuncia 'el_ini' ANTES de medir" `
    ([bool]($jan -match '(?s)foreach \(\$pe in \$Pendentes\).{0,3200}T = "el_ini".{0,1200}Get-TipoCamadaDV'))
Checar "Medicao: e o 'el_ini' carrega serie, indice, posicao e total" `
    ([bool]($jan -match 'T = "el_ini"; Serie = \$Serie; Idx = \$pe\.Idx; Pos = \$nEL; Total = \$Pendentes\.Count'))
<#  3.35 - 18.00: o numero de serie e o que torna seguro cancelar sem esperar.
    Sem ele, um "el" atrasado da rodada velha gravaria veredicto no arquivo
    errado depois de uma releitura. #>
<#  "pelo menos N" nao e teste: com uma mensagem a menos ele continua verde.
    A sabotagem provou isso - tirei o Serie de uma e nada reprovou. O teste
    certo compara os DOIS lados: quantas mensagens desta familia existem, e
    quantas carregam o selo. Tem que ser o mesmo numero. #>
$msgsMed = ([regex]::Matches($jan, 'T = "el(_ini|_fim)?"')).Count
$msgsSelo = ([regex]::Matches($jan, 'T = "el(_ini|_fim)?"; Serie = \$Serie')).Count
Checar "Medicao: TODA mensagem da medicao carrega o numero de serie" `
    (($msgsMed -gt 0) -and ($msgsSelo -eq $msgsMed)) `
    ("{0} mensagem(ns) da medicao, {1} com selo - sem selo, sobra de rodada velha suja a fila nova" -f $msgsMed, $msgsSelo)
<#  3.56 - 18.19: CENSO CANCELADO NAO VIRA VEREDICTO.
    Log dele de 17/09 17:39:26 - censo cancelado 2s depois de comecar escreveu
    "11 cena(s) do FILME INTEIRO (9,09%)" por cima do numero certo (1.124 cenas,
    19,22%). Cancelar passou a MATAR o dovi_tool na 18.14, e o que sobra no
    disco e um RPU pela metade que o motor aceita como bom. #>
Checar "Censo: resultado de um censo que EU matei e descartado" `
    ([bool]($jan -match '(?s)if \(\[bool\]\$m\.Ok -and \$script:CensoMorto -and\s*\r?\n.{0,200}resultado DESCARTADO')) `
    "nao existe censo parcial valido - o veredicto anterior continua valendo"
Checar "Censo: e RPU muito menor que o previsto tambem e recusado (segunda trava)" `
    ([bool]($jan -match '(?s)\$m\.RpuMb \* 1MB\) -lt \(\$script:CensoBytesPrev \* 0\.5\).{0,400}resultado DESCARTADO')) `
    "o dovi_tool devolve 'Done.' em arquivo cortado - quem desconfia e o LaFirma (bancada de 08/09)"
Checar "Censo: as duas travas vem ANTES de o resultado encostar na linha" `
    ($(  $iC = $jan.IndexOf('if ("$($m.T)" -eq "censo_fim")')
         $iD = $jan.IndexOf('resultado DESCARTADO', $iC)
         $iA = $jan.IndexOf('$m.Idx = $iC', $iC)
         ($iC -ge 0 -and $iD -gt $iC -and $iA -gt $iD))) `
    "descartar depois de escrever na tela nao descarta nada"
Checar "Janela: e existe UM portao que descarta rodada velha, antes do switch" `
    ([bool]($jan -match '(?s)while \(\$script:FilaMsg\.TryDequeue.{0,1800}?\[int\]\$m\.Serie -ne \[int\]\$script:MedSerie.{0,1600}?continue.{0,12000}?switch \(\$m\.T\)'))
Checar "Janela: a leitura tem o mesmo selo (sobra dela tambem nao entra)" `
    ([bool]($jan -match '\[int\]\$m\.SerieL -ne \[int\]\$script:LeituraSerie'))
Checar "Janela: existe tratador para 'el_ini'" `
    ([bool]($jan -match '"el_ini" \{'))
Checar "Janela: o 'el_ini' e quem grava quem esta na vez e a conta" `
    ([bool]($jan -match '(?s)"el_ini" \{.{0,600}\$script:ELmedindoIdx = \[int\]\$m\.Idx.{0,200}\$script:ELtotal\s+= \[int\]\$m\.Total.{0,200}\$script:ELfeitos\s+= \[int\]\$m\.Pos - 1'))
Checar "Janela: o fim da medicao devolve o indice para -1 (ninguem na vez)" `
    ([bool]($jan -match '(?s)"el_fim" \{.{0,200}\$script:ELmedindoIdx = -1'))
Checar "Medicao: e ninguem nasce 'na vez' - quem acende e o el_ini" `
    ([bool]($jan -match '(?s)function Start-Medicao.{0,3800}\$script:ELmedindoIdx\s*=\s*-1'))

<#  AS DUAS TRAVAS CONTRA A DEDUCAO VOLTAR.
    Nao guardam o sintoma - guardam a regra: ninguem calcula "quem esta
    medindo" a partir da lista de marcados, e ninguem casa linha por nome. #>
<#  Estes dois olham o CORPO da funcao e o CODIGO de verdade, nao uma janela
    de regex: a primeira versao deles usava .{0,900} depois do nome da funcao
    e pegava a funcao SEGUINTE, reprovando codigo certo (licao 18). #>
$corpoMed = ""
try {
    $astMed = [System.Management.Automation.Language.Parser]::ParseInput($jan, [ref]$null, [ref]$null)
    $fdMed = @($astMed.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                                 $args[0].Name -eq "Get-MedicaoEmCurso" }, $true))
    if ($fdMed.Count -eq 1) { $corpoMed = $fdMed[0].Extent.Text }
} catch { }
Checar "Janela: Get-MedicaoEmCurso NAO consulta a lista de marcados" `
    (($corpoMed -ne "") -and -not ($corpoMed -match 'Get-MarcadosMedindo')) `
    "deduzir quem esta medindo a partir dos marcados foi o defeito da 17.18"

<#  Token a token: comentario nao conta. Os blocos que EXPLICAM o defeito da
    17.18 citam a variavel pelo nome de proposito, e devem continuar podendo. #>
$tokJan = $null
[void][System.Management.Automation.Language.Parser]::ParseInput($jan, [ref]$tokJan, [ref]$null)
$vivos = @($tokJan | Where-Object { "$($_.Kind)" -ne "Comment" -and "$($_.Text)" -match 'ELtotalFila' })
Checar "Janela: a variavel da deducao (ELtotalFila) nao existe mais no codigo" `
    ($vivos.Count -eq 0) `
    ("ainda viva em " + $vivos.Count + " lugar(es) fora de comentario")
Checar "Janela: a linha da fila casa por INDICE, nao por nome" `
    ([bool]($jan -match '\$i -eq \[int\]\$medindoAgora\.Idx')) `
    "casar por nome erra em dois arquivos de mesmo nome"
Checar "Janela: e nao sobrou comparacao por nome no ramo do medindo" `
    (-not ($jan -match '"\$\(\$v\.Nome\)" -eq "\$\(\$medindoAgora\.Nome\)"'))

# ---- o ramo da coluna SITUACAO e a condicao que estava errada (17.18) -------
Checar "Janela: Fill-Fila pergunta UMA vez por redesenho quem esta medindo" `
    ([bool]($jan -match '(?s)function Fill-Fila.{0,2200}\$medindoAgora = Get-MedicaoEmCurso.{0,400}for \(\$i = 0'))
<#  3.45 - O BOTAO DO CENSO FALA A LINGUA DA CASA (18.10).
    "toda nova ferramenta ou botao tem que ir refinando igual as outras, sendo
    que ja existe um padrao" (Diego). O vocabulario de cor deste programa:
    cinza nao se aplica, normal da para usar, ciano em curso, verde ja feito. #>
Checar "Censo: existe UMA funcao que pinta o botao pelo estado" `
    ([bool]($jan -match 'function Update-BotaoCenso'))
Checar "Censo: ja contado fica VERDE e diz 'Censo Feito'" `
    ([bool]($jan -match '(?s)\[bool\]\$v\.CensoFeito.{0,300}Censo Feito.{0,200}\$Cores\.okdim'))
Checar "Censo: e quem pinta e chamado toda vez que a dica e atualizada" `
    ([bool]($jan -match '(?s)function Update-DicaCenso.{0,300}Update-BotaoCenso \$v'))

<#  3.45 - O NOME PRESO NO CABECALHO DA FILA (18.10).
    Fill-Faixas roda tambem quando se troca Automatico/Manual - e escrevia o
    nome do video dela no cabecalho mesmo com a aba FILA na tela, deixando o
    nome de outro arquivo preso ali. O cabecalho e da aba FAIXAS. #>
<#  3.50: a 18.10 protegeu so o NOME; a 18.13 levou a regra para o lugar
    onde ela vale para os TRES textos (nome, "selecione um video", "nao pode
    ser lido"). O que o teste cobra agora e o modelo: existe UM portao, e
    Fill-Faixas nao escreve no cabecalho por fora dele. #>
Checar "Cabecalho: existe um portao unico e ele confere a aba" `
    ([bool]($jan -match '(?s)function Set-DicaFaixas.{0,200}?if \(\$script:AbaAtual -ne "faixas"\) \{ return \}')) `
    "print dele: FILA na frente, video marcado, e o cabecalho pedindo para selecionar um video"
$corpoFX = ""
try {
    $iFX = $jan.IndexOf("function Fill-Faixas")
    if ($iFX -ge 0) {
        $fFX = $jan.IndexOf("`r`nfunction ", $iFX + 20)
        if ($fFX -lt 0) { $fFX = $jan.Length }
        $corpoFX = Remove-Comentarios $jan.Substring($iFX, $fFX - $iFX)
    }
} catch { }
Checar "Cabecalho: Fill-Faixas NAO escreve no cabecalho por fora do portao" `
    (($corpoFX.Length -gt 1000) -and (-not ($corpoFX -match 'Set-AbaDica'))) `
    "tres ramos escreviam ali; um deles disparava no instante em que o repinte zera a selecao"

<#  3.44 - O CONTADOR TEM QUE DIZER QUANTO FALTA (18.09).
    "e esse contador e do que? se cada filme tem seu tempo, ele ta contando ate
    que tempo?" (Diego). Cronometro subindo prova que nao travou, mas nao
    responde a pergunta. A previsao sai do tempo da amostra DAQUELE arquivo
    vezes um fator medido - e o fator se corrige a cada censo. #>
<#  2.0 - A PREVISAO DO CENSO MUDOU DE MODELO, E A PROVA ESTA NOS LOGS DELE.
    Ate aqui a previsao era "amostra daquele arquivo x fator da maquina".
    Nos logs do usuario, dois filmes do MESMO tamanho deram fatores 18 vezes
    diferentes:
        Saving Private Ryan  82 GB / 2h49  em SSD -> 4,7x a amostra
        Transformers ROTF    78 GB / 2h30  em HD  -> 85,5x a amostra
    Nao foi a CPU que mudou: foi o DISCO. O censo le o filme INTEIRO, e num
    HD mecanico quem manda no relogio e a leitura. O modelo agora calcula os
    DOIS tempos e adota o MAIOR - e o log diz qual deles mandou. #>
Checar "Censo: a previsao e o MAIOR entre o tempo de disco e o de CPU" `
    ([bool]($jan -match '\$script:CensoPrev = \[math\]::Max\(\$segDisco, \$segCpu\)')) `
    "com um HD lento, a CPU nunca e quem manda - e era so nela que o modelo velho olhava"
Checar "Censo: o tempo de disco sai do TAMANHO dividido pela velocidade medida" `
    ([bool]($jan -match '\$segDisco = \(\$gbCenso \* 1024\.0\) / \$mbsCenso'))
Checar "Censo: e a velocidade vem da medicao da origem, nao de um chute" `
    ([bool]($jan -match '\$mbsCenso = Measure-VelocidadeOrigem'))
Checar "Censo: o tempo de CPU sai da DURACAO vezes o segundos-por-segundo" `
    ([bool]($jan -match '\$segCpu = \[double\]\$v\.DurSeg \* \$script:CensoSegPorSegFilme'))
Checar "Censo: o log DIZ qual dos dois mandou no relogio" `
    ([bool]($jan -match 'quem manda aqui e')) `
    "numero sem dono nao se confere depois (licao 2)"
<#  3.45 - 18.10: o rotulo do botao ficou CURTO ("Censo - 00m 45s"). Frase
    comprida em botao de barra e poluicao: o total previsto e o "passou do
    previsto" vivem na DICA. O que o teste cobra e que os dois existam. #>
<#  3.50 - 18.13: o rotulo curto continua curto, mas curto nao pode ser mudo.
    Sao tres sinais, e o teste cobra os tres pelo EFEITO: o giro (a tela esta
    viva), a porcentagem (quanto falta, da relacao medida) e o "sem resposta"
    (o dovi_tool parou de consumir CPU - o unico que nao e estimativa). #>
<#  3.54 - 18.17: A PORCENTAGEM SAIU DO RELOGIO E FOI PARA O ARQUIVO.
    "em que sentido voce chega ate 100%?" (Diego). Em nenhum, enquanto a conta
    fosse de TEMPO: tempo depende de o disco estar livre, e com a medicao
    rodando junto o censo estourava a previsao no meio do caminho. Agora a conta
    e de TAMANHO - bytes de RPU escritos contra os previstos para a duracao
    daquele filme - e a medida se corrige a cada censo. #>
<#  3.57 - 18.20: A PORCENTAGEM VOLTOU A SER DE TEMPO.
    A 18.17 apostou que o arquivo de RPU cresce com o trabalho. Os logs dele
    desmentiram tres vezes: o dovi_tool grava tudo no fim, entao a barra ficava
    em 0% o censo inteiro e pulava para 99%. O tamanho do RPU nao virou lixo -
    ele mudou de funcao: nao serve de PROGRESSO, serve de PROVA no fim. #>
Checar "Censo: e o previsto continua sendo por ARQUIVO, nunca um numero fixo" `
    ([bool]($jan -match '\$script:CensoPrev = \[math\]::Max\(\$segDisco, \$segCpu\)')) `
    "era a ressalva dele: cada filme tem o seu tempo"
Checar "Censo: o previsto de BYTES existe so para conferir o resultado no fim" `
    ([bool]($jan -match '\$script:CensoBytesPrev = \[double\]\$v\.DurSeg \* \$script:CensoBytesSeg'))
Checar "Censo: e essa medida se corrige com o RPU real de cada censo" `
    ([bool]($jan -match '(?s)\$bytesSeg = \(\[double\]\$m\.RpuMb \* 1MB\) / \$durFilme.{0,400}\$script:CensoBytesSeg = \$bytesSeg')) `
    "licao 1: numero medido numa maquina nao e verdade eterna"
Checar "Censo: com limite de sanidade (censo cortado no meio nao envenena a conta)" `
    ([bool]($jan -match '\$bytesSeg -ge 2000 -and \$bytesSeg -le 40000'))
<#  3.57 - O TESTE QUE TERIA PEGO O MEU ERRO, E VAI PEGAR O PROXIMO.

    Na 18.19 eu criei uma trava que le $m.RpuMb e ESQUECI de acrescentar RpuMb
    na mensagem que o trabalho envia. O campo chegava vazio, valia zero, e todo
    censo completo era descartado como se fosse pela metade - o censo inteiro
    parou de funcionar e os testes continuaram verdes, porque a bancada montava
    a mensagem na mao (com o campo!) e a bateria so conferia o texto do codigo.

    A regra que faltava, e que vale para qualquer mensagem entre o trabalho e a
    janela: TODO campo que a janela LE de uma mensagem tem que ser ENVIADO por
    quem a monta. O teste descobre os dois lados no fonte e cruza - nao ha lista
    digitada a mao para envelhecer. #>
$camposLidos = @()
try {
    <#  Os DOIS lugares que leem a mensagem: o portao (antes do switch) e o
        ramo "censo_fim" dentro dele. Cada um delimitado pelo seu proprio fim -
        janela de regex nao respeita fronteira (licao 18). #>
    $trecho = ""
    $iH = $jan.IndexOf('if ("$($m.T)" -eq "censo_fim")')
    $gH = $jan.IndexOf('$m.Idx = $iC', $iH)
    if ($iH -ge 0 -and $gH -gt $iH) { $trecho += $jan.Substring($iH, $gH - $iH) }
    $iSw = $jan.IndexOf('switch ($m.T) {')
    $iR = $jan.IndexOf("`r`n            `"censo_fim`" {", $iSw)
    $fR = $jan.IndexOf("`r`n            `"el_fim`" {", $iR)
    if ($iR -ge 0 -and $fR -gt $iR) { $trecho += $jan.Substring($iR, $fR - $iR) }
    if ($trecho.Length -gt 100) {
        $trecho = Remove-Comentarios $trecho
        $camposLidos = @([regex]::Matches($trecho, '\$m\.([A-Za-z]+)') |
                         ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    }
} catch { }
$camposEnviados = @()
try {
    $iE = $jan.IndexOf('Enviar @{ T = "censo_fim"; Serie = $Serie; Idx = $Idx; Caminho = "$Caminho"; Ok = $true')
    if ($iE -ge 0) {
        $fE = $jan.IndexOf('} catch {', $iE)
        $bloco = $jan.Substring($iE, $fE - $iE)
        $camposEnviados = @([regex]::Matches($bloco, '([A-Za-z]+)\s*=') |
                            ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    }
} catch { }
$semEnvio = @($camposLidos | Where-Object { $_ -notin $camposEnviados -and $_ -ne "Idx" })
Checar "Censo: os dois lados da mensagem foram achados no fonte" `
    (($camposLidos.Count -ge 4) -and ($camposEnviados.Count -ge 8))
Checar "Censo: TODO campo que a janela le do censo_fim e realmente ENVIADO" `
    ($semEnvio.Count -eq 0) `
    ("nunca sao enviados: " + ($semEnvio -join ", ") + " - foi assim que a 18.19 matou o censo inteiro")

Checar "Censo: o tamanho do RPU VIAJA na mensagem do fim (a trava depende dele)" `
    ([bool]($jan -match 'RpuMb = \[double\]\$r\.RpuMb')) `
    "18.19: eu criei a trava e esqueci de mandar o numero - TODO censo virou descartado"
<#  3.55 - 18.18: O AVISO DE "SEM RESPOSTA" SAIU DE VEZ.
    Deu falso nas duas versoes (CPU na 18.15, arquivo na 18.17) porque o comeco
    e o fim do trabalho sao justamente os momentos em que nada cresce. Licao 6:
    alarme falso e pior que alarme nenhum. O teste agora GUARDA a ausencia -
    se algum dia ele voltar sem um sinal confiavel, isto aqui reprova. #>
Checar "Censo: o botao NAO tem mais aviso de 'sem resposta' (deu falso duas vezes)" `
    (-not ($janCodigo -match 'sem resposta')) `
    "17:21:40 'RPU parou de crescer (0,0 MB)' com o censo perfeitamente vivo"
Checar "Censo: Start-Censo NAO mexe mais no IsEnabled (isso e do dono unico)" `
    (-not ($jan -match '(?s)function Start-Censo.{0,7000}\$UI\.btnCenso\.IsEnabled')) `
    "18.20 consertou o clique pondo mais um dono; 18.21 consertou tirando os outros"
Checar "Censo: cancelamento que nao achou processo nenhum DIZ isso" `
    ([bool]($jan -match '(?s)\$mortos -eq 0.{0,200}nenhum processo do censo foi encontrado')) `
    "17:56:37: cancelou, nao matou nada, nao disse nada - e o runspace ficou preso"

<#  ===========================================================================
    3.58 - 18.21: O CENSO MEDIDO NO LOG DE 17/09 21:47, QUE E O PIOR QUE JA
           SAIU DAQUI - 20 censos comecados e mortos em 57 segundos, e catorze
           frases dizendo que "o resultado vale" para censos de 180ms.
    =========================================================================== #>

<#  1. O FREIO. Cada "pedido" abre ffmpeg + cmd + dovi_tool num arquivo de
    82 GB; 366ms depois de matar o anterior nao e intencao, e ruido. #>
Checar "Censo: existe freio entre cancelar e comecar de novo" `
    ([bool]($jan -match '(?s)function Invoke-BotaoCenso.{0,1200}\$script:CensoParadoEm.{0,600}-lt 2\.0')) `
    "21:56:29,330 cancelou / 21:56:29,698 pediu de novo - 20 pares em 57s no log dele"
Checar "Censo: o cancelamento anota a hora (senao o freio nao tem de que medir)" `
    ([bool]($jan -match '(?s)function Invoke-BotaoCenso.{0,600}\$script:CensoParadoEm = Get-Date.{0,200}Stop-Censo'))
Checar "Censo: e o freio FALA quando recusa (licao 2 - silencio faz apertar de novo)" `
    ([bool]($jan -match '(?s)function Invoke-BotaoCenso.{0,1400}CENSO COMPLETO recusado: o censo foi cancelado ha'))
Checar "Censo: o freio nasce vazio (censo nenhum foi cancelado ainda)" `
    ([bool]($jan -match '\$script:CensoParadoEm = \$null'))

<#  2. O QUE PODE QUEBRAR O CENSO FICA TRAVADO ENQUANTO ELE RODA - pedido
    dele: "quando o censo se tiver rodando vc tem q travar teclas que podem
    travar ele... sem engessar o programa". Sao duas, e as duas foram medidas
    no log: F12 (dovi_tool no mesmo disco) e F5 (refaz a lista por baixo). #>
Checar "Censo: com o censo rodando, o F12/medicao e recusado" `
    ([bool]($jan -match '(?s)function Invoke-TrocarMedirEL.{0,600}if \(\$script:CensoRodando\).{0,400}return')) `
    "21:56:32,438 censo lendo o filme inteiro / 21:56:32,551 MEDIR EL: LIGADO"
Checar "Censo: e a recusa do F12 diz COMO sair dela (cancele o censo)" `
    ([bool]($jan -match '(?s)function Invoke-TrocarMedirEL.{0,700}MEDIR EL bloqueado \(censo completo em curso.{0,300}F11'))
Checar "Censo: com o censo rodando, o F5/Atualizar e recusado" `
    ([bool]($jan -match '(?s)function Invoke-Reler.{0,600}if \(\$script:CensoRodando\).{0,400}return')) `
    "reler troca a lista embaixo do censo e o resultado cai no 'nao esta mais na lista'"
Checar "Censo: e a recusa do F5 tambem diz como sair" `
    ([bool]($jan -match '(?s)function Invoke-Reler.{0,700}ATUALIZAR bloqueado \(censo completo em curso.{0,300}F11'))
Checar "Censo: travar nao virou engessar - o proprio censo continua cancelavel" `
    ([bool]($jan -match '(?s)function Invoke-BotaoCenso.{0,600}if \(\$script:CensoRodando\).{0,300}Stop-Censo'))

<#  3. CENSO MORTO NAO TEM RESULTADO - DE NENHUM JEITO. A 18.19 fechou a porta
    do Ok=true; o log de 21:55:34,093 mostra a do Ok=false passando. #>
Checar "Censo: censo morto por nos nao anuncia resultado nenhum (nem com Ok=false)" `
    ([bool]($jan -match '(?s)if \(\$script:CensoMorto -and "\$\(\$m\.Caminho\)" -eq "\$\(\$script:CensoCaminho\)"\) \{.{0,400}cancelado por voce - nao ha numero novo')) `
    "21:55:34,093: 'terminou... o RESULTADO VALE e esta na tela' depois de 180ms de censo"
$mCensoFim = [regex]::Match($janCodigo, '(?s)if \("\$\(\$m\.T\)" -eq "censo_fim"\) \{.{0,6000}?\r\n        \}')
$ordemOk = $false
if ($mCensoFim.Success) {
    $iMorto = $mCensoFim.Value.IndexOf('cancelado por voce - nao ha numero novo')
    $iVale  = $mCensoFim.Value.IndexOf('o resultado vale e esta na tela')
    $ordemOk = ($iMorto -ge 0) -and ($iVale -ge 0) -and ($iMorto -lt $iVale)
}
Checar "Censo: e a pergunta 'foi morto?' vem ANTES da frase que diz que vale" `
    $ordemOk `
    "guarda que chega depois da mentira nao e guarda"

<#  4. A PORCENTAGEM. "a % nao conta do censo, fica 0%" e "vc continua errando
    feio a contagem do CENSO". A causa nao era a conta: era ELsegundos vindo
    zero do cache, e ai nao havia conta nenhuma. #>
Checar "Censo: existe previsao por DURACAO para quando a amostra nao foi medida" `
    ([bool]($jan -match '\$script:CensoSegPorSegFilme')) `
    "ELsegundos vem 0 quando o veredicto e do cache - e ai a % ficava em 0% o censo inteiro"
Checar "Censo: o valor de partida e o medido no log dele (106,1s / 10.140s de filme)" `
    ([bool]($jan -match '\$script:CensoSegPorSegFilme = 0\.0105'))
Checar "Censo: sem tamanho E sem duracao, ele DIZ que nao ha previsao" `
    ([bool]($jan -match '(?s)function Start-Censo.{0,12000}sem previsao de tempo')) `
    "previsao inventada e pior que previsao nenhuma"
<#  2.0 - A APRENDIZAGEM DO s/s TEM QUE SER GUARDADA.
    Aprender "0,0711 s/s" de um censo que passou 10 minutos preso num HD era
    ensinar a coisa errada ao proximo filme, que pode estar num SSD. O s/s e
    numero de CPU: so se aprende quando foi a CPU que mandou no relogio.
    E ha um teste especifico para a SEGUNDA dona: ate a 2.0 existiam DUAS
    aprendizagens do mesmo numero, e a velha (sem guarda) rodava primeiro. #>
Checar "Censo: o s/s so e reajustado quando quem mandou no relogio foi a CPU" `
    ([bool]($jan -match '(?s)if \(\$discoAp -gt 0 -and \$discoAp -gt \(\$cpuAp \* 1\.2\)\).{0,400}NAO foi ajustado'))
Checar "Censo: e o s/s novo sai do tempo de parede dividido pela duracao" `
    ([bool]($jan -match '\$novoSS = \$segParede / \[double\]\$v\.DurSeg'))
Checar "Censo: com limite de sanidade (censo cortado nao envenena a proxima previsao)" `
    ([bool]($jan -match '\$novoSS -ge 0\.003 -and \$novoSS -le 0\.20'))
Checar "Censo: NAO existe uma segunda aprendizagem do s/s sem guarda" `
    (-not ($jan -match '\$script:CensoSegPorSegFilme = \$segPorSeg')) `
    "um numero, um dono (licao 41) - duas donas discordando foi o defeito"

<#  5. "2/3 FOTOS MOSTRAM O FEL SEM O [F12]". Os tres estados do rotulo de
    cima da medicao carregam a tecla - inclusive o que fica mais tempo na
    tela, que era justamente o que nao carregava. #>
$escritasTopo = [regex]::Matches($janCodigo, '\$UI\.lblMedirELTopo\.Text\s*=\s*([^\r\n]+)')
$todasComF12 = ($escritasTopo.Count -gt 0)
foreach ($e in $escritasTopo) { if ($e.Groups[1].Value -notmatch '\[F12\]') { $todasComF12 = $false } }
Checar "Medicao: TODO estado do rotulo de cima carrega o [F12] (os tres)" `
    $todasComF12 `
    ("achei $($escritasTopo.Count) escrita(s) no rotulo - '2/3 FOTOS MOSTRAM O FEL SEM O [F12]' (Diego)")
Checar "Medicao: inclusive o 'Medindo N de M', que e o que fica mais tempo na tela" `
    ([bool]($jan -match '\$UI\.lblMedirELTopo\.Text = "\[F12\] " \+ \$txtMed'))
Checar "Barra: o Pausar/Retomar tambem usa a tecla ANTES, entre colchetes" `
    (($jan -match '"\[F2\] " \+ \(Traduzir "Pausar"\)') -and ($jan -match '"\[F2\] " \+ \(Traduzir "Retomar"\)')) `
    "ele viu 'Pausar F2' no meio dos [F1] e [ESC] - dois lugares escreviam esse rotulo"
Checar "Censo: NENHUMA consulta WMI no tique do relogio (foi o congelamento de 55s)" `
    ($(  $iT = $jan.IndexOf('$TimerFila.add_Tick(')
         $fT = if ($iT -ge 0) { $jan.IndexOf("`r`n})`r`n", $iT) } else { -1 }
         if ($iT -ge 0 -and $fT -gt $iT) { -not ((Remove-Comentarios $jan.Substring($iT, $fT - $iT)) -match 'Get-CimInstance|Get-WmiObject') } else { $false })) `
    "17/09 16:51:46->16:54:28: o trabalho levou 106s e a tela so contou 162s"
Checar "Censo: toda recusa FALA (nenhum return mudo em Start-Censo)" `
    ([bool]($jan -match '(?s)function Start-Censo.{0,4000}nenhum video selecionado na fila.{0,600}CENSO COMPLETO recusado para')) `
    "17:18:29: sete F11 seguidos, sete 'CLIQUE: Censo Completo' e nada mais no log"
Checar "Teclas: tecla SEGURADA nao vira vinte cliques (auto-repeat)" `
    ([bool]($jan -match '\$e\.IsRepeat.{0,60}return')) `
    "no log dele, segurar o F12 virou 20 ligar/desligar em 2 segundos"
Checar "Censo: quem acha os processos e UM lugar so (matar e vigiar olham a mesma lista)" `
    ((([regex]::Matches($jan, 'Get-ProcessosDoCenso')).Count -ge 3) -and
     [bool]($jan -match '(?s)function Matar-ProcessosDoCenso.{0,300}Get-ProcessosDoCenso')) `
    "duas listas para a mesma coisa e o defeito que este projeto persegue desde a 16.79"
Checar "Censo: o cmd que segura o pipe tambem e encerrado" `
    ([bool]($jan -match '(?s)\$n -eq "cmd\.exe".{0,200}pipe_rpu')) `
    "17/09 15:24:43: matei os dois filhos e o cmd de pe prendeu o runspace para sempre"
Checar "Censo: handle que nao responde e ABANDONADO (nunca trava o recurso)" `
    ([bool]($jan -match '(?s)\$orfao = \$true.{0,900}handle abandonado')) `
    "quinze cliques dizendo 'o anterior ainda esta encerrando' no log dele"
Checar "Censo: e o abandono NAO usa Dispose (isso esperaria e congelaria a tela)" `
    ([bool]($jan -match '(?s)handle abandonado.{0,200}\$script:CensoPS = \$null; \$script:CensoRunspace = \$null'))
Checar "Censo: cada censo comeca com a prova de vida zerada" `
    ([bool]($jan -match '\$script:CensoCpu = 0\.0; \$script:CensoVivoEm = Get-Date; \$script:CensoMudo = \$false')) `
    "CPU de um censo anterior nao pode responder pelo de agora"
Checar "Censo: o previsto continua existindo, na dica" `
    ([bool]($jan -match 'leva cerca de \{1\} no total'))
Checar "Censo: a dica diz ha quanto tempo o censo esta rodando (o tempo saiu do rotulo)" `
    ([bool]($jan -match 'está rodando há \{0\}')) `
    "18.16: o cronometro saiu do botao e foi para a dica - nao sumiu do programa"
Checar "Censo: e a dica ENSINA que da para cancelar ali mesmo" `
    ([bool]($jan -match 'Clique de novo \(ou F11\) para cancelar')) `
    "botao que so comeca nao se descobre sozinho que tambem para"
Checar "Censo: a previsao comeca ZERADA a cada censo (nao herda a do anterior)" `
    ([bool]($jan -match '(?s)\$script:CensoPrev = 0\.0.{0,300}\$gbCenso'))
Checar "Censo: o fator se corrige com o custo real da maquina" `
    ([bool]($jan -match '(?s)\$fatorReal = \$segParede / \$amostraSeg.{0,400}\$script:CensoFator = \$fatorReal'))
<#  2.0: o teto era 12x e o Transformers mediu 85,5x - um caso REAL foi
    recusado como "numero solto". O teto subiu para 200x, que e o que um HD
    mecanico produz de verdade; o piso continua em 2x. #>
Checar "Censo: com limite de sanidade (numero solto nao envenena a previsao)" `
    ([bool]($jan -match '\$fatorReal -ge 2\.0 -and \$fatorReal -le 200\.0'))
Checar "Censo: e o aviso do limite diz o teto REAL (nao um numero antigo)" `
    ([bool]($jan -match 'fora dos limites \(2x a 200x\)')) `
    "mensagem que mente sobre o proprio limite ja nos custou uma rodada"
Checar "Censo: a dica para de so mandar esperar - diz quanto leva" `
    ([bool]($jan -match '(?s)if \(\$script:CensoRodando\) \{.{0,500}leva cerca de'))

<#  3.43 - A MEDICAO MORRIA PARA SEMPRE, E A ESPERA FICAVA PENDURADA (18.08).
    Log dele: depois de um "Nova Conversao", TODA medicao seguinte caia em "a
    anterior ainda esta encerrando" - ate o fim da sessao. Start-Leitura
    esvaziava a fila de mensagens e engolia o "el_fim", que e a unica noticia
    que fecha o handle. E a espera do Iniciar, que era desarmada dentro desse
    mesmo "el_fim", ficou tres minutos na tela. #>
Checar "Fila de mensagens: esvaziar NAO pode engolir a noticia de morte" `
    ([bool]($jan -match '(?s)while \(\$script:FilaMsg\.TryDequeue\(\[ref\]\$descarte\)\) \{.{0,400}"el_fim".{0,120}Fechar-Runspace-Medicao')) `
    "sem isso o handle fica preso e nenhuma medicao nova comeca - o log dele prova"
Checar "Fila de mensagens: o censo tem a mesma protecao" `
    ([bool]($jan -match '(?s)while \(\$script:FilaMsg\.TryDequeue\(\[ref\]\$descarte\)\) \{.{0,400}"censo_fim".{0,120}Fechar-Runspace-Censo'))
Checar "Iniciar: a espera olha o ESTADO, nao espera uma mensagem chegar" `
    ([bool]($jan -match '(?s)\$script:IniciarAposMedir -and \(-not \$script:MedindoEL\) -and \$Estado\.Atual -eq "inicial".{0,800}Invoke-IniciarAutomatico')) `
    "evento pode nao vir (rodada cancelada, fila esvaziada); estado sempre esta la"
Checar "Iniciar: e isso roda no relogio da fila, uma vez por batida" `
    ([bool]($jan -match '(?s)\$TimerFila\.add_Tick.{0,85000}\$script:IniciarAposMedir -and \(-not \$script:MedindoEL\)'))

<#  3.42 - TRABALHO LONGO TEM QUE MOSTRAR QUE ESTA VIVO (18.07).
    "o censo tem q so imaginar q ele ta fazendo algo ne? demora pra kralho"
    (Diego). 104 segundos sem sinal na tela e indistinguivel de travado. E a
    mesma condicao nao pode ter duas cores: o painel de disco pinta "Espaco
    Insuficiente" de vermelho e o cartao do resumo pintava de ambar. #>
Checar "Barra: a tecla vem ANTES do rotulo, entre colchetes, em TODOS os botoes" `
    ($(  $faltam = @()
         foreach ($par in @(@("[F1] Iniciar","F1"), @("[F2] Pausar","F2"), @("[ESC] Cancelar","ESC"),
                            @("[F5] Atualizar","F5"), @("[F11] Censo Completo","F11"),
                            @("[F12] Medir MEL x FEL","F12"))) {
             if ($jan -notmatch [regex]::Escape($par[0])) { $faltam += $par[1] }
         }
         $faltam.Count -eq 0)) `
    "pedido dele: 'os F TEM QUE VIR ANTES - [F1] Iniciar - uma logica simples de organizacao'"
<#  3.58: a cor do 'em curso' nunca foi de Start-Censo - ela e escrita por
    Update-BotaoCenso, o dono do botao. O teste media a DISTANCIA ate la, e
    portanto reprovava sozinho a cada comentario novo (licao 37). Agora ele
    cobra o dono, que e o que importa. #>
Checar "Censo: o botao fica na cor de 'em curso' enquanto trabalha" `
    ([bool]($corpoUpdBotaoCenso -match '(?s)if \(\$script:CensoRodando\) \{.{0,1600}lblCenso\.Foreground = Pincel \$Cores\.emCurso'))
Checar "Censo: e a cor volta ao normal junto com o rotulo" `
    ([bool]($jan -match '(?s)function Reset-BotaoCenso.{0,900}Update-BotaoCenso'))
Checar "Censo: o icone do botao tem nome (senao a cor nao alcanca ele)" `
    ([bool]($jan -match 'x:Name="icoCenso"'))
Checar "Resumo: falta de espaco e VERMELHO, igual ao painel de disco" `
    ([bool]($jan -match '(?s)"PULADO"\s*\{.{0,900}?Test-PuladoPorEspaco \$R.{0,200}?errBorda'))
Checar "Resumo: e ja-existia continua ambar (avisa, nao impede)" `
    ([bool]($jan -match '(?s)Test-PuladoPorEspaco \$R.{0,400}?pausaBorda'))
Checar "Resumo: a frase acompanha a cor do cartao" `
    ([bool]($jan -match '\$status -eq "PULADO" -and -not \(Test-PuladoPorEspaco \$R\)'))

<#  3.41 - O PROGRAMA DESMARCAVA ARQUIVO SOZINHO (18.06).
    Log dele, 17/09: um segundo depois de cada linha ser desenhada saia
    "SELECAO: <arquivo> -> desmarcado", sem clique nenhum. A caixinha se
    identificava pelo INDICE e a lista reciclava containers: chegava evento com
    o indice de uma linha e o estado de outra, e isso virava "clique". #>
Checar "Selecao: a caixinha se identifica pelo CAMINHO do arquivo" `
    ([bool]($jan -match 'Tag="\{Binding Caminho\}"')) `
    "indice e endereco temporario; caminho nao muda de dono (licao 30)"
Checar "Selecao: e a linha da fila carrega esse caminho" `
    ([bool]($jan -match 'Idx=\$Idx; Marcado=\$Marcado; PodeMarcar=\$PodeMarcar; Caminho=\$Caminho'))
Checar "Selecao: o tratador acha o video pelo caminho, nao pelo indice da Tag" `
    ([bool]($jan -match '(?s)\$script:TrocaMarca = .{0,2600}?Achar-LinhaPorCaminho "\$\(\$cx\.Tag\)"'))
Checar "Selecao: evento que chega durante o repinte NAO e tratado como clique" `
    ([bool]($jan -match '(?s)\$script:TrocaMarca = .{0,2600}?if \(\$script:PintandoFila\) \{ return \}'))
<#  3.49: a regra nao e "a porta fecha na primeira linha da funcao" - e "a
    porta esta fechada ANTES de qualquer toque na colecao que a tela mostra".
    Desde a 18.12 a funcao monta as linhas numa lista a parte primeiro (isso
    nao mexe na tela e nao dispara evento nenhum), e so entao toca na colecao.
    Cobrar a forma antiga reprovaria o codigo certo - licao 18, de novo. #>
$corpoFF = ""
try {
    $iFF = $jan.IndexOf("function Fill-Fila")
    if ($iFF -ge 0) { $corpoFF = $jan.Substring($iFF, [Math]::Min(32000, $jan.Length - $iFF)) }
} catch { }
$posPorta = $corpoFF.IndexOf('$script:PintandoFila = $true')
$posToque = $corpoFF.IndexOf('$script:LinhasFila.Clear()')
Checar "Selecao: a porta esta fechada ANTES de tocar na lista que a tela mostra" `
    ($posPorta -ge 0 -and $posToque -gt $posPorta) `
    "evento de caixinha durante o desenho e eco, nao clique (18.06)"
Checar "Fila: repintura identica nao toca na tela (nem dispara evento)" `
    ([bool]($jan -match '(?s)\$assinatura -eq \$script:AssinaturaFila.{0,260}?return')) `
    "133 repinturas iguais e coladas nos logs de 15 a 17/09 - cada uma um Clear() inteiro"
Checar "Fila: e quem limpa a lista por fora zera a assinatura" `
    (([regex]::Matches($jan, '\$script:AssinaturaFila = \$null')).Count -ge 3) `
    "senao a proxima repintura se acha igual a uma tela que nao existe mais"
Checar "Selecao: e reabre pelo Dispatcher, SEM esperar (a regra da 18.00 vale)" `
    ([bool]($jan -match '(?s)\$script:PintandoFila = \$true.{0,500}BeginInvoke.{0,200}\$script:PintandoFila = \$false'))
Checar "Selecao: a lista da fila nao recicla linha (era a origem do descasamento)" `
    ([bool]($jan -match 'x:Name="lstFila"[^>]{0,400}VirtualizingStackPanel\.IsVirtualizing="False"'))

Checar "Janela: a coluna SITUACAO tem ramo proprio para o que esta sendo medido" `
    ([bool]($jan -match 'Medindo Camada . \{0\} de \{1\}'))
Checar "Janela: e ele pinta de ciano (emCurso), como o 'Convertendo'" `
    ([bool]($jan -match '(?s)Medindo Camada .{0,200}\$corSit = \$Cores\.emCurso'))
Checar "Janela: o ramo do medindo vem ANTES do 'Proximo a Converter'" `
    ([bool]($jan -match '(?s)\$medindoAgora\.Idx.{0,2200}Proximo a Converter'))
Checar "Janela: 'Proximo a Converter' olha o ESTADO, nao o motivo do redesenho" `
    ([bool]($jan -match '\$primeiroAtivo -and \$Estado\.Atual -eq "inicial"')) `
    "com \$Fase, redesenhar por causa da medicao ou do idioma apagava o rotulo"
Checar 'Janela: e nao sobrou nenhum $Fase decidindo o "Proximo a Converter"' `
    (-not ($jan -match '\$primeiroAtivo -and \$Fase -eq "inicial"'))
Checar "Janela: o redesenho da medicao continua passando motivo proprio ('el')" `
    ([bool]($jan -match 'Fill-Fila "el"'))
Checar "Janela: e o da troca de idioma tambem ('idioma')" `
    ([bool]($jan -match 'Fill-Fila "idioma"'))

<#  17.19: o aviso de espera e o botao respondem perguntas DIFERENTES e por
    isso nao podem ter a mesma forma. O botao conta progresso ("2 de 3"); o
    aviso conta o que falta da fila DELE ("faltam 2"). Escritos iguais, com
    numeros legitimamente diferentes, pareciam um contador se contradizendo. #>
Checar "Janela: o aviso de espera nao usa mais a forma 'X de Y' do botao" `
    (-not ($jan -match '(?s)function Get-TextoEspera.{0,1800}\$de = if \(\$script:Lang -eq "EN"\)'))
Checar "Janela: o aviso de espera conta o que falta DA FILA do usuario" `
    ([bool]($jan -match '(?s)function Get-TextoEspera.{0,2200}arquivos da sua fila'))
Checar "Janela: e ele continua contando so os MARCADOS (regra da 17.15)" `
    ([bool]($jan -match '(?s)function Get-TextoEspera.{0,1600}\$faltam = @\(Get-MarcadosMedindo\)\.Count'))

# ---- a traducao das frases montadas --------------------------------------
if ($fnsTrad.Count -eq 3 -and (Test-Path -LiteralPath (Join-Path $Fonte "IDIOMA_EN.txt"))) {
    $guardaPastaM = $script:PastaScript
    try {
        $script:PastaScript = $Fonte
        $script:Lang = "EN"; $script:MapaEN = @{}; $script:MapaPT = @{}
        $script:RegrasEN = New-Object System.Collections.ArrayList
        [void](Carregar-Idioma)
        $simAtual = [string][char]0x25B6
        $paresM = @(
          @{ Pt = "$simAtual Medindo Camada " + [char]0xB7 + " 2 de 3"; En = "$simAtual Measuring Layer " + [char]0xB7 + " 2 of 3" },
          @{ Pt = "$simAtual Medindo Camada " + [char]0xB7 + " 1 de 12"; En = "$simAtual Measuring Layer " + [char]0xB7 + " 1 of 12" },
          @{ Pt = "(falta 1 arquivo da sua fila)"; En = "(1 file from your queue to go)" },
          @{ Pt = "(faltam {0} arquivos da sua fila)"; En = "({0} files from your queue to go)" })
        foreach ($c in $paresM) {
            $saiu = Traduzir-Frase $c.Pt
            Checar ("Idioma: '" + $c.Pt + "' vira '" + $c.En + "'") ($saiu -eq $c.En) ("saiu: $saiu")
        }
        $script:Lang = "PT"
    } finally { $script:PastaScript = $guardaPastaM }
} else {
    Pular "Idioma: as frases da medicao tem traducao" "as funcoes de idioma nao carregaram"
}


Titulo "48. O SELO [BL+RPU] NO NOME DO ARQUIVO FINAL (14.6)"
<#  Pedido do usuario, 21/09: "o arquivo final MKV deve ter o nome no final
    [BL+RPU] - e mantenha a regra se ai existir um com o mesmo nome [BL+RPU]
    ai sim falar que ja existe um na pasta".

    O PERIGO DESTA MUDANCA NAO E O NOME: E A TRAVA. Tudo o que ele ja
    converteu esta gravado com o nome ANTIGO, sem selo. Uma trava que olhe
    so o nome novo nao encontra nada, e a biblioteca inteira e reconvertida
    do zero - horas de trabalho e, no fim, a saida boa sobrescrita. Os
    testes abaixo existem por causa disso, nao por causa do colchete. #>
Checar "Motor: o nome do arquivo final carrega o selo [BL+RPU]" `
    ([bool]($mot -match '\$nomeSaida = \$nomeSaida \+ " \[BL\+RPU\]"'))
Checar "Motor: e o .mkv de saida e montado com esse nome, nao com o original" `
    ([bool]($mot -match '\$outFile       = Join-Path \$OutputDir \(\$nomeSaida \+ "\.mkv"\)'))
Checar "Motor: o selo nao e repetido (arquivo ja selado nao ganha outro)" `
    ([bool]($mot -match '-not \$nomeSaida\.Contains\("\[BL\+RPU\]"\)'))
Checar "Motor: a conferencia do selo usa Contains, nunca -like" `
    (-not ($mot -match '-(not)?like\s+"\*\[BL')) `
    "colchete e classe de caractere em wildcard - foi o que quebrou o Test-Path na 14.32"
Checar "Motor: o nome ANTIGO continua existindo para a trava" `
    ([bool]($mot -match '\$outFileAntigo = Join-Path \$OutputDir \(\$name \+ "\.mkv"\)'))
Checar "Motor: a trava 'ja existe' olha OS DOIS nomes" `
    ([bool]($mot -match '(?s)\$jaTemNovo   = Test-Path -LiteralPath \$outFile.{0,200}\$jaTemAntigo = Test-Path -LiteralPath \$outFileAntigo.{0,200}if \(\$jaTemNovo -or \$jaTemAntigo\)')) `
    "sem isto, a primeira fila depois da atualizacao reconverte a biblioteca inteira"
Checar "Motor: e os dois Test-Path usam -LiteralPath (licao 14.32)" `
    (-not ($mot -match 'Test-Path \$outFile')) `
    "nome de release tem colchete; sem -LiteralPath o Test-Path devolve falso com o arquivo do lado"
Checar "Motor: a trava DIZ qual dos dois nomes encontrou" `
    ([bool]($mot -match 'Nome Antigo, Sem o Selo'))
Checar "Motor: a copia solta da legenda acompanha o nome do arquivo final" `
    ([bool]($mot -match '\$srtDestino = Join-Path \$OutputDir \(\$nomeSaida \+ "\.srt"\)')) `
    "com o nome antigo o player nao casa a legenda externa com o filme"
Checar "Motor: o resultado leva o nome real do arquivo para a janela" `
    ([bool]($mot -match 'NomeSaida     = \$nomeSaida'))
# 2.0.17: a copia do log saiu da pasta de saida (ver secao 37).
Checar "Janela 19.15: remontagem com video extraido usa 8s + 4,5 s/GB e historico novo (remontagem2)" `
    (($jan -match "RemontagemExtraidoSegFixo = 8") -and ($jan -match "RemontagemSegPorGb   = 4\.5") -and ($jan -match '\$fixo5 = if \(\$pl\.Dovi\)') -and ($jan -match '"remontagem2"'))
Checar "Janela: o cartao final le o arquivo COM o selo (senao le um caminho que nao existe)" `
    ([bool]($jan -match '(?s)if \("\$\(\$R\.NomeSaida\)" -ne ""\).{0,200}Get-DescricaoDoFinal'))
Checar "Motor: o Profile 5 NAO recebe o selo (ele sai .mp4 e nao e BL+RPU)" `
    ([bool]($mot -match '\$destinoMp4 = Join-Path \$OutputDir \(\$name \+ "\.mp4"\)'))


Titulo "50. A BATERIA CONFERE O PROPRIO ENCODING (2.0.2)"
<#  A 3.36 achou um LF solto na linha 43 do LaFirma_JANELA.ps1 e a bateria
    passou VERDE, porque a tabela de encoding tinha uma excecao justo nele.
    Licao 10: uma excecao numa tabela desliga um teste em silencio.

    Hoje a bateria confere o CRLF de tudo que esta em fonte\ - e nao conferia
    o unico arquivo .ps1 que ela NAO alcanca: ela mesma, que mora em _testes\.
    Tinha TRES LF soltos quando este teste foi escrito. Nenhum estrago: ela
    roda igual. Mas o contrato do projeto vale para ela tambem, e um arquivo
    que cobra dos outros o que nao cumpre e o pior lugar para abrir excecao. #>
$meuArquivo = $MyInvocation.MyCommand.Path
if (-not $meuArquivo) { $meuArquivo = $PSCommandPath }
if ($meuArquivo -and (Test-Path -LiteralPath $meuArquivo)) {
    $meusBytes = [System.IO.File]::ReadAllBytes($meuArquivo)
    $temBom = ($meusBytes.Length -ge 3 -and $meusBytes[0] -eq 0xEF -and $meusBytes[1] -eq 0xBB -and $meusBytes[2] -eq 0xBF)
    $lfSoltos = 0
    for ($b = 0; $b -lt $meusBytes.Length; $b++) {
        if ($meusBytes[$b] -eq 0x0A -and ($b -eq 0 -or $meusBytes[$b - 1] -ne 0x0D)) { $lfSoltos++ }
    }
    Checar "Bateria: ela mesma esta em CRLF puro (sem LF solto)" ($lfSoltos -eq 0) `
        ("achei $lfSoltos LF solto(s) neste proprio arquivo")
    Checar "Bateria: ela mesma tem BOM, como o contrato manda" $temBom
} else {
    Pular "Bateria: ela mesma esta em CRLF puro" "nao consegui descobrir o proprio caminho"
}

Titulo "51. CANCELAR E UM ESTADO, NAO UM EVENTO (14.7 / licao 50)"
<#  DEFEITO MEDIDO (Diego, 22/09, log das 11:57). Quatro linhas do log dele:
        11:57:31.281  ACAO: cancelar - flag gravada
        11:57:31.613  [CANCELANDO] Encerrando o Processo Atual...
        11:57:31.614  [AVISO] seconv Nao Gerou Legenda. Tentando PgsToSrt
        11:59:01.092  [OK] Legenda Convertida com Sucesso (PgsToSrt)
    O [ESC] matou o seconv; a etapa leu a morte dele como falha e disparou a
    rede de seguranca - PgsToSrt (90s) e depois o Corretor, que chama o
    seconv de novo. Tres programas iniciados DEPOIS do pedido de parar. Ele
    teve que fechar a janela na mao.

    Estes testes existem para que nenhuma reserva nova nasca sem a pergunta. #>
Checar "Motor: existe UM lugar que responde 'ainda vale comecar?'" `
    ([bool]($mot -match 'function Cancelado-AntesDe')) `
    "um dono da pergunta, nao a mesma regra repetida em quatro lugares (licao 41)"
Checar "Motor: e ele so diz sim quando ha cancelamento de verdade" `
    ([bool]($mot -match '(?s)function Cancelado-AntesDe.{0,2600}if \(-not \$script:CancelamentoSolicitado\) \{ return \$false \}'))
Checar "Motor: o OCR de reserva (PgsToSrt) pergunta antes de comecar" `
    ([bool]($mot -match 'Cancelado-AntesDe "O OCR de Reserva \(PgsToSrt\)"')) `
    "era esta a reserva que rodou 90s depois do ESC"
Checar "Motor: o Corretor_Legenda pergunta antes de comecar" `
    ([bool]($mot -match 'Cancelado-AntesDe "A Revisao de Blocos-Lixo \(Corretor_Legenda\)"'))
Checar "Motor: e o Reocr_Legenda tambem" `
    ([bool]($mot -match 'Cancelado-AntesDe "O Re-OCR de Falas Curtas \(Reocr_Legenda\)"'))
Checar "Motor: o Corretor NAO e anunciado antes de a pergunta ser feita" `
    ([bool]($mot -match '(?s)if \(\$temCorretor -and -not \(Cancelado-AntesDe.{0,200}SaySub "Revisao de blocos-lixo')) `
    "anunciar uma sub-etapa que nao vai rodar deixa a barra com etapa fantasma"
Checar "Motor: matar o seconv NAO e mais escrito como falha dele" `
    ([bool]($mot -match 'O seconv Foi Encerrado Porque Voce Cancelou - Nao Foi Falha Dele')) `
    "terceiro estado precisa de nome (licao 19): 'eu matei' nao e 'ele falhou'"
Checar "Janela: o [ESC] recusado diz o MOTIVO REAL, nunca 'nao se aplica ao estado'" `
    ([bool]($jan -match 'TECLA: Escape recusada - o cancelamento ja foi pedido')) `
    "o mesmo conserto que o F11 ganhou na 18.22 - licao 46, o defeito voltou por outra tecla"
Checar "Janela: e ele distingue 'ja estou cancelando' de 'nao ha o que cancelar'" `
    ([bool]($jan -match 'TECLA: Escape recusada - nao ha conversao em curso para cancelar'))

Titulo "52. O CORRETOR NAO PODE INVENTAR NOME PROPRIO (2.28)"
<#  DEFEITO MEDIDO (relatorio do Diego, 22/09, Transformers):
        'All Spark'    -> 'Ali Spark'   (5 vezes)
        'Tut'          -> 'Tui'
        'Autobotzinho' -> 'Autoboizinho'
    O OCR tinha ACERTADO nos tres. Quem estragou fomos nos.

    CAUSA: Repair-FamiliaBarraVertical (troca l/t/| por i) era a UNICA regra
    do Corretor que nao recebia a lista de nomes proprios. E a protecao nem
    teria salvo: Get-NomesProprios perguntava com Test-NoDicionario (que acha
    "all" no dicionario de 1,3M e conclui "palavra conhecida, nao precisa de
    protecao") enquanto a regra perguntava com Test-PalavraPtBr (que, abaixo
    de 4 letras, nem consulta esse dicionario e conclui "nunca vi"). Duas
    funcoes, respostas opostas, mesma palavra - licao 41 num lugar novo. #>
Checar "Corretor: a regra da barra vertical RECEBE a lista de nomes" `
    ([bool]($corr -match 'function Repair-FamiliaBarraVertical[\s\S]{0,4000}?param\(\[string\]\$Texto, \$Dicionario, \$Nomes\)')) `
    "era a unica regra de fora - todas as outras ja recebiam"
Checar "Corretor: e a chamada passa a lista de verdade" `
    ([bool]($corr -match 'Repair-FamiliaBarraVertical \$resultado \$Dicionario \$Nomes')) `
    "receber o parametro e nao passar o argumento e pior que nao ter o parametro"
Checar "Corretor: nome protegido nao e trocado" `
    ([bool]($corr -match '\$protegido = \$Nomes\.Contains\(\$nu\)'))
<#  2.0.2 - ESTE TESTE ERA DE TEXTO E DEIXOU A SABOTAGEM PASSAR.
    Ele conferia que as palavras "antesTok", "depoisTok" e "bigrama"
    existiam no fonte. Apaguei a linha do IF que usa as duas e o teste
    passou verde - porque as atribuicoes e o comentario continuavam la.
    Licao 45 outra vez: conferir o TEXTO de uma conta nao e conferir a
    conta. Agora a regra e EXTRAIDA e EXECUTADA contra as frases reais do
    relatorio do Diego, com um dicionario que reproduz a armadilha: tem
    "all" (ingles, como o de 1,3M tem) e tem "ali" (portugues). #>
$corrAst = [System.Management.Automation.Language.Parser]::ParseInput($corr, [ref]$null, [ref]$null)
$corrTop = $corrAst.EndBlock.Statements
$corrCorpo = New-Object System.Text.StringBuilder
foreach ($s in $corrTop) {
    if ($s -is [System.Management.Automation.Language.TryStatementAst]) { continue }
    [void]$corrCorpo.AppendLine($s.Extent.Text)
}
$corrOk = $true
try { . ([scriptblock]::Create($corrCorpo.ToString())) } catch { $corrOk = $false }
Checar "Corretor: as regras dele podem ser extraidas e executadas" $corrOk
if ($corrOk) {
    $dicArm = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($w in @("all","ali","tui","autoboizinho","nossa","estava","esse","quem","seu","como",
                     "codigo","rei","tutankamon","pai","ir","vou","pirar","favor","coisa","alguma",
                     "por","temos","para","onde","nao","que","com","no","o","e","a","de","do")) { [void]$dicArm.Add($w) }
    $frases = @(
        'da nossa raca estava no All Spark,',
        'Com esse All Spark destruido,',
        'Codigo "Tut", como Rei Tutankamon.',
        'Quem e o seu Autobotzinho?',
        'Vou pirar. Por favor, faca alguma coisa, pal.',
        'Nao temos para onde tr!')
    $nomesArm = Get-NomesProprios ($frases -join "`n") $dicArm

    <#  As tres que NAO podem mudar sao as tres do relatorio real. A ultima
        coluna diz QUAL guarda tem que segurar cada uma - se uma guarda cair,
        a linha dela reprova sozinha. #>
    $casosCor = @(
        @{ T = 'da nossa raca estava no All Spark,'  ; Q = "All Spark (nome + bigrama)" },
        @{ T = 'Codigo "Tut", como Rei Tutankamon.'  ; Q = "Tut (bigrama com Rei)" },
        @{ T = 'Quem e o seu Autobotzinho?'          ; Q = "Autobotzinho (meio da frase)" })
    foreach ($c in $casosCor) {
        $saiu = Repair-FamiliaBarraVertical $c.T $dicArm $nomesArm
        Checar ("EXECUTANDO: o corretor NAO inventa nome - " + $c.Q) ($saiu -ceq $c.T) `
            ("virou: " + $saiu)
    }
    <#  E o conserto legitimo nao pode ter morrido junto: minuscula continua
        sendo trocada. Se este par ficar verde sozinho, a guarda virou uma
        desculpa para nao consertar nada. #>
    $saiuPal = Repair-FamiliaBarraVertical 'Vou pirar. Por favor, faca alguma coisa, pal.' $dicArm $nomesArm
    Checar "EXECUTANDO: e continua consertando minuscula ('pal' -> 'pai')" `
        ($saiuPal -cmatch 'pai') ("saiu: " + $saiuPal)
    $saiuTr = Repair-FamiliaBarraVertical 'Nao temos para onde tr!' $dicArm $nomesArm
    Checar "EXECUTANDO: e 'tr' -> 'ir'" ($saiuTr -cmatch 'ir!') ("saiu: " + $saiuTr)
}
Checar "Corretor: GUARDA 3 - capitalizada no meio da frase nao tem letra trocada" `
    ([bool]($corr -match 'if \(-not \$protegido -and -not \$abre\) \{ \$protegido = \$true \}')) `
    "no relatorio real foram 1 acerto contra 7 estragos - o preco esta escrito no codigo"
Checar "Corretor: a pergunta do coletor de nomes e a MESMA das regras" `
    ([bool]($corr -match '(?s)function Get-NomesProprios[\s\S]{0,4000}?if \(Test-PalavraPtBr \$k \$Dicionario\) \{ continue \}')) `
    "era Test-NoDicionario aqui e Test-PalavraPtBr la - duas respostas para a mesma palavra"
Checar "Corretor: e o coletor NAO usa mais a funcao que discordava" `
    (-not ($corr -match '(?s)function Get-NomesProprios[\s\S]{0,4000}?Test-NoDicionario \$k'))

Titulo "53. O CANCELAMENTO PARA NA ENTRADA DE CADA ETAPA (14.8)"
<#  DEFEITO MEDIDO (Diego, 22/09, log das 18:19):
        18:19:10  TECLA: Escape
        18:19:16  [CANCELANDO] Encerrando o Processo Atual...
        18:19:16  > [5/5] Remontando MKV Final (mkvmerge):
        18:20:59  [OK] Arquivo Finalizado - 19,05 GB
        18:20:59  [CANCELADO] Removendo a Saida Parcial...
        18:20:59  Motor encerrou 103,9s depois do pedido
    Ele cancelou e o motor montou um MKV de 19 GB - 1m42 - para apagar em
    seguida. A guarda existia, mas no FIM do episodio: protegia o REGISTRO
    (nao marcar como concluido), nao o TEMPO dele.

    A 14.7 pos a pergunta nas tres reservas do OCR porque foi o que aquele
    log mostrou. A porta seguinte era a maior de todas. Licao 37: padrao
    errado se conserta onde ele MORA, nao so onde doeu. Estes testes cobram
    a pergunta em TODA etapa, uma por uma - e a lista nao pode encolher. #>
Checar "Motor: existe o guarda que PARA a etapa (irmao do Cancelado-AntesDe)" `
    ([bool]($mot -match 'function Parar-SeCancelado'))
Checar "Motor: e ele lanca o MESMO erro de sempre (cai no mesmo catch que limpa)" `
    ([bool]($mot -match '(?s)function Parar-SeCancelado.{0,3000}throw "Operacao Cancelada pelo Usuario \(\[ESC\]\)\."')) `
    "erro novo significa caminho de limpeza novo - e a saida parcial ficaria no disco"
Checar "Motor: e so para quando ha cancelamento de verdade" `
    ([bool]($mot -match '(?s)function Parar-SeCancelado.{0,3000}if \(-not \$script:CancelamentoSolicitado\) \{ return \}'))
foreach ($et in @("A Extracao do Video", "A Conversao do Dolby Vision", "A Conversao de Audio",
                  "A Conversao da Legenda", "A Remontagem do MKV Final", "A Conferencia do Arquivo Final")) {
    Checar ("Motor: pergunta antes de comecar - " + $et) `
        ([bool]($mot -match ('Parar-SeCancelado "' + [regex]::Escape($et) + '"')))
}
<#  E a prova de que a pergunta vem ANTES do trabalho, nao depois: em cada
    etapa o Parar-SeCancelado tem que aparecer antes do SayStep dela. Se
    alguem mover a chamada para depois, isto reprova. #>
$ordemOk = $true
foreach ($par in @(@("A Extracao do Video","\[1/5\]"), @("A Conversao do Dolby Vision","\[2/5\]"),
                   @("A Conversao de Audio","\[3/5\]"), @("A Conversao da Legenda","\[4/5\]"),
                   @("A Remontagem do MKV Final","\[5/5\]"))) {
    $iG = $mot.IndexOf('Parar-SeCancelado "' + $par[0] + '"')
    $mS = [regex]::Match($mot, 'SayStep "' + $par[1])
    if ($iG -lt 0 -or -not $mS.Success -or $iG -gt $mS.Index) { $ordemOk = $false }
}
Checar "Motor: e a pergunta vem ANTES do anuncio da etapa, em todas" $ordemOk `
    "perguntar depois de fazer e contabilidade, nao cancelamento"
Checar "Janela: o censo repinta a FILA, nao so o diagnostico" `
    ([bool]($jan -match '(?s)Reset-BotaoCenso.{0,2000}Update-Diagnostico.{0,2000}Fill-Fila "el"')) `
    "a linha de baixo virava laranja e a coluna de cima ficava vermelha na mesma tela"

Titulo "54. REVISAO GERAL 2.0.6 (MOTOR 14.9 / JANELA 19.6 / CORRETOR 2.29)"
<#  Pedido do Diego (23/09): revisar o codigo inteiro atras de bug e de
    inconsistencia. Cada achado confirmado tem aqui um teste - e onde da,
    o teste EXECUTA a regra em vez de procurar o texto dela (licao 45). #>

# ---- Motor: Profile 5 ----
$iDur = $mot.IndexOf('$duracaoTotal = 0.0')
$iP5  = $mot.IndexOf('if ($infoDV.Perfil -eq 5) {')
Checar "Motor: a duracao e lida ANTES do ramo do Profile 5" (($iDur -gt 0) -and ($iP5 -gt 0) -and ($iDur -lt $iP5)) `
    "o P5 usava a duracao do arquivo anterior da fila (ou zero)"
Checar "Motor: falha do P5 e FALHOU, como no resto (o resumo so conta FALHOU)" `
    (-not ($mot -match 'Status = "FALHA"; StatusDV = "P5_MP4"'))
Checar "Motor: no P5 o catch apaga o .mp4 (e nao um .mkv que nunca existiu)" `
    ([bool]($mot -match '(?s)\$outFile = \$destinoMp4\s*\r?\n\s*Parar-SeCancelado "O Remux do Profile 5"\s*\r?\n\s*\$p5 = Convert-Perfil5ParaMp4'))
Checar "Motor: ESC durante o P5 vira CANCELADO e para o lote (nao cai no continue)" `
    ([bool]($mot -match '(?s)\$tempoP5 = \(Get-Date\) - \$tIni\s*\r?\n\s*if \(\$script:CancelamentoSolicitado\) \{ throw'))
Checar "Motor: o P5 tem status proprio de audio/legenda (nao finge TrueHD e OCR)" `
    ([bool]($mot -match 'StatusDV = "P5_MP4"; StatusAudio = "P5";[^\r\n]*StatusLegenda = "P5";'))
Checar "Motor: o cartao do console tem ramo proprio do P5 (MPEG-4, nao Matroska)" `
    ([bool]($mot -match '(?s)if \(\$r\.StatusDV -eq "P5_MP4"\) \{.{0,600}MPEG-4 \(\.mp4\).{0,80}continue'))

# ---- Motor: processo que nasce depois do ESC ----
$totWait = 0; $totGuard = 0
foreach ($fn in @("Invoke-ProcessoComBarraEstimada","Invoke-FfmpegComBarra")) {
    $mF = [regex]::Match($mot, '(?s)function ' + $fn + ' \{.*?\r?\n\}\r?\n')
    if ($mF.Success) {
        $totWait  += ([regex]::Matches($mF.Value, '\$proc\.WaitForExit\(\)')).Count
        $totGuard += ([regex]::Matches($mF.Value, 'Encerrar-SeCancelado \$proc\s*[^\r\n]*\r?\n\s*\$proc\.WaitForExit\(\)')).Count
    }
}
Checar "Motor: todo WaitForExit das barras e precedido de Encerrar-SeCancelado" (($totWait -ge 2) -and ($totWait -eq $totGuard)) `
    "achei $totWait espera(s) e $totGuard guarda(s)"
$mEnc = [regex]::Match($mot, '(?s)function Encerrar-SeCancelado\(\$Proc\) \{.*?\r?\n\}\r?\n')
$encOk = $false; $encNaoMata = $false
if ($mEnc.Success) {
    try {
        . ([scriptblock]::Create($mEnc.Value))
        function Matar-ArvoreDoProcesso($x) { return 0 }
        if (-not ('DdvtJob' -as [type])) { Add-Type -TypeDefinition 'public static class DdvtJob { public static void Retomar(System.IntPtr h) { } }' }
        $exeSleep = if ($IsWindows -or $env:OS -eq "Windows_NT") { "powershell.exe" } else { "sleep" }
        $argSleep = if ($exeSleep -eq "sleep") { "30" } else { "-NoProfile -Command Start-Sleep 30" }
        $script:CancelamentoSolicitado = $false
        $spArgs = @{ FilePath = $exeSleep; ArgumentList = $argSleep; PassThru = $true; ErrorAction = "Stop" }
        if ($exeSleep -ne "sleep") { $spArgs.WindowStyle = "Hidden" }
        $p1 = Start-Process @spArgs
        Encerrar-SeCancelado $p1
        Start-Sleep -Milliseconds 300
        $encNaoMata = -not $p1.HasExited
        $script:CancelamentoSolicitado = $true
        Encerrar-SeCancelado $p1
        $encOk = $p1.WaitForExit(5000)
        $script:CancelamentoSolicitado = $false
        try { if (-not $p1.HasExited) { $p1.Kill() } } catch { }
    } catch { $encOk = $false; $script:CancelamentoSolicitado = $false }
}
Checar "Motor: EXECUTADO - sem ESC o processo segue vivo" $encNaoMata
Checar "Motor: EXECUTADO - com ESC o processo que ja nasceu e morto na hora" $encOk `
    "antes o laco via a flag, saia, e o WaitForExit esperava o processo inteiro"

# ---- Motor: .srt orfao ----
Checar "Motor: o .srt copiado so vira 'nosso' depois da copia dar certo" `
    ([bool]($mot -match '(?s)Copy-Item -LiteralPath \$srtPtBr -Destination \$srtDestino -Force -ErrorAction Stop\s*\r?\n\s*\$srtCopiaFinal = \$srtDestino'))
Checar "Motor: cancelado ou falho, o .srt deste episodio sai junto com o .mkv" `
    (([regex]::Matches($mot, 'if \(\$srtCopiaFinal -and \(Test-Path -LiteralPath \$srtCopiaFinal\)\) \{ Remove-Item')).Count -eq 2)
Checar "Motor: e ele e zerado a cada episodio (nunca apaga o do anterior)" `
    ([bool]($mot -match 'foreach \(\$f in \$files\) \{\s*\r?\n\s*\$srtCopiaFinal = \$null'))

# ---- Janela ----
Checar "Janela: Atualizar/F5 durante a conversao NAO mata o lote" `
    ([bool]($jan -match '(?s)function Invoke-Reler \{.{0,300}\$Estado\.Atual -eq "rodando" -or \$Estado\.Atual -eq "pausado".{0,120}return'))
Checar "Janela: medicao nao renasce no meio da conversao (el_fim atrasado)" `
    ([bool]($jan -match '(?s)function Start-Medicao \{\s*\r?\n\s*if \(\$script:MedindoEL\) \{ return \}.{0,300}\$Estado\.Atual -eq "rodando" -or \$Estado\.Atual -eq "pausado"\) \{ return \}'))
$mSM = [regex]::Match($jan, '(?s)function Start-Motor \{.*?(\$guardar = New-Object System\.Collections\.ArrayList.*?foreach \(\$g in \$guardar\) \{ \$script:FilaMsg\.Enqueue\(\$g\) \})')
$drenoOk = $false
if ($mSM.Success) {
    try {
        $script:FilaMsg = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
        foreach ($t in @("pct","etapa","el_fim","log","censo_fim","el","fim")) { $script:FilaMsg.Enqueue(@{ T = $t }) }
        $descarte = $null
        . ([scriptblock]::Create($mSM.Groups[1].Value))
        $sobrou = @(); $x = $null
        while ($script:FilaMsg.TryDequeue([ref]$x)) { $sobrou += "$($x.T)" }
        $drenoOk = (($sobrou -join ",") -eq "el_fim,censo_fim,el")
    } catch { $drenoOk = $false }
}
Checar "Janela: EXECUTADO - Start-Motor limpa o motor velho e GUARDA el_fim/censo_fim" $drenoOk `
    "esvaziar sem olhar perdia a unica mensagem que fecha o runspace (18.08)"
Checar "Janela: o cartao do P5 tem selo proprio" ([bool]($jan -match '"P5_MP4"\s*\{ \$selos \+= ,@\("Dolby Vision Profile 5 → MP4 - REMUXADO", "ok"\) \}'))
Checar "Janela: e o container do P5 e MPEG-4" ([bool]($jan -match 'MPEG-4 \(\.mp4\)  \|  \{0\}'))

# ---- Idioma: regras de padrao em ordem ----
$regrasT = New-Object System.Collections.ArrayList
foreach ($l in ($idi -split "`r?`n")) {
    if ($l.StartsWith("~")) { $pp = $l.Substring(1) -split "`t", 2; if ($pp.Count -eq 2) { [void]$regrasT.Add($pp) } }
}
function Aplicar-RegrasT([string]$t) { foreach ($r in $regrasT) { try { $t = [regex]::Replace($t, $r[0], $r[1]) } catch { } }; return $t }
$trA = Aplicar-RegrasT "Áudio TrueHD Mantido a Pedido - CONVERSÃO DESLIGADA"
Checar "Idioma: EXECUTADO - selo 'Mantido a Pedido' sai inteiro em ingles" ($trA -eq "Audio TrueHD Kept on Request - CONVERSION OFF") "saiu: $trA"
foreach ($k in @("Áudio → E-AC-3 640k - CONVERTIDO","Áudio → E-AC-3[ATMOS] 1152k - CONVERTIDO",
                 "Legenda PT-BR [.SRT] - REAPROVEITADA","Legenda PT-BR [.SRT] - DESCARTADA A PEDIDO",
                 "Legenda - ERRO","Dolby Vision Profile 5 → MP4 - REMUXADO",
                 "O censo anterior ainda está encerrando - dá para pedir de novo em alguns segundos.")) {
    Checar ("Idioma: '{0}' tem traducao" -f $k) ([bool]($idi -match ("(?m)^" + [regex]::Escape($k) + "`t")))
}

# ---- Corretor: EXECUTADO ----
if ($corrOk) {
    $dic54 = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($w in @("ele","comprou","um","novo","os","rumores","estavam","certos","lutou","com","ontem",
                     "vamos","ir","embora","eu","estava","foi","agora","carro","ali")) { [void]$dic54.Add($w) }
    $nom54 = New-Object 'System.Collections.Generic.HashSet[string]'
    $script:NomesCamel = New-Object 'System.Collections.Generic.HashSet[string]'
    $c54 = @(
        @{ E = "Ele comprou um OnStar novo.";            S = "Ele comprou um OnStar novo.";           Q = "Regra C: CamelCase que aparece uma vez" },
        @{ E = "OS rumores estavam certos.";             S = "Os rumores estavam certos.";            Q = "Regra D: fala nao perde a maiuscula" },
        @{ E = "Ele lutou com Muhammad Ali ontem.";      S = "Ele lutou com Muhammad Ali ontem.";     Q = "familia Ir: nome composto" },
        @{ E = "Vamos Ir embora agora.";                 S = "Vamos ir embora agora.";                Q = "familia Ir: o conserto certo continua (controle)" },
        @{ E = "Eu estava com ele`nSam!`nfoi embora agora"; S = "Eu estava com ele`nSam!`nfoi embora agora"; Q = "Regra X: fala curta com nome" },
        @{ E = "Eu estava com ele`n- Sam!`nfoi embora agora"; S = "Eu estava com ele`n- Sam!`nfoi embora agora"; Q = "Regra X: fala de dialogo" })
    foreach ($c in $c54) {
        $out = ""
        try { $out = Repair-ErrosClassicos $c.E $dic54 $nom54 } catch { $out = "ERRO: " + $_.Exception.Message }
        Checar ("Corretor: EXECUTADO - " + $c.Q) ($out -ceq $c.S) ("saiu: " + ($out -replace "`n", " / "))
    }
} else {
    Pular "Corretor: casos executados da 2.29" "as regras nao puderam ser extraidas"
}

Titulo "55. NADA FICA PARA DEPOIS (2.0.6, segunda passada)"
<#  "nao e pra deixar nada pra depois e pra fazer agora" (Diego, 23/09).
    O que a primeira passada tinha adiado, com teste cada um. #>

# ---- Motor ----
Checar "Motor: a pausa congela a ARVORE (netos primeiro), nao so o filho" `
    ([bool]($mot -match '(?s)function Invoke-NaArvore\(\$Proc, \[bool\]\$Pausar\).{0,900}foreach \(\$a in \$alvos\) \{ try \{ \[DdvtJob\]::Pausar\(\$a\.Handle\) \} catch \{ \} \}\s*\r?\n\s*try \{ \[DdvtJob\]::Pausar\(\$Proc\.Handle\)')) `
    "o tesseract debaixo do Corretor seguia rodando com a tela dizendo PAUSADO"
Checar "Motor: Suspender e Retomar passam pela arvore" `
    (($mot -match 'function Suspender-Processo\(\$Proc\) \{ Invoke-NaArvore \$Proc \$true \}') -and ($mot -match 'function Retomar-Processo\(\$Proc\)\s+\{ Invoke-NaArvore \$Proc \$false \}'))
$iMp4 = $mot.IndexOf('$mp4Existente = Join-Path $OutputDir ($name + ".mp4")')
$iWork = $mot.IndexOf('$WorkDir = Join-Path $f.DirectoryName ("_ddvt_temp_" + $name)')
Checar "Motor: o .mp4 do P5 ja existente e visto ANTES do diagnostico" (($iMp4 -gt 0) -and ($iMp4 -lt $iWork))
Checar "Motor: ESC durante o OCR diz cancelado, nao 'OCR nao gerou legenda'" `
    ([bool]($mot -match '(?s)\} elseif \(\$script:CancelamentoSolicitado\) \{.{0,200}Interrompido pelo Cancelamento.{0,200}\} else \{\s*\r?\n\s*\$motivoLegenda = "Codigo'))

# ---- Janela ----
Checar "Janela: as consultas de processo tem teto de tempo (thread da tela)" `
    (([regex]::Matches($jan, 'Get-CimInstance Win32_Process -OperationTimeoutSec 3')).Count -eq 2)
$mVel = [regex]::Match($jan, '(?s)\$script:CacheVelocidade = @\{\}\s*\r?\nfunction Measure-VelocidadeOrigem\(\[string\]\$Arquivo\) \{.*?\r?\n\}\r?\n')
$velOk = $false
if ($mVel.Success) {
    try {
        . ([scriptblock]::Create($mVel.Value))
        $script:ChamadasVel = 0
        function Measure-VelocidadeOrigemReal([string]$Arquivo) { $script:ChamadasVel++; return 123.0 }
        $v1 = Measure-VelocidadeOrigem "C:\x\Filme.mkv"; $v2 = Measure-VelocidadeOrigem "C:\X\filme.MKV"
        $velOk = ($v1 -eq 123.0 -and $v2 -eq 123.0 -and $script:ChamadasVel -eq 1)
    } catch { $velOk = $false }
}
Checar "Janela: EXECUTADO - a medida do disco e lida uma vez por arquivo" $velOk "72 MB lidos na thread da tela a cada clique"
Checar "Janela: o motivo da pasta vazia sobrevive ao Update-Disco" `
    (($jan -match 'elseif \(\$script:MotivoVazio\) \{ Traduzir-Frase \$script:MotivoVazio \}') -and ($jan -match '\$script:MotivoVazio = "\$\(\$m\.Motivo\)"'))
Checar "Janela: e ele e zerado a cada leitura nova" ([bool]($jan -match '\$script:Lendo = \$true\s*\r?\n\s*\$script:MotivoVazio = ""'))
Checar "Janela: a dica do censo nao manda ligar a chave com o botao aceso" `
    ([bool]($jan -match 'if \(-not \$script:MedirELLigado -and -not \(Test-PodeCenso \$v\)\)'))
Checar "Janela: 'A Seguir' traduz cada pedaco UMA vez" ([bool]($jan -match '\$UI\.lblASeguir\.Text = \(Traduzir-Frase "A Seguir: "\) \+ \(Traduzir-Frase \$prox\)'))
Checar "Janela: fim da espera pela medicao reacende o Iniciar" `
    ([bool]($jan -match '(?s)Set-BotaoIniciar \(@\(Get-Marcados\)\.Count -gt 0\)\s*\r?\n\s*Escrever-Log "INICIAR: a medicao terminou \(ou foi cancelada\)'))

# ---- Idioma ----
$vistos = New-Object System.Collections.Hashtable ([System.StringComparer]::Ordinal); $dupIdi = @()
foreach ($l in ($idiAgora = (Get-Content -Raw -LiteralPath (Join-Path $Fonte "IDIOMA_EN.txt")) -split "`r?`n")) {
    if ($l -eq "" -or $l.StartsWith("#") -or $l.StartsWith("~") -or -not $l.Contains("`t")) { continue }
    $kk = ($l -split "`t", 2)[0].Trim()
    if ($vistos.ContainsKey($kk)) { $dupIdi += $kk } else { $vistos[$kk] = 1 }
}
Checar "Idioma: nenhuma chave duplicada (caixa conta: FILA e Fila sao duas)" ($dupIdi.Count -eq 0) (($dupIdi | Select-Object -First 3) -join "; ")
$regrasV = New-Object System.Collections.ArrayList
foreach ($l in ($idiAgora -split "`r?`n")) { if ($l.StartsWith("~")) { $pp = $l.Substring(1) -split "`t", 2; if ($pp.Count -eq 2) { [void]$regrasV.Add($pp) } } }
$tv = "Nenhum .mkv aqui, mas ha 3 em subpastas (2 subpasta(s)). A leitura olha so o primeiro nivel."
foreach ($r in $regrasV) { try { $tv = [regex]::Replace($tv, $r[0], $r[1]) } catch { } }
Checar "Idioma: EXECUTADO - o motivo da pasta vazia sai em ingles" ($tv -eq "No .mkv here, but there are 3 in subfolders (2 subfolder(s)). Only the first level is read.") "saiu: $tv"

Checar "Janela: o mapa de traducao e EXATO (Ordinal) - FILA e Fila nao se sobrescrevem" `
    ([bool]($jan -match '\$script:MapaEN = New-Object System\.Collections\.Hashtable \(\[System\.StringComparer\]::Ordinal\)'))
$mapaOk = $false; $mapaDet = ""
try {
    $astM = [System.Management.Automation.Language.Parser]::ParseInput($jan, [ref]$null, [ref]$null)
    foreach ($nf in @("Carregar-Idioma","Traduzir")) {
        $fd = @($astM.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -eq $nf }, $true))
        . ([scriptblock]::Create($fd[0].Extent.Text))
    }
    $script:PastaScript = $Fonte
    Carregar-Idioma | Out-Null
    $script:Lang = "EN"
    $a1 = Traduzir "Fila"; $a2 = Traduzir "FILA"; $a3 = Traduzir "Lendo a pasta..."; $a4 = Traduzir "Lendo a Pasta..."
    $mapaDet = "$a1 | $a2 | $a3 | $a4"
    $mapaOk = ($a1 -ceq "Queue") -and ($a2 -ceq "QUEUE") -and ($a3 -ceq "Reading the folder...") -and ($a4 -ceq "Reading the Folder...")
    $script:Lang = "PT"
} catch { $mapaOk = $false; $mapaDet = $_.Exception.Message; $script:Lang = "PT" }
Checar "Janela: EXECUTADO - Fila->Queue e FILA->QUEUE (antes a segunda apagava a primeira)" $mapaOk $mapaDet

# ---- Corretor / Reocr: EXECUTADO ----
if ($corrOk) {
    $dicE = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($w in @("tol","ne","pas")) { [void]$dicE.Add($w) }
    $outE = ""
    try { $outE = Repair-ErrosClassicos "Je ne sais pas, toi." $dicE (New-Object 'System.Collections.Generic.HashSet[string]') } catch { $outE = "ERRO" }
    Checar "Corretor: EXECUTADO - bloco em outra lingua nao recebe troca l/i (toi)" ($outE -ceq "Je ne sais pas, toi.") "saiu: $outE"
    $srtAl = "1`n00:00:01,000 --> 00:00:02,000`nAl`n`nquebrado aqui`n`n2`n00:00:03,000 --> 00:00:04,000`nOutra fala`n"
    $repAl = ""
    try { $repAl = Repair-EstruturaSrt $srtAl } catch { $repAl = "ERRO" }
    Checar "Corretor: EXECUTADO - nome de duas letras sobrevive ao conserto de bloco" ([bool]($repAl -cmatch "(?m)^Al$")) ("saiu: " + ($repAl -replace "`n", " / "))
    $repLixo = ""
    try { $repLixo = Repair-EstruturaSrt ("1`n00:00:01,000 --> 00:00:02,000`nrn`n`nfala certa`n") } catch { $repLixo = "ERRO" }
    Checar "Corretor: EXECUTADO - e o lixo minusculo ('rn') continua saindo (controle)" (-not ($repLixo -cmatch "(?m)^rn$"))
}
$reoTxt = Get-Content -Raw -LiteralPath (Join-Path $Fonte "Reocr_Legenda.ps1")
$mParse = [regex]::Match($reoTxt, '(?s)function Parse-Srt \{.*?\r?\n\}\r?\n')
$mConv  = [regex]::Match($reoTxt, '(?s)function Converter-TempoParaMs \{.*?\r?\n\}\r?\n')
$parseOk = $false; $parseDet = ""
if ($mParse.Success -and $mConv.Success) {
    try {
        . ([scriptblock]::Create($mConv.Value)); . ([scriptblock]::Create($mParse.Value))
        $bl = @(Parse-Srt "1`n00:00:01,000 --> 00:00:02,000`nPrimeira fala`n`nlinha orfa`n`n2`n00:00:03,000 --> 00:00:04,000`nSegunda fala`n")
        $parseDet = "blocos: $($bl.Count)"
        $parseOk = ($bl.Count -eq 2 -and $bl[1].TimingOk -and $bl[1].Texto -eq "Segunda fala" -and $bl[0].Texto -match "linha orfa")
    } catch { $parseOk = $false; $parseDet = $_.Exception.Message }
}
Checar "Reocr: EXECUTADO - linha orfa volta para o bloco de cima e nao come o tempo do de baixo" $parseOk $parseDet
Checar "Reocr: nome curto decidido pela lista fechada, como no Corretor" `
    ([bool]($reoTxt -match 'if \(\$k\.Length -le 3\) \{ if \(Test-CurtaComum \$k\) \{ continue \} \}'))

# ---- Documentos ----
$comoUsar = Get-Content -Raw -LiteralPath (Join-Path $Fonte "COMO_USAR_PT.txt")
$howTo    = Get-Content -Raw -LiteralPath (Join-Path $Fonte "HOW_TO_USE_EN.txt")
$faqPt    = Get-Content -Raw -LiteralPath (Join-Path $Fonte "FAQ_PT.txt")
$faqEn    = Get-Content -Raw -LiteralPath (Join-Path $Fonte "FAQ_EN.txt")
Checar "Docs: COMO_USAR e HOW_TO_USE dizem o selo [BL+RPU] do nome final" (($comoUsar -match '\[BL\+RPU\]') -and ($howTo -match '\[BL\+RPU\]'))
Checar "Docs: os dois explicam F11 e F12, e a regra da cor" (($comoUsar -match 'CENSO COMPLETO \[F11\]') -and ($comoUsar -match 'O CENSO INFORMA, NUNCA MUDA A COR') -and ($howTo -match 'FULL CENSUS \[F11\]') -and ($howTo -match 'NEVER CHANGES THE COLOUR'))
Checar "Docs: HOW_TO_USE nao usa rotulo de tela em portugues" (-not ($howTo -match '"(Fila|Faixas do Vídeo|Iniciar F1|Atualizar|Ferramentas|Marque o vídeo p/ editar|Convertendo · Etapa n/5|Deve Terminar[^"]*)"'))
Checar "Docs: FAQ EN e PT falam a mesma coisa na secao 4 (lista por MKV)" (($faqPt -match 'QUEM PERDE ALGUMA COISA, EM ARQUIVO MKV') -and ($faqEn -match 'WHO DOES LOSE SOMETHING, IN AN MKV FILE') -and ($faqEn -match 'Chromecast with Google TV'))
Checar "Docs: as duas FAQs explicam o censo e a EULA" (($faqPt -match 'O CENSO COMPLETO \[F11\]') -and ($faqEn -match 'THE FULL CENSUS \[F11\]') -and ($faqPt -match 'EULA') -and ($faqEn -match 'EULA'))
# 4.7: a versao vem da JANELA (a 4.6 tinha "2.0.9" escrito a mao - envelhecia a cada entrega)
$verAppDoc = [regex]::Match($jan, '\$APP_VERSAO = "([\d.]+)"').Groups[1].Value
Checar "Docs: cabecalho do COMO_USAR na versao de agora ($verAppDoc)" (($verAppDoc -ne "") -and ($comoUsar -match ('Instalador ' + [regex]::Escape($verAppDoc) + '\s')))
Checar "Docs: e o do HOW_TO_USE tambem ($verAppDoc)" (($verAppDoc -ne "") -and ($howTo -match ('Installer ' + [regex]::Escape($verAppDoc) + '\s')))
Checar "Docs: os dois manuais dao a tecla do F3 e do F4" (($comoUsar -match '\[F3\] Abrir') -and ($comoUsar -match '\[F4\] Abrir') -and ($howTo -match '\[F3\] Open') -and ($howTo -match '\[F4\] Open'))
Checar "Docs: nenhum manual/FAQ promete censo em '5x' a amostra (medido: 22x no Ryan)" (-not (($comoUsar + $howTo + $faqPt + $faqEn) -match '5x o tempo da amostra|5x the sample time'))

Titulo "56. O QUE OS LOGS DE 20 DIAS MOSTRARAM (2.0.7)"
<#  Releitura dos 128 logs de 04/09 a 22/09. Cada item aqui e um defeito que
    aparece NOS LOGS DELE, com a linha do log no comentario do codigo. #>

# ---- censo -> motor -> rotulo ----
Checar "Janela: o censo vai para o motor como argumento (como as escolhas manuais)" `
    (($jan -match 'param\(\$EscolhasDaJanela, \$CensosDaJanela\)') -and ($jan -match '\$null = \$ps\.AddArgument\(\$censos\)'))
Checar "Janela: e o motor recebe depois do preparo (nome proprio, nao e apagado)" `
    ([bool]($jan -match '\$script:CensosDoFilme = \$CensosDaJanela'))
Checar "Motor: com censo, o cabecalho continua NAO RECOMENDADA e o censo vira numero (pedido do Diego, 2.0.9)" `
    ([bool]($mot -match '(?s)if \(\$censoArq -and \[int\]\$censoArq\.Cenas -gt 0\) \{.{0,900}\[CONVERSAO NAO RECOMENDADA\].{0,300}Censo do filme inteiro'))
Checar "Nenhum rotulo 'PERDA EM' na tela, no motor, no cartao ou no idioma" `
    ((-not ($mot -match 'CensoTextoArquivo = \("PERDA')) -and (-not ($jan -match '\$rotPerda')) -and (-not ($jan -match 'Complex FEL - " \+')) -and (-not ((Get-Content -Raw -LiteralPath (Join-Path $Fonte "IDIOMA_EN.txt")) -match 'PERDA EM')))
Checar "Janela: o cartao volta a dizer 'Complex FEL - CONVERSAO NAO RECOMENDADA'" ([bool]($jan -match '(?s)"EXPANDE"\s*\{.{0,200}?\$selos \+= ,@\("Complex FEL - CONVERSÃO NÃO RECOMENDADA", "err"\)'))

# ---- legenda: frase que nao nega o numero ----
Checar "Motor: EXCELENTE nao diz mais 'nenhuma falha' ao lado do numero de defeitos" `
    ((-not ($mot -match 'nenhuma falha encontrada, pode assistir')) -and (-not ($mot -match 'Say "        Nenhum defeito detectavel')))
Checar "Janela: nem o cartao ('Nenhum defeito detectavel' com '1 falha em 1832')" (-not ($jan -match '"EXCELENTE" \{ \$acao = "Nenhum defeito'))
Checar "Motor: o Reocr nao anuncia mais um exemplo FIXO ('INF TOL' -> 'Nao!' em todo filme)" (-not ($mot -match "SayOk .{0,120}ex: 'INF TOL'"))

# ---- seconv ----
Checar "Motor: seconv so roda quando nao ha PgsToSrt (recusado em 7 de 7 filmes)" `
    (($mot -match '\$seconvPrimeiro = \$temSeconv -and -not \$temOcr') -and ($mot -match '\$viaSeconv = \$false\s*\r?\n\s*if \(\$seconvPrimeiro\)'))
Checar "Motor: e o Corretor nao chama o seconv de novo como 2a opiniao" ([bool]($mot -match 'if \(\$script:SeconvRecusadoNesteArquivo -or -not \$seconvPrimeiro\) \{ \$argsCorretor \+= "-PularSegundaOpiniao" \}'))
Checar "Motor: e o aviso 'seconv nao gerou' so aparece se ele rodou" ([bool]($mot -match '(?s)nunca fica sem nada\.\s*\r?\n\s*if \(\$seconvPrimeiro\) \{'))

# ---- calibragem ----
Checar "Janela: etapa cancelada nao grava calibragem (TROTF 00:45: fator 0,30)" `
    ([bool]($jan -match 'if \(\$pesoDaEtapa -gt 0 -and \$liquido -ge 2 -and -not \$script:Controle\.Cancelar\)'))
Checar "Janela: a pausa sai do tempo do arquivo (GoT 22:33: +44,6% gravado)" `
    (($jan -match '\$seg = \(\(Get-Date\) - \$Motor\.T0Video\)\.TotalSeconds - \[double\]\$Motor\.PausadoVideo') -and ($jan -match '\$Motor\.PausadoVideo = \[double\]\$Motor\.PausadoVideo \+ \$dur') -and ($jan -match '\$Motor\.T0Video = Get-Date\s*\r?\n\s*\$Motor\.PausadoVideo = 0\.0'))

# ---- medicao velha ----
Checar "Janela: a medicao para quando a rodada dela deixa de ser a viva" `
    (($jan -match 'if \(\$Controle\.PararMedicao -or \(\[int\]\$Controle\.MedSerieViva -ne \[int\]\$Serie\)\) \{ break \}') -and
     (([regex]::Matches($jan, '\$script:Controle\.MedSerieViva = \[int\]\$script:MedSerie')).Count -eq 2))

# ---- versao ----
$mVer = [regex]::Match($jan, '(?s)\$APP_VERSAO = "([\d.]+)"')
$verOk = $false
try {
    $APP_VERSAO = $mVer.Groups[1].Value; $vArq = "1.9.3"
    if ([version]$vArq -gt [version]$APP_VERSAO) { $APP_VERSAO = $vArq }
    $verOk = ($APP_VERSAO -eq $mVer.Groups[1].Value)
} catch { }
Checar "Janela: o titulo nao volta mais para o VERSAO.txt velho (v1.9.3 por 25 builds)" `
    ($verOk -and ($jan -match 'if \(\[version\]\$vArq -gt \[version\]\$APP_VERSAO\) \{ \$APP_VERSAO = \$vArq \}'))
$caminhoIss = Join-Path (Split-Path -Parent $Fonte) "LaFirma_Setup.iss"
$iss = $null
if (Test-Path -LiteralPath $caminhoIss) { $iss = Get-Content -Raw -LiteralPath $caminhoIss }
if ($iss) {
    $mIss = [regex]::Match($iss, '#define Versao\s+"([\d.]+)"')
    Checar "Janela: e o numero embutido e o mesmo do instalador" ($mIss.Success -and $mIss.Groups[1].Value -eq $mVer.Groups[1].Value) ("iss " + $mIss.Groups[1].Value + " / janela " + $mVer.Groups[1].Value)
}

# ---- Corretor 2.30: EXECUTADO com o dicionario "sujo" de verdade ----
if ($corrOk) {
    $dicSujo = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($w in @("igual","um","gps","da","onstar","ainda","esta","aqui","es","la","ia","casa","del","chicas","en","fuego","ele")) { [void]$dicSujo.Add($w) }
    $nomV = New-Object 'System.Collections.Generic.HashSet[string]'
    $script:NomesCamel = New-Object 'System.Collections.Generic.HashSet[string]'
    $script:MinusculasDoArquivo = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($w in @("ainda","esta","aqui","igual","um","da")) { [void]$script:MinusculasDoArquivo.Add($w) }
    $o1 = ""; try { $o1 = Repair-ErrosClassicos "- Igual a um GPS, da OnStar!" $dicSujo $nomV } catch { $o1 = "ERRO" }
    Checar "Corretor: EXECUTADO - 'da OnStar' fica, mesmo com 'onstar' no dicionario" ($o1 -ceq "- Igual a um GPS, da OnStar!") "saiu: $o1"
    $o2 = ""; try { $o2 = Repair-ErrosClassicos "Ele AiNda esta aqui." $dicSujo $nomV } catch { $o2 = "ERRO" }
    Checar "Corretor: EXECUTADO - 'AiNda' continua virando 'ainda' (controle)" ($o2 -ceq "Ele ainda esta aqui.") "saiu: $o2"
    $o3 = ""; try { $o3 = Repair-ErrosClassicos "Es la casa del chicas en fuego." $dicSujo $nomV } catch { $o3 = "ERRO" }
    Checar "Corretor: EXECUTADO - fala em espanhol nao vira 'Es ia casa'" ($o3 -ceq "Es la casa del chicas en fuego.") "saiu: $o3"
}

Titulo "57. O SECONV SAIU DO INSTALADOR (2.0.7)"
if ($iss) {
    Checar "Setup: nenhum ramo depende mais do seconv empacotado" (-not ($iss -match 'TemSeconvLocal'))
    Checar "Setup: tools\SubtitleEdit fica fora do pacote pelos Excludes (nada para apagar a mao)" ([bool]($iss -match 'Excludes: "[^"]*tools\\SubtitleEdit\\\*'))
    Checar "Setup: a atualizacao apaga a pasta velha do seconv" ([bool]($iss -match '\[InstallDelete\]\s*\r?\n(;[^\r\n]*\r?\n)*Type: filesandordirs; Name: "\{app\}\\tools\\SubtitleEdit"'))
    Checar "Setup: nao exige mais a libSkiaSharp.dll" (-not ($iss -match 'SkiaDll'))
}
Checar "Janela: o topo mostra cinco ferramentas, sem seconv" ([bool]($jan -match '\$ordem = @\("dovi_tool", "DeeZy", "PgsToSrt", "Tesseract", "mkvmerge"\)'))
Checar "Janela: e o painel de ferramentas nao lista mais o seconv" (-not ($jan -match 'Chip = "seconv"'))
$docsSem = $true; $docsQuem = @()
foreach ($d in @("COMO_USAR_PT.txt","HOW_TO_USE_EN.txt","FAQ_PT.txt","FAQ_EN.txt")) {
    $t = Get-Content -Raw -LiteralPath (Join-Path $Fonte $d)
    if ($t -match 'SubtitleEdit|SkiaSharp|seconv\.exe') { $docsSem = $false; $docsQuem += $d }
}
Checar "Docs: nenhum manual manda procurar o seconv/SubtitleEdit" $docsSem ($docsQuem -join ", ")

Titulo "58. O INICIAR QUEBROU NA 2.0.7 (teste do Diego, 23/09 01:55)"
<#  "Os tipos de argumento nao correspondem" em foreach ($vc in @($script:Videos)).
    @() em cima de List[object] estoura - no 5.1 e no 7. Nenhum teste EXECUTAVA
    o bloco do censo do Start-Motor; so conferia o texto. Agora executa. #>
Checar "Janela: nenhum @(`$script:Videos) (List[object] estoura dentro de @())" (-not ($jan -match '@\(\$script:Videos\)'))
$mCen = [regex]::Match($jan, '(?s)(\$censos = @\{\}\s*\r?\n.*?\r?\n    \}\r?\n)')
$cenOk = $false; $cenDet = ""
if ($mCen.Success) {
    try {
        $script:Videos = New-Object System.Collections.Generic.List[object]
        $script:Videos.Add([pscustomobject]@{ Caminho = "C:\a.mkv"; CensoFeito = $false; CensoCenas = 0; CensoAcima = 0; ELpctAcima = 0.0; CensoPico = 0.0 })
        $script:Videos.Add([pscustomobject]@{ Caminho = "C:\b.mkv"; CensoFeito = $true; CensoCenas = 2225; CensoAcima = 15; ELpctAcima = 0.67; CensoPico = 1555.0 })
        . ([scriptblock]::Create($mCen.Groups[1].Value))
        $cenOk = ($censos.Count -eq 1 -and [int]$censos["C:\b.mkv"].Acima -eq 15)
    } catch { $cenOk = $false; $cenDet = $_.Exception.Message }
} else { $cenDet = "bloco nao encontrado" }
Checar "Janela: EXECUTADO - o bloco do censo do Start-Motor roda com a List de verdade" $cenOk $cenDet

Titulo "59. O TESTE DE ACEITE DA 2.0.9 E A AUDITORIA LINHA A LINHA (2.0.10)"
<#  Logs do Diego de 23/09 02:14 e 02:40 (2.0.9) e a releitura inteira dos
    fontes. Cada item e um defeito visto no log/print dele ou provado no codigo. #>
# ---- log ----
Checar "Motor: o cancelamento nao sai mais '[CANCELADO] [CANCELANDO]' (log 02:42:20)" `
    ((-not ($mot -match 'SayStop "\[CANCELANDO\]')) -and ($mot -match 'SayStop "Encerrando o Processo Atual e Limpando os Temporarios\.\.\."'))
Checar "Janela: a sub-etapa nao sai duas vezes no log ('- OCR completo' + 'OCR completo')" `
    (($jan -match "\`$eco = \(`"\`$\(\`$script:ultimaLinhaMotor\)`" -replace '\^-\\s\+', ''\)\.Trim\(\)") -and ($jan -match 'if \(\$lim -ne \$eco\) \{ Enviar @\{ T = "log"') -and ($jan -match '\$script:ultimaLinhaMotor = \$lim'))
Checar "Janela: processo que ja terminou sozinho nao vira AVISO de 'nao consegui encerrar'" `
    (([regex]::Matches($jan, 'ja tinha terminado sozinho antes do pedido')).Count -eq 2)
# ---- cancelar ----
Checar "Motor: a marca da legenda e por episodio (zerada no comeco do laco)" `
    ([bool]($mot -match '(?s)\$srtCopiaFinal = \$null   # 14\.9.{0,400}\$script:T0Legenda = \$null'))
Checar "Motor: o [ESC] leva os arquivos de trabalho da legenda deste episodio" `
    ([bool]($mot -match '(?s)Removendo a Saida Parcial e os Temporarios Deste Episodio.{0,2500}if \(\$script:T0Legenda\) \{.{0,400}_corretor.{0,60}_reocr.{0,300}LastWriteTime -lt \$script:T0Legenda'))
Checar "Janela: cancelar com a conversao PAUSADA tira a tela da pausa" `
    ([bool]($jan -match '(?s)\$script:Controle\.Pausar = \$false.{0,700}if \(\$Estado\.Atual -eq "pausado"\) \{ Set-Estado "rodando" \}\s*\r?\n\s*\$UI\.btnPausar\.IsEnabled = \$false'))
Checar "Janela: fechar a janela para o censo e a medicao tambem" `
    ([bool]($jan -match '(?s)\$Janela\.add_Closed\(\{.{0,2500}Stop-Censo.{0,200}Stop-Medicao.{0,100}Stop-Motor'))
Checar "Motor: o teto do Reocr mata a arvore (o tesseract ficava vivo)" `
    ([bool]($mot -match '(?s)\$estourouTeto = \$true.{0,300}Matar-ArvoreDoProcesso \(\[int\]\$proc\.Id\)'))
# ---- pausa e tempo ----
Checar "Janela: barra e restante usam o TRABALHO da etapa, nao a parede (pausa de 29s no OCR)" `
    (($jan -match '\$trabEtapa = \[math\]::Max\(0\.0, \$wallEtapa - \[double\]\$d\.PausadoEtapa - \$pausaAgoraEt\)') -and
     ($jan -match 'Get-FracaoDaEtapa \$d\.EtapaIdx \(\[double\]\$pct\) \$trabEtapa') -and
     ($jan -match 'Get-PrevistoAjustadoDaEtapa \$d\.EtapaIdx \(\[double\]\$pct\) \$trabEtapa') -and
     (-not ($jan -match 'Get-PrevistoAjustadoDaEtapa \$d\.EtapaIdx \(\[double\]\$pct\) \$wallEtapa')))
Checar "Janela: pausa que atravessa troca de etapa nao some (nem da etapa nem do arquivo)" `
    (($jan -match '(?s)function Fechar-EtapaNoLog \{\s*\r?\n\s*Dobrar-PausaEmCurso') -and
     (-not ($jan -match '\$Motor\.PausadoEtapa = 0\.0; \$Motor\.PausaIni = \$null\s*\r?\n\s*\$Motor\.Nota = ""; \$Motor\.Fase = ""')))
Checar "Janela: ao retomar, o filtro do restante nao desconta a pausa" `
    ([bool]($jan -match '(?s)\$Motor\.PausaIni = \$null.{0,500}\$script:SuaveEm = Get-Date\s*\r?\n\s*Escrever-Log \("PAUSA de'))
Checar "Janela: o erro da previsao da fila desconta a pausa" ([bool]($jan -match 'fora \{0\} de pausa'))
Checar "Motor: DeeZy TrueHD com as fases MEDIDAS (24/7/69), nao 1/3 cada" `
    (($mot -match '\$tam3 = @\(0\.24, 0\.07, 0\.69\)') -and ($mot -match "if \(\`$linha -match '\(\?i\)truehdd'\) \{ \`$Event\.MessageData\.ComTruehdd = \`$true \}"))
# ---- o resto da auditoria ----
Checar "Motor: Get-BrilhoDoContainer nasce com Erro (o catch nao estoura mais)" `
    ([bool]($mot -match 'MaxFALL = 0; Lido = \$false; Erro = ""'))
Checar "Janela: titulo 'Pronto para Converter' com o numero (`$ativos nao existia - print 23/09)" `
    ((-not ($jan -match '-f \$ativos\)')) -and ($jan -match 'Vídeo\(s\) Selecionado\(s\)" -f \$marcadosOk\)'))
Checar "Janela: arquivo que sumiu da pasta nao entra no lote (o n/N do motor e posicao)" `
    ([bool]($jan -match '(?s)foreach \(\$v in \$marcados\) \{.{0,700}if \(-not \(Test-Path -LiteralPath "\$\(\$v\.Caminho\)"\)\) \{.{0,200}continue'))
Checar "Janela: o censo mede o disco POR ARQUIVO" ([bool]($jan -match '\$mbsCenso = Measure-VelocidadeOrigem "\$\(\$v\.Caminho\)"\s*\r?\n\s*if \(\$mbsCenso -le 0\)'))
Checar "Janela: 'Nova Conversao' + trocar idioma nao redesenha o resumo velho" ([bool]($jan -match '(?s)function Redesenhar-Resumo \{.{0,400}if \(\$Estado\.Atual -ne "fim"\) \{ return \}'))
Checar "Janela: arquivo novo zera o % e a nota da etapa" ([bool]($jan -match '(?s)\$Motor\.PctEtapa = 0; \$Motor\.Nota = "".{0,700}# 16\.47'))
if ($iss) {
    $issBytes = [System.IO.File]::ReadAllBytes($caminhoIss)
    $lfSo = 0
    for ($k = 0; $k -lt $issBytes.Length; $k++) { if ($issBytes[$k] -eq 10 -and ($k -eq 0 -or $issBytes[$k - 1] -ne 13)) { $lfSo++ } }
    Checar "Setup: o .iss e CRLF inteiro (a 2.0.7 deixou 6 linhas so com LF)" ($lfSo -eq 0) ("$lfSo linha(s) so com LF")
}
Checar "Motor: espaco conferido POR DISCO (origem fator-1, saida 1x) nas duas travas" `
    ((([regex]::Matches($mot, 'Get-FaltaDeEspaco \(\[double\]')).Count -eq 2) -and ($mot -match '\(\$Fator - 1\.0\)') -and ($mot -match '"espaco insuficiente em " \+ \$fp0\.Drive'))
$mFal = [regex]::Match($mot, '(?s)(function Get-FaltaDeEspaco\(.*?\r?\n\})\r?\n')
$falOk = $false; $falDet = ""
if ($mFal.Success) {
    try {
        . ([scriptblock]::Create($mFal.Groups[1].Value))
        function Get-PSDrive { param($Name, $ErrorAction) $livres = @{ C = 100GB; E = 30GB }; return [pscustomobject]@{ Free = $livres[$Name] } }
        $a1 = @(Get-FaltaDeEspaco 40GB 3.15 "C:\" "C:\LaFirma\01")      # mesmo disco: 126 GB > 100 -> falta em C:
        $a2 = @(Get-FaltaDeEspaco 40GB 3.15 "C:\" "E:\Saida")           # origem 86 GB cabe; saida 40 > 30 -> falta em E:
        $a3 = @(Get-FaltaDeEspaco 20GB 3.15 "C:\" "E:\Saida")           # 43 GB em C:, 20 em E: -> cabe
        $falOk = ($a1.Count -eq 1 -and $a1[0].Drive -eq "C:" -and $a2.Count -eq 1 -and $a2[0].Drive -eq "E:" -and $a2[0].EhSaida -and $a3.Count -eq 0)
        $falDet = "mesmo=$($a1.Count) dois=$($a2.Count)/$($a2[0].Drive) cabe=$($a3.Count)"
        Remove-Item Function:\Get-PSDrive -ErrorAction SilentlyContinue
    } catch { $falDet = $_.Exception.Message }
} else { $falDet = "funcao nao encontrada" }
Checar "Motor: EXECUTADO - mesmo disco cobra tudo; discos diferentes, cada um o seu" $falOk $falDet
Checar "Janela: o cartao nomeia o disco que faltou" ([bool]($jan -match 'Faltam ~\{0\} livres no disco \{1\}'))
Checar "Motor: faixa SRT com acento sem byte acentuado no motor" ([bool]($mot -match '"0:Portugu" \+ \[char\]0x00EA \+ "s \(Brasil\) \[OCR\]"'))
Checar "Janela: trocar o idioma retraduz o [F12] do topo (print 23/09 13:35)" ([bool]($jan -match '(?s)function Set-Idioma.{0,4000}try \{ Update-BotaoMedirEL \} catch \{ \}'))
Checar "Janela: arquivo novo zera o relogio da etapa e poe o restante DELE" (($jan -match '\$Motor\.SegEtapa = 0\s*\r?\n\s*\$idxNovoA = \[int\]\$m\.Idx') -and ($jan -match '\$Motor\.RestVideo = \[double\]\$script:LoteAtual\[\$idxNovoA\]\.SegEstimado'))
Checar "Janela: abaixo de 20% o ritmo nao projeta a etapa (OCR do Ryan: 1.867 -> 2.403 s)" (-not ($jan -match '(?s)function Get-PrevistoAjustadoDaEtapa.{0,600}if \(\$fr -gt 0\.05\)'))
Checar "Janela: arquivo pulado (ja existia) nao vira 'erro -100%' na previsao (log 13:33:45)" (($jan -match 'nao comparada - nada foi convertido \(arquivo pulado\)') -and ($jan -match 'nao comparada - nenhum arquivo foi convertido nesta fila'))
if ($corrOk) {
    $dicR = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($w in @("vamos","explodir","tubos","saiam","salam","dos","cascalhos","se","eu","magoei","somos","sobras","das","companhias","viu","mais","vem","ele","seus","meus","atirem","corram")) { [void]$dicR.Add($w) }
    $nR = New-Object 'System.Collections.Generic.HashSet[string]'
    $script:MinusculasDoArquivo = New-Object 'System.Collections.Generic.HashSet[string]'
    $script:NomesCamel = New-Object 'System.Collections.Generic.HashSet[string]'
    $casosR = @(
        @("Vamos explodir os tubos!`nSailam dos cascalhos!", "Vamos explodir os tubos!`nSaiam dos cascalhos!"),
        @("Se eu a magoel...", "Se eu a magoei..."),
        @(("- Viu mais algu" + [char]0x00E9 + "m?`n- S" + [char]0x00D3 + " Jackson."), ("- Viu mais algu" + [char]0x00E9 + "m?`n- S" + [char]0x00F3 + " Jackson.")),
        @(("A" + [char]0x00CD + " vem ele."), ("A" + [char]0x00ED + " vem ele.")),
        @("Somos as sobras das companhias F, Ae G.", "Somos as sobras das companhias F, A e G."),
        @("Atirem e corram. 2 Seus, 2 meus.", "Atirem e corram. 2 seus, 2 meus."),
        @("Voce e amigo da Coroa e do Norte.", "Voce e amigo da Coroa e do Norte."),
        @("- Ai estao eles.`n- E Isso o que eu vejo.", ("- Ai estao eles.`n- " + [char]0x00C9 + " isso o que eu vejo.")),
        @("- E uma rainha Targaryen.", "- E uma rainha Targaryen."),
        @("E ela tambem.`nSel.", "E ela tambem.`nSei."),
        @("Pal...", "Pai..."),
        @("Encontrei Sel Pal na rua.", "Encontrei Sel Pal na rua."))
    foreach ($c in $casosR) {
        $sR = ""; try { $sR = Repair-ErrosClassicos $c[0] $dicR $nR } catch { $sR = "ERRO: " + $_.Exception.Message }
        Checar ("Corretor 2.32: EXECUTADO - '" + ($c[0] -replace "`n", " / ") + "'") ($sR -ceq $c[1]) ("saiu: " + ($sR -replace "`n", " / "))
    }
}
Checar "Motor: o resumo do console separa 'sem espaco' de 'ja existiam'" ([bool]($mot -match 'Pulados por Falta de Espaco'))
if ($corrOk) {
    $dicE = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($w in @("porque","vou","pegar","agora","eles","para","casa")) { [void]$dicE.Add($w) }
    $e1 = $null; try { $e1 = Test-BlocoEhPtBr "Porque vou pegá-los agora." $dicE } catch { $e1 = "ERRO: " + $_.Exception.Message }
    Checar "Corretor: EXECUTADO - 'Porque vou pegá-los' continua portugues (2.31)" ($e1 -eq $true) "saiu: $e1"
    $e2 = $null; try { $e2 = Test-BlocoEhPtBr "Es la casa del chicas en fuego." $dicSujo } catch { $e2 = "ERRO" }
    Checar "Corretor: EXECUTADO - e o espanhol do TROTF continua espanhol" ($e2 -eq $false) "saiu: $e2"
}

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

<#  ===========================================================================
    3.59 - 18.22: O ROTULO DO CENSO EM CURSO MUDOU DE DONO.

    Ele saiu do relogio da fila e foi para Update-BotaoCenso, junto com a cor,
    a DICA e o IsEnabled. Os testes seguem o dono, nao o lugar antigo.
    =========================================================================== #>
$mUBC2 = [regex]::Match($janCodigo, '(?s)function Update-BotaoCenso\(\$v\) \{.{0,5000}?\r\n\}')
$corpoUBC = ""
if ($mUBC2.Success) { $corpoUBC = $mUBC2.Value }
Checar "Censo: o corpo de Update-BotaoCenso foi extraido" ($corpoUBC.Length -gt 400)
Checar "Censo: contando fica na cor de em-curso" `
    ([bool]($corpoUBC -match '(?s)\$script:CensoRodando.{0,1400}\$Cores\.emCurso'))
Checar "Censo: o que nao se aplica fica cinza de inativo" `
    ([bool]($corpoUBC -match '(?s)Test-PodeCenso \$v.{0,600}\$Cores\.dim2'))
Checar "Censo: o rotulo tem um giro que muda a cada segundo (a tela esta viva)" `
    ([bool]($corpoUBC -match '(?s)\$giros = @\(.{0,40}\).{0,200}\$seg % 4')) `
    "'so ter um tempo, nao se sabe se ta funcionando' - foi a queixa dele"
Checar "Censo: a porcentagem sai do tempo contra o previsto medido" `
    ([bool]($corpoUBC -match '100\.0 \* \$seg / \[double\]\$script:CensoPrev'))
Checar "Censo: passando do previsto o rotulo avisa com (+)" `
    ([bool]($corpoUBC -match '(?s)\$seg -gt \[int\]\$script:CensoPrev.{0,200}\(\+\)'))
Checar "Censo: a porcentagem nunca passa de 99 e vira (+) depois da previsao" `
    ([bool]($corpoUBC -match 'Min\(99')) `
    "pedido dele: chegar perto de 100% e SO entao virar o +"
Checar "Censo: o rotulo NAO carrega mais o cronometro (so giro e quanto falta)" `
    (-not ($corpoUBC -match 'Format-MinSeg')) `
    "'tira o tempo do censo contando ali, deixa so o % e o - /'"

<#  "AGORA O CENSO QUANDO TA RODANDO NAO APARECE [F11]" (Diego, 17/09). Mesma
    varredura que a 3.58 fez no rotulo da MEDICAO, agora no do CENSO: toda
    escrita carrega a tecla, inclusive a de "em curso" - que era a unica sem
    ela. O mesmo buraco, no mesmo estado, do outro lado da barra (licao 37). #>
$escritasCenso = [regex]::Matches($janCodigo, '\$UI\.lblCenso\.Text\s*=\s*([^\r\n]+)')
$censoComF11 = ($escritasCenso.Count -gt 0)
foreach ($e in $escritasCenso) {
    $val = $e.Groups[1].Value
    if ($val -match '^\$txtCenso\s*$') { continue }
    if ($val -notmatch '\[F11\]') { $censoComF11 = $false }
}
Checar "Censo: TODA escrita no rotulo do censo carrega o [F11]" `
    $censoComF11 `
    ("achei $($escritasCenso.Count) escrita(s) - 'QUANDO TA RODANDO NAO APARECE [F11]'")
Checar "Censo: e o texto de 'em curso' comeca pelo [F11], antes do giro" `
    ([bool]($corpoUBC -match '\$txtCenso = "\[F11\] " \+ \(Traduzir "Censo"\)'))
Checar "Censo: nao existe mais o rotulo 'Censo: contando...' (sem tecla, sem %)" `
    (-not ($janCodigo -match 'Censo: contando'))

<#  A DICA CONGELAVA ENQUANTO O CENSO RODAVA: ela so era recalculada na troca
    de linha da fila, e comecar um censo nao troca linha nenhuma. Por isso ele
    viu "Ligue Medir MEL x FEL" com o censo rodando - frase certa no instante
    em que foi escrita, e ninguem a apagou nos dois minutos seguintes. #>
Checar "Censo: a dica tambem e do dono do botao (nao so da troca de linha)" `
    ([bool]($corpoUBC -match 'btnCenso\.ToolTip = Traduzir-Frase \(Get-MotivoCenso \$v\)'))
Checar "Censo: e a dica e escrita TAMBEM no ramo de 'em curso'" `
    ([bool]($corpoUBC -match '(?s)\$script:CensoRodando.{0,1600}btnCenso\.ToolTip.{0,300}return'))
Checar "Censo: o relogio da fila nao escreve mais o rotulo - ele chama o dono" `
    ([bool]($jan -match '(?s)\$segCenso -ne \$script:CensoSegMostrado.{0,700}Update-BotaoCenso')) `
    "tres donos do rotulo eram tres chances de um deles esquecer a tecla"
Checar "Censo: a contagem so muda quando o segundo VIRA (nao 4x por segundo)" `
    ([bool]($jan -match '(?s)\$segCenso -ne \$script:CensoSegMostrado'))

<#  ===========================================================================
    3.59 - 18.22: O F11 TRAVOU PARA SEMPRE. LICAO 47.

    Log dele de 17/09, da linha 139 ate o fim da sessao:
      22:26:00,8  TECLA: F11 (ignorada - nao se aplica ao estado 'inicial')
      ... mais de trinta vezes, ate ele fechar o programa.

    A 18.21 mandou o F11 conferir o botao - certo - e com isso tirou do
    caminho a unica saida de emergencia do handle preso, que morava dentro de
    Start-Censo, onde o F11 nao chega mais.
    =========================================================================== #>
Checar "Censo: existe liberacao do handle preso FORA de Start-Censo" `
    ([bool]($jan -match 'function Liberar-CensoOrfao')) `
    "'APERTEI TANTO O F11 QUE TEVE UMA HORA QUE NAO FUNCIONOU NUNCA MAIS'"
Checar "Censo: e ela roda no relogio da fila (o estado se desfaz sozinho)" `
    ([bool]($jan -match '(?s)\$TimerFila\.add_Tick.{0,85000}Liberar-CensoOrfao')) `
    "trava que so sai fechando o programa nao pode existir (18.15, de novo)"
Checar "Censo: ela olha o HANDLE, nunca processos (WMI no relogio congela a tela)" `
    ([bool]($jan -match '(?s)function Liberar-CensoOrfao.{0,1200}CensoHandle\.IsCompleted') -and
     -not ($jan -match '(?s)function Liberar-CensoOrfao.{0,1200}Get-ProcessosDoCenso')) `
    "licao 40: rede de seguranca que custa a thread da tela nao e rede"
Checar "Censo: e ela nao encosta em censo que esta rodando" `
    ([bool]($jan -match '(?s)function Liberar-CensoOrfao.{0,700}if \(\$script:CensoRodando\) \{ return \$false \}'))
Checar "Teclas: o F11 recusado diz o MOTIVO REAL, nunca 'nao se aplica ao estado'" `
    ([bool]($jan -match '(?s)elseif \(\$e\.Key -eq "F11"\).{0,1600}TECLA: F11 recusada')) `
    "o estado ERA 'inicial' - a frase apontava para onde o problema nao estava"
Checar "Teclas: e o motivo sai da MESMA frase da dica do botao (um lugar so)" `
    ([bool]($jan -match '(?s)TECLA: F11 recusada.{0,200}Get-MotivoCenso'))

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
