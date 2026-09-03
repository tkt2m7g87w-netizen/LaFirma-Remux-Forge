<#
================================================================================
 LaFirma - Corretor_Legenda.ps1
 Versao 2.27
 --------------------------------------------------------------------------
 HISTORICO (entrada nova a cada mudanca de $Versao, na MESMA edicao)
 --------------------------------------------------------------------------
  2.27  01/09/2026 - Nenhuma regra mudou. Registrada ao lado da regra 3 a
        medicao que prova por que ela PRECISA contar palavra curta: com a
        guarda de 4 letras os 8.887 blocos dos quatro filmes iriam de ~10
        para 850 suspeitos. A nota existe para ninguem 'consertar' isso de
        novo sem refazer a conta.
  2.26  28/08/2026 - REGRA A2 validava o resultado no dicionario de 1,3M
        mesmo com 2 e 3 letras. Agora usa Test-PalavraPtBr, que abaixo de 4
        letras so consulta a lista FECHADA de curtas.
        MEDIDO: 'O:i' -> 'Oi' (Se7en) continua; 'a:s'/'n:o'/'e:s' continuam
        iguais (essas estao na lista fechada tambem). O que MUDA e o lixo:
        'n:et', 't:or' e 'i:nf' viravam 'net', 'tor' e 'inf' - a regra
        FABRICAVA a familia de sigla que o re-OCR existe para cacar, com
        aval do dicionario grande. Agora ficam como estao e o re-OCR os ve.
  2.25  27/08/2026 - Tres achados de auditoria (nao de conversao):
        (a) 'fol' e 'urn' estavam na lista fechada de palavras curtas em
            portugues. Nao sao palavras: sao os proprios cacos que a lista
            existe para rejeitar - 'fol' e o 'foi' com i->l e 'urn' e o 'um'
            com m->rn. Com 'fol' declarado portugues, Get-TrocaBarraVertical
            desistia dele e 'fol' NUNCA virava 'foi'.
        (b) Test-PalavraPtBr mandava sigla curta em CAIXA ALTA para o
            dicionario de 1,3M, ao contrario do que o proprio comentario
            dela promete. INF, TOR, TOL e NET existem la dentro.
        (c) Bloco vazio saia gravado com DUAS linhas em branco, o que fazia
            a passada seguinte contar conserto de formato que nao houve e
            gravar um _CORRIGIDO.srt novo identico ao anterior.
  2.24  27/08/2026 - Regra 6B: linha inteira em caixa alta sem nenhuma
#        palavra de portugues ("NF TOR" no Spider-Man). A regra 6 so olhava
#        palavra de 4+ letras e a 3B exigia o bloco todo em caixa alta - o
#        lixo curto ao lado de fala normal caia no vao entre as duas.
#  2.23  27/08/2026 - Parametro -PularSegundaOpiniao. O motor 14.30 avisa
        quando JA rodou o seconv neste .mkv nesta rodada e recusou o
        resultado; repetir daria a mesma leitura (mesmo programa, mesma
        imagem, mesmo Latin.db) e custaria o mesmo tempo. Medido no
        Spider-Man de 26/08: 1m13s no motor + 1m12s aqui, 0 correcoes.
        Rodando na mao, sem a chave, nada muda.
  2.22  Chave -GuardarSegundaOpiniao (guarda a pasta tmp_<carimbo>\ para
        medir quanto da 2a opiniao foi aproveitavel).
  2.18  Mensagem de dicionario faltando parou de mentir sobre qual
        arquivo procurar (aceita LaFirma_PTBR_1.3M.dic.gz tambem).
  ATENCAO: ate 27/08 o cabecalho dizia "Versao 2.18" enquanto o
        $Versao dizia 2.23 - cinco versoes de diferenca, e o relatorio
        impresso usa o $Versao. Mesma armadilha que a JANELA ja tinha
        documentado: DOIS lugares com o mesmo numero sempre divergem.
        Ao subir a versao, trocar AQUI e no $Versao.
 --------------------------------------------------------------------------
 O QUE ESTE SCRIPT RESOLVE (o problema real, nao um teste)
 --------------------------------------------------------------------------
 Confirmado em 3 releases reais (Spider-Man, Troy, Game of Thrones): o
 PgsToSrt as vezes produz blocos ALIENIGENAS - nao e troca de 1 letra
 (I/l, pai/pal), e a fala inteira virando lixo sem nexo:

     "Quase."        ->  "OITEÇT"      (GoT S08E01, 00:06:41 - confirmado
                                        visualmente no player pelo usuario)
     "É, é matematica." -> "s"          (Spider-Man, 6 blocos assim)
     "Nao. Nao sou."    -> "INFETORE NE ToRSTOUR"

 CAUSA RAIZ (confirmada no codigo-fonte oficial do PgsToSrt):
 O PgsToSrt NAO expoe o parametro PSM (page segmentation mode) do
 Tesseract. Ele usa o padrao (PSM 3 = "analise automatica de pagina
 inteira"), que e projetado pra documento digitalizado, nao pra uma linha
 curta de legenda solta na tela. Em fala curta, o Tesseract se perde na
 segmentacao e devolve lixo. Nao ha flag pra corrigir isso por fora.

 A SOLUCAO (nova, baseada no que a comunidade de legendagem usa)
 --------------------------------------------------------------------------
 O Subtitle Edit tem uma CLI propria chamada "seconv" que:
   - roda OCR direto no .mkv (acha as faixas PGS sozinho)
   - tem motores ALTERNATIVOS ao Tesseract: nocr (sem dependencia externa)
     e binaryocr (comparacao de imagem - a escolha da comunidade quando o
     Tesseract falha)
   - aplica automaticamente XMLs de correcao de erro de OCR por idioma
 Docs: https://subtitleedit.github.io/subtitleedit/reference/command-line.html

 ESTE SCRIPT:
   1. Le o .srt gerado pelo motor e detecta os blocos alienigenas
      (dicionario PT-BR de 50k palavras + regras de plausibilidade)
   2. Se o seconv estiver instalado, gera uma SEGUNDA opiniao do OCR
      inteiro com um motor diferente, e usa ela SO nos blocos ruins
   3. Escreve um .srt novo do lado. NUNCA sobrescreve nada.

 NAO mexe no motor, nao mexe na instalacao, nao apaga nada.

 O QUE MUDOU NA 2.7 - achado no teste real do TROIA (1377 blocos)
 --------------------------------------------------------------------------
 O Troia provou o que o Diego tinha dito: metrica por arquivo engana. O que
 no GoT era 1 ocorrencia, no Troia foi 8.

   REGRA NOVA  enclitico  "armar-los" com acento -> "arma-los". Em portugues
               o infinitivo PERDE o 'r' antes do pronome. "ar-lo" e
               gramaticalmente impossivel: troca 100% segura, sem dicionario.
               (armar-los, queimar-lo, Comandar-los)
   REGRA NOVA  traco partido  "Pali"->"Pai", "Seli"->"Sei", "construii"->
               "construi". So apaga um 'l'/'i' ENCOSTADO em outro 'l'/'i' -
               assinatura exata do OCR partindo um traco fino em dois.
               NAO GENERALIZAR: testei apagar letra em qualquer posicao e
               virou "ecoar"->"ecoa", "arremessem"->"arremesse".
   LISTA NOVA  poluicao do dicionario. "pal" ESTA nas 50k e nao e palavra
               portuguesa - por isso "Pal" no lugar de "Pai" passou 8 vezes.
               Lista manual de propósito: existem 138 pares onde AS DUAS
               formas sao reais ("muita/multa", "saia/sala", "veia/vela",
               "piano/plano"). Regra automatica ali destroi legenda boa.

 TRES BUGS ACHADOS NO TESTE DA PROPRIA 2.7:
   1. "-ne" de texto no PowerShell IGNORA maiuscula/minuscula. O programa
      chamava a correcao, ela consertava "OS rumores"->"os rumores", e o
      "if ($corrigido -ne $b.Texto)" dava FALSO - a correcao era descartada
      em silencio. Agora e "-cne". Bug que vinha desde a 2.0.
   2. O detector de nome proprio pegava verbo: "Deixe-me", "Derrubarei",
      "Entregue-o". Agora exige a palavra aparecer capitalizada NO MEIO de
      uma frase - verbo so aparece maiusculo no comeco.
   3. A validacao da 2a opiniao nao recebia a lista de nomes, entao recusava
      substituicao boa cheia de nome proprio.

 MEDIDO: Troia 17 blocos corrigidos em 1377 | legenda boa do Troia 0 em 1377
         GoT 4 em 446 | legenda boa do GoT 0 em 448 | 51 armadilhas intactas

 O QUE MUDOU NA 2.6 (tudo medido, nada estimado)
 --------------------------------------------------------------------------
 A 2.5 fechou os erros DESTE arquivo. A 2.6 ataca os que VOLTAM em qualquer
 filme - porque 4 defeitos em 446 blocos e 0,9% aqui, mas um erro que se
 repete escala junto com o filme.

   1. l <-> i em qualquer posicao        "Sel."      -> "Sei."
   2. ordinal masculino/feminino          "1o vez"    -> "1a vez"
   3. maiuscula no meio da palavra        "MOrTrer"   -> "morrer"
   4. "E" sem acento em frase sem verbo   "E claro."  -> "E-agudo claro."

 Mais 3 BUGS achados durante o teste da propria 2.6:

   5. O dicionario guarda a palavra COM acento (7.308 entradas). O codigo
      consultava so a forma sem acento, entao "Aco" e "Perdao" passavam por
      palavra inexistente. Efeito real: "Aco valiriano." era acusado de lixo
      de OCR e ia pra fila da segunda opiniao - fala boa correndo risco.
   6. Nome proprio nao contava como palavra valida. "Seria Randyll Tarly?"
      dava "so 1 de 3 palavras existem em portugues". Em Troia, com Aquiles,
      Heitor, Priamo e Briseida em quase toda fala, isso condenaria a legenda
      inteira. Agora existe uma lista de nomes proprios do arquivo.
   7. Sem o seconv instalado, o script MORRIA com erro fatal antes mesmo de
      ler a legenda (Split-Path com string vazia). Bug que vinha desde a 2.1.

 MEDIDO NOS ARQUIVOS REAIS, ANTES DE ENTREGAR:
   legenda com defeito (GoT)  : 4 blocos mudados em 446 - os 4 conhecidos
   legenda boa (referencia)   : 0 blocos mudados em 448
   falso positivo na deteccao : 4 -> 0 na legenda boa
   teste adversarial          : 51 armadilhas (nomes de Troia e Homem-Aranha,
                                "sol/mil/vil/mal", "1o lugar", "E claro que",
                                "PERIGO", "FBI", "ONU") -> zero tocada
                                7 lixos reais -> 7 corrigidos

 ENCODING DESTE ARQUIVO: UTF-8 COM BOM + CRLF
================================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)] [string]$Mkv = "",
    [Parameter(Position = 1)] [string]$Srt = "",
    [string]$Seconv = "",
    [string]$Motor = "binaryocr",
    [switch]$SemPausa,
    <#  v2.22: -GuardarSegundaOpiniao
        A pasta tmp_<carimbo>\ com o .srt inteiro do seconv passou a ser
        apagada no finally desde a 2.15, porque ela acumulava para sempre.
        Certo para o uso normal - e cego para investigacao: sem esse arquivo
        nao da para medir QUANTO da segunda opiniao foi aproveitavel e quanto
        foi descartado a toa. Tres rodadas seguidas do Spider-Man fecharam com
        "Corrigidos pela 2a opiniao: 0" e nao havia como saber se a regra esta
        apertada demais ou se o material era mesmo ruim.
        Com esta chave a pasta fica. Sem ela, nada muda.  #>
    [switch]$GuardarSegundaOpiniao,
    <#  v2.23: -PularSegundaOpiniao
        MEDIDO no teste de 26/08 (Spider-Man): o motor chamou o seconv, ele
        voltou com 31,1% dos caracteres como '*', o motor RECUSOU e caiu pro
        PgsToSrt (1m13s). Logo em seguida, ESTE script chamou O MESMO seconv,
        no MESMO .mkv, com o MESMO Latin.db - deu os mesmos 31,1% de '*' e
        fechou com "Corrigidos pela 2a opiniao: 0" (mais 1m12s jogados fora).
        Nao e caso isolado: quando o Latin.db nao casa com a fonte do release,
        as duas chamadas SEMPRE dao o mesmo resultado - e o mesmo programa
        lendo a mesma imagem com o mesmo banco.
        Com esta chave o motor avisa "ja tentei o seconv neste arquivo e nao
        prestou" e a 2a opiniao e pulada, com o motivo escrito no relatorio.
        Rodando na mao (sem o motor) nada muda: a chave nao e passada e a 2a
        opiniao roda como sempre.  #>
    [switch]$PularSegundaOpiniao
)

$ErrorActionPreference = "Continue"
$Versao = "2.27"

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

function Get-PastaScript {
    if ($PSScriptRoot -and $PSScriptRoot.Trim() -ne "") { return $PSScriptRoot }
    return (Get-Location).Path
}

<#
      v2.9 - CACHE. Sem isto, o dicionario grande deixa o Corretor lento.
      Medido: 100.000 chamadas levavam 7,58s refazendo a normalizacao toda vez;
      com cache caem para 0,18s. 42 vezes mais rapido. Como o Corretor pergunta
      a mesma palavra varias vezes (uma por candidato de correcao), o cache
      acerta quase sempre.
      Dictionary[string,string] de proposito: o @{} do PowerShell IGNORA
      maiuscula/minuscula, e aqui "Pali" e "pali" tem que ser chaves diferentes.
#>
$script:CacheSemAcento = New-Object 'System.Collections.Generic.Dictionary[string,string]'
function Get-SemAcento {
    param([string]$P)
    $achado = ""
    if ($script:CacheSemAcento.TryGetValue($P, [ref]$achado)) { return $achado }
    $s = $P.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($c in $s.ToCharArray()) {
        if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($c) }
    }
    $r = $sb.ToString()
    if ($script:CacheSemAcento.Count -lt 200000) { $script:CacheSemAcento[$P] = $r }
    return $r
}

