<#
================================================================================
 LaFirma - Auditor de OCR de Legenda
 Versao 1.1.10 (o valor efetivo esta em $VersaoAuditor, mais abaixo)
 --------------------------------------------------------------------------
 v1.1.10 - palavra com menos de 4 letras nao e mais perguntada ao
           dicionario de 1,3M. 'tor', 'inf' e 'tol' existem la dentro, entao
           o auditor declarava a familia 'INF TOL' como palavra valida e a
           descartava antes de qualquer regra - cego justo no que ele cacava.
           Abaixo de 4 letras vale so a lista pequena de reforco.
 v1.1.9 - so acabamento, nenhuma regra de deteccao mudou:
   * o cabecalho aqui dizia "Versao 1.1" enquanto o $VersaoAuditor ja
     estava em 1.1.8. Mesmo tipo de defasagem que o motor tinha (cabecalho
     em 13.8 com $SCRIPT_VERSION em 14.4) - so confunde na hora de conferir
     o que esta instalado.
   * Test-PalavraValida: a lista de reforco ($ComunsPtBr) e escrita SEM
     acento ('nao', 'voce', 'tambem'), mas a consulta e feita COM acento.
     Ou seja: quando o dicionario grande nao estava disponivel, a lista de
     reforco nao reconhecia UMA palavra acentuada sequer - justo no caminho
     em que ela e a unica defesa contra falso positivo. Agora, e SO contra
     essa lista pequena, tambem tenta a forma sem acento.
     O dicionario grande continua sendo consultado COM acento de proposito:
     e assim que o auditor percebe acento comido pelo OCR ("coracao" no
     lugar de "coração"), que e erro de verdade e tem que ser reportado.
 --------------------------------------------------------------------------
 NAO altera nenhum arquivo do projeto. So LE.
 Faz tres coisas numa passada:
   (A) SONDA  - abre o Converter_AUTO_DIRETO.ps1 e mostra, verbatim, como o
                motor chama o PgsToSrt/Tesseract; lista tools\PgsToSrt\ e os
                .traineddata com tamanho e MD5; confere o runtime .NET 8.
   (B) AUDITORIA POR ESTATISTICA - le um .srt (ou extrai as legendas de
                texto de um .mkv) e varre procurando erro de OCR usando
                estrutura/timing, padroes impossiveis em portugues, e
                vocabulario do proprio arquivo contra um dicionario real de
                50 mil palavras (Auditor_OCR.dic.gz, ao lado deste script).
   (C) AUDITORIA POR REFERENCIA (novo na v1.1, MAIS CONFIAVEL QUE B) - se
                voce tiver uma legenda de referencia do mesmo filme/episodio
                (baixada manualmente, outro release), passa ela como segundo
                argumento e o auditor compara direto, bloco por bloco casado
                por TEMPO (nao por indice - releases diferentes cortam fala
                diferente). Testado contra Spider-Man: Far From Home: achou
                16 erros reais confirmados, incluindo 6 blocos que o OCR
                tinha silenciosamente esvaziado - nenhum deles tinha
                aparecido no metodo B.

 Saida: pasta _auditoria_ocr\ ao lado deste script
          relatorio_ocr_<data>_<hora>.txt   (leitura humana)
          achados_ocr_<data>_<hora>.csv     (planilha)

 USO:
   Auditor_OCR.bat                                  (interativo, pergunta tudo)
   Auditor_OCR.bat "legenda.srt"                    (so metodo B)
   Auditor_OCR.bat "nossa.srt" "referencia.srt"      (metodo B + C)
   Auditor_OCR.bat -SoSonda                         (so a sonda, sem auditar)

 ENCODING DESTE ARQUIVO: UTF-8 COM BOM + CRLF.
 (proposital: o PowerShell 5.1 le .ps1 SEM BOM como ANSI e quebraria todo
  acento das listas de palavras e das regex de portugues aqui dentro)
================================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Alvo = "",
    [Parameter(Position = 1)]
    [string]$Referencia = "",
    [switch]$SoSonda,
    [switch]$SemPausa
)

$ErrorActionPreference = "Continue"
$VersaoAuditor = "1.1.10"

# ------------------------------------------------------------------ estado
$script:Relatorio = New-Object System.Collections.Generic.List[string]
$script:Achados   = New-Object System.Collections.Generic.List[object]

function Diz {
    param([string]$Texto = "", [string]$Cor = "Gray")
    Write-Host $Texto -ForegroundColor $Cor
    $script:Relatorio.Add($Texto)
}

function Titulo {
    param([string]$Texto)
    Diz ""
    Diz ("=" * 78) "DarkCyan"
    Diz $Texto "Cyan"
    Diz ("=" * 78) "DarkCyan"
}

function Achado {
    param(
        [string]$Arquivo,
        [int]$Bloco,
        [string]$Tempo,
        [string]$Peso,      # ALTA / MEDIA / BAIXA
        [string]$Tipo,
        [string]$Trecho,
        [string]$Sugestao = ""
    )
    $o = New-Object PSObject -Property ([ordered]@{
        Arquivo  = $Arquivo
        Bloco    = $Bloco
        Tempo    = $Tempo
        Peso     = $Peso
        Tipo     = $Tipo
        Trecho   = $Trecho
        Sugestao = $Sugestao
    })
    $script:Achados.Add($o)
}

# --------------------------------------------------------- utilidades base

function Get-PastaScript {
    if ($PSScriptRoot -and $PSScriptRoot.Trim() -ne "") { return $PSScriptRoot }
    if ($MyInvocation.MyCommand.Path) { return (Split-Path -Parent $MyInvocation.MyCommand.Path) }
    return (Get-Location).Path
}

