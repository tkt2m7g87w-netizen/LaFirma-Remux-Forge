<#
================================================================================
 LaFirma - Reocr_Legenda.ps1
 Versao 1.29
 --------------------------------------------------------------------------
 HISTORICO (entrada nova a cada mudanca de $Versao, na MESMA edicao)
 --------------------------------------------------------------------------
  1.29  01/09/2026 - Nenhuma regra mudou. Uma auditoria apontou que a regra 3
        (e a nota que escolhe a leitura vencedora) pergunta ao dicionario sobre
        palavra curta. MEDI nos 8.887 blocos dos quatro filmes: a 'correcao'
        levaria de ~10 para 850 blocos suspeitos, +28 min por lote, e cada
        troca errada seria defeito novo numa legenda que sai EXCELENTE.
        Fala normal em portugues e cheia de palavra curta - a conta PRECISA
        conta-las. A decisao e o numero ficaram escritos ao lado da regra.
  1.28  28/08/2026 - Dois achados de auditoria, medidos em 4 conversoes:
        (a) A trava que ACEITA a leitura nova perguntava ao dicionario de
            1,3M sobre palavra de 2 e 3 letras. Com dois tokens ('nf tor')
            a conta dava 100% e o lixo era GRAVADO no .srt. Agora vale a
            regra da casa: abaixo de 4 letras so a lista fechada ou nome
            proprio. Medido nas 27 trocas reais de 28/08 (Lara, Troia,
            Aranha e GoT): as 27 continuam passando; 'nf tor' e 'tor inf'
            passam a ser recusadas.
        (b) O RESUMO dizia 'Recusados: 4' e a nota dizia '2 com defeito'.
            Os dois estavam certos, mas ninguem adivinha que recusado nao e
            defeito. A linha agora se explica onde aparece.
  1.27  27/08/2026 - Bloco vazio saia gravado com DUAS linhas em branco
        (o AppendLine do texto vazio mais o separador). Duas linhas em branco
        seguidas quebram o formato do .srt - e este e o arquivo que entra no
        .mkv. Mesmo defeito e mesmo conserto do Corretor 2.25.
  1.26  27/08/2026 - O bloco VAZIO era contado DUAS vezes na nota (uma como
#        recusado, outra como vazio). Spider-Man dizia 3 defeitos e tinha 2.
#        Agora a conta e por bloco DISTINTO.
#  1.25  27/08/2026 - Regra 6B: linha inteira em caixa alta sem nenhuma
#        palavra de portugues ("NF TOR" no Spider-Man, bloco 416). A regra 6
#        so olhava palavra de 4+ letras; NF tem 2 e TOR tem 3.
#  1.24  27/08/2026 - BUG QUE PERDIA FALA: o re-OCR podia gravar um bloco com
        LINHA EM BRANCO NO MEIO (visto no Se7en, bloco 1083). No formato .srt
        a linha vazia separa blocos - o leitor corta ali e a segunda fala
        some. Vinha do PSM 12, e a trava de aceite so olhava o conteudo,
        nunca o formato. Agora toda linha vazia e removida da leitura nova
        antes de ela virar troca. E o mesmo defeito que o Corretor conta como
        "FORMATO quebrado", so que criado DEPOIS que ele ja passou.
  1.24  27/08/2026 - O #PROG# saia uma vez por ALTURA, e dentro de cada
        altura rodam CINCO leituras do Tesseract: a barra la fora andava
        uma vez a cada 5 leituras. Num bloco RECUSADO (que roda as 60
        leituras inteiras antes de desistir) isso deu os 3 minutos de
        '87% travado' do Spider-Man de 27/08. Agora o passo e a LEITURA:
        60 avisos por bloco em vez de 12. Instante perdido soma 20
        passos (4 alturas x 5 modos); altura perdida soma 5.
  1.23  Trava de aceite e relatorio com [CONFERIDO] para o bloco que o
        re-OCR le igual ao que ja estava - o disco escreve assim mesmo.
 --------------------------------------------------------------------------
 v1.1.0 (alinhamento com o motor 14.5 / Corretor 2.3 - nenhuma mudanca na
        tecnica de re-OCR em si)
   * Faixa PGS: passou a aceitar tambem o idioma "pob". Muitos remuxes
     brasileiros marcam a faixa como pob em vez de por, e o filtro antigo
     ("^(por|pt)$") simplesmente nao via essas - caia direto no "nao
     detectei" e exigia -Track na mao. O Corretor_Legenda ja aceitava os
     dois; agora esta igual.
   * Faixa de COMENTARIO nunca mais e escolhida sozinha. O motor exclui
     comentario ha muito tempo (Test-EhFaixaComentario) porque existe filme
     com PGS "Brazilian" E "Brazilian (Commentary)" - se o comentario
     aparecesse primeiro, era ele que ia pro re-OCR. Aqui faltava.
   * Dicionario: agora entra tambem a forma SEM acento de cada palavra. A
     consulta sempre foi feita sem acento ("CORACAO" -> chave "coracao"),
     mas o dicionario so tem "coracao" com cedilha e til - entao palavra
     acentuada em CAIXA ALTA caia como "fora do dicionario" e virava
     suspeita a toa. Isso so DIMINUI a lista de suspeitos, nunca aumenta -
     ou seja, o script passa a mexer em menos blocos, nao em mais.
   * Encoding normalizado: o arquivo tinha 66 linhas com LF solto no meio
     (o bloco de comentario das versoes 1.0.2-1.0.7), contrariando o
     proprio cabecalho aqui embaixo. Agora e CRLF do inicio ao fim.
 --------------------------------------------------------------------------
 NAO mexe no motor, no Converter_AUTO_DIRETO.ps1 nem na instalacao. So LE o
 .mkv original e o .srt que o motor gerou, e escreve um .srt NOVO (nunca
 sobrescreve nada).

 O QUE FAZ:
 O PgsToSrt (o OCR do motor) nao expõe controle de PSM (page segmentation
 mode) do Tesseract - conferido direto no codigo-fonte oficial, so aceita
 --input/--output/--track/--tracklanguage/--tesseractlanguage/--tesseractdata/
 --tesseractversion/--libleptname/--libleptversion. O modo padrao (PSM 3,
 "automatico de pagina inteira") e ruim pra imagem de legenda de 1-2
 palavras - foi confirmado que ele produz LIXO em falas curtas que comecam
 com maiuscula acentuada isolada ("É", "Não").

 Este script re-processa SO os blocos que dao cara de suspeito no .srt que
 o motor ja gerou (letra sozinha, ou palavra toda maiuscula que nao existe
 no dicionario): extrai so a imagem daquele bloco especifico via ffmpeg
 (a legenda sozinha, sobre fundo preto - sem o video atras atrapalhando),
 e manda pro tesseract.exe de verdade com --psm 6 (bloco unico de texto),
 que da resultado muito melhor pra fala curta do que o PSM 3 automatico.

 TESSERACT: vem EMPACOTADO em tools\Tesseract\ (nao e o mesmo que o
 tessdata do PgsToSrt - o PgsToSrt so tem a biblioteca, nao o programa).
 A busca e: tools\Tesseract\ primeiro, PATH/Program Files so como ultimo
 recurso. O programa e portatil - nao depende de instalacao por fora.

 USO:
   Reocr_Legenda.bat "original.mkv" "gerado.srt"
   (ou rode sem nada que ele abre janela de selecao pros dois)

 SAIDA: <nome>_REOCR.srt (copia corrigida) + relatorio_reocr_<data>.txt
        (mostra ANTES/DEPOIS de cada bloco tocado, pra voce conferir)

 ENCODING DESTE ARQUIVO: UTF-8 COM BOM + CRLF (mesmo motivo do Auditor -
 PowerShell 5.1 le .ps1 sem BOM como ANSI e quebra os acentos das regex).
================================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Mkv = "",
    [Parameter(Position = 1)]
    [string]$Srt = "",
    [string]$Track = "",
    [string]$TesseractExe = "",
    [switch]$IgnorarTesseractDoSistema,
    <#  v1.21: quantas combinacoes precisam concordar para parar de ler.
        8 e o valor medido (ver o comentario grande no laco de leitura).
        -LimiteConsenso 60 desliga a parada e volta ao comportamento antigo,
        para comparar sem precisar editar o script. #>
    [int]$LimiteConsenso = 8,
    [switch]$SemPausa
)

$ErrorActionPreference = "Continue"
$Versao = "1.29"

$script:Relatorio = New-Object System.Collections.Generic.List[string]
function Diz {
    param([string]$Texto = "", [string]$Cor = "Gray")
    Write-Host $Texto -ForegroundColor $Cor
    $script:Relatorio.Add($Texto)
}
function Titulo {
    param([string]$Texto)
    Diz ""; Diz ("=" * 78) "DarkCyan"; Diz $Texto "Cyan"; Diz ("=" * 78) "DarkCyan"
}

<#  Test-TiraPreta - devolve $true quando a imagem nao tem NADA desenhado.

    v1.9: A VERSAO 1.8 DESTA FUNCAO DERRUBOU 3 BLOCOS BONS DO Se7en.
    Ela amostrava 400 pixels em grade (20x20) pra nao varrer os 3,3 milhoes
    de pixels da tira. O raciocinio era "legenda branca ocupa uma fatia
    grande da tira". Nao ocupa. Um "Nao." em 4K tem cerca de 300x90 pixels
    numa tira de 3840x864 - 0,8% da area. Na grade de 20x20 os pontos ficam
    a 183 px um do outro na horizontal: a palavra inteira e atravessada por
    1 ou 2 colunas de amostra, e os tracos das letras cobrem so uma parte
    disso. Ou seja: era cara ou coroa.
    E o resultado ficou registrado no relatorio do Se7en de 19/08:
        'DOMINGO'  (cartela longa, ocupa a tira toda) -> passou
        'Nao.' x3  (fala curta)                       -> "tira PRETA" x3
    As tres imagens salvas como falha tinham o "Nao." legivel a olho nu. A
    funcao nao viu porque nao olhou - so espiou 400 pontos.
    Pior: na 1.6, SEM esta funcao, esses mesmos 3 blocos eram lidos certo
    (4 de 4). A funcao que existia pra explicar falha passou a CAUSAR falha.

    AGORA ELA OLHA A IMAGEM INTEIRA. Reduzir pela metade, repetidamente, ate
    sobrar uns 240 px de largura: cada reducao pela metade e a media exata de
    4 pixels vizinhos, entao NENHUM pixel da imagem original fica de fora -
    um traco branco fino sempre puxa a media do seu quadradinho pra cima.
    Depois basta olhar a diferenca entre o pixel mais claro e o mais escuro
    da miniatura. Tira com legenda: claro ~255, escuro ~15 -> diferenca alta.
    Tira vazia: tudo no mesmo tom -> diferenca perto de zero. O criterio e
    RELATIVO, entao nao depende do "brightness=+0.06" do filtro nem de
    limiar magico.
    Custo medido: milissegundos. Roda no maximo 3 vezes por bloco suspeito.
    Se o System.Drawing nao carregar (ambiente sem GDI+), devolve $false: na
    duvida, segue o caminho normal e deixa o OCR decidir - nunca inventa uma
    falha que nao viu.
#>
$script:HouveTiraPreta = $false
$script:GdiOk = $null
function Test-TiraPreta {
    param([string]$Png)
    if ($null -eq $script:GdiOk) {
        $script:GdiOk = $false
        try { Add-Type -AssemblyName System.Drawing -ErrorAction Stop; $script:GdiOk = $true } catch { }
    }
    if (-not $script:GdiOk) { return $false }
    $atual = $null
    try {
        $atual = New-Object System.Drawing.Bitmap $Png
        if ($atual.Width -lt 8 -or $atual.Height -lt 8) { return $false }
        # Reducao pela metade, em passos - cada passo e media de 4 vizinhos.
        # O laco tem teto de 12 passos por seguranca (nunca chega perto).
        $passos = 0
        while ($atual.Width -gt 320 -and $passos -lt 12) {
            $nw = [int][math]::Max(1, [math]::Floor($atual.Width / 2))
            $nh = [int][math]::Max(1, [math]::Floor($atual.Height / 2))
            $menor = New-Object System.Drawing.Bitmap $nw, $nh
            $g = [System.Drawing.Graphics]::FromImage($menor)
            try {
                $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
                $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $g.DrawImage($atual, 0, 0, $nw, $nh)
            } finally { $g.Dispose() }
            $atual.Dispose()
            $atual = $menor
            $passos++
        }
        $claro  = 0
        $escuro = 255
        for ($y = 0; $y -lt $atual.Height; $y++) {
            for ($x = 0; $x -lt $atual.Width; $x++) {
                $c = $atual.GetPixel($x, $y)
                $l = [int]$c.R
                if ([int]$c.G -gt $l) { $l = [int]$c.G }
                if ([int]$c.B -gt $l) { $l = [int]$c.B }
                if ($l -gt $claro)  { $claro  = $l }
                if ($l -lt $escuro) { $escuro = $l }
            }
        }
        # 25 de 255 e folga larga: uma tira de verdade vazia da diferenca de
        # 0 a 3. Na duvida o retorno e $false, que so custa uma tentativa de
        # OCR a mais - nunca joga fora um bloco que tinha legenda.
        return (($claro - $escuro) -lt 25)
    } catch {
        return $false
    } finally {
        if ($atual) { try { $atual.Dispose() } catch { } }
    }
}

function Get-PastaScript {
    if ($PSScriptRoot -and $PSScriptRoot.Trim() -ne "") { return $PSScriptRoot }
    return (Get-Location).Path
}

function Get-SemAcento {
    param([string]$P)
    $s = $P.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($c in $s.ToCharArray()) {
        if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($c) }
    }
    return $sb.ToString()
}

function Get-DicionarioPtBr {
    <#  v1.11: O DICIONARIO DE 1,3 MILHAO NUNCA ERA ABERTO POR NOME.
        Esta funcao procurava SO por "Auditor_OCR.dic.gz". O arquivo grande,
        "LaFirma_PTBR_1.3M.dic.gz", nao aparecia em nenhuma linha de nenhum
        dos dois scripts - e o instalador 1.4 tem uma TRAVA DE COMPILACAO
        exigindo esse arquivo, com o comentario dizendo que "e o que o
        Corretor 2.9+ e o Reocr 1.2+ usam".
        Aqui funcionou ate hoje por acidente: o Auditor_OCR.dic.gz da maquina
        do Diego tinha sido substituido a mao pelo arquivo grande (3.145 KB
        no lugar de 195 KB). Por isso os relatorios dizem "1296508 palavras".
        No dia em que o setup instalasse os DOIS arquivos com os nomes certos,
        os scripts voltariam a ler o de 50 mil - e junto voltaria a familia de
        falso positivo que a 2.9 fechou, sem nenhum aviso na tela.
        Duas coisas mudaram:
          1. o arquivo grande e procurado PRIMEIRO, pelo nome dele;
          2. a funcao devolve TAMBEM qual arquivo abriu, e o relatorio passa a
             imprimir o nome junto da contagem. Numero sem origem foi o que
             deixou isso passar despercebido por tantas versoes. #>
    param([string]$Raiz)
    $caminho = $null
    $candidatos = @(
        (Join-Path $Raiz "LaFirma_PTBR_1.3M.dic.gz"),
        "C:\LaFirma\LaFirma_PTBR_1.3M.dic.gz",
        (Join-Path $Raiz "Auditor_OCR.dic.gz"),
        "C:\LaFirma\Auditor_OCR.dic.gz"
    )
    foreach ($c in $candidatos) {
        if (Test-Path -LiteralPath $c) { $caminho = $c; break }
    }
    if (-not $caminho) { $script:DicionarioArquivo = ""; return $null }
    $script:DicionarioArquivo = [System.IO.Path]::GetFileName($caminho)
    try {
        $bytesGz = [System.IO.File]::ReadAllBytes($caminho)
        $msIn = New-Object System.IO.MemoryStream(,$bytesGz)
        $gz = New-Object System.IO.Compression.GZipStream($msIn, [System.IO.Compression.CompressionMode]::Decompress)
        $msOut = New-Object System.IO.MemoryStream
        $gz.CopyTo($msOut); $gz.Dispose()
        $texto = [System.Text.Encoding]::UTF8.GetString($msOut.ToArray())
        $set = New-Object 'System.Collections.Generic.HashSet[string]'
        # v1.2.0: guarda SO a palavra como veio.
        #
        # A 1.1.0 guardava tambem a forma sem acento de cada palavra, pra
        # resolver a consulta que era feita so sem acento. Funcionava com o
        # dicionario de 50 mil. Com o de 1.296.517 isso vira 2,6 MILHOES de
        # entradas na memoria - o dobro do necessario, e num script que ja
        # roda ffmpeg e tesseract em paralelo.
        # Agora quem se vira e a consulta: Test-NoDicionario pergunta as duas
        # formas (com e sem acento), igual ao Corretor_Legenda 2.6+. Mesmo
        # resultado, metade da memoria.
        foreach ($linha in ($texto -split "`n")) {
            $p = $linha.Trim()
            if ($p -ne "") { [void]$set.Add($p) }
        }
        return $set
    } catch { return $null }
}

function Ler-TextoComEncoding {
    param([string]$Caminho)
    $bytes = [System.IO.File]::ReadAllBytes($Caminho)
    $utf8Estrito = New-Object System.Text.UTF8Encoding($false, $true)
    try { $texto = $utf8Estrito.GetString($bytes) }
    catch { $texto = [System.Text.Encoding]::GetEncoding(1252).GetString($bytes) }
    if ($texto.Length -gt 0 -and [int]$texto[0] -eq 0xFEFF) { $texto = $texto.Substring(1) }
    return $texto
}

function Converter-TempoParaMs {
    param([string]$T)
    $m = [regex]::Match($T, '^\s*(\d+):(\d{2}):(\d{2})[,\.](\d{1,3})\s*$')
    if (-not $m.Success) { return -1 }
    $h = [int]$m.Groups[1].Value; $mi = [int]$m.Groups[2].Value; $s = [int]$m.Groups[3].Value
    $ms = [int]($m.Groups[4].Value.PadRight(3, '0'))
    return (((($h * 60) + $mi) * 60 + $s) * 1000 + $ms)
}

function Ms-ParaTempo {
    param([int]$Ms)
    $t = [TimeSpan]::FromMilliseconds([math]::Max(0, $Ms))
    return ("{0:00}:{1:00}:{2:00},{3:000}" -f [int]$t.TotalHours, $t.Minutes, $t.Seconds, $t.Milliseconds)
}