function Get-DicionarioPtBr {
    <#  v2.15: O DICIONARIO DE 1,3 MILHAO NUNCA ERA ABERTO POR NOME.
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
        foreach ($linha in ($texto -split "`n")) { $p = $linha.Trim(); if ($p -ne "") { [void]$set.Add($p) } }
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

<#
      v2.8 - REPARO DE ESTRUTURA. Achado no teste real do Homem-Aranha.

      O Tesseract as vezes cospe uma LINHA EM BRANCO no meio de um bloco:

          25
          00:03:41,513 --> 00:03:43,098
          s
                                <- linha em branco AQUI
          E, e-agudo matematica.

      Em .srt, linha em branco e o que separa um bloco do outro. Entao o
      bloco acaba no "s" e o "E, e matematica." vira um PEDACO ORFAO, sem
      numero e sem tempo. O Parse-Srt via um pedaco sem "-->" e JOGAVA FORA.

      Resultado medido no Homem-Aranha: 7 falas sumiram da legenda final. Nao
      e erro de letra - e dialogo faltando no filme. O Corretor entregou uma
      legenda PIOR que a crua do OCR.

      Aqui a gente conserta antes de qualquer coisa: pedaco orfao volta pro
      bloco de cima. E se o bloco de cima era so uma letra solta de lixo (o
      "s", que na verdade e um "E-agudo" que o OCR partiu), essa letra sai.
#>
function Repair-EstruturaSrt {
    param([string]$Texto)
    $script:ReparosEstrutura = 0
    $script:ReparosAcentoE = 0
    $t = $Texto -replace "`r`n", "`n" -replace "`r", "`n"
    $pedacos = [regex]::Split($t.Trim(), "`n[ `t]*`n")
    $saida = New-Object System.Collections.Generic.List[string]
    foreach ($pedaco in $pedacos) {
        $linhas = @($pedaco -split "`n")
        # bloco valido: "numero / tempo / texto"  ou ja comeca no tempo
        $ehBloco = $false
        if ($linhas.Count -ge 2 -and $linhas[0].Trim() -match '^\d+$' -and $linhas[1] -match '-->') { $ehBloco = $true }
        elseif ($linhas.Count -ge 1 -and $linhas[0] -match '-->') { $ehBloco = $true }

        if ($ehBloco -or $saida.Count -eq 0) {
            $saida.Add($pedaco)
            continue
        }
        # ORFAO: volta pro bloco anterior
        $anterior = @($saida[$saida.Count - 1] -split "`n")
        $cabecalho = New-Object System.Collections.Generic.List[string]
        $corpo     = New-Object System.Collections.Generic.List[string]
        $viuTempo  = $false
        foreach ($ln in $anterior) {
            if (-not $viuTempo) {
                $cabecalho.Add($ln)
                if ($ln -match '-->') { $viuTempo = $true }
            } else { $corpo.Add($ln) }
        }
        # letra solta de lixo no corpo (o "s") sai quando chega texto de verdade
        $tinhaLixo = $false
        <#  v2.15: ESTA GUARDA APAGAVA FALA BOA.
            Ela so protegia UMA letra, sem acento e sem pontuacao. Sumiam sem
            aviso: "E-agudo.", "A.", "O.", "Oi", "Va", "Ta", "Ah", "Ei" - e
            justamente agora que o Reocr 1.10 passou a recuperar os "E-agudo."
            perdidos, o Corretor podia estar apagando outros.
            A Regra 1 deste mesmo arquivo ja tinha aprendido a licao na 2.13:
            normalizar o acento ANTES de testar [aeo]. Aqui isso nao tinha
            sido aplicado. Agora: tira a pontuacao final, tira o acento, e so
            entao decide - e qualquer coisa com 2+ letras de verdade fica. #>
        $soLetrasCorpo = ""
        if ($corpo.Count -eq 1) {
            $limpoCorpo = $corpo[0].Trim().TrimEnd('.', ',', '!', '?', ':', ';', [char]0x2026)
            $soLetrasCorpo = (Get-SemAcento $limpoCorpo)
        }
        # Lista FECHADA de falas curtas que existem de verdade em legenda
        # portuguesa. Fechada de proposito: "aceita qualquer duas letras"
        # deixaria passar o "ln" e o "rn" que sao lixo classico de OCR.
        $curtasBoas = '^(a|e|o|ai|ui|ih|ah|eh|oh|uh|ei|oi|hm|he|ha|ue|ne|ce|po|so|ou|se|me|te|no|na|do|da|um|eu|tu|va|ta|la|ca|ja|ma|pa|vo|vi|li|ir|to|ta|ok|tv|dr|sr|si|ia|as|os|es|is|us|ah)$'
        if ($corpo.Count -eq 1 -and $corpo[0].Trim().Length -le 2 -and
            $soLetrasCorpo -notmatch ('(?i)' + $curtasBoas)) {
            $corpo.Clear()
            $tinhaLixo = $true
        }
        foreach ($ln in $linhas) { $corpo.Add($ln) }

        # v2.10 - O "s" QUE EU APAGUEI ERA UM "E-agudo".
        # Descoberto medindo Troia e Homem-Aranha lado a lado: em TODOS os
        # blocos quebrados o padrao e o mesmo - o OCR escreveu a letra "s"
        # sozinha (que e o E-agudo destrucado) e, na linha orfa, repetiu a fala
        # com o "E" SEM acento. Exemplo do Troia:
        #     era     : "E muito corajoso ou muito estupido..."
        #     correto : "E-agudo muito corajoso ou muito estupido..."
        #
        # POR QUE SO SEM VIRGULA: conferi os 10 casos reais dos dois filmes.
        # Sem virgula depois do "E" (E + espaco + palavra), os 5 casos eram
        # E-agudo, sem excecao - porque conjuncao nao inicia frase sem verbo
        # ("E muito corajoso" nao fecha; "E-agudo muito corajoso" fecha).
        # COM virgula e ambiguo de verdade: "E, sim." e conjuncao legitima,
        # mas "E, vamos." era E-agudo. 4 acertos contra 1 estrago - nao vale.
        # Entao pego so o lado seguro: 5 acertos, 0 estragos, medido.
        #
        # E so age em bloco que JA se provou quebrado e de onde eu JA tirei a
        # letra de lixo. Em bloco normal esta regra nem chega a rodar.
        if ($tinhaLixo -and $corpo.Count -gt 0) {
            $primeira = $corpo[0]
            if ($primeira -cmatch '^E ' -and $primeira -cnotmatch '^E,') {
                $corpo[0] = [string][char]0x00C9 + $primeira.Substring(1)
                $script:ReparosAcentoE++
            }
        }
        $saida[$saida.Count - 1] = (@($cabecalho) + @($corpo)) -join "`n"
        $script:ReparosEstrutura++
    }
    return ($saida -join "`n`n") + "`n"
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
        if ($linhas[$i] -notmatch '-->') { $i++ }
        if ($i -ge $n) { break }
        $ini = ""; $fim = ""; $ok = $false
        $mt = [regex]::Match($linhas[$i], '(\d+:\d{2}:\d{2}[,\.]\d{1,3})\s*-->\s*(\d+:\d{2}:\d{2}[,\.]\d{1,3})')
        if ($mt.Success) { $ini = $mt.Groups[1].Value; $fim = $mt.Groups[2].Value; $ok = $true }
        $i++
        $corpo = New-Object System.Collections.Generic.List[string]
        while ($i -lt $n -and $linhas[$i].Trim() -ne "") { $corpo.Add($linhas[$i]); $i++ }
        if ($ok) {
            $blocos.Add((New-Object PSObject -Property ([ordered]@{
                Inicio = $ini; Fim = $fim
                IniMs = (Converter-TempoParaMs $ini)
                # v2.15: o FIM em milissegundos passou a ser guardado tambem.
                # O casamento com a segunda opiniao so olhava o inicio, e sem
                # o fim nao havia como conferir se o bloco casado tinha mesmo
                # a mesma duracao (ver o comentario la embaixo).
                FimMs = (Converter-TempoParaMs $fim)
                Texto = ($corpo -join "`n")
            })))
        }
    }
    return (Merge-BlocosPartidos $blocos)
}

<#  Merge-BlocosPartidos - v2.19
    -------------------------------------------------------------------------
    O DEFEITO, MEDIDO NO SPIDER-MAN DE 22/08.
    O .srt convertido saiu com 1905 blocos e o .srt do BluRay tem 1904. A
    diferenca nao era fala perdida - era fala DUPLICADA:

        939  00:59:51,463 --> 00:59:51,796   "- Que houve? / - Lutei com..."
        940  00:59:51,796 --> 00:59:54,174   "- Que houve? / - Lutei com..."

    O PGS partiu um unico evento em dois (o primeiro com 333 ms), o OCR leu o
    mesmo texto nos dois, e dali pra frente TODA a numeracao do arquivo andou
    um numero pra frente. E por isso que os blocos 66 e 464 batiam com a
    referencia e o 1637 batia com o 1636 dela.

    A TRAVA (medida no proprio arquivo, nao suposta): so funde quando o texto
    e identico E o fim de um e EXATAMENTE o inicio do outro (gap zero). Isso
    funde o caso acima e preserva os tres blocos "- Cara. / - Cara!" de
    00:02:06, que se repetem de proposito e tem 83 ms de intervalo entre si -
    conferido contra a legenda humana do release, que tambem tem os tres.
    Fundir por "texto igual" sozinho apagaria fala legitima repetida. #>
function Merge-BlocosPartidos {
    param($Blocos)
    <#  POR QUE [object[]] E NAO @( ).
        Escrevendo esta funcao, @($Blocos) sobre o List[object] devolvido pelo
        Parse-Srt estourou "Argument types do not match" e a funcao devolveu
        lista vazia. As quatro formas, medidas:
            $z = @($Blocos)        -> ERRO
            $z = $Blocos           -> ok
            $z = [object[]]$Blocos -> ok
            $z = ,$Blocos          -> Count 1 (embrulha - errado)

        RESSALVA HONESTA: isso foi observado em PowerShell 7.4 sobre .NET 8,
        em Linux - NAO em Windows PowerShell 5.1, que e onde este programa
        roda e onde eu nao consigo testar. Tem cara de defeito daquele
        ambiente e nao de regra da linguagem: o mesmo List criado com
        [List[object]]::new() em vez de New-Object aceita @( ) normalmente,
        sendo os dois exatamente o mesmo tipo, e foreach e indexacao funcionam
        nos dois casos.

        Ou seja: NAO trate isto como armadilha geral do projeto e nao saia
        trocando os @( ) do resto do codigo por causa deste comentario.
        [object[]] fica porque e correto e explicito nos dois ambientes - nao
        porque @( ) esteja provadamente errado no 5.1. #>
    $listaBlocos = [object[]]$Blocos
    if ($listaBlocos.Count -lt 2) { return $Blocos }
    $fundidos = New-Object System.Collections.Generic.List[object]
    $script:BlocosFundidos = 0
    $atual = $listaBlocos[0]
    for ($k = 1; $k -lt $listaBlocos.Count; $k++) {
        $prox = $listaBlocos[$k]
        if ($atual.Texto.Trim() -ne "" -and
            $atual.Texto.Trim() -ceq $prox.Texto.Trim() -and
            $atual.FimMs -eq $prox.IniMs) {
            # mesmo evento partido em dois: estica o fim e descarta o segundo
            $atual.Fim   = $prox.Fim
            $atual.FimMs = $prox.FimMs
            $script:BlocosFundidos++
            continue
        }
        $fundidos.Add($atual)
        $atual = $prox
    }
    $fundidos.Add($atual)
    return $fundidos
}

# ---------------------------------------------------------------- deteccao
<#
      Decide se um bloco e ALIENIGENA (lixo de OCR) e nao so uma traducao
      diferente ou um erro de 1 letra. Baseado nos casos REAIS confirmados
      visualmente pelo usuario nos 3 releases de teste:
        "OITEÇT"                  <- deveria ser "Quase."   (GoT 00:06:41)
        "s"                       <- deveria ser "É, é matematica."
        "INFETORE NE ToRSTOUR"    <- deveria ser "Nao. Nao sou."
        "OU MOrTrer."             <- deveria ser "ou morrer."

      VALIDADO antes de entrar aqui: 6 de 7 casos de lixo real detectados,
      e ZERO falso positivo em 15 falas boas (incluindo traducao diferente,
      "Tróia" com acento antigo, "Romanée-Conti", nome alemao comprido,
      e "É, é matematica." - que a versao anterior acusava por engano
      porque "matematica" nem existe no dicionario de 50k).

      Devolve $true/$false. O MOTIVO fica em $script:UltimoMotivo.
#>
function Test-BlocoAlienigena {
    param([string]$Texto, $Dicionario, $Nomes)
    $script:UltimoMotivo = ""
    if ($null -eq $Nomes) { $Nomes = New-Object 'System.Collections.Generic.HashSet[string]' }

    $limpo = ($Texto -replace '<[^>]{1,20}>', '').Trim()
    if ($limpo -eq "") { return $false }

    # --- Regra 1: bloco de 1 letra so (que nao seja interjeicao valida)
    # v2.12: se o bloco tem NUMERO, a letra sozinha e unidade, nao lixo.
    # Caso real do Homem-Aranha: o bloco '"4h"?' (quatro horas) era acusado
    # de "bloco de 1 letra so" - a unica letra e o "h" de hora. Ia parar na
    # fila da 2a opiniao sendo uma fala perfeita. Mesma coisa valeria pra
    # "3km", "50%s", "R$ 2 mi".
    $soConteudo = ($limpo -replace '[^\p{L}]', '')
    # v2.13: o teste era feito na letra COM acento, entao "E." (o verbo ser)
    # e "A." nao batiam em [aeo] e o bloco caia como lixo. Um bloco que e so
    # "E." e fala perfeita e comum em legenda. Agora tiro o acento antes.
    if ($soConteudo.Length -eq 1 -and (Get-SemAcento $soConteudo) -notmatch '(?i)^[aeo]$' -and $limpo -notmatch '\d') {
        $script:UltimoMotivo = "bloco de 1 letra so"
        return $true
    }

    $palavras = @([regex]::Matches($limpo, '[\p{L}]{2,}') | ForEach-Object { $_.Value })
    if ($palavras.Count -eq 0) { return $false }

    # --- Regra 2 (a mais forte): MAIUSCULA NO MEIO DA PALAVRA.
    # Assinatura inconfundivel de garbling do Tesseract - "MOrTrer",
    # "ToRSTOUR". Portugues real nunca escreve assim no meio de uma
    # palavra. Nao depende de dicionario nenhum, entao nao sofre com
    # palavra que falta no dic.
    foreach ($p in $palavras) {
        if ($p.Length -ge 3 -and $p -cmatch '[\p{Ll}][\p{Lu}]') {
            # v2.10: MARCA em CamelCase nao e garbling. Ver Test-EhMarcaCamel.
            if (Test-EhMarcaCamel $p) { continue }
            # v2.13: nome proprio em CamelCase que se repete no arquivo e
            # nao existe no dicionario ("McGregor"). Ver Get-NomesCamel.
            if ($script:NomesCamel -and $script:NomesCamel.Contains($p)) { continue }
            $script:UltimoMotivo = "maiuscula no meio de '$p'"
            return $true
        }
    }

    if (-not $Dicionario) { return $false }

    $reconhecidas = 0
    foreach ($p in $palavras) {
        # v2.6: usa a mesma consulta das correcoes (com E sem acento). Antes
        # so olhava a forma sem acento, entao toda palavra acentuada contava
        # como "nao existe em portugues" e inflava a contagem de lixo.
        #
        # v2.6: NOME PROPRIO CONTA COMO PALAVRA BOA. Sem isso, "Seria Randyll
        # Tarly?" dava "so 1 de 3 palavras existem em portugues" e ia parar na
        # fila da segunda opiniao - uma fala PERFEITA correndo risco de ser
        # sobrescrita. Num filme como Troia, onde quase toda fala tem Aquiles,
        # Heitor, Priamo ou Briseida, isso condenaria a legenda inteira.
        if ((Test-NoDicionario $p $Dicionario) -or $Nomes.Contains($p)) { $reconhecidas++ }
    }
    $taxa = $reconhecidas / $palavras.Count

    <#  2.27 - MEDIDO E DELIBERADAMENTE NAO ALTERADO.
        Uma auditoria de 01/09 apontou que esta conta pergunta ao dicionario
        de 1,3M sobre palavra de 2 e 3 letras - proibido no resto do projeto,
        porque 'tor', 'inf' e 'tol' existem la dentro. O apontamento esta
        certo quanto a regra da casa, e mesmo assim isto TEM que ficar como
        esta. Medi nos 8.887 blocos dos quatro filmes convertidos:
            hoje              : cerca de 10 blocos suspeitos no total
            com a guarda de 4 : 850 blocos suspeitos (+28 min por lote)
        A razao e simples: fala normal em portugues e cheia de palavra curta
        ('Nao sei o que e', 'E ai?'). Se palavra curta nao pontua, fala
        legitima vira lixo aos olhos da regra, e cada bloco trocado por
        engano e um defeito NOVO numa legenda que hoje sai EXCELENTE.
        Quem cuida do 'INF TOL' e a regra 3B, que e cirurgica: caixa alta,
        2+ palavras, e pelo menos uma sem vogal.
        NAO troque por uma guarda de 4 letras sem refazer a medicao. #>
    # --- Regra 3: 2+ palavras e quase nada existe em portugues.
    # Exijo 2+ palavras de proposito: com 1 palavra so, a chance de ser
    # so uma falta no dicionario (nome proprio, termo tecnico) e alta
    # demais - foi exatamente o que gerava falso positivo antes.
    if ($palavras.Count -ge 2 -and $taxa -lt 0.34) {
        $script:UltimoMotivo = ("so " + $reconhecidas + " de " + $palavras.Count + " palavras existem em portugues")
        return $true
    }

    <#
      --- Regra 3B (v2.12): BLOCO EM CAIXA ALTA SO COM PALAVRA DE ATE 3 LETRAS.

      O "INF TOL" do Troia aparece SEIS vezes no filme - e todas as seis eram
      "Nao.". Com o dicionario de 50k a Regra 3 pegava ele. Com o de 1,3M
      parou de pegar: "inf" e "tol" EXISTEM la dentro (entram pela parte de
      frequencia, que tem sigla e abreviacao de tudo quanto e lingua). Duas
      de duas "reconhecidas" = 100% = bloco aprovado. O dicionario grande,
      que consertou tanta coisa, abriu este buraco - e num defeito que se
      repete, que e o pior tipo.

      A regra nova nao pergunta nada ao dicionario, e por isso nao sofre com
      ele. Medi os blocos EM CAIXA ALTA dos tres filmes, um por um:
        legitimos  : 'EU MAIS SUA', 'PONTE CARLOS', 'ARMA: ALABARDA',
                     'ITACA - GRECIA', 'QUANTOS HOJE?', 'CONTROLE MANUAL'...
                     -> a MENOR palavra mais longa de todos eles tem 4 letras
        lixo do OCR: 'INF TOL' (3), 'INF=TOR' (3)
      Ou seja: placa e letreiro de verdade sempre trazem pelo menos uma
      palavra de 4+ letras. Duas ou mais palavras em caixa alta, todas com 3
      letras ou menos, e assinatura de OCR picotado.
      Uma palavra so nao entra aqui - isso e a Regra 4, que exige 4+ letras
      justamente pra nao encostar num "NAO." ou "SIM." legitimo.
    #>
    if ($palavras.Count -ge 2) {
        $todasCaixaAlta = $true
        $maiorPalavra = 0
        foreach ($p in $palavras) {
            if ($p -cne $p.ToUpperInvariant()) { $todasCaixaAlta = $false; break }
            if ($p.Length -gt $maiorPalavra) { $maiorPalavra = $p.Length }
        }
        # v2.13: "SIM OU NAO" / "EU VOU LA" tambem sao 2+ palavras curtas em
        # caixa alta e sao fala legitima. Se o bloco tem pelo menos uma
        # palavra curta COMUM do portugues, ele nao e lixo. Ver Test-CurtaComum.
        $temCurtaComum = $false
        foreach ($p in $palavras) { if (Test-CurtaComum $p) { $temCurtaComum = $true; break } }
        if ($todasCaixaAlta -and $maiorPalavra -le 3 -and -not $temCurtaComum) {
            $script:UltimoMotivo = ("bloco todo em caixa alta so com palavra de ate 3 letras ('" + $limpo + "')")
            return $true
        }
    }

    # --- Regra 4: 1 palavra so, MAS toda maiuscula e inexistente em PT.
    # Assinatura do "OITEÇT" e do "INFETOR".
    if ($palavras.Count -eq 1 -and $taxa -eq 0) {
        $letras = ($palavras[0] -replace '[^\p{L}]', '')
        if ($letras.Length -ge 4) {
            $mai = ([regex]::Matches($letras, '[\p{Lu}]')).Count
            if (($mai / $letras.Length) -gt 0.6) {
                $script:UltimoMotivo = ("'" + $palavras[0] + "' e toda maiuscula e nao existe em portugues")
                return $true
            }
        }
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
    <#  REGRA 6 (v2.24): LINHA DE LIXO DENTRO DE BLOCO BOM - palavra LONGA.
        Esta regra ja existia no Reocr desde a 1.12 e nunca tinha sido
        trazida pro Corretor. Ela cobre o 'E NFETOL' / 'MN NETORVE': a linha
        tem UMA palavra de 4+ letras em caixa alta que nao existe em
        portugues, e a outra linha do bloco e fala normal.
        Ate agora quem pegava esses no Corretor era a 6B - e quando eu
        apertei a 6B para exigir 2+ palavras (por causa dos falsos
        positivos), esses cairiam no vazio. Trazer a regra 6 pra ca fecha o
        buraco: cada uma cobre um tamanho de palavra.
        GUARDA DE PLACA: palavra conhecida em caixa alta na mesma linha
        absolve. Medido nos 7.695 blocos do Reocr: 13 acertos, 0 falsos. #>
    foreach ($linha in ($limpo -split "`n")) {
        $emCaixa = @([regex]::Matches($linha, '[\p{L}]{4,}') | ForEach-Object { $_.Value } |
                     Where-Object { $_ -ceq $_.ToUpperInvariant() -and $_ -cne $_.ToLowerInvariant() })
        if ($emCaixa.Count -eq 0) { continue }
        $temConhecida = $false; $temEstranha = $false
        foreach ($p in $emCaixa) {
            if ((Test-NoDicionario $p $Dicionario) -or $Nomes.Contains($p)) { $temConhecida = $true }
            else { $temEstranha = $true }
        }
        if ($temEstranha -and -not $temConhecida) {
            $script:UltimoMotivo = ("linha com palavra em caixa alta que nao existe em portugues ('" + $linha.Trim() + "')")
            return $true
        }
    }

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
            $script:UltimoMotivo = ("linha toda em caixa alta sem palavra de portugues ('" + $linha.Trim() + "')")
            return $true
        }
    }

    return $false
}