function Achar-Ferramenta {
    param([string]$Nome, [string]$Raiz)
    $tentativas = @(
        (Join-Path $Raiz ("tools\" + $Nome + ".exe")),
        (Join-Path $Raiz ($Nome + ".exe")),
        (Join-Path "C:\LaFirma" ("tools\" + $Nome + ".exe"))
    )
    foreach ($t in $tentativas) {
        if (Test-Path -LiteralPath $t) { return $t }
    }
    $cmd = Get-Command $Nome -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Ler-TextoComEncoding {
    # devolve hashtable: Texto, Encoding, Aviso
    param([string]$Caminho)

    $bytes = [System.IO.File]::ReadAllBytes($Caminho)
    $enc   = "UTF-8 (sem BOM, presumido)"
    $aviso = ""

    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $enc = "UTF-8 com BOM"
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        $enc = "UTF-16 LE"
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        $enc = "UTF-16 BE"
    }

    # tenta UTF-8 estrito
    $utf8Estrito = New-Object System.Text.UTF8Encoding($false, $true)
    $texto = $null
    try {
        $texto = $utf8Estrito.GetString($bytes)
        if ($enc -like "UTF-8*") { $enc = $enc }
    } catch {
        $texto = $null
    }

    if ($null -eq $texto) {
        # nao e UTF-8 valido -> quase certo Windows-1252 (legenda antiga)
        $texto = [System.Text.Encoding]::GetEncoding(1252).GetString($bytes)
        $enc   = "Windows-1252 / ANSI"
        $aviso = "arquivo NAO e UTF-8 valido - foi lido como ANSI"
    } else {
        if ($enc -eq "UTF-16 LE") { $texto = [System.Text.Encoding]::Unicode.GetString($bytes) }
        if ($enc -eq "UTF-16 BE") { $texto = [System.Text.Encoding]::BigEndianUnicode.GetString($bytes) }
    }

    # tira BOM se sobrou
    if ($texto.Length -gt 0 -and [int]$texto[0] -eq 0xFEFF) { $texto = $texto.Substring(1) }

    return @{ Texto = $texto; Encoding = $enc; Aviso = $aviso }
}

function Converter-TempoParaMs {
    param([string]$T)
    $m = [regex]::Match($T, '^\s*(\d+):(\d{2}):(\d{2})[,\.](\d{1,3})\s*$')
    if (-not $m.Success) { return -1 }
    $h  = [int]$m.Groups[1].Value
    $mi = [int]$m.Groups[2].Value
    $s  = [int]$m.Groups[3].Value
    $ms = [int]($m.Groups[4].Value.PadRight(3, '0'))
    return (((($h * 60) + $mi) * 60 + $s) * 1000 + $ms)
}

function Test-Distancia1 {
    param([string]$A, [string]$B)
    $la = $A.Length
    $lb = $B.Length
    $d  = $la - $lb
    if ($d -gt 1 -or $d -lt -1) { return $false }

    if ($la -eq $lb) {
        $dif = 0
        for ($i = 0; $i -lt $la; $i++) {
            if ($A[$i] -ne $B[$i]) {
                $dif++
                if ($dif -gt 1) { return $false }
            }
        }
        return ($dif -eq 1)
    }

    if ($la -gt $lb) { $lon = $A; $cur = $B } else { $lon = $B; $cur = $A }
    $i = 0; $j = 0; $pulou = $false
    while ($i -lt $lon.Length -and $j -lt $cur.Length) {
        if ($lon[$i] -ne $cur[$j]) {
            if ($pulou) { return $false }
            $pulou = $true
            $i++
        } else {
            $i++; $j++
        }
    }
    return $true
}

function Get-SemAcento {
    param([string]$P)
    $s  = $P.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($c in $s.ToCharArray()) {
        $cat = [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($c)
        if ($cat -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($c) }
    }
    return $sb.ToString()
}

function Get-EsqueletoOcr {
    # colapsa tudo que o Tesseract costuma trocar entre si
    param([string]$P)
    $s = (Get-SemAcento $P).ToLowerInvariant()
    # primeiro os pares de DOIS caracteres (o Tesseract funde/parte glifos)
    $s = $s -replace 'rn', 'm'
    $s = $s -replace 'cl', 'd'
    $s = $s -replace 'vv', 'w'
    $s = $s -replace 'li', 'u'
    $s = $s -replace 'ii', 'u'
    $s = $s -replace 'ri', 'n'
    $s = $s -replace 'lj', 'y'
    # depois os de um caractere so
    $s = $s -replace '[l1\|!i]', 'i'
    $s = $s -replace '[0o]', 'o'
    $s = $s -replace '[5s]', 's'
    $s = $s -replace '[8b]', 'b'
    $s = $s -replace '[9g]', 'g'
    $s = $s -replace '[2z]', 'z'
    $s = $s -replace '[6b]', 'b'
    return $s
}

# ---------------------------------------------------- vocabulario de apoio
# v1.1: era uma lista curta de ~250 palavras, so pra ancorar distancia de
# edicao. Rodando contra um SRT real de 90min (Spider-Man: Far From Home,
# 1674 blocos) ela deixava passar palavras legitimas raras (teoria, seria,
# flor, arte, honra, tocar, sentir, voar...) que so nao apareciam muitas
# vezes NAQUELE arquivo - mas sao portugues correto. Resultado medido: 239
# "achados" de vocabulario, e ao conferir um por um contra a legenda real,
# quase todos eram falsos positivos.
#
# Trocado por um dicionario de verdade: as 50.000 palavras mais frequentes
# do portugues do Brasil (fonte: hermitdave/FrequencyWords, corpus de
# legendas). Vem comprimido em Auditor_OCR.dic.gz, ao lado deste script -
# 199 KB no disco, ~430 KB depois de descomprimido. Com o dicionario real,
# o mesmo teste caiu de 239 achados pra 4 (e nenhum desses 4 restantes era
# erro de verdade tambem - eram nomes/girias legitimas raras no arquivo).
# Se o arquivo .dic.gz nao estiver presente, o auditor AVISA e segue sem
# esse filtro (mais falso positivo, mas nao trava).
function Get-DicionarioPtBr {
    param([string]$Raiz)
    $candidatos = @(
        (Join-Path $Raiz "Auditor_OCR.dic.gz"),
        "C:\LaFirma\Auditor_OCR.dic.gz"
    )
    $caminho = $null
    foreach ($c in $candidatos) { if (Test-Path -LiteralPath $c) { $caminho = $c; break } }
    if (-not $caminho) { return $null }
    try {
        $bytesGz = [System.IO.File]::ReadAllBytes($caminho)
        $msIn  = New-Object System.IO.MemoryStream(,$bytesGz)
        $gz    = New-Object System.IO.Compression.GZipStream($msIn, [System.IO.Compression.CompressionMode]::Decompress)
        $msOut = New-Object System.IO.MemoryStream
        $gz.CopyTo($msOut)
        $gz.Dispose()
        $texto = [System.Text.Encoding]::UTF8.GetString($msOut.ToArray())
        $set = New-Object 'System.Collections.Generic.HashSet[string]'
        foreach ($linha in ($texto -split "`n")) {
            $p = $linha.Trim()
            if ($p -ne "") { [void]$set.Add($p) }
        }
        return $set
    } catch {
        return $null
    }
}
$script:Dicionario = $null   # populado no programa principal, antes de auditar

# Lista pequena continua existindo, agora so como REFORCO pra quando o
# dicionario grande nao estiver disponivel (script:Dicionario = $null).
$script:ComunsPtBr = @(
    'a','o','as','os','um','uma','uns','umas','de','do','da','dos','das','em','no','na','nos','nas',
    'por','para','pra','pro','com','sem','sob','sobre','ate','entre','desde','apos','contra',
    'e','ou','mas','porem','porque','pois','que','se','como','quando','onde','quem','qual','quais',
    'nao','sim','ja','ainda','sempre','nunca','tambem','so','mesmo','muito','pouco','mais','menos',
    'bem','mal','aqui','ali','la','ca','agora','depois','antes','hoje','ontem','amanha','entao',
    'eu','tu','voce','voces','ele','ela','eles','elas','nos','vos','me','te','se','lhe','lhes',
    'meu','minha','teu','tua','seu','sua','nosso','nossa','dele','dela','deles','delas',
    'este','esta','isto','esse','essa','isso','aquele','aquela','aquilo','tudo','todo','toda','todos','todas',
    'nada','algo','alguem','ninguem','cada','outro','outra','outros','outras','qualquer',
    'ser','estar','ter','haver','fazer','poder','querer','dizer','ir','vir','ver','dar','saber','ficar',
    'sou','es','somos','sao','era','eram','foi','fomos','foram','sera','seria','seja','sendo','sido',
    'esta','estao','estava','estavam','esteve','estive','estar','estou','estamos',
    'tem','tenho','temos','tinha','tinham','teve','tive','tera','tenha',
    'vai','vou','vamos','vao','foi','ia','iam','indo',
    'faz','faco','fazemos','fazem','fez','fazia','farei','fara',
    'pode','posso','podemos','podem','podia','pude','podera',
    'quero','quer','queremos','querem','queria','quis',
    'diz','digo','dizemos','dizem','disse','dizia','disseram',
    've','vejo','vemos','veem','viu','via','vi',
    'sei','sabe','sabemos','sabem','sabia','soube',
    'certo','certa','claro','clara','verdade','mentira','coisa','coisas','vez','vezes','hora','horas',
    'dia','dias','noite','noites','ano','anos','tempo','vida','morte','casa','lugar','mundo','gente',
    'homem','mulher','pai','mae','filho','filha','irmao','irma','amigo','amiga','pessoa','pessoas',
    'deus','senhor','senhora','obrigado','obrigada','favor','desculpa','desculpe','licenca',
    'ok','ei','oi','ola','tchau','ate','logo','espera','calma','vamos','vem','va','venha','olha','olhe',
    'melhor','pior','grande','pequeno','novo','velho','bom','boa','ruim','forte','fraco',
    'aconteceu','acontecer','precisa','preciso','precisamos','deve','devia','devemos',
    'acho','acha','achamos','acham','achei','pensa','penso','pensei','entendo','entende','entendi',
    'ajuda','ajudar','falar','falo','fala','falou','conversar','ouvir','escutar','esperar',
    'talvez','quase','apenas','realmente','exatamente','simplesmente','provavelmente','felizmente',
    'pais','paises','cidade','rua','porta','carro','dinheiro','trabalho','problema','problemas',
    'nome','filme','historia','caso','razao','motivo','ideia','plano','jeito','forma','parte','fim'
)
$script:ComunsSet = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($w in $script:ComunsPtBr) { [void]$script:ComunsSet.Add($w) }

function Test-PalavraValida {
    # $true quando a palavra E conhecida - pelo dicionario grande (se
    # carregado) OU pela lista pequena de reforco. Usado pra NAO acusar
    # palavras raras-mas-legitimas (teoria, honra, flor...) como erro de OCR.
    param([string]$P)
    $p2 = $P.ToLowerInvariant()
    <#  1.1.10: PALAVRA CURTA NAO SE PERGUNTA AO DICIONARIO DE 1,3M.
        Era a regra da casa em todo lugar menos aqui - e aqui era o lugar
        mais ironico de todos: o auditor existe para achar exatamente a
        familia 'INF TOL', e 'tor', 'inf' e 'tol' EXISTEM no dicionario
        grande (ele carrega sigla e abreviacao de todo idioma). Resultado:
        o auditor declarava esse lixo 'palavra valida' e o descartava antes
        de qualquer regra de raridade. Cego justo no que ele cacava.
        Abaixo de 4 letras vale a lista pequena de reforco, e so ela. #>
    if ($p2.Length -ge 4 -and $script:Dicionario -and $script:Dicionario.Contains($p2)) { return $true }
    if ($script:ComunsSet.Contains($p2)) { return $true }
    # v1.1.9: a lista de reforco e escrita sem acento ('nao','voce','ate'),
    # entao contra ELA - e so contra ela - vale tentar a forma sem acento.
    # Sem isso, no caminho em que o dicionario grande falta, a lista pequena
    # nao reconhecia nenhuma palavra acentuada e tudo virava suspeito.
    $p3 = (Get-SemAcento $p2).ToLowerInvariant()
    if ($p3 -ne $p2 -and $script:ComunsSet.Contains($p3)) { return $true }
    return $false
}

# ------------------------------------------------------------- parse do srt

function Parse-Srt {
    param([string]$Texto)

    $t = $Texto -replace "`r`n", "`n" -replace "`r", "`n"
    $linhas = $t -split "`n"

    $blocos = New-Object System.Collections.Generic.List[object]
    $i = 0
    $n = $linhas.Count

    while ($i -lt $n) {
        # pula linhas em branco
        while ($i -lt $n -and $linhas[$i].Trim() -eq "") { $i++ }
        if ($i -ge $n) { break }

        $linhaArq = $i + 1
        $indice   = $null

        if ($linhas[$i] -notmatch '-->') {
            $cand = $linhas[$i].Trim()
            if ($cand -match '^\d+$') { $indice = [int]$cand }
            $i++
        }
        if ($i -ge $n) { break }

        $timing = $linhas[$i]
        $ini = ""; $fim = ""
        $mt = [regex]::Match($timing, '(\d+:\d{2}:\d{2}[,\.]\d{1,3})\s*-->\s*(\d+:\d{2}:\d{2}[,\.]\d{1,3})')
        if ($mt.Success) {
            $ini = $mt.Groups[1].Value
            $fim = $mt.Groups[2].Value
            $i++
        } else {
            # linha de timing quebrada - registra e segue
            $i++
        }

        $corpo = New-Object System.Collections.Generic.List[string]
        while ($i -lt $n -and $linhas[$i].Trim() -ne "") {
            $corpo.Add($linhas[$i])
            $i++
        }

        $blocos.Add((New-Object PSObject -Property ([ordered]@{
            Indice   = $indice
            Inicio   = $ini
            Fim      = $fim
            IniMs    = (Converter-TempoParaMs $ini)
            FimMs    = (Converter-TempoParaMs $fim)
            Linhas   = $corpo.ToArray()
            Texto    = ($corpo -join "`n")
            LinhaArq = $linhaArq
            TimingOk = $mt.Success
        })))
    }
    return $blocos
}

function Limpar-Tags {
    param([string]$T)
    $s = $T -replace '<[^>]{1,20}>', ''
    $s = $s -replace '\{\\[^}]*\}', ''
    return $s
}

# --------------------------------------------------------- auditoria: estrutura

function Auditar-Estrutura {
    param($Blocos, [string]$NomeArq)

    $anteriorFim = -1
    $esperado    = 0

    foreach ($b in $Blocos) {
        $esperado++
        $tempo = if ($b.Inicio) { $b.Inicio } else { ("linha " + $b.LinhaArq) }

        if (-not $b.TimingOk) {
            Achado $NomeArq $esperado $tempo "ALTA" "TIMING ILEGIVEL" `
                ("linha " + $b.LinhaArq + " do arquivo - nao achei o '-->'") ""
            continue
        }
        if ($null -eq $b.Indice) {
            Achado $NomeArq $esperado $tempo "BAIXA" "SEM NUMERO DE BLOCO" "bloco sem a linha de indice" ""
        } elseif ($b.Indice -ne $esperado) {
            Achado $NomeArq $esperado $tempo "MEDIA" "NUMERACAO FORA DE ORDEM" `
                ("esperado " + $esperado + ", veio " + $b.Indice) ""
        }
        if ($b.FimMs -le $b.IniMs) {
            Achado $NomeArq $esperado $tempo "ALTA" "FIM ANTES DO INICIO" ($b.Inicio + " --> " + $b.Fim) ""
        }
        if ($anteriorFim -ge 0 -and $b.IniMs -lt $anteriorFim) {
            Achado $NomeArq $esperado $tempo "MEDIA" "SOBREPOSICAO COM O BLOCO ANTERIOR" `
                ("comeca " + ($anteriorFim - $b.IniMs) + " ms antes do anterior acabar") ""
        }
        $dur = $b.FimMs - $b.IniMs
        if ($dur -gt 0 -and $dur -lt 250) {
            Achado $NomeArq $esperado $tempo "MEDIA" "BLOCO RAPIDO DEMAIS" ($dur.ToString() + " ms") ""
        }
        if ($dur -gt 12000) {
            Achado $NomeArq $esperado $tempo "BAIXA" "BLOCO LONGO DEMAIS" ([math]::Round($dur/1000,1).ToString() + " s") ""
        }
        $limpo = (Limpar-Tags $b.Texto).Trim()
        if ($limpo -eq "") {
            Achado $NomeArq $esperado $tempo "ALTA" "BLOCO VAZIO" "sem texto nenhum" ""
        } else {
            # v1.1: bloco cujo conteudo inteiro (tirando pontuacao) e UMA
            # letra minuscula, e essa letra nao e nenhuma das 3 que sao
            # palavra de verdade em portugues (a, e, o). Regra estreita de
            # proposito - deliberadamente NAO pega blocos de 2+ caracteres
            # (tipo "Ai.", "Tá.", "MJ!", "Vi.") pra nao voltar a gerar o
            # tipo de falso positivo que a v1.0 gerava. Mesmo assim, achou
            # de verdade os 6 blocos "s" isolados do Spider-Man: Far From
            # Home, confirmados contra legenda de referencia - os 6 eram
            # falas reais que comecavam com "É" maiusculo isolado.
            # v1.1.1: BUG CORRIGIDO - a limpeza tirava DIGITO junto com
            # pontuacao, entao '"4h"?' (fala real, alguem repetindo "4h" de
            # pergunta) virava so "h" depois de limpo e disparava a regra a
            # toa. Confirmado contra a legenda de referencia: a linha existe
            # de verdade no filme. Agora so tira pontuacao/aspas/espaco -
            # digito conta como conteudo, igual letra.
            $soConteudo = ($limpo -replace '[^\p{L}\p{N}]', '')
            if ($soConteudo.Length -eq 1 -and $soConteudo -notmatch '(?i)^[aeo]$') {
                Achado $NomeArq $esperado $tempo "ALTA" "BLOCO SUSPEITO (uma letra so)" `
                    ("'" + $limpo + "'") "conteudo implausivel pra uma fala inteira - provavel falha silenciosa do OCR"
            }
            if ($dur -gt 0) {
                $cps = [math]::Round(($limpo.Length / ($dur / 1000.0)), 1)
                if ($cps -gt 30) {
                    Achado $NomeArq $esperado $tempo "MEDIA" "CPS ALTO" ($cps.ToString() + " car/s") "timing ou juncao de blocos"
                }
            }
            if ($b.Linhas.Count -gt 3) {
                Achado $NomeArq $esperado $tempo "BAIXA" "MAIS DE 3 LINHAS" ($b.Linhas.Count.ToString() + " linhas") ""
            }
        }
        $anteriorFim = $b.FimMs
    }
}

# ------------------------------------------------- auditoria: padroes de OCR

function Auditar-Padroes {
    param($Blocos, [string]$NomeArq)

    # par de vogais com a MESMA base onde pelo menos uma tem acento -> nao
    # existe em portugues. E o caso classico "paiis" / "paíís".
    $rxVogalDupla = '(?i)(áa|aá|áá|àa|aà|ãa|aã|âa|aâ|ée|eé|éé|êe|eê|íi|ií|íí|óo|oó|óó|ôo|oô|õo|oõ|úu|uú|úú)'
    $rxTriplaIgual = '(?i)([a-zçáéíóúâêôãõà])\1\1'
    # sem (?i) de proposito: sigla toda em MAIUSCULA (NYPD, PSDB, R2D2) e
    # legitima e nao pode virar achado
    $rxDigitoNoMeio = '\b[a-zçáéíóúâêôãõà]+[0-9]+[a-zçáéíóúâêôãõà]+\b'
    $rxMaiusMeio = '\b[a-zçáéíóúâêôãõà]{2,}[A-ZÇÁÉÍÓÚÂÊÔÃÕÀ][a-zçáéíóúâêôãõà]*\b'
    $rxLixo = '[\|\\{}_~¢£§¥¤©®µ¶¦¬]'
    $rxSemVogal = '\b[bcdfghjklmnpqrstvwxyzç]{4,}\b'
    $rxEspacoAntesPont = '(?i)[a-zçáéíóúâêôãõ]\s+[,;:!?]'
    $rxColadoDepoisVirg = '(?i)[,;:][a-zçáéíóúâêôãõ]'
    $rxMojibake = '(Ã[©£µ§¡³ºª\u00AD]|Ã‡|Ãƒ|â€œ|â€™|â€\u009D|Â[°ª º])'

    $regras = @(
        @{ Rx = $rxVogalDupla;       Peso = "ALTA";  Tipo = "VOGAL ACENTUADA DUPLICADA"; Dica = "classico do OCR (ex: pais -> paiis)" },
        @{ Rx = $rxTriplaIgual;      Peso = "ALTA";  Tipo = "LETRA TRIPLICADA";          Dica = "nao existe em portugues" },
        @{ Rx = $rxDigitoNoMeio;     Peso = "ALTA";  Tipo = "DIGITO DENTRO DE PALAVRA";  Dica = "1 lido no lugar de l/i, 0 no lugar de o" },
        @{ Rx = $rxSemVogal;         Peso = "ALTA";  Tipo = "PALAVRA SEM VOGAL";         Dica = "quase sempre lixo de OCR" },
        @{ Rx = $rxLixo;             Peso = "ALTA";  Tipo = "CARACTERE ESTRANHO";        Dica = "caractere que legenda PT nao usa" },
        @{ Rx = $rxMojibake;         Peso = "ALTA";  Tipo = "ENCODING QUEBRADO";         Dica = "NAO e erro de OCR - e o arquivo gravado no encoding errado" },
        @{ Rx = $rxMaiusMeio;        Peso = "MEDIA"; Tipo = "MAIUSCULA NO MEIO";         Dica = "I/l trocados" },
        @{ Rx = $rxEspacoAntesPont;  Peso = "BAIXA"; Tipo = "ESPACO ANTES DA PONTUACAO"; Dica = "segmentacao da imagem" },
        @{ Rx = $rxColadoDepoisVirg; Peso = "BAIXA"; Tipo = "SEM ESPACO APOS PONTUACAO"; Dica = "segmentacao da imagem" }
    )

    $num = 0
    foreach ($b in $Blocos) {
        $num++
        $txt = Limpar-Tags $b.Texto
        if ($txt.Trim() -eq "") { continue }
        $tempo = if ($b.Inicio) { $b.Inicio } else { ("linha " + $b.LinhaArq) }

        foreach ($r in $regras) {
            $ms = [regex]::Matches($txt, $r.Rx)
            # v1.1.7: falso positivo real achado - "Romanée-Conti" (vinho
            # frances de verdade, nome proprio) batia na regra de vogal
            # duplicada por causa do "ée" legitimo em frances. Palavra
            # comecando com maiuscula e bem mais provavel de ser nome
            # proprio estrangeiro do que erro de OCR - filtra so pra essa
            # regra especifica, sem mudar as outras.
            if ($r.Tipo -eq "VOGAL ACENTUADA DUPLICADA" -and $ms.Count -gt 0) {
                $ms = @($ms | Where-Object {
                    $ini = $_.Index
                    while ($ini -gt 0 -and $txt[$ini - 1] -match '[\p{L}]') { $ini-- }
                    -not ($txt[$ini] -cmatch '[A-ZÁÉÍÓÚÂÊÔÃÕÀÇ]')
                })
            }
            if ($ms.Count -gt 0) {
                $amostras = @()
                foreach ($m in $ms) {
                    $ini = [math]::Max(0, $m.Index - 12)
                    $len = [math]::Min($txt.Length - $ini, $m.Length + 24)
                    $amostras += ("..." + ($txt.Substring($ini, $len) -replace "`n", " / ") + "...")
                    if ($amostras.Count -ge 3) { break }
                }
                Achado $NomeArq $num $tempo $r.Peso $r.Tipo (($amostras | Select-Object -Unique) -join " | ") $r.Dica
            }
        }

        # letra solta 'l' como palavra (I maiusculo vira l minusculo no OCR)
        if ([regex]::IsMatch($txt, '(?<![\w])l(?![\w])')) {
            Achado $NomeArq $num $tempo "MEDIA" "LETRA 'l' SOLTA" ($txt -replace "`n"," / ") "sobra de I/1"
        }
    }
}

# --------------------------------------- auditoria: vocabulario do proprio srt

function Auditar-Vocabulario {
    param($Blocos, [string]$NomeArq)

    $freq = @{}
    $onde = @{}
    $num  = 0
    $rxTok = '[\p{L}\p{M}]+(?:[''\u2019\-][\p{L}\p{M}]+)*'

    foreach ($b in $Blocos) {
        $num++
        $txt = Limpar-Tags $b.Texto
        $marca = $b.Inicio
        if (-not $marca) { $marca = "linha " + $b.LinhaArq }
        foreach ($m in [regex]::Matches($txt, $rxTok)) {
            $p = $m.Value.ToLowerInvariant()
            if ($p.Length -lt 3) { continue }
            if ($freq.ContainsKey($p)) {
                $freq[$p] = $freq[$p] + 1
            } else {
                $freq[$p] = 1
                $onde[$p] = @{ Bloco = $num; Tempo = $marca }
            }
        }
    }

    $frequentes = @()
    foreach ($k in $freq.Keys) { if ($freq[$k] -ge 3) { $frequentes += $k } }

    # indexa frequentes por esqueleto e por comprimento
    $porEsqueleto = @{}
    foreach ($f in $frequentes) {
        $e = Get-EsqueletoOcr $f
        if (-not $porEsqueleto.ContainsKey($e)) { $porEsqueleto[$e] = @() }
        $porEsqueleto[$e] += $f
    }

    # topo de frequencia: as 60 palavras mais repetidas do proprio arquivo,
    # exigindo 8+ ocorrencias. Ancora segura para a passada de 2 letras.
    $topo = @()
    foreach ($k in ($freq.Keys | Sort-Object -Property @{ Expression = { $freq[$_] } } -Descending)) {
        if ($freq[$k] -lt 8) { break }
        if ($k.Length -lt 3) { continue }
        $topo += $k
        if ($topo.Count -ge 60) { break }
    }

    $raras = @()
    foreach ($k in $freq.Keys) { if ($freq[$k] -le 2) { $raras += $k } }

    foreach ($r in $raras) {
        # v1.1: se a palavra rara e uma palavra de verdade do portugues
        # (dicionario de 50k ou a lista pequena de reforco), ela NAO e
        # candidata a erro de OCR - e so uma palavra pouco repetida NESTE
        # arquivo especifico (nome proprio, giria, termo tecnico, sinonimo).
        # Medido no SRT real do Spider-Man: Far From Home (1674 blocos) -
        # sem este filtro, 239 achados de vocabulario; com ele, 4. E nenhum
        # desses 4 restantes era erro de verdade tambem (eram "blipa",
        # "misterio" dentro de uma citacao em italiano, "calei" e
        # "bem-vindos" - todas palavras corretas, so raras no dicionario ou
        # fora dele). Sem este filtro a ferramenta praticamente so gera
        # ruido em texto corrido de verdade.
        if (Test-PalavraValida $r) { continue }

        $tempo = $onde[$r].Tempo
        $bl    = $onde[$r].Bloco
        $resolvido = $false

        # 1) mesmo esqueleto de OCR que uma palavra frequente
        $eR = Get-EsqueletoOcr $r
        if ($porEsqueleto.ContainsKey($eR)) {
            foreach ($cand in $porEsqueleto[$eR]) {
                if ($cand -ne $r) {
                    Achado $NomeArq $bl $tempo "ALTA" "PALAVRA RARA x FREQUENTE (mesmo desenho)" `
                        ("'" + $r + "' aparece " + $freq[$r] + "x") `
                        ("provavel '" + $cand + "' (aparece " + $freq[$cand] + "x)")
                    $resolvido = $true
                    break
                }
            }
        }
        if ($resolvido) { continue }

        # 2) distancia 1 de uma palavra frequente do proprio arquivo
        foreach ($f in $frequentes) {
            if ([math]::Abs($f.Length - $r.Length) -gt 1) { continue }
            if ($freq[$f] -lt (3 * [math]::Max(1, $freq[$r]))) { continue }
            if (Test-Distancia1 $r $f) {
                Achado $NomeArq $bl $tempo "ALTA" "PALAVRA RARA x FREQUENTE (1 letra)" `
                    ("'" + $r + "' aparece " + $freq[$r] + "x") `
                    ("provavel '" + $f + "' (aparece " + $freq[$f] + "x)")
                $resolvido = $true
                break
            }
        }
        if ($resolvido) { continue }

        # 3) distancia 1 de uma palavra comum do portugues
        $rSemAcento = (Get-SemAcento $r).ToLowerInvariant()
        if ($script:ComunsSet.Contains($rSemAcento)) { continue }
        foreach ($c in $script:ComunsPtBr) {
            if ([math]::Abs($c.Length - $rSemAcento.Length) -gt 1) { continue }
            if (Test-Distancia1 $rSemAcento $c) {
                Achado $NomeArq $bl $tempo "MEDIA" "PARECIDA COM PALAVRA COMUM" `
                    ("'" + $r + "' aparece " + $freq[$r] + "x") ("provavel '" + $c + "'")
                $resolvido = $true
                break
            }
        }
        if ($resolvido) { continue }

        # 4) esqueleto de OCR a UMA letra de distancia de uma palavra do topo
        #    de frequencia. Pega 'qLie' -> 'que', que escapa das outras tres.
        #    Medido: 1,9% de falso positivo (o Levenshtein 2 puro dava 17,9%).
        if ($r.Length -ge 3) {
            foreach ($t in $topo) {
                if ($t -eq $r) { continue }
                if (Test-Distancia1 $eR (Get-EsqueletoOcr $t)) {
                    Achado $NomeArq $bl $tempo "MEDIA" "PARECIDA COM PALAVRA MUITO FREQUENTE" `
                        ("'" + $r + "' aparece " + $freq[$r] + "x") `
                        ("provavel '" + $t + "' (aparece " + $freq[$t] + "x)")
                    break
                }
            }
        }
    }

    return @{ Total = ($freq.Values | Measure-Object -Sum).Sum; Unicas = $freq.Count; Frequentes = $frequentes.Count }
}

# --------------------------------------- auditoria: comparacao com referencia
# v1.1: o metodo mais confiavel de todos. Em vez de adivinhar por estatistica
# de palavra, compara direto contra uma legenda de referencia (baixada pelo
# usuario - outro release, outra fonte) do MESMO filme/episodio.
#
# NAO casa por numero de bloco: releases diferentes cortam/juntam fala de
# jeito diferente, entao os indices desalinham (medido: um desalinhamento de
# 1 bloco em algum ponto do meio faz TODOS os indices daquele ponto em diante
# apontarem pra fala errada - gera falso positivo em cascata). Em vez disso,
# casa por TEMPO: pra cada bloco nosso, acha o bloco da referencia cujo
# INICIO fica mais perto (tolerancia de 4s pra cobrir diferenca de sync entre
# releases). So compara quando os dois textos, depois de normalizados
# (minusculo, sem tag <i>, sem pontuacao), sao DIFERENTES.
#
# Testado contra Spider-Man: Far From Home (1674 blocos, referencia
# BDRip-SPARKS): achou 16 blocos genuinamente divergentes - os 6 "s"
# isolados (todos eram falas comecando com "É"), 3 blocos de lixo tipo
# "INFETOR" (todos eram falas comecando com "Não"), e 7 erros pontuais de
# 1-2 letras. Nenhum desses 16 tinha aparecido nos achados de vocabulario,
# nem depois do filtro de dicionario - confirma que isto e mais confiavel
# que estatistica quando ha uma referencia disponivel.
function Normalizar-TextoComparacao {
    param([string]$T)
    $s = Limpar-Tags $T
    $s = $s.ToLowerInvariant()
    $s = $s -replace '[^\p{L}\p{M}\s]', ''
    $s = $s -replace '\s+', ' '
    return $s.Trim()
}

function Auditar-ComparandoReferencia {
    param($Blocos, [string]$NomeArq, [string]$CaminhoReferencia)

    if (-not (Test-Path -LiteralPath $CaminhoReferencia)) {
        Diz ("[!] Referencia nao encontrada: " + $CaminhoReferencia) "Yellow"
        return @{ Comparados = 0; Divergentes = 0 }
    }

    $lidoRef = Ler-TextoComEncoding $CaminhoReferencia
    Diz ("Referencia   : " + (Split-Path -Leaf $CaminhoReferencia) + "  [" + $lidoRef.Encoding + "]")
    $blocosRef = @(Parse-Srt $lidoRef.Texto | Where-Object { $_.TimingOk -and $_.IniMs -ge 0 } | Sort-Object IniMs)
    Diz ("Blocos na referencia: " + $blocosRef.Count)
    if ($blocosRef.Count -eq 0) {
        Diz "[!] a referencia nao tem nenhum bloco valido - abortando comparacao." "Yellow"
        return @{ Comparados = 0; Divergentes = 0 }
    }

    $iniciosRef = @($blocosRef | ForEach-Object { $_.IniMs })
    $TOLERANCIA_MS = 4000

    $comparados = 0
    $divergentes = 0

    foreach ($b in $Blocos) {
        if (-not $b.TimingOk) { continue }
        $tempo = $b.Inicio

        # busca binaria simples pelo bloco de referencia mais proximo em tempo
        # v1.1.6: BUG CORRIGIDO - a linha antiga (@($lo - 1, $lo, $lo + 1) |
        # Where-Object {...}) quebrava em producao com "System.Object[] nao
        # contem 'op_Subtraction'", ou seja $lo virava array em vez de
        # numero em algum caso real que eu nao reproduzi aqui. Reescrito de
        # forma totalmente explicita, com [int] forcado em cada variavel e
        # sem o padrao @(...) | Where-Object numa linha so, que e onde o
        # PowerShell 5.1 parecia estar ambiguo.
        [int]$lo = 0
        [int]$hi = $iniciosRef.Count - 1
        [int]$melhorIdx = -1
        while ($lo -le $hi) {
            [int]$mid = [math]::Floor(($lo + $hi) / 2)
            if ($iniciosRef[$mid] -lt $b.IniMs) { [int]$lo = $mid + 1 } else { [int]$hi = $mid - 1 }
        }
        $candidatosIdx = New-Object System.Collections.Generic.List[int]
        foreach ($desloc in 0, -1, 1) {
            [int]$ci = $lo + $desloc
            if ($ci -ge 0 -and $ci -lt $blocosRef.Count) { $candidatosIdx.Add($ci) }
        }
        $melhorDelta = [double]::MaxValue
        foreach ($ci in $candidatosIdx) {
            $delta = [math]::Abs([double]$blocosRef[$ci].IniMs - [double]$b.IniMs)
            if ($delta -lt $melhorDelta) { $melhorDelta = $delta; $melhorIdx = $ci }
        }
        if ($melhorIdx -lt 0 -or $melhorDelta -gt $TOLERANCIA_MS) { continue }

        $comparados++
        $refBloco = $blocosRef[$melhorIdx]
        $nossoNorm = Normalizar-TextoComparacao $b.Texto
        $refNorm   = Normalizar-TextoComparacao $refBloco.Texto
        if ($nossoNorm -eq $refNorm) { continue }
        if ($nossoNorm -eq "" -and $refNorm -eq "") { continue }

        $divergentes++
        $nossoLimpo = (Limpar-Tags $b.Texto) -replace "`n", " / "
        $refLimpo   = (Limpar-Tags $refBloco.Texto) -replace "`n", " / "

        # v1.1.8: caso real achado no Troy 2004 - "TRÓIA" (nosso) vs "TROIA"
        # (referencia) se repetia DEZENAS de vezes, inflando "DIVERGE DA
        # REFERENCIA" com o que NAO e erro de OCR nenhum: e a diferenca
        # entre a grafia de ANTES do Acordo Ortografico de 1990 ("Tróia",
        # "heróico" - com acento) e a de DEPOIS ("Troia", "heroico" - sem).
        # O disco original as vezes usa a grafia antiga, a referencia baixada
        # usa a nova - nosso OCR esta lendo CERTO o que esta na imagem. Se a
        # unica diferenca entre as duas linhas e acento (tudo igual sem
        # diacritico), rebaixa pra BAIXA em vez de ALTA - ainda aparece pra
        # conferir, mas para de disfarcar de erro grave o que provavelmente
        # e so uma norma ortografica diferente.
        $nossoSemAcento = (Get-SemAcento $nossoNorm).ToLowerInvariant()
        $refSemAcento   = (Get-SemAcento $refNorm).ToLowerInvariant()
        if ($nossoSemAcento -eq $refSemAcento) {
            Achado $NomeArq 0 $tempo "BAIXA" "DIVERGE DA REFERENCIA (so acento)" `
                ("NOSSO: '" + $nossoLimpo.Trim() + "'") `
                ("REF: '" + $refLimpo.Trim() + "' - provavel diferenca de norma ortografica (Acordo de 1990), nao necessariamente erro de OCR")
            continue
        }

        Achado $NomeArq 0 $tempo "ALTA" "DIVERGE DA REFERENCIA" `
            ("NOSSO: '" + $nossoLimpo.Trim() + "'") `
            ("REF: '" + $refLimpo.Trim() + "'")
    }

    return @{ Comparados = $comparados; Divergentes = $divergentes }
}

function Split-CaminhosArrastados {
    # v1.1.1: o Windows, ao arrastar VARIOS arquivos pro console de uma vez,
    # cola os caminhos entre aspas - mas o separador entre eles varia (as
    # vezes espaco, as vezes nada). ".Trim('"')" sozinho so tira UMA aspa de
    # cada ponta da string inteira, entao "arq1.srt" "arq2.mkv" vira lixo:
    # arq1.srt" "arq2.mkv (sobra aspa e espaco no meio) - e no caso real que
    # achou isto, sem espaco nenhum entre os dois, ainda pior:
    #   "...srt""...mkv"
    # Esta funcao usa regex pra puxar cada trecho ENTRE aspas como um
    # caminho separado. Se nao tiver aspa nenhuma (arraste de 1 arquivo so,
    # ou caminho digitado a mao), devolve a string inteira aparada como
    # unico item - comportamento identico ao de antes pra esse caso.
    param([string]$Bruto)
    $t = $Bruto.Trim()
    if ($t -eq "") { return @() }
    $ms = [regex]::Matches($t, '"([^"]+)"')
    if ($ms.Count -gt 0) {
        return @($ms | ForEach-Object { $_.Groups[1].Value.Trim() } | Where-Object { $_ -ne "" })
    }
    return @($t.Trim('"'))
}

# ------------------------------------------------------------------- sonda

function Sondar-Ambiente {
    param([string]$Raiz)

    Titulo "SONDA - COMO O MOTOR CHAMA O OCR (nada e alterado)"

    $motor = $null
    foreach ($p in @((Join-Path $Raiz "Converter_AUTO_DIRETO.ps1"), "C:\LaFirma\Converter_AUTO_DIRETO.ps1")) {
        if (Test-Path -LiteralPath $p) { $motor = $p; break }
    }

    if (-not $motor) {
        Diz "[!] Converter_AUTO_DIRETO.ps1 nao encontrado nem aqui nem em C:\LaFirma." "Yellow"
    } else {
        Diz ("Motor: " + $motor)
        $linhas = [System.IO.File]::ReadAllLines($motor, (New-Object System.Text.UTF8Encoding($false)))
        Diz ("Linhas do motor: " + $linhas.Count)
        Diz ""
        Diz "--- linhas que mencionam PgsToSrt / tesseract / tessdata / traineddata / .sup ---"
        $achou = 0
        for ($i = 0; $i -lt $linhas.Count; $i++) {
            if ($linhas[$i] -match '(?i)(PgsToSrt|tesseract|tessdata|traineddata|\.sup|pgs)') {
                $achou++
                if ($achou -le 120) {
                    Diz ("  " + ($i + 1).ToString().PadLeft(5) + " | " + $linhas[$i].TrimEnd())
                }
            }
        }
        if ($achou -eq 0) { Diz "  (nenhuma linha bateu - o OCR pode estar em outro arquivo)" "Yellow" }
        elseif ($achou -gt 120) { Diz ("  ... e mais " + ($achou - 120) + " linha(s). Total: " + $achou) "DarkGray" }
        else { Diz ("  total: " + $achou + " linha(s)") "DarkGray" }
    }

    Diz ""
    Diz "--- conteudo de tools\PgsToSrt\ ---"
    $pgsDir = $null
    foreach ($p in @((Join-Path $Raiz "tools\PgsToSrt"), "C:\LaFirma\tools\PgsToSrt")) {
        if (Test-Path -LiteralPath $p) { $pgsDir = $p; break }
    }
    if (-not $pgsDir) {
        Diz "[!] pasta tools\PgsToSrt nao encontrada." "Yellow"
    } else {
        Diz ("Pasta: " + $pgsDir)
        Get-ChildItem -LiteralPath $pgsDir -Recurse -File -ErrorAction SilentlyContinue |
            Sort-Object FullName | ForEach-Object {
                $rel = $_.FullName.Substring($pgsDir.Length).TrimStart('\')
                $kb  = [math]::Round($_.Length / 1KB, 1)
                $ln  = "  " + $rel.PadRight(52) + $kb.ToString().PadLeft(10) + " KB"
                if ($_.Extension -eq ".traineddata") {
                    $md5 = (Get-FileHash -LiteralPath $_.FullName -Algorithm MD5).Hash
                    $ln += "  MD5 " + $md5
                }
                Diz $ln
            }
    }

    Diz ""
    Diz "--- runtime .NET (PgsToSrt precisa do 8) ---"
    $dot = "C:\Program Files\dotnet\shared\Microsoft.NETCore.App"
    $dotW = "C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App"
    foreach ($d in @($dot, $dotW)) {
        if (Test-Path -LiteralPath $d) {
            $vers = (Get-ChildItem -LiteralPath $d -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) -join ", "
            Diz ("  " + (Split-Path -Leaf $d) + ": " + $vers)
        } else {
            Diz ("  " + (Split-Path -Leaf $d) + ": NAO INSTALADO") "Yellow"
        }
    }
}

# ------------------------------------------------- extrair legendas de um mkv

function Extrair-LegendasDoMkv {
    param([string]$Mkv, [string]$Destino, [string]$Raiz)

    $ffprobe = Achar-Ferramenta "ffprobe" $Raiz
    $ffmpeg  = Achar-Ferramenta "ffmpeg"  $Raiz
    if (-not $ffprobe -or -not $ffmpeg) {
        Diz "[!] ffprobe/ffmpeg nao encontrados em tools\ nem no PATH." "Yellow"
        return @()
    }
    Diz ("ffprobe: " + $ffprobe)
    Diz ("ffmpeg : " + $ffmpeg)

    $saidaProbe = & $ffprobe '-v' 'error' '-select_streams' 's' '-show_entries' 'stream=index,codec_name:stream_tags=language,title' '-of' 'csv=p=0' '-i' $Mkv 2>&1
    if (-not $saidaProbe) {
        Diz "[!] nenhuma faixa de legenda encontrada nesse .mkv." "Yellow"
        return @()
    }

    # v1.1.7: BUG CORRIGIDO - antes extraia TODAS as faixas de texto do mkv
    # (ingles incluso), e como o motor sempre mantem uma faixa em ingles
    # completa junto da PT-BR, isso gerava 2 arquivos numa unica rodada -
    # disparando a trava de "referencia so serve pra 1 video" e cancelando
    # a comparacao inteira. Caso real: Troy, onde os 82 achados eram quase
    # todos sobre a faixa em INGLES por engano, e a comparacao com a
    # referencia (que era so da parte em portugues) nunca rodou. Agora
    # filtra pra so as faixas por/pt/pob - a unica coisa que esta
    # ferramenta audita de verdade. Se nao achar nenhuma nesse idioma,
    # cai pro comportamento antigo (extrai tudo) so pra nao ficar cego.
    $linhasPor = @(@($saidaProbe) | Where-Object {
        $c = ("$_".Trim() -split ',')
        $c.Count -ge 3 -and $c[2].Trim() -match '(?i)^(por|pt|pob)$'
    })
    $linhasUsar = if ($linhasPor.Count -gt 0) { $linhasPor } else { @($saidaProbe) }
    if ($linhasPor.Count -eq 0) {
        Diz "[!] nenhuma faixa marcada como por/pt/pob - extraindo TODAS as faixas de texto (sem filtro de idioma) pra nao ficar sem nada." "Yellow"
    }

    $gerados = @()
    $baseNome = [System.IO.Path]::GetFileNameWithoutExtension($Mkv)

    foreach ($linha in $linhasUsar) {
        $l = "$linha".Trim()
        if ($l -eq "") { continue }
        $campos = $l -split ','
        if ($campos.Count -lt 2) { continue }
        $idx   = $campos[0]
        $codec = $campos[1]
        $lang  = if ($campos.Count -ge 3) { $campos[2] } else { "und" }

        if ($codec -match '(?i)pgs|dvd_subtitle|dvb') {
            Diz ("  faixa " + $idx + " (" + $codec + ", " + $lang + ") - e IMAGEM, ffmpeg nao converte em texto. Pulada.") "DarkYellow"
            continue
        }

        $nomeSaida = Join-Path $Destino ($baseNome + ".faixa" + $idx + "." + $lang + ".srt")
        & $ffmpeg '-v' 'error' '-y' '-i' $Mkv '-map' ("0:" + $idx) '-c:s' 'srt' $nomeSaida 2>&1 | Out-Null
        if (Test-Path -LiteralPath $nomeSaida) {
            $kb = [math]::Round((Get-Item -LiteralPath $nomeSaida).Length / 1KB, 1)
            Diz ("  faixa " + $idx + " (" + $codec + ", " + $lang + ") -> " + (Split-Path -Leaf $nomeSaida) + "  " + $kb + " KB") "Green"
            $gerados += $nomeSaida
        } else {
            Diz ("  faixa " + $idx + " (" + $codec + ", " + $lang + ") -> FALHOU") "Yellow"
        }
    }
    return $gerados
}

# =============================================================== programa

try {
    $raiz = Get-PastaScript
    $carimbo = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $pastaSaida = Join-Path $raiz "_auditoria_ocr"
    if (-not (Test-Path -LiteralPath $pastaSaida)) {
        New-Item -ItemType Directory -Path $pastaSaida -Force | Out-Null
    }

    Titulo ("LaFirma - AUDITOR DE OCR DE LEGENDA  v" + $VersaoAuditor)
    Diz ("Data      : " + (Get-Date -Format "dd/MM/yyyy HH:mm:ss"))
    Diz ("Pasta     : " + $raiz)
    Diz ("PowerShell: " + $PSVersionTable.PSVersion)
    Diz ("Saida     : " + $pastaSaida)

    Sondar-Ambiente $raiz

    $script:Dicionario = Get-DicionarioPtBr $raiz
    if ($script:Dicionario) {
        Diz ("Dicionario PT-BR: " + $script:Dicionario.Count + " palavras carregadas (Auditor_OCR.dic.gz)") "DarkGray"
    } else {
        Diz "[!] Auditor_OCR.dic.gz nao encontrado - o filtro de vocabulario vai usar so a lista pequena de reforco (mais falso positivo)." "Yellow"
    }

    if (-not $SoSonda) {

        if ($Alvo -eq "") {
            # v1.1.4: TRES tentativas de consertar o Read-Host (timing, retry,
            # flush de buffer) e nenhuma resolveu - continuava vindo so "C",
            # na hora, sem digitar nada. Isso sobrou pra alem de qualquer
            # teoria de teclado/buffer que eu consiga testar as cegas.
            # Solucao definitiva: parar de usar o console pra escolher
            # arquivo. Janela nativa do Windows (OpenFileDialog) nao passa
            # pelo Read-Host, pelo PSReadLine nem por simulacao de tecla
            # nenhuma - e clique de mouse puro.
            #
            # v1.1.5: BUG CORRIGIDO - a v1.1.4 tentava selecionar os 2
            # arquivos (nosso + referencia) numa UNICA janela com Ctrl+clique.
            # O OpenFileDialog do Windows so deixa selecionar varios arquivos
            # DA MESMA PASTA de uma vez - e o caso real e a referencia quase
            # sempre estar em outro lugar (Desktop, Downloads) enquanto o
            # nosso .mkv esta em 01_Arquivos_Finalizados. Agora sao DUAS
            # janelas em sequencia, cada uma podendo ser em pasta diferente -
            # a 2a e claramente opcional (Cancelar pula ela).
            $Alvo = ""
            $Referencia = ""
            try {
                Add-Type -AssemblyName System.Windows.Forms
                [void][System.Windows.Forms.Application]::EnableVisualStyles()

                $dlg1 = New-Object System.Windows.Forms.OpenFileDialog
                $dlg1.Title = "LaFirma Auditor - PASSO 1/2: selecione o SEU arquivo (.mkv ou .srt que o motor gerou)"
                $dlg1.Filter = "Video ou legenda (*.mkv;*.srt;*.ass;*.ssa;*.vtt)|*.mkv;*.srt;*.ass;*.ssa;*.vtt|Todos os arquivos (*.*)|*.*"
                $dlg1.Multiselect = $false
                $dlg1.InitialDirectory = $raiz
                $dlg1.CheckFileExists = $true
                $r1 = $dlg1.ShowDialog()

                if ($r1 -eq [System.Windows.Forms.DialogResult]::OK) {
                    $Alvo = $dlg1.FileName
                    Diz ""
                    Diz ("ALVO selecionado: " + $Alvo) "DarkGray"

                    $dlg2 = New-Object System.Windows.Forms.OpenFileDialog
                    $dlg2.Title = "LaFirma Auditor - PASSO 2/2 (OPCIONAL): legenda de REFERENCIA - Cancelar pula e segue so com estatistica"
                    $dlg2.Filter = "Legenda (*.srt;*.ass;*.ssa;*.vtt)|*.srt;*.ass;*.ssa;*.vtt|Todos os arquivos (*.*)|*.*"
                    $dlg2.Multiselect = $false
                    # comeca na pasta do arquivo que acabou de escolher, mas o
                    # usuario pode navegar pra qualquer lugar (Desktop, etc)
                    try { $dlg2.InitialDirectory = (Split-Path -Parent $Alvo) } catch { $dlg2.InitialDirectory = $raiz }
                    $dlg2.CheckFileExists = $true
                    $r2 = $dlg2.ShowDialog()
                    if ($r2 -eq [System.Windows.Forms.DialogResult]::OK) {
                        $Referencia = $dlg2.FileName
                        Diz ("REFERENCIA selecionada: " + $Referencia) "DarkGray"
                    } else {
                        Diz "Sem referencia - seguindo so com a estatistica." "DarkGray"
                    }
                } else {
                    Diz ""
                    Diz "Nenhum arquivo selecionado - seguindo so com a sonda acima." "DarkGray"
                }
            } catch {
                # Fallback se Windows Forms nao estiver disponivel (raro,
                # servidor sem GUI por exemplo) - volta ao texto, mas SEM os
                # prompts que geraram o problema: aceita so digitacao/colagem
                # manual, sem retry automatico (que so mascarava o sintoma).
                Diz ""
                Diz ("[!] Nao consegui abrir a janela de selecao (" + $_.Exception.Message + ")") "Yellow"
                Diz "Digite ou COLE (botao direito do mouse, nao Ctrl+V) o caminho completo:" "White"
                $Alvo = Read-Host "Alvo"
                $itensAlvo = Split-CaminhosArrastados $Alvo
                $Alvo = if ($itensAlvo.Count -gt 0) { $itensAlvo[0] } else { "" }
            }
        }


        $srts = @()

        if ($Alvo -ne "" -and (Test-Path -LiteralPath $Alvo)) {
            $item = Get-Item -LiteralPath $Alvo

            if ($item.PSIsContainer) {
                Titulo ("PASTA: " + $item.FullName)
                # v1.1.1: separado em dois - solto (ja estava na pasta, quase
                # sempre a referencia que voce baixou) e extraido (saiu do
                # .mkv agora). Se sobrar exatamente 1 de cada e voce nao
                # informou -Referencia, pareia os dois sozinho - poupa o
                # passo de dar os dois caminhos na mao. Caso real que motivou
                # isto: voce colocou o .srt de referencia e o .mkv convertido
                # na MESMA pasta e arrastou a pasta - antes disso, os dois
                # eram auditados cada um sozinho, sem comparar entre si.
                $srtsSoltos = @(Get-ChildItem -LiteralPath $item.FullName -Filter *.srt -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
                $srtsExtraidos = @()
                foreach ($mkv in (Get-ChildItem -LiteralPath $item.FullName -Filter *.mkv -File -ErrorAction SilentlyContinue)) {
                    Diz ("Extraindo legendas de: " + $mkv.Name)
                    $srtsExtraidos += (Extrair-LegendasDoMkv $mkv.FullName $pastaSaida $raiz)
                }
                if ($srtsSoltos.Count -eq 1 -and $srtsExtraidos.Count -eq 1 -and $Referencia -eq "") {
                    $Referencia = $srtsSoltos[0]
                    $srts += $srtsExtraidos[0]
                    Diz ""
                    Diz "Achei 1 .srt solto na pasta + 1 extraido do .mkv - tratando o solto" "Cyan"
                    Diz "como REFERENCIA automaticamente (o mais comum: voce baixou ele pra" "Cyan"
                    Diz "comparar com o que o motor gerou)." "Cyan"
                    Diz ("  REFERENCIA: " + $Referencia) "DarkGray"
                    Diz ("  AUDITANDO : " + $srtsExtraidos[0]) "DarkGray"
                } else {
                    $srts += $srtsSoltos
                    $srts += $srtsExtraidos
                }
            }
            elseif ($item.Extension -match '(?i)^\.mkv$') {
                Titulo ("EXTRAINDO LEGENDAS DE: " + $item.Name)
                $srts += (Extrair-LegendasDoMkv $item.FullName $pastaSaida $raiz)
            }
            elseif ($item.Extension -match '(?i)^\.(srt|ass|ssa|vtt)$') {
                $srts += $item.FullName
            }
            else {
                Diz ("[!] nao sei auditar '" + $item.Extension + "'. Use .srt, .mkv ou uma pasta.") "Yellow"
            }
        }
        elseif ($Alvo -ne "") {
            Diz ("[!] caminho nao existe: " + $Alvo) "Yellow"
        }

        $srts = @($srts | Select-Object -Unique)


        foreach ($s in $srts) {
            $nome = Split-Path -Leaf $s
            Titulo ("AUDITANDO: " + $nome)

            $lido = Ler-TextoComEncoding $s
            Diz ("Encoding detectado: " + $lido.Encoding)
            if ($lido.Aviso -ne "") { Diz ("[!] " + $lido.Aviso) "Yellow" }
            if ($lido.Texto -match "\uFFFD") {
                Diz "[!] o arquivo tem caractere de substituicao (losango com ?) - encoding perdido, NAO e erro de OCR." "Yellow"
                Achado $nome 0 "-" "ALTA" "ENCODING PERDIDO" "caractere U+FFFD presente no arquivo" "regravar o srt em UTF-8"
            }

            $blocos = Parse-Srt $lido.Texto
            Diz ("Blocos de legenda: " + $blocos.Count)
            if ($blocos.Count -eq 0) { Diz "[!] nenhum bloco reconhecido - o arquivo pode nao ser .srt." "Yellow"; continue }

            $antes = $script:Achados.Count
            Auditar-Estrutura   $blocos $nome
            $depEstr = $script:Achados.Count
            Auditar-Padroes     $blocos $nome
            $depPadr = $script:Achados.Count
            $voc = Auditar-Vocabulario $blocos $nome
            $depVoc = $script:Achados.Count

            Diz ("Palavras: " + $voc.Total + " no total, " + $voc.Unicas + " diferentes, " + $voc.Frequentes + " com 3+ ocorrencias")
            Diz ""
            Diz ("  estrutura / timing : " + ($depEstr - $antes)   + " achado(s)")
            Diz ("  padroes de OCR     : " + ($depPadr - $depEstr) + " achado(s)")
            Diz ("  vocabulario        : " + ($depVoc - $depPadr)  + " achado(s)")

            if ($Referencia -ne "") {
                if ($srts.Count -gt 1) {
                    if ($s -eq $srts[0]) {
                        Diz ""
                        Diz ("[!] -Referencia informada mas ha " + $srts.Count + " arquivo(s) nesta rodada - a mesma referencia so faz sentido pra UM video. Comparacao pulada; audite este video sozinho se quiser usar a referencia.") "Yellow"
                    }
                } else {
                    Diz ""
                    Diz "--- comparando com a legenda de referencia (metodo mais confiavel) ---" "Cyan"
                    $comp = Auditar-ComparandoReferencia $blocos $nome $Referencia
                    $depRef = $script:Achados.Count
                    Diz ("Blocos comparados por tempo (tolerancia 4s): " + $comp.Comparados)
                    Diz ("  divergentes da referencia : " + ($depRef - $depVoc) + " achado(s)")
                }
            }
        }

        # ---------------------------------------------------------- resumo
        Titulo "RESUMO"
        $altas  = @($script:Achados | Where-Object { $_.Peso -eq "ALTA"  })
        $medias = @($script:Achados | Where-Object { $_.Peso -eq "MEDIA" })
        $baixas = @($script:Achados | Where-Object { $_.Peso -eq "BAIXA" })

        Diz ("Arquivos auditados : " + $srts.Count)
        Diz ("Achados ALTA       : " + $altas.Count)  "Red"
        Diz ("Achados MEDIA      : " + $medias.Count) "Yellow"
        Diz ("Achados BAIXA      : " + $baixas.Count) "DarkGray"

        if ($altas.Count -gt 0) {
            Diz ""
            Diz "--- os 40 primeiros de peso ALTA ---" "Red"
            $altas | Select-Object -First 40 | ForEach-Object {
                Diz ("  [" + $_.Tempo + "] " + $_.Tipo + " :: " + $_.Trecho + $(if ($_.Sugestao) { "  ->  " + $_.Sugestao } else { "" }))
            }
        }

        Diz ""
        Diz "--- contagem por tipo ---"
        $script:Achados | Group-Object Tipo | Sort-Object Count -Descending | ForEach-Object {
            Diz ("  " + $_.Count.ToString().PadLeft(5) + "  " + $_.Name)
        }

        # ------------------------------------------------------- gravacao
        $csv = Join-Path $pastaSaida ("achados_ocr_" + $carimbo + ".csv")
        if ($script:Achados.Count -gt 0) {
            $script:Achados | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8 -Delimiter ";"
            Diz ""
            Diz ("CSV  : " + $csv) "Green"
        }
    }

    $txt = Join-Path $pastaSaida ("relatorio_ocr_" + $carimbo + ".txt")
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($txt, ($script:Relatorio -join "`r`n"), $utf8Bom)
    Write-Host ""
    Write-Host ("RELATORIO: " + $txt) -ForegroundColor Green

} catch {
    Write-Host ""
    Write-Host "=============== ERRO FATAL NO AUDITOR ===============" -ForegroundColor Red
    Write-Host ("Mensagem : " + $_.Exception.Message) -ForegroundColor Red
    Write-Host ("Onde     : " + $_.InvocationInfo.ScriptLineNumber + " -> " + $_.InvocationInfo.Line.Trim()) -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
    Write-Host "=====================================================" -ForegroundColor Red
} finally {
    if (-not $SemPausa) {
        Write-Host ""
        Read-Host "Pressione ENTER para fechar" | Out-Null
    }
}