function Parse-Srt {
    param([string]$Texto)
    $t = $Texto -replace "`r`n", "`n" -replace "`r", "`n"
    $linhas = $t -split "`n"
    $blocos = New-Object System.Collections.Generic.List[object]
    $i = 0; $n = $linhas.Count
    while ($i -lt $n) {
        while ($i -lt $n -and $linhas[$i].Trim() -eq "") { $i++ }
        if ($i -ge $n) { break }
        $indice = $null
        if ($linhas[$i] -notmatch '-->') {
            $cand = $linhas[$i].Trim()
            if ($cand -match '^\d+$') { $indice = [int]$cand }
            $i++
        }
        if ($i -ge $n) { break }
        $ini = ""; $fim = ""; $timingOk = $false
        $mt = [regex]::Match($linhas[$i], '(\d+:\d{2}:\d{2}[,\.]\d{1,3})\s*-->\s*(\d+:\d{2}:\d{2}[,\.]\d{1,3})')
        if ($mt.Success) { $ini = $mt.Groups[1].Value; $fim = $mt.Groups[2].Value; $timingOk = $true; $i++ } else { $i++ }
        $corpo = New-Object System.Collections.Generic.List[string]
        while ($i -lt $n -and $linhas[$i].Trim() -ne "") { $corpo.Add($linhas[$i]); $i++ }
        $blocos.Add((New-Object PSObject -Property ([ordered]@{
            Indice = $indice; Inicio = $ini; Fim = $fim
            IniMs = (Converter-TempoParaMs $ini); FimMs = (Converter-TempoParaMs $fim)
            Texto = ($corpo -join "`n"); TimingOk = $timingOk
        })))
    }
    return $blocos
}

# v1.2.0: consulta igual a do Corretor_Legenda 2.6+ - pergunta a forma COM
# acento e a SEM acento. Sem isso, "CORACAO" (que no dicionario so existe
# como "coracao" com cedilha e til) caia como fora do dicionario e o bloco
# virava suspeito a toa.
<#  v1.12 - PREFIXO PRODUTIVO.
    O dicionario de 1,3 milhao tem buraco em palavra prefixada. Medido nos
    .srt reais do projeto: "excomandante", "reconsiderei", "supercolisor",
    "superpessoas", "multiversais", "superestimei", "autoterapia",
    "reconsidero" - todas portugues legitimo, todas ausentes.
    Isso NAO e detalhe: a trava de ACEITE do re-OCR conta "% das palavras
    que existem em portugues", entao uma leitura CORRETA era recusada por
    falta no dicionario.
    Caso real: SANITIZANTE (Spider-Man, 19/08) recusado com o motivo "so 0
    de 1 palavras existem em portugues". O re-OCR tinha lido CERTO. Deu
    certo por sorte - o bloco original ja estava bom. Se estivesse errado,
    a trava teria bloqueado a correcao certa.
    Lista FECHADA e conservadora: so prefixos que formam palavra nova sem
    alterar a base. Exige base de 4+ letras.
    RISCO MEDIDO: 14 lixos tipicos de OCR ("renetor", "exnetor", "retol",
    "subtol", "automn", "supertejlorl") - todos rejeitados.
    NAO FOI INCLUIDO corte cego de terminacao verbal: testado, ele aceita
    lixo junto (diz que "transporao" vem de "transar"). Melhor deixar de
    fora do que abrir porta torta. #>
$script:PrefixosProdutivos = @('sobre','contra','inter','intra','micro','macro',
    'ultra','infra','extra','pluri','super','multi','auto','semi','anti','mono',
    'pos','pre','sub','tri','ex','re','bi')

function Test-PrefixoProdutivo {
    param([string]$P, $Dicionario)
    if (-not $Dicionario) { return $false }
    if ([string]::IsNullOrEmpty($P)) { return $false }
    $pl = $P.ToLowerInvariant()
    foreach ($pre in $script:PrefixosProdutivos) {
        if (($pl.Length - $pre.Length) -lt 4) { continue }
        if (-not $pl.StartsWith($pre)) { continue }
        $base = $pl.Substring($pre.Length)
        if ($Dicionario.Contains($base) -or
            $Dicionario.Contains((Get-SemAcento $base).ToLowerInvariant())) { return $true }
    }
    return $false
}

function Test-NoDicionario {
    param([string]$P, $Dicionario)
    if (-not $Dicionario) { return $false }
    $comAcento = $P.ToLowerInvariant()
    if ($Dicionario.Contains($comAcento)) { return $true }
    if ($Dicionario.Contains((Get-SemAcento $P).ToLowerInvariant())) { return $true }

    <#  v1.8: PALAVRA COM HIFEN. Mesma correcao do Corretor 2.14, e aqui ela
        pesa MAIS: a trava de aceite deste script conta "% das palavras que
        existem em portugues", e ela olha a palavra INTEIRA. Com o dicionario
        cego pra hifen, uma leitura CORRETA de "mata-lo", "deixe-me" ou
        "bem-vindo" contava como palavra inexistente e podia derrubar a
        troca boa.
        MEDIDO: o dicionario de 1.296.517 palavras nao tem UMA palavra com
        hifen. Das 218 hifenizadas distintas nos .srt reais do projeto, a
        regra "todas as partes conhecidas" reconhece 216 (99%) - e as duas
        que sobram sao os dois erros de OCR de verdade ("mexar-se" e
        "homem-aranh").
    #>
    if ($P.Contains("-")) {
        <#  v1.11: FALTAVA A SEGUNDA GUARDA - E SEM ELA "INF-TOL" PASSAVA.
            A regra aceitava a palavra hifenizada quando TODAS as partes
            existiam no dicionario. So que `inf`, `tol`, `net`, `tor` e `neto`
            existem no dicionario de 1,3 milhao (ele tem sigla e termo solto),
            entao "INF-TOL" e "NET-TOR" - que sao o lixo de OCR que a
            ferramenta inteira existe para pegar - seriam declarados palavra
            portuguesa legitima.
            O prototipo que validei tinha a guarda e ela nao chegou no
            PowerShell: palavra hifenizada de verdade em portugues ou termina
            em pronome atono (mata-lo, diz-se, vamo-nos) ou tem pelo menos um
            pedaco com 4+ letras (guarda-chuva, segunda-feira, bem-vindo).
            Duas siglas de tres letras coladas por hifen nao e nenhum dos dois. #>
        $partes = @($P.Split("-") | Where-Object { $_ -ne "" })
        if ($partes.Count -ge 2) {
            $ultima = (Get-SemAcento $partes[$partes.Count - 1]).ToLowerInvariant()
            $atonos = @("lo","la","los","las","no","na","nos","nas","me","te","se","lhe","lhes","o","a","os","as")
            $temPedacoLongo = $false
            foreach ($ped in $partes) { if ($ped.Length -ge 4) { $temPedacoLongo = $true } }
            if (-not ($temPedacoLongo -or ($atonos -contains $ultima))) { return $false }
            $todas = $true
            foreach ($ped in $partes) {
                $pa = $ped.ToLowerInvariant()
                $pk = (Get-SemAcento $ped).ToLowerInvariant()
                if (-not ($Dicionario.Contains($pa) -or $Dicionario.Contains($pk))) { $todas = $false; break }
            }
            if ($todas) { return $true }
        }
    }
    # v1.12: ultimo recurso - palavra formada por PREFIXO PRODUTIVO + palavra
    # conhecida ("super"+"colisor", "ex"+"comandante"). Ver o bloco grande
    # acima de Test-PrefixoProdutivo.
    if (Test-PrefixoProdutivo $P $Dicionario) { return $true }
    return $false
}

# Marcas que SE ESCREVEM com maiuscula no meio - a mesma lista do
# Corretor_Legenda 2.11. Sem ela, "BuzzFeed" entra na fila de re-OCR.
$script:MarcasCamel = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($m in @(
    "buzzfeed","youtube","youtuber","youtubers","facebook","whatsapp","tiktok",
    "linkedin","snapchat","paypal","ebay","airbnb","deviantart","soundcloud",
    "iphone","iphones","ipad","ipads","ipod","imac","macbook","airpods",
    "ios","macos","ipados","watchos","airtag","facetime","imessage",
    "playstation","gamecube","geforce","thinkpad","gopro","dvd-rw",
    "powerpoint","onedrive","onenote","sharepoint","wordpress","javascript",
    "typescript","github","gitlab","bitbucket","mysql","postgresql","mongodb",
    "openai","chatgpt","deepmind","mastercard","teamviewer","adblock",
    "mcdonald","mcdonalds","fedex","jetblue","easyjet","hispantv",
    "starwars","spiderman","ironman","medlab","biotech"
)) { [void]$script:MarcasCamel.Add($m) }

# v1.2.0: nome proprio nao e bloco suspeito.
# Mesma logica do Corretor_Legenda: comeca com maiuscula, sem maiuscula no
# meio, aparece 2+ vezes no arquivo e nao esta no dicionario. Erro de OCR e
# aleatorio; nome proprio se repete. Sem isso, num filme como o Troia
# ("Aquiles", "Briseida", "Priamo" em quase toda fala) o re-OCR ia mexer em
# fala PERFEITA.

<#
      --- LISTA DE PALAVRAS CURTAS COMUNS (v1.6) ---

      Para que serve: a Regra 3B derruba bloco EM CAIXA ALTA com 2+ palavras
      todas de ate 3 letras ("INF TOL", que no Troia aparece 6 vezes e sempre
      era "Nao."). Ela nao consulta o dicionario de propósito - foi o
      dicionario de 1,3M que abriu o buraco, porque "inf" e "tol" existem la.

      O problema logico: um letreiro legitimo pode ser EXATAMENTE assim.
      "SIM OU NAO", "EU VOU LA", "QUE FIM TEM" - todas as palavras com 3
      letras ou menos, todas em caixa alta. Nos 3 filmes testados isso nao
      aconteceu, mas nao acontecer em 3 filmes nao e o mesmo que nao poder
      acontecer. Num quarto filme acontece.

      A saida: uma palavra CURTA de verdade do portugues nunca aparece
      sozinha em lixo de OCR. Se o bloco tem pelo menos uma palavra desta
      lista, ele e fala de verdade. A lista sao as 469 palavras de ate 3
      letras mais frequentes do portugues (wordfreq PT, top 10 mil, sem as
      siglas e o ingles). "inf", "tol" e "tor" NAO estao aqui - e por isso
      que o "INF TOL" continua sendo pego.
#>
$script:CurtasComuns = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($w in @(
    "de","que","do","em","da","é","não","um","uma","com","no","se",
    "na","por","os","eu","as","dos","mas","foi","ao","me","ser","seu",
    "sua","tem","são","das","ou","à","ele","já","nos","meu","ela","vai",
    "só","dia","bem","até","te","ter","sem","era","nas","vou","há","ver",
    "bom","ano","vez","aos","sou","mim","sei","tão","nem","faz","às","nós",
    "pra","lá","sim","diz","dar","ir","la","boa","mãe","rio","fez","aí",
    "for","fim","num","têm","pai","tu","vem","vão","mil","dá","sul","lei",
    "lo","mal","sob","lhe","ex","vi","uso","deu","fui","tal","los","rua",
    "mês","mão","paz","fiz","si","uns","viu","vê","via","teu","ali","ia",
    "luz","voz","ar","oi","ah","irá","ler","tua","amo","sol","dez","ti",
    "rei","vir","etc","mar","las","tá","pé","dor","sai","al","ok","cor",
    "ai","usa","fé","som","el","ana","céu","nao","pro","olá","one","pré",
    "tom","cá","ato","pós","web","daí","dê","ii","pt","ama","vim","vá",
    "gay","der","dei","li","lua","dão","fãs","oh","quê","del","gol","gás",
    "pés","né","sr","á","dou","nº","dom","en","mau","pão","san","co",
    "le","vos","par","vc","és","bar","vêm","use","tio","ben","tia","má",
    "ora","pau","ei","es","et","am","chá","ha","iii","an","cai","eis",
    "mel","ja","pr","fã","lê","º","voo","cão","lar","sal","zé","cem",
    "pôr","rir","avó","tim","ma","ep","ido","les","or","pe","gil","más",
    "di","põe","pró","pó","un","boy","fio","avô","dj","iv","dói","ta",
    "ó","aço","ba","net","tô","rap","fi","mac","ovo","ás","pan","rui",
    "leu","cu","eh","iam","alô","sao","ate","eva","got","ida","irã","pq",
    "ira","sbt","sc","sir","hd","pá","saí","jay","sa","une","ian","nu",
    "xix","ave","ms","per","amy","av","cc","fox","two","hip","how","usá",
    "vós","ya","ip","mia","ala","dc","fm","hey","una","boi","hop","hot",
    "men","sá","au","box","ios","jon","mor","pl","yo","mc","mtv","ne",
    "wi","ad","air","end","mp","sra","su","cv","doc","dra","let","non",
    "qu","xvi","xxi","ac","df","dum","ego","est","jo","cbf","cds","iso",
    "ps","sky","tb","vaz","asa","dai","eco","guy","but","cap","dem","he",
    "pf","ª","tse","uol","bi","car","jan","law","psd","ri","sus","was",
    "abu","pôs","sun","ted","xi","bo","cat","hiv","nua","roy","rss","sex",
    "sic","vip","ap","gps","hum","lu","nó","our","pia","foz","han","jin",
    "rey","vôo","blá","cpi","his","ig","mec","ni","ong","say","soa","tê",
    "vcs","bio","dog","neo","see","von","bh","fbi","ho","ss","toa","bay",
    "clã","grã","ola","pec","run","sin","sos","tel","ata","bin","pô","son",
    "sé","vii","ann","ceo","god","ken","ny","pas","she","too","uau","pi",
    "qui","rob","réu","sri","uva","org","rt","sur","voa","hp","mai","pb",
    "po","ago","id","low","mae","obs","rn","ron","ame","crê","gp","léo",
    "xv","è","cup","her","lia","lou","ro","ré","sea","tao","ufc","act",
    "dó"
)) {
    [void]$script:CurtasComuns.Add($w)
    [void]$script:CurtasComuns.Add((Get-SemAcento $w).ToLowerInvariant())
}

function Test-CurtaComum {
    param([string]$P)
    if ([string]::IsNullOrEmpty($P)) { return $false }
    $b = $P.ToLowerInvariant()
    if ($script:CurtasComuns.Contains($b)) { return $true }
    return $script:CurtasComuns.Contains((Get-SemAcento $b).ToLowerInvariant())
}

<#
      --- NOME PROPRIO EM CamelCase (v1.6) ---

      A Regra 2 (maiuscula no meio da palavra) e a mais forte que existe
      aqui, mas ela tem um custo: "McGregor", "MacArthur", "DeLorean",
      "LaFirma" se escrevem assim. A lista MarcasCamel cobre as marcas que
      eu conheco - e uma lista fechada, entao ela nunca vai cobrir o nome
      proprio do proximo filme.

      Esta funcao fecha o buraco sem lista nenhuma, com tres exigencias ao
      mesmo tempo:
        1. FORMA LIMPA "Xxx Xxx" grudado - maiuscula, minusculas, maiuscula,
           minusculas ate o fim. "McGregor" passa. O garbling de verdade
           nao tem essa forma: "ToRSTOUR" tem duas maiusculas seguidas,
           "MOrTrer" comeca com duas, "NEToL" termina em maiuscula.
        2. APARECE 2+ VEZES no arquivo. Erro de OCR e aleatorio; nome se
           repete. (E o mesmo raciocinio do Get-NomesProprios.)
        3. A forma minuscula NAO EXISTE no dicionario. Isto e o que separa
           "McGregor" (mcgregor nao existe = nome) de "PaLavra" e "AiNda"
           (palavra e ainda existem = garbling de palavra real). Foi
           justamente aqui que a minha primeira tentativa de regra de forma
           falhou, la na 2.10: sem esta terceira exigencia ela protegia
           "PaLavra".
#>
function Get-NomesCamel {
    param([string]$TextoInteiro, $Dicionario)
    $s = New-Object 'System.Collections.Generic.HashSet[string]'
    # v1.11: @{} do PowerShell ignora maiuscula/minuscula - "Ir" e "ir"
    # contavam como a mesma palavra, e a guarda "aparece 2+ vezes" podia ser
    # satisfeita por ocorrencias em caixas diferentes. Aqui a caixa E o dado.
    $cont = New-Object 'System.Collections.Generic.Dictionary[string,int]' 
    foreach ($m in [regex]::Matches($TextoInteiro, '[\p{L}]{4,}')) {
        $v = $m.Value
        if ($v -cnotmatch '^[\p{Lu}][\p{Ll}]+[\p{Lu}][\p{Ll}]+$') { continue }
        if ($cont.ContainsKey($v)) { $cont[$v] = $cont[$v] + 1 } else { $cont[$v] = 1 }
    }
    foreach ($k in $cont.Keys) {
        if ($cont[$k] -lt 2) { continue }
        if (Test-NoDicionario $k $Dicionario) { continue }
        [void]$s.Add($k)
    }
    # A VIRGULA NAO E ENFEITE: sem ela, HashSet VAZIO sai como $null (o
    # PowerShell desembrulha colecao de 1 ou 0 itens). Arquivo sem nome
    # CamelCase nenhum - que e a maioria - devolvia $null e a Regra 2
    # estourava "You cannot call a method on a null-valued expression".
    # Peguei isso no teste, nao na maquina do Diego.
    return ,$s
}
$script:NomesCamel = New-Object 'System.Collections.Generic.HashSet[string]'

function Get-NomesProprios {
    param([string]$TextoInteiro, $Dicionario)
    $nomes = New-Object 'System.Collections.Generic.HashSet[string]'
    # v1.11: @{} do PowerShell ignora maiuscula/minuscula - "Ir" e "ir"
    # contavam como a mesma palavra, e a guarda "aparece 2+ vezes" podia ser
    # satisfeita por ocorrencias em caixas diferentes. Aqui a caixa E o dado.
    $cont = New-Object 'System.Collections.Generic.Dictionary[string,int]' 
    foreach ($m in [regex]::Matches($TextoInteiro, '[\p{L}]{2,}')) {
        $v = $m.Value
        if ($cont.ContainsKey($v)) { $cont[$v] = $cont[$v] + 1 } else { $cont[$v] = 1 }
    }
    foreach ($k in $cont.Keys) {
        if ($cont[$k] -lt 2) { continue }
        if ($k -cnotmatch '^[\p{Lu}]') { continue }
        if ($k -cnotmatch '[\p{Ll}]') { continue }
        if ($k -cmatch '[\p{Ll}][\p{Lu}]') { continue }
        if (Test-NoDicionario $k $Dicionario) { continue }
        [void]$nomes.Add($k)
    }
    return ,$nomes
}

<#
      v1.2.0 - O DETECTOR ANTIGO DEIXAVA PASSAR METADE DOS CASOS REAIS.

      A regra da 1.1.0 exigia TOKEN UNICO de 4+ letras, tudo maiusculo. Ela
      pegava "INFETOR" e "INETORENETO", mas nao pegava os outros dois casos
      medidos no Homem-Aranha e no Troia:
          "INFETORE NE ToRSTOUR"  (tem espaco)   -> era "Nao. Nao sou."
          "INF TOL"               (tokens curtos) -> era "Nao."
      Ou seja: dos 6 blocos destruidos nos 3 filmes, o re-OCR so era
      oferecido pra 4. Justo os que precisavam ficavam de fora.

      Agora este detector e o mesmo Test-BlocoAlienigena do Corretor 2.11,
      que ja provou pegar os 6 - com a rede de nome proprio junto, que e o
      que impede ele de virar uma maquina de estragar legenda boa.