<#
      v2.6 - LISTAS FECHADAS usadas pelas regras novas.
      Tudo em minuscula e SEM acento: a consulta sempre normaliza antes.
#>
$script:OrdFeminino = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($w in @("vez","vezes","hora","horas","semana","semanas","parte","partes","fase","fases",
                 "rodada","temporada","edicao","pessoa","filha","esposa","mulher","noite","manha",
                 "tarde","vitoria","guerra","batalha","chance","tentativa","serie","linha","porta",
                 "casa","vida","vista","volta","vez")) { [void]$script:OrdFeminino.Add($w) }

$script:OrdMasculino = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($w in @("lugar","lugares","ano","anos","mes","meses","dia","dias","tempo","andar","andares",
                 "filho","marido","homem","turno","posto","grau","capitulo","episodio","jogo","passo",
                 "livro","round","tempo")) { [void]$script:OrdMasculino.Add($w) }

# Palavras que sozinhas formam predicado. "E claro." nao existe: a conjuncao
# "e" nao liga nada aqui - a frase nao tem verbo. Logo o "E" e um "E-agudo"
# que perdeu o acento no OCR. Ja "E claro que ele veio" tem verbo e NAO entra.
$script:Predicativos = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($w in @("claro","isso","verdade","mesmo","mesma","obvio","possivel","certo","certa",
                 "cedo","pouco","melhor","pior","facil","dificil","bom","boa")) { [void]$script:Predicativos.Add($w) }

# Palavra funcional curta. Se aparecer TODA MAIUSCULA dentro de um bloco que o
# OCR ja provou ser lixo, e caixa errada, nao enfase do legendador.
$script:FuncionaisCaixa = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($w in @("OU","DE","DO","DA","DOS","DAS","EM","NO","NA","NOS","NAS","COM","POR","PARA",
                 "QUE","SE","MAS","NEM","AO","AOS","AS","OS","UM","UMA")) { [void]$script:FuncionaisCaixa.Add($w) }


<#
      --- FAMILIA "Ir" (v2.13): MAIUSCULA INICIAL NO MEIO DA FRASE ---

      Achei esta comparando bloco a bloco os 3 filmes com a legenda HUMANA
      do release. Nove ocorrencias que a legenda humana nao tem:

        "- Tenho que Ir."              (Homem-Aranha)
        "Espera. Antes de Ir."         (Homem-Aranha)
        "Temos que Ir."                (Homem-Aranha)
        "Helena. Precisamos Ir."       (Troia)
        "Voce precisa Ir."             (Troia)
        "voce nao precisa fazer Isso." (Troia)
        "o po dos Nossos ossos"        (Troia)

      Cinco das sete sao a MESMA palavra: "Ir". O Tesseract le o 'i'
      minusculo como 'I' maiusculo quando a fonte da legenda e alta ou
      italica - e "ir" e a palavra curta mais comum que comeca com 'i'.
      Nao e um caso: e uma familia, e ela se repete.

      As tres travas abaixo foram medidas contra a legenda humana dos 3
      filmes, e cada uma existe por causa de um caso real:

        1. So no MEIO da frase. Depois de . ! ? : " - traco, a maiuscula
           esta certa e nao se toca.
        2. So palavra em forma "Xxx" (mixed case). Palavra TODA maiuscula
           e sigla ate prova em contrario - foi exatamente a regressao do
           "pulso EM" que eu causei na 2.8 e que a regra de cima ja trata.
        3. A QUEBRA DE LINHA conta como espaco. "o po dos\nNossos ossos" e
           a mesma frase partida em duas linhas - o bloco do Troia era
           exatamente assim e escapava quando eu so olhava o espaco.
        4. NAO MEXE se a palavra SEGUINTE tambem comeca com maiuscula.
           Esta salva "no Museu Da Vinci as 15h" e "Sexto do Seu Nome" -
           os dois estao assim na legenda HUMANA, entao estao certos.
#>
$script:FuncionaisMeio = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($w in @(
    "ir","vir","ver","dar","ser","estar","fazer","dizer","isso","isto","aquilo",
    "nosso","nossa","nossos","nossas","meu","minha","meus","minhas",
    "seu","sua","seus","suas","dele","dela","deles","delas",
    "mas","que","quando","porque","pois","ainda","tudo","nada","nunca",
    "sempre","muito","mais","menos","bem","aqui","ali","agora","depois",
    "antes","hoje","ontem","tambem","talvez","assim","entao","apenas",
    "vamos","temos","tenho","tem","vou","vai","vem","pode","deve","quer",
    "sabe","acho","era","foi","sao","esta","estao","com","sem","por","para"
)) { [void]$script:FuncionaisMeio.Add($w) }

<#
      Consulta ao dicionario COM a regra fonotatica da v2.5 embutida.
      Palavra que comeca com 'l' + consoante (menos o digrafo 'lh') NAO EXISTE
      em portugues - as 24 entradas assim no dicionario de 50k sao lixo de OCR
      de quem montou a lista. Tratar como inexistente e o que destravou o
      "-lsso" -> "-Isso".
#>
<#
      v2.7 - POLUICAO DO DICIONARIO, caso por caso.
      Descoberto no Troia: "pal" ESTA no dicionario de 50k. Nao e palavra
      portuguesa - e o mesmo tipo de lixo que ja tinhamos achado em "lsso".
      Resultado: "Pal" no lugar de "Pai" apareceu 8 VEZES no filme e a regra
      de l/i nao mexia, porque via "pal" na lista e concluia palavra legitima.

      POR QUE UMA LISTA MANUAL E NAO UMA REGRA ESPERTA: conferi as 50k e
      existem 138 pares onde AS DUAS formas com l/i sao palavra real -
      "muita/multa", "saia/sala", "veia/vela", "piano/plano", "cadeia/cadela",
      "estreia/estrela". Qualquer regra automatica de trocar l por i ali
      destroi legenda boa. So da pra tratar caso a caso, e a lista cresce
      quando aparecer outro. Preferi honestidade a esperteza.
#>
$script:PoluicaoDic = New-Object 'System.Collections.Generic.HashSet[string]'
# v2.9: com o dicionario de 1,3M, "sel", "seli" e "pali" passaram a EXISTIR
# (sao palavra estrangeira / nome de idioma, legitimos num dicionario grande).
# Sem entrar aqui, "Sel."->"Sei." e "Pali."->"Pai." parariam de funcionar.
# Todas as entradas desta lista tem a mesma justificativa: palavra estrangeira
# que uma legenda em portugues nao usa em minuscula.
foreach ($w in @("pal","pali","sel","seli","ihe","ihes","aii","iei","eie","fln",
                 "shil","bla","pla","lal","wal","lsso","lsto","toi")) { [void]$script:PoluicaoDic.Add($w) }

<#  v2.17 - PREFIXO PRODUTIVO.
    O dicionario de 1,3 milhao tem buraco em palavra prefixada. Medido nos
    .srt reais: "excomandante", "reconsiderei", "supercolisor",
    "superpessoas", "multiversais", "superestimei", "autoterapia",
    "reconsidero" - todas portugues legitimo, todas ausentes.
    Palavra boa dada como inexistente empurra o bloco para a fila de
    suspeitos e, no Reocr, faz a trava de aceite RECUSAR uma leitura certa.
    Lista FECHADA e conservadora: so prefixos que formam palavra nova sem
    alterar a base. Exige base de 4+ letras.
    RISCO MEDIDO: 14 lixos tipicos de OCR ("renetor", "exnetor", "retol",
    "subtol", "automn", "supertejlorl") - todos rejeitados.
    NAO INCLUI corte cego de terminacao verbal: testado, aceita lixo junto
    (diz que "transporao" vem de "transar"). Melhor de fora do que torto. #>
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
    if ($script:PoluicaoDic.Contains($P.ToLowerInvariant())) { return $false }
    $comAcento = $P.ToLowerInvariant()
    $k = (Get-SemAcento $P).ToLowerInvariant()
    # v2.9: a regra fonotatica ("l" + consoante nao existe em portugues) foi
    # criada na 2.5 pra contornar o dicionario de 50k, que estava poluido com
    # "lsso", "lgreja", "ldiota". O dicionario de 1,3M nao tem nenhuma dessas -
    # a gambiarra virou desnecessaria. Fica como rede, custa nada.
    if ($k -cmatch '^l[bcdfgjklmnpqrstvwxz]') { return $false }
    # v2.6 BUG ACHADO NO TESTE: o dicionario de 50k guarda a palavra COM acento
    # (7.308 entradas tem acento - "aco" nao existe la, "aco-cedilha" existe).
    # Consultar so a forma sem acento fazia "Aco" e "Perdao" passarem por
    # palavra inexistente - e virarem "nome proprio protegido".
    if ($Dicionario.Contains($comAcento)) { return $true }
    if ($Dicionario.Contains($k)) { return $true }

    <#  v2.14: PALAVRA COM HIFEN.
        MEDIDO: o dicionario de 1.296.517 palavras nao tem UMA UNICA palavra
        com hifen. Varri as 218 palavras hifenizadas distintas dos .srt reais
        do projeto (Troia, Se7en, Homem-Aranha, Lara Croft, GoT) e as 218
        deram "nao existe" - incluindo "bem-vindo", "meio-dia", "super-heroi",
        "montanha-russa" e as ~160 enclises ("mata-lo", "deixe-me",
        "levante-se", "lembre-se").
        Ate agora isso era inofensivo por acidente: quem consulta costuma
        quebrar o token no hifen antes. Mas era municao carregada pra
        qualquer regra futura que olhasse a palavra inteira - e o Reocr JA
        olha, na trava de "% das palavras existem em portugues".
        A regra e a mais simples possivel: palavra composta e conhecida se
        TODAS as suas partes forem conhecidas. Nao precisou de nada sobre
        enclise - "mata" e "lo" estao os dois no dicionario.
        MEDIDA da regra no mesmo corpus: 216 de 218 reconhecidas (99%).
        As DUAS que sobram sao exatamente os dois erros de OCR reais:
            "mexar-se"      (o certo e "mexer-se")
            "homem-aranh"   (comeu o "a" final)
        Ou seja: ela aceita o que e legitimo e continua entregando o que e
        defeito. Era esse o alvo.
    #>
    if ($P.Contains("-")) {
        <#  v2.15: FALTAVA A SEGUNDA GUARDA - "INF-TOL" PASSARIA.
            A regra aceitava a palavra hifenizada quando TODAS as partes
            existiam no dicionario, e `inf`, `tol`, `net`, `tor`, `neto`
            existem no de 1,3 milhao. O lixo de OCR que a ferramenta existe
            para pegar seria declarado palavra legitima.
            Palavra hifenizada de verdade ou termina em pronome atono
            (mata-lo, diz-se) ou tem um pedaco com 4+ letras (guarda-chuva,
            segunda-feira). Duas siglas de tres letras nao sao nenhum dos dois. #>
        $partes = @($P.Split("-") | Where-Object { $_ -ne "" })
        if ($partes.Count -ge 2) {
            $ultimaP = (Get-SemAcento $partes[$partes.Count - 1]).ToLowerInvariant()
            $atonosP = @("lo","la","los","las","no","na","nos","nas","me","te","se","lhe","lhes","o","a","os","as")
            $temLongoP = $false
            foreach ($pedP in $partes) { if ($pedP.Length -ge 4) { $temLongoP = $true } }
            if (-not ($temLongoP -or ($atonosP -contains $ultimaP))) { return $false }
            $todas = $true
            foreach ($ped in $partes) {
                $pa = $ped.ToLowerInvariant()
                $pk = (Get-SemAcento $ped).ToLowerInvariant()
                if (-not ($Dicionario.Contains($pa) -or $Dicionario.Contains($pk))) { $todas = $false; break }
            }
            if ($todas) { return $true }
        }
    }
    # v2.17: ultimo recurso - PREFIXO PRODUTIVO + palavra conhecida
    # ("super"+"colisor", "ex"+"comandante"). Ver o bloco abaixo.
    if (Test-PrefixoProdutivo $P $Dicionario) { return $true }
    return $false
}

<#
      v2.10 - MARCA ESCRITA EM CamelCase NAO E GARBLING.

      A regra "maiuscula no meio da palavra = lixo do OCR" foi escrita quando
      o dicionario tinha 50.000 palavras. No de 1,3M as marcas passaram a
      EXISTIR em minuscula: buzzfeed, youtube, iphone, powerpoint, netflix,
      ebay, whatsapp - todas confirmadas dentro do .dic. Isso abre um buraco
      na Regra C: o codigo ve maiuscula no meio, marca como garbling, baixa a
      caixa, acha a palavra no dicionario e devolve "buzzfeed". Legenda humana
      corrigida pra pior.

      Nao e teoria: a legenda ORIGINAL do release do Homem-Aranha escreve
      "O BuzzFeed diz que um marinheiro" - texto humano, correto - e a 2.8
      ja acusava esse bloco no relatorio ("maiuscula no meio de 'BuzzFeed'").
      Com o dicionario grande ela deixaria de so acusar e passaria a estragar.

      POR QUE UMA LISTA E NAO UMA REGRA DE FORMA:
      minha primeira versao aceitava qualquer PascalCase cuja forma minuscula
      existisse no dicionario. Testei e ela protegia "PaLavra" e "AiNda" -
      que sao exatamente o erro de OCR que a regra existe pra consertar
      (palavra portuguesa com UMA letra do meio em caixa alta). Trocar um
      conserto real por um nome de marca e um pessimo negocio. A lista custa
      manutencao, mas nao consegue engolir conserto nenhum: so escapa da
      regra a palavra que esta escrita aqui.

      Se faltar uma marca aqui, o pior que acontece e o que ja acontecia
      antes: a marca sai em minuscula. Basta acrescentar a linha.
#>
$script:MarcasCamel = New-Object 'System.Collections.Generic.HashSet[string]'
# So entra aqui marca que SE ESCREVE com maiuscula no meio. Marca que se
# escreve normal (Netflix, Uber, Oscorp) nunca chega nesta funcao, porque sem
# maiuscula no meio a palavra nem e marcada como garbling - e se chegar, e
# porque o OCR errou a caixa e nos QUEREMOS o conserto.
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

function Test-EhMarcaCamel {
    param([string]$P)
    if ([string]::IsNullOrEmpty($P)) { return $false }
    return $script:MarcasCamel.Contains($P.ToLowerInvariant())
}

