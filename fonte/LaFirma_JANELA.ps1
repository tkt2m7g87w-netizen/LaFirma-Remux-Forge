# ============================================================================
#  LaFirma - JANELA 16.75
#  [DDVT] Interface Grafica WPF do Conversor de PERFIL Dolby Vision 8.1
# ============================================================================
#
#  O QUE E ESTE ARQUIVO:
#    Fase MOTOR: a janela aprovada na 14.0-p14 comeca a receber o motor da
#    v13.1 por baixo, SEM alterar o visual aprovado e SEM alterar a logica
#    do Converter_AUTO_DIRETO.ps1 (que segue intocado, como modo console).
#
#    Entrega m2 = a TELA INICIAL fica real. A janela passa a ler a pasta
#    de verdade, achar as ferramentas de verdade e diagnosticar cada video
#    chamando as funcoes do proprio motor v13.1 - extraidas do arquivo pela
#    AST, sem executa-lo (caminho provado pela Sonda 15.0-s1: 59 funcoes
#    lidas, 22 exigidas presentes, zero erro de sintaxe).
#
#    A leitura roda no MESMO runspace da m1, porque diagnosticar custa
#    ~2,4s por arquivo: uma temporada de 20 episodios travaria a janela
#    por 47 segundos se isso rodasse na thread da interface.
#
#    A CONVERSAO em si continua falsa (a prova de ~80s da m1 segue igual).
#    O que virou real: pastas, ferramentas, fila, diagnostico, disco e o
#    inventario de faixas.
#
#  DECISOES DE ENGENHARIA (definidas com o usuario):
#    - WPF via XAML carregado pelo proprio .ps1 (zero instalacao extra).
#    - Pipeline num runspace separado (MTA); mensagens numa ConcurrentQueue;
#      DispatcherTimer de 100ms consumindo na thread da janela.
#    - Flags de controle (Pausar/Cancelar) numa hashtable sincronizada,
#      lidas pelo motor a cada ciclo de 200ms (mesmo ritmo da v13.1).
#    - F1 = Iniciar. F2 = alterna Pausar/Retomar. ESC = cancelar.
#    - Janela unica; paineis por estado; maquina de estados Set-Estado.
#
#  REGRA DE VERSIONAMENTO: fase MOTOR = 15.0-m1, m2, ...
#    (a fase visual encerrou aprovada na 14.0-p14)
#
#  HISTORICO (entrada nova a cada mudanca de $SCRIPT_VERSION, na MESMA edicao)
#    Ate 27/08/2026 este arquivo NAO tinha lista de historico - so blocos
#    <# 16.xx: ... #> espalhados ao lado do codigo. Para saber o que mudou
#    era preciso varrer 5.000 linhas. As entradas abaixo comecam na 16.58;
#    o que veio antes continua documentado ao lado do codigo que mudou.
#
#    16.75  03/09/2026  O CHIP DIZIA "Tesseract standalone". Desde a 14.23
#                       o Tesseract vai EMPACOTADO em tools\Tesseract\, e a
#                       janela procura la primeiro. O rotulo continuava
#                       mandando o usuario instalar por fora - o mesmo texto
#                       velho que estava nos dois manuais.
#    16.74  02/09/2026  UMA AMOSTRA RUIM DE DISCO DECIDIA A ESTIMATIVA
#                        INTEIRA. Log de 02/09 01h54 (Lara Croft): a medida
#             deu 52 MB/s e o fator bateu no teto de 8x - previsto 961s contra
#             515s de relogio, +87%. O MESMO disco tinha medido 3.324, 3.072,
#             2.964, 2.531 e 2.214 MB/s nas cinco conversoes anteriores: 52 e
#             contencao momentanea, nao velocidade. Agora sao tres leituras de
#             24 MB (25%, 50% e 75% do arquivo) e vale a MAIOR - disco lento e
#             lento nos tres pontos. As tres saem no log.
#    16.73  02/09/2026  MAQUINA LENTA: O NUMERO PULAVA E A BARRA IA A 100%
#                        COM A ETAPA EM 62%.
#             Log de 01/09 21h54 - o mesmo Jackie Brown, mas com o mkvmerge
#             levando 5m18s em vez de 2m50s. Duas coisas so aparecem nesse
#             caso: (1) o bruto pulava 304-439-218-141-126-145-158-137, cada
#             leitura uma conta nova; agora um filtro deixa o numero cair com
#             o relogio e andar 25% por leitura, subindo no maximo 10% de uma
#             vez. (2) a barra do video marcava 100% com a etapa em 62%,
#             porque a barra comparava o relogio com o previsto do CATALOGO e
#             o tempo usava o previsto CORRIGIDO - duas contas discordando.
#             Agora e uma so: Get-PrevistoAjustadoDaEtapa.
#    16.72  02/09/2026  ERRO CONSTANTE DE +71s NO JACKIE BROWN - ERAM DUAS
#                        COISAS, E O LOG DA 16.71 MOSTROU AS DUAS.
#             As 13 linhas RODAPE do log de 01/09 21h36 erraram +71s cada uma,
#             do comeco ao fim. Erro constante e parcela fixa sobrando:
#             . a etapa 5 estava no catalogo com 228s e levou 170s, e a 16.70
#               so deixava o previsto da etapa SUBIR. Agora, passados 20% da
#               etapa, o ritmo dela manda nos dois sentidos.
#             . a remontagem tem CUSTO FIXO: 2,10 s/GB no Jackie Brown contra
#               2,72 no Jumanji. A reta pelos dois da 51s + 1,49 s/GB e acerta
#               os dois na mosca. Conferencia de 38 para 32 (5 medidas).
#    16.71  02/09/2026  O LOG GRAVA O TEMPO RESTANTE QUE A TELA MOSTRA.
#             Tres entregas seguidas em que eu precisei pedir print da tela
#             para saber se a conta estava boa. O log tinha o % de cada
#             ferramenta, o tempo de cada etapa e a estimativa do lote - e nao
#             tinha o unico numero reclamado. Agora tem: linha RODAPE a cada
#             30s e em toda troca de etapa ou fase, com o que entrou na conta.
#    16.70  02/09/2026  O TEMPO RESTANTE PASSOU A SER CONTADO DA ETAPA DE
#                        AGORA PARA A FRENTE - E A CONFERENCIA ENTROU NA CONTA.
#             Jumanji 01/09 21h24: etapa 5/5 em 70%, mkvmerge montando, e o
#             rodape dizia "Terminando Agora". Faltavam 1m18s. A 16.68 so sabia
#             fazer PREVISTO - DECORRIDO, e naquela noite o audio levou 31m36s
#             contra 25m50s previstos: passado o previsto, o resto virava zero.
#             E a conferencia (40s em todo arquivo) nao entrava em conta
#             nenhuma - a 16.69 tinha escondido isso atras de "Finalizando".
#             Agora: falta da etapa de agora (pelo ritmo medido DELA) +
#             etapas seguintes + conferencia + videos seguintes da fila.
#             "Terminando Agora" so abaixo de 15s.
#    16.69  01/09/2026  O RODAPE DA FILA FICAVA MUDO NA VERIFICACAO E NA
#                        LIMPEZA. Troy 01/09: fechada a etapa 5/5, a fila
#             marcava 100% e ainda vinham 41s de verificacao mais a limpeza -
#             e a linha inteira sumia da tela. Nao ha numero a dar ali (as
#             duas ficam fora da regua de proposito), mas sumir nao e
#             resposta: agora escreve "Finalizando".
#    16.68  01/09/2026  TEMPO RESTANTE E BARRA DEIXARAM DE ACREDITAR NO %
#                        DA FERRAMENTA.
#             Log do Jumanji (01/09, 16h45): a etapa de audio DeeZy levou
#             27m09s e reportou 20% aos 3 min, 43% aos 7m22s, 67% 25 segundos
#             depois, e 14 minutos entre 82% e 99%. A tela extrapolava
#             decorrido x (100-pct)/pct e escreveu "Tempo Restante: 17 min"
#             quando faltavam 29m36s, "9 min" quando faltavam 15m34s. O numero
#             caiu 8 minutos enquanto passavam 14 de relogio.
#             - Tempo restante agora e PREVISTO - DECORRIDO (descontada a
#               pausa), com o previsto corrigido pela regua a cada etapa que
#               FECHA. A extrapolacao so entra se o relogio passar do previsto.
#             - A fracao da etapa (barra do VIDEO) e a maior entre o % da
#               ferramenta e decorrido/previsto-da-etapa, travada em 99% ate a
#               etapa fechar: a barra nunca congela e nunca mente que acabou.
#             - Os segundos previstos de cada etapa passaram a viajar no lote
#               (SegEtapas), ao lado dos pesos.
#    16.67  01/09/2026  (fecha o ciclo - build 1.6)
#           - Sem mudanca de comportamento na janela. Versao acompanhando o
#             conserto do motor 14.33 e as notas de medicao do Corretor 2.27
#             e do Reocr 1.29.
#    16.66  01/09/2026
#           - A 16.65 SAIU QUEBRADA: duas funcoes com o mesmo nome. A que
#             responde "o que vai rodar neste video" nasceu chamada
#             Get-PlanoDoVideo e ja existia outra assim. Em PowerShell a
#             ultima definicao vence, calada - a minha era substituida, a
#             chamada caia na outra (que devolve um array), e .Dovi num
#             array e $null. As tres etapas viravam "nao roda".
#             O Troia foi estimado em 248s contra 23m05s reais: -82%.
#             Agora e Get-TrabalhoDoVideo, e a bateria reprova qualquer
#             funcao definida duas vezes no primeiro nivel de qualquer um
#             dos seis arquivos. O teste da estimativa parou de usar stub -
#             era o stub que escondia exatamente esta colisao.
#    16.65  01/09/2026
#           - A ESTIMATIVA DA LEGENDA DEIXOU DE SER APROXIMACAO. Ela custa
#             0,28 s por BLOCO, e o numero de blocos parecia so existir
#             depois do OCR - por isso ate a 16.64 era aproximado pela
#             duracao do filme, e era a unica parte fraca do modelo (+24%
#             no Lara Croft).
#             O mkvmerge devolve num_index_entries por faixa lendo SO O
#             CABECALHO. Numa faixa de legenda isso e a contagem de eventos:
#             SRT grava um por fala, PGS grava dois (desenhar e apagar).
#             Conferido nos arquivos do Diego contra os blocos que sairam:
#                 Troia  2757/2 = 1378,5  ->  1378   (+0,04%)
#                 Se7en  3144/2 = 1572    ->  1572   (exato)
#                 Lara   1436/2 =  718    ->   718   (exato)
#                 GoT     892/2 =  446    ->   446   (exato)
#             Nas 12 conversoes medidas o erro medio do TOTAL cai de 5,26%
#             para 2,84%, e o pior caso de 24,3% para 8,8%.
#             Tem trava de sanidade: fora da faixa de 20 a 20.000 blocos o
#             numero nao e o que eu penso que e, e a conta volta para a
#             duracao. Melhor cair no plano B do que inventar numero.
#           - O log grava quantos blocos foram usados na conta.
#    16.64  28/08/2026
#           - PASTA DE ORIGEM E DE SAIDA VIRARAM CAIXA DE TEXTO. Clica,
#             digita ou cola o caminho, ENTER aplica, ESC desfaz. Sair da
#             caixa tambem aplica. Enquanto o caminho nao existir a borda
#             fica vermelha e nada e aplicado. O botao virou "Procurar" e
#             chama o MESMO codigo.
#           - SELETOR DE PASTA MODERNO. O FolderBrowserDialog do .NET
#             Framework e a arvorinha sem barra de endereco, onde nao da
#             para digitar nem colar caminho. Agora abre o dialogo do
#             Explorer (IFileDialog + FOS_PICKFOLDERS via COM), com barra
#             de endereco, favoritos e busca. Se falhar em qualquer ponto,
#             cai no antigo - seletor feio e melhor que nenhum.
#           - ESTIMATIVA DE TEMPO REFEITA EM 12 CONVERSOES REAIS (8
#             episodios de Fallout S02, Lara Croft, Troia, Homem-Aranha e
#             GoT S08E01). Erro medio caiu de 33,1% para 5,2%; o pior caso
#             de +71% para +23%. Cada etapa passou a seguir a grandeza que
#             ela realmente segue:
#               audio TrueHD -> MINUTOS DE FILME (14,9 s/min, dispersao de
#                 1,9% em nove medidas). Era estimado por GB, onde a mesma
#                 etapa variava 44%. Como o audio e 60 a 77% do tempo, era
#                 este o erro que fazia o Fallout inteiro sair +30 a +45%.
#               extracao 2,3 s/GB | dovi 2,6 s/GB | remontagem 5,6 s/GB
#                 (2,8 no remux direto). A 16.63 modelava a remontagem como
#                 "274s fixos + 1,39 s/GB" a partir de tres arquivos todos
#                 entre 61 e 87 GB; os oito Fallout, de 25 a 31 GB, provaram
#                 que aquilo era ajuste em cima de pontos amontoados.
#               legenda -> 0,28 s/bloco, estimada por duracao ate a proxima
#                 rodada ter o tamanho da faixa PGS medido.
#           - O DISCO DE ORIGEM ENTRA NA CONTA. O GoT veio de um HD (G:) e
#             as etapas de disco levaram de 3 a 6 vezes mais, enquanto o
#             audio quase nao mudou. A janela agora MEDE a leitura da origem
#             (64 MB reais, meio segundo) em vez de perguntar ao Windows que
#             tipo de disco e - pasta de rede entra na mesma conta. Cada
#             etapa absorve o fator na medida que foi medida nela. Sem isso
#             o GoT era estimado 36% abaixo; com isso, 1,1% acima.
#           - O log passou a gravar GB, duracao e TAMANHO DA FAIXA PGS de
#             cada video. Sao os numeros que faltam para a legenda deixar de
#             ser estimada por duracao (a etapa mais fraca do modelo).
#    16.63  27/08/2026
#           - ESTIMATIVA DE TEMPO RE-MEDIDA EM 7 CONVERSOES. O erro do total
#             era de -0,6% a +45%; agora e de -5% a +12%. Tres causas:
#             1) A etapa de LEGENDA nao escala com GB - ela escala com o
#                numero de blocos. Medido: 0,306 s/bloco no Aranha, 0,330 no
#                Se7en, 0,286 no Troia (dispersao de 8%); por GB a dispersao
#                era de 110%. Agora ela entra em SEGUNDOS FIXOS (220 + 280
#                do re-OCR), convertidos em peso pelo GB do proprio video.
#                Era isso que dava +58% de erro na etapa 4 do Troia.
#             2) A REMONTAGEM tem dois precos: 5,0 s/GB quando o video foi
#                extraido (remonta de pedacos e apaga temporarios) e 2,48
#                s/GB quando remuxa direto do original. E quase toda custo
#                FIXO: a reta dos tres pontos e 274s + 1,39 s/GB. Por isso
#                ela virou parte em segundos + parte por GB. Era isso que
#                estimava o Se7en em 910s para levar 685s.
#             3) Extracao de video (167->130), dovi_tool (221->170), TrueHD
#                (2800->2520) e audio por ffmpeg (190->145) estavam todos
#                altos demais. Re-medidos um a um.
#           - Funcao nova: Get-PesoDeSegundos (converte segundos em peso de
#             regua usando o GB do video).
#    16.62  27/08/2026
#           - A linha da qualidade dizia "nenhuma falha" duas vezes e o
#             parenteses comecava em minuscula. Sem falha: "(1378 legendas
#             conferidas)". Com falha, o texto continua o mesmo.
#    16.61  27/08/2026
#           - DIAGNOSTICO respeita a escolha manual: com "Manter" marcado no
#             audio, o painel dizia "[SERA CONVERTIDO] E-AC-3 640k" enquanto
#             a coluna dizia "DTS Mantido" e o motor mantinha. Agora o painel
#             le a mesma escolha que a coluna. Vale para audio e legenda.
#    16.60  27/08/2026
#           * A TELA DIZIA "DA" E O MOTOR DIZIA "FALTAM 4,33 GB". Os dois
#             numeros no mesmo print, Troy 27/08 01h04: a tela inicial
#             calculava 268,88 GB e o motor exigiu 274,05 GB com o MESMO
#             espaco livre. Sao TRES contas diferentes no projeto e a tela
#             mostrava a mais otimista das tres. A que de fato bloqueia e a
#             POR EPISODIO (3,15x a origem; 1,6x quando o video ja e 8.1 e
#             nem sai do container). Agora a tela calcula a do lote E a por
#             episodio e mostra a MAIOR, dizendo qual das duas mandou.
#           * A LINHA DA FILA FICAVA PRESA EM "CONVERTENDO - Diagnostico".
#             A condicao era "estado -ne 'parado'", verdadeira tambem em
#             INICIAL e FIM. Depois do erro do Troy o Diego voltou para a
#             tela inicial e a linha continuou anunciando uma conversao que
#             nao existia; so sumiu quando ele trocou de pasta. Agora a
#             condicao e "rodando ou pausado", e o Set-Estado limpa
#             VideoNome/Fase/Nota ao sair desses dois.
#           * OS DOIS PONTOS DAS FASES na barra do VIDEO. A regua desenha so
#             as etapas numeradas; o [DIAGNOSTICO] (antes da 1a) e a
#             [VERIFICACAO]+[LIMPEZA] (depois da ultima) nao apareciam em
#             lugar nenhum dela - e sao justamente os trechos em que a tela
#             parece parada. Viraram um "·" em cada ponta, com as mesmas
#             cores da regua (apagado / ciano / verde). Nao viraram
#             segmento: fase nao e etapa (16.47).
#
#    16.59  27/08/2026
#           * A linha "Qualidade da Legenda" do cartao final ganhou COR.
#             Ate aqui os quatro veredictos saiam no mesmo cinza do resto da
#             tabela - a unica diferenca era o usuario LER a palavra, numa
#             tela que usa verde/laranja/vermelho em todo o resto.
#             EXCELENTE verde | BOA verde claro | RAZOAVEL laranja | RUIM
#             vermelho. Laranja e nao ambar: ambar ja significa PAUSADO.
#           * BUG REAL, achado no teste de 27/08 00h21: o selo de audio
#             mentia em tres frentes ao mesmo tempo. Com a conversao
#             desligada no Modo Manual, o motor 13.3 devolve JA_OTIMO com
#             MotivoAudio "Conversao de Audio Desligada na Escolha Manual" -
#             um TERCEIRO caso que este switch nao conhecia. Ele caia no
#             else e o cartao escrevia "Audio E-AC-3/AC-3 Ja Existente -
#             REAPROVEITADO" em ambar, num arquivo que saiu com TrueHD Atmos
#             LOSSLESS e nenhum E-AC-3. Nada foi reaproveitado (o usuario
#             mandou MANTER), o codec estava errado, e ambar significa
#             "houve perda" quando nao houve perda nenhuma. O contador do
#             DETALHAMENTO tinha o mesmo defeito ("Audio E-AC-3/AC-3
#             Reaproveitado : 1"). Agora ha um caso proprio, em cinza, com
#             o codec real: "Audio <codec> Mantido a Pedido - CONVERSAO
#             DESLIGADA", e o contador "Audio Mantido a Pedido (sem
#             converter)". Os outros dois casos do JA_OTIMO seguem iguais.
#
#    16.58  27/08/2026
#           * As quatro frases do veredicto da legenda reescritas. Saiam em
#             minuscula e fora do padrao ("BOA - pode assistir por ela"), e
#             o RAZOAVEL ainda vinha sem acento ("da pra assistir").
# ============================================================================

<#  O LOG LE ESTA VARIAVEL, NAO O COMENTARIO DO TOPO.
    Em 25/08 o cabecalho foi para 16.52 e esta linha ficou em 16.50, entao
    todo log da sessao passou a anunciar uma versao que nao era a do arquivo.
    Eu mesmo cai nisso: li "JANELA 16.50" no log do Diego e afirmei que ele
    nao tinha atualizado o arquivo - ele tinha. A tela mentiu e eu usei a
    mentira como prova contra ele.
    Ao subir a versao, trocar AQUI e no comentario do topo. #>
$SCRIPT_VERSION = "16.75"

# 16.30: BUG CORRIGIDO na estimativa de tamanho de saida (aba Faixas e log
# FAIXAS). $bytesFaixa de cada faixa vinha SO da tag "number_of_bytes" do
# mkvmerge, que remux de Blu-ray quase sempre tem mas release WEB-DL muitas
# vezes nao grava. Sem a tag, a faixa de VIDEO (que sozinha e sempre 100% do
# total, nunca recodifica) contava Bytes=0 e a estimativa inteira zerava.
# Caso real: Desperate Housewives, "saida estimada ~0,00 GB (original 2,49
# GB, delta -2,49 GB)". Agora, quando falta a tag, a sobra (tamanho total do
# arquivo menos as faixas que TEM a tag) vira a estimativa da faixa de video
# sem tag - ver o bloco logo apos "$d.Faixas = $inv" acima. So entra em acao
# quando a tag falta; arquivo com todas as tags (como o TLOU) nao muda nada.

# 16.29: o nome do programa passa a abrir SEMPRE a barra de titulo. Antes o
# titulo era so o estado ("LaFirma - Pronto para Converter"), o que nao segue a
# convencao de aplicativo - la em cima e lugar de nome de programa.
# APP_VERSAO e a versao do INSTALADOR (a que aparece em Adicionar/Remover), nao
# a da janela. Se mudar o "#define Versao" no LaFirma_Setup.iss, mude aqui tambem.
<#  VERSAO DO PRODUTO - LIDA DO VERSAO.txt QUE O INSTALADOR ESCREVE.
    Ate a 16.53 este numero era digitado a mao aqui e no .iss. Duas fontes
    para o mesmo dado sempre divergem: em 25/08 o cabecalho deste arquivo
    dizia 16.52 e o $SCRIPT_VERSION dizia 16.50, e o log passou a anunciar
    uma versao que nao era a do arquivo - eu li o log do Diego e afirmei que
    ele nao tinha atualizado, quando tinha.

    Agora a fonte unica e o .iss: ele grava VERSAO.txt na pasta do programa
    ao instalar, e a Janela le dali. Subir a versao do produto passa a ser
    UMA edicao, no .iss.

    Sem o arquivo (rodando direto da pasta de desenvolvimento, sem instalar)
    cai no valor abaixo - que e so um piso, nao a verdade. #>
$APP_VERSAO = "1.5.0"
try {
    <#  $script:PastaScript so nasce la na linha ~185; aqui em cima ele ainda
        e $null e o Join-Path devolveria caminho errado. Por isso a pasta e
        resolvida do zero, do mesmo jeito que ela e resolvida mais abaixo. #>
    $pastaDoScript = $PSScriptRoot
    if ([string]::IsNullOrWhiteSpace($pastaDoScript)) {
        $pastaDoScript = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    $arqVersao = Join-Path $pastaDoScript "VERSAO.txt"
    if (Test-Path -LiteralPath $arqVersao) {
        foreach ($ln in @(Get-Content -LiteralPath $arqVersao -ErrorAction SilentlyContinue)) {
            if ($ln -match '^\s*Produto\s*:\s*(\S+)') { $APP_VERSAO = $Matches[1]; break }
        }
    }
} catch { }
$NOME_APP   = "LaFirma Remux Forge - Black Edition v$APP_VERSAO"

# ---- Guarda de STA ----------------------------------------------------------
# WPF exige thread STA. O .bat ja chama com -Sta; isto aqui e o cinto de
# seguranca para quando o .ps1 e executado direto.
if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne "STA") {
    $argsRelanc = @("-NoProfile","-Sta","-ExecutionPolicy","Bypass","-File","`"$(if($PSCommandPath){$PSCommandPath}else{$MyInvocation.MyCommand.Path})`"")
    Start-Process -FilePath "powershell" -ArgumentList $argsRelanc | Out-Null
    exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms   # apenas para o dialogo de pasta

# ---- Paleta (mesmos RGB da v13.1) ------------------------------------------
$Cores = @{
    txt   = "#C9C7BF"; foco = "#F1EFE8"
    ok    = "#16C60C"; okdim = "#6EDC5A"
    src   = "#85B7EB"; dst  = "#9FE1CB"
    warn  = "#FAC775"; lar  = "#F08C3C"; err = "#E24B4A"
    dim   = "#888780"; dim2 = "#5F5E5A"; vazio = "#3A3A37"
    marca = "#D696FF"; marcadim = "#A88CC8"
    <#  16.45: O ROXO DEIXOU DE SER ESTADO.
        Ate a 16.44 o violeta ($Cores.marca) fazia dois trabalhos que nao tem
        nada a ver um com o outro: era a COR DA MARCA (rotulos ETAPA/VIDEO/
        FILA, seta dos paineis, selo Manual, linha selecionada) e era tambem
        o estado "ESTA ACONTECENDO AGORA" (segmento da regua, coluna
        SITUACAO). A mesma tinta em duas gramaticas: o olho nao tem como
        saber se aquele roxo esta dizendo "isto e o LaFirma" ou "isto esta
        rodando".
        Como e feito na industria (GOV.UK Progress tracker, Material 3,
        Fluent, Carbon): o estado NAO e codificado so pela cor. Feito e
        solido; em andamento e a unica coisa que se MOVE e a unica que ocupa
        a altura inteira; o que ainda vai acontecer e fino e apagado. A cor
        vem depois, para reforcar - nunca sozinha (quem enxerga pouco cor
        continua lendo a tela pelo tamanho e pelo preenchimento).
        Entao:
          marca   = so identidade. Nunca mais significa estado.
          emCurso = ciano. UM tom, um significado: acontecendo agora.
                    Ciano porque os tres vizinhos ja tem dono - verde e
                    FEITO, ambar e PAUSADO, vermelho e ERRO - e porque ele
                    separa de verde por brilho, nao so por matiz.
          ok      = feito (ja existia)
          vazio   = ainda vai acontecer (ja existia)
        emCursoTrilho e o leito escuro do ciano, para a barra da etapa e para
        o preenchimento dentro do segmento que esta rodando. #>
    emCurso = "#3FC7F0"; emCursoTrilho = "#123642"; emCursoDim = "#2A8FAE"
    # 16.47: trabalho de APOIO (diagnostico, conferencia, limpeza). Nao e
    # etapa, entao nao pode usar a cor de etapa. Cinza-azulado: o olho ve que
    # algo anda sem ler "isto e uma das etapas do arquivo".
    fase = "#5A6672"
    # Tons de fundo BLACK EDITION (aprovados nos .jpg)
    fundo = "#050507"; painel = "#101015"; painel2 = "#16161C"
    borda = "#2A2A33"; borda2 = "#33333D"; trilho = "#1B1B22"
    selRoxo = "#2A1C3A"; pausaFundo = "#151107"; pausaBorda = "#3A3118"
    okFundo = "#0D1409"; okBorda = "#22331B"
    errFundo = "#150A0B"; errBorda = "#3D2426"
}

# ---- Marcadores solidos (conjunto "solido" da v13.1) ------------------------
$Sim = @{
    Ok = [string][char]0x2714; Skip = [string][char]0x25CF
    Warn = [string][char]0x25B2; Err = [string][char]0x25A0
    Atual = [string][char]0x25B6; Pausa = [string][char]0x275A + [string][char]0x275A
    Pasta = [string][char]0x25A4; Disco = [string][char]0x25A5
    # 16.36: a faixa PADRAO ganhou simbolo proprio. Ate a 16.35 ela usava o
    # mesmo triangulo do "etapa atual" ($Sim.Atual) - o mesmo desenho
    # significando duas coisas diferentes na mesma tela. Estrela e o simbolo
    # que o usuario pediu e que ninguem confunde com "em andamento".
    Padrao = [string][char]0x2605
}

# ---- Pincel: cache de SolidColorBrush -------------------------------------
# Alem de encurtar o codigo, evita criar um objeto novo a cada troca de estado
# (a versao anterior instanciava um BrushConverter por chamada).
# 16.39: pesos do video que esta convertendo agora. Peso 0 = etapa que nao vai
# rodar neste arquivo (ex: DV que ja e 8.1, audio mantido na mao).
$script:PesosDoVideoAtual = @()
$script:SegEtapasDoVideoAtual = @()   # 16.68: segundos previstos por etapa
$script:UltimoRodapeChave = ""        # 16.71: log do tempo restante
$script:UltimoRodapeEm    = $null
$script:SuaveChave = ""               # 16.73: filtro do tempo restante
$script:SuaveValor = 0.0
$script:SuaveEm    = $null
$script:AmostrasDisco = @()           # 16.74: as tres leituras do disco
$script:CachePinceis = @{}
function Pincel([string]$Hex) {
    if (-not $script:CachePinceis.ContainsKey($Hex)) {
        $b = (New-Object System.Windows.Media.BrushConverter).ConvertFromString($Hex)
        $b.Freeze()
        $script:CachePinceis[$Hex] = $b
    }
    return $script:CachePinceis[$Hex]
}

# ---- LOG DA SESSAO ---------------------------------------------------------
# Mesma filosofia do Start-Transcript da v13.1: tudo que acontece fica
# registrado em arquivo, para conferencia depois. Aqui o log serve de PROVA
# do teste: registra ambiente, cada troca de estado, cada clique/tecla e
# qualquer erro. O botao "Log" mostra este conteudo ao vivo.
$script:LogLinhas = New-Object System.Collections.Generic.List[string]
# $PSCommandPath e confiavel em qualquer escopo; $MyInvocation.MyCommand.Path
# vira vazio quando lido de DENTRO de uma funcao (bug visto no log da p2).
$script:CaminhoScript = $PSCommandPath
if (-not $script:CaminhoScript) { $script:CaminhoScript = $MyInvocation.MyCommand.Path }
$script:PastaScript = Split-Path -Parent $script:CaminhoScript
# 16.24: o log da janela passou a morar em _logs\, em vez de ficar solto na
# raiz do programa. Se a pasta nao puder ser criada, cai de volta na raiz -
# log no lugar antigo ainda e melhor que uma sessao inteira sem log.
$script:PastaLogs = Join-Path $script:PastaScript "_logs"
try { [System.IO.Directory]::CreateDirectory($script:PastaLogs) | Out-Null } catch { }
if (-not (Test-Path -LiteralPath $script:PastaLogs)) { $script:PastaLogs = $script:PastaScript }
$script:LogArquivo = Join-Path $script:PastaLogs ("LaFirma_motor_log_{0}.txt" -f (Get-Date -Format "yyyy-MM-dd_HHmmss"))

# Um unico StreamWriter aberto (AutoFlush ligado para nao perder nada se o
# programa cair). A versao p3 abria e fechava o arquivo A CADA LINHA - com o
# ruido de redimensionamento isso virava centenas de escritas por segundo.
$script:LogEscritor = $null
try {
    $script:LogEscritor = New-Object System.IO.StreamWriter($script:LogArquivo, $false, [System.Text.Encoding]::UTF8)
    $script:LogEscritor.AutoFlush = $true
} catch { }

function Escrever-Log([string]$Texto, [string]$Tipo = "INFO") {
    $linha = "[{0}] [{1}] {2}" -f (Get-Date -Format "HH:mm:ss.fff"), $Tipo.PadRight(5), $Texto
    $script:LogLinhas.Add($linha)
    if ($script:LogEscritor) { try { $script:LogEscritor.WriteLine($linha) } catch { } }
}

function Registrar-Ambiente {
    $so = try { (Get-CimInstance Win32_OperatingSystem).Caption } catch { "?" }
    <#  16.54: o log abre com a versao do PRODUTO (a que o usuario conhece)
        e a da janela entre parenteses (a tecnica, para rastrear defeito).
        Antes so aparecia a tecnica, e "JANELA 16.50" nao responde a
        pergunta "que versao do LaFirma e essa?". #>
    Escrever-Log ("===== LaFirma Remux Forge - Black Edition v" + $APP_VERSAO + "  (janela " + $SCRIPT_VERSION + ") - log da sessao =====")
    Escrever-Log ("Sistema      : {0}" -f $so)
    Escrever-Log ("PowerShell   : {0}" -f $PSVersionTable.PSVersion)
    Escrever-Log ("CLR / .NET   : {0}" -f [System.Environment]::Version)
    Escrever-Log ("Apartamento  : {0} (WPF exige STA)" -f [Threading.Thread]::CurrentThread.GetApartmentState())
    Escrever-Log ("Arquivo      : {0}" -f $script:CaminhoScript)
}

# ============================================================================
#  MOTOR - RUNSPACE, FILA DE MENSAGENS E CONTROLE (Etapa 1 do plano)
# ============================================================================
#
#  Por que runspace: o pipeline real chama ffmpeg/dovi_tool/mkvmerge, que
#  podem segurar o disco por minutos. Se isso rodar na thread da janela, o
#  Windows marca "nao esta respondendo". Entao:
#
#    JANELA (thread STA do WPF)          MOTOR (runspace separado, MTA)
#    - desenha e reage a cliques         - roda o pipeline (aqui, FALSO)
#    - $TimerFila (100ms) consome  <---  - empurra mensagens na $FilaMsg
#    - grava flags no $Controle    --->  - le as flags a cada ciclo de 200ms
#
#  A fila e uma ConcurrentQueue (thread-safe por construcao). As flags vivem
#  numa hashtable sincronizada. Nenhum controle WPF e tocado fora da thread
#  da janela - o DispatcherTimer garante isso.

$script:FilaMsg  = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
$script:Controle = [hashtable]::Synchronized(@{ Pausar = $false; Cancelar = $false; Rodando = $false })
$script:MotorPS = $null; $script:MotorRunspace = $null; $script:MotorHandle = $null
$script:TsAcao = $null      # hora do F1/F2, para medir a latencia do ack do motor
$script:TsCancel = $null    # hora do ESC, para medir quanto o motor levou para encerrar

# ---- PESOS DAS ETAPAS: medidos, nao chutados -------------------------------
# Vieram do log real do Fallout S02E01 (28,49 GB, 1h00m10s) de 31/07:
#   [1/7] 1s | [2/7] 60s | [3/7] 65s | [4/7] 921s | [5/7] 0s | [6/7] 143s | [7/7] 0s
# A etapa 4 (DeeZy) e 77% do tempo QUANDO tem audio para converter - e ~zero
# quando o motor reaproveita uma faixa Atmos/JOC que ja existe. Por isso o peso
# nao pode ser um so: ele e escolhido POR VIDEO, pelo diagnostico que a tela ja
# fez. Os pesos antigos da prova falsa diziam 1% para a etapa 4 e 44% para a 6 -
# o oposto do que acontece de verdade.
# v16.34 - PESOS REFEITOS, MEDIDOS EM 14 CONVERSOES REAIS
#
# O que estava errado nos pesos de cima (mantidos aqui como historico):
#   - a etapa 4 tinha peso 921 de 1.192 (77%) e rodava 0 SEGUNDO em 10 das 12
#     conversoes medidas, porque o audio estava desligado. Quando ela fechava
#     com 0s carregando 77% do peso, a regua (s por unidade de peso) despencava
#     8x de uma vez e TODAS as etapas seguintes eram re-escaladas no meio da
#     corrida. E isso que fazia a barra encher varias vezes.
#   - a etapa 5 (legenda) tinha peso 1 (0,1%) e e 22% do tempo real.
#   - a escolha do par de pesos olhava $v.AUprecisa, que e o DIAGNOSTICO
#     automatico. Com "manter audio" marcado na mao, o diagnostico continua
#     dizendo "precisa" - por isso o Troia de 20:03, com audio desligado,
#     ainda imprimiu "pesos somando 1.192".
#
# Medias medidas (12 conversoes de GoT S08E01, Homem-Aranha e Troia, mais o
# Se7en e o Homem-Aranha Sem Volta):
#        etapa 1 ffprobe    0,5%      etapa 5 legenda    21,9%
#        etapa 2 video     16,7%      etapa 6 mkvmerge   38,8%
#        etapa 3 dovi_tool 22,1%      etapa 7 limpeza     0,0%
# A etapa 4 nao entra nessa media porque ela nao e uma fracao fixa: depende do
# codec de origem. Medida separada:
#        TrueHD -> E-AC-3 Atmos (DeeZy + truehdd): 73,7% do tempo total
#            (Homem-Aranha Sem Volta, 61,5 GB: 43m49s de 59m28s)
#        DTS -> E-AC-3 (ffmpeg):                   15,9% do tempo total
#            (Troia, 87 GB: 3m08s de 19m44s)
# Por isso o peso do audio nao e um numero so - sao dois, e zero quando a
# etapa nao vai rodar.
# 16.37: Ffprobe e Limpeza sairam da LISTA de etapas, mas o tempo deles nao
# some do mundo - o diagnostico gasta ~5 unidades e a limpeza ~0. Os dois
# foram somados dentro de Video, a primeira etapa de trabalho, pra estimativa
# do lote continuar batendo com o relogio.
<#  ==========================================================================
    16.64: O MODELO DE TEMPO FOI REFEITO EM CIMA DE 12 CONVERSOES REAIS.
    ==========================================================================
    Ate a 16.63 TUDO era estimado por GB. Doze conversoes na 1.5.6 (8
    episodios de Fallout S02, Lara Croft, Troia, Homem-Aranha e Game of
    Thrones S08E01) mostraram que isso e errado etapa por etapa - e o erro
    ia de +2,8% a +71%.

    O QUE CADA ETAPA REALMENTE SEGUE (medido, nao chutado):

    [1] extracao do video  -> GB.  2,3 s/GB
        Fallout 2,77/2,15/2,28/2,82/2,01/1,92/3,30/2,69 | Troia 1,95 | Aranha 2,07

    [2] dovi_tool          -> GB.  2,6 s/GB
        Fallout 2,14 a 3,48 | Troia 2,62 | Aranha 2,47

    [3] audio TrueHD       -> DURACAO DO FILME. 14,9 s por minuto.
        Este foi o achado grande. A etapa mais cara de todas (60 a 77% do
        tempo) nao tem nada a ver com o tamanho do arquivo - ela codifica
        audio, e audio se mede em MINUTOS:
            Fallout E01..E08: 15,30 14,96 14,98 15,25 15,12 14,61 14,70 14,55
            Homem-Aranha    : 14,89   <- 61,5 GB, o dobro do Fallout, MESMO numero
        Dispersao de 1,9% em nove medidas. Por GB a mesma etapa variava de
        24,9 a 35,9 s/GB - 44%. Era isso que fazia o Fallout inteiro sair
        com +30 a +45% de erro.

    [3] audio DTS/AC-3     -> DURACAO. 1,1 s por minuto.
        Troia 0,99 | Lara Croft 1,19

    [4] legenda            -> NUMERO DE BLOCOS. 0,28 s por bloco.
        Lara 718 blocos/167s = 0,233 | Troia 1378/395 = 0,287
        Aranha 1904/579 = 0,304
        So que o numero de blocos so existe DEPOIS do OCR. O que da para
        saber antes e a duracao, e blocos por minuto varia muito (Lara 6,1 |
        Troia 7,0 | GoT 8,4 | Aranha 12,9). Entao aqui a estimativa usa
        8,6 blocos/min x 0,28 s = 2,4 s/min, e esta e a etapa mais fraca do
        modelo - de proposito, porque nao ha o que medir antes.
        A 16.64 passou a GRAVAR NO LOG o tamanho da faixa PGS e o numero de
        blocos que saiu, para a proxima rodada trocar a duracao pelo
        tamanho da PGS, que deve prever bloco muito melhor.

    [5] remontagem         -> GB.  5,6 s/GB com video extraido, 2,8 sem.
        Fallout 6,14/5,48/5,55/6,82/5,27/5,64/6,53/5,31 | Troia 4,69 | Aranha 5,79
        Lara (remux direto, sem temporario para apagar) 2,75
        A 16.63 modelou esta etapa como "274s fixos + 1,39 s/GB" a partir de
        tres arquivos todos entre 61 e 87 GB. Os oito Fallout, de 25 a 31 GB,
        provaram que aquilo era ajuste em cima de pontos amontoados: a etapa
        e linear em GB e passa perto do zero.

    O DISCO DE ORIGEM MUDA TUDO NAS ETAPAS DE I/O. O Game of Thrones veio de
    um HD mecanico (G:) e as etapas de disco levaram de 3 a 6 vezes mais:
        extracao 14,93 s/GB (contra 2,3)  |  dovi 11,97 (contra 2,6)
        remontagem 17,79 s/GB (contra 5,6)
    enquanto o audio quase nao mudou (17,9 contra 14,9 s/min) - ele e CPU.
    Por isso a 16.64 MEDE a velocidade de leitura da origem antes de estimar,
    em vez de perguntar ao Windows que tipo de disco e: o que importa nao e
    ser SSD ou HD, e quantos MB/s aquele caminho entrega - e pasta de rede
    entra na mesma conta sem codigo novo.
    ========================================================================== #>
$script:TempoEtapa = @{
    ExtracaoSegPorGb   = 2.3
    DoviSegPorGb       = 2.6
    AudioTrueHDSegPorMin = 14.9
    AudioOutroSegPorMin  = 1.1
    LegendaSegPorMin     = 2.4     # so o plano B: 8,6 blocos/min x 0,28 s/bloco
    <#  16.65: agora o numero de blocos E conhecido antes de converter (ver
        num_index_entries na leitura das faixas), entao esta e a conta
        principal e a de cima virou plano B.
        Calibrado nas 12 conversoes: com 0,28 o erro medio do TOTAL cai de
        5,26% para 2,84% e o pior caso de 24,3% para 8,8%. Testei 0,26 a
        0,31 - 0,28 e o melhor. #>
    LegendaSegPorBloco   = 0.28
    LegendaFracaoReocr   = 0.56    # medido no Troia de 18/08: 343s de 612s
    <#  16.72: A REMONTAGEM TEM PARTE FIXA - por GB puro ela nao fecha.
        Medido (mkvmerge, remux direto): Jackie Brown 81,40 GB -> 170s e 175s
        (2,10 s/GB); Jumanji 41,79 GB -> 113s e 114s (2,72 s/GB). O s/GB muda
        40% entre os dois, o que so acontece quando ha custo fixo. A reta
        pelos dois pontos: 51s + 1,49 s/GB - e ela devolve 172s e 113s, os
        dois na mosca. Com video extraido so ha um ponto (Troy, 87 GB, 365s):
        mesmo intercepto, 3,6 s/GB. #>
    RemontagemSegFixo    = 51      # os dois casos pagam este pedaco
    RemontagemSegPorGb   = 3.6     # com video extraido (remonta + apaga temporario)
    RemontagemDiretoSegPorGb = 1.49 # remux direto do original, sem temporario
    DiagnosticoSeg       = 4
    <#  16.70: A CONFERENCIA E A LIMPEZA CUSTAM TEMPO E NINGUEM CONTAVA.
        Elas ficam fora da regua DESENHADA de proposito (ver $Cfg), e ate a
        16.69 isso tinha virado "nao existem": o video marcava 100%, a fila
        marcava 100% e a tela dizia "Terminando Agora" com o mkvmerge ainda
        montando e mais 40s de ffmpeg pela frente.
        Medido em 4 conversoes reais: Jumanji 40s e 40s, Troy 41s, Jackie
        Brown 25s (41-87 GB). Nao escala com o tamanho - e ffmpeg lendo 10
        trechos curtos. Numero fixo, e honesto. #>
    <#  16.72: cinco medidas agora - 40s, 40s (Jumanji), 41s (Troy), 25s e
        23s (Jackie Brown). Media 34, e os dois curtos sao do arquivo sem
        Dolby Vision para converter. Numero unico, no meio. #>
    ConferenciaSeg       = 32       # medido: "DIAGNOSTICO do arquivo: parede 00m 04s"
}
<#  16.64: NEM TODA ETAPA SOFRE IGUAL COM DISCO LENTO.
    O Game of Thrones veio de um HD mecanico e deu a medida de cada uma
    (fator sobre o mesmo trabalho no SSD):
        extracao do video 6,5x   dovi_tool 4,6x   remontagem 3,2x
        audio             1,2x   legenda   1,3x
    Faz sentido: extracao e remontagem sao disco puro; o dovi_tool le e
    reescreve mas tambem calcula; audio e legenda sao CPU - o disco so entra
    na leitura da faixa.
    A sensibilidade abaixo e quanto do fator de disco cada etapa absorve:
    tempo = base * (1 + (fator - 1) * sensibilidade).
    Conferido: com fator 6,5 dao 6,5x / 4,6x / 1,2x / 1,3x / 3,2x - os
    numeros medidos. Com disco de referencia (fator 1) todas dao 1, ou seja,
    nada muda para quem le do SSD.
    AVISO HONESTO: isto saiu de UM filme num HD. Serve para nao errar 36%
    para baixo como a 16.63 errou nele, nao para ser lei. #>
$script:SensibilidadeDisco = @{
    Extracao = 1.00
    Dovi     = 0.65
    Audio    = 0.04
    Legenda  = 0.06
    Remontagem = 0.40
}
function Get-FatorDaEtapa([string]$Etapa) {
    $sens = [double]$script:SensibilidadeDisco[$Etapa]
    return 1.0 + ((Get-FatorDisco) - 1.0) * $sens
}
<#  A velocidade de leitura de referencia e a do SSD do Diego, tirada da
    propria etapa de extracao: 2,3 s/GB = 1024/2,3 = 445 MB/s efetivos.
    O fator de disco e (referencia / medido), preso entre 1 e 8:
      - 1 porque disco mais rapido que o de referencia nao encolhe o tempo de
        CPU das ferramentas, e prometer menos tempo do que vai levar e o pior
        tipo de erro aqui;
      - 8 porque acima disso a conta vira ficcao (pen drive, rede ruim) e um
        numero absurdo na tela e pior que um numero conservador.
    Conferido contra o Game of Thrones do HD: com o fator o total previsto
    fica em 1.947s para 2.037s reais (-4,4%); sem ele, 1.296s (-36%). #>
$script:MbPorSegReferencia = 445.0
$script:SegPorGbPorPeso = 0.0153

# --- pesos antigos, guardados so pra nao perder a referencia do Fallout ---
$script:PesosComAudio  = @(1, 60, 65, 921, 1, 143, 1)
$script:PesosSemAudio  = @(1, 60, 65,   5, 1, 143, 1)
$script:RefGB          = 28.49
$script:RefSegComAudio = 1190
$script:RefSegSemAudio = 269

# ---- O trabalho que roda DENTRO do runspace --------------------------------
# Regras deste bloco: nada de WPF, nada de Escrever-Log direto (o log e da
# janela) - tudo sai como mensagem na fila.
#
#  A RECEITA (provada em maquina real pelas sondas 16.0-s2 ate s5, que
#  converteram o Fallout inteiro com estrutura identica a do console):
#
#   1. as 59 funcoes do motor entram por AST (dot-source). O arquivo do motor
#      nao e alterado nem copiado.
#   2. o bloco Add-Type do motor e executado - e dele que sai o [DdvtJob],
#      o Job Object que mata os filhos junto e o NtSuspendProcess que congela
#      o processo na pausa. Ele NAO e funcao, entao a AST precisa busca-lo
#      separado.
#   3. TODO o preparo de topo do motor roda VERBATIM, statement a statement,
#      ate a linha em que ele monta a propria lista de arquivos. Isso traz
#      paleta, constantes, caminhos das ferramentas e o teste do DeeZy/OCR.
#      Duas trocas, as unicas: qualquer variavel que o motor calcule a partir
#      de $MyInvocation recebe a raiz informada aqui (dentro de um runspace o
#      $MyInvocation nao aponta para arquivo nenhum, e sem isso TODO caminho
#      de ferramenta vira string vazia), e o Start-Transcript e pulado.
#   4. QUATRO nomes sao redefinidos. No PowerShell a funcao vence o cmdlet e a
#      definicao nova vence a antiga, entao o motor passa a falar com a janela
#      achando que fala com o console:
#         Write-Host              -> vira log (e e de onde saem a etapa [n/7]
#                                    e o "ARQUIVO n/N", que o motor ja imprime)
#         Show-Barra              -> vira a porcentagem da barra
#         Show-BarraCompleta      -> 100%
#         Invoke-ControlesTeclado -> le as flags F1/ESC da janela em vez do
#                                    teclado, e chama as funcoes REAIS de
#                                    pausar, retomar e cancelar do motor
#   5. $files recebe SO os videos marcados, $OutputDir a pasta de saida da tela
#   6. executa o proprio foreach do motor (776 linhas, da 2389 a 3164).
#
#  Consequencia: nao existe copia da logica do motor aqui dentro. Se o motor
#  for atualizado, a janela roda a versao nova sem uma linha de mudanca.
$script:TrabalhoMotor = {
    # 16.15: a escolha manual chega como PARAMETRO, nao como variavel solta.
    # Tres builds tentaram entregar por variavel (16.12 sem prefixo, 16.13
    # com $global:, 16.14 com nome proprio) e a Sonda_Entrega mediu PERDEU nas
    # tres. Parametro nao depende de escopo nenhum: o valor e ligado ao nome
    # no momento da chamada, igual a qualquer funcao. param() TEM que ser a
    # primeira instrucao do bloco - a mesma regra que quebrou o motor 13.3.
    param($EscolhasDaJanela)
    function Enviar($m) { $Fila.Enqueue($m) }
    function Avisar([string]$t, [string]$tipo = "MOTOR") { Enviar @{ T = "log"; Texto = $t; Tipo = $tipo } }
    try {
        $Controle.Rodando = $true
        Avisar ("Runspace vivo na thread {0} (a janela esta em outra)" -f [System.Threading.Thread]::CurrentThread.ManagedThreadId)

        $errosSint = $null; $tokens = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($CaminhoMotor, [ref]$tokens, [ref]$errosSint)

        # --- 1. funcoes do motor, por AST ---------------------------------
        $todas = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        $defs = @()
        foreach ($fd in $todas) {
            $pai = $fd.Parent; $aninhada = $false
            while ($pai) {
                if ($pai -is [System.Management.Automation.Language.FunctionDefinitionAst]) { $aninhada = $true; break }
                $pai = $pai.Parent
            }
            if (-not $aninhada) { $defs += $fd.Extent.Text }
        }
        . ([scriptblock]::Create(($defs -join "`r`n`r`n")))
        Avisar ("{0} funcoes do motor carregadas (o arquivo dele nao foi tocado)" -f $defs.Count)

        # --- 2. o Add-Type do motor: [DdvtJob] ----------------------------
        if (-not ('DdvtJob' -as [type])) {
            $addT = @($ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                $args[0].GetCommandName() -eq 'Add-Type' }, $true))
            if ($addT.Count -gt 0) {
                & ([scriptblock]::Create($addT[0].Extent.Text))
                Avisar "Job Object e NtSuspendProcess carregados do bloco Add-Type do motor"
            } else { Avisar "nao achei o bloco Add-Type do motor - a pausa pode nao congelar o processo" "ERRO" }
        }
        if ('DdvtJob' -as [type]) { try { [DdvtJob]::Iniciar() } catch { } }

        # --- 3. o preparo de topo, verbatim -------------------------------
        # O motor inteiro vive dentro de UM try de topo, entao a lista precisa
        # DESCER dentro dele e parar na linha em que ele monta $files.
        $listaPrep = @()
        $parar = $false
        foreach ($st in @($ast.EndBlock.Statements)) {
            if ($parar) { break }
            if ($st -is [System.Management.Automation.Language.FunctionDefinitionAst]) { continue }
            if ($st -is [System.Management.Automation.Language.TryStatementAst]) {
                foreach ($st2 in @($st.Body.Statements)) {
                    if ($st2 -is [System.Management.Automation.Language.FunctionDefinitionAst]) { continue }
                    if ($st2.Extent.Text -match '^\s*\$files\s*=') { $parar = $true; break }
                    $listaPrep += $st2
                }
                continue
            }
            if ($st.Extent.Text -match '^\s*\$files\s*=') { $parar = $true; break }
            $listaPrep += $st
        }
        # A execucao fica AQUI, no escopo do script: dot-source dentro de funcao
        # deixaria as variaveis do motor presas no escopo da funcao.
        $prepFalhas = 0; $prepOk = 0
        foreach ($st in $listaPrep) {
            $txt = $st.Extent.Text
            $ln  = $st.Extent.StartLineNumber
            if ($txt -match '^\s*\$(\w+)\s*=\s*Split-Path\s+-Parent\s+\$MyInvocation') {
                $nomeVar = $Matches[1]
                $txt = ('${0} = ''{1}''' -f $nomeVar, $Raiz.Replace("'", "''"))
                Avisar ("linha {0}: {1} informada pela janela (no motor vem de MyInvocation)" -f $ln, $nomeVar) "PROVA"
            } elseif ($txt -match '^\s*Start-Transcript') {
                continue
            }
            try { . ([scriptblock]::Create($txt)); $prepOk++ }
            catch { $prepFalhas++; Avisar ("preparo do motor falhou na linha {0}: {1}" -f $ln, $_.Exception.Message) "ERRO" }
        }
        Avisar ("preparo do motor: {0} statements executados, {1} falha(s)" -f $prepOk, $prepFalhas)
        # Atras da janela nao existe console: sem codigo ANSI no log e sem
        # tentativa de ler teclado (as teclas sao da janela, viram flag).
        $script:AnsiOn            = $false
        $script:ConsoleInterativo = $false

        # --- 4. relogios e regua de progresso ------------------------------
        $script:swVideo = [System.Diagnostics.Stopwatch]::StartNew()
        $script:swEtapa = [System.Diagnostics.Stopwatch]::StartNew()
        $script:ultimaRepintura = $null
        $script:idxVideo = -1
        $script:etapaIdx = 0
        # 16.37: cinco etapas de trabalho (o diagnostico e a limpeza sairam
        # da regua - ver o comentario grande em $Cfg). O tamanho passou a ser
        # lido do proprio array em vez de escrito 7 a mao.
        $script:pesos = @(1,1,1,1,1)
        $script:pesoFeito = 0.0
        $script:segFeito = 0.0        # tempo das etapas CONCLUIDAS - so ele
        $script:unidade = 1.0
        $script:unidade0 = 1.0        # a estimativa inicial, ancora da faixa
        $script:somaPesos = 5.0
        $script:ultimoPct = 0

        function Somar-PesosRestantes([int]$Apos) {
            $n = @($script:pesos).Count
            if ($n -le 0) { return 0.0 }
            $t = 0.0
            for ($i = $Apos + 1; $i -lt $n; $i++) { $t += [double]$script:pesos[$i] }
            return $t
        }
        function Enviar-Pct([int]$Pct) {
            $script:ultimoPct = $Pct
            $segVideo = $script:swVideo.Elapsed.TotalSeconds
            # A unidade (segundos por unidade de peso) comeca na estimativa e se
            # corrige sozinha conforme as etapas terminam: com trabalho medido
            # em maos, a estimativa deixa de ser chute.
            # Peso concluido x TEMPO CONCLUIDO - as duas metades medindo a
            # mesma coisa. E so quando ja ha amostra que valha (5% do peso).
            if ($script:pesoFeito -ge (0.05 * $script:somaPesos) -and $script:segFeito -gt 1) {
                $u = $script:segFeito / $script:pesoFeito
                $piso = $script:unidade0 * 0.25
                $teto = $script:unidade0 * 4.0
                $script:unidade = [math]::Max($piso, [math]::Min($teto, $u))
            }
            # 16.37: guarda de indice. Com [DIAGNOSTICO] e [LIMPEZA] fora da
            # numeracao, $etapaIdx pode ficar apontando pra ultima etapa
            # enquanto a limpeza roda - sem esta trava seria acesso fora do
            # array e a barra morreria no fim de cada video.
            $nP = @($script:pesos).Count
            $iP = [math]::Max(0, [math]::Min($nP - 1, $script:etapaIdx))
            $restPeso = (Somar-PesosRestantes $iP) +
                        ((100.0 - $Pct) / 100.0) * $script:pesos[$iP]
            Enviar @{ T = "pct"; Pct = $Pct
                      SegEtapa  = [math]::Floor($script:swEtapa.Elapsed.TotalSeconds)
                      SegVideo  = [math]::Floor($segVideo)
                      RestVideo = [math]::Floor([math]::Max(0, $script:unidade * $restPeso))
                      Fator     = $(if ($script:unidade0 -gt 0) { $script:unidade / $script:unidade0 } else { 1.0 }) }
        }

        # --- 5. AS QUATRO TRAVAS -------------------------------------------
        function Write-Host {
            param(
                [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromRemainingArguments = $true)] $Object,
                [switch] $NoNewline,
                $ForegroundColor, $BackgroundColor, $Separator
            )
            $t = [string]$Object
            if (-not $t -or $t.Trim().Length -eq 0) { return }
            $lim = $t.Trim()
            # 16.9: Write-Host -NoNewline com "`r" na frente e REPINTURA de
            # console - o motor reescreve o MESMO ponto da linha, nao produz
            # conteudo novo. No console isso e uma linha so que pisca; aqui
            # virava uma linha de log a cada 200ms. O "preparando OCR..." do
            # PgsToSrt encheu 413 das 704 linhas de uma sessao inteira (59%).
            # Registra a PRIMEIRA (a informacao interessa: o OCR esta se
            # preparando) e cala as repeticoes identicas ate o texto mudar.
            if ($NoNewline) {
                if ($lim -eq $script:ultimaRepintura) { return }
                $script:ultimaRepintura = $lim
                # 16.10: a repintura tambem vira NOTA na linha da etapa. No
                # console ela E a tela ("preparando OCR..." piscando no lugar
                # da barra); aqui ela sumia e a etapa 5/7 ficava 1m44s parada
                # em 0% sem dizer o que estava acontecendo.
                Enviar @{ T = "log"; Texto = $lim; Tipo = "MOTOR" }
                Enviar @{ T = "nota"; Texto = $lim }
                return
            } else {
                $script:ultimaRepintura = $null
            }
            # O motor JA anuncia o arquivo e a etapa. Nao ha nada a inventar:
            # so escutar o que ele diz.
            if ($lim -match '^ARQUIVO\s+(\d+)\/(\d+)\s*:\s*(.+)$') {
                $script:idxVideo = [int]$Matches[1] - 1
                $script:swVideo.Restart()
                $script:pesoFeito = 0.0
                $script:etapaIdx = 0
                $i = $script:idxVideo
                $itens = @($Lote)
                if ($i -ge 0 -and $i -lt $itens.Count -and $itens[$i]) {
                    $script:pesos = @($itens[$i].Pesos)
                    $somaP = 0.0; foreach ($p in $script:pesos) { $somaP += [double]$p }
                    if ($somaP -gt 0) {
                        $script:somaPesos = $somaP
                        $script:unidade = [double]$itens[$i].SegEstimado / $somaP
                        $script:unidade0 = $script:unidade
                        $script:segFeito = 0.0
                        # Deixa o numero no log: se a estimativa sair errada de
                        # novo, da pra ver POR QUE sem precisar adivinhar.
                        # 16.42: o NOME entrou na mensagem. Esta linha e emitida
                        # quando chega o "ARQUIVO n/N" do proximo video, e no log
                        # ela aparecia ANTES do nome dele - dava a impressao de
                        # ser a estimativa do video que tinha acabado de fechar
                        # (no log de 18/08 ela dizia 3.811s logo depois de um
                        # episodio que levou 737s). Os numeros sempre estiveram
                        # certos; faltava dizer de quem eram.
                        Enviar @{ T = "log"; Tipo = "PROVA"
                                  Texto = ("estimativa de '{0}': {1:N0}s (pesos somando {2:N0})" -f $itens[$i].Nome, $itens[$i].SegEstimado, $somaP) }
                    } else {
                        Enviar @{ T = "log"; Tipo = "ERRO"; Texto = "os pesos deste video vieram vazios - o tempo restante vai ficar sem base" }
                    }
                } else {
                    Enviar @{ T = "log"; Tipo = "ERRO"
                              Texto = ("nao achei este video no lote (indice {0} de {1}) - o tempo restante vai ficar sem base" -f $i, $itens.Count) }
                }
                Enviar @{ T = "arquivo"; Idx = $script:idxVideo; Total = [int]$Matches[2]; Nome = $Matches[3] }
            }
            # 16.37: o denominador deixou de ser 7 fixo. O motor 14.13 fala
            # "[1/5]".."[5/5]" para as etapas de trabalho e usa marcador de
            # TEXTO para as duas que nao sao trabalho ([DIAGNOSTICO] e
            # [LIMPEZA]) - assim elas aparecem na tela e no log sem entrar na
            # regua nem na divisao do tempo restante.
            # Os tres estao ANCORADOS no ">" que o SayStep escreve. Sem a
            # ancora, um "[1/8]" vindo de qualquer saida repassada de
            # ferramenta (o Reocr numera os blocos assim) seria lido como
            # troca de etapa.
            elseif ($lim -match '^>\s*\[DIAGNOSTICO\]') {
                Enviar @{ T = "fase"; Nome = "Diagnóstico do arquivo" }
            }
            elseif ($lim -match '^>\s*\[VERIFICACAO\]') {
                Enviar @{ T = "fase"; Nome = "Conferindo o arquivo final" }
            }
            elseif ($lim -match '^>\s*\[LIMPEZA\]') {
                Enviar @{ T = "fase"; Nome = "Limpando temporários" }
            }
            elseif ($lim -match '^>\s*\[(\d+)\/(\d+)\]') {
                $novo = [int]$Matches[1] - 1
                $nEtapas = @($script:pesos).Count
                if ($novo -lt 0) { $novo = 0 }
                if ($novo -gt ($nEtapas - 1)) { $novo = $nEtapas - 1 }
                if ($novo -ne $script:etapaIdx) {
                    $script:pesoFeito += [double]$script:pesos[$script:etapaIdx]
                    $script:segFeito  += $script:swEtapa.Elapsed.TotalSeconds
                    Enviar @{ T = "log"; Tipo = "PROVA"
                              Texto = ("regua: {0:N0}s feitos para {1:N0} de peso -> {2:N2}s por unidade (base {3:N2})" -f `
                                       $script:segFeito, $script:pesoFeito, ($script:segFeito / [math]::Max(1, $script:pesoFeito)), $script:unidade0) }
                }
                $script:etapaIdx = $novo
                $script:swEtapa.Restart()
                Enviar @{ T = "etapa"; Idx = $novo }
            }
            Enviar @{ T = "log"; Texto = $lim; Tipo = "MOTOR" }
        }
        function Show-Barra($Pct) {
            Enviar-Pct ([int][math]::Floor([math]::Max(0, [math]::Min(100, $Pct))))
        }
        function Show-BarraCompleta() {
            if (-not $script:CancelamentoSolicitado) { Enviar-Pct 100 }
        }
        function Invoke-ControlesTeclado($Proc) {
            # Mesmo papel da original do motor - e chamada a cada volta dos
            # loops de progresso. So que le a flag da janela em vez do teclado,
            # e quem pausa, retoma e cancela sao as funcoes REAIS dele.
            if ($script:CancelamentoSolicitado) { return }
            if ($Controle.Cancelar) { Request-Cancelamento $Proc; return }
            if ($Controle.Pausar) {
                $ini = Get-Date
                Suspender-Processo $Proc
                Enviar @{ T = "ack"; V = "pausado" }
                $script:swVideo.Stop(); $script:swEtapa.Stop()
                while ($Controle.Pausar -and -not $Controle.Cancelar) { Start-Sleep -Milliseconds 120 }
                Retomar-Processo $Proc
                $script:swVideo.Start(); $script:swEtapa.Start()
                $script:SegundosPausadosEtapa += ((Get-Date) - $ini).TotalSeconds
                if ($Controle.Cancelar) { Request-Cancelamento $Proc; return }
                Enviar @{ T = "ack"; V = "rodando" }
            }
        }

        # --- 6. a selecao da tela e a pasta de saida da tela ----------------
        $OutputDir = $SaidaDir
        $files = @()
        foreach ($item in $Lote) {
            try { $files += Get-Item -LiteralPath $item.Caminho } catch { Avisar ("nao consegui abrir: {0}" -f $item.Caminho) "ERRO" }
        }
        # 16.13: se um video sumiu da pasta entre a leitura e o Iniciar (voce
        # trocou os arquivos com o programa aberto), o Get-Item acima falha e
        # a fila encolhe calada - na 16.12 isso terminou num resumo dizendo
        # "Total de Videos na Fila: 0", como se nada tivesse sido pedido.
        $sumiram = @($Lote).Count - @($files).Count
        if ($sumiram -gt 0) {
            Avisar ("{0} de {1} video(s) da fila nao existem mais na pasta de origem e foram ignorados" -f $sumiram, @($Lote).Count) "ERRO"
        }
        if (@($files).Count -eq 0) {
            throw "Nenhum video da fila existe mais na pasta de origem. Clique em Atualizar para reler a pasta e monte a fila de novo."
        }
        $numero = 0
        if ($null -eq $resultados) { $resultados = @() }

        # --- 6b. a porta das escolhas manuais (motor 13.3+) ----------------
        # O NOME DIFERENTE E O CONSERTO. Duas builds erraram isto:
        #  16.12 - lia $EscolhasManuais sem prefixo e achava $null;
        #  16.13 - trocou para $global:EscolhasManuais e continuou $null.
        # O motivo so apareceu quando a Sonda_Entrega mediu os dois casos num
        # runspace de verdade e deu PERDEU nos DOIS: um script adicionado com
        # AddScript no topo de um runspace roda num lugar onde $script: E
        # $global: SAO O MESMO ESCOPO. Ou seja, o "$script:EscolhasManuais =
        # $null" do preparo do motor apagava a propria variavel que a janela
        # tinha mandado - nenhum prefixo resolvia, porque o problema nunca foi
        # de prefixo e sim de NOME REPETIDO.
        # Agora a janela manda como EscolhasDaJanela, que o motor nao conhece
        # e portanto nao tem como apagar, e so aqui - DEPOIS do preparo - o
        # valor e copiado para o nome que o motor le.
        if ($EscolhasDaJanela -and $EscolhasDaJanela.Count -gt 0) {
            $script:EscolhasManuais = $EscolhasDaJanela
            Avisar ("porta manual ABERTA para {0} arquivo(s)" -f $EscolhasDaJanela.Count) "PROVA"
        } else {
            $script:EscolhasManuais = $null
            # Este log existe por causa daquele silencio: agora o log SEMPRE
            # diz de que lado a porta esta, e um "FECHADA" com escolha na tela
            # aponta o problema na hora.
            Avisar "porta manual FECHADA (nenhuma escolha recebida)" "PROVA"
        }

        # --- 7. o proprio foreach do motor ---------------------------------
        $laco = @($ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.ForEachStatementAst] -and
            $args[0].Variable.VariablePath.UserPath -eq 'f' -and
            $args[0].Condition.Extent.Text -match '\$files' }, $false))
        if ($laco.Count -eq 0) { throw "nao localizei o laco principal do motor na AST" }
        Avisar ("laco do motor localizado: {0} linhas a partir da linha {1}" -f `
            ($laco[0].Extent.EndLineNumber - $laco[0].Extent.StartLineNumber + 1), $laco[0].Extent.StartLineNumber) "PROVA"
        . ([scriptblock]::Create($laco[0].Extent.Text))

        $comoFim = "concluida"
        if ($script:CancelamentoSolicitado) { $comoFim = "interrompida" }
        Enviar @{ T = "fim"; Como = $comoFim; Resultados = @($resultados) }
    } catch {
        Enviar @{ T = "log"; Texto = ("ERRO no runspace: {0}" -f $_.Exception.Message); Tipo = "ERRO" }
        Enviar @{ T = "fim"; Como = "interrompida"; Resultados = @() }
    } finally {
        $Controle.Rodando = $false
    }
}

# ---- O trabalho de LEITURA da pasta (roda no runspace) ---------------------
# Faz o que a Sonda 15.0-s1 provou na maquina real: le a arvore do motor,
# extrai SO as definicoes de funcao (o arquivo nao e alterado nem copiado),
# injeta os caminhos das ferramentas com os nomes que o motor usa por dentro,
# e chama o cerebro dele arquivo por arquivo.
$script:TrabalhoLeitura = {
    function Enviar($m) { $Fila.Enqueue($m) }
    function Avisar([string]$t, [string]$tipo = "LEITURA") { Enviar @{ T = "log"; Texto = $t; Tipo = $tipo } }
    try {
        # --- 1. ferramentas ---
        $achar = {
            param($nome)
            $r = Get-ChildItem -Path $PastaScript -Filter $nome -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($r) { return $r.FullName } else { return $null }
        }
        $mkvmerge  = & $achar "mkvmerge.exe"
        $ffprobe   = & $achar "ffprobe.exe"
        $ffmpeg    = & $achar "ffmpeg.exe"
        $dovi_tool = & $achar "dovi_tool.exe"
        $mediainfo = & $achar "MediaInfo.exe"
        $deezy     = & $achar "deezy.exe"
        $pgstosrt  = & $achar "PgsToSrt.dll"
        # v16.33: mesma logica do motor (temSeconv) - seconv.exe + Latin.db
        # precisam existir os dois pra contar como disponivel. So pra EXIBIR
        # certo no diagnostico/checklist - a decisao de verdade continua so
        # do motor, a janela so reflete o que ele provavelmente vai escolher.
        $seconvExe = & $achar "seconv.exe"
        $latinDb   = & $achar "Latin.db"
        $temSeconvJanela = [bool]$seconvExe -and [bool]$latinDb
        <#  16.52: O TESSERACT PASSOU A MORAR EM tools\ - E A JANELA NAO SABIA.
            O comentario que estava aqui dizia "o tesseract.exe NAO mora em
            tools\ - ele e instalado a parte", e isso era verdade ate o motor
            14.23. A partir dele o Tesseract vai EMPACOTADO no instalador, e o
            motor e o Reocr passaram a resolver tools\Tesseract\ primeiro.
            A janela ficou para tras nos dois pontos em que procura por ele.

            Efeito medido na instalacao limpa de 25/08, sem Tesseract
            instalado por fora: a bolinha da barra de ferramentas ficou
            AMARELA, dizendo que o motor do re-OCR nao existe - enquanto o
            arquivo estava ali, empacotado, e a conversao ia usa-lo
            normalmente. A tela contradizia o programa.

            Mesma ordem do motor: pasta local primeiro, sistema so como
            ultimo recurso. #>
        <#  Usa o mesmo $achar das outras ferramentas: ele varre tools\ de
            forma recursiva, entao acha tanto tools\Tesseract\ quanto
            qualquer nome de subpasta que venha a ser usado no futuro. Uma
            lista de caminhos a mao aqui envelheceria igual ao comentario que
            esta correcao substituiu. #>
        $tesseractJanela = & $achar "tesseract.exe"
        if (-not $tesseractJanela) { $tesseractJanela = "" }
        if ($tesseractJanela -eq "") {
            try {
                $cmdT = Get-Command "tesseract.exe" -ErrorAction SilentlyContinue
                if ($cmdT) { $tesseractJanela = $cmdT.Source }
            } catch { }
        }
        if ($tesseractJanela -eq "") {
            foreach ($cT in @("C:\Program Files\Tesseract-OCR\tesseract.exe",
                              "C:\Program Files (x86)\Tesseract-OCR\tesseract.exe")) {
                if (Test-Path -LiteralPath $cT) { $tesseractJanela = $cT; break }
            }
        }
        # String vazia quebraria o Test-Path -LiteralPath de
        # Get-SinaisAtmosMediaInfo; caminho inexistente apenas devolve $false.
        if (-not $mediainfo) { $mediainfo = Join-Path $PastaScript "_mediainfo_ausente.exe" }

        # 16.40: "Chip" e o nome curto que aparece na faixa do topo durante a
        # conversao. Vazio = fica so no painel de Ferramentas, nao sobe pro topo.
        # Escolhi as SEIS que decidem se um pedaco do trabalho acontece, na
        # ordem do pipeline. ffprobe ficou de fora de proposito: ele le
        # metadado, nao produz nada - se faltar, o programa nem chega na fila.
        $listaFerr = @(
            @{ Chip = "dovi_tool"; Rotulo = "Conversão de Perfil Dolby Vision 7 → 8.1 (dovi_tool)"; Papel = "obrigatória"; Ok = [bool]$dovi_tool; Caminho = $dovi_tool }
            @{ Chip = "mkvmerge";  Rotulo = "Extração e Remontagem de Vídeo (ffmpeg + mkvmerge)";   Papel = "obrigatória"; Ok = ([bool]$ffmpeg -and [bool]$mkvmerge); Caminho = $mkvmerge }
            @{ Chip = "";          Rotulo = "Leitura de Metadados (ffprobe)";                        Papel = "obrigatória"; Ok = [bool]$ffprobe; Caminho = $ffprobe }
            @{ Chip = "seconv";    Rotulo = "OCR de Legenda PT-BR (seconv/BinaryOCR - preferencial)"; Papel = "opcional";    Ok = $temSeconvJanela; Caminho = $seconvExe }
            @{ Chip = "PgsToSrt";  Rotulo = "OCR de Legenda PT-BR (PgsToSrt - reserva)";             Papel = "opcional";    Ok = [bool]$pgstosrt; Caminho = $pgstosrt }
            @{ Chip = "DeeZy";     Rotulo = "Áudio TrueHD → E-AC-3 Atmos (DeeZy)";                   Papel = "opcional";    Ok = [bool]$deezy; Caminho = $deezy }
            @{ Chip = "";          Rotulo = "Sinal de Atmos (MediaInfo)";                            Papel = "opcional";    Ok = (Test-Path -LiteralPath $mediainfo); Caminho = $mediainfo }
            # 16.38: TRES LINHAS QUE FALTAVAM.
            # A lista mostrava 7 ferramentas e nao dizia nada sobre as que
            # cuidam do TEXTO da legenda depois do OCR. O tesseract.exe em
            # especial e obrigatorio pro re-OCR de falas curtas (o que troca
            # "INF TOL" por "Nao!") - sem ele o motor pula a sub-etapa
            # inteira, em silencio pra quem so olha este painel.
            @{ Chip = "";          Rotulo = "Revisão de Blocos-Lixo do OCR (Corretor_Legenda)";      Papel = "opcional";    Ok = (Test-Path -LiteralPath (Join-Path $PastaScript "Corretor_Legenda.ps1")); Caminho = (Join-Path $PastaScript "Corretor_Legenda.ps1") }
            @{ Chip = "";          Rotulo = "Re-OCR de Falas Curtas (Reocr_Legenda)";                Papel = "opcional";    Ok = (Test-Path -LiteralPath (Join-Path $PastaScript "Reocr_Legenda.ps1")); Caminho = (Join-Path $PastaScript "Reocr_Legenda.ps1") }
            @{ Chip = "Tesseract"; Rotulo = "Motor do Re-OCR (Tesseract, empacotado)";               Papel = "opcional";    Ok = [bool]$tesseractJanela; Caminho = $tesseractJanela }
        )
        Enviar @{ T = "ferr"; Lista = $listaFerr }

        if (-not $mkvmerge -or -not $ffprobe) {
            Avisar "Sem mkvmerge ou ffprobe nao da para diagnosticar nada." "ERRO"
            Enviar @{ T = "leitura_fim"; Ok = 0; Erros = 1; Seg = 0 }
            return
        }

        # --- 2. abrir o motor pela AST (sem executa-lo) ---
        if (-not (Test-Path -LiteralPath $CaminhoMotor)) {
            Avisar "Converter_AUTO_DIRETO.ps1 nao encontrado ao lado da GUI." "ERRO"
            Enviar @{ T = "leitura_fim"; Ok = 0; Erros = 1; Seg = 0 }
            return
        }
        $errosSint = $null; $tokens = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($CaminhoMotor, [ref]$tokens, [ref]$errosSint)
        if ($errosSint -and $errosSint.Count -gt 0) {
            Avisar ("O motor tem {0} erro(s) de sintaxe - diagnostico pode falhar." -f $errosSint.Count) "AVISO"
        }
        $todas = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        $defs = @()
        foreach ($f in $todas) {
            $pai = $f.Parent; $aninhada = $false
            while ($pai) {
                if ($pai -is [System.Management.Automation.Language.FunctionDefinitionAst]) { $aninhada = $true; break }
                $pai = $pai.Parent
            }
            if (-not $aninhada) { $defs += $f.Extent.Text }
        }
        . ([scriptblock]::Create(($defs -join "`r`n`r`n")))
        Avisar ("Motor aberto pela AST: {0} funcoes carregadas (arquivo intocado)" -f $defs.Count)

        $exigidas = @("Get-MkvJson","Get-FaixaAudioPrincipal","Get-IndiceAudioNaFaixa",
                      "Get-SinaisAtmosMediaInfo","Test-EhAtmosOuJoc","Test-EhTrueHD","Test-EhDts",
                      "Test-EhCompativelC2","Get-FaixaAtmosJocExistente","Get-FaixaLegendaPtBrTexto",
                      "Find-PtBrPgsTrack","Get-InfoDolbyVision","Get-FaixaLegendaIngles",
                      "Get-FaixaCompativelC2Externa","Test-IdiomaConflitante")
        $faltam = @($exigidas | Where-Object { -not (Get-Command $_ -CommandType Function -ErrorAction SilentlyContinue) })
        if ($faltam.Count -gt 0) {
            Avisar ("FALTARAM funcoes no motor: {0}" -f ($faltam -join ", ")) "ERRO"
            Enviar @{ T = "leitura_fim"; Ok = 0; Erros = 1; Seg = 0 }
            return
        }

        # --- 3. varrer a pasta ---
        $arquivos = @(Get-ChildItem -LiteralPath $PastaOrigem -Filter *.mkv -File -ErrorAction SilentlyContinue | Sort-Object Name)
        Enviar @{ T = "leitura_ini"; Total = $arquivos.Count }
        Avisar ("{0} arquivo(s) .mkv encontrados em {1}" -f $arquivos.Count, $PastaOrigem)
        if ($arquivos.Count -eq 0) {
            # Explicar o vazio: a busca e so no primeiro nivel e so .mkv.
            $subs = @(Get-ChildItem -LiteralPath $PastaOrigem -Directory -ErrorAction SilentlyContinue)
            $mkvFundo = @(Get-ChildItem -LiteralPath $PastaOrigem -Filter *.mkv -File -Recurse -ErrorAction SilentlyContinue)
            $outros = @(Get-ChildItem -LiteralPath $PastaOrigem -File -ErrorAction SilentlyContinue |
                        Where-Object { $_.Extension -match "^\.(mp4|m2ts|ts|avi|mov|mkv3d|webm)$" })
            $motivo = "Nenhum .mkv nesta pasta."
            if ($mkvFundo.Count -gt 0) {
                $motivo = "Nenhum .mkv aqui, mas ha {0} em subpastas ({1} subpasta(s)). A leitura olha so o primeiro nivel." -f $mkvFundo.Count, $subs.Count
            } elseif ($outros.Count -gt 0) {
                $motivo = "Nenhum .mkv, mas ha {0} video(s) de outra extensao ({1}). O conversor so trabalha com .mkv." -f `
                    $outros.Count, (($outros | ForEach-Object { $_.Extension } | Sort-Object -Unique) -join ", ")
            } elseif ($subs.Count -gt 0) {
                $motivo = "Pasta sem videos no primeiro nivel ({0} subpasta(s) dentro)." -f $subs.Count
            }
            Avisar $motivo "AVISO"
            Enviar @{ T = "vazio"; Motivo = $motivo }
        }

        $cron = [System.Diagnostics.Stopwatch]::StartNew()
        $bons = 0; $ruins = 0
        for ($i = 0; $i -lt $arquivos.Count; $i++) {
            if ($Controle.Cancelar) { break }
            $a = $arquivos[$i]
            Enviar @{ T = "leitura_pct"; Idx = $i; Total = $arquivos.Count; Nome = $a.Name }

            # os caches internos do motor sao por arquivo
            $script:CacheMkvJsonPath = $null; $script:CacheMkvJson = $null
            $script:CacheInfoDVPath  = $null; $script:CacheInfoDV  = $null
            $script:CacheSinaisAtmosPath = $null; $script:CacheSinaisAtmos = $null

            $d = @{ Nome = $a.BaseName; Arquivo = $a.Name; Caminho = $a.FullName
                    Bytes = $a.Length; Ignorar = $false; MotivoIgnorar = ""
                    Faixas = @(); DVprecisa = $false; AUprecisa = $false; LGprecisa = $false
                    Modo = "Automatico"
                    # m3c25: dados brutos do audio que sai. Declarados aqui pra
                    # nunca faltarem (arquivo sem audio, erro de leitura), senao
                    # a coluna quebraria em vez de so nao mostrar o detalhe.
                    AudioModo = ""; PrincipalCanais = 0; PrincipalTrueHD = $false
                    DiagDVcor = "cinza"; DiagAucor = "cinza"; DiagLgcor = "cinza"
                    JocCanais = 0; JocBytes = 0 }
            try {
                $json = Get-MkvJson -MkvPath $a.FullName
                if (-not $json) { throw "mkvmerge nao devolveu JSON" }

                $d.DurSeg = 0
                if ($json.container.properties.duration) { $d.DurSeg = [double]$json.container.properties.duration / 1000000000.0 }
                $d.Capitulos = if ($json.chapters) { [int]$json.chapters[0].num_entries } else { 0 }
                $d.Anexos = @($json.attachments).Count
                $d.Titulo = "$($json.container.properties.title)"

                # inventario completo (o que a tabela de faixas vai usar na m3)
                $inv = @()
                foreach ($t in $json.tracks) {
                    $p = $t.properties
                    $marcas = @()
                    if ($p.default_track)         { $marcas += "DEFAULT" }
                    if ($p.forced_track)          { $marcas += "FORCED" }
                    if ($p.flag_original)         { $marcas += "ORIGINAL" }
                    if ($p.flag_commentary)       { $marcas += "COMENTARIO" }
                    if ($p.flag_hearing_impaired) { $marcas += "SDH" }
                    $bytesFaixa = 0
                    if ($p.tag_number_of_bytes) { $bytesFaixa = [double]$p.tag_number_of_bytes }
                    # m3c25: canais vem de graca no mkvmerge (audio_channels). E
                    # o que separa uma JOC 5.1 de uma 7.1 - a diferenca que a
                    # coluna AUDIO escondia ao mostrar so "E-AC-3[ATMOS] OK".
                    $canaisFaixa = 0
                    if ($p.audio_channels) { $canaisFaixa = [int]$p.audio_channels }
                    <#  16.65: O NUMERO DE BLOCOS DA LEGENDA, DE GRACA.
                        num_index_entries e o numero de entradas do indice
                        daquela faixa, e o mkvmerge devolve isso lendo so o
                        cabecalho - nao custa nada nem em 87 GB.
                        Numa faixa de legenda isso E a contagem de falas:
                        SRT da 1 entrada por fala, PGS da 2 (uma para
                        desenhar, uma para apagar). Medido nos arquivos do
                        proprio Diego em 01/09, contra os blocos que sairam
                        no .srt do Reocr:
                            Troia  2757/2 = 1378,5  ->  1378 blocos  (+0,04%)
                            Se7en  3144/2 = 1572    ->  1572 blocos  (exato)
                            Lara   1436/2 =  718    ->   718 blocos  (exato)
                            GoT     892/2 =  446    ->   446 blocos  (exato)
                        Era o numero que faltava para a etapa de legenda
                        deixar de ser estimada por duracao. #>
                    $idxFaixa = 0
                    if ($p.num_index_entries) { $idxFaixa = [int]$p.num_index_entries }
                    $inv += @{ Id = $t.id; Tipo = $t.type; Codec = "$($t.codec)"
                               Lang = "$($p.language)"; Ietf = "$($p.language_ietf)"
                               Nome = "$($p.track_name)"; Marcas = ($marcas -join "|")
                               Bytes = $bytesFaixa; Canais = $canaisFaixa; Relevante = $false
                               IndiceEntradas = $idxFaixa
                               # m3c: PAPEL = o que esta faixa E para o motor
                               # (audio-principal, audio-joc, leg-ptbr, leg-eng,
                               # video, extra). VerboAuto = o que o motor FAZ com
                               # ela (Manter/Converter/Excluir). Os dois sao
                               # preenchidos logo abaixo, depois do diagnostico -
                               # que ja calcula esses papeis, mas ate a m3b os
                               # descartava depois de marcar o Relevante.
                               Papel = "extra"; VerboAuto = "EXCLUIR"; DetalheAuto = ""
                               VerboUsuario = $null }
                }
                # v16.30: fallback para Bytes=0 quando o arquivo nao tem a
                # tag 'number_of_bytes' do mkvmerge (comum em release WEB-DL,
                # que muitas vezes nao remuxa com estatisticas gravadas -
                # ao contrario de remux de Blu-ray, onde a tag quase sempre
                # vem). Sem isso, Get-TamanhoEstimadoVideo somava 0 pro
                # video (que e sempre 100% do total, nunca recodifica) e a
                # estimativa toda zerava - caso real: Desperate Housewives,
                # 'saida estimada ~0,00 GB (original 2,49 GB, delta -2,49 GB)'.
                # A conta: pega o tamanho total do arquivo no disco (que a
                # janela ja tem, $a.Length) e subtrai so as faixas que TEM a
                # tag - o resto (overhead do container incluso) vira a
                # estimativa das faixas SEM tag, jogada inteira na de video
                # (a maior de longe, e a unica que sempre soma 100% do seu
                # Bytes na formula de estimativa - ver Get-TamanhoEstimadoVideo).
                # So entra em acao quando falta a tag; arquivo remuxado como
                # o TLOU (toda faixa com a tag) passa por aqui sem mudar nada.
                $semTag = @($inv | Where-Object { [double]$_.Bytes -eq 0 })
                if ($semTag.Count -gt 0) {
                    $comTagSoma = ((@($inv | Where-Object { [double]$_.Bytes -gt 0 }) | ForEach-Object { [double]$_.Bytes } | Measure-Object -Sum).Sum)
                    if (-not $comTagSoma) { $comTagSoma = 0.0 }
                    $sobra = [double]$a.Length - $comTagSoma
                    $videoSemTag = @($semTag | Where-Object { $_.Tipo -eq "video" })
                    if ($sobra -gt 0 -and $videoSemTag.Count -eq 1) {
                        # caso comum: so o video (ou so o video + faixas
                        # pequenas sem peso real) ficou sem tag - joga a sobra
                        # inteira nele, que e exatamente o que ele vale.
                        $videoSemTag[0].Bytes = $sobra
                    }
                }
                $d.Faixas = $inv

                # ---- DOLBY VISION ----
                $dv = Get-InfoDolbyVision -MkvPath $a.FullName
                if ($dv) {
                    $d.DiagDVrot = "Dolby VISION: $($dv.Nome) [$($dv.Codec)] [$($dv.Camadas)] [DETECTADO]"
                    if ($dv.Perfil -eq 8 -and $dv.Camadas -notmatch "EL") {
                        $d.DiagDVres = "→ [NÃO NECESSÁRIO] Já Está em Profile 8.1"; $d.DiagDVcor = "cinza"
                        # Mesmo formato do outro ramo: so o numero do perfil.
                        # "Profile 8.1 - ok" nao cabia e saia cortado.
                        $d.ColDV = "{0} OK" -f ($dv.Nome -replace '^\s*Profile\s*', '')
                    } else {
                        $d.DiagDVres = "→ [SERÁ CONVERTIDO] Profile 8.1 [dvhe.08.06] [BL+RPU]"; $d.DiagDVcor = "verde"
                        $d.ColDV = "$($dv.Perfil).$($dv.Level) → 8.1"
                        $d.DVprecisa = $true
                    }
                } else {
                    $d.DiagDVrot = "Dolby VISION: NÃO DETECTADO"
                    $d.DiagDVres = "→ [SEM DOLBY VISION] Este Vídeo Será Ignorado"; $d.DiagDVcor = "vermelho"
                    $d.ColDV = "Sem Dolby Vision"
                    $d.Ignorar = $true; $d.MotivoIgnorar = "Sem Dolby Vision"
                }

                # ---- AUDIO ----
                # Zerar por arquivo: $pronta so e atribuida no ramo "tem audio",
                # entao sem isto ela carregaria a faixa JOC do .mkv ANTERIOR
                # quando o atual nao tem audio - o mesmo tipo de vazamento entre
                # arquivos que a regra 3 do projeto proibe (cache do motor).
                $pronta = $null
                $prontaEhJoc = $false
                $pr = Get-FaixaAudioPrincipal -MkvPath $a.FullName
                if (-not $pr) {
                    $d.DiagAurot = "ÁUDIO PRINCIPAL: NENHUM"
                    $d.DiagAures = "→ [SEM ÁUDIO] O Arquivo Não Tem Faixa de Áudio"; $d.DiagAucor = "vermelho"
                    $d.ColAudio = "Sem Áudio"
                } else {
                    $idxA = Get-IndiceAudioNaFaixa -MkvPath $a.FullName -Faixa $pr
                    $sinais = Get-SinaisAtmosMediaInfo -MkvPath $a.FullName
                    $sinal = $null
                    if ($sinais -and $idxA -lt @($sinais).Count) { $sinal = @($sinais)[$idxA] }
                    $ehAtmos = Test-EhAtmosOuJoc -Track $pr -SinalMediaInfo $sinal
                    $rot = "$($pr.codec)"
                    if ($pr.properties.track_name) { $rot = "$($pr.properties.track_name)" }
                    $d.DiagAurot = "ÁUDIO PRINCIPAL: $rot [DETECTADO]"

                    $pronta = Get-FaixaAtmosJocExistente -MkvPath $a.FullName -FaixaExcluir $pr
                    $prontaEhJoc = [bool]$pronta
                    # 16.8: o motor NAO converte um DTS (nem um codec fora da
                    # lista) quando ja existe no arquivo uma faixa E-AC-3/AC-3/
                    # AAC nao-comentario e no MESMO IDIOMA - regra da etapa 4/7,
                    # funcao Get-FaixaCompativelC2Externa. Ate a 16.7 a GUI so
                    # olhava Atmos/JOC aqui, entao ela prometia "SERA CONVERTIDO"
                    # e "EXCLUIR a dublagem" em arquivo Dual Audio onde o motor
                    # nao convertia nada e ainda promovia a dublagem a padrao
                    # (caso Troy 2004). Chamando a MESMA funcao do motor, os dois
                    # lados passam a dizer a mesma coisa por construcao - que e a
                    # regra de ouro do projeto: a GUI nao reimplementa a decisao.
                    if (-not $pronta -and -not (Test-EhTrueHD $pr) -and -not (Test-EhCompativelC2 $pr)) {
                        $pronta = Get-FaixaCompativelC2Externa -MkvPath $a.FullName -FaixaExcluir $pr
                    }
                    # m3c25: guardo aqui os dados BRUTOS que a coluna AUDIO vai
                    # precisar (canais e bytes da faixa que vai sair, e qual
                    # caminho o motor tomou). O TEXTO e montado na thread da
                    # janela, nao aqui: as funcoes de formatacao vivem lá e o
                    # runspace nao as conhece. Separar dado de apresentacao
                    # tambem evita duplicar a mesma logica nos dois lados.
                    $d.PrincipalCanais = if ($pr.properties.audio_channels) { [int]$pr.properties.audio_channels } else { 0 }
                    $d.PrincipalTrueHD = [bool](Test-EhTrueHD $pr)
                    if ($pronta) {
                        $nomeP = if ($pronta.properties.track_name) { $pronta.properties.track_name } else { $pronta.codec }
                        if ($prontaEhJoc) {
                            $d.DiagAures = "→ [REAPROVEITADO] $nomeP"; $d.DiagAucor = "cinza"
                            $d.ColAudio = "E-AC-3[ATMOS] OK"
                            $d.AudioModo = "joc"
                        } else {
                            # 16.8: faixa pronta que NAO e Atmos. Escrever
                            # "E-AC-3[ATMOS]" aqui seria a mesma mentira do resumo
                            # do Troy, onde um AC-3 448k dublado apareceu como
                            # Atmos reaproveitado. O codec vai escrito como ele e.
                            $d.DiagAures = "→ [REAPROVEITADO] $nomeP ($($pronta.codec))"; $d.DiagAucor = "cinza"
                            $d.ColAudio = "{0} OK" -f $pronta.codec
                            $d.AudioModo = "prontaext"
                        }
                        $d.JocCanais = if ($pronta.properties.audio_channels) { [int]$pronta.properties.audio_channels } else { 0 }
                        $d.JocBytes  = if ($pronta.properties.tag_number_of_bytes) { [double]$pronta.properties.tag_number_of_bytes } else { 0 }
                    } elseif (Test-EhTrueHD $pr) {
                        $d.DiagAures = "→ [SERÁ CONVERTIDO] E-AC-3[ATMOS] 1152k (DeeZy)"; $d.DiagAucor = "verde"
                        $d.ColAudio = "TrueHD → E-AC-3[ATMOS]"; $d.AUprecisa = $true
                        $d.AudioModo = "truehd"
                    } elseif (Test-EhDts $pr) {
                        $d.DiagAures = "→ [SERÁ CONVERTIDO] E-AC-3 640k (ffmpeg)"; $d.DiagAucor = "verde"
                        $d.ColAudio = "DTS → E-AC-3"; $d.AUprecisa = $true
                        $d.AudioModo = "dts"
                    } elseif (Test-EhCompativelC2 $pr) {
                        $d.DiagAures = "→ [NÃO NECESSÁRIO] Faixa Já Compatível"; $d.DiagAucor = "cinza"
                        $d.ColAudio = "{0} OK" -f $pr.codec
                        $d.AudioModo = "compativel"
                        $d.JocCanais = $d.PrincipalCanais
                        $d.JocBytes  = if ($pr.properties.tag_number_of_bytes) { [double]$pr.properties.tag_number_of_bytes } else { 0 }
                    } else {
                        $d.DiagAures = "→ [MANTIDO] Modo Seguro, Faixa Preservada"; $d.DiagAucor = "cinza"
                        $d.ColAudio = "{0} OK" -f $pr.codec
                        $d.AudioModo = "seguro"
                    }
                }

                # ---- LEGENDA ----
                $ptTxt = Get-FaixaLegendaPtBrTexto -MkvPath $a.FullName
                $ptPgs = Find-PtBrPgsTrack -MkvPath $a.FullName
                if ($ptTxt) {
                    $n = if ($ptTxt.properties.track_name) { $ptTxt.properties.track_name } else { $ptTxt.codec }
                    $d.DiagLgrot = "LEGENDA PT-BR [.SRT]: '$n' na Faixa $($ptTxt.id) [DETECTADO]"
                    $d.DiagLgres = "→ [REAPROVEITADA] Legenda Padrão do Arquivo Final"; $d.DiagLgcor = "cinza"
                    $d.ColLegenda = "SRT OK"
                } elseif ($ptPgs) {
                    $n = if ($ptPgs.properties.track_name) { $ptPgs.properties.track_name } else { "PGS" }
                    $d.DiagLgrot = "LEGENDA PT-BR [PGS]: '$n' na Faixa $($ptPgs.id) [DETECTADO]"
                    # v16.33: motor tenta seconv/BinaryOCR primeiro (melhor
                    # qualidade), cai pro PgsToSrt sozinho se faltar/falhar -
                    # o texto aqui reflete qual caminho esta CONFIGURADO nesta
                    # maquina, nao uma garantia de qual vai rodar de verdade
                    # (isso so o motor sabe, na hora).
                    <#  v16.51: a linha dizia o MOTOR DE OCR, nao o RESULTADO.
                        Todas as outras linhas do diagnostico anunciam como a
                        faixa vai FICAR no arquivo final ("Profile 8.1",
                        "E-AC-3[ATMOS] 1152k"). So a legenda anunciava a
                        ferramenta interna ("seconv/BinaryOCR"), que e detalhe
                        de implementacao e nao diz nada ao usuario. Agora ela
                        segue o mesmo padrao: o nome da faixa e o formato de
                        saida, com o motor de OCR entre parenteses no fim. #>
                    $nomeSaidaLeg = $n
                    if ($temSeconvJanela) {
                        $d.DiagLgres = "→ [SERÁ CONVERTIDA] $nomeSaidaLeg .SRT (OCR: seconv/BinaryOCR)"; $d.DiagLgcor = "verde"
                    } else {
                        $d.DiagLgres = "→ [SERÁ CONVERTIDA] $nomeSaidaLeg .SRT (OCR: PgsToSrt)"; $d.DiagLgcor = "verde"
                    }
                    $d.ColLegenda = "PGS → SRT"; $d.LGprecisa = $true
                } else {
                    $d.DiagLgrot = "LEGENDA PT-BR: NÃO ENCONTRADA"
                    $d.DiagLgres = "→ [SEM LEGENDA PT-BR] O Arquivo Final Não Terá Legenda em Português"; $d.DiagLgcor = "vermelho"
                    $d.ColLegenda = "Sem Legenda PT-BR"
                }

                # Legenda inglesa que o motor MANTEM no remux final ("+ English").
                # Faltava atribuir: $eng era usado logo abaixo mas nascia $null,
                # entao a faixa inglesa ficava escondida no "...mais N nao usadas".
                $eng = Get-FaixaLegendaIngles -MkvPath $a.FullName

                # ---- m3c: PAPEL e VERBO de cada faixa ----
                # O motor JA decide um dos tres verbos pra cada faixa (regra da
                # etapa [6/7], documentada no COMO_USAR.txt). Ate a m3b a GUI
                # jogava essa informacao fora; aqui ela passa a ser guardada,
                # porque e ela que a aba Faixas mostra e que o modo Manual (m3c-b)
                # vai deixar sobrescrever.
                #
                # Regra do motor, faixa a faixa:
                #   video/capitulos ....... sempre Manter (nunca descartados)
                #   audio principal ....... Converter se precisa (TrueHD->E-AC-3
                #                           Atmos, DTS->E-AC-3); senao Manter.
                #                           A original NUNCA e descartada: o log
                #                           real mostra "TrueHD Atmos 7.1 +
                #                           E-AC-3 Atmos (Novo)".
                #   audio Atmos/JOC pronto  Manter (reaproveitado, vira o padrao)
                #   demais audios ......... Excluir (comentarios, dublagens)
                #   legenda pt-BR texto ... Manter (reaproveitada como padrao)
                #   legenda pt-BR PGS ..... Converter (OCR -> .srt; a PGS
                #                           original sai do arquivo final)
                #   legenda inglesa ....... Manter
                #   demais legendas ....... Excluir (pt-PT, forcada, SDH, outros)
                foreach ($f in $d.Faixas) {
                    $fid = [int]$f.Id
                    if ($f.Tipo -eq "video") {
                        $f.Papel = "video"; $f.VerboAuto = "MANTER"
                        # m3c14: SEM RECODIFICAR agora aparece SEMPRE na faixa
                        # de video. Antes so aparecia quando o Dolby Vision
                        # precisava de conversao, e a ausencia dava a impressao
                        # errada de que nos outros arquivos o video SERIA
                        # recodificado. O video nunca e recodificado, em caso
                        # nenhum - o texto tem que dizer isso sempre.
                        $f.DetalheAuto = "[SEM RECODIFICAR]"
                        continue
                    }
                    if ($f.Tipo -eq "audio") {
                        if ($pr -and $fid -eq [int]$pr.id) {
                            $f.Papel = "audio-principal"
                            if ($d.AUprecisa) {
                                $f.VerboAuto = "CONVERTER"
                                $f.DetalheAuto = "[GERA FAIXA NOVA]"
                            } else {
                                $f.VerboAuto = "MANTER"
                            }
                        } elseif ($pronta -and $fid -eq [int]$pronta.id) {
                            $f.Papel = "audio-joc"; $f.VerboAuto = "MANTER"
                        } else {
                            $f.Papel = "extra"; $f.VerboAuto = "EXCLUIR"
                        }
                        continue
                    }
                    if ($f.Tipo -eq "subtitles") {
                        if ($ptTxt -and $fid -eq [int]$ptTxt.id) {
                            $f.Papel = "leg-ptbr"; $f.VerboAuto = "MANTER"
                        } elseif ($ptPgs -and $fid -eq [int]$ptPgs.id) {
                            $f.Papel = "leg-ptbr"; $f.VerboAuto = "CONVERTER"
                            # v1.5: a tabela mostrava "CONVERTER OCR para .srt".
                            # OCR e a FERRAMENTA, nao o que esta sendo convertido -
                            # o que se converte e a legenda PGS (imagem) em SRT
                            # (texto). Agora le "CONVERTER PGS em .SRT (via OCR)".
                            $f.DetalheAuto = "PGS em .SRT (via OCR)"
                        } elseif ($eng -and $fid -eq [int]$eng.id) {
                            $f.Papel = "leg-eng"; $f.VerboAuto = "MANTER"
                        } else {
                            $f.Papel = "extra"; $f.VerboAuto = "EXCLUIR"
                        }
                        continue
                    }
                    $f.Papel = "extra"; $f.VerboAuto = "EXCLUIR"
                }

                # ---- marcar as faixas que o diagnostico escolheu ----
                # Sao essas que aparecem abertas na tabela; as demais colapsam
                # numa linha so. O usuario e brasileiro e nao se importa com as
                # outras legendas - elas existem para resgate, nao para leitura.
                $idsRelev = New-Object System.Collections.Generic.List[object]
                if ($pr)    { [void]$idsRelev.Add([int]$pr.id) }
                if ($pronta){ [void]$idsRelev.Add([int]$pronta.id) }
                if ($ptTxt) { [void]$idsRelev.Add([int]$ptTxt.id) }
                if ($ptPgs) { [void]$idsRelev.Add([int]$ptPgs.id) }
                if ($eng)   { [void]$idsRelev.Add([int]$eng.id) }
                for ($k = 0; $k -lt $d.Faixas.Count; $k++) {
                    $f = $d.Faixas[$k]
                    # video e audio sempre abertos: sao poucos e sao onde
                    # moram as decisoes que importam
                    if ($f.Tipo -ne "subtitles") { $f.Relevante = $true; continue }
                    if ($idsRelev -contains [int]$f.Id) { $f.Relevante = $true }
                }

                # m3c20: aviso pt-PT sem pt-BR (HANDOFF 7.10, ultimo item da
                # fase). Caso real que ja confundiu o Diego na m3b: alguns
                # releases de serie tem legenda de PORTUGAL e nenhuma pt-BR - o
                # motor recusa (certo, pt-PT nao serve como legenda padrao
                # brasileira), mas a coluna so dizia "Sem Legenda PT-BR", o que
                # parecia defeito do motor em vez de caracteristica do release.
                # Agora diz que EXISTE portugues, so nao o do Brasil. De brinde,
                # a faixa pt-PT passa a aparecer na aba Faixas - sem isso ela
                # ficava escondida no "...mais N nao usadas", justo a faixa que
                # ele procurava pra conferir.
                if ($d.ColLegenda -eq "Sem Legenda PT-BR") {
                    # m3c21: exige pt-PT EXPLICITO (regiao no IETF ou o nome
                    # dizendo Portugal). O match anterior era '^pt' sem 'BR', o
                    # que carimbava como "de Portugal" qualquer faixa gravada
                    # so como "pt" generico - e "pt" generico e justamente o
                    # caso do release brasileiro mal etiquetado.
                    $ptPt = @($d.Faixas | Where-Object {
                        $_.Tipo -eq "subtitles" -and (
                            "$($_.Ietf)" -match '(?i)^pt-PT$' -or "$($_.Nome)" -match '(?i)portugal'
                        )
                    })
                    if ($ptPt.Count -gt 0) {
                        $d.ColLegenda = "Sem PT-BR (só pt-PT)"
                        $d.DiagLgres = "→ [SEM LEGENDA PT-BR] Existe Só Legenda de Portugal (pt-PT)"; $d.DiagLgcor = "vermelho"
                        foreach ($fp in $ptPt) { $fp.Relevante = $true }
                    }
                }

                # ---- ja existe na saida? ----
                if (-not $d.Ignorar -and $PastaSaida -and (Test-Path -LiteralPath $PastaSaida)) {
                    $alvo = Join-Path $PastaSaida $a.Name
                    if (Test-Path -LiteralPath $alvo) {
                        $d.Ignorar = $true; $d.MotivoIgnorar = "Já Existe na Saída"
                    }
                }
                # m3c15: "Nada a Converter" NAO trava mais o video (Ignorar
                # ficava reservado pra "Ja Existe na Saida"/"Erro na Leitura",
                # onde mexer e inutil ou perigoso). Aqui e so um AVISO - o
                # Diego pode discordar do automatico e forcar uma conversao
                # manual mesmo sem trabalho detectado (ex: recodificar audio
                # por preferencia, mesmo o DV ja estando 8.1). So guarda o
                # motivo pra Fill-Fila mostrar o aviso; nao desabilita nada.
                if (-not $d.Ignorar -and -not $d.DVprecisa -and -not $d.AUprecisa -and -not $d.LGprecisa) {
                    $d.MotivoIgnorar = "Nada a Converter"
                }
                $bons++
            } catch {
                $d.Ignorar = $true
                $d.MotivoIgnorar = "Erro na Leitura"
                $d.DiagDVrot = "ERRO"; $d.DiagDVres = "→ [ERRO] $($_.Exception.Message)"; $d.DiagDVcor = "vermelho"
                $d.DiagAurot = ""; $d.DiagAures = ""; $d.DiagLgrot = ""; $d.DiagLgres = ""
                $d.ColDV = "Não Lido"; $d.ColAudio = "Não Lido"; $d.ColLegenda = "Não Lido"
                $ruins++
                Avisar ("Erro lendo {0}: {1}" -f $a.Name, $_.Exception.Message) "ERRO"
            }
            Enviar @{ T = "video"; Dados = $d }
        }
        $cron.Stop()
        Enviar @{ T = "leitura_fim"; Ok = $bons; Erros = $ruins; Seg = ($cron.ElapsedMilliseconds / 1000.0) }
    } catch {
        Enviar @{ T = "log"; Texto = ("ERRO na leitura: {0}" -f $_.Exception.Message); Tipo = "ERRO" }
        Enviar @{ T = "leitura_fim"; Ok = 0; Erros = 1; Seg = 0 }
    }
}

$script:ReleituraPendente = $false

function Start-Leitura {
    if ($script:Lendo) {
        # Nao descartar o pedido: cancela a leitura em curso e reagenda.
        Escrever-Log "Leitura em curso cancelada para reler a pasta nova" "LEITURA"
        $script:ReleituraPendente = $true
        $script:Controle.Cancelar = $true
        return
    }
    Stop-Motor
    $descarte = $null
    while ($script:FilaMsg.TryDequeue([ref]$descarte)) { }
    $script:Lendo = $true
    $script:Videos.Clear()
    $script:LinhasFila.Clear()
    $script:Controle.Cancelar = $false
    $UI.btnIniciar.IsEnabled = $false
    # O botao NAO desabilita durante a leitura: vira "Parar" para o usuario
    # poder abortar um reescaneamento em curso (o clique cai no ramo de parada).
    $UI.btnReler.IsEnabled = $true
    $UI.lblReler.Text = "Parar"
    $Janela.Title = "$NOME_APP  ·  Lendo a Pasta..."

    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "MTA"; $rs.ThreadOptions = "ReuseThread"; $rs.Open()
    $rs.SessionStateProxy.SetVariable("Fila", $script:FilaMsg)
    $rs.SessionStateProxy.SetVariable("Controle", $script:Controle)
    $rs.SessionStateProxy.SetVariable("PastaScript", $script:PastaScript)
    $rs.SessionStateProxy.SetVariable("CaminhoMotor", $script:CaminhoMotor)
    $rs.SessionStateProxy.SetVariable("PastaOrigem", $Cfg.Origem)
    $rs.SessionStateProxy.SetVariable("PastaSaida", $Cfg.Saida)
    $ps = [powershell]::Create(); $ps.Runspace = $rs
    $null = $ps.AddScript($script:TrabalhoLeitura.ToString())
    $script:MotorRunspace = $rs; $script:MotorPS = $ps
    $script:MotorHandle = $ps.BeginInvoke()
    Escrever-Log "Leitura da pasta disparada no runspace" "LEITURA"
}

<#
      --- v16.34: O PESO DE CADA ETAPA, DECIDIDO POR VIDEO ---

      Antes existiam dois vetores de peso fixos e a escolha entre eles olhava
      $v.AUprecisa - o diagnostico AUTOMATICO. Quem marcava "manter audio" na
      mao continuava com o peso de quem converte audio, e a etapa 4 (77% da
      barra) fechava com 0 segundo. Dai a barra saltava e a estimativa errava
      por 3x.

      Agora cada etapa recebe peso ZERO quando ela nao vai rodar neste video,
      e o peso do audio muda conforme o codec de origem, porque TrueHD (DeeZy
      + truehdd) e ~15x mais caro que DTS (ffmpeg). E a decisao respeita a
      ESCOLHA MANUAL, lendo o verbo efetivo de cada faixa - o mesmo caminho
      que o Get-EscolhaDoVideo usa pra montar o que vai pro motor. Se as duas
      fontes discordassem, a barra mediria uma conversao que nao e a que esta
      acontecendo.
#>
<#  16.37: o Reocr so pesa se ele PODE rodar.
    O motor 14.13 exige o tesseract.exe standalone (o tessdata do PgsToSrt e
    biblioteca, nao programa). Sem ele o motor pula a sub-etapa e avisa uma
    vez na lista de ferramentas - entao contar o peso dela seria estimar um
    trabalho que nao vai acontecer.
    O resultado fica em cache: e uma busca em disco, e ela nao muda no meio
    de um lote.
#>
$script:TemReocrCache = $null
function Test-TemReocr {
    if ($null -ne $script:TemReocrCache) { return $script:TemReocrCache }
    $ok = $false
    try {
        $raiz = $script:PastaScript
        if ($raiz -and (Test-Path -LiteralPath (Join-Path $raiz "Reocr_Legenda.ps1"))) {
            # 16.52: mesma correcao do bloco de deteccao das ferramentas -
            # a copia empacotada em tools\Tesseract\ vem PRIMEIRO.
            foreach ($c in @((Join-Path $raiz "tools\Tesseract\tesseract.exe"),
                             (Join-Path $raiz "tools\Tesseract-OCR\tesseract.exe"))) {
                if (Test-Path -LiteralPath $c) { $ok = $true; break }
            }
            if (-not $ok) {
                if (Get-Command "tesseract.exe" -ErrorAction SilentlyContinue) { $ok = $true }
                else {
                    foreach ($c in @("C:\Program Files\Tesseract-OCR\tesseract.exe",
                                     "C:\Program Files (x86)\Tesseract-OCR\tesseract.exe")) {
                        if (Test-Path -LiteralPath $c) { $ok = $true; break }
                    }
                }
            }
        }
    } catch { }
    $script:TemReocrCache = $ok
    return $ok
}

<#  16.63: SEGUNDOS -> PESO.
    A regua inteira do programa fala em "peso", e um peso vale
    ($Gb * $SegPorGbPorPeso) segundos naquele video. Etapa que NAO escala
    com o tamanho do arquivo (legenda, e a parte fixa da remontagem) e
    medida em segundos e convertida aqui - assim ela ocupa o pedaco certo
    da barra sem que o resto do motor de progresso precise mudar.
    $Gb = 0 devolve 0: sem tamanho nao ha conversao possivel, e devolver
    zero e melhor que dividir por zero. #>
function Get-PesoDeSegundos([double]$Seg, [double]$Gb) {
    $umPeso = $Gb * $script:SegPorGbPorPeso
    if ($umPeso -le 0) { return 0 }
    $p = [int][math]::Round($Seg / $umPeso)
    if ($p -lt 1) { $p = 1 }
    return $p
}

<#  16.64: MEDIR O DISCO EM VEZ DE PERGUNTAR QUE DISCO E.
    Le 64 MB de um arquivo real da pasta de origem e devolve MB/s. Nao
    pergunta ao Windows se e SSD ou HD porque a pergunta certa nao e essa:
    e quantos MB/s aquele caminho entrega. Pasta de rede, pen drive, HD
    externo e disco cheio entram todos na mesma conta, sem codigo novo.
    Le a partir de 25% do arquivo (nao do inicio) porque o comeco costuma
    estar no cache do Windows depois do ffprobe do diagnostico, e cache
    faria um HD mecanico parecer um SSD.
    Custa meio segundo, roda uma vez por lote, e qualquer falha devolve a
    velocidade de referencia - ou seja, o comportamento da 16.63. #>
$script:MbPorSegMedido = 0.0
<#  16.74: TRES AMOSTRAS, E VALE A MELHOR.
    Log de 02/09 01h54, Lara Croft: a medida deu 52 MB/s e o fator bateu no
    TETO de 8x. Nas cinco conversoes anteriores, do MESMO disco, a medida
    tinha dado 3.324, 3.072, 2.964, 2.531 e 2.214 MB/s. 52 e um outlier - o
    disco estava ocupado naquele segundo (o Windows tinha acabado de ler a
    pasta duas vezes) e a leitura pegou a fila, nao a velocidade.
    O estrago: previsto 961s contra 515s de relogio, +87%. Uma amostra ruim
    de 64 MB decidiu sozinha a estimativa do arquivo inteiro.
    Agora sao TRES leituras de 24 MB, em 25%, 50% e 75% do arquivo, e vale a
    MAIOR. Disco lento e lento nos tres pontos; contencao momentanea nao pega
    os tres. E as tres vao para o log: se o numero sair estranho de novo, da
    pra ver qual amostra puxou, sem adivinhar. #>
function Measure-VelocidadeOrigem([string]$Arquivo) {
    if ([string]::IsNullOrWhiteSpace($Arquivo)) { return 0.0 }
    $script:AmostrasDisco = @()
    try {
        $fi = New-Object System.IO.FileInfo($Arquivo)
        if (-not $fi.Exists -or $fi.Length -lt 32MB) { return 0.0 }
        $alvo = [long](24MB)
        $buf = New-Object byte[] (4MB)
        $melhor = 0.0
        $fs = [System.IO.File]::Open($Arquivo, 'Open', 'Read', 'ReadWrite')
        try {
            foreach ($fracao in @(0.25, 0.50, 0.75)) {
                $inicio = [long]($fi.Length * $fracao)
                if (($inicio + $alvo) -gt $fi.Length) { continue }
                $fs.Position = $inicio
                $rel = [System.Diagnostics.Stopwatch]::StartNew()
                $lido = 0L
                while ($lido -lt $alvo) {
                    $n = $fs.Read($buf, 0, $buf.Length)
                    if ($n -le 0) { break }
                    $lido += $n
                }
                $rel.Stop()
                if ($rel.Elapsed.TotalSeconds -le 0.001 -or $lido -le 0) { continue }
                $mbs = ($lido / 1MB) / $rel.Elapsed.TotalSeconds
                $script:AmostrasDisco += $mbs
                if ($mbs -gt $melhor) { $melhor = $mbs }
            }
        } finally { $fs.Dispose() }
        return $melhor
    } catch { return 0.0 }
}
function Get-FatorDisco {
    <#  Fator preso entre 1 e 8 - ver o comentario do $script:MbPorSegReferencia. #>
    $v = [double]$script:MbPorSegMedido
    if ($v -le 1) { return 1.0 }
    $f = $script:MbPorSegReferencia / $v
    if ($f -lt 1.0) { return 1.0 }
    if ($f -gt 8.0) { return 8.0 }
    return $f
}

<#  16.64: O QUE VAI RODAR NESTE VIDEO.
    Saiu de dentro de Get-PesosDoVideo para poder ser usado tambem por quem
    so quer saber "esta etapa roda?" sem calcular peso nenhum. #>
<#  16.65: QUANTOS BLOCOS A LEGENDA TEM, ANTES DE CONVERTER.
    O mkvmerge devolve num_index_entries por faixa lendo so o cabecalho. Numa
    faixa de legenda isso e a contagem de eventos: SRT grava um por fala, PGS
    grava dois (desenhar e apagar). Conferido nos arquivos do Diego contra os
    blocos que sairam no .srt: Troia, Se7en, Lara e GoT bateram, o pior com
    0,04% de diferenca.
    Devolve 0 quando nao da para saber - e ai quem estima e a duracao, como
    na 16.64. Melhor cair no plano B do que inventar numero. #>
function Get-BlocosDaLegenda($v) {
    $lp = @(@($v.Faixas) | Where-Object { "$($_.Papel)" -eq "leg-ptbr" }) | Select-Object -First 1
    if (-not $lp) { return 0 }
    $idx = 0
    if ($lp.IndiceEntradas) { $idx = [int]$lp.IndiceEntradas }
    if ($idx -le 0) { return 0 }
    $cod = "$($lp.Codec)"
    $blocos = $idx
    if ($cod -match "(?i)PGS|HDMV") { $blocos = [int][math]::Round($idx / 2.0) }
    <#  Trava de sanidade: legenda de filme fica entre umas poucas dezenas e
        alguns milhares de falas. Fora disso o numero nao e o que eu penso
        que e - pode ser um container esquisito, uma faixa de imagem que nao
        e legenda, ou um formato que conta de outro jeito. Nesse caso volto
        para a duracao em vez de entregar uma estimativa absurda. #>
    if ($blocos -lt 20 -or $blocos -gt 20000) { return 0 }
    return $blocos
}

<#  16.66: NOME TROCADO DEPOIS DE UM DEFEITO CARO.
    Esta funcao nasceu na 16.64 chamada Get-PlanoDoVideo - e JA EXISTIA outra
    com esse nome (a que devolve os indices das etapas do plano, mais
    abaixo). Em PowerShell a ultima definicao vence, entao a minha era
    substituida em silencio: "Get-PlanoDoVideo $v" caia na outra, que ignora
    o parametro e devolve um ARRAY. E $pl.Dovi num array e $null - ou seja,
    false. Todas as tres perguntas viravam "nao vai rodar".
    Resultado no Troia de 01/09: etapas 2, 3 e 4 com peso ZERO e a conversao
    inteira estimada em 248s (4 min) contra 23m05s reais - erro de -82%. O
    log dizia, uma linha por etapa:
        "PLANO: a etapa 2/5 rodou apesar de o diagnostico da tela ter dado
         peso zero - peso tipico (221) entrou no lugar"
    Duas licoes viraram teste: nome unico aqui, e a bateria agora reprova
    QUALQUER funcao definida duas vezes neste arquivo - que e a classe do
    defeito, nao este caso. #>
function Get-TrabalhoDoVideo($v) {
    $vaiDovi    = [bool]$v.DVprecisa
    $vaiAudio   = [bool]$v.AUprecisa
    $vaiLegenda = [bool]$v.LGprecisa

    # a escolha manual manda mais que o diagnostico
    if ("$($v.Modo)" -eq "Manual") {
        $achouLegendaConverter = $false
        foreach ($f in @($v.Faixas)) {
            if (Test-VerboBloqueado $f) { continue }
            $vb = Get-VerboEfetivo $v $f
            if ($f.Tipo -eq "audio" -and $f.Papel -eq "audio-principal") {
                if ($vb -eq "CONVERTER") { $vaiAudio = $true } else { $vaiAudio = $false }
            } elseif ($f.Tipo -eq "subtitles") {
                if ($vb -eq "CONVERTER") { $achouLegendaConverter = $true }
            }
        }
        # em Manual, legenda so converte se alguem estiver marcada pra isso
        $temLegendaTocada = @(@($v.Faixas) | Where-Object {
            $_.Tipo -eq "subtitles" -and $null -ne $_.VerboUsuario -and -not (Test-VerboBloqueado $_) }).Count -gt 0
        if ($temLegendaTocada) { $vaiLegenda = $achouLegendaConverter }
    }
    return @{ Dovi = $vaiDovi; Audio = $vaiAudio; Legenda = $vaiLegenda
              ModoAudio = "$($v.AudioModo)" }
}

<#  16.64: A ESTIMATIVA AGORA E FEITA EM SEGUNDOS, ETAPA POR ETAPA.
    Cada etapa segue a grandeza que ela realmente segue (GB, minutos de
    filme ou blocos de legenda) - ver a medicao no bloco $script:TempoEtapa.
    Devolve os CINCO tempos, na ordem das cinco etapas de trabalho. Peso
    zero continua significando "esta etapa nao roda neste arquivo", e e o
    que tira a etapa do plano e da regua. #>
function Get-SegundosDasEtapas($v, [double]$Gb, [double]$Min) {
    $T = $script:TempoEtapa
    $pl = Get-TrabalhoDoVideo $v
    if ($Min -le 0) { $Min = 0 }

    <#  [1] extrair o video so acontece quando o dovi_tool vai mexer nele.
        O diagnostico (ffprobe) roda logo antes e entra somado aqui - ele nao
        e etapa, mas o relogio do usuario nao sabe disso.
        16.64b: o diagnostico estava DENTRO do if do dovi, ou seja, sumia da
        conta em todo arquivo que ja chega em Profile 8.1. Achado no log do
        Devil Wears Prada de 28/08: o ffprobe rodou (4s de trabalho, 15s de
        parede porque teve 11s de pausa) num arquivo em que a etapa 1 nem
        existiu. Ele roda SEMPRE - agora conta sempre. #>
    $s1 = $T.DiagnosticoSeg
    if ($pl.Dovi) { $s1 += ($Gb * $T.ExtracaoSegPorGb * (Get-FatorDaEtapa "Extracao")) }

    # [2] dovi_tool le e reescreve o video extraido - tambem e disco.
    $s2 = 0.0
    if ($pl.Dovi) { $s2 = $Gb * $T.DoviSegPorGb * (Get-FatorDaEtapa "Dovi") }

    # [3] audio e CPU, e se mede em MINUTOS DE FILME. O disco quase nao entra
    # aqui - medido 1,2x no HD contra 6,5x da extracao - e a sensibilidade de
    # 0,04 e exatamente isso.
    $s3 = 0.0
    if ($pl.Audio) {
        $porMin = if ($pl.ModoAudio -eq "truehd") { $T.AudioTrueHDSegPorMin } else { $T.AudioOutroSegPorMin }
        $s3 = $Min * $porMin * (Get-FatorDaEtapa "Audio")
    }

    # [4] legenda: OCR bloco a bloco. Sem o Reocr (tesseract ausente) some a
    # fatia dele, medida em 56% da etapa.
    $s4 = 0.0
    if ($pl.Legenda) {
        <#  16.65: com o numero de blocos em maos a conta e direta. Sem ele
            (faixa sem indice, container esquisito) cai na duracao, que era
            o unico caminho ate a 16.64 - e a parte mais fraca do modelo. #>
        $blocos = Get-BlocosDaLegenda $v
        if ($blocos -gt 0) { $s4 = $blocos * $T.LegendaSegPorBloco }
        else               { $s4 = $Min * $T.LegendaSegPorMin }
        if (-not (Test-TemReocr)) { $s4 = $s4 * (1.0 - $T.LegendaFracaoReocr) }
        $s4 = $s4 * (Get-FatorDaEtapa "Legenda")
    }

    # [5] remontagem: dois precos. Com video extraido ela remonta de pedacos
    # soltos e ainda apaga dezenas de GB de temporario; sem extracao, remuxa
    # direto do original e nao ha temporario nenhum.
    $porGb = if ($pl.Dovi) { $T.RemontagemSegPorGb } else { $T.RemontagemDiretoSegPorGb }
    $s5 = ($T.RemontagemSegFixo + $Gb * $porGb) * (Get-FatorDaEtapa "Remontagem")

    return ,@($s1, $s2, $s3, $s4, $s5)
}

function Get-PesosDoVideo($v, [double]$Gb = 0, [double]$Min = 0) {
    <#  16.64: os pesos passaram a ser DERIVADOS dos segundos. A regua, a
        barra e o tempo restante continuam falando em peso e nao mudaram
        uma linha - so a conta que produz o peso mudou. #>
    $segs = Get-SegundosDasEtapas $v $Gb $Min
    $pesos = @()
    foreach ($sg in $segs) {
        if ([double]$sg -le 0) { $pesos += 0; continue }
        $pesos += (Get-PesoDeSegundos ([double]$sg) $Gb)
    }
    return ,$pesos
}

# Monta o lote na ORDEM da fila, com o peso das etapas de cada video.
# O peso muda conforme o diagnostico que a tela ja fez: quando o audio vai ser
# convertido pelo DeeZy, a etapa 4 sozinha e 77% do tempo; quando o motor
# reaproveita uma faixa Atmos/JOC que ja existe, ela e quase zero.
function Set-LoteParaConverter {
    $lote = @()
    $marcados = @(Get-Marcados)
    <#  16.64: mede a velocidade do disco de origem UMA vez por lote, no
        primeiro arquivo marcado. Todos os videos de um lote vem da mesma
        pasta, entao medir de novo em cada um seria pagar o mesmo pedagio
        oito vezes seguidas por um numero que nao muda. #>
    $script:MbPorSegMedido = 0.0
    if ($marcados.Count -gt 0) {
        $script:MbPorSegMedido = Measure-VelocidadeOrigem $marcados[0].Caminho
        if ($script:MbPorSegMedido -gt 0) {
            $txtAm = ""
            if (@($script:AmostrasDisco).Count -gt 0) {
                $txtAm = " | amostras: " + ((@($script:AmostrasDisco) | ForEach-Object { "{0:N0}" -f $_ }) -join ", ")
            }
            Escrever-Log ("DISCO: origem le a {0:N0} MB/s (referencia {1:N0}) -> fator {2:N2}x nas etapas de disco{3}" -f `
                          $script:MbPorSegMedido, $script:MbPorSegReferencia, (Get-FatorDisco), $txtAm) "PROVA"
        } else {
            Escrever-Log "DISCO: nao consegui medir a velocidade da origem - estimando como se fosse o disco de referencia" "AVISO"
        }
    }
    foreach ($v in $marcados) {
        $gb = [double]$v.Bytes / 1GB
        $min = 0.0
        if ($v.DurSeg) { $min = [double]$v.DurSeg / 60.0 }
        $segs  = Get-SegundosDasEtapas $v $gb $min
        $pesos = Get-PesosDoVideo $v $gb $min
        $soma  = 0.0
        foreach ($p in $pesos) { $soma += [double]$p }
        $est = $gb * $soma * $script:SegPorGbPorPeso
        if ($est -lt 30) { $est = 30 }
        <#  16.64: o tamanho da faixa PGS e a duracao vao para o log de
            proposito. Sao os dois numeros que faltam para trocar a
            estimativa da legenda (hoje por duracao, a etapa mais fraca do
            modelo) por uma por TAMANHO DA PGS, que deve prever o numero de
            blocos muito melhor. Sem gravar agora, a proxima rodada comeca
            sem dado de novo. #>
        <#  16.64b: a linha dizia "PGS pt-BR" para QUALQUER faixa pt-BR. No
            Devil Wears Prada, que ja vem com legenda .SRT, ela imprimiu
            "PGS pt-BR 0,06 MB" - e 0,06 MB e o tamanho do SRT, nao de PGS
            nenhum. Numero certo com nome errado e a mesma familia de
            mensagem que mente que a gente vem cacando: quando eu for
            calibrar a legenda com estes logs, misturar SRT com PGS
            estragaria a conta inteira. Agora imprime o codec que achou. #>
        $lp = @(@($v.Faixas) | Where-Object { "$($_.Papel)" -eq "leg-ptbr" }) | Select-Object -First 1
        $legMb = 0.0
        $legCod = "nenhuma"
        if ($lp) {
            if ($lp.Bytes) { $legMb = [double]$lp.Bytes / 1MB }
            $legCod = "$($lp.Codec)"
            if ([string]::IsNullOrWhiteSpace($legCod)) { $legCod = "?" }
        }
        $blocosLeg = Get-BlocosDaLegenda $v
        $txtBl = "por duracao"
        if ($blocosLeg -gt 0) { $txtBl = ("{0} blocos" -f $blocosLeg) }
        Escrever-Log ("MEDIDA: '{0}' | {1:N2} GB | {2:N1} min | legenda pt-BR [{3}] {4:N2} MB, {5} | previsto {6:N0}s" -f `
                      $v.Nome, $gb, $min, $legCod, $legMb, $txtBl, $est) "PROVA"
        <#  16.68: os SEGUNDOS previstos de cada etapa viajam junto com os
            pesos. O peso e um numero de regua (largura na barra); o segundo
            e o que a tela precisa para saber se a etapa esta atrasada. Ate
            a 16.67 a tela so tinha o peso e era obrigada a acreditar no %
            que a FERRAMENTA reportava - e o deezy reporta um % que nao anda
            junto com o relogio (20% em 3 min de 27, 82% em 17 min de 27). #>
        $lote += @{ Caminho = $v.Caminho; Nome = $v.Nome; Pesos = $pesos; SegEstimado = $est
                    SegEtapas = @($segs) }
    }
    # Sem return: a atribuicao direta nao passa pelo pipeline, entao nao ha
    # desmonte (o problema da 16.3) nem aninhamento (o problema da 16.4).
    $script:LoteAtual = $lote
}

function Start-Motor {
    Stop-Motor
    $descarte = $null
    while ($script:FilaMsg.TryDequeue([ref]$descarte)) { }   # limpa sobras de rodada anterior
    $script:Controle.Pausar = $false
    $script:Controle.Cancelar = $false
    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "MTA"          # o motor nao usa WPF, nao precisa de STA
    $rs.ThreadOptions = "ReuseThread"
    $rs.Open()
    $rs.SessionStateProxy.SetVariable("Fila", $script:FilaMsg)
    $rs.SessionStateProxy.SetVariable("Controle", $script:Controle)
    $rs.SessionStateProxy.SetVariable("CaminhoMotor", $script:CaminhoMotor)
    $rs.SessionStateProxy.SetVariable("Raiz", $script:PastaScript)
    $rs.SessionStateProxy.SetVariable("SaidaDir", $Cfg.Saida)
    # O MESMO lote que a janela guardou - nao uma segunda chamada da funcao.
    # Assim a conta da fila na tela e a conta do motor nao podem divergir.
    $rs.SessionStateProxy.SetVariable("Lote", $script:LoteAtual)
    # 16.11: as escolhas do modo Manual. Vao como DADO, nao como logica - a
    # janela nao decide nada aqui, so entrega ao motor a lista de ids que o
    # usuario montou na aba Faixas. Quando nao ha nenhum video em Manual isto
    # e $null, e o motor se comporta exatamente como sempre.
    # 16.15: SetVariable continua aqui como reserva, mas quem manda de
    # verdade e o AddArgument logo abaixo - ver o param() do TrabalhoMotor.
    $rs.SessionStateProxy.SetVariable("EscolhasDaJanela", $script:EscolhasAtuais)
    $ps = [powershell]::Create()
    $ps.Runspace = $rs
    $null = $ps.AddScript($script:TrabalhoMotor.ToString())
    # Liga o valor ao param($EscolhasDaJanela) do bloco. Se nao houver escolha
    # nenhuma, vai $null - que e exatamente o modo automatico.
    $null = $ps.AddArgument($script:EscolhasAtuais)
    $qtd = 0
    if ($script:EscolhasAtuais) { $qtd = @($script:EscolhasAtuais.Keys).Count }
    Escrever-Log ("ESCOLHAS enviadas ao runspace por parametro: {0} arquivo(s)" -f $qtd) "PROVA"
    $script:MotorRunspace = $rs
    $script:MotorPS = $ps
    $script:MotorHandle = $ps.BeginInvoke()
    Escrever-Log "Runspace do motor criado e disparado" "MOTOR"
}

function Stop-Motor {
    if (-not $script:MotorPS) { return }
    $script:Controle.Cancelar = $true
    $script:Controle.Pausar = $false
    try { if ($script:MotorHandle -and -not $script:MotorHandle.IsCompleted) { $null = $script:MotorHandle.AsyncWaitHandle.WaitOne(1500) } } catch { }
    try { $script:MotorPS.Stop() } catch { }
    try { $script:MotorPS.Dispose() } catch { }
    try { $script:MotorRunspace.Close() } catch { }
    try { $script:MotorRunspace.Dispose() } catch { }
    $script:MotorPS = $null; $script:MotorRunspace = $null; $script:MotorHandle = $null
    Escrever-Log "Runspace do motor encerrado e descartado" "MOTOR"
}

# ============================================================================
#  XAML - a janela inteira. Controles de estado recebem x:Name e sao
#  encontrados no code-behind. Nenhum evento e declarado aqui (regra do
#  XamlReader): tudo e conectado por codigo mais abaixo.
# ============================================================================
$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$NOME_APP"
        Width="1280" MinWidth="1080" Height="760" MinHeight="700"
        Background="$($Cores.fundo)" WindowStartupLocation="CenterScreen"
        UseLayoutRounding="True" TextOptions.TextFormattingMode="Display">
  <Window.Resources>
    <BooleanToVisibilityConverter x:Key="BoolParaVisibilidade"/>

    <SolidColorBrush x:Key="CorTxt"   Color="$($Cores.txt)"/>
    <SolidColorBrush x:Key="CorFoco"  Color="$($Cores.foco)"/>
    <SolidColorBrush x:Key="CorOk"    Color="$($Cores.ok)"/>
    <SolidColorBrush x:Key="CorOkDim" Color="$($Cores.okdim)"/>
    <SolidColorBrush x:Key="CorSrc"   Color="$($Cores.src)"/>
    <SolidColorBrush x:Key="CorWarn"  Color="$($Cores.warn)"/>
    <SolidColorBrush x:Key="CorErr"   Color="$($Cores.err)"/>
    <SolidColorBrush x:Key="CorDim"   Color="$($Cores.dim)"/>
    <SolidColorBrush x:Key="CorDim2"  Color="$($Cores.dim2)"/>
    <SolidColorBrush x:Key="CorMarca" Color="$($Cores.marca)"/>
    <SolidColorBrush x:Key="CorEmCurso" Color="$($Cores.emCurso)"/>

    <Style x:Key="BtnBarra" TargetType="Button">
      <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="{StaticResource CorTxt}"/>
      <Setter Property="BorderBrush" Value="Transparent"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="13,6"/>
      <Setter Property="Margin" Value="1,0"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}"
                    CornerRadius="7" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#23232B"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Foreground" Value="$($Cores.vazio)"/>
                <Setter TargetName="bd" Property="Background" Value="Transparent"/>
                <Setter TargetName="bd" Property="BorderBrush" Value="Transparent"/>
              </Trigger>
              <Trigger Property="IsKeyboardFocused" Value="True">
                <Setter TargetName="bd" Property="BorderBrush" Value="#6A5A80"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="BtnAcao" TargetType="Button" BasedOn="{StaticResource BtnBarra}">
      <Setter Property="Background" Value="#1A1A20"/>
      <Setter Property="BorderBrush" Value="$($Cores.borda2)"/>
      <Setter Property="Foreground" Value="{StaticResource CorFoco}"/>
      <Setter Property="Padding" Value="12,6"/>
    </Style>

    <!-- m3c-c: dropdown "estilo Excel" da coluna ACAO. So cores/bordas por
         cima do template NATIVO do ComboBox - de proposito: um template
         customizado do zero teria que reimplementar fechar ao clicar fora,
         navegacao por teclado, etc., e nao da pra testar isso aqui (sem
         Windows/WPF no ambiente). O nativo ja faz tudo isso de graca. -->
    <Style x:Key="ComboVerbo" TargetType="ComboBox">
      <Setter Property="Background" Value="#1A1A20"/>
      <Setter Property="BorderBrush" Value="$($Cores.borda2)"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="6,2"/>
      <Setter Property="Cursor" Value="Hand"/>
      <!-- Legibilidade: o template NATIVO do ComboBox as vezes nao respeita
           o Foreground/Background pedido no texto da caixa FECHADA (so
           respeita nos itens da lista ABERTA) - efeito colateral do tema
           padrao do Windows, nao um erro de binding. Corrigido desenhando o
           texto com um ItemTemplate proprio: o WPF usa o MESMO ItemTemplate
           tanto pra desenhar cada item da lista quanto o valor selecionado
           na caixa fechada, entao a cor fica garantida nos dois estados. -->
      <Setter Property="ItemTemplate">
        <Setter.Value>
          <DataTemplate>
            <TextBlock Text="{Binding}" FontFamily="Consolas" FontSize="13"
                       Padding="2,0">
              <TextBlock.Style>
                <Style TargetType="TextBlock">
                  <Setter Property="Foreground" Value="$($Cores.foco)"/>
                  <Setter Property="Background" Value="#1A1A20"/>
                  <Style.Triggers>
                    <!-- m3c8: "MANTER" ganhou um DataTrigger proprio (antes so
                         tinha o Setter base acima). Suspeita forte do bug real:
                         a caixa FECHADA do ComboBox saia errada so pra Manter,
                         nunca pra Converter/Excluir - e esses dois sao
                         justamente os unicos com DataTrigger. Trigger tem
                         precedencia maior que Setter simples no WPF; deixar
                         os 3 verbos simetricos (todos via trigger) elimina
                         essa diferenca de mecanismo em vez de so suspeitar
                         dela. TESTAR DE NOVO na maquina real.
                         m3c9: o Setter base ja tentava por Foreground E
                         Background - mesmo assim continuou branco. Agora o
                         Background tambem esta dentro de CADA DataTrigger (nao
                         so no Setter base), pra descartar de vez a hipotese
                         de precedencia entre Setter/Trigger. Se persistir
                         depois disso, o problema nao esta na cor do TextBlock
                         e sim no CHROME do ComboBox por baixo dele (a
                         proxima tentativa teria que reescrever o
                         ControlTemplate inteiro, e ai sim precisa de Windows
                         pra validar fechar-ao-clicar-fora). -->
                    <DataTrigger Binding="{Binding}" Value="MANTER">
                      <Setter Property="Foreground" Value="$($Cores.foco)"/>
                      <Setter Property="Background" Value="#1A1A20"/>
                    </DataTrigger>
                    <DataTrigger Binding="{Binding}" Value="CONVERTER">
                      <Setter Property="Foreground" Value="$($Cores.ok)"/>
                      <Setter Property="Background" Value="#1A1A20"/>
                      <Setter Property="FontWeight" Value="SemiBold"/>
                    </DataTrigger>
                    <DataTrigger Binding="{Binding}" Value="EXCLUIR">
                      <Setter Property="Foreground" Value="$($Cores.err)"/>
                      <Setter Property="Background" Value="#1A1A20"/>
                    </DataTrigger>
                  </Style.Triggers>
                </Style>
              </TextBlock.Style>
            </TextBlock>
          </DataTemplate>
        </Setter.Value>
      </Setter>
      <Setter Property="ItemContainerStyle">
        <Setter.Value>
          <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="$($Cores.painel2)"/>
            <Setter Property="Padding" Value="10,4"/>
          </Style>
        </Setter.Value>
      </Setter>
      <Style.Triggers>
        <Trigger Property="IsEnabled" Value="False">
          <!-- Automatico ou faixa travada: sem fundo/borda, parece texto
               simples (era assim antes do dropdown existir). -->
          <Setter Property="Background" Value="Transparent"/>
          <Setter Property="BorderBrush" Value="Transparent"/>
          <Setter Property="Cursor" Value="Arrow"/>
        </Trigger>
      </Style.Triggers>
    </Style>


    <Style x:Key="Cabecalho" TargetType="TextBlock">
      <Setter Property="Foreground" Value="{StaticResource CorMarca}"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Margin" Value="0,0,0,7"/>
    </Style>

    <Style x:Key="Mono" TargetType="TextBlock">
      <Setter Property="FontFamily" Value="Consolas"/>
      <Setter Property="FontSize" Value="14.5"/>
      <Setter Property="Foreground" Value="{StaticResource CorTxt}"/>
    </Style>

    <Style TargetType="GridViewColumnHeader">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="{StaticResource CorMarca}"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="HorizontalContentAlignment" Value="Left"/>
      <Setter Property="Padding" Value="6,7"/>
      <Setter Property="BorderBrush" Value="$($Cores.borda)"/>
      <Setter Property="BorderThickness" Value="0,0,0,1"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="GridViewColumnHeader">
            <Grid>
              <Border Background="{TemplateBinding Background}"
                      BorderBrush="{TemplateBinding BorderBrush}"
                      BorderThickness="{TemplateBinding BorderThickness}"
                      Padding="{TemplateBinding Padding}">
                <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center"/>
              </Border>
              <Thumb x:Name="PART_HeaderGripper" HorizontalAlignment="Right" Width="10" Cursor="SizeWE">
                <Thumb.Template>
                  <ControlTemplate TargetType="Thumb"><Border Background="Transparent" Width="10"><Border Width="1" HorizontalAlignment="Right" Background="$($Cores.dim2)"/></Border></ControlTemplate>
                </Thumb.Template>
              </Thumb>
            </Grid>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style TargetType="ListViewItem">
      <!-- 16.20: essa linha ja existia (fio embaixo de cada LINHA), mas na
           cor $Cores.trilho (#1B1B22) - quase igual ao fundo, por isso
           nunca dava pra ver. So existia fio entre COLUNAS (16.18); sem fio
           entre LINHAS, o olho nao conseguia prender qual texto pertencia a
           qual linha - exatamente o que o Diego teve que resolver desenhando
           a mao. Agora usa o MESMO tom do fio das colunas: as duas direcoes
           fecham uma grade de verdade, tipo tabela do Word. -->
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="BorderBrush" Value="#2A2A33"/>
      <Setter Property="BorderThickness" Value="0,0,0,1"/>
      <Setter Property="Padding" Value="0,3"/>
      <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
      <!-- 16.22: SEM isto o GridViewRowPresenter dimensiona cada celula
           no tamanho do CONTEUDO, nao da COLUNA. Em coluna de texto nao
           se ve (texto encostado a esquerda parece alinhado); nas 3
           colunas coloridas (DOLBY VISION/AUDIO/LEGENDA) o fundo tintado
           encolhia junto e parava ANTES da linha de grade, deixando um
           vao escuro - era o "mal sincronizado" que o Diego apontou. Com
           Stretch a celula preenche a largura da coluna: o fundo vai ate
           o fio e a grade fecha. Texto continua a esquerda (default do
           TextBlock) e o checkbox continua centralizado (HA=Center
           proprio) - nada mais se desloca. -->
      <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ListViewItem">
            <Border x:Name="bd" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}"
                    Padding="{TemplateBinding Padding}">
              <GridViewRowPresenter Columns="{Binding Path=View.Columns, RelativeSource={RelativeSource AncestorType=ListView}}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#1C1C24"/>
              </Trigger>
              <Trigger Property="IsSelected" Value="True">
                <Setter TargetName="bd" Property="Background" Value="$($Cores.selRoxo)"/>
                <Setter TargetName="bd" Property="BorderBrush" Value="$($Cores.marca)"/>
                <Setter TargetName="bd" Property="BorderThickness" Value="2,0,0,1"/>
              </Trigger>
              <MultiTrigger>
                <MultiTrigger.Conditions>
                  <Condition Property="IsSelected" Value="True"/>
                  <Condition Property="IsMouseOver" Value="True"/>
                </MultiTrigger.Conditions>
                <Setter TargetName="bd" Property="Background" Value="#332246"/>
              </MultiTrigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

  </Window.Resources>

  <DockPanel LastChildFill="True">
    <!-- Nota: o miolo NAO fica dentro de ScrollViewer de proposito - isso
         anularia a linha estrela que faz a fila esticar. A protecao contra
         janela pequena e o par MinHeight (janela) + MinHeight (caixa da
         fila), calculados para o pior caso. -->

    <!-- BARRA DE FERRAMENTAS -->
    <Border DockPanel.Dock="Top" Background="$($Cores.painel2)" BorderBrush="$($Cores.borda)" BorderThickness="0,0,0,1" Padding="9,7">
      <DockPanel LastChildFill="False">
        <Button x:Name="btnIniciar" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock x:Name="icoIniciar" Text="$($Sim.Atual)" FontSize="17.5" HorizontalAlignment="Center"/><TextBlock Text="Iniciar F1" Margin="0,2,0,0"/></StackPanel>
        </Button>
        <Button x:Name="btnPausar" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock x:Name="icoPausar" Text="$($Sim.Pausa)" FontSize="15.5" HorizontalAlignment="Center"/><TextBlock x:Name="lblPausar" Text="Pausar F2" Margin="0,3,0,0"/></StackPanel>
        </Button>
        <Button x:Name="btnCancelar" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock Text="$($Sim.Err)" FontSize="15.5" HorizontalAlignment="Center"/><TextBlock Text="Cancelar ESC" Margin="0,3,0,0"/></StackPanel>
        </Button>
        <Border Width="1" Background="$($Cores.borda)" Margin="7,2"/>
        <!-- 16.45: era o botao que recolhia o bloco PASTAS - trabalho que o
             clique no proprio cabecalho ja fazia, e que some sozinho no F1.
             Um botao na barra principal para uma acao duplicada e opcional.
             Agora ele e o par do "Abrir Saída": abre a pasta de ORIGEM. -->
        <Button x:Name="btnAbrirOrigem" Focusable="False" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock Text="$($Sim.Pasta)" FontSize="16.5" HorizontalAlignment="Center"/><TextBlock Text="Abrir Origem" Margin="0,2,0,0"/></StackPanel>
        </Button>
        <Button x:Name="btnReler" Focusable="False" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock Text="&#8635;" FontSize="16.5" HorizontalAlignment="Center"/><TextBlock x:Name="lblReler" Text="Atualizar" Margin="0,2,0,0"/></StackPanel>
        </Button>
        <Button x:Name="btnAbrirSaida" Focusable="False" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock Text="$($Sim.Disco)" FontSize="16.5" HorizontalAlignment="Center"/><TextBlock Text="Abrir Saída" Margin="0,2,0,0"/></StackPanel>
        </Button>
        <Button x:Name="btnFerramentas" Focusable="False" DockPanel.Dock="Right" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock Text="&#9881;" FontSize="16.5" HorizontalAlignment="Center"/><TextBlock Text="Ferramentas" Margin="0,2,0,0"/></StackPanel>
        </Button>
        <Button x:Name="btnLog" Focusable="False" DockPanel.Dock="Right" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock Text="&#9776;" FontSize="16.5" HorizontalAlignment="Center"/><TextBlock Text="Log" Margin="0,2,0,0"/></StackPanel>
        </Button>
      </DockPanel>
    </Border>

    <!-- RODAPE DE PROGRESSO (fixo embaixo; visivel so durante conversao) -->
    <Border x:Name="painelProgresso" DockPanel.Dock="Bottom" Background="$($Cores.painel)" BorderBrush="$($Cores.borda)" BorderThickness="0,1,0,0" Visibility="Collapsed">
      <StackPanel>
        <!--  16.45: TRES NIVEIS, TRES DESENHOS DIFERENTES.
              Ate a 16.44 os tres blocos do rodape usavam o mesmo vocabulario
              (rotulo violeta + "n/N" violeta) e so um deles tinha barra. Quem
              olhava de longe via tres linhas iguais e nao sabia qual respondia
              "quanto falta pra ESTE video" e qual respondia "quanto falta pra
              TUDO". Agora cada pergunta tem uma forma propria:
                ETAPA -> barra GROSSA (13px) + numero grande. O que esta
                         acontecendo neste segundo.
                VIDEO -> REGUA segmentada + % proprio. O caminho do arquivo
                         inteiro, com as etapas dele desenhadas.
                FILA  -> barra FINA (5px), sem cantos, apagada + % proprio.
                         E o pano de fundo da operacao, nao o assunto.
              Barra grossa/media/fina em ordem = do agora para o total, e da
              pra ler a hierarquia sem ler uma palavra. -->
        <Border Padding="14,9" BorderBrush="$($Cores.trilho)" BorderThickness="0,0,0,1">
          <StackPanel>
            <DockPanel Margin="0,0,0,7">
              <TextBlock Text="ETAPA " Foreground="{StaticResource CorMarca}" FontSize="12"/>
              <TextBlock x:Name="lblEtapaNum" Text="1/5" Foreground="{StaticResource CorMarca}" FontSize="12" Width="62"/>
              <TextBlock x:Name="lblEtapaNome" FontSize="13.5" Foreground="{StaticResource CorFoco}" Text="$($Sim.Atual) Extraindo Vídeo Puro do MKV (ffmpeg, Sem Recodificar)"/>
              <TextBlock x:Name="lblGerado" DockPanel.Dock="Right" HorizontalAlignment="Right" FontSize="12.5" Foreground="{StaticResource CorDim2}" Text=""/>
            </DockPanel>
            <DockPanel>
              <TextBlock x:Name="lblPct" DockPanel.Dock="Right" Style="{StaticResource Mono}" Foreground="{StaticResource CorFoco}" Width="52" TextAlignment="Right" Text="0%"/>
              <Border Background="$($Cores.emCursoTrilho)" CornerRadius="4" Height="13" Margin="0,0,10,0">
                <Border x:Name="barraEtapa" Background="{StaticResource CorEmCurso}" CornerRadius="4" HorizontalAlignment="Left" Width="0"/>
              </Border>
            </DockPanel>
            <TextBlock x:Name="lblTemposEtapa" Style="{StaticResource Mono}" FontSize="12.5" Foreground="{StaticResource CorDim2}" Margin="0,7,0,0" Text=""/>
          </StackPanel>
        </Border>
        <Border Padding="14,8" BorderBrush="$($Cores.trilho)" BorderThickness="0,0,0,1">
          <StackPanel>
            <DockPanel Margin="0,0,0,6">
              <TextBlock Text="VÍDEO " Foreground="{StaticResource CorMarca}" FontSize="12"/>
              <TextBlock x:Name="lblVideoNum" Text="2/3" Foreground="{StaticResource CorMarca}" FontSize="12" Width="62"/>
              <TextBlock x:Name="lblVideoNome" FontSize="13" Foreground="{StaticResource CorTxt}" Text=""/>
              <TextBlock x:Name="lblPctVideo" DockPanel.Dock="Right" HorizontalAlignment="Right" Style="{StaticResource Mono}" FontSize="12.5" Width="52" TextAlignment="Right" Foreground="{StaticResource CorTxt}" Text=""/>
            </DockPanel>
            <!-- Altura 11 (era 7): o segmento que esta rodando ocupa os 11
                 inteiros e os outros ficam recuados 3 em cima e 3 embaixo.
                 A etapa de agora e a UNICA alta - da pra achar no relance,
                 mesmo em preto e branco. -->
            <!-- 16.60: OS DOIS PONTOS DAS FASES.
                 A regua desenha SO as etapas numeradas. O que roda antes da
                 primeira ([DIAGNOSTICO]) e depois da ultima ([VERIFICACAO] e
                 [LIMPEZA]) nao tem lugar nenhum nela - e sao justamente os
                 dois trechos em que a tela parece nao estar fazendo nada.
                 Nao viram segmento: fase nao e etapa, e a 16.47 existe
                 exatamente para isso. Viram um PONTO em cada ponta - o mesmo
                 "·" que a caixa do numero da etapa ja usa quando o que roda
                 nao tem numero. Seguem as cores da regua: apagado = ainda
                 nao, ciano = agora, verde = feito. -->
            <DockPanel Margin="0,0,62,6">
              <TextBlock x:Name="pontoDiag" DockPanel.Dock="Left"  Text="·" FontSize="18" FontWeight="Bold" Margin="0,-4,5,0" VerticalAlignment="Center" Foreground="$($Cores.vazio)"/>
              <TextBlock x:Name="pontoFim"  DockPanel.Dock="Right" Text="·" FontSize="18" FontWeight="Bold" Margin="5,-4,0,0" VerticalAlignment="Center" Foreground="$($Cores.vazio)"/>
              <Grid x:Name="gridEtapas" Height="11"/>
            </DockPanel>
            <DockPanel>
              <TextBlock x:Name="lblASeguir" DockPanel.Dock="Right" HorizontalAlignment="Right" FontSize="12.5" Foreground="{StaticResource CorDim2}" Text=""/>
              <TextBlock x:Name="lblTemposVideo" Style="{StaticResource Mono}" FontSize="12.5" Foreground="{StaticResource CorDim2}" Text=""/>
            </DockPanel>
          </StackPanel>
        </Border>
        <StackPanel Margin="14,8">
          <DockPanel Margin="0,0,0,5">
            <TextBlock Text="FILA " Foreground="{StaticResource CorMarca}" FontSize="12"/>
            <TextBlock x:Name="lblFilaNum" Text="2/3" Foreground="{StaticResource CorMarca}" FontSize="12" Width="62"/>
            <!-- 16.49: esta e a linha que responde "posso dormir?". Ela vinha
                 no mesmo cinza-fundo das outras duas (12.5 / CorDim2) e sumia.
                 Sobe pra 13.5 SemiBold no cinza claro - um degrau acima das
                 irmas, um degrau abaixo do nome da etapa (13.5 CorFoco). -->
            <TextBlock x:Name="lblTemposFila" Style="{StaticResource Mono}" FontSize="13.5" FontWeight="SemiBold" Foreground="{StaticResource CorDim}" Text=""/>
            <TextBlock x:Name="lblLivreAgora" DockPanel.Dock="Right" HorizontalAlignment="Right" Style="{StaticResource Mono}" FontSize="12.5" Foreground="{StaticResource CorDim2}" Text=""/>
          </DockPanel>
          <DockPanel>
            <TextBlock x:Name="lblPctFila" DockPanel.Dock="Right" Style="{StaticResource Mono}" Foreground="{StaticResource CorDim}" FontSize="12.5" Width="52" TextAlignment="Right" Text=""/>
            <Border Background="$($Cores.trilho)" Height="5" Margin="0,0,10,0">
              <Border x:Name="barraFila" Background="{StaticResource CorOkDim}" HorizontalAlignment="Left" Width="0"/>
            </Border>
          </DockPanel>
        </StackPanel>
      </StackPanel>
    </Border>

    <!-- FAIXA DE PAUSA -->
    <Border x:Name="faixaPausa" DockPanel.Dock="Bottom" Background="$($Cores.pausaFundo)" BorderBrush="$($Cores.pausaBorda)" BorderThickness="0,1" Padding="0,9" Visibility="Collapsed">
      <TextBlock HorizontalAlignment="Center" FontSize="14" Foreground="{StaticResource CorWarn}"
                 Text="&gt;&gt;&gt; PAUSADO (sem consumir CPU/disco) - [F2] Retomar   [ESC] Cancelar &lt;&lt;&lt;"/>
    </Border>

    <!-- MIOLO -->
    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>   <!-- pastas -->
        <RowDefinition Height="Auto"/>   <!-- ferramentas -->
        <RowDefinition Height="Auto"/>   <!-- faixa compacta -->
        <!-- m3c28: MinHeight na PROPRIA linha do grid, nao no Border. A fila e a
             unica linha estrela: sem isso, qualquer painel Auto que crescesse
             (o diagnostico quebrando linha em janela estreita) comia o espaco
             dela ate zerar - a caixa da fila desapareceu inteira no print do
             Diego. MinHeight aqui faz o Grid RESERVAR essa altura antes de
             distribuir o resto, entao a fila nunca mais pode ser zerada.
             Tentei antes por MinHeight no Border e por MinHeight na janela:
             nenhum dos dois funciona, porque o Border e clipado pela linha e a
             altura da janela nao muda a ordem de distribuicao do Grid. -->
        <RowDefinition Height="*" MinHeight="188"/>      <!-- fila OU resumo (exclusivos) -->
        <RowDefinition Height="Auto"/>   <!-- diagnostico -->
        <RowDefinition Height="Auto"/>   <!-- disco -->
      </Grid.RowDefinitions>

      <!-- PASTAS -->
      <Border x:Name="painelPastas" Grid.Row="0" Background="$($Cores.fundo)" BorderBrush="$($Cores.trilho)" BorderThickness="0,0,0,1" Padding="14,10">
        <StackPanel>
          <Border x:Name="cabecPastas" Cursor="Hand" Background="Transparent">
            <StackPanel Orientation="Horizontal">
              <TextBlock x:Name="setaPastas" Text="▼" FontSize="12" Foreground="{StaticResource CorMarca}" Margin="0,0,7,1" VerticalAlignment="Center"/>
              <TextBlock Text="PASTAS:" Style="{StaticResource Cabecalho}"/>
            </StackPanel>
          </Border>
          <StackPanel x:Name="corpoPastas">
          <DockPanel Margin="0,6,0,6">
            <TextBlock Text="Pasta de Origem :" FontSize="13" Foreground="{StaticResource CorTxt}" Width="132" VerticalAlignment="Center"/>
            <Button x:Name="btnTrocarOrigem" Focusable="False" Content="Procurar" DockPanel.Dock="Right" Style="{StaticResource BtnAcao}" Margin="8,0,0,0"/>
            <Border x:Name="boxOrigem" Background="$($Cores.painel)" BorderBrush="$($Cores.borda)" BorderThickness="1" CornerRadius="6" Padding="9,5">
              <TextBox x:Name="txtOrigem" FontFamily="Consolas" FontSize="13" Background="Transparent"
                       Foreground="{StaticResource CorTxt}" BorderThickness="0" IsReadOnly="True"
                       Padding="0" VerticalContentAlignment="Center" Cursor="Hand" Focusable="False"
                       ToolTip="Clique para escolher a pasta de ORIGEM."/>
            </Border>
          </DockPanel>
          <DockPanel>
            <TextBlock Text="Pasta de Saída  :" FontSize="13" Foreground="{StaticResource CorTxt}" Width="132" VerticalAlignment="Center"/>
            <Button x:Name="btnTrocarSaida" Focusable="False" Content="Procurar" DockPanel.Dock="Right" Style="{StaticResource BtnAcao}" Margin="8,0,0,0"/>
            <Border x:Name="boxSaida" Background="$($Cores.painel)" BorderBrush="$($Cores.borda)" BorderThickness="1" CornerRadius="6" Padding="9,5">
              <TextBox x:Name="txtSaida" FontFamily="Consolas" FontSize="13" Background="Transparent"
                       Foreground="{StaticResource CorTxt}" BorderThickness="0" IsReadOnly="True"
                       Padding="0" VerticalContentAlignment="Center" Cursor="Hand" Focusable="False"
                       ToolTip="Clique para escolher a pasta de SAIDA."/>
            </Border>
          </DockPanel>
          </StackPanel>
        </StackPanel>
      </Border>

      <!-- FERRAMENTAS (expandido na tela inicial) -->
      <Border x:Name="painelFerramentas" Grid.Row="1" Background="$($Cores.fundo)" BorderBrush="$($Cores.trilho)" BorderThickness="0,0,0,1" Padding="14,10">
        <StackPanel>
          <Border x:Name="cabecFerramentas" Cursor="Hand" Background="Transparent">
            <StackPanel Orientation="Horizontal">
              <TextBlock x:Name="setaFerramentas" Text="▼" FontSize="12" Foreground="{StaticResource CorMarca}" Margin="0,0,7,1" VerticalAlignment="Center"/>
              <TextBlock Text="FERRAMENTAS DISPONIVEIS:" Style="{StaticResource Cabecalho}"/>
            </StackPanel>
          </Border>
          <StackPanel x:Name="corpoFerramentas">
            <StackPanel x:Name="listaFerramentas"/>
          </StackPanel>
        </StackPanel>
      </Border>

      <!-- FAIXA COMPACTA (substitui pastas+ferramentas durante a conversao) -->
      <Border x:Name="faixaCompacta" Grid.Row="2" Background="$($Cores.fundo)" BorderBrush="$($Cores.trilho)" BorderThickness="0,0,0,1" Padding="14,6" Visibility="Collapsed">
        <DockPanel>
          <TextBlock x:Name="txtPastasCompacto" FontSize="13" Foreground="{StaticResource CorDim}"/>
          <!-- 16.40: era TEXTO FIXO no XAML. Ficava verde com visto nas tres
               ferramentas SEMPRE, existissem elas ou nao - ninguem nunca
               atualizava esta linha. Agora ela e montada em codigo a partir
               da checagem real (Update-FerramentasTopo). -->
          <TextBlock x:Name="lblFerrTopo" DockPanel.Dock="Right" HorizontalAlignment="Right" FontSize="13"/>
        </DockPanel>
      </Border>

      <!-- TABELA DA FILA -->
      <Border x:Name="caixaFila" Grid.Row="3" Background="$($Cores.painel)"
              BorderBrush="$($Cores.borda)" BorderThickness="1" CornerRadius="8"
              Margin="14,10,14,10" MinHeight="120">
      <Grid>
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- ABAS -->
        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="6,6,6,0">
          <Border x:Name="abaFila" Background="$($Cores.painel2)" BorderBrush="$($Cores.borda)"
                  BorderThickness="1,1,1,0" CornerRadius="6,6,0,0" Padding="16,6" Margin="0,0,2,0">
            <TextBlock x:Name="txtAbaFila" Text="Fila" FontSize="13.5" FontWeight="SemiBold" Foreground="#FFFFFF"/>
          </Border>
          <Border x:Name="abaFaixas" Background="Transparent" BorderBrush="Transparent"
                  BorderThickness="1,1,1,0" CornerRadius="6,6,0,0" Padding="16,6">
            <TextBlock x:Name="txtAbaFaixas" Text="Faixas do Vídeo" FontSize="13.5" Foreground="$($Cores.dim2)"/>
          </Border>
          <Border x:Name="btnMarcarTodos" Background="Transparent" BorderBrush="$($Cores.borda)"
                  BorderThickness="1" CornerRadius="4" Padding="10,3" Margin="14,4,0,0" Cursor="Hand">
            <TextBlock Text="Marcar Todos" FontSize="12.5" Foreground="$($Cores.txt)"/>
          </Border>
          <Border x:Name="btnDesmarcarTodos" Background="Transparent" BorderBrush="$($Cores.borda)"
                  BorderThickness="1" CornerRadius="4" Padding="10,3" Margin="6,4,0,0" Cursor="Hand">
            <TextBlock Text="Desmarcar Todos" FontSize="12.5" Foreground="$($Cores.txt)"/>
          </Border>
          <TextBlock x:Name="lblAbaDica" Margin="14,8,0,0" FontSize="12.5" Foreground="$($Cores.dim2)" Text=""/>
          <Border x:Name="btnModoVideo" Background="Transparent" BorderBrush="$($Cores.borda)"
                  BorderThickness="1" CornerRadius="4" Padding="10,3" Margin="14,4,0,0" Cursor="Hand"
                  Visibility="Collapsed">
            <TextBlock x:Name="txtModoVideo" Text="Modo: Automático" FontSize="12.5" Foreground="$($Cores.txt)"/>
          </Border>
        </StackPanel>

      <ListView x:Name="lstFila" Grid.Row="1" Background="Transparent" BorderThickness="0" Margin="4,4,4,6"
                ScrollViewer.VerticalScrollBarVisibility="Auto"
                VerticalAlignment="Stretch"
                ScrollViewer.HorizontalScrollBarVisibility="Disabled">
        <ListView.View>
          <!-- 16.16: cada celula vai dentro de um Border com fio SO na
               direita. ListView+GridView nao tem linha de grade nativa - o
               GridViewRowPresenter desenha as celulas coladas, e por isso a
               informacao parecia solta dentro da coluna. O tom e um degrau
               acima do fundo do painel: separa sem virar grade preta.
               16.18: subiu pra #2A2A33 - o Diego confirmou que o #1F1F27
               so aparecia com a linha selecionada. Este tom e o MESMO de
               $Cores.borda2, ja usado no resto da janela. -->
          <GridView AllowsColumnReorder="False">
            <GridViewColumn Width="34" Header="">
              <GridViewColumn.CellTemplate><DataTemplate>
                <!-- 16.17: a coluna do checkbox tem 34px. O recuo de 8px que
                     as outras celulas usam pra afastar o texto do fio comia
                     um quarto dela e espremia a caixinha. Aqui o recuo e zero
                     e quem centraliza e o proprio CheckBox. -->
                <Border BorderBrush="#2A2A33" BorderThickness="0,0,1,0" Padding="0">
                <CheckBox IsChecked="{Binding Marcado, Mode=OneWay}" IsEnabled="{Binding PodeMarcar}"
                          Tag="{Binding Idx}" VerticalAlignment="Center" HorizontalAlignment="Center" Margin="0"
                          Focusable="False" ToolTip="Converter este vídeo"/>
                </Border>
              </DataTemplate></GridViewColumn.CellTemplate>
            </GridViewColumn>
            <GridViewColumn x:Name="colFila" Width="330" Header="VÍDEOS NA FILA">
              <GridViewColumn.CellTemplate><DataTemplate>
                <Border BorderBrush="#2A2A33" BorderThickness="0,0,1,0" Padding="6,0,8,0">
                <TextBlock VerticalAlignment="Center" FontFamily="Consolas" FontSize="13.5" Text="{Binding Nome}" Foreground="{Binding CorNome}"
                           FontWeight="{Binding Peso}" TextTrimming="CharacterEllipsis"/>
                </Border>
              </DataTemplate></GridViewColumn.CellTemplate>
            </GridViewColumn>
            <GridViewColumn Width="95" Header="TAMANHO">
              <GridViewColumn.CellTemplate><DataTemplate>
                <Border BorderBrush="#2A2A33" BorderThickness="0,0,1,0" Padding="6,0,8,0">
                <TextBlock VerticalAlignment="Center" FontFamily="Consolas" FontSize="13" Text="{Binding Tamanho}" Foreground="$($Cores.dim)"/>
                </Border>
              </DataTemplate></GridViewColumn.CellTemplate>
            </GridViewColumn>
            <GridViewColumn Width="150" Header="DOLBY VISION">
              <GridViewColumn.CellTemplate><DataTemplate>
                <!-- 16.21: ate aqui esta coluna era DUAS molduras uma dentro
                     da outra - uma caixa reta pra linha de grade, e uma
                     pastilha arredondada flutuando dentro dela pro chip. Por
                     isso nunca ficava alinhada com TAMANHO/VIDEOS NA FILA,
                     que sao uma caixa so. Agora e uma UNICA caixa: o fundo
                     colorido (FundoDV/FundoAudio/FundoLeg) preenche a celula
                     inteira, sem cantos arredondados e sem moldura extra -
                     estrutura IDENTICA as colunas de texto simples, so que
                     com fundo tintado quando ha conversao. -->
                <Border BorderBrush="#2A2A33" BorderThickness="0,0,1,0" Padding="6,0,8,0" Background="{Binding FundoDV}">
                  <TextBlock VerticalAlignment="Center" FontFamily="Consolas" FontSize="13" Text="{Binding DV}" Foreground="{Binding CorDV}" TextTrimming="CharacterEllipsis"/>
                </Border>
              </DataTemplate></GridViewColumn.CellTemplate>
            </GridViewColumn>
            <GridViewColumn Width="255" Header="ÁUDIO">
              <GridViewColumn.CellTemplate><DataTemplate>
                <!-- 16.21: ate aqui esta coluna era DUAS molduras uma dentro
                     da outra - uma caixa reta pra linha de grade, e uma
                     pastilha arredondada flutuando dentro dela pro chip. Por
                     isso nunca ficava alinhada com TAMANHO/VIDEOS NA FILA,
                     que sao uma caixa so. Agora e uma UNICA caixa: o fundo
                     colorido (FundoAudio) preenche a celula
                     inteira, sem cantos arredondados e sem moldura extra -
                     estrutura IDENTICA as colunas de texto simples, so que
                     com fundo tintado quando ha conversao. -->
                <Border BorderBrush="#2A2A33" BorderThickness="0,0,1,0" Padding="6,0,8,0" Background="{Binding FundoAudio}">
                  <TextBlock VerticalAlignment="Center" FontFamily="Consolas" FontSize="13" Text="{Binding Audio}" Foreground="{Binding CorAudio}" TextTrimming="CharacterEllipsis"/>
                </Border>
              </DataTemplate></GridViewColumn.CellTemplate>
            </GridViewColumn>
            <GridViewColumn Width="160" Header="LEGENDA PT-BR">
              <GridViewColumn.CellTemplate><DataTemplate>
                <!-- 16.16: esta coluna era o unico "A -> B" da fila sem chip.
                     Dolby Vision e Audio ja diziam "vou converter isto" com o
                     enquadramento verde; a legenda dizia a mesma coisa em
                     texto solto, e o olho passava batido. Mesma regra dos
                     outros: chip SO quando ha seta, ou seja, so quando ha
                     conversao de verdade. 16.21: mesma caixa unica das
                     outras colunas coloridas - ver DOLBY VISION. -->
                <Border BorderBrush="#2A2A33" BorderThickness="0,0,1,0" Padding="6,0,8,0" Background="{Binding FundoLeg}">
                  <TextBlock VerticalAlignment="Center" FontFamily="Consolas" FontSize="13" Text="{Binding Legenda}" Foreground="{Binding CorLegenda}" TextTrimming="CharacterEllipsis"/>
                </Border>
              </DataTemplate></GridViewColumn.CellTemplate>
            </GridViewColumn>
            <GridViewColumn Width="245" Header="SITUAÇÃO">
              <GridViewColumn.CellTemplate><DataTemplate>
                <Border BorderBrush="#2A2A33" BorderThickness="0,0,1,0" Padding="6,0,8,0">
                <!-- 16.16: eram DUAS informacoes pintadas com uma cor so. O
                     "Proximo a Converter" e verde porque e o proximo da fila;
                     o "· Manual" e violeta porque ha escolha manual ali. Como
                     tudo saia num TextBlock unico, o violeta do selo engolia o
                     verde e voce perdia de vista qual video ia comecar. Agora
                     sao dois blocos, cada um com a sua cor. -->
                <StackPanel VerticalAlignment="Center" Orientation="Horizontal">
                  <TextBlock FontFamily="Consolas" FontSize="13.5" Text="{Binding Situacao}" Foreground="{Binding CorSituacao}"
                             FontWeight="{Binding Peso}"/>
                  <TextBlock FontFamily="Consolas" FontSize="13.5" Text="{Binding SeloManual}" Foreground="{Binding CorSelo}"/>
                </StackPanel>
                </Border>
              </DataTemplate></GridViewColumn.CellTemplate>
            </GridViewColumn>
          </GridView>
        </ListView.View>
      </ListView>

      <!-- TABELA DE FAIXAS - mesmo espaco da fila, alternado pelas abas -->
      <!-- m3c9: HorizontalScrollBarVisibility="Auto" foi tentado pra resolver
           a coluna AÇÃO sumindo com a janela estreita, e QUEBROU o layout
           inteiro na maquina real (Diego reportou com print) - revertido pra
           Disabled. Nao mexer nisso de novo sem poder testar ao vivo; se o
           problema persistir, pensar numa MinWidth pra janela em vez de
           scroll horizontal na tabela. -->
      <ListView x:Name="lstFaixas" Grid.Row="1" Background="Transparent" BorderThickness="0"
                Margin="4,4,4,6" Visibility="Collapsed"
                ScrollViewer.VerticalScrollBarVisibility="Auto"
                VerticalAlignment="Stretch"
                ScrollViewer.HorizontalScrollBarVisibility="Disabled">
        <ListView.View>
          <!-- 16.16: cada celula vai dentro de um Border com fio SO na
               direita. ListView+GridView nao tem linha de grade nativa - o
               GridViewRowPresenter desenha as celulas coladas, e por isso a
               informacao parecia solta dentro da coluna. O tom e um degrau
               acima do fundo do painel: separa sem virar grade preta.
               16.18: subiu pra #2A2A33 - o Diego confirmou que o #1F1F27
               so aparecia com a linha selecionada. Este tom e o MESMO de
               $Cores.borda2, ja usado no resto da janela. -->
          <GridView AllowsColumnReorder="False">
            <GridViewColumn Width="52" Header="ID">
              <GridViewColumn.CellTemplate><DataTemplate>
                <Border BorderBrush="#2A2A33" BorderThickness="0,0,1,0" Padding="6,0,8,0">
                <TextBlock VerticalAlignment="Center" FontFamily="Consolas" FontSize="13" Text="{Binding Id}" Foreground="{Binding CorDim}"
                           FontWeight="{Binding Peso}"/>
                </Border>
              </DataTemplate></GridViewColumn.CellTemplate>
            </GridViewColumn>
            <GridViewColumn x:Name="colFxTipo" Width="128" Header="TIPO">
              <GridViewColumn.CellTemplate><DataTemplate>
                <Border BorderBrush="#2A2A33" BorderThickness="0,0,1,0" Padding="6,0,8,0">
                <TextBlock VerticalAlignment="Center" FontFamily="Consolas" FontSize="13" Text="{Binding Tipo}" Foreground="{Binding CorTipo}"
                           FontWeight="{Binding Peso}"/>
                </Border>
              </DataTemplate></GridViewColumn.CellTemplate>
            </GridViewColumn>
            <GridViewColumn Width="215" Header="CODEC">
              <GridViewColumn.CellTemplate><DataTemplate>
                <Border BorderBrush="#2A2A33" BorderThickness="0,0,1,0" Padding="6,0,8,0">
                <TextBlock VerticalAlignment="Center" FontFamily="Consolas" FontSize="13" Text="{Binding Codec}" Foreground="{Binding CorNome}"
                           FontWeight="{Binding Peso}" TextTrimming="CharacterEllipsis"/>
                </Border>
              </DataTemplate></GridViewColumn.CellTemplate>
            </GridViewColumn>
            <GridViewColumn Width="92" Header="IDIOMA">
              <GridViewColumn.CellTemplate><DataTemplate>
                <Border BorderBrush="#2A2A33" BorderThickness="0,0,1,0" Padding="6,0,8,0">
                <TextBlock VerticalAlignment="Center" FontFamily="Consolas" FontSize="13" Text="{Binding Idioma}" Foreground="{Binding CorIdioma}"
                           FontWeight="{Binding Peso}"/>
                </Border>
              </DataTemplate></GridViewColumn.CellTemplate>
            </GridViewColumn>
            <GridViewColumn Width="300" Header="NOME DA FAIXA">
              <GridViewColumn.CellTemplate><DataTemplate>
                <Border BorderBrush="#2A2A33" BorderThickness="0,0,1,0" Padding="6,0,8,0">
                <TextBlock VerticalAlignment="Center" FontFamily="Consolas" FontSize="13" Text="{Binding NomeFaixa}" Foreground="{Binding CorNome}"
                           FontWeight="{Binding Peso}" TextTrimming="CharacterEllipsis"/>
                </Border>
              </DataTemplate></GridViewColumn.CellTemplate>
            </GridViewColumn>
            <GridViewColumn Width="96" Header="TAMANHO">
              <GridViewColumn.CellTemplate><DataTemplate>
                <Border BorderBrush="#2A2A33" BorderThickness="0,0,1,0" Padding="6,0,8,0">
                <TextBlock VerticalAlignment="Center" FontFamily="Consolas" FontSize="13" Text="{Binding TamanhoFx}" Foreground="{Binding CorDim}"
                           FontWeight="{Binding Peso}"/>
                </Border>
              </DataTemplate></GridViewColumn.CellTemplate>
            </GridViewColumn>
            <GridViewColumn Width="200" Header="MARCAS">
              <GridViewColumn.CellTemplate><DataTemplate>
                <Border BorderBrush="#2A2A33" BorderThickness="0,0,1,0" Padding="6,0,8,0">
                <TextBlock VerticalAlignment="Center" FontFamily="Consolas" FontSize="13" Text="{Binding MarcasFx}" Foreground="{Binding CorMarcas}"
                           FontWeight="{Binding Peso}"/>
                </Border>
              </DataTemplate></GridViewColumn.CellTemplate>
            </GridViewColumn>
            <GridViewColumn Width="90" Header="PADRÃO">
              <GridViewColumn.CellTemplate><DataTemplate>
                <Border BorderBrush="#2A2A33" BorderThickness="0,0,1,0" Padding="6,0,8,0">
                <TextBlock VerticalAlignment="Center" FontFamily="Consolas" FontSize="12" Text="{Binding Padrao}" Foreground="{StaticResource CorMarca}"
                           FontWeight="SemiBold"/>
                </Border>
              </DataTemplate></GridViewColumn.CellTemplate>
            </GridViewColumn>
            <GridViewColumn Width="260" Header="AÇÃO">
              <GridViewColumn.CellTemplate><DataTemplate>
                <Border BorderBrush="#2A2A33" BorderThickness="0,0,1,0" Padding="6,0,8,0">
                <StackPanel VerticalAlignment="Center" Orientation="Horizontal">
                  <ComboBox ItemsSource="{Binding Opcoes}" SelectedItem="{Binding Verbo, Mode=OneWay}"
                            IsEnabled="{Binding Editavel}" Tag="{Binding IdxFaixa}"
                            Visibility="{Binding ComboVisivel, Converter={StaticResource BoolParaVisibilidade}}"
                            FontFamily="Consolas" FontSize="13" Padding="2,1" MinWidth="90"
                            Style="{StaticResource ComboVerbo}"/>
                  <TextBlock Text="{Binding Verbo}" FontFamily="Consolas" FontSize="13"
                             Foreground="{Binding CorVerbo}" FontWeight="{Binding PesoVerbo}"
                             Visibility="{Binding ComboOculto, Converter={StaticResource BoolParaVisibilidade}}"/>
                  <TextBlock Text="{Binding DetalheVerbo}" FontFamily="Consolas" FontSize="12"
                             Foreground="{Binding CorDim}" VerticalAlignment="Center" Margin="4,0,0,0"/>
                </StackPanel>
                </Border>
              </DataTemplate></GridViewColumn.CellTemplate>
            </GridViewColumn>
          </GridView>
        </ListView.View>
      </ListView>

      <Border x:Name="rodapeTamanho" Grid.Row="2" Background="$($Cores.painel2)" BorderBrush="$($Cores.trilho)"
              BorderThickness="0,1,0,0" Padding="14,8" Visibility="Collapsed">
        <TextBlock x:Name="txtRodapeTamanho" FontFamily="Consolas" FontSize="13" Foreground="$($Cores.txt)"/>
      </Border>

      </Grid>
      </Border>

      <!-- DIAGNÓSTICO DO SELECIONADO -->
      <!-- m3c27: MaxHeight + ScrollViewer. As 3 linhas de resultado usam
           TextWrapping="Wrap": em janela estreita cada uma quebra em duas, o
           painel cresce, e como a FILA e a unica linha estrela do grid, era
           ela que pagava - chegou a desaparecer inteira na janela minima
           (1080x700, visto em print). Agora o diagnostico para de crescer num
           teto e rola por dentro; a fila mantem o espaco dela.
           Mesmo padrao do painel de cartoes do resumo, que ja fazia isso. -->
      <Border x:Name="painelDiagnostico" Grid.Row="4" Background="$($Cores.painel)" BorderBrush="$($Cores.borda)"
              BorderThickness="1" CornerRadius="8" Margin="14,0,14,10" Padding="14,10" MaxHeight="168">
        <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
        <StackPanel>
          <TextBlock x:Name="lblDiagTitulo" Style="{StaticResource Cabecalho}" FontSize="14.5" FontWeight="SemiBold" Margin="0,0,0,6" Text="DIAGNÓSTICO:"/>
          <Grid>
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="Auto"/>
              <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
              <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock x:Name="diagDV"  Grid.Row="0" Grid.Column="0" FontSize="14.5" FontWeight="SemiBold" Foreground="{StaticResource CorSrc}"  Margin="0,3,10,3"/>
            <TextBlock x:Name="diagAu"  Grid.Row="1" Grid.Column="0" FontSize="14.5" FontWeight="SemiBold" Foreground="{StaticResource CorSrc}"  Margin="0,3,10,3"/>
            <TextBlock x:Name="diagLg"  Grid.Row="2" Grid.Column="0" FontSize="14.5" FontWeight="SemiBold" Foreground="{StaticResource CorSrc}"  Margin="0,3,10,3"/>
            <TextBlock x:Name="diagDVr" Grid.Row="0" Grid.Column="1" FontSize="14.5" FontWeight="SemiBold" Foreground="{StaticResource CorOk}"   TextWrapping="Wrap" Margin="0,3"/>
            <TextBlock x:Name="diagAur" Grid.Row="1" Grid.Column="1" FontSize="14.5" FontWeight="SemiBold" Foreground="{StaticResource CorOk}"   TextWrapping="Wrap" Margin="0,3"/>
            <TextBlock x:Name="diagLgr" Grid.Row="2" Grid.Column="1" FontSize="14.5" FontWeight="SemiBold" Foreground="{StaticResource CorWarn}" TextWrapping="Wrap" Margin="0,3"/>
          </Grid>
        </StackPanel>
        </ScrollViewer>
      </Border>

      <!-- ESPAÇO EM DISCO (tela inicial) -->
      <Border x:Name="painelDisco" Grid.Row="5" Background="$($Cores.painel)" BorderBrush="$($Cores.borda)"
              BorderThickness="1" CornerRadius="8" Margin="14,0,14,12" Padding="14,10">
        <StackPanel>
          <TextBlock Text="ESPAÇO EM DISCO:" Style="{StaticResource Cabecalho}"/>
          <Grid>
            <Grid.ColumnDefinitions><ColumnDefinition Width="310"/><ColumnDefinition/></Grid.ColumnDefinitions>
            <TextBlock x:Name="txtDisco" Grid.Column="0" Style="{StaticResource Mono}" FontSize="14" LineHeight="24"/>
            <StackPanel Grid.Column="1" Margin="18,4,0,0" VerticalAlignment="Center">
              <Border Background="$($Cores.trilho)" CornerRadius="4" Height="9" Margin="0,0,0,6">
                <Border x:Name="barraDisco" Background="{StaticResource CorOk}" CornerRadius="4" HorizontalAlignment="Left" Width="0"/>
              </Border>
              <TextBlock x:Name="lblDiscoMsg" FontSize="13" Foreground="{StaticResource CorOk}"/>
            </StackPanel>
          </Grid>
        </StackPanel>
      </Border>

      <!-- RESUMO FINAL -->
      <Border x:Name="painelResumo" Grid.Row="3" Background="$($Cores.fundo)" Visibility="Collapsed">
      <Grid>
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>   <!-- veredito -->
          <RowDefinition Height="Auto"/>   <!-- contadores -->
          <RowDefinition Height="*"/>      <!-- cartoes (estica) -->
          <RowDefinition Height="Auto"/>   <!-- rodape -->
        </Grid.RowDefinitions>
          <Border Grid.Row="0" Padding="14,11" BorderBrush="$($Cores.trilho)" BorderThickness="0,1,0,1">
            <DockPanel>
              <TextBlock x:Name="icoResumo" Text="$($Sim.Ok)" FontSize="25" Foreground="{StaticResource CorOk}" Margin="0,0,11,0" VerticalAlignment="Center"/>
              <StackPanel VerticalAlignment="Center">
                <TextBlock x:Name="lblResumoTitulo" Text="Conversão Concluída" FontSize="16.5" Foreground="{StaticResource CorFoco}"/>
                <TextBlock x:Name="lblResumoTempos" FontSize="13" Foreground="{StaticResource CorDim}"/>
              </StackPanel>
              <StackPanel DockPanel.Dock="Right" Orientation="Horizontal" HorizontalAlignment="Right">
                <Button x:Name="btnNovaConversao" Style="{StaticResource BtnAcao}" Margin="0,0,8,0">
                  <TextBlock Text="&#8635; Nova Conversão" FontSize="14"/>
                </Button>
                <Button x:Name="btnEncerrar" Style="{StaticResource BtnAcao}" Background="$($Cores.errFundo)" BorderBrush="$($Cores.errBorda)">
                  <TextBlock Text="&#9211; Encerrar Programa" FontSize="14" Foreground="{StaticResource CorErr}"/>
                </Button>
              </StackPanel>
            </DockPanel>
          </Border>
          <Border Grid.Row="1" Padding="14,10" BorderBrush="$($Cores.trilho)" BorderThickness="0,0,0,1">
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
              <StackPanel Grid.Column="0" Margin="0,0,14,0">
                <TextBlock Text="RESUMO DA CONVERSÃO:" Style="{StaticResource Cabecalho}"/>
                <TextBlock x:Name="txtContadores" Style="{StaticResource Mono}" LineHeight="20"/>
              </StackPanel>
              <StackPanel Grid.Column="1">
                <TextBlock Text="DETALHAMENTO POR PROCESSO:" Style="{StaticResource Cabecalho}"/>
                <TextBlock x:Name="txtDetalhamento" Style="{StaticResource Mono}" LineHeight="20"/>
              </StackPanel>
            </Grid>
          </Border>
          <Border Grid.Row="2" Background="$($Cores.painel)" BorderBrush="$($Cores.borda)"
                  BorderThickness="1" CornerRadius="8" Margin="14,11,14,6" Padding="10" MinHeight="152">
            <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
              <StackPanel x:Name="pilhaCartoes"/>
            </ScrollViewer>
          </Border>
          <Border Grid.Row="3" Padding="14,9" Background="$($Cores.painel)" BorderBrush="$($Cores.borda)" BorderThickness="0,1,0,0">
            <TextBlock x:Name="txtRodapeResumo" Style="{StaticResource Mono}" FontSize="12.5" Foreground="{StaticResource CorDim}" LineHeight="17"/>
          </Border>
      </Grid>
      </Border>

    </Grid>
  </DockPanel>
</Window>
"@

# ============================================================================
#  CODE-BEHIND
# ============================================================================

# ---- Identidade propria na barra de tarefas ---------------------------------
# 16.26: o icone da barra de TAREFAS nao vem do Window.Icon - vem da identidade
# de aplicativo (AppUserModelID) do processo. Como quem hospeda a janela e o
# powershell.exe, o Windows agrupava o botao junto com o PowerShell e usava o
# icone azul dele, mesmo com o Window.Icon ja certo na barra de titulo.
# Declarar um AppUserModelID proprio desgruda o botao do PowerShell e faz a
# barra de tarefas usar o icone da propria janela.
# TEM que ser chamado ANTES da janela existir - por isso esta aqui em cima.
try {
    if (-not ('LaFirma.Shell' -as [type])) {
        Add-Type -Namespace LaFirma -Name Shell -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("shell32.dll", SetLastError=true)]
public static extern int SetCurrentProcessExplicitAppUserModelID(
    [System.Runtime.InteropServices.MarshalAs(
        System.Runtime.InteropServices.UnmanagedType.LPWStr)] string AppID);
'@ -ErrorAction Stop
    }
    [LaFirma.Shell]::SetCurrentProcessExplicitAppUserModelID(
        "LaFirma.RemuxForge.BlackEdition") | Out-Null
    Escrever-Log "Identidade de aplicativo propria registrada (barra de tarefas)"
} catch {
    # Puramente cosmetico: se falhar, a janela abre igual, so que o botao da
    # barra de tarefas continua com o icone do PowerShell. Nunca trava nada.
    Escrever-Log "AVISO: nao foi possivel registrar a identidade de aplicativo: $($_.Exception.Message)"
}

# ---- Carregar a janela ------------------------------------------------------
try {
    $leitor = New-Object System.Xml.XmlNodeReader ([xml]$Xaml)
    $Janela = [Windows.Markup.XamlReader]::Load($leitor)
} catch {
    [System.Windows.MessageBox]::Show("Falha ao montar a interface: $($_.Exception.Message)",
        "LaFirma", "OK", "Error") | Out-Null
    exit 1
}
Registrar-Ambiente
Escrever-Log "XAML carregado e janela construida com sucesso"

# 16.25: sem isto a barra de tarefas usa o icone padrao do powershell.exe,
# porque a janela WPF nunca disse qual icone e o dela. So afeta a aparencia -
# se o arquivo nao existir por qualquer motivo, o try/catch deixa passar
# batido e a janela abre igual, so que com o icone padrao de nome.
try {
    $CaminhoIcone = Join-Path $script:PastaScript "icone\LaFirmaRemuxForge.ico"
    if (Test-Path -LiteralPath $CaminhoIcone) {
        $Janela.Icon = New-Object System.Windows.Media.Imaging.BitmapImage(
            (New-Object Uri($CaminhoIcone, [UriKind]::Absolute)))
    }
} catch { }

# Todos os controles nomeados, achados UMA vez (sem FindName espalhado).
$UI = @{}
([regex]'x:Name="([^"]+)"').Matches($Xaml) | ForEach-Object {
    $n = $_.Groups[1].Value
    $UI[$n] = $Janela.FindName($n)
}

# ---- Barra de titulo escura (Windows 10 20H1+; falha em silencio se nao der)
try {
    Add-Type -Namespace Nativo -Name Dwm -MemberDefinition @'
[DllImport("dwmapi.dll")]
public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int value, int size);
'@
    $Janela.add_SourceInitialized({
        $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper($Janela)).Handle
        $on = 1
        [Nativo.Dwm]::DwmSetWindowAttribute($hwnd, 20, [ref]$on, 4) | Out-Null
    })
} catch { }

# ---- Dados de demonstracao --------------------------------------------------
# ---- Configuracao e estado real --------------------------------------------
$Cfg = @{
    Origem = ""   # preenchidos em Descobrir-Pastas, logo abaixo
    Saida  = ""
    # 16.37: SAO CINCO ETAPAS, NAO SETE.
    # O diagnostico (ffprobe, media 1s) e a limpeza de temporarios (00m00s em
    # TODOS os logs medidos) nunca foram trabalho - eram duas caixas de sete
    # na regua, 29% dela, reservadas pra 1 segundo. Era exatamente dai que
    # vinha o pedaco vazio no fim da barra do VIDEO durante a remontagem: a
    # barra guardava lugar pra uma etapa que nao gasta tempo.
    # As duas continuam aparecendo (o motor 14.13 marca com [DIAGNOSTICO] e
    # [LIMPEZA]) e continuam com relogio proprio no log - so sairam da regua
    # e da divisao do tempo restante.
    # Estes Pesos aqui sao SO a largura desenhada da regua. O peso que conta
    # tempo e o de $script:PesoEtapa / Get-PesosDoVideo, mais abaixo.
    # 16.41: mesma ESCALA dos pesos reais ($script:PesoEtapa), pra regua antes
    # de comecar ja ter a proporcao certa. So e usada quando nao ha arquivo
    # convertendo - com arquivo, quem manda sao os pesos dele.
    #   video 172 · dovi 221 · audio 190 (DTS) · legenda 469 · mkvmerge 413
    # 16.44: o ultimo era 388 e ficou para tras quando a 16.42 somou a
    # [VERIFICACAO] (25) na etapa de remontagem dentro de Get-PesosDoVideo.
    # Dois numeros para a mesma coisa, e este e o que a regua usa ANTES de
    # comecar a conversao - a barra mudava de largura sozinha no primeiro
    # arquivo.
    Pesos  = @(172,221,190,469,413)
    Etapas = @(
        "Extraindo Vídeo Puro do MKV (ffmpeg, Sem Recodificar)"
        "Convertendo Dolby Vision para Profile 8.1 (dovi_tool)"
        "Conversão de Áudio para E-AC-3"
        "Conversão de Legenda PGS para .SRT"
        "Remontando MKV Final (mkvmerge)"
    )
}

# Estado vivo, preenchido pela leitura real da pasta.
# Lista tipada: .Add e .Count sem surpresa de desembrulho de array.
$script:Videos      = New-Object System.Collections.Generic.List[object]
# A colecao que a tela observa. Criada uma vez; dai em diante so Clear/Add.
$script:LinhasFila  = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$script:Ferramentas = @()     # o que foi achado em tools\
$script:Lendo       = $false
$script:CaminhoMotor = ""

function Descobrir-Pastas {
    # A GUI mora na mesma pasta do motor, entao as pastas padrao saem dai.
    # Se nao existirem, cai na propria pasta do script - melhor abrir
    # mostrando algo que existe do que um caminho quebrado.
    $base = Join-Path $script:PastaScript "00_Arquivos_Base"
    $fim  = Join-Path $script:PastaScript "01_Arquivos_Finalizados"
    if (-not (Test-Path -LiteralPath $base)) { $base = $script:PastaScript }
    $Cfg.Origem = $base
    $Cfg.Saida  = $fim
}

function New-LinhaFila($Nome,$Tam,$DV,$Audio,$Leg,$Sit,$CorNome,$CorDV,$CorAudio,$CorLeg,$CorSit,$Peso="Normal",$Idx=-1,$Marcado=$false,$PodeMarcar=$false,
                       $FundoDV="Transparent",$BordaDV="Transparent",$FundoAudio="Transparent",$BordaAudio="Transparent",
                       $FundoLeg="Transparent",$BordaLeg="Transparent",$SeloManual="",$CorSelo="Transparent") {
    [PSCustomObject]@{ Nome=$Nome; Tamanho=$Tam; DV=$DV; Audio=$Audio; Legenda=$Leg
                       Situacao=$Sit; CorNome=$CorNome; CorDV=$CorDV; CorAudio=$CorAudio
                       CorLegenda=$CorLeg; CorSituacao=$CorSit; Peso=$Peso
                       Idx=$Idx; Marcado=$Marcado; PodeMarcar=$PodeMarcar
                       FundoDV=$FundoDV; BordaDV=$BordaDV
                       FundoAudio=$FundoAudio; BordaAudio=$BordaAudio
                       FundoLeg=$FundoLeg; BordaLeg=$BordaLeg
                       SeloManual=$SeloManual; CorSelo=$CorSelo }
}

# m3c25: chip = enquadramento + cor, o estilo que o Diego aprovou (o mesmo dos
# selos da tela de resumo). Aparece SO onde ha acao ou perda - se aparecesse em
# tudo viraria papel de parede e ele pararia de olhar.
#   verde = vai converter, e o resultado e o melhor possivel
#   ambar = vai reaproveitar algo PIOR do que daria pra ter
#   nenhum = ja esta no melhor possivel, nada a fazer
function Get-ChipVerde  { return @{ Fundo = "#0B1A08"; Borda = "#1F5A16" } }
function Get-ChipAmbar  { return @{ Fundo = "#211A08"; Borda = "#6E5518" } }
function Get-ChipVazio  { return @{ Fundo = "Transparent"; Borda = "Transparent" } }

# m3c19: vocabulario "X Mantido" != "X OK" (HANDOFF 7.10 item 4).
#   "X OK"      = VEREDITO DO MOTOR - ele analisou e achou que ja esta bom.
#   "X Mantido" = ESCOLHA DO USUARIO - o motor queria mexer, o Diego decidiu
#                 deixar como esta (ou o contrario, no caso do CONVERTER).
# Os dois sairiam com o MESMO texto na coluna da Fila, escondendo justamente a
# informacao que o modo Manual existe pra dar: "isso aqui nao e o automatico".
# Cor tambem distingue: Mantido em violeta (mesma cor do selo "· Manual" da
# fila), Excluido em vermelho (mesma cor do verbo EXCLUIR na coluna ACAO).
function Get-CodecCurto($f) {
    $c = "$($f.Codec)"
    if ($c -match "TrueHD")     { return "TrueHD" }
    if ($c -match "DTS")        { return "DTS" }
    if ($c -match "E-AC-3")     { return "E-AC-3" }
    if ($c -match "AC-3")       { return "AC-3" }
    if ($c -match "AAC")        { return "AAC" }
    if ($c -match "PGS")        { return "PGS" }
    if ($c -match "SubRip|SRT") { return "SRT" }
    return $c
}
function Get-DestinoConversao($f) {
    if ($f.Tipo -eq "subtitles")   { return "SRT" }
    if ("$($f.Codec)" -match "TrueHD") { return "E-AC-3[ATMOS]" }
    return "E-AC-3"
}
function Get-TextoEscolha($f) {
    # Texto no vocabulario da Fila para a escolha MANUAL feita nesta faixa.
    $base = Get-CodecCurto $f
    switch ("$($f.VerboUsuario)") {
        "MANTER"    { return "$base Mantido" }
        "EXCLUIR"   { return "$base Excluído" }
        "CONVERTER" { return "$base → $(Get-DestinoConversao $f)" }
    }
    return ""
}
function Test-TemEscolha($f) {
    return ($f -and -not (Test-VerboBloqueado $f) -and $null -ne $f.VerboUsuario)
}
function Get-ColunaAudioComEscolha($v, [string]$TextoMotor) {
    if ($v.Modo -ne "Manual") { return $TextoMotor }
    $faixas = @($v.Faixas)
    $joc = @($faixas | Where-Object { "$($_.Papel)" -eq "audio-joc" }) | Select-Object -First 1
    $pri = @($faixas | Where-Object { "$($_.Papel)" -eq "audio-principal" }) | Select-Object -First 1
    # A JOC pronta e a RAZAO do "E-AC-3[ATMOS] OK". Se o usuario excluir ela, o
    # audio final passa a ser definido pela faixa principal - que volta a
    # precisar de conversao se ele nao tiver escolhido nada nela.
    if ((Test-TemEscolha $joc) -and "$($joc.VerboUsuario)" -eq "EXCLUIR") {
        if (-not $pri) { return "Sem Áudio" }
        if (Test-TemEscolha $pri) { return Get-TextoEscolha $pri }
        return "$(Get-CodecCurto $pri) → $(Get-DestinoConversao $pri)"
    }
    if (Test-TemEscolha $pri) { return Get-TextoEscolha $pri }
    return $TextoMotor
}
function Get-ColunaLegendaComEscolha($v, [string]$TextoMotor) {
    if ($v.Modo -ne "Manual") { return $TextoMotor }
    $leg = @(@($v.Faixas) | Where-Object { "$($_.Papel)" -eq "leg-ptbr" }) | Select-Object -First 1
    if (-not (Test-TemEscolha $leg)) { return $TextoMotor }
    # Excluir a pt-BR nao e "PT-BR Excluida" e sim o resultado final: o mkv sai
    # sem legenda em portugues. Esse texto ja existe no vocabulario.
    if ("$($leg.VerboUsuario)" -eq "EXCLUIR") { return "Sem Legenda PT-BR" }
    return Get-TextoEscolha $leg
}

# 16.61: O DIAGNOSTICO NAO OLHAVA A ESCOLHA MANUAL.
#   O painel DIAGNOSTICO e montado UMA vez, na leitura da pasta, e ficava
#   congelado. O Diego marcou "Manter" no audio do Se7en, deu F1, e o painel
#   continuou anunciando "[SERA CONVERTIDO] E-AC-3 640k (ffmpeg)" - enquanto
#   a coluna AUDIO ja dizia "DTS Mantido" e o motor, no fim, mantinha mesmo
#   ("Audio DTS-HD Master Audio Mantido a Pedido - CONVERSAO DESLIGADA").
#   Ou seja: o unico que mentia era o aviso. Mesmo defeito que o motor ja
#   tinha corrigido no log em 14.8 - a GUI so nao tinha recebido a correcao.
#   Aqui o painel passa a ler a MESMA escolha que a coluna le (as funcoes
#   Test-TemEscolha / Get-CodecCurto / Get-DestinoConversao, que ja existem),
#   em vez de reimplementar a decisao - regra de ouro do projeto.
#   Devolve $null quando nao ha escolha manual: nesse caso vale o texto do
#   motor, intacto.
function Get-DiagAudioComEscolha($v) {
    if ("$($v.Modo)" -ne "Manual") { return $null }
    $faixas = @($v.Faixas)
    $joc = @($faixas | Where-Object { "$($_.Papel)" -eq "audio-joc" }) | Select-Object -First 1
    $pri = @($faixas | Where-Object { "$($_.Papel)" -eq "audio-principal" }) | Select-Object -First 1
    $alvo = $null
    if ((Test-TemEscolha $joc) -and "$($joc.VerboUsuario)" -eq "EXCLUIR") {
        if (-not $pri) { return @("→ [ESCOLHA MANUAL] Todas as Faixas de Áudio Excluídas por Você", "vermelho") }
        $alvo = $pri
    } elseif (Test-TemEscolha $pri) {
        $alvo = $pri
    }
    if (-not (Test-TemEscolha $alvo)) { return $null }
    $cod = Get-CodecCurto $alvo
    switch ("$($alvo.VerboUsuario)") {
        "MANTER"    { return @("→ [ESCOLHA MANUAL] $cod Mantido a Pedido - Conversão Desligada", "cinza") }
        "EXCLUIR"   { return @("→ [ESCOLHA MANUAL] $cod Excluído a Pedido", "vermelho") }
        "CONVERTER" { return @("→ [ESCOLHA MANUAL] $cod → $(Get-DestinoConversao $alvo) a Pedido", "verde") }
    }
    return $null
}
function Get-DiagLegendaComEscolha($v) {
    if ("$($v.Modo)" -ne "Manual") { return $null }
    $leg = @(@($v.Faixas) | Where-Object { "$($_.Papel)" -eq "leg-ptbr" }) | Select-Object -First 1
    if (-not (Test-TemEscolha $leg)) { return $null }
    $cod = Get-CodecCurto $leg
    switch ("$($leg.VerboUsuario)") {
        "MANTER"    { return @("→ [ESCOLHA MANUAL] $cod Mantida a Pedido - Conversão Desligada", "cinza") }
        "EXCLUIR"   { return @("→ [ESCOLHA MANUAL] Sem Legenda PT-BR no Arquivo Final", "vermelho") }
        "CONVERTER" { return @("→ [ESCOLHA MANUAL] $cod → .SRT a Pedido", "verde") }
    }
    return $null
}

# m3c25: a coluna AUDIO passa a dizer QUAL faixa vai sair, com canais e
# bitrate - antes dizia so "E-AC-3[ATMOS] OK", que trata igual uma JOC 7.1
# 1152k e uma 5.1 640k. O caso real que expos isso foi o The Last of Us:
# ele traz uma JOC 5.1 640k pronta, o motor reaproveita (regra certa: nao
# reconverter o que existe) e por isso NAO chama o DeeZy, que faria 7.1 1152k
# a partir do TrueHD Atmos que esta no mesmo arquivo. Confirmado no arquivo
# convertido: saiu 6ch 640 kbps. A tela dizia "OK" e escondia a perda.
# BITRATE: nao leio do arquivo - calculo por bytes da faixa / duracao, que a
# GUI ja tem de graca. Da 1148 onde o real e 1152 (GB vs GiB + overhead do
# container), entao encaixo na escala fechada do E-AC-3 quando cai perto. Se
# nao cair perto de nenhum degrau, mostro o numero calculado com "~" - nesse
# caso o erro e meu, e prefiro admitir a inventar precisao que nao tenho.
$script:EscalaEac3 = @(192, 224, 256, 320, 384, 448, 512, 640, 768, 896, 1024, 1152, 1280, 1536)
function Get-CanaisTexto([int]$Canais) {
    switch ($Canais) {
        8       { return "7.1" }
        6       { return "5.1" }
        2       { return "2.0" }
        1       { return "1.0" }
        default { if ($Canais -gt 0) { return "${Canais}ch" } else { return "" } }
    }
}
function Get-BitrateTexto([double]$Bytes, [double]$DurSeg) {
    if ($Bytes -le 0 -or $DurSeg -le 0) { return "" }
    $kbps = ($Bytes * 8.0) / $DurSeg / 1000.0
    foreach ($degrau in $script:EscalaEac3) {
        if ([Math]::Abs($kbps - $degrau) -le ($degrau * 0.05)) { return "${degrau}k" }
    }
    return ("~{0:N0}k" -f $kbps)
}
function Get-AudioDetalhe([double]$Bytes, [int]$Canais, [double]$DurSeg) {
    $partes = @()
    $c = Get-CanaisTexto $Canais
    if ($c -ne "") { $partes += $c }
    $b = Get-BitrateTexto $Bytes $DurSeg
    if ($b -ne "") { $partes += $b }
    if ($partes.Count -eq 0) { return "" }
    return " " + ($partes -join " ")
}
# A JOC reaproveitada e PIOR que a alternativa? So faz sentido perguntar isso
# quando o principal e TrueHD, porque e o unico caso em que o DeeZy entraria
# (1152k, mantendo os canais do TrueHD). Se o principal e DTS, a alternativa
# seria ffmpeg a 640k - ai uma JOC de 640k nao perde nada.
function Test-JocInferior($v) {
    if ("$($v.AudioModo)" -ne "joc" -or -not $v.PrincipalTrueHD) { return $false }
    if ([int]$v.JocCanais -gt 0 -and [int]$v.PrincipalCanais -gt 0 -and
        [int]$v.JocCanais -lt [int]$v.PrincipalCanais) { return $true }
    if ([double]$v.JocBytes -gt 0 -and [double]$v.DurSeg -gt 0) {
        $kbps = ([double]$v.JocBytes * 8.0) / [double]$v.DurSeg / 1000.0
        if ($kbps -lt (1152 * 0.95)) { return $true }
    }
    return $false
}
function Get-ColunaAudioReal($v) {
    # Enriquece o texto do motor com os numeros reais da faixa que vai sair.
    # Se faltar dado bruto (arquivo sem audio, leitura com erro), devolve o
    # texto do motor intacto - nunca fica pior que antes.
    switch ("$($v.AudioModo)") {
        "joc" {
            $det = Get-AudioDetalhe $v.JocBytes $v.JocCanais $v.DurSeg
            if ($det -eq "") { return $v.ColAudio }
            if (Test-JocInferior $v) { return "E-AC-3[ATMOS]$det" }   # sem "OK": nao esta ok
            return "E-AC-3[ATMOS]$det OK"
        }
        # 15.1a: canais+bitrate em TODOS os casos. Eu tinha tirado das conversoes
        # pra economizar largura, e isso criou uma incoerencia que o Diego viu na
        # hora: um video mostrando "7.1 1152k" e o de baixo so "DTS → E-AC-3".
        # Ou todos mostram ou nenhum mostra - meio-termo aqui e so confusao.
        # A largura deixou de ser desculpa: a coluna NOME estava inchando por um
        # defeito (Width virando Auto), nao por falta de espaco de verdade.
        "truehd"    { return "TrueHD → E-AC-3[ATMOS] $(Get-CanaisTexto ([int]$v.PrincipalCanais)) 1152k" }
        "dts"       { return "DTS → E-AC-3 $(Get-CanaisTexto ([int]$v.PrincipalCanais)) 640k" }
        "compativel" {
            $det = Get-AudioDetalhe $v.JocBytes $v.JocCanais $v.DurSeg
            if ($det -eq "") { return $v.ColAudio }
            return ("{0}{1} OK" -f ($v.ColAudio -replace " OK$", ""), $det)
        }
        # 16.8: faixa pronta reaproveitada que NAO e Atmos (ex: um AC-3 no
        # mesmo idioma da principal). Mesmo tratamento de "compativel": o
        # numero vem da faixa que vai SAIR, e o nome do codec vem escrito.
        "prontaext" {
            $det = Get-AudioDetalhe $v.JocBytes $v.JocCanais $v.DurSeg
            if ($det -eq "") { return $v.ColAudio }
            return ("{0}{1} OK" -f ($v.ColAudio -replace " OK$", ""), $det)
        }
        default { return $v.ColAudio }
    }
}

function Get-CorColuna([string]$Texto, [bool]$Ignorado) {
    # A cor vem do que a PROPRIA coluna diz. Verde so onde havera trabalho.
    if ($Ignorado) { return $Cores.dim2 }
    # 15.1d: "X Mantido" voltou pro CINZA. Eu tinha posto violeta pra marcar
    # "escolha do usuario", mas violeta ja e o selo de Manual na coluna
    # SITUACAO - repetir aqui nao acrescentava nada e ainda dava cor forte pra
    # uma linha em que NADA sera feito. A diferenca entre "X OK" (veredito do
    # motor) e "X Mantido" (escolha dele) ja esta na PALAVRA; a cor fica pra
    # separar quem tem trabalho de quem nao tem, que e o que ela faz no resto
    # da tela. Excluido continua vermelho: ali a faixa some do arquivo.
    if ($Texto -like "* Mantido")  { return $Cores.dim }
    if ($Texto -like "* Excluído") { return $Cores.err }
    if ($Texto -match "→")   { return $Cores.okdim }
    if ($Texto -eq "Não Lido")  { return $Cores.err }
    if ($Texto -like "Sem *")   { return $Cores.warn }
    return $Cores.dim
}

function Fill-Fila([string]$Fase) {
    # $Fase: inicial | rodando | pausado | fim
    #
    # HIERARQUIA VISUAL (tres niveis, sempre presentes):
    #   DESTAQUE  branco puro + SemiBold  -> o video que importa agora
    #   NORMAL    cinza claro, peso normal -> os demais da fila
    #   APAGADO   cinza escuro             -> ja concluido ou ignorado
    $Destaque = @{ Cor = "#FFFFFF";  Peso = "SemiBold" }
    $Normal   = @{ Cor = $Cores.txt; Peso = "Normal"   }
    $Apagado  = @{ Cor = $Cores.dim; Peso = "Normal"   }

    # Guardar a selecao: Clear() zera o SelectedIndex e o painel de
    # diagnostico apagaria sem o usuario ter pedido nada.
    $selAntes = $UI.lstFila.SelectedIndex
    $script:LinhasFila.Clear()
    $primeiroAtivo = $true
    for ($i = 0; $i -lt $script:Videos.Count; $i++) {
        $v = $script:Videos[$i]

        if ($v.Ignorar) {
            # Ja existe na saida, ou nao ha nada a fazer neste arquivo.
            # O diagnostico REAL continua visivel; o cinza e a coluna
            # Situacao e que dizem que este arquivo nao sera processado.
            # 15.1a: o motivo tem um TEXTO DE TELA proprio, curto e objetivo.
            # "Já Existe na Saída" era longo e burocratico, e saía em amarelo de
            # aviso - mas um arquivo ja convertido nao e alerta nenhum, e o
            # amarelo ja carrega significado demais nesta coluna. Agora:
            #   ja convertido  -> cinza claro, SEM triangulo (so informa)
            #   nada a fazer   -> amarelo com triangulo (voce PODE querer forcar)
            #   erro           -> vermelho (precisa de atencao)
            $rotulo = switch ("$($v.MotivoIgnorar)") {
                "Já Existe na Saída" { "Já Convertido" }
                "Erro na Leitura"    { "$($Sim.Err) Não Foi Possível Ler" }
                default              { "$($Sim.Warn) $($v.MotivoIgnorar)" }
            }
            $corRotulo = switch ("$($v.MotivoIgnorar)") {
                "Já Existe na Saída" { $Cores.dim2 }
                "Erro na Leitura"    { $Cores.err }
                default              { $Cores.warn }
            }
            [void]$script:LinhasFila.Add((New-LinhaFila $v.Nome $v.TamanhoTxt `
                $v.ColDV $v.ColAudio $v.ColLegenda `
                $rotulo `
                $Cores.dim2 $Cores.dim2 $Cores.dim2 $Cores.dim2 $corRotulo "Normal" `
                $i $false $false))
            continue
        }

        $est = $Normal
        $sit = "Na Fila"; $corSit = $Cores.txt
        <#  16.38: DÁ PRA VER QUAL VÍDEO ESTÁ CONVERTENDO, OLHANDO A LISTA.
            Com a fila rodando, a coluna SITUAÇÃO dizia "Na Fila" em TODAS as
            linhas - inclusive na que estava sendo convertida naquele exato
            momento. A única forma de saber qual era estava lá embaixo, no
            rodapé, no nome escrito por extenso. Com 2 ou 3 arquivos de nome
            parecido isso é adivinhação.
            Agora a linha que o motor anunciou ("ARQUIVO n/N") fica marcada,
            em destaque e com a etapa em que ela está. As já terminadas
            recebem visto. O "Próximo a Converter" continua valendo só antes
            de começar - depois disso o que importa é o que está acontecendo.
        #>
        <#  16.60: A LINHA FICAVA PRESA EM "CONVERTENDO - Diagnostico".
            A condicao era "$Estado.Atual -ne 'parado'", que e verdadeira
            tambem em INICIAL e em FIM. Como $Motor.VideoNome e $Motor.Fase
            continuavam preenchidos da rodada anterior, ao voltar para a tela
            inicial (Nova Conversao, ou depois de um erro/cancelamento) a
            linha seguia anunciando "Convertendo - Diagnostico" para um
            arquivo que nao estava sendo convertido por ninguem.
            Visto pelo Diego em 27/08 01h05: o Troy falhou por falta de
            espaco, ele voltou para a tela inicial e a situacao continuou
            "Convertendo"; so sumiu quando ele TROCOU DE PASTA (o que recria
            a lista do zero).
            "Esta linha esta convertendo AGORA" so pode ser verdade enquanto
            existe conversao acontecendo. Sao dois estados, e agora e isso que
            esta escrito. O Set-Estado tambem limpa VideoNome/Fase ao sair de
            rodando - as duas pontas, porque so a condicao ja bastaria mas
            deixaria dado velho vivo para o proximo defeito parecido. #>
        $ehOAtual = ($Estado.Atual -in @("rodando","pausado") -and "$($Motor.VideoNome)" -ne "" -and "$($v.Nome)" -eq "$($Motor.VideoNome)")
        if ($ehOAtual) {
            $est = $Destaque
            # 16.45: mesma numeracao do rodape - posicao no plano deste
            # arquivo. Duas partes da tela nao podem contar etapas de jeitos
            # diferentes.
            $iEtF  = [math]::Max(0, [math]::Min($Cfg.Etapas.Count - 1, $Motor.EtapaIdx))
            $posF  = Get-PosicaoNoPlano $iEtF
            $totF  = @(Get-PlanoDoVideo).Count
            $qual = if ($Motor.Fase) { "$($Motor.Fase)" }
                    elseif ($posF -gt 0) { "Etapa {0}/{1}" -f $posF, $totF }
                    else { "Etapa {0}/{1}" -f ($iEtF + 1), $Cfg.Etapas.Count }
            <#  16.45: "Convertendo" saiu do violeta e foi para o ciano.
                O violeta e a cor da MARCA - ele pinta os rotulos, a seta dos
                paineis, o selo Manual e a linha selecionada. Usar o mesmo
                tom para dizer "esta rodando agora" e pedir que a mesma tinta
                signifique duas coisas na mesma tela.
                Verde nao serve: verde ja e "Convertido". Ambar ja e
                "Pausado", vermelho ja e erro. Sobra o ciano - e ele nao e
                escolha por eliminacao, e a convencao de "em execucao" em
                praticamente todo painel de build/tarefa (o azul do "running"
                contra o verde do "passed"). #>
            if ($Estado.Atual -eq "pausado") { $sit = "$($Sim.Pausa) Pausado · $qual"; $corSit = $Cores.warn }
            else                             { $sit = "$($Sim.Atual) Convertendo · $qual"; $corSit = $Cores.emCurso }
            $primeiroAtivo = $false
        } elseif ("$($v.MotivoIgnorar)" -eq "Nada a Converter") {
            # m3c15: aviso, nao trava - o video continua com checkbox normal,
            # so nao string como "proximo a converter" (isso e so pra quem
            # tem trabalho de verdade, ver o proximo bloco).
            $sit = "$($Sim.Warn) Nada a Converter"; $corSit = $Cores.warn
        } elseif ($Estado.Atual -ne "inicial" -and $Motor.VideoTotal -gt 0 -and (Test-JaConvertido $v)) {
            $sit = "$($Sim.Ok) Convertido"; $corSit = $Cores.okdim
        } elseif ($primeiroAtivo -and $Fase -eq "inicial") {
            $est = $Destaque
            $sit = "$($Sim.Atual) Proximo a Converter"; $corSit = $Cores.okdim
            $primeiroAtivo = $false
        }
        # m3c-b: selo de modo. So aparece pro caso fora do padrao (Manual) -
        # o Automatico e o comportamento default, nao precisa gritar que
        # esta "normal" (HANDOFF 7.1/7.5).
        # m3c26: o selo "· Manual" (e o violeta) so aparece quando existe uma
        # escolha manual EFETIVA - pelo menos uma faixa com VerboUsuario
        # gravado. So trocar o modo pra Manual nao muda resultado nenhum: apenas
        # LIBERA a edicao. Marcar a linha antes disso dizia "tem customizacao
        # aqui" quando a saida seria identica ao automatico, que e exatamente a
        # confusao que o Diego apontou no Lara Croft. Mesma regra do resto do
        # projeto: destaque so onde existe diferenca real.
        # (VerboUsuario identico ao VerboAuto e limpado na origem, no TrocaVerbo,
        # entao ter VerboUsuario ja significa "difere do automatico".)
        $temEscolhaManual = ($v.Modo -eq "Manual") -and
            (@(@($v.Faixas) | Where-Object { $null -ne $_.VerboUsuario -and -not (Test-VerboBloqueado $_) }).Count -gt 0)
        # 16.16: o selo virou um campo proprio. A frase da situacao guarda a
        # cor dela (verde do "proximo", ambar do "nada a converter") e o selo
        # violeta fica ao lado, em vez de repintar tudo.
        $seloManual = ""
        $corSelo    = "Transparent"
        if ($temEscolhaManual) { $seloManual = "  ·  Manual"; $corSelo = $Cores.marca }
        # m3c19: DV nao entra aqui - nao existe verbo manual pra faixa de video
        # (ela e sempre MANTER/SEM RECODIFICAR), a conversao de perfil e uma
        # etapa do motor, nao uma escolha de faixa. Audio e legenda sim.
        # m3c25: o texto do audio agora carrega canais e bitrate reais.
        $audioReal = Get-ColunaAudioReal $v
        $colAudio  = Get-ColunaAudioComEscolha $v $audioReal
        $colLeg    = Get-ColunaLegendaComEscolha $v $v.ColLegenda
        # O aviso de JOC inferior vale so enquanto o automatico manda. Se ele
        # trocou o verbo no Manual, quem decide e a escolha dele.
        $avisoAudio = (Test-JocInferior $v) -and ($colAudio -eq $audioReal)
        $chipDV     = if ($v.ColDV -match "→") { Get-ChipVerde } else { Get-ChipVazio }
        $chipAudio  = if ($avisoAudio)         { Get-ChipAmbar }
                      elseif ($colAudio -match "→") { Get-ChipVerde }
                      else { Get-ChipVazio }
        $corAudio   = if ($avisoAudio) { $Cores.warn } else { Get-CorColuna $colAudio $false }
        # Mesma regra do DV e do audio: chip so onde ha seta (conversao real).
        $chipLeg    = if ($colLeg -match "→") { Get-ChipVerde } else { Get-ChipVazio }
        [void]$script:LinhasFila.Add((New-LinhaFila $v.Nome $v.TamanhoTxt $v.ColDV $colAudio $colLeg `
            $sit $est.Cor `
            (Get-CorColuna $v.ColDV $false) `
            $corAudio `
            (Get-CorColuna $colLeg $false) `
            $corSit $est.Peso `
            $i ([bool]$v.Marcado) $true `
            $chipDV.Fundo $chipDV.Borda $chipAudio.Fundo $chipAudio.Borda `
            $chipLeg.Fundo $chipLeg.Borda $seloManual $corSelo))
    }
    # Prova no log: quantos videos existem e quantas linhas foram parar na
    # tela. Se esses dois numeros divergirem, o defeito e aqui e nao no WPF.
    if ($selAntes -ge 0 -and $selAntes -lt $script:LinhasFila.Count) {
        $UI.lstFila.SelectedIndex = $selAntes
    } elseif ($script:LinhasFila.Count -gt 0 -and $UI.lstFila.SelectedIndex -lt 0) {
        $UI.lstFila.SelectedIndex = 0
    }
    Escrever-Log ("FILA: {0} video(s) na lista -> {1} linha(s) na tela" -f `
        $script:Videos.Count, $script:LinhasFila.Count) "FILA"
}

# ---- Diagnostico do video selecionado --------------------------------------
function Update-JaExiste {
    # Reavalia so a marca "Ja Existe na Saida" - sem tocar no diagnostico,
    # que e caro (ffprobe + mkvmerge + MediaInfo por arquivo).
    $temSaida = $Cfg.Saida -and (Test-Path -LiteralPath $Cfg.Saida)
    foreach ($v in $script:Videos) {
        if ($v.MotivoIgnorar -eq "Já Existe na Saída") { $v.Ignorar = $false; $v.MotivoIgnorar = "" }
        if ($v.Ignorar) { continue }   # ignorado por outro motivo: nao mexer
        if ($temSaida -and (Test-Path -LiteralPath (Join-Path $Cfg.Saida $v.Arquivo))) {
            $v.Ignorar = $true; $v.MotivoIgnorar = "Já Existe na Saída"
            continue
        }
        if (-not $v.DVprecisa -and -not $v.AUprecisa -and -not $v.LGprecisa) {
            $v.MotivoIgnorar = "Nada a Converter"
        }
    }
}

function Test-PastasIguais {
    # Origem = saida faria o arquivo convertido sobrescrever o original.
    $mesma = $false
    try {
        $a = [System.IO.Path]::GetFullPath($Cfg.Origem).TrimEnd('\')
        $b = [System.IO.Path]::GetFullPath($Cfg.Saida).TrimEnd('\')
        $mesma = ($a -eq $b)
    } catch { $mesma = $false }
    if ($mesma) {
        $UI.lblDiscoMsg.Text = "$($Sim.Err) Pasta de Saída é a Mesma da Origem - o Arquivo Convertido Sobrescreveria o Original"
        $UI.lblDiscoMsg.Foreground = Pincel $Cores.err
        $UI.btnIniciar.IsEnabled = $false
        $Janela.Title = "$NOME_APP  ·  Origem e Saída São a Mesma Pasta"
        Escrever-Log "AVISO: pasta de origem e de saida sao a mesma - Iniciar bloqueado" "AVISO"
    } else {
        # Desfazer o aviso: sem isto o titulo e o botao ficavam presos no
        # estado antigo depois de o usuario arrumar as pastas.
        <#  16.44: ESTA LINHA DESFAZIA A DECISAO DE Update-Selecao.
            Update-Selecao decide o botao por MARCADOS (checkbox + nao
            ignorado + estado inicial) e, tres linhas depois, chamava esta
            funcao - que reescrevia o botao por ATIVOS (so "nao ignorado").
            Resultado: "Desmarcar Todos" deixava o botao ligado. Clicando,
            o lote saia vazio e o erro que aparecia era "Nenhum video da fila
            existe mais na pasta de origem - clique em Atualizar" - com os
            arquivos todos no lugar. A mensagem culpava a pasta pelo que era
            falta de selecao.
            Aqui so se DESFAZ o travamento por pastas iguais; quem decide o
            botao continua sendo Update-Selecao. #>
        $marcadosOk = @(Get-Marcados).Count
        $UI.btnIniciar.IsEnabled = ($marcadosOk -gt 0) -and ($Estado.Atual -eq "inicial")
        if ($Estado.Atual -eq "inicial") {
            $Janela.Title = "$NOME_APP  ·  Pronto para Converter - $ativos Vídeo(s) na Fila"
        }
    }
    return $mesma
}

$script:LinhasFaixas = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$script:AbaAtual = "fila"

function New-LinhaFaixa {
    param($Id, $Tipo, $Codec, $Idioma, $NomeFaixa, $TamanhoFx, $MarcasFx,
          $CorTipo, $CorNome, $CorIdioma, $CorMarcas, $CorDim, $Peso,
          $Verbo = "", $DetalheVerbo = "", $CorVerbo = $null, $PesoVerbo = "Normal",
          $IdxFaixa = -1, $Opcoes = $null, [bool]$Editavel = $false, [bool]$ComboVisivel = $false,
          [string]$Padrao = "")
    if (-not $CorVerbo) { $CorVerbo = $Cores.dim2 }
    if (-not $Opcoes) { $Opcoes = @($Verbo) }
    [PSCustomObject]@{
        Id = $Id; Tipo = $Tipo; Codec = $Codec; Idioma = $Idioma
        NomeFaixa = $NomeFaixa; TamanhoFx = $TamanhoFx; MarcasFx = $MarcasFx
        CorTipo = $CorTipo; CorNome = $CorNome; CorIdioma = $CorIdioma
        CorMarcas = $CorMarcas; CorDim = $CorDim; Peso = $Peso
        Verbo = $Verbo; DetalheVerbo = $DetalheVerbo
        CorVerbo = $CorVerbo; PesoVerbo = $PesoVerbo
        IdxFaixa = $IdxFaixa; Opcoes = $Opcoes; Editavel = $Editavel
        ComboVisivel = $ComboVisivel; ComboOculto = (-not $ComboVisivel)
        Padrao = $Padrao
    }
}

# m3c: cor de cada verbo. Tres cores CLARAMENTE distintas e todas legiveis no
# painel escuro - a coluna ACAO e o ponto da tela, nao pode ter verbo que
# "some". Escolha:
#   Manter    -> foco  (#F1EFE8) branco quente: a faixa fica como esta
#   Converter -> ok    (#16C60C) verdao: e o trabalho acontecendo
#   Excluir   -> err   (#E24B4A vermelho): sai do arquivo final
# (Ate a m3c6 Manter usava txt e Excluir usava dim - os dois ficaram ilegiveis
# dentro do dropdown, testado na maquina real.)
# DECISAO REVERTIDA NA m3c8: a m3c7 tinha fechado Excluir em LARANJA de
# proposito ("decisao intencional, nao erro"). Testado na maquina real, o
# Diego pediu vermelho mesmo - fica friccao visual maior no que sai do
# arquivo, que e o resultado mais dificil de reverter depois de convertido.
function Cor-Verbo([string]$Verbo) {
    switch ($Verbo) {
        "CONVERTER" { $Cores.ok }
        "MANTER"    { $Cores.foco }
        "EXCLUIR"   { $Cores.err }
        default     { $Cores.dim2 }
    }
}

# m3c-b: regras dos 3 verbos no modo Manual.
#
# Trava (nunca cicla, sempre Manter): faixa de VIDEO. E regra do proprio
# motor - COMO_USAR.txt etapa 6: "Vídeo e capítulos são sempre mantidos
# intactos". Capitulos/Anexos nem entram aqui: sao linhas sinteticas, sem
# Trava (nunca fica editavel, sempre Manter): faixa de VIDEO. E regra do
# proprio motor - COMO_USAR.txt etapa 6: "Vídeo e capítulos são sempre
# mantidos intactos". Capitulos/Anexos nem entram aqui: sao linhas sinteticas,
# sem $f real por tras (IdxFaixa = -1), entao nunca ganham dropdown.
#
# Faixa de audio PRINCIPAL: so oferece Manter/Converter no dropdown, NUNCA
# Excluir - o motor nunca descarta a principal (modo seguro), entao a UI nao
# pode oferecer uma opcao que o motor nunca executaria.
function Test-VerboBloqueado($f) { return ($f.Tipo -eq "video") }
function Get-OpcoesVerbo($f) {
    if ($f.Papel -eq "audio-principal") { return @("MANTER", "CONVERTER") }
    return @("MANTER", "CONVERTER", "EXCLUIR")
}

function Add-CabecalhoGrupo([string]$Texto, [string]$Extra) {
    [void]$script:LinhasFaixas.Add((New-LinhaFaixa "" $Texto "" "" $Extra "" "" `
        $Cores.marca $Cores.dim2 $Cores.dim2 $Cores.dim2 $Cores.dim2 "SemiBold"))
}

# m3c13: estimativa de tamanho da SAIDA (HANDOFF 7.5/7.10 item 2). So temos
# bytes reais de ORIGEM por faixa - pra Converter, a unica estimativa honesta
# possivel e bitrate-alvo x duracao do video, usando os MESMOS numeros que ja
# aparecem no texto de diagnostico (DeeZy 1152 kbps p/ TrueHD, ffmpeg 640
# kbps p/ DTS). Fora isso (outro codec de audio raro, ou uma faixa "extra"
# convertida manualmente sem ser TrueHD/DTS) nao da pra estimar direito -
# assume o tamanho original mesmo, e melhor errar pra menos otimista.
function Get-TamanhoEstimadoFaixa($f, $v) {
    if ($f.Tipo -eq "audio" -and $v.DurSeg -gt 0) {
        $kbps = if ("$($f.Codec)" -match "TrueHD") { 1152 }
                elseif ("$($f.Codec)" -match "DTS") { 640 }
                else { $null }
        if ($kbps) { return ($kbps * 1000.0 / 8.0) * $v.DurSeg }
    }
    if ($f.Tipo -eq "subtitles") {
        return 200KB   # OCR PGS -> SRT: texto puro, poucas centenas de KB no total
    }
    return [double]$f.Bytes
}
function Get-TamanhoEstimadoVideo($v) {
    $total = 0.0
    $manual = ($v.Modo -eq "Manual")
    foreach ($f in @($v.Faixas)) {
        if (-not $f.Relevante) { continue }   # nao usada pelo motor, nao entra na saida de qualquer jeito
        if ($f.Tipo -eq "video") { $total += [double]$f.Bytes; continue }   # video nunca recodifica
        $bloq = Test-VerboBloqueado $f
        $usaManual = ($manual -and -not $bloq -and $null -ne $f.VerboUsuario)
        $vb = if ($usaManual) { "$($f.VerboUsuario)" } else { "$($f.VerboAuto)" }
        switch ($vb) {
            "EXCLUIR"   { }   # nao entra na soma
            "CONVERTER" {
                # 16.9: CONVERTER audio no motor NAO substitui a faixa - ele
                # GERA UMA NOVA e mantem a original junto ("Far Field 5.1
                # Surround Mix + E-AC-3 (Novo)" no log da etapa 6/7). A conta
                # somava so a faixa nova, entao a estimativa saia sempre MENOR
                # que o arquivo real - e o erro era exatamente o tamanho do
                # audio original: Troia previu 79,26 GB e saiu 81,74 (a DTS
                # esquecida pesa 2,57); Fallout errou 1,23 com o TrueHD. Erra
                # sempre pra MENOS, e e esse numero que alimenta o semaforo de
                # disco - ou seja, errava na direcao de dizer "cabe".
                # Legenda continua somando so a nova: ali a PGS original SAI
                # mesmo do arquivo final, so o .srt fica.
                $total += Get-TamanhoEstimadoFaixa $f $v
                if ($f.Tipo -eq "audio") { $total += [double]$f.Bytes }
            }
            default     { $total += [double]$f.Bytes }   # MANTER
        }
    }
    return $total
}

# m3c21: coluna IDIOMA no padrao BCP-47, o mesmo que MediaInfo e mkvmerge
# usam: "pt-BR", "pt-PT", "en". O que vem do arquivo e o campo IETF cru, e
# muita release grava so "pt" generico, sem regiao - era o caso do Bloodsport
# (mostrava "pt" com o nome da faixa dizendo "Portugues (Brasil)") enquanto o
# A Knight mostrava "pt-BR", os dois sendo legenda brasileira.
# Quando a regiao NAO vem no arquivo, so completo se der pra saber sem chutar:
#   1. e a faixa que o MOTOR escolheu como pt-BR (Papel leg-ptbr) -> pt-BR
#   2. o nome da faixa diz Brasil/Brazil -> pt-BR ; diz Portugal -> pt-PT
# Fora desses casos fica o codigo cru: melhor mostrar "pt" do que inventar
# uma regiao que o arquivo nao afirma.
$script:MapaIdioma = @{ eng="en"; por="pt"; spa="es"; esl="es"; fra="fr"; fre="fr"
                        deu="de"; ger="de"; ita="it"; jpn="ja"; kor="ko"; rus="ru"
                        zho="zh"; chi="zh"; nld="nl"; dut="nl"; pol="pl"; swe="sv"
                        dan="da"; nor="no"; fin="fi"; tur="tr"; ara="ar"; heb="he" }
function Get-IdiomaExibicao($f) {
    $cod = "$($f.Ietf)"
    if ($cod -eq "") { $cod = "$($f.Lang)" }
    if ($cod -eq "") { return "" }
    $partes = $cod -split '-'
    $lang = $partes[0].ToLower()
    if ($script:MapaIdioma.ContainsKey($lang)) { $lang = $script:MapaIdioma[$lang] }
    if ($partes.Count -gt 1) {
        # Regiao ja veio no arquivo: so normalizo a caixa (pt-br -> pt-BR).
        return ($lang + "-" + (($partes[1..($partes.Count - 1)] -join '-').ToUpper()))
    }
    if ($lang -eq "pt") {
        $nome = "$($f.Nome)"
        if ("$($f.Papel)" -eq "leg-ptbr")     { return "pt-BR" }
        if ($nome -match "(?i)brasil|brazil") { return "pt-BR" }
        if ($nome -match "(?i)portugal")      { return "pt-PT" }
    }
    return $lang
}

# m3c23: SO o botao Modo, sem redesenhar tabela nenhuma.
# A m3c21 chamava Fill-Faixas inteiro de dentro de Update-Selecao pra resolver
# o botao que nao "acordava" - e isso saiu caro: Fill-Faixas refaz a tabela de
# faixas, o pre-scan de PADRAO, a estimativa de tamanho E chama Update-Disco
# (que por sua vez estima o tamanho de TODOS os videos marcados). Rodando isso
# a cada mudanca de selecao - inclusive a cada arquivo lido durante a leitura -
# a thread da janela ficava ocupada e ENGOLIA CLIQUES. Era o "botao para de
# funcionar" que o Diego viu: 86 redesenhos de FAIXAS em 286 linhas de log, e
# os cliques perdidos nem chegavam no handler (por isso nao apareciam no log).
# Trocar de aba ja chama Fill-Faixas (Set-Aba), entao a tabela nunca precisou
# ser refeita aqui - so o botao, que fica visivel nas DUAS abas.
function Update-BotaoModo {
    $idx = $UI.lstFila.SelectedIndex
    if ($idx -lt 0 -or $idx -ge $script:Videos.Count) {
        $UI.btnModoVideo.Visibility = "Collapsed"; return
    }
    $v = $script:Videos[$idx]
    if (@($v.Faixas).Count -eq 0) {
        $UI.btnModoVideo.Visibility = "Collapsed"; return
    }
    $marcado = [bool]$v.Marcado
    $UI.btnModoVideo.Visibility  = "Visible"
    $UI.btnModoVideo.IsEnabled   = $marcado
    # m3c24: quando esta travado o botao passa a DIZER O MOTIVO. Antes so
    # apagava a borda (m3c16) e depois o texto (m3c23), e o Diego leu isso como
    # "o botao morreu" - a confusao de fundo e que a tela tem DUAS nocoes de
    # selecao: a LINHA selecionada (clicar no nome) e o video MARCADO (o
    # checkbox). O botao pertence a linha selecionada mas depende do checkbox
    # DELA - ele estava marcando outros videos e estranhando o botao apagado.
    # Ficou 3 builds procurando bug onde o comportamento estava certo e a
    # explicacao e que faltava.
    $UI.txtModoVideo.Text = if ($marcado) { "Modo: $($v.Modo)" } else { "Marque o vídeo p/ editar" }
    $UI.txtModoVideo.Foreground  = Pincel $(if ($marcado) { $Cores.txt } else { $Cores.dim2 })
    $UI.btnModoVideo.BorderBrush = Pincel $(if (-not $marcado) { $Cores.dim2 }
                                            elseif ($v.Modo -eq "Manual") { $Cores.marca }
                                            else { $Cores.borda })
}

function Fill-Faixas {
    $script:LinhasFaixas.Clear()
    $idx = $UI.lstFila.SelectedIndex
    if ($idx -lt 0 -or $idx -ge $script:Videos.Count) {
        $UI.lblAbaDica.Text = "Selecione um vídeo na aba Fila."
        $UI.btnModoVideo.Visibility = "Collapsed"
        $UI.txtRodapeTamanho.Text = ""
        return
    }
    $v = $script:Videos[$idx]
    $faixas = @($v.Faixas)
    if ($faixas.Count -eq 0) {
        $UI.lblAbaDica.Text = "Este vídeo não pôde ser lido."
        $UI.btnModoVideo.Visibility = "Collapsed"
        $UI.txtRodapeTamanho.Text = ""
        return
    }

    # indice de cada faixa dentro de $v.Faixas, pra achar de volta no clique
    # (a tabela mostra so uma COPIA/filtro das faixas, o clique precisa saber
    # qual posicao mutar no array de verdade)
    $idxPorId = @{}
    for ($k = 0; $k -lt $faixas.Count; $k++) { $idxPorId[[int]$faixas[$k].Id] = $k }
    $manual = ($v.Modo -eq "Manual")

    $grupos = @(
        @{ Chave = "video";     Titulo = "VÍDEO" }
        @{ Chave = "audio";     Titulo = "ÁUDIO" }
        @{ Chave = "subtitles"; Titulo = "LEGENDAS" }
    )
    $padraoLog = [System.Collections.Generic.List[string]]::new()
    foreach ($g in $grupos) {
        $doGrupo = @($faixas | Where-Object { $_.Tipo -eq $g.Chave })
        if ($doGrupo.Count -eq 0) { continue }
        $abertas = @($doGrupo | Where-Object { $_.Relevante })
        $ocultas = $doGrupo.Count - $abertas.Count
        $extra = if ($ocultas -gt 0) { "$($doGrupo.Count) faixas" } else { "" }
        Add-CabecalhoGrupo $g.Titulo $extra

        # m3c17: a faixa PADRAO de audio e legenda precisa olhar o GRUPO
        # inteiro (nao da pra decidir faixa por faixa isolada) - audio-joc
        # concorre com audio-principal pelo posto (se um sair por EXCLUIR,
        # o outro assume, respeitando qualquer escolha manual ja feita);
        # "extra" nunca vira padrao mesmo se mantida. So 2 faixas por video
        # no maximo entram nessa conta, custo desprezivel.
        $idPadraoAudio = $null
        if ($g.Chave -eq "audio") {
            foreach ($papelCand in @("audio-joc","audio-principal")) {
                $fa = @($abertas | Where-Object { $_.Papel -eq $papelCand }) | Select-Object -First 1
                if (-not $fa) { continue }
                $bloqA = Test-VerboBloqueado $fa
                $usaManualA = ($manual -and -not $bloqA -and $null -ne $fa.VerboUsuario)
                $vbA = if ($usaManualA) { "$($fa.VerboUsuario)" } else { "$($fa.VerboAuto)" }
                if ($vbA -ne "EXCLUIR") { $idPadraoAudio = [int]$fa.Id; break }
            }
        }
        $idPadraoLeg = $null
        if ($g.Chave -eq "subtitles") {
            $fa = @($abertas | Where-Object { $_.Papel -eq "leg-ptbr" }) | Select-Object -First 1
            if ($fa) {
                $bloqL = Test-VerboBloqueado $fa
                $usaManualL = ($manual -and -not $bloqL -and $null -ne $fa.VerboUsuario)
                $vbL = if ($usaManualL) { "$($fa.VerboUsuario)" } else { "$($fa.VerboAuto)" }
                if ($vbL -ne "EXCLUIR") { $idPadraoLeg = [int]$fa.Id }
            }
        }
        if ($idPadraoAudio) { $padraoLog.Add("audio id $idPadraoAudio") }
        if ($idPadraoLeg)   { $padraoLog.Add("legenda id $idPadraoLeg") }

        foreach ($f in $abertas) {
            $tam = if ($f.Bytes -gt 0) { Format-GB $f.Bytes } else { "" }
            # O IETF e o que separa pt-BR de pt-PT (o motor acertou por causa
            # dele); por isso ele fica em destaque quando e portugues.
            # m3c21: passa pelo normalizador antes de ir pra tela - a cor
            # tambem, pra uma faixa gravada como "por" nao perder o destaque.
            $idiomaTxt = Get-IdiomaExibicao $f
            $corIdioma = if ($idiomaTxt -like "pt*") { $Cores.warn } else { $Cores.dim }

            $bloq = Test-VerboBloqueado $f
            # No Automatico (ou faixa travada), o que aparece e sempre o do
            # motor. So no Manual, numa faixa destravada, o VerboUsuario (se
            # ja foi escolhido alguma vez) vence.
            $usaManual = ($manual -and -not $bloq -and $null -ne $f.VerboUsuario)
            $vb  = if ($usaManual) { "$($f.VerboUsuario)" } else { "$($f.VerboAuto)" }
            $det = if ($usaManual) { "[ESCOLHA MANUAL]" } else { "$($f.DetalheAuto)" }
            $corVerbo = if ($usaManual) { $Cores.marca } else { (Cor-Verbo $vb) }
            $idxF = if ($idxPorId.ContainsKey([int]$f.Id)) { $idxPorId[[int]$f.Id] } else { -1 }
            # m3c8: so editavel em "inicial". Sem isso o dropdown continuava
            # aceitando clique depois do F1 - Fill-Faixas so roda de novo por
            # causa de troca de aba/pasta/video, nunca por causa do ESTADO
            # mudar sozinho (achado no log real: 3 edicoes de faixa aceitas
            # durante a etapa 6/7 de uma conversao ja rodando). Ver tambem a
            # chamada nova de Fill-Faixas dentro de Set-Estado, que faz a
            # tela reagir no exato instante em que o F1 e apertado.
            # m3c16: editavel tambem exige o video estar MARCADO. Sem isso,
            # um video desmarcado (nao vai entrar na conversao de jeito
            # nenhum) continuava deixando trocar Automatico/Manual e mexer
            # nas faixas - inutil, ja que nada daquilo ia ser aplicado.
            $editavel = ($manual -and -not $bloq -and $Estado.Atual -eq "inicial" -and [bool]$v.Marcado)
            $opcoes = if ($editavel) { Get-OpcoesVerbo $f } else { @($vb) }
            $ehPadrao = ($f.Tipo -eq "video") -or ([int]$f.Id -eq $idPadraoAudio) -or ([int]$f.Id -eq $idPadraoLeg)
            $padraoTxt = if ($ehPadrao) { "PADRÃO" } else { "" }

            [void]$script:LinhasFaixas.Add((New-LinhaFaixa `
                $f.Id "" $f.Codec $idiomaTxt $f.Nome $tam $f.Marcas `
                $Cores.dim2 $Cores.txt $corIdioma $Cores.okdim $Cores.dim "SemiBold" `
                $vb $det $corVerbo $(if ($vb -eq "CONVERTER") { "SemiBold" } else { "Normal" }) `
                $idxF $opcoes $editavel $editavel $padraoTxt))
        }
        if ($ocultas -gt 0) {
            [void]$script:LinhasFaixas.Add((New-LinhaFaixa `
                "" "" "" "" ("… mais $ocultas não usadas pelo motor") "" "" `
                $Cores.dim2 $Cores.dim2 $Cores.dim2 $Cores.dim2 $Cores.dim2 "Normal" `
                "EXCLUIR" "" (Cor-Verbo "EXCLUIR") "Normal"))
        }
    }

    Add-CabecalhoGrupo "EXTRAS" ""
    $temCap = ($v.Capitulos -gt 0)
    [void]$script:LinhasFaixas.Add((New-LinhaFaixa `
        "" "" "Capítulos" "" $(if ($temCap) { "$($v.Capitulos) capítulos" } else { "sem capítulos" }) "" `
        $(if ($temCap) { "Mantidos" } else { "" }) `
        $Cores.dim2 $(if ($temCap) { $Cores.txt } else { $Cores.dim2 }) $Cores.dim $Cores.okdim $Cores.dim "SemiBold" `
        $(if ($temCap) { "MANTER" } else { "" }) "" (Cor-Verbo "MANTER") "Normal"))
    $txtAnexos = if ($v.Anexos -gt 0) { "$($v.Anexos) anexo(s)" } else { "nenhum anexo" }
    [void]$script:LinhasFaixas.Add((New-LinhaFaixa `
        "" "" "Anexos" "" $txtAnexos "" "" `
        $Cores.dim2 $Cores.txt $Cores.dim $Cores.dim2 $Cores.dim "SemiBold"))

    Update-BotaoModo
    $UI.lblAbaDica.Text = "$($v.Nome)"

    $estimado = Get-TamanhoEstimadoVideo $v
    $delta = $estimado - [double]$v.Bytes
    $sinalDelta = if ($delta -gt 0) { "+" } else { "" }
    $UI.txtRodapeTamanho.Text = ("Tamanho Estimado da Saída : ~{0}   ·   Original : {1}   ·   Δ : {2}{3}" -f `
        (Format-GB $estimado), (Format-GB $v.Bytes), $sinalDelta, (Format-GB $delta))

    # m3c14: a estimativa tambem vai pro log - da pra conferir a conta depois,
    # sem depender de print (pedido do Diego).
    # m3c18: idem pra coluna PADRAO - a mudanca de padrao entre faixas
    # concorrentes nao deixava rastro nenhum no log, so na tela (o Diego
    # tentou confirmar pelo log e nao achou nada).
    $txtPadrao = if ($padraoLog.Count -gt 0) { " | padrao: $($padraoLog -join ', ')" } else { "" }
    Escrever-Log ("FAIXAS: {0} faixa(s) no arquivo -> {1} linha(s) na tabela | saida estimada ~{2} (original {3}, delta {4}{5}){6}" -f `
        $faixas.Count, $script:LinhasFaixas.Count, (Format-GB $estimado), (Format-GB $v.Bytes), $sinalDelta, (Format-GB $delta), $txtPadrao) "FAIXAS"

    # O painel de disco depende dos verbos escolhidos aqui, entao tem que ser
    # recalculado junto (so em "inicial" - rodando, o rodape vira progresso).
    if ($Estado.Atual -eq "inicial") { Update-Disco }
}

function Set-Aba([string]$Qual) {
    $script:AbaAtual = $Qual
    $ehFila = ($Qual -eq "fila")
    $UI.lstFila.Visibility   = if ($ehFila) { "Visible" } else { "Collapsed" }
    $UI.lstFaixas.Visibility = if ($ehFila) { "Collapsed" } else { "Visible" }
    $UI.rodapeTamanho.Visibility = if ($ehFila) { "Collapsed" } else { "Visible" }
    $UI.abaFila.Background    = if ($ehFila) { Pincel $Cores.painel2 } else { Pincel "Transparent" }
    $UI.abaFila.BorderBrush   = if ($ehFila) { Pincel $Cores.borda } else { Pincel "Transparent" }
    $UI.txtAbaFila.Foreground = if ($ehFila) { Pincel "#FFFFFF" } else { Pincel $Cores.dim2 }
    $UI.txtAbaFila.FontWeight = if ($ehFila) { "SemiBold" } else { "Normal" }
    $UI.abaFaixas.Background    = if ($ehFila) { Pincel "Transparent" } else { Pincel $Cores.painel2 }
    $UI.abaFaixas.BorderBrush   = if ($ehFila) { Pincel "Transparent" } else { Pincel $Cores.borda }
    $UI.txtAbaFaixas.Foreground = if ($ehFila) { Pincel $Cores.dim2 } else { Pincel "#FFFFFF" }
    $UI.txtAbaFaixas.FontWeight = if ($ehFila) { "Normal" } else { "SemiBold" }
    $UI.btnMarcarTodos.Visibility    = if ($ehFila) { "Visible" } else { "Collapsed" }
    $UI.btnDesmarcarTodos.Visibility = if ($ehFila) { "Visible" } else { "Collapsed" }
    if ($ehFila) {
        $UI.lblAbaDica.Text = ""
    } else {
        Fill-Faixas
    }
}

function Get-Marcados {
    return @($script:Videos | Where-Object { $_.Marcado -and -not $_.Ignorar })
}

function Update-Selecao {
    # Um lugar so decide tudo que depende da selecao.
    $marcados = @(Get-Marcados).Count
    $UI.btnIniciar.IsEnabled = ($marcados -gt 0) -and ($Estado.Atual -eq "inicial")
    Update-CabecalhoFila
    Update-Disco
    if ($Estado.Atual -eq "inicial") {
        $Janela.Title = "$NOME_APP  ·  Pronto para Converter - $marcados Vídeo(s) Selecionado(s)"
    }
    Test-PastasIguais | Out-Null
    # m3c23: SO o botao (era Fill-Faixas inteiro na m3c21, e foi isso que
    # travou a janela). A tabela de faixas nao precisa ser refeita aqui:
    # estando na aba Faixas nao ha como mudar a selecao (o checkbox e os
    # botoes Marcar/Desmarcar so existem na aba Fila), e ao voltar pra aba
    # Faixas o Set-Aba ja chama Fill-Faixas.
    Update-BotaoModo
}

function Set-TodosMarcados([bool]$Valor) {
    if ($Estado.Atual -in @("rodando","pausado")) {
        # Mesma trava dos checkbox individuais: durante a conversao a fila nao muda.
        Escrever-Log "SELECAO bloqueada (conversao em curso): marcar/desmarcar todos" "ACAO"
        return
    }
    foreach ($v in $script:Videos) {
        if (-not $v.Ignorar) { $v.Marcado = $Valor }
    }
    Fill-Fila "inicial"
    Update-Selecao
    Escrever-Log ("SELECAO: {0} todos" -f $(if ($Valor) { "marcar" } else { "desmarcar" })) "ACAO"
}

function Update-CabecalhoFila {
    $tot = $script:Videos.Count
    $ativos = @(Get-Marcados).Count
    $UI.txtAbaFila.Text = if ($tot -eq 0) { "Fila" } else { "Fila ($tot)" }
    $idxSel = $UI.lstFila.SelectedIndex
    $UI.txtAbaFaixas.Text = if ($idxSel -ge 0 -and $idxSel -lt $script:Videos.Count) {
        "Faixas do Vídeo ($(@($script:Videos[$idxSel].Faixas).Count))"
    } else { "Faixas do Vídeo" }
    $UI.colFila.Header = if ($tot -eq 0) { "VÍDEOS NA FILA" }
                         elseif ($ativos -eq $tot) { "VÍDEOS NA FILA ($tot)" }
                         else { "VÍDEOS NA FILA ($ativos de $tot Selecionados)" }
}

function Update-Diagnostico {
    $idx = $UI.lstFila.SelectedIndex
    if ($idx -lt 0 -or $idx -ge $script:Videos.Count) {
        $UI.lblDiagTitulo.Text = "DIAGNÓSTICO:"
        foreach ($c in @("diagDV","diagAu","diagLg","diagDVr","diagAur","diagLgr")) { $UI.$c.Text = "" }
        return
    }
    $v = $script:Videos[$idx]
    # 15.1e: um video que NAO vai ser processado nao pode exibir "[SERÁ
    # CONVERTIDO]" em verde nem aviso em ambar - isso e mentira na tela. O
    # diagnostico continua visivel (e util saber o que o arquivo tem), mas o
    # titulo diz o motivo e TODAS as linhas ficam apagadas, deixando claro que
    # nada daquilo vai acontecer. Era o caso do The Last of Us "Já Convertido"
    # mostrando conversao em verde e perda em amarelo ao mesmo tempo.
    $naoProcessa = [bool]$v.Ignorar
    $UI.lblDiagTitulo.Text = "DIAGNÓSTICO - $($v.Nome)"
    $UI.diagDV.Text  = $v.DiagDVrot
    $UI.diagAu.Text  = $v.DiagAurot
    $UI.diagLg.Text  = $v.DiagLgrot
    if ($naoProcessa) {
        # 15.1f: as tres linhas dizem a MESMA coisa, no mesmo padrao de selo das
        # outras: nada vai acontecer, e por que. Antes eu mostrava o diagnostico
        # normal ("[SERÁ CONVERTIDO]" em verde) num arquivo que nao seria
        # processado - mentira na tela. Apagar as linhas tambem nao servia: a
        # informacao que importa aqui e o MOTIVO, e ele tem que estar escrito,
        # na mesma posicao e no mesmo formato das demais linhas.
        $frase = "→ [NÃO SERÁ FEITO] $($v.MotivoIgnorar)"
        $UI.diagDVr.Text = $frase
        $UI.diagAur.Text = $frase
        $UI.diagLgr.Text = $frase
        foreach ($c in @("diagDVr","diagAur","diagLgr")) { $UI.$c.Foreground = Pincel $Cores.err }
        return
    }
    $UI.diagDVr.Text = $v.DiagDVres
    # m3c25: no diagnostico tem espaco pra explicar, entao aqui vai a frase
    # inteira - na coluna fica so o dado. Cor ambar: nao e erro do motor
    # (reaproveitar e a regra certa), e uma perda que vale ele saber.
    # 16.61: a escolha manual manda. So se nao houver escolha e que valem as
    # frases do motor gravadas na leitura da pasta.
    $escAu = Get-DiagAudioComEscolha $v
    $escLg = Get-DiagLegendaComEscolha $v
    if ($null -ne $escAu) {
        $UI.diagAur.Text = [string]$escAu[0]
    } elseif (Test-JocInferior $v) {
        $detJoc = (Get-AudioDetalhe $v.JocBytes $v.JocCanais $v.DurSeg).Trim()
        $UI.diagAur.Text = "→ [REAPROVEITADO] E-AC-3[ATMOS] $detJoc  ·  DeeZy Faria $(Get-CanaisTexto ([int]$v.PrincipalCanais)) 1152k"
    } else {
        $UI.diagAur.Text = $v.DiagAures
    }
    if ($null -ne $escLg) { $UI.diagLgr.Text = [string]$escLg[0] } else { $UI.diagLgr.Text = $v.DiagLgres }
    # 15.1d: a cor vem do campo gravado junto com a frase, la onde a decisao
    # foi tomada - nao e mais DEDUZIDA lendo o texto de volta. Deduzir era
    # fragil: quando a busca nao casava, a linha ficava com a cor padrao do
    # XAML (verde no DV/audio, amarelo na legenda) e aparecia cor sem
    # significado nenhum na tela, que foi o que o Diego viu.
    #   verde    = vai dar trabalho  [SERÁ CONVERTIDO]
    #   cinza    = nada a fazer      [NÃO NECESSÁRIO] [REAPROVEITADO] [MANTIDO]
    #   vermelho = falta / bloqueia  [SEM ...] [ERRO]
    #   ambar    = unico caso: reaproveitou algo PIOR do que daria pra ter
    function Cor-Diag([string]$Nome) {
        switch ($Nome) {
            "verde"    { return $Cores.ok }
            "vermelho" { return $Cores.err }
            "ambar"    { return $Cores.warn }
            default    { return $Cores.dim }
        }
    }
    $nomeAur = if ($null -ne $escAu) { [string]$escAu[1] } elseif (Test-JocInferior $v) { "ambar" } else { "$($v.DiagAucor)" }
    $nomeLgr = if ($null -ne $escLg) { [string]$escLg[1] } else { "$($v.DiagLgcor)" }
    $UI.diagDVr.Foreground = Pincel (Cor-Diag "$($v.DiagDVcor)")
    $UI.diagAur.Foreground = Pincel (Cor-Diag $nomeAur)
    $UI.diagLgr.Foreground = Pincel (Cor-Diag $nomeLgr)
}

# ---- Espaco em disco real ---------------------------------------------------
function Update-Disco {
    $ativos = @(Get-Marcados)
    if ($ativos.Count -eq 0) {
        $UI.txtDisco.Text = if ($script:Lendo) { "Lendo a pasta..." }
                            elseif (@($script:Videos | Where-Object { -not $_.Ignorar }).Count -gt 0) { "Nenhum vídeo selecionado." }
                            else { "Nenhum vídeo a converter nesta pasta." }
        $UI.barraDisco.Width = 0
        $UI.lblDiscoMsg.Text = ""
        return
    }
    # Regra do motor: pico do LOTE = soma de todos + 2.15x o maior arquivo
    # (o 3.15 do script e o teste por-episodio individual, outra conta).
    # m3c14: a SOMA passou a ser o tamanho ESTIMADO DA SAIDA de cada video, nao
    # mais o tamanho original. Motivo: os originais JA ocupam disco - o que
    # precisa de espaco novo e o que vai ser ESCRITO. Antes o painel somava os
    # originais, entao mudar EXCLUIR/CONVERTER nas faixas nao mexia em nada
    # aqui (o Diego reparou nisso comparando dois prints). O 2.15x do MAIOR
    # continua sobre o tamanho ORIGINAL: essa parte e o rascunho temporario da
    # extracao/remontagem, que trabalha em cima do arquivo de origem.
    <#  16.60: A TELA DIZIA "DA" E O MOTOR DIZIA "FALTAM 4,33 GB".
        Aconteceu com o Troy em 27/08 01h04, com os dois numeros no mesmo
        print: a tela inicial mostrou "Necessario ~268,88 GB / Livre 269,72 GB
        / Sobra ~0,83 GB" (amarelo, "no limite"), o Diego apertou F1 e o motor
        recusou na hora: "Necessario ~274,05 GB (~3.15x o Tamanho do Arquivo),
        Disponivel 269,72 GB. Faltam ~4,33 GB".
        O espaco livre era o MESMO nos dois. O que diferia era a CONTA - e ha
        duas contas no motor, nao uma:
          LOTE (aviso, nunca bloqueia): soma dos arquivos + 2,15x o maior;
          POR EPISODIO (e esta que faz throw e pula o arquivo):
                3,15x o tamanho da ORIGEM  - ou 1,6x quando o video ja esta em
                Profile 8.1 e nem sai do container.
        A tela mostrava so a do LOTE, e ainda por cima com a soma das SAIDAS
        ESTIMADAS no lugar dos originais - a versao mais otimista das tres.
        Ou seja: prometia com a conta frouxa e era barrada pela conta apertada.
        Agora a tela calcula as DUAS e mostra a MAIOR, que e a que decide de
        verdade se a conversao comeca. Numero unico, e o mesmo dos dois lados.
        Regra 12: mensagem que mente e bug - e "cabe" antes de comecar,
        seguido de "faltam 4,33 GB" tres segundos depois, e mentira. #>
    $soma = 0.0; $maior = 0.0; $picoEpisodio = 0.0
    foreach ($v in $ativos) {
        $soma += Get-TamanhoEstimadoVideo $v
        $b = [double]$v.Bytes
        if ($b -gt $maior) { $maior = $b }
        # Mesmo fator do motor: sem conversao de Dolby Vision o video nao sai
        # do container (1,6x); com conversao ele e extraido, convertido e
        # remontado, os tres no disco ao mesmo tempo (3,15x).
        $fator = if ("$($v.ColDV)" -match "→") { 3.15 } else { 1.6 }
        $exigido = $b * $fator
        if ($exigido -gt $picoEpisodio) { $picoEpisodio = $exigido }
    }
    $precisoLote = $soma + (2.15 * $maior)
    $preciso = [math]::Max($precisoLote, $picoEpisodio)

    # A letra vem do drive de ORIGEM, nao de C: fixo.
    $raizDrive = [System.IO.Path]::GetPathRoot($Cfg.Origem)
    $livre = 0
    try {
        $d = New-Object System.IO.DriveInfo ($raizDrive)
        $livre = [double]$d.AvailableFreeSpace
    } catch { $livre = 0 }

    $sobra = $livre - $preciso
    $pct = if ($livre -gt 0) { 100.0 * $preciso / $livre } else { 999 }
    # 16.60: quando quem manda e a exigencia de UM arquivo (e nao a soma do
    # lote), a tela diz isso - senao o numero parece grande sem explicacao.
    $porQue = if ($picoEpisodio -ge $precisoLote) { "  (pico de um arquivo)" } else { "  (pico do lote)" }
    $UI.txtDisco.Text = ("Espaço Necessário Estimado : ~{0}{4}`nEspaço Livre em {1,-11}: {2}`nEspaço Livre Apos Converter: ~{3}" -f `
        (Format-GB $preciso), $raizDrive.TrimEnd('\'), (Format-GB $livre), (Format-GB $sobra), $porQue)
    Set-BarraDisco $pct
}

function Format-GB([double]$Bytes) {
    if ($Bytes -lt 0) { return "-" + ("{0:N2} GB" -f ([math]::Abs($Bytes)/1GB)) }
    return "{0:N2} GB" -f ($Bytes / 1GB)
}

<#  16.40: A FAIXA DE FERRAMENTAS DO TOPO ERA MENTIRA.
    Ate a 16.39 aquela linha no canto direito ("✔ dovi_tool  ✔ PgsToSrt
    ✔ DeeZy 1.3.13") era TEXTO FIXO escrito no XAML. Verde, com visto, nas
    tres, SEMPRE - existissem elas ou nao. Nenhuma linha de codigo olhava pra
    ela. Era a coisa mais visivel da tela durante a conversao e nao media
    nada. Regra fixa deste projeto: mensagem que mente e defeito, e dos
    graves - vale para o log e vale para a tela.
    Agora ela e montada da checagem real, e mostra SEIS: as que decidem se um
    pedaco do trabalho acontece, na ordem em que o pipeline usa cada uma.
        dovi_tool -> DeeZy -> seconv -> PgsToSrt -> Tesseract -> mkvmerge
    ffprobe e MediaInfo ficam so no painel de Ferramentas: o primeiro so le
    metadado (se faltar, o programa nem monta a fila) e o segundo so refina a
    deteccao de Atmos. Nenhum dos dois muda o arquivo final.
    Cor: verde = tem; ambar = opcional que falta (essa parte e pulada);
    vermelho = obrigatoria que falta (nao roda).
#>
function Update-FerramentasTopo {
    if (-not $UI.lblFerrTopo) { return }
    $UI.lblFerrTopo.Inlines.Clear()
    $ordem = @("dovi_tool", "DeeZy", "seconv", "PgsToSrt", "Tesseract", "mkvmerge")
    $primeiro = $true
    foreach ($chave in $ordem) {
        $f = @($script:Ferramentas | Where-Object { "$($_.Chip)" -eq $chave })
        if ($f.Count -eq 0) { continue }
        $f = $f[0]
        if (-not $primeiro) {
            $sep = New-Object System.Windows.Documents.Run
            $sep.Text = "   "
            $UI.lblFerrTopo.Inlines.Add($sep)
        }
        $primeiro = $false
        $obrig = ("$($f.Papel)" -match "(?i)obrigat")
        $marca = if ($f.Ok) { $Sim.Ok } elseif ($obrig) { $Sim.Err } else { $Sim.Skip }
        $cor   = if ($f.Ok) { $Cores.ok } elseif ($obrig) { $Cores.err } else { $Cores.warn }
        $r = New-Object System.Windows.Documents.Run
        $r.Text = "$marca $chave"
        $r.Foreground = Pincel $cor
        $UI.lblFerrTopo.Inlines.Add($r)
    }
}

# ---- Painel de ferramentas real ---------------------------------------------
function Update-Ferramentas {
    $UI.listaFerramentas.Children.Clear()
    foreach ($f in $script:Ferramentas) {
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.FontSize = 13.5; $tb.FontWeight = "SemiBold"; $tb.Margin = "0,0,0,3"
        # 16.38: opcional que falta nao e erro. Antes TUDO que faltava saia
        # em vermelho com "NAO ENCONTRADA", o que fazia o MediaInfo ausente
        # parecer tao grave quanto o dovi_tool ausente - e nao e: sem
        # dovi_tool nao ha conversao, sem MediaInfo a deteccao de Atmos so
        # cai num metodo pior. Obrigatoria ausente = vermelho; opcional
        # ausente = ambar, com a frase dizendo o que deixa de funcionar.
        $ehObrigatoria = ("$($f.Papel)" -match "(?i)obrigat")
        $marca = if ($f.Ok) { $Sim.Ok } elseif ($ehObrigatoria) { $Sim.Err } else { $Sim.Skip }
        $cor   = if ($f.Ok) { $Cores.ok } elseif ($ehObrigatoria) { $Cores.err } else { $Cores.warn }
        $r1 = New-Object System.Windows.Documents.Run
        $r1.Text = "$marca $($f.Rotulo)"; $r1.Foreground = Pincel $cor
        $r2 = New-Object System.Windows.Documents.Run
        $r2.Text = if ($f.Ok) { "  · " + $f.Papel }
                   elseif ($ehObrigatoria) { "  · " + $f.Papel + " - NÃO ENCONTRADA, A CONVERSÃO NÃO RODA" }
                   else { "  · " + $f.Papel + " - não encontrada, esta parte é pulada" }
        $r2.Foreground = Pincel $(if ($f.Ok) { $Cores.dim2 } elseif ($ehObrigatoria) { $Cores.err } else { $Cores.warn })
        $tb.Inlines.Add($r1); $tb.Inlines.Add($r2)
        $UI.listaFerramentas.Children.Add($tb) | Out-Null
    }
}

# ---- Regua das etapas (montada uma vez; so as cores mudam) ----------------
# 16.37: a quantidade vem de $Cfg.Etapas, nao mais do numero 7 escrito a mao
# em quatro lugares diferentes. Mudar a lista de etapas passa a ser mudar UMA
# lista.
$ReguaSegmentos = @()
$ReguaColunas = @()
# 16.45: cada segmento agora tem um FILHO. O segmento e o leito da etapa; o
# filho e o quanto dela ja andou. So o segmento que esta rodando usa o filho -
# nos outros ele fica com largura zero (feito = leito inteiro pintado de
# verde; a fazer = leito apagado e vazio).
$ReguaPreenche = @()
# 16.47: ultimo numero de etapa REALMENTE valido (ver Update-Progresso).
$script:UltimoRotuloEtapa = ""
for ($i = 0; $i -lt $Cfg.Etapas.Count; $i++) {
    $col = New-Object System.Windows.Controls.ColumnDefinition
    $col.Width = New-Object System.Windows.GridLength($Cfg.Pesos[$i], [System.Windows.GridUnitType]::Star)
    $UI.gridEtapas.ColumnDefinitions.Add($col) | Out-Null
    $ReguaColunas += $col
    $seg = New-Object System.Windows.Controls.Border
    $seg.CornerRadius = "2"; $seg.Margin = "0,3,3,3"
    $seg.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Cores.vazio)
    $enc = New-Object System.Windows.Controls.Border
    $enc.CornerRadius = "2"; $enc.Width = 0
    $enc.HorizontalAlignment = "Left"
    $enc.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Cores.emCurso)
    $seg.Child = $enc
    [System.Windows.Controls.Grid]::SetColumn($seg, $i)
    $UI.gridEtapas.Children.Add($seg) | Out-Null
    $ReguaSegmentos += $seg
    $ReguaPreenche += $enc
}

<#  HISTORICO DA REGUA (a mesma tela mudou tres vezes - vale registrar por
    que, senao a quarta repete alguma das duas primeiras):
      16.41 - a largura de cada pedaco era FIXA (@(23,28,10,10,44)), igual pra
              qualquer arquivo. No Se7en a [2/5] e a [3/5] nao tinham nada pra
              fazer e mesmo assim ocupavam 33% da regua, enquanto a [4/5], que
              foi 45% do trabalho real, tinha 9%. Passou a usar os pesos reais
              do arquivo ($script:PesosDoVideoAtual) - e etapa de peso zero
              sumia.
      16.43 - com a etapa sumindo, a regua ficava com dois blocos enquanto o
              texto dizia "5/5": a tela se contradizendo. Trouxe o segmento de
              volta num tom proprio, so pra fechar a conta.
      16.45 - fecha a conta pelo outro lado, que era o certo: quem estava
              errado era o DENOMINADOR. Ver o bloco da Set-Regua logo abaixo.
#>
<#  16.44: "Convertido" era decidido por  $i -lt $Motor.VideoIdx  - e os dois
    numeros vivem em listas DIFERENTES: $i e indice em $script:Videos (todos
    os .mkv da pasta) e VideoIdx e indice em $script:LoteAtual (so os
    marcados). Numa pasta A/B/C com so B e C marcados, quando o motor chegava
    em C a linha do A virava "Convertido" em verde - e o A nunca foi tocado.
    Agora a pergunta e feita no lugar certo: este video esta ANTES do atual
    DENTRO DO LOTE? Quem nao esta no lote nunca responde que sim. #>
function Test-JaConvertido($V) {
    $lote = @($script:LoteAtual)
    if ($lote.Count -eq 0) { return $false }
    $posicao = -1
    for ($k = 0; $k -lt $lote.Count; $k++) {
        if ("$($lote[$k].Nome)" -eq "$($V.Nome)") { $posicao = $k; break }
    }
    if ($posicao -lt 0) { return $false }
    return ($posicao -lt [int]$Motor.VideoIdx)
}

<#  16.45: A ETAPA QUE NAO VAI RODAR SAI DA REGUA *E* SAI DA CONTA.
    Historico honesto deste pedaco de tela, que ja mudou tres vezes:
      16.41 - etapa de peso zero saia da regua (largura 0). Ficaram duas
              barras onde o texto dizia "5/5": tela se contradizendo.
      16.43 - trouxe ela de volta em cinza escuro, so pra fechar a conta.
              Resolveu a contradicao e criou outra: um bloco na tela que
              nao e nada, ocupando espaco pra dizer que nao vai acontecer.
    O Diego chamou o erro pelo nome: "se a etapa nao é feita nao é necessaria
    naquele momento, nao tem o porque ela aparecer ali". Ele esta certo, e o
    que faltava era corrigir a CAUSA em vez de escolher qual sintoma doia
    menos: o problema nunca foi a regua, foi o DENOMINADOR. Chamar de "5/5"
    um arquivo que so tem 3 etapas de trabalho e que estava errado.
    A industria faz assim (GOV.UK progress tracker, Carbon, Polaris): passo
    que nao se aplica ao seu caminho nao aparece nem e contado - a barra
    mostra o SEU processo, nao o catalogo do programa.
    Agora existe UM plano por arquivo:
        etapas com peso > 0  ->  aparecem, na ordem, e sao as unicas contadas
        etapas com peso = 0  ->  nao existem para este arquivo
    A [1/5] (ffprobe+limpeza) e a [5/5] (mkvmerge+verificacao) tem peso fixo
    e nunca somem: todo arquivo passa por elas. Quem pode sumir e DV, audio e
    legenda - exatamente as tres que dependem do que tem dentro do arquivo.
    AUTOCORRECAO: se o motor anunciar uma etapa que a tela julgava pulada
    (diagnostico da janela e do motor discordaram), o peso tipico do $Cfg
    entra no lugar do zero e o plano se refaz sozinho na hora - a tela nunca
    fica com uma etapa rodando fora do proprio mapa. #>
function Get-PesoDaEtapa([int]$i) {
    $lp = @($script:PesosDoVideoAtual)
    if ($lp.Count -ge $Cfg.Etapas.Count -and $i -ge 0 -and $i -lt $lp.Count) { return [double]$lp[$i] }
    if ($i -ge 0 -and $i -lt $Cfg.Pesos.Count) { return [double]$Cfg.Pesos[$i] }
    return 0.0
}

<#  16.68: QUANTOS SEGUNDOS ESTA ETAPA DEVE DEMORAR NESTE ARQUIVO.
    Devolve 0 quando nao ha previsao (arquivo sem lote montado). #>
function Get-SegPrevistoDaEtapa([int]$i) {
    $ls = @($script:SegEtapasDoVideoAtual)
    if ($i -ge 0 -and $i -lt $ls.Count) { return [double]$ls[$i] }
    return 0.0
}

<#  16.68: A FRACAO DA ETAPA - RELOGIO NA FRENTE, FERRAMENTA ATRAS.
    Ate a 16.67 a barra do VIDEO e o tempo restante saiam do % que a
    ferramenta da etapa reportava. Para mkvmerge e ffmpeg esse % anda junto
    com o relogio e serve. Para o DeeZy nao: no Jumanji (01/09) ele marcou
    20% aos 3 min de uma etapa de 27, pulou de 43% para 67% em 25 segundos e
    depois gastou 14 minutos indo de 82% a 99%. A tela acreditou nele e
    escreveu "Tempo Restante: 17 min" quando faltavam 29, e "9 min" quando
    faltavam 15.
    Agora a fracao e a MAIOR entre o que a ferramenta diz e o que o relogio
    diz (decorrido / previsto desta etapa). Dois efeitos:
      - a barra nunca congela: mesmo com a ferramenta muda, o relogio empurra;
      - a barra nunca volta atras nem estoura: para em 99% ate a etapa fechar
        de verdade, porque etapa que passou do previsto nao esta "quase la".
    O tempo restante NAO usa mais esta fracao - ver Update-Rodape. #>
<#  16.73: QUANTO ESTA ETAPA VAI DEMORAR, JA CORRIGIDO PELO QUE ELA MOSTROU.
    Uma so conta, usada pela BARRA e pelo TEMPO - antes eram duas, e elas
    discordavam: no log de 01/09 22h00 a barra do video marcava 100% com a
    etapa 5 em 62%, porque a barra comparava o relogio com o previsto do
    CATALOGO (172s) enquanto a etapa ja ia em 184s e caminhava para 318s.
    Passados 20% da etapa, o que ELA mede manda; antes disso, o catalogo. #>
function Get-PrevistoAjustadoDaEtapa([int]$i, [double]$PctFerramenta, [double]$SegDecorrido) {
    $prev = Get-SegPrevistoDaEtapa $i
    $fr = [math]::Max(0.0, [math]::Min(1.0, $PctFerramenta / 100.0))
    if ($SegDecorrido -le 0) { return $prev }
    if ($fr -ge 0.20) { return ($SegDecorrido / $fr) }
    if ($fr -gt 0.05) {
        $porRitmo = $SegDecorrido / $fr
        if ($porRitmo -gt $prev) { return $porRitmo }
    }
    if ($SegDecorrido -gt $prev) { return $SegDecorrido }   # sem amostra, mas ja estourou
    return $prev
}

function Get-FracaoDaEtapa([int]$i, [double]$PctFerramenta, [double]$SegDecorrido) {
    $f = [math]::Max(0.0, [math]::Min(1.0, $PctFerramenta / 100.0))
    $prev = Get-PrevistoAjustadoDaEtapa $i $PctFerramenta $SegDecorrido
    if ($prev -gt 1 -and $SegDecorrido -gt 0) {
        $fr = $SegDecorrido / $prev
        if ($fr -gt 0.99) { $fr = 0.99 }
        if ($fr -gt $f)   { $f = $fr }
    }
    return [math]::Max(0.0, [math]::Min(1.0, $f))
}

# Indices das etapas que vao rodar neste arquivo, na ordem. E o "plano".
function Get-PlanoDoVideo {
    $plano = @()
    for ($i = 0; $i -lt $Cfg.Etapas.Count; $i++) {
        if ((Get-PesoDaEtapa $i) -gt 0) { $plano += $i }
    }
    # Nenhum peso conhecido ainda (antes do primeiro arquivo): mostra todas.
    # Esta garantia e o que permite o "return" simples logo abaixo.
    if ($plano.Count -eq 0) { for ($i = 0; $i -lt $Cfg.Etapas.Count; $i++) { $plano += $i } }
    <#  ATENCAO - NAO TROQUE POR "return ,$plano".
        A virgula existe pra impedir que o PowerShell DESMONTE uma colecao de
        zero ou um elemento no retorno. So que TODO chamador aqui recebe com
        @(...) - e @( ,@(0,3,4) ) nao desmonta: fica um array de UM elemento,
        que por dentro e o array de verdade. O plano do Se7en (3 etapas) saia
        com Count = 1 e a conta do % dividia por um array, dando NaN na tela.
        Peguei isso simulando os pesos reais do Se7en antes de empacotar.
        Como esta funcao NUNCA devolve vazio (o if acima garante), o retorno
        simples e o certo: com um elemento so, @(...) remonta o array. #>
    return $plano
}

# Posicao da etapa $i DENTRO do plano (1..N). Zero = fora do plano.
function Get-PosicaoNoPlano([int]$i) {
    $plano = @(Get-PlanoDoVideo)
    for ($k = 0; $k -lt $plano.Count; $k++) { if ($plano[$k] -eq $i) { return ($k + 1) } }
    return 0
}

<#  16.47: A AUTOCORRECAO NAO PODE DISPARAR NO ANUNCIO - SO NO TRABALHO.
    Na 16.45 eu chamava isto assim que o motor anunciava a etapa. Parecia
    certo e estava errado, e o log do Lara Croft (19/08 15h23) mostra por que:

        > [1/5] Extraindo Video Puro...      ETAPA 1/5 fechada: 00m 00s
        > [2/5] Convertendo Dolby Vision...  ETAPA 2/5 fechada: 00m 00s
        > [3/5] Conversao de Audio...        ETAPA 3/5 fechada: 00m 00s
        > [4/5] Conversao de Legenda...      04m 59s

    O motor ANUNCIA as cinco etapas sempre - inclusive as que so imprimem
    "nao necessario" e fecham no mesmo segundo. Com a autocorrecao no anuncio,
    a tela reativaria a 2 e a 3 no ato: o Lara Croft comecaria em "1/3", viraria
    "2/4", depois "3/5", com a regua mudando de tamanho tres vezes em dois
    segundos. O conserto viraria o defeito.

    Anunciar nao e trabalhar. A pergunta certa nao e "o motor citou esta
    etapa?" e sim "esta etapa esta MESMO ocupando tempo?". Quatro segundos
    respondem: etapa pulada fecha em zero; etapa de verdade nunca termina
    nisso (a mais rapida do projeto, o dovi_tool, leva mais de um minuto).
    Nao e chute de tolerancia - e a distancia entre 0,0s e 60s.  #>
function Confirmar-EtapaNoPlano([int]$i) {
    if ($i -lt 0 -or $i -ge $Cfg.Etapas.Count) { return }
    $lp = @($script:PesosDoVideoAtual)
    if ($lp.Count -lt $Cfg.Etapas.Count) { return }
    if ([double]$lp[$i] -gt 0) { return }
    $lp[$i] = [double]$Cfg.Pesos[$i]
    $script:PesosDoVideoAtual = $lp
    Escrever-Log ("PLANO: a etapa {0}/{1} rodou apesar de o diagnostico da tela ter dado peso zero - peso tipico ({2}) entrou no lugar e a regua foi refeita" -f `
        ($i + 1), $Cfg.Etapas.Count, $Cfg.Pesos[$i]) "PROVA"
}

function Set-Regua([int]$EtapaAtual, [double]$PctEtapa = 0.0) {
    $plano = @(Get-PlanoDoVideo)
    $somaPesos = 0.0
    foreach ($i in $plano) { $somaPesos += (Get-PesoDaEtapa $i) }
    # Piso de largura: a [1/5] de um arquivo que ja e 8.1 pesa 5 de 887 (o
    # ffprobe, 1 segundo) e viraria um fio invisivel. 4% do total, minimo 12.
    $piso = [math]::Max(12.0, $somaPesos * 0.04)
    for ($i = 0; $i -lt $ReguaSegmentos.Count; $i++) {
        $noPlano = ($plano -contains $i)
        if (-not $noPlano) {
            # Nao e "cinza": e AUSENTE. Coluna de largura zero e segmento
            # escondido - a etapa nao faz parte deste arquivo.
            if ($i -lt $ReguaColunas.Count) {
                $ReguaColunas[$i].Width = New-Object System.Windows.GridLength(0, [System.Windows.GridUnitType]::Pixel)
            }
            $ReguaSegmentos[$i].Visibility = "Collapsed"
            $ReguaPreenche[$i].Width = 0
            continue
        }
        $ReguaSegmentos[$i].Visibility = "Visible"
        $peso = Get-PesoDaEtapa $i
        if ($i -lt $ReguaColunas.Count) {
            $larg = [math]::Max($piso, $peso)
            $ReguaColunas[$i].Width = New-Object System.Windows.GridLength($larg, [System.Windows.GridUnitType]::Star)
        }
        $feita  = ($i -lt $EtapaAtual)
        $agora  = ($i -eq $EtapaAtual)
        # ALTURA e o segundo codigo, junto com a cor: so a etapa de agora
        # ocupa os 11px inteiros. As outras ficam recuadas em 3.
        $ReguaSegmentos[$i].Margin = if ($agora) { "0,0,3,0" } else { "0,3,3,3" }
        $ReguaSegmentos[$i].Background = Pincel $(
            if ($feita) { $Cores.ok } elseif ($agora) { $Cores.emCursoTrilho } else { $Cores.vazio })
        if ($agora) {
            $ReguaPreenche[$i].Background = Pincel $Cores.emCurso
            $largSeg = [double]$ReguaSegmentos[$i].ActualWidth
            $p = [math]::Max(0.0, [math]::Min(100.0, $PctEtapa))
            $ReguaPreenche[$i].Width = [math]::Max(0.0, $largSeg * ($p / 100.0))
        } else {
            $ReguaPreenche[$i].Width = 0
        }
    }
}

# ---- Semaforo do disco ------------------------------------------------------
function Set-BarraDisco([double]$PctUso) {
    $cor = if ($PctUso -le 70) { $Cores.ok } elseif ($PctUso -le 85) { $Cores.warn }
           elseif ($PctUso -le 100) { $Cores.lar } else { $Cores.err }
    $msg = if ($PctUso -le 70) { "$($Sim.Ok) Espaço em Disco Suficiente para Converter Todos os Vídeos da Fila." }
           elseif ($PctUso -le 85) { "$($Sim.Skip) Espaço Suficiente, Mas o Disco Vai Ficar Apertado Durante a Conversão." }
           elseif ($PctUso -le 100) { "$($Sim.Warn) No Limite: Sobra Menos de 10% do Disco no Pico da Conversão." }
           else { "$($Sim.Err) Espaço Insuficiente - Vídeos Podem Ser Ignorados por Falta de Espaço." }
    $larguraMax = [math]::Max(80, $UI.barraDisco.Parent.ActualWidth)
    $UI.barraDisco.Width = $larguraMax * ([math]::Min(100,$PctUso) / 100.0)
    $pincel = [System.Windows.Media.BrushConverter]::new().ConvertFromString($cor)
    $UI.barraDisco.Background = $pincel
    $UI.lblDiscoMsg.Text = $msg
    $UI.lblDiscoMsg.Foreground = $pincel
}

function Update-TemposPausa {
    $d = $Motor
    $wallEtapa = if ($d.T0Etapa) { ((Get-Date) - $d.T0Etapa).TotalSeconds } else { $d.SegEtapa }
    $wallFila  = if ($d.T0Fila)  { ((Get-Date) - $d.T0Fila).TotalSeconds }  else { $d.SegFila }
    $UI.lblTemposEtapa.Text = ("Começou: {0}   Decorrido: {1}   {2} PAUSADO POR VOCÊ há {3}" -f
        $d.HoraEtapa, (Format-MinSeg $wallEtapa), $Sim.Pausa, (Format-MinSeg $d.SegPausado))
    $UI.lblTemposFila.Text = ("Começou: {0}   Decorrido: {1}" -f
        $d.HoraFila, (Format-MinSeg $wallFila))
    $Janela.Title = "$NOME_APP  ·  PAUSADO - $([int]$d.PctEtapa)% - Sem Consumir CPU/Disco"
}

# ---- Maquina de estados -----------------------------------------------------
# Um unico lugar decide o que aparece e o que habilita. Sem duplicatas.
$Estado = @{ Atual = "" }

function Set-Estado([string]$Novo) {
    $anterior = $Estado.Atual
    $Estado.Atual = $Novo
    if ($anterior -ne $Novo) { Escrever-Log ("ESTADO: {0} -> {1}" -f $(if($anterior){$anterior}else{"(inicio)"}), $Novo) }
    $ini  = $Novo -eq "inicial"
    $run  = $Novo -eq "rodando"
    # 16.60: saindo de rodando/pausado, o que o motor estava anunciando deixa
    # de ser verdade. Ver o comentario em $ehOAtual, na montagem da fila.
    if ($Novo -eq "inicial" -or $Novo -eq "parado") {
        $Motor.VideoNome = ""; $Motor.Fase = ""; $Motor.Nota = ""
    }
    $pau  = $Novo -eq "pausado"
    $fim  = $Novo -eq "fim"
    # 16.64: as caixas de pasta so aceitam edicao na tela inicial. O painel
    # inteiro ja fica escondido fora dela, mas esconder nao e travar - e o
    # foco pode estar dentro da caixa na hora em que ela some.
    Set-CaixasDePastaEditaveis $ini

    # Visibilidade dos paineis
    $UI.painelPastas.Visibility      = if ($ini) { "Visible" } else { "Collapsed" }
    $UI.corpoPastas.Visibility       = if ($script:PastasVisivel) { "Visible" } else { "Collapsed" }
    # 16.29: o painel grande "FERRAMENTAS DISPONIVEIS" saiu da tela inicial - a
    # tira compacta (a mesma que ja aparecia durante a conversao) agora vale
    # para todos os estados. A lista completa, com o CAMINHO de cada ferramenta,
    # continua no botao "Ferramentas" da barra - so deixou de ocupar a tela.
    $UI.painelFerramentas.Visibility = "Collapsed"
    $UI.corpoFerramentas.Visibility  = "Collapsed"
    $UI.faixaCompacta.Visibility     = if ($fim) { "Collapsed" } else { "Visible" }
    # Na tela inicial o painel de Pastas (com os botoes Trocar) ja mostra origem
    # e saida - repetir na tira seria a mesma informacao duas vezes na tela.
    $UI.txtPastasCompacto.Visibility = if ($ini) { "Collapsed" } else { "Visible" }
    $UI.painelDisco.Visibility       = if ($ini) { "Visible" } else { "Collapsed" }
    $UI.painelProgresso.Visibility   = if ($run -or $pau) { "Visible" } else { "Collapsed" }
    $UI.faixaPausa.Visibility        = if ($pau) { "Visible" } else { "Collapsed" }
    $UI.painelResumo.Visibility      = if ($fim) { "Visible" } else { "Collapsed" }
    $UI.painelDiagnostico.Visibility = if ($fim) { "Collapsed" } else { "Visible" }
    $UI.caixaFila.Visibility         = if ($fim) { "Collapsed" } else { "Visible" }

    # Habilitacao dos botoes (mapa aprovado)
    $UI.btnIniciar.IsEnabled  = $ini
    $UI.btnPausar.IsEnabled   = $run -or $pau
    $UI.btnCancelar.IsEnabled = $run -or $pau
    # 16.45: "Abrir Origem" e "Abrir Saída" valem SEMPRE - inclusive com a
    # fila rodando, que e justamente quando da vontade de ir olhar o que ja
    # saiu. Eles nao mexem em nada, so abrem o Explorer.
    $UI.btnReler.IsEnabled    = $ini

    # Toggle Pausar/Retomar (F2 unico)
    if ($pau) {
        $UI.lblPausar.Text = "Retomar F2"; $UI.icoPausar.Text = $Sim.Atual
        $UI.btnPausar.Foreground  = Pincel $Cores.warn
        $UI.btnPausar.Background  = Pincel $Cores.pausaFundo
        $UI.btnPausar.BorderBrush = Pincel $Cores.pausaBorda
    } else {
        $UI.lblPausar.Text = "Pausar F2"; $UI.icoPausar.Text = $Sim.Pausa
        $UI.btnPausar.Foreground  = Pincel $(if ($run) { $Cores.txt } else { $Cores.vazio })
        $UI.btnPausar.Background  = Pincel "#00000000"
        $UI.btnPausar.BorderBrush = Pincel "#00000000"
    }
    # ATENCAO (bug corrigido na 14.0-p2): no WPF, valor local definido por
    # codigo VENCE o gatilho IsEnabled=False do estilo. Por isso a cor de
    # cada botao e sempre recalculada aqui conforme o estado - nunca deixada
    # "por conta do estilo" depois de ter sido pintada uma vez.
    if ($ini) {
        $UI.btnIniciar.Foreground  = Pincel $Cores.ok
        $UI.btnIniciar.Background  = Pincel $Cores.okFundo
        $UI.btnIniciar.BorderBrush = Pincel $Cores.okBorda
    } else {
        $UI.btnIniciar.Foreground  = Pincel $Cores.vazio
        $UI.btnIniciar.Background  = Pincel "#00000000"
        $UI.btnIniciar.BorderBrush = Pincel "#00000000"
    }
    $UI.btnCancelar.Foreground = Pincel $(if ($run -or $pau) { $Cores.err } else { $Cores.vazio })

    # Aparencia do PAUSADO (aprovada nos mockups): barra da etapa em ambar
    # apagado - congelada, nao morta -, "Restante" vira "congelado" e entra o
    # contador "Pausado ha".
    if ($pau) {
        $UI.barraEtapa.Background = Pincel "#7A6A3A"
        # 16.37: guarda de indice + a fase (diagnostico/limpeza) tem nome
        # proprio, senao pausar durante a limpeza mostraria o nome da ultima
        # etapa como se ela ainda estivesse rodando.
        $UI.lblEtapaNome.Text = if ($Motor.Fase) { "$($Sim.Pausa) " + $Motor.Fase }
                                else {
                                    $iP = [math]::Max(0, [math]::Min($Cfg.Etapas.Count - 1, $Motor.EtapaIdx))
                                    "$($Sim.Pausa) " + $Cfg.Etapas[$iP]
                                }
        # 16.45: o ambar da pausa vale para o PREENCHIMENTO tambem - o que
        # congelou foi o avanco, nao o leito. E com guarda de indice: ate a
        # 16.44 isso indexava $Motor.EtapaIdx cru e uma pausa fora de faixa
        # derrubava a janela.
        $iPa = [math]::Max(0, [math]::Min($ReguaSegmentos.Count - 1, [int]$Motor.EtapaIdx))
        $ReguaSegmentos[$iPa].Background = Pincel "#3A3222"
        $ReguaPreenche[$iPa].Background  = Pincel "#7A6A3A"
        $Motor.SegPausado = 0
        $Motor.PausaIni = Get-Date
        Update-TemposPausa
        $TimerPausa.Start()
    } else {
        $TimerPausa.Stop()
        if ($Motor.PausaIni) {
            $dur = ((Get-Date) - $Motor.PausaIni).TotalSeconds
            $Motor.PausadoEtapa += $dur
            $Motor.PausaIni = $null
            Escrever-Log ("PAUSA de {0} encerrada (total pausado nesta etapa: {1})" -f `
                (Format-MinSeg $dur), (Format-MinSeg $Motor.PausadoEtapa)) "PROVA"
        }
        $UI.barraEtapa.Background = Pincel $Cores.emCurso
    }

    # Fila e foco
    switch ($Novo) {
        "inicial" {
                    # 16.41: volta a regua pros pesos tipicos. Sem isto, depois
                    # de converter um Se7en (que pula duas etapas) a tela
                    # inicial continuaria mostrando a regua DELE, com dois
                    # pedacos sumidos, pro proximo arquivo que nem foi lido.
                    $script:PesosDoVideoAtual = @()
                    $script:SegEtapasDoVideoAtual = @()
                    Fill-Fila "inicial"; $UI.btnIniciar.Focus() | Out-Null
                    $n = @($script:Videos | Where-Object { -not $_.Ignorar }).Count
                    $Janela.Title = "$NOME_APP  ·  Pronto para Converter - $n Vídeo(s) na Fila" }
        "rodando" { Fill-Fila "rodando"
                    $UI.btnPausar.Focus() | Out-Null }
        "pausado" { Fill-Fila "pausado"
                    $UI.btnPausar.Focus() | Out-Null
                    $Janela.Title = "$NOME_APP  ·  PAUSADO - $([int]$Motor.PctEtapa)% - Sem Consumir CPU/Disco" }
        "fim"     { $script:LinhasFila.Clear(); $UI.btnNovaConversao.Focus() | Out-Null }
    }
    # m3c8: sem isso, o dropdown da coluna ACAO so refletia o novo Estado na
    # PROXIMA vez que algo mais chamasse Fill-Faixas (trocar de aba/video) -
    # entre o F1 e essa proxima chamada, o dropdown continuava clicavel e
    # aceitando escolha em plena conversao (bug achado no log real da m3c7).
    Fill-Faixas
}

# ---- Consumo da fila do motor ----------------------------------------------
# DispatcherTimer de 100ms na thread da janela: drena a ConcurrentQueue e
# aplica cada mensagem nos controles. E o UNICO lugar que traduz motor -> UI.
# (Substitui o DispatcherTimer de simulacao da 14.0-p14, que inventava os
#  numeros na propria thread da janela.)
$Motor = @{ EtapaIdx = 0; PctEtapa = 0.0; SegEtapa = 0; SegVideo = 0; RestVideo = 0
            FatorRegua = 1.0; PausadoFila = 0; T0Fase = $null
            SegPausado = 0; LivreGB = 404.99; HoraFila = ""; HoraVideo = ""; HoraEtapa = ""
            VideoNome = ""; VideoIdx = 0; VideoTotal = 0; SegFila = 0
            # T0* sao relogios de PAREDE. O motor manda tempo LIQUIDO (sem as
            # pausas), que serve pra estimar o que falta; mas "Começou 13h54 /
            # Decorrido 06m30s" as 14h16 nao fecha conta nenhuma na cabeca de
            # quem le. Entao: Decorrido = parede, e a pausa aparece do lado.
            T0Fila = $null; T0Video = $null; T0Etapa = $null; T0Diag = $null
            PctUltimo = -1; PctUltimoEm = $null; LivreEm = $null
            VidaEm = $null; VidaCpuMs = 0.0; VidaPct = 0; VidaNomes = ""; VidaEmVida = $null
            # 16.49: a prova de vida agora tem DONO. VidaChave guarda de qual
            # etapa/fase veio a ultima medicao; quando o dono muda, a leitura
            # velha e descartada em vez de vazar pra etapa seguinte.
            VidaChave = ""; VidaSemMedida = $true
            LogPctUltimo = -100; LogPctEm = $null; PausadoEtapa = 0.0; PausaIni = $null
            # 16.37: Fase e o que roda FORA da numeracao - o diagnostico antes
            # da [1/5] e a limpeza depois da [5/5]. Vazio o resto do tempo.
            Nota = ""; Fase = ""
            # 16.45: estimativa somada do lote inteiro - base do % da FILA.
            # Ja era calculada no Iniciar so pra escrever no log; agora fica
            # guardada, porque a tela precisa dela a cada segundo.
            EstTotalFila = 0.0 }

$TimerFila = New-Object System.Windows.Threading.DispatcherTimer
$TimerFila.Interval = [TimeSpan]::FromMilliseconds(100)

# Relogio do tempo pausado: so corre enquanto a conversao esta parada.
$TimerPausa = New-Object System.Windows.Threading.DispatcherTimer
$TimerPausa.Interval = [TimeSpan]::FromSeconds(1)

# 16.39: BUG REAL - o log de 18/08 16h09 tem a linha
#   "ETAPA 1/5 fechada: parede 01m 60s"
# 01m 60s nao existe. Vinha de arredondar os SEGUNDOS depois de ja ter
# separado os minutos: com 119,6s, Floor(119,6/60) da 1 minuto e [int] de
# 59,6 arredonda pra 60. Agora arredonda o total PRIMEIRO e so depois divide -
# 119,6s vira 120s, que vira 02m 00s.
function Format-MinSeg([double]$Seg) {
    $t = [int][math]::Round($Seg)
    if ($t -lt 0) { $t = 0 }
    # 16.49: acima de uma hora o cronometro passa a mostrar a HORA. Uma fila de
    # quatro filmes escrevia "Decorrido 480m 00s" - ninguem le 480 minutos como
    # oito horas sem parar pra dividir, e essa linha existe justamente pra ser
    # lida de relance. Abaixo de 60 min nada muda: "35m 25s" continua igual.
    $min = [int][math]::Floor($t / 60)
    if ($min -lt 60) { return ("{0:00}m {1:00}s" -f $min, ($t % 60)) }
    "{0}h {1:00}m {2:00}s" -f [int][math]::Floor($min / 60), ($min % 60), ($t % 60)
}

<#  16.46: Format-MinSeg e um CRONOMETRO - ele conta o que ja passou, e ali
    o segundo importa. O que FALTA e outra coisa: e uma espera, e ninguem
    espera "137m 20s". Alem de nao se ler, o segundo ali e falso - uma
    previsao nao tem precisao de segundo. Duas perguntas diferentes, dois
    formatos diferentes. #>
function Format-Espera([double]$Seg) {
    $t = [int][math]::Round($Seg)
    if ($t -lt 60) { return "menos de 1 min" }
    # Arredonda para MINUTO antes de decidir se usa hora - senao 3599s cai no
    # ramo dos minutos e sai "60 min", enquanto 3600s sai "1h": o mesmo tempo
    # escrito de dois jeitos por causa de um segundo.
    $totMin = [int][math]::Round($t / 60.0)
    if ($totMin -lt 60) { return ("{0} min" -f $totMin) }
    $h = [int][math]::Floor($totMin / 60)
    $m = $totMin % 60
    if ($m -eq 0) { return ("{0}h" -f $h) }
    return ("{0}h {1:00}min" -f $h, $m)
}

# O rodape mostrava "Livre Agora 404,99 GB" - numero da maquete, que nunca
# mudava. Agora e o espaco real do disco da SAIDA, lido no maximo a cada 5s
# (Get-PSDrive nao e caro, mas tambem nao precisa rodar 10x por segundo).
# Os executaveis que o motor usa. Sao nomes especificos o bastante para nao
# confundir com outra coisa aberta na maquina.
# 16.35: seconv e tesseract entraram na lista. Faltavam os dois, e por isso a
# etapa 5/7 escrevia "(nenhum processo do motor)" no log EXATAMENTE enquanto o
# OCR estava trabalhando - o que lia como travamento e nao era. O Corretor e o
# Reocr rodam dentro de um powershell.exe filho; "powershell" NAO entra aqui de
# proposito, porque casaria com a propria janela e a prova de vida passaria a
# dizer "esta vivo" sempre, inclusive quando nao esta. Pra essas duas o nome da
# sub-etapa (motor 14.11, SaySub) e que responde "quem esta rodando".
$script:ProcMotor = @("ffmpeg","ffprobe","dovi_tool","deezy","truehdd","dee",
                      "mkvmerge","mkvextract","PgsToSrt","java",
                      "seconv","tesseract")

# PROVA DE VIDA: soma o tempo de CPU dos executaveis do motor e converte em %
# da maquina. E barato (Get-Process por nome) e responde com FATO se o processo
# esta trabalhando - que e o que uma barra parada nao responde.
function Update-ProvaDeVida {
    $agora = Get-Date
    <#  16.49: A LEITURA DE UMA ETAPA NAO PODE VAZAR PARA A SEGUINTE.

        Diego, no log de 19/08 22h56: "apareceu q leu o diagnostico duas vezes
        e por duas vezes comecou o processo de extrair o mkv". Nao comecou -
        foi a tela que escreveu isso:

            22:57:28.460   Diagnostico do arquivo - 100% - ffprobe
            22:57:28.480   > [1/5] Extraindo Video Puro do MKV
            22:57:28.695   etapa 1/5 -   0% - ffprobe      <- MENTIRA

        A barra zerou e o nome do processo continuou o mesmo. Isso le como
        "voltou pro comeco e esta refazendo a mesma coisa" - e e exatamente o
        que ele leu. O motivo: esta funcao so remede de 2 em 2 segundos, e nos
        2 primeiros segundos de CADA etapa ela devolvia o nome medido na etapa
        ANTERIOR. O padrao esta no log inteiro, sempre no 0%:

            etapa 1/5 -> ffprobe     (era do diagnostico)
            etapa 2/5 -> ffmpeg      (era da 1/5)
            etapa 4/5 -> dovi_tool   (era da 2/5)
            etapa 5/5 -> tesseract   (era da 4/5)

        A medicao passa a ter DONO: guardo de qual etapa/fase ela veio. Quando
        o dono muda, a leitura velha e jogada fora e uma nova e tirada na hora,
        sem esperar os 2s. Se o executavel novo ainda nao subiu, a linha diz
        "preparando" - que e a verdade - em vez de repetir o nome de um
        processo que ja morreu.

        O % de CPU e zerado junto e marcado como "sem medida": ele e um DELTA
        contra a leitura anterior, e subtrair o tempo de CPU do ffprobe do
        tempo de CPU do ffmpeg nao produz numero nenhum que signifique alguma
        coisa. Enquanto nao houver duas leituras da MESMA etapa, quem le a tela
        ve "ffmpeg comecando", nao um "0% de CPU" que parece travamento.  #>
    $chave = if ($Motor.Fase) { "F:" + $Motor.Fase } else { "E:" + $Motor.EtapaIdx }
    # -cne de proposito: "F:Limpando temporarios" e "E:4" nunca colidem, mas
    # comparar com -ne (insensivel) e o tipo de descuido que volta pra assombrar.
    $trocouDeDono = ("$($Motor.VidaChave)" -cne $chave)
    if ($trocouDeDono) {
        $Motor.VidaChave     = $chave
        $Motor.VidaNomes     = ""
        $Motor.VidaPct       = 0
        $Motor.VidaSemMedida = $true
        $Motor.VidaEm        = $null   # zera a janela do delta
        $Motor.VidaCpuMs     = 0.0
    }
    if (-not $trocouDeDono -and $Motor.VidaEm -and ($agora - $Motor.VidaEm).TotalSeconds -lt 2) { return }
    $cpuMs = 0.0
    $nomes = New-Object System.Collections.Generic.List[string]
    foreach ($n in $script:ProcMotor) {
        foreach ($p in @(Get-Process -Name $n -ErrorAction SilentlyContinue)) {
            try { $cpuMs += $p.TotalProcessorTime.TotalMilliseconds
                  if (-not $nomes.Contains($p.ProcessName)) { $nomes.Add($p.ProcessName) } } catch { }
            # 16.44: ler TotalProcessorTime abre um handle nativo. Esta funcao
            # roda a cada 2s varrendo 12 nomes; numa temporada de 20 episodios
            # sao dezenas de milhares de handles esperando o coletor de lixo.
            finally { try { $p.Dispose() } catch { } }
        }
    }
    if ($Motor.VidaEm) {
        $janelaMs = ($agora - $Motor.VidaEm).TotalMilliseconds
        $nucleos = [math]::Max(1, [Environment]::ProcessorCount)
        if ($janelaMs -gt 0) {
            $pct = (($cpuMs - $Motor.VidaCpuMs) / ($janelaMs * $nucleos)) * 100.0
            $Motor.VidaPct = [math]::Max(0, [math]::Round($pct, 0))
            $Motor.VidaSemMedida = $false
        }
        # "Trabalhando" e CPU acima de 1% OU pelo menos um executavel de pe.
        # Vale para o mkvmerge, que e mais disco do que processador.
        if ($Motor.VidaPct -ge 1 -or $nomes.Count -gt 0) { $Motor.VidaEmVida = $agora }
    } elseif ($nomes.Count -gt 0) {
        # 16.49: primeira leitura da etapa - nao ha delta, mas ter executavel de
        # pe ja e prova de vida. Sem esta linha o relogio de "nada rodando ha X"
        # continuaria correndo durante uma etapa que acabou de comecar a
        # trabalhar, e o rodape acusaria travamento onde nao ha.
        $Motor.VidaEmVida = $agora
    }
    $Motor.VidaEm = $agora
    $Motor.VidaCpuMs = $cpuMs
    $Motor.VidaNomes = ($nomes -join ", ")
}

function Update-LivreAgora([bool]$Forcar = $false) {
    if (-not $Forcar -and $Motor.LivreEm -and ((Get-Date) - $Motor.LivreEm).TotalSeconds -lt 5) { return }
    $Motor.LivreEm = Get-Date
    try {
        $alvo = if ($Cfg.Saida) { $Cfg.Saida } else { $script:PastaScript }
        $raiz = [System.IO.Path]::GetPathRoot($alvo)
        $nome = $raiz.TrimEnd('\','/').TrimEnd(':')
        $Motor.LivreGB = (Get-PSDrive -Name $nome -ErrorAction Stop).Free / 1GB
    } catch { }
}

function Update-Progresso {
    $d = $Motor
    Update-LivreAgora
    $pct = [int]$d.PctEtapa
    $UI.lblPct.Text = "$pct%"
    $trilho = $UI.barraEtapa.Parent
    $UI.barraEtapa.Width = [math]::Max(0, $trilho.ActualWidth * ($pct/100.0))

    <#  16.47: FASE NAO E ETAPA - E A TELA ESTAVA TRATANDO AS DUAS IGUAL.
        Existem TRES trabalhos que rodam fora da numeracao: [DIAGNOSTICO]
        (antes da 1a etapa), [VERIFICACAO] e [LIMPEZA] (depois da ultima).
        Os tres mandam progresso pelo MESMO canal das etapas, e ate a 16.46 a
        tela acreditava. Dava nisto, e o Diego viu os dois:

        NO COMECO - o [DIAGNOSTICO] do ffprobe sobe de 0 a 100% (log 19/08
        14h43: "PROGRESSO: etapa 1/5 - 0% ... 100%" ANTES da linha "> [1/5]").
        Como EtapaIdx ainda vale 0, a barra grossa enchia inteira E o primeiro
        segmento da regua enchia de ciano - anunciando uma etapa que nem tinha
        comecado. Dois segundos depois zerava tudo e a [1/5] comecava de novo.
        Pior: o % do VIDEO tambem pulava para o peso da etapa 1 e voltava.

        NO FIM - a [VERIFICACAO] tem barra propria (10 trechos = 0 a 100%).
        Ali a regua ja esta verde inteira e o video ja marca 100%, e mesmo
        assim a barra da etapa subia em CIANO, a cor de "esta rodando agora".
        "duas barras azul sendo que embaixo ja ta tudo verde" - exatamente.

        A causa e uma so, entao a correcao e uma so: quando ha FASE, o rodape
        para de falar a lingua das etapas.
          - a barra grossa vira CINZA-AZULADO (trabalho de apoio, nao etapa)
          - a regua nao recebe preenchimento nenhum
          - diagnostico -> regua sem nada aceso, VIDEO em 0%
          - verificacao/limpeza -> regua verde inteira, VIDEO em 100%
        A barra continua andando (ela informa que o ffprobe/o teste esta
        progredindo, e isso e util) - o que ela para de fazer e mentir sobre
        QUAL trabalho esta progredindo. #>
    $emFase   = [bool]$d.Fase
    $faseDiag = $emFase -and ("$($d.Fase)" -match "(?i)diagn")
    # 16.47: a autocorrecao do plano mora aqui, no pulso da tela, e so depois
    # de a etapa provar que esta trabalhando (ver o bloco da funcao).
    if (-not $emFase -and $d.T0Etapa -and ((Get-Date) - $d.T0Etapa).TotalSeconds -ge 4) {
        Confirmar-EtapaNoPlano $d.EtapaIdx
    }
    $UI.barraEtapa.Background = Pincel $(if ($emFase) { $Cores.fase } else { $Cores.emCurso })
    $trilho.Background = Pincel $(if ($emFase) { $Cores.trilho } else { $Cores.emCursoTrilho })
    # Entre o clique e o motor anunciar o primeiro arquivo passam ~2s carregando
    # as funcoes e o preparo. Nesses 2s a tela mostrava "ETAPA 1/7 Detectando
    # Informações do Vídeo" como se ja estivesse rodando - nao estava.
    $nEt = $Cfg.Etapas.Count
    if (-not $d.VideoNome) {
        $UI.lblEtapaNum.Text = "-/$nEt"
        $UI.lblEtapaNome.Text = "$($Sim.Atual) Preparando o motor..."
    } elseif ($d.Fase) {
        # 16.37: diagnostico e limpeza nao tem numero - e essa a informacao.
        # Antes elas ocupavam a caixa "1/7" e "7/7" e o usuario contava sete
        # etapas onde havia cinco de trabalho.
        $UI.lblEtapaNum.Text = "·"
        $UI.lblEtapaNome.Text = "$($Sim.Atual) $($d.Fase)"
    } else {
        $iEt = [math]::Max(0, [math]::Min($nEt - 1, $d.EtapaIdx))
        # 16.45: o numero e a POSICAO NO PLANO deste arquivo, nao o indice no
        # catalogo. Arquivo que ja chega em 8.1 e com o audio mantido tem tres
        # etapas de trabalho - e le "2 de 3", nao "4/5" com dois buracos.
        $posPlano = Get-PosicaoNoPlano $iEt
        $totPlano = @(Get-PlanoDoVideo).Count
        <#  16.47: etapa fora do plano nao troca o numero na tela.
            O motor anuncia as cinco etapas mesmo quando tres delas so
            imprimem "nao necessario" e fecham em 00m00s. Se cada anuncio
            reescrevesse o contador, o Lara Croft piscaria "1/3 - 2/5 - 3/5 -
            2/3" em dois segundos. Fora do plano = nada mudou ainda: mantem o
            ultimo numero valido. Quando a etapa for de verdade, ela entra no
            plano sozinha (Confirmar-EtapaNoPlano) e o numero anda. #>
        if ($posPlano -gt 0) {
            $script:UltimoRotuloEtapa = "$posPlano/$totPlano"
        } elseif (-not $script:UltimoRotuloEtapa) {
            $script:UltimoRotuloEtapa = "1/$totPlano"
        }
        $UI.lblEtapaNum.Text = $script:UltimoRotuloEtapa
        $nomeEtapa = "$($Sim.Atual) $($Cfg.Etapas[$iEt])"
        if ($d.Nota) { $nomeEtapa += "   ·   $($d.Nota)" }
        $UI.lblEtapaNome.Text = $nomeEtapa
    }
    # Decorrido de PAREDE, pra fechar com o "Começou". Sem o "(pausado XX)" que
    # eu punha aqui: alem de o relogio de parede ja incluir a pausa, a palavra
    # lida na tela parecia ESTADO ("está pausado") quando era historico.
    $wallEtapa = if ($d.T0Etapa) { ((Get-Date) - $d.T0Etapa).TotalSeconds } else { $d.SegEtapa }

    # No lugar da hora de termino: quem esta rodando e quanto de CPU consome.
    Update-ProvaDeVida
    $semVidaSeg = if ($d.VidaEmVida) { ((Get-Date) - $d.VidaEmVida).TotalSeconds } else { 0 }
    # 16.36: o nome do processo sozinho nao respondia "o que esta rodando".
    # Durante o Corretor e o Reocr o filho e um powershell.exe (que NAO entra
    # na lista de proposito - casaria com a propria janela), entao a linha
    # dizia "(nenhum processo do motor)" no exato momento em que o trabalho
    # acontecia. Agora quem manda e a SUB-ETAPA que o motor anunciou; o nome
    # do executavel e o CPU viram detalhe no fim. Foi assim que ficou legivel
    # o trecho em que ffmpeg e tesseract se revezam a cada segundo dentro do
    # Reocr - o que muda o tempo todo e a ferramenta, nao a tarefa.
    # O nome da SUB-ETAPA nao entra aqui: ele ja esta na linha de cima
    # (lblEtapaNome). Esta linha responde outra pergunta - "esta trabalhando
    # agora?" - e a resposta muda de segundo em segundo dentro do Reocr, que
    # reveza ffmpeg e tesseract um por bloco.
    $tarefa = "$($d.Nota)".Trim()
    if ($d.VidaNomes -and -not $d.VidaSemMedida) {
        $txtVida = "{0} {1} · {2}% de CPU" -f $Sim.Atual, $d.VidaNomes, $d.VidaPct
    } elseif ($d.VidaNomes) {
        # 16.49: nome ja medido, consumo ainda nao. O % de CPU e um DELTA entre
        # duas leituras; na primeira leitura de uma etapa nova nao existe delta
        # nenhum, e imprimir "0% de CPU" ali lia como "nao esta fazendo nada".
        $txtVida = "{0} {1} · começando" -f $Sim.Atual, $d.VidaNomes
    } elseif ($semVidaSeg -ge 120) {
        $txtVida = "{0} nada rodando há {1}" -f $Sim.Err, (Format-MinSeg $semVidaSeg)
    } elseif ($tarefa) {
        $txtVida = "{0} trabalhando · sem processo próprio (roda dentro do PowerShell)" -f $Sim.Atual
    } else {
        $txtVida = "{0} preparando" -f $Sim.Atual
    }
    <#  16.50: FALTAVA O ":". Diego, depois do teste do GoT: "falta um : ne?
        Comecou: 00h52 ... feio demais do jeito que esta, duvido em algum
        lugar da industria um programa mostrar desse jeito." Ele tem razao -
        "Comecou 00h52" le como duas palavras soltas lado a lado; "Comecou:
        00h52" le como rotulo e valor, que e o que e. Mesma correcao em
        "Decorrido" e em "Tempo Restante" da linha da fila - as tres sao o
        mesmo tipo de par rotulo:valor. #>
    $UI.lblTemposEtapa.Text = ("Começou: {0}   Decorrido: {1}   {2}" -f
        $d.HoraEtapa, (Format-MinSeg $wallEtapa), $txtVida)
    $UI.lblGerado.Text = ""
    # Quem esta convertendo e o que o MOTOR anunciou ("ARQUIVO n/N"), nao o
    # primeiro da lista - com fila de varios videos os dois divergem.
    $UI.lblVideoNome.Text = if ($d.VideoNome) { $d.VideoNome } else { "(aguardando o motor)" }
    # ($nEt ja foi calculado no topo desta funcao)
    <#  16.44: "Fase" e preenchida por TRES marcadores - [DIAGNOSTICO],
        [VERIFICACAO] e [LIMPEZA] - e so o ultimo, e so no ultimo video da
        fila, e mesmo seguido do resumo. Antes, qualquer um dos tres fazia o
        rodape anunciar "A Seguir: Resumo da Conversao" - inclusive no
        diagnostico do primeiro video de tres, antes de comecar a etapa 1. #>
    $ultimoDaFila = ($d.VideoTotal -le 0) -or (($d.VideoIdx + 1) -ge $d.VideoTotal)
    <#  16.45: "A Seguir" tambem anda pelo PLANO. Ate a 16.44 ele anunciava
        a etapa de indice seguinte, mesmo que ela nao fosse rodar: num
        arquivo ja 8.1 a tela dizia "A Seguir: [2/5] Convertendo Dolby Vision"
        e o que vinha era a legenda. Agora ele pula o que nao esta no plano e
        numera igual ao resto da tela. #>
    $planoA = @(Get-PlanoDoVideo)
    $totA   = $planoA.Count
    $proxIdx = -1
    foreach ($ip in $planoA) { if ($ip -gt $d.EtapaIdx) { $proxIdx = $ip; break } }
    $prox = if ("$($d.Fase)" -match "(?i)limpando")  { if ($ultimoDaFila) { "Resumo da Conversão" } else { "Próximo Vídeo da Fila" } }
            elseif ("$($d.Fase)" -match "(?i)conferindo") { "Limpeza dos Temporários" }
            elseif ("$($d.Fase)" -match "(?i)diagn")  {
                $pri = if ($totA -gt 0) { $planoA[0] } else { 0 }
                "[1/{0}] {1}" -f $totA, $Cfg.Etapas[$pri]
            }
            elseif ($proxIdx -ge 0) {
                "[{0}/{1}] {2}" -f (Get-PosicaoNoPlano $proxIdx), $totA, $Cfg.Etapas[$proxIdx]
            } else { "Conferência do Arquivo Final e Limpeza" }
    $UI.lblASeguir.Text = "A Seguir: $prox"
    # Contadores calculados AQUI, antes de qualquer linha que os use - eu tinha
    # posto a conta depois e a linha da FILA sairia com o numero vazio.
    $nTotal = [math]::Max(1, $d.VideoTotal)
    $nAtual = [math]::Min($nTotal, $d.VideoIdx + 1)

    $wallVideo = if ($d.T0Video) { ((Get-Date) - $d.T0Video).TotalSeconds } else { $d.SegVideo }
    $UI.lblTemposVideo.Text = ("Começou: {0}   Decorrido: {1}" -f
        $d.HoraVideo, (Format-MinSeg $wallVideo))

    $wallFila = if ($d.T0Fila) { ((Get-Date) - $d.T0Fila).TotalSeconds } else { $d.SegFila }
    $txtFila = "Começou: {0}   Decorrido: {1}" -f $d.HoraFila, (Format-MinSeg $wallFila)
    if ($d.VideoTotal -gt 1) { $txtFila += "   Vídeo {0} de {1}" -f $nAtual, $nTotal }
    $UI.lblTemposFila.Text = $txtFila

    # (os contadores foram calculados no inicio desta funcao)
    $UI.lblVideoNum.Text = "$nAtual/$nTotal"
    $UI.lblFilaNum.Text  = "$nAtual/$nTotal"
    $UI.lblLivreAgora.Text = ("Livre Agora {0:N2} GB" -f $d.LivreGB)
    # 16.37: durante a LIMPEZA (que vem depois da [5/5]) todas as etapas ja
    # terminaram - a regua fica verde inteira. Passar $EtapaIdx ali deixaria a
    # ultima pintada como "em andamento" enquanto ela ja acabou.
    # 16.47: as tres situacoes da regua, explicitas (ver o bloco no topo desta
    # funcao). Fase nenhuma = etapa de verdade, com preenchimento.
    $acabouOVideo = $emFase -and -not $faseDiag
    if     ($faseDiag)      { Set-Regua -1 0 }        # nada aceso: ainda nao comecou
    elseif ($acabouOVideo)  { Set-Regua $nEt 0 }      # tudo verde: ja acabou
    else                    { Set-Regua $d.EtapaIdx ([double]$pct) }
    <#  16.60: os dois pontos das fases, nos mesmos tres estados da regua.
        Ponto da esquerda  = [DIAGNOSTICO] (antes da 1a etapa).
        Ponto da direita   = [VERIFICACAO] + [LIMPEZA] (depois da ultima).
        diagnostico rodando -> esquerdo ciano, direito apagado
        etapa rodando       -> esquerdo verde, direito apagado
        conferencia/limpeza -> esquerdo verde, direito ciano  #>
    if ($faseDiag) {
        $UI.pontoDiag.Foreground = Pincel $Cores.emCurso
        $UI.pontoFim.Foreground  = Pincel $Cores.vazio
    } elseif ($acabouOVideo) {
        $UI.pontoDiag.Foreground = Pincel $Cores.ok
        $UI.pontoFim.Foreground  = Pincel $Cores.emCurso
    } else {
        $UI.pontoDiag.Foreground = Pincel $Cores.ok
        $UI.pontoFim.Foreground  = Pincel $Cores.vazio
    }

    <#  16.45: O % DO VIDEO E O % DA FILA SAO CONTAS DIFERENTES E AGORA
        APARECEM SEPARADOS.
        Ate a 16.44 existia UM numero na tela - o da etapa - e ele era lido
        como se fosse o do arquivo. Nao e: 90% da [4/5] num filme onde a
        legenda e 45% do trabalho significa 70% do filme, nao 90%.
          % DO VIDEO = peso das etapas ja fechadas + peso da etapa de agora
                       vezes o % dela, sobre o peso do plano deste arquivo.
                       Peso, nao contagem: as etapas nao valem o mesmo.
          % DA FILA  = estimativa dos videos ja terminados + estimativa do
                       atual vezes o % dele, sobre a estimativa do lote.
                       Mesma base que ja alimenta o "Termina as ~".
        As duas usam os pesos reais do arquivo, os mesmos da regua e da conta
        do tempo restante - um numero so, tres leituras. #>
    $plano = @(Get-PlanoDoVideo)
    $somaPlano = 0.0
    foreach ($ip in $plano) { $somaPlano += (Get-PesoDaEtapa $ip) }
    $pctVideo = 0.0
    if ($faseDiag) {
        # Diagnostico: o arquivo ainda nao teve UM byte processado. Zero.
        $pctVideo = 0.0
    } elseif ($acabouOVideo) {
        $pctVideo = 100.0
    } elseif ($somaPlano -gt 0 -and $d.VideoNome) {
        $feitoPeso = 0.0
        foreach ($ip in $plano) { if ($ip -lt $d.EtapaIdx) { $feitoPeso += (Get-PesoDaEtapa $ip) } }
        $pesoAgora = 0.0
        if ($plano -contains $d.EtapaIdx) { $pesoAgora = Get-PesoDaEtapa $d.EtapaIdx }
        $fracAgora = Get-FracaoDaEtapa $d.EtapaIdx ([double]$pct) $wallEtapa
        $pctVideo = 100.0 * ($feitoPeso + $pesoAgora * $fracAgora) / $somaPlano
    }
    $pctVideo = [math]::Max(0.0, [math]::Min(100.0, $pctVideo))
    $UI.lblPctVideo.Text = if ($d.VideoNome) { "{0}%" -f [int][math]::Floor($pctVideo) } else { "" }

    $pctFila = 0.0
    $estTotal = [double]$d.EstTotalFila
    if ($estTotal -gt 0) {
        $lote = @($script:LoteAtual)
        $feitoEst = 0.0
        for ($k = 0; $k -lt $lote.Count -and $k -lt $d.VideoIdx; $k++) { $feitoEst += [double]$lote[$k].SegEstimado }
        $estAtual = 0.0
        if ($d.VideoIdx -ge 0 -and $d.VideoIdx -lt $lote.Count) { $estAtual = [double]$lote[$d.VideoIdx].SegEstimado }
        $pctFila = 100.0 * ($feitoEst + $estAtual * ($pctVideo / 100.0)) / $estTotal
    } elseif ($nTotal -gt 0) {
        # Sem estimativa (lote nao montado): cai na contagem de arquivos, que
        # e grosseira mas nunca mente sobre a ordem de grandeza.
        $pctFila = 100.0 * (($nAtual - 1) + ($pctVideo / 100.0)) / $nTotal
    }
    $pctFila = [math]::Max(0.0, [math]::Min(100.0, $pctFila))
    $UI.lblPctFila.Text = "{0}%" -f [int][math]::Floor($pctFila)

    <#  16.46: "TERMINA AS ~" - e aqui que o RestVideo finalmente serve pra
        alguma coisa. Ele era calculado no runspace, mandado pela fila a cada
        mensagem "pct" e NUNCA aparecia na tela: dado morto desde a 16.x.
        Agora as duas fontes se revezam, cada uma no trecho em que e boa:
          nos primeiros 60s (ou abaixo de 3% da fila) vale a ESTIMATIVA por
            peso - e a unica que existe quando ainda nao ha o que medir;
          depois disso vale a MEDICAO - decorrido x (100-pct)/pct. Ela se
            corrige sozinha e nao depende de os pesos estarem certos.
        Trocar de uma pra outra no meio faria o numero pular; por isso a
        virada acontece cedo, quando o erro entre as duas ainda e pequeno.
        Isto importa de verdade numa fila que roda de madrugada: a pergunta
        nao e "quantos por cento" - e "posso dormir?". #>
    <#  16.70: O TEMPO RESTANTE E CONTADO DA ETAPA DE AGORA PARA A FRENTE.
        A 16.68 acertou o meio da conversao e deixou o fim quebrado, e a
        16.69 so tapou o buraco com a palavra "Finalizando". Print do Diego,
        01/09 21h24: etapa 5/5 em 70%, mkvmerge montando, e o rodape dizia
        "Terminando Agora" - faltavam 1m18s. Duas causas, as duas minhas:
          1. PREVISTO - DECORRIDO nao vale quando o relogio JA passou do
             previsto (aqui o audio levou 31m36s contra 25m50s previstos - a
             maquina estava mais lenta que na vespera). Dali em diante o resto
             virava zero e a conta caia numa extrapolacao pelo % da fila, que
             estava em 98% e devolvia 44 segundos.
          2. A conferencia e a limpeza nao entravam em conta nenhuma. Sao ~40
             segundos que existem em TODO arquivo e que ninguem somava.
        Agora a conta e sempre a mesma, esteja adiantado ou atrasado:
             falta da etapa de agora  (pelo ritmo DELA, medido)
           + previsto das etapas que ainda vem
           + conferencia e limpeza
           + estimativa dos videos seguintes da fila
        "Pelo ritmo dela" e o que segura o caso do Jumanji: com a etapa em 70%
        e 1m15s de relogio, o previsto dela vira 1m47s mesmo que o catalogo
        dissesse menos, e sobram 32s + 38s de conferencia = 1m10s contra 1m18s
        reais. Nenhuma etapa "termina agora" enquanto esta em 70%. #>
    $rabo = [double]$script:TempoEtapa.ConferenciaSeg
    $wallFase = if ($d.T0Fase) { ((Get-Date) - $d.T0Fase).TotalSeconds } else { 0.0 }
    $restProximos = 0.0
    $loteR = @($script:LoteAtual)
    for ($k = [int]$d.VideoIdx + 1; $k -lt $loteR.Count; $k++) {
        $restProximos += ([double]$loteR[$k].SegEstimado + $rabo)
    }
    $restFila = 0.0
    if ($faseDiag) {
        $restFila = [double]$d.RestVideo + $rabo + $restProximos
    } elseif ($acabouOVideo) {
        # conferencia ou limpeza rodando: o que falta e o resto do rabo.
        $restFila = [math]::Max(3.0, $rabo - $wallFase) + $restProximos
    } elseif ($d.VideoNome -and $somaPlano -gt 0) {
        $prevAgora = Get-PrevistoAjustadoDaEtapa $d.EtapaIdx ([double]$pct) $wallEtapa
        $restEtapa = [math]::Max(0.0, $prevAgora - $wallEtapa)
        $restDepois = 0.0
        foreach ($ip in $plano) { if ($ip -gt [int]$d.EtapaIdx) { $restDepois += (Get-SegPrevistoDaEtapa $ip) } }
        $restFila = $restEtapa + $restDepois + $rabo + $restProximos
    }
    <#  16.70: a linha nao depende mais de $pctFila < 100. A fila marcar 100%
        nao quer dizer que acabou - quer dizer que as ETAPAS acabaram, e a
        conferencia ainda esta rodando. Quem decide agora e o ESTADO: enquanto
        o motor roda, ha um numero a dar. #>
    <#  16.71: O LOG GRAVA O QUE O RODAPE ESTA MOSTRANDO.
        Diego, depois de tres entregas em que eu pedi print da tela: "ja falei
        q nao vou olhar merda nenhuma de RODAPE, E A MERDA DO SEU LOG Q TEM Q
        SABER SE TA FUNCIONANDO". Ele esta certo e isso e falha minha: o log
        registrava o % de cada ferramenta, o tempo de cada etapa e a
        estimativa do lote, mas NAO registrava o unico numero que ele reclama
        - o tempo restante que a tela escreve. Sem isso, so foto da tela podia
        provar se a conta esta boa, e conferir foto durante a conversao nao e
        trabalho dele.
        Grava uma linha a cada 30 segundos e SEMPRE que a etapa ou a fase
        muda, com tudo que entrou na conta: da pra refazer a conta inteira
        depois, so lendo o log, sem ninguem olhar a tela. #>
    <#  16.73: O NUMERO NAO PODE PULAR PARA CIMA E PARA BAIXO.
        Log de 01/09 21h54, etapa 5 (mkvmerge, maquina lenta - 5m18s contra
        2m50s da conversao anterior): o bruto saiu 304s, 439s, 218s, 141s,
        126s, 145s, 158s, 137s. Cada leitura e uma conta nova, e o mkvmerge
        reporta de 5 em 5 por cento com intervalos irregulares - a conta esta
        certa e mesmo assim o numero pula, que na tela e indistinguivel de
        estar quebrado.
        Filtro: o valor exibido cai sozinho com o relogio e so anda 25% em
        direcao ao novo calculo a cada leitura; e nao pode SUBIR mais de 10%
        de uma vez. Atraso de verdade ainda sobe - so que devagar, e sem o
        serrote. Nos mesmos oito pontos acima ele devolve 304, 314, 267, 213,
        168, 139, 121, 102: sempre descendo. Zera quando muda a etapa, a fase
        ou o video, porque ali a conta e outra. #>
    if ($restFila -gt 0) {
        $chaveS = "{0}|{1}|{2}" -f "$($d.Fase)", [int]$d.EtapaIdx, [int]$d.VideoIdx
        $agoraS = Get-Date
        if ($script:SuaveChave -ne $chaveS -or -not $script:SuaveEm) {
            $script:SuaveChave = $chaveS
            $script:SuaveValor = $restFila
        } else {
            $dt = ($agoraS - $script:SuaveEm).TotalSeconds
            if ($dt -lt 0) { $dt = 0 }
            $base = [math]::Max(0.0, [double]$script:SuaveValor - $dt)
            $novo = $base + 0.25 * ($restFila - $base)
            $teto = [double]$script:SuaveValor * 1.10
            if ($novo -gt $teto -and $teto -gt 0) { $novo = $teto }
            $script:SuaveValor = [math]::Max(0.0, $novo)
        }
        $script:SuaveEm = $agoraS
        $restFila = [double]$script:SuaveValor
    }
    if ($restFila -gt 0 -and ($Estado.Atual -eq "rodando" -or $Estado.Atual -eq "pausado")) {
        $chaveR = "{0}|{1}" -f "$($d.Fase)", [int]$d.EtapaIdx
        $agoraR = Get-Date
        $devoLogar = $false
        if ($script:UltimoRodapeChave -ne $chaveR) { $devoLogar = $true }
        elseif ((-not $script:UltimoRodapeEm) -or (($agoraR - $script:UltimoRodapeEm).TotalSeconds -ge 30)) { $devoLogar = $true }
        if ($devoLogar) {
            $script:UltimoRodapeChave = $chaveR
            $script:UltimoRodapeEm    = $agoraR
            $ondeR = if ($d.Fase) { "$($d.Fase)" } else { "etapa {0} em {1:N0}%" -f ([int]$d.EtapaIdx + 1), $pct }
            Escrever-Log ("RODAPE: restante {0:N0}s | {1} | decorrido: etapa {2:N0}s, video {3:N0}s, fila {4:N0}s | previsto da etapa {5:N0}s | video {6:N0}% fila {7:N0}%" -f `
                          $restFila, $ondeR, $wallEtapa, $wallVideo, $wallFila,
                          (Get-SegPrevistoDaEtapa ([int]$d.EtapaIdx)), $pctVideo, $pctFila) "PROVA"
        }
        $fim = (Get-Date).AddSeconds($restFila)
        $quando = if ($fim.Date -eq (Get-Date).Date) { $fim.ToString("HH'h'mm") }
                  else { $fim.ToString("HH'h'mm 'de' dd/MM") }
        <#  16.49: O "~" SAIU. Diego: "ja q eh uma previsao deixe algo escrito
            no sentido e nao esse ~ amador". Ele tem razao - o til nao e um
            sinal que se le, e uma abreviacao de quem nao quis escrever. Quem
            olha essa linha as 3 da manha esta perguntando "posso dormir?", e a
            resposta certa e uma frase, nao um simbolo:
                antes  -> Termina as ~11h48 (faltam 1h 13min)
                agora  -> Deve Terminar por Volta das 11h48 - Tempo Restante 1h 13min
            "Deve" e "por Volta das" ja carregam a incerteza inteira, entao nao
            entra um segundo "cerca de" em cima. E "Tempo Restante" no lugar de
            "faltam" porque "faltam 1h" nao concorda em portugues e "falta 1h
            13min" tambem nao - substantivo nao tem esse problema.
            No ultimo minuto a previsao perde o sentido (o horario previsto e
            AGORA): ali vira uma frase so.  #>
        <#  16.70: "Terminando Agora" so abaixo de 15s. Com 60 ela mentia: no
            print das 21h24 faltava mais de um minuto de mkvmerge. #>
        if ($restFila -lt 15) {
            $txtFila += "   Terminando Agora"
        } else {
            $txtFila += "   Deve Terminar por Volta das {0}   ·   Tempo Restante: {1}" -f $quando, (Format-Espera $restFila)
        }
        $UI.lblTemposFila.Text = $txtFila
    }
    $trilhoFila = $UI.barraFila.Parent
    if ($trilhoFila) { $UI.barraFila.Width = [math]::Max(0.0, $trilhoFila.ActualWidth * ($pctFila / 100.0)) }
    $rotuloFila = if ($d.VideoTotal -gt 1) { " ($nAtual/$nTotal)" } else { "" }
    <#  16.48: O TITULO DA JANELA CONTAVA POR FORA.
        Print do Diego (19/08 17h49): a barra de titulo dizia
        "Convertendo - Etapa 3/5 - 7%" enquanto o rodape, na mesma tela,
        dizia "ETAPA 2/4". Dois numeros para a mesma etapa, a um palmo um do
        outro. A 16.45 passou a contar pelo PLANO do arquivo e este ponto
        ficou para tras, ainda usando EtapaIdx+1 sobre as 5 do catalogo.
        Agora o titulo pergunta ao mesmo lugar que o rodape. #>
    $tituloEtapa = if ($d.Fase) { $d.Fase }
                   else {
                       $iT = [math]::Max(0, [math]::Min($nEt - 1, $d.EtapaIdx))
                       $pT = Get-PosicaoNoPlano $iT
                       $tT = @(Get-PlanoDoVideo).Count
                       if ($pT -gt 0) { "Etapa {0}/{1}" -f $pT, $tT }
                       elseif ($script:UltimoRotuloEtapa) { "Etapa " + $script:UltimoRotuloEtapa }
                       else { "Etapa {0}/{1}" -f ($iT + 1), $nEt }
                   }
    $Janela.Title = "$NOME_APP  ·  Convertendo$rotuloFila - $tituloEtapa - $pct%"
}

$TimerPausa.add_Tick({
    $Motor.SegPausado += 1
    $Motor.PausadoFila += 1     # 16.68: este NAO zera a cada etapa
    Update-TemposPausa
})

# Relogio da FILA: corre do Iniciar ate o resumo, em qualquer estado. Sem ele o
# tempo total do resumo teria que ser adivinhado a partir do tempo do video.
$TimerFilaRelogio = New-Object System.Windows.Threading.DispatcherTimer
$TimerFilaRelogio.Interval = [TimeSpan]::FromSeconds(1)
$TimerFilaRelogio.add_Tick({
    $Motor.SegFila += 1
    # 16.10: PULSO DA TELA. Update-Progresso so era chamado quando CHEGAVA
    # mensagem do motor ("pct", "etapa", "arquivo"). Numa etapa que nao
    # reporta progresso - o PgsToSrt enquanto carrega as imagens da legenda,
    # 1m44s no Troia - nao chega nenhuma, e entao TUDO congelava junto: a
    # barra em 0%, o "Decorrido" em 00m 00s e a prova de vida mostrando o
    # processo da etapa ANTERIOR (ffmpeg durante o OCR). Parecia travado, e
    # nao estava. Agora a tela tem batimento proprio, uma vez por segundo.
    # Barato: Update-ProvaDeVida so mede de 2 em 2s e o disco de 5 em 5s,
    # os dois com trava propria - o pulso nao muda essa conta.
    if ($Estado.Atual -eq "rodando") { Update-Progresso }
})

# 16.9: fechar a conta da etapa passou a viver em UM lugar so. Antes o bloco
# estava solto dentro do handler "etapa", e dai vinham dois defeitos que
# apareciam em todo log: (a) a linha da 1/7 saia ANTES da 1/7 comecar, medindo
# o diagnostico, e (b) a etapa 7/7 NUNCA fechava, porque nao vem nenhuma etapa
# depois dela - no lote de 2 videos, a 7/7 do primeiro so "fechava" no
# diagnostico do segundo, com o tempo errado. Agora quem fecha e esta funcao,
# chamada nos TRES pontos em que uma etapa de verdade termina: troca de etapa,
# troca de arquivo e fim do lote.
function Fechar-EtapaNoLog {
    if (-not $Motor.T0Etapa) { return }
    $parede  = ((Get-Date) - $Motor.T0Etapa).TotalSeconds
    $liquido = [math]::Max(0, $parede - $Motor.PausadoEtapa)
    # 16.39: etapa que nao tinha nada pra fazer NAO e etapa que durou zero.
    # No Se7en (log de 18/08 16h44) a [2/5] e a [3/5] fecharam com 00m 00s
    # cada, porque o DV ja era 8.1 e o audio foi mantido na mao - as duas nao
    # tinham trabalho nenhum. "fechada: 00m 00s" le como se elas tivessem
    # rodado num piscar; "PULADA" diz o que de fato aconteceu. Quem sabe e o
    # PESO: peso 0 e exatamente "esta etapa nao vai rodar neste arquivo".
    $pesoDaEtapa = 0.0
    $lp = @($script:PesosDoVideoAtual)
    if ($lp.Count -gt $Motor.EtapaIdx -and $Motor.EtapaIdx -ge 0) { $pesoDaEtapa = [double]$lp[$Motor.EtapaIdx] }
    if ($pesoDaEtapa -le 0 -and $liquido -lt 2) {
        Escrever-Log ("ETAPA {0}/{1} PULADA - nada a fazer neste arquivo" -f `
            ($Motor.EtapaIdx + 1), $Cfg.Etapas.Count) "PROVA"
    } else {
        Escrever-Log ("ETAPA {0}/{1} fechada: parede {2} | pausado {3} | TRABALHO REAL {4}" -f `
            ($Motor.EtapaIdx + 1), $Cfg.Etapas.Count, (Format-MinSeg $parede),
            (Format-MinSeg $Motor.PausadoEtapa), (Format-MinSeg $liquido)) "PROVA"
    }
    $Motor.T0Etapa = $null
    $Motor.PausadoEtapa = 0.0; $Motor.PausaIni = $null
}

$TimerFila.add_Tick({
    $m = $null
    while ($script:FilaMsg.TryDequeue([ref]$m)) {
        switch ($m.T) {
            "log"   { Escrever-Log $m.Texto $m.Tipo }
            "etapa" {
                # Fecha a conta da etapa anterior ANTES de trocar de etapa.
                Fechar-EtapaNoLog
                # A primeira [1/7] de cada arquivo nao fecha etapa nenhuma: o
                # que terminou ali foi o DIAGNOSTICO. Ele ganhou linha propria
                # em vez de entrar na conta de uma etapa que nem comecou.
                if ($Motor.T0Diag) {
                    Escrever-Log ("DIAGNOSTICO do arquivo: parede {0}" -f `
                        (Format-MinSeg ((Get-Date) - $Motor.T0Diag).TotalSeconds)) "PROVA"
                    $Motor.T0Diag = $null
                }
                $Motor.PausadoEtapa = 0.0; $Motor.PausaIni = $null
                $Motor.Nota = ""; $Motor.Fase = ""
                $Motor.LogPctUltimo = -100; $Motor.LogPctEm = Get-Date
                $Motor.EtapaIdx = $m.Idx; $Motor.PctEtapa = 0; $Motor.SegEtapa = 0
                $Motor.HoraEtapa = (Get-Date).ToString("HH'h'mm")
                $Motor.T0Etapa = Get-Date
                $Motor.PctUltimo = -1; $Motor.PctUltimoEm = Get-Date
                Update-LivreAgora $true
                # 16.38: a coluna SITUAÇÃO mostra a etapa do vídeo que está
                # convertendo - então ela precisa ser redesenhada quando a
                # etapa muda. São 5 vezes por vídeo, não por segundo.
                Fill-Fila $Estado.Atual
                if ($Estado.Atual -eq "rodando") { Update-Progresso }
            }
            "pct"   {
                if ([int]$m.Pct -ne [int]$Motor.PctUltimo) {
                    $Motor.PctUltimo = [int]$m.Pct; $Motor.PctUltimoEm = Get-Date
                }
                $Motor.PctEtapa = $m.Pct; $Motor.SegEtapa = $m.SegEtapa
                $Motor.SegVideo = $m.SegVideo; $Motor.RestVideo = $m.RestVideo
                if ([double]$m.Fator -gt 0) { $Motor.FatorRegua = [double]$m.Fator }
                if ($Estado.Atual -eq "rodando") { Update-Progresso }
                # PROGRESSO no log: a cada 5% ou a cada 60s parado, o que vier
                # primeiro. Com isso o log sozinho mostra a barra andando (ou
                # nao andando) e nao precisa mais de print junto.
                $pctN = [int]$m.Pct
                $segLog = if ($Motor.LogPctEm) { ((Get-Date) - $Motor.LogPctEm).TotalSeconds } else { 999 }
                if (($pctN - $Motor.LogPctUltimo) -ge 5 -or $segLog -ge 60) {
                    $Motor.LogPctUltimo = $pctN; $Motor.LogPctEm = Get-Date
                    $parede = if ($Motor.T0Etapa) { ((Get-Date) - $Motor.T0Etapa).TotalSeconds } else { 0 }
                    # 16.36: mesma correcao da tela - o log dizia "(nenhum
                    # processo do motor)" durante o Corretor e o Reocr, que
                    # rodam dentro de um powershell.exe filho. Agora registra
                    # a SUB-ETAPA anunciada pelo motor quando nao ha
                    # executavel proprio de pe.
                    $quem = if ($Motor.VidaNomes) { $Motor.VidaNomes }
                            elseif ("$($Motor.Nota)".Trim()) { "$($Motor.Nota)".Trim() }
                            else { "(nenhum processo do motor)" }
                    # 16.47: durante uma FASE o log dizia "etapa 1/5" - foi
                    # essa linha que mostrou o defeito da barra no diagnostico,
                    # e ela mesma estava mentindo. Agora nomeia o que roda.
                    $ondeLog = if ($Motor.Fase) { "$($Motor.Fase)" }
                               else { "etapa {0}/{1}" -f ($Motor.EtapaIdx + 1), $Cfg.Etapas.Count }
                    # 16.49: mesma correcao da tela - sem delta nao ha consumo
                    # que signifique alguma coisa, entao o log escreve
                    # "começando" em vez de um zero que parece travamento.
                    $cpuLog = if ($Motor.VidaSemMedida) { "começando" }
                              else { "{0}% CPU" -f $Motor.VidaPct }
                    Escrever-Log ("PROGRESSO: {0} - {1}% - decorrido {2} (pausado {3}) - {4} · {5}" -f `
                        $ondeLog, $pctN, (Format-MinSeg $parede),
                        (Format-MinSeg $Motor.PausadoEtapa), $quem, $cpuLog) "PROVA"
                }
            }
            "arquivo" {
                # 16.9: aqui termina o video ANTERIOR - e com ele a etapa 7/7,
                # que ate a 16.8 nunca fechava. Depois de fechar, o relogio que
                # comeca e o do DIAGNOSTICO do novo arquivo, nao o de etapa.
                Fechar-EtapaNoLog
                $Motor.T0Diag = Get-Date
                $Motor.VideoNome = $m.Nome; $Motor.VideoIdx = $m.Idx; $Motor.VideoTotal = $m.Total
                $Motor.HoraVideo = (Get-Date).ToString("HH'h'mm")
                <#  16.44: O ESTADO DE ETAPA DO ARQUIVO ANTERIOR FICAVA GRUDADO.
                    O motor anuncia "ARQUIVO n/N" ANTES do [DIAGNOSTICO] do
                    arquivo novo. Como este handler nao zerava EtapaIdx nem
                    Fase, os dois chegavam aqui valendo o que o arquivo
                    ANTERIOR deixou: EtapaIdx=4 e Fase="Limpando temporarios".
                    Com isso, nos primeiros segundos de todo arquivo a partir
                    do segundo a tela mostrava o nome NOVO com a regua INTEIRA
                    VERDE e "Limpando temporarios" - a mesma contradicao que a
                    16.43 acabou de tirar da regua, entrando por outra porta.
                    So aparece em fila de dois ou mais videos, que e o caso de
                    hoje a noite. #>
                $Motor.EtapaIdx = 0
                $Motor.Fase = ""
                # 16.47: arquivo novo = plano novo. O rotulo da etapa nao pode
                # herdar o "3/3" do arquivo anterior enquanto o novo diagnostica.
                $script:UltimoRotuloEtapa = ""
                # 16.38: trocou de arquivo - a marca de "convertendo" muda de
                # linha, e a anterior vira "Convertido".
                Fill-Fila $Estado.Atual
                $Motor.T0Video = Get-Date
                $Motor.SegVideo = 0
                # Comeca pela estimativa do lote em vez de zero: com zero, a
                # linha da FILA dizia "Termina às ~<agora>" enquanto o video
                # inteiro ainda estava pela frente.
                $Motor.RestVideo = 0
                if ($m.Idx -ge 0 -and $m.Idx -lt $script:LoteAtual.Count) {
                    $Motor.RestVideo = [double]$script:LoteAtual[$m.Idx].SegEstimado
                    # 16.39: a janela precisa dos pesos DESTE video pra saber
                    # quais etapas nao vao rodar (peso 0) - ver Fechar-EtapaNoLog
                    # e Set-Regua.
                    $script:PesosDoVideoAtual = @($script:LoteAtual[$m.Idx].Pesos)
                    $script:SegEtapasDoVideoAtual = @($script:LoteAtual[$m.Idx].SegEtapas)
                }
                # A tela passa a mostrar as faixas e o diagnostico de QUEM ESTA
                # CONVERTENDO. Antes ficava no video que estivesse selecionado -
                # e durante a conversao do The Last of Us o painel de baixo
                # mostrava o diagnostico do Lara Croft, que nao tem nada a ver.
                # Continua sendo so a selecao inicial: clicar em outra linha
                # segue funcionando.
                for ($iv = 0; $iv -lt $script:Videos.Count; $iv++) {
                    if ("$($script:Videos[$iv].Nome)" -eq "$($m.Nome)") {
                        if ($UI.lstFila.SelectedIndex -ne $iv) { $UI.lstFila.SelectedIndex = $iv }
                        break
                    }
                }
                Escrever-Log ("Convertendo {0}/{1}: {2}" -f ($m.Idx + 1), $m.Total, $m.Nome) "MOTOR"
                if ($Estado.Atual -eq "rodando") { Update-Progresso }
            }
            "nota"  {
                $Motor.Nota = "$($m.Texto)"
                if ($Estado.Atual -eq "rodando") { Update-Progresso }
            }
            "fase"  {
                # 16.37: diagnostico e limpeza. Nao fecham etapa, nao mexem na
                # regua e nao entram na conta do tempo restante - so dizem na
                # tela o que esta acontecendo entre uma etapa e outra.
                <#  16.70: relogio proprio da FASE. O da ETAPA nao reinicia
                    quando comeca a verificacao (ela nao e etapa), entao no
                    print do Diego a conferencia aparecia com "02m 23s"
                    decorridos - o tempo da etapa 5, nao o dela. #>
                if ("$($Motor.Fase)" -ne "$($m.Nome)") { $Motor.T0Fase = Get-Date }
                $Motor.Fase = "$($m.Nome)"
                $Motor.Nota = ""
                if ($Estado.Atual -eq "rodando") { Update-Progresso }
            }
            "ack"   {
                if ($script:TsAcao) {
                    $lat = ((Get-Date) - $script:TsAcao).TotalMilliseconds
                    Escrever-Log ("Motor confirmou '{0}' {1:0} ms depois da tecla/clique" -f $m.V, $lat) "PROVA"
                    $script:TsAcao = $null
                }
            }
            "ferr"  {
                $script:Ferramentas = @($m.Lista)
                Update-Ferramentas
                Update-FerramentasTopo
            }
            "vazio" { $UI.txtDisco.Text = $m.Motivo }
            "leitura_ini" { Escrever-Log ("Lendo {0} arquivo(s)..." -f $m.Total) "LEITURA" }
            "leitura_pct" {
                $Janela.Title = "$NOME_APP  ·  Lendo {0}/{1} - {2}" -f ($m.Idx + 1), $m.Total, $m.Nome
            }
            "video" {
                $d = $m.Dados
                $d.TamanhoTxt = Format-GB $d.Bytes
                # Nasce marcado quem tem o que converter de verdade.
                # "Ignorar" cobre so Ja-Existe-na-Saida/Erro-na-Leitura agora
                # (m3c15); "Nada a Converter" nao trava mais o video, entao
                # precisa ser checado aqui em separado pra nao nascer marcado
                # sozinho so por nao estar "Ignorado".
                $d.Marcado = (-not $d.Ignorar) -and ($d.DVprecisa -or $d.AUprecisa -or $d.LGprecisa)
                [void]$script:Videos.Add($d)
                Fill-Fila "inicial"
                if ($UI.lstFila.SelectedIndex -lt 0) { $UI.lstFila.SelectedIndex = 0 }
                Update-CabecalhoFila
                Update-Disco
            }
            "leitura_fim" {
                $script:Lendo = $false
                $UI.btnReler.IsEnabled = $true
                $UI.lblReler.Text = "Atualizar"
                $ativos = @(Get-Marcados).Count
                Escrever-Log ("Leitura concluida: {0} lido(s), {1} erro(s), {2:N2}s" -f $m.Ok, $m.Erros, $m.Seg) "LEITURA"
                Escrever-Log ("SELECAO: {0} de {1} marcado(s) automaticamente (tem trabalho)" -f $ativos, $script:Videos.Count) "ACAO"
                Fill-Fila "inicial"
                if ($script:Videos.Count -gt 0 -and $UI.lstFila.SelectedIndex -lt 0) { $UI.lstFila.SelectedIndex = 0 }
                Update-Diagnostico
                # m3c23: Update-Selecao ja faz Update-CabecalhoFila e
                # Update-Disco - chamar os dois aqui antes era trabalho dobrado
                # a cada arquivo lido (e Update-Disco estima o tamanho de todos
                # os videos marcados, nao e barato).
                Update-Selecao
                if (Test-PastasIguais) { $Janela.Title = "$NOME_APP  ·  Origem e Saída São a Mesma Pasta" }
                Stop-Motor
                if ($script:ReleituraPendente) {
                    $script:ReleituraPendente = $false
                    Start-Leitura
                }
            }
            "fim"   {
                if ($script:TsCancel) {
                    $lat = ((Get-Date) - $script:TsCancel).TotalSeconds
                    Escrever-Log ("Motor encerrou {0:0.0}s depois do pedido de cancelamento" -f $lat) "PROVA"
                    $script:TsCancel = $null
                }
                # 16.9: a ultima etapa do ultimo video fecha AQUI - e o unico
                # ponto em que da pra saber que ela acabou.
                Fechar-EtapaNoLog
                $TimerFilaRelogio.Stop()
                $script:Resultados = @($m.Resultados)
                Show-Resumo $m.Como
            }
        }
    }
})

# ---- Resumo final -----------------------------------------------------------
# 16.1: os cartoes eram CHUMBADOS (nome do Fallout, "39,42 GB", "E-AC-3 Atmos
# 5.1"). Agora vem do $resultados que o motor devolve - o mesmo objeto que
# alimenta o resumo do console. Nada aqui inventa numero.
$script:Resultados = @()
$script:LoteAtual  = @()

# Traducao dos codigos do motor para o vocabulario da tela. Cada selo segue o
# padrao ja fechado: MAIUSCULO, seta "→", audio como E-AC-3[ATMOS].
# O motor guarda o fps cru ("24000/1001"). O cartao chumbado antigo mostrava
# "23,976 fps (24000/1001)" - a conta e a fracao, e as duas informacoes servem:
# a primeira pra ler, a segunda pra conferir.
function Format-Fps([string]$Raw) {
    if ([string]::IsNullOrWhiteSpace($Raw)) { return "-" }
    if ($Raw -match '^\s*(\d+)\s*/\s*(\d+)\s*$' -and [double]$Matches[2] -ne 0) {
        return ("{0:N3} fps ({1})" -f ([double]$Matches[1] / [double]$Matches[2]), $Raw.Trim())
    }
    return $Raw
}

function Get-SelosResultado($R) {
    $selos = @()
    switch ("$($R.StatusDV)") {
        "OK"             { $selos += ,@("Dolby Vision → Profile 8.1 - CONVERTIDO", "ok") }
        "NAO_NECESSARIO" { $selos += ,@("Dolby Vision Já em Profile 8.1 - NÃO NECESSÁRIO", "cinza") }
    }
    switch ("$($R.StatusAudio)") {
        "OK" {
            $destino = if ("$($R.TipoConvAudio)" -eq "DTS") { "E-AC-3 640k" } else { "E-AC-3[ATMOS] 1152k" }
            $selos += ,@("Áudio → $destino - CONVERTIDO", "ok")
        }
        # JA_OTIMO e o caso do The Last of Us: o motor reaproveitou uma faixa
        # Atmos/JOC que ja existia, que pode ser PIOR do que a que o DeeZy
        # geraria. E ambar pela mesma regra da coluna AUDIO - houve perda.
        "JA_OTIMO"       {
            # 16.8: JA_OTIMO cobre DOIS casos diferentes e o selo dizia "Atmos"
            # nos dois. No Troy isso virou uma frase falsa na tela: a faixa
            # reaproveitada era um AC-3 448k DUBLADO, nao um Atmos. O motor ja
            # distingue os dois pelo MotivoAudio - aqui e so ler o que ele disse.
            <#  16.59: O TERCEIRO CASO DO JA_OTIMO - E ELE MENTIA NA TELA.
                JA_OTIMO cobria DOIS casos ate a 16.58 e o motor 13.3 criou um
                TERCEIRO sem que este switch soubesse: "Conversao de Audio
                Desligada na Escolha Manual". Como o motivo nao casa com
                "Atmos/JOC", ele caia no else e o cartao escrevia:

                    Áudio E-AC-3/AC-3 Já Existente - REAPROVEITADO   (âmbar)

                Tres mentiras numa frase so, vistas no teste de 27/08 00h21:
                  1. Nada foi reaproveitado - o usuario mandou MANTER a faixa.
                  2. O audio era TrueHD Atmos, nao E-AC-3/AC-3 - a propria
                     tabela logo abaixo dizia "TrueHD Atmos 7.1".
                  3. Ambar significa "houve perda"; aqui nao houve perda
                     NENHUMA - ficou o audio LOSSLESS, o melhor do arquivo.
                O motor ja distingue o caso pelo MotivoAudio e ja escreve
                "[NAO NECESSARIO]" no log - quem estava errado era so a tela. #>
            if ("$($R.MotivoAudio)" -match "(?i)escolha manual") {
                $codAu = "$($R.CodecAudio)".Trim()
                if ($codAu -eq "" -or $codAu -eq "-") { $codAu = "Original" }
                $selos += ,@("Áudio $codAu Mantido a Pedido - CONVERSÃO DESLIGADA", "cinza")
            } else {
                # 16.8: JA_OTIMO cobre dois casos e o selo dizia "Atmos" nos
                # dois. No Troia isso virou frase falsa: a faixa reaproveitada
                # era AC-3 448k DUBLADO. O motor distingue pelo MotivoAudio.
                $rotAu = if ("$($R.MotivoAudio)" -match "Atmos/JOC") {
                    "Áudio E-AC-3[ATMOS] Já Existente - REAPROVEITADO"
                } else {
                    "Áudio E-AC-3/AC-3 Já Existente - REAPROVEITADO"
                }
                $selos += ,@($rotAu, "warn")
            }
        }
        "NAO_NECESSARIO" { $selos += ,@("Áudio - NÃO NECESSÁRIO", "cinza") }
        "ERRO"           { $selos += ,@("Áudio - ERRO", "err") }
    }
    switch ("$($R.StatusLegenda)") {
        "OK"             { $selos += ,@("Legenda PGS → .SRT - CONVERTIDA", "ok") }
        "JA_TEXTO"       { $selos += ,@("Legenda PT-BR [.SRT] - REAPROVEITADA", "warn") }
        # v16.32: status novo do motor 13.8 - a PT-BR ja em texto existia,
        # mas foi excluida por escolha manual no Modo Manual. Antes disso
        # sempre caia em JA_TEXTO (que so checa se OCR era necessario, nao
        # se a faixa sobreviveu ate o arquivo final) - o selo dizia
        # REAPROVEITADA bem ao lado da tabela de faixas dizendo "Nenhuma".
        "DESCARTADA_MANUAL" { $selos += ,@("Legenda PT-BR [.SRT] - DESCARTADA A PEDIDO", "cinza") }
        "NAO_NECESSARIO" { $selos += ,@("Legenda - NÃO NECESSÁRIA", "cinza") }
        "ERRO"           { $selos += ,@("Legenda - ERRO", "err") }
    }
    <#  16.47: UM SELO SO PARA DUAS COISAS QUE PODEM DISCORDAR.
        "Áudios e Legendas Extras - DESCARTADOS" aparecia quando QUALQUER um
        dos dois tivesse sido filtrado. No Fallout S02E04 o áudio foi filtrado
        e a legenda NAO (modo seguro, por não haver PT-BR): o cartão dizia
        "Legendas Extras - DESCARTADOS" com as 33 legendas do original
        intactas dentro do arquivo, listadas logo abaixo no próprio cartão.
        O selo contradizia a tabela que ele mesmo encabeça.
        Agora cada um responde por si, e o "mantidas" também é dito - porque
        manter 33 legendas é uma informação, não a ausência de uma. #>
    if ($R.DescarteAudio -and $R.DescarteLegenda) {
        $selos += ,@("Áudios e Legendas Extras - DESCARTADOS", "cinza")
    } elseif ($R.DescarteAudio) {
        $selos += ,@("Áudios Extras - DESCARTADOS  ·  Legendas - TODAS MANTIDAS", "cinza")
    } elseif ($R.DescarteLegenda) {
        $selos += ,@("Legendas Extras - DESCARTADAS  ·  Áudios - TODOS MANTIDOS", "cinza")
    } else {
        $selos += ,@("Áudios e Legendas - TODOS MANTIDOS (Modo Seguro)", "cinza")
    }
    # A virgula NAO e enfeite: sem ela, um unico selo volta desmontado em duas
    # strings soltas e o cartao sairia com "ok" escrito como se fosse um selo.
    return ,$selos
}

# 16.12: ate a 16.11 as linhas Audio e Legenda do cartao vinham dos ROTULOS
# que o motor montou a partir do arquivo de ORIGEM. Dava textos que nao
# descreviam o arquivo que ficou: no Troia saiu "Brazilian / PGS [OCR/SRT] +
# SubRip/SRT" - e no arquivo final NAO HA nenhuma PGS (a legenda pt-BR virou
# .srt e a inglesa ja era .srt), nem da pra saber qual e qual idioma, nem
# qual e a padrao. Agora o cartao LE O ARQUIVO FINAL e diz o que esta nele.
# Se a leitura falhar por qualquer motivo, cai no texto antigo do motor - o
# cartao nunca fica pior do que era.
function Get-CaminhoMkvmerge {
    if ($script:MkvmergePath) { return $script:MkvmergePath }
    $r = Get-ChildItem -Path $script:PastaScript -Filter "mkvmerge.exe" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($r) { $script:MkvmergePath = $r.FullName }
    return $script:MkvmergePath
}

function Get-NomeIdioma([string]$Iso, [string]$Ietf) {
    # So para a TELA. Nao decide nada - o motor e quem trata idioma de fato.
    $v = "$Ietf".Trim(); if (-not $v) { $v = "$Iso".Trim() }
    $b = ($v -split "-")[0].ToLower()
    $mapa = @{ "en"="Inglês"; "eng"="Inglês"; "pt"="Português"; "por"="Português";
               "es"="Espanhol"; "spa"="Espanhol"; "fr"="Francês"; "fre"="Francês"; "fra"="Francês";
               "de"="Alemão"; "ger"="Alemão"; "deu"="Alemão"; "it"="Italiano"; "ita"="Italiano";
               "ja"="Japonês"; "jpn"="Japonês"; "ko"="Coreano"; "kor"="Coreano";
               "zh"="Chinês"; "chi"="Chinês"; "zho"="Chinês"; "ru"="Russo"; "rus"="Russo" }
    $nome = $v
    if ($mapa.ContainsKey($b)) { $nome = $mapa[$b] }
    if ("$Ietf" -match "-BR") { $nome = "Português (Brasil)" }
    if ("$Ietf" -match "-US") { $nome = "Inglês (EUA)" }
    if (-not $nome -or $nome -eq "und") { $nome = "sem idioma marcado" }
    return $nome
}

# v16.34: o mesmo idioma escrito de outro jeito continua sendo o mesmo
# idioma. O grupo do release chama a faixa de "Portuguese (Brazilian)" ou
# "Brazilian / PGS"; a tela ja diz "Português (Brasil)". Sem esta tabela o
# diagnostico repetia "Brazilian" depois de ja ter dito "Português".
$script:ApelidosIdioma = @{
    "por" = @("portugues","portuguese","brasil","brazil","brazilian","br","pt","ptbr","pob","luso")
    "eng" = @("ingles","english","en","us","usa","uk","gb")
    "spa" = @("espanhol","spanish","espanol","es")
    "fra" = @("frances","french","francais","fr")
    "deu" = @("alemao","german","deutsch","de","ger")
    "ita" = @("italiano","italian","it")
    "jpn" = @("japones","japanese","ja","jp")
    "kor" = @("coreano","korean","ko")
    "zho" = @("chines","chinese","zh","chi")
    "rus" = @("russo","russian","ru")
    "nld" = @("holandes","dutch","nederlands","nl","dut")
    "swe" = @("sueco","swedish","sv")
    "nor" = @("norgues","norueges","norwegian","no")
    "dan" = @("dinamarques","danish","da")
    "fin" = @("finlandes","finnish","fi")
    "pol" = @("polones","polish","pl")
    "tur" = @("turco","turkish","tr")
    "ara" = @("arabe","arabic","ar")
    "heb" = @("hebraico","hebrew","he")
    "hin" = @("hindi","hi")
    "tha" = @("tailandes","thai","th")
    "ces" = @("tcheco","czech","cs","cze")
    "hun" = @("hungaro","hungarian","hu")
    "ell" = @("grego","greek","el","gre")
    "ron" = @("romeno","romanian","ro","rum")
    "ind" = @("indonesio","indonesian","id")
    "msa" = @("malaio","malay","ms","may")
    "vie" = @("vietnamita","vietnamese","vi")
    "ukr" = @("ucraniano","ukrainian","uk")
    "cat" = @("catalao","catalan","ca")
    "eus" = @("basco","basque","eu","baq")
    "glg" = @("galego","galician","gl")
    "tam" = @("tamil","ta")
    "tel" = @("telugu","te")
    "kan" = @("kannada","kn")
    "mal" = @("malaiala","malayalam","ml")
}

function Get-ApelidosDoIdioma {
    param([string]$Cod3, [string]$Cod2)
    $saida = New-Object System.Collections.Generic.List[string]
    foreach ($c in @($Cod3, $Cod2)) {
        if ([string]::IsNullOrWhiteSpace($c)) { continue }
        $k = $c.ToLowerInvariant()
        [void]$saida.Add($k)
        if ($script:ApelidosIdioma.ContainsKey($k)) {
            foreach ($a in $script:ApelidosIdioma[$k]) { [void]$saida.Add($a) }
        }
    }
    # busca cruzada: se veio "pt" e a tabela e por "por", acha assim mesmo
    foreach ($k in $script:ApelidosIdioma.Keys) {
        foreach ($a in $script:ApelidosIdioma[$k]) {
            if ($saida -contains $a) {
                [void]$saida.Add($k)
                foreach ($b in $script:ApelidosIdioma[$k]) { [void]$saida.Add($b) }
                break
            }
        }
    }
    return ,($saida | Select-Object -Unique)
}

# v16.34: tira acento pra comparar texto. A Janela nao tinha isso - o
# Corretor e o Reocr tem o deles. Usado pelo Get-SoOQueAcrescenta, que
# precisa fazer "Português" casar com "Portugues".
function Get-SemAcentoJanela {
    param([string]$Texto)
    if ([string]::IsNullOrEmpty($Texto)) { return "" }
    $d = $Texto.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $d.ToCharArray()) {
        if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne
            [System.Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($ch) }
    }
    return $sb.ToString().Normalize([System.Text.NormalizationForm]::FormC)
}

<#
      --- v16.34: FIM DA REPETICAO NO DIAGNOSTICO FINAL ---

      O cartao mostrava, numa linha so:
          DTS-HD Master Audio 7.1  ·  Inglês  ·  DTS-HD MA 7.1   <- padrão
      "DTS-HD Master Audio" e "DTS-HD MA" sao a MESMA coisa escrita de dois
      jeitos, e o "7.1" aparecia duas vezes. A guarda antiga era
      `if ($nome -ne $codec)` - comparacao literal, que nunca casa quando o
      grupo do release escreve o codec abreviado. Na legenda era pior:
          Português  ·  SubRip/SRT  ·  Portugues (Brasil) [OCR]   <- padrão
      "Português" e "Portugues (Brasil)" repetidos, um com acento e outro sem.

      Esta funcao pega o NOME da faixa e devolve so o que ele acrescenta de
      verdade. Ela quebra o nome em pedacos (por espaco, ponto, barra, tra;o,
      colchete e parentese), joga fora todo pedaco que ja esta dito no codec,
      nos canais ou no idioma - comparando SEM acento, SEM pontuacao e SEM
      caixa, que e o que faz "MA" casar com "Master" nao casar por engano e
      "Portugues" casar com "Português".

      O que sobra e o que interessa: Atmos, JOC, OCR, SDH, Forcada,
      Comentario, Legendado. Se nao sobra nada, a linha nao repete nada.
#>
<#  16.38: -SoTermosTecnicos
    O DIAGNOSTICO FINAL e uma FICHA TECNICA, nao a etiqueta do release. Ate a
    16.37 ele repetia o nome cru da faixa e saia assim:

        E-AC-3  ·  Far Field Surround Mix  ·  5.1  ·  Inglês

    "Far Field Surround Mix" e o nome que o estudio deu a mixagem. Nao muda
    nada do que a ficha responde (o que e, quantos canais, que idioma) e come
    metade da linha - com tres faixas, vira um varal.
    O que MUDA a leitura sao os termos fechados: Comentário, Forçada,
    Descritiva, Legendada, Latino, Castelhano... Esses ficam. Nome livre de
    mixagem sai.
    Ligado so no painel final. Onde o nome da faixa E a informacao (a aba
    Faixas, onde voce escolhe qual manter), ele continua inteiro.
#>
function Get-SoOQueAcrescenta {
    param([string]$Nome, [string[]]$JaDito, [switch]$SoTermosTecnicos)

    if ([string]::IsNullOrWhiteSpace($Nome)) { return "" }

    # normalizador: sem acento, sem pontuacao, minusculo
    $limpar = {
        param([string]$S)
        $sem = Get-SemAcentoJanela $S
        return ($sem -replace '[^0-9A-Za-z]', '').ToLowerInvariant()
    }

    # tudo que ja foi dito vira um saco de pedacos normalizados
    $saco = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($d in $JaDito) {
        if ([string]::IsNullOrWhiteSpace($d)) { continue }
        foreach ($ped in ($d -split '[\s\.\-\/\[\]\(\)_,:]+')) {
            $n = & $limpar $ped
            if ($n.Length -ge 1) { [void]$saco.Add($n) }
        }
        # o nome inteiro tambem, pra "DTSHDMasterAudio" bater com "DTSHDMA"
        $inteiro = & $limpar $d
        if ($inteiro.Length -ge 1) { [void]$saco.Add($inteiro) }
    }

    $sobrou = New-Object System.Collections.Generic.List[string]
    foreach ($ped in ($Nome -split '[\s\.\-\/\[\]\(\)_,:]+')) {
        if ([string]::IsNullOrWhiteSpace($ped)) { continue }
        $n = & $limpar $ped
        if ($n.Length -eq 0) { continue }
        if ($saco.Contains($n)) { continue }

        # pedaco que e ABREVIACAO de algo ja dito (MA dentro de Master, ou
        # Portugues dentro de PortuguesBrasil) tambem nao acrescenta.
        $ehParte = $false
        foreach ($s in $saco) {
            if ($s.Length -gt $n.Length -and $s.StartsWith($n)) { $ehParte = $true; break }
            if ($n.Length -gt $s.Length -and $n.StartsWith($s) -and $s.Length -ge 4) { $ehParte = $true; break }
        }
        if ($ehParte) { continue }

        # numero solto que nao seja canal (2.0, 5.1, 7.1) nao diz nada
        if ($ped -match '^[0-9]+$') { continue }

        [void]$sobrou.Add($ped)
    }

    if ($sobrou.Count -eq 0) { return "" }

    # v16.34: o marcador vem em ingles no arquivo. A tela e em portugues -
    # nao faz sentido escrever "Forced" no meio de "Português · HDMV PGS".
    # So os termos fechados sao traduzidos; nome de mixagem ("Far Field
    # Surround Mix") passa inteiro, porque ali o texto E a informacao.
    $traduz = @{
        "forced" = "Forçada"; "forcada" = "Forçada"
        "commentary" = "Comentário"; "comment" = "Comentário"
        "descriptive" = "Descritiva"; "narration" = "Narração"
        "songs" = "Canções"; "signs" = "Letreiros"
        "dubbed" = "Dublada"; "subtitled" = "Legendada"
        "director" = "diretor"; "cast" = "elenco"; "crew" = "equipe"
        "simplified" = "Simplificado"; "traditional" = "Tradicional"
        "latin" = "Latino"; "american" = ""; "castilian" = "Castelhano"
        "parisian" = "Parisiense"; "metropolitan" = ""
        "by" = "do"; "the" = ""; "of" = "de"; "and" = "e"; "with" = "com"
        # 16.38: marcadores de acessibilidade sao FICHA TECNICA, nao nome de
        # release - dizem pra quem a legenda serve. Sem eles, "English SDH" e
        # "English" viravam a mesma linha na tela.
        "sdh" = "SDH"; "cc" = "CC"; "hi" = "SDH"; "hearingimpaired" = "SDH"
    }
    $final = New-Object System.Collections.Generic.List[string]
    foreach ($s in $sobrou) {
        $ch = (Get-SemAcentoJanela $s).ToLowerInvariant() -replace '[^a-z]', ''
        if ($traduz.ContainsKey($ch)) {
            # traducao vazia = palavra de ligacao que nao acrescenta ("the")
            if ($traduz[$ch] -ne "") { [void]$final.Add($traduz[$ch]) }
        } elseif (-not $SoTermosTecnicos) { [void]$final.Add($s) }
    }
    if ($SoTermosTecnicos) {
        # As ligacoes ("do", "de", "e", "com") so valem ENTRE dois termos que
        # ficaram - "Comentário do diretor" le melhor que "Comentário
        # diretor". Sozinhas, ou nas pontas, nao dizem nada: apara.
        $ehLig = { param($x) ("$x" -match '^(?i)(do|de|e|com)$') }
        $lista = @($final)
        while ($lista.Count -gt 0 -and (& $ehLig $lista[0])) { $lista = @($lista[1..($lista.Count-1)]) }
        while ($lista.Count -gt 0 -and (& $ehLig $lista[$lista.Count-1])) { $lista = @($lista[0..($lista.Count-2)]) }
        if ($lista.Count -eq 0) { return "" }
        return ($lista -join " ")
    }
    return ($final -join " ")
}

function Get-DescricaoDoFinal([string]$CaminhoMkv) {
    $saida = @{ Audio = $null; Legenda = $null }
    if (-not $CaminhoMkv -or -not (Test-Path -LiteralPath $CaminhoMkv)) { return $saida }
    $exe = Get-CaminhoMkvmerge
    if (-not $exe) { return $saida }
    $j = $null
    try {
        $bruto = & $exe -J "$CaminhoMkv" 2>$null
        $j = ($bruto | Out-String) | ConvertFrom-Json
    } catch { return $saida }
    if (-not $j -or -not $j.tracks) { return $saida }

    $au = @(); $lg = @()
    foreach ($t in $j.tracks) {
        $p = $t.properties
        $idioma = Get-NomeIdioma "$($p.language)" "$($p.language_ietf)"
        $nome   = "$($p.track_name)".Trim()
        $codec  = "$($t.codec)".Trim()
        # v16.34: a marca de faixa padrao era "   <- padrão" colada no fim da
        # linha. Com 2 faixas ja desalinhava; com 30 legendas (o Fallout tem
        # 30) virava um varal. Agora e um simbolo NA FRENTE, que alinha as
        # linhas em coluna e le de cima pra baixo sem procurar o fim.
        $marca = "    "
        if ($p.default_track) { $marca = " " + $Sim.Padrao + "  " }
        if ("$($t.type)" -eq "audio") {
            $canais = ""
            if ($p.audio_channels) { $canais = Get-CanaisTexto ([int]$p.audio_channels) }
            $apel = Get-ApelidosDoIdioma "$($p.language)" "$($p.language_ietf)"
            $extra = Get-SoOQueAcrescenta $nome (@($codec, $canais, $idioma) + $apel) -SoTermosTecnicos
            $partes = @($codec)
            if ($extra)  { $partes += $extra }
            if ($canais) { $partes += $canais }
            $partes += $idioma
            $au += ($marca + ($partes -join "  ·  "))
        } elseif ("$($t.type)" -eq "subtitles") {
            $apel = Get-ApelidosDoIdioma "$($p.language)" "$($p.language_ietf)"
            $extra = Get-SoOQueAcrescenta $nome (@($codec, $idioma) + $apel) -SoTermosTecnicos
            $partes = @($idioma, $codec)
            if ($extra) { $partes += $extra }
            $lg += ($marca + ($partes -join "  ·  "))
        }
    }
    if ($au.Count -gt 0) { $saida.Audio   = ($au -join "`n") }
    if ($lg.Count -gt 0) { $saida.Legenda = ($lg -join "`n") }
    return $saida
}

function New-CartaoResultado($R) {
    $bc = [System.Windows.Media.BrushConverter]::new()
    $b = New-Object System.Windows.Controls.Border
    $b.CornerRadius = "0,8,8,0"; $b.Padding = "12,10"; $b.Margin = "0,0,0,8"
    $pilha = New-Object System.Windows.Controls.StackPanel
    $b.Child = $pilha
    function Add-LinhaTxt($Painel,$Texto,$Cor,$Tam=13.5,$Mono=$true,$MargemBaixo=0,$Peso="Normal") {
        $t = New-Object System.Windows.Controls.TextBlock
        $t.Text = $Texto; $t.FontSize = $Tam; $t.TextWrapping = "Wrap"
        $t.FontWeight = $Peso
        if ($Mono) { $t.FontFamily = New-Object System.Windows.Media.FontFamily("Consolas") }
        $t.Foreground = $bc.ConvertFromString($Cor)
        $t.Margin = "0,0,0,$MargemBaixo"
        $Painel.Children.Add($t) | Out-Null
    }
    $status = "$($R.Status)"
    switch ($status) {
        "OK"         { $fundo = "#0B1109"; $borda = $Cores.okBorda;    $ico = $Sim.Ok;   $corNome = $Cores.foco }
        "OK_PARCIAL" { $fundo = "#100E08"; $borda = $Cores.pausaBorda; $ico = $Sim.Warn; $corNome = $Cores.foco }
        "PULADO"     { $fundo = "#100E08"; $borda = $Cores.pausaBorda; $ico = $Sim.Skip; $corNome = $Cores.txt }
        "CANCELADO"  { $fundo = "#110809"; $borda = $Cores.errBorda;   $ico = $Sim.Err;  $corNome = $Cores.txt }
        default      { $fundo = "#110809"; $borda = $Cores.errBorda;   $ico = $Sim.Err;  $corNome = $Cores.txt }
    }
    $b.Background = $bc.ConvertFromString($fundo)
    $b.BorderBrush = $bc.ConvertFromString($borda); $b.BorderThickness = "2,1,1,1"
    Add-LinhaTxt $pilha ("{0} {1}" -f $ico, $R.Episodio) $corNome 14.5 $true 8 "SemiBold"

    if ($status -eq "OK" -or $status -eq "OK_PARCIAL") {
        $selos = New-Object System.Windows.Controls.WrapPanel
        foreach ($par in (Get-SelosResultado $R)) {
            switch ($par[1]) {
                "ok"    { $fs = $Cores.okdim;  $ft = "#0B1A08" }
                "warn"  { $fs = $Cores.warn;   $ft = "#2A2410" }
                "err"   { $fs = $Cores.err;    $ft = "#1A0809" }
                default { $fs = $Cores.dim;    $ft = "#101010" }
            }
            $selo = New-Object System.Windows.Controls.Border
            $selo.Background = $bc.ConvertFromString($fs); $selo.CornerRadius = "4"
            $selo.Padding = "8,3"; $selo.Margin = "0,0,5,5"
            $st = New-Object System.Windows.Controls.TextBlock
            $st.Text = $par[0]; $st.FontSize = 12.5; $st.Foreground = $bc.ConvertFromString($ft)
            $selo.Child = $st; $selos.Children.Add($selo) | Out-Null
        }
        $pilha.Children.Add($selos) | Out-Null

        $fpsTxt = Format-Fps "$($R.Fps)"
        # A leitura do arquivo final custa uma chamada de mkvmerge por video,
        # em um momento em que a conversao ja acabou - e o unico jeito de o
        # cartao falar do arquivo que existe, e nao do que se pretendia fazer.
        $descFinal = Get-DescricaoDoFinal (Join-Path $Cfg.Saida ("{0}.mkv" -f $R.Episodio))
        $txtAudio = "-"
        if ($descFinal.Audio) { $txtAudio = $descFinal.Audio }
        elseif ($R.FaixasAudioMantidas) { $txtAudio = "$($R.FaixasAudioMantidas)" }
        $txtLegenda = "-"
        if ($descFinal.Legenda) { $txtLegenda = $descFinal.Legenda }
        elseif ($R.FaixasLegendaMantidas) { $txtLegenda = "$($R.FaixasLegendaMantidas)" }
        # 16.36: o rotulo diz o que a estrela significa, e SO quando existe
        # uma estrela naquela linha. Marca sem legenda e enigma; legenda fixa
        # numa lista sem marca nenhuma e ruido.
        $rotAudio   = "Áudio"
        $rotLegenda = "Legenda"
        if ($txtAudio   -like ("*" + $Sim.Padrao + "*")) { $rotAudio   = "Áudio  ({0} = faixa padrão)"   -f $Sim.Padrao }
        if ($txtLegenda -like ("*" + $Sim.Padrao + "*")) { $rotLegenda = "Legenda  ({0} = faixa padrão)" -f $Sim.Padrao }
        <#  16.55: A QUALIDADE DA LEGENDA ENTRA NO CARTAO.
            O veredicto existia desde a 14.28 - o motor calculava, escrevia no
            log e imprimia na tela da conversao. Mas o cartao final e montado
            a partir dos CAMPOS do objeto de resultado, um a um, e linha solta
            de saida nao entra nele. Resultado na rodada de 26/08 11h28: a
            nota estava no log das 12:30:36 e o usuario nao via nada ao fim de
            1h05 de conversao - justamente o dado que decide se ele assiste
            pela .SRT ou troca para a PGS original.
            Entra logo DEPOIS da linha das faixas de legenda, que e onde a
            pergunta nasce ("ficaram duas; qual eu uso?"). #>
        <#  16.57: A LINHA DA QUALIDADE, REESCRITA.
            A primeira versao despejava o numero cru:
                BOA - 5 de 1904 blocos com defeito (0,26%) - pode assistir por ela
            Tres problemas. "5 de 1904 blocos com defeito" e vocabulario de
            relatorio tecnico, nao de quem acabou de converter um filme e quer
            saber se pode assistir. A porcentagem repetia a mesma informacao
            numa terceira forma. E o veredicto ficava perdido no meio da
            frase, do mesmo tamanho do resto.

            Agora: veredicto em CAIXA ALTA na frente, a consequencia pratica
            logo depois, e o detalhe numerico por ultimo e entre parenteses -
            quem quiser confere, quem nao quiser le so as duas primeiras
            palavras e ja sabe o que fazer. #>
        $linhaQualidade = $null
        if ($R.PSObject.Properties.Name -contains 'NotaLegendaVeredicto' -and
            $R.NotaLegendaVeredicto -and $R.NotaLegendaVeredicto -ne "") {
            $vq = [string]$R.NotaLegendaVeredicto
            switch ($vq) {
                "EXCELENTE" { $acao = "Nenhuma falha encontrada. Pode assistir por esta legenda." }
                "BOA"       { $acao = "Pode assistir por esta legenda." }
                "RAZOAVEL"  { $acao = "Dá para assistir. Se tropeçar numa fala, troque no player para a legenda PGS original." }
                default     { $acao = "Prefira a legenda PGS original - ela está neste mesmo arquivo." }
            }
            <#  16.62: A LINHA DIZIA A MESMA COISA DUAS VEZES.
                No Troy saia assim:
                  "EXCELENTE - Nenhuma falha encontrada. Pode assistir por
                   esta legenda.   (nenhuma falha em 1378 legendas)"
                "Nenhuma falha" aparecia na frase E no parenteses. E o
                parenteses comecava em minuscula, contra o padrao da tela.
                O parenteses existe para dar o NUMERO - o veredicto e a frase
                ja dizem o resto. Quando nao ha falha, o numero que interessa
                e quantas legendas foram conferidas; quando ha, e quantas
                falharam de quantas. Nos dois casos ele agora comeca com
                maiuscula ou com algarismo, nunca com palavra minuscula. #>
            $det = ""
            if ($R.NotaLegendaDefeitos -ge 0 -and $R.NotaLegendaBlocos -gt 0) {
                if ($R.NotaLegendaDefeitos -eq 0) {
                    $det = ("     ({0} legendas conferidas)" -f $R.NotaLegendaBlocos)
                } elseif ($R.NotaLegendaDefeitos -eq 1) {
                    $det = ("     (1 falha em {0} legendas)" -f $R.NotaLegendaBlocos)
                } else {
                    $det = ("     ({0} falhas em {1} legendas)" -f $R.NotaLegendaDefeitos, $R.NotaLegendaBlocos)
                }
            }
            <#  16.59: A LINHA DA QUALIDADE GANHA COR.
                Ate a 16.58 o veredicto saia no mesmo cinza do resto da
                tabela: BOA, RAZOAVEL e RUIM tinham exatamente o mesmo peso
                visual, e a unica diferenca era o usuario LER a palavra. Numa
                tela que ja usa verde/ambar/laranja/vermelho em todo o resto
                (selos, coluna da fila, situacao), essa era a unica nota do
                programa que nao se anunciava sozinha.
                Mesma escala do resto da janela, sem cor nova:
                  EXCELENTE -> verde       (ok)
                  BOA       -> verde claro (okdim) - bom, mas nao impecavel
                  RAZOAVEL  -> laranja     (lar)   - da pra usar, com ressalva
                  RUIM      -> vermelho    (err)   - nao use esta faixa
                Laranja e nao ambar: ambar ja e PAUSADO no rodape. #>
            $corQ = switch ($vq) {
                "EXCELENTE" { $Cores.ok }
                "BOA"       { $Cores.okdim }
                "RAZOAVEL"  { $Cores.lar }
                default     { $Cores.err }
            }
            $linhaQualidade = @("Qualidade da Legenda", ($vq + "  -  " + $acao + $det), $corQ)
        }
        $grade = @(
            @("Container Final", ("Matroska (.mkv)  |  {0}" -f $R.Tamanho)),
            @($rotAudio,   $txtAudio),
            @($rotLegenda, $txtLegenda))
        if ($null -ne $linhaQualidade) { $grade += ,$linhaQualidade }
        $grade += ,@("Duração / Taxa de Quadros", ("{0}  |  {1}" -f $R.DuracaoVideo, $fpsTxt))
        $grade += ,@("Tempo de Processamento", "$($R.Tempo)")
        # 16.16: era uma pilha de DockPanel com a primeira coluna de largura
        # fixa. Funcionava enquanto cada valor era uma linha; desde que o
        # Audio e a Legenda passaram a listar UMA FAIXA POR LINHA, o texto
        # ficava boiando ao lado de um rotulo sem nenhuma referencia visual.
        # Agora e uma Grid de verdade: duas colunas, uma linha por item, e um
        # fio separando as linhas - o mesmo tom das colunas das tabelas.
        $tab = New-Object System.Windows.Controls.Grid
        $tab.Margin = "0,4,0,0"
        $cRot = New-Object System.Windows.Controls.ColumnDefinition
        $cRot.Width = "215"
        $cVal = New-Object System.Windows.Controls.ColumnDefinition
        $cVal.Width = "*"
        $tab.ColumnDefinitions.Add($cRot) | Out-Null
        $tab.ColumnDefinitions.Add($cVal) | Out-Null
        $fio = $bc.ConvertFromString($Cores.borda)
        $iLinha = 0
        foreach ($linha in $grade) {
            $rd = New-Object System.Windows.Controls.RowDefinition
            $rd.Height = "Auto"
            $tab.RowDefinitions.Add($rd) | Out-Null
            # A ultima linha nao leva fio embaixo - fio no rodape da tabela
            # parece corte, nao separacao.
            $baixo = 1
            if ($iLinha -eq ($grade.Count - 1)) { $baixo = 0 }

            $celRot = New-Object System.Windows.Controls.Border
            $celRot.BorderBrush = $fio
            $celRot.BorderThickness = "0,0,1,$baixo"
            $celRot.Padding = "0,4,10,4"
            $r1 = New-Object System.Windows.Controls.TextBlock
            $r1.Text = $linha[0]; $r1.FontSize = 13.5
            $r1.TextWrapping = "Wrap"
            $r1.Foreground = $bc.ConvertFromString($Cores.dim)
            $celRot.Child = $r1

            $celVal = New-Object System.Windows.Controls.Border
            $celVal.BorderBrush = $fio
            $celVal.BorderThickness = "0,0,0,$baixo"
            $celVal.Padding = "10,4,0,4"
            $r2 = New-Object System.Windows.Controls.TextBlock
            $r2.Text = $linha[1]; $r2.FontSize = 13.5
            # Uma faixa por linha: com tres faixas de audio, tudo numa linha so
            # vira uma tira ilegivel.
            $r2.TextWrapping = "Wrap"
            $r2.FontFamily = New-Object System.Windows.Media.FontFamily("Consolas")
            # 16.59: terceiro item da linha = cor do valor. Quem nao traz cor
            # continua no cinza de sempre - so a qualidade da legenda usa.
            $corVal = $Cores.txt
            if (@($linha).Count -ge 3 -and "$($linha[2])" -ne "") { $corVal = [string]$linha[2] }
            $r2.Foreground = $bc.ConvertFromString($corVal)
            $celVal.Child = $r2

            [System.Windows.Controls.Grid]::SetRow($celRot, $iLinha)
            [System.Windows.Controls.Grid]::SetColumn($celRot, 0)
            [System.Windows.Controls.Grid]::SetRow($celVal, $iLinha)
            [System.Windows.Controls.Grid]::SetColumn($celVal, 1)
            $tab.Children.Add($celRot) | Out-Null
            $tab.Children.Add($celVal) | Out-Null
            $iLinha++
        }
        $pilha.Children.Add($tab) | Out-Null
    } else {
        $frase = switch ($status) {
            "PULADO"    { "Ignorado - Já Existia na Pasta de Saída" }
            "CANCELADO" { "Cancelado pelo Usuário" }
            default     { "Não Finalizado - Erro" }
        }
        $corFrase = if ($status -eq "PULADO") { $Cores.warn } else { $Cores.err }
        Add-LinhaTxt $pilha ("Situação   {0}" -f $frase) $corFrase 13.5 $true 2
        if ("$($R.Motivo)") { Add-LinhaTxt $pilha ("Motivo     {0}" -f $R.Motivo) $corFrase 13.5 }
        if ("$($R.Tempo)")  { Add-LinhaTxt $pilha ("Tempo      {0}" -f $R.Tempo) $Cores.dim 13.5 }
    }
    return $b
}

function Show-Resumo([string]$Como) {
    $bc = [System.Windows.Media.BrushConverter]::new()
    $UI.pilhaCartoes.Children.Clear()
    $res = @($script:Resultados)

    $ok        = @($res | Where-Object { "$($_.Status)" -eq "OK" })
    $parcial   = @($res | Where-Object { "$($_.Status)" -eq "OK_PARCIAL" })
    $falhou    = @($res | Where-Object { "$($_.Status)" -eq "FALHOU" })
    $pulado    = @($res | Where-Object { "$($_.Status)" -eq "PULADO" })
    $cancelado = @($res | Where-Object { "$($_.Status)" -eq "CANCELADO" })
    <#  16.44: $Motor.SegFila e "+1 a cada tique de DispatcherTimer". Tique
        perdido (CPU saturada pelo DeeZy/ffmpeg) e segundo perdido, e o resumo
        saia com um total MENOR que o "Decorrido" que a propria tela mostrava
        um segundo antes. O relogio de parede ja existe e ja e usado durante a
        conversao - agora o resumo usa o mesmo. #>
    $totalSeg = [math]::Max(0, $Motor.SegFila)
    if ($Motor.T0Fila) {
        $paredeFila = ((Get-Date) - $Motor.T0Fila).TotalSeconds
        if ($paredeFila -gt $totalSeg) { $totalSeg = $paredeFila }
    }
    $tempoTxt  = Format-MinSeg $totalSeg
    $agora     = (Get-Date).ToString("HH'h'mm")

    if ($Como -eq "concluida") {
        $UI.icoResumo.Text = $Sim.Ok
        $UI.icoResumo.Foreground = $bc.ConvertFromString($Cores.ok)
        $UI.lblResumoTitulo.Text = "Conversão Concluída"
        $Janela.Title = "$NOME_APP  ·  Conversão Concluída às $agora"
        $UI.lblResumoTempos.Text = "Começou às $($Motor.HoraFila) - Terminou às $agora - Tempo Total $tempoTxt"
    } else {
        $UI.icoResumo.Text = $Sim.Err
        $UI.icoResumo.Foreground = $bc.ConvertFromString($Cores.err)
        $UI.lblResumoTitulo.Text = "Conversão Interrompida"
        $Janela.Title = "$NOME_APP  ·  Conversão Interrompida às $agora"
        $UI.lblResumoTempos.Text = "Começou às $($Motor.HoraFila) - Interrompida às $agora - Tempo Total $tempoTxt"
    }

    $linhas = @()
    # 16.44: contava $res (o que o motor CHEGOU a processar). Cancelando o 2o
    # de 3, o resumo dizia "Total: 2" e "Cancelados: 1" - sumia um video da
    # contabilidade. O total pedido esta no lote.
    $totalPedido = @($script:LoteAtual).Count
    if ($totalPedido -lt $res.Count) { $totalPedido = $res.Count }
    $linhas += "Total de Vídeos na Fila       : {0}" -f $totalPedido
    $linhas += "Convertidos com Sucesso       : {0}" -f $ok.Count
    if ($parcial.Count   -gt 0) { $linhas += "Convertidos com Avisos        : {0}" -f $parcial.Count }
    if ($pulado.Count    -gt 0) { $linhas += "Ignorados (Já Existiam)       : {0}" -f $pulado.Count }
    if ($falhou.Count    -gt 0) { $linhas += "Não Finalizados (Erro)        : {0}" -f $falhou.Count }
    if ($cancelado.Count -gt 0) { $linhas += "Cancelados pelo Usuário       : {0}" -f $cancelado.Count }
    $linhas += "Tempo Total                   : {0}" -f $tempoTxt
    $UI.txtContadores.Text = ($linhas -join "`n")

    if ($res.Count -eq 0) {
        $UI.txtContadores.Text = "O motor não devolveu nenhum resultado.`nTempo Total                   : $tempoTxt"
    }
    foreach ($r in $res) { $UI.pilhaCartoes.Children.Add((New-CartaoResultado $r)) | Out-Null }

    # Detalhamento: conta o que REALMENTE aconteceu, sem repetir o numero de
    # sucessos como se tudo tivesse acontecido em todos.
    $comDV  = @($res | Where-Object { "$($_.StatusDV)" -eq "OK" }).Count
    $comAu  = @($res | Where-Object { "$($_.StatusAudio)" -eq "OK" }).Count
    $reapAu = @($res | Where-Object { "$($_.StatusAudio)" -eq "JA_OTIMO" -and "$($_.MotivoAudio)" -match "Atmos/JOC" }).Count
    # 16.59: "mantido a pedido" nao e "reaproveitado" - ver Get-SelosResultado.
    # Sem esta separacao o resumo de 27/08 contou 1 em "E-AC-3/AC-3
    # Reaproveitado" num arquivo que saiu com TrueHD Atmos e nenhum E-AC-3.
    $manAu  = @($res | Where-Object { "$($_.StatusAudio)" -eq "JA_OTIMO" -and "$($_.MotivoAudio)" -match "(?i)escolha manual" }).Count
    $reapC2 = @($res | Where-Object { "$($_.StatusAudio)" -eq "JA_OTIMO" -and "$($_.MotivoAudio)" -notmatch "Atmos/JOC" -and "$($_.MotivoAudio)" -notmatch "(?i)escolha manual" }).Count
    $comLg  = @($res | Where-Object { "$($_.StatusLegenda)" -eq "OK" }).Count
    $reapLg = @($res | Where-Object { "$($_.StatusLegenda)" -eq "JA_TEXTO" }).Count
    # v16.32: contador separado - ver o comentario em Get-SelosResultado.
    $descLg = @($res | Where-Object { "$($_.StatusLegenda)" -eq "DESCARTADA_MANUAL" }).Count
    $det = @()
    $det += "Dolby Vision Convertido para Profile 8.1  : {0}" -f $comDV
    $det += "Áudio Convertido para E-AC-3[ATMOS]       : {0}" -f $comAu
    if ($reapAu -gt 0) { $det += "Áudio E-AC-3[ATMOS] Reaproveitado         : {0}" -f $reapAu }
    if ($reapC2 -gt 0) { $det += "Áudio E-AC-3/AC-3 Reaproveitado           : {0}" -f $reapC2 }
    if ($manAu  -gt 0) { $det += "Áudio Mantido a Pedido (sem converter)    : {0}" -f $manAu }
    $det += "Legenda PGS Convertida para .SRT          : {0}" -f $comLg
    if ($reapLg -gt 0) { $det += "Legenda PT-BR [.SRT] Reaproveitada        : {0}" -f $reapLg }
    if ($descLg -gt 0) { $det += "Legenda PT-BR [.SRT] Descartada a Pedido  : {0}" -f $descLg }
    $UI.txtDetalhamento.Text = ($det -join "`n")

    $UI.txtRodapeResumo.Text = "Pasta de Saída: $($Cfg.Saida)`nLog completo desta sessão: $($script:LogArquivo)"

    # 16.9: o resumo tambem vai pro LOG. Ate a 16.8 a sessao terminava com
    # "ESTADO: rodando -> fim" e mais nada - quem abrisse o log depois nao
    # sabia quantos converteram, quais falharam nem em quanto tempo, que e
    # justamente o que fecha a conta. Log autossuficiente e regra do projeto,
    # e o fim do log era o unico lugar onde ela nao valia.
    Escrever-Log "===== RESUMO DA CONVERSAO =====" "PROVA"
    foreach ($l in $linhas) { Escrever-Log $l "PROVA" }
    foreach ($l in $det)    { Escrever-Log $l "PROVA" }
    foreach ($r in $res) {
        Escrever-Log ("{0} | {1} | {2}" -f "$($r.Episodio)", "$($r.Status)", "$($r.Tempo)") "PROVA"
    }
    Set-Estado "fim"
}

# ---- Janelas auxiliares (Log / Ferramentas) --------------------------------
function Show-JanelaTexto([string]$Titulo, [string]$Conteudo) {
    $w = New-Object System.Windows.Window
    $w.Title = $Titulo; $w.Width = 780; $w.Height = 460
    $w.WindowStartupLocation = "CenterOwner"; $w.Owner = $Janela
    $w.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Cores.fundo)
    $tb = New-Object System.Windows.Controls.TextBox
    $tb.Text = $Conteudo; $tb.IsReadOnly = $true; $tb.BorderThickness = 0
    $tb.FontFamily = New-Object System.Windows.Media.FontFamily("Consolas"); $tb.FontSize = 14
    $tb.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Cores.fundo)
    $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Cores.txt)
    $tb.VerticalScrollBarVisibility = "Auto"; $tb.Padding = "12"
    $tb.TextWrapping = "Wrap"          # sem isto a linha some pela direita
    $w.Content = $tb
    $w.add_ContentRendered({ $tb.ScrollToEnd() })   # log longo abre no fim
    $w.ShowDialog() | Out-Null
}

<#  16.64: O SELETOR DE PASTA ANTIGO ERA UMA ARVORINHA SEM CAMINHO.
    O FolderBrowserDialog do .NET Framework e o dialogo de 1998: arvore de
    pastas, sem barra de endereco, sem poder digitar nem colar caminho, sem
    "recentes". O Diego reclamou com razao - em pasta funda (G:\Series\Nome
    Longo\Temporada 2) sao dez cliques para chegar onde um Ctrl+V resolveria.
    O dialogo MODERNO (o mesmo do "Salvar como" do Explorer, com barra de
    endereco, favoritos, busca e caminho digitavel) existe no Windows desde o
    Vista, mas o .NET Framework nunca o expos - so o .NET 5+ expos, e o
    PowerShell 5.1 do Diego roda em .NET Framework 4.8. Entao vai por COM:
    IFileDialog com a opcao FOS_PICKFOLDERS ligada.
    A declaracao abaixo tem que manter a ORDEM EXATA dos metodos na vtable do
    COM, inclusive os que nao uso - por isso os placeholders vazios. Chamar
    um deles quebraria; declarar fora de ordem quebraria calado, que e pior.
    Se qualquer coisa falhar (Windows antigo, politica, Add-Type bloqueado),
    cai no dialogo velho: seletor feio e melhor que nenhum seletor. #>
$script:DialogoModernoOk = $null
function Initialize-DialogoModerno {
    if ($null -ne $script:DialogoModernoOk) { return $script:DialogoModernoOk }
    $script:DialogoModernoOk = $false
    try {
        if (-not ([System.Management.Automation.PSTypeName]'LaFirma.SeletorDePasta').Type) {
            Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace LaFirma {
    [ComImport, Guid("DC1C5A9C-E88A-4dde-A5A1-60F82A20AEF7")]
    internal class FileOpenDialogCoClass { }

    [ComImport, Guid("43826D1E-E718-42EE-BC55-A1E261C37BFE"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IShellItem {
        void BindToHandler(IntPtr pbc, ref Guid bhid, ref Guid riid, out IntPtr ppv);
        void GetParent(out IShellItem ppsi);
        void GetDisplayName(uint sigdnName, [MarshalAs(UnmanagedType.LPWStr)] out string ppszName);
        void GetAttributes(uint sfgaoMask, out uint psfgaoAttribs);
        void Compare(IShellItem psi, uint hint, out int piOrder);
    }

    [ComImport, Guid("42F85136-DB7E-439C-85F1-E4075D135FC8"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IFileDialog {
        [PreserveSig] int Show(IntPtr parent);
        void SetFileTypes(uint cFileTypes, IntPtr rgFilterSpec);
        void SetFileTypeIndex(uint iFileType);
        void GetFileTypeIndex(out uint piFileType);
        void Advise(IntPtr pfde, out uint pdwCookie);
        void Unadvise(uint dwCookie);
        void SetOptions(uint fos);
        void GetOptions(out uint pfos);
        void SetDefaultFolder(IShellItem psi);
        void SetFolder(IShellItem psi);
        void GetFolder(out IShellItem ppsi);
        void GetCurrentSelection(out IShellItem ppsi);
        void SetFileName([MarshalAs(UnmanagedType.LPWStr)] string pszName);
        void GetFileName([MarshalAs(UnmanagedType.LPWStr)] out string pszName);
        void SetTitle([MarshalAs(UnmanagedType.LPWStr)] string pszTitle);
        void SetOkButtonLabel([MarshalAs(UnmanagedType.LPWStr)] string pszText);
        void SetFileNameLabel([MarshalAs(UnmanagedType.LPWStr)] string pszLabel);
        void GetResult(out IShellItem ppsi);
        void AddPlace(IShellItem psi, uint fdap);
        void SetDefaultExtension([MarshalAs(UnmanagedType.LPWStr)] string pszDefaultExtension);
        void Close(int hr);
        void SetClientGuid(ref Guid guid);
        void ClearClientData();
        void SetFilter(IntPtr pFilter);
    }

    public static class SeletorDePasta {
        [DllImport("shell32.dll", CharSet = CharSet.Unicode, PreserveSig = false)]
        private static extern void SHCreateItemFromParsingName(
            [MarshalAs(UnmanagedType.LPWStr)] string pszPath, IntPtr pbc,
            ref Guid riid, [MarshalAs(UnmanagedType.Interface)] out IShellItem ppv);

        // FOS_PICKFOLDERS | FOS_FORCEFILESYSTEM | FOS_PATHMUSTEXIST | FOS_NOCHANGEDIR
        private const uint OPCOES = 0x00000020 | 0x00000040 | 0x00000800 | 0x00000008;
        private const uint SIGDN_FILESYSPATH = 0x80058000;

        public static string Escolher(string inicial, string titulo, IntPtr dono) {
            IFileDialog dlg = (IFileDialog)(new FileOpenDialogCoClass());
            try {
                dlg.SetOptions(OPCOES);
                if (!string.IsNullOrEmpty(titulo)) { dlg.SetTitle(titulo); }
                if (!string.IsNullOrEmpty(inicial) && System.IO.Directory.Exists(inicial)) {
                    Guid iid = typeof(IShellItem).GUID;
                    IShellItem item;
                    SHCreateItemFromParsingName(inicial, IntPtr.Zero, ref iid, out item);
                    if (item != null) { dlg.SetFolder(item); }
                }
                int hr = dlg.Show(dono);
                if (hr != 0) { return null; }          // 0x800704C7 = o usuario cancelou
                IShellItem res;
                dlg.GetResult(out res);
                string caminho;
                res.GetDisplayName(SIGDN_FILESYSPATH, out caminho);
                return caminho;
            } finally {
                if (dlg != null) { Marshal.ReleaseComObject(dlg); }
            }
        }
    }
}
'@
        }
        $script:DialogoModernoOk = $true
    } catch {
        Escrever-Log ("SELETOR: dialogo moderno indisponivel ({0}) - usando o antigo" -f $_.Exception.Message) "AVISO"
    }
    return $script:DialogoModernoOk
}

function Select-Pasta([string]$Atual, [string]$Titulo = "Escolha a pasta") {
    if (Initialize-DialogoModerno) {
        try {
            $dono = [IntPtr]::Zero
            try { $dono = (New-Object System.Windows.Interop.WindowInteropHelper($Janela)).Handle } catch { }
            $r = [LaFirma.SeletorDePasta]::Escolher($Atual, $Titulo, $dono)
            if ($r) { return $r }
            return $null
        } catch {
            Escrever-Log ("SELETOR: dialogo moderno falhou na hora de abrir ({0}) - caindo no antigo" -f $_.Exception.Message) "AVISO"
            $script:DialogoModernoOk = $false
        }
    }
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = $Titulo
    $dlg.ShowNewFolderButton = $true
    if (Test-Path -LiteralPath $Atual) { $dlg.SelectedPath = $Atual }
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $dlg.SelectedPath }
    return $null
}

# ---- Diagnostico e textos fixos da demo ------------------------------------
$script:PastaScript = Split-Path -Parent $PSCommandPath
$script:CaminhoMotor = Join-Path $script:PastaScript "Converter_AUTO_DIRETO.ps1"
Descobrir-Pastas
# A tela observa esta colecao do inicio ao fim da sessao.
$UI.lstFila.ItemsSource = $script:LinhasFila
$UI.lstFaixas.ItemsSource = $script:LinhasFaixas

# A coluna NOME e a "flex": ocupa a largura que sobra, matando o espaco morto
# a direita e mostrando o nome inteiro. As demais colunas sao arrastaveis (o
# gripper voltou ao cabecalho); o NOME reabsorve a diferenca no proximo ajuste
# de tamanho da janela.
#
# BUG m3b6/m3b7: a v1 desta funcao somava o ActualWidth (LARGURA MEDIDA PELO
# WPF) das outras colunas pra saber quanto espaco sobra pro NOME. O teste da
# m3b7 provou que isso NAO E CONFIAVEL na transicao minimizar -> maximizar: a
# leitura vem errada (nao so zerada - qualquer valor errado), o calculo de
# "espaco livre" sai gigante, o NOME engole a tela.
#
# m3b8 trocou a leitura por uma memoria propria (script:LimitesCol.Atual) -
# resolveu a leitura errada, mas sobrou um SEGUNDO bug, achado no teste da
# m3b8 ao ARRASTAR A JANELA PRA ENCOLHER: a funcao so ATUALIZAVA o Width do
# NOME quando "disp -gt 220" - ou seja, quando a janela encolhia rapido o
# bastante pra "disp" cair abaixo disso, a funcao simplesmente NAO FAZIA NADA,
# e o NOME ficava PRESO no valor antigo (grande) enquanto a janela ao redor
# continuava menor - o NOME sozinho passava a ser maior que a janela inteira,
# empurrando as outras colunas pra fora da area visivel.
#
# CORRECAO m3b9: a funcao agora SEMPRE define uma largura valida pro NOME -
# nunca "pula" a atualizacao. Se nao sobra espaco confortavel, ela encolhe o
# NOME ate o minimo dele (o Limitar-Coluna abaixo trava mesmo assim, isso e
# so a segunda camada de garantia). Tambem foi dado um TETO ao NOME (era sem
# limite - por isso ficava enorme, com metade da tela em branco, quando a
# janela maximizava): agora ele para de crescer numa largura confortavel pro
# nome de arquivo, sobrando espaco de verdade pras outras colunas.
function Update-LarguraNome {
    if (-not $UI.lstFila.View) { return }
    if (-not $script:LimitesCol -or $script:LimitesCol.Count -eq 0) { return }  # ainda nao inicializado
    $limNome = $script:LimitesCol[$UI.colFila]
    if (-not $limNome) { return }
    $outras    = 0.0
    $minOutras = 0.0
    foreach ($c in $UI.lstFila.View.Columns) {
        if ([Object]::ReferenceEquals($c, $UI.colFila)) { continue }
        $lim = $script:LimitesCol[$c]
        if (-not $lim) { continue }
        $outras    += $lim.Atual
        $minOutras += $lim.Min
    }
    $disp       = $UI.lstFila.ActualWidth - $outras - 24       # ~barra de rolagem + bordas
    $tetoSeguro = $UI.lstFila.ActualWidth - $minOutras - 24    # teto: minimo garantido das outras
    # 15.1a: BLINDAGEM. Se qualquer parcela vier invalida (NaN/Infinito), o
    # calculo inteiro contamina e o Width da coluna vira NaN - e Width NaN no
    # WPF significa AUTO, entao a coluna passa a crescer com o TEXTO e ignora o
    # teto de 620. Foi exatamente o que o Diego viu: NOME com ~1314px empurrando
    # LEGENDA e SITUACAO pra fora da tela na janela maximizada, e nenhuma
    # reducao das OUTRAS colunas resolvia, porque o problema nunca esteve nelas.
    if ([double]::IsNaN($disp) -or [double]::IsInfinity($disp))             { $disp = $limNome.Max }
    if ([double]::IsNaN($tetoSeguro) -or [double]::IsInfinity($tetoSeguro)) { $tetoSeguro = $limNome.Max }
    if ($disp -gt $tetoSeguro)  { $disp = $tetoSeguro }
    if ($disp -gt $limNome.Max) { $disp = $limNome.Max }
    if ($disp -lt $limNome.Min) { $disp = $limNome.Min }
    # Ultima barreira: nunca deixar sair NaN daqui, aconteca o que acontecer.
    if ([double]::IsNaN($disp)) { $disp = $limNome.Max }
    if ($disp -ne $UI.colFila.Width) {
        $UI.colFila.Width = $disp
        # Log de diagnostico: se o corte voltar, estes numeros dizem qual
        # parcela esta errada, em vez de eu chutar de novo.
        Escrever-Log ("LARGURA: lista={0:N0} outras={1:N0} min={2:N0} -> NOME={3:N0} (teto {4:N0})" -f `
            $UI.lstFila.ActualWidth, $outras, $minOutras, $disp, $limNome.Max) "INFO"
    }
}
$UI.lstFila.add_SizeChanged({ Update-LarguraNome })

# LIMITES DE LARGURA POR COLUNA. O GridViewColumn do WPF nao tem MinWidth/
# MaxWidth, entao vigiamos a propriedade Width via DependencyPropertyDescriptor
# e travamos nos limites - assim o usuario nao consegue mais colapsar uma coluna
# ate sumir (e nao ter como voltar). O checkbox fica fixo; o NOME (flex) so tem
# minimo; as demais tem minimo e maximo. O mesmo vigia tambem grava a largura
# ATUAL de cada coluna em .Atual - e essa memoria propria, nunca o ActualWidth
# medido pelo WPF, que o Update-LarguraNome usa pra calcular o espaco do NOME.
$script:LimitesCol = @{}
$dpdLargura = [System.ComponentModel.DependencyPropertyDescriptor]::FromProperty(
    [System.Windows.Controls.GridViewColumn]::WidthProperty,
    [System.Windows.Controls.GridViewColumn])
function Limitar-Coluna($Col, $Min, $Max) {
    $atualInicial = [double]$Col.Width
    if ([double]::IsNaN($atualInicial)) { $atualInicial = $Min }
    $script:LimitesCol[$Col] = @{ Min = [double]$Min; Max = [double]$Max; Atual = $atualInicial }
    $dpdLargura.AddValueChanged($Col, {
        param($remetente, $evento)
        $lim = $script:LimitesCol[$remetente]
        if (-not $lim) { return }
        $w = [double]$remetente.Width
        if ([double]::IsNaN($w)) {
            # 15.1c: AUTOSIZE DE VOLTA. Largura NaN no WPF significa duas coisas
            # ao mesmo tempo: o clique duplo na borda ("ajustar ao conteudo",
            # que o Diego usa) e o estado defeituoso que fazia o NOME inchar ate
            # ~1314px. A 15.1a proibia NaN e matava os dois junto.
            # Agora deixo o auto-ajuste ACONTECER e olho o RESULTADO: se a
            # largura que ele produziu couber no teto, mantem (o clique duplo
            # funciona); se estourar, trava no teto (o inchaco nao passa).
            $real = [double]$remetente.ActualWidth
            if ([double]::IsNaN($real) -or $real -le 0) { $remetente.Width = $lim.Atual; return }
            if ($real -gt $lim.Max) { $remetente.Width = $lim.Max; return }
            if ($real -lt $lim.Min) { $remetente.Width = $lim.Min; return }
            $lim.Atual = $real
            return
        }
        if     ($w -lt $lim.Min) { $remetente.Width = $lim.Min; $w = $lim.Min }
        elseif ($w -gt $lim.Max) { $remetente.Width = $lim.Max; $w = $lim.Max }
        $lim.Atual = $w
    })
}
# O minimo de cada coluna e grande o bastante para o texto ficar LEGIVEL por
# inteiro (Diego pediu), menos a coluna do nome do episodio, que pode cortar.
# Header -> (minimo, maximo) em px.
$limFila = @{
    "TAMANHO"       = @(95, 200)
    "DOLBY VISION"  = @(150, 280)
    "ÁUDIO"         = @(240, 400)
    "LEGENDA PT-BR" = @(155, 300)
    "SITUAÇÃO"      = @(180, 320)
}
$colsFila = @($UI.lstFila.View.Columns)
for ($ic = 0; $ic -lt $colsFila.Count; $ic++) {
    $c = $colsFila[$ic]
    if ($ic -eq 0)                                     { Limitar-Coluna $c 34 34; continue }       # checkbox fixo
    if ([Object]::ReferenceEquals($c, $UI.colFila))    { Limitar-Coluna $c 200 620; continue }    # NOME: pode cortar, mas nao precisa de mais que isso (era sem teto)
    $l = $limFila["$($c.Header)"]
    if ($l) { Limitar-Coluna $c $l[0] $l[1] } else { Limitar-Coluna $c 90 400 }
}
# Faixas: "NOME DA FAIXA" pode cortar (analoga ao nome do episodio); o resto legivel.
$limFx = @{ "ID"=@(45,80); "TIPO"=@(110,200); "CODEC"=@(130,260); "IDIOMA"=@(75,150); "TAMANHO"=@(80,160); "MARCAS"=@(90,180); "AÇÃO"=@(190,320) }
foreach ($c in @($UI.lstFaixas.View.Columns)) {
    if ("$($c.Header)" -eq "NOME DA FAIXA") { Limitar-Coluna $c 160 100000; continue }
    $l = $limFx["$($c.Header)"]
    if ($l) { Limitar-Coluna $c $l[0] $l[1] } else { Limitar-Coluna $c 60 400 }
}
$UI.txtOrigem.Text = $Cfg.Origem
$UI.txtSaida.Text  = $Cfg.Saida

function Format-Duracao-Curta([double]$Seg) {
    $t = [TimeSpan]::FromSeconds($Seg)
    if ($t.TotalHours -ge 1) { return "{0}h {1:D2}m" -f [int][math]::Floor($t.TotalHours), $t.Minutes }
    return "{0:D2}m {1:D2}s" -f [int][math]::Floor($t.TotalMinutes), $t.Seconds
}
$UI.txtPastasCompacto.Text = "$($Sim.Pasta) ...\00_Arquivos_Base  →  ...\01_Arquivos_Finalizados"
# A tela nasce vazia: quem escreve aqui e a leitura real.
$UI.lblDiagTitulo.Text = "DIAGNÓSTICO:"
foreach ($campo in @("diagDV","diagAu","diagLg","diagDVr","diagAur","diagLgr")) { $UI.$campo.Text = "" }
$UI.txtDisco.Text = "Lendo a pasta..."

# ---- Eventos ----------------------------------------------------------------
# As escolhas por faixa do modo Manual ainda NAO chegam ao motor. Na 16.1 isso
# era so um aviso no log e a conversao seguia - ou seja, a tela aceitava uma
# escolha que ia ser ignorada, e o Diego so descobriria 20 minutos depois,
# olhando o arquivo pronto. Agora ela nao deixa comecar.
# 16.11: o verbo que VALE para esta faixa. A mesma conta que a tabela de
# Faixas ja fazia em quatro lugares - so no Manual, so em faixa destravada e
# so quando o usuario mexeu no dropdown e que o VerboUsuario manda.
function Get-VerboEfetivo($v, $f) {
    $bloq = Test-VerboBloqueado $f
    if (("$($v.Modo)" -eq "Manual") -and (-not $bloq) -and ($null -ne $f.VerboUsuario)) {
        return "$($f.VerboUsuario)"
    }
    return "$($f.VerboAuto)"
}

# 16.11: traduz a aba Faixas para a porta do motor (13.3). O que sai daqui e
# LISTA DE IDS - nenhum julgamento. As regras de traducao, e o porque de cada
# uma:
#   - EXCLUIR simplesmente nao entra na lista;
#   - CONVERTER num audio entra na lista, porque o motor GERA UMA FAIXA NOVA
#     e mantem a original junto (etapa 6/7: "Far Field 5.1 + E-AC-3 (Novo)");
#   - CONVERTER numa legenda NAO entra na lista: ali a PGS original sai do
#     arquivo e so o .srt novo fica - e assim que o automatico se comporta, e
#     o Manual nao pode divergir disso sem o usuario ter pedido;
#   - a faixa de VIDEO nunca entra (o motor sempre mantem, regra dele);
#   - AudioPrincipal NAO e enviado de proposito: quem elege a principal e o
#     Get-FaixaAudioPrincipal do motor, e a janela so ecoa o que ele disse.
#     Mandar de volta seria a janela reimplementando a decisao dele.
function Build-EscolhasManuais {
    $tabela = @{}
    foreach ($v in (Get-Marcados)) {
        if ("$($v.Modo)" -ne "Manual") { continue }
        # Estar em Manual sem ter mexido em nada NAO e escolha: nesse caso o
        # video segue pelo automatico, sem porta aberta.
        $mexeu = @($v.Faixas | Where-Object { $null -ne $_.VerboUsuario -and -not (Test-VerboBloqueado $_) })
        if ($mexeu.Count -eq 0) { continue }

        $e = @{}
        $aud = @(); $leg = @()
        # v16.31: precisa saber se o usuario mexeu em ALGUMA faixa de
        # LEGENDA especificamente - nao so "mexeu em algo" ($mexeu acima
        # inclui audio tambem). E o que decide se $leg vazio e "usuario
        # nao tocou legenda, motor decide" ou "usuario excluiu as duas de
        # proposito" - ver o if mais abaixo.
        $legTocada = @($v.Faixas | Where-Object { $_.Tipo -eq "subtitles" -and $null -ne $_.VerboUsuario -and -not (Test-VerboBloqueado $_) })
        foreach ($f in @($v.Faixas)) {
            if ($f.Tipo -eq "video") { continue }
            $vb = Get-VerboEfetivo $v $f
            if ($f.Tipo -eq "audio") {
                if ($vb -ne "EXCLUIR") { $aud += [int]$f.Id }
                if ($f.Papel -eq "audio-principal") {
                    if ($vb -eq "CONVERTER")   { $e["ConverterPrincipal"] = $true }
                    elseif ($vb -eq "MANTER")  { $e["ConverterPrincipal"] = $false }
                }
            } elseif ($f.Tipo -eq "subtitles") {
                if ($vb -eq "MANTER")     { $leg += [int]$f.Id }
                elseif ($vb -eq "CONVERTER") { $e["LegendaPgs"] = [int]$f.Id }
            }
        }
        if ($aud.Count -gt 0) { $e["AudioManter"] = $aud }
        # v16.31: BUG CORRIGIDO - antes so mandava LegendaManter quando $leg
        # tinha pelo menos 1 id (igual o audio, "if Count -gt 0"). Pra audio
        # isso e certo (lista vazia = invalida, motor tem que decidir). Pra
        # legenda NAO E: excluir as duas de proposito e uma escolha valida, e
        # com a regra antiga essa chave NUNCA chegava vazia no motor - o
        # Resolve-FaixasDoRemux (motor 13.7) ja sabe tratar chave presente e
        # vazia como "excluir tudo", mas a chave nunca saia daqui pra ele ver.
        # Confirmado no log real: TLOU com id 30 e id 3 marcados EXCLUIR no
        # Manual, ESCOLHA MANUAL mostrava "legenda manter []" no log da
        # janela, mas o motor resolvia "Legenda: 30, 3" - as duas mantidas
        # mesmo assim, porque a chave simplesmente nao chegava. Agora manda
        # a chave sempre que alguma faixa de LEGENDA foi tocada, vazia ou nao.
        if ($leg.Count -gt 0 -or $legTocada.Count -gt 0) { $e["LegendaManter"] = $leg }
        if ($e.Count -eq 0) { continue }
        $tabela[$v.Caminho] = $e

        # O log tem que bastar sozinho: se a saida vier diferente do esperado,
        # e aqui que se ve o que foi realmente pedido ao motor.
        $txtConv = "(o motor decide)"
        if ($e.ContainsKey("ConverterPrincipal")) {
            $txtConv = if ($e["ConverterPrincipal"]) { "SIM" } else { "NAO" }
        }
        $txtPgs = "-"
        if ($e.ContainsKey("LegendaPgs")) { $txtPgs = [string]$e["LegendaPgs"] }
        Escrever-Log ("ESCOLHA MANUAL: {0} | audio manter [{1}] | converter principal = {2} | legenda manter [{3}] | PGS p/ OCR = {4}" -f `
            $v.Nome, (@($aud) -join ","), $txtConv, (@($leg) -join ","), $txtPgs) "ACAO"
    }
    # Sem return pelo pipeline (licao da 16.3/16.4): atribuicao direta.
    $script:EscolhasAtuais = $tabela
}

function Test-PodeIniciar {
    # 16.11: O BLOQUEIO SAIU. Ele existia porque as escolhas por faixa nao
    # chegavam ao motor - a tela aceitava uma escolha que ia ser ignorada e
    # voce so descobria 20 minutos depois, olhando o arquivo pronto. Agora
    # elas chegam (porta do motor 13.3, provada pela Sonda_Manual).
    # A funcao continua existindo como ponto de checagem: se um dia aparecer
    # uma escolha que o motor nao saiba executar, e aqui que ela e barrada.
    return $true
}

function Invoke-Iniciar {
    Escrever-Log "CLIQUE: Iniciar" "ACAO"
    if (-not (Test-PodeIniciar)) { return }
    # Um defeito no caminho da partida fechou o programa na sua cara na 16.4.
    # Erro aqui agora vira mensagem e log - a janela continua de pe.
    try { Invoke-IniciarInterno }
    catch {
        Escrever-Log ("FALHA ao iniciar: {0}" -f $_.Exception.Message) "ERRO"
        Escrever-Log ("   em: {0}" -f $_.InvocationInfo.PositionMessage) "ERRO"
        try { Stop-Motor } catch { }
        try { $TimerFilaRelogio.Stop() } catch { }
        Set-Estado "inicial"
        [System.Windows.MessageBox]::Show(
            ("Não consegui iniciar a conversão:`n`n{0}`n`nNada foi convertido e nenhum arquivo foi tocado. O log desta sessão tem o detalhe." -f $_.Exception.Message),
            "LaFirma - falha ao iniciar", "OK", "Error") | Out-Null
    }
}

function Invoke-IniciarInterno {
    $agora = (Get-Date).ToString("HH'h'mm")
    $script:UltimoRotuloEtapa = ""
    $Motor.EtapaIdx = 0; $Motor.PctEtapa = 0; $Motor.SegEtapa = 0
    $Motor.SegVideo = 0; $Motor.RestVideo = 0; $Motor.SegPausado = 0
    $Motor.FatorRegua = 1.0; $Motor.PausadoFila = 0; $Motor.T0Fase = $null
    $Motor.HoraFila = $agora; $Motor.HoraVideo = $agora; $Motor.HoraEtapa = $agora
    $Motor.VideoNome = ""; $Motor.VideoIdx = 0; $Motor.SegFila = 0
    Set-LoteParaConverter
    # 16.11: as escolhas sao montadas AQUI, na partida, e nao antes: assim o
    # que vai pro motor e exatamente o que estava na tela no momento em que
    # voce clicou em Iniciar.
    Build-EscolhasManuais
    $Motor.VideoTotal = @($script:LoteAtual).Count
    if ($Motor.VideoTotal -gt 0) { $Motor.RestVideo = [double]$script:LoteAtual[0].SegEstimado }
    # Soma no braco: Measure-Object nao enxerga chave de hashtable como
    # propriedade, entao devolveria vazio e o log mentiria em silencio.
    $somaEst = 0.0
    foreach ($it in @($script:LoteAtual)) { $somaEst += [double]$it.SegEstimado }
    $Motor.EstTotalFila = $somaEst
    $nManual = 0
    if ($script:EscolhasAtuais) { $nManual = @($script:EscolhasAtuais.Keys).Count }
    Escrever-Log ("LOTE: {0} video(s), estimativa total {1:N0}s, {2} com escolha manual" -f $Motor.VideoTotal, $somaEst, $nManual) "PROVA"
    $agoraDt = Get-Date
    $Motor.T0Fila = $agoraDt; $Motor.T0Video = $agoraDt
    # 16.9: o relogio da ETAPA nao comeca aqui. Entre o Iniciar e a primeira
    # [1/7] o que roda e o DIAGNOSTICO do arquivo - comecar a etapa aqui era o
    # que fazia sair "ETAPA 1/7 fechada" ANTES da 1/7 existir, com o tempo do
    # diagnostico dentro. O diagnostico tem relogio proprio agora.
    $Motor.T0Etapa = $null; $Motor.T0Diag = $agoraDt
    $Motor.PctUltimo = -1; $Motor.PctUltimoEm = $agoraDt; $Motor.LivreEm = $null
    $Motor.VidaEm = $null; $Motor.VidaCpuMs = 0.0; $Motor.VidaPct = 0
    $Motor.VidaNomes = ""; $Motor.VidaEmVida = $agoraDt
    $Motor.VidaChave = ""; $Motor.VidaSemMedida = $true
    $Motor.LogPctUltimo = -100; $Motor.LogPctEm = $agoraDt
    $Motor.PausadoEtapa = 0.0; $Motor.PausaIni = $null; $Motor.Nota = ""
    Update-LivreAgora $true
    Set-Estado "rodando"; Update-Progresso
    $TimerFilaRelogio.Start()
    Start-Motor
}
$UI.btnIniciar.add_Click({ Invoke-Iniciar })
function Invoke-TogglePausa {
    Escrever-Log ("ACAO: alternar pausa (estado atual: {0})" -f $Estado.Atual) "ACAO"
    if ($Estado.Atual -eq "rodando") {
        $script:TsAcao = Get-Date
        $script:Controle.Pausar = $true      # o motor confirma pela fila (latencia no log)
        Set-Estado "pausado"
    } elseif ($Estado.Atual -eq "pausado") {
        $script:TsAcao = Get-Date
        $script:Controle.Pausar = $false
        Set-Estado "rodando"; Update-Progresso
    }
}
# 16.12: um ESC esbarrado matou uma conversao de 30 minutos. Nao ha desfazer:
# o motor apaga a saida parcial e os temporarios do episodio. Cancelar passou
# a exigir confirmacao, com o NAO ja selecionado - assim um Enter reflexo
# tambem nao cancela nada.
function Confirm-Parar([string]$Titulo, [string]$Texto) {
    $r = [System.Windows.MessageBox]::Show($Texto, $Titulo,
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning,
            [System.Windows.MessageBoxResult]::No)
    return ($r -eq [System.Windows.MessageBoxResult]::Yes)
}

function Invoke-Cancelar {
    $oQuePerde = "o vídeo que está sendo montado agora"
    if ($Motor.VideoTotal -gt 1) {
        # 16.44: VideoIdx e 0-based. Todo o resto da tela mostra +1; so esta
        # caixa dizia "o vídeo 0 de 3" enquanto o rodapé atrás dela dizia 1/3.
        $oQuePerde = ("o vídeo {0} de {1} (o que está sendo montado agora)" -f ([int]$Motor.VideoIdx + 1), $Motor.VideoTotal)
    }
    $texto = ("Cancelar a conversão?`n`nVocê perde {0}, e o tempo já gasto nele - são {1} até aqui. O arquivo parcial é apagado.`n`nOs vídeos que já terminaram continuam na pasta de saída." -f `
                $oQuePerde, (Format-MinSeg $Motor.SegVideo))
    if (-not (Confirm-Parar "LaFirma - cancelar a conversão?" $texto)) {
        Escrever-Log "ACAO: cancelar RECUSADO na confirmacao - a conversao segue" "ACAO"
        return
    }
    # 16.23: MessageBox::Show roda uma bomba de mensagens ANINHADA - o
    # $TimerFila (100ms) continua batendo com a caixinha aberta. Ou seja: a
    # conversao pode TERMINAR enquanto o usuario le a pergunta. Nesse caso o
    # "fim" ja foi consumido, Show-Resumo ja rodou e Set-Estado "fim" ja
    # arrumou a tela - e seguir daqui gravaria Cancelar num motor morto,
    # desligaria os botoes que o fim acabou de ligar e cravaria o titulo em
    # "Cancelando..." pra sempre (o fim que limparia esse titulo ja passou).
    # Por isso o estado e RELIDO depois do modal: se saiu de rodando/pausado,
    # a resposta "Sim" perdeu a validade e a acao e abortada.
    if ($Estado.Atual -notin @("rodando","pausado")) {
        Escrever-Log ("ACAO: cancelar IGNORADO - a conversao terminou enquanto a pergunta estava aberta (estado={0})" -f $Estado.Atual) "ACAO"
        return
    }
    Escrever-Log "ACAO: cancelar - flag gravada, aguardando o motor encerrar" "ACAO"
    $script:TsCancel = Get-Date
    $script:Controle.Cancelar = $true
    $script:Controle.Pausar = $false
    $UI.btnPausar.IsEnabled = $false
    $UI.btnCancelar.IsEnabled = $false
    $Janela.Title = "$NOME_APP  ·  Cancelando - Aguardando o Motor Encerrar..."
}
$UI.btnPausar.add_Click({ Invoke-TogglePausa })
$UI.btnCancelar.add_Click({
    Escrever-Log "CLIQUE: Cancelar" "ACAO"
    if ($Estado.Atual -in @("rodando","pausado")) { Invoke-Cancelar }
})
$UI.btnNovaConversao.add_Click({
    Escrever-Log "CLIQUE: Nova Conversao (relendo a pasta - o que acabou de ser convertido ja esta na saida)" "ACAO"
    Set-Estado "inicial"
    Update-Disco
    Start-Leitura
})
$UI.btnEncerrar.add_Click({ Escrever-Log "CLIQUE: Encerrar Programa" "ACAO"; $Janela.Close() })
<#  16.64: DIGITAR O CAMINHO NA PROPRIA CAIXA.
    Ate a 16.63 as duas caixas de pasta eram TextBlock - texto morto. Para
    trocar de pasta so havia o botao. O Diego: "eu quero poder clicar no nome
    ali e ja poder mudar o local, nao tem q ir la no botao TROCAR".
    Agora sao TextBox: clica, digita ou cola, ENTER aplica. ESC desfaz e
    devolve o que estava. Sair da caixa (Tab, clicar fora) tambem aplica -
    ninguem espera que o que ele digitou seja jogado fora so porque clicou em
    outro lugar.
    Enquanto o texto nao for uma pasta que existe, a borda fica VERMELHA e
    nada e aplicado: caminho digitado errado nao pode virar leitura de pasta
    inexistente nem, pior, pasta de saida invalida na hora de gravar.
    As duas funcoes abaixo sao o MESMO codigo do botao - ele passou a chamar
    Aplicar-PastaOrigem/Saida em vez de repetir a sequencia. Assim o proximo
    conserto entra em um lugar so. #>
$script:CorBordaOk  = $Cores.borda
$script:CorBordaRuim = "#FF5C5C"
function Set-BordaPasta($Caixa, [bool]$Valida) {
    if ($null -eq $Caixa) { return }
    if ($Valida) { $Caixa.BorderBrush = Pincel $script:CorBordaOk }
    else         { $Caixa.BorderBrush = Pincel $script:CorBordaRuim }
}
function Test-CaminhoDePasta([string]$C) {
    if ([string]::IsNullOrWhiteSpace($C)) { return $false }
    try { return (Test-Path -LiteralPath $C.Trim() -PathType Container) } catch { return $false }
}
function Aplicar-PastaOrigem([string]$Novo) {
    <#  16.64: TROCAR DE PASTA NO MEIO DA CONVERSAO MATARIA A CONVERSAO.
        Start-Leitura chama Stop-Motor. Com a caixa editavel isso virou um
        caminho real: bastava o cursor estar dentro dela, o usuario digitar
        qualquer coisa e clicar fora - o LostKeyboardFocus aplicaria a pasta
        nova e derrubaria o motor no meio do arquivo, calado.
        Fora do estado "inicial" a caixa nao aplica nada e devolve o que
        estava. A caixa tambem fica somente-leitura (Set-CaixasDePastaEditaveis),
        mas a trava tem que estar AQUI tambem: quem protege o motor e a
        funcao que mexe no motor, nao a cor do controle. #>
    if ("$($Estado.Atual)" -ne "inicial") {
        $UI.txtOrigem.Text = $Cfg.Origem; Set-BordaPasta $UI.boxOrigem $true
        return $true
    }
    $Novo = "$Novo".Trim().Trim('"')
    if (-not (Test-CaminhoDePasta $Novo)) { Set-BordaPasta $UI.boxOrigem $false; return $false }
    Set-BordaPasta $UI.boxOrigem $true
    if ($Novo -eq "$($Cfg.Origem)") { return $true }
    $UI.txtOrigem.Text = $Novo; $Cfg.Origem = $Novo
    Escrever-Log "PASTA origem trocada: $Novo" "ACAO"
    Start-Leitura
    return $true
}
function Aplicar-PastaSaida([string]$Novo) {
    # Mesma trava da origem: no meio da conversao a pasta de saida ja esta
    # dentro do runspace do motor, e trocar aqui so criaria divergencia entre
    # o que a tela diz e onde o arquivo esta sendo gravado.
    if ("$($Estado.Atual)" -ne "inicial") {
        $UI.txtSaida.Text = $Cfg.Saida; Set-BordaPasta $UI.boxSaida $true
        return $true
    }
    $Novo = "$Novo".Trim().Trim('"')
    if (-not (Test-CaminhoDePasta $Novo)) { Set-BordaPasta $UI.boxSaida $false; return $false }
    Set-BordaPasta $UI.boxSaida $true
    if ($Novo -eq "$($Cfg.Saida)") { return $true }
    $UI.txtSaida.Text = $Novo; $Cfg.Saida = $Novo
    Escrever-Log "PASTA saida trocada: $Novo" "ACAO"
    # Nao relemos os videos: a pasta de saida so muda o "Ja Existe na Saida".
    Update-JaExiste
    Fill-Fila "inicial"
    Update-CabecalhoFila
    Update-Disco
    Update-Diagnostico
    Test-PastasIguais
    return $true
}
<#  16.64b: CLICAR NA CAIXA ABRE O SELETOR.
    A 16.64 tinha deixado a caixa editavel para poder colar caminho. Vendo
    funcionando, o Diego pediu o contrario: "quando eu clicar la e pra abrir
    essa janela normal". Ele tem razao e o motivo e simples - o dialogo
    moderno TEM barra de endereco e campo "Pasta:", entao colar caminho ja
    acontece dentro dele. Duas formas de fazer a mesma coisa, sendo que uma
    delas (digitar na caixa) nao tem autocompletar nem valida enquanto
    digita, e so um jeito a mais de errar.
    Agora a caixa e somente-leitura, com cursor de mao, e o clique abre o
    mesmo seletor do botao. A borda vermelha continua: se a pasta for
    apagada ou o pen drive sair, a caixa avisa sem precisar de clique.
    As caixas nao pegam foco (Focusable="False"), entao nao ha mais
    LostKeyboardFocus - o caminho que podia derrubar o motor no meio da
    conversao deixou de existir. A trava de estado dentro de
    Aplicar-PastaOrigem/Saida fica assim mesmo: ela protege o motor, e quem
    protege o motor nao depende de como o controle esta configurado. #>
$UI.txtOrigem.add_TextChanged({ Set-BordaPasta $UI.boxOrigem (Test-CaminhoDePasta $UI.txtOrigem.Text) })
$UI.txtSaida.add_TextChanged({  Set-BordaPasta $UI.boxSaida  (Test-CaminhoDePasta $UI.txtSaida.Text) })
function Abrir-SeletorOrigem {
    if ("$($Estado.Atual)" -ne "inicial") { return }
    $p = Select-Pasta $UI.txtOrigem.Text "Escolha a pasta de ORIGEM (onde estao os .mkv)"
    if ($p) { Aplicar-PastaOrigem $p | Out-Null }
}
function Abrir-SeletorSaida {
    if ("$($Estado.Atual)" -ne "inicial") { return }
    $p = Select-Pasta $UI.txtSaida.Text "Escolha a pasta de SAIDA (onde o arquivo final vai ser gravado)"
    if ($p) { Aplicar-PastaSaida $p | Out-Null }
}
<#  16.64c: MAXIMIZAR A JANELA ABRIA O SELETOR SOZINHO.
    Achado pelo Diego no log de 28/08 15h28: nove Maximized/Normal seguidos e
    nenhuma pasta trocada - o dialogo abria a cada maximizada e ele cancelava.

    A CAUSA: eu tinha ligado a acao ao MouseLeftButtonUp sozinho. Soltar o
    botao NAO quer dizer que ele foi apertado ali. Ao maximizar, o botao e
    apertado na barra de titulo (area nao-cliente, que o WPF nem enxerga), a
    janela cresce, e o botao e SOLTO ja com o cursor por cima da caixa de
    pasta, que agora ocupa aquele pedaco da tela. O WPF entrega um
    MouseLeftButtonUp limpinho na caixa e ela obedece.
    O mesmo vale para o duplo-clique na barra de titulo, que e o jeito mais
    comum de maximizar.

    A CORRECAO e a regra que todo botao de verdade segue: so vale quando o
    APERTAR e o SOLTAR acontecem no mesmo controle. O apertar marca qual
    caixa comecou o clique; o soltar so age se a marca for dela.
    O PreviewMouseLeftButtonDown da janela limpa a marca em QUALQUER apertar,
    e ele corre antes (tunel) do Down da caixa - entao a caixa sempre remarca
    depois de limpa. Apertar na barra de titulo nao gera evento nenhum no
    WPF, e por isso a marca continua vazia: e exatamente esse o caso que
    estava quebrado.
    Mudar de tamanho ou de estado tambem limpa a marca, para o caso de o
    apertar ter comecado numa caixa e o layout ter mudado embaixo do cursor. #>
$script:CliquePastaEm = ""
$Janela.add_PreviewMouseLeftButtonDown({ $script:CliquePastaEm = "" })
$Janela.add_StateChanged({ $script:CliquePastaEm = "" })
$Janela.add_SizeChanged({  $script:CliquePastaEm = "" })
# O clique e pego no Border inteiro, nao so no texto: a caixa toda e o botao,
# inclusive a parte vazia depois do fim do caminho.
$UI.boxOrigem.add_MouseLeftButtonDown({ $_.Handled = $true; $script:CliquePastaEm = "origem" })
$UI.boxSaida.add_MouseLeftButtonDown({  $_.Handled = $true; $script:CliquePastaEm = "saida"  })
$UI.boxOrigem.add_MouseLeftButtonUp({
    $_.Handled = $true
    if ($script:CliquePastaEm -ne "origem") { return }
    $script:CliquePastaEm = ""
    Abrir-SeletorOrigem
})
$UI.boxSaida.add_MouseLeftButtonUp({
    $_.Handled = $true
    if ($script:CliquePastaEm -ne "saida") { return }
    $script:CliquePastaEm = ""
    Abrir-SeletorSaida
})
$UI.boxOrigem.Cursor = "Hand"
$UI.boxSaida.Cursor  = "Hand"
function Set-CaixasDePastaEditaveis([bool]$Pode) {
    # Fora da tela inicial a caixa nao aceita clique e o botao fica apagado.
    foreach ($n in @("boxOrigem","boxSaida")) {
        if ($UI[$n]) { $UI[$n].Cursor = $(if ($Pode) { "Hand" } else { "Arrow" }) }
    }
    foreach ($n in @("btnTrocarOrigem","btnTrocarSaida")) {
        if ($UI[$n]) { $UI[$n].IsEnabled = $Pode }
    }
}
$UI.btnTrocarOrigem.add_Click({ Abrir-SeletorOrigem })
$UI.btnTrocarSaida.add_Click({ Abrir-SeletorSaida })
# 16.45: os dois botoes de pasta passaram a ser o MESMO codigo. Antes o de
# saida tinha a mensagem de erro escrita na mao ali dentro; duplicar isso pro
# de origem seria duplicar tambem o proximo conserto.
function Abrir-PastaNoExplorer([string]$Caminho, [string]$Rotulo) {
    Escrever-Log ("CLIQUE: Abrir {0}" -f $Rotulo) "ACAO"
    if ("$Caminho" -and (Test-Path -LiteralPath $Caminho)) {
        Start-Process explorer.exe -ArgumentList "`"$Caminho`""
    } else {
        [System.Windows.MessageBox]::Show(
            ("A pasta de {0} não existe nesta máquina:{1}{1}{2}" -f $Rotulo, [Environment]::NewLine, $Caminho),
            $NOME_APP) | Out-Null
    }
}
$UI.btnAbrirSaida.add_Click({ Abrir-PastaNoExplorer $UI.txtSaida.Text "Saída" })
$UI.btnAbrirOrigem.add_Click({ Abrir-PastaNoExplorer $UI.txtOrigem.Text "Origem" })
# m3c9: Pastas e Ferramentas colapsam do mesmo jeito - corpo some, cabecalho
# (com a seta) continua visivel pra poder reabrir com um clique nele mesmo,
# sem depender so do botao la em cima na barra. Uma funcao so pros dois:
# menos chance de um painel ganhar um comportamento e o outro nao.
function Set-PainelRecolhivel([string]$Nome, [ref]$FlagVisivel, $Corpo, $Seta) {
    $FlagVisivel.Value = -not $FlagVisivel.Value
    if ($Estado.Atual -eq "inicial") {
        $Corpo.Visibility = if ($FlagVisivel.Value) { "Visible" } else { "Collapsed" }
    }
    $Seta.Text = if ($FlagVisivel.Value) { "▼" } else { "▶" }
    Escrever-Log ("CLIQUE: {0} (bloco {1})" -f $Nome, $(if ($FlagVisivel.Value) { "aberto" } else { "recolhido" })) "ACAO"
}
$script:PastasVisivel = $true
$script:FerramentasVisivel = $true
$UI.cabecPastas.add_MouseLeftButtonUp({ Set-PainelRecolhivel "Pastas" ([ref]$script:PastasVisivel) $UI.corpoPastas $UI.setaPastas })
$UI.cabecFerramentas.add_MouseLeftButtonUp({ Set-PainelRecolhivel "Ferramentas" ([ref]$script:FerramentasVisivel) $UI.corpoFerramentas $UI.setaFerramentas })
$UI.btnReler.add_Click({
    if ($script:Lendo) {
        # Botao esta como "Parar": aborta o reescaneamento em curso SEM reagendar
        # (o mesmo Cancelar que a troca de pasta usa; aqui sem ReleituraPendente).
        Escrever-Log "CLIQUE: Parar leitura" "ACAO"
        $script:ReleituraPendente = $false
        $script:Controle.Cancelar = $true
    } else {
        Escrever-Log "CLIQUE: Atualizar (reler pasta)" "ACAO"
        Start-Leitura
    }
})
$UI.lstFila.add_SelectionChanged({
    Update-Diagnostico
    Update-CabecalhoFila
    # m3c23: o botao Modo mostra o Modo e o Marcado DO VIDEO SELECIONADO, entao
    # trocar de video tem que atualiza-lo - inclusive na aba Fila, onde ele
    # tambem aparece. Sem isso, sair de um video desmarcado pra um marcado
    # deixava o botao travado (mais um caminho do mesmo bug).
    Update-BotaoModo
    if ($script:AbaAtual -eq "faixas") { Fill-Faixas }
})
$UI.abaFila.add_MouseLeftButtonUp({ Escrever-Log "ABA: Fila" "ACAO"; Set-Aba "fila" })
$UI.btnMarcarTodos.add_MouseLeftButtonUp({ Set-TodosMarcados $true })
$UI.btnDesmarcarTodos.add_MouseLeftButtonUp({ Set-TodosMarcados $false })

# A marcacao e gravada pelo EVENTO, nao por binding de duas maos: assim
# nao dependemos de o WPF escrever de volta num PSCustomObject.
$script:TrocaMarca = [System.Windows.RoutedEventHandler]{
    param($remetente, $evento)
    $cx = $evento.OriginalSource
    if (-not ($cx -is [System.Windows.Controls.CheckBox])) { return }
    $i = -1
    if ($null -ne $cx.Tag) { $i = [int]$cx.Tag }
    if ($i -lt 0 -or $i -ge $script:Videos.Count) { return }
    $novo = [bool]$cx.IsChecked
    # Fill-Fila reconstroi a lista a cada video lido; todo checkbox que nasce
    # marcado re-dispara Checked. Esse disparo sintetico SEMPRE bate com o
    # modelo (nasceu do proprio $v.Marcado), entao so um clique REAL do usuario
    # difere. Filtrar por essa diferenca corta ~N^2 logs e Update-Selecao na
    # leitura, sem depender de QUANDO o WPF realiza cada linha (virtualizacao).
    if ($script:Videos[$i].Marcado -eq $novo) { return }
    if ($Estado.Atual -in @("rodando","pausado")) {
        # Trava durante a conversao. A versao que solta os PENDENTES (deixa
        # dropar um episodio esquecido) e trava so o atual + os ja feitos vem
        # com a ponte de progresso real - la existe o ciclo de vida por item.
        $cx.IsChecked = $script:Videos[$i].Marcado   # desfaz; reentra e cai no guard acima
        Escrever-Log ("SELECAO bloqueada (conversao em curso): {0}" -f $script:Videos[$i].Nome) "ACAO"
        return
    }
    $script:Videos[$i].Marcado = $novo
    Escrever-Log ("SELECAO: {0} -> {1}" -f $script:Videos[$i].Nome, $(if ($novo) { "marcado" } else { "desmarcado" })) "ACAO"
    Update-Selecao
}
$UI.lstFila.AddHandler([System.Windows.Controls.Primitives.ToggleButton]::CheckedEvent, $script:TrocaMarca)
$UI.lstFila.AddHandler([System.Windows.Controls.Primitives.ToggleButton]::UncheckedEvent, $script:TrocaMarca)
$UI.abaFaixas.add_MouseLeftButtonUp({ Escrever-Log "ABA: Faixas" "ACAO"; Set-Aba "faixas" })

# m3c-b: Automatico <-> Manual, por video. Automatico e o padrao (a logica do
# motor v13.1, igual pra todos - ver HANDOFF 7.1); Manual e a excecao pontual
# (caso The Last of Us - HANDOFF 7.2), e so libera os 3 verbos DAQUELE video.
$UI.btnModoVideo.add_MouseLeftButtonUp({
    if ($Estado.Atual -in @("rodando","pausado")) {
        Escrever-Log "MODO bloqueado (conversao em curso)" "ACAO"
        return
    }
    $idx = $UI.lstFila.SelectedIndex
    if ($idx -lt 0 -or $idx -ge $script:Videos.Count) { return }
    $v = $script:Videos[$idx]
    if (-not $v.Marcado) {
        # Cinto e suspensorio: IsEnabled ja trava isso na origem (m3c16),
        # mas nao custa nada garantir aqui tambem.
        Escrever-Log ("MODO bloqueado (video desmarcado): {0}" -f $v.Nome) "ACAO"
        return
    }
    $v.Modo = if ($v.Modo -eq "Manual") { "Automatico" } else { "Manual" }
    Escrever-Log ("MODO: {0} -> {1}" -f $v.Nome, $v.Modo) "ACAO"
    Fill-Faixas
    Fill-Fila $Estado.Atual   # o selo Automatico/Manual mora na coluna SITUACAO da Fila
})

# m3c-c: escolha no dropdown da coluna ACAO, so vale quando o video esta em
# Manual e a faixa nao esta travada (o proprio ComboBox.Editavel ja garante
# isso via IsEnabled - faixa travada/Automatico nem abre o dropdown). Mesmo
# padrao das demais interacoes por linha: handler no nivel da ListView
# (SelectionChanged tambem e um evento roteado, sobe ate o lstFaixas).
#
# GUARDA CONTRA ECO: toda vez que Fill-Faixas reconstroi a lista, o ComboBox
# de cada linha nasce com o SelectedItem que a propria linha ja tinha (o
# binding inicial), e isso TAMBEM dispara SelectionChanged - nao e um clique
# de verdade. Filtra comparando com o valor que a faixa ja tem: so um clique
# REAL do usuario escolhe algo DIFERENTE do que ja estava.
$script:TrocaVerbo = [System.Windows.Controls.SelectionChangedEventHandler]{
    param($remetente, $evento)
    $cb = $evento.OriginalSource
    if (-not ($cb -is [System.Windows.Controls.ComboBox])) { return }
    if ($null -eq $cb.Tag) { return }
    $idxF = [int]$cb.Tag
    if ($idxF -lt 0) { return }   # linhas sinteticas (cabecalho, "...mais N", Anexos): sem faixa real
    if (@($evento.AddedItems).Count -eq 0) { return }
    $novo = "$($evento.AddedItems[0])"
    $idxV = $UI.lstFila.SelectedIndex
    if ($idxV -lt 0 -or $idxV -ge $script:Videos.Count) { return }
    $v = $script:Videos[$idxV]
    if ($v.Modo -ne "Manual") { return }   # Automatico: dropdown nem deveria estar habilitado
    if (-not $v.Marcado) {
        Escrever-Log ("FAIXA bloqueada (video desmarcado): {0}" -f $v.Nome) "ACAO"
        return
    }
    if ($Estado.Atual -in @("rodando","pausado")) {
        # Cinto e suspensorio: Editavel/Fill-Faixas ja travam isso na origem
        # (m3c8), mas um clique bem no instante da troca de estado nao pode
        # colar. Mesmo padrao das demais SELECAO bloqueada.
        Escrever-Log ("FAIXA bloqueada (conversao em curso): {0}" -f $v.Nome) "ACAO"
        return
    }
    if ($idxF -ge $v.Faixas.Count) { return }
    $f = $v.Faixas[$idxF]
    if (Test-VerboBloqueado $f) { return }
    $atual = if ($f.VerboUsuario) { "$($f.VerboUsuario)" } else { "$($f.VerboAuto)" }
    if ($novo -eq $atual) { return }   # eco do rebuild, nao um clique de verdade
    # Se a escolha voltou pro mesmo valor que o motor ja escolheria sozinho,
    # limpa o VerboUsuario em vez de guardar uma "escolha manual" identica -
    # assim a faixa volta a se comportar como Automatico de verdade.
    $f.VerboUsuario = if ($novo -eq $f.VerboAuto) { $null } else { $novo }
    Escrever-Log ("FAIXA: {0} id {1} ({2}) -> {3}" -f $v.Nome, $f.Id, $f.Papel, $novo) "ACAO"
    # m3c19: a Fila tambem precisa ser redesenhada - as colunas AUDIO e LEGENDA
    # PT-BR agora mostram a escolha manual ("X Mantido"/"X Excluido") em vez do
    # veredito do motor. Sem isso, a mudanca aparecia so na aba Faixas.
    Fill-Fila $Estado.Atual
    Fill-Faixas
}
$UI.lstFaixas.AddHandler([System.Windows.Controls.Primitives.Selector]::SelectionChangedEvent, $script:TrocaVerbo)
$UI.btnLog.add_Click({
    Escrever-Log "CLIQUE: Log" "ACAO"
    $cab = "Log desta sessao. Arquivo salvo em:`n$($script:LogArquivo)`n" + ("-" * 90) + "`n"
    Show-JanelaTexto "LaFirma - Log da Sessao" ($cab + ($script:LogLinhas -join "`n"))
})
$UI.btnFerramentas.add_Click({
    Escrever-Log "CLIQUE: Ferramentas" "ACAO"
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("Procuradas dentro de: $($script:PastaScript)")
    [void]$sb.AppendLine("")
    foreach ($f in $script:Ferramentas) {
        $marca = if ($f.Ok) { "[OK]   " } else { "[FALTA]" }
        [void]$sb.AppendLine(("{0} {1}  ({2})" -f $marca, $f.Rotulo, $f.Papel))
        [void]$sb.AppendLine(("        {0}" -f $(if ($f.Caminho) { $f.Caminho } else { "nao encontrada" })))
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("Motor lido: $($script:CaminhoMotor)")
    Show-JanelaTexto "LaFirma - Ferramentas" $sb.ToString()
})

# Teclado global: F1 inicia; F2 alterna Pausar/Retomar; ESC cancela.
$Janela.add_PreviewKeyDown({
    param($s,$e)
    if ($e.Key -in @("F1","F2","Escape")) {
        $vale = switch ($e.Key) {
            "F1"     { $UI.btnIniciar.IsEnabled }
            "F2"     { $UI.btnPausar.IsEnabled }
            "Escape" { $UI.btnCancelar.IsEnabled }
        }
        if ($vale) { Escrever-Log ("TECLA: {0}" -f $e.Key) "ACAO" }
        else { Escrever-Log ("TECLA: {0} (ignorada - nao se aplica ao estado '{1}')" -f $e.Key, $Estado.Atual) "ACAO" }
    }
    switch ($e.Key) {
        "F1"     { if ($UI.btnIniciar.IsEnabled) { Invoke-Iniciar }; $e.Handled = $true }
        "F2"     { if ($UI.btnPausar.IsEnabled)  { Invoke-TogglePausa }; $e.Handled = $true }
        "Escape" { if ($UI.btnCancelar.IsEnabled) { Invoke-Cancelar; $e.Handled = $true } }
    }
})

# Recalcular larguras dependentes quando a janela muda de tamanho
# Arrastar a borda dispara SizeChanged ~100x por segundo. Sem freio, a p3
# gerou 546 linhas de ruido (90% do log) e uma rajada de escrita em disco.
# Solucao: temporizador de 400ms que reinicia a cada evento - so quando o
# usuario PARA de arrastar e que registramos e recalculamos a barra.
$TimerRedim = New-Object System.Windows.Threading.DispatcherTimer
$TimerRedim.Interval = [TimeSpan]::FromMilliseconds(400)
$TimerRedim.add_Tick({
    $TimerRedim.Stop()
    if ($Estado.Atual -eq "inicial") { Update-Disco }
    $tam = "{0}x{1}" -f [int]$Janela.ActualWidth, [int]$Janela.ActualHeight
    if ($tam -ne $script:UltimoTamanho) {
        $script:UltimoTamanho = $tam
        Escrever-Log ("JANELA tamanho final: {0}" -f $tam)
    }
})
$script:UltimoTamanho = ""
$Janela.add_SizeChanged({ $TimerRedim.Stop(); $TimerRedim.Start() })
$Janela.add_StateChanged({ Escrever-Log ("JANELA estado: {0}" -f $Janela.WindowState) })
$Janela.add_ContentRendered({
    $fonte = [System.Windows.SystemFonts]::MessageFontFamily.Source
    $src2  = [System.Windows.PresentationSource]::FromVisual($Janela)
    $escala = if ($src2) { $src2.CompositionTarget.TransformToDevice.M11 } else { 1 }
    Escrever-Log ("TELA: {0}x{1} px | janela {2}x{3} | escala DPI {4}x | fonte do sistema '{5}'" -f
        [int][System.Windows.SystemParameters]::PrimaryScreenWidth,
        [int][System.Windows.SystemParameters]::PrimaryScreenHeight,
        [int]$Janela.ActualWidth, [int]$Janela.ActualHeight, $escala, $fonte)
    Start-Leitura
    Update-LarguraNome
    # 16.9: a versao do motor era texto FIXO ("v13.1") e ficou mentindo no dia
    # em que o motor virou 13.2. Agora ela e LIDA do proprio arquivo do motor -
    # e so ler a constante, nao e reimplementar nada dele. Se a leitura falhar,
    # a linha sai sem versao em vez de sair com uma versao errada.
    $verMotor = ""
    try {
        $mLinha = Select-String -LiteralPath $script:CaminhoMotor -Pattern '^\$SCRIPT_VERSION\s*=\s*"([^"]+)"' -ErrorAction Stop | Select-Object -First 1
        if ($mLinha) { $verMotor = " v" + $mLinha.Matches[0].Groups[1].Value }
    } catch { $verMotor = "" }
    Escrever-Log ("Interface renderizada. Iniciar chama o motor{0} DE VERDADE - a conversao escreve na pasta de saida." -f $verMotor)
})
# 16.12: fechar a janela no meio de uma conversao e cancelar por outro nome -
# o runspace morre junto e o episodio em andamento se perde. Mesma pergunta.
$Janela.add_Closing({
    param($remetente, $ev)
    if ($Estado.Atual -notin @("rodando","pausado")) { return }
    $texto = ("Fechar o programa agora?`n`nA conversão está em andamento. Fechar cancela o vídeo que está sendo montado - o arquivo parcial é apagado e o tempo gasto nele se perde.`n`nOs vídeos que já terminaram continuam na pasta de saída.")
    if (-not (Confirm-Parar "LaFirma - fechar com conversão em andamento?" $texto)) {
        # 16.23: mesma armadilha do Invoke-Cancelar. Se a conversao terminou
        # enquanto a pergunta estava aberta, NAO faz sentido segurar a janela
        # aberta por causa de um trabalho que ja acabou - o "Nao" respondia a
        # um mundo que nao existe mais. Deixa fechar normal.
        if ($Estado.Atual -notin @("rodando","pausado")) {
            Escrever-Log "FECHAR: a conversao terminou enquanto a pergunta estava aberta - fecha normal" "ACAO"
            return
        }
        $ev.Cancel = $true
        Escrever-Log "FECHAR a janela RECUSADO na confirmacao - a conversao segue" "ACAO"
        return
    }
    Escrever-Log "FECHAR a janela CONFIRMADO com a conversao em andamento" "ACAO"
})
$Janela.add_Closed({
    Escrever-Log "Janela fechada pelo usuario"
    $TimerFila.Stop()
    Stop-Motor
    Escrever-Log ("===== fim da sessao - {0} linhas registradas =====" -f $script:LogLinhas.Count)
    if ($script:LogEscritor) { try { $script:LogEscritor.Dispose() } catch { } }
})

# ---- Truque do icone na barra de tarefas -------------------------------------
# 16.28: quando a janela NAO esta fixada na barra de tarefas, o Windows so
# "acorda" o botao (icone certo, botao visivel) quando algo forca um redesenho
# - e minimizar/restaurar e exatamente esse gatilho, confirmado nos seus logs
# (o botao so aparecia depois do "JANELA estado: Minimized"). Fixado ja tem
# esse vinculo pronto de antemao, por isso sempre funcionou direto.
# Em vez de pedir pra voce minimizar toda vez, o programa faz isso sozinho,
# uma vez, bem no inicio - um pisca rapido que ninguem chega a notar.
$Janela.Add_ContentRendered({
    try {
        $Janela.WindowState = [System.Windows.WindowState]::Minimized
        $Janela.Dispatcher.BeginInvoke(
            [System.Action]{ $Janela.WindowState = [System.Windows.WindowState]::Normal },
            [System.Windows.Threading.DispatcherPriority]::ApplicationIdle) | Out-Null
        Escrever-Log "Truque de redesenho da barra de tarefas aplicado (minimizar/restaurar automatico)"
    } catch {
        Escrever-Log ("AVISO: truque do icone da barra de tarefas falhou: {0}" -f $_.Exception.Message) "AVISO"
    }
})

# ---- Partida ----------------------------------------------------------------
trap { Escrever-Log ("ERRO: {0}" -f $_.Exception.Message) "ERRO"; continue }
[System.Windows.Threading.Dispatcher]::CurrentDispatcher.add_UnhandledException({
    param($s,$e)
    Escrever-Log ("ERRO NAO TRATADO: {0}" -f $e.Exception.Message) "ERRO"
})
$TimerFila.Start()
Set-Aba "fila"
Set-Estado "inicial"
$Janela.ShowDialog() | Out-Null