#>
<#
      v1.3.0 - A TRAVA DE ACEITE. O BURACO MAIS GRAVE QUE ESTA FERRAMENTA TEVE.

      Teste real do Troia, 13/08 16:37. Oito blocos foram pro re-OCR e o
      relatorio anunciou "Trocas com resultado aproveitavel : 8". A verdade:
      o Tesseract leu a CENA DO FILME, nao a legenda, e o bloco

          'INF TOL'      (lixo, mas 7 caracteres)

      virou

          'P k q : DD 4 dE CA / , o no co DR e A e CE, sa / a Fra E uia e p ,
           + " 7 o efa ndo , REM o / E A LA VE O O: td AR / ...'   (700+ chars)

      E o arquivo _REOCR.srt foi GRAVADO assim. Ou seja: a ferramenta trocou
      lixo por lixo MUITO pior e escreveu no relatorio que tinha dado certo.

      Por que passou: o unico criterio de aceite era
          if ($novoTexto -eq "" -or $novoTexto -notmatch '\p{L}') { pula }
      "nao esta vazio e tem pelo menos uma letra". Um muro de ruido de cena
      passa nisso com folga.

      Esta e a mesma familia dos outros quatro casos de "mensagem que mente"
      que ja fechamos no motor e no Corretor - e desta vez o defeito era meu,
      numa ferramenta que eu mandei rodar. Agora o resultado do re-OCR tem
      que PROVAR que serve, com as mesmas travas que se exigiria de qualquer
      legenda:
        1) TAMANHO: bloco de legenda tem no maximo 3 linhas e ~200 caracteres.
        2) PICOTADO: ruido de cena vira enxame de letra solta ("P k q : DD").
           Se mais de 40% dos tokens tem 1 caractere so, e ruido.
        3) DICIONARIO: pelo menos metade das palavras de 2+ letras tem que
           existir em portugues (ou ser nome proprio do proprio filme).
        4) O JUIZ: o texto novo nao pode ser reprovado pelo MESMO
           Test-BlocoSuspeito que escolheu o bloco. Se continua com cara de
           lixo, nao houve conserto nenhum.
      Reprovou, o bloco fica como estava. Melhor ficar com o defeito que a
      gente ja conhece do que trocar por um pior fingindo que melhorou.
#>
<#  v1.9: LISTA FECHADA DE FALAS DE UMA LETRA SO.
    Escrita a mao, curta e imutavel - de proposito. Perguntar ao dicionario
    de 1,3M se uma letra "existe" nao prova nada (foi assim que o "net"
    passou por palavra e o "INF TOL" quase passou por fala). Estas sao as
    unicas palavras de uma letra que aparecem sozinhas numa legenda em
    portugues, e a lista nao cresce sem medida nova.
    Serve SO para bloco que veio VAZIO, onde qualquer leitura plausivel e
    ganho puro - nao ha texto bom a perder. #>
$script:FalasDeUmaLetra = @('E', "$([char]0xC9)", 'A', "$([char]0xC0)", 'O', "$([char]0xD3)")

function Test-FalaCurtaValida {
    param([string]$Texto)
    $t = "$Texto".Trim()
    if ($t -eq "" -or $t.Length -gt 6) { return $false }
    if ($t.Contains("`n")) { return $false }
    # uma letra, seguida no maximo de pontuacao final
    if ($t -notmatch '^[\p{L}][\.\,\!\?\:\;\-]{0,3}$') { return $false }
    return ($script:FalasDeUmaLetra -contains $t.Substring(0,1).ToUpperInvariant())
}


<#  Concordancia de numero. "1 bloco(s)" e desleixo que aparece na tela do
    usuario; texto de tela e contrato, vale para o singular tambem. #>
function Plural {
    param([int]$N, [string]$Um, [string]$Muitos)
    if ($N -eq 1) { return $Um }
    return $Muitos
}

<#  =========================================================================
    NOTA DA LEGENDA  (v1.18)
    -------------------------------------------------------------------------
    POR QUE ISTO EXISTE
    A conversao de PGS para .SRT nunca vai ser perfeita: o texto no disco e
    uma IMAGEM, e ler imagem e adivinhacao. Ate aqui o usuario so descobria a
    qualidade assistindo ao filme e tropecando num "INFETOR" no meio de uma
    cena. Esta secao diz, no fim da conversao, o que ele pode esperar - e
    quando vale a pena usar a faixa PGS original, que desde o motor 14.23
    fica no arquivo ao lado da .SRT justamente para isso.

    POR QUE NAO E UMA PORCENTAGEM SOZINHA
    "97% de acerto" nao ajuda ninguem a decidir nada, e pior: esconde. Um
    unico bloco podre no clima da cena final incomoda mais que vinte acentos
    trocados. Por isso a nota tem VEREDICTO (uma palavra), CONTAGEM (quantos
    e onde) e MOTIVO (o que exatamente sobrou), nessa ordem.

    DE ONDE SAEM OS NUMEROS - todos ja existiam, nenhum e estimado:
      . blocos do arquivo ......... contados no .srt
      . suspeitos ................. a trava do Reocr ja marcou
      . recusados ................. suspeitos que o re-OCR nao resolveu
      . vazios .................... blocos sem texto nenhum
      . fora do dicionario ........ varredura contra o dicionario de 1,3M,
                                    DESCONTANDO as familias que sao falha do
                                    dicionario e nao da leitura (enclise com
                                    hifen, conjugacao nao expandida), que ja
                                    estao documentadas como falso positivo.
    Nada aqui roda OCR de novo nem abre o .mkv: e leitura do que ja foi feito,
    custo proximo de zero.

    A ESCALA
    Os cortes saem das seis auditorias ja fechadas (7.695 blocos, 6 filmes):
    uma legenda saudavel deste pipeline fica em torno de 0,2% de defeito
    residual, e 1% ja e uma rodada em que o seconv foi recusado e o Tesseract
    penou. Por isso:
        ATE 0,1% ....... EXCELENTE  (praticamente sem defeito residual)
        0,1% a 0,5% .... BOA        (o normal quando tudo funciona)
        0,5% a 1,5% .... RAZOAVEL   (da pra assistir, alguns tropecos)
        ACIMA DE 1,5% .. RUIM       (vale usar a PGS original)
    ========================================================================= #>
function Write-NotaDaLegenda {
    param($Blocos, $Suspeitos, $Trocas, $Dicionario)

    <#  [object[]] e nao @( ).  @($umList) sobre um
        System.Collections.Generic.List[object] estoura "Os tipos de argumento
        nao correspondem" - foi o ERRO FATAL que derrubou esta funcao na
        rodada de 26/08 01h43, na linha "$resolvidos = @($Trocas).Count",
        DEPOIS de o re-OCR ja ter feito todo o trabalho certo (15 de 19).
        O mesmo defeito ja tinha aparecido no Corretor 2.19; aqui passou
        porque a funcao so roda no fim de tudo.
        Convertido UMA vez, no topo, em vez de espalhar @( ) pelo corpo. #>
    $listaBlocos    = [object[]]$Blocos
    $listaSuspeitos = [object[]]$Suspeitos
    $listaTrocas    = [object[]]$Trocas
    if ($null -eq $listaBlocos)    { $listaBlocos    = @() }
    if ($null -eq $listaSuspeitos) { $listaSuspeitos = @() }
    if ($null -eq $listaTrocas)    { $listaTrocas    = @() }

    $totalBlocos = $listaBlocos.Count
    if ($totalBlocos -le 0) { return }

    <#  Recusados = o que a trava marcou e o re-OCR nao conseguiu melhorar.
        Estes sao os que continuam no arquivo do jeito que estavam. #>
    $resolvidos = $listaTrocas.Count
    $recusados  = $listaSuspeitos.Count - $resolvidos
    if ($recusados -lt 0) { $recusados = 0 }

    <#  v1.23: os CONFERIDOS saem da conta de defeito.
        Bloco conferido e aquele em que 3 ou mais leituras independentes
        chegaram ao mesmo texto que ja estava no arquivo: o OCR nao falhou,
        ele confirmou, e o texto estranho vem do proprio disco.
        Contar isso como defeito era o mesmo tipo de erro que a gente vem
        caçando - numero que nao corresponde ao que aconteceu. No Spider-Man
        eram 2 dos 5 "defeitos", e empurravam o filme de EXCELENTE para BOA
        por causa de duas leituras CERTAS. #>
    $conferidos = 0
    if ($null -ne $script:BlocosConfirmados) { $conferidos = @($script:BlocosConfirmados).Count }
    if ($conferidos -gt $recusados) { $conferidos = $recusados }
    $recusados = $recusados - $conferidos

    <#  Blocos que continuaram VAZIOS depois de tudo. Fala perdida e o pior
        defeito possivel - pior que ler errado, porque nem da para adivinhar
        pelo contexto. Por isso conta separado. #>
    <#  Guarda o TEXTO NOVO, nao $true. Com $true, a linha mais abaixo
        ($txt = $chavesTrocadas[$chave]) punha o booleano no lugar da fala e a
        contagem passava a analisar a palavra "True". #>
    $chavesTrocadas = @{}
    foreach ($tr in $listaTrocas) {
        $novoTexto = $tr.Novo
        if ($null -eq $novoTexto) { $novoTexto = "" }
        $chavesTrocadas[$tr.Bloco.Inicio + "|" + $tr.Bloco.Fim] = [string]$novoTexto
    }
    $vazios = 0
    foreach ($b in $listaBlocos) {
        if ([string]::IsNullOrWhiteSpace($b.Texto) -and -not $chavesTrocadas.ContainsKey($b.Inicio + "|" + $b.Fim)) { $vazios++ }
    }

    <#  v1.26 - O BLOCO VAZIO ESTAVA SENDO CONTADO DUAS VEZES.
        Achado pelo Diego nos dois testes do Spider-Man de 27/08: os dois
        diziam "3 blocos com defeito (0,16%)" e o arquivo tinha DOIS.
        O bloco vazio 00:11:15 e suspeito (todo vazio e), foi recusado pelo
        re-OCR, e por isso entrava em $recusados. Depois entrava DE NOVO em
        $vazios, que varre o arquivo procurando bloco sem texto. A soma
        $recusados + $vazios contava ele nas duas pontas.
        O numero da nota tem que ser BLOCO DISTINTO, nao evento. Aqui os
        recusados que TAMBEM estao vazios saem da conta de "ilegivel" e
        ficam so na de "vazio" - que e a categoria mais grave e a mais
        honesta para descrever o que aconteceu (a fala sumiu).
        Efeito no Spider-Man: 3 -> 2 defeitos, 0,16% -> 0,11%. O veredicto
        continua BOA (a faixa de EXCELENTE termina em 0,10%), mas o numero
        agora corresponde ao arquivo. Numero que nao bate com o arquivo e a
        mesma familia de "mensagem que mente" que a gente vem caçando. #>
    $recusadosVazios = 0
    foreach ($s in $listaSuspeitos) {
        $chave = $s.Inicio + "|" + $s.Fim
        if ($chavesTrocadas.ContainsKey($chave)) { continue }
        if ($null -ne $script:BlocosConfirmados -and $script:BlocosConfirmados.Contains($chave)) { continue }
        if ([string]::IsNullOrWhiteSpace($s.Texto)) { $recusadosVazios++ }
    }
    $recusados = $recusados - $recusadosVazios
    if ($recusados -lt 0) { $recusados = 0 }

    <#  Palavras que o dicionario de 1,3M nao conhece, tirando as familias que
        JA foram medidas como falha do dicionario e nao da leitura:
          - token com hifen: enclise e mesoclise ("mata-lo", "detem-no") e
            palavra composta ("Homem-Aranha") - ~100 casos por filme, todos
            portugues legitimo;
          - token com digito: "US$ 100", "4a", "1080p";
          - token de 1 letra: pontuacao solta e travessao.
        Sem esse desconto o numero vira alarme falso, que e pior que nao ter
        numero nenhum. #>
    $foraDic = 0
    if ($null -ne $Dicionario -and $Dicionario.Count -gt 0) {
        foreach ($b in $listaBlocos) {
            $txt = $b.Texto
            $chave = $b.Inicio + "|" + $b.Fim
            if ($chavesTrocadas.ContainsKey($chave)) { $txt = $chavesTrocadas[$chave] }
            if ([string]::IsNullOrWhiteSpace($txt)) { continue }
            foreach ($w in @([regex]::Matches($txt, "[\p{L}]+") | ForEach-Object { $_.Value })) {
                if ($w.Length -le 1) { continue }
                if (-not (Test-NoDicionario $w $Dicionario)) { $foraDic++ }
            }
        }
    }

    <#  O defeito que conta para o veredicto e o que o LEITOR vai encontrar:
        bloco recusado ou vazio. Palavra fora do dicionario entra como
        informacao ao lado, nao na conta - ela tem falso positivo demais
        (nome proprio, neologismo do filme, ortografia do release). #>
    $comDefeito = $recusados + $vazios
    $pct = 0.0
    if ($totalBlocos -gt 0) { $pct = ($comDefeito * 100.0) / $totalBlocos }

    <#  v1.22: entrou EXCELENTE. Com tres degraus, "BOA" era ao mesmo tempo
        o resultado perfeito e o meramente aceitavel - e o Spider-Man, que
        fecha em 0,26% com 15 de 19 blocos recuperados, saia com o mesmo
        rotulo de uma legenda em 0,49%. Quatro degraus separam "nao ha nada
        a fazer aqui" de "esta bom, mas nao esta impecavel". #>
    if     ($pct -le 0.1)  { $veredicto = "EXCELENTE"; $cor = "Green" }
    elseif ($pct -le 0.5)  { $veredicto = "BOA";       $cor = "Green" }
    elseif ($pct -le 1.5)  { $veredicto = "RAZOAVEL";  $cor = "Yellow" }
    else                   { $veredicto = "RUIM";      $cor = "Red" }

    $larg = 78
    Diz ""
    Diz ("=" * $larg) "DarkGray"
    Diz ("QUALIDADE DA LEGENDA: " + $veredicto) $cor
    Diz ("=" * $larg) "DarkGray"

    Diz ("  {0} blocos no arquivo - {1} com defeito conhecido ({2:N2}%)" -f $totalBlocos, $comDefeito, $pct)
    Diz ""

    if ($recusados -gt 0) {
        Diz ("  . " + $recusados + (Plural $recusados " bloco ilegivel que o re-OCR nao conseguiu recuperar" " blocos ilegiveis que o re-OCR nao conseguiu recuperar"))
        Diz  "    (as imagens estao em _reocr\ - a maioria costuma ser texto que" "DarkGray"
        Diz  "     o proprio disco ja traz escrito assim)" "DarkGray"
    }
    if ($vazios -gt 0) {
        Diz ("  . " + $vazios + (Plural $vazios " bloco sem texto nenhum - fala perdida na leitura" " blocos sem texto nenhum - falas perdidas na leitura")) "Yellow"
    }
    if ($resolvidos -gt 0) {
        Diz ("  . " + $resolvidos + (Plural $resolvidos " bloco estava ilegivel e foi recuperado nesta rodada" " blocos estavam ilegiveis e foram recuperados nesta rodada")) "Green"
    }
    if ($foraDic -gt 0) {
        Diz ("  . " + $foraDic + (Plural $foraDic " palavra fora do dicionario (nome proprio e neologismo" " palavras fora do dicionario (nome proprio e neologismo")) "DarkGray"
        Diz  "     do filme entram nesta conta - nem toda e erro)" "DarkGray"
    }
    if ($conferidos -gt 0) {
        Diz ("  . " + $conferidos + (Plural $conferidos " bloco CONFERIDO: o re-OCR leu igual ao que ja" " blocos CONFERIDOS: o re-OCR leu igual ao que ja")) "Cyan"
        Diz  "     estava no arquivo. O disco escreve assim mesmo - nao e erro" "DarkGray"
        Diz  "     nosso, e por isso nao entra na conta de defeito." "DarkGray"
    }
    if ($comDefeito -eq 0) {
        Diz "  Nenhum defeito conhecido sobrou. Nada exigindo revisao." "Green"
    }

    Diz ""
    if ($veredicto -ceq "EXCELENTE") {
        Diz "  Pode assistir tranquilo pela legenda convertida." "Green"
    } elseif ($veredicto -ceq "BOA") {
        Diz "  Pode assistir pela legenda convertida." "Green"
    } elseif ($veredicto -ceq "RAZOAVEL") {
        Diz "  Da para assistir. Se tropecar em alguma fala, a faixa PGS" "Yellow"
        Diz "  original esta no arquivo e pode ser trocada no player." "Yellow"
    } else {
        Diz "  Recomendo assistir pela faixa PGS original, que esta no mesmo" "Red"
        Diz "  arquivo - ela e a copia fiel do disco. A .SRT convertida fica" "Red"
        Diz "  como alternativa." "Red"
    }

    <#  v1.22: O CONVITE PARA MANDAR O RELATORIO.
        A correcao da legenda melhora por FAMILIA de erro, e uma familia so
        se prova quando o mesmo defeito aparece em filmes diferentes - foi
        assim que "INF TOL"/"Nao!" e a barra vertical viraram regra. Casos
        isolados (Sefior, lagarto, Faz) continuam sem regra justamente por
        terem aparecido uma vez so.
        Este aviso so aparece quando HA recusa - sem defeito nao ha o que
        analisar, e convite sem motivo vira ruido. #>
    if ($recusados -gt 0) {
        Diz ""
        Diz "  ---------------------------------------------------------------------" "DarkGray"
        Diz ("  Sobraram " + $recusados + (Plural $recusados " bloco que o re-OCR nao recuperou." " blocos que o re-OCR nao recuperou.")) "DarkGray"
        Diz "  Guarde ESTE relatorio. Quando juntar 3 ou 4 de filmes diferentes," "DarkGray"
        Diz "  mande no chat: defeito que se repete entre estudios vira regra nova" "DarkGray"
        Diz "  no Corretor. Defeito de um filme so continua sendo caso isolado." "DarkGray"
        <#  O caminho do relatorio NAO entra aqui: ele so e definido depois
            que esta nota e escrita (a nota faz parte do proprio relatorio).
            Imprimir a variavel neste ponto daria uma linha "Este relatorio:"
            terminando em nada - mensagem vazia e primo da mensagem que mente.
            O caminho ja sai no fim, na linha RELATORIO:. #>
    }
    Diz ("=" * $larg) "DarkGray"
}