<#
      v2.6 - NOMES PROPRIOS: a rede de protecao que faltava.
      Troia e Homem-Aranha estao cheios de nome que o dicionario de 50k nao
      tem (Priamo, Briseida, Osborn, Oscorp...). Sem isso, toda regra nova
      viraria uma maquina de estragar nome proprio.
      Assinatura de nome: comeca com maiuscula, NAO tem maiuscula no meio
      (isso e garbling), aparece 2+ vezes no arquivo e nao esta no dicionario.
      Erro de OCR e aleatorio; nome proprio se repete. E essa a diferenca.
#>

<#
      --- LISTA DE PALAVRAS CURTAS COMUNS (v2.13) ---

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
      --- NOME PROPRIO EM CamelCase (v2.13) ---

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
    # v2.15: @{} do PowerShell ignora maiuscula/minuscula, e aqui a caixa E
    # o dado ("Ir" e "ir" nao sao a mesma palavra).
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
    # v2.15: @{} do PowerShell ignora maiuscula/minuscula, e aqui a caixa E
    # o dado ("Ir" e "ir" nao sao a mesma palavra).
    $cont = New-Object 'System.Collections.Generic.Dictionary[string,int]' 
    $noMeio = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($linha in ($TextoInteiro -split "`n")) {
        # v2.7: sem hifen no padrao. Com hifen, "Deixe-me", "Entregue-o" e
        # "Derrubarei" entravam como nome proprio no Troia - sao verbo.
        $ms = @([regex]::Matches($linha, '[\p{L}]+'))
        for ($i = 0; $i -lt $ms.Count; $i++) {
            $v = $ms[$i].Value
            if ($cont.ContainsKey($v)) { $cont[$v] = $cont[$v] + 1 } else { $cont[$v] = 1 }
            # v2.7: assinatura FORTE - capitalizada NO MEIO da frase. Verbo so
            # aparece maiusculo no comeco; nome proprio aparece nos dois lugares.
            if ($i -gt 0) {
                $antes = $linha.Substring(0, $ms[$i].Index).TrimEnd()
                if ($antes.Length -gt 0 -and ".!?:-`"" -notlike ("*" + $antes.Substring($antes.Length-1) + "*")) {
                    [void]$noMeio.Add($v)
                }
            }
        }
    }
    foreach ($k in $cont.Keys) {
        if ($k.Length -lt 2) { continue }
        if ($k -cnotmatch '^[\p{Lu}]') { continue }
        if ($k -cnotmatch '[\p{Ll}]') { continue }
        if ($k -cmatch '[\p{Ll}][\p{Lu}]') { continue }
        if ($cont[$k] -lt 2) { continue }
        if (-not $noMeio.Contains($k)) { continue }
        if (Test-NoDicionario $k $Dicionario) { continue }
        [void]$nomes.Add($k)
    }
    return ,$nomes
}

# Candidatos trocando 'l' <-> 'i'. O 'l' no INICIO da palavra tem prioridade e
# vira 'I' MAIUSCULO: em fonte sem serifa os dois glifos sao identicos, e o
# erro real e sempre nessa direcao ("llhas" -> "Ilhas", nao "ilhas").
function Get-CandidatosTrocaLI {
    param([string]$P, $Dicionario)
    $saida = New-Object 'System.Collections.Generic.List[string]'
    if ($P.Substring(0,1) -ceq 'l') {
        $c = 'I' + $P.Substring(1)
        if (Test-NoDicionario $c $Dicionario) { $saida.Add($c); return $saida }
    }
    for ($i = 0; $i -lt $P.Length; $i++) {
        $ch = $P.Substring($i,1)
        $novo = ""
        if     ($ch -ceq 'l') { $novo = 'i' } elseif ($ch -ceq 'L') { $novo = 'I' }
        elseif ($ch -ceq 'i') { $novo = 'l' } elseif ($ch -ceq 'I') { $novo = 'L' }
        else { continue }
        $c = $P.Substring(0,$i) + $novo + $P.Substring($i+1)
        if ((Test-NoDicionario $c $Dicionario) -and -not $saida.Contains($c)) { $saida.Add($c) }
    }
    return $saida
}

# v2.7 - delecao FINA: so apaga um 'l'/'i' que esteja ENCOSTADO em outro
# 'l'/'i'. Essa e a assinatura exata do traco partido - o OCR viu um traco
# fino unico e escreveu dois ("Pai"->"Pali", "Sei"->"Seli", "construi"->
# "construii"). Descoberto no Troia.
# NAO GENERALIZAR: testei apagar letra em qualquer posicao e virou desastre -
# "ecoar"->"ecoa", "arremessem"->"arremesse", "subjugados"->"subjugado",
# "Peleu"->"Pele". O dicionario de 50k nao tem toda conjugacao, entao some
# uma letra e cai noutra forma valida. Fica so no traco partido.
function Get-CandidatosDelecaoFina {
    param([string]$P, $Dicionario)
    $finos = "liLI" + [string][char]0x00ED + [string][char]0x00CD
    $vistos = @{}
    $saida = New-Object 'System.Collections.Generic.List[string]'
    for ($i = 1; $i -lt $P.Length; $i++) {
        if (-not $finos.Contains($P.Substring($i,1))) { continue }
        $viz = ""
        if ($i -gt 0) { $viz = $viz + $P.Substring($i-1,1) }
        if ($i + 1 -lt $P.Length) { $viz = $viz + $P.Substring($i+1,1) }
        $temVizinho = $false
        foreach ($ch in $viz.ToCharArray()) { if ($finos.Contains([string]$ch)) { $temVizinho = $true } }
        if (-not $temVizinho) { continue }
        # v2.8 REGRESSAO MINHA, achada no Homem-Aranha: esta regra virou
        # "blipou" em "bipou" 1 vez. "blipou" nao esta no dicionario de 50k
        # (e giria do filme), tem 'l' colado no 'i', e apagando o 'l' cai em
        # "bipou", que esta. Estraga palavra boa.
        # A diferenca: em "Pali"/"Seli"/"construii" a letra ANTES do traco a
        # apagar e VOGAL (a, e, u). Em "blipou" e CONSOANTE (b) - e "bl" e
        # encontro consonantal legitimo do portugues, igual cl, fl, gl, pl,
        # tl. Traco partido de OCR nao inventa encontro consonantal.
        $anterior = ""
        if ($i -gt 0) { $anterior = (Get-SemAcento $P.Substring($i-1,1)).ToLowerInvariant() }
        if ($anterior -notmatch '^[aeiou]$') { continue }
        $c = $P.Substring(0,$i) + $P.Substring($i+1)
        if ($c.Length -lt 3) { continue }
        if (-not (Test-NoDicionario $c $Dicionario)) { continue }
        $k = (Get-SemAcento $c).ToLowerInvariant()
        if ($vistos.ContainsKey($k)) { continue }
        $vistos[$k] = $true
        $saida.Add($c)
    }
    return $saida
}

# Candidatos apagando UMA letra. Trata o glifo que o Tesseract parte em dois
# ("mortrer" -> "morrer"). So vale com UM unico acerto no dicionario: se der
# dois, e chute, e chute nao entra na legenda do usuario.
function Get-CandidatosDelecao {
    param([string]$P, $Dicionario)
    $saida = New-Object 'System.Collections.Generic.List[string]'
    for ($i = 0; $i -lt $P.Length; $i++) {
        $c = $P.Substring(0,$i) + $P.Substring($i+1)
        <#  v2.24: o piso de 3 letras jogava fora o unico conserto certo do
            "Aii esta." do Se7en (01:07:48). O OCR leu "A<i><I> esta"; a regra C
            baixou a caixa do I do meio e ficou "Aii" - conserto pela metade,
            defeito NOSSO, escrito no arquivo final. Apagar uma das duas cai
            em "Ai", que existe, mas tem 2 letras e o piso descartava.
            Abro o piso SO quando a letra apagada e igual a vizinha (letra
            dobrada). Fora disso o piso continua: deixar qualquer delecao
            chegar a 2 letras abre a porta pro dicionario de 1,3M, que tem
            sigla e fragmento de tudo quanto e lingua com 2 letras. #>
        # E VOGAL dobrada, nao qualquer letra dobrada: o artefato real e o
        # glifo do i/I-acentuado lido duas vezes. Aceitar consoante dobrada
        # deixaria um "eSs" garbled virar "es" - fragmento que o dicionario
        # de 1,3M aceita e que nao e palavra nenhuma na tela.
        $ch = $P.Substring($i,1)
        $ehVogal = ((Get-SemAcento $ch).ToLowerInvariant() -match '^[aeiou]$')
        $dobrada = $ehVogal -and (
                   ($i -gt 0 -and $ch -eq $P.Substring($i-1,1)) -or
                   ($i + 1 -lt $P.Length -and $ch -eq $P.Substring($i+1,1)))
        if ($c.Length -lt 3 -and -not ($c.Length -eq 2 -and $dobrada)) { continue }
        if ((Test-NoDicionario $c $Dicionario) -and -not $saida.Contains($c)) { $saida.Add($c) }
    }
    return $saida
}

<#
      Correcoes DETERMINISTICAS de OCR - as que nao precisam de segunda
      opiniao nenhuma porque o padrao e conhecido e sem ambiguidade.

      v2.5 tratava so o "I maiusculo lido como l minusculo" no INICIO de
      palavra, mais o "E" circunflexo sozinho.

      v2.6 acrescenta 4 familias, todas escolhidas por um criterio so: ELAS
      SE REPETEM EM QUALQUER FILME. Erro que so aparece uma vez nao vale
      regra; erro que volta em todo release, vale.

        1. l <-> i em QUALQUER posicao da palavra ("Sel." -> "Sei.")
        2. ordinal masculino/feminino trocado ("1o vez" -> "1a vez")
        3. maiuscula no meio da palavra ("MOrTrer" -> "morrer")
        4. "E" que perdeu o acento em frase sem verbo ("E claro." -> "E-agudo claro.")

      TODAS obedecem a mesma trava: so troca se a palavra NOVA existe no
      dicionario, a ORIGINAL nao existe, o candidato e UNICO, e a palavra nao
      esta na lista de nomes proprios do arquivo.

      MEDIDO ANTES DE ENTREGAR (nao e estimativa):
        legenda com defeito (GoT rodada 4) : 4 blocos mudados em 446 - os 4
                                             defeitos conhecidos, mais nada
        legenda boa (referencia)           : 0 blocos mudados em 448
        teste adversarial                  : 53 armadilhas (nomes de Troia e
                                             Homem-Aranha, "sol/mil/vil/mal",
                                             "1o lugar", "E claro que...",
                                             "PERIGO", "FBI", "ONU") -> zero
                                             tocada; 6 lixos reais -> 6 corrigidos