function Test-ReocrAceitavel {
    param([string]$Texto, $Dicionario, $Nomes, [switch]$BlocoVazio, [int]$LinhasOriginais = 0)
    $script:MotivoRecusa = ""
    $t = $Texto.Trim()
    if ($t -eq "") { $script:MotivoRecusa = "veio vazio"; return $false }

    $linhas = @($t -split "`n" | Where-Object { $_.Trim() -ne "" })
    if ($linhas.Count -gt 3) {
        $script:MotivoRecusa = ("{0} linhas - bloco de legenda tem no maximo 3" -f $linhas.Count)
        return $false
    }
    <#  v1.13 - NAO PERCA A LINHA QUE ESTAVA BOA.  ESTRAGO REAL, PEGO EM MAQUINA.
        A regra 6 (1.12) passou a marcar bloco MISTO: uma linha de lixo ao lado
        de uma fala perfeita. So que o re-OCR substitui o bloco INTEIRO pela
        leitura nova - e quando ela sai curta, a linha boa vai junto.
        Medido no Spider-Man (19/08 19h04), com a 1.12 rodando:
            "E NFETOL / - Nossa!"        virou  "- Nossa"      (perdeu a linha)
            "ACRIDITAMOS NO / MYSTERIO"  virou  "misterio"     (destruiu)
            "- E ele? / E NFETOR"        virou  "Co,"          (destruiu)
            "- Me da a caixa. / E NFETOR" virou "Nao."         (perdeu a fala)
        Quatro falas boas perdidas para consertar quatro linhas ruins: o
        conserto saiu pior que o defeito. A 1.12 NAO deve ser usada.
        A trava: bloco de 2+ linhas so aceita leitura com o MESMO numero de
        linhas. Conferido contra os acertos do Se7en, que continuam passando -
        la o re-OCR devolveu as duas linhas ("-O Mercador de Veneza. / -Nao
        vi.", "ADVOGADO DE DEFESA / ENCONTRADO MORTO").
        Barrar aqui nao perde nada: o bloco fica como estava. #>
    if ($LinhasOriginais -ge 2 -and $linhas.Count -lt $LinhasOriginais) {
        $script:MotivoRecusa = ("a leitura nova tem {0} linha(s) e o bloco tinha {1} - trocar apagaria a linha que estava boa" -f $linhas.Count, $LinhasOriginais)
        return $false
    }

    if ($t.Length -gt 200) {
        $script:MotivoRecusa = ("{0} caracteres - bloco de legenda nao tem esse tamanho" -f $t.Length)
        return $false
    }

    <#  v1.15 - O TRAVESSAO DE DIALOGO NAO E RUIDO.  DEFEITO MEDIDO, NAO SUPOSTO.
        Spider-Man, rodada de 22/08 15:23. CINCO blocos foram recusados por
        esta regra com o motivo "2 de 4 tokens tem 1 caractere so", e as
        imagens salvas em _reocr\ provam que a leitura estava CERTA:
            'E NFETOL / - Nossa!'        a imagem e  '- Nao! / - Nossa!'
            '- Funcionou? / E NFETOL'    a imagem e  '- Funcionou? / - Nao!'
            '- E ele? / E NFETOR'        a imagem e  '- E ele? / - Nao.'
            '- Me da a caixa. / E NFETOR' a imagem e '- Me da a caixa. / - Nao.'
            'E NFETOL / - Perai.'        a imagem e  '- Nao! / - Perai.'
        A conta era literal: "- Nao! - Nossa!" tokeniza em  -  Nao!  -  Nossa!
        Quatro tokens, dois deles com 1 caractere = 50% > 40% -> RECUSADO.
        Ou seja: a regra que existe pra barrar enxame de letra solta estava
        contando o TRAVESSAO DE DIALOGO, que e o caractere mais comum que
        existe numa legenda de duas falas. Toda fala curta em dialogo caia
        aqui - exatamente a familia do "Nao!" que esta ferramenta existe pra
        consertar. Ela detectava certo, re-OCRava certo, e jogava fora.
        A correcao: token que nao tem NENHUMA letra ou digito (travessao,
        hifen, aspa, reticencia) sai da conta dos dois lados - nem conta como
        solto, nem como total. "P k q : DD 4 dE" continua sendo pego porque
        ali os soltos sao LETRAS (p, k, q, 4), nao pontuacao. #>
    $tokensBrutos = @($t -split '\s+' | Where-Object { $_ -ne "" })
    if ($tokensBrutos.Count -eq 0) { $script:MotivoRecusa = "sem nenhum token"; return $false }
    $tokens = @($tokensBrutos | Where-Object { $_ -match '[\p{L}\d]' })
    if ($tokens.Count -eq 0) { $script:MotivoRecusa = "so pontuacao, nenhuma letra"; return $false }
    $soltos = @($tokens | Where-Object { $_.Length -eq 1 }).Count
    if ($tokens.Count -ge 4 -and (($soltos / $tokens.Count) -gt 0.40)) {
        $script:MotivoRecusa = ("{0} de {1} tokens com letra tem 1 caractere so - isso e ruido de cena, nao texto" -f $soltos, $tokens.Count)
        return $false
    }

    $palavras = @([regex]::Matches($t, '[\p{L}]{2,}') | ForEach-Object { $_.Value })
    if ($palavras.Count -eq 0) {
        # v1.9: a regra "sem palavra de 2+ letras nao vale" existe pra barrar
        # ruido de cena. Mas quando o bloco de origem esta VAZIO nao ha nada
        # a proteger - o que existe hoje no arquivo e o silencio. Nesse caso
        # uma fala de uma letra da lista fechada e aceita.
        if ($BlocoVazio -and (Test-FalaCurtaValida $t)) { return $true }
        $script:MotivoRecusa = "nenhuma palavra de 2+ letras"; return $false
    }

    # TOKEN UNICO CURTO EM CAIXA ALTA. Pego no teste: o Tesseract devolveu
    # "NET" em quatro blocos e a trava do dicionario deixou passar - "net"
    # EXISTE no dicionario de 1,3M (entra pela parte de frequencia, cheia de
    # sigla e termo estrangeiro). Mesmo buraco que fechei no Corretor 2.12
    # com o "INF TOL": pergunta que depende do dicionario grande nao serve
    # de prova. Fala curta de verdade vem capitalizada ("Nao.", "Sim!",
    # "Paris!"), nao em caixa alta; letreiro em caixa alta e palavra longa
    # ("ALBERGUE", "CONTROLE MANUAL") e nem chega aqui, porque nao teria
    # sido marcado como suspeito.
    if ($palavras.Count -eq 1 -and $palavras[0].Length -le 4 -and
        $palavras[0] -ceq $palavras[0].ToUpperInvariant() -and
        $palavras[0] -cne $palavras[0].ToLowerInvariant()) {
        $script:MotivoRecusa = ("'" + $palavras[0] + "' - token unico curto em caixa alta, assinatura de ruido")
        return $false
    }
    <#  1.28: A TRAVA DE ACEITE PERGUNTAVA AO DICIONARIO DE 1,3M SOBRE
        PALAVRA DE 2 E 3 LETRAS - a mesma armadilha do 'INF TOL', aqui no
        pior lugar possivel: esta e a trava que decide o que vai ser GRAVADO
        no .srt do usuario. O bloco acima ja fechou o caso de UM token curto
        em caixa alta ('NET'), mas com dois tokens ('es tor', 'nf tor') a
        conta dava 2 de 2 = 100% e a leitura entrava.
        Agora vale a mesma regra da guarda de placa, que e a regra da casa:
        palavra com menos de 4 letras NAO se pergunta ao dicionario grande -
        ela vale pela lista fechada Test-CurtaComum ou por ser nome proprio.
        MEDIDO nas 24 trocas aceitas das quatro conversoes de 28/08 (Lara,
        Troia, Aranha e GoT): as 24 continuam sendo aceitas. Faz sentido -
        elas sao 'Nao.', 'Suba!', 'Aí está', e nao/vai/ele/aí estao todas na
        lista fechada. Ou seja: fecha o buraco sem custar nenhuma correcao
        real das que ja existem. #>
    $boas = 0
    foreach ($p in $palavras) {
        if ($Nomes -and $Nomes.Contains($p)) { $boas++; continue }
        if (Test-CurtaComum $p) { $boas++; continue }
        if ($p.Length -ge 4 -and (Test-NoDicionario $p $Dicionario)) { $boas++ }
    }
    if ($Dicionario -and (($boas / $palavras.Count) -lt 0.50)) {
        $script:MotivoRecusa = ("so {0} de {1} palavras existem em portugues" -f $boas, $palavras.Count)
        return $false
    }

    if (Test-BlocoSuspeito $t $Dicionario $Nomes) {
        $script:MotivoRecusa = "o texto novo continua com cara de lixo pelo mesmo criterio que marcou o bloco"
        return $false
    }
    return $true
}

function Test-BlocoSuspeito {
    param([string]$Texto, $Dicionario, $Nomes)
    if ($null -eq $Nomes) { $Nomes = New-Object 'System.Collections.Generic.HashSet[string]' }
    $limpo = ($Texto -replace '<[^>]{1,20}>', '').Trim()
    <#  v1.9: BLOCO VAZIO PASSOU A SER SUSPEITO - ANTES ERA IGNORADO.
        Num .srt que veio de PGS, todo bloco existe porque uma IMAGEM foi
        desenhada na tela naquele instante. Bloco sem texto nenhum nao e
        "silencio": e uma fala que o OCR PERDEU no caminho.
        Achado real no Se7en (19/08): os blocos 00:01:10,278 e 00:38:06,074
        sairam vazios do PgsToSrt. A segunda opiniao do seconv, no mesmo
        arquivo, leu os dois como "E." (E com acento) - o glifo do E-acentuado
        sozinho e justamente o que o Corretor ja tinha visto quebrar o formato
        em outros 11 blocos. Duas falas somem do arquivo final sem nenhum
        aviso, e o "return $false" daqui era o motivo de o re-OCR nem tentar.
        Vazio agora entra na fila. Se o re-OCR tambem nao conseguir ler, o
        bloco continua vazio como estava - nao se perde nada tentando. #>
    if ($limpo -eq "") { return $true }

    # regra 1: bloco de 1 letra so (que nao seja interjeicao valida).
    # Se o bloco tem NUMERO, a letra sozinha e unidade e nao lixo - o '"4h"?'
    # do Homem-Aranha (quatro horas) caia aqui sendo uma fala perfeita.
    $soConteudo = ($limpo -replace '[^\p{L}]', '')
    # v1.6: o teste era na letra COM acento, entao um bloco que e so "E."
    # (o verbo ser) nao batia em [aeo] e ia pro re-OCR sendo fala perfeita.
    if ($soConteudo.Length -eq 1 -and (Get-SemAcento $soConteudo) -notmatch '(?i)^[aeo]$' -and $limpo -notmatch '\d') { return $true }

    $palavras = @([regex]::Matches($limpo, '[\p{L}]{2,}') | ForEach-Object { $_.Value })
    if ($palavras.Count -eq 0) { return $false }

    # regra 2: MAIUSCULA NO MEIO DA PALAVRA ("ToRSTOUR"). Nao depende de
    # dicionario nenhum, entao nao sofre com palavra que falta la.
    # A excecao e marca que SE ESCREVE assim (BuzzFeed, YouTube, iPhone) -
    # mesma lista do Corretor_Legenda 2.11, pelo mesmo motivo: a legenda
    # original do Homem-Aranha escreve "O BuzzFeed diz que um marinheiro".
    foreach ($p in $palavras) {
        if ($p.Length -ge 3 -and $p -cmatch '[\p{Ll}][\p{Lu}]') {
            if ($script:MarcasCamel.Contains($p.ToLowerInvariant())) { continue }
            # v1.6: nome proprio em CamelCase que se repete no arquivo e nao
            # existe no dicionario ("McGregor"). Ver Get-NomesCamel.
            if ($script:NomesCamel -and $script:NomesCamel.Contains($p)) { continue }
            return $true
        }
    }

    if (-not $Dicionario) { return $false }

    $reconhecidas = 0
    foreach ($p in $palavras) {
        if ((Test-NoDicionario $p $Dicionario) -or $Nomes.Contains($p)) { $reconhecidas++ }
    }

    <#  regra 3: 2+ palavras e quase nada existe em portugues.

        1.29 - MEDIDO E DELIBERADAMENTE NAO ALTERADO.
        Uma auditoria de 01/09 apontou que esta conta pergunta ao dicionario
        de 1,3M sobre palavra de 2 e 3 letras, o que e proibido no resto do
        projeto (siglas como 'tor', 'inf' e 'tol' existem la dentro). Do
        ponto de vista da regra da casa, o apontamento esta certo.
        So que eu MEDI antes de mexer, nos 8.887 blocos dos quatro filmes
        convertidos (GoT, Lara, Troia e Aranha), e a correcao seria MUITO
        pior que o defeito:
            hoje              : cerca de 10 blocos suspeitos no total
            com a guarda de 4 : 850 blocos suspeitos
        Cada suspeito custa 60 leituras do Tesseract, entao seriam ~28
        minutos a mais por lote - e, pior, cada bloco trocado por engano e
        um defeito NOVO numa legenda que hoje sai EXCELENTE.
        A razao e simples e vale escrever: fala normal em portugues e cheia
        de palavra curta ('Nao sei o que e', 'E ai?'). Se palavra curta nao
        pontua, fala legitima vira lixo aos olhos da regra.
        Esta conta PRECISA contar palavra curta - e por isso que ela separa
        fala de lixo. Quem cuida do 'INF TOL' e a regra 3B logo abaixo, que
        e cirurgica: caixa alta, 2+ palavras, e pelo menos uma sem vogal.
        NAO troque isto por uma guarda de 4 letras sem refazer a medicao. #>
    if ($palavras.Count -ge 2 -and ($reconhecidas / $palavras.Count) -lt 0.34) { return $true }

    # regra 3B: bloco EM CAIXA ALTA com 2+ palavras, todas de ate 3 letras.
    # E o "INF TOL" do Troia, que aparece 6 vezes e sempre era "Nao.". A
    # regra 3 parou de pegar ele porque "inf" e "tol" existem no dicionario
    # de 1,3M. Esta nao pergunta nada ao dicionario. Medido nos 3 filmes:
    # todo bloco em caixa alta legitimo ('EU MAIS SUA', 'PONTE CARLOS',
    # 'ARMA: ALABARDA') tem pelo menos uma palavra de 4+ letras.
    if ($palavras.Count -ge 2) {
        $todasCaixaAlta = $true
        $maiorPalavra = 0
        foreach ($p in $palavras) {
            if ($p -cne $p.ToUpperInvariant()) { $todasCaixaAlta = $false; break }
            if ($p.Length -gt $maiorPalavra) { $maiorPalavra = $p.Length }
        }
        # v1.6: "SIM OU NAO" / "EU VOU LA" tambem sao 2+ palavras curtas em
        # caixa alta e sao fala legitima. Ver Test-CurtaComum.
        $temCurtaComum = $false
        foreach ($p in $palavras) { if (Test-CurtaComum $p) { $temCurtaComum = $true; break } }
        if ($todasCaixaAlta -and $maiorPalavra -le 3 -and -not $temCurtaComum) { return $true }
    }

    # regra 4: 1 palavra so, MAS toda maiuscula e inexistente em PT
    # ("INFETOR"). Com 1 palavra minuscula a chance de ser so falta no
    # dicionario e alta demais - por isso a exigencia de caixa alta.
    if ($palavras.Count -eq 1 -and $reconhecidas -eq 0) {
        $u = $palavras[0]
        if ($u.Length -ge 4 -and $u -ceq $u.ToUpperInvariant() -and $u -cne $u.ToLowerInvariant()) { return $true }
    }
    <#  regra 6 (v1.12): LINHA DE LIXO DENTRO DE BLOCO BOM.
        Tudo acima julga o bloco INTEIRO. Quando o lixo esta numa linha e a
        outra e uma fala perfeita, a proporcao do bloco fica boa e ele passa.
        Casos reais nos arquivos FINAIS de 19/08:
            "- Me da a caixa. / E NFETOR"
            "-O Mercador de Veneza. / MN NETORVE"
            "- E ele? / E NFETOR"
            "-Ponha a sua labia para funcionar. / e NETOR"
        Sao 13 blocos nos 6 filmes - a maior familia que ainda escapava.
        E a regra 4 (palavra unica MAIUSCULA inexistente) aplicada por LINHA
        em vez de por bloco. Legenda tem 2-3 linhas: custa nada.
        GUARDA DE PLACA: nao marca se OUTRA palavra em caixa alta da mesma
        linha existir em portugues. Placa de lugar ("PHTIA - GRECIA",
        "IXTENCO, MEXICO", "BROEK OP LANGEDIJK, HOLANDA") sempre traz o
        pais/lugar conhecido ao lado; lixo de OCR nao traz nada.
        MEDIDO nos 7.695 blocos: 13 acertos, ZERO falso positivo. Sem a
        guarda de placa eram 13 acertos e 3 falsos. #>
    foreach ($linha in ($limpo -split "`n")) {
        $emCaixa = @([regex]::Matches($linha, '[\p{L}]{4,}') | ForEach-Object { $_.Value } |
                     Where-Object { $_ -ceq $_.ToUpperInvariant() -and $_ -cne $_.ToLowerInvariant() })
        if ($emCaixa.Count -eq 0) { continue }
        $temConhecida = $false
        $temEstranha  = $false
        foreach ($p in $emCaixa) {
            if ((Test-NoDicionario $p $Dicionario) -or $Nomes.Contains($p)) { $temConhecida = $true }
            else { $temEstranha = $true }
        }
        if ($temEstranha -and -not $temConhecida) { return $true }
    }

    <#  REGRA 6B (Reocr 1.25 / Corretor 2.24): LINHA INTEIRA EM CAIXA ALTA
        SEM UMA PALAVRA SEQUER EM PORTUGUES.

        Caso real, Spider-Man 27/08, bloco 416 do arquivo FINAL:

            NF TOR
            - AI esta.

        "NF TOR" e a mesma familia do "INF=TOR" / "INFETOR" / "MN NETORVE"
        que este detector ja pega ha versoes - o texto certo e "- Nao.".
        Ele escapava por UM numero: a regra 6 so olhava palavras de 4+
        letras ([\p{L}]{4,}), e "NF" tem 2 e "TOR" tem 3. E a regra 3B, que
        cobre palavra curta, exige que o BLOCO INTEIRO seja caixa alta - e
        aqui a segunda linha e fala normal. O lixo caiu no vao entre as duas.

        A regra nova nao tem tamanho minimo. Em troca exige que a linha seja
        SO caixa alta: se sobrou qualquer palavra em minuscula na linha, ela
        nao entra. Isso e o que protege "MJ! MJ, a gente te ama!" e qualquer
        sigla no meio de fala - o caso que faria esta regra virar uma maquina
        de marcar legenda boa.
        E mantem a GUARDA DE PLACA da regra 6: uma palavra conhecida em
        caixa alta na mesma linha absolve a linha inteira. Letreiro de
        verdade sempre traz uma ("ILHA ROOSEVELT", "MALAS STARK", "DIGITE A
        SENHA", "MOLHO DE ESPAGUETE"); lixo de OCR nao traz nenhuma.

        O QUE ACONTECE COM UM FALSO POSITIVO: nada se perde. Um letreiro de
        nome proprio ("MARTIN TALBOT") pode ser marcado - vai para o re-OCR,
        as 60 leituras devolvem o mesmo texto, o bloco sai [CONFERIDO] e NAO
        conta como defeito. O custo e tempo, nao qualidade. #>
    foreach ($linha in ($limpo -split "`n")) {
        $tokens = @([regex]::Matches($linha, '[\p{L}]{2,}') | ForEach-Object { $_.Value })
        if ($tokens.Count -eq 0) { continue }
        <#  v2.24/1.25 - A 6B NASCEU LARGA DEMAIS E EU MEDI DEPOIS.
            Medida nos 3 filmes inteiros (4.854 blocos), a versao de manha
            marcava 28 linhas e SO UMA era lixo de verdade. As outras 27 eram
            letreiro e nome: 'MARTIN TALBOT', 'DANTE ALIGHIERI', 'CHAUCER',
            'MJ!', 'MICENAS - GRECIA', '[BRAZILIAN PORTUGUESE]'.
            E isso NAO era inofensivo como eu tinha dito: bloco que vai pro
            re-OCR e nao e recuperado entra na conta de defeito e DERRUBA o
            veredicto da legenda. Ou seja: a regra ia fazer a nota mentir.
            Duas travas a mais, tiradas da assinatura real da familia:
              . PELO MENOS 2 PALAVRAS - 'NF TOR', 'MN NETORVE', 'SM EISTOR'.
                Letreiro de uma palavra so ('MJ!', 'TROIA') sai fora. Lixo de
                uma palavra so ja tem dono: as regras 3B e 4.
              . PELO MENOS UMA PALAVRA SEM VOGAL NENHUMA - 'NF', 'MN', 'SM'.
                Nome e letreiro de verdade sempre tem vogal. Isso sozinho
                absolve TALBOT, ALIGHIERI, CHAUCER, TROIA, NEGATIVO, FRAGIL.
            Remedida com as duas travas: das 28, sobra 1 - o 'NF TOR'. #>
        if ($tokens.Count -lt 2) { continue }
        <#  A GUARDA DE PLACA NAO PODE PERGUNTAR PALAVRA CURTA AO DICIONARIO
            DE 1,3M. Teste real do Spider-Man de 27/08 11:19: a 6B pegou os
            cinco 'E NFETOL' / 'E NFETOR' e deixou passar o 'NF TOR' - o
            unico que eu tinha escrito a regra para pegar.
            Motivo: 'tor' EXISTE no dicionario de 1,3M (ele traz sigla e
            abreviacao de tudo quanto e lingua). Uma palavra "conhecida" na
            linha absolvia a linha inteira, e o lixo saiu ileso.
            E a MESMA armadilha que ja esta escrita na regra 3B sobre o
            'INF TOL' do Troia - 'inf' e 'tol' tambem existem la dentro. Eu
            tinha o aviso no arquivo e repeti o erro.
            Agora, para ABSOLVER uma linha, a palavra conhecida tem que ser:
              . de 4+ letras e existir no dicionario, OU
              . estar na LISTA FECHADA de palavras curtas comuns
                (Test-CurtaComum - escrita a mao, imune ao dicionario), OU
              . ser nome proprio colhido do proprio filme.
            Letreiro de verdade sempre traz uma dessas ('ILHA ROOSEVELT',
            'MOLHO DE ESPAGUETE', 'DIGITE A SENHA'). 'NF TOR' nao traz. #>
        $soCaixa = $true; $conhecida = $false; $semVogal = $false
        foreach ($p in $tokens) {
            if ($p -cne $p.ToUpperInvariant()) { $soCaixa = $false; break }
            if ($Nomes.Contains($p)) { $conhecida = $true }
            elseif (Test-CurtaComum $p) { $conhecida = $true }
            elseif ($p.Length -ge 4 -and (Test-NoDicionario $p $Dicionario)) { $conhecida = $true }
            if ((Get-SemAcento $p) -notmatch '(?i)[aeiou]') { $semVogal = $true }
        }
        if ($soCaixa -and -not $conhecida -and $semVogal) {
            return $true
        }
    }

    return $false
}

# =============================================================== programa
try {
    $raiz = Get-PastaScript
    $carimbo = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $pastaSaida = Join-Path $raiz "_reocr"
    if (-not (Test-Path -LiteralPath $pastaSaida)) { New-Item -ItemType Directory -Path $pastaSaida -Force | Out-Null }
    $pastaTemp = Join-Path $pastaSaida ("tmp_" + $carimbo)
    New-Item -ItemType Directory -Path $pastaTemp -Force | Out-Null

    Titulo ("LaFirma - Reocr_Legenda v" + $Versao)
    Diz ("Data      : " + (Get-Date -Format "dd/MM/yyyy HH:mm:ss"))
    Diz ("Pasta     : " + $raiz)

    # ------------------------------------------------------- selecao de arquivo
    if ($Mkv -eq "" -or $Srt -eq "") {
        try {
            Add-Type -AssemblyName System.Windows.Forms
            [void][System.Windows.Forms.Application]::EnableVisualStyles()
            if ($Mkv -eq "") {
                $d1 = New-Object System.Windows.Forms.OpenFileDialog
                $d1.Title = "Reocr_Legenda - PASSO 1/2: selecione o .mkv ORIGINAL (com a faixa PGS)"
                $d1.Filter = "Video Matroska (*.mkv)|*.mkv|Todos os arquivos (*.*)|*.*"
                $d1.InitialDirectory = $raiz
                if ($d1.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $Mkv = $d1.FileName }
            }
            if ($Mkv -ne "" -and $Srt -eq "") {
                $d2 = New-Object System.Windows.Forms.OpenFileDialog
                $d2.Title = "Reocr_Legenda - PASSO 2/2: selecione o .srt que o motor gerou (o que sera corrigido)"
                $d2.Filter = "Legenda (*.srt)|*.srt|Todos os arquivos (*.*)|*.*"
                try { $d2.InitialDirectory = (Split-Path -Parent $Mkv) } catch { $d2.InitialDirectory = $raiz }
                if ($d2.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $Srt = $d2.FileName }
            }
        } catch {
            Diz ("[!] Nao consegui abrir a janela de selecao (" + $_.Exception.Message + ")") "Yellow"
        }
    }
    if ($Mkv -eq "" -or -not (Test-Path -LiteralPath $Mkv)) { Diz "[!] .mkv nao informado ou nao existe. Encerrando." "Red"; exit 1 }
    if ($Srt -eq "" -or -not (Test-Path -LiteralPath $Srt)) { Diz "[!] .srt nao informado ou nao existe. Encerrando." "Red"; exit 1 }

    Diz ("MKV : " + $Mkv)
    Diz ("SRT : " + $Srt)

    # ------------------------------------------------------------- ferramentas
    $ffmpeg = Join-Path $raiz "tools\ffmpeg.exe"
    if (-not (Test-Path -LiteralPath $ffmpeg)) { $ffmpeg = "C:\LaFirma\tools\ffmpeg.exe" }
    $ffprobe = Join-Path $raiz "tools\ffprobe.exe"
    if (-not (Test-Path -LiteralPath $ffprobe)) { $ffprobe = "C:\LaFirma\tools\ffprobe.exe" }
    if (-not (Test-Path -LiteralPath $ffmpeg) -or -not (Test-Path -LiteralPath $ffprobe)) {
        Diz "[!] ffmpeg.exe/ffprobe.exe nao encontrados em tools\. Encerrando." "Red"
        exit 1
    }

    <#  v1.15 - TESSERACT PORTATIL.  A ORDEM DE BUSCA MUDOU DE PROPOSITO.
        O programa inteiro e portatil: seconv, ffmpeg, dovi_tool, mkvmerge e
        DeeZy vivem todos dentro de tools\. O tesseract.exe era a UNICA peca
        que so existia se o usuario tivesse instalado o UB-Mannheim por fora -
        ou seja, numa maquina recem-formatada o re-OCR de fala curta nao
        rodava, e o programa nao avisava nada no meio da conversao.
        Agora a ordem e: pasta local PRIMEIRO, sistema so como ultimo recurso.
        Assim a copia empacotada e sempre a que roda, e a versao instalada na
        maquina do usuario nao muda o resultado de um arquivo pro outro.
        O -IgnorarTesseractDoSistema serve pra PROVAR o caminho portatil numa
        maquina que ainda tem o Tesseract instalado (foi como isso foi testado
        sem precisar desinstalar nada).  #>
    $script:TessDataDir = ""
    if ($TesseractExe -eq "") {
        foreach ($c in @((Join-Path $raiz "tools\Tesseract\tesseract.exe"),
                         (Join-Path $raiz "tools\Tesseract-OCR\tesseract.exe"),
                         "C:\LaFirma\tools\Tesseract\tesseract.exe")) {
            if (Test-Path -LiteralPath $c) { $TesseractExe = $c; break }
        }
    }
    if ($TesseractExe -eq "" -and -not $IgnorarTesseractDoSistema) {
        $cmd = Get-Command "tesseract.exe" -ErrorAction SilentlyContinue
        if ($cmd) { $TesseractExe = $cmd.Source }
        else {
            foreach ($c in @("C:\Program Files\Tesseract-OCR\tesseract.exe", "C:\Program Files (x86)\Tesseract-OCR\tesseract.exe")) {
                if (Test-Path -LiteralPath $c) { $TesseractExe = $c; break }
            }
        }
    }
    <#  --tessdata-dir explicito quando a copia e a nossa.
        Sem isso o tesseract.exe portatil procura o por.traineddata pela
        variavel TESSDATA_PREFIX, que numa maquina limpa nao existe - e ele
        falha com "Error opening data file" em TODAS as 60 leituras, o que
        apareceria como "nenhuma leitura passou na trava": mensagem que mente
        sobre a causa. Com o caminho na mao isso nao depende do ambiente.
        Ordem: o tessdata do lado do exe; se nao houver, o do PgsToSrt, que
        ja carrega o por.traineddata e sempre foi empacotado.  #>
    if ($TesseractExe -ne "") {
        foreach ($td in @((Join-Path (Split-Path -Parent $TesseractExe) "tessdata"),
                          (Join-Path $raiz "tools\PgsToSrt\tessdata"))) {
            if (Test-Path -LiteralPath (Join-Path $td "por.traineddata")) { $script:TessDataDir = $td; break }
        }
    }
    if ($TesseractExe -eq "" -or -not (Test-Path -LiteralPath $TesseractExe)) {
        Diz "" "Red"
        Diz "[!] tesseract.exe nao encontrado. O PgsToSrt do motor so tem a" "Red"
        Diz "biblioteca (tesseract53.dll), nao o programa standalone que este" "Red"
        Diz "script precisa pra controlar o modo de segmentacao (--psm)." "Red"
        Diz "" "Red"
        Diz "Esperado em:  tools\Tesseract\tesseract.exe (copia empacotada)" "Yellow"
        Diz "Se voce apagou a pasta, reinstale o LaFirma - ela vem no setup." "Yellow"
        exit 1
    }
    $ondeTess = "do sistema"
    if ($TesseractExe -like (Join-Path $raiz "tools\*")) { $ondeTess = "empacotado" }
    elseif ($TesseractExe -like "C:\LaFirma\tools\*") { $ondeTess = "empacotado" }
    Diz ("Tesseract: " + $TesseractExe + "  [" + $ondeTess + "]")
    if ($script:TessDataDir -ne "") { Diz ("tessdata : " + $script:TessDataDir) "DarkGray" }
    else { Diz "[!] por.traineddata nao encontrado - o re-OCR vai falhar em todas as leituras." "Yellow" }

    # -------------------------------------------------- dicionario (opcional)
    $dicionario = Get-DicionarioPtBr $raiz
    if ($dicionario) { Diz ("Dicionario PT-BR: " + $dicionario.Count + " palavras (" + $script:DicionarioArquivo + ")") "DarkGray" }
    else {
        # 1.14: mesma correcao de mensagem do Corretor 2.18 - a funcao acima
        # procura os DOIS arquivos (o grande primeiro); dizer so o nome do
        # pequeno confundia quem lia quando nenhum dos dois existia.
        Diz "[!] Nenhum dicionario PT-BR encontrado (LaFirma_PTBR_1.3M.dic.gz ou Auditor_OCR.dic.gz) - deteccao de bloco suspeito so usa a regra de letra sozinha." "Yellow"
    }

    # ------------------------------------------------------- faixa PGS a usar
    if ($Track -eq "") {
        Diz "" ; Diz "Detectando faixa PGS pt-BR no .mkv original..." "White"
        $probeJson = & $ffprobe '-v' 'error' '-show_streams' '-select_streams' 's' '-of' 'json' $Mkv 2>&1
        $erroProbe = $null
        $candidatas = @()
        $todasLegendas = @()
        try {
            $obj = ($probeJson -join "`n") | ConvertFrom-Json
            $todasLegendas = @($obj.streams)
            # v1.1.0: "pob" entrou na lista - muito remux brasileiro marca a
            # faixa assim, e sem isso a deteccao automatica nem via a faixa.
            # E faixa de COMENTARIO ficou de fora: existe filme com PGS
            # "Brazilian" E "Brazilian (Commentary)" (Tomb Raider 2001 e o
            # caso real citado no changelog do motor). Se o comentario
            # aparecesse primeiro no arquivo, era ele que ia pro re-OCR.
            $candidatas = @($todasLegendas | Where-Object {
                "$($_.codec_name)" -match '(?i)pgs|hdmv_pgs' -and
                "$($_.tags.language)" -match '(?i)^(por|pob|pt)$' -and
                $_.disposition.forced -ne 1 -and
                "$($_.tags.title)" -notmatch '(?i)coment|commentary'
            })
        } catch {
            $erroProbe = $_.Exception.Message
        }

        if ($erroProbe) {
            Diz ("[!] ffprobe/JSON deu erro ao listar faixas: " + $erroProbe) "Red"
        }

        if ($candidatas.Count -eq 1) {
            $Track = $candidatas[0].index
            Diz ("Faixa PGS pt-BR detectada automaticamente: id " + $Track) "Green"
        } elseif ($candidatas.Count -gt 1) {
            # v1.0.1: mesmo criterio do motor (Find-PtBrPgsTrack) - varios
            # filmes tem PGS "Brazilian" E "Iberian" com language=por nas
            # duas. Prefere a que tem "Brazilian" no nome da faixa.
            $brasileira = @($candidatas | Where-Object { "$($_.tags.title)" -match '(?i)brazilian' })
            if ($brasileira.Count -ge 1) {
                $Track = $brasileira[0].index
                Diz ("Faixa PGS pt-BR detectada automaticamente (nome 'Brazilian'): id " + $Track) "Green"
            } else {
                Diz ("[!] " + $candidatas.Count + " faixas PGS com idioma 'por' encontradas, nenhuma com 'Brazilian' no nome - preciso que voce escolha:") "Yellow"
                foreach ($c in $candidatas) {
                    Diz ("    id " + $c.index + "  -  '" + "$($c.tags.title)" + "'") "White"
                }
                Diz "Rode de novo passando -Track <id> com o numero certo." "Yellow"
            }
        }

        if ($Track -eq "") {
            # v1.0.8: BUG CORRIGIDO - quando 0 candidatas batiam no filtro
            # (codec PGS + language por/pt + nao forcada), o script so dizia
            # "nao detectei" e parava, sem mostrar NADA do que realmente
            # existe no arquivo. Casos reais que pegaram isso: Troy 2004 e
            # Tomb Raider 2001 - o Tomb Raider especificamente e citado no
            # changelog do proprio motor como tendo 3 variantes de PGS em
            # portugues, entao o criterio simples daqui nao bastou. Agora,
            # se a deteccao automatica falhar, LISTA TODAS as faixas de
            # legenda do arquivo (nao so as candidatas) - da pra ver o
            # idioma/nome real de cada uma e escolher com -Track.
            Diz "[!] Nao detectei automaticamente nenhuma faixa PGS pt-BR nao-forcada." "Red"
            if ($todasLegendas.Count -eq 0) {
                Diz "    O ffprobe nao encontrou NENHUMA faixa de legenda neste arquivo." "Red"
            } else {
                Diz ("    Todas as " + $todasLegendas.Count + " faixas de legenda encontradas no arquivo:") "Yellow"
                foreach ($t in $todasLegendas) {
                    $forcada = if ($t.disposition.forced -eq 1) { " [FORCADA]" } else { "" }
                    Diz ("      id " + $t.index + "  codec=" + $t.codec_name + "  lang=" + "$($t.tags.language)" + "  titulo='" + "$($t.tags.title)" + "'" + $forcada) "White"
                }
                # v1.0.9: se a faixa pt-BR que existe JA E TEXTO (subrip/ass/
                # ssa), nao adianta pedir pra rodar de novo com -Track nela -
                # nao tem imagem PGS nenhuma pra extrair e reprocessar. Caso
                # real: Troy 2004 (CiNEPHiLES DUAL-LACTATO) - a faixa pt-BR
                # e subrip com o titulo literal "Portugues (Brasil) [OCR]",
                # ou seja alguem (o grupo do remux, provavelmente) ja rodou
                # OCR nisso ANTES de empacotar. O Reocr_Legenda so consegue
                # melhorar uma faixa que nasceu de imagem PGS - se a origem
                # ja e texto, o unico jeito de corrigir e o Auditor_OCR
                # (estatistica, nao precisa de imagem) ou comparando com
                # uma legenda de referencia.
                $textoPtBr = @($todasLegendas | Where-Object {
                    "$($_.codec_name)" -notmatch '(?i)pgs|hdmv_pgs' -and
                    "$($_.tags.language)" -match '(?i)^(por|pob|pt)$'
                })
                if ($textoPtBr.Count -gt 0) {
                    Diz "" "Cyan"
                    Diz "    Reparo: a faixa pt-BR que existe (acima) JA E TEXTO (nao PGS)." "Cyan"
                    Diz "    Isso significa que ela nao veio de OCR nosso - alguem (o grupo do" "Cyan"
                    Diz "    remux, geralmente) ja converteu antes de empacotar. Nao existe" "Cyan"
                    Diz "    imagem PGS nenhuma pra este script reprocessar - passar -Track" "Cyan"
                    Diz "    nela nao vai funcionar. Se essa legenda tiver erro, o jeito e o" "Cyan"
                    Diz "    Auditor_OCR (nao precisa de imagem) ou comparar com referencia." "Cyan"
                } else {
                    Diz "    Escolha o id certo (o mesmo numero da aba Faixas do LaFirma) e rode de novo com -Track <id>." "Yellow"
                }
            }
            exit 1
        }
    } else {
        Diz ("Faixa PGS informada manualmente: id " + $Track)
    }

    <#  v1.7: A RESOLUCAO ERA LIDA ERRADO - E A LINHA MENTIA.
        A leitura antiga concatenava a saida inteira do ffprobe numa string e
        exigia exatamente 2 pedacos depois de separar por virgula. Qualquer
        linha extra, aviso ou quebra derrubava a conta, e o valor caia no
        default "1920x1080" - SEM DIZER que caiu. Prova: nos quatro relatorios
        de 18/08 (Troia, Se7en, Spider-Man e Lara Croft) essa linha imprimiu
        "1920x1080" nos QUATRO, sendo que tres deles sao 2160p. Ou seja: ela
        nunca leu nada, sempre imprimiu o default.
        Isso importa agora porque a resolucao passou a ser USADA (ver o
        comentario do filtro, mais abaixo), nao so exibida.
        Agora le linha a linha, aceita so numero, e quando nao consegue ler
        DIZ que nao conseguiu.
    #>
    $vidW = 0; $vidH = 0
    try {
        $probeV = @(& $ffprobe '-v' 'error' '-select_streams' 'v:0' `
                      '-show_entries' 'stream=width,height' `
                      '-of' 'default=noprint_wrappers=1:nokey=1' $Mkv 2>$null)
        $nums = @()
        foreach ($ln in $probeV) {
            $t = "$ln".Trim()
            if ($t -match '^\d+$') { $nums += [int]$t }
        }
        if ($nums.Count -ge 2) { $vidW = $nums[0]; $vidH = $nums[1] }
    } catch { }
    if ($vidW -gt 0 -and $vidH -gt 0) {
        $wh = ("" + $vidW + "x" + $vidH)
        Diz ("Resolucao do video: " + $wh) "DarkGray"
    } else {
        $wh = ""
        Diz "[!] Nao consegui ler a resolucao do video pelo ffprobe - a legenda nao sera reescalada." "Yellow"
    }

    <#  v1.8: REGRESSAO DA 1.7, ACHADA NO TESTE DE 18/08 AS 22h11.
        A 1.7 passou a escalar a legenda SEMPRE. Isso consertou o Spider-Man
        (7 de 9, era 0 de 9) e QUEBROU o Se7en: os tres blocos "INF=TOR" que a
        1.6 resolvia passaram a dar tira preta.
        A prova de que a culpa e do scale, e nao do seek em geral, esta no
        proprio relatorio: no MESMO arquivo, na MESMA faixa, o quarto bloco
        ("BIOININNICIO)" -> "DOMINGO") funcionou. A diferenca entre eles e a
        DURACAO: "DOMINGO" e um letreiro que fica segundos na tela; "Nao." e
        uma fala curta. Um filtro a mais na frente do overlay atrapalha o
        casamento do display set do PGS com o instante pedido, e so a legenda
        curta sente.
        Ou seja: escalar SO RESOLVE quando as resolucoes sao diferentes, e SO
        ATRAPALHA quando ja sao iguais. Entao agora e condicional - a
        resolucao da propria faixa PGS decide.
        Quando o ffprobe nao devolve a resolucao da faixa (acontece em alguns
        containers), o padrao e NAO escalar: e o comportamento da 1.6, que ja
        tinha 15 de 15 nos tres filmes onde as resolucoes batem.
    #>
    $pgsW = 0; $pgsH = 0
    try {
        $probeS = @(& $ffprobe '-v' 'error' '-select_streams' ("" + $Track) `
                      '-show_entries' 'stream=width,height' `
                      '-of' 'default=noprint_wrappers=1:nokey=1' $Mkv 2>$null)
        $nums2 = @()
        foreach ($ln in $probeS) {
            $t2 = "$ln".Trim()
            if ($t2 -match '^\d+$') { $nums2 += [int]$t2 }
        }
        if ($nums2.Count -ge 2) { $pgsW = $nums2[0]; $pgsH = $nums2[1] }
    } catch { }
    $precisaEscalar = $false
    if ($pgsW -gt 0 -and $pgsH -gt 0) {
        Diz ("Resolucao da legenda PGS: " + $pgsW + "x" + $pgsH) "DarkGray"
        if ($vidW -gt 0 -and $vidH -gt 0 -and ($pgsW -ne $vidW -or $pgsH -ne $vidH)) {
            $precisaEscalar = $true
            Diz ("    a legenda e MENOR que o video - vai ser reescalada de " + $pgsW + "x" + $pgsH + " para " + $wh) "Yellow"
        }
    } else {
        Diz "[!] Nao consegui ler a resolucao da faixa PGS - nao vou reescalar (comportamento da 1.6)." "Yellow"
    }

    # ------------------------------------------------------------- ler o srt
    $textoSrt = Ler-TextoComEncoding $Srt
    $blocos = Parse-Srt $textoSrt
    Diz ("Blocos no SRT: " + $blocos.Count)

    # v1.2.0: levanta os nomes proprios do arquivo INTEIRO antes de julgar
    # bloco nenhum - senao "Seria Randyll Tarly?" vira suspeito.
    $textoTodoSrt = ($blocos | ForEach-Object { $_.Texto }) -join "`n"
    $nomesProprios = Get-NomesProprios $textoTodoSrt $dicionario
    $script:NomesCamel = Get-NomesCamel $textoTodoSrt $dicionario
    if ($nomesProprios.Count -gt 0) {
        Diz ("Nomes proprios protegidos: " + $nomesProprios.Count + " (" + ((@($nomesProprios) | Sort-Object | Select-Object -First 8) -join ", ") + ")") "DarkGray"
    }

    $suspeitos = @($blocos | Where-Object { $_.TimingOk -and (Test-BlocoSuspeito $_.Texto $dicionario $nomesProprios) })
    Diz ("Blocos suspeitos (candidatos a re-OCR): " + $suspeitos.Count)
    if ($suspeitos.Count -eq 0) {
        Diz "" ; Diz "Nenhum bloco suspeito encontrado - nada pra corrigir. Encerrando." "Green"
        if (-not $SemPausa) { Read-Host "ENTER pra fechar" | Out-Null }; exit 0
    }

    Titulo "RE-OCR DOS BLOCOS SUSPEITOS"
    $trocas = New-Object System.Collections.Generic.List[object]
    # v1.23: chaves dos blocos CONFERIDOS (re-OCR leu igual ao que ja estava).
    # Nao sao defeito - saem da conta da nota. Lista, nao contador, porque a
    # nota precisa saber QUAIS blocos para nao conta-los duas vezes.
    $script:BlocosConfirmados = New-Object System.Collections.Generic.List[string]
    $num = 0
    foreach ($b in $suspeitos) {
        $num++
        # v1.9: bloco que chegou VAZIO segue por um caminho um pouco mais
        # permissivo (ver Test-FalaCurtaValida) - nao ha texto bom a perder.
        $blocoVazio = ((("" + $b.Texto) -replace '<[^>]{1,20}>', '').Trim() -eq "")
        # v1.13: quantas linhas o bloco ORIGINAL tem. A trava de aceite usa
        # isso para nao trocar um bloco de duas linhas por uma leitura de uma
        # so - o que apagaria a linha que estava boa. Ver Test-ReocrAceitavel.
        $linhasOriginaisDoBloco = @((("" + $b.Texto) -replace '<[^>]{1,20}>', '') -split "`n" |
                                    Where-Object { $_.Trim() -ne "" }).Count
        <#  v1.23: o texto que ja estava no bloco, limpo de tag, para comparar
            com o que o re-OCR ler. Bloco vazio nao entra: nao ha o que
            confirmar quando nao havia texto nenhum. #>
        $textoOriginalDoBloco = ""
        if (-not $blocoVazio) { $textoOriginalDoBloco = (("" + $b.Texto) -replace '<[^>]{1,20}>', '') }
        $rotulo = if ($blocoVazio) { "(BLOCO VAZIO - fala perdida pelo OCR)" } else { "'" + ($b.Texto -replace "`n"," / ") + "'" }
        Diz ("[" + $num + "/" + $suspeitos.Count + "] " + $b.Inicio + " :: " + $rotulo) "White"

        <#
          v1.4.0 - TRES INSTANTES, NAO UM SO.
          No teste do Troia, 2 das 8 imagens sairam PRETAS - o frame caiu
          fora da janela em que a legenda esta na tela. Pegar um instante so
          e apostar tudo num palpite. Agora tenta tres pontos dentro do
          bloco (300ms depois do inicio, o meio, e 250ms antes do fim) e
          fica com a melhor leitura das tres. Custa 3 chamadas de ffmpeg em
          um punhado de blocos - nao pesa, e mata a imagem preta.
        #>
        $duracaoBloco = $b.FimMs - $b.IniMs
        if ($duracaoBloco -lt 0) { $duracaoBloco = 0 }
        <#  v1.18: A ORDEM DOS INSTANTES INVERTEU - E ISSO SAI DA MEDIDA, NAO
            DE PALPITE.
            Relatorio do Spider-Man de 25/08 21h27: dos 15 blocos aceitos,
            QUINZE venceram com "instante 3/3". Nenhum venceu com o 1 ou o 2.
            O mesmo padrao aparece em todas as rodadas anteriores guardadas.
            Faz sentido fisico: o instante 1 fica 300 ms depois do bloco
            comecar, quando a legenda pode ainda estar em fade-in, e o 3 fica
            250 ms antes do fim, com o desenho ja completamente estabelecido.

            Como o laco PARA assim que um instante devolve leitura aprovada,
            comecar pelo que costuma ganhar economiza as duas extracoes
            seguintes na maioria dos blocos. Cada extracao custa alguns
            segundos (seek + decodificacao 4K), e sao 3 por bloco: no
            Spider-Man, 19 blocos x 3 = 57 extracoes, das quais ~2/3 eram
            descartadas depois de prontas.

            Nada mais muda: os mesmos tres instantes continuam sendo tentados
            quando o primeiro nao resolve, entao nenhum bloco perde chance de
            ser corrigido. So a ORDEM mudou. Se um dia o instante do fim parar
            de ser o melhor, o unico efeito e voltar a gastar o que se gastava
            antes - nunca um resultado pior.  #>
        $instantes = New-Object System.Collections.Generic.List[int]
        $offFim = $duracaoBloco - 250
        if ($offFim -lt 0) { $offFim = 0 }
        [void]$instantes.Add($b.IniMs + $offFim)
        [void]$instantes.Add($b.IniMs + [int]($duracaoBloco / 2))
        $offInicio = 300
        if ($offInicio -gt [int]($duracaoBloco / 2)) { $offInicio = [int]($duracaoBloco / 2) }
        [void]$instantes.Add($b.IniMs + $offInicio)

        $melhorTexto = ""
        $melhorNota = -1.0
        $melhorPct = 0
        $melhorConsenso = 0
        $psmVencedor = ""
        $pngSaida = ""
        $tentativa = 0
        # v1.21: zerada POR BLOCO. Sem isto, o primeiro bloco que parasse por
        # consenso deixaria a flag ligada e todos os seguintes sairiam na
        # primeira leitura - um bug silencioso que so apareceria como queda
        # de qualidade, sem erro nenhum na tela.
        $pararPorConsenso = $false
        <#  v1.23: CONFIRMACAO - quando o re-OCR le IGUAL ao que ja estava.
            A trava recusa o bloco por "nao parece portugues", e ate a 1.22
            isso era contado como defeito. Mas ha um caso em que a recusa nao
            significa falha nenhuma: quando as leituras novas chegam ao MESMO
            texto que ja estava no arquivo. Aí o OCR nao errou - ele
            confirmou, e quem "escreve errado" e o disco.
            Spider-Man: ACRIDITAMOS NO MYSTERIO e SANITIZANTE sao exatamente
            isso, e as imagens em _reocr\ provam. Contavam como 2 dos 5
            defeitos, empurrando o filme de EXCELENTE para BOA por causa de
            duas leituras CERTAS. #>
        $confirmacoes = 0
        # v1.10: quantos instantes REALMENTE renderam imagem com legenda.
        # Nem sempre sao os tres - ver a trava de consenso mais abaixo.
        $instantesUteis = 0
        <#  v1.10: PROGRESSO FINO PARA QUEM ESTA ESPERANDO.
            Ate agora este script so avisava quando COMECAVA um bloco novo
            ("[3/9]"). Quem le isso e o motor, pra mover a barra - e entre um
            bloco e o proximo a barra nao tinha o que ler. Num bloco lento
            (o do Se7en levou mais de 3 minutos) a barra ficava parada, e do
            lado de fora isso parece travamento.
            Agora sai uma linha "#PROG# bloco passo total" a cada altura
            testada: 3 instantes x 4 alturas = 12 passos por bloco. Instante
            que sai preto conta os 4 passos dele de uma vez (ele terminou,
            so foi rapido). A linha comeca com "#" e o motor a consome sem
            mostrar - nao polui o relatorio nem a tela. #>
        $passoBloco = 0
        <#  v1.24: O PASSO ERA GROSSO DEMAIS - 12 POR BLOCO.
            O #PROG# saia uma vez por ALTURA, e dentro de cada altura rodam
            CINCO leituras do Tesseract. Num bloco recusado (que roda tudo)
            eram 60 leituras reportadas em 12 avisos: a barra la fora andava
            uma vez a cada 5 leituras, e num bloco de 3 minutos isso dava a
            impressao de travamento (o "87% travado" de 27/08).
            Agora o passo e a LEITURA, nao a altura: 60 avisos por bloco. #>
        $passosDoBloco = $instantes.Count * 4 * 5
        if ($passosDoBloco -le 0) { $passosDoBloco = 60 }
        # v1.11: primeiro instante que rendeu tira - e ele que vale guardar
        # como prova quando o bloco e recusado.
        $pngUtilPrimeiro = ""
        <#  v1.11: O CONTADOR DE CONSENSO IGNORAVA MAIUSCULA/MINUSCULA.
            @{} do PowerShell e case-insensitive. O Corretor documenta essa
            armadilha e usa Dictionary de proposito; aqui ela tinha ficado
            aberta - justamente no lugar onde o valor da prova e "duas rotas
            independentes chegaram no MESMO texto".
            Caso concreto, que o proprio comentario da v1.4.0 descreve: o
            psm 11 devolve "Nao!" e o psm 6 devolve "NAO!". As duas rotas
            DISCORDARAM exatamente na caixa - que e o defeito procurado - e o
            contador somava como se tivessem concordado. Em bloco vazio isso
            decide sozinho se a fala entra no arquivo final. #>
        $script:Consenso = New-Object 'System.Collections.Generic.Dictionary[string,int]' 
        foreach ($tempoMeioMs in $instantes) {
            $tentativa++
            [int]$tempoMeio = $tempoMeioMs
            [int]$segAntes = [math]::Floor($tempoMeio / 1000) - 5
            if ($segAntes -lt 0) { $segAntes = 0 }
            [int]$segDepoisMs = $tempoMeio - ($segAntes * 1000)
            if ($segDepoisMs -lt 0) { $segDepoisMs = 0 }
            [int]$segDepoisS = [math]::Floor($segDepoisMs / 1000)
            [int]$segDepoisResto = $segDepoisMs % 1000
            $pngSaida = Join-Path $pastaTemp ("bloco_" + $num.ToString("0000") + "_t" + $tentativa + ".png")

            $tempoFiltro = "00:00:{0:00}.{1:000}" -f $segDepoisS, $segDepoisResto
        # v1.0.2: BUG CORRIGIDO - "0:s:$Track" significa "a N-esima faixa DE
        # LEGENDA" (contando so entre legendas, 0-based), nao "faixa de
        # indice absoluto N". $Track vem do ffprobe (campo "index"), que E
        # o indice absoluto - o mesmo numero da aba Faixas do LaFirma. Com
        # o "s:" o ffmpeg pegava uma faixa errada (ou nenhuma, se passasse
        # do total de legendas) e falhava silenciosamente pra TODOS os
        # blocos - foi exatamente o que aconteceu no teste real do
        # Spider-Man (index 31 absoluto, so ~28 faixas de legenda existem
        # antes dele contando so subtitles). Sintaxe certa: "0:$Track" sem
        # o "s:", igual o Extrair-LegendasDoMkv do Auditor_OCR ja fazia
        # certo com "-map 0:$idx".
        # v1.0.3: BUG CORRIGIDO - "$wh:d" dentro da string fazia o PowerShell
        # tentar ler "wh:d" como sintaxe de ESCOPO (igual "$env:PATH"), nao
        # como "a variavel $wh seguida da letra d". Isso apagava a resolucao
        # do video ($wh) do filtro sem erro nenhum na hora - so aparecia
        # depois, no ffmpeg, como "Unable to parse option value '=0.1' as
        # image size" (o "s=" chegava vazio). Corrigido com ${wh} entre
        # chaves, que desambigua e forca ler so o nome da variavel.
        # v1.0.4: BUG CORRIGIDO - o fundo preto sintetico ("color=...")
        # so durava d=0.1 (100 ms), mas o segundo -ss (seek fino, depois do
        # -filter_complex) pode pedir um frame ate quase 6s depois do inicio
        # desse fundo (segAntes tira exatamente 5s inteiros, sobra o resto
        # em milissegundos, ate 5999ms). Depois de 100ms o fundo simplesmente
        # parava de existir - o overlay nao tinha em cima de que desenhar a
        # legenda, e o ffmpeg gravava um PNG "valido" (existe, tem tamanho)
        # mas provavelmente preto/vazio, sem a legenda - por isso o Tesseract
        # nao achava nada em nenhum dos 9 blocos, sem erro nenhum aparente.
        # Corrigido: fundo dura 10s, cobrindo com folga qualquer offset fino
        # possivel dentro da janela de 5s de margem que o seek grosso deixa.
        # v1.0.5: BUG ESTRUTURAL - as 9 imagens da 1.0.4 vieram TODAS pretas,
        # em blocos de horarios bem diferentes entre si - isso descarta erro
        # de timing (ja corrigido na 1.0.4) e aponta pra algo na propria
        # tecnica: overlay em cima de um fundo "color" SINTETICO parece nao
        # sincronizar direito com o stream de legenda (duas linhas de tempo
        # diferentes dentro do filtro, uma real - a legenda seekada do mkv -
        # e uma artificial - o fundo preto gerado do zero). Trocado pela
        # tecnica documentada e testada de "hardsub" (queimar legenda no
        # video): sobrepoe em cima do FRAME DE VIDEO REAL, que vem do MESMO
        # input seekado - as duas linhas de tempo sao a mesma, sem risco de
        # dessincronia. Perde um pouco do contraste ideal (fundo nao e mais
        # preto puro), mas PGS tem contorno preto + preenchimento branco, da
        # pra ler bem mesmo sobre video real - e o essencial e a legenda
        # aparecer na imagem, o que o fundo sintetico simplesmente nao fazia.
        # v1.0.6: o video real funcionou (texto de verdade apareceu, ex: bloco
        # 7 saiu quase perfeito: "nossa ultima noite na Europa... tinha um
        # plano que queria te contar" - quase identico a referencia) - mas o
        # Tesseract estava lendo o FRAME INTEIRO (1920x1080), textura da cena
        # do filme virando um mar de ruido em volta do texto real da legenda.
        # PGS de filme widescreen fica quase sempre no terco inferior da
        # tela - corta pra essa faixa (os 32% de baixo, com uma margem) antes
        # de mandar pro Tesseract, tirando a maior parte da cena do caminho.
        # v1.0.7: tres melhorias na imagem, sem depender de referencia
        # nenhuma - e o passo 1 da Opcao 1 (deixar o Reocr_Legenda confiavel
        # sozinho). Todas evitam sintaxe de EXPRESSAO (geq/lutyuv com virgula
        # escapada) de proposito - ja levei bug real duas vezes neste projeto
        # com interpolacao/parsing de filtro ffmpeg (o "$wh:d" da v1.0.3, o
        # "s:$Track" da v1.0.2), entao prefiro filtros com parametro numerico
        # simples, sem expressao embutida, mesmo abrindo mao de um pouco de
        # precisao:
        #   - corte alargado de 32% pra 40% da altura (o de 32% cortou a
        #     legenda fora em cena de close-up - bloco 3 do teste real)
        #   - scale 2x - Tesseract reconhece melhor texto maior
        #   - eq contrast+brightness+saturation=0 - empurra o texto branco
        #     da legenda pro extremo claro e desatura a cor da cena, sem
        #     ser um limiar binario perfeito (mais seguro sintaticamente
        #     que um threshold via geq/lutyuv)
        # v1.3.0: APAGA A CENA ANTES DE SOBREPOR A LEGENDA.
        #
        # A 1.0.5 trocou o fundo preto SINTETICO ("color=") pelo frame de
        # video real porque o sintetico tem outra linha de tempo e nao
        # sincronizava - isso continua verdade. O erro foi parar por ai: o
        # frame real trouxe a CENA junto, e a partir da 1.0.6 o trabalho todo
        # virou tentar abafar a cena depois (crop, contraste, escala). Nao
        # abafa. No teste do Troia de 13/08 o Tesseract leu a batalha inteira
        # e devolveu 700 caracteres de ruido no lugar de uma palavra.
        #
        # A saida e usar o frame real - mesma linha de tempo, que era o ponto
        # da 1.0.5 - mas APAGADO. "eq=brightness=-1.0:contrast=0.0" leva
        # qualquer pixel a preto puro. Sobra o canvas certo, no tempo certo,
        # e a legenda por cima. So parametro numerico, sem expressao - mesma
        # regra de sempre neste arquivo.
        #
        # MEDIDO AQUI, mesma cena e mesma legenda, Tesseract psm 6:
        #   cena atras (como estava)  -> 123 bytes de lixo, igual ao do Troia
        #   cena apagada (agora)      -> "Nao." limpo, 6 bytes
        # v1.5.0: o ffmpeg nao escala mais nada. Ele entrega a tira no
        # tamanho NATIVO e quem varia a escala e o laco de leitura logo
        # abaixo - ver o comentario grande la. Motivo: nao existe uma escala
        # unica que sirva pra tudo, entao escala virou tentativa, igual ao
        # PSM e ao instante.
        <#  v1.7: A LEGENDA PASSA A SER ESCALADA PRO TAMANHO DO VIDEO.
            O overlay desenha a legenda no canto 0,0 do canvas, no tamanho
            NATIVO dela. Quando a PGS do release e 1920x1080 e o video e
            3840x2160, a legenda inteira cabe no quadrante superior esquerdo:
            a linha de fala, que na PGS fica por volta de y=950 de 1080, cai
            em y~950 de 2160 - ou seja, a 44% da altura. E o crop pega de 60%
            pra baixo. Resultado: TIRA PRETA, sempre, em todos os blocos.
            Foi exatamente o que aconteceu no Spider-Man (18/08): 9 blocos,
            9 recusas, e os 9 PNGs de falha salvos sao IDENTICOS byte a byte
            (14.835 bytes cada, 3840x864, todos pretos). Nove instantes
            diferentes do filme nao produzem nove imagens iguais por acaso -
            produzem quando nao ha nada pra desenhar.
            Nos filmes em que a PGS ja casa com o video (Troia, Se7en, Lara
            Croft) o scale nao muda nada: escalar 1920x1080 para 1920x1080 e
            operacao vazia. Por isso a correcao nao mexe no que ja funciona.
            Se a resolucao nao pode ser lida, o filtro volta a ser o antigo -
            melhor o comportamento conhecido do que um numero inventado.
        #>
        <#  v1.18: O FUNDO PRETO SAIU - E NAO PRECISAVA DE FUNDO NENHUM.
            O filtro decodificava o quadro HEVC 4K e o apagava com
            eq=brightness=-1.0. Ou seja: gastava o passo mais caro da extracao
            para produzir um retangulo preto. Sao 3 extracoes por bloco
            suspeito.

            A 1.16 tentou trocar o video por uma fonte "color=" e FALHOU na
            maquina real: 19 de 19 blocos recusados com "os 3 instantes
            sairam vazios". Testado agora contra a PGS de verdade (o .sup do
            Spider-Man extraido com mkvextract, remuxado com um video 4K),
            a causa ficou clara: a fonte color= gera o proprio quadro no tempo
            ZERO e o overlay casa com ela, ignorando o -ss. Saia preto puro
            (max=0) em todos os instantes.

            A solucao e mais simples do que as duas tentativas: NAO USAR FUNDO.
            A faixa PGS ja e uma imagem com transparencia; escalada e
            convertida para gray ela ja da exatamente o mesmo resultado que
            "video apagado + legenda por cima", porque o video apagado era,
            por definicao, preto.

            MEDIDO CONTRA A PGS REAL, nao contra substituto:
              - imagem comparada pixel a pixel com o filtro antigo, no mesmo
                instante:  0 pixels diferentes de 3.317.760
              - 14 instantes com legenda, lidos pelo Tesseract nos dois
                filtros:  14 leituras IDENTICAS, 0 diferentes
              - tempo: 7,9s -> 2,1s  (3,8x mais rapido)

            O ganho e por extracao; num arquivo com 19 blocos suspeitos sao 57
            extracoes. #>
        if ($vidW -gt 0 -and $vidH -gt 0) {
            $filtro = "[0:${Track}]scale=${vidW}:${vidH}:flags=neighbor,format=gray[ov];[ov]crop=iw:ih*0.40:0:ih*0.60,eq=contrast=2.2:brightness=0.06:saturation=0"
        } else {
            <#  Sem resolucao lida nao da para escalar; cai no caminho antigo,
                que depende do quadro de video para dimensionar. Comportamento
                conhecido e melhor que numero inventado. #>
            $filtro = "[0:v:0]eq=brightness=-1.0:contrast=0.0[bg];[bg][0:$Track]overlay[ov];[ov]crop=iw:ih*0.40:0:ih*0.60,eq=contrast=2.2:brightness=0.06:saturation=0"
        }
        $saidaFfmpeg = & $ffmpeg '-y' '-ss' $segAntes '-i' $Mkv '-filter_complex' $filtro '-ss' $tempoFiltro '-frames:v' '1' '-q:v' '2' $pngSaida 2>&1

        if (-not (Test-Path -LiteralPath $pngSaida) -or (Get-Item -LiteralPath $pngSaida).Length -eq 0) {
            Diz ("    [!] ffmpeg nao gerou imagem no instante " + $tentativa + "/3 - tentando o proximo. Saida do ffmpeg:") "Yellow"
            $ultimasLinhas = @($saidaFfmpeg | Select-Object -Last 4)
            foreach ($ln in $ultimasLinhas) { Diz ("      " + $ln) "DarkGray" }
            # v1.11: este instante acabou (mal, mas acabou). Sem somar os
            # passos dele, o bloco terminava em 8/12 e a barra la fora ficava
            # parada ate o proximo bloco - exatamente o "parece travamento"
            # que a v1.10 foi escrita para eliminar.
            # v1.24: um instante inteiro agora vale 4 alturas x 5 modos = 20.
            $passoBloco += 20
            Write-Host ("#PROG# " + $num + " " + $passoBloco + " " + $passosDoBloco)
            continue
        }

        <#  v1.7: TIRA PRETA TEM NOME AGORA.
            Ate a 1.6, quando a imagem saia sem legenda nenhuma, o Tesseract
            devolvia vazio nas 60 combinacoes e o relatorio dizia
            "nenhuma palavra de 2+ letras". Tecnicamente verdade e
            praticamente inutil: e a mesma frase que aparece quando a imagem
            esta boa e a leitura e que foi ruim. Duas causas opostas, uma
            mensagem so - e foi por isso que o caso do Spider-Man ficou
            escondido ate alguem abrir os PNGs na mao.
            A checagem e barata: 400 pixels em grade. Se TODOS forem quase
            pretos, nao ha o que ler - o problema esta na extracao, nao no
            OCR, e o relatorio passa a dizer isso.
        #>
        if (Test-TiraPreta $pngSaida) {
            Diz ("    [!] a tira saiu PRETA no instante " + $tentativa + "/3 (nenhuma legenda foi desenhada) - tentando o proximo.") "Yellow"
            $script:HouveTiraPreta = $true
            $passoBloco += 20   # v1.24: instante inteiro = 4 alturas x 5 modos
            Write-Host ("#PROG# " + $num + " " + $passoBloco + " " + $passosDoBloco)
            continue
        }
        $instantesUteis++
        if ($pngUtilPrimeiro -eq "") { $pngUtilPrimeiro = $pngSaida }

        $txtSaidaBase = Join-Path $pastaTemp ("bloco_" + $num.ToString("0000") + "_t" + $tentativa)

        <#
          v1.4.0 - PSM 11 ENTROU, E A ESCOLHA DEIXOU DE SER POR "MAIS LETRAS".

          Duas coisas erradas aqui, e as duas apareceram no teste do Troia:

          [1] FALTAVA O PSM 11. Reproduzi a falha exata do Diego aqui,
              gerando "Nao!" branco em fundo preto num canvas 4K e passando
              pelo mesmo tratamento. Resultado, com a imagem PERFEITA:
                  psm 6  -> "NEToL"      psm 7  -> "NEToL"
                  psm 4  -> "NEToL"      psm 11 -> "Nao!"   <- certo
              Ou seja: o "INF TOL" e o "NET" que ele viu NAO eram a imagem
              suja. Eram o modo de segmentacao errado. "Nao!" e o pior caso
              do psm 6 - o til e a exclamacao viram um bloco que ele tenta
              ler como duas colunas. O psm 11 (texto esparso) nao faz
              analise de layout e acerta.
              Testado nas duas resolucoes e em 8 falas diferentes: o psm 11
              ganha em fala curta ("Nao!", "Sim!"), o psm 6 ganha em fala
              longa ("Nao. Nao sou." - o 11 devolve "SOU" em caixa alta).
              Por isso os dois ficam, e a ordem decide o empate.

          [2] A ESCOLHA POR "MAIS LETRAS" ESCOLHIA O LIXO. "NEToL" tem 5
              letras, "Nao!" tem 3 - a heuristica antiga entregaria "NEToL"
              e a trava depois recusaria o bloco inteiro, perdendo a leitura
              boa que ja estava na mao. Agora a ordem e a certa: cada
              tentativa passa PRIMEIRO pela trava de aceite, e entre as que
              passam vence a que tem a maior proporcao de palavras que
              existem em portugues. Empate fica com a primeira da ordem.
        #>
        <#
          v1.5.0 - A ESCALA TAMBEM VIROU TENTATIVA. E ERA ELA O PROBLEMA.

          A 1.4.0 fixou a tira em 864px de altura e apostou no psm 11. No
          teste real do Diego (Troia 4K, 17:02) isso salvou 1 bloco de 8 - o
          resto continuou devolvendo "NETO" apesar das imagens estarem
          IMPECAVEIS (ele mandou os PNG; da pra ler "Nao!" a olho nu).

          Medi a mesma legenda em varias alturas, com os 5 modos, nas duas
          resolucoes. Nao existe altura unica que sirva:

            "Nao!" 4K   h=216 acerta nos 5 modos | h=864 so no psm 11
            "Nao." 4K   h=216 erra nos 5 ("INETOR") | h=300 acerta nos 5
            "Nao!" 1080 h=216 acerta nos 5 | h=300 erra em 4 dos 5

          Ou seja: a mesma imagem, so mudando o tamanho que o Tesseract
          recebe, passa de "INETOR" pra "Nao." e vice-versa. Isso tambem
          explica por que aqui funcionava e na maquina dele nao - basta uma
          diferenca pequena de tamanho de glifo pra virar a chave.

          Entao paro de procurar o numero certo: agora o script tenta as
          quatro alturas (216/300/432/864) x cinco modos x tres instantes, e
          a trava de aceite mais a nota de dicionario escolhem. As quatro
          alturas juntas acertaram TODOS os casos da bateria.

          Custo: a extracao pesada (ffmpeg no .mkv) continua sendo 3 por
          bloco. O reescalonamento acontece em cima do PNG ja pronto, que e
          minusculo, e o Tesseract roda em imagem pequena - segundos.

          O '--dpi 300' entrou junto: sem ele o Tesseract chuta a resolucao
          e o chute muda de versao pra versao, o que joga resultado pra
          todo lado sem nenhum aviso.
        #>
        foreach ($altura in @('216', '300', '432', '864')) {
            $pngEscalado = $txtSaidaBase + "_h" + $altura + ".png"
            & $ffmpeg '-y' '-loglevel' 'error' '-i' $pngSaida '-vf' ("scale=-2:" + $altura) '-frames:v' '1' $pngEscalado 2>&1 | Out-Null
            if (-not (Test-Path -LiteralPath $pngEscalado)) {
                # v1.24: altura perdida = os 5 modos dela nao vao rodar.
                $passoBloco += 5
                Write-Host ("#PROG# " + $num + " " + $passoBloco + " " + $passosDoBloco)
                continue
            }
            foreach ($psm in @('6', '7', '4', '11', '12')) {
                # v1.24: o passo agora e a LEITURA. Ver o comentario do
                # $passosDoBloco la em cima.
                $passoBloco++
                Write-Host ("#PROG# " + $num + " " + $passoBloco + " " + $passosDoBloco)
                $txtTentativa = $txtSaidaBase + "_h" + $altura + "_psm" + $psm
                if ($script:TessDataDir -ne "") {
                    & $TesseractExe $pngEscalado $txtTentativa '-l' 'por' '--psm' $psm '--dpi' '300' '--tessdata-dir' $script:TessDataDir 2>&1 | Out-Null
                } else {
                    & $TesseractExe $pngEscalado $txtTentativa '-l' 'por' '--psm' $psm '--dpi' '300' 2>&1 | Out-Null
                }
                $arqTentativa = $txtTentativa + ".txt"
                if (-not (Test-Path -LiteralPath $arqTentativa)) { continue }
                $tent = (Ler-TextoComEncoding $arqTentativa).Trim()
                if ($tent -eq "") { continue }
                <#  Contado ANTES da trava de proposito: e justamente o texto
                    que a trava vai recusar (o mesmo que ja estava no bloco).
                    Comparacao sem acento e sem caixa porque o que interessa
                    e "leu a mesma palavra", nao "leu byte a byte igual". #>
                if ($textoOriginalDoBloco -ne "") {
                    $a = (Get-SemAcento ($tent -replace "\s+", " ")).ToLowerInvariant().Trim()
                    $bb = (Get-SemAcento ($textoOriginalDoBloco -replace "\s+", " ")).ToLowerInvariant().Trim()
                    if ($a -eq $bb) { $confirmacoes++ }
                }
                if (-not (Test-ReocrAceitavel $tent $dicionario $nomesProprios -BlocoVazio:$blocoVazio -LinhasOriginais $linhasOriginaisDoBloco)) { continue }
                $pal = @([regex]::Matches($tent, '[\p{L}]{2,}') | ForEach-Object { $_.Value })
                $curtaValida = $false
                if ($pal.Count -eq 0) {
                    if (-not ($blocoVazio -and (Test-FalaCurtaValida $tent))) { continue }
                    $curtaValida = $true
                }
                $totalPal = if ($curtaValida) { 1 } else { $pal.Count }
                $boas = 0
                if ($curtaValida) {
                    $boas = 1
                } else {
                    foreach ($p in $pal) {
                        if ((Test-NoDicionario $p $dicionario) -or $nomesProprios.Contains($p)) { $boas++ }
                    }
                }
                # empate na nota do dicionario e desempatado por CONSENSO:
                # a leitura que mais se repetiu entre as combinacoes ganha.
                # Duas rotas independentes chegando no mesmo texto e a
                # evidencia mais barata que existe de que o texto e o certo.
                $pctDicionario = [Math]::Round(($boas / $totalPal) * 100)
                if ($script:Consenso.ContainsKey($tent)) {
                    $script:Consenso[$tent] = $script:Consenso[$tent] + 1
                } else {
                    $script:Consenso[$tent] = 1
                }
                # v1.5.1: a nota de ORDENACAO nao serve pra mostrar na tela.
                # Ela e "percentual x 100 + numero de repeticoes", um numero
                # interno. Na 1.5.0 eu imprimia ela como se fosse porcentagem
                # e o relatorio saiu com "13000% das palavras existem em
                # portugues". Numero absurdo em relatorio e a mesma familia
                # de defeito que a gente vem caçando: mensagem que nao
                # corresponde ao que aconteceu. Agora sao duas variaveis
                # separadas - uma pra ordenar, outra pra contar a verdade.
                $nota = ($boas / $totalPal) * 100 + $script:Consenso[$tent]
                if ($nota -gt $melhorNota) {
                    $melhorNota = $nota
                    $melhorTexto = $tent
                    $melhorPct = $pctDicionario
                    $melhorConsenso = $script:Consenso[$tent]
                    $psmVencedor = ("psm " + $psm + ", altura " + $altura + ", instante " + $tentativa + "/3")
                }
                <#  v1.21: PARAR QUANDO JA SE SABE A RESPOSTA.
                    O laco rodava as 60 combinacoes SEMPRE, mesmo com a
                    resposta ja decidida. Medido: 84% do tempo do Reocr e
                    Tesseract - 1140 execucoes por filme, ~370 ms cada - e a
                    etapa da legenda foi 24,5% da conversao de 26/08.

                    Quando o MESMO texto sai de $LimiteConsenso combinacoes
                    diferentes, mais leituras nao mudam quem ganha: a nota e
                    (percentual do dicionario + consenso), e o lider ja esta
                    na frente por margem que as combinacoes restantes nao
                    cobrem. Entao para.

                    MEDIDO nos 19 blocos reais do Spider-Man (o .sup extraido
                    do arquivo do Diego, remuxado com video 24 fps e escalado
                    igual ao pipeline - 13 dos 15 blocos com texto conhecido
                    reproduzidos identicos):
                        K= 4  -> 19/19 identicos, 19% do custo
                        K= 8  -> 19/19 identicos, 45% do custo
                        K=12  -> 19/19 identicos, 60% do custo
                    Nenhum K testado mudou uma resposta sequer. Escolhido
                    K=8: o dobro da margem do menor valor que ja bastava,
                    porque o custo de errar aqui (trocar uma fala por outra)
                    e maior que o de gastar mais alguns segundos.

                    Bloco dificil nao para cedo - e justamente nele que as 60
                    leituras continuam rodando, que e onde elas servem. #>
                if ($script:Consenso[$tent] -ge $LimiteConsenso -and $tent -ceq $melhorTexto) {
                    $pararPorConsenso = $true
                    break
                }
            }
            if ($pararPorConsenso) { break }
        }
        if ($pararPorConsenso) { break }
        }
        $novoTexto = $melhorTexto
        if ($novoTexto -ne "") {
            $textoConsenso = "leitura unica"
            # v1.11: 60 nem sempre e 60 - instante que sai vazio nao roda
            # combinacao nenhuma. A v1.10 corrigiu isso na linha da recusa e
            # esqueceu desta e da de baixo.
            $combRodadas = $instantesUteis * 20
            if ($combRodadas -le 0) { $combRodadas = 60 }
            if ($melhorConsenso -gt 1) { $textoConsenso = ("mesma leitura em " + $melhorConsenso + " das " + $combRodadas + " combinacoes") }
            Diz ("    (" + $psmVencedor + " | " + $melhorPct + "% das palavras existem em portugues | " + $textoConsenso + ")") "DarkGray"
        }

        <#  v1.9: leitura de UMA letra so nao entra por nota - entra por
            REPETICAO. Uma letra sozinha e barata de alucinar: qualquer
            borrao vira "E". Se a MESMA letra sai em varias das combinacoes
            (instantes x 4 alturas x 5 modos), que sao rotas independentes,
            ela esta na imagem.

            v1.10: O NUMERO EXIGIDO ERA FIXO EM 5 DE 60 - E 60 NEM SEMPRE E 60.
            Achado no Se7en de 19/08: quatro blocos vazios foram recuperados
            como "E." com 6 de 60 cada, e um quinto (01:05:36) foi RECUSADO
            com 2. Parecia leitura fraca. Nao era: naquele bloco DOIS dos tres
            instantes sairam vazios de verdade, entao so 20 combinacoes
            chegaram a rodar. 2 de 20 e a mesma densidade de prova que 6 de
            60 - mas a trava comparava contra um total que nao existiu.
            E o PNG salvo daquele bloco mostra "E." legivel.
            Agora a exigencia acompanha quantos instantes de fato renderam
            imagem: 3 instantes -> 5 combinacoes; 2 -> 4; 1 -> 2. Mesma
            densidade de prova, independente de quantas rotas existiram. #>
        $exigeConsenso = 5
        if ($instantesUteis -gt 0 -and $instantesUteis -lt 3) {
            $exigeConsenso = [int][math]::Max(2, [math]::Ceiling(5.0 * $instantesUteis / 3.0))
        }
        if ($novoTexto -ne "" -and (Test-FalaCurtaValida $novoTexto) -and $melhorConsenso -lt $exigeConsenso) {
            $totalComb = $instantesUteis * 20
            if ($totalComb -le 0) { $totalComb = 60 }
            Diz ("    [RECUSADO] leitura curta '" + $novoTexto + "' apareceu em so " + $melhorConsenso + " das " + $totalComb + " combinacoes que rodaram (precisa de " + $exigeConsenso + ") - pouco pra uma letra sozinha") "Yellow"
            $novoTexto = ""
            $script:MotivoRecusa = "leitura de uma letra sem repeticao suficiente"
        }

        # v1.4.0: a trava ja rodou la em cima, tentativa por tentativa. Se
        # $novoTexto esta vazio, e porque NENHUMA das 5 passou - e o motivo
        # da ultima recusa e o que sobrou em $script:MotivoRecusa.
        if ($novoTexto -eq "") {
            $combRodadasR = $instantesUteis * 20
            if ($combRodadasR -le 0) {
                Diz ("    [RECUSADO] nenhuma leitura chegou a rodar - os " + $tentativa + " instantes sairam vazios") "Yellow"
            } else {
                Diz ("    [RECUSADO] nenhuma das " + $combRodadasR + " leituras que rodaram (" + $instantesUteis + " instante(s) x 4 alturas x 5 modos) passou na trava") "Yellow"
            }
            if ($script:MotivoRecusa -ne "") { Diz ("    ultima recusa: " + $script:MotivoRecusa) "DarkGray" }
        }

        if ($novoTexto -eq "" -or $novoTexto -notmatch '\p{L}') {
            # v1.0.4: quando nao aproveita, guarda o PNG num lugar que NAO e
            # apagado no final (a pasta _reocr\ ao lado do script) - assim,
            # se continuar falhando, da pra abrir a imagem e ver com os
            # proprios olhos se a legenda apareceu nela ou se ainda esta so
            # preto. Antes isso ficava so na pasta temp, que era sempre
            # apagada no fim - eu ficava tentando adivinhar sem nunca ver.
            <#  v1.11: A FRASE AFIRMAVA UM ARQUIVO QUE PODIA NAO EXISTIR.
                $pngSaida e o caminho do ULTIMO instante. Se esse ultimo caiu
                no continue (o ffmpeg nao gerou imagem), o Copy-Item falhava
                em silencio por causa do -ErrorAction SilentlyContinue e a
                mensagem mandava abrir um arquivo que nao estava la. E o
                procedimento de diagnostico oficial da ferramenta e "abra o
                PNG e me mande" - ou seja, a mentira caia justamente em cima
                de quem estava tentando entender a falha.
                Agora: guarda o PNG do PRIMEIRO instante que rendeu imagem
                (esse foi o que o Tesseract de fato leu), confere que a copia
                existe, e so entao diz onde esta. #>
            $pngGuardado = Join-Path $pastaSaida ("falha_" + $carimbo + "_bloco_" + $num.ToString("0000") + ".png")
            $pngOrigem = if ($pngUtilPrimeiro -ne "" -and (Test-Path -LiteralPath $pngUtilPrimeiro)) { $pngUtilPrimeiro } else { $pngSaida }
            $salvouPng = $false
            if ($pngOrigem -ne "" -and (Test-Path -LiteralPath $pngOrigem)) {
                try { Copy-Item -LiteralPath $pngOrigem -Destination $pngGuardado -Force -ErrorAction Stop; $salvouPng = $true } catch { }
            }
            <#  v1.23: recusa COM confirmacao nao e o mesmo que recusa sem.
                Tres ou mais leituras independentes chegando ao texto que ja
                estava e evidencia de que a leitura esta certa e o disco e
                que escreve assim. Dizer "nao devolveu nada aproveitavel"
                nesse caso e mensagem que engana - o re-OCR devolveu a
                resposta certa, ela e que era igual a de antes.
                O corte e 3 pelo mesmo motivo do consenso: uma coincidencia
                acontece, tres leituras diferentes concordando, nao. #>
            if ($confirmacoes -ge 3) {
                [void]$script:BlocosConfirmados.Add($b.Inicio + "|" + $b.Fim)
                Diz ("    [CONFERIDO] " + $confirmacoes + " leituras chegaram ao MESMO texto que ja estava no bloco.") "Cyan"
                Diz "    O disco escreve assim mesmo - nao e erro de leitura. Bloco mantido." "DarkGray"
                continue
            }
            if ($salvouPng) {
                Diz ("    [!] re-OCR nao devolveu nada aproveitavel - bloco mantido como estava. Imagem salva em: " + $pngGuardado) "Yellow"
            } else {
                Diz "    [!] re-OCR nao devolveu nada aproveitavel - bloco mantido como estava. Nao houve imagem para salvar (nenhum instante rendeu tira)." "Yellow"
            }
            continue
        }

        <#  v1.24: O RE-OCR ESTAVA CRIANDO BLOCO QUEBRADO - E BLOCO QUEBRADO
            PERDE FALA.
            Achado no Se7en de 27/08, bloco 1083 (01:26:32,978):
                -tem que passar por você, não tem?
                <LINHA EM BRANCO>
                -Isso.
            Linha em branco DENTRO de um bloco e o separador de blocos do
            formato .srt: o leitor corta ali e a fala "-Isso." simplesmente
            nao existe para o player. E exatamente o defeito que o
            Corretor_Legenda conta em "Consertei N bloco(s) com o FORMATO
            quebrado - sem esse conserto essas falas seriam PERDIDAS".
            So que o Corretor roda ANTES do Reocr. Ninguem passa depois.
            Vinha do PSM 12, que devolveu as duas falas separadas por uma
            linha vazia, e a trava de aceite so olhava o CONTEUDO (palavras
            existem? consenso bateu?), nunca o FORMATO.
            A limpeza e obrigatoria e nao tem excecao: nenhum bloco de .srt
            valido tem linha vazia no meio. #>
        $linhasNovas = @($novoTexto -split "`n" | ForEach-Object { $_.TrimEnd() } | Where-Object { $_.Trim() -ne "" })
        if ($linhasNovas.Count -eq 0) {
            Diz "    [!] a leitura nova ficou so com linha(s) em branco - bloco mantido como estava." "Yellow"
            continue
        }
        $novoTexto = ($linhasNovas -join "`n")

        Diz ("    -> '" + ($novoTexto -replace "`n"," / ") + "'") "Green"
        $trocas.Add((New-Object PSObject -Property ([ordered]@{
            Bloco = $b; TextoAntigo = $b.Texto; TextoNovo = $novoTexto
        })))
    }

    Titulo "RESUMO"
    if ($script:HouveTiraPreta) {
        Diz "[!] EM PELO MENOS UM INSTANTE A TIRA SAIU VAZIA - a imagem extraida" "Yellow"
        Diz "    nao tinha nenhuma legenda desenhada. Isso sozinho NAO e defeito:" "Yellow"
        Diz "    o instante amostrado pode cair no intervalo entre duas falas, e" "Yellow"
        Diz "    por isso sao tres instantes por bloco. So vira problema se os" "Yellow"
        Diz "    TRES sairem vazios no mesmo bloco." "Yellow"
        Diz "    Se isso acontecer, abra o PNG salvo em _reocr\ e olhe: se a" "Yellow"
        Diz "    legenda estiver la, me mande o arquivo - a checagem errou." "Yellow"
        Diz ""
    }
    Diz ("Blocos suspeitos processados : " + $suspeitos.Count)
    Diz ("Aceitos (passaram na trava)  : " + $trocas.Count)
    $recCru = $suspeitos.Count - $trocas.Count
    if ($recCru -lt 0) { $recCru = 0 }
    Diz ("Recusados (bloco intacto)    : " + $recCru)
    <#  1.28: RECUSADO NAO E SINONIMO DE DEFEITO, e o relatorio nao dizia
        isso. No Homem-Aranha de 28/08 esta linha imprimia "Recusados: 4" e
        oito linhas abaixo a nota dizia "2 com defeito conhecido". Os dois
        numeros estao certos - recusado e o que o re-OCR nao trocou, e disso
        2 eram CONFERIDOS (tres leituras independentes chegaram no mesmo
        texto que ja estava la: o disco escreve assim) e 1 era bloco vazio,
        que conta na categoria mais grave. Mas quem le ve dois numeros
        diferentes para a mesma coisa e conclui que um deles mente.
        Agora a linha se explica onde ela aparece. #>
    if ($recCru -gt 0) {
        $confRes = 0
        if ($null -ne $script:BlocosConfirmados) { $confRes = @($script:BlocosConfirmados).Count }
        if ($confRes -gt $recCru) { $confRes = $recCru }
        $chavesTr = @{}
        foreach ($tr in $trocas) { $chavesTr[$tr.Bloco.Inicio + "|" + $tr.Bloco.Fim] = $true }
        $vazRes = 0
        foreach ($sp in $suspeitos) {
            $ch = $sp.Inicio + "|" + $sp.Fim
            if ($chavesTr.ContainsKey($ch)) { continue }
            if ($null -ne $script:BlocosConfirmados -and $script:BlocosConfirmados.Contains($ch)) { continue }
            if ([string]::IsNullOrWhiteSpace($sp.Texto)) { $vazRes++ }
        }
        $sobra = $recCru - $confRes - $vazRes
        if ($sobra -lt 0) { $sobra = 0 }
        if ($confRes -gt 0 -or $vazRes -gt 0) {
            Diz "   recusado NAO e o mesmo que defeito - destes:" "DarkGray"
            if ($confRes -gt 0) { Diz ("   . {0} CONFERIDO(S) - o re-OCR leu igual ao que ja estava: o disco escreve assim, nao e erro" -f $confRes) "DarkGray" }
            if ($vazRes  -gt 0) { Diz ("   . {0} sem texto nenhum - contam na categoria de fala perdida, mais grave" -f $vazRes) "DarkGray" }
            Diz ("   . {0} ilegivel(is) de verdade - e este numero que entra na nota" -f $sobra) "DarkGray"
        }
    }

    <#  $dicionario, nao $dic: a chamada usava um nome que NAO EXISTE neste
    script, entao o parametro chegava $null e a contagem de palavras fora
    do dicionario nunca rodava - a linha simplesmente sumia do relatorio,
    sem erro. Visto na rodada de 26/08 09h13: dicionario com 1.296.508
    palavras carregado no cabecalho e zero palavras contadas em 1904
    blocos, o que e impossivel. #>
    Write-NotaDaLegenda -Blocos $blocos -Suspeitos $suspeitos -Trocas $trocas -Dicionario $dicionario

    if ($trocas.Count -eq 0) {
        Diz "" ; Diz "Nenhuma troca aproveitavel - nao gerei srt novo." "Yellow"
    } else {
        $mapaTrocas = @{}
        foreach ($tr in $trocas) { $mapaTrocas[$tr.Bloco.Inicio + "|" + $tr.Bloco.Fim] = $tr.TextoNovo }

        $sb = New-Object System.Text.StringBuilder
        $idx = 0
        foreach ($b in $blocos) {
            $idx++
            [void]$sb.AppendLine($idx)
            [void]$sb.AppendLine($b.Inicio + " --> " + $b.Fim)
            $chave = $b.Inicio + "|" + $b.Fim
            <#  1.27: BLOCO VAZIO GERAVA DUAS LINHAS EM BRANCO.
                AppendLine de texto vazio ja escreve uma linha em branco e a
                separadora abaixo escrevia a segunda - duas linhas em branco
                seguidas, que e a quebra de formato que o Corretor existe
                para consertar. Este arquivo e o que entra no .mkv: e o
                ultimo lugar do mundo onde podia sair torto. O Reocr conta
                os blocos vazios em $vazios, entao ele sabe que eles existem.
                Identico ao conserto do Corretor 2.25 - os dois gravam .srt
                pelo mesmo molde e tinham o mesmo defeito. #>
            $txtBloco = ""
            if ($mapaTrocas.ContainsKey($chave)) { $txtBloco = [string]$mapaTrocas[$chave] }
            else { $txtBloco = [string]$b.Texto }
            if (-not [string]::IsNullOrWhiteSpace($txtBloco)) { [void]$sb.AppendLine($txtBloco) }
            [void]$sb.AppendLine("")
        }

        $nomeBase = [System.IO.Path]::GetFileNameWithoutExtension($Srt)
        $srtSaida = Join-Path $pastaSaida ($nomeBase + "_REOCR.srt")
        $utf8Bom = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($srtSaida, $sb.ToString(), $utf8Bom)
        Diz ""
        Diz ("SRT CORRIGIDO: " + $srtSaida) "Green"
        Diz "IMPORTANTE: confira as trocas abaixo antes de usar este arquivo -" "Yellow"
        Diz "re-OCR tambem pode errar, isso NAO e garantia de 100% de acerto." "Yellow"
        Diz ""
        Diz "--- todas as trocas feitas ---" "Cyan"
        foreach ($tr in $trocas) {
            Diz ("  [" + $tr.Bloco.Inicio + "]") "White"
            Diz ("    ANTES : '" + ($tr.TextoAntigo -replace "`n"," / ") + "'") "DarkGray"
            Diz ("    DEPOIS: '" + ($tr.TextoNovo -replace "`n"," / ") + "'") "Green"
        }
    }

    # v1.11: a limpeza estava DENTRO do try, depois de cinco "exit 1". Erro
    # fatal ou saida antecipada deixava a pasta com todos os PNGs e .txt (sao
    # 3 PNGs + 4 escalados + ate 20 .txt POR bloco suspeito). Agora ela e
    # marcada aqui e apagada no finally, que sempre roda.
    $script:PastaTempParaApagar = $pastaTemp
    Remove-Item -LiteralPath $pastaTemp -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "Concluido." -ForegroundColor Green

} catch {
    Diz ""
    Diz "=============== ERRO FATAL ===============" "Red"
    Diz ("Mensagem : " + $_.Exception.Message) "Red"
    Diz ("Onde     : " + $_.InvocationInfo.ScriptLineNumber + " -> " + $_.InvocationInfo.Line.Trim()) "Red"
    Diz ($_.ScriptStackTrace) "DarkRed"
} finally {
    # v1.0.1: BUG CORRIGIDO - o relatorio so era gravado no FINAL do try, bem
    # depois de varios "exit 1" (tesseract/ffmpeg/mkv/srt faltando, faixa nao
    # detectada) e do catch de erro fatal - todos esses caminhos saiam sem
    # deixar rastro nenhum em disco, so o que aparecia na tela (que se
    # fechasse, sumia). Gravar aqui no finally cobre TODOS os jeitos do
    # script terminar - normal, exit antecipado, ou excecao.
    try {
        if ($script:Relatorio -and $script:Relatorio.Count -gt 0) {
            $pastaRel = if ($pastaSaida) { $pastaSaida } else { (Get-Location).Path }
            if (-not (Test-Path -LiteralPath $pastaRel)) { New-Item -ItemType Directory -Path $pastaRel -Force | Out-Null }
            $carimboRel = if ($carimbo) { $carimbo } else { Get-Date -Format "yyyy-MM-dd_HHmmss" }
            $relatorioSaida = Join-Path $pastaRel ("relatorio_reocr_" + $carimboRel + ".txt")
            $utf8Bom2 = New-Object System.Text.UTF8Encoding($true)
            [System.IO.File]::WriteAllText($relatorioSaida, ($script:Relatorio -join "`r`n"), $utf8Bom2)
            Write-Host ""
            Write-Host ("RELATORIO: " + $relatorioSaida) -ForegroundColor Green
        }
    } catch { }
    if (-not $SemPausa) { Write-Host ""; Read-Host "Pressione ENTER para fechar" | Out-Null }
}