#>
<#  ===================================================================
    v2.16 - A FAMILIA DA BARRA VERTICAL

    Numa fonte de legenda o "I" maiusculo e uma barra vertical limpa -
    visualmente identica ao "l" minusculo e ao "|". A haste do "t" cai na
    mesma confusao. Medido nos 6 filmes ja convertidos do projeto:

        "la mesmo me matar?"    era  "Ia mesmo me matar?"
        "Eu la morrer."         era  "Eu ia morrer."
        "onde tr."              era  "onde ir."
        "- Ol, May."            era  "- Oi, May."
        "Ele estava all,"       era  "Ele estava ali,"
        "val ser..."            era  "Vai ser..."
        "devesse |r"            era  "devesse ir"

    POR QUE NUNCA FOI PEGO: o dicionario de 1,3 milhao aceita "la", "lo",
    "tr", "ol", "all", "val" como palavras portuguesas. Ele tem sigla,
    termo solto, palavra estrangeira e ate lixo de extracao ("rn", "vv",
    "0a", "1b" - 1.588 das 1.662 entradas de duas letras nao sao
    portugues). Perguntar a ele "isto e portugues?" sobre uma palavra de
    duas ou tres letras nao serve para nada.

    A lista abaixo e a resposta certa: o conjunto de palavras de ate 3
    letras do portugues e FECHADO - da para escrever inteiro. Nao ha por
    que consultar 1,3 milhao de entradas para saber se "tr" e palavra.
    "la" e "lo" ficam DE FORA de proposito: soltos nao sao portugues, so
    existem grudados por hifen ("da-la", "ve-lo") - e e exatamente por
    estarem no dicionario que "la mesmo?" nunca virou "Ia mesmo?".

    MEDIDO ANTES DE ENTRAR: 7.695 blocos dos 6 filmes ja convertidos.
    28 blocos corrigidos, ZERO estrago. Controles intactos ("Li a
    respeito", "Vou da-la a ele", "US$ 100 mil", "Ele tem 12 anos").
    =================================================================== #>
$script:CurtasPtBr = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
<#  ATENCAO AO PARENTESES DE CADA ITEM ACENTUADO.
    Dentro de @( ... ) a VIRGULA tem precedencia MAIOR que o '+'. Sem os
    parenteses, @( 'l'+[string][char]0x00E1+'' ) nao produz UM item "la-com-
    acento": produz TRES - 'l', o acento sozinho e ''. Foi assim que 'l',
    'r', 'i', 't' e 'ol' entraram na lista de palavras portuguesas curtas -
    justamente os cacos que esta lista existe para rejeitar. Com 'ol' dentro
    dela, "- Ol, May." nunca viraria "- Oi, May.".
    Pego no teste em PowerShell: a lista tinha 407 itens onde deviam ser 472. #>
foreach ($w in @(
        'a', 'aba', 'abe', 'ada', 'ade',
        ('ad'+[string][char]0x00E1), ('af'+[string][char]0x00E1), 'aga', 'age', 'ago',
        'ah', 'ai', 'aia', 'aja', 'ajo',
        'ala', 'ali', 'alo', ('al'+[string][char]0x00E1), ('al'+[string][char]0x00F4),
        'am', 'ama', 'amo', ('am'+[string][char]0x00E1), 'ana',
        'ano', 'ao', 'aos', 'apa', 'apo',
        'ar', 'ara', 'arc', 'are', 'aro',
        'ars', ('ar'+[string][char]0x00E1), 'as', 'asa', 'ase',
        'ass', ('as'+[string][char]0x00E9), 'ate', 'ato', ('at'+[string][char]0x00E9),
        'aum', 'aur', 'ave', 'avo', ('av'+[string][char]0x00F3),
        'azo', ('a'+[string][char]0x00E7+'a'), ('a'+[string][char]0x00E7+'o'), ('a'+[string][char]0x00ED), 'ba',
        'bar', 'be', 'bem', 'bi', 'bis',
        'bo', 'boa', 'boi', 'bom', 'bu',
        'bua', 'bum', ('b'+[string][char]0x00EA+'s'), ('b'+[string][char]0x00ED+'u'), 'cai',
        'cal', 'cam', 'cap', 'car', 'cas',
        ('ca'+[string][char]0x00ED), 'cd', 'ce', 'cem', 'cen',
        'cha', 'che', ('ch'+[string][char]0x00E1), 'ci', 'cia',
        'cio', 'cis', 'cm', 'com', 'cor',
        'cru', 'cu', 'cus', 'cuz', ('c'+[string][char]0x00E1),
        ('c'+[string][char]0x00E3+'o'), ('c'+[string][char]0x00E9+'u'), ('c'+[string][char]0x00F3+'s'), 'da', 'dai',
        'dar', 'das', ('da'+[string][char]0x00ED), 'de', 'dei',
        'del', 'dem', 'den', 'der', 'des',
        'deu', 'dez', 'di', 'dia', 'diz',
        'dj', 'do', 'doa', 'doe', 'dor',
        'dos', 'dou', 'dr', 'duo', ('d'+[string][char]0x00E1),
        ('d'+[string][char]0x00E1+'s'), ('d'+[string][char]0x00E3+'o'), ('d'+[string][char]0x00EA), ('d'+[string][char]0x00F3), ('d'+[string][char]0x00F3+'i'),
        'e', 'eh', 'ei', 'eis', 'el',
        'ela', 'ele', 'elo', 'em', 'ema',
        'era', 'ere', 'ero', 'ers', 'es',
        'esp', 'eta', 'eu', 'eus', 'ex',
        'faz', 'fez', 'fi', 'fim', 'fio',
        'fiz', 'foi', 'for', 'fu',
        'fui', 'fun', 'fus', ('f'+[string][char]0x00E1), ('f'+[string][char]0x00E3+'o'),
        ('f'+[string][char]0x00E9), ('f'+[string][char]0x00EA), 'gaz', 'gb', 'gel',
        'gim', 'gol', 'gua', ('g'+[string][char]0x00E1+'s'), 'ha',
        'he', 'hi', 'hm', 'hoj', 'hoo',
        ('h'+[string][char]0x00E1), 'ia', 'iam', 'ias', ('ia'+[string][char]0x00ED),
        'ida', 'ide', 'ido', ('il'+[string][char]0x00E9), 'io',
        'ir', 'ira', 'ire', 'iro', ('ir'+[string][char]0x00E1),
        'isa', 'iso', 'ito', 'ivo', ('i'+[string][char]0x00E7+'a'),
        ('i'+[string][char]0x00E9), 'jaz', 'joi', 'ju', 'jus',
        ('j'+[string][char]0x00E1), 'kg', 'km', 'lar', 'las',
        'lda', 'lei', 'leu', 'lex', 'lha',
        'lhe', 'lho', 'li', 'lia', 'lis',
        'los', 'lua', 'luz', ('l'+[string][char]0x00E1), ('l'+[string][char]0x00E3),
        ('l'+[string][char]0x00E3+'s'), ('l'+[string][char]0x00EA), 'mal', 'mar', 'mas',
        'mau', 'max', 'me', 'mel', 'meu',
        'mi', 'mil', 'mim', 'min', 'ml',
        'mm', 'mo', 'moa', 'moi', 'mor',
        'mos', 'mu', 'muc', 'mui', ('m'+[string][char]0x00E1),
        ('m'+[string][char]0x00E3), ('m'+[string][char]0x00E3+'e'), ('m'+[string][char]0x00E3+'o'), ('m'+[string][char]0x00E9), ('m'+[string][char]0x00EA+'s'),
        ('m'+[string][char]0x00ED), ('m'+[string][char]0x00F3), 'na', 'nao', 'nas',
        'nau', 'ne', 'nel', 'nem', 'nen',
        'ni', 'no', 'nos', 'nu', 'nua',
        'num', 'nun', 'nus', ('n'+[string][char]0x00E1), ('n'+[string][char]0x00E3),
        ('n'+[string][char]0x00E3+'o'), ('n'+[string][char]0x00E9), ('n'+[string][char]0x00F3), ('n'+[string][char]0x00F3+'s'), 'o',
        'oba', 'obs', 'ode', 'oh', 'oi',
        'ok', ('ol'+[string][char]0x00E1), 'ora', 'ore', 'oro',
        'os', ('os'+[string][char]0x00E9), 'ou', 'ouo', 'ovo',
        'oxi', 'paf', 'pai', 'par', 'pas',
        'pau', 'paz', 'pcs', 'pe', 'pel',
        'per', 'pi', 'pia', 'pio', 'pis',
        'piu', 'pm', 'pmc', 'po', 'por',
        'pos', 'pra', 'pro', ('pr'+[string][char]0x00E9), ('pr'+[string][char]0x00F3),
        'pus', ('p'+[string][char]0x00E1), ('p'+[string][char]0x00E1+'s'), ('p'+[string][char]0x00E3+'o'), ('p'+[string][char]0x00E9),
        ('p'+[string][char]0x00E9+'s'), ('p'+[string][char]0x00F3), ('p'+[string][char]0x00F4), ('p'+[string][char]0x00F4+'r'), ('p'+[string][char]0x00F4+'s'),
        ('p'+[string][char]0x00F5+'e'), 'qtd', 'qua', 'que', 'qui',
        'quo', ('qu'+[string][char]0x00EA), 're', 'rei', 'rem',
        'ren', 'res', 'rez', 'ri', 'rio',
        'rir', 'riu', 'rol', 'ru', 'rua',
        'rui', 'rum', ('r'+[string][char]0x00E3), ('r'+[string][char]0x00E9), ('r'+[string][char]0x00E9+'s'),
        ('r'+[string][char]0x00EA+'s'), 'sai', 'sal', 'se', 'sei',
        'sem', 'sen', 'seq', 'ser', 'ses',
        'set', 'seu', 'si', 'sim', 'soa',
        'sob', 'soe', 'sol', 'som', 'sou',
        'sr', 'sra', 'srs', 'sua', 'sub',
        'sul', 'sus', ('s'+[string][char]0x00E3), ('s'+[string][char]0x00E3+'o'), ('s'+[string][char]0x00E9),
        ('s'+[string][char]0x00F3), ('s'+[string][char]0x00F3+'s'), 'ta', 'tal', 'tao',
        'tb', 'te', 'tem', 'ter', 'teu',
        'tez', 'ti', 'tia', 'tio', 'to',
        'tom', 'ton', 'top', 'tos', 'tu',
        'tua', 'tui', 'tum', 'tv', ('t'+[string][char]0x00E1),
        ('t'+[string][char]0x00E3+'o'), ('t'+[string][char]0x00E9), ('t'+[string][char]0x00EA), ('t'+[string][char]0x00EA+'m'), ('t'+[string][char]0x00F4),
        'uai', 'uau', 'ufa', 'uh', 'ui',
        'um', 'uma', 'un', 'uns',
        'us', 'usa', 'use', 'uso', ('us'+[string][char]0x00E1),
        'uva', 'vai', 've', 'vem', 'ver',
        'vez', 'vi', 'via', 'vil', 'vim',
        'vir', 'viu', 'voa', 'voo', 'vos',
        'vou', 'vu', ('v'+[string][char]0x00E1), ('v'+[string][char]0x00E3+'o'), ('v'+[string][char]0x00EA),
        ('v'+[string][char]0x00EA+'m'), ('v'+[string][char]0x00F3), ('v'+[string][char]0x00F3+'s'), ('v'+[string][char]0x00F4), 'xam',
        'xar', 'xis', ('x'+[string][char]0x00E1), ('x'+[string][char]0x00F4), 'zip',
        'zoo', 'zum', ('z'+[string][char]0x00E9), ([string][char]0x00E0), ([string][char]0x00E0+'s'),
        ([string][char]0x00E1), ([string][char]0x00E2), ([string][char]0x00E3), ([string][char]0x00E9), ([string][char]0x00EA),
        ([string][char]0x00F3), ([string][char]0x00F4)
)) { [void]$script:CurtasPtBr.Add($w) }

function Test-PalavraPtBr {
    # Para <=3 letras manda a lista fechada; o dicionario grande nao opina.
    # Excecao: TODA em maiuscula e sigla (TV, MJ, FBI) - nao se julga aqui.
    param([string]$P, $Dicionario)
    if ([string]::IsNullOrEmpty($P)) { return $false }
    $semHifen = $P -replace '-', ''
    if ($semHifen.Length -le 3) {
        <#  2.25: a excecao de sigla estava fazendo o CONTRARIO do que o
            comentario acima promete. "TODA em maiuscula nao se julga aqui"
            virava, no codigo, "TODA em maiuscula vai para o dicionario de
            1,3M" - e la dentro INF, TOR, TOL e NET existem todos, porque o
            dicionario carrega sigla de qualquer idioma. Era a mesma
            armadilha do "INF TOL", entrando pela porta dos fundos.
            Sigla curta agora responde $true e ninguem mexe nela: nao se
            conserta o que nao se sabe ler. E o mesmo motivo por que o
            "Ja VOU" continua quieto - a regra que o consertaria estragaria
            o "IA" de "sistema de IA", sigla de verdade no mesmo arquivo. #>
        if ($P -ceq $P.ToUpperInvariant() -and $P -cne $P.ToLowerInvariant()) { return $true }
        return $script:CurtasPtBr.Contains($P)
    }
    return (Test-NoDicionario $P $Dicionario)
}

function Test-BlocoEhPtBr {
    # Guarda contra fala em outra lingua dentro da legenda ("No lo entiendo"):
    # ali o "lo" esta certo e trocar seria criar erro onde nao havia.
    # So olha palavras de 4+ letras: as curtas sao as suspeitas (nao votam
    # sobre si mesmas) e nome proprio nao esta em dicionario nenhum.
    param([string]$Texto, $Dicionario)
    $longas = @([regex]::Matches($Texto, '[\p{L}]{4,}') | ForEach-Object { $_.Value })
    if ($longas.Count -eq 0) { return $true }
    $ok = 0
    foreach ($l in $longas) { if (Test-NoDicionario $l $Dicionario) { $ok++ } }
    return ((($ok * 1.0) / $longas.Count) -ge 0.50)
}

function Get-TrocaBarraVertical {
    # Devolve a palavra corrigida, ou "" se nao ha troca segura.
    # Exige UM unico candidato valido - com dois, a escolha seria chute.
    param([string]$P, $Dicionario, [bool]$AbreFrase)
    if ([string]::IsNullOrEmpty($P)) { return "" }
    if ($P -match '\d') { return "" }                 # "US$ 100" nao vira "US$ I00"
    if (Test-PalavraPtBr $P $Dicionario) { return "" }
    $cands = New-Object 'System.Collections.Generic.List[string]'
    for ($i = 0; $i -lt $P.Length; $i++) {
        $ch = $P.Substring($i, 1)
        if ($ch -cne 'l' -and $ch -cne 't' -and $ch -ne '|') { continue }
        $c = ($P.Substring(0, $i) + 'i' + $P.Substring($i + 1)).ToLowerInvariant()
        if ($c -eq $P.ToLowerInvariant()) { continue }
        if ((Test-PalavraPtBr $c $Dicionario) -and -not $cands.Contains($c)) { [void]$cands.Add($c) }
    }
    if ($cands.Count -ne 1) { return "" }
    $novo = $cands[0]
    # A caixa vem da POSICAO na frase, nao do que o OCR leu: "la mesmo" abre a
    # fala e vira "Ia"; "onde tr" esta no meio e vira "ir". Decidir pela letra
    # original dava "onde Ir" - um erro novo no lugar do velho.
    $ini = $P.Substring(0,1)
    if ($AbreFrase -or ($ini -ceq $ini.ToUpperInvariant() -and $ini -cne $ini.ToLowerInvariant())) {
        $novo = $novo.Substring(0,1).ToUpperInvariant() + $novo.Substring(1)
    }
    return $novo
}

function Repair-FamiliaBarraVertical {
    param([string]$Texto, $Dicionario)
    if ([string]::IsNullOrEmpty($Texto)) { return $Texto }
    $ehPt = Test-BlocoEhPtBr $Texto $Dicionario
    $partes = [regex]::Split($Texto, '(\s+)')
    $saida = New-Object System.Text.StringBuilder
    $primeiro = $true
    $reticencias = [string][char]0x2026
    $travessao   = [string][char]0x2013
    $travessaoL  = [string][char]0x2014
    foreach ($parte in $partes) {
        if ($parte -match '^\s*$') { [void]$saida.Append($parte); continue }
        # Token sem letra nenhuma (traco de dialogo, reticencias) vai inteiro:
        # picotar em prefixo/sufixo devolvia comprimento negativo e duplicava
        # o traco ("- Ol," virava "-- Ol,").
        if ($parte -notmatch '[\p{L}|]') { [void]$saida.Append($parte); continue }
        $pref = ([regex]::Match($parte, '^[^\p{L}\d|]*')).Value
        $suf  = ([regex]::Match($parte, '[^\p{L}\d|]*$')).Value
        $tam  = $parte.Length - $pref.Length - $suf.Length
        if ($tam -le 0) { [void]$saida.Append($parte); continue }
        $nu = $parte.Substring($pref.Length, $tam)
        # "Abre frase" olha o que veio ANTES: em "Quero. la ser otimo" o ponto
        # esta grudado na palavra anterior, nao no prefixo deste token.
        $ateAqui = $saida.ToString()
        $abre = $primeiro -or
                ($ateAqui -match ('[.!?:' + $reticencias + '][")\]]?\s*$')) -or
                ($pref -match ('[.!?:\-' + $travessao + $travessaoL + ']\s*$')) -or
                ($pref.Trim() -eq '-') -or ($pref.Trim() -eq '"')
        # --- pipe solto grudado na palavra: "|Isso" -> "Isso"
        if ($nu.Contains('|')) {
            $semPipe = $nu -replace '\|', ''
            if ($semPipe -ne "" -and (Test-PalavraPtBr $semPipe $Dicionario)) {
                $script:RepairMexeu = $true; $nu = $semPipe
            }
        }
        # --- letra dobrada com caixa trocada: "oO local" -> "o local"
        $mDob = [regex]::Match($nu, '^([\p{Ll}])([\p{Lu}])(.*)$')
        if ($mDob.Success -and
            ($mDob.Groups[1].Value.ToLowerInvariant() -eq $mDob.Groups[2].Value.ToLowerInvariant())) {
            $cand = $mDob.Groups[1].Value + $mDob.Groups[3].Value
            if ($mDob.Groups[3].Value -eq "" -or (Test-PalavraPtBr $cand $Dicionario)) {
                $script:RepairMexeu = $true; $nu = $cand
            }
        }
        # --- barra vertical: l / t / | lidos no lugar de i / I
        if ($ehPt) {
            $troca = Get-TrocaBarraVertical $nu $Dicionario $abre
            if ($troca -ne "") { $script:RepairMexeu = $true; $nu = $troca }
        }
        if ($nu -match '\p{L}') { $primeiro = $false }
        [void]$saida.Append($pref + $nu + $suf)
    }
    return $saida.ToString()
}

function Repair-ErrosClassicos {
    param([string]$Texto, $Dicionario, $Nomes)
    if (-not $Dicionario) { return $Texto }
    if ($null -eq $Nomes) { $Nomes = New-Object 'System.Collections.Generic.HashSet[string]' }

    $script:RepairMexeu = $false
    $resultado = $Texto

    # ---- REGRA 0 (v2.7): "armar-los" com acento -> "arma-los".
    # Em portugues o infinitivo PERDE o 'r' quando recebe o pronome enclitico:
    # "armar" + "los" = "armá-los", nunca "armár-los". A sequencia "vogal
    # acentuada + r + hifen + pronome" e gramaticalmente IMPOSSIVEL, entao a
    # troca e 100% segura, sem dicionario e sem excecao.
    # Achado no Troia: armár-los, queimár-lo, Comandár-los.
    $vogaisAcent = 'aeiou' + [string][char]0x00E1 + [string][char]0x00E9 + [string][char]0x00ED + [string][char]0x00F3 + [string][char]0x00FA
    $classeAcent = '[' + [string][char]0x00E1 + [string][char]0x00E9 + [string][char]0x00ED + [string][char]0x00F3 + [string][char]0x00FA + [string][char]0x00C1 + [string][char]0x00C9 + [string][char]0x00CD + [string][char]0x00D3 + [string][char]0x00DA + ']'
    $resultado = [regex]::Replace($resultado,
        '(' + $classeAcent + ')r-(lo|la|los|las|no|na|nos|nas|me|te|se|lhe|lhes)(?![\p{L}])', {
        param($m)
        $script:RepairMexeu = $true
        return ($m.Groups[1].Value + '-' + $m.Groups[2].Value)
    })

    # ---- REGRA A: ordinal masculino/feminino trocado.
    # O 'o' e o 'a' sobrescritos sao dois desenhos minusculos e quase iguais -
    # o OCR troca um pelo outro o tempo todo. Mas a concordancia em portugues
    # e obrigatoria: "vez" e feminino, ponto. Zero ambiguidade, zero risco.
    $ordMasc = [char]0x00BA   # o sobrescrito
    $ordFem  = [char]0x00AA   # a sobrescrito

    <#  v2.21 - A REGRA ERA UMA LISTA DE EXCECAO, E A MEDIDA PROVOU.
        Auditoria do Spider-Man de 25/08, .srt final contra o do BluRay:
        seis ocorrencias de "2<masc> chance" foram corrigidas e CINCO passaram:
            "Conhece a 4<masc> Emenda?"        -> era 4<fem>
            "as mesmas 2<masc>s opcoes"        -> era 2<fem>s
            "Chegou a 1<masc>!"                -> era 1<fem>
            "Era 2<masc> opcao."               -> era 2<fem>
            "simbolo das 2<masc>s chances"     -> era 2<fem>s
        Motivo unico: "chance" estava na lista de substantivos e "Emenda",
        "opcao", "opcoes" e "chances" nao. Uma lista de palavras nunca vai
        cobrir o substantivo do proximo filme - e a regra do projeto e clara:
        "nao e uma solucao para pouca coisa, e uma solucao geral".

        Agora sao QUATRO camadas, da mais especifica para a mais geral, e a
        primeira que decidir manda:

        1. SUBSTANTIVO NA LISTA (o que ja existia) - continua sendo a mais
           confiavel quando acerta.
        2. PLURAL NORMALIZADO - "chances" cai para "chance", "opcoes" cai
           para "opcao". Antes o "s" final fazia a consulta falhar sozinha.
        3. TERMINACAO PRODUTIVA - em portugues o sufixo carrega o genero sem
           excecao pratica: -cao/-coes, -dade, -agem, -eza, -ura, -ncia,
           -tude, -ice sao femininos; -mento, -ismo sao masculinos. Isso vale
           para QUALQUER palavra nova, inclusive a que ainda nao existe.
        4. DETERMINANTE ANTES DO NUMERO - "a 4<masc> Emenda", "as mesmas
           2<masc>s opcoes", "Chegou a 1<masc>!". O artigo/pronome que vem
           antes ja concorda com o substantivo, entao ele denuncia o genero
           mesmo quando a palavra seguinte e desconhecida - ou quando nao ha
           palavra nenhuma depois, que e o caso do "Chegou a 1<masc>!".

        A ordem importa: o substantivo conhecido sempre vence o determinante,
        para que "ao 1<masc> andar" nao seja arrastado pelo "a" da contracao.
        Se nenhuma camada decidir, NAO MEXE - a regra continua sem chutar. #>

    $femTerm  = @('cao','coes','dade','dades','agem','agens','eza','ezas','ura','uras','ncia','ncias','tude','tudes','ice','ices','sao','soes')
    $mascTerm = @('mento','mentos','ismo','ismos')
    $detFem   = @('a','as','uma','umas','essa','essas','esta','estas','aquela','aquelas','minha','minhas','sua','suas','nossa','nossas','mesma','mesmas','outra','outras','toda','todas','primeira','segunda','terceira','da','das','na','nas','pela','pelas')
    $detMasc  = @('o','os','um','uns','esse','esses','este','estes','aquele','aqueles','meu','meus','seu','seus','nosso','nossos','mesmo','mesmos','outro','outros','todo','todos','primeiro','segundo','terceiro','do','dos','no','nos','pelo','pelos','ao','aos')

    <#  Decide o genero do substantivo. Devolve 'F', 'M' ou '' (nao sei). #>
    $GeneroDaPalavra = {
        param([string]$Palavra)
        if ([string]::IsNullOrWhiteSpace($Palavra)) { return '' }
        $k = (Get-SemAcento $Palavra).ToLowerInvariant()
        # camada 1 - lista
        if ($script:OrdFeminino.Contains($k))  { return 'F' }
        if ($script:OrdMasculino.Contains($k)) { return 'M' }
        # camada 2 - plural normalizado
        if ($k.Length -gt 3 -and $k.EndsWith('s')) {
            $sing = $k.Substring(0, $k.Length - 1)
            if ($script:OrdFeminino.Contains($sing))  { return 'F' }
            if ($script:OrdMasculino.Contains($sing)) { return 'M' }
            # "opcoes" -> "opcao"
            if ($k.EndsWith('oes')) {
                $sing2 = $k.Substring(0, $k.Length - 3) + 'ao'
                if ($script:OrdFeminino.Contains($sing2))  { return 'F' }
                if ($script:OrdMasculino.Contains($sing2)) { return 'M' }
            }
        }
        # camada 3 - terminacao produtiva
        foreach ($t in $mascTerm) { if ($k.Length -gt $t.Length -and $k.EndsWith($t)) { return 'M' } }
        foreach ($t in $femTerm)  { if ($k.Length -gt $t.Length -and $k.EndsWith($t)) { return 'F' } }
        return ''
    }

    <#  O indicador pode vir com "s" de plural colado: "2<masc>s opcoes".
        Grupo 3 captura esse "s" para devolve-lo intacto. #>
    <#  O grupo 5 captura a palavra seguinte DENTRO do proprio padrao.
        Primeira versao lia essa palavra com $m.Input.Substring(...) - e
        System.Text.RegularExpressions.Match NAO tem propriedade Input. O
        retorno era $null, a palavra saia sempre vazia, e as camadas 1 a 3
        nunca chegavam a rodar: so o determinante decidia. O teste pegou:
        "Era 2<masc> opcao" falhava (nenhum determinante) enquanto
        "as mesmas 2<masc>s opcoes" passava - mesma familia, resultado
        diferente, que e a assinatura de camada morta.
        Como o grupo 5 faz parte do match, o texto dele e devolvido junto na
        substituicao - por isso ele e reinserido no retorno. #>
    <#  v2.24: "as mesmas 2<masc>?s opcoes" (Spider 00:14:56). A regra
        acertava o genero e devolvia "2<fem>?s" - com o '?' do OCR ainda no
        meio. Correcao pela metade sobrando na tela e defeito nosso.
        O (?:[\?\*](?=s))? come esse lixo, e SO quando vem um 's' logo
        depois - senao "Chegou a 1<fem>?" (pergunta de verdade) perderia a
        interrogacao. #>
    $padraoOrd = '(?<=^|[^\p{L}\d])((?:[\p{L}]+\s+)?)(\d+)([' + $ordMasc + $ordFem + '])(?:[\?\*](?=s))?(s?)(\s+[\p{L}]+)?'
    $resultado = [regex]::Replace($resultado, $padraoOrd, {
        param($m)
        $antes = $m.Groups[1].Value
        $num   = $m.Groups[2].Value
        $ind   = $m.Groups[3].Value
        $plu   = $m.Groups[4].Value
        $cauda = $m.Groups[5].Value

        $depois = $cauda.Trim()

        $g = & $GeneroDaPalavra $depois

        # camada 4 - o determinante antes do numero
        if ($g -eq '') {
            $det = (Get-SemAcento $antes.Trim()).ToLowerInvariant()
            if ($det -ne '') {
                if ($detFem.Contains($det))  { $g = 'F' }
                elseif ($detMasc.Contains($det)) { $g = 'M' }
            }
        }

        if ($g -eq 'F' -and $ind -ceq $ordMasc) { $script:RepairMexeu = $true; return ($antes + $num + $ordFem  + $plu + $cauda) }
        if ($g -eq 'M' -and $ind -ceq $ordFem)  { $script:RepairMexeu = $true; return ($antes + $num + $ordMasc + $plu + $cauda) }
        return $m.Value
    })

    # ---- REGRA B: "E claro." / "E isso." -> com acento.
    # A linha inteira e "E" + UMA palavra predicativa + pontuacao final. Sem
    # verbo, a conjuncao "e" nao tem o que ligar - so o verbo "e-agudo" fecha
    # a frase. "E claro que ele veio" tem verbo e por isso NAO casa aqui.
    $eAgudo = [string][char]0x00C9
    $listaPred = (($script:Predicativos) | Sort-Object { $_.Length } -Descending) -join '|'
    <#  v2.15: O IgnoreCase FAZIA ESTA REGRA ESTRAGAR LEGENDA BOA.
        Todo o raciocinio acima e sobre o "E" MAIUSCULO ("sem verbo, a
        conjuncao 'e' nao tem o que ligar"). Mas o IgnoreCase no fim da
        chamada fazia o literal "E " casar tambem com "e " minusculo - e o
        (?m)^ casa no inicio de CADA LINHA do bloco, nao so da fala.
        Entao uma legenda perfeita quebrada em duas linhas, que e o normal:
            Foi mais rapido
            e melhor.
        virava "Foi mais rapido / E-agudo melhor.". A lista de predicativos
        tem 18 palavras dessas (facil, pior, certo, claro...), e esta regra
        roda em TODOS os blocos, nao so nos alienigenas - ou seja, o alvo
        era legenda que estava certa.
        Agora o "E" e comparado com caixa (que e a premissa da regra) e so a
        palavra predicativa continua sem distinguir maiuscula. #>
    $resultado = [regex]::Replace($resultado,
        '(?m)^([\-' + [char]0x2013 + ']?[ ]?)E (?i:(' + $listaPred + '))(?=[.!?' + [char]0x2026 + ']*[ ]*$)', {
        param($m)
        $script:RepairMexeu = $true
        return ($m.Groups[1].Value + $eAgudo + ' ' + $m.Groups[2].Value)
    })

    <#  ---- REGRA A2 (v2.24): ':' ou '=' COLADO NO MEIO DA PALAVRA.
        Caso real do Se7en (00:33:17): "-O:i, idiota." - era "-Oi, idiota.".
        Os dois pontos sao o desenho de dois pingos que o OCR enfia entre
        duas letras. A trava e o dicionario: so tira o sinal se a palavra
        SEM ele existir em portugues. "INF=TOR" -> "INFTOR" nao existe,
        entao esse nao e tocado (e ele ja tem dono: o re-OCR).
        Nao encosta em ':' de pontuacao normal ("Um aviso:") porque exige
        letra dos DOIS lados. #>
    $resultado = [regex]::Replace($resultado, '[\p{L}]+[:=][\p{L}]+', {
        param($m)
        # Bloco-lixo TODO em caixa alta ("INF=TOR") nao e assunto desta
        # regra - ele ja tem dono, que e o re-OCR. Polir aqui so apagaria a
        # assinatura que o detector usa pra achar ele.
        if ($m.Value -ceq $m.Value.ToUpperInvariant()) { return $m.Value }
        $limpa = $m.Value -replace '[:=]', ''
        if ($Nomes.Contains($limpa)) { $script:RepairMexeu = $true; return $limpa }
        <#  2.26: aqui tambem valia a regra da casa e nao valia. Com 'a:s',
            'e:s' ou 'n:o' a palavra limpa fica com 2 letras, e 'as', 'es' e
            'no' existem no dicionario de 1,3M - ou seja, dois pontos de
            pontuacao legitima podiam ser APAGADOS com aval de um dicionario
            que ninguem devia estar consultando nesse tamanho.
            A troca e para Test-PalavraPtBr, que desde a 2.25 ja faz a coisa
            certa: abaixo de 4 letras manda para a lista FECHADA de curtas e
            nem encosta no dicionario grande. Com isso o 'O:i' -> 'Oi' do
            Se7en continua funcionando ('oi' esta na lista fechada) e o
            'n:et', 't:or' e 'i:nf' param de virar 'net', 'tor' e 'inf' -
            a regra estava FABRICANDO a familia de sigla que o re-OCR caca.
            ('a:s' e 'n:o' seguem iguais: essas estao na lista fechada.) #>
        if (Test-PalavraPtBr $limpa $Dicionario) { $script:RepairMexeu = $true; return $limpa }
        return $m.Value
    })

    # ---- REGRA C: palavra a palavra (l<->i, caixa, glifo partido)
    $resultado = [regex]::Replace($resultado, '[\p{L}]{3,}', {
        param($m)
        $p = $m.Value
        if ($Nomes.Contains($p)) { return $p }
        $garbling = ($p -cmatch '[\p{Ll}][\p{Lu}]')
        # v2.10: marca conhecida escrita em CamelCase nao e garbling.
        # Sem isto, o dicionario de 1,3M faz "BuzzFeed" virar "buzzfeed".
        if ($garbling -and (Test-EhMarcaCamel $p)) { return $p }
        if ((Test-NoDicionario $p $Dicionario) -and -not $garbling) { return $p }

        # O @() e OBRIGATORIO: sem ele o PowerShell desembrulha a lista de 1
        # elemento num string solto, e $cands[0] devolve a primeira LETRA em
        # vez da palavra ("Sel" virava "S", "MOrTrer" virava "m").
        # v2.7: nao troca l/i em palavra curta TODA MAIUSCULA. No Troia isso
        # "consertava" o bloco-lixo "INF TOL" pra "INF TOI" - lixo virando
        # outro lixo. Esses blocos vao pra 2a opiniao ou pra mao de qualquer
        # jeito; polir eles so suja o relatorio.
        $curtaMaiuscula = ($p.Length -lt 5 -and $p -ceq $p.ToUpperInvariant())
        if (-not $curtaMaiuscula) {
            $cands = @(Get-CandidatosTrocaLI $p $Dicionario)
            if ($cands.Count -eq 1) { $script:RepairMexeu = $true; return $cands[0] }
        }

        if ($garbling) {
            # palavra com maiuscula no meio ja E prova de lixo - aqui pode
            # apagar qualquer letra ("MOrTrer" -> "morrer")
            #
            # v2.10 - COMECO DE FRASE NAO PODE PERDER A MAIUSCULA.
            # Este ramo baixava a caixa da palavra inteira. Quando o lixo
            # estava no comeco da fala ("AiNda esta aqui.") o conserto saia
            # "ainda esta aqui." - trocava um defeito por outro, menor mas
            # visivel. Se a palavra vinha capitalizada E esta em inicio de
            # frase, devolvo o conserto capitalizado. No meio da frase segue
            # tudo minusculo, que e o certo pro "OU MOrTrer." -> "ou morrer."
            $inicioFrase = $false
            if ($p -cmatch '^[\p{Lu}]') {
                $antesDaPalavra = ""
                if ($m.Index -gt 0) { $antesDaPalavra = $resultado.Substring(0, $m.Index).TrimEnd(" `t") }
                if ($antesDaPalavra.Length -eq 0) {
                    $inicioFrase = $true
                } else {
                    $ult = $antesDaPalavra[$antesDaPalavra.Length - 1]
                    $fechaFrase = ".!?" + [char]0x2026 + "`n`r" + [char]0x201C + '"' + [char]0x2013 + "-"
                    if ($fechaFrase.IndexOf($ult) -ge 0) { $inicioFrase = $true }
                }
            }
            $baixa = $p.ToLowerInvariant()
            if (Test-NoDicionario $baixa $Dicionario) {
                $script:RepairMexeu = $true
                if ($inicioFrase) { return ($baixa.Substring(0,1).ToUpperInvariant() + $baixa.Substring(1)) }
                return $baixa
            }
            $del = @(Get-CandidatosDelecao $baixa $Dicionario)
            if ($del.Count -eq 1) {
                $script:RepairMexeu = $true
                if ($inicioFrase) { return ($del[0].Substring(0,1).ToUpperInvariant() + $del[0].Substring(1)) }
                return $del[0]
            }
        } elseif ($p.Length -ge 4) {
            # palavra normal: so o traco partido ("Pali" -> "Pai")
            $del = @(Get-CandidatosDelecaoFina $p $Dicionario)
            if ($del.Count -eq 1) { $script:RepairMexeu = $true; return $del[0] }
        }
        return $p
    })

    # ---- REGRA D: caixa alta em palavra funcional curta.
    # v2.7: passou a rodar sempre, nao so em bloco ja marcado como lixo. No
    # Troia apareceu "OS rumores estavam certos." num bloco limpo no resto.
    # A trava continua sendo a linha: se a linha INTEIRA e maiuscula, e placa
    # ou grito do legendador e nao se toca. Palavra funcional de 2-4 letras em
    # caixa alta no meio de uma linha normal e sempre erro de OCR.
    if ($true) {
        $linhas = $resultado -split "`n"
        for ($i = 0; $i -lt $linhas.Count; $i++) {
            $ln = $linhas[$i]
            if ($ln -cnotmatch '[\p{Ll}]') { continue }
            if ($ln.Trim() -ceq $ln.Trim().ToUpperInvariant()) { continue }
            # v2.8 REGRESSAO MINHA: esta regra virou "pulso EM" em "pulso em"
            # 2 vezes no Homem-Aranha. "EM" ali e SIGLA (pulso eletromagnetico),
            # nao a preposicao. Agora so age no COMECO da linha, que era onde
            # os casos reais estavam ("OS rumores", "OU MOrTrer"). No meio da
            # frase, palavra em caixa alta e sigla ate prova em contrario.
            $linhas[$i] = [regex]::Replace($ln, '^[\p{Lu}]{2,4}(?![\p{L}])', {
                param($m)
                if ($script:FuncionaisCaixa.Contains($m.Value)) { return $m.Value.ToLowerInvariant() }
                return $m.Value
            })
        }
        $resultado = $linhas -join "`n"
    }


    <#
      v2.13: a familia "Ir". Ver o comentario grande do $script:FuncionaisMeio.
      A palavra so cai pra minuscula se: esta no meio da frase (lookbehind de
      letra minuscula + espaco), tem forma Xxx, a proxima palavra NAO comeca
      com maiuscula, e nao e nome proprio conhecido do arquivo.
    #>
    $script:NomesAtuais = $Nomes
    $resultado = [regex]::Replace($resultado,
        '(?<=[\p{Ll}][ \n])([\p{Lu}][\p{Ll}]+)(?![\p{L}])(?![ \n][\p{Lu}])', {
        param($m)
        $p = $m.Groups[1].Value
        if ($script:NomesAtuais -and $script:NomesAtuais.Contains($p)) { return $p }
        if (-not $script:FuncionaisMeio.Contains($p.ToLowerInvariant())) { return $p }
        $script:RepairMexeu = $true
        return $p.ToLowerInvariant()
    })

    # v2.5: "E" circunflexo sozinho e sempre "E" agudo lido errado. O
    # circunflexo maiusculo isolado nao existe como palavra em portugues.
    $eCircunflexo = [string][char]0x00CA
    $resultado = [regex]::Replace($resultado, '(?<![\p{L}])' + $eCircunflexo + '(?![\p{L}])', $eAgudo)

    # ---- REGRA V (v2.16): cifrao lido como S. "USS 100" / "USS$ 12".
    # O "$" tem a haste vertical do "S" - mesmo par de glifos da familia da
    # barra. Exige numero logo depois, senao mexeria em sigla qualquer.
    $resultado = [regex]::Replace($resultado, '\bUSS\$', 'US$')
    $resultado = [regex]::Replace($resultado, '\bUSS(?=\s+\d)', 'US$')

    # ---- REGRA W (v2.16): familia da barra vertical (l / t / | -> i / I),
    # pipe solto e letra dobrada com caixa trocada. Ver o bloco grande acima
    # de Test-PalavraPtBr.
    $resultado = Repair-FamiliaBarraVertical $resultado $Dicionario

    <#  ---- REGRA X (v2.19): ASPAS CURVAS PICOTADAS.
        Spider-Man 22/08, bloco 652. O disco tem  como "por favor".  e o OCR
        devolveu tres linhas:
            como '
            fo) 1
            por favor"
        As aspas tipograficas (U+201C/U+201D) sao um glifo que o Tesseract nao
        casa com nenhuma letra; ele quebra a linha em volta delas e cospe um
        token sem sentido no meio ("fo) 1").
        A trava e estreita de proposito: so age quando a linha do meio NAO tem
        nenhuma palavra de 2+ letras que exista em portugues E esta cercada de
        linhas que tem. Assim ela remove o caco e junta a frase, sem tocar em
        bloco onde as tres linhas sao fala de verdade. Bloco de 1 ou 2 linhas
        nunca entra aqui.  #>
    $linhasX = @($resultado -split "`n")
    if ($linhasX.Count -eq 3) {
        $meio = $linhasX[1].Trim()
        <#  v2.20 - POR QUE A LINHA DO MEIO NAO PODE SER JULGADA PELO DIC DE 1,3M.
            Medido no Spider-Man de 25/08. A 2.19 juntou o bloco 1529
            ("Na Terra e no espaco. / s / E, ele era roxo.") mas deixou passar
            o 652:
                como '
                fo) 1
                por favor"
            A linha do meio e 'fo) 1'. O unico token de 2+ letras e "fo" - e
            "fo" EXISTE no dicionario de 1,3M, que nao e dicionario e sim
            despejo de corpus (1.588 das 1.662 entradas de duas letras nao sao
            portugues). Logo temPalavraMeio virava $true e a regra desistia.
            Exatamente a armadilha ja registrada no AUDITORIA_legenda_raio_x:
            o dicionario grande chancela justamente os cacos que o OCR produz.
            Correcao: palavra de ate 3 letras e julgada pela LISTA FECHADA das
            472 palavras curtas reais do portugues (Test-CurtaComum), nao pelo
            dicionario. De 4 letras pra cima o dicionario volta a valer, porque
            ali ele nao tem esse problema. #>
        $temPalavraMeio = $false
        foreach ($w in @([regex]::Matches($meio, '[\p{L}]{2,}') | ForEach-Object { $_.Value })) {
            if ($w.Length -le 3) {
                if (Test-CurtaComum $w) { $temPalavraMeio = $true; break }
            } elseif (Test-NoDicionario $w $Dicionario) {
                $temPalavraMeio = $true; break
            }
        }
        $bordasOk = $true
        foreach ($idx in @(0, 2)) {
            $achou = $false
            foreach ($w in @([regex]::Matches($linhasX[$idx], '[\p{L}]{2,}') | ForEach-Object { $_.Value })) {
                if (Test-NoDicionario $w $Dicionario) { $achou = $true; break }
            }
            if (-not $achou) { $bordasOk = $false; break }
        }
        if ($bordasOk -and -not $temPalavraMeio -and $meio -ne "" -and $meio.Length -le 12) {
            $topo  = $linhasX[0].Trim()
            $baixo = $linhasX[2].Trim()
            <#  v2.20 - AS DUAS ASPAS ORFAS.
                No caso real (bloco 652) o que sobra nas bordas e:
                    topo  = como '
                    baixo = por favor"
                O disco tem  como "por favor".  - as aspas tipograficas viraram
                uma apostrofe e uma aspa reta, e o caco do meio era o restante
                do desenho delas. Juntar cru daria  como ' por favor"  , que e
                menos errado mas ainda sujo.
                Quando o topo termina em aspa solta E o baixo termina em aspa,
                as duas sao o MESMO par: normalizo para aspa reta e junto sem
                espaco depois da de abertura. Nao invento o ponto final que o
                OCR perdeu - o resultado e 'como "por favor"', que e o que a
                imagem sustenta, nada alem disso. #>
            $aspas = "'" + '"' + [string][char]0x2018 + [string][char]0x2019 + [string][char]0x201C + [string][char]0x201D
            $topoTemAspaSolta  = ($topo.Length -ge 2) -and ($aspas.Contains($topo[$topo.Length - 1])) -and ($topo[$topo.Length - 2] -eq ' ')
            $baixoTermEmAspa   = ($baixo.Length -ge 1) -and ($aspas.Contains($baixo[$baixo.Length - 1]))
            if ($topoTemAspaSolta -and $baixoTermEmAspa) {
                $topoLimpo  = $topo.Substring(0, $topo.Length - 1).TrimEnd()
                $baixoLimpo = $baixo.Substring(0, $baixo.Length - 1).TrimEnd()
                $juntada = $topoLimpo + ' "' + $baixoLimpo + '"'
            } else {
                $juntada = ($topo + " " + $baixo)
            }
            $juntada = [regex]::Replace($juntada, "\s+", " ").Trim()
            if ($juntada -ne "") { $resultado = $juntada }
        }
    }

    return $resultado
}

# ============================================================== programa
try {
    $raiz = Get-PastaScript
    $carimbo = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $pastaSaida = Join-Path $raiz "_corretor"
    if (-not (Test-Path -LiteralPath $pastaSaida)) { New-Item -ItemType Directory -Path $pastaSaida -Force | Out-Null }

    Titulo ("LaFirma - Corretor_Legenda v" + $Versao)
    Diz ("Data  : " + (Get-Date -Format "dd/MM/yyyy HH:mm:ss"))
    Diz ("Pasta : " + $raiz)

    # ---------------------------------------------------- selecao de arquivo
    if ($Srt -eq "") {
        try {
            Add-Type -AssemblyName System.Windows.Forms
            [void][System.Windows.Forms.Application]::EnableVisualStyles()

            $d1 = New-Object System.Windows.Forms.OpenFileDialog
            $d1.Title = "Corretor - PASSO 1/2: o .srt que o motor gerou (o que tem os erros)"
            $d1.Filter = "Legenda (*.srt)|*.srt|Todos (*.*)|*.*"
            $d1.InitialDirectory = $raiz
            if ($d1.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $Srt = $d1.FileName }

            if ($Srt -ne "" -and $Mkv -eq "") {
                $d2 = New-Object System.Windows.Forms.OpenFileDialog
                $d2.Title = "Corretor - PASSO 2/2 (OPCIONAL): o .mkv ORIGINAL, pra 2a opiniao do OCR - Cancelar pula"
                $d2.Filter = "Video Matroska (*.mkv)|*.mkv|Todos (*.*)|*.*"
                try { $d2.InitialDirectory = (Split-Path -Parent $Srt) } catch { }
                if ($d2.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $Mkv = $d2.FileName }
            }
        } catch {
            Diz ("[!] Nao consegui abrir a janela de selecao: " + $_.Exception.Message) "Yellow"
        }
    }

    if ($Srt -eq "" -or -not (Test-Path -LiteralPath $Srt)) {
        Diz "[!] .srt nao informado ou nao existe. Encerrando." "Red"
        exit 1
    }
    Diz ("SRT : " + $Srt)
    if ($Mkv -ne "") { Diz ("MKV : " + $Mkv) }

    # -------------------------------------------------------------- dicionario
    $dicionario = Get-DicionarioPtBr $raiz
    if ($dicionario) { Diz ("Dicionario PT-BR: " + $dicionario.Count + " palavras (" + $script:DicionarioArquivo + ")") "DarkGray" }
    else {
        # 2.18: a mensagem dizia so "Auditor_OCR.dic.gz", mas a funcao acima
        # procura os DOIS arquivos (o grande primeiro). Se chegou aqui, nenhum
        # dos dois foi achado - dizer so o nome do pequeno confundia quem lia.
        Diz "[!] Nenhum dicionario PT-BR encontrado (LaFirma_PTBR_1.3M.dic.gz ou Auditor_OCR.dic.gz) - sem ele a deteccao fica muito fraca." "Red"
        Diz "    Coloque o LaFirma_PTBR_1.3M.dic.gz (preferido) ou o Auditor_OCR.dic.gz nesta pasta e rode de novo." "Red"
        exit 1
    }

    # ------------------------------------------------------- procurar o seconv
    if ($Seconv -eq "") {
        $cmd = Get-Command "seconv.exe" -ErrorAction SilentlyContinue
        if ($cmd) { $Seconv = $cmd.Source }
        else {
            foreach ($c in @(
                "C:\Program Files\Subtitle Edit\seconv.exe",
                "C:\Program Files (x86)\Subtitle Edit\seconv.exe",
                (Join-Path $raiz "tools\SubtitleEdit\seconv.exe"),
                (Join-Path $raiz "tools\SubtitleEdit\SubtitleEdit.exe")
            )) {
                if (Test-Path -LiteralPath $c) { $Seconv = $c; break }
            }
        }
    }
    # v2.1: banco de imagem do BinaryOCR - procurado do lado de onde o seconv
    # foi achado (mesma pasta tools\SubtitleEdit\), com fallback pro local
    # padrao do proprio Subtitle Edit em %AppData%. Sem isso, "--ocr-engine:
    # binaryocr" sozinho SEMPRE falha - o motor exige --ocr-db explicito, nao
    # tem banco padrao embutido.
    # v2.6 BUG PRE-EXISTENTE (vinha desde a 2.1, so nao aparecia porque nesta
    # maquina o seconv sempre foi achado): quando o seconv NAO existe, $Seconv
    # fica vazio, o "Split-Path -Parent" recebe string vazia e derruba o script
    # inteiro com ERRO FATAL - antes mesmo de ler a legenda. O certo e seguir
    # sem segunda opiniao, que ja e um caminho previsto mais abaixo.
    $LatinDb = ""
    $ondeProcurar = New-Object System.Collections.Generic.List[string]
    $ondeProcurar.Add((Join-Path $raiz "tools\SubtitleEdit\Latin.db"))
    if ($Seconv -ne "") {
        try { $ondeProcurar.Add((Join-Path (Split-Path -Parent $Seconv) "Latin.db")) } catch { }
    }
    if ($env:APPDATA) { $ondeProcurar.Add((Join-Path $env:APPDATA "Subtitle Edit\Ocr\Latin.db")) }
    foreach ($c in $ondeProcurar) {
        if ($c -and (Test-Path -LiteralPath $c)) { $LatinDb = $c; break }
    }

    # ----------------------------------------------------------- ler e detectar
    $textoBruto = Repair-EstruturaSrt (Ler-TextoComEncoding $Srt)
    $blocos = Parse-Srt $textoBruto
    Diz ("Blocos no SRT: " + $blocos.Count)
    if ($script:ReparosEstrutura -gt 0) {
        Diz ("[!] Consertei " + $script:ReparosEstrutura + " bloco(s) com o FORMATO quebrado (linha em branco no meio do bloco).") "Yellow"
        Diz ("    Sem esse conserto essas falas seriam PERDIDAS - o leitor de .srt as descarta.") "Yellow"
        if ($script:ReparosAcentoE -gt 0) {
            Diz ("    Em " + $script:ReparosAcentoE + " deles o 'E' recuperou o acento (o lixo que saiu era o proprio E-agudo).") "Yellow"
        }
    }

    # ------- v2.6: levantar os nomes proprios ANTES de corrigir qualquer coisa.
    # Precisa do arquivo INTEIRO: a assinatura de nome proprio e "capitalizado,
    # fora do dicionario e REPETIDO". Sem essa lista, as regras novas iriam
    # atras de Priamo, Briseida, Osborn e Oscorp achando que sao erro de OCR.
    $textoTodo = ($blocos | ForEach-Object { $_.Texto }) -join "`n"
    $nomes = Get-NomesProprios $textoTodo $dicionario
    $script:NomesCamel = Get-NomesCamel $textoTodo $dicionario
    if ($nomes.Count -gt 0) {
        $amostra = ((@($nomes) | Sort-Object | Select-Object -First 8) -join ", ")
        if ($nomes.Count -gt 8) { $amostra = $amostra + ", ..." }
        Diz ("Nomes proprios protegidos: " + $nomes.Count + " (" + $amostra + ")") "DarkGray"
    }

    # ------- passo 1: correcoes deterministicas em TODOS os blocos
    $trocasAuto = New-Object System.Collections.Generic.List[object]
    foreach ($b in $blocos) {
        $corrigido = Repair-ErrosClassicos $b.Texto $dicionario $nomes
        # v2.7 BUG: tem que ser -cne, nao -ne. No PowerShell o "-ne" de texto
        # IGNORA maiuscula/minuscula, entao "os rumores" -ne "OS rumores" dava
        # FALSO e a correcao de caixa era jogada fora em silencio - a funcao
        # consertava e o programa descartava sem avisar ninguem.
        if ($corrigido -cne $b.Texto) {
            $trocasAuto.Add((New-Object PSObject -Property ([ordered]@{
                Chave = ($b.Inicio + "|" + $b.Fim); Antigo = $b.Texto; Novo = $corrigido
            })))
            $b.Texto = $corrigido
        }
    }
    if ($trocasAuto.Count -gt 0) {
        Titulo "CORRECOES AUTOMATICAS (padrao conhecido, sem ambiguidade)"
        Diz ("Corrigidos " + $trocasAuto.Count + " bloco(s) por padrao conhecido de OCR:") "Green"
        foreach ($t in $trocasAuto) {
            Diz ("  [" + $t.Chave.Split('|')[0] + "]") "White"
            Diz ("    ANTES : '" + ($t.Antigo -replace "`n", " / ") + "'") "DarkGray"
            Diz ("    DEPOIS: '" + ($t.Novo -replace "`n", " / ") + "'") "Green"
        }
    }

    # ------- passo 2: detectar os alienigenas que sobraram
    $ruins = New-Object System.Collections.Generic.List[object]
    foreach ($b in $blocos) {
        if (Test-BlocoAlienigena $b.Texto $dicionario $nomes) {
            $b | Add-Member -NotePropertyName Motivo -NotePropertyValue $script:UltimoMotivo -Force
            $ruins.Add($b)
        }
    }

    Titulo "BLOCOS ALIENIGENAS ENCONTRADOS"
    if ($ruins.Count -eq 0) {
        Diz "Nenhum bloco alienigena encontrado - esta legenda esta limpa." "Green"
    } else {
        Diz ("Encontrados: " + $ruins.Count + " de " + $blocos.Count + " blocos") "Yellow"
        Diz ""
        foreach ($b in $ruins) {
            Diz ("  [" + $b.Inicio + "]  '" + ($b.Texto -replace "`n", " / ") + "'") "White"
            Diz ("      motivo: " + $b.Motivo) "DarkGray"
        }
    }

    # v2.2: acha a faixa PGS pt-BR de verdade antes de rodar a 2a opiniao.
    # Bug achado no teste real de 12/08 16h43: sem --track-number, o seconv
    # processava TODAS as faixas de legenda do mkv (o log mostrava "#6
    # [eng]" - a faixa SDH em ingles) e o codigo pegava so o .srt MAIOR
    # como se fosse o certo. Resultado: os "corrigidos" pela 2a opiniao
    # viravam texto em INGLES misturado na legenda PT-BR ("Al*ost." em vez
    # de "Quase.") - pior que o lixo original, porque parece corrigido.
    $mkvmergeExe = ""
    foreach ($c in @(
        (Join-Path $raiz "tools\mkvmerge.exe"),
        (Join-Path $raiz "tools\MKVToolNix\mkvmerge.exe")
    )) { if (Test-Path -LiteralPath $c) { $mkvmergeExe = $c; break } }
    $trackPtBr = $null
    $idiomaPtBr = ""
    if ($mkvmergeExe -ne "" -and $Mkv -ne "" -and (Test-Path -LiteralPath $Mkv)) {
        try {
            $json = (& $mkvmergeExe -J "$Mkv" 2>$null) | ConvertFrom-Json
            $candidatas = @($json.tracks | Where-Object {
                $_.type -eq "subtitles" -and $_.properties.codec_id -match "PGS" -and
                ($_.properties.language -in @("por","pob") -or $_.properties.language_ietf -match "^pt")
            })
            # v2.3: BUG REAL - a 2.2 achava a faixa certa e passava o numero
            # ERRADO mesmo assim. O seconv casa o --track-number contra o
            # TrackNumber do MATROSKA (1-based, do cabecalho do .mkv), nao
            # contra o "id" do mkvmerge (0-based, posicional). Confirmado no
            # fonte do seconv (ContainerSubtitleLoader.LoadMatroska) e no do
            # PgsToSrt, que faz "track++" justamente pra converter um no
            # outro. Com o id cru, a 2.2 ia reproduzir exatamente o mesmo
            # estrago em INGLES que ela foi feita pra corrigir.
            # O mkvmerge -J entrega os dois: .id e .properties.number.
            if ($candidatas.Count -gt 0) {
                $trackPtBr = if ($null -ne $candidatas[0].properties.number) { [int]$candidatas[0].properties.number } else { [int]$candidatas[0].id + 1 }
                $idiomaPtBr = if ($candidatas[0].properties.language) { [string]$candidatas[0].properties.language } else { "" }
            }
        } catch { }
    }

    # ------------------------------------------- 2a opiniao via Subtitle Edit
    $srtSegundaOpiniao = ""
    if ($ruins.Count -gt 0 -and $Mkv -ne "" -and (Test-Path -LiteralPath $Mkv)) {
        Titulo "SEGUNDA OPINIAO DO OCR (Subtitle Edit / seconv)"
        if ($PularSegundaOpiniao) {
            # v2.23: o motor ja rodou o seconv neste mesmo .mkv nesta mesma
            # rodada e recusou o resultado. Repetir aqui da o mesmo resultado
            # e custa o mesmo tempo. Ver o comentario do parametro.
            Diz "[i] 2a opiniao PULADA: o motor ja rodou o seconv neste arquivo nesta rodada e recusou o resultado." "Yellow"
            Diz "    Rodar de novo daria a mesma leitura (mesmo programa, mesma imagem, mesmo Latin.db) e custaria o mesmo tempo." "DarkGray"
            Diz "    Os blocos suspeitos seguem para o Reocr_Legenda, que usa outro caminho (Tesseract PSM 6)." "DarkGray"
        } elseif ($null -eq $trackPtBr) {
            Diz "[!] Nao consegui identificar a faixa PGS pt-BR no .mkv (mkvmerge.exe nao achado, ou nenhuma faixa por/pob) - pulando a 2a opiniao pra nao arriscar pegar a faixa errada." "Yellow"
        } elseif ($Seconv -eq "" -or -not (Test-Path -LiteralPath $Seconv)) {
            Diz "[!] seconv/SubtitleEdit NAO encontrado - pulando a segunda opiniao." "Yellow"
            Diz "" "Yellow"
            Diz "    Pra ativar esta parte, instale o Subtitle Edit:" "Cyan"
            Diz "      https://www.nikse.dk/subtitleedit" "Cyan"
            Diz "    ou coloque a pasta dele em tools\SubtitleEdit\ aqui no LaFirma." "Cyan"
            Diz "    Ele traz motores de OCR DIFERENTES do Tesseract (binaryocr, nocr)" "Cyan"
            Diz "    que costumam acertar justamente onde o PgsToSrt erra." "Cyan"
        } else {
            Diz ("seconv: " + $Seconv) "DarkGray"
            Diz ("motor de OCR: " + $Motor + "  (troque com -Motor nocr | tesseract | binaryocr)") "DarkGray"
            if ($Motor -eq "binaryocr" -and $LatinDb -eq "") {
                Diz "[!] Motor binaryocr precisa de Latin.db, e nenhum foi encontrado - a 2a opiniao vai falhar." "Yellow"
                Diz "    Coloque Latin.db em tools\SubtitleEdit\ (do lado do seconv.exe) e rode de novo." "Yellow"
            } elseif ($LatinDb -ne "") {
                Diz ("banco (ocr-db): " + $LatinDb) "DarkGray"
            }
            Diz ""
            Diz "Rodando OCR alternativo no .mkv - isso pode demorar varios minutos..." "White"

            $pastaTmp = Join-Path $pastaSaida ("tmp_" + $carimbo)
            # v2.15: marcada para o finally apagar (ver o fim do arquivo).
            $script:PastaTempCorretor = $pastaTmp
            New-Item -ItemType Directory -Path $pastaTmp -Force | Out-Null
            # v2.2: --track-number aponta pra faixa PT-BR de verdade, achada
            # acima via mkvmerge - sem isso o seconv processava TODAS as
            # faixas de legenda do mkv (incluindo a SDH em ingles) e o codigo
            # so pegava o .srt maior como se fosse o certo.
            # v2.1: --ocr-db so entra quando o motor e binaryocr E o banco foi
            # achado - nocr usa banco .nocr (nao mexido aqui) e tesseract nao
            # usa banco nenhum, entao passar --ocr-db pra eles seria lixo.
            $argsSeconv = @($Mkv, "subrip", ("--track-number:" + $trackPtBr), ("--ocr-engine:" + $Motor), "--ocr-language:por", ("--outputfolder:" + $pastaTmp))
            if ($Motor -eq "binaryocr" -and $LatinDb -ne "") { $argsSeconv += ("--ocr-db:" + $LatinDb) }
            $saidaSe = & $Seconv @argsSeconv 2>&1
            foreach ($ln in @($saidaSe | Select-Object -Last 8)) { Diz ("    " + $ln) "DarkGray" }

            # v2.3: parar de escolher "o .srt MAIOR". O seconv nomeia a saida
            # de faixa de container como "<arquivo>.<idioma>.srt" (ver
            # ResolveOutputFileName no fonte dele), entao da pra conferir o
            # idioma pelo NOME em vez de chutar pelo tamanho - foi o chute
            # pelo tamanho que deixou passar a faixa SDH em ingles na 2.1.
            # Com o --track-number certo (acima) so deve sair um arquivo,
            # mas conferir e de graca e fecha o buraco de vez.
            $gerado = @(Get-ChildItem -LiteralPath $pastaTmp -Filter "*.srt" -ErrorAction SilentlyContinue)
            if ($gerado.Count -gt 0) {
                $escolhido = $null
                if ($idiomaPtBr -ne "") {
                    $escolhido = @($gerado | Where-Object { $_.BaseName -match ("(?i)\." + [regex]::Escape($idiomaPtBr) + "$") }) | Select-Object -First 1
                }
                if ($null -eq $escolhido -and $gerado.Count -eq 1 -and $gerado[0].BaseName -notmatch "\.[A-Za-z]{2,3}$") {
                    # faixa sem idioma declarado no .mkv: o seconv nao poe
                    # sufixo nenhum, e veio um arquivo so - e o que pedimos.
                    $escolhido = $gerado[0]
                }
                if ($null -ne $escolhido) {
                    # v2.4: mesma rede de qualidade que o motor ganhou na 14.6.
                    # O BinaryOCR marca com "*" todo glifo que nao acha no
                    # Latin.db (esta no fonte do seconv: "if (match == null)
                    # matches.Add(new CompareMatch("*", ...))"). Se o banco nao
                    # casa com a fonte do release, a 2a opiniao vem furada - e
                    # ai ela nao corrige nada, so troca um lixo por outro.
                    # Caso real, teste de 13/08 00:28: o bloco "OU MOrTrer."
                    # virou "ou *orrer.". Pior que o original, porque parece
                    # corrigido.
                    $txt2 = Get-Content -LiteralPath $escolhido.FullName -Raw -Encoding UTF8
                    $falas2 = @($txt2 -split "`n" | Where-Object { $_ -notmatch '-->' -and $_.Trim() -notmatch '^\d+$' }) -join ''
                    $chars2 = ($falas2 -replace '\s', '').Length
                    $ast2 = ([regex]::Matches($falas2, '\*')).Count
                    # ATENCAO - aqui a regra e DIFERENTE da do motor, de
                    # proposito. O motor usa a saida do seconv INTEIRA como
                    # legenda: se ela vier furada, tem que recusar tudo. O
                    # Corretor so cata bloco solto - entao descartar o arquivo
                    # inteiro jogaria fora as correcoes BOAS junto com as
                    # ruins. Foi o que aconteceu naquele teste: a 2a opiniao
                    # tinha 8,4% de "*", mas o bloco de 00:06:41 veio
                    # "Quase." limpinho e consertou o "OITECT".
                    # Entao aqui: AVISA, mas nao descarta. Quem filtra e a
                    # checagem por bloco, mais abaixo.
                    $srtSegundaOpiniao = $escolhido.FullName
                    Diz ("Segunda opiniao gerada: " + $srtSegundaOpiniao) "Green"
                    if ($chars2 -gt 0 -and $ast2 -ge 10 -and ($ast2 / $chars2) -gt 0.005) {
                        Diz ("[!] atencao: a 2a opiniao veio com " + $ast2 + " de " + $chars2 + " caracteres (" + ([Math]::Round(($ast2/$chars2)*100,1)) + "%) como '*'.") "Yellow"
                        Diz "    O BinaryOCR marca assim todo glifo que nao acha no Latin.db - o banco nao" "Yellow"
                        Diz "    casa com a fonte deste release. Vou aproveitar SO os blocos que vierem" "Yellow"
                        Diz "    limpos; os que tiverem '*' sao ignorados, e o bloco original fica como" "Yellow"
                        Diz "    esta. Espere poucas correcoes nesta rodada." "Yellow"
                    }
                } else {
                    Diz ("[!] o seconv gerou " + (($gerado | ForEach-Object { $_.Name }) -join ", ") + " - nenhum casa com o idioma '" + $idiomaPtBr + "' da faixa pedida.") "Yellow"
                    Diz "    Descartando a 2a opiniao: melhor ficar com o bloco-lixo do que trocar por texto de outro idioma." "Yellow"
                }
            } else {
                Diz "[!] o seconv nao gerou .srt nenhum - veja a saida acima." "Yellow"
            }
        }
    }

    # ------------------------------------------------------- montar o corrigido
    $trocas = New-Object System.Collections.Generic.List[object]
    if ($srtSegundaOpiniao -ne "" -and (Test-Path -LiteralPath $srtSegundaOpiniao)) {
        $blocos2 = Parse-Srt (Ler-TextoComEncoding $srtSegundaOpiniao)
        $inicios2 = @($blocos2 | ForEach-Object { $_.IniMs })

        foreach ($b in $ruins) {
            $melhor = $null; $melhorDelta = [double]::MaxValue
            for ($k = 0; $k -lt $blocos2.Count; $k++) {
                $delta = [math]::Abs([double]$blocos2[$k].IniMs - [double]$b.IniMs)
                if ($delta -lt $melhorDelta) { $melhorDelta = $delta; $melhor = $blocos2[$k] }
            }
            <#  v2.15: O CASAMENTO OLHAVA SO O INICIO, COM 3 SEGUNDOS DE FOLGA.
                Em dialogo corrido os blocos ficam a 100-500 ms um do outro.
                Se a segunda opiniao juntar ou dividir um display set (o
                BinaryOCR tem segmentacao propria), o bloco mais proximo pode
                ser o VIZINHO - e o texto da fala seguinte era gravado no
                lugar do bloco-lixo. Como a fala do vizinho e portugues
                plausivel, a trava de aceite aprovava. O resultado e uma linha
                deslocada que PARECE corrigida, que e pior do que o lixo.
                Agora o fim tambem tem que bater, com folga de 1 segundo, e a
                folga do inicio caiu para 1 segundo. Nao casou direito, nao
                troca - o bloco fica como esta. #>
            $deltaFim = [double]::MaxValue
            if ($null -ne $melhor) { $deltaFim = [math]::Abs([double]$melhor.FimMs - [double]$b.FimMs) }
            if ($null -ne $melhor -and $melhorDelta -le 1000 -and $deltaFim -le 1000) {
                $novo = $melhor.Texto.Trim()
                # v2.4: cinto e suspensorio. Mesmo com a checagem de densidade
                # acima, um bloco solto pode vir com "*" - e "*" nunca melhora
                # nada. Test-BlocoAlienigena nao pega isso sozinho: em
                # "ou *orrer." ele conta 2 palavras, acha "ou" no dicionario,
                # da 50% de reconhecimento e aprova.
                # v2.7: passa $nomes tambem aqui - senao uma substituicao BOA
                # cheia de nome proprio ("Aquiles, filho de Peleu") era
                # recusada por "nao existe em portugues" e o lixo ficava.
                if ($novo -ne "" -and $novo -notmatch '\*' -and -not (Test-BlocoAlienigena $novo $dicionario $nomes)) {
                    $trocas.Add((New-Object PSObject -Property ([ordered]@{
                        Chave = ($b.Inicio + "|" + $b.Fim); Antigo = $b.Texto; Novo = $novo
                    })))
                }
            }
        }
    }

    Titulo "RESUMO"
    Diz ("Blocos alienigenas detectados : " + $ruins.Count)
    Diz ("Corrigidos pela 2a opiniao    : " + $trocas.Count)

    # v2.7 BUG GRAVE: aqui era "if ($trocas.Count -gt 0)", ou seja, o arquivo
    # corrigido SO era gravado quando a 2a OPINIAO acertava alguma coisa. Se
    # so as correcoes automaticas tivessem rodado, o script imprimia
    # "Corrigidos 2 bloco(s)" no relatorio e jogava tudo no lixo sem gravar
    # nada. Foi exatamente o que aconteceu no Troia: o relatorio anunciou
    # "trolanos"->"troianos" e "magoel"->"magoei", e as duas continuaram
    # erradas dentro do .mkv. Correcao anunciada e nao entregue e pior que
    # correcao nenhuma. Agora grava se QUALQUER uma das duas mexeu.
    # v2.8: o reparo de ESTRUTURA tambem obriga a gravar. Sem isso o script
    # consertava os 7 blocos quebrados, nao gravava por "nao teve correcao de
    # texto", e as falas se perdiam do mesmo jeito - o mesmo tipo de furo do
    # bug 8. Reparo feito e reparo que TEM que chegar no arquivo.
    if ($trocas.Count -gt 0 -or $trocasAuto.Count -gt 0 -or $script:ReparosEstrutura -gt 0) {
        $mapa = @{}
        foreach ($t in $trocas) { $mapa[$t.Chave] = $t.Novo }

        $sb = New-Object System.Text.StringBuilder
        $idx = 0
        foreach ($b in $blocos) {
            $idx++
            [void]$sb.AppendLine($idx)
            [void]$sb.AppendLine($b.Inicio + " --> " + $b.Fim)
            $chave = $b.Inicio + "|" + $b.Fim
            <#  2.25: BLOCO VAZIO GERAVA DUAS LINHAS EM BRANCO.
                AppendLine de texto vazio ja escreve uma linha em branco, e
                a linha separadora logo abaixo escrevia a segunda. Duas
                linhas em branco seguidas sao exatamente a quebra de formato
                que este script existe para consertar: na passada seguinte o
                Repair-EstruturaSrt lia aquilo como bloco quebrado, contava
                um conserto que nao aconteceu, imprimia "consertei N bloco(s)
                com o FORMATO quebrado" - mentira - e so por causa desse
                contador gravava um _CORRIGIDO.srt novo, identico ao que ja
                estava la. Bloco vazio existe de verdade: o proprio Reocr
                conta os dele. Medido em laboratorio antes e depois. #>
            $txtBloco = ""
            if ($mapa.ContainsKey($chave)) { $txtBloco = [string]$mapa[$chave] }
            else { $txtBloco = [string]$b.Texto }
            if (-not [string]::IsNullOrWhiteSpace($txtBloco)) { [void]$sb.AppendLine($txtBloco) }
            [void]$sb.AppendLine("")
        }
        $nomeBase = [System.IO.Path]::GetFileNameWithoutExtension($Srt)
        $srtSaida = Join-Path $pastaSaida ($nomeBase + "_CORRIGIDO.srt")
        [System.IO.File]::WriteAllText($srtSaida, $sb.ToString(), (New-Object System.Text.UTF8Encoding($true)))

        Diz ""
        Diz ("SRT CORRIGIDO: " + $srtSaida) "Green"
        Diz ""
        Diz "--- trocas feitas ---" "Cyan"
        foreach ($t in $trocas) {
            Diz ("  ANTES : '" + ($t.Antigo -replace "`n", " / ") + "'") "DarkGray"
            Diz ("  DEPOIS: '" + ($t.Novo -replace "`n", " / ") + "'") "Green"
        }
    } elseif ($ruins.Count -gt 0) {
        Diz ""
        Diz "Nao havia nada pra gravar: nenhuma correcao foi possivel." "Yellow"
        # v2.7: o resumo mentia. Ele so olhava a 2a opiniao, entao dizia
        # "nenhuma correcao foi possivel" mesmo depois de ter corrigido 17
        # blocos por padrao conhecido. Agora conta as duas coisas.
        if ($trocasAuto.Count -gt 0) {
            Diz ("Corrigi " + $trocasAuto.Count + " bloco(s) por padrao conhecido de OCR (listados la em cima).") "Green"
            Diz "A 2a opiniao nao conseguiu ajudar nos blocos alienigenas que sobraram." "Yellow"
        } else {
            Diz "Nenhuma correcao automatica foi possivel nesta rodada." "Yellow"
        }
        Diz "Os blocos alienigenas estao listados acima, com o tempo exato -" "Yellow"
        Diz "da pra corrigir na mao no .srt, ou rodar o Reocr_Legenda.bat" "Yellow"
        Diz "passando tambem o .mkv original." "Yellow"
    }

} catch {
    Diz ""
    Diz "=============== ERRO FATAL ===============" "Red"
    Diz ("Mensagem : " + $_.Exception.Message) "Red"
    Diz ("Onde     : linha " + $_.InvocationInfo.ScriptLineNumber) "Red"
} finally {
    # v2.15: a pasta "_corretor\tmp_<carimbo>\" com o .srt inteiro da segunda
    # opiniao nunca era apagada - uma pasta e um SRT completo por execucao,
    # acumulando para sempre. O Reocr ja apagava a dele; as duas ferramentas
    # irmas se comportavam de jeitos diferentes.
    try {
        if ($script:PastaTempCorretor -and (Test-Path -LiteralPath $script:PastaTempCorretor)) {
            if ($GuardarSegundaOpiniao) {
                Write-Host ""
                Write-Host ("SEGUNDA OPINIAO GUARDADA EM: " + $script:PastaTempCorretor) -ForegroundColor Yellow
                Write-Host "  (-GuardarSegundaOpiniao ligado - apague a pasta a mao quando nao precisar mais)" -ForegroundColor DarkGray
            } else {
                Remove-Item -LiteralPath $script:PastaTempCorretor -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    } catch { }
    try {
        if ($script:Relatorio -and $script:Relatorio.Count -gt 0) {
            $pastaRel = if ($pastaSaida) { $pastaSaida } else { (Get-Location).Path }
            if (-not (Test-Path -LiteralPath $pastaRel)) { New-Item -ItemType Directory -Path $pastaRel -Force | Out-Null }
            $cr = if ($carimbo) { $carimbo } else { Get-Date -Format "yyyy-MM-dd_HHmmss" }
            $rel = Join-Path $pastaRel ("relatorio_corretor_" + $cr + ".txt")
            [System.IO.File]::WriteAllText($rel, ($script:Relatorio -join "`r`n"), (New-Object System.Text.UTF8Encoding($true)))
            Write-Host ""
            Write-Host ("RELATORIO: " + $rel) -ForegroundColor Green
        }
    } catch { }
    if (-not $SemPausa) { Write-Host ""; Read-Host "Pressione ENTER para fechar" | Out-Null }
}
