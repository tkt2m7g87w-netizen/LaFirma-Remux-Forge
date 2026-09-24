# ============================================================================
#  LaFirma - JANELA 19.15
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
#    19.15  23/09/2026  Remontagem com video extraido: 8s + 4,5 s/GB (era 51 + 3,6)
#    19.14  23/09/2026  Pasta de saida so com .mkv + .srt (sem copia do log)
#    19.13  23/09/2026  Arquivo pulado nao vira 'erro -100%' na previsao
#    19.12  23/09/2026  Grande teste final: [F12] do topo traduzido na troca
#                       de idioma; rodape do arquivo seguinte nao herda o
#                       relogio do anterior; OCR parado em 10% nao infla mais
#                       o restante
#    19.11  23/09/2026  Espaco: o cartao diz QUAL disco faltou; "Livre Agora"
#                       mostra a origem (e a saida, quando e outro disco)
#    19.10  23/09/2026  Teste de aceite da 2.0.9 + auditoria: a pausa saia
#                       das contas do rodape (restante subia de 196s para
#                       422s depois de 29s pausado); pausa que atravessava a
#                       troca de etapa sumia; cancelar pausado ficava
#                       "PAUSADO"; fechar nao parava censo/medicao; titulo
#                       sem o numero de videos; sub-etapa repetida no log
#    19.9   23/09/2026  Desfeito o rotulo "[PERDA EM ...]": volta o cabecalho
#                       de sempre, e o censo so acrescenta o numero
#    19.8   23/09/2026  O Iniciar quebrava: @() em cima da List dos videos
#                       ("Os tipos de argumento nao correspondem")
#    19.7   23/09/2026  Censo vai para o motor e o rotulo vira "PERDA EM N DE
#                       M CENAS"; pausa e etapa cancelada nao entram mais na
#                       calibragem; medicao velha nao ressuscita ao trocar de
#                       pasta; titulo mostra a versao de verdade
#    19.6   23/09/2026  Revisao geral: F5 e Atualizar nao matam mais a
#                       conversao; Start-Motor nao joga fora el_fim/censo_fim;
#                       medicao nao renasce no meio da conversao; cartao do P5
#    19.5   22/09/2026  A cor volta a seguir so a classificacao: o censo
#                       acrescenta numeros, nunca troca vermelho por laranja
#    19.4   22/09/2026  A fila passou a ser repintada quando o censo muda
#                       a cor: a linha de baixo virava laranja e a coluna
#                       de cima ficava vermelha, na mesma tela
#    19.3   22/09/2026  O [ESC] recusado passou a dizer o motivo real (o
#                       mesmo conserto que o F11 ganhou na 18.22), e a
#                       frase do veredicto da legenda ficou curta
#    19.2   22/09/2026  O Complex FEL deixou de ser um so vermelho: com o
#                       Censo Completo na mao, pico isolado (menos de 1%
#                       das cenas e no maximo 2x o master) desce para
#                       laranja. A camada NAO e reclassificada
#    19.1   22/09/2026  A previsao do censo passou a olhar o DISCO, que e
#                       quem manda no relogio, e o cartao final le o arquivo
#                       com o selo [BL+RPU] no nome
#    19.0   18/09/2026  2.0: a calibragem que se anulava (licao 49), a barra
#                       com [F3]/[F4], traducoes fechadas e o instalador
#                       bilingue com EULA
#    18.24  18/09/2026  65 janelas do Explorer empilhadas: F3/F4 sem freio.
#                       Agora reaproveita a janela aberta, e freia por pasta
#    18.23  18/09/2026  A barra na ordem dele: Origem, Saida, Atualizar - e
#                       [F3] e [F4] abrindo as pastas
#    18.22  18/09/2026  O [F11] que sumia com o censo rodando, a dica que
#                       congelava, e o F11 que travou para sempre (licao 47)
#    18.21  18/09/2026  UMA PORTA SO (o botao do censo tinha tres donos), o
#                       freio dos 2s, F5/F12 travados com o censo rodando, a
#                       porcentagem por duracao e o [F12] que faltava
#    18.20  17/09/2026  O CENSO VOLTOU A FUNCIONAR (eu tinha quebrado na 18.19)
#    18.19  17/09/2026  CENSO CANCELADO NAO VIRA VEREDICTO (RPU PELA METADE)
#    18.18  17/09/2026  UM DONO POR BOTAO; [F1] ANTES DO ROTULO; RECUSA FALA
#    18.17  17/09/2026  PROGRESSO REAL DO CENSO; A MEDICAO VOLTA SOZINHA; F5
#    18.16  17/09/2026  O BOTAO DO CENSO PARA; F11/F12; ROTULO SO COM %
#    18.15  17/09/2026  O CMD DO PIPE TAMBEM MORRE; PROVA DE VIDA OLHA OS DOIS
#    18.14  17/09/2026  CANCELAR O CENSO VALE NA HORA (o dovi_tool e parado)
#    18.13  17/09/2026  CABECALHO E DA ABA; O CENSO PROVA QUE ESTA VIVO
#    18.12  17/09/2026  FECHAR PARA TODOS OS RELOGIOS (erro de 10/09 01:26:31)
#    18.11  17/09/2026  NAO PROMETE MEDICAO QUE NAO EXISTE; FAIXAS UMA VEZ SO
#    18.10  17/09/2026  O BOTAO DO CENSO ENTROU NO PADRAO DE CORES DA CASA
#    18.09  17/09/2026  O CONTADOR DO CENSO PASSOU A DIZER QUANTO FALTA
#    18.08  17/09/2026  A MEDICAO MORRIA PARA SEMPRE, E A ESPERA FICAVA PENDURADA
#    18.07  17/09/2026  O CENSO MOSTRA QUE ESTA VIVO, E SEM ESPACO E VERMELHO
#    18.06  17/09/2026  O PROGRAMA DESMARCAVA ARQUIVO SOZINHO (a caixinha e o indice)
#    18.05  17/09/2026  A LINHA E O CAMINHO, NAO O INDICE - E O CACHE GUARDAVA MEIA VERDADE
#    18.04  17/09/2026  O CENSO CONGELAVA A JANELA 92s, E A MEDIDA NAO SE PERDE MAIS
#    18.03  17/09/2026  VEREDICTO DO RYAN NA LINHA DO DRAGON: A SERIE NAO VIRAVA
#    18.02  17/09/2026  A MEDICAO NUNCA MEDIU: BANDEIRA DE OUTRO DONO
#    18.01  16/09/2026  A TELA FECHA NA HORA, O TRABALHO FECHA QUANDO PUDER
#    18.00  16/09/2026  OS TRES TRABALHOS, SEPARADOS - o modelo, nao o remendo
#    17.24  16/09/2026  A JANELA TRAVAVA ACHANDO QUE AINDA LIA
#    17.23  16/09/2026  A CHAVE RELIA A PASTA A TOA (28x, 254s)
#    17.22  16/09/2026  A FAIXA DE PAUSADO NAO TRADUZIA
#    17.21  16/09/2026  O ESTADO DA MEDICAO MORRIA PELA METADE
#    17.20  15/09/2026  TRES DEFEITOS DA 17.19, ACHADOS
#                        PELO DIEGO EM QUINZE MINUTOS.
#                        - "Terminou de medir e ficou
#                          mostrando ainda": a fila seguia
#                          com "Medindo Camada - 3 de 3"
#                          depois de todos medidos. Ele leu
#                          como o programa TRAVADO.
#                        - O "Proximo a Converter" verde caia
#                          na linha DE BAIXO enquanto a de
#                          cima era medida.
#                        - Arquivo DESMARCADO sendo medido
#                          aparecia cinza ("Fora da Fila") e
#                          nenhuma linha acendia, com o botao
#                          dizendo "2 de 3".
#                        - Causa comum: a 17.18 deduzia, e
#                          deducao se corrige sozinha a cada
#                          redesenho. Virou estado - e estado
#                          precisa de quem o apague. Eu
#                          apaguei a variavel sem redesenhar.
#
#    17.19  15/09/2026  A 17.18 DEDUZIA QUEM ESTAVA SENDO
#                        MEDIDO - E A DEDUCAO ERRAVA.
#                        - Achado do Diego na tela: a coluna
#                          dizia um numero e o botao dizia
#                          outro, e a posicao andava para tras.
#                        - Dois furos: o runspace mede TODOS os
#                          pendentes (marcados ou nao), e o
#                          total era fotografado uma vez -
#                          desmarcar/remarcar no meio da
#                          medicao mudava a conta debaixo da
#                          formula.
#                        - E a 17.18 criou a TERCEIRA contagem
#                          da mesma coisa na tela (botao, aviso
#                          de espera, deducao).
#                        - Agora o laco que mede manda "el_ini"
#                          com indice, posicao e total antes de
#                          cada arquivo. Ninguem deduz.
#                        - O aviso de espera deixou de usar a
#                          forma "X de Y" do botao: ele responde
#                          outra pergunta ("faltam N da sua
#                          fila") e escrito igual parecia o
#                          mesmo contador se contradizendo.
#
#    17.18  15/09/2026  A FILA NAO DIZIA QUEM ESTAVA SENDO
#                        MEDIDO - E PERDIA O "PROXIMO A
#                        CONVERTER" AO REDESENHAR.
#                        - O botao dizia "Medindo MEL x FEL:
#                          2 de 3" e as tres linhas da fila
#                          diziam "Na Fila". Agora a linha que
#                          esta sendo medida fica em ciano,
#                          "Medindo Camada - 2 de 3", com a
#                          mesma conta do aviso de espera.
#                        - "Proximo a Converter" olhava o MOTIVO
#                          do redesenho ($Fase), nao o estado do
#                          programa. Redesenhar por causa da
#                          medicao ("el") ou da troca de idioma
#                          ("idioma") apagava o rotulo verde da
#                          tela. Agora quem responde e o ESTADO.
#                        - Achado do Diego, 15/09, na foto da
#                          fila em ingles.
#
#    17.17  15/09/2026  DUAS FUNCOES COM O MESMO NOME, E A
#                        ERRADA GANHANDO DESDE A 16.95.
#                        - Get-FatorDisco existia DUAS vezes: o
#                          fator de VELOCIDADE do disco (estimativa
#                          de tempo) e o de ESPACO (1,6x/3,15x).
#                          Em PowerShell a ultima vence: a de espaco
#                          respondia para as duas, e devolvia 1,60
#                          constante para quem chamava sem
#                          argumento. A prova esta nos logs - 10.715
#                          MB/s e 7.601 MB/s imprimindo o MESMO
#                          1,60x, numero que a funcao certa nao
#                          consegue produzir.
#                        - Achado por teste sintetico, nao por uso.
#                        - A simulacao da fila do disco virou funcao
#                          pura (Get-PlanoDoDisco) para a bateria
#                          poder executa-la com arquivos reais.
#                        - A bateria agora reprova qualquer funcao
#                          de topo definida duas vezes.
#    17.16  13/09/2026  UMA LEGENDA INGLESA CARIMBADA DE
#                        BRASILEIRA, E A FILA QUE COMECOU SEM
#                        CABER.
#                        - No Manual dava para marcar CONVERTER na
#                          PGS de INGLES, e o programa convertia: o
#                          arquivo saiu com legenda inglesa rotulada
#                          "Portugues (Brasil) [OCR]", como padrao.
#                          O verbo deixou de existir para ela (e o
#                          motor 14.54 recusa a ordem tambem).
#                        - A conta do disco que enxerga a fila na
#                          ordem existia desde a 16.93 e ninguem
#                          olhava: so a conta agregada parava o
#                          Iniciar. Fila verde comecou, converteu o
#                          primeiro e o segundo morreu por 2,95 GB.
#                        - Barrinha e contador na chave de medicao:
#                          da para ver que esta indo.
#                        - Cartao final: selos em caixa alta, nota da
#                          legenda, botoes do fim, verbo dos
#                          Capitulos e motivo do pulado - tudo isso
#                          ainda saia em portugues no cartao ingles.
#                        - A dica da chave agora esta nos dois botoes.
#    17.15  11/09/2026  O DIAGNOSTICO EM DUAS LINGUAS AO MESMO
#                        TEMPO, E UMA ESPERA SEM MOTIVO.
#                        - O cartao final era o unico painel montado
#                          por codigo que Set-Idioma nao redesenhava.
#                          Trocar de lingua depois da conversao
#                          deixava metade da tela em portugues.
#                        - Titulo e linha de tempos do cartao nunca
#                          passaram pela traducao.
#                        - A espera do Iniciar contava arquivo
#                          DESMARCADO: esperava a medicao de um video
#                          que nao ia converter. Agora ela olha a fila
#                          real e comeca assim que o ultimo MARCADO
#                          termina.
#                        - Excluir a .SRT antiga e mandar CONVERTER a
#                          PGS (trocar de legenda) dizia "Sem Legenda
#                          PT-BR no Arquivo Final". O que foi enviado
#                          ao motor estava certo; so o texto mentia.
#                        - As frases de ESCOLHA MANUAL ganharam
#                          traducao (nenhuma tinha).
#    17.14  11/09/2026  A TABELA PROMETIA UM OCR QUE NUNCA IA
#                        ACONTECER.
#                        - Arquivo com .SRT pt-BR E PGS pt-BR: o motor
#                          reaproveita a de texto e nao roda OCR
#                          nenhum, mas a aba Faixas punha CONVERTER na
#                          PGS. Era a tela mentindo sobre o motor.
#                          Agora a PGS le MANTER com o motivo do lado,
#                          e o rotulo PADRAO para de ser disputado por
#                          duas faixas com o mesmo papel.
#                        - O aviso de espera passou a dizer em qual
#                          arquivo a medicao esta ("1 de 2"): parado
#                          por 40 segundos ele era indistinguivel de
#                          aviso morto.
#                        - O botao Censo Completo diz POR QUE esta
#                          cinza, em cada um dos sete motivos.
#                        - Ingles: a regra da palavra "medindo" comia a
#                          regra da frase inteira e sobrava "measuring
#                          a camada de melhoria" na tela.
#    17.13  11/09/2026  O AVISO DE ESPERA VIROU AVISO DE VERDADE.
#                        - Esconder o nome do arquivo UMA VEZ nao
#                          adiantou: qualquer Fill-Faixas o reescrevia
#                          por cima, e trocar o Modo faz exatamente
#                          isso. Agora existe UM lugar que escreve a
#                          dica (Set-AbaDica) e ele respeita a espera.
#                        - O aviso ficou maior, em negrito e com um
#                          ponto ambar - competia de igual para igual
#                          com um nome de release de 70 caracteres.
#                        - "Contando..." nao dizia o que contava, e
#                          podia ficar preso no botao para sempre.
#                        - Cancelar deixava o rodape mostrando a etapa
#                          antiga enquanto o motor limpava - a tela
#                          dizia "Extraindo" no meio da faxina.
#    17.12  11/09/2026  O TRAVAMENTO QUE EU CRIEI NA 17.11, E O
#                        INGLES QUE NUNCA CHEGOU NO CARTAO FINAL.
#                        - A pergunta "esperar a medicao?" e MODAL, e
#                          modal do WPF roda um laco de mensagens
#                          proprio: a medicao podia TERMINAR com a
#                          caixa aberta. Ao responder Sim, a janela
#                          passava a esperar um "el_fim" que ja tinha
#                          passado - e a conversao nunca comecava.
#                        - O cartao final, a grade e o rodape de
#                          progresso eram montados por codigo e nunca
#                          passaram pela traducao. Em ingles a tela
#                          virava meio a meio.
#                        - "espaco insuficiente - faltam ~46,80 GB" ia
#                          para a tela como o motor escreveu: minusculo
#                          e sem acento. A tela agora escreve a frase.
#    17.11  11/09/2026  DOIS DEFEITOS ACHADOS USANDO A 17.10:
#                        - O CARTAO DE PULADO DIZIA SEMPRE "JA EXISTIA
#                          NA PASTA DE SAIDA", mesmo quando o motivo
#                          era outro. No print do Diego a mesma caixa
#                          dizia "Ja Existia na Pasta de Saida" e, na
#                          linha de baixo, "espaco insuficiente -
#                          faltam ~47,68 GB". O motor tem TRES motivos
#                          de pular; a tela so conhecia um.
#                        - O INICIAR NAO ESPERAVA A MEDICAO. Com a
#                          chave LIGADA, apertar F1 durante a fase B
#                          matava a medicao e a linha ficava "EL nao
#                          medida" - e o motor remedia o mesmo arquivo
#                          sozinho, 30s depois. Trabalho feito duas
#                          vezes e veredicto nenhum na tela.
#    17.10  11/09/2026  A MEDICAO MEL x FEL VIROU UMA CHAVE, E O CUSTO
#                        DELA ENTROU NO LOG NOS DOIS ESTADOS.
#                        Queixa de 10/09: "esse lance do FEL x MEL esta
#                        gerando um custo de tempo para apenas comecar
#                        a conversao, e antes era so abrir o programa,
#                        apontar a pasta e dar F1". Agora da para
#                        desligar e comparar - "com isso ligado durou
#                        tanto, com isso desligado durou tanto" - com
#                        numero medido, nao com sensacao.
#    17.09  10/09/2026  TRES CONSERTOS DO QUE A 1.8.2 ENTREGOU E NAO
#                        FUNCIONOU: o botao do censo pedia um campo que
#                        o objeto do video nao tem (e campo errado, em
#                        PowerShell, e sempre mudo); a copia do log
#                        estava num lugar que a JANELA nunca executa; e
#                        o cartao final saia todo verde num arquivo que
#                        o proprio programa tinha marcado como
#                        CONVERSAO NAO RECOMENDADA.
#    17.08  10/09/2026  O CENSO COMPLETO VIROU BOTAO, E A REGUA PASSOU A
#                        SER DESCONFIADA (itens A e D).
#                        - Botao "Censo Completo" na barra. Acende SO na
#                          linha Complex FEL, roda em runspace proprio e
#                          le o RPU do filme INTEIRO em vez da amostra.
#                          Medido na bancada: ~5x o custo da amostra
#                          (Ryan 109s x 22s), e por isso e botao e nao
#                          automatico.
#                        - REGUA SUSPEITA: quando a maioria das cenas
#                          lidas passa do pico declarado pelo master, o
#                          log passa a dizer que a suspeita e do metadado,
#                          nao do filme. Vai para o LOG, nunca para a
#                          linha do diagnostico.
#                        - O custo da medicao e o pico do master ficam
#                          guardados na linha: o censo reaproveita os dois.
#    17.07  10/09/2026  CONSERTO DA 17.06: a nota do audio foi escrita com
#                        Escrever-Log DENTRO do runspace de leitura, onde
#                        as funcoes da janela nao existem. Todo arquivo
#                        saia como "Nao Foi Possivel Ler". Agora usa a
#                        Avisar do proprio runspace.
#    17.06  10/09/2026  A LINHA DO AUDIO VOLTOU AO TAMANHO DAS VIZINHAS.
#                        A 16.98 poe um parentese no rotulo e uma frase de
#                        justificativa depois do selo; a linha virava um
#                        paragrafo e empurrava a coluna da direita. A nota
#                        de qual faixa o arquivo marcava foi para o log.
#    17.05  10/09/2026  A TROCA AO VIVO PASSOU A ALCANCAR A TELA INTEIRA.
#                        Traduzir-Arvore so andava na arvore VISUAL, que
#                        contem apenas o ja renderizado - a barra de
#                        botoes, os paineis e a aba nao selecionada
#                        ficavam em portugues. Agora anda tambem na
#                        arvore LOGICA, e o log diz quantos rotulos
#                        trocaram.
#    17.04  10/09/2026  A PERGUNTA DE REINICIO E DO CLIQUE, NUNCA DO
#                        ARRANQUE. A 17.03 poe a pergunta dentro do
#                        Set-Idioma, que o arranque tambem chama para
#                        aplicar o idioma guardado - entao o programa abria
#                        perguntando, e responder Sim estourava ao fechar
#                        uma janela ainda nao exibida. Extraida para
#                        Offer-ReinicioIdioma, chamada so pelo botao.
#    17.03  09/09/2026  "PERFIL 7.6" NAO EXISTE - O NIVEL NAO E NOME DE
#                       PERFIL. E O QUE A TELA ESCREVE PASSOU A TRADUZIR.
#    17.02  09/09/2026  A ESCOLHA DE IDIOMA CHEGA AO DISCO, E O PAINEL DE
#                       DISCO VOLTA JUNTO COM A LINGUA.
#    17.01  09/09/2026  A TELA EM INGLES PAROU DE SER METADE EM CADA.
#           Print do Diego com a bandeira em EN: ele olhou "VIDEOS IN
#           QUEUE" e perguntou "que lingua e essa?". A frase esta certa -
#           o que estava errado era a tela ser metade em cada lingua.
#           O que faltava, e por que:
#             Atualizar        o CODIGO reescreve este rotulo em dois
#                              pontos (vira "Parar" na leitura e volta).
#                              A varredura da arvore traduz UMA vez,
#                              quando a bandeira troca - qualquer escrita
#                              depois desfaz em silencio.
#             Modo: Automatico o valor guardado nao tem acento e a tabela
#                              tinha "Modo: Automático". Nunca casava.
#             titulo da janela havia um SEGUNDO titulo ("... na Fila") que
#                              eu nao vi ao cobrir o primeiro. Agora
#                              NENHUM titulo escreve portugues direto, e a
#                              bateria reprova se algum voltar a escrever.
#             painel de disco  quatro linhas montadas com numero dentro.
#             Ja Convertido    ramo proprio da coluna SITUACAO.
#             DIAGNOSTICO - x  montado com o nome do arquivo.
#           LICAO: rotulo que o codigo reescreve nao pode depender da
#           varredura da arvore - tem que traduzir na hora em que e
#           escrito.
#
#    17.00 09/09/2026  O DEFEITO QUE EU MESMO PLANTEI, NA REVISAO.
#           A calibragem olhava so o relogio do video (T0Video) para saber
#           que um arquivo tinha terminado. Mas o T0Video ja e preenchido
#           no INICIAR, antes de qualquer arquivo comecar - entao no
#           primeiro anuncio da fila ela acharia que o arquivo 0 acabou e
#           gravaria como tempo real o segundo e meio entre o Iniciar e o
#           anuncio. Os limites de sanidade recusariam o numero, mas a
#           tela ganharia um aviso de calibragem recusada em TODA
#           conversao - e ruido que aparece sempre e ruido que ninguem le
#           mais. Entrou o estado MedidaAberta: relogio ligado nao quer
#           dizer arquivo rodando.
#
#    16.99  09/09/2026  A ESTIMATIVA DE TEMPO SE CALIBRA SOZINHA.
#           Item de fila desde 03/09, e o de maior efeito visivel: a
#           estimativa do primeiro segundo errava (+56% no Troy, +39% no
#           Se7en) e a barra dava saltos. Ja estava medido que trocar a
#           constante NAO resolve - a media melhora dois filmes e faz o
#           terceiro subestimar 20%, e subestimar e o pior erro aqui.
#           Entao a constante deixou de ser constante. A cada arquivo
#           convertido o programa grava quanto ele custou por GB e por
#           peso (CALIBRAGEM.txt, uma linha por arquivo), e a proxima
#           estimativa usa o p75 das ultimas cinco rodadas.
#           p75 e nao mediana, e a escolha esta medida: a mediana e mais
#           exata na media (11,6% x 18,3%) e subestimaria o Spider-Man em
#           23%; o p75 reduz essa subestimacao para 11%. A regra do
#           projeto e que prometer tempo que nao se cumpre e pior.
#           O que isto NAO resolve, e o log diz: os tres filmes sao da
#           mesma maquina e se espalham 45% entre si. Boa parte do erro e
#           do MODELO DE PESOS, nao da maquina - e isso so sai revisando
#           os pesos.
#
#    16.98  09/09/2026  "AUDIO PRINCIPAL" SEGUNDO QUEM.
#           O rotulo dizia "AUDIO PRINCIPAL" e quem lia entendia "a faixa
#           que vai tocar". Nao e isso: a escolha aqui IGNORA de proposito
#           a marca de padrao do arquivo, porque em remux Dual Audio essa
#           marca costuma apontar a dublagem que o grupo de release
#           preferiu, e o programa quer o TrueHD/Atmos esteja ele marcado
#           ou nao. A regra esta certa e continua. Errado era o NOME - e o
#           silencio sobre a divergencia, que e exatamente quando o
#           usuario se surpreende. Agora a linha diz de quem e a escolha
#           e, quando a faixa escolhida nao e a marcada como padrao, diz
#           qual e a outra e por que ela nao foi seguida.
#
#    16.97  09/09/2026  A JANELA PAROU DE PEDIR UMA AMOSTRA PROPRIA.
#           Ela chamava Get-TipoCamadaDV com -Pontos 3 e o motor usava o
#           padrao 5. Mesmo arquivo, mesma pergunta, duas amostras - e
#           portanto a possibilidade de duas respostas para o mesmo fato.
#           Agora nenhum dos dois escolhe: quem decide e a duracao.
#
#    16.96  09/09/2026  AS DUAS REGUAS, E QUAL DELAS FALOU.
#           Item de fila desde 04/09. Quando o arquivo nao declara o pico
#           do mastering display, a linha parava em "pico do master nao
#           declarado" e o usuario ficava com um numero solto e nenhuma
#           referencia - com os numeros do container ali, lidos no mesmo
#           ffprobe, sem aparecer em lugar nenhum.
#           Agora eles aparecem, DITOS COMO SAO. O MaxCLL do container e
#           medido por histograma e o L1 e MaxRGB: grandezas diferentes,
#           e compara-las e o erro que a licao 15 proibiu neste projeto.
#           Entao nao entrou uma segunda regua - entrou o nome da regua
#           que falou, e o container como CONTEXTO, marcado como outra
#           medida. O veredicto Expande continua saindo so do master.
#
#    16.95  09/09/2026  O P5 DEIXOU DE SER SO UMA FRASE.
#           Na 16.92 esta tela passou a dizer a verdade sobre o Profile 5
#           (nao vira 8.1 sem recodificar) e prometeu um remux para MP4
#           que o motor nao fazia. Verdade pela metade, so que do outro
#           lado: em vez de prometer demais sobre a conversao, apontava
#           uma porta que nao existia.
#           Na 14.45 o motor passou a executar esse remux. Entao o P5
#           volta a TER trabalho: DVprecisa e $true, a linha diz
#           "[SERA REMUXADO]" em verde, e ele deixa de cair em "Nada a
#           Converter".
#
#    16.94  09/09/2026  UMA ESCALA DE COR SO, E O TEXTO SEGUINDO A LINGUA.
#           Quatro achados do Diego na mesma rodada, e os quatro sao a
#           mesma queixa: "vc ta se perdendo em todos lugares como sempre
#           em padronizar ne?". Ele tem razao - em todos.
#           1) A COR. A sigla [EL: FEL] do diagnostico saia vermelha num
#           Complex FEL e a coluna DOLBY VISION da MESMA linha saia ambar.
#           A regra verde/laranja/vermelho estava escrita DENTRO da
#           Pintar-RotuloDV e copiada pela metade na fila. Agora ela mora
#           na Get-NomeCorEL, e a sigla, o texto da coluna e o chip leem
#           todos dela. Uma escala, um lugar.
#           2) O TEXTO DO ENTENDA. O rotulo do botao virava "Learn" e o
#           texto que abria continuava em portugues. Agora existe o
#           FAQ_EN.txt e o arquivo e escolhido no CLIQUE, pela lingua
#           atual - trocar a bandeira no meio da sessao ja vale.
#           3) A TRADUCAO PELA METADE. "Fila (3)", "VÍDEOS NA FILA (2 de
#           3 Selecionados)", "Convertendo · Etapa 3/5" e o diagnostico
#           inteiro ficavam em portugues numa tela em ingles. Nao era
#           esquecimento: a traducao varria a ARVORE VISUAL e so alcanca
#           rotulo fixo; essas frases sao montadas com numero dentro, a
#           cada redesenho. Entrou a Traduzir-Frase, com regras de padrao
#           no proprio IDIOMA_EN.txt (linha comecando com ~).
#           4) O FAQ ganhou a secao 14, com as fontes que sustentam cada
#           afirmacao do texto, e os creditos deixaram de ser tabela de
#           duas colunas coladas.
#
#    16.93  09/09/2026  A PERGUNTA DO DISCO PASSOU A FALAR DESTA FILA.
#           A 16.91 dizia a regra geral: "o motor vai converter o que
#           couber e pular o que nao couber". Verdade, e inutil para
#           decidir - o Diego comecou, viu um filme de 82 GB entrar em
#           conversao e parou no meio achando que nunca terminaria.
#           Ele estava certo em desconfiar e o programa estava certo em
#           comecar: o Ryan CABIA sozinho (258 GB de pico contra 276
#           livres); quem nao cabia era o Troy, DEPOIS dele. A informacao
#           existia e nao estava na tela.
#           Agora a janela percorre a fila na ordem, do jeito que o motor
#           decide, e a pergunta diz quantos cabem, qual e o primeiro que
#           fica de fora e quanto faltaria na vez dele.
#           Junto: a escolha de idioma passou a ser guardada (IDIOMA.txt)
#           - escolher ingles e o programa voltar em portugues na proxima
#           vez seria escolha que nao vale de nada.
#
#    16.92  09/09/2026  IDIOMA PT/EN, E O PROFILE 5 PAROU DE MENTIR.
#           1) Botao de bandeira ao lado do Entenda. A traducao e uma
#              TABELA em IDIOMA_EN.txt (portugues TAB ingles) e uma
#              varredura na arvore visual - nada de reescrever o XAML em
#              chaves. Corrigir uma traducao e editar uma linha de texto.
#              Sem o arquivo, o programa continua em portugues INTEIRO: a
#              traducao e camada por cima, nunca a fonte.
#              Esta camada cobre os rotulos fixos (barra, abas, colunas,
#              titulos). As frases montadas na hora entram na proxima.
#           2) O Profile 5 caia no mesmo ramo do Profile 7: a coluna
#              dizia "5.0 -> 8.1" e a linha prometia "[SERA CONVERTIDO]
#              Profile 8.1". O motor, no mesmo programa, ja dizia ha
#              semanas que isso RECODIFICA o video. A tela prometia o que
#              o motor ia negar. Agora ele tem ramo proprio e a resposta
#              diz o caminho que existe: remux para MP4.
#
#    16.91  09/09/2026  COMECAR SABENDO QUE NAO CABE.
#           A tela dizia "Espaco Insuficiente" em vermelho e o Iniciar
#           comecava assim mesmo; o motor recusava arquivo por arquivo
#           23 segundos depois, com a MESMA conta que ja estava na tela.
#           Agora Test-PodeIniciar pergunta antes, com os tres numeros e
#           o NAO pre-selecionado. AVISA, nao bloqueia: a estimativa e do
#           pior caso e ha quem queira converter o que couber.
#
#    16.90  09/09/2026  O TEXTO DO ENTENDA PAROU DE COMPARAR E PASSOU A
#           AGRADECER - e ganhou estrutura.
#           O Diego: "comparar nao faz sentido, nao queremos competir e
#           nem mostrar o que um programa ou outro faz; se usamos o de
#           alguem, damos os creditos e agradecemos pelo aprendizado".
#           A secao 11 deixou de ser "Comparando com outras ferramentas"
#           e virou "De onde veio o que sabemos". Sumiram a tabela de
#           nos-contra-eles e a frase que reduzia o DDVT a bordas e L5.
#           As secoes 3, 4 e 5 ganharam subtitulos e respiro - estavam
#           num paragrafo unico, sem hierarquia nenhuma.
#
#    16.89  09/09/2026  CONSERTOS NO TEXTO DO ENTENDA (achados do Diego).
#           1) Audio: o texto dizia "preservando o Atmos quando ele
#              existe", como se DTS tambem saisse com Atmos. Nao sai, e
#              nunca vai: DTS e Atmos sao de empresas diferentes. Agora o
#              texto separa os dois caminhos - TrueHD vai para E-AC-3
#              Atmos pelo DeeZy (1152k) e a familia DTS vai para E-AC-3
#              comum pelo ffmpeg (640k), sem objetos.
#           2) "nenhuma ferramenta publica mede a camada base" era
#              absoluto e de duplo sentido. O DaVinci Resolve mede brilho
#              quadro a quadro; o que nao existe e uma ferramenta de
#              LINHA DE COMANDO que faca isso sozinha e devolva um numero
#              para um script decidir. O texto agora diz exatamente isso.
#           3) O DDVT passou a ser creditado como a origem do projeto, e
#              o autor do dovi_convert pela critica que fez o programa
#              parar de descartar a EL em silencio.
#
#    16.88  08/09/2026  BOTAO "ENTENDA" - o texto que nao cabe na tela.
#           MEL x FEL, Simple x Complex, o que cada player faz com a EL,
#           audio, legenda, Perfil 5, bordas, o que o programa NAO faz e
#           a comparacao honesta com dovi_convert e DDVT. Inclui as
#           duvidas reais que chegaram ao Diego - a do autor do
#           dovi_convert entre elas. Texto em FAQ_PT.txt, fora do .ps1.
#
#    16.87  08/09/2026  O QUE O USUARIO LE, LIDO POR UM USUARIO.
#           Tudo aqui saiu de perguntas do Diego olhando a tela pronta:
#           1) A sigla [EL: MEL] no rotulo agora e PINTADA na mesma
#              escala do resto (Pintar-RotuloDV, via Inlines).
#           2) "em 1/3 cenas" SAIU da tela. Ele leu e perguntou se o
#              filme tinha tres cenas - eram tres cenas da AMOSTRA. O
#              numero volta ao log, escrito por extenso.
#           3) A resposta da legenda dizia "Brazilian / PGS .SRT (OCR)":
#              anunciava PGS na linha do RESULTADO, e PGS e o que deixa
#              de existir. Agora so o que sai.
#           4) Os selos de descarte eram cinza. Descartar E acao: verdes.
#           5) Quem decide se ha expansao de brilho passou a ser o MOTOR
#              (campo Expande). A tela refazia a conta por conta propria.
#
#    16.86  08/09/2026  TRES NIVEIS, TRES CORES - E O DISCO PAROU DE
#           PROMETER SOBRA QUE NAO EXISTE.
#           1) FEL nao e um estado so. O Diego apontou: "o GOT e FEL
#              tanto quanto o Ryan, mas o do Ryan e mais forte" - e os
#              numeros concordam (153/1.000 contra 1.608/1.000). Agora
#              verde = MEL, laranja = FEL sem expansao, vermelho = FEL
#              com expansao. Vermelho aqui nao bloqueia nada; diz "este
#              e o caso que estraga a imagem".
#           2) A frase do diagnostico encolheu: ela tem UMA linha de
#              largura e estava vazando por cima da linha de baixo.
#           3) "Espaco Livre Apos Converter: -47,52 GB" era mentira -
#              sobra negativa nao existe. Agora, quando nao cabe, a
#              linha diz "Falta Liberar: 47,52 GB", que e o numero que
#              resolve o problema.
#
#    16.85  08/09/2026  O CENSO DO L1 E A AREA ATIVA (L5) NA TELA.
#           A frase do FEL dizia SE o pico passa do master; agora diz
#           QUANTAS das cenas lidas passam, que e o que muda a decisao.
#           O L5 so aparece na tela quando a borda declarada no RPU nao
#           resulta em formato de cinema nenhum - crop errado que ja veio
#           da origem. O LaFirma nao cria esse defeito: "convert
#           --discard" nao toca nos blocos L5. O caso normal fica no log.
#
#    16.84  08/09/2026  UMA COISA, UM TEXTO - a queixa mais antiga.
#           A mesma informacao de Dolby Vision saia escrita de OITO jeitos,
#           um em cada canto da tela. Agora quem escreve e uma funcao so
#           (Format-DolbyVision), com o vocabulario oficial da Dolby, e a
#           sigla MEL/FEL aparece nas QUATRO formas - coluna, rotulo,
#           resposta e nome da faixa. A aba Faixas ganhou a identificacao
#           completa no video quando o release nao nomeou a faixa.
#    16.83  05/09/2026  EU QUEBREI O 'JA EXISTE NA SAIDA' NA 16.82.
#           Tirei a marca da leitura e escrevi no comentario que
#           Update-JaExiste 'ja roda depois de toda leitura'. Nao rodava:
#           so era chamado ao TROCAR a pasta de saida. O GOT ja convertido
#           deixava clicar Iniciar e quem barrava era o motor la na frente.
#           Agora a leitura chama, e a bateria EXECUTA a funcao contra
#           arquivos reais em vez de so ler o fonte.
#    16.82  05/09/2026  CONSERTO DO 'ERRO NA LEITURA' QUE EU CAUSEI.
#           A 16.79 chamava Test-SaidaCompleta (funcao DA JANELA) dentro
#           do runspace de leitura, que nao a enxerga: TODO arquivo com
#           pasta de saida existente virava 'Erro na Leitura'. Mesma
#           armadilha do $doviTool na 16.76. Agora quem decide 'ja existe
#           na saida' e so a janela, e a bateria tem um teste ESTRUTURAL
#           que reprova qualquer funcao da janela chamada num runspace.
#    16.81  05/09/2026  A TELA PROMETIA E O MOTOR NAO CUMPRIA.
#           BUG: marcar MANTER numa legenda PGS mostrava 'Conversao
#           Desligada' e o motor fazia o OCR do mesmo jeito - a chave
#           LegendaPgs nao era enviada, e chave ausente quer dizer 'voce
#           decide', nao 'nao converta'. Agora manda -1, que e uma ordem.
#           E o par L1/master virou frase com conclusao: 'L1 pede 153 de
#           1.000 nits: sem expansao de brilho'.
#    16.80  05/09/2026  O CONSERTO DO AUDIO ESTAVA PELA METADE.
#           A 16.79 arrumou o ROTULO e deixou a RESPOSTA com o mesmo
#           defeito: '[REAPROVEITADO] E-AC-3 Atmos' tambem era o
#           track_name - e num arquivo ja convertido essa etiqueta foi o
#           NOSSO motor que escreveu, entao o programa estava lendo de
#           volta a propria etiqueta em vez do codec. A regra de nomear
#           faixa de audio passou a morar numa funcao so (Rotular-Audio),
#           chamada pelos dois lados.
#    16.79  05/09/2026  CINCO DEFEITOS ACHADOS USANDO O PROGRAMA.
#           1. o audio saia com o NOME DA FAIXA ('Surround') no lugar do
#              codec - agora e sempre o codec, com Atmos e canais.
#           2. a legenda prometia 'OCR: seconv/BinaryOCR' antes de o motor
#              escolher (e no GOT ele recusou o seconv) - agora diz 'OCR'.
#           3. a linha do DV virou dado outra vez: sigla + L1/master, sem
#              paragrafo e sem nome de ferramenta de terceiro.
#           4. BUG: Iniciar no meio da fase B derrubava o runspace e a
#              linha ficava presa em 'medindo' pela conversao inteira.
#           5. BUG: .mkv truncado na saida (PC reiniciou no mkvmerge)
#              contava como 'Ja Existe na Saida' e travava o arquivo.
#    16.78  04/09/2026  ENQUANTO MEDE, A LINHA E CINZA - NAO VERDE.
#           Verde aqui quer dizer "e o melhor resultado possivel", e
#           isso nao esta provado antes de a medida chegar. Cinza e a cor
#           de "ainda nao ha veredicto"; vira verde (MEL) ou ambar (FEL)
#           quando a fase B responde.
#    16.77  04/09/2026  A MEDICAO SAIU DA LEITURA DA PASTA.
#           Medir MEL x FEL custa de 2 a 5s POR ARQUIVO, e a 16.76 fazia
#           isso dentro da leitura: 20 filmes = quase 2 minutos de tela
#           parada. Agora a leitura volta a ser instantanea e a medicao
#           roda em segundo plano, preenchendo cada linha conforme mede.
#           Enquanto nao mediu, a tela diz que esta medindo - nunca que
#           esta limpa.
#    16.76  04/09/2026  A JANELA PASSOU A DIZER MEL x FEL (2.0 / item 1).
#                       A coluna DOLBY VISION mostra "7.6 FEL → 8.1", o
#                       diagnóstico traz o selo do arquivo (conversão limpa,
#                       com ressalva, ou não medida) e o chip da coluna
#                       deixou de ser verde quando há ressalva — verde é
#                       afirmação, e num FEL a afirmação seria falsa.
#                       De brinde, uma armadilha real: o motor chama a
#                       ferramenta de $doviTool e a janela só tinha
#                       $dovi_tool. Função carregada pela AST enxerga só as
#                       variáveis da janela — sem a ponte, todo arquivo sairia
#                       "não medido" sem um único erro na tela.
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
$SCRIPT_VERSION = "19.15"

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
$APP_VERSAO = "2.0"
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
            <#  2.0.7: o VERSAO.txt do ultimo INSTALADOR vencia sempre. Quem cola
                os .ps1 novos em cima (o fluxo de teste) via "v1.9.3" no titulo por
                25 builds - e nao dava para saber de qual build era um log. Agora
                vale o MAIOR dos dois. #>
            if ($ln -match '^\s*Produto\s*:\s*(\S+)') {
                $vArq = $Matches[1]
                try { if ([version]$vArq -gt [version]$APP_VERSAO) { $APP_VERSAO = $vArq } } catch { }
                break
            }
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
$script:MotivoVazio = ""
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
function Get-PastaDados {
    <#  17.02 - ONDE O PROGRAMA GUARDA O QUE E DELE.

        O idioma escolhido e a calibragem do tempo eram gravados na pasta
        do proprio programa. Funciona quando o LaFirma mora em C:\LaFirma,
        e falha calada quando ele mora em Program Files - o Windows nega a
        escrita e o catch engolia o erro. Era esse o defeito de "escolhi
        ingles, fechei e voltou em portugues": a escolha nunca chegou ao
        disco.

        Agora: tenta a pasta do programa (que continua sendo o lugar certo
        para quem instala em C:\LaFirma, e mantem o que ja esta gravado);
        se ela nao aceita escrita, cai para %LOCALAPPDATA%\LaFirma, que e
        do usuario e sempre aceita. O teste e uma escrita de verdade, nao
        um palpite pelo caminho. #>
    if ($script:PastaDados) { return $script:PastaDados }
    $cand = $script:PastaScript
    try {
        $sonda = Join-Path $cand ".lafirma_escrita.tmp"
        [System.IO.File]::WriteAllText($sonda, "x")
        [System.IO.File]::Delete($sonda)
    } catch {
        $cand = Join-Path $env:LOCALAPPDATA "LaFirma"
        try { if (-not (Test-Path -LiteralPath $cand)) { New-Item -ItemType Directory -Path $cand -Force | Out-Null } }
        catch { $cand = $script:PastaScript }
    }
    $script:PastaDados = $cand
    return $cand
}

<#  17.19 - A SESSAO INTEIRA SEM LOG, EM SILENCIO.

    O log tentava _logs\ e, se nao desse, a raiz do programa. As duas ficam
    DENTRO da pasta de instalacao - entao numa instalacao em Program Files (ou
    qualquer pasta sem escrita) as duas falham, o StreamWriter estoura num
    catch vazio, $LogEscritor fica nulo e o programa roda a sessao toda sem
    gravar uma linha. Sem aviso nenhum.

    E justamente quem tem o problema e quem fica sem a prova dele: "me manda o
    log" nao tem resposta.

    A licao 23 ja existia para isto - Get-PastaDados decide ESCREVENDO, nao
    olhando o caminho - e o log era a unica escrita do programa que ainda nao
    a usava. Agora usa, na mesma ordem das outras: pasta do programa primeiro
    (quem instala em C:\LaFirma nao muda nada), %LOCALAPPDATA%\LaFirma
    depois.

    E quando cai para a pasta de dados, a PRIMEIRA linha do log diz isso - o
    caminho novo aparece no painel Log, senao vira "sumiu". #>
$script:LogCaiuParaDados = $false
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
} catch {
    <#  17.19: a pasta do programa nao aceita escrita. Em vez de ficar sem log,
        vai para a pasta de dados do usuario - a mesma que guarda o idioma e a
        calibragem desde a 17.02. #>
    try {
        $pastaAlt = Join-Path (Get-PastaDados) "_logs"
        [System.IO.Directory]::CreateDirectory($pastaAlt) | Out-Null
        $script:LogArquivo = Join-Path $pastaAlt ("LaFirma_motor_log_{0}.txt" -f (Get-Date -Format "yyyy-MM-dd_HHmmss"))
        $script:LogEscritor = New-Object System.IO.StreamWriter($script:LogArquivo, $false, [System.Text.Encoding]::UTF8)
        $script:LogEscritor.AutoFlush = $true
        $script:LogCaiuParaDados = $true
    } catch { }
}

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
    <#  17.19: so aparece quando houve desvio. Linha que so existe quando algo
        saiu do padrao vale mais que uma linha fixa dizendo o obvio. #>
    if ($script:LogCaiuParaDados) {
        Escrever-Log ("LOG: a pasta do programa nao aceita escrita - este log esta em {0}" -f $script:LogArquivo) "AVISO"
    }
    if (-not $script:LogEscritor) {
        $script:LogLinhas.Add("[--------] [AVISO] LOG: nao foi possivel gravar em disco - o painel Log desta sessao e tudo que existe")
    }
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
<#  17.24: PararMedicao e um canal VIVO para a fase B, separado do Cancelar.
    Cancelar derruba a leitura INTEIRA; este so diz "pule a medicao" - a fase
    A termina e a fila fica completa. Sem ele, desligar a chave no meio de uma
    leitura so tinha um caminho: matar o runspace, que e o que quebrou a
    janela no log de 16/09 18:06. #>
$script:Controle = [hashtable]::Synchronized(@{ Pausar = $false; Cancelar = $false; Rodando = $false; PararMedicao = $false; MedSerieViva = 0 })
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
    <#  19.15 (2.0.18): a reta do caso COM video extraido estava errada. O
        intercepto de 51s veio do remux direto e foi emprestado para o outro
        caso com um ponto so (Troy). Tres filmes medidos em 23/09, duas vezes
        cada (a etapa 5 inteira, com conferencia e limpeza):
            GoT 20,6 GB -> 102/104/99s   Ryan 82 GB -> 359/368s   Troy 87 GB -> 406/396s
        A reta por eles: 8s + 4,5 s/GB - devolve 101, 377 e 400. Com os 51s o
        GoT saia previsto em 136s para 100 reais, e era essa a maior parte do
        -27% dele. O remux direto continua com os 51s dele (medidos). #>
    RemontagemSegFixo    = 51      # remux direto (sem video extraido)
    RemontagemExtraidoSegFixo = 8  # com video extraido - 19.15
    RemontagemSegPorGb   = 4.5     # com video extraido (remonta + apaga temporario) - 19.15
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
    return 1.0 + ((Get-FatorVelocidadeDisco) - 1.0) * $sens
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

<#  16.99 - A CONSTANTE VIROU PONTO DE PARTIDA, NAO VERDADE.

    Este numero e o que traduz "peso" em segundos, e ele era fixo desde que a
    barra existe. O sintoma esta medido em tres filmes, e nao e pequeno:

      Troy         previsto 1697s   real 1091s   +56%
      Se7en        previsto  910s   real  655s   +39%
      Spider-Man   previsto 1200s   real 1121s    +7%

    E ja esta medido que TROCAR A CONSTANTE NAO RESOLVE: usar a media (0,0115)
    melhora Troy e Se7en e faz o Spider-Man SUBESTIMAR 20% - e subestimar e o
    pior erro aqui, porque promete um tempo que nao vai ser cumprido. O
    problema nunca foi o valor: e que UM numero fixo tem que servir para
    maquinas, discos e filmes diferentes.

    Entao ele deixou de ser fixo. A cada arquivo convertido o programa grava
    quanto aquele arquivo REALMENTE custou por GB e por peso, e a proxima
    estimativa usa o P75 das ultimas cinco rodadas. Auto-calibra na maquina de
    quem esta usando, com o disco de quem esta usando.

    P75 e nao media, e nao mediana - as tres foram MEDIDAS antes da escolha, e
    a conta esta no bloco do Get-Percentil, mais abaixo. O resumo: a media vai
    atras de uma rodada esquisita, a mediana e a mais exata na media mas
    subestima 23% no pior caso, e subestimar promete um tempo que nao vai ser
    cumprido. O p75 troca exatidao media por nao prometer o que nao cumpre.

    (Ate a 17.19 este paragrafo dizia "MEDIANA", enquanto o codigo chama
    Get-Percentil 0.75 desde a 16.99. Comentario que descreve o que o codigo
    NAO faz e a licao 2 virada para dentro: a proxima pessoa "conserta" o
    codigo certo para bater com o texto errado.)

    O valor abaixo continua sendo o de partida: e o que vale na primeira
    execucao, e o que volta se o arquivo de calibragem sumir ou vier ilegivel.
    Ninguem fica sem estimativa por falta de historico. #>
$script:SegPorGbPorPesoPadrao = 0.0153
$script:SegPorGbPorPeso = 0.0153
# Limites de sanidade: fora disto a medida nao e calibragem, e acidente.
# 0,004 seria um disco NVMe irreal para o trabalho todo; 0,060 seria quatro
# vezes o pior caso ja medido. Os dois lados existem para que um numero
# estragado no arquivo nao contamine a proxima estimativa.
$script:CalibMin = 0.004
$script:CalibMax = 0.060
$script:CalibArquivo = "CALIBRAGEM.txt"
$script:CalibUsadas = @()

<#  ============================================================================
    2.0 - A CALIBRAGEM SE ANULAVA. PROVA ALGEBRICA E NUMERICA.

    "vc continua errando feio" e, toda sessao, o proprio programa avisando:

      CALIBRAGEM: as rodadas se espalham 44% entre si (0,0125 a 0,0180) ... a
      estimativa vai continuar errando por arquivo ate os pesos serem revistos.

    O aviso estava certo no diagnostico e a correcao nunca podia funcionar,
    porque desde a 16.64 a constante de calibragem NAO TEM EFEITO NENHUM sobre
    a estimativa. A algebra, com k = SegPorGbPorPeso:

      peso_i = round( s_i / (Gb * k) )        (Get-PesoDeSegundos)
      est    = Gb * k * SOMA(peso_i)          (Set-LoteParaConverter)
      est    = Gb * k * SOMA( s_i / (Gb * k) ) = SOMA( s_i )

    O k CANCELA. Medido com os numeros reais do Saving Private Ryan (81,99 GB,
    etapas 193,6 / 213,2 / 2524 / 387,8 / 346,2 s):

      k = 0,0125  -> soma de pesos 3576 -> estimativa 3.665,0s
      k = 0,0153  -> soma de pesos 2921 -> estimativa 3.664,2s
      k = 0,0176  -> soma de pesos 2540 -> estimativa 3.665,3s
      k = 0,0400  -> soma de pesos 1118 -> estimativa 3.666,6s

    A constante varia 3,2x e a estimativa anda 1,6 SEGUNDO em 3.665 - que e o
    arredondamento do peso para inteiro, nada mais. Cada linha gravada em
    CALIBRAGEM.txt era, na verdade, k vezes o erro daquele arquivo; e o "44%
    de espalhamento" era o erro por arquivo se espalhando 44%, relatado como
    se fosse a calibragem.

    Ou seja: o programa vinha prometendo, em toda sessao, uma auto-correcao
    que ele nao fazia. Licao 2 na escala de um modelo inteiro.

    O QUE MUDA AGORA

    1. A calibragem sai de DENTRO da conta de peso e passa a multiplicar os
       SEGUNDOS previstos. Fora do laco, ela nao tem como se anular.
    2. E ela deixa de ser UM numero para o arquivo inteiro e passa a ser UM
       POR ETAPA. Esse era o motivo real dos 44%: um filme TrueHD longo e
       pequeno e um filme DTS curto e grande erram em direcoes OPOSTAS, e um
       escalar unico nao descreve as duas formas ao mesmo tempo. Com um fator
       por etapa, "esta maquina e 20% mais lenta no audio" deixa de brigar com
       "este disco e 10% mais rapido na remontagem".
    3. O peso continua existindo e continua derivado dos segundos - ele e a
       LARGURA DA REGUA, e a regua nao mudou. O que mudou e quem decide o
       tempo previsto.

    LICAO 49: UM NUMERO QUE APARECE NOS DOIS LADOS DA MESMA CONTA NAO E UM
              AJUSTE - E UMA TROCA DE UNIDADE. Antes de confiar numa
              constante de calibragem, varie ela e veja o resultado mudar.
    ============================================================================ #>
$script:FatorEtapaPadrao = @(1.0, 1.0, 1.0, 1.0, 1.0)
$script:FatorEtapa       = @(1.0, 1.0, 1.0, 1.0, 1.0)
# Limites de sanidade POR ETAPA: uma etapa que saiu 4x do previsto nao e a
# maquina - e outra coisa (cancelamento, pausa longa, arquivo trocado).
$script:FatorEtapaMin = 0.25
$script:FatorEtapaMax = 4.00
$script:CalibEtapaArquivo = "CALIBRAGEM_ETAPAS.txt"
# 19.15: "remontagem2" - a base da etapa 5 mudou; o historico antigo foi medido
# contra a reta velha e aplicado na nova daria +9%. Recomeca do zero.
$script:NomeEtapaCalib = @("extracao", "dovi", "audio", "legenda", "remontagem2")

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
    param($EscolhasDaJanela, $CensosDaJanela)
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
        $script:ultimaLinhaMotor = ""
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
                # 2.0.10: o SaySub do motor escreve a sub-etapa DUAS vezes - a
                # linha "- OCR completo (...)" e, logo atras, a mesma frase como
                # repintura. No log saiam as duas, uma embaixo da outra (log de
                # 23/09: OCR, Corretor e Reocr repetidos). A repintura que so
                # repete a linha anterior vira nota da etapa, e nao linha nova.
                $eco = ("$($script:ultimaLinhaMotor)" -replace '^-\s+', '').Trim()
                if ($lim -ne $eco) { Enviar @{ T = "log"; Texto = $lim; Tipo = "MOTOR" } }
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
            $script:ultimaLinhaMotor = $lim
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

        # --- 6c. 2.0.7: o censo do filme inteiro vai para o motor ----------
        # O motor so tinha a AMOSTRA e escrevia "NAO RECOMENDADA" em cima de
        # um censo que a janela ja tinha feito (TROTF: 15 de 2.225 cenas).
        # Mesmo truque do nome proprio da porta manual (6b).
        if ($CensosDaJanela -and $CensosDaJanela.Count -gt 0) {
            $script:CensosDoFilme = $CensosDaJanela
            Avisar ("censo do filme inteiro enviado para {0} arquivo(s)" -f $CensosDaJanela.Count) "PROVA"
        } else {
            $script:CensosDoFilme = $null
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
<#  17.08 - O CENSO COMPLETO RODA NO SEU PROPRIO RUNSPACE (item A).

    Ele leva de um a tres minutos num filme grande. Na thread da janela isso
    seria a tela congelada o tempo todo - e o Diego ja pagou esse preco na
    16.76. Runspace proprio, mensagem de volta pela mesma fila de sempre.

    A ARMADILHA DE SEMPRE, ESCRITA AQUI PARA NAO SER PISADA DE NOVO: aqui
    dentro as funcoes da JANELA nao existem. Nada de Escrever-Log neste bloco
    (foi o defeito da 17.06, que derrubou a leitura inteira). Quem fala daqui
    e a Avisar declarada logo abaixo, neste proprio bloco. #>
$script:TrabalhoCenso = {
    function Enviar($m) { $Fila.Enqueue($m) }
    function Avisar([string]$t, [string]$tipo = "LEITURA") { Enviar @{ T = "log"; Texto = $t; Tipo = $tipo } }
    try {
        $achar = {
            param($nome)
            $r = Get-ChildItem -Path $PastaScript -Filter $nome -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($r) { return $r.FullName } else { return $null }
        }
        $ffmpeg   = & $achar "ffmpeg.exe"
        $ffprobe  = & $achar "ffprobe.exe"
        # O motor batiza esta variavel de $doviTool - mesma licao da 16.76.
        $doviTool = & $achar "dovi_tool.exe"
        if (-not $ffmpeg -or -not $doviTool) {
            Avisar "CENSO: sem ffmpeg ou dovi_tool nao da para ler o RPU do filme inteiro." "ERRO"
            Enviar @{ T = "censo_fim"; Serie = $Serie; Idx = $Idx; Caminho = "$Caminho"; Ok = $false; Erro = "ferramenta ausente" }
            return
        }

        $errosSint = $null; $tokens = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($CaminhoMotor, [ref]$tokens, [ref]$errosSint)
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
        if (-not (Get-Command "Get-CensoCompletoDV" -CommandType Function -ErrorAction SilentlyContinue)) {
            Avisar "CENSO: o motor nao tem Get-CensoCompletoDV." "ERRO"
            Enviar @{ T = "censo_fim"; Serie = $Serie; Idx = $Idx; Caminho = "$Caminho"; Ok = $false; Erro = "funcao ausente no motor" }
            return
        }

        Avisar ("CENSO COMPLETO de '{0}': lendo o RPU do filme inteiro. A medicao normal le uma amostra; esta le todas as cenas." -f $Nome) "LEITURA"
        $r = Get-CensoCompletoDV -MkvPath $Caminho -MasterMaxConhecido ([double]$MasterMax)

        if (-not $r.Ok) {
            Avisar ("CENSO COMPLETO de '{0}': FALHOU - {1}" -f $Nome, "$($r.Erro)") "ERRO"
            Enviar @{ T = "censo_fim"; Serie = $Serie; Idx = $Idx; Caminho = "$Caminho"; Ok = $false; Erro = "$($r.Erro)" }
            return
        }

        <#  O LOG GUARDA A MEDIDA, NAO SO O VEREDICTO - a regra que o Diego
            fixou em 04/09 e repetiu em 10/09 ("tudo tem que ser medido, e
            pensando em comparacoes futuras"). Sem os segundos aqui nao da
            para comparar o censo com a amostra depois. #>
        Avisar ("CENSO COMPLETO de '{0}': {1} quadro(s) no RPU, {2} cena(s), pico de cena {3:N2} nits | RPU {4:N2} MB | RPU {5:N1}s + censo {6:N1}s = {7:N1}s" -f `
            $Nome, [int]$r.QuadrosNoRpu, [int]$r.CenasNoCenso, [double]$r.PicoDeCena,
            [double]$r.RpuMb, [double]$r.SegundosRpu, [double]$r.SegundosCenso, [double]$r.Segundos) "LEITURA"
        if ([double]$r.MasterMax -gt 0) {
            Avisar ("   {0} de {1} cena(s) do FILME INTEIRO ({2}%) pedem mais que os {3:N0} nits do master." -f `
                [int]$r.CenasAcimaDoMaster, [int]$r.CenasNoCenso,
                [double]$r.PctAcimaDoMaster, [double]$r.MasterMax) "LEITURA"
        } else {
            Avisar "   O container nao declarou o pico do mastering display - o censo conta as cenas, mas nao ha regua para comparar." "LEITURA"
        }
        if ($r.ReguaSuspeita) {
            Avisar ("   REGUA SUSPEITA: {0}" -f "$($r.ReguaSuspeitaMotivo)") "LEITURA"
        }
        if ([double]$AmostraSeg -gt 0) {
            Avisar ("   Custo: a amostra levou {0:N1}s neste arquivo; o censo completo levou {1:N1}s ({2}x)." -f `
                [double]$AmostraSeg, [double]$r.Segundos,
                [math]::Round([double]$r.Segundos / [double]$AmostraSeg, 1)) "LEITURA"
        }

        Enviar @{ T = "censo_fim"; Serie = $Serie; Idx = $Idx; Caminho = "$Caminho"; Ok = $true; Erro = ""
                  Quadros = [int]$r.QuadrosNoRpu; Cenas = [int]$r.CenasNoCenso
                  CenasAcima = [int]$r.CenasAcimaDoMaster; Pct = [double]$r.PctAcimaDoMaster
                  PicoCena = [double]$r.PicoDeCena; MasterMax = [double]$r.MasterMax
                  ReguaSuspeita = [bool]$r.ReguaSuspeita
                  ReguaSuspeitaMotivo = "$($r.ReguaSuspeitaMotivo)"
                  <#  18.20: o tamanho do RPU VIAJA na mensagem. A 18.19 criou
                      uma trava que confere este numero e eu esqueci de manda-lo
                      - entao ele chegava vazio, valia zero, e TODO censo
                      completo era descartado como se fosse pela metade. #>
                  RpuMb = [double]$r.RpuMb
                  Seg = [double]$r.Segundos }
    } catch {
        Enviar @{ T = "log"; Texto = ("ERRO no censo completo: {0}" -f $_.Exception.Message); Tipo = "ERRO" }
        Enviar @{ T = "censo_fim"; Serie = $Serie; Idx = $Idx; Caminho = "$Caminho"; Ok = $false; Erro = $_.Exception.Message }
    }
}

<#  ============================================================================
    18.00 - OS TRES TRABALHOS, SEPARADOS

    Ate a 17.24 a MEDICAO (fase B) morava DENTRO da leitura da pasta (fase A).
    Um runspace so, fazendo duas coisas com tempos de vida diferentes:

        fase A - ler faixas/audio/DV   ~4s por arquivo   SEMPRE necessaria
        fase B - medir MEL x FEL      14-26s por arquivo  so com a chave ligada

    Isso obrigava contorcao atras de contorcao, e cada uma criou a proxima. Em
    24 horas sairam quatro builds remendando a mesma area (1.9.6 a 1.9.9), duas
    delas consertando o que a anterior quebrou. O Diego resumiu: "vc vem com
    novas builds mto rapidas, mexe so um negocinho e vem mais teste".

    O QUE A JUNCAO CUSTAVA, medido nos logs dele de 16/09:

      1. A JANELA CONGELAVA DE VERDADE. Parar a medicao so tinha um caminho:
         matar o runspace. E Stop-Motor espera o runspace morrer com
         AsyncWaitHandle.WaitOne(1500) NA THREAD DA INTERFACE. Medido quatro
         vezes no log dele: 1,52s / 1,93s / 2,01s / 1,91s de janela parada.
         Era o "quando desliga ele fica la medindo ainda por um tempo".

      2. LIGAR A CHAVE RELIA A PASTA INTEIRA, porque a unica forma de comecar
         a medir era comecar uma leitura. 28 releituras numa sessao, 254,5s.

      3. LIGAR A CHAVE MATAVA O CENSO. 18:32:22 ele pediu o censo (105s de
         trabalho); 18:32:23,4 ligou a chave; 18:32:23,8 o censo morreu, porque
         releitura mata censo. Ele esperou por um trabalho ja cancelado.

      4. UM BOTAO, SEIS MENSAGENS. A chave tinha seis saidas diferentes, cada
         uma um "if" que eu somei quando um caso quebrou. Isso nao e modelo, e
         casuistica - e do lado de fora vira comportamento imprevisivel.

    AGORA SAO TRES TRABALHOS INDEPENDENTES, cada um com um dono:

      LER A PASTA   disparada por: trocar pasta, Atualizar, abrir o programa
                    cancelada por: Parar leitura, trocar pasta
      MEDIR CAMADA  disparada por: a chave ligada + existe arquivo sem veredicto
                    cancelada por: a chave desligada
      CENSO         disparado por: o botao Censo
                    cancelado por: novo censo, inicio de conversao

    Nenhum derruba o outro. Cancelar a medicao virou erguer uma flag e voltar
    NA HORA - nao ha mais espera na thread da interface.

    O PREAMBULO (achar ferramentas + abrir o motor pela AST) e o MESMO para a
    leitura e para a medicao, e por isso mora em UM lugar so, aqui embaixo.
    Duas copias divergem - e a divergencia silenciosa entre dois lugares que
    deviam dizer a mesma coisa e a familia de defeito que este projeto persegue
    desde a 16.79. Cada trabalho injeta este texto e confere $PreparoOk. #>
$script:PreambuloTrabalho = @'
        $PreparoOk = $false
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
        <#  16.76: O MOTOR CHAMA ESTA FERRAMENTA DE $doviTool.
            A janela sempre batizou a variavel de $dovi_tool, e ate agora
            nenhuma FUNCAO do motor precisava dela - o dovi_tool so era usado
            no fluxo principal, que a janela nao executa. Get-TipoCamadaDV
            (2.0 / item 1) precisa, e funcao carregada pela AST enxerga so as
            variaveis que existem AQUI. Sem esta linha ela nao acharia a
            ferramenta e todo arquivo sairia como "nao medido" - sem erro
            nenhum na tela, que e o pior jeito de quebrar. #>
        $doviTool  = $dovi_tool
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
            # 2.0.7: o seconv saiu do instalador (recusado em todos os filmes medidos
            # desde 13/08). O PgsToSrt deixou de ser "reserva" - e ELE o OCR.
            @{ Chip = "PgsToSrt";  Rotulo = "OCR de Legenda PT-BR (PgsToSrt)";             Papel = "opcional";    Ok = [bool]$pgstosrt; Caminho = $pgstosrt }
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
            $PreparoOk = $false
            return
        }

        # --- 2. abrir o motor pela AST (sem executa-lo) ---
        if (-not (Test-Path -LiteralPath $CaminhoMotor)) {
            Avisar "Converter_AUTO_DIRETO.ps1 nao encontrado ao lado da GUI." "ERRO"
            $PreparoOk = $false
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
                      "Get-FaixaCompativelC2Externa","Test-IdiomaConflitante",
                      "Get-TipoCamadaDV")
        $faltam = @($exigidas | Where-Object { -not (Get-Command $_ -CommandType Function -ErrorAction SilentlyContinue) })
        if ($faltam.Count -gt 0) {
            Avisar ("FALTARAM funcoes no motor: {0}" -f ($faltam -join ", ")) "ERRO"
            $PreparoOk = $false
            return
        }
        $PreparoOk = $true
'@

<#  Quem falhar no preparo avisa do SEU jeito: a leitura manda "leitura_fim",
    a medicao manda "el_fim". O preambulo so diz SE deu certo - ele nao sabe
    quem o chamou, e nao deve saber. #>
$script:TrabalhoLeitura = {
    function Enviar($m) { $Fila.Enqueue($m) }
    function Avisar([string]$t, [string]$tipo = "LEITURA") { Enviar @{ T = "log"; Texto = $t; Tipo = $tipo } }
    try {
        . ([scriptblock]::Create($Preambulo))
        if (-not $PreparoOk) {
            Enviar @{ T = "leitura_fim"; SerieL = $SerieL; Ok = 0; Erros = 1; Seg = 0 }
            return
        }
        # --- 3. varrer a pasta ---
        $arquivos = @(Get-ChildItem -LiteralPath $PastaOrigem -Filter *.mkv -File -ErrorAction SilentlyContinue | Sort-Object Name)
        Enviar @{ T = "leitura_ini"; SerieL = $SerieL; Total = $arquivos.Count }
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
            Enviar @{ T = "vazio"; SerieL = $SerieL; Motivo = $motivo }
        }

        $cron = [System.Diagnostics.Stopwatch]::StartNew()
        $bons = 0; $ruins = 0
        # 16.77: quem a FASE B vai medir. Preenchida durante a leitura,
        # consumida depois que a fila ja esta na tela.
        $pendentesEL = @()
        for ($i = 0; $i -lt $arquivos.Count; $i++) {
            if ($Controle.Cancelar) { break }
            $a = $arquivos[$i]
            Enviar @{ T = "leitura_pct"; SerieL = $SerieL; Idx = $i; Total = $arquivos.Count; Nome = $a.Name }

            # os caches internos do motor sao por arquivo
            $script:CacheMkvJsonPath = $null; $script:CacheMkvJson = $null
            $script:CacheInfoDVPath  = $null; $script:CacheInfoDV  = $null
            $script:CacheSinaisAtmosPath = $null; $script:CacheSinaisAtmos = $null
            $script:CacheTipoELPath  = $null; $script:CacheTipoEL  = $null

            $d = @{ Nome = $a.BaseName; Arquivo = $a.Name; Caminho = $a.FullName
                    Bytes = $a.Length; Ignorar = $false; MotivoIgnorar = ""
                    Faixas = @(); DVprecisa = $false; AUprecisa = $false; LGprecisa = $false
                    Modo = "Automatico"
                    # m3c25: dados brutos do audio que sai. Declarados aqui pra
                    # nunca faltarem (arquivo sem audio, erro de leitura), senao
                    # a coluna quebraria em vez de so nao mostrar o detalhe.
                    AudioModo = ""; PrincipalCanais = 0; PrincipalTrueHD = $false
                    DiagDVcor = "cinza"; DiagAucor = "cinza"; DiagLgcor = "cinza"
                    # 16.76: declarados aqui pelo mesmo motivo dos demais -
                    # arquivo que nem chega a ser lido nao pode deixar a tela
                    # com o selo do arquivo anterior.
                    ELtipo = "NAO_APLICAVEL"; ELselo = "-"; ELmotivo = ""
                    # 16.77: o container e lido na fase A (instantaneo) e
                    # guardado, porque a FASE B precisa remontar as mesmas
                    # frases depois, ja com o tipo de camada medido.
                    DVnome = ""; DVcodec = ""; DVcamadas = ""; DVperfil = 0; DVlevel = ""
                    ELmaxcll = 0.0; ELmaxfall = 0.0; ELdm = ""; ELpontos = ""
                    ELcenas = 0; ELcenasAcima = 0; ELpicoCena = 0.0; ELexpande = $null
                    P5 = $false
                    # 16.96: qual regua respondeu ("master" ou "nenhuma") e os
                    # numeros do container, que sao CONTEXTO e nunca regua.
                    ELregua = "nenhuma"; ELctnMaxCLL = 0; ELctnMaxFALL = 0
                    <#  17.08 - A REGUA TORTA (item D) E O CENSO COMPLETO
                        (item A) moram na linha, como todo o resto do
                        veredicto: o objeto do video e a unica memoria que
                        sobrevive a uma releitura de tela. #>
                    ELreguaSuspeita = $false; ELreguaSuspeitaMotivo = ""
                    ELpctAcima = 0.0
                    # A regua e o custo da amostra ficam guardados porque o
                    # censo completo (item A) reaproveita os dois: uma leitura,
                    # um lugar - e o "x vezes mais caro" precisa do de-antes.
                    ELmastermax = 0.0; ELsegundos = 0.0
                    CensoFeito = $false; CensoResumo = ""; CensoCenas = 0; CensoAcima = 0; CensoPico = 0.0
                    L5bordas = ""; L5formato = ""; L5area = ""
                    # 16.79: o pico do master e a UNICA referencia que da
                    # sentido ao L1. Sem ele, "153 nits" nao decide nada.
                    DVmaster = 0.0
                    # 16.84: a string do MediaInfo COM a sigla medida, para a
                    # coluna NOME DA FAIXA do video na aba Faixas - que no GOT
                    # vinha vazia porque o release nao nomeou a faixa.
                    DVtextoFaixa = ""
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
                    <#  16.77: A MEDICAO DE MEL x FEL SAIU DA LEITURA DA PASTA.

                        A 16.76 media aqui dentro, arquivo por arquivo. Medido
                        na maquina do Diego (log 04/09 16:40): 4 arquivos em
                        17,57s; GOT de 20 GB em 12,57s no HD e 7,72s no SSD;
                        Troy de 87 GB em ~9s. O TAMANHO DO ARQUIVO QUASE NAO
                        PESA - o corte e "-c copy" -, o custo e fixo por
                        arquivo: 3 cortes + 3 extract-rpu + 3 info. Numa pasta
                        de 20 filmes isso vira quase dois minutos de tela
                        parada antes de dar para clicar em Iniciar, e a
                        leitura da pasta e justamente o momento em que o
                        programa precisa ser rapido.

                        Agora a fase A le so o container (instantaneo) e a
                        medicao vai para a FASE B, que roda DEPOIS da fila
                        aparecer e preenche cada linha conforme mede. Ninguem
                        espera por ela. Se o usuario mandar converter antes de
                        terminar, nao perde nada: o motor mede de novo no
                        inicio da conversao, que e onde a decisao acontece e
                        onde 11s dentro de 19 minutos nao sao nada.

                        O que NAO mudou: enquanto nao mediu, a tela nao afirma
                        que a conversao e limpa. Ela diz que esta medindo. #>
                    try {
                        $br = Get-BrilhoDoContainer -MkvPath $a.FullName
                        if ($br -and $br.MasterMax -gt 0) { $d.DVmaster = [double]$br.MasterMax }
                    } catch { }
                    $d.DVnome = "$($dv.Nome)"; $d.DVcodec = "$($dv.Codec)"
                    $d.DVcamadas = "$($dv.Camadas)"; $d.DVlevel = "$($dv.Level)"
                    $d.DVperfil = [int]$dv.Perfil
                    $d.DiagDVrot = "Dolby VISION: $($dv.Nome) [$($dv.Codec)] [$($dv.Camadas)] [DETECTADO]"
                    if ($dv.Perfil -eq 8 -and $dv.Camadas -notmatch "EL") {
                        $d.DiagDVres = "→ [NÃO NECESSÁRIO] Já Está em Profile 8.1"; $d.DiagDVcor = "cinza"
                        # Mesmo formato do outro ramo: so o numero do perfil.
                        # "Profile 8.1 - ok" nao cabia e saia cortado.
                        $d.ColDV = "{0} OK" -f ($dv.Nome -replace '^\s*Profile\s*', '')
                    } elseif ($dv.Perfil -eq 5) {
                        <#  16.92 - O PERFIL 5 TINHA RAMO NENHUM, E A TELA MENTIA.

                            Ate aqui o P5 caia no ramo "senao" junto com o
                            Profile 7: a coluna dizia "5.0 -> 8.1" e a linha
                            dizia "[SERA CONVERTIDO] Profile 8.1". O motor,
                            no mesmo programa, ja dizia o contrario ha
                            semanas: chegar a 8.1 a partir do P5 RECODIFICA
                            o video, e recodificar e o que este programa se
                            recusa a fazer. A tela prometia o que o motor ia
                            negar - a mesma familia do bug da legenda.

                            Agora ele tem ramo proprio, e a resposta diz o
                            caminho que existe de verdade: remux para MP4,
                            sem recodificar, que e como um P5 toca em TV. #>
                        <#  16.95: O CAMINHO DEIXOU DE SER SO UMA FRASE.

                            Na 16.92 esta linha ja dizia a verdade sobre o
                            8.1 - e prometia um remux para MP4 que o motor
                            nao fazia. Meia-verdade e a mesma familia de
                            defeito, so que do outro lado: a tela apontava
                            uma porta que nao existia.
                            Na 14.45 o motor passou a executar esse remux
                            (video copiado, tag dvh1, audio copiado quando
                            cabe no MP4). Entao o P5 volta a TER trabalho:
                            DVprecisa e $true de novo, e ele deixa de cair em
                            "Nada a Converter". #>
                        $d.DiagDVres = "→ [SERÁ REMUXADO] Profile 5 não vira 8.1 sem recodificar o vídeo — o caminho dele é o MP4, com o vídeo copiado"
                        $d.DiagDVcor = "verde"
                        $d.ColDV = "P5 → MP4"
                        $d.DVprecisa = $true
                        $d.P5 = $true
                    } else {
                        <#  A frase de resposta passa a carregar o selo. Ela e a
                            unica linha da tela que o usuario le antes de mandar
                            converter - dizer so "SERA CONVERTIDO" num FEL deixa
                            ele achar que o resultado e sempre sem perda, que e
                            justamente a omissao que a 2.0 veio fechar. #>
                        $d.DiagDVres = "→ [SERÁ CONVERTIDO] Profile 8.1 [dvhe.08.06] [BL+RPU]"; $d.DiagDVcor = "verde"
                        $d.ColDV = "$($dv.Perfil).$($dv.Level) → 8.1"
                        $d.DVprecisa = $true
                        # So Profile 7 COM EL tem MEL x FEL a medir. Nos outros
                        # casos nao ha camada nenhuma para classificar, e a
                        # fase B nem toca no arquivo.
                        if ($dv.Perfil -eq 7 -and $dv.Camadas -match "EL") {
                            <#  18.00 - A LEITURA NAO DECIDE MAIS QUE ESTA "MEDINDO".

                                Ate a 17.24 ela marcava MEDINDO em todo P7 com
                                EL, sempre - mesmo com a chave desligada, porque
                                a decisao de medir vivia la na frente, dentro do
                                mesmo trabalho. Dai saia, em TODA leitura com a
                                chave desligada, a linha "Medicao interrompida em
                                3 arquivo(s)" no log, falando de uma medicao que
                                nunca tinha comecado.

                                A leitura nao sabe se vai haver medicao - quem
                                sabe e a janela, depois que a fila estiver na
                                tela. Entao a leitura diz a verdade do que ela
                                mesma apurou: este arquivo tem camada EL e ainda
                                NAO TEM VEREDICTO. Quem for medido de fato vira
                                MEDINDO em Start-Medicao, um por um.

                                Os textos (coluna, rotulo, resposta) nao sao
                                montados aqui: quem escreve e Update-TextosDV,
                                no lugar unico da 16.84, quando a mensagem
                                "video" chega na janela. #>
                            $d.ELtipo = "NAO_MEDIDO"; $d.ELselo = "NAO MEDIDO"
                            $d.ELmotivo = "ainda sem veredicto de camada"
                            # 17.10: o GB viaja junto - sem ele nao da para
                            # dizer "tantos segundos por GB", que e a unica
                            # forma de comparar pastas de tamanhos diferentes.
                            $pendentesEL += ,@{ Idx = $i; Path = $a.FullName; Dur = [double]$d.DurSeg
                                                Nome = $a.Name; Gb = ($a.Length / 1GB) }
                        }
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
                    <#  16.80 - A REGRA DE NOMEAR FAIXA DE AUDIO, NUM LUGAR SO.

                        A 16.79 consertou o ROTULO ("Surround" -> "TrueHD
                        Atmos 7.1") e deixou a RESPOSTA com o mesmo defeito:
                        "[REAPROVEITADO] E-AC-3 Atmos" tambem era o track_name,
                        nao o codec. Conserto pela metade e o mesmo bug de pe -
                        e o Diego achou em 10 minutos.

                        Agora existe UMA funcao que da nome a uma faixa de
                        audio, e os dois lados chamam ela. Nao da mais para
                        consertar um e esquecer o outro. #>
                    function Rotular-Audio($Faixa, [bool]$EhAtmos) {
                        if (-not $Faixa) { return "" }
                        $r = "$($Faixa.codec)"
                        if ($EhAtmos -and $r -notmatch "(?i)atmos") { $r = "$r Atmos" }
                        $c = 0
                        if ($Faixa.properties.audio_channels) { $c = [int]$Faixa.properties.audio_channels }
                        if ($c -ge 2) {
                            $l = switch ($c) { 8 { "7.1" } 6 { "5.1" } 2 { "2.0" } default { "$c ch" } }
                            $r = "$r $l"
                        }
                        return $r
                    }
                    <#  16.79 - O DIAGNOSTICO MOSTRAVA O NOME DA FAIXA NO
                        LUGAR DO CODEC. No GOT a faixa se chama "Surround", e
                        a tela dizia "AUDIO PRINCIPAL: Surround" enquanto o
                        motor, no mesmo arquivo, dizia "Dolby TrueHD Atmos".
                        Duas telas do mesmo programa, dois nomes para a mesma
                        faixa - e o que a janela mostrava nao era informacao
                        tecnica nenhuma: "Surround" e um rotulo que o release
                        escolheu, nao diz codec, nem canais, nem Atmos.
                        Agora quem manda e o CODEC, sempre. Canais e Atmos
                        entram porque mudam a decisao; o nome do release fica
                        de fora - quem quiser ve-lo abre a aba Faixas. #>
                    $rot = Rotular-Audio $pr $ehAtmos
                    <#  16.98 - "PRINCIPAL" SEGUNDO QUEM? (item de fila)

                        Este rotulo dizia "ÁUDIO PRINCIPAL" e o usuario lia
                        "a faixa que vai tocar". Nao e isso que ele quer
                        dizer, e a diferenca nao e detalhe.

                        A escolha aqui IGNORA de proposito a marca de padrao
                        do arquivo: em remux Dual Audio, a marca costuma
                        apontar a dublagem que o grupo de release preferiu,
                        e o programa quer o TrueHD/Atmos, esteja ele marcado
                        ou nao. A regra esta certa e vai continuar.

                        Errado era o NOME. Agora a linha diz de quem e a
                        escolha - e, quando a faixa escolhida NAO e a que o
                        arquivo marca como padrao, diz isso tambem. Esse e
                        exatamente o caso em que o usuario se surpreende, e
                        e o unico em que a frase precisa crescer. #>
                    $marcadaPadrao = $null
                    try {
                        # $json ja foi lido no comeco deste bloco (mkvmerge -J):
                        # nao custa uma segunda leitura do arquivo.
                        $marcadaPadrao = @(@($json.tracks) | Where-Object {
                            $_.type -eq "audio" -and $_.properties.default_track -eq $true }) | Select-Object -First 1
                    } catch { }
                    <#  17.06 - A LINHA VOLTOU AO TAMANHO DAS VIZINHAS.

                        A 16.98 resolveu o sentido e estragou a forma: o
                        rotulo ganhou um parentese explicativo e a linha
                        ganhou uma frase inteira de justificativa depois do
                        selo. Do lado de "Dolby VISION: Profile 7 [...]
                        [DETECTADO]" e "LEGENDA PT-BR [PGS]: ... [DETECTADO]",
                        a do audio virava um paragrafo - sozinha empurrava a
                        coluna da direita e quebrava o alinhamento do bloco.

                        A regra do Diego, e ela vale para o diagnostico
                        inteiro: a ESQUERDA detecta, a DIREITA diz o que sera
                        feito. Qual faixa o arquivo marcava como padrao nao e
                        nenhuma das duas coisas.

                        Entao a nota saiu da tela e foi para o LOG, inteira,
                        com o porque. Nao se perde: quem quer entender a
                        escolha abre o log; quem so quer o diagnostico nao
                        leva um paragrafo na cara.

                        A REGRA CONTINUA A MESMA: a escolha ignora de
                        proposito a marca de padrao do arquivo, porque em
                        remux Dual Audio ela costuma apontar a dublagem que o
                        grupo preferiu, e o programa quer o TrueHD/Atmos. #>
                    if ($null -ne $marcadaPadrao -and $null -ne $pr -and
                        [int]$marcadaPadrao.id -ne [int]$pr.id) {
                        # 17.07: AQUI DENTRO E O RUNSPACE - as funcoes da
                        # janela nao existem. Quem manda mensagem daqui e a
                        # Avisar declarada neste proprio bloco. A 17.06
                        # tropecou nisso e derrubou a leitura inteira; o
                        # porque completo esta no Changelog.
                        Avisar ("AUDIO: '{0}' - escolhida a faixa {1} ({2}); o arquivo marca a faixa {3} ({4}) como padrao. A escolha e pelo codec, nao pela marca." -f `
                            $a.Name, [int]$pr.id, (Rotular-Audio $pr $ehAtmos),
                            [int]$marcadaPadrao.id, (Rotular-Audio $marcadaPadrao $false)) "LEITURA"
                    }
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
                        # 16.80: MESMA regra do rotulo - codec, nunca o
                        # track_name. Num arquivo ja convertido a faixa se
                        # chama "E-AC-3 Atmos" porque o NOSSO motor batizou
                        # assim; ler esse nome de volta e o programa
                        # acreditando na propria etiqueta em vez do codec.
                        $nomeP = Rotular-Audio $pronta $prontaEhJoc
                        if ($prontaEhJoc) {
                            $d.DiagAures = "→ [REAPROVEITADO] $nomeP"; $d.DiagAucor = "cinza"
                            $d.ColAudio = "E-AC-3[ATMOS] OK"
                            $d.AudioModo = "joc"
                        } else {
                            # 16.8: faixa pronta que NAO e Atmos. Escrever
                            # "E-AC-3[ATMOS]" aqui seria a mesma mentira do resumo
                            # do Troy, onde um AC-3 448k dublado apareceu como
                            # Atmos reaproveitado. O codec vai escrito como ele e.
                            $d.DiagAures = "→ [REAPROVEITADO] $nomeP"; $d.DiagAucor = "cinza"
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
                    <#  16.87 - A RESPOSTA DIZIA O QUE ENTRA, NAO O QUE SAI.

                        Ela saia como "[SERÁ CONVERTIDA] Brazilian / PGS .SRT
                        (OCR)", porque colava o NOME DA FAIXA de origem antes
                        do formato de saida - e o nome dessa faixa, no Troy,
                        e literalmente "Brazilian / PGS". Resultado: a linha
                        do resultado anunciava PGS, que e justamente o que
                        deixa de existir. O Diego: "está sendo convertido
                        para .SRT, então isso é um resultado".

                        A esquerda ja diz de onde vem, com o nome real da
                        faixa. A direita diz so onde chega. Os dois ramos do
                        if antigo eram identicos - codigo morto desde a 16.79,
                        quando os dois pararam de prometer a ferramenta. #>
                    $d.DiagLgres = "→ [SERÁ CONVERTIDA] Legenda em Português no formato .SRT (por OCR)"
                    $d.DiagLgcor = "verde"
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
                        } elseif ($ptPgs -and $fid -eq [int]$ptPgs.id -and $ptTxt) {
                            <#  17.14 - A TABELA PROMETIA UM OCR QUE NUNCA IA ACONTECER.

                                Quando o arquivo tem AS DUAS faixas pt-BR - uma
                                .SRT de texto e uma PGS de imagem - o motor nao
                                roda OCR nenhum: ele reaproveita a de texto
                                (Caminho 1 da etapa de legenda, "[NAO NECESSARIO]
                                Legenda 'PT-BR .SRT' na Faixa N"). A janela dizia
                                outra coisa: marcava as DUAS como leg-ptbr e punha
                                CONVERTER na PGS. O Diego leu exatamente isso e
                                perguntou o obvio: "se ja existe uma .srt e uma pgs
                                para que converter outra perdendo tempo?".

                                Nao converte - e nunca ia converter. Era a TELA
                                mentindo sobre o motor, nao o motor errando. De
                                quebra, duas faixas com o mesmo Papel disputavam o
                                rotulo PADRAO da legenda e quem ganhava era a
                                ordem do arquivo.

                                A PGS continua no arquivo final (decisao de 22/08,
                                v14.23), entao o verbo honesto e MANTER, com o
                                motivo do lado. #>
                            $f.Papel = "leg-pgs-extra"; $f.VerboAuto = "MANTER"
                            $f.DetalheAuto = "Já Existe .SRT - OCR Não Necessário"
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

                <#  ---- ja existe na saida? ----

                    16.82 - BUG QUE EU MESMO CRIEI NA 16.79, E QUE O LOG DO
                    DIEGO PEGOU DE PRIMEIRA:

                      Erro lendo Troy...: O termo 'Test-SaidaCompleta' nao e
                      reconhecido como nome de cmdlet, funcao...

                    Eu escrevi Test-SaidaCompleta como funcao da JANELA e a
                    chamei AQUI DENTRO, no runspace da leitura - que so
                    enxerga as funcoes do motor carregadas pela AST e as
                    definidas dentro deste bloco. Efeito: TODO arquivo com
                    pasta de saida existente caiu em "Erro na Leitura".
                    E a mesmissima armadilha do $doviTool na 16.76 - o
                    runspace e outro mundo - cometida de novo por mim.

                    A licao nao e "declara nos dois lugares": duplicar regra
                    foi o que causou o bug do audio da 16.79/16.80. A licao e
                    NAO DECIDIR AQUI. Quem responde "ja existe na saida?" e a
                    janela, em Update-JaExiste, que ja roda depois de toda
                    leitura (via Update-Selecao) e ja tem a funcao. A leitura
                    so junta os dados. Uma regra, um lugar. #>
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
            Enviar @{ T = "video"; SerieL = $SerieL; Dados = $d }
        }
        $cron.Stop()
        Enviar @{ T = "leitura_fim"; SerieL = $SerieL; Ok = $bons; Erros = $ruins; Seg = ($cron.ElapsedMilliseconds / 1000.0)
                  MedirEL = $pendentesEL.Count }
    } catch {
        Enviar @{ T = "log"; Texto = ("ERRO na leitura: {0}" -f $_.Exception.Message); Tipo = "ERRO" }
        Enviar @{ T = "leitura_fim"; SerieL = $SerieL; Ok = 0; Erros = 1; Seg = 0 }
    }
}

<#  18.00 - A MEDICAO, AGORA SOZINHA.

    Recebe PRONTA a lista de quem medir ($Pendentes, montada pela janela a
    partir da fila que esta na tela) e nao varre pasta nenhuma. Nao existe mais
    o ramo "chave desligada" aqui dentro: se a chave esta desligada, a janela
    simplesmente NAO dispara este trabalho - decisao de quem tem a informacao,
    que e a janela, e nao de um parametro viajando para dentro do runspace.

    Cancelamento: $Controle.PararMedicao, o mesmo canal vivo da 17.24. O laco
    confere a cada arquivo. Ninguem precisa matar runspace nenhum para parar
    isto, e por isso a interface nao congela mais. #>
$script:TrabalhoMedicao = {
    function Enviar($m) { $Fila.Enqueue($m) }
    function Avisar([string]$t, [string]$tipo = "LEITURA") { Enviar @{ T = "log"; Texto = $t; Tipo = $tipo } }
    try {
        . ([scriptblock]::Create($Preambulo))
        if (-not $PreparoOk) {
            Enviar @{ T = "el_fim"; Serie = $Serie; Medidos = 0; Total = 0; Seg = 0; Gb = 0.0; Falhou = $true }
            return
        }

        <#  ---------------- FASE B: MEDIR MEL x FEL (16.77) ----------------
            Roda com a fila JA na tela e o botao Iniciar JA liberado. Cada
            arquivo medido vira uma mensagem "el" que atualiza aquela linha -
            a tela se preenche sozinha, ninguem fica esperando.
            So Profile 7 com EL entra aqui; os outros nem sao tocados. #>
        <#  16.83: checar o cancelamento ANTES de anunciar. No log de 05/09
            01:32:28 sairam, no MESMO milissegundo, "Medindo a camada de 1
            arquivo(s)" e "Medicao interrompida" - o usuario tinha clicado
            "Parar leitura" e a fase B nasceu ja cancelada, mas mesmo assim
            avisou que ia medir. Nao mediu nada; so mentiu por um instante. #>
        <#  17.10 - A CHAVE DESLIGADA NAO "PULA EM SILENCIO".

            Ela avisa quantos arquivos ficaram sem veredicto e por que, e
            grava no log o que a leitura custou SEM a medicao. E esse par de
            numeros - com e sem - que responde a pergunta do Diego; um deles
            sozinho nao responde nada. #>
        if ($Pendentes.Count -gt 0 -and -not $Controle.PararMedicao) {
            $cronEL = [System.Diagnostics.Stopwatch]::StartNew()
            Avisar ("Medindo a camada de melhoria (MEL x FEL) de {0} arquivo(s) em segundo plano..." -f $Pendentes.Count)
            $medidos = 0
            $nEL = 0
            foreach ($pe in $Pendentes) {
                <#  18.02 - A MEDICAO NAO OLHA MAIS PARA "Cancelar". ELE NAO E DELA.

                    Log do Diego, 16/09 19:53:27: a medicao comecava e MORRIA
                    no mesmo instante - "Medindo ... 3 arquivo(s)" as 27,569 e
                    "Medicao interrompida em 3" as 27,580. Zero medidos, 0,00s,
                    em toda sessao. O ciano piscava e sumia, e era isso que ele
                    via: "o FEL ele chama azul ciano e some rapidinho, nao
                    importa o que eu faca".

                    A causa e minha, e nasceu NA 18.00: quando a medicao morava
                    dentro da leitura, ela terminava ANTES de Stop-Motor. Ao
                    separar os trabalhos, a ordem virou leitura_fim ->
                    Stop-Motor -> Start-Medicao - e Stop-Motor levanta
                    $Controle.Cancelar para matar o runspace DA LEITURA.
                    A medicao nascia com essa bandeira ja em pe e parava no
                    primeiro arquivo.

                    Separar trabalhos e separar TAMBEM as bandeiras: quem manda
                    na medicao e PararMedicao, e so ele. Cancelar e da leitura e
                    da conversao. Bandeira compartilhada entre dois donos e a
                    mesma familia de defeito do runspace compartilhado. #>
                <#  2.0.7 - A MEDICAO VELHA RESSUSCITAVA.
                    Log de 22/09 23:05:58: a pasta foi trocada, Stop-Medicao
                    levantou PararMedicao - e Start-Leitura, 40 ms depois,
                    abaixou de novo. A medicao da pasta anterior seguiu
                    lendo GoT, Ryan e Troy (ate 23:06:12) enquanto a pasta
                    nova esperava "a anterior ainda esta encerrando".
                    Bandeira que qualquer um abaixa nao para ninguem. A
                    rodada viva nao volta atras: se ela nao e mais a minha,
                    eu paro. #>
                if ($Controle.PararMedicao -or ([int]$Controle.MedSerieViva -ne [int]$Serie)) { break }
                $nEL++
                <#  17.19 - QUEM ESTA SENDO MEDIDO E ANUNCIADO, NAO DEDUZIDO.

                    Ate a 17.18 a janela DEDUZIA quem estava na vez ("o
                    primeiro marcado que ainda esta em MEDINDO") e contava
                    sozinha. Deduzir sobre uma lista que o usuario pode mexer
                    no meio da medicao nao funciona: desmarcar e remarcar
                    arquivos muda a conta debaixo da formula, e foi exatamente
                    o que o Diego viu - a coluna dizendo um numero enquanto o
                    botao dizia outro.

                    Quem sabe qual arquivo esta sendo lido NESTE instante e
                    este laco. Entao e ele que fala. #>
                Enviar @{ T = "el_ini"; Serie = $Serie; Idx = $pe.Idx; Pos = $nEL; Total = $Pendentes.Count }
                $c1 = [System.Diagnostics.Stopwatch]::StartNew()
                $script:CacheTipoELPath = $null; $script:CacheTipoEL = $null
                $script:CacheInfoDVPath = $null; $script:CacheInfoDV = $null
                $el = $null
                try {
                    <#  16.97: o -Pontos 3 SAIU daqui. A janela pedia 3 e o
                        motor usava 5 - mesmo arquivo, mesma pergunta, duas
                        amostras, e portanto a possibilidade de duas
                        respostas. Agora nenhum dos dois escolhe: quem decide
                        e Get-PontosDaAmostra, no motor, pela duracao. #>
                    $el = Get-TipoCamadaDV -MkvPath $pe.Path -DuracaoSeg ([double]$pe.Dur)
                } catch {
                    Avisar ("Erro medindo a camada de {0}: {1}" -f $pe.Nome, $_.Exception.Message) "ERRO"
                }
                $c1.Stop()
                if (-not $el) { continue }
                $medidos++
                <#  O LOG GUARDA A MEDIDA, NAO SO O VEREDICTO (pedido do Diego,
                    04/09): sem os numeros nao da para comparar um caso com o
                    outro depois. O L1 MaxCLL/MaxFALL sao a regua da Dolby
                    (MaxRGB do RPU) - NAO se comparam com o MaxCLL do HDR10 do
                    container, que e histograma (licao 15). O que se compara
                    com o L1 e o pico do MASTERING DISPLAY: L1 bem abaixo dele
                    e o sinal de que a EL nao esta expandindo brilho. #>
                Avisar ("EL de '{0}': {1} | L1 MaxCLL {2:N2} nits, MaxFALL {3:N2} nits | DM {4} | {5} de {6} trecho(s) | {7:N2}s" -f `
                    $pe.Nome, $el.Tipo, [double]$el.MaxCLL, [double]$el.MaxFALL, "$($el.DmVersion)",
                    $el.PontosLidos, $el.PontosPedidos, ($c1.ElapsedMilliseconds / 1000.0))
                <#  16.85 - O CENSO E O L5 TAMBEM VAO PARA O LOG.

                    O MaxCLL acima e UM numero: o pico do trecho mais claro.
                    O censo diz QUANTAS cenas passam do que o master entrega -
                    a diferenca entre "teve um pico alto" e "isso acontece o
                    tempo todo". Sem o pico do master a conta nao existe, e a
                    linha diz isso em vez de inventar regua. #>
                if ([int]$el.CenasNoCenso -gt 0) {
                    if ([double]$el.MasterMax -gt 0) {
                        <#  16.87: a linha antiga dizia "1 cena(s) acima do
                            master" e o Diego perguntou, com razao, se o filme
                            tinha 3 cenas. A amostra sao 3 trechos curtos, nao
                            o filme - e a linha tem que dizer isso, senao o
                            numero parece falar do titulo inteiro. #>
                        Avisar ("   Censo do L1: {0} de {1} cena(s) da amostra pedem mais que os {2:N0} nits do master (pico {3:N2} nits). A amostra são {4} trechos curtos, não o filme inteiro." -f `
                            [int]$el.CenasAcimaDoMaster, [int]$el.CenasNoCenso, [double]$el.MasterMax,
                            [double]$el.PicoDeCena, "$($el.PontosLidos)")
                    } else {
                        Avisar ("   Censo do L1: {0} cena(s) lida(s), pico de cena {1:N2} nits — o container não declarou o pico do mastering display, então não há régua para comparar" -f `
                            [int]$el.CenasNoCenso, [double]$el.PicoDeCena)
                    }
                }
                <#  17.08 - A REGUA SUSPEITA VAI PARA O LOG (item D).

                    Nao vai para a LINHA do diagnostico: a linha diz o que foi
                    detectado e o que sera feito, e "desconfio do metadado"
                    nao e nenhum dos dois. Vai para o log, que e onde mora a
                    justificativa - a mesma regra da 16.79. #>
                if ($el.ReguaSuspeita) {
                    Avisar ("   REGUA SUSPEITA: {0}" -f "$($el.ReguaSuspeitaMotivo)") "LEITURA"
                }
                if ($el.L5Lido) {
                    if ("$($el.L5Formato)" -ne "") {
                        Avisar ("   Área ativa (L5): bordas {0} — imagem de {1}, {2}" -f `
                            "$($el.L5Bordas)", "$($el.L5AreaAtiva)", "$($el.L5Formato)")
                        # 16.86: era "Scope 2,39:1 (2.39:1)" - o mesmo numero
                        # duas vezes, e um deles com ponto em vez de virgula.
                    } else {
                        Avisar ("   Área ativa (L5): bordas {0}" -f "$($el.L5Bordas)")
                    }
                }
                Enviar @{ T = "el"; Serie = $Serie; Idx = $pe.Idx; Caminho = "$($pe.Path)"
                          Tipo = "$($el.Tipo)"; Selo = "$($el.Selo)"; Motivo = "$($el.Motivo)"
                          MaxCLL = [double]$el.MaxCLL; MaxFALL = [double]$el.MaxFALL
                          Dm = "$($el.DmVersion)"
                          Pontos = ("{0}/{1}" -f $el.PontosLidos, $el.PontosPedidos)
                          Expande = $el.Expande
                          ReguaSuspeita = [bool]$el.ReguaSuspeita
                          ReguaSuspeitaMotivo = "$($el.ReguaSuspeitaMotivo)"
                          PctAcima = [double]$el.PctAcimaDoMaster
                          Cenas = [int]$el.CenasNoCenso
                          CenasAcima = [int]$el.CenasAcimaDoMaster
                          MasterMax = [double]$el.MasterMax
                          PicoCena = [double]$el.PicoDeCena
                          Master = [double]$el.MasterMax
                          <#  16.96: a janela passa a saber QUAL regua falou, e
                              a carregar os numeros do container. Eles NAO
                              respondem se a EL levantava brilho - regua
                              diferente, licao 15 - mas sao o que sobra para
                              o usuario decidir quando o master nao existe. #>
                          Regua = "$($el.ReguaUsada)"
                          CtnMaxCLL = [int]$el.CtnMaxCLL
                          CtnMaxFALL = [int]$el.CtnMaxFALL
                          L5 = "$($el.L5Bordas)"; L5Formato = "$($el.L5Formato)"
                          L5Area = "$($el.L5AreaAtiva)"
                          Seg = ($c1.ElapsedMilliseconds / 1000.0) }
            }
            $cronEL.Stop()
            $gbMed = 0.0
            foreach ($pe in $Pendentes) { $gbMed += [double]$pe.Gb }
            Enviar @{ T = "el_fim"; Serie = $Serie; Medidos = $medidos; Total = $Pendentes.Count
                      Seg = ($cronEL.ElapsedMilliseconds / 1000.0)
                      Gb = $gbMed; Desligada = $false }
        } else {
            Enviar @{ T = "el_fim"; Serie = $Serie; Medidos = 0; Total = 0; Seg = 0; Gb = 0.0 }
        }
    } catch {
        Enviar @{ T = "log"; Texto = ("ERRO na medicao: {0}" -f $_.Exception.Message); Tipo = "ERRO" }
        Enviar @{ T = "el_fim"; Serie = $Serie; Medidos = 0; Total = 0; Seg = 0; Gb = 0.0; Falhou = $true }
    }
}

$script:ReleituraPendente = $false
# 16.77: true entre o "leitura_fim" e o "el_fim" - a janela ja esta usavel
# e o runspace ainda esta medindo a camada de melhoria em segundo plano.
$script:MedindoEL = $false
# 17.08: true enquanto o censo completo (item A) esta lendo o filme inteiro
# no runspace proprio. A fila e a conversao seguem livres; so o botao dorme.
$script:CensoRodando  = $false
$script:CensoRunspace = $null
$script:CensoPS       = $null
$script:CensoHandle   = $null
$script:CensoSerie    = 0
$script:CensoT0       = $null
$script:CensoSegMostrado = -1
<#  18.09 - "E ESSE CONTADOR E DO QUE? SE CADA FILME TEM SEU TEMPO, ELE TA
    CONTANDO ATE QUE TEMPO?" (Diego, 17/09).

    Pergunta certa, e a 18.07 respondeu pela metade: eu botei um cronometro
    subindo, que prova que o programa nao travou mas nao diz QUANTO FALTA - e
    quanto falta e a unica coisa que ele queria saber.

    O censo nao tem barra de progresso porque quem le o RPU e o dovi_tool, num
    processo so, sem contar quadros para fora. O que existe e uma relacao
    MEDIDA: o censo do filme inteiro custa ~4,7x a amostra DAQUELE arquivo.
    Tres medicoes no log dele, no Saving Private Ryan:

       amostra 22,1s -> censo 104,5s   (4,73x)
       amostra 22,2s -> censo 106,5s   (4,80x)
       amostra 22,3s -> censo 104,1s   (4,67x)

    Entao a previsao nasce do tempo que ESTE arquivo levou na amostra, nao de
    um numero fixo para todos - era exatamente a ressalva dele ("cada filme tem
    seu tempo"). E o fator se corrige sozinho: cada censo que termina grava a
    relacao real daquela maquina.

    Quando passa do previsto, a tela DIZ que passou em vez de continuar
    fingindo - licao 2. E sem amostra medida nao ha previsao nenhuma: mostra so
    o decorrido, sem inventar. #>
$script:CensoPrev     = 0.0
$script:CensoFator    = 4.7
<#  18.21 - A PORCENTAGEM QUE FICAVA EM 0% O CENSO INTEIRO.

    "a % nao conta do censo, fica 0%, como vou saber se chegou a 90%" e "vc
    continua errando feio a contagem do CENSO, PQ E TAO DIFICIL ACERTAR +- O
    CALCULO DA %?" (Diego, 17/09). Duas vezes a mesma cobranca, e ela e justa.

    A previsao inteira pendurava num numero so:

        CensoPrev = ELsegundos (o tempo da AMOSTRA daquele arquivo) x 4,7

    ELsegundos so existe se a amostra tiver sido medida NESTA sessao. Quando o
    veredicto vem do cache (arquivo ja medido ontem, ou pasta relida), ele volta
    ZERO - e com CensoPrev = 0 o rotulo nao mostra porcentagem nenhuma. Nao era
    uma conta errada: era uma conta que nao acontecia, e do lado de fora isso e
    "fica 0%". A conta certa no lugar errado continua errada (licao 43).

    Agora ha um segundo caminho, que nao depende de a amostra ter rodado: a
    DURACAO DO FILME, que todo arquivo da fila tem desde a leitura. Os numeros
    do proprio log dele, medidos tres vezes no mesmo arquivo:

        Saving Private Ryan - 2h49m = 10.140s de filme
        censo completo (RPU + contagem) = 106,1s
        -> 0,0105 segundo de censo por segundo de filme

    E o mesmo principio dos outros dois numeros desta tela: valor de partida
    medido, e cada censo que termina corrige o da proxima vez. Limite de
    sanidade de 0,003 a 0,05 s/s - fora disso o censo foi cortado no meio.

    A ordem entre os dois: a amostra DAQUELE arquivo ganha quando existe (ela
    ja viu este filme); a duracao entra quando ela nao existe. O que nao pode
    mais acontecer e nao haver previsao nenhuma. #>
$script:CensoSegPorSegFilme = 0.0105
# 2.0b: a velocidade do disco de origem, medida uma vez e reaproveitada - e a
# metade da previsao do censo que a amostra nunca soube descrever.
$script:CensoDiscoMbs = 0.0

<#  18.04 - O VEREDICTO MEDIDO PARA DE SER JOGADO FORA A CADA LEITURA.

    Cobranca dele, 17/09: "eu cancelo a conversao e volta a estaca zero as
    medicoes... esse modo seu de trabalhar nao guarda informacao".

    O log mostra o desperdicio: 62,4s medindo os tres arquivos, e ai um
    "Nova Conversao" (que rele a pasta) jogava os tres veredictos fora - com a
    chave desligada eles voltavam todos para "EL nao medida". Na proxima vez,
    mais 62,4s para chegar ao mesmo numero.

    Medir e caro (14 a 26s por arquivo) e o resultado NAO muda enquanto o
    arquivo nao muda. Entao o veredicto fica guardado por CAMINHO + TAMANHO +
    DATA DE MODIFICACAO. Mudou qualquer um dos tres, o arquivo e outro e a
    medida velha nao vale - reaproveitar por NOME seria inventar veredicto,
    que e o pecado que este programa persegue desde a 1.8.

    O cache vive na sessao e nao vai para disco: ele existe para a pasta que
    se rele dez vezes em dez minutos, nao para afirmar amanha o que foi medido
    hoje. #>
$script:CacheEL = @{}

<#  18.05 - QUEM ACHA A LINHA E O CAMINHO DO ARQUIVO, NAO O INDICE.

    O indice e a posicao numa lista que muda debaixo do trabalho: relendo a
    pasta, trocando de pasta, ou so tirando um arquivo, o "2" de vinte segundos
    atras e outro filme. Foi assim que o veredicto do Ryan foi parar na linha do
    House of the Dragon (18.03). O numero de serie resolveu descartando a sobra
    - mas descartar joga fora resultado que as vezes AINDA VALE: o censo do Ryan
    terminou depois de a pasta ser relida, e o Ryan continuava ali. 104 segundos
    de trabalho no lixo, duas vezes no log dele.

    O caminho do arquivo nao muda de dono. Entao: acha pelo caminho; o indice so
    serve de atalho quando ja aponta o arquivo certo. Se o caminho nao esta mais
    na lista, ai sim nao ha onde escrever, e a mensagem morre. #>
function Achar-LinhaPorCaminho([string]$caminho, [int]$idxDica) {
    if ("$caminho" -eq "") { return $idxDica }
    if ($idxDica -ge 0 -and $idxDica -lt $script:Videos.Count) {
        if ("$($script:Videos[$idxDica].Caminho)" -eq "$caminho") { return $idxDica }
    }
    for ($k = 0; $k -lt $script:Videos.Count; $k++) {
        if ("$($script:Videos[$k].Caminho)" -eq "$caminho") { return $k }
    }
    return -1
}

function Chave-CacheEL($v) {
    if (-not $v -or -not "$($v.Caminho)") { return "" }
    $dt = ""
    try { $dt = (Get-Item -LiteralPath "$($v.Caminho)" -ErrorAction Stop).LastWriteTimeUtc.Ticks }
    catch { $dt = "sem-data" }
    return ("{0}|{1}|{2}" -f "$($v.Caminho)".ToLower(), [long]$v.Bytes, $dt)
}

function Guardar-CacheEL($v) {
    if ("$($v.ELtipo)" -eq "NAO_MEDIDO" -or "$($v.ELtipo)" -eq "MEDINDO" -or "$($v.ELtipo)" -eq "") { return }
    $k = Chave-CacheEL $v
    if ($k -eq "") { return }
    $script:CacheEL[$k] = @{
        ELtipo = "$($v.ELtipo)"; ELselo = "$($v.ELselo)"; ELmotivo = "$($v.ELmotivo)"
        ELmaxcll = [double]$v.ELmaxcll; ELmaxfall = [double]$v.ELmaxfall
        ELdm = "$($v.ELdm)"; ELpontos = "$($v.ELpontos)"; ELexpande = $v.ELexpande
        ELcenas = [int]$v.ELcenas; ELcenasAcima = [int]$v.ELcenasAcima
        ELpicoCena = [double]$v.ELpicoCena; L5bordas = "$($v.L5bordas)"
        L5formato = "$($v.L5formato)"; L5area = "$($v.L5area)"
        ELregua = "$($v.ELregua)"; ELctnMaxCLL = [int]$v.ELctnMaxCLL
        ELctnMaxFALL = [int]$v.ELctnMaxFALL
        ELreguaSuspeita = [bool]$v.ELreguaSuspeita
        ELreguaSuspeitaMotivo = "$($v.ELreguaSuspeitaMotivo)"
        ELpctAcima = [double]$v.ELpctAcima; ELmastermax = [double]$v.ELmastermax
        ELsegundos = [double]$v.ELsegundos
        CensoFeito = [bool]$v.CensoFeito; CensoResumo = "$($v.CensoResumo)"
        CensoCenas = [int]$v.CensoCenas; CensoAcima = [int]$v.CensoAcima; CensoPico = [double]$v.CensoPico
        <#  2.0.1: sem isto, reler a pasta trazia de volta o VERMELHO de um
            arquivo cujo censo ja tinha provado que o pico e isolado - e o
            usuario teria que rodar 10 minutos de censo de novo para ver a
            mesma verdade. O cache guarda a medida; tem que guardar o que
            se concluiu dela. #>
        <#  18.05 - A CONTRADICAO DA FOTO 8, E ELA E MINHA.

            Print dele, uma linha so, dizendo duas coisas opostas:
              "Dolby VISION: Profile 7 [BL+EL+RPU] [EL: MEL] [DETECTADO]
               -> [SERA CONVERTIDO] Profile 8.1 - EL NAO MEDIDA"
            A ESQUERDA (o que foi detectado) dizia MEL; a DIREITA (o que sera
            feito) dizia que nao mediu.

            Causa: na 18.04 eu guardei no cache o veredicto (ELtipo e numeros)
            e ESQUECI de guardar a RESPOSTA - DiagDVres/DiagDVcor. Ao reler a
            pasta, a esquerda e a coluna voltavam do cache e a direita ficava a
            frase que a leitura tinha acabado de escrever ("EL nao medida"),
            porque Update-TextosDV so preenche a resposta quando ela esta
            VAZIA - e ela nao estava.

            A regra do projeto e a de sempre: a esquerda detecta, a direita diz
            o que sera feito. As duas saem do MESMO fato. Guardar meia verdade
            e pior que nao guardar nada. #>
        DiagDVres = "$($v.DiagDVres)"; DiagDVcor = "$($v.DiagDVcor)"
        DiagDVrot = "$($v.DiagDVrot)"; ColDV = "$($v.ColDV)"
    }
}

function Restaurar-CacheEL($v) {
    $k = Chave-CacheEL $v
    if ($k -eq "" -or -not $script:CacheEL.ContainsKey($k)) { return $false }
    $c = $script:CacheEL[$k]
    foreach ($campo in @($c.Keys)) {
        try { $v.$campo = $c[$campo] } catch { }
    }
    <#  18.05: Update-TextosDV reescreve rotulo e coluna a partir do ELtipo
        (que agora e o medido) e NAO toca na resposta, que ja veio guardada.
        Depois dele, a esquerda e a direita contam a mesma historia. #>
    Update-TextosDV $v
    return $true
}

function Start-Leitura {
    if ($script:Lendo) {
        # Nao descartar o pedido: cancela a leitura em curso e reagenda.
        Escrever-Log "Leitura em curso cancelada para reler a pasta nova" "LEITURA"
        $script:ReleituraPendente = $true
        $script:Controle.Cancelar = $true
        return
    }
    Stop-Motor
    <#  18.00: a fila que a medicao estava medindo vai ser apagada e remontada,
        entao a medicao perde o sentido. Fechar-MedicaoPendente vira os MEDINDO
        em "EL nao medida" antes de a lista sumir, e o numero de serie garante
        que nenhuma sobra dela caia na fila nova. #>
    Stop-Medicao
    Fechar-MedicaoPendente
    <#  18.08 - AQUI A MEDICAO MORRIA PARA SEMPRE. ESTA NO LOG DELE:

          01:27:07,8  MEDICAO: encerrada - a conversao comecou
          01:27:30,9  CLIQUE: Nova Conversao  (que chama esta funcao)
          01:29:05,1  MEDICAO: a anterior ainda esta encerrando
          01:29:46,5  MEDICAO: a anterior ainda esta encerrando
          01:30:11,0  MEDICAO: a anterior ainda esta encerrando
          ... ate o fim da sessao. Ligar, desligar, Atualizar, trocar de pasta:
          nada mais media. "TROQUEI DE PASTA NAO LEU O FEL, TENTEI LIGAR
          DESLIGAR LER A PASTA DE NOVO E NADA."

        A causa: esta linha esvaziava a fila de mensagens SEM OLHAR o que
        estava nela. La dentro estava o "el_fim" da medicao recem-cancelada - a
        unica mensagem que fecha o handle do runspace. Ela ia para o lixo,
        $script:MedPS ficava preenchido para sempre, e a trava da 18.05 ("nao
        nasce outra enquanto a anterior nao sair") passou a barrar TODAS as
        medicoes seguintes.

        Esvaziar a fila era protecao da epoca em que nao havia numero de
        rodada; hoje o portao ja descarta sobra velha sozinho. O que nunca pode
        ser descartado e a NOTICIA DE MORTE de um trabalho - e o unico jeito de
        saber que o runspace pode ser fechado. #>
    $descarte = $null
    while ($script:FilaMsg.TryDequeue([ref]$descarte)) {
        switch ("$($descarte.T)") {
            "el_fim"    { Fechar-Runspace-Medicao }
            "censo_fim" { Fechar-Runspace-Censo   }
        }
    }
    <#  17.11: uma leitura NOVA cancela um Iniciar que estava esperando. Se
        o usuario trocou de pasta ou apertou Atualizar, a fila que ele mandou
        converter nao existe mais - comecar a conversao dela seria converter
        outra coisa. E o botao volta a acender, senao fica morto para sempre. #>
    if ($script:IniciarAposMedir) {
        $script:IniciarAposMedir = $false
        Update-AvisoEspera
        Escrever-Log "INICIAR: a espera pela medicao foi cancelada - a pasta esta sendo lida de novo" "ACAO"
    }
    <#  17.13: uma leitura nova tambem encerra um censo em curso. A fila que
        ele estava contando deixou de existir, e deixar o botao dizendo
        "contando" sobre um arquivo que saiu da tela e mentira. #>
    if ($script:CensoRodando) {
        Escrever-Log "CENSO COMPLETO: encerrado - a pasta esta sendo lida de novo" "ACAO"
        Stop-Censo
    }
    $script:LeituraSerie = $script:LeituraSerie + 1
    $script:Lendo = $true
    $script:MotivoVazio = ""
    $script:Videos.Clear()
    $script:LinhasFila.Clear()
    $script:AssinaturaFila = $null   # 18.12: quem limpa a tela por fora zera a assinatura
    $script:Controle.Cancelar = $false
    $script:Controle.PararMedicao = $false
    $UI.btnIniciar.IsEnabled = $false
    # O botao NAO desabilita durante a leitura: vira "Parar" para o usuario
    # poder abortar um reescaneamento em curso (o clique cai no ramo de parada).
    $UI.btnReler.IsEnabled = $true
    <#  17.01 - POR QUE O "Atualizar" NAO TRADUZIA (achado do Diego, no print).

        Ele estava na tabela desde o comeco: "Atualizar -> Refresh". E ficava
        em portugues assim mesmo, do lado de "Open Source" e "Open Output"
        traduzidos - o que parecia sorteio.

        Nao era: este rotulo e ESCRITO DE VOLTA por codigo, em dois pontos
        (aqui vira "Parar" durante a leitura, e em "leitura_fim" volta para
        "Atualizar"). A varredura da arvore traduz UMA vez, quando a bandeira
        troca; qualquer escrita depois disso desfaz a traducao em silencio.

        Licao: rotulo que o codigo reescreve nao pode depender da varredura -
        ele tem que traduzir na hora em que e escrito. #>
    Update-BotaoReler
    $Janela.Title = "$NOME_APP  ·  " + (Traduzir "Lendo a Pasta...")

    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "MTA"; $rs.ThreadOptions = "ReuseThread"; $rs.Open()
    $rs.SessionStateProxy.SetVariable("Fila", $script:FilaMsg)
    $rs.SessionStateProxy.SetVariable("Controle", $script:Controle)
    $rs.SessionStateProxy.SetVariable("PastaScript", $script:PastaScript)
    $rs.SessionStateProxy.SetVariable("CaminhoMotor", $script:CaminhoMotor)
    $rs.SessionStateProxy.SetVariable("PastaOrigem", $Cfg.Origem)
    $rs.SessionStateProxy.SetVariable("PastaSaida", $Cfg.Saida)
    <#  18.00: a chave NAO viaja mais para dentro da leitura. Ela nao decide
        mais nada aqui - quem decide se mede e a janela, depois que a fila
        estiver na tela, disparando (ou nao) o trabalho da medicao. A leitura
        voltou a fazer uma coisa so. #>
    $rs.SessionStateProxy.SetVariable("Preambulo", $script:PreambuloTrabalho)
    $rs.SessionStateProxy.SetVariable("SerieL", [int]$script:LeituraSerie)
    $ps = [powershell]::Create(); $ps.Runspace = $rs
    $null = $ps.AddScript($script:TrabalhoLeitura.ToString())
    $script:MotorRunspace = $rs; $script:MotorPS = $ps
    $script:MotorHandle = $ps.BeginInvoke()
    Escrever-Log "Leitura da pasta disparada no runspace" "LEITURA"
}

<#  ============================================================================
    18.00 - O TRABALHO DA MEDICAO: COMECAR E PARAR

    Start-Medicao monta a lista de quem medir a partir da fila QUE ESTA NA TELA
    (Get-PendentesDeMedida) e dispara um runspace so dele. Nao varre pasta, nao
    toca na leitura, nao toca no censo.

    Stop-Medicao e a razao de a interface nao congelar mais: ele ERGUE UMA FLAG
    e volta. Nao espera runspace morrer, nao chama WaitOne. O runspace ve a flag
    no proximo arquivo do laco e se encerra sozinho, mandando "el_fim" - e e o
    "el_fim" que faz a faxina, pelo mesmo caminho de sempre. #>
$script:MedRunspace = $null
$script:MedPS       = $null
$script:MedHandle   = $null
<#  18.00 - O NUMERO DE SERIE, E POR QUE ELE E OBRIGATORIO AQUI.

    Stop-Medicao nao espera - e essa e a razao de a janela nao congelar mais.
    Mas nao esperar tem um preco: o runspace cancelado ainda pode ter uma
    mensagem no ar quando a proxima coisa comeca. Se nesse meio tempo a pasta
    for relida, a fila e OUTRA - e um "el" atrasado, carregando o indice 2 da
    fila velha, gravaria o veredicto de um arquivo no lugar de outro. Veredicto
    certo no arquivo errado e pior que veredicto nenhum.

    Entao toda medicao recebe um numero, toda mensagem dela carrega esse numero,
    e a janela IGNORA o que vier de uma medicao que nao e a de agora. E o mesmo
    princípio da 17.19 (quem sabe, anuncia) aplicado ao tempo: a mensagem diz de
    qual rodada ela e, em vez de a janela supor que so existe uma. #>
<#  18.12: a janela ja fechou? Quem mexe na tela confere isto antes.
    Ver o add_Closed - o erro de 10/09 01:26:31 e o motivo. #>
$script:Fechando = $false
$script:MedSerie = 0
<#  18.13: a prova de vida do censo - CPU do dovi_tool e o instante em que
    ela cresceu pela ultima vez. CensoMudo e o estado que o botao mostra. #>
$script:CensoCpu    = 0.0
$script:CensoCaminho = ""
$script:CensoMorto   = $false
$script:CensoMortoEm = $null
<#  18.17: o progresso do censo vive no arquivo de RPU que o motor escreve.
    CensoBytesSeg e a medida que se corrige sozinha - bytes de RPU por segundo
    de filme. O valor de partida saiu do log dele: 86,66 MB para 2h49m. #>
$script:CensoBytesPrev = 0.0
$script:CensoBytesSeg  = 8950.0
$script:TiqueConta     = 0
$script:CensoVivoEm = $null
$script:CensoMudo   = $false
<#  18.00: a leitura tem o mesmo problema e ganha a mesma solucao. Sem a espera
    do WaitOne (ver Stop-Motor), uma leitura cancelada tambem pode ter mensagem
    no ar - e um "video" atrasado entraria como linha na fila NOVA. #>
$script:LeituraSerie = 0

function Start-Medicao {
    if ($script:MedindoEL) { return }
    # 19.6: um el_fim atrasado de rodada velha chamava isto no meio da
    # conversao - e a medicao voltava a disputar o disco com o motor.
    if ($Estado.Atual -eq "rodando" -or $Estado.Atual -eq "pausado") { return }
    <#  18.01 - A TRAVA MECANICA, agora que a TELA fecha antes do trabalho.

        Stop-Medicao passou a zerar o estado visivel na hora (o rotulo parava
        de mentir), e isso solta $script:MedindoEL antes do runspace morrer -
        o que abriria a porta para uma segunda medicao nascer por cima da
        primeira, duas lendo o mesmo disco. Quem responde por isso e o handle:
        enquanto ele existe, nao nasce outra. O el_fim da anterior fecha o
        handle e a proxima troca da chave comeca normalmente. #>
    <#  18.11 - PRIMEIRO OLHAR SE HA TRABALHO, DEPOIS SE DA PARA FAZE-LO.

        Log dele de 17/09, 11:54:22,8: a pasta voltou para 00_Arquivos_Base, os
        tres veredictos vieram do cache da sessao (nenhum arquivo sem veredicto)
        e mesmo assim a janela escreveu "a anterior ainda esta encerrando - a
        nova comeca assim que ela sair". Nao havia "nova" nenhuma: a fila de
        pendentes estava vazia. A mensagem prometia trabalho que nao existia
        porque a trava do handle era conferida ANTES de olhar se havia o que
        medir. Licao 2: mensagem que mente e defeito, mesmo quando o programa
        se comporta certo por baixo. #>
    $pend = @(Get-PendentesDeMedida)
    if ($pend.Count -eq 0) { return }

    <#  18.01 - A TRAVA MECANICA: enquanto o handle da anterior existe, nao
        nasce outra medicao. Agora esta mensagem so aparece quando REALMENTE
        ha arquivo esperando - e ai ela e verdade. #>
    if ($script:MedPS) {
        Escrever-Log "MEDICAO: a anterior ainda esta encerrando - a nova comeca assim que ela sair" "LEITURA"
        return
    }

    $lista = @()
    foreach ($v in $pend) {
        $i = $script:Videos.IndexOf($v)
        if ($i -lt 0) { continue }
        $lista += ,@{ Idx = $i; Path = "$($v.Caminho)"; Dur = [double]$v.DurSeg
                      Nome = "$($v.Nome)"; Gb = ([double]$v.Bytes / 1GB) }
        <#  Quem entra na medicao volta para MEDINDO na hora, senao a linha
            continua dizendo "EL nao medida" enquanto ja esta sendo medida. #>
        $v.ELtipo = "MEDINDO"; $v.ELselo = "-"
        $v.ELmotivo = "medindo a camada de melhoria"
        Update-TextosDV $v
    }
    if ($lista.Count -eq 0) { return }

    $script:Controle.PararMedicao = $false
    $script:MedSerie    = $script:MedSerie + 1
    $script:Controle.MedSerieViva = [int]$script:MedSerie
    $script:MedindoEL   = $true
    $script:ELtotal     = $lista.Count
    $script:ELfeitos    = 0
    $script:ELmedindoIdx = -1
    $script:PintandoFila = $false
    Update-BotaoMedirEL
    Fill-Fila "el"

    Escrever-Log ("MEDICAO: comecou em segundo plano - {0} arquivo(s) sem veredicto" -f $lista.Count) "LEITURA"
    Disparar-RunspaceMedicao $lista
}

<#  18.00: o RUNSPACE mora numa funcao propria, separado da DECISAO acima.

    Nao e enfeite: e o que torna a decisao testavel. A bancada de cliques roda
    Start-Medicao de verdade, com as regras de verdade, e troca so esta funcao
    por um dubles - entao o que o teste confere e o codigo que vai rodar na
    maquina dele, e nao uma imitacao minha. Misturar "decidir" com "executar"
    numa funcao so e o que deixa uma regra impossivel de conferir sem abrir o
    programa inteiro. #>
function Disparar-RunspaceMedicao($Lista) {
    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "MTA"; $rs.ThreadOptions = "ReuseThread"; $rs.Open()
    $rs.SessionStateProxy.SetVariable("Fila", $script:FilaMsg)
    $rs.SessionStateProxy.SetVariable("Controle", $script:Controle)
    $rs.SessionStateProxy.SetVariable("PastaScript", $script:PastaScript)
    $rs.SessionStateProxy.SetVariable("CaminhoMotor", $script:CaminhoMotor)
    $rs.SessionStateProxy.SetVariable("Preambulo", $script:PreambuloTrabalho)
    $rs.SessionStateProxy.SetVariable("Pendentes", $Lista)
    $rs.SessionStateProxy.SetVariable("Serie", [int]$script:MedSerie)
    $ps = [powershell]::Create(); $ps.Runspace = $rs
    $null = $ps.AddScript($script:TrabalhoMedicao.ToString())
    $script:MedRunspace = $rs; $script:MedPS = $ps
    $script:MedHandle = $ps.BeginInvoke()
}

function Stop-Medicao {
    <#  NAO ESPERA. Erguer a flag e voltar e a diferenca entre a janela
        responder na hora e a janela congelar por dois segundos. O
        encerramento de verdade acontece no "el_fim", que chega sozinho. #>
    if (-not $script:MedindoEL) { return }
    $script:Controle.PararMedicao = $true
    <#  18.03 - CANCELAR VIRA A RODADA. ERA ISSO QUE FALTAVA.

        Log dele de 16/09 23:26, e e o defeito mais grave que este programa ja
        teve na tela:

          23:26:30,3  pasta trocada para House of the Dragon (2 arquivos)
          23:26:53,3  "EL de 'Saving.Private.Ryan...': FEL | 1.608,29 nits"
                      ... com a FILA JA MOSTRANDO 2 videos.

        O veredicto do Ryan foi gravado na linha 2 da lista NOVA - o
        House.of.the.Dragon.S03E08, que e Profile 8 e nem tem camada extra.
        Dai o "P8 FEL" e o "o arquivo pede 1.608 nits" num arquivo que nunca
        foi medido. Veredicto CERTO no arquivo ERRADO: a licao 25 inteira.

        O numero de serie existia para impedir exatamente isso, e nao impediu
        por um detalhe meu: eu so virava a serie quando uma medicao NOVA
        comecava (Start-Medicao). Cancelar nao virava nada. Entao a mensagem
        atrasada da rodada cancelada chegava com a MESMA serie que a janela
        ainda tinha, passava pelo portao como se fosse de agora, e escrevia
        pelo indice - que na lista nova aponta outro filme.

        Agora quem cancela VIRA A RODADA. Depois deste ponto nao existe
        mensagem "da rodada de agora" vinda do trabalho que esta morrendo:
        tudo que ele ainda enviar e, por definicao, velho. #>
    $script:MedSerie = $script:MedSerie + 1
    # 2.0.7: a rodada viva muda junto - ver o laco do TrabalhoMedicao.
    $script:Controle.MedSerieViva = [int]$script:MedSerie
    <#  2.0: antes desta linha o log dizia "o trabalho encerra sozinho no
        proximo arquivo" - e era verdade, e era o defeito. Agora ele encerra
        AGORA, no arquivo que esta sendo medido. Ver o bloco de
        Test-EhProcessoDaMedicao. #>
    $alvoMed = ""
    try {
        $iM = [int]$script:ELmedindoIdx
        if ($iM -ge 0 -and $iM -lt $script:Videos.Count) { $alvoMed = "$($script:Videos[$iM].Caminho)" }
    } catch { $alvoMed = "" }
    [void](Matar-ProcessosDaMedicao $alvoMed)
    Escrever-Log "MEDICAO: cancelada" "LEITURA"
    <#  18.01 - A TELA FECHA AGORA, O TRABALHO FECHA QUANDO PUDER.

        Achado da bancada, cenario 8 (o roteiro do LEIA-ME rodado inteiro):
        eu tinha separado as duas coisas certas - cancelar nao espera - e
        deixado a TELA amarrada ao fim mecanico. Resultado: o rotulo continuava
        em ciano dizendo "Medindo MEL x FEL: 2 de 3" ate o "el_fim" chegar, o
        que pode levar os 26s do arquivo em curso. E era exatamente a queixa
        do Diego: "quando desliga ele fica la medindo ainda por um tempo".

        Trocar "congela 2s" por "mente por 26s" nao e conserto (licao 2). O
        estado mecanico ($script:MedindoEL) segue de pe ate o el_fim - e e o
        que impede uma segunda medicao nascer por cima da que ainda morre. #>
    Fechar-MedicaoPendente
    Update-BotaoMedirEL
    Fill-Fila "el"
}

<#  ============================================================================
    2.0 - CANCELAR A MEDICAO PASSOU A VALER NA HORA (item 1 da auditoria).

    Confirmado em TRES logs dele. O mais claro, 17/09:

      22:22:42,5  MEDIR EL: DESLIGADO
      22:22:42,9  "a medicao em curso esta sendo encerrada"
      22:22:47,4  EL de 'Troy...': MEL | 11 de 11 trecho(s) | 26,76s

    Ele desligou e o Troy foi medido assim que terminou, 5 segundos depois. A
    janela ate soltava o botao na hora (18.01), mas o TRABALHO continuava - e
    foi isso que o fez perguntar se a troca de pasta tinha remedido o arquivo.

    O censo aprendeu isso na 18.14 e a medicao ficou para tras. A diferenca
    nao e de principio, e de assinatura: era preciso saber reconhecer os
    processos DA MEDICAO sem tocar nos da conversao nem nos do censo.

    As tres assinaturas, que nao se confundem:

      conversao  dovi_tool ... convert ...              (nunca morre aqui)
      censo      dovi_tool extract-rpu -i -             (entrada padrao)
      medicao    dovi_tool extract-rpu -i "<trecho>"    (um ARQUIVO)

    A medicao corta trechos curtos com ffmpeg -c copy e le cada um. Entao o
    ffmpeg dela tambem tem assinatura propria: carrega o caminho do filme e
    NAO tem o "-f hevc -" do censo.

    Funcao PURA de proposito, como a do censo: a bancada roda isto com linhas
    de comando de mentira - inclusive as das outras duas - e prova que so a
    medicao morre. #>
function Test-EhProcessoDaMedicao([string]$Nome, [string]$Linha, [string]$Caminho) {
    if ([string]::IsNullOrWhiteSpace($Linha)) { return $false }
    $n = "$Nome".ToLowerInvariant()
    if ($n -eq "dovi_tool.exe") {
        if ($Linha -match "\bconvert\b") { return $false }              # conversao
        if ($Linha -match "extract-rpu\s+-i\s+-(\s|$)") { return $false } # censo
        return [bool]($Linha -match "extract-rpu\s+-i\s+")
    }
    if ($n -eq "ffmpeg.exe") {
        if ([string]::IsNullOrWhiteSpace($Caminho)) { return $false }
        if ($Linha -match "-f\s+hevc\s+-(\s|$)") { return $false }      # censo
        if ($Linha -notmatch "-c\s+copy") { return $false }
        return $Linha.ToLowerInvariant().Contains("$Caminho".ToLowerInvariant())
    }
    return $false
}

function Get-ProcessosDaMedicao([string]$Caminho) {
    $achados = @()
    try {
        $todos = @(Get-CimInstance Win32_Process -OperationTimeoutSec 3 -Filter "Name='dovi_tool.exe' OR Name='ffmpeg.exe'" -ErrorAction Stop)
        foreach ($p in $todos) {
            if (Test-EhProcessoDaMedicao "$($p.Name)" "$($p.CommandLine)" $Caminho) { $achados += $p }
        }
    } catch { }
    return ,$achados
}

function Matar-ProcessosDaMedicao([string]$Caminho) {
    $mortos = 0
    try {
        foreach ($pr in (Get-ProcessosDaMedicao $Caminho)) {
            try {
                Stop-Process -Id ([int]$pr.ProcessId) -Force -ErrorAction Stop
                $mortos++
                Escrever-Log ("MEDICAO: processo {0} (pid {1}) encerrado a pedido do cancelamento" -f $pr.Name, $pr.ProcessId) "LEITURA"
            } catch {
                # 2.0.10: entre listar e encerrar o processo pode ter acabado
                # sozinho (log de 23/09 02:14:23, ffmpeg da medicao). Isso nao e
                # falha - e o trabalho que terminou um instante antes do pedido.
                if (-not (Get-Process -Id ([int]$pr.ProcessId) -ErrorAction SilentlyContinue)) {
                    Escrever-Log ("MEDICAO: {0} (pid {1}) ja tinha terminado sozinho antes do pedido" -f $pr.Name, $pr.ProcessId) "LEITURA"
                } else {
                    Escrever-Log ("MEDICAO: nao consegui encerrar {0} (pid {1}) - {2}" -f $pr.Name, $pr.ProcessId, $_.Exception.Message) "AVISO"
                }
            }
        }
    } catch {
        Escrever-Log ("MEDICAO: nao consegui olhar os processos para encerrar - {0}" -f $_.Exception.Message) "AVISO"
    }
    # Licao 2 tambem aqui: "nao havia o que matar" e "nao achei o que matar"
    # sao coisas muito diferentes na hora de entender um log.
    if ($mortos -eq 0) {
        Escrever-Log "MEDICAO: nenhum processo da medicao foi encontrado - o trabalho ja tinha terminado sozinho" "LEITURA"
    } else {
        Escrever-Log ("MEDICAO: cancelada de verdade - {0} processo(s) encerrado(s), o disco fica livre na hora" -f $mortos) "LEITURA"
    }
    return $mortos
}

function Fechar-Runspace-Medicao {
    # Chamado pelo "el_fim", quando o trabalho JA terminou - aqui nao ha espera.
    try { if ($script:MedPS)       { $script:MedPS.Dispose() } } catch { }
    try { if ($script:MedRunspace) { $script:MedRunspace.Close(); $script:MedRunspace.Dispose() } } catch { }
    $script:MedPS = $null; $script:MedRunspace = $null; $script:MedHandle = $null
}

<#  17.08 - QUEM PODE PEDIR O CENSO COMPLETO (item A).

    So Complex FEL. Nao e economia de botao: e onde a pergunta existe.

      MEL           - a camada extra nao tem imagem. Nao ha o que contar.
      Simple FEL    - tem imagem, mas o L1 cabe dentro do master. Contar
                      todas as cenas nao muda o veredicto.
      EL nao medida - nao ha nem o primeiro nivel; o certo e medir a amostra
                      antes, que custa 5x menos.
      Complex FEL   - AQUI. O veredicto e "o arquivo pede mais brilho do que
                      o master entrega", e ele foi tirado de tres trechos
                      curtos. Foi exatamente isso que o autor do dovi_convert
                      questionou, e e a unica linha onde ler o filme inteiro
                      responde alguma coisa.

    Uma regra, um lugar: quem pinta de vermelho e Get-NomeCorEL, entao quem
    decide se o botao acende pergunta a ELA, e nao refaz o criterio. Refazer
    criterio em dois lugares foi o bug do audio da 16.79/16.80. #>
function Test-PodeCenso($v) {
    if ($null -eq $v) { return $false }
    if ("$($v.ELtipo)" -ne "FEL" -and "$($v.ELtipo)" -ne "MISTO") { return $false }
    return ((Get-NomeCorEL $v) -eq "vermelho")
}

<#  17.14 - O BOTAO CINZA TINHA QUE DIZER POR QUE ESTA CINZA.

    "esse botao de censo nao entedi porra nenhuma direto fica cinza."

    Tinha razao de novo. O botao nasce apagado, acende em UM caso raro
    (Complex FEL, nao contado ainda) e nao explicava nada - do lado de fora e
    identico a um botao quebrado. Mesma familia da m3c24, quando o botao Modo
    apagado o fez procurar bug por tres builds: quando a tela nao diz o
    motivo, a pessoa inventa um, e o inventado e sempre "ta bugado".

    A regra do projeto vale aqui tambem: quem afirma mostra em que se baseou.
    A dica responde na ordem em que as perguntas caem - sem linha, censo
    rodando, ja contado, chave desligada, sem medida, MEL, Simple FEL - e por
    ultimo, quando ele ESTA aceso, diz o que vai acontecer se clicar.

    Uma regra, um lugar: o criterio continua sendo Test-PodeCenso; esta
    funcao so traduz para portugues o "nao" que ela deu. #>
function Get-MotivoCenso($v) {
    <#  17.21: a conversao em curso vem ANTES de tudo - e a resposta mais
        forte, e era a que faltava. #>
    if ($Estado.Atual -in @("rodando","pausado")) { return "A conversão está em curso - o censo lê o filme inteiro e disputaria o disco com ela. Espere a fila terminar." }
    if ($null -eq $v) { return "Selecione um vídeo na fila para poder contar as cenas." }
    <#  18.09: a dica dizia "espere ele terminar" enquanto o botao ja mostrava
        o cronometro - duas frases sobre o mesmo estado, e a de baixo sem
        informacao. Agora ela diz o que o usuario quer saber: quanto falta. #>
    if ($script:CensoRodando) {
        <#  18.16: o tempo decorrido saiu do rotulo e passou a morar AQUI, com
            o resto. E a dica termina dizendo o que o botao agora faz: clicar
            de novo (ou F11) cancela. #>
        $decorrido = ""
        if ($script:CensoT0) { $decorrido = Format-MinSeg ([int]((Get-Date) - $script:CensoT0).TotalSeconds) }
        if ($script:CensoPrev -gt 0) {
            return (Traduzir-Frase ("O censo deste arquivo está rodando há {0} - leva cerca de {1} no total (a amostra dele levou {2}). Clique de novo (ou F11) para cancelar." -f `
                $decorrido, (Format-MinSeg ([int]$script:CensoPrev)), (Format-MinSeg ([int]($script:CensoPrev / $script:CensoFator)))))
        }
        return (Traduzir-Frase ("O censo está rodando há {0} - ele lê o RPU do filme inteiro e a fila continua livre. Clique de novo (ou F11) para cancelar." -f $decorrido))
    }
    <#  18.05: e existe um terceiro estado, que antes mentia de cinza calado -
        o censo anterior foi encerrado na tela e o trabalho dele ainda esta
        morrendo la atras. O botao fica apagado por alguns segundos e agora
        DIZ isso, em vez de o usuario achar que quebrou. #>
    if ($script:CensoPS)         { return "O censo anterior ainda está encerrando - dá para pedir de novo em alguns segundos." }
    <#  18.21: o botao deixou de apagar depois de contado (o F11 sempre deixou
        recontar; o mouse, nao - ver Update-BotaoCenso). Entao a dica, que e
        quem explica o botao, tem que dizer que dá para contar de novo. #>
    if ([bool]$v.CensoFeito)     { return "Este arquivo já foi contado - o número está no diagnóstico e no log. Clique (ou F11) para contar de novo." }
    # 19.6: com a chave desligada mas o arquivo JA medido como Complex FEL, o
    # botao acendia (Test-PodeCenso) e a dica mandava ligar a chave.
    if (-not $script:MedirELLigado -and -not (Test-PodeCenso $v)) { return "Ligue 'Medir MEL x FEL' e releia a pasta: sem a amostra não há veredicto para conferir." }
    switch ("$($v.ELtipo)") {
        "MEDINDO"    { return "A camada de melhoria deste arquivo ainda está sendo medida." }
        "NAO_MEDIDO" { return "A camada de melhoria deste arquivo não foi medida - meça a amostra antes, ela custa 5x menos." }
        "MEL"        { return "Só vale em Complex FEL: aqui a camada extra não carrega imagem, não há cena para contar." }
    }
    if (-not (Test-PodeCenso $v)) { return "Só vale em Complex FEL: aqui o L1 cabe dentro do master, contar o filme inteiro não muda o veredicto." }
    return "Lê o filme inteiro e conta quantas cenas pedem mais brilho que o master. Demora cerca de 5x a amostra - a fila continua livre."
}

<#  18.22: a dica virou parte do desenho do botao - ver Update-BotaoCenso. Esta
    funcao continua existindo porque tres lugares a chamam pelo nome, mas ela
    nao decide mais nada: encaminha. #>
function Update-DicaCenso($v) { Update-BotaoCenso $v }

<#  18.10 - O BOTAO DO CENSO ENTROU NO PADRAO DA CASA.

    "botao do censo la em cima muito poluido... o censo depois de medido deve
    ficar com o botao verde, ne? ou uma cor que significa que aquele arquivo
    foi medido; e quando o arquivo nao pode ser lido pelo censo, que fique
    cinza de inativo... toda nova ferramenta ou botao tem que ir refinando
    igual as outras, sendo que ja existe um padrao" (Diego, 17/09).

    Ele esta certo e a cobranca e justa: este programa JA tem um vocabulario de
    cor, usado na fila, nos chips e nos selos, e o botao do censo era o unico
    que nao falava essa lingua - ele so acendia e apagava, e desde a 18.07
    ainda carregava uma frase comprida no rotulo.

    O vocabulario, agora tambem aqui:

      cinza  = nao se aplica a este arquivo (nao ha o que contar)
      normal = da para contar, e vale a pena
      ciano  = contando agora (a mesma cor que a medicao usa, pelo mesmo motivo)
      verde  = ja contado - o numero esta no diagnostico

    E o rotulo ficou curto. O tempo que falta continua existindo: no rotulo
    enquanto conta ("Censo - 00m 45s") e, por extenso, na dica. Frase comprida
    em botao de barra e poluicao; ela tem lugar, e o lugar e a dica. #>
<#  18.21 - O BOTAO DO CENSO TINHA DOIS DONOS, COM REGRAS OPOSTAS.

    "PQ O CENSO PODE RELER NOVAMENTE APERTA F11 E CLICANDO NAO? Q MERDA EH
    ESSA?" (Diego, 17/09). A pergunta tem resposta exata, e ela e minha:

      Start-Censo (18.20)      ->  $UI.btnCenso.IsEnabled = $true
      Update-Diagnostico       ->  $UI.btnCenso.IsEnabled = (... -and
                                     -not $script:CensoRodando -and
                                     -not $v.CensoFeito -and ...)

    Duas linhas, em dois arquivos de ideia diferentes, escrevendo na MESMA
    propriedade. Quem repintasse por ultimo ganhava. E a segunda apagava o
    botao em dois estados em que a acao existe:

      - CENSO RODANDO   -> clicar cancelaria, mas o botao estava apagado;
      - CENSO JA FEITO  -> contar de novo e legitimo (o F11 sempre deixou),
                           mas o botao estava apagado.

    Em ambos o F11 funcionava, porque TECLA NAO PASSA PELO IsEnabled. Dai a
    assimetria que ele viu: a mesma acao com duas portas e duas regras - a
    familia de defeito que este projeto persegue desde a 16.79 (licao 41).

    A 18.20 consertou metade disso (o estado "rodando") no lugar errado: pos
    mais um dono em vez de tirar um. Agora e um so, e a regra e uma frase:
    O BOTAO ACENDE QUANDO Invoke-BotaoCenso VAI FAZER ALGUMA COISA. Nada mais.
    E o F11 passou a conferir o MESMO botao (ver PreviewKeyDown), entao mouse
    e teclado nao tem mais como discordar: e literalmente a mesma leitura. #>
function Update-BotaoCenso($v) {
    try {
        <#  18.22 - O ROTULO E A DICA DO CENSO EM CURSO VOLTARAM PARA O DONO.

            "AGORA O CENSO QUANDO TA RODANDO NAO APARECE [F11]. A DICA TAMBEM
            NAO TA LEGAL ENQUANTO RODA, NADA A VER, ELA SEM SENTIDO NESSE
            MOMENTO" (Diego, 17/09). As duas cobrancas, e as duas sao minhas.

            O rotulo: a 18.21 varreu TODAS as escritas do rotulo da medicao e
            exigiu a tecla em cada uma - e eu nao fiz a mesma varredura no
            rotulo do CENSO, que tinha o mesmo buraco no mesmo lugar: o estado
            "em curso". Tres lugares escreviam nele, e os dois de "em curso"
            (o relogio da fila e o Start-Censo) nao punham [F11]. Exatamente o
            defeito que eu tinha acabado de consertar do outro lado da barra.

            A dica: ela so era recalculada quando ele TROCAVA DE LINHA na fila.
            Comecar um censo nao troca linha nenhuma - entao a dica que estava
            na tela quando o censo comecou ficava la, congelada, os dois
            minutos inteiros. Foi por isso que ele viu "Ligue Medir MEL x FEL e
            releia a pasta" com o censo rodando: a frase estava certa no
            instante em que foi escrita, e ninguem a apagou.

            Agora rotulo, cor, dica e IsEnabled saem TODOS daqui, e o relogio
            da fila chama esta funcao uma vez por segundo em vez de escrever
            por conta propria. Um dono, quatro coisas, nenhuma podendo
            discordar das outras (licao 41). #>
        if ($script:CensoRodando) {
            $UI.btnCenso.IsEnabled  = $true
            $txtCenso = "[F11] " + (Traduzir "Censo")
            if ($script:CensoT0) {
                $seg   = [int]((Get-Date) - $script:CensoT0).TotalSeconds
                $giros = @("|", "/", "-", "\")
                $txtCenso += " " + $giros[$seg % 4] + " "
                if ($script:CensoPrev -gt 0) {
                    if ($seg -gt [int]$script:CensoPrev) { $txtCenso += (Traduzir "(+)") }
                    else { $txtCenso += ("{0}%" -f [math]::Min(99, [int](100.0 * $seg / [double]$script:CensoPrev))) }
                }
            }
            $UI.lblCenso.Text       = $txtCenso
            $UI.lblCenso.Foreground = Pincel $Cores.emCurso
            $UI.icoCenso.Foreground = Pincel $Cores.emCurso
            try { $UI.btnCenso.ToolTip = Traduzir-Frase (Get-MotivoCenso $v) } catch { }
            return
        }
        try { $UI.btnCenso.ToolTip = Traduzir-Frase (Get-MotivoCenso $v) } catch { }
        $UI.btnCenso.IsEnabled = ($null -ne $v) -and (Test-PodeCenso $v) -and `
            ($Estado.Atual -eq "inicial") -and (-not $script:CensoPS)
        if ($v -and [bool]$v.CensoFeito) {
            $UI.lblCenso.Text       = "[F11] " + (Traduzir "Censo Feito")
            $UI.lblCenso.Foreground = Pincel $Cores.okdim
            $UI.icoCenso.Foreground = Pincel $Cores.okdim
            return
        }
        $UI.lblCenso.Text = "[F11] " + (Traduzir "Censo Completo")
        if ($v -and (Test-PodeCenso $v) -and ($Estado.Atual -eq "inicial") -and (-not $script:CensoPS)) {
            $UI.lblCenso.Foreground = Pincel $Cores.txt
            $UI.icoCenso.Foreground = Pincel $Cores.txt
        } else {
            $UI.lblCenso.Foreground = Pincel $Cores.dim2
            $UI.icoCenso.Foreground = Pincel $Cores.dim2
        }
    } catch { }
}

function Start-Censo {
    if ($script:CensoRodando) { return }
    <#  18.05: a trava mecanica, igual a da medicao. Depois que um censo e
        encerrado na tela, o dovi_tool dele ainda esta rodando por ate 100s.
        Disparar outro agora seriam dois lendo o mesmo disco. #>
    if ($script:CensoPS) {
        <#  18.15 - A REDE, PARA O CASO DE O ENCERRAMENTO NAO RESPONDER.

            No log dele de 17/09 o botao repetiu esta frase em QUINZE cliques e
            nunca mais voltou: o runspace tinha ficado preso e o "censo_fim",
            que e quem solta o handle, nunca chegou. A causa foi consertada
            acima (o cmd do pipe tambem morre), mas trava que so sai com o
            programa fechado nao pode existir. Entao: se ja se passaram 20s
            desde o encerramento e NENHUM processo do censo continua de pe, o
            handle e orfao - ele e abandonado (sem Dispose, que esperaria) e o
            censo novo comeca. Vazar um objeto e menos grave que perder o
            recurso para o resto da sessao. #>
        $orfao = $false
        if ($script:CensoMorto -and $script:CensoMortoEm -and
            ((Get-Date) - $script:CensoMortoEm).TotalSeconds -gt 20) {
            if (@(Get-ProcessosDoCenso "$($script:CensoCaminho)").Count -eq 0) { $orfao = $true }
        }
        if ($orfao) {
            Escrever-Log "CENSO COMPLETO: o anterior nao respondeu e nao ha processo dele de pe - handle abandonado, o censo novo comeca" "AVISO"
            $script:CensoPS = $null; $script:CensoRunspace = $null; $script:CensoHandle = $null
        } else {
            Escrever-Log "CENSO COMPLETO: o anterior ainda esta encerrando - o novo comeca assim que ele sair" "LEITURA"
            return
        }
    }
    <#  17.21: o botao e a aparencia; esta linha e a regra. Tecla, foco e
        qualquer outro caminho futuro batem aqui do mesmo jeito. #>
    if ($Estado.Atual -in @("rodando","pausado")) {
        Escrever-Log "CENSO COMPLETO bloqueado (conversao em curso - o censo le o filme inteiro e disputaria o disco)" "ACAO"
        return
    }
    <#  18.18 - RECUSA MUDA E PIOR QUE RECUSA.

        "os F quebrou... o censo pelo jeito quebrou, so mandar ele comecar
        quebrou de qualquer jeito" (Diego, 17/09). E o log mostra o que ele viu:

          17:18:29,4  TECLA: F11
          17:18:29,4  CLIQUE: Censo Completo      <- e mais nada. Sete vezes.

        O censo nao quebrou: ele RECUSOU, e recusou calado. Estas duas linhas
        saiam com "return" seco - sem arquivo selecionado, ou com um arquivo que
        nao e Complex FEL (no caso dele, no meio de uma releitura da pasta). Do
        lado de fora e indistinguivel de defeito: a tecla nao faz nada e o
        programa nao diz por que.

        Licao 2, que este projeto persegue desde o comeco: toda recusa fala. E a
        dica do botao ja sabia o motivo certo - agora o log usa a MESMA frase,
        de um lugar so. #>
    $idx = $UI.lstFila.SelectedIndex
    if ($idx -lt 0 -or $idx -ge $script:Videos.Count) {
        Escrever-Log "CENSO COMPLETO recusado: nenhum video selecionado na fila - clique num Complex FEL primeiro" "ACAO"
        return
    }
    $v = $script:Videos[$idx]
    if (-not (Test-PodeCenso $v)) {
        Escrever-Log ("CENSO COMPLETO recusado para '{0}': {1}" -f $v.Nome, (Get-MotivoCenso $v)) "ACAO"
        return
    }

    $script:CensoRodando = $true
    <#  18.13: cada censo comeca com a prova de vida zerada - CPU de um censo
        anterior nao pode responder pelo de agora. #>
    $script:CensoCpu = 0.0; $script:CensoVivoEm = Get-Date; $script:CensoMudo = $false
    <#  18.14: guarda O CAMINHO do arquivo que esta sendo contado. E ele que
        identifica o ffmpeg deste censo na hora de encerrar - identidade e o
        caminho, nunca o indice (licao 30). #>
    $script:CensoCaminho = "$($v.Caminho)"; $script:CensoMorto = $false; $script:CensoMortoEm = $null
    <#  18.20 - O BOTAO CONTINUA CLICAVEL ENQUANTO O CENSO RODA.

        "click la nao funciona, so os F11" (Diego, 17/09). Ele esta certo e o
        motivo e bobo: a 18.16 fez o botao virar liga/desliga, e esta linha -
        que existe desde a 17.08, de quando o botao so comecava - continuava
        APAGANDO o botao no instante em que o censo comecava. Com o botao
        desabilitado, o clique nao chega em lugar nenhum; o F11 chegava, porque
        tecla nao passa pelo IsEnabled.

        Resultado: duas portas para a mesma acao, com regras diferentes - o
        defeito que este projeto persegue desde a 16.79, agora entre o mouse e
        o teclado.

        18.21: o conserto estava no lugar errado - isto aqui era um TERCEIRO
        dono do IsEnabled brigando com Update-Diagnostico a cada repintura, e
        por isso o clique funcionava as vezes. Quem desenha o botao (rotulo,
        cor E IsEnabled) e Update-BotaoCenso, um so. #>
    <#  17.13: "Contando..." sozinho nao diz o que esta contando - o Diego
        viu o botao cinza escrito "Contando..." e perguntou o que era. O
        rotulo passa a carregar o assunto, como todos os outros da barra. #>
    <#  18.07 - O CENSO PASSOU A MOSTRAR QUE ESTA VIVO.

        "o censo tem q so imaginar q ele ta fazendo algo ne? demora pra
         kralho e so deixa o mouse em cima e DIZ q ta fazendo algo"
        (Diego, 17/09). Ele esta certo, e e a licao 2 do projeto: trabalho de
        100 segundos sem sinal na tela e indistinguivel de programa travado.

        Agora o rotulo CONTA o tempo (o relogio da fila ja bate 10x por
        segundo, nao custa nada) e o botao fica na cor de "em curso" - a mesma
        que a medicao usa. Nao e enfeite: e a diferenca entre esperar e achar
        que quebrou. #>
    $script:CensoT0 = Get-Date
    $script:CensoSegMostrado = -1
    <#  ========================================================================
        2.0b - A PREVISAO DO CENSO NAO PODE VIR DA AMOSTRA. MEDIDO, 18x DE ERRO.

        "O CENSO LEVOU 2:30 MAS EM MENOS DE 30 SEGUNDOS JA TINHA DADO 100%"
        (Diego). E a foto dele, com o mouse parado no botao:

          "O censo deste arquivo esta rodando ha 10m 09s - leva cerca de
           00m 35s no total (a amostra dele levou 00m 07s)."

        O log do Transformers (21/09) fecha a conta:

          10:54:17  CENSO: previsao de 00m 35s (a amostra levou 00m 07s, 4,7x)
          11:07:07  RPU 638,4s + censo 0,9s = 639,3s
                    "Custo: a amostra levou 7,5s; o censo levou 639,3s (85,5x)"

        Previsto 35s, real 639s: erro de DEZOITO VEZES. E como a barra chega a
        99% no previsto e vira "(+)", ela ficou dez minutos em "(+)".

        POR QUE A AMOSTRA NAO SERVE DE REGUA

        Sao dois trabalhos de natureza diferente:

          amostra  - 11 trechos CURTOS, espalhados. O disco pula, le pouco, e
                     boa parte vem de cache. Custo quase independente do filme.
          censo    - le o arquivo INTEIRO, sequencialmente, uma vez.

        Entao o fator amostra->censo nao e uma constante da maquina: ele muda
        com o tamanho do filme E com o disco. Medido nos dois logs dele:

          Saving Private Ryan   82 GB, 2h49  SSD   104,9s   ->  4,7x
          Transformers          78 GB, 2h30  HD    639,3s   -> 85,5x

        Filmes quase do mesmo tamanho, fator dezoito vezes diferente. O que
        mudou foi o DISCO (a foto mostra o G: a 100 MB/s, 97% de uso).

        O MODELO CERTO: O CENSO LE UM ARQUIVO INTEIRO, ENTAO ELE E O MAIOR
        ENTRE DUAS COISAS - o tempo de PUXAR os bytes do disco e o tempo de a
        CPU mastigar o RPU. Quem for mais lento manda:

          disco = tamanho do arquivo / velocidade medida do disco de origem
          cpu   = duracao do filme x s/s calibrado (medido em disco rapido,
                  onde o disco nao era o gargalo)
          previsao = o MAIOR dos dois

        Conferindo com os numeros reais:

          Ryan   disco 82 GB / 2745 MB/s = 30s | cpu 10140s x 0,0103 = 104s
                 -> maior = 104s, real 104,9s          (1% de erro)
          Trans. disco 78 GB /  100 MB/s = 780s | cpu 8993s x 0,0103 =  93s
                 -> maior = 780s, real 639,3s         (22% de erro)

        De 1.700% de erro para 22%. E o s/s continua se corrigindo sozinho.

        A velocidade do disco ja era medida por Measure-VelocidadeOrigem desde
        a 16.64 - ela so nunca tinha sido usada aqui. Licao 15 de novo: a regua
        certa ja existia, so estava sendo usada para outra coisa.
        ======================================================================== #>
    $script:CensoPrev = 0.0
    $gbCenso = 0.0
    if ([double]$v.Bytes -gt 0) { $gbCenso = [double]$v.Bytes / 1GB }
    $segDisco = 0.0
    # 2.0.10: medida POR ARQUIVO (a funcao ja guarda em cache por arquivo).
    # Antes o primeiro censo da sessao valia para todos - um censo no SSD e o
    # seguinte num HD da rede saia com a previsao do SSD.
    $mbsCenso = Measure-VelocidadeOrigem "$($v.Caminho)"
    if ($mbsCenso -le 0) { $mbsCenso = [double]$script:CensoDiscoMbs }
    if ($mbsCenso -gt 0) { $script:CensoDiscoMbs = $mbsCenso }
    if ($gbCenso -gt 0 -and $mbsCenso -gt 0) { $segDisco = ($gbCenso * 1024.0) / $mbsCenso }
    $segCpu = 0.0
    if ([double]$v.DurSeg -gt 0) { $segCpu = [double]$v.DurSeg * $script:CensoSegPorSegFilme }

    if ($segDisco -gt 0 -or $segCpu -gt 0) {
        $script:CensoPrev = [math]::Max($segDisco, $segCpu)
        $mandou = if ($segDisco -ge $segCpu) { "o DISCO" } else { "a CPU" }
        Escrever-Log ("CENSO: previsao de {0} - quem manda aqui e {1} (puxar {2:N1} GB a {3:N0} MB/s = {4}; mastigar o RPU de {5} = {6})" -f `
            (Format-MinSeg ([int]$script:CensoPrev)), $mandou, $gbCenso, $mbsCenso,
            (Format-MinSeg ([int]$segDisco)), (Format-MinSeg ([int][double]$v.DurSeg)), (Format-MinSeg ([int]$segCpu))) "PROVA"
    } else {
        Escrever-Log "CENSO: sem previsao de tempo - nao sei o tamanho deste arquivo nem a velocidade do disco; o rotulo mostra so o tempo decorrido" "AVISO"
    }
    <#  18.17/18.20/18.21: os bytes de RPU esperados para este filme. A 18.17
        pos a PORCENTAGEM neles e a 18.20 desfez isso - o dovi_tool grava o RPU
        de uma vez no fim, entao tamanho nao e progresso (licao 43). O numero
        continua servindo para o que ele sabe fazer: DESCONFIAR de um RPU muito
        menor que o previsto, que e censo cortado no meio. A porcentagem e de
        tempo, e vem de CensoPrev, logo acima. #>
    $script:CensoBytesPrev = 0.0
    if ([double]$v.DurSeg -gt 0) { $script:CensoBytesPrev = [double]$v.DurSeg * $script:CensoBytesSeg }
    <#  18.22: era a terceira escrita no rotulo, e a unica que ainda dizia
        "Censo: contando..." - sem [F11] e sem porcentagem. Quem desenha o
        botao e Update-BotaoCenso; aqui so se avisa que ha o que desenhar. #>
    $script:CensoSegMostrado = -1
    try { Update-BotaoCenso $v } catch { }
    <#  Mesma licao da 17.01: rotulo que o CODIGO reescreve nao pode depender
        da varredura de traducao - ele traduz na hora em que e escrito. #>
    Escrever-Log ("CENSO COMPLETO pedido para '{0}' (Complex FEL). Isto le o filme inteiro e demora - a fila e a conversao continuam livres." -f $v.Nome) "ACAO"

    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "MTA"; $rs.ThreadOptions = "ReuseThread"; $rs.Open()
    $rs.SessionStateProxy.SetVariable("Fila", $script:FilaMsg)
    $rs.SessionStateProxy.SetVariable("PastaScript", $script:PastaScript)
    $rs.SessionStateProxy.SetVariable("CaminhoMotor", $script:CaminhoMotor)
    <#  17.09 - O BOTAO DO CENSO NAO FAZIA NADA, E ESTA E A LINHA.

        Na 17.08 eu pedi o campo pelo nome errado. O objeto do video NAO tem
        um campo chamado como eu escrevi - ele guarda o endereco do arquivo em
        Caminho (e o nome em Nome). Resultado: o runspace recebia string
        vazia, Get-CensoCompletoDV devolvia "Arquivo nao encontrado" e o
        clique morria no log, sem nada na tela. O Diego clicou em tudo e nao
        aconteceu foi nada - com razao.

        A bateria de 17.08 nao pegou porque ela conferia o DESENHO (roda em
        runspace, so em Complex FEL, nao chama funcao da janela) e nao os
        NOMES DOS CAMPOS. Nome de campo errado e sempre mudo. A secao 35
        agora extrai os campos que a LEITURA cria e reprova se o censo pedir
        um que nao existe - o mesmo tipo de teste da secao 13. #>
    $rs.SessionStateProxy.SetVariable("Caminho", "$($v.Caminho)")
    $rs.SessionStateProxy.SetVariable("Nome", "$($v.Nome)")
    $rs.SessionStateProxy.SetVariable("Idx", [int]$idx)
    <#  18.04: o censo tambem ganhou numero de rodada. Mesmo motivo da medicao:
        ele demora 105s, e nesse tempo a pasta pode ter sido trocada. Sem a
        serie, o resultado cairia pelo INDICE na lista nova - o defeito do
        "veredicto do Ryan na linha do Dragon", agora pelo censo. #>
    $script:CensoSerie = $script:CensoSerie + 1
    $rs.SessionStateProxy.SetVariable("Serie", [int]$script:CensoSerie)
    $rs.SessionStateProxy.SetVariable("MasterMax", [double]$v.ELmastermax)
    $rs.SessionStateProxy.SetVariable("AmostraSeg", [double]$v.ELsegundos)
    $ps = [powershell]::Create(); $ps.Runspace = $rs
    $null = $ps.AddScript($script:TrabalhoCenso.ToString())
    $script:CensoRunspace = $rs; $script:CensoPS = $ps
    $script:CensoHandle = $ps.BeginInvoke()
}

function Reset-BotaoCenso {
    <#  17.13 - O ROTULO TINHA COMO FICAR PRESO.

        Ele so voltava no "censo_fim". Se a pasta fosse relida, ou o programa
        seguisse sem o censo terminar, o botao ficava "Censo: contando..."
        apagado - para sempre, sem nada acontecendo atras. Botao que mente
        sobre o proprio estado e a familia de bug que este projeto persegue
        desde a 15.1e. Agora quem zera o estado zera o rotulo junto. #>
    <#  18.10: uma regra, um lugar. O rotulo e a cor saem de Update-BotaoCenso,
        que olha o ESTADO daquele arquivo - inclusive o "ja contado". #>
    try {
        $UI.lblCenso.Text = "[F11] " + (Traduzir "Censo Completo")
        $i = $UI.lstFila.SelectedIndex
        Update-BotaoCenso $(if ($i -ge 0 -and $i -lt $script:Videos.Count) { $script:Videos[$i] } else { $null })
    } catch { }
}

<#  18.14 - CANCELAR O CENSO PASSOU A VALER NA HORA.

    MEDIDO no log dele de 17/09:
      14:28:20,4  CENSO COMPLETO: encerrado - a conversao comecou
      14:30:01,5  CENSO: o arquivo contado nao esta mais na lista - descartado

    101 segundos lendo o disco DEPOIS de cancelado, disputando o disco com a
    conversao que acabara de comecar, para o resultado ir para o lixo no fim.
    "Abandonar o trabalho" resolveu a TELA (18.04) e nao resolveu o DISCO.

    O QUE MATA, E POR QUE ISSO E SEGURO

    O censo e a UNICA coisa neste programa que roda 'dovi_tool extract-rpu'
    lendo da ENTRADA PADRAO (-i -), num pipe montado pelo cmd:

        ffmpeg ... -f hevc -  |  dovi_tool extract-rpu -i -  -o <tmp>\filme.bin

    A conversao roda 'dovi_tool -m 2 convert --discard -i <arquivo>' e a
    medicao por amostra roda 'extract-rpu -i "<trecho>"' - as duas com arquivo
    no -i, nunca com o tracinho. Entao a assinatura separa os tres sem chance
    de confusao, e ainda assim eu exijo TODAS as condicoes: a assinatura, o
    caminho do filme que esta sendo contado (no lado do ffmpeg) e o censo em
    curso. Qualquer duvida, nao mata.

    O QUE ACONTECE DEPOIS, e por que nao sobra sujeira: o '& cmd.exe /c' do
    motor desbloqueia, Get-CensoCompletoDV nao acha o RPU, devolve Ok=false e
    o finally DELE apaga a pasta temporaria - caminho que ja existia e ja era
    testado. O motor nao mudou uma linha. #>
function Test-EhProcessoDoCenso([string]$Nome, [string]$Linha, [string]$Caminho) {
    <#  Funcao PURA de proposito: a bancada roda isto com linhas de comando de
        mentira - inclusive as da conversao - e prova que so o censo morre. #>
    if ([string]::IsNullOrWhiteSpace($Linha)) { return $false }
    $n = "$Nome".ToLowerInvariant()
    if ($n -eq "dovi_tool.exe") {
        if ($Linha -match "\bconvert\b") { return $false }   # isso e a conversao
        return [bool]($Linha -match "extract-rpu\s+-i\s+-(\s|$)")
    }
    if ($n -eq "ffmpeg.exe") {
        if ([string]::IsNullOrWhiteSpace($Caminho)) { return $false }
        if ($Linha -notmatch "-f\s+hevc\s+-(\s|$)") { return $false }
        return $Linha.ToLowerInvariant().Contains("$Caminho".ToLowerInvariant())
    }
    <#  18.15 - O CMD QUE SEGURA O PIPE TAMBEM TEM QUE MORRER.

        MEDIDO no log dele de 17/09 15:24:43 -> 15:27:21: os dois processos
        foram encerrados e mesmo assim o botao repetiu "o anterior ainda esta
        encerrando" em QUINZE cliques, ate ele fechar o programa. As 15:12:44,
        no mesmo log, o mesmo cancelamento funcionou - o que e pior que falhar
        sempre, porque parece sorte.

        Nao e sorte: quem monta o pipe e um cmd.exe (o PowerShell 5.1 estraga
        pipe binario - ver Invoke-PipeExtractRpu no motor). Matando so os dois
        filhos, o cmd PODE continuar de pe esperando a escrita fechar, e o
        "& cmd.exe /c" do motor nunca volta - o runspace fica preso para
        sempre e o censo nunca mais comeca.

        O cmd do censo tambem tem assinatura propria e unica: e o unico cmd
        que este programa executa, e ele carrega o nome do arquivo de linha
        que o motor gravou. #>
    if ($n -eq "cmd.exe") {
        return [bool]($Linha -match "pipe_rpu\.cmd")
    }
    return $false
}

<#  18.15: quem ACHA os processos do censo virou um lugar so - o cancelamento
    mata exatamente os mesmos que a prova de vida observa. Duas listas para a
    mesma coisa e o defeito que este projeto persegue desde a 16.79. #>
function Get-ProcessosDoCenso([string]$Caminho) {
    $achados = @()
    try {
        $lista = @(Get-CimInstance Win32_Process -OperationTimeoutSec 3 -Filter "Name='dovi_tool.exe' OR Name='ffmpeg.exe' OR Name='cmd.exe'" -ErrorAction SilentlyContinue)
        foreach ($pr in $lista) {
            if (Test-EhProcessoDoCenso "$($pr.Name)" "$($pr.CommandLine)" $Caminho) { $achados += $pr }
        }
    } catch { }
    return $achados
}

function Matar-ProcessosDoCenso([string]$Caminho) {
    $mortos = 0
    try {
        foreach ($pr in (Get-ProcessosDoCenso $Caminho)) {
            try {
                Stop-Process -Id ([int]$pr.ProcessId) -Force -ErrorAction Stop
                $mortos++
                Escrever-Log ("CENSO: processo {0} (pid {1}) encerrado a pedido do cancelamento" -f $pr.Name, $pr.ProcessId) "LEITURA"
            } catch {
                # 2.0.10: entre listar e encerrar o processo pode ter acabado
                # sozinho (log de 23/09 02:14:23, ffmpeg da medicao). Isso nao e
                # falha - e o trabalho que terminou um instante antes do pedido.
                if (-not (Get-Process -Id ([int]$pr.ProcessId) -ErrorAction SilentlyContinue)) {
                    Escrever-Log ("CENSO: {0} (pid {1}) ja tinha terminado sozinho antes do pedido" -f $pr.Name, $pr.ProcessId) "LEITURA"
                } else {
                    Escrever-Log ("CENSO: nao consegui encerrar {0} (pid {1}) - {2}" -f $pr.Name, $pr.ProcessId, $_.Exception.Message) "AVISO"
                }
            }
        }
    } catch {
        Escrever-Log ("CENSO: nao consegui olhar os processos para encerrar - {0}" -f $_.Exception.Message) "AVISO"
    }
    <#  18.20: no log dele de 17:56:37 o cancelamento nao encerrou processo
        nenhum e NAO disse nada - e o runspace ficou preso, porque o cmd do pipe
        seguiu vivo. Silencio aqui e a diferenca entre "nao havia o que matar" e
        "eu nao achei o que matar", que sao coisas MUITO diferentes na hora de
        entender um log. Licao 2. #>
    if ($mortos -eq 0) {
        Escrever-Log "CENSO: nenhum processo do censo foi encontrado para encerrar - ou ele ja tinha terminado, ou a busca falhou" "AVISO"
    }
    return $mortos
}

function Stop-Censo {
    <#  18.04 - ESTA FUNCAO CONGELAVA A JANELA POR UM MINUTO E MEIO.

        Log dele de 16/09, medido DUAS vezes, com o censo rodando:

          23:55:13,5  CLIQUE: Iniciar  ->  ESTADO rodando so as 23:56:35,3
                      = 81,8 SEGUNDOS de janela morta
          23:58:38,4  Iniciar confirmado -> ESTADO rodando as 00:00:10,8
                      = 92,4 SEGUNDOS

        Os dois casam com o tempo que FALTAVA do censo (106,5s de dovi_tool
        lendo o RPU inteiro). A causa: $CensoPS.Dispose() NA THREAD DA
        INTERFACE. Dispose() em pipeline que esta rodando NAO retorna - ele
        espera o pipeline parar, e o pipeline estava dentro do dovi_tool.

        Mesma familia do WaitOne que saiu do Stop-Motor na 18.00. A regra que
        eu escrevi la ("nenhuma espera sincrona no codigo da janela") listava
        WaitOne, Start-Sleep, .Wait(, .Join( e .EndInvoke( - e NAO listava
        Dispose/Stop/Close, que bloqueiam igual. Regra incompleta nao pega o
        proximo caso; foi o que aconteceu.

        Agora ninguem espera: a tela fecha o estado do censo na hora, o
        trabalho e ABANDONADO e morre sozinho, e quem descarta o runspace e a
        chegada do "censo_fim" - que a essa altura ja vem com serie velha e
        nao encosta em veredicto nenhum. #>
    if (-not $script:CensoRodando -and -not $script:CensoPS) { return }
    $script:CensoRodando = $false; $script:CensoMudo = $false
    <#  18.14: e agora o trabalho morre de verdade, nao so na tela. #>
    $script:CensoMorto = $true; $script:CensoMortoEm = Get-Date
    $mortos = Matar-ProcessosDoCenso "$($script:CensoCaminho)"
    if ($mortos -gt 0) {
        Escrever-Log ("CENSO COMPLETO: cancelado de verdade - {0} processo(s) encerrado(s), o disco fica livre na hora" -f $mortos) "LEITURA"
    }
    $script:CensoSerie   = $script:CensoSerie + 1   # o que estiver no ar fica velho
    Reset-BotaoCenso
    Escrever-Log "CENSO COMPLETO: encerrado na tela - o trabalho morre sozinho (nada espera por ele)" "LEITURA"
}

<#  18.22 - O F11 TRAVOU PARA SEMPRE, E A CULPA E DA MINHA REGRA DA 18.21.

    MEDIDO no log dele de 17/09. Da linha 139 ate o fim da sessao, sem uma
    unica excecao:

      22:26:00,8  TECLA: F11 (ignorada - nao se aplica ao estado 'inicial')
      22:26:01,2  TECLA: F11 (ignorada - nao se aplica ao estado 'inicial')
      ... e assim por mais de trinta vezes, ate ele fechar o programa.

    "APERTEI TANTO O F11 QUE TEVE UMA HORA QUE NAO FUNCIONOU NUNCA MAIS."

    O que aconteceu: o botao fica apagado enquanto $script:CensoPS existe (o
    censo anterior ainda encerrando). Ate a 18.20 isso nao prendia ninguem,
    porque o F11 NAO passava pelo botao - ele chegava em Start-Censo, e la
    dentro existe a saida de emergencia: passados 20s, se nenhum processo do
    censo continua de pe, o handle e orfao e vai embora.

    A 18.21 mandou o F11 conferir o botao. Certo para acabar com "clica nao
    funciona, F11 funciona" - e errado de um jeito que eu nao vi: com o botao
    apagado, o F11 nunca mais chega em Start-Censo, e a saida de emergencia
    ficou atras de uma porta trancada. A trava que existia para durar segundos
    passou a durar a sessao inteira.

    Licao 47: ao unificar duas portas numa so, confira o que so a porta que
    voce fechou sabia fazer. A saida de emergencia morava dentro de uma delas.

    O conserto tem duas partes. Esta e a primeira: a liberacao do orfao saiu
    de dentro de Start-Censo e virou funcao propria, chamada TAMBEM pelo
    relogio da fila - entao o estado se desfaz sozinho, sem depender de
    ninguem apertar nada.

    E ela NAO usa WMI. O runspace, quando termina, marca o proprio handle como
    completo; perguntar isso e de graca e e local. Consultar processos no
    relogio da tela foi o que congelou a janela por 55 segundos na 18.17
    (licao 40) - esse caminho continua existindo, mas so em Start-Censo, que
    roda por clique e nao quatro vezes por segundo. #>
function Liberar-CensoOrfao {
    if (-not $script:CensoPS) { return $false }
    if ($script:CensoRodando) { return $false }
    if (-not $script:CensoHandle) { return $false }
    try { if (-not $script:CensoHandle.IsCompleted) { return $false } } catch { return $false }
    Escrever-Log "CENSO COMPLETO: o trabalho anterior ja terminou de verdade - o botao esta livre de novo" "LEITURA"
    Fechar-Runspace-Censo
    Reset-BotaoCenso
    return $true
}

function Fechar-Runspace-Censo {
    # So aqui, e so quando o "censo_fim" JA chegou: descartar agora nao espera.
    try { if ($script:CensoPS)       { $script:CensoPS.Dispose() } } catch { }
    try { if ($script:CensoRunspace) { $script:CensoRunspace.Close(); $script:CensoRunspace.Dispose() } } catch { }
    $script:CensoPS = $null; $script:CensoRunspace = $null; $script:CensoHandle = $null
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
<#  17.19: Get-PastaDados subiu para JUNTO do bloco do log (bem mais acima).
    Ela precisa existir antes dele: o log e a primeira coisa que o programa
    escreve, e era a unica escrita do programa que ainda nao perguntava se a
    pasta aceita escrita. Nao foi copiada - foi MOVIDA. #>
function Get-CaminhoIdioma {
    <#  17.02: le dos DOIS lugares. Quem ja tinha o IDIOMA.txt na pasta do
        programa nao perde a escolha ao atualizar. #>
    $naDados = Join-Path (Get-PastaDados) "IDIOMA.txt"
    if (Test-Path -LiteralPath $naDados) { return $naDados }
    $noScript = Join-Path $script:PastaScript "IDIOMA.txt"
    if (Test-Path -LiteralPath $noScript) { return $noScript }
    return $naDados
}

<#  17.10 - A CHAVE DA MEDICAO MEL x FEL.

    A medicao de camada e o unico trabalho da leitura da pasta que NAO e
    instantaneo: medido em 10/09, 22,65s no Ryan e 27,49s no Troy - 50,14s
    para dois arquivos. Ela roda em segundo plano (o F1 ja fica liberado),
    mas ate ela terminar a linha nao tem veredicto, e numa pasta grande isso
    e minutos antes de a tela dizer alguma coisa.

    A chave existe para RESPONDER A PERGUNTA, nao para esconder o custo:
    ligada e desligada, o log grava o que a leitura levou, e a comparacao
    fica escrita. Regra do projeto - numero de teste real, nunca sensacao.

    LIGADA e o padrao e continua sendo: desligar troca o veredicto por
    "EL nao medida" (ambar), que e duvida honesta, mas e duvida. #>
$script:MedirELArquivo = "MEDIR_EL.txt"
$script:MedirELLigado  = $true

function Get-CaminhoMedirEL {
    return (Join-Path (Get-PastaDados) $script:MedirELArquivo)
}

function Carregar-MedirEL {
    try {
        $c = Get-CaminhoMedirEL
        if (Test-Path -LiteralPath $c) {
            $v = ([System.IO.File]::ReadAllText($c)).Trim().ToUpperInvariant()
            # Qualquer coisa ilegivel volta ao padrao LIGADO: duvida no
            # arquivo de preferencia nao pode virar veredicto faltando.
            $script:MedirELLigado = ($v -ne "0" -and $v -ne "NAO" -and $v -ne "OFF")
        }
    } catch { }
}

function Salvar-MedirEL {
    try {
        [System.IO.File]::WriteAllText((Get-CaminhoMedirEL),
            $(if ($script:MedirELLigado) { "1" } else { "0" }),
            (New-Object System.Text.UTF8Encoding($false)))
    } catch {
        Escrever-Log ("MEDIR EL: nao consegui gravar a preferencia - {0}" -f $_.Exception.Message) "AVISO"
    }
}

<#  17.15 - A CHAVE PASSA A TER AS DUAS CORES, E DOIS LUGARES.

    "O medir MEL x FEL ali de baixo fica em amarelo certo quando desligado,
    agora ligado fica cinza podre. Coloca ele verde... e esse amarelo dele
    quando ta desligado tambem... na vdd ele pode ser vermelho ne desligado?"

    Pode e deve. A escala de cores deste projeto ja estava definida desde a
    16.94 e esta chave era a unica coisa da tela fora dela: ligado saia no
    cinza da borda (que e ausencia de cor, nao "ligado") e desligado no ambar
    da DUVIDA - so que desligar a medicao nao e uma duvida, e uma decisao. A
    duvida e o resultado disso, e ela ja aparece onde tem que aparecer: no
    'EL nao medida' ambar da coluna.

      LIGADO    verde     - vai medir, e o veredicto sai
      DESLIGADO vermelho  - nao vai medir, e nenhum arquivo tera veredicto

    Vermelho aqui NAO quer dizer erro, do mesmo jeito que o vermelho do
    Complex FEL nao quer dizer bloqueado: quer dizer "voce desligou uma
    verificacao". Ela volta a qualquer clique.

    O gemeo da barra de cima le o MESMO estado desta funcao - uma regra, um
    lugar. A dica explica o custo, que e o que decide o clique. #>
<#  17.16 - "ENQUANTO ESTA MEDINDO NAO TEM UMA BARRA DE %?"

    Pedido do Diego: a medicao leva 20-30s por arquivo, a tela diz "medindo"
    e nada mais se move. "As vezes demora e nao da pra saber se ta indo ou se
    ta travado" - a mesma queixa do aviso de espera parado (17.14), agora do
    lado de quem nem apertou Iniciar ainda.

    A janela ja conta os arquivos desde a 17.14 ($ELtotal / $ELfeitos): o que
    faltava era mostrar. O botao vira o lugar natural - e o botao que fala da
    medicao, e ele esta na barra, sempre visivel, em qualquer aba. #>
function Update-BarraMedirEL {
    try {
        if (-not $script:MedindoEL -or $script:ELtotal -le 0) {
            $UI.trilhoMedirEL.Visibility = "Collapsed"
            return
        }
        $UI.trilhoMedirEL.Visibility = "Visible"
        $largura = [math]::Max(40.0, $UI.trilhoMedirEL.ActualWidth)
        $fr = [double]$script:ELfeitos / [double]$script:ELtotal
        if ($fr -lt 0) { $fr = 0 } elseif ($fr -gt 1) { $fr = 1 }
        $UI.barraMedirEL.Width = $largura * $fr
    } catch { }
}

function Update-BotaoMedirEL {
    <#  17.16: medindo e um TERCEIRO estado, e ele manda no rotulo enquanto
        dura - a chave continua ligada, mas o que interessa saber naquele
        momento nao e isso, e em que arquivo ela esta. #>
    <#  18.01: cancelada = a tela para de dizer "Medindo" na hora, mesmo com o
        runspace ainda morrendo atras. Ver Stop-Medicao. #>
    if ($script:MedirELLigado -and $script:MedindoEL -and $script:ELtotal -gt 0 -and
        (-not $script:Controle.PararMedicao)) {
        $emCurso = [math]::Min($script:ELtotal, $script:ELfeitos + 1)
        $txtMed = Traduzir-Frase ("Medindo MEL x FEL: {0} de {1}" -f $emCurso, $script:ELtotal)
        $UI.txtMedirEL.Text = $txtMed
        $UI.txtMedirEL.Foreground  = Pincel $Cores.emCurso
        $UI.btnMedirEL.BorderBrush = Pincel $Cores.emCurso
        $UI.btnMedirEL.Background  = Pincel "#08161A"
        try {
            <#  18.21: "2/3 FOTOS MOSTRAM O FEL SEM O [F12]" (Diego, 17/09).
                Ele contou certo. Os ramos Ligado e Desligado ganharam a tecla
                na 18.18; ESTE, o "Medindo N de M", ficou de fora - e e
                justamente o que fica na tela enquanto algo acontece. Rotulo
                que perde a tecla no estado mais visto e a tecla nao existindo. #>
            $UI.lblMedirELTopo.Text = "[F12] " + $txtMed
            $UI.lblMedirELTopo.Foreground = Pincel $Cores.emCurso
            $UI.icoMedirELTopo.Foreground = Pincel $Cores.emCurso
            $dicaMed = Traduzir "A camada de melhoria está sendo medida agora. A fila fica livre - isto roda em segundo plano."
            $UI.btnMedirELTopo.ToolTip = $dicaMed
            $UI.btnMedirEL.ToolTip     = $dicaMed
        } catch { }
        Update-BarraMedirEL
        return
    }
    Update-BarraMedirEL
    if ($script:MedirELLigado) {
        $UI.txtMedirEL.Text = Traduzir "Medir MEL x FEL: Ligado"
        $UI.txtMedirEL.Foreground  = Pincel $Cores.okdim
        $UI.btnMedirEL.BorderBrush = Pincel $Cores.okdim
        $UI.btnMedirEL.Background  = Pincel "#0B1109"
    } else {
        $UI.txtMedirEL.Text = Traduzir "Medir MEL x FEL: Desligado"
        $UI.txtMedirEL.Foreground  = Pincel $Cores.err
        $UI.btnMedirEL.BorderBrush = Pincel $Cores.err
        $UI.btnMedirEL.Background  = Pincel "#110809"
    }
    # O gemeo da barra de cima: mesmo estado, mesma escala, o desenho da
    # barra (icone em cima, rotulo embaixo).
    try {
        if ($script:MedirELLigado) {
            $UI.lblMedirELTopo.Text = "[F12] " + (Traduzir "Medir MEL x FEL: Ligado")
            $UI.lblMedirELTopo.Foreground = Pincel $Cores.okdim
            $UI.icoMedirELTopo.Foreground = Pincel $Cores.okdim
            $dicaEL = Traduzir ("Mede a camada de melhoria (MEL x FEL) de cada Profile 7 ao ler a pasta. " +
                "É o que dá o veredicto da coluna DOLBY VISION. Clique para desligar.")
            # 17.16: "so a de cima da a descricao, a de baixo nao aparece
            # nada" - eram dois botoes e uma dica so. Mesmo estado, mesma
            # explicacao, nos dois.
            $UI.btnMedirELTopo.ToolTip = $dicaEL
            $UI.btnMedirEL.ToolTip     = $dicaEL
        } else {
            $UI.lblMedirELTopo.Text = "[F12] " + (Traduzir "Medir MEL x FEL: Desligado")
            $UI.lblMedirELTopo.Foreground = Pincel $Cores.err
            $UI.icoMedirELTopo.Foreground = Pincel $Cores.err
            $dicaEL = Traduzir ("A leitura da pasta não vai medir a camada de melhoria: nenhum Profile 7 " +
                "terá veredicto e todos aparecem como 'EL não medida'. Clique para ligar.")
            $UI.btnMedirELTopo.ToolTip = $dicaEL
            $UI.btnMedirEL.ToolTip     = $dicaEL
        }
    } catch { }
}

function Get-CaminhoCalibragem {
    return (Join-Path (Get-PastaDados) $script:CalibArquivo)
}

function Get-Percentil([double[]]$Valores, [double]$P) {
    <#  16.99: percentil por interpolacao linear. P = 0,5 e a mediana.
        Uma amostra so devolve ela mesma - com um numero nao ha distribuicao,
        e inventar uma seria pior que usar o unico dado que existe. #>
    $v = @($Valores | Sort-Object)
    if ($v.Count -eq 0) { return 0.0 }
    if ($v.Count -eq 1) { return [double]$v[0] }
    $i  = ($v.Count - 1) * $P
    $lo = [int][math]::Floor($i)
    $hi = [int][math]::Ceiling($i)
    if ($lo -eq $hi) { return [double]$v[$lo] }
    return ([double]$v[$lo] + ($i - $lo) * ([double]$v[$hi] - [double]$v[$lo]))
}

function Fechar-MedidaDoVideo {
    <#  16.99: chamada nos DOIS pontos em que um arquivo termina - quando o
        motor anuncia o proximo ("arquivo") e quando a fila acaba ("fim").
        Sao os dois unicos lugares em que da para saber o tempo real, e
        esquecer um deles deixaria o ultimo arquivo de toda fila sem entrar
        na calibragem - justamente o caso da fila de um arquivo so, que e o
        mais comum.

        So conta arquivo que REALMENTE converteu: cancelado no meio nao serve
        de medida de nada, e entraria como um numero baixo puxando todas as
        proximas estimativas para menos. #>
    param([bool]$Concluido = $true)
    <#  17.00 - O DEFEITO QUE EU MESMO PLANTEI, ACHADO NA REVISAO.

        A primeira versao disto olhava so o T0Video. Mas o T0Video ja e
        preenchido no INICIAR (linha "T0Fila = T0Video = agora"), antes de
        qualquer arquivo comecar - e o motor anuncia "ARQUIVO 1/N" logo
        depois. Resultado: no primeiro anuncio da fila esta funcao acharia
        que o arquivo 0 tinha acabado, e gravaria como tempo real o segundo
        e meio entre o Iniciar e o anuncio.

        Os limites de sanidade recusariam esse numero - ele cairia muito
        abaixo do CalibMin - entao nada seria gravado. Mas a tela ganharia um
        aviso de calibragem recusada em TODA conversao, e aviso que aparece
        sempre e aviso que ninguem le mais. Ruido tambem e defeito.

        A correcao nao e olhar melhor o relogio: e ter um estado que diz "ha
        um arquivo em andamento". Relogio ligado nao quer dizer arquivo
        rodando - e o dado que faltava. #>
    if (-not $Concluido) { $Motor.MedidaAberta = $false; $Motor.T0Video = $null; return }
    if ($Motor.MedidaAberta -ne $true) { return }
    $Motor.MedidaAberta = $false
    if ($null -eq $Motor.T0Video) { return }
    $idx = [int]$Motor.VideoIdx
    if ($idx -lt 0 -or $idx -ge @($script:LoteAtual).Count) { $Motor.T0Video = $null; return }
    $item = $script:LoteAtual[$idx]
    <#  2.0.7 - A PAUSA ENTRAVA NO TEMPO "REAL" DO ARQUIVO.
        GoT 22/09 22:33: 2m43s pausado viraram "erro +44,6%" e foram
        gravados como 0,0232 s/GB/peso - envenenando as proximas
        estimativas. As etapas ja descontavam a pausa; o arquivo nao. #>
    $seg = ((Get-Date) - $Motor.T0Video).TotalSeconds - [double]$Motor.PausadoVideo
    if ($seg -lt 0) { $seg = 0 }
    <#  17.16 - PREVISTO x REAL, NO LOG, POR ARQUIVO.

        Pergunta do Diego, 13/09: "no inicio dizia 1:25 para terminar, achei
        estranho pois sao duas conversoes de TrueHD que demoram mais... nao
        fiquei pra acompanhar, veja voce como se comportou pelo log."

        Fui ver e a previsao tinha acertado: 1h25 prevista contra 1h20 real,
        6% de erro. Mas para descobrir isso eu tive que abrir dois logs,
        casar a linha 'previsto' do comeco com a 'Tempo deste episodio' do
        fim, e subtrair na mao. Ele nao vai fazer isso - e nem deveria.

        A linha existe pelo mesmo motivo da AUDIO PADRAO (motor 14.54): a
        regra estava certa e faltava PROVA. Quem desconfia da estimativa
        agora tem a resposta no mesmo log, na hora em que o arquivo termina.

        E ela vale para mim tambem: e por esta linha que da para ver se os
        pesos precisam ser revistos - o AVISO de calibragem grita quando as
        rodadas se espalham, mas espalhamento entre filmes DIFERENTES nao e
        erro, e erro por arquivo e. Este numero e o que separa os dois. #>
    $prev = [double]$item.SegEstimado
    <#  2.0.12: arquivo que ja existia na saida e pulado em menos de 1 s. O log
        de 23/09 13:33:45 dizia "real 0s | erro -100,0%" e a calibragem dava
        AVISO - para um arquivo em que nada foi convertido. Nao ha o que medir. #>
    if ($seg -lt 5) {
        Escrever-Log ("PREVISAO: '{0}' nao comparada - nada foi convertido (arquivo pulado)" -f "$($item.Nome)") "PROVA"
        $Motor.T0Video = $null
        return
    }
    if ($prev -gt 0) {
        $erro = 100.0 * ($seg - $prev) / $prev
        $sinal = if ($erro -ge 0) { "+" } else { "" }
        Escrever-Log ("PREVISAO: '{0}' | previsto {1:N0}s | real {2:N0}s | erro {3}{4:N1}%" -f `
                      "$($item.Nome)", $prev, $seg, $sinal, $erro) "PROVA"
    }
    Registrar-Calibragem -Gb ([double]$item.Gb) -SomaPesos ([double]$item.SomaPesos) `
                         -SegReais $seg -Nome "$($item.Nome)"
    $Motor.T0Video = $null
}

function Registrar-Calibragem {
    <#  16.99: grava UMA linha por arquivo convertido. E so isto:
          data, nome, GB, soma dos pesos, segundos reais, e o valor derivado.
        O valor derivado e o que interessa - segundos por GB por peso, que e
        exatamente a grandeza que a estimativa usa. Os outros campos ficam
        para poder auditar depois de onde veio cada numero.

        NAO grava o que nao serve de calibragem: arquivo cancelado no meio,
        arquivo que falhou, ou qualquer conta que caia fora dos limites de
        sanidade. Historico sujo e pior que historico curto - um numero
        errado aqui envenena as proximas cinco estimativas. #>
    param([double]$Gb, [double]$SomaPesos, [double]$SegReais, [string]$Nome)
    if ($Gb -le 0 -or $SomaPesos -le 0 -or $SegReais -le 0) { return }
    $valor = $SegReais / ($Gb * $SomaPesos)
    if ($valor -lt $script:CalibMin -or $valor -gt $script:CalibMax) {
        Escrever-Log ("CALIBRAGEM: '{0}' deu {1:N4} s/GB/peso - fora dos limites ({2:N3} a {3:N3}), NAO gravado" -f `
                      $Nome, $valor, $script:CalibMin, $script:CalibMax) "AVISO"
        return
    }
    try {
        $linha = ("{0}`t{1}`t{2}`t{3}`t{4}`t{5}" -f `
                    (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Nome,
                    $Gb.ToString("0.000", [System.Globalization.CultureInfo]::InvariantCulture),
                    $SomaPesos.ToString("0.0", [System.Globalization.CultureInfo]::InvariantCulture),
                    $SegReais.ToString("0", [System.Globalization.CultureInfo]::InvariantCulture),
                    $valor.ToString("0.00000", [System.Globalization.CultureInfo]::InvariantCulture))
        [System.IO.File]::AppendAllText((Get-CaminhoCalibragem), ($linha + "`r`n"),
                                        (New-Object System.Text.UTF8Encoding($true)))
        Escrever-Log ("CALIBRAGEM: '{0}' | {1:N2} GB | peso {2:N0} | {3:N0}s reais -> {4:N4} s/GB/peso (gravado)" -f `
                      $Nome, $Gb, $SomaPesos, $SegReais, $valor) "PROVA"
    } catch {
        # Nao poder gravar a calibragem nao pode derrubar uma conversao que
        # deu certo. Perde-se a linha, nao o arquivo.
        Escrever-Log ("CALIBRAGEM: nao consegui gravar - {0}" -f $_.Exception.Message) "AVISO"
    }
}

<#  2.0 - A CALIBRAGEM POR ETAPA: GRAVAR E LER.

    Uma linha por etapa concluida, com o previsto e o real daquela etapa. O
    fator e real/previsto: 1,0 e "acertou", 1,3 e "esta maquina leva 30% a mais
    neste trabalho". P75 das ultimas 5 de CADA etapa, pelo mesmo motivo que a
    16.99 escolheu p75 no modelo antigo: subestimar e o erro pior. #>
function Get-CaminhoCalibragemEtapas {
    return (Join-Path (Get-PastaDados) $script:CalibEtapaArquivo)
}

function Registrar-FatorDaEtapa([int]$Idx, [double]$SegReais) {
    if ($Idx -lt 0 -or $Idx -ge 5) { return }
    if ($SegReais -le 0) { return }
    $prev = 0.0
    try {
        $iv = [int]$Motor.VideoIdx
        if ($iv -ge 0 -and $iv -lt @($script:LoteAtual).Count) {
            $se = @($script:LoteAtual[$iv].SegEtapas)
            if ($Idx -lt $se.Count) { $prev = [double]$se[$Idx] }
        }
    } catch { $prev = 0.0 }
    if ($prev -le 0) { return }
    <#  O previsto que viajou no lote JA esta multiplicado pelo fator que valia
        no inicio da fila. Entao real/previsto e a correcao que falta APLICAR
        POR CIMA do fator atual - e o que se grava e o fator final, ja composto.
        Gravar a razao crua faria a correcao se aplicar duas vezes na proxima
        conversao, e o numero divergiria um pouco mais a cada rodada. #>
    $fAtual = 1.0
    if ($Idx -lt @($script:FatorEtapa).Count) { $fAtual = [double]$script:FatorEtapa[$Idx] }
    if ($fAtual -le 0) { $fAtual = 1.0 }
    $fNovo = ($SegReais / $prev) * $fAtual
    $nome = "etapa$($Idx + 1)"
    if ($Idx -lt @($script:NomeEtapaCalib).Count) { $nome = $script:NomeEtapaCalib[$Idx] }
    if ($fNovo -lt $script:FatorEtapaMin -or $fNovo -gt $script:FatorEtapaMax) {
        Escrever-Log ("CALIBRAGEM {0}: previsto {1:N0}s, real {2:N0}s -> fator {3:N2} fora dos limites ({4:N2} a {5:N2}), NAO gravado" -f `
                      $nome, $prev, $SegReais, $fNovo, $script:FatorEtapaMin, $script:FatorEtapaMax) "AVISO"
        return
    }
    try {
        $inv = [System.Globalization.CultureInfo]::InvariantCulture
        $linha = ("{0}`t{1}`t{2}`t{3}`t{4}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $nome,
                  $prev.ToString("0.0", $inv), $SegReais.ToString("0.0", $inv), $fNovo.ToString("0.0000", $inv))
        [System.IO.File]::AppendAllText((Get-CaminhoCalibragemEtapas), ($linha + "`r`n"),
                                        (New-Object System.Text.UTF8Encoding($true)))
        Escrever-Log ("CALIBRAGEM {0}: previsto {1:N0}s, real {2:N0}s -> fator {3:N2} (gravado; a proxima estimativa desta etapa ja usa)" -f `
                      $nome, $prev, $SegReais, $fNovo) "PROVA"
    } catch {
        Escrever-Log ("CALIBRAGEM {0}: nao consegui gravar - {1}" -f $nome, $_.Exception.Message) "AVISO"
    }
}

function Carregar-CalibragemEtapas {
    $arq = Get-CaminhoCalibragemEtapas
    if (-not (Test-Path -LiteralPath $arq)) {
        Escrever-Log "CALIBRAGEM por etapa: sem historico ainda - a primeira fila usa os tempos medidos de fabrica" "PROVA"
        return
    }
    $porEtapa = @{}
    try {
        $inv = [System.Globalization.CultureInfo]::InvariantCulture
        foreach ($l in [System.IO.File]::ReadAllLines($arq)) {
            $c = "$l" -split "`t"
            if ($c.Count -lt 5) { continue }
            $nome = "$($c[1])"
            $f = 0.0
            if (-not [double]::TryParse($c[4], [System.Globalization.NumberStyles]::Float, $inv, [ref]$f)) { continue }
            if ($f -lt $script:FatorEtapaMin -or $f -gt $script:FatorEtapaMax) { continue }
            if (-not $porEtapa.ContainsKey($nome)) { $porEtapa[$nome] = @() }
            $porEtapa[$nome] += $f
        }
    } catch {
        Escrever-Log ("CALIBRAGEM por etapa: nao consegui ler o historico - {0}. Usando os tempos de fabrica." -f $_.Exception.Message) "AVISO"
        return
    }
    $ditos = @()
    for ($i = 0; $i -lt 5; $i++) {
        $nome = $script:NomeEtapaCalib[$i]
        if (-not $porEtapa.ContainsKey($nome)) { continue }
        $ult = @($porEtapa[$nome] | Select-Object -Last 5)
        if ($ult.Count -lt 1) { continue }
        $f = Get-Percentil ([double[]]$ult) 0.75
        if ($f -lt $script:FatorEtapaMin -or $f -gt $script:FatorEtapaMax) { continue }
        $script:FatorEtapa[$i] = $f
        $ditos += ("{0} {1:N2}x ({2} medida(s))" -f $nome, $f, $ult.Count)
    }
    if ($ditos.Count -gt 0) {
        Escrever-Log ("CALIBRAGEM por etapa: {0}" -f ($ditos -join " | ")) "PROVA"
    } else {
        Escrever-Log "CALIBRAGEM por etapa: historico existe mas nenhuma medida passou nos limites - usando os tempos de fabrica" "AVISO"
    }
}

function Carregar-Calibragem {
    <#  16.99: le o historico e passa a estimativa a usar o P75 das ultimas
        cinco rodadas.

        Cinco porque e o suficiente para o numero parar de pular a cada
        conversao e pouco o bastante para acompanhar uma mudanca real (disco
        novo, maquina nova). P75 e nao media nem mediana: o porque esta
        medido no bloco do Get-Percentil, logo abaixo. (Ate a 17.19 estas
        linhas diziam "mediana", que e o que esta funcao NAO faz.)

        Arquivo ausente, ilegivel ou sem linha valida NAO e erro: e a
        primeira execucao, e o valor de partida vale. Ninguem fica sem
        estimativa por falta de historico. #>
    $script:SegPorGbPorPeso = $script:SegPorGbPorPesoPadrao
    $script:CalibUsadas = @()
    $arq = Get-CaminhoCalibragem
    if (-not (Test-Path -LiteralPath $arq)) {
        Escrever-Log ("CALIBRAGEM: sem historico ainda - usando o valor de partida {0:N4} s/GB/peso" -f $script:SegPorGbPorPeso) "INFO"
        return
    }
    $vals = @()
    try {
        foreach ($l in [System.IO.File]::ReadAllLines($arq, [System.Text.Encoding]::UTF8)) {
            if ("$l" -eq "" -or "$l".StartsWith("#")) { continue }
            $c = "$l" -split "`t"
            if ($c.Count -lt 6) { continue }
            $x = 0.0
            if ([double]::TryParse($c[5], [System.Globalization.NumberStyles]::Float,
                                   [System.Globalization.CultureInfo]::InvariantCulture, [ref]$x)) {
                if ($x -ge $script:CalibMin -and $x -le $script:CalibMax) { $vals += $x }
            }
        }
    } catch {
        Escrever-Log ("CALIBRAGEM: nao consegui ler o historico ({0}) - usando o valor de partida" -f $_.Exception.Message) "AVISO"
        return
    }
    if ($vals.Count -eq 0) {
        Escrever-Log ("CALIBRAGEM: historico sem linha aproveitavel - usando o valor de partida {0:N4}" -f $script:SegPorGbPorPeso) "AVISO"
        return
    }
    $ult = @($vals | Select-Object -Last 5)
    $script:CalibUsadas = $ult
    <#  16.99 - POR QUE p75 E NAO A MEDIANA (medido, nao escolhido no gosto).

        Rodei as quatro opcoes contra os tres filmes que temos com previsto e
        real anotados (Troy, Se7en, Spider-Man):

          fixo 0,0153   erro medio 33,8%   pior 55,5%   subestima 0 de 3
          mediana       erro medio 11,6%   pior 22,9%   subestima 1 (-23%)
          p75           erro medio 18,3%   pior 28,6%   subestima 1 (-11%)
          maximo        erro medio 25,0%   pior 45,3%   subestima 0 de 3

        A mediana e a mais exata NA MEDIA e e a que erra pior no unico lugar
        onde errar dói: ela prometeria ao Spider-Man 23% MENOS tempo do que
        ele leva. Este projeto ja decidiu que subestimar e pior que
        superestimar - prometer um tempo que nao vai ser cumprido e mensagem
        que mente, e mensagem que mente e defeito (licao 2).

        p75 fica no meio: corta o erro medio quase pela metade em relacao ao
        fixo e reduz a subestimacao de 23% para 11%. E a escolha que respeita
        a regra sem jogar fora o ganho.

        O QUE ISTO NAO RESOLVE, e esta escrito para nao virar promessa: os
        tres filmes sao da MESMA maquina e mesmo assim se espalham de 0,0098 a
        0,0143. Ou seja, boa parte do erro nao e da maquina - e do MODELO DE
        PESOS, que descreve os tres filmes com a mesma forma. A calibragem
        mata o erro sistematico (maquina, disco); a variacao entre filmes so
        sai revisando os pesos. Quando o espalhamento for grande, o log diz
        isso em vez de deixar parecer que a calibragem resolveu tudo. #>
    $k = Get-Percentil ([double[]]$ult) 0.75
    if ($k -lt $script:CalibMin -or $k -gt $script:CalibMax) {
        Escrever-Log ("CALIBRAGEM: valor calculado {0:N4} fora dos limites - usando o valor de partida" -f $k) "AVISO"
        return
    }
    $script:SegPorGbPorPeso = $k
    $lista = (($ult | ForEach-Object { "{0:N4}" -f $_ }) -join ", ")
    $dif = 0.0
    if ($script:SegPorGbPorPesoPadrao -gt 0) {
        $dif = (($k - $script:SegPorGbPorPesoPadrao) / $script:SegPorGbPorPesoPadrao) * 100.0
    }
    Escrever-Log ("CALIBRAGEM: {0} rodada(s) no historico, usando o p75 das ultimas {1}: {2:N4} s/GB/peso ({3:+0.0;-0.0;0}% do valor de partida) | amostras: {4}" -f `
                  $vals.Count, $ult.Count, $k, $dif, $lista) "PROVA"
    if ($ult.Count -ge 3) {
        $mn = ($ult | Measure-Object -Minimum).Minimum
        $mx = ($ult | Measure-Object -Maximum).Maximum
        if ($mn -gt 0 -and (($mx - $mn) / $mn) -gt 0.30) {
            <#  2.0: o aviso continua, porque o espalhamento e real e e uma
                informacao. O que mudou e o que ele promete: ate a 1.11 ele
                dizia que a estimativa ia continuar errando "ate os pesos
                serem revistos", sem dizer que a calibragem que ele estava
                relatando nao tinha efeito nenhum (licao 49). Agora quem
                corrige e o fator POR ETAPA, e este numero aqui e historico. #>
            Escrever-Log ("CALIBRAGEM (historica, por arquivo): as rodadas se espalham {0:N0}% entre si ({1:N4} a {2:N4}) - filmes de formas diferentes descritos pelo mesmo escalar. Quem corrige isso agora e o fator por etapa, acima." -f `
                          ((($mx - $mn) / $mn) * 100.0), $mn, $mx) "AVISO"
        }
    }
}

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
<#  19.6: a leitura de 72 MB roda na thread da tela. Ela nao sai de la
    (o numero e usado na hora do clique), mas nao precisa ser repetida: o
    mesmo arquivo na mesma sessao devolve a medida guardada. #>
$script:CacheVelocidade = @{}
function Measure-VelocidadeOrigem([string]$Arquivo) {
    if ([string]::IsNullOrWhiteSpace($Arquivo)) { return 0.0 }
    $chaveVel = $Arquivo.ToLowerInvariant()
    if ($script:CacheVelocidade.ContainsKey($chaveVel)) { $script:AmostrasDisco = @([double]$script:CacheVelocidade[$chaveVel]); return [double]$script:CacheVelocidade[$chaveVel] }
    $medida = Measure-VelocidadeOrigemReal $Arquivo
    if ($medida -gt 0) { $script:CacheVelocidade[$chaveVel] = $medida }
    return $medida
}
function Measure-VelocidadeOrigemReal([string]$Arquivo) {
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
<#  17.17 - DUAS FUNCOES COM O MESMO NOME, E A ERRADA ESTAVA GANHANDO.

    Achado por um teste sintetico (secao 46), montado justamente porque o
    Diego nao ia refazer o roteiro na mao. O teste carregou "Get-FatorDisco"
    do fonte e recebeu o fator errado - e o motivo e que existiam DUAS
    funcoes com esse nome neste arquivo:

      esta aqui        - fator de VELOCIDADE do disco (referencia/medido,
                         preso entre 1 e 8), usada na estimativa de TEMPO;
      a da 16.95       - fator de ESPACO (1,6x ou 3,15x), usada no painel
                         de disco, e que recebe o video como parametro.

    Em PowerShell a ULTIMA definicao vence. A de espaco e definida depois,
    entao era ELA que existia em runtime - inclusive para as duas chamadas
    aqui de cima, que passam argumento NENHUM. Sem video para olhar, ela caia
    no ramo "nao tem seta na coluna" e devolvia 1,6. Sempre 1,6.

    A PROVA esta nos logs do Diego, e e obvia depois de vista:

      origem le a 10.715 MB/s (referencia 445) -> fator 1,60x
      origem le a  7.601 MB/s (referencia 445) -> fator 1,60x

    Com a funcao certa, qualquer leitura acima de 445 MB/s da fator 1,00 (o
    piso). 1,60 e um numero que esta funcao nao consegue produzir - ele so
    podia estar vindo de outro lugar. Nos logs anteriores a 16.95, quando so
    existia uma funcao com esse nome, a mesma linha imprimia 1,00x.

    Ou seja: desde a 16.95 a estimativa de tempo ignorava a velocidade do
    disco e usava uma constante disfarcada. E isso alimentou o espalhamento
    de 170% que a propria calibragem vinha denunciando no arranque.

    O nome era a armadilha inteira. Agora cada uma se chama pelo que mede. #>
function Get-FatorVelocidadeDisco {
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
    $fixo5 = if ($pl.Dovi) { $T.RemontagemExtraidoSegFixo } else { $T.RemontagemSegFixo }
    $s5 = ($fixo5 + $Gb * $porGb) * (Get-FatorDaEtapa "Remontagem")

    <#  2.0: e aqui, no fim, entra a calibragem POR ETAPA - o que esta maquina
        provou, medida contra medida, sobre cada um dos cinco trabalhos. Ela
        multiplica os SEGUNDOS, que e o unico lugar onde ela nao se anula (ver
        o bloco da licao 49). Tudo que vem depois - peso, regua, barra, tempo
        restante - herda a correcao de graca, porque tudo depois deriva daqui. #>
    $bruto = @($s1, $s2, $s3, $s4, $s5)
    $saida = @()
    for ($i = 0; $i -lt $bruto.Count; $i++) {
        $f = 1.0
        if ($i -lt @($script:FatorEtapa).Count) { $f = [double]$script:FatorEtapa[$i] }
        if ($f -le 0) { $f = 1.0 }
        $saida += ([double]$bruto[$i] * $f)
    }
    return ,$saida
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
                          $script:MbPorSegMedido, $script:MbPorSegReferencia, (Get-FatorVelocidadeDisco), $txtAm) "PROVA"
        } else {
            Escrever-Log "DISCO: nao consegui medir a velocidade da origem - estimando como se fosse o disco de referencia" "AVISO"
        }
    }
    foreach ($v in $marcados) {
        <#  2.0.10: arquivo que sumiu da pasta NAO entra no lote. O motor ja o
            deixava de fora (Get-Item falha), mas o lote da tela ficava com ele
            - e o "ARQUIVO n/N" do motor e uma POSICAO: com o primeiro sumido,
            o segundo filme recebia a estimativa, os pesos e a calibragem do
            primeiro. Tirando aqui, as duas listas tem o mesmo tamanho. #>
        if (-not (Test-Path -LiteralPath "$($v.Caminho)")) {
            Escrever-Log ("LOTE: '{0}' nao existe mais na pasta - fica fora desta fila (clique em Atualizar para reler)" -f $v.Nome) "AVISO"
            continue
        }
        $gb = [double]$v.Bytes / 1GB
        $min = 0.0
        if ($v.DurSeg) { $min = [double]$v.DurSeg / 60.0 }
        $segs  = Get-SegundosDasEtapas $v $gb $min
        $pesos = Get-PesosDoVideo $v $gb $min
        $soma  = 0.0
        foreach ($p in $pesos) { $soma += [double]$p }
        <#  2.0: a estimativa e a SOMA DOS SEGUNDOS previstos, que ja vem
            calibrados por etapa. A conta antiga (Gb * soma-de-pesos * k) dava
            exatamente este mesmo numero - com a diferenca de que ela passava
            por uma constante que se anulava e fazia todo mundo, eu inclusive,
            acreditar que havia auto-correcao. Ver a licao 49. #>
        $est = 0.0
        foreach ($sg in @($segs)) { $est += [double]$sg }
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
        # 16.99: Gb e SomaPesos viajam junto porque sao exatamente o que a
        # calibragem precisa quando este arquivo terminar. Sem eles, a conta
        # teria que ser refeita do zero na hora do fim - e refazer conta e
        # como as duas contas do disco divergiram.
        $lote += @{ Caminho = $v.Caminho; Nome = $v.Nome; Pesos = $pesos; SegEstimado = $est
                    SegEtapas = @($segs); Gb = $gb; SomaPesos = $soma }
    }
    # Sem return: a atribuicao direta nao passa pelo pipeline, entao nao ha
    # desmonte (o problema da 16.3) nem aninhamento (o problema da 16.4).
    $script:LoteAtual = $lote
}

function Start-Motor {
    Stop-Motor
    $descarte = $null
    # 19.6: esvaziar sem olhar jogava fora o el_fim/censo_fim - a unica
    # mensagem que fecha o runspace (mesmo defeito que a 18.08 tirou do
    # Start-Leitura). Sobra do MOTOR velho sai; mensagem de medicao/censo
    # volta para a fila - o portao do tick ja filtra rodada velha pelo numero
    # de serie, e o censo_fim tardio ainda entrega o resultado (regra 18.05).
    $guardar = New-Object System.Collections.ArrayList
    while ($script:FilaMsg.TryDequeue([ref]$descarte)) {
        if ("$($descarte.T)" -match '^(el|el_ini|el_fim|censo_fim)$') { [void]$guardar.Add($descarte) }
    }
    foreach ($g in $guardar) { $script:FilaMsg.Enqueue($g) }
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
    # 2.0.7: o censo feito na janela vai junto - quem escreve o veredicto do
    # arquivo e o motor, e ele precisa do numero do filme inteiro.
    $censos = @{}
    # 2.0.7b: @() em cima da List[object] estoura "Os tipos de argumento nao
    # correspondem" (PowerShell 5.1 e 7) - derrubou o Iniciar. Enumera direto.
    foreach ($vc in $script:Videos) {
        if ([bool]$vc.CensoFeito -and [int]$vc.CensoCenas -gt 0) {
            $censos["$($vc.Caminho)"] = @{ Cenas = [int]$vc.CensoCenas; Acima = [int]$vc.CensoAcima
                                          Pct = [double]$vc.ELpctAcima; Pico = [double]$vc.CensoPico }
        }
    }
    $null = $ps.AddArgument($censos)
    Escrever-Log ("CENSO enviado ao motor: {0} arquivo(s)" -f $censos.Count) "PROVA"
    $qtd = 0
    if ($script:EscolhasAtuais) { $qtd = @($script:EscolhasAtuais.Keys).Count }
    Escrever-Log ("ESCOLHAS enviadas ao runspace por parametro: {0} arquivo(s)" -f $qtd) "PROVA"
    $script:MotorRunspace = $rs
    $script:MotorPS = $ps
    $script:MotorHandle = $ps.BeginInvoke()
    Escrever-Log "Runspace do motor criado e disparado" "MOTOR"
}

function Fechar-MedicaoPendente {
    <#  16.79 - "MEDINDO" NAO PODE FICAR PRESO NA TELA.

        BUG MEDIDO no log do Diego (18:49:57 -> 18:50:01): a fase B comecou a
        medir, ele clicou Iniciar 3 segundos depois, o Iniciar derrubou o
        runspace da leitura - e o "el_fim" nunca chegou. Resultado: a linha do
        Dolby Vision ficou escrita "medindo a camada de melhoria..." durante a
        CONVERSAO INTEIRA, e depois dela. A tela travada numa frase que nao era
        mais verdade, que e a pior classe de bug deste projeto.

        Toda saida da fase B passa por Stop-Motor, entao e aqui que o estado se
        fecha. Quem ficou sem medida NAO volta a ser verde: vira "EL nao
        medida", em ambar, que e o terceiro estado honesto - a mesma regra de
        sempre, nao medir nunca vira limpo. #>
    <#  17.20: este e o ponto unico por onde toda saida da fase B passa
        (Stop-Motor chama sempre). Se a medicao morreu no meio - Iniciar,
        troca de pasta, chave desligada - ninguem esta sendo medido, e a
        linha nao pode continuar acesa. #>
    <#  17.21 - FECHAR A MEDICAO E FECHAR TUDO, NAO SO A LINHA.

        BUG MEDIDO no log do Diego (15/09 20:33 e 20:36): ele apertou
        Iniciar com a fase B rodando, escolheu "comecar agora", e a barra de
        cima continuou escrita "Medindo MEL x FEL: 2 de 3" em CIANO durante a
        conversao inteira - com a medicao morta ha minutos. Print dele:
        "TA ROLANDO A CONVERSAO E TA FALANDO Q TA MEDINDO EM CIANO".

        A causa e a mesma licao da 17.20 cobrada um nivel acima: eu apaguei o
        estado de QUEM estava sendo medido ($ELmedindoIdx) e deixei de pe o
        estado de QUE EXISTE UMA MEDICAO ($MedindoEL, $ELtotal, $ELfeitos) -
        que e quem manda no rotulo, na cor e na barrinha da barra de cima.
        Matar o runspace nao apaga variavel nenhuma: o "el_fim", que era quem
        zerava isso, nunca chega quando a fase B morre no meio.

        Aqui e o ponto unico por onde TODA saida da fase B passa. Entao aqui
        o estado morre inteiro, e a tela e redesenhada - estado novo sem
        redesenho e tela mentindo. #>
    $script:ELmedindoIdx = -1
    $script:MedindoEL    = $false
    $script:ELtotal      = 0
    $script:ELfeitos     = 0
    Update-BotaoMedirEL
    if (-not $script:Videos) { return }
    $presos = 0
    foreach ($v in $script:Videos) {
        if ("$($v.ELtipo)" -ne "MEDINDO") { continue }
        $presos++
        $v.ELtipo = "NAO_MEDIDO"; $v.ELselo = "NAO MEDIDO"
        $v.ELmotivo = "a medicao foi interrompida antes de terminar"
        <#  17.21 - AQUI EU ESCREVIA OS TEXTOS A MAO, E ELES SAIAM DIFERENTES.

            Print do Diego (15/09): duas linhas da coluna DOLBY VISION
            mostravam "7.6 → 8.1" enquanto as vizinhas mostravam
            "P7 FEL → P8.1". Eram exatamente as duas cuja medicao eu tinha
            interrompido - e passavam por aqui, onde eu montava a coluna com
            os campos crus em vez de chamar quem sabe formatar. O rotulo e a
            resposta tambem eram copias congeladas, com "[dvhe.08.06]" fixo
            no texto.

            Update-TextosDV e o lugar unico que escreve as tres formas DO
            REGISTRO (16.84). Basta trocar o ELtipo e mandar ele reescrever:
            o "EL nao medida" sai da mesma regra que todos os outros casos. #>
        Update-TextosDV $v
    }
    if ($presos -gt 0) {
        Escrever-Log ("Medicao interrompida em {0} arquivo(s) - marcados como EL nao medida (nunca como limpa)" -f $presos) "LEITURA"
        Update-Diagnostico
    }
    <#  17.21: o Fill-Fila sai de dentro do "if" e passa a valer sempre. Com
        zero presos ainda pode haver uma linha pintada de ciano na tela - a
        do arquivo que estava na vez - e ela so despinta se alguem
        redesenhar. #>
    Fill-Fila "el"
}

function Stop-Motor {
    <#  18.00: Stop-Motor cuida do runspace da LEITURA e do MOTOR, e mais nada.
        Ate a 17.24 ele tambem fechava a medicao, porque ela morava dentro da
        leitura. Continuar fazendo isso agora seria pior que inutil: a medicao
        roda no runspace DELA, e apagar o estado dela daqui mataria na tela uma
        medicao que segue viva atras. Quem para a medicao e Stop-Medicao. #>
    if (-not $script:MotorPS) { return }
    $script:Controle.Cancelar = $true
    $script:Controle.Pausar = $false
    <#  18.00 - A ESPERA SAIU DAQUI, E ESSA E A LINHA QUE CONGELAVA A JANELA.

        Ate a 17.24 esta funcao fazia AsyncWaitHandle.WaitOne(1500) NA THREAD DA
        INTERFACE. Medido quatro vezes no log do Diego de 16/09: 1,52s / 1,93s /
        2,01s / 1,91s de janela sem responder. Era o "travou tudo" dele, e nao
        era figura de linguagem - a thread que desenha estava parada.

        A espera existia para garantir que o runspace velho estivesse morto
        antes de o novo nascer, senao uma mensagem atrasada dele cairia na fila
        nova. Esse problema agora tem solucao melhor e de graca: o NUMERO DE
        SERIE. Mensagem de rodada velha e ignorada no portao do laco, e o
        runspace morre sozinho, no tempo dele, sem ninguem esperando por ele.

        Stop() e Dispose() abaixo nao bloqueiam: pedem o encerramento e voltam. #>
    try { $script:MotorPS.Stop() } catch { }
    try { $script:MotorPS.Dispose() } catch { }
    try { $script:MotorRunspace.Close() } catch { }
    try { $script:MotorRunspace.Dispose() } catch { }
    $script:MotorPS = $null; $script:MotorRunspace = $null; $script:MotorHandle = $null
    <#  17.24 - BUG QUE EU CRIEI NA 17.23, MEDIDO NO LOG DO DIEGO (16/09
        18:06:41 -> 18:08:27).

        $script:Lendo so voltava a $false num lugar: o handler "leitura_fim".
        Matar o runspace no meio da fase A significa que essa mensagem NUNCA
        chega - e a janela fica achando que esta lendo para sempre. O estrago
        aparece em dois lugares, e ele viu os dois:

          1. O botao Atualizar fica preso em "Parar leitura". Ele clicou 15
             vezes (18:07:16 a 18:08:27) e nada acontecia: o clique so escreve
             Cancelar num runspace que ja morreu.
          2. Start-Leitura comeca com "if ($script:Lendo) { reagenda; return }"
             - entao TROCAR DE PASTA parou de funcionar. Ele trocou tres vezes
             (18:07:42, 18:07:55, 18:08:24) e a fila nunca recarregou, ate
             ficar com 0 videos na tela.

        A licao e a da 17.21, de novo e um nivel acima: matar o runspace nao
        apaga variavel nenhuma. Quem derruba o runspace tem que desfazer o
        estado que o nascimento dele criou - AQUI, e nao no chamador, porque
        chamador novo esquece. Este e o ponto unico por onde todo encerramento
        passa. #>
    if ($script:Lendo) {
        $script:Lendo = $false
        try {
            $UI.btnReler.IsEnabled = $true
            Update-BotaoReler
        } catch { }
        Escrever-Log "LEITURA: encerrada junto com o runspace - a janela voltou ao estado de nao-lendo" "LEITURA"
    }
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
                    <!-- 17.03: os mesmos tres verbos na tela em ingles. O
                         DataTrigger casa com o TEXTO exibido, entao sem estes
                         a coluna ACAO perdia a cor ao trocar de lingua. -->
                    <DataTrigger Binding="{Binding}" Value="KEEP">
                      <Setter Property="Foreground" Value="$($Cores.foco)"/>
                      <Setter Property="Background" Value="#1A1A20"/>
                    </DataTrigger>
                    <DataTrigger Binding="{Binding}" Value="CONVERT">
                      <Setter Property="Foreground" Value="$($Cores.ok)"/>
                      <Setter Property="Background" Value="#1A1A20"/>
                      <Setter Property="FontWeight" Value="SemiBold"/>
                    </DataTrigger>
                    <DataTrigger Binding="{Binding}" Value="DROP">
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
          <StackPanel><TextBlock x:Name="icoIniciar" Text="$($Sim.Atual)" FontSize="17.5" HorizontalAlignment="Center"/><TextBlock Text="[F1] Iniciar" Margin="0,2,0,0"/></StackPanel>
        </Button>
        <Button x:Name="btnPausar" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock x:Name="icoPausar" Text="$($Sim.Pausa)" FontSize="15.5" HorizontalAlignment="Center"/><TextBlock x:Name="lblPausar" Text="[F2] Pausar" Margin="0,3,0,0"/></StackPanel>
        </Button>
        <Button x:Name="btnCancelar" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock Text="$($Sim.Err)" FontSize="15.5" HorizontalAlignment="Center"/><TextBlock Text="[ESC] Cancelar" Margin="0,3,0,0"/></StackPanel>
        </Button>
        <Border Width="1" Background="$($Cores.borda)" Margin="7,2"/>
        <!-- 16.45: era o botao que recolhia o bloco PASTAS - trabalho que o
             clique no proprio cabecalho ja fazia, e que some sozinho no F1.
             Um botao na barra principal para uma acao duplicada e opcional.
             Agora ele e o par do "Abrir Saída": abre a pasta de ORIGEM. -->
        <!-- 18.23 - A ORDEM DA BARRA, E AS DUAS TECLAS QUE FALTAVAM.

             "joga o botao Atualizar pra direita e traz o Abrir Saida pra
             esquerda... e [F3] Abrir Origem, [F4] Abrir Saida, padrao"
             (Diego, 17/09).

             ORIGEM e SAIDA sao um par - o de onde vem e o para onde vai - e
             tinham o Atualizar plantado no meio deles. Juntos, e na ordem em
             que o trabalho acontece, a barra le de um jeito so:

               [F1] [F2] [ESC] | [F3] Origem  [F4] Saida  [F5] Atualizar |
               [F11] Censo  [F12] Medir

             As teclas ficaram em ordem crescente da esquerda para a direita
             sem ninguem ter que forcar - foi so por os dois no lugar certo. -->
        <Button x:Name="btnAbrirOrigem" Focusable="False" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock Text="$($Sim.Pasta)" FontSize="16.5" HorizontalAlignment="Center"/><TextBlock x:Name="lblAbrirOrigem" Text="[F3] Abrir Origem" Margin="0,2,0,0"/></StackPanel>
        </Button>
        <Button x:Name="btnAbrirSaida" Focusable="False" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock Text="$($Sim.Disco)" FontSize="16.5" HorizontalAlignment="Center"/><TextBlock x:Name="lblAbrirSaida" Text="[F4] Abrir Saída" Margin="0,2,0,0"/></StackPanel>
        </Button>
        <Button x:Name="btnReler" Focusable="False" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock x:Name="icoReler" Text="&#8635;" FontSize="16.5" HorizontalAlignment="Center"/><TextBlock x:Name="lblReler" Text="[F5] Atualizar" Margin="0,2,0,0"/></StackPanel>
        </Button>
        <!-- 17.08: CENSO COMPLETO (item A). A medicao normal le uma amostra;
             este botao le o filme INTEIRO. Nasce DESLIGADO e so acende na
             linha onde a duvida existe - Complex FEL. Medido na bancada, ele
             custa ~5x a amostra (Ryan 109s x 22s), e e por isso que ele e um
             botao e nao um automatico: numa fila de dez filmes seriam vinte
             minutos parado antes de comecar a converter. -->
        <Button x:Name="btnCenso" Focusable="False" IsEnabled="False" ToolTipService.ShowOnDisabled="True" ToolTipService.InitialShowDelay="250" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock x:Name="icoCenso" Text="&#9673;" FontSize="16.5" HorizontalAlignment="Center"/><TextBlock x:Name="lblCenso" Text="[F11] Censo Completo" Margin="0,2,0,0"/></StackPanel>
        </Button>
        <!-- 17.15: a chave da medicao ganha um gemeo AQUI, do lado do Censo,
             a pedido do Diego. Os dois falam da mesma coisa (a camada de
             melhoria), e a de baixo continua onde estava: quem esta olhando a
             fila mexe nela ali, quem esta na barra mexe aqui. Um estado, dois
             lugares que o mostram - e um so lugar que o desenha
             (Update-BotaoMedirEL). -->
        <Button x:Name="btnMedirELTopo" Focusable="False" ToolTipService.ShowOnDisabled="True" ToolTipService.InitialShowDelay="250" Style="{StaticResource BtnBarra}">
          <StackPanel>
            <TextBlock x:Name="icoMedirELTopo" Text="&#9678;" FontSize="16.5" HorizontalAlignment="Center"/>
            <TextBlock x:Name="lblMedirELTopo" Text="[F12] Medir MEL x FEL" Margin="0,2,0,0"/>
            <!-- 17.16: a barrinha da medicao. Fica escondida (Collapsed)
                 quando nao ha medicao rodando - trilho vazio permanente
                 seria ruido, e a barra so existe para responder "esta indo
                 ou travou?". -->
            <Border x:Name="trilhoMedirEL" Height="3" Margin="0,3,0,0" CornerRadius="2"
                    Background="$($Cores.borda)" Visibility="Collapsed" HorizontalAlignment="Stretch">
              <Border x:Name="barraMedirEL" Height="3" CornerRadius="2" Width="0"
                      HorizontalAlignment="Left" Background="$($Cores.emCurso)"/>
            </Border>
          </StackPanel>
        </Button>
        <Button x:Name="btnFerramentas" Focusable="False" DockPanel.Dock="Right" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock Text="&#9881;" FontSize="16.5" HorizontalAlignment="Center"/><TextBlock Text="Ferramentas" Margin="0,2,0,0"/></StackPanel>
        </Button>
        <Button x:Name="btnLog" Focusable="False" DockPanel.Dock="Right" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock Text="&#9776;" FontSize="16.5" HorizontalAlignment="Center"/><TextBlock Text="Log" Margin="0,2,0,0"/></StackPanel>
        </Button>
        <!-- 16.88: ENTENDA. O programa decide muita coisa sozinho e explicava
             cada decisao em uma linha de tela, que e onde nao cabe explicacao.
             Este botao abre o texto inteiro, para quem quiser saber POR QUE.
             Fica ao lado de Log e Ferramentas: os tres sao "abrir e ler". -->
        <Button x:Name="btnEntenda" Focusable="False" DockPanel.Dock="Right" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock Text="&#8505;" FontSize="16.5" HorizontalAlignment="Center"/><TextBlock x:Name="lblEntenda" Text="Entenda" Margin="0,2,0,0"/></StackPanel>
        </Button>
        <!-- 16.92: o idioma. Uma bandeira, um clique. O texto vive em
             IDIOMA_EN.txt, fora do .ps1 - traduzir nao e mexer em codigo. -->
        <Button x:Name="btnIdioma" Focusable="False" DockPanel.Dock="Right" Style="{StaticResource BtnBarra}">
          <StackPanel><TextBlock x:Name="lblBandeira" Text="&#127463;&#127479;" FontSize="16.5" HorizontalAlignment="Center"/><TextBlock x:Name="lblIdioma" Text="Português" Margin="0,2,0,0"/></StackPanel>
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
              <TextBlock Text="ETAPA" Margin="0,0,4,0" Foreground="{StaticResource CorMarca}" FontSize="12"/>
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
              <TextBlock Text="VÍDEO" Margin="0,0,4,0" Foreground="{StaticResource CorMarca}" FontSize="12"/>
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
            <TextBlock Text="FILA" Margin="0,0,4,0" Foreground="{StaticResource CorMarca}" FontSize="12"/>
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
                       ToolTip="Clique para escolher a pasta de SAÍDA."/>
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
              <TextBlock Text="FERRAMENTAS DISPONÍVEIS:" Style="{StaticResource Cabecalho}"/>
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
          <!-- 17.11: enquanto o Iniciar espera a medicao, a tela tem que
               dizer POR QUE ele esta apagado. Botao desabilitado sem motivo
               escrito e a mesma familia de defeito do "abre e fecha". -->
          <!-- 17.13: o aviso competia de igual para igual com um nome de
               release de 70 caracteres, no mesmo tamanho e no mesmo peso.
               Agora ele e maior, em negrito, com um ponto ambar na frente -
               e o nome sai da linha enquanto ele estiver visivel. -->
          <Border x:Name="avisoEspera" Background="#231A05" BorderBrush="$($Cores.warn)"
                  BorderThickness="1" CornerRadius="4" Padding="10,3" Margin="14,3,0,0"
                  Visibility="Collapsed">
            <StackPanel Orientation="Horizontal">
              <TextBlock Text="&#9679;" FontSize="13" FontWeight="Bold" Margin="0,0,7,0"
                         Foreground="$($Cores.warn)" VerticalAlignment="Center"/>
              <TextBlock x:Name="lblEsperandoMedida" FontSize="13.5" FontWeight="SemiBold"
                         Foreground="$($Cores.warn)" VerticalAlignment="Center"
                         Text="Esperando a medição terminar para começar..."/>
            </StackPanel>
          </Border>
          <Border x:Name="btnModoVideo" Background="Transparent" BorderBrush="$($Cores.borda)"
                  BorderThickness="1" CornerRadius="4" Padding="10,3" Margin="14,4,0,0" Cursor="Hand"
                  Visibility="Collapsed">
            <TextBlock x:Name="txtModoVideo" Text="Modo: Automático" FontSize="12.5" Foreground="$($Cores.txt)"/>
          </Border>
          <!-- 17.10: a chave da medicao de camada. Fica aqui, e nao na barra
               de cima, porque ela muda o que a LEITURA faz - e a leitura e o
               que enche esta lista. Desligada, a borda fica ambar: a cor da
               duvida, que e exatamente o que o arquivo passa a ter. -->
          <Border x:Name="btnMedirEL" Background="Transparent" BorderBrush="$($Cores.borda)"
                  BorderThickness="1" CornerRadius="4" Padding="10,3" Margin="14,4,0,0" Cursor="Hand">
            <TextBlock x:Name="txtMedirEL" Text="Medir MEL x FEL: Ligado" FontSize="12.5" Foreground="$($Cores.txt)"/>
          </Border>
        </StackPanel>

      <ListView x:Name="lstFila" Grid.Row="1" Background="Transparent" BorderThickness="0" Margin="4,4,4,6"
                VirtualizingStackPanel.IsVirtualizing="False"
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
                          Tag="{Binding Caminho}" VerticalAlignment="Center" HorizontalAlignment="Center" Margin="0"
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
                  <TextBlock x:Name="lblNovaConversao" Text="&#8635; Nova Conversão" FontSize="14"/>
                </Button>
                <Button x:Name="btnEncerrar" Style="{StaticResource BtnAcao}" Background="$($Cores.errFundo)" BorderBrush="$($Cores.errBorda)">
                  <TextBlock x:Name="lblEncerrar" Text="&#9211; Encerrar Programa" FontSize="14" Foreground="{StaticResource CorErr}"/>
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
$script:AssinaturaFila = $null   # 18.12: o que a fila mostrava da ultima vez
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
                       $Caminho="",
                       $FundoDV="Transparent",$BordaDV="Transparent",$FundoAudio="Transparent",$BordaAudio="Transparent",
                       $FundoLeg="Transparent",$BordaLeg="Transparent",$SeloManual="",$CorSelo="Transparent") {
    [PSCustomObject]@{ Nome=$Nome; Tamanho=$Tam; DV=$DV; Audio=$Audio; Legenda=$Leg
                       Situacao=$Sit; CorNome=$CorNome; CorDV=$CorDV; CorAudio=$CorAudio
                       CorLegenda=$CorLeg; CorSituacao=$CorSit; Peso=$Peso
                       Idx=$Idx; Marcado=$Marcado; PodeMarcar=$PodeMarcar; Caminho=$Caminho
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
<#  17.15 - A LEGENDA DO ARQUIVO FINAL E O CONJUNTO, NAO UMA FAIXA.

    O Diego, no Se7en: excluiu a .SRT antiga (feita por OCR numa rodada
    anterior) e mandou CONVERTER a PGS, para gerar uma nova. Intencao clara:
    trocar a legenda. A tela respondeu "[ESCOLHA MANUAL] Sem Legenda PT-BR no
    Arquivo Final" - e ele reagiu certo: "nao sei nem pq existe essa frase,
    no caso nem vai acontecer isso".

    Nao ia mesmo. O que foi mandado ao motor estava CERTO (log 01:17:33/34:
    id 2 -> CONVERTER, id 3 -> EXCLUIR; a porta manual envia LegendaPgs = 2 e
    tira o id 3 do LegendaManter). Errado era so o texto: esta funcao olhava
    UMA faixa - a de papel leg-ptbr - e dava o veredicto do arquivo inteiro a
    partir dela. Com a PGS redundante ganhando papel proprio na 17.14, "a
    faixa" deixou de ser uma so.

    Agora ela olha TODAS as candidatas a legenda pt-BR e decide na ordem em
    que o arquivo final fica: se alguma vai ser CONVERTIDA, o final tem
    legenda nova; senao, se alguma fica, o final tem a que ficou; so quando
    nao sobra nenhuma e que a frase vermelha e verdade. #>
function Get-DiagLegendaComEscolha($v) {
    if ("$($v.Modo)" -ne "Manual") { return $null }
    $cand = @(@($v.Faixas) | Where-Object { "$($_.Papel)" -eq "leg-ptbr" -or "$($_.Papel)" -eq "leg-pgs-extra" })
    if ($cand.Count -eq 0) { return $null }
    if (-not (@($cand | Where-Object { Test-TemEscolha $_ }).Count -gt 0)) { return $null }

    # O verbo EFETIVO de cada faixa: a escolha do usuario quando existe, o do
    # motor quando nao existe. Ler so o VerboUsuario esconderia a metade do
    # quadro que o usuario nao tocou.
    $conv   = @($cand | Where-Object { $(if (Test-TemEscolha $_) { "$($_.VerboUsuario)" } else { "$($_.VerboAuto)" }) -eq "CONVERTER" })
    $manter = @($cand | Where-Object { $(if (Test-TemEscolha $_) { "$($_.VerboUsuario)" } else { "$($_.VerboAuto)" }) -eq "MANTER" })

    if ($conv.Count -gt 0) {
        $cod = Get-CodecCurto $conv[0]
        # Trocou uma legenda pela outra: dizer so "$cod -> .SRT" esconderia
        # que a antiga saiu, que foi o pedido inteiro dele.
        if ($manter.Count -eq 0 -and $cand.Count -gt 1) {
            return @("→ [ESCOLHA MANUAL] $cod → .SRT a Pedido - a Legenda Anterior Foi Descartada", "verde")
        }
        return @("→ [ESCOLHA MANUAL] $cod → .SRT a Pedido", "verde")
    }
    if ($manter.Count -gt 0) {
        $cod = Get-CodecCurto $manter[0]
        return @("→ [ESCOLHA MANUAL] $cod Mantida a Pedido - Conversão Desligada", "cinza")
    }
    return @("→ [ESCOLHA MANUAL] Sem Legenda PT-BR no Arquivo Final", "vermelho")
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
    <#  18.06: a partir daqui e ate o WPF terminar de desenhar, qualquer evento
        de caixinha e ECO DO DESENHO, nao clique de gente. A porta e fechada
        agora e reaberta pelo proprio Dispatcher quando o desenho acabar - sem
        esperar nada (BeginInvoke), que a regra da 18.00 continua valendo. #>
    <#  18.12 - REPINTURA IDENTICA NAO E REPINTURA, E RUIDO.

        MEDIDO nos logs dele de 15 a 17/09: 1.588 linhas "FILA: N video(s) ...",
        e 133 delas sao repinturas IGUAIS a anterior, coladas - tres seguidas
        para uma acao so (17/09 11:43:03,065/,072/,077). Cada repintura faz
        Clear() na colecao inteira e monta tudo de novo, e e exatamente isso
        que dispara evento de caixinha e de selecao sem ninguem ter clicado -
        o defeito da 18.06 e o da 18.11 nasceram os dois dai.

        Agora as linhas sao montadas numa lista a parte e COMPARADAS com o que
        ja esta na tela. Se nada mudou, a tela nao e tocada: zero Clear(), zero
        evento, zero pisca. O que sobra no log e repintura de verdade. #>
    $novas = New-Object System.Collections.Generic.List[object]
    $primeiroAtivo = $true
    # 17.18: uma consulta por redesenho, nao uma por linha - a lista nao pode
    # dizer "2 de 3" numa linha e "3 de 3" na de baixo do mesmo desenho.
    $medindoAgora = Get-MedicaoEmCurso
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
            # 17.01: este ramo tem rotulo proprio e nao passava pela traducao -
            # era o "Já Convertido" que ficava em portugues na tela em ingles.
            $rotulo = Traduzir-Frase $(switch ("$($v.MotivoIgnorar)") {
                "Já Existe na Saída" { "Já Convertido" }
                "Erro na Leitura"    { "$($Sim.Err) Não Foi Possível Ler" }
                default              { "$($Sim.Warn) $($v.MotivoIgnorar)" }
            })
            $corRotulo = switch ("$($v.MotivoIgnorar)") {
                "Já Existe na Saída" { $Cores.dim2 }
                "Erro na Leitura"    { $Cores.err }
                default              { $Cores.warn }
            }
            [void]$novas.Add((New-LinhaFila $v.Nome $v.TamanhoTxt `
                $v.ColDV $v.ColAudio $v.ColLegenda `
                $rotulo `
                $Cores.dim2 $Cores.dim2 $Cores.dim2 $Cores.dim2 $corRotulo "Normal" `
                $i $false $false "$($v.Caminho)"))
            continue
        }

        $est = $Normal
        $sit = Traduzir-Frase "Na Fila"; $corSit = $Cores.txt
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
            <#  17.20: ESTE RAMO SUBIU PARA CIMA DO "FORA DA FILA".

                A fase B mede TODOS os arquivos pendentes, marcados ou nao.
                Com o ramo do desmarcado vindo antes, um arquivo fora da fila
                sendo medido mostrava "Fora da Fila" em cinza - e o botao la
                em cima dizia "Medindo 2 de 3" sem nenhuma linha acesa. O
                mesmo defeito que esta secao inteira veio consertar.

                Medindo ganha de Fora da Fila porque uma coisa esta
                ACONTECENDO e a outra so descreve: assim que a medicao daquele
                arquivo acaba, a linha volta a dizer "Fora da Fila", e o
                checkbox - que e quem decide de verdade - nunca mudou. #>
        } elseif ($null -ne $medindoAgora -and $i -eq [int]$medindoAgora.Idx) {
            <#  17.19: casa por INDICE. Casar por nome errava em dois arquivos
                de mesmo nome, e o nome nem e necessario - o "el_ini" ja manda
                o indice, que e como a mensagem "el" sempre encontrou a linha. #>
            <#  17.18: ciano porque e a MESMA coisa que o "Convertendo" ciano -
                esta acontecendo agora, neste arquivo. Verde nao serve (verde e
                "ja e / vai ser"), cinza nao serve (cinza e ausencia). E a
                linha fica em destaque pelo mesmo motivo da 16.38: o que esta
                acontecendo agora nao pode ter o mesmo peso do que espera. #>
            $est = $Destaque
            $sit = "$($Sim.Atual) Medindo Camada · {0} de {1}" -f $medindoAgora.Posicao, $medindoAgora.Total
            $corSit = $Cores.emCurso
            <#  17.20 - O ARQUIVO QUE ESTA SENDO MEDIDO CONTINUA SENDO O
                PROXIMO A CONVERTER.

                Achado do Diego: com o arquivo 1 sendo medido, o rotulo verde
                "Proximo a Converter" aparecia no arquivo 2. Falso - o proximo
                a converter e o 1; ele so esta, tambem, sendo medido agora.

                Esta linha ocupa a vaga do "proximo" sem escrever a frase: a
                coluna so cabe um estado, e "esta acontecendo agora" ganha de
                "vai acontecer depois". Quem nao pode e a linha DE BAIXO herdar
                um rotulo que nao e dela.

                So consome se a vaga ainda estava livre: medindo o arquivo 2
                com o 1 ja medido, o verde fica no 1, que e o certo - e foi o
                que a foto das 19:37 mostrou funcionando. #>
            if ($primeiroAtivo -and $Estado.Atual -eq "inicial") { $primeiroAtivo = $false }
        } elseif (-not $v.Marcado) {
            <#  17.15 - "NA FILA" NUM ARQUIVO QUE NAO ESTA NA FILA.

                O Diego desmarcou o Saving e o Troy, deixou so o Se7en, deu F1
                - e os dois desmarcados continuaram escritos "Na Fila", na cor
                normal, enquanto o Se7en convertia. Ele mesmo desmontou a
                frase: "ele nao ta na Fila, ele nao vai converter, nao faz
                sentido... teria q ser outra informacao e em outra cor, cinza
                claro talvez, pq nao vai fazer nada".

                Estava certo dos dois lados. "Na Fila" era o texto de todo
                arquivo sem ramo proprio - e desmarcado nunca teve ramo. O
                checkbox e a unica coisa na tela que decide quem converte, e a
                coluna que se chama SITUACAO era justamente a que nao olhava
                para ele.

                Cinza apagado pelo mesmo motivo do "Ja Convertido": nao e
                alerta, nao e erro, nao e progresso - e ausencia. E esta linha
                nao disputa o "Proximo a Converter": quem nao entra na
                conversao nao pode ser o proximo dela. #>
            $sit = "Fora da Fila - Não Será Convertido"; $corSit = $Cores.dim2
        } elseif ($primeiroAtivo -and $Estado.Atual -eq "inicial") {
            <#  17.18: a condicao era "$Fase -eq 'inicial'" - o Fase e o MOTIVO
                do redesenho, nao o estado do programa. Redesenhar por causa da
                medicao (Fill-Fila "el") ou da troca de idioma (Fill-Fila
                "idioma") apagava o "Proximo a Converter" da tela, porque
                "el" nao e "inicial".
                Foi o que o Diego viu: "a primeira vez q ta lendo a primeira
                linha fica verde escrito proxima conversao, quando vai para
                proxima fica tudo em fila cinza". O rotulo nao sumia porque
                deixou de ser verdade - sumia porque a lista foi redesenhada
                por outro motivo.
                Quem responde "ja comecou a converter?" e o ESTADO. #>
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
        # 16.94: a coluna SITUACAO tambem e frase montada ("Convertendo ·
        # Etapa 3/5"), entao passa pelas regras de padrao como o resto.
        $sit = Traduzir-Frase $sit
        # m3c19: DV nao entra aqui - nao existe verbo manual pra faixa de video
        # (ela e sempre MANTER/SEM RECODIFICAR), a conversao de perfil e uma
        # etapa do motor, nao uma escolha de faixa. Audio e legenda sim.
        # m3c25: o texto do audio agora carrega canais e bitrate reais.
        $audioReal = Get-ColunaAudioReal $v
        $colAudio  = Get-ColunaAudioComEscolha $v $audioReal
        $colLeg    = Get-ColunaLegendaComEscolha $v $v.ColLegenda
        $colAudio = Traduzir-Frase $colAudio
        $colLeg   = Traduzir-Frase $colLeg
        # O aviso de JOC inferior vale so enquanto o automatico manda. Se ele
        # trocou o verbo no Manual, quem decide e a escolha dele.
        $avisoAudio = (Test-JocInferior $v) -and ($colAudio -eq $audioReal)
        <#  16.76: o chip do DV deixou de ser so "tem seta = verde".
            Verde quer dizer "converte e o resultado e o melhor possivel".
            Num FEL isso nao e verdade: a EL descartada carregava imagem e o
            L1 fica descrevendo BL+EL. Ambar e exatamente a cor que este
            programa ja usa para "vai acontecer, com perda que voce precisa
            saber". Nao medido tambem nao pode ser verde - verde e afirmacao. #>
        <#  16.94: chip e texto da coluna saem da MESMA funcao que pinta a
            sigla do diagnostico (Get-NomeCorEL). Antes o Complex FEL ficava
            vermelho no diagnostico e ambar na coluna - duas cores para o
            mesmo veredicto medido. #>
        $semEL      = ("$($v.ELtipo)" -eq "NAO_APLICAVEL" -or "$($v.ELtipo)" -eq "")
        $chipDV     = if ($v.ColDV -notmatch "→") { Get-ChipVazio }
                      elseif ($semEL) { Get-ChipVerde }
                      else { Get-ChipEL $v }
        $corDV      = if ($v.ColDV -notmatch "→") { Get-CorColuna $v.ColDV $false }
                      elseif ($semEL) { Get-CorColuna $v.ColDV $false }
                      else { Get-CorEL $v }
        $chipAudio  = if ($avisoAudio)         { Get-ChipAmbar }
                      elseif ($colAudio -match "→") { Get-ChipVerde }
                      else { Get-ChipVazio }
        $corAudio   = if ($avisoAudio) { $Cores.warn } else { Get-CorColuna $colAudio $false }
        # Mesma regra do DV e do audio: chip so onde ha seta (conversao real).
        $chipLeg    = if ($colLeg -match "→") { Get-ChipVerde } else { Get-ChipVazio }
        [void]$novas.Add((New-LinhaFila $v.Nome $v.TamanhoTxt $v.ColDV $colAudio $colLeg `
            $sit $est.Cor `
            $corDV `
            $corAudio `
            (Get-CorColuna $colLeg $false) `
            $corSit $est.Peso `
            $i ([bool]$v.Marcado) $true "$($v.Caminho)" `
            $chipDV.Fundo $chipDV.Borda $chipAudio.Fundo $chipAudio.Borda `
            $chipLeg.Fundo $chipLeg.Borda $seloManual $corSelo))
    }
    # Prova no log: quantos videos existem e quantas linhas foram parar na
    # tela. Se esses dois numeros divergirem, o defeito e aqui e nao no WPF.
    $assinatura = ($novas | ForEach-Object { ($_.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "|" }) -join "`n"
    if ($assinatura -eq $script:AssinaturaFila -and $script:LinhasFila.Count -eq $novas.Count) {
        Escrever-Log ("FILA: nada mudou na tela - repintura dispensada ({0} linha(s))" -f $novas.Count) "FILA"
        return
    }
    $script:AssinaturaFila = $assinatura

    <#  18.06: a partir daqui e ate o WPF terminar de desenhar, qualquer evento
        de caixinha e ECO DO DESENHO, nao clique de gente. A porta e fechada
        agora e reaberta pelo proprio Dispatcher quando o desenho acabar - sem
        esperar nada (BeginInvoke), que a regra da 18.00 continua valendo. #>
    $script:PintandoFila = $true
    try {
        $Janela.Dispatcher.BeginInvoke([System.Action]{ $script:PintandoFila = $false },
            [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null
    } catch { $script:PintandoFila = $false }
    $script:LinhasFila.Clear()
    foreach ($ln in $novas) { [void]$script:LinhasFila.Add($ln) }

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

function Update-TextosDV($v) {
    <#  16.84: escreve NO REGISTRO DO VIDEO as tres formas que a tela usa.
        Chamada na leitura (handler "video") e de novo quando a medicao chega
        (handler "el") - o mesmo caminho nos dois casos, para nao existir
        "o texto da leitura" e "o texto da medicao" divergindo. #>
    $fmt  = Format-DolbyVision -Perfil ([int]$v.DVperfil) -Level "$($v.DVlevel)" `
                               -Codec "$($v.DVcodec)" -Camadas "$($v.DVcamadas)" `
                               -ELtipo "$($v.ELtipo)"
    $alvo = Format-DolbyVision -Perfil 8 -Level "$($v.DVlevel)" -Alvo
    $v.DVtextoFaixa = $fmt.Faixa
    $v.DiagDVrot    = "Dolby VISION: $($fmt.Longo) [DETECTADO]"
    if ([int]$v.DVperfil -eq 8 -and "$($v.DVcamadas)" -notmatch "EL") {
        $v.DiagDVres = "→ [NÃO NECESSÁRIO] Já Está em Profile 8.1"
        $v.DiagDVcor = "cinza"
        $v.ColDV     = "$($fmt.Curto) OK"
        return
    }
    $v.ColDV = "$($fmt.Curto) → $($alvo.Curto)"
    # A frase de resposta e montada por quem tem a medida em maos (handler
    # "el"); aqui fica so o estado inicial, honesto para cada caso.
    if ("$($v.ELtipo)" -eq "MEDINDO") {
        $v.DiagDVres = "→ [SERÁ CONVERTIDO] $($alvo.Longo) — medindo a camada de melhoria (MEL x FEL)…"
        $v.DiagDVcor = "cinza"
    } elseif ("$($v.ELtipo)" -eq "NAO_MEDIDO") {
        $v.DiagDVres = "→ [SERÁ CONVERTIDO] $($alvo.Longo) — EL não medida"
        $v.DiagDVcor = "ambar"
    } elseif ("$($v.DiagDVres)" -eq "") {
        $v.DiagDVres = "→ [SERÁ CONVERTIDO] $($alvo.Longo)"
        $v.DiagDVcor = "verde"
    }
}

function Format-DolbyVision {
    <#  16.84 - UMA COISA, UM TEXTO. EM TODO LUGAR.

        O Diego cobra isto ha semanas, e estava certo: a MESMA informacao
        saia escrita de oito jeitos diferentes, cada um num canto da tela.
        A coluna dizia "7.6 FEL -> 8.1", o diagnostico dizia "Profile 7.6
        [dvhe.07.06] [BL+EL+RPU] [EL: FEL]", a aba Faixas nao dizia nada, e o
        resumo final dizia outra coisa ainda. Oito lugares montando string na
        mao e um deles sempre esquecido a cada mudanca.

        Agora quem escreve Dolby Vision na tela e SO esta funcao. Ela devolve
        as quatro formas que o programa precisa, todas derivadas dos mesmos
        campos, com o vocabulario oficial da Dolby:

          Codec   dvhe.07.06                      (o codec, seco)
          Curto   P7.6 FEL -> P8.1                (coluna da fila)
          Faixa   Dolby Vision, Version 1.0, dvhe.07.06, BL+EL+RPU [FEL]
                                                  (aba Faixas - a string do
                                                   MediaInfo, com a sigla que
                                                   o MediaInfo nao sabe dizer)
          Longo   Profile 7.6 [dvhe.07.06] [BL+EL+RPU] [EL: FEL]
                                                  (rotulo do diagnostico)

        A SIGLA APARECE EM TODAS AS QUATRO. Era a queixa principal: no MEL a
        tela escrevia "EL vazia - descarte sem perda" e nao dizia "MEL" em
        lugar nenhum da linha de resposta.

        Sobre acrescentar [FEL] / [MEL] na string do MediaInfo: nao e invencao.
        O MediaInfo escreve BL+EL+RPU identico nos dois casos porque le so a
        estrutura do container; quem sabe a diferenca e o dovi_tool, lendo o
        el_type do RPU - e foi ele que respondeu. A sigla entre colchetes
        marca que aquele pedaco veio da MEDICAO, nao do container.
    #>
    param(
        [int]$Perfil, [string]$Level, [string]$Codec, [string]$Camadas,
        [string]$ELtipo = "", [switch]$Alvo
    )
    if ($Alvo) {
        # O destino da conversao, sempre o mesmo: 8.1 de camada unica.
        return [PSCustomObject]@{
            Codec = "dvhe.08.{0:D2}" -f ([int]$Level)
            Curto = "P8.1"
            Faixa = "Dolby Vision, Version 1.0, dvhe.08.{0:D2}, BL+RPU, HDR10 compatible" -f ([int]$Level)
            Longo = "Profile 8.1 [dvhe.08.{0:D2}] [BL+RPU]" -f ([int]$Level)
        }
    }
    $cod = "$Codec"
    if ($cod -eq "") { $cod = "dvhe.{0:D2}.{1:D2}" -f $Perfil, ([int]$Level) }
    $cam = "$Camadas"; if ($cam -eq "") { $cam = "BL+RPU" }
    # A sigla so existe onde ela quer dizer alguma coisa: Profile 7 com EL.
    <#  18.00 - "MEDINDO" SAIU DAQUI (achado do Diego, 16/09).

        "P7 MEDINDO sempre impresso em todos, e pra estar assim so no que
        estiver fazendo, ne? Se o proximo ta na lista... outra palavra, muito
        ridiculo isso."

        Ele esta certo em tres niveis, e os tres importam:

        1. E MENTIRA para quem nao esta sendo medido. No print dele, Bloodsport
           E Minions mostravam "P7 medindo" - mas so o Bloodsport estava sendo
           medido; o Minions estava esperando a vez. A coluna SITUACAO dizia a
           verdade ao lado ("Medindo Camada - 1 de 2" x "Na Fila") enquanto esta
           dizia a mesma coisa para os dois.

        2. E REPETICAO. Quem esta sendo medido AGORA ja e dito pela coluna
           SITUACAO, em ciano, e pelo contador da barra de cima. Tres lugares
           para um fato so - e dois deles errados.

        3. E A PALAVRA ERRADA NO LUGAR ERRADO. Esta coluna carrega o VEREDICTO
           da camada (MEL / FEL / EL nao medida). "Medindo" nao e veredicto, e
           atividade: ele nao pertence a esta coluna em nenhum momento.

        Entao: enquanto nao ha veredicto, a coluna mostra so o que foi
        DETECTADO - "P7 -> P8.1" - e cala sobre a camada, porque ainda nao sabe.
        Calar e honesto; inventar atividade em linha parada nao e. Quando o
        veredicto chega, ele aparece: "P7 FEL -> P8.1".

        "EL nao medida" CONTINUA, porque aquilo e um veredicto de verdade - o
        terceiro estado honesto da 1.8: nao medir nunca vira "limpa". #>
    $sigla = ""
    switch ("$ELtipo") {
        "MEL"        { $sigla = "MEL" }
        "FEL"        { $sigla = "FEL" }
        "MISTO"      { $sigla = "MEL+FEL" }
        "NAO_MEDIDO" { $sigla = "EL não medida" }
        <#  18.09 - QUEM ESTA SENDO MEDIDO CONTINUA SEM VEREDICTO, E A COLUNA
            TEM QUE DIZER ISSO.

            Print dele, 17/09: com a medicao rodando, a coluna do Troy mostrava
            so "P7 -> P8.1" - sem uma palavra sobre a camada. A 18.00 tirou
            "medindo" daqui com razao (era atividade na coluna de VEREDICTO, e
            aparecia em quem nem tinha vez), mas eu deixei o buraco: sem sigla
            nenhuma, a linha parece um Profile 7 comum, do lado de outros que
            dizem "FEL" e "MEL".

            A verdade e simples: quem esta sendo medido AINDA NAO TEM
            VEREDICTO - entao mostra o mesmo que os outros sem veredicto. Quem
            avisa que o trabalho esta acontecendo e a coluna SITUACAO
            ("Medindo Camada - 1 de 1"), que e o lugar da atividade. #>
        "MEDINDO"    { $sigla = "EL não medida" }
    }
    <#  17.03 - "PERFIL 7.6" NAO EXISTE (achado do Diego, 09/09).

        A tela escrevia "P7.6" e "Profile 7.6". Na string dvhe.07.06 o 07 e
        o PERFIL e o 06 e o NIVEL - duas coisas separadas, e a Dolby nomeia
        os perfis so pelo primeiro numero: Profile 5, Profile 7, Profile 8.
        O unico "ponto" legitimo e o do Profile 8.1, e ali o 1 nao e nivel:
        e o bl_signal_compatibility_id (Profile 8 compativel com HDR10).

        Fonte: Dolby Vision Profiles and Levels, tabela de bitstream profile
        strings - "[Dolby_Vision_Profile_String].[Dolby_Vision_Level_ID]".

        O nivel nao se perde: ele continua visivel no codec, que aparece ao
        lado (dvhe.07.06). O que sai e a invencao de um nome de perfil que a
        Dolby nunca definiu. #>
    $curto = "P{0}" -f $Perfil
    if ($sigla -ne "") { $curto = "$curto $sigla" }
    $faixa = "Dolby Vision, Version 1.0, $cod, $cam"
    if ($sigla -ne "") { $faixa = "$faixa [$sigla]" }
    $longo = "Profile {0} [{1}] [{2}]" -f $Perfil, $cod, $cam
    if ($sigla -ne "") { $longo = "$longo [EL: $sigla]" }
    return [PSCustomObject]@{ Codec = $cod; Curto = $curto; Faixa = $faixa; Longo = $longo }
}

function Test-SaidaCompleta([string]$Caminho, [double]$BytesOrigem) {
    <#  16.79 - EXISTIR NAO E ESTAR PRONTO.

        BUG RELATADO: o PC do Diego reiniciou sozinho na etapa 5/5, bem no
        mkvmerge. Ao voltar, a janela disse "Ja Existe na Saida" e travou o
        arquivo - so que o que estava la era o .mkv PELA METADE que o mkvmerge
        nao terminou de escrever. O teste era um Test-Path: existe, logo esta
        convertido. Um arquivo truncado passava por pronto, e o usuario perdia
        o filme achando que ja tinha feito.

        O teste barato que separa os dois e o TAMANHO. Nestas conversoes a
        saida fica em ~94% do original (GOT 20,62 -> 19,48 GB; Troy 87,0 ->
        81,7 GB) porque o video, que e 90% do arquivo, e copiado sem
        recodificar. Mesmo descartando faixas de audio e legenda ela nao chega
        perto de 60%. Um mkvmerge interrompido, sim.

        Nao abre o arquivo: so pergunta o tamanho. Em duvida (origem sem
        tamanho conhecido), aceita - este teste existe para pegar o truncado
        obvio, nao para reprovar conversao legitima. #>
    if (-not (Test-Path -LiteralPath $Caminho)) { return $false }
    if ($BytesOrigem -le 0) { return $true }
    try {
        $b = (Get-Item -LiteralPath $Caminho -ErrorAction Stop).Length
    } catch { return $true }
    return ([double]$b -ge ([double]$BytesOrigem * 0.60))
}

# ---- Diagnostico do video selecionado --------------------------------------
function Update-JaExiste {
    # Reavalia so a marca "Ja Existe na Saida" - sem tocar no diagnostico,
    # que e caro (ffprobe + mkvmerge + MediaInfo por arquivo).
    $temSaida = $Cfg.Saida -and (Test-Path -LiteralPath $Cfg.Saida)
    foreach ($v in $script:Videos) {
        if ($v.MotivoIgnorar -eq "Já Existe na Saída") { $v.Ignorar = $false; $v.MotivoIgnorar = "" }
        if ($v.Ignorar) { continue }   # ignorado por outro motivo: nao mexer
        if ($temSaida) {
            $alvo = Join-Path $Cfg.Saida $v.Arquivo
            if (Test-SaidaCompleta $alvo ([double]$v.Bytes)) {
                $v.Ignorar = $true; $v.MotivoIgnorar = "Já Existe na Saída"
                continue
            }
            <#  16.82: existe na saida mas nao fecha o tamanho = restos de uma
                conversao interrompida (o PC do Diego reiniciou no mkvmerge).
                O video CONTINUA na fila, e o usuario fica sabendo por que -
                antes ele sumia da fila achando que ja estava pronto. Avisa
                uma vez por arquivo: esta funcao roda a cada troca de pasta
                de saida, e repetir a linha a cada clique vira ruido. #>
            if (Test-Path -LiteralPath $alvo) {
                if (-not $script:AvisouIncompleto) { $script:AvisouIncompleto = @{} }
                if (-not $script:AvisouIncompleto.ContainsKey($alvo)) {
                    $script:AvisouIncompleto[$alvo] = $true
                    Escrever-Log ("Ha um arquivo INCOMPLETO na saida para '{0}' (sobra de conversao interrompida) - o video continua na fila." -f $v.Arquivo) "AVISO"
                }
            }
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
        $UI.lblDiscoMsg.Text = "$($Sim.Err) " + (Traduzir "Pasta de Saída é a Mesma da Origem - o Arquivo Convertido Sobrescreveria o Original")
        $UI.lblDiscoMsg.Foreground = Pincel $Cores.err
        $UI.btnIniciar.IsEnabled = $false
        $Janela.Title = "$NOME_APP  ·  " + (Traduzir "Origem e Saída São a Mesma Pasta")
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
        Set-BotaoIniciar (($marcadosOk -gt 0) -and ($Estado.Atual -eq "inicial"))
        if ($Estado.Atual -eq "inicial") {
            # 17.01: este titulo tambem e montado - e era o que aparecia na
            # barra da janela do Diego, em portugues, com a tela em ingles.
            # 2.0.10: $ativos nao existia aqui - o titulo saia "Pronto para
            # Converter -  Vídeo(s) na Fila", sem o numero (print de 23/09),
            # por cima do titulo certo que o Update-Selecao tinha acabado de por.
            # Agora e a mesma frase e o mesmo numero do Update-Selecao.
            $Janela.Title = "$NOME_APP  ·  " + (Traduzir-Frase ("Pronto para Converter - {0} Vídeo(s) Selecionado(s)" -f $marcadosOk))
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
<#  17.03 - O VERBO DA COLUNA ACAO ERA DADO E TEXTO AO MESMO TEMPO.

    Achado do Diego (09/09, print): a tela inteira em ingles e a coluna ACAO
    continuava MANTER / CONVERTER / EXCLUIR.

    Nao era esquecimento. A palavra era usada para DUAS coisas: e o texto que
    aparece, e e a CHAVE que o XAML usa para escolher a cor
    (DataTrigger Value="MANTER"). Traduzir a palavra apagava as tres cores da
    coluna - por isso a varredura de traducao nunca encostou nela.

    O conserto e a mesma separacao que ja fizemos no Dolby Vision: uma coisa,
    um texto. O VALOR continua em portugues, invisivel, e a coluna passa a
    exibir um texto proprio, que traduz. Os DataTriggers ganharam os tres
    verbos em ingles ao lado dos tres em portugues, para que a cor funcione
    nas duas linguas.
#>
$script:VerbosEN = @{ "MANTER" = "KEEP"; "CONVERTER" = "CONVERT"; "EXCLUIR" = "DROP" }

function Get-VerboExibido([string]$Verbo) {
    if ($script:Lang -ne "EN") { return $Verbo }
    if ($script:VerbosEN.ContainsKey($Verbo)) { return $script:VerbosEN[$Verbo] }
    return $Verbo
}

function Get-VerboCanonico([string]$Texto) {
    # O caminho de volta: o que o usuario escolheu no dropdown vira sempre o
    # valor em portugues antes de tocar em qualquer decisao. Sem isto, uma
    # escolha feita com a tela em ingles gravaria "KEEP" em VerboUsuario e
    # nenhuma comparacao do programa reconheceria esse valor.
    foreach ($k in $script:VerbosEN.Keys) {
        if ($script:VerbosEN[$k] -eq $Texto) { return $k }
    }
    return $Texto
}

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
<#  17.16 - CONVERTER NUMA LEGENDA QUE NAO E PT-BR.

    Achado do Diego, 13/09: no Modo Manual ele conseguiu marcar CONVERTER na
    PGS de INGLES (faixa 5, 'SDH') do GOT. E o programa CONVERTEU. O log
    escreveu, sem pestanejar:

        Legenda PT-BR Encontrada na Faixa 5 'SDH'

    e o arquivo final saiu com uma legenda EM INGLES rotulada
    "Portugues (Brasil) [OCR]", marcada como padrao. Uma legenda inglesa se
    passando por brasileira - a mentira mais cara que esta tela ja contou,
    porque ela sobrevive ao programa e vai parar na TV.

    O programa converte legenda PT-BR. Isso nao e uma preferencia, e a
    definicao do que ele faz: o OCR usa dicionario pt-BR (1,3M palavras), o
    Corretor caca bloco alienigena comparando com portugues, o Reocr refaz
    fala curta em portugues. Apontar esse cano para uma faixa inglesa nao
    "converte ingles": produz uma legenda inglesa com carimbo errado.

    Entao o verbo simplesmente nao existe para ela. O dropdown de uma legenda
    que nao e a pt-BR escolhida oferece MANTER e EXCLUIR - que e tudo que o
    motor sabe fazer com ela. O motor tambem passou a recusar a ordem
    (14.54): duas trancas, porque esta e do tipo que estraga arquivo. #>
function Get-OpcoesVerbo($f) {
    # 17.03: o dropdown mostra na lingua da tela; quem le de volta e
    # Get-VerboCanonico, no TrocaVerbo.
    $ops = if ($f.Papel -eq "audio-principal") { @("MANTER", "CONVERTER") }
           elseif ($f.Tipo -eq "subtitles" -and -not (Test-EhLegendaPtBr $f)) { @("MANTER", "EXCLUIR") }
           else { @("MANTER", "CONVERTER", "EXCLUIR") }
    return @($ops | ForEach-Object { Get-VerboExibido $_ })
}

<#  17.16: quem e candidata a legenda pt-BR. Os papeis sao dados pela
    LEITURA (leg-ptbr = a que o motor escolheu; leg-pgs-extra = a PGS pt-BR
    redundante da 17.14), entao aqui nao se refaz criterio nenhum - so se
    pergunta o que ja foi decidido. Uma regra, um lugar. #>
function Test-EhLegendaPtBr($f) {
    return ("$($f.Papel)" -eq "leg-ptbr" -or "$($f.Papel)" -eq "leg-pgs-extra")
}

function Add-CabecalhoGrupo([string]$Texto, [string]$Extra) {
    # 17.03: VIDEO / AUDIO / LEGENDAS / EXTRAS sao montados aqui, nao no XAML -
    # a varredura de traducao nao alcanca linha de ListView.
    $Texto = Traduzir-Frase $Texto
    $Extra = Traduzir-Frase $Extra
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
    # 17.01: "Modo: Automatico" (o valor guardado nao tem acento) nunca batia
    # com a entrada "Modo: Automático" da tabela. Passa pelas regras agora.
    $UI.txtModoVideo.Text = Traduzir-Frase $(if ($marcado) { "Modo: $($v.Modo)" } else { "Marque o vídeo p/ editar" })
    $UI.txtModoVideo.Foreground  = Pincel $(if ($marcado) { $Cores.txt } else { $Cores.dim2 })
    $UI.btnModoVideo.BorderBrush = Pincel $(if (-not $marcado) { $Cores.dim2 }
                                            elseif ($v.Modo -eq "Manual") { $Cores.marca }
                                            else { $Cores.borda })
}

function Fill-Faixas {
    $script:LinhasFaixas.Clear()
    $idx = $UI.lstFila.SelectedIndex
    if ($idx -lt 0 -or $idx -ge $script:Videos.Count) {
        Set-DicaFaixas "Selecione um vídeo na aba Fila."
        $UI.btnModoVideo.Visibility = "Collapsed"
        $UI.txtRodapeTamanho.Text = ""
        return
    }
    $v = $script:Videos[$idx]
    $faixas = @($v.Faixas)
    if ($faixas.Count -eq 0) {
        Set-DicaFaixas "Este vídeo não pôde ser lido."
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
            # 17.03: a COR e a logica seguem o valor em portugues; o que vai
            # para a tela e o texto exibido, na lingua atual.
            $vbTela  = Get-VerboExibido $vb
            $det     = Traduzir-Frase $det
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
            $opcoes = if ($editavel) { Get-OpcoesVerbo $f } else { @($vbTela) }
            $ehPadrao = ($f.Tipo -eq "video") -or ([int]$f.Id -eq $idPadraoAudio) -or ([int]$f.Id -eq $idPadraoLeg)
            $padraoTxt = if ($ehPadrao) { Traduzir-Frase "PADRÃO" } else { "" }

            <#  16.84 - A COLUNA "NOME DA FAIXA" DO VIDEO VINHA VAZIA.

                No Troy o release batizou a faixa de "Dolby Vision P7 MEL CM
                v4.0" e o Diego gostou de ver aquilo ali. No GOT a mesma
                coluna estava em branco - porque o release nao escreveu nada,
                e o programa so repassa o que o arquivo diz.

                Agora, QUANDO E SO QUANDO o release nao nomeou a faixa de
                video, o campo recebe a identificacao que o proprio programa
                apurou, no formato oficial do MediaInfo mais a sigla que so a
                medicao sabe dizer:

                  Dolby Vision, Version 1.0, dvhe.07.06, BL+EL+RPU [FEL]

                Nao sobrescreve nome nenhum: se o release nomeou, o nome dele
                continua. E nao inventa - cada pedaco veio do container, menos
                a sigla, que veio do dovi_tool e por isso vai entre colchetes. #>
            $nomeFx = "$($f.Nome)"
            if ($f.Tipo -eq "video" -and $nomeFx -eq "" -and "$($v.DVtextoFaixa)" -ne "") {
                $nomeFx = "$($v.DVtextoFaixa)"
            }
            [void]$script:LinhasFaixas.Add((New-LinhaFaixa `
                $f.Id "" $f.Codec $idiomaTxt $nomeFx $tam $f.Marcas `
                $Cores.dim2 $Cores.txt $corIdioma $Cores.okdim $Cores.dim "SemiBold" `
                $vbTela $det $corVerbo $(if ($vb -eq "CONVERTER") { "SemiBold" } else { "Normal" }) `
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
    <#  17.16: a linha dos Capitulos mostrava o verbo CRU ("MANTER") enquanto
        as faixas logo acima ja mostravam "KEEP" - meia tabela em cada lingua.
        O verbo tem UM tradutor (Get-VerboExibido) e esta linha, por ser
        montada a mao, era a unica que nao passava por ele. #>
    [void]$script:LinhasFaixas.Add((New-LinhaFaixa `
        "" "" (Traduzir-Frase "Capítulos") "" (Traduzir-Frase $(if ($temCap) { "$($v.Capitulos) capítulos" } else { "sem capítulos" })) "" `
        $(if ($temCap) { Traduzir-Frase "Mantidos" } else { "" }) `
        $Cores.dim2 $(if ($temCap) { $Cores.txt } else { $Cores.dim2 }) $Cores.dim $Cores.okdim $Cores.dim "SemiBold" `
        $(if ($temCap) { Get-VerboExibido "MANTER" } else { "" }) "" (Cor-Verbo "MANTER") "Normal"))
    $txtAnexos = Traduzir-Frase $(if ($v.Anexos -gt 0) { "$($v.Anexos) anexo(s)" } else { "nenhum anexo" })
    [void]$script:LinhasFaixas.Add((New-LinhaFaixa `
        "" "" (Traduzir-Frase "Anexos") "" $txtAnexos "" "" `
        $Cores.dim2 $Cores.txt $Cores.dim $Cores.dim2 $Cores.dim "SemiBold"))

    Update-BotaoModo
    <#  18.10 - O NOME QUE FICAVA PRESO NO CABECALHO DA FILA.

        "veja que no circulo de cima as vezes vem o nome ali quando clico
        automatico/manual e tem vezes que nao; eu selecionei o Se7en e la ainda
        fica como Blood... eu ja tinha comentado de tirar isso dali na parte da
        fila" (Diego, 17/09), com a sequencia de prints provando.

        O que acontecia: esta linha escreve o nome do video cujas FAIXAS
        acabaram de ser montadas - e Fill-Faixas tambem roda por outros
        motivos, como trocar Automatico/Manual. No log dele, as 11:53:48, o
        clique em MODO do Bloodsport remontou as faixas E escreveu o nome dele
        no cabecalho, com a aba FILA na tela e o Se7en selecionado. Dai o nome
        errado, "as vezes sim e as vezes nao", e o conserto de clicar em outra
        coisa e voltar.

        O cabecalho e da ABA FAIXAS: e ali que faz sentido dizer de quem sao as
        faixas. Na aba FILA ele nao tem o que dizer - quem diz o nome e a
        propria linha selecionada. Entao o nome so e escrito quando a aba das
        faixas esta na tela. #>
    Set-DicaFaixas "$($v.Nome)"

    $estimado = Get-TamanhoEstimadoVideo $v
    $delta = $estimado - [double]$v.Bytes
    $sinalDelta = if ($delta -gt 0) { "+" } else { "" }
    $UI.txtRodapeTamanho.Text = Traduzir-Frase ("Tamanho Estimado da Saída : ~{0}   ·   Original : {1}   ·   Δ : {2}{3}" -f `
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
        Set-AbaDica ""
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
    Set-BotaoIniciar (($marcados -gt 0) -and ($Estado.Atual -eq "inicial"))
    Update-CabecalhoFila
    Update-Disco
    if ($Estado.Atual -eq "inicial") {
        $Janela.Title = "$NOME_APP  ·  " + (Traduzir-Frase ("Pronto para Converter - {0} Vídeo(s) Selecionado(s)" -f $marcados))
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
    # 16.94: os tres passam por Traduzir-Frase - sao montados com numero
    # dentro e por isso a varredura da arvore nunca os alcancou.
    $UI.txtAbaFila.Text = Traduzir-Frase $(if ($tot -eq 0) { "Fila" } else { "Fila ($tot)" })
    $idxSel = $UI.lstFila.SelectedIndex
    $UI.txtAbaFaixas.Text = Traduzir-Frase $(if ($idxSel -ge 0 -and $idxSel -lt $script:Videos.Count) {
        "Faixas do Vídeo ($(@($script:Videos[$idxSel].Faixas).Count))"
    } else { "Faixas do Vídeo" })
    $UI.colFila.Header = Traduzir-Frase $(if ($tot -eq 0) { "VÍDEOS NA FILA" }
                         elseif ($ativos -eq $tot) { "VÍDEOS NA FILA ($tot)" }
                         else { "VÍDEOS NA FILA ($ativos de $tot Selecionados)" })
}

<#  =====================================================================
    16.92 - IDIOMA: PORTUGUES / INGLES
    =====================================================================

    COMO ISSO FUNCIONA, E POR QUE ASSIM

    A janela tem centenas de textos, e a maioria e escrita direto no XAML ou
    montada no codigo. Trocar cada um por uma chave seria reescrever o
    arquivo inteiro - semanas de trabalho mecanico e uma chance enorme de
    quebrar coisa que ja funciona.

    Entao o caminho e outro: uma TABELA de pares (portugues -> ingles) num
    arquivo de texto, e uma varredura na arvore visual que troca o texto de
    cada rotulo pelo par correspondente. Nada de chaves, nada de reescrever
    o XAML. Quem quiser corrigir uma traducao abre o IDIOMA_EN.txt e edita
    uma linha - nao precisa tocar em codigo nem saber PowerShell.

    O QUE E TRADUZIDO NESTA VERSAO

    Os rotulos fixos: barra de botoes, abas, cabecalhos das tabelas, titulos
    dos paineis. As frases que o programa MONTA na hora (diagnostico, selos
    do resumo, situacao da fila) ainda saem em portugues - elas passam por
    T() a partir da proxima camada, e a tabela ja aceita as entradas.

    Isso esta dito na tela, no proprio botao, para nao parecer defeito.

    O PORTUGUES NUNCA DEPENDE DO ARQUIVO

    Se o IDIOMA_EN.txt sumir, o botao avisa e o programa continua em
    portugues, inteiro. A traducao e uma camada por cima, nunca a fonte. #>

$script:Lang     = "PT"
<#  19.6 - A TABELA IGNORAVA MAIUSCULA, E O IDIOMA TEM PARES QUE SO DIFEREM
    NELA: "Fila"/"FILA" (Queue/QUEUE), "Lendo a pasta..."/"Lendo a Pasta...".
    Com @{} a segunda linha sobrescrevia a primeira e a tela saia com a
    caixa errada. Agora o mapa e exato (Ordinal) e o @{} antigo fica so como
    reserva, para quem pedir com uma caixa que a tabela nao tem. #>
$script:MapaEN   = (New-Object System.Collections.Hashtable ([System.StringComparer]::Ordinal))   # portugues -> ingles
$script:MapaENi  = @{}
$script:MapaPTi  = @{}
$script:RegrasEN = New-Object System.Collections.ArrayList
$script:MapaPT   = (New-Object System.Collections.Hashtable ([System.StringComparer]::Ordinal))   # ingles -> portugues (o caminho de volta)

function Carregar-Idioma {
    $arq = Join-Path $script:PastaScript "IDIOMA_EN.txt"
    if (-not (Test-Path -LiteralPath $arq)) { return $false }
    try {
        $linhas = [System.IO.File]::ReadAllLines($arq, [System.Text.Encoding]::UTF8)
    } catch { return $false }
    $script:MapaEN = New-Object System.Collections.Hashtable ([System.StringComparer]::Ordinal)
    $script:MapaPT = New-Object System.Collections.Hashtable ([System.StringComparer]::Ordinal)
    $script:MapaENi = @{}; $script:MapaPTi = @{}
    $script:RegrasEN = New-Object System.Collections.ArrayList
    foreach ($l in $linhas) {
        if ($l -eq "" -or $l.StartsWith("#")) { continue }
        # O separador e TAB de proposito: nenhum rotulo da tela tem TAB, e
        # assim a traducao pode conter qualquer sinal de pontuacao.
        $partes = $l -split "`t", 2
        if ($partes.Count -ne 2) { continue }
        <#  16.94: regra de padrao NAO passa por Trim. Varias delas terminam
            em espaco de proposito ("Convertendo · " -> "Converting · ") e o
            Trim comia justamente esse espaco, colando as palavras. Rotulo
            comum continua aparado - ali o espaco sobrando e engano. #>
        if ($partes[0].StartsWith("~")) {
            $padrao = $partes[0].Substring(1)
            if ($padrao -ne "") { [void]$script:RegrasEN.Add(@{ De = $padrao; Para = $partes[1] }) }
            continue
        }
        $pt = $partes[0].Trim(); $en = $partes[1].Trim()
        if ($pt -eq "" -or $en -eq "") { continue }
        <#  16.94 - REGRAS DE PADRAO, PARA O TEXTO QUE E MONTADO NA HORA.

            Achado do Diego (09/09, terceira foto): "ta em ingles e varias
            partes em portugues". Estava certo, e a causa era estrutural: a
            traducao trocava o TEXTO DOS ROTULOS varrendo a arvore visual, e
            rotulo fixo era tudo o que ela alcancava. "Fila (3)", "VÍDEOS NA
            FILA (2 de 3 Selecionados)", "Convertendo · Etapa 3/5" e as
            frases do diagnostico nao sao rotulos: sao montadas com numero
            dentro, a cada redesenho, e nunca existiram na tabela.

            Uma linha que comeca com ~ e uma REGRA, nao um rotulo: o lado
            esquerdo e uma expressao regular e o lado direito a substituicao
            (com $1, $2... para os pedacos capturados - tipicamente o
            numero, que nao se traduz). Elas rodam EM ORDEM sobre a frase
            montada, entao regra mais especifica vem primeiro no arquivo.

            Continua tudo fora do .ps1: uma frase nova so precisa de uma
            linha nova aqui. #>
        $script:MapaEN[$pt] = $en
        if (-not $script:MapaPT.ContainsKey($en)) { $script:MapaPT[$en] = $pt }
        if (-not $script:MapaENi.ContainsKey($pt)) { $script:MapaENi[$pt] = $en }
        if (-not $script:MapaPTi.ContainsKey($en)) { $script:MapaPTi[$en] = $pt }
    }
    return (($script:MapaEN.Count + $script:RegrasEN.Count) -gt 0)
}

function Traduzir-Frase([string]$Pt) {
    <#  Como Traduzir, mas para frase MONTADA (com numero, nome de arquivo,
        percentual dentro). Tenta primeiro a tabela exata - se a frase
        inteira estiver la, e ela que vale - e so depois aplica as regras,
        em ordem. Sem regra que case, devolve o portugues: texto na lingua
        errada e feio, texto em branco e defeito. #>
    if ($script:Lang -ne "EN") { return $Pt }
    if ($Pt -eq $null -or $Pt -eq "") { return $Pt }
    if ($script:MapaEN.ContainsKey($Pt)) { return $script:MapaEN[$Pt] }
    if ($script:MapaENi -and $script:MapaENi.ContainsKey($Pt)) { return $script:MapaENi[$Pt] }
    $r = $Pt
    foreach ($re in $script:RegrasEN) {
        try { $r = [regex]::Replace($r, $re.De, $re.Para) } catch { }
    }
    return $r
}

function Traduzir-LinhaContador([string]$Linha) {
    <#  17.12 - AS LINHAS DO RESUMO SAO "ROTULO ... : VALOR".

        Traduzir-Frase so casa a frase INTEIRA, e aqui a frase carrega o
        numero e um monte de espacos de alinhamento - nunca vai bater. Entao
        a linha e partida no ultimo ":", o ROTULO e traduzido pela tabela, e
        a linha e remontada com o MESMO comprimento de antes: as duas colunas
        do resumo alinham os dois-pontos, e um rotulo em ingles de outro
        tamanho desmancharia a coluna.

        Sem ":" a linha passa por Traduzir-Frase e segue a vida. #>
    if ($script:Lang -ne "EN") { return $Linha }
    $i = $Linha.LastIndexOf(":")
    if ($i -lt 1) { return (Traduzir-Frase $Linha) }
    $rot = $Linha.Substring(0, $i)
    $val = $Linha.Substring($i)
    $largura = $rot.Length
    $novo = Traduzir ($rot.TrimEnd())
    if ($novo -eq $rot.TrimEnd()) { $novo = Traduzir-Frase ($rot.TrimEnd()) }
    if ($novo.Length -lt $largura) { $novo = $novo.PadRight($largura) }
    return ($novo + $val)
}

function Traduzir([string]$Pt) {
    <#  Traduz UMA frase, se houver traducao e se o idioma for ingles.
        Sem traducao, devolve o portugues - texto faltando aparece na lingua
        original, que e feio mas legivel; texto em branco seria pior. #>
    if ($script:Lang -ne "EN") { return $Pt }
    if ($script:MapaEN.ContainsKey($Pt)) { return $script:MapaEN[$Pt] }
    if ($script:MapaENi -and $script:MapaENi.ContainsKey($Pt)) { return $script:MapaENi[$Pt] }
    return $Pt
}

function Traduzir-Arvore($Raiz, [hashtable]$Mapa) {
    $reservaArv = if ([object]::ReferenceEquals($Mapa, $script:MapaEN)) { $script:MapaENi } elseif ([object]::ReferenceEquals($Mapa, $script:MapaPT)) { $script:MapaPTi } else { $null }
    <#  17.05 - A ARVORE VISUAL NAO E A TELA INTEIRA.

        Defeito achado em uso, 10/09, olhando as fotos: depois de trocar de
        idioma ao vivo a tela ficava METADE em cada lingua. Traduziam o
        titulo, a fila e os cabecalhos de coluna; NAO traduziam a barra de
        botoes, "Marcar Todos", os paineis DIAGNOSTICO e ESPACO EM DISCO e a
        aba que nao estava selecionada.

        A CAUSA: esta funcao percorria so o VisualTreeHelper. A arvore
        VISUAL contem apenas o que ja foi RENDERIZADO - o conteudo de uma
        aba nao selecionada, e tudo que mora dentro de um ControlTemplate
        ainda nao realizado, simplesmente nao esta la. O que traduzia era o
        que tem outro caminho: o titulo e a fila sao remontados por
        Fill-Fila, e as colunas ja tinham o bloco proprio la embaixo.

        Reiniciar "resolvia" porque a janela nasce montada de uma vez - e foi
        por isso que a pergunta de reinicio existiu. Ela era o remendo do
        defeito que esta sendo consertado agora.

        O CONSERTO: varrer TAMBEM a arvore LOGICA (LogicalTreeHelper), que
        enxerga o que o XAML declarou, renderizado ou nao. As duas juntas,
        sem repetir - um HashSet guarda quem ja foi visitado, senao um
        elemento que esta nas duas arvores seria traduzido duas vezes (e na
        segunda o texto ja estaria em ingles, o que nao quebra, mas mede
        errado).

        E a conta vai para o LOG. Sem esse numero a unica forma de saber se
        a traducao pegou era olhar foto da tela. #>
    if ($null -eq $Raiz) { return 0 }
    $trocados = 0
    $vistos   = New-Object 'System.Collections.Generic.HashSet[object]' ([System.Collections.Generic.EqualityComparer[object]]::Default)
    $fila     = New-Object System.Collections.Generic.Queue[object]
    $fila.Enqueue($Raiz)
    while ($fila.Count -gt 0) {
        $o = $fila.Dequeue()
        if ($null -eq $o) { continue }
        if (-not $vistos.Add($o)) { continue }

        if ($o -is [System.Windows.Controls.TextBlock]) {
            $x = "$($o.Text)"
            if ($x -ne "" -and (($Mapa.ContainsKey($x)) -or ($reservaArv -and $reservaArv.ContainsKey($x)))) { $o.Text = $(if ($Mapa.ContainsKey($x)) { $Mapa[$x] } else { $reservaArv[$x] }); $trocados++ }
        } elseif ($o -is [System.Windows.Controls.GridViewColumnHeader]) {
            $x = "$($o.Content)"
            if ($x -ne "" -and (($Mapa.ContainsKey($x)) -or ($reservaArv -and $reservaArv.ContainsKey($x)))) { $o.Content = $(if ($Mapa.ContainsKey($x)) { $Mapa[$x] } else { $reservaArv[$x] }); $trocados++ }
        } elseif ($o -is [System.Windows.Controls.TabItem]) {
            $x = "$($o.Header)"
            if ($x -ne "" -and (($Mapa.ContainsKey($x)) -or ($reservaArv -and $reservaArv.ContainsKey($x)))) { $o.Header = $(if ($Mapa.ContainsKey($x)) { $Mapa[$x] } else { $reservaArv[$x] }); $trocados++ }
        }
        <#  17.15: a DICA tambem e texto de tela, e nenhuma delas trocava de
            lingua - a varredura so olhava o texto do elemento. Vale para
            qualquer controle, entao fica fora da cadeia de tipos acima. #>
        if ($o -is [System.Windows.FrameworkElement]) {
            $d = $o.ToolTip
            if ($d -is [string] -and $d -ne "" -and (($Mapa.ContainsKey($d)) -or ($reservaArv -and $reservaArv.ContainsKey($d)))) { $o.ToolTip = $(if ($Mapa.ContainsKey($d)) { $Mapa[$d] } else { $reservaArv[$d] }); $trocados++ }
        }

        # --- filhos VISUAIS (o que ja foi desenhado)
        if ($o -is [System.Windows.DependencyObject]) {
            try {
                $n = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($o)
                for ($i = 0; $i -lt $n; $i++) {
                    $fila.Enqueue([System.Windows.Media.VisualTreeHelper]::GetChild($o, $i))
                }
            } catch { }
            # --- filhos LOGICOS (o que o XAML declarou, desenhado ou nao)
            try {
                foreach ($f in [System.Windows.LogicalTreeHelper]::GetChildren($o)) {
                    if ($f -is [System.Windows.DependencyObject]) { $fila.Enqueue($f) }
                }
            } catch { }
        }

        # Content de ContentControl (botao, aba) nem sempre e filho logico.
        if ($o -is [System.Windows.Controls.ContentControl]) {
            $c = $o.Content
            if ($c -is [System.Windows.DependencyObject]) { $fila.Enqueue($c) }
        }
        # Items de ItemsControl que ainda nao viraram container.
        if ($o -is [System.Windows.Controls.ItemsControl]) {
            foreach ($it in @($o.Items)) {
                if ($it -is [System.Windows.DependencyObject]) { $fila.Enqueue($it) }
            }
        }
    }

    # Os cabecalhos do GridView nao aparecem na arvore visual antes de a
    # lista ser desenhada; por isso eles tambem sao trocados direto no modelo.
    try {
        foreach ($lst in @($UI.lstFila, $UI.lstFaixas)) {
            if ($null -eq $lst -or $null -eq $lst.View) { continue }
            foreach ($col in @($lst.View.Columns)) {
                $x = "$($col.Header)"
                if ($x -ne "" -and $Mapa.ContainsKey($x)) { $col.Header = $Mapa[$x]; $trocados++ }
            }
        }
    } catch { }
    return $trocados
}

function Set-Idioma([string]$Novo) {
    if ($Novo -eq $script:Lang) { return }
    if ($Novo -eq "EN" -and $script:MapaEN.Count -eq 0) {
        if (-not (Carregar-Idioma)) {
            [System.Windows.MessageBox]::Show(
                ("O arquivo de tradução não foi encontrado.`n`nEle deveria estar em:`n{0}`n`n" +
                 "Sem ele o programa continua em português, inteiro - a tradução é uma camada por cima, nunca a fonte." -f `
                 (Join-Path $script:PastaScript "IDIOMA_EN.txt")),
                "LaFirma - tradução indisponível", "OK", "Warning") | Out-Null
            return
        }
    }
    $mapa = if ($Novo -eq "EN") { $script:MapaEN } else { $script:MapaPT }
    $script:Lang = $Novo
    $trocados = Traduzir-Arvore $Janela $mapa
    $UI.lblBandeira.Text = $(if ($Novo -eq "EN") { [char]::ConvertFromUtf32(0x1F1FA) + [char]::ConvertFromUtf32(0x1F1F8) }
                             else { [char]::ConvertFromUtf32(0x1F1E7) + [char]::ConvertFromUtf32(0x1F1F7) })
    $UI.lblIdioma.Text = $(if ($Novo -eq "EN") { "English" } else { "Português" })
    # 17.05: o numero vai para o log. Se ele vier baixo demais, a varredura
    # nao esta alcancando a tela - e era exatamente isso que acontecia.
    Escrever-Log ("IDIOMA: {0} - {1} rotulo(s) trocado(s) na tela" -f $Novo, $trocados) "ACAO"
    <#  16.93: a escolha fica guardada. O Diego perguntou se nao daria para
        simplesmente reiniciar o programa ao trocar - a troca ao vivo ja
        funciona e nao precisa disso, mas a preocupacao dele estava certa:
        de nada adianta escolher ingles e o programa voltar em portugues na
        proxima vez. Um arquivo de uma linha resolve, e ele nao e critico:
        se sumir ou vier corrompido, abre em portugues, como sempre foi. #>
    try {
        [System.IO.File]::WriteAllText((Join-Path (Get-PastaDados) "IDIOMA.txt"), $Novo,
            (New-Object System.Text.UTF8Encoding($false)))
    } catch {
        # 17.02: falhar em silencio foi o defeito. Se nao deu para gravar,
        # o log diz - senao o programa "esquece" a escolha sem explicar.
        Escrever-Log ("IDIOMA: nao foi possivel guardar a escolha - {0}" -f $_.Exception.Message) "AVISO"
    }
    # O que e montado na hora tem que ser redesenhado, senao metade da tela
    # fica na lingua anterior ate o proximo evento.
    try { Fill-Fila "idioma" } catch { }
    try { Update-Diagnostico } catch { }
    <#  17.02: o painel de disco TAMBEM e montado na hora, e nao estava
        nesta lista. Resultado: trocava para ingles, voltava para portugues
        e as tres linhas do disco continuavam em ingles ate a proxima
        leitura da pasta - a tela com duas linguas ao mesmo tempo que o
        Diego viu e descreveu como "fica horrivel quando volta". #>
    try { Update-Disco } catch { }
    # 2.0.12: o "[F12] Medir MEL x FEL: Ligado" do topo ficava em portugues na
    # tela em ingles (print de 23/09 13:35) - ele e montado por codigo, com o
    # "[F12] " na frente, e a troca de idioma so relia os rotulos do XAML.
    try { Update-BotaoMedirEL } catch { }
    try { Fill-Faixas } catch { }
    # 17.15: o cartao final e o quinto painel montado por codigo. Ficava de
    # fora e deixava a tela meio em cada lingua depois de uma conversao.
    try { Redesenhar-Resumo } catch { }
    try { Update-DicaCenso $(if ($UI.lstFila.SelectedIndex -ge 0 -and $UI.lstFila.SelectedIndex -lt $script:Videos.Count) { $script:Videos[$UI.lstFila.SelectedIndex] } else { $null }) } catch { }

}


function Offer-ReinicioIdioma([string]$Novo) {
    <#  17.04 - ESTA PERGUNTA E DO CLIQUE, NUNCA DO ARRANQUE.

        Defeito achado em uso, madrugada de 10/09, e ele era meu: a pergunta
        de reiniciar nasceu DENTRO do Set-Idioma na 17.03. So que o arranque
        tambem chama Set-Idioma, para aplicar o idioma guardado da sessao
        anterior. Resultado: quem tinha escolhido ingles abria o programa e
        era recebido pela caixa "reiniciar agora?" - e dizer Sim estourava:

            "Nao sera possivel definir Visibility nem chamar Show, ShowDialog
             ou WindowInteropHelper.EnsureHandle depois que uma Janela for
             fechada."

        A janela ainda nem tinha sido exibida quando o codigo mandou fecha-la
        e reabrir. Cinco sessoes do log de 01:26 terminam nessa linha.

        E no arranque a pergunta nao faz sentido nenhum: a janela esta sendo
        construida AGORA, no idioma certo. Nao ha nada a completar.

        Por isso a pergunta saiu do Set-Idioma e mora aqui, chamada so pelo
        clique no botao de idioma. O arranque chama Set-Idioma e mais nada.

        A guarda de IsLoaded e cinto e suspensorio: se um dia alguem chamar
        isto cedo demais de novo, nao estoura - so nao pergunta. #>
    if (-not $Janela.IsLoaded) {
        Escrever-Log "IDIOMA: janela ainda nao exibida - reinicio nao oferecido" "ACAO"
        return
    }
    <#  17.03 - A TROCA AO VIVO ALCANCA QUASE TUDO. QUASE.

        Ideia do Diego (09/09): "no momento que a pessoa clica para mudar a
        linguagem, o programa avisa que muda na proxima reiniciada e ja
        pergunta se quer fazer na hora".

        Ele esta certo, e o motivo e concreto: alguns textos do WPF sao
        escritos uma vez, na construcao da janela - cabecalho de coluna que
        ja foi medido, largura calculada com a palavra antiga, tooltip que o
        template guardou. A varredura reescreve o que consegue alcancar; o
        resto so nasce certo abrindo de novo.

        A TRAVA QUE IMPORTA: com uma fila rodando, reiniciar joga fora a
        conversao em curso. Entao a pergunta so aparece com o programa
        parado. Rodando, ele troca o que da e diz que o resto fica para a
        proxima abertura - sem oferecer nada que possa custar uma hora de
        trabalho. #>
    if ($Estado.Atual -in @("rodando","pausado")) {
        Escrever-Log "IDIOMA: fila em andamento - reinicio nao oferecido" "ACAO"
        return
    }
    $msg = if ($Novo -eq "EN") {
        "The language was switched now, and most of the screen is already in English." + "`n`n" +
        "A few labels are written once, when the window is built, and only come out right after restarting." + "`n`n" +
        "Restart the program now?"
    } else {
        "O idioma foi trocado agora, e quase toda a tela já está em português." + "`n`n" +
        "Alguns rótulos são escritos uma vez só, quando a janela é montada, e só saem certos depois de reabrir." + "`n`n" +
        "Reiniciar o programa agora?"
    }
    $titulo = if ($Novo -eq "EN") { "LaFirma - restart to finish" } else { "LaFirma - reiniciar para completar" }
    $r = [System.Windows.MessageBox]::Show($msg, $titulo, "YesNo", "Question", "No")
    if ($r -eq "Yes") {
        Escrever-Log "IDIOMA: reinicio pedido pelo usuario" "ACAO"
        try {
            $exe = (Get-Process -Id $PID).Path
            if (-not $exe) { $exe = "powershell.exe" }
            Start-Process -FilePath $exe `
                -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-STA","-File","`"$($script:CaminhoScript)`"")
            $script:Fechando = $true   # 18.12: o Closed confirma, mas quem fecha avisa antes
            $Janela.Close()
        } catch {
            Escrever-Log ("IDIOMA: nao consegui reabrir o programa - {0}" -f $_.Exception.Message) "AVISO"
        }
    } else {
        Escrever-Log "IDIOMA: usuario preferiu continuar sem reiniciar" "ACAO"
    }
}


function Get-FatorEspacoDisco($v) {
    <#  16.95 - O FATOR DE DISCO NUM LUGAR SO.

        O motor usa 3,15x quando o video vai SAIR do container (extraido,
        convertido pelo dovi_tool e remontado, os tres no disco ao mesmo
        tempo) e 1,6x quando ele nao sai. A janela tinha essa regra escrita
        duas vezes, e uma delas era so "tem seta na coluna = 3,15".

        O P5 quebrou esse atalho: a coluna dele e "P5 -> MP4", TEM seta, e
        mesmo assim ele nao passa pelo dovi_tool - e uma passada so de
        ffmpeg. Cobrar 3,15x dele era recusar arquivo por espaco que o motor
        nem ia usar. #>
    if ($v.P5 -eq $true) { return 1.6 }
    if ("$($v.ColDV)" -notmatch "→") { return 1.6 }
    return 3.15
}

function Get-NomeCorEL($v) {
    <#  16.94 - A ESCALA DAS TRES CORES MORA AQUI, E SO AQUI.

        Achado do Diego (09/09): "vc ta se perdendo em todos lugares como
        sempre em padronizar ne?". Estava certo. A regra verde/laranja/
        vermelho vivia escrita DENTRO da Pintar-RotuloDV, entao a sigla do
        diagnostico obedecia a escala e a coluna DOLBY VISION da fila nao -
        ela pintava tudo com a mesma regra antiga ("tem seta = okdim"). O
        mesmo veredicto medido saia de duas cores diferentes em duas partes
        da tela, que e exatamente o defeito que a 16.84 fechou no TEXTO e
        eu deixei aberto na COR.

          verde     MEL              - EL sem imagem, descarte sem perda
          laranja   Simple FEL       - EL com imagem, nao levanta o brilho
          vermelho  Complex FEL      - EL com imagem E levanta o brilho
          ambar     EL nao medida    - duvida, que nao e ressalva
          cinza     medindo / sem EL - ainda nao ha veredicto, ou nao se aplica

        Quem precisa de cor chama esta funcao. Ninguem mais decide sozinho. #>
    switch ("$($v.ELtipo)") {
        "MEL"        { return "verde" }
        <#  2.0.1 - O VERMELHO PASSOU A TER UMA CONDICAO DE SAIDA, E SO UMA.

            "Expande" e uma comparacao de UM numero: o pico da cena mais alta
            contra o pico do master. Uma cena passou, o arquivo inteiro ficava
            vermelho - e vermelho aqui quer dizer "este e o caso que estraga a
            imagem".

            O comentario da 16.85 ja dizia o que faltava: "um pico isolado
            numa cena e outra coisa de metade do filme acima da regua". O que
            nao existia era a contagem grande o bastante para separar os dois.
            O CENSO COMPLETO e essa contagem - le o filme inteiro.

            Medido, nos dois casos que temos:
                Saving Private Ryan   216 de 1.124 cenas (19,22%), pico 3.468
                                      contra master 1.000  -> 3,47x  VERMELHO
                Transformers ROTF      15 de 2.225 cenas (0,67%), pico 1.555
                                      contra master 1.000  -> 1,56x  isolado
            A planilha da comunidade mede o Transformers por outro caminho
            (madVR, imagem decodificada) e da 0,3% dos QUADROS acima de 1.000
            nits, com a MESMA contagem de quadros do nosso censo (215.617).
            As duas medicoes concordam que este filme mal encosta acima do
            master - e ele levava a mesma cor de um que expande o tempo todo.

            ISTO NAO RECLASSIFICA A CAMADA. FEL continua FEL, a EL continua
            sendo descartada e o usuario continua perdendo o residual. O que
            muda e a GRAVIDADE, que e o que a cor comunica. Por isso o destino
            e laranja (a cor de "converte, com ressalva") e nunca verde. #>
        "FEL"        { if ($v.ELexpande -eq $true) { return "vermelho" } else { return "laranja" } }
        "MISTO"      { if ($v.ELexpande -eq $true) { return "vermelho" } else { return "laranja" } }
        "NAO_MEDIDO" { return "ambar" }
        "MEDINDO"    { return "cinza" }
    }
    return "cinza"
}

function Get-CorEL($v) {
    switch (Get-NomeCorEL $v) {
        "verde"    { return $Cores.ok }
        "laranja"  { return $Cores.lar }
        "vermelho" { return $Cores.err }
        "ambar"    { return $Cores.warn }
    }
    return $Cores.dim
}

function Get-ChipEL($v) {
    # O chip e a mesma escala, so que em fundo/borda.
    switch (Get-NomeCorEL $v) {
        "verde"    { return @{ Fundo = "#0B1A08"; Borda = "#1F5A16" } }
        "laranja"  { return @{ Fundo = "#231206"; Borda = "#7A4212" } }
        "vermelho" { return @{ Fundo = "#230B0B"; Borda = "#7A1E1D" } }
        "ambar"    { return Get-ChipAmbar }
    }
    return Get-ChipVazio
}

function Pintar-RotuloDV($v) {
    $txt = Traduzir-Frase "$($v.DiagDVrot)"
    $UI.diagDV.Inlines.Clear()
    $m = [regex]::Match($txt, '^(.*?)(\[EL: [^\]]+\])(.*)$')
    if (-not $m.Success) {
        $UI.diagDV.Inlines.Add((New-Object System.Windows.Documents.Run $txt))
        return
    }
    # A cor sai do MEDIDO, nunca do texto: ler a palavra de volta da frase
    # seria a mesma informacao em dois lugares, que e o que a 16.84 fechou.
    $cor = Get-CorEL $v
    $r1 = New-Object System.Windows.Documents.Run $m.Groups[1].Value
    $r2 = New-Object System.Windows.Documents.Run $m.Groups[2].Value
    $r2.Foreground = Pincel $cor
    $r3 = New-Object System.Windows.Documents.Run $m.Groups[3].Value
    $UI.diagDV.Inlines.Add($r1); $UI.diagDV.Inlines.Add($r2); $UI.diagDV.Inlines.Add($r3)
}

function Update-Diagnostico {
    $idx = $UI.lstFila.SelectedIndex
    if ($idx -lt 0 -or $idx -ge $script:Videos.Count) {
        $UI.lblDiagTitulo.Text = Traduzir "DIAGNÓSTICO:"
        foreach ($c in @("diagDV","diagAu","diagLg","diagDVr","diagAur","diagLgr")) { $UI.$c.Text = "" }
        # 17.08: sem linha selecionada nao ha o que contar (item A).
        # 18.21: quem apaga o botao e Update-BotaoCenso, chamado aqui dentro.
        Update-DicaCenso $null
        return
    }
    $v = $script:Videos[$idx]
    <#  17.08 - O BOTAO DO CENSO SEGUE A LINHA SELECIONADA (item A).

        Acende so em Complex FEL, e so uma vez por arquivo: contar o mesmo
        filme duas vezes gasta dois minutos para chegar ao mesmo numero. #>
    <#  17.21 - O CENSO PODIA SER APERTADO DURANTE A CONVERSAO.

        BUG MEDIDO no log do Diego (15/09 20:36:56): com a etapa 1/5 rodando
        ele clicou em "Censo Completo". O censo le o RPU do FILME INTEIRO; a
        conversao estava lendo outro arquivo de 82 GB no MESMO disco
        mecanico. Os dois se estrangularam: a etapa 1/5 ficou em 1% por mais
        de um minuto e o censo nunca voltou. Ele: "BOTAO CENSO FUNCIONANDO EM
        CONVERSAO E NUNCA TERMINA".

        A 17.08 escreveu no log que "a fila e a conversao continuam livres".
        Continuam livres de TRAVA - nao de disco. Custo de I/O nao aparece em
        nenhuma flag, e foi por isso que eu nao vi. Pergunta do Diego: "O
        BOTAO CENSO PODE SER APERTADO DEPOIS DE UMA F1?". Nao pode. #>
    <#  18.21: esta linha era o SEGUNDO dono do IsEnabled e a causa do
        "clicando nao" dele. A regra inteira mora em Update-BotaoCenso, que
        Update-DicaCenso chama logo abaixo - dono unico, uma leitura so. #>
    # 17.14: aceso ou apagado, ele diz por que.
    Update-DicaCenso $v
    # 15.1e: um video que NAO vai ser processado nao pode exibir "[SERÁ
    # CONVERTIDO]" em verde nem aviso em ambar - isso e mentira na tela. O
    # diagnostico continua visivel (e util saber o que o arquivo tem), mas o
    # titulo diz o motivo e TODAS as linhas ficam apagadas, deixando claro que
    # nada daquilo vai acontecer. Era o caso do The Last of Us "Já Convertido"
    # mostrando conversao em verde e perda em amarelo ao mesmo tempo.
    $naoProcessa = [bool]$v.Ignorar
    $UI.lblDiagTitulo.Text = Traduzir-Frase ("DIAGNÓSTICO - {0}" -f $v.Nome)
    <#  16.87 - A SIGLA DA EL PINTADA DENTRO DA PROPRIA LINHA (pedido do
        Diego, que circulou o "[EL: MEL]" no print).

        A linha do rotulo e uma frase so, azul inteira. Mas dentro dela ha um
        pedaco que carrega o veredicto - e veredicto neste programa tem cor.
        Um TextBlock nao aceita cor no meio do Text; aceita Inlines. Entao a
        frase e quebrada em tres pedacos (antes, a sigla, depois) e so o do
        meio muda de cor, na MESMA escala do resto:

          verde    MEL
          laranja  FEL sem expansao
          vermelho FEL com expansao
          ambar    EL nao medida  (duvida, nao ressalva)

        Se nao houver "[EL: ...]" na frase, nada muda - a linha sai como antes. #>
    Pintar-RotuloDV $v
    $UI.diagAu.Text  = Traduzir-Frase $v.DiagAurot
    $UI.diagLg.Text  = Traduzir-Frase $v.DiagLgrot
    if ($naoProcessa) {
        # 15.1f: as tres linhas dizem a MESMA coisa, no mesmo padrao de selo das
        # outras: nada vai acontecer, e por que. Antes eu mostrava o diagnostico
        # normal ("[SERÁ CONVERTIDO]" em verde) num arquivo que nao seria
        # processado - mentira na tela. Apagar as linhas tambem nao servia: a
        # informacao que importa aqui e o MOTIVO, e ele tem que estar escrito,
        # na mesma posicao e no mesmo formato das demais linhas.
        $frase = "→ [NÃO SERÁ FEITO] $($v.MotivoIgnorar)"
        $frase = Traduzir-Frase $frase
        $UI.diagDVr.Text = $frase
        $UI.diagAur.Text = $frase
        $UI.diagLgr.Text = $frase
        foreach ($c in @("diagDVr","diagAur","diagLgr")) { $UI.$c.Foreground = Pincel $Cores.err }
        return
    }
    $UI.diagDVr.Text = Traduzir-Frase $v.DiagDVres
    # m3c25: no diagnostico tem espaco pra explicar, entao aqui vai a frase
    # inteira - na coluna fica so o dado. Cor ambar: nao e erro do motor
    # (reaproveitar e a regra certa), e uma perda que vale ele saber.
    # 16.61: a escolha manual manda. So se nao houver escolha e que valem as
    # frases do motor gravadas na leitura da pasta.
    $escAu = Get-DiagAudioComEscolha $v
    $escLg = Get-DiagLegendaComEscolha $v
    if ($null -ne $escAu) {
        $UI.diagAur.Text = Traduzir-Frase ([string]$escAu[0])
    } elseif (Test-JocInferior $v) {
        $detJoc = (Get-AudioDetalhe $v.JocBytes $v.JocCanais $v.DurSeg).Trim()
        $UI.diagAur.Text = Traduzir-Frase ("→ [REAPROVEITADO] E-AC-3[ATMOS] {0}  ·  DeeZy Faria {1} 1152k" -f `
            $detJoc, (Get-CanaisTexto ([int]$v.PrincipalCanais)))
    } else {
        $UI.diagAur.Text = Traduzir-Frase $v.DiagAures
    }
    if ($null -ne $escLg) { $UI.diagLgr.Text = Traduzir-Frase ([string]$escLg[0]) } else { $UI.diagLgr.Text = Traduzir-Frase $v.DiagLgres }
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
            # 16.86: o laranja ja existia na paleta (barra de disco) e agora
            # tem uso no diagnostico: o degrau entre "atencao" e "nao faca".
            "laranja"  { return $Cores.lar }
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
<#  17.17 - A SIMULACAO DA FILA VIROU FUNCAO PURA.

    Ela nasceu na 16.93 dentro de Update-Disco, entre dois punhados de
    $UI.algo - e por isso a unica forma de conferi-la era abrir o programa,
    montar a fila na mao e olhar. Foi assim que ela ficou TRES versoes
    calculando certo e sendo ignorada (a 17.16 conta essa historia).

    Agora ela e uma funcao que recebe a fila e o espaco livre e devolve
    numeros. Sem tela no meio, a bateria executa ela com os arquivos reais do
    Diego e confere o resultado contra o que o motor decidiu de verdade
    naquele dia - que e o unico teste que vale para uma conta como esta.

    A regra nao mudou: cada arquivo exige o FATOR do motor sobre o proprio
    tamanho enquanto converte, e deixa a saida ocupando disco quando termina.
    O que muda e que agora da para provar. #>
function Get-PlanoDoDisco {
    param($Videos, [double]$Livre)
    $r = @{ Cabem = 0; NaoCabem = 0; PrimeiroFora = ""; FaltaNoPrimeiroFora = 0.0 }
    $sobrando = [double]$Livre
    foreach ($v in @($Videos)) {
        $precisaEste = [double]$v.Bytes * (Get-FatorEspacoDisco $v)
        if ($sobrando -ge $precisaEste) {
            $r.Cabem++
            # O que fica no disco depois nao e o pico: e a saida gerada.
            $sobrando = $sobrando - (Get-TamanhoEstimadoVideo $v)
        } else {
            $r.NaoCabem++
            if ($r.PrimeiroFora -eq "") {
                $r.PrimeiroFora = "$($v.Nome)"
                $r.FaltaNoPrimeiroFora = $precisaEste - $sobrando
            }
        }
    }
    return $r
}

function Update-Disco {
    $ativos = @(Get-Marcados)
    if ($ativos.Count -eq 0) {
        $UI.txtDisco.Text = if ($script:Lendo) { Traduzir "Lendo a pasta..." }
                            <#  18.03: as duas linhas abaixo estavam SEM Traduzir - a
                                primeira do "if" tinha, as duas do "else" nao. Apareceu
                                no print dele: painel DISK SPACE em ingles com
                                "Nenhum vídeo selecionado." em portugues. #>
                            elseif (@($script:Videos | Where-Object { -not $_.Ignorar }).Count -gt 0) { Traduzir "Nenhum vídeo selecionado." }
                            elseif ($script:MotivoVazio) { Traduzir-Frase $script:MotivoVazio }
                            else { Traduzir "Nenhum vídeo a converter nesta pasta." }
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
        $fator = Get-FatorEspacoDisco $v
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
    <#  16.86 - A TERCEIRA LINHA MENTIA QUANDO NAO CABIA (achado do Diego).

        Ate aqui a terceira linha era sempre "Espaço Livre Após Converter",
        inclusive quando o resultado era NEGATIVO - e sobra negativa nao
        existe. A tela dizia "Espaço Insuficiente" na barra e, uma linha
        acima, prometia "-47,52 GB livres depois". Nao ha depois: a conversao
        nao comeca.

        Sobra negativa nao e sobra, e FALTA. E falta se diz pelo nome, com o
        numero que resolve: quanto liberar para a fila caber. #>
    $terceira = if ($sobra -lt 0) {
        "Falta Liberar              : {0}" -f (Format-GB ([math]::Abs($sobra)))
    } else {
        "Espaço Livre Após Converter: ~{0}" -f (Format-GB $sobra)
    }
    <#  16.91: o Iniciar precisa saber o que ESTA tela concluiu. Antes ele
        nao sabia, e por isso deixava comecar uma fila que nao cabia - o
        motor recusava arquivo por arquivo, 23 segundos depois, com a
        resposta que ja estava escrita aqui. #>
    $script:DiscoFalta = $(if ($sobra -lt 0) { [double][math]::Abs($sobra) } else { 0.0 })
    $script:DiscoPreciso = [double]$preciso
    $script:DiscoLivre   = [double]$livre

    <#  16.93 - QUANTOS CABEM, E QUAL E O PRIMEIRO QUE NAO CABE.

        A 16.91 passou a perguntar antes de comecar sem espaco, e a pergunta
        dizia "o motor vai converter o que couber e pular o que nao couber".
        Verdade, mas o Diego leu e nao soube o que ia acontecer com A FILA
        DELE: comecou, viu um filme de 82 GB entrar em conversao e parou no
        meio, achando que aquilo nunca terminaria.

        Ele estava certo em desconfiar e o programa estava certo em comecar -
        o Ryan CABIA sozinho (258 GB de pico contra 276 livres); quem nao
        cabia era o Troy, depois dele. Ou seja: a informacao existia e nao
        estava na tela.

        Agora a conta e feita aqui, na ordem da fila, do jeito que o motor
        decide: cada arquivo exige 3,15x o proprio tamanho DURANTE a
        conversao, e deixa a saida ocupando o disco quando termina. O
        resultado vai inteiro para a pergunta do Iniciar. #>
    $plano = Get-PlanoDoDisco -Videos $ativos -Livre $livre
    $script:DiscoCabem               = [int]$plano.Cabem
    $script:DiscoNaoCabem            = [int]$plano.NaoCabem
    $script:DiscoPrimeiroFora        = "$($plano.PrimeiroFora)"
    $script:DiscoFaltaNoPrimeiroFora = [double]$plano.FaltaNoPrimeiroFora
    <#  17.01: o painel de disco tambem e frase montada, linha por linha, e
        ficava inteiro em portugues numa tela em ingles. Cada linha passa
        pelas regras de padrao - o rotulo traduz, o numero fica onde esta. #>
    $UI.txtDisco.Text = (
        (Traduzir-Frase ("Espaço Necessário Estimado : ~{0}{1}" -f (Format-GB $preciso), $porQue)) + "`n" +
        (Traduzir-Frase ("Espaço Livre em {0,-11}: {1}" -f $raizDrive.TrimEnd('\'), (Format-GB $livre))) + "`n" +
        (Traduzir-Frase $terceira))
    <#  17.16 - A CONTA CERTA JA ESTAVA FEITA, E NINGUEM OLHAVA.

        Caso real, 13/09 10h13. A tela deu verde-amarelo ("Espaço Suficiente,
        Mas o Disco Vai Ficar Apertado"), o Diego apertou F1, o GOT converteu
        em 10 minutos - e o Ryan morreu no comeco da vez dele:

            [NAO INICIADO] Espaco Insuficiente. Necessario ~258,26 GB,
            Disponivel 255,31 GB. Faltam ~2,95 GB.

        Ele reclamou com razao: "quando dei inicio falou q tinha 10% livre, no
        final era pra ter ocorrido de boa, NAO PODE ACONTECER ISSO".

        E o mais irritante: a simulacao que pega isso existe desde a 16.93,
        dez linhas acima. Ela percorre a fila NA ORDEM e desconta do disco o
        que cada conversao DEIXA na saida - foi assim que ela viu que, depois
        dos 19 GB do GOT, o Ryan nao caberia mais.

        O que faltava era ligar o resultado dela na decisao. A pergunta do
        Iniciar (16.91) so disparava com $DiscoFalta > 0, e $DiscoFalta vem da
        conta AGREGADA - max(soma do lote, pico de um arquivo) contra o livre
        de AGORA. Essa conta nao sabe que o disco encolhe entre um arquivo e
        o outro, entao deu positivo e calou a boca.

        Duas contas, e a que estava sendo ouvida era a que nao sabia do
        problema. Agora a fila que nao cabe INTEIRA e um estado por si - com
        ou sem sobra agregada - e ele aparece na barra e na pergunta. #>
    if ($script:DiscoNaoCabem -gt 0 -and $sobra -ge 0) {
        Set-BarraDisco 101
        $UI.lblDiscoMsg.Text = Traduzir-Frase (
            "$($Sim.Warn) Cabe Agora, Mas Não Até o Fim: {0} de {1} Arquivo(s) da Fila Não Vão Começar." -f `
            $script:DiscoNaoCabem, ($script:DiscoCabem + $script:DiscoNaoCabem))
        $UI.lblDiscoMsg.Foreground = Pincel $Cores.lar
    } else {
        Set-BarraDisco $pct
    }
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
    $ordem = @("dovi_tool", "DeeZy", "PgsToSrt", "Tesseract", "mkvmerge")   # 2.0.7: sem seconv
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
        <#  17.15: o painel inteiro de FERRAMENTAS ficava em portugues na
            tela em ingles - rotulo, papel e as duas frases de ausencia. Ele
            e montado por codigo, como todo o resto que a varredura da arvore
            nao alcanca, e por isso traduz na hora em que e escrito. #>
        $r1 = New-Object System.Windows.Documents.Run
        $r1.Text = "$marca " + (Traduzir-Frase "$($f.Rotulo)"); $r1.Foreground = Pincel $cor
        $papelTxt = Traduzir-Frase "$($f.Papel)"
        $r2 = New-Object System.Windows.Documents.Run
        $r2.Text = if ($f.Ok) { "  · " + $papelTxt }
                   <#  O carregador da tabela faz Trim nos rotulos exatos
                       (so as REGRAS mantem o espaco das pontas), entao o
                       espaco de separacao fica aqui, fora da frase. #>
                   elseif ($ehObrigatoria) { "  · " + $papelTxt + " " + (Traduzir "- NÃO ENCONTRADA, A CONVERSÃO NÃO RODA") }
                   else { "  · " + $papelTxt + " " + (Traduzir "- não encontrada, esta parte é pulada") }
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
    <#  2.0.12: abaixo de 20% o ritmo NAO manda mais. No OCR do Ryan (23/09
        12:16) a ferramenta ficou 90 s parada em 10-11% e a conta 95s/0,11
        projetou 860 s de etapa: o restante subiu de 1.867 para 2.403 s e
        depois despencou. A etapa real levou 336 s (previsto 233). Com pouca
        amostra vale o catalogo; se o relogio passar dele, o relogio (abaixo). #>
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
    $msg = Traduzir-Frase $(
           if ($PctUso -le 70) { "$($Sim.Ok) Espaço em Disco Suficiente para Converter Todos os Vídeos da Fila." }
           elseif ($PctUso -le 85) { "$($Sim.Skip) Espaço Suficiente, Mas o Disco Vai Ficar Apertado Durante a Conversão." }
           elseif ($PctUso -le 100) { "$($Sim.Warn) No Limite: Sobra Menos de 10% do Disco no Pico da Conversão." }
           else { "$($Sim.Err) Espaço Insuficiente - Vídeos Podem Ser Ignorados por Falta de Espaço." })
    # 16.86: a barra e o texto acima falam do MESMO fato; quem diz quanto
    # falta e a linha "Falta Liberar", nao esta - repetir o numero aqui seria
    # a mesma informacao em dois lugares (a queixa mais antiga do Diego).
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
    # 17.15: o rodape inteiro e montado por codigo - nenhuma destas linhas
    # passava pela traducao (o Diego: "comecou decorrido deve terminar por
    # volta das tempo restante tudo isso ainda nao tem traducao").
    $UI.lblTemposEtapa.Text = Traduzir-Frase ("Começou: {0}   Decorrido: {1}   {2} PAUSADO POR VOCÊ há {3}" -f
        $d.HoraEtapa, (Format-MinSeg $wallEtapa), $Sim.Pausa, (Format-MinSeg $d.SegPausado))
    $UI.lblTemposFila.Text = Traduzir-Frase ("Começou: {0}   Decorrido: {1}" -f
        $d.HoraFila, (Format-MinSeg $wallFila))
    $Janela.Title = "$NOME_APP  ·  " + (Traduzir-Frase ("PAUSADO - {0}% - Sem Consumir CPU/Disco" -f [int]$d.PctEtapa))
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
    Set-BotaoIniciar $ini
    $UI.btnPausar.IsEnabled   = $run -or $pau
    $UI.btnCancelar.IsEnabled = $run -or $pau
    # 16.45: "Abrir Origem" e "Abrir Saída" valem SEMPRE - inclusive com a
    # fila rodando, que e justamente quando da vontade de ir olhar o que ja
    # saiu. Eles nao mexem em nada, so abrem o Explorer.
    $UI.btnReler.IsEnabled    = $ini

    # Toggle Pausar/Retomar (F2 unico)
    if ($pau) {
        $UI.lblPausar.Text = "[F2] " + (Traduzir "Retomar"); $UI.icoPausar.Text = $Sim.Atual
        $UI.btnPausar.Foreground  = Pincel $Cores.warn
        $UI.btnPausar.Background  = Pincel $Cores.pausaFundo
        $UI.btnPausar.BorderBrush = Pincel $Cores.pausaBorda
    } else {
        $UI.lblPausar.Text = "[F2] " + (Traduzir "Pausar"); $UI.icoPausar.Text = $Sim.Pausa
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
        <#  17.03: o NOME DA ETAPA vinha do motor, que fala so portugues, e
            era escrito na tela sem passar pela traducao - a tela em ingles
            mostrava "Extraindo Video Puro do MKV". Achado do Diego no print
            de 09/09. Agora as quatro escritas do rotulo traduzem. #>
        $UI.lblEtapaNome.Text = if ($Motor.Fase) { "$($Sim.Pausa) " + (Traduzir-Frase $Motor.Fase) }
                                else {
                                    $iP = [math]::Max(0, [math]::Min($Cfg.Etapas.Count - 1, $Motor.EtapaIdx))
                                    "$($Sim.Pausa) " + (Traduzir-Frase $Cfg.Etapas[$iP])
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
            $Motor.PausadoVideo = [double]$Motor.PausadoVideo + $dur   # 2.0.7: a pausa sai do tempo do arquivo
            $Motor.PausaIni = $null
            # 2.0.10: o filtro do tempo restante desconta o relogio desde a
            # ultima leitura - e a ultima leitura foi ANTES da pausa. Sem isto,
            # a primeira conta depois de retomar tirava a pausa inteira do
            # restante (40 min restantes + 60 de pausa = "Terminando Agora").
            $script:SuaveEm = Get-Date
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
                    $Janela.Title = "$NOME_APP  ·  " + (Traduzir-Frase ("Pronto para Converter - {0} Vídeo(s) na Fila" -f $n)) }
        "rodando" { Fill-Fila "rodando"
                    $UI.btnPausar.Focus() | Out-Null }
        "pausado" { Fill-Fila "pausado"
                    $UI.btnPausar.Focus() | Out-Null
                    $Janela.Title = "$NOME_APP  ·  " + (Traduzir-Frase ("PAUSADO - {0}% - Sem Consumir CPU/Disco" -f [int]$Motor.PctEtapa)) }
        "fim"     { $script:LinhasFila.Clear(); $script:AssinaturaFila = $null; $UI.btnNovaConversao.Focus() | Out-Null }
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
            SegPausado = 0; LivreGB = 404.99; LivreGBSaida = -1.0; LivreDiscoO = ""; LivreDiscoS = ""; HoraFila = ""; HoraVideo = ""; HoraEtapa = ""
            VideoNome = ""; VideoIdx = 0; VideoTotal = 0; SegFila = 0
            # T0* sao relogios de PAREDE. O motor manda tempo LIQUIDO (sem as
            # pausas), que serve pra estimar o que falta; mas "Começou 13h54 /
            # Decorrido 06m30s" as 14h16 nao fecha conta nenhuma na cabeca de
            # quem le. Entao: Decorrido = parede, e a pausa aparece do lado.
            T0Fila = $null; T0Video = $null; T0Etapa = $null; T0Diag = $null
            # 17.00: "ha um arquivo em andamento agora". Relogio ligado nao
            # quer dizer arquivo rodando - ver Fechar-MedidaDoVideo.
            MedidaAberta = $false
            PctUltimo = -1; PctUltimoEm = $null; LivreEm = $null
            VidaEm = $null; VidaCpuMs = 0.0; VidaPct = 0; VidaNomes = ""; VidaEmVida = $null
            # 16.49: a prova de vida agora tem DONO. VidaChave guarda de qual
            # etapa/fase veio a ultima medicao; quando o dono muda, a leitura
            # velha e descartada em vez de vazar pra etapa seguinte.
            VidaChave = ""; VidaSemMedida = $true
            LogPctUltimo = -100; LogPctEm = $null; PausadoEtapa = 0.0; PausaIni = $null; PausadoVideo = 0.0
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
                      <#  2.0: o mkvextract saiu do instalador (provado na auditoria: nenhuma
          referencia no motor - quem extrai o video puro e o ffmpeg). Procurar
          um processo que nunca nasce e lista que envelheceu calada, licao 37. #>
      "mkvmerge","PgsToSrt","java",
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
        <#  2.0.10: o que enche durante a conversao e o disco da ORIGEM (os
            temporarios nascem ao lado do arquivo); a saida so recebe o .mkv
            final. Mesmo disco: um numero, como sempre. Discos diferentes: os
            dois, cada um com o nome dele. #>
        $alvoS = if ($Cfg.Saida) { $Cfg.Saida } else { $script:PastaScript }
        $alvoO = if ($Cfg.Origem) { $Cfg.Origem } else { $alvoS }
        $raizO = [System.IO.Path]::GetPathRoot($alvoO); $raizS = [System.IO.Path]::GetPathRoot($alvoS)
        $Motor.LivreGB = (Get-PSDrive -Name ($raizO.TrimEnd('\','/').TrimEnd(':')) -ErrorAction Stop).Free / 1GB
        $Motor.LivreGBSaida = -1.0
        $Motor.LivreDiscoO = $raizO.TrimEnd('\'); $Motor.LivreDiscoS = $raizS.TrimEnd('\')
        if ($raizS.TrimEnd('\').ToUpperInvariant() -ne $raizO.TrimEnd('\').ToUpperInvariant()) {
            try { $Motor.LivreGBSaida = (Get-PSDrive -Name ($raizS.TrimEnd('\','/').TrimEnd(':')) -ErrorAction Stop).Free / 1GB } catch { $Motor.LivreGBSaida = -1.0 }
        }
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
    <#  17.13 - DEPOIS DO CANCELAR, O RODAPE MENTIA POR ATE 21 SEGUNDOS.

        Medido nos logs de 11/09: o motor levou 14,6s e 21,0s para encerrar
        depois do pedido, porque ele so checa o cancelamento ENTRE etapas e
        estava no meio da medicao de camada (~21s). Nao e travamento - e o
        tempo de a etapa em curso chegar ao fim, e nao da para interromper um
        processo externo no meio sem deixar lixo.

        O problema era outro: durante esses segundos o rodape continuava
        anunciando "Extraindo Video Puro do MKV", e depois a faxina com o
        mesmo texto. O usuario le a TELA, nao o log - e a tela dizia que
        estava trabalhando no que ele acabou de mandar parar.

        A checagem mora AQUI, no pulso, e nao numa linha escrita uma vez no
        clique: o rodape e reescrito a cada tique, e qualquer texto posto
        fora daqui seria apagado no tique seguinte. Quando o estado sai de
        rodando, a condicao deixa de valer sozinha. #>
    if ($script:Controle.Cancelar -and $Estado.Atual -in @("rodando","pausado")) {
        $UI.lblEtapaNum.Text = "·"
        $UI.lblEtapaNome.Text = "$($Sim.Pausa) " + (Traduzir "Cancelando - esperando a etapa atual terminar e limpando os temporários...")
        $UI.lblEtapaNome.Foreground = Pincel $Cores.warn
    }
    elseif (-not $d.VideoNome) {
        $UI.lblEtapaNome.Foreground = Pincel $Cores.foco
        $UI.lblEtapaNum.Text = "-/$nEt"
        $UI.lblEtapaNome.Text = "$($Sim.Atual) " + (Traduzir-Frase "Preparando o motor...")
    } elseif ($d.Fase) {
        $UI.lblEtapaNome.Foreground = Pincel $Cores.foco
        # 16.37: diagnostico e limpeza nao tem numero - e essa a informacao.
        # Antes elas ocupavam a caixa "1/7" e "7/7" e o usuario contava sete
        # etapas onde havia cinco de trabalho.
        $UI.lblEtapaNum.Text = "·"
        $UI.lblEtapaNome.Text = "$($Sim.Atual) " + (Traduzir-Frase "$($d.Fase)")
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
        $UI.lblEtapaNome.Foreground = Pincel $Cores.foco
        $UI.lblEtapaNum.Text = $script:UltimoRotuloEtapa
        $nomeEtapa = "$($Sim.Atual) " + (Traduzir-Frase $Cfg.Etapas[$iEt])
        if ($d.Nota) { $nomeEtapa += "   ·   " + (Traduzir-Frase "$($d.Nota)") }
        $UI.lblEtapaNome.Text = $nomeEtapa
    }
    # Decorrido de PAREDE, pra fechar com o "Começou". Sem o "(pausado XX)" que
    # eu punha aqui: alem de o relogio de parede ja incluir a pausa, a palavra
    # lida na tela parecia ESTADO ("está pausado") quando era historico.
    $wallEtapa = if ($d.T0Etapa) { ((Get-Date) - $d.T0Etapa).TotalSeconds } else { $d.SegEtapa }
    <#  2.0.10: O TEMPO DE TRABALHO DA ETAPA NAO INCLUI A PAUSA.
        Log do Diego, 23/09 02:36: pausou 29s logo no comeco da etapa 4 (OCR).
        As contas da barra e do tempo restante usavam o relogio de PAREDE da
        etapa. Com a ferramenta em 4% e 36s de parede (29 deles parados), a
        fracao pelo relogio deu 48% - o video foi a 86%. Quando o OCR chegou
        a 20% de verdade, a conta virou 67s/0,20 = 335s de etapa: o video
        VOLTOU para 84% e o restante SUBIU de 196s para 422s.
        A calibragem ja descontava a pausa desde a 2.0.7; o rodape nao.
        O "Decorrido" da tela continua de parede (fecha com o "Comecou"). #>
    $pausaAgoraEt = if ($d.PausaIni) { ((Get-Date) - $d.PausaIni).TotalSeconds } else { 0.0 }
    $trabEtapa = [math]::Max(0.0, $wallEtapa - [double]$d.PausadoEtapa - $pausaAgoraEt)

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
    $UI.lblTemposEtapa.Text = Traduzir-Frase ("Começou: {0}   Decorrido: {1}   {2}" -f
        $d.HoraEtapa, (Format-MinSeg $wallEtapa), $txtVida)
    $UI.lblGerado.Text = ""
    # Quem esta convertendo e o que o MOTOR anunciou ("ARQUIVO n/N"), nao o
    # primeiro da lista - com fila de varios videos os dois divergem.
    $UI.lblVideoNome.Text = if ($d.VideoNome) { $d.VideoNome } else { Traduzir "(aguardando o motor)" }
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
    <#  17.15: o NOME DA ETAPA e traduzido na origem, sozinho. Colado dentro
        de "[3/4] <nome>" ele nunca casaria: a tabela tem o nome exato, e
        Traduzir-Frase so casa a frase INTEIRA (a parte que casa por pedaco
        sao as regras). Foi assim que "A Seguir: [3/4] Conversao de Legenda"
        ficou em portugues na tela em ingles - o teste executado pegou. #>
    $prox = if ("$($d.Fase)" -match "(?i)limpando")  { if ($ultimoDaFila) { "Resumo da Conversão" } else { "Próximo Vídeo da Fila" } }
            elseif ("$($d.Fase)" -match "(?i)conferindo") { "Limpeza dos Temporários" }
            elseif ("$($d.Fase)" -match "(?i)diagn")  {
                $pri = if ($totA -gt 0) { $planoA[0] } else { 0 }
                "[1/{0}] {1}" -f $totA, (Traduzir "$($Cfg.Etapas[$pri])")
            }
            elseif ($proxIdx -ge 0) {
                "[{0}/{1}] {2}" -f (Get-PosicaoNoPlano $proxIdx), $totA, (Traduzir "$($Cfg.Etapas[$proxIdx])")
            } else { "Conferência do Arquivo Final e Limpeza" }
    # 19.6: cada pedaco traduzido UMA vez (antes o texto ja em ingles passava
    # de novo pelas regras de padrao).
    $UI.lblASeguir.Text = (Traduzir-Frase "A Seguir: ") + (Traduzir-Frase $prox)
    # Contadores calculados AQUI, antes de qualquer linha que os use - eu tinha
    # posto a conta depois e a linha da FILA sairia com o numero vazio.
    $nTotal = [math]::Max(1, $d.VideoTotal)
    $nAtual = [math]::Min($nTotal, $d.VideoIdx + 1)

    $wallVideo = if ($d.T0Video) { ((Get-Date) - $d.T0Video).TotalSeconds } else { $d.SegVideo }
    $UI.lblTemposVideo.Text = Traduzir-Frase ("Começou: {0}   Decorrido: {1}" -f
        $d.HoraVideo, (Format-MinSeg $wallVideo))

    $wallFila = if ($d.T0Fila) { ((Get-Date) - $d.T0Fila).TotalSeconds } else { $d.SegFila }
    $txtFila = "Começou: {0}   Decorrido: {1}" -f $d.HoraFila, (Format-MinSeg $wallFila)
    if ($d.VideoTotal -gt 1) { $txtFila += "   Vídeo {0} de {1}" -f $nAtual, $nTotal }
    $UI.lblTemposFila.Text = Traduzir-Frase $txtFila

    # (os contadores foram calculados no inicio desta funcao)
    $UI.lblVideoNum.Text = "$nAtual/$nTotal"
    $UI.lblFilaNum.Text  = "$nAtual/$nTotal"
    if ([double]$d.LivreGBSaida -ge 0) {
        $UI.lblLivreAgora.Text = Traduzir-Frase ("Livre Agora {0} {1:N2} GB · {2} {3:N2} GB" -f $d.LivreDiscoO, $d.LivreGB, $d.LivreDiscoS, $d.LivreGBSaida)
    } else {
        $UI.lblLivreAgora.Text = Traduzir-Frase ("Livre Agora {0:N2} GB" -f $d.LivreGB)
    }
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
        $fracAgora = Get-FracaoDaEtapa $d.EtapaIdx ([double]$pct) $trabEtapa
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
        $prevAgora = Get-PrevistoAjustadoDaEtapa $d.EtapaIdx ([double]$pct) $trabEtapa
        $restEtapa = [math]::Max(0.0, $prevAgora - $trabEtapa)
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
        $UI.lblTemposFila.Text = Traduzir-Frase $txtFila
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
    $Janela.Title = "$NOME_APP  ·  " + (Traduzir-Frase ("Convertendo$rotuloFila - $tituloEtapa - $pct%"))
}

$TimerPausa.add_Tick({
    if ($script:Fechando) { return }
    $Motor.SegPausado += 1
    $Motor.PausadoFila += 1     # 16.68: este NAO zera a cada etapa
    Update-TemposPausa
})

# Relogio da FILA: corre do Iniciar ate o resumo, em qualquer estado. Sem ele o
# tempo total do resumo teria que ser adivinhado a partir do tempo do video.
$TimerFilaRelogio = New-Object System.Windows.Threading.DispatcherTimer
$TimerFilaRelogio.Interval = [TimeSpan]::FromSeconds(1)
$TimerFilaRelogio.add_Tick({
    if ($script:Fechando) { return }
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
<#  2.0.10: A PAUSA QUE ATRAVESSA UMA TROCA DE ETAPA.
    O motor so para no proximo ponto de consulta - entao e comum o [F2] cair e,
    logo atras, chegar a mensagem de etapa nova que ja estava na fila. As duas
    trocas zeravam $Motor.PausaIni COM A TELA AINDA PAUSADA: ao retomar, a
    pausa inteira nao ia nem para a etapa nem para o arquivo, e contava como
    trabalho (barra, restante e calibragem). Agora o pedaco ja pausado vai para
    as contas, e o relogio da pausa recomeca na etapa nova. #>
function Dobrar-PausaEmCurso {
    if (-not $Motor.PausaIni) { return }
    $durP = ((Get-Date) - $Motor.PausaIni).TotalSeconds
    if ($durP -gt 0) {
        $Motor.PausadoEtapa = [double]$Motor.PausadoEtapa + $durP
        $Motor.PausadoVideo = [double]$Motor.PausadoVideo + $durP
    }
    $Motor.PausaIni = Get-Date
}
function Get-PausaIniDaEtapaNova {
    if ($Estado.Atual -eq "pausado") { return (Get-Date) }
    return $null
}

function Fechar-EtapaNoLog {
    Dobrar-PausaEmCurso
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
    <#  2.0: e aqui que a calibragem por etapa APRENDE. Este e o unico ponto
        do programa em que se sabe, ao mesmo tempo, qual etapa terminou, quanto
        ela tinha sido prevista e quanto ela realmente custou de trabalho -
        parede menos pausa. Era o dado que faltava, e ele ja estava calculado
        aqui desde a 16.39; so ninguem o guardava. #>
    # 2.0.7: etapa interrompida pelo ESC nao e medida - no TROTF (00:45) a
    # legenda cancelada gravou "fator 0,30" e baixou a proxima estimativa.
    if ($pesoDaEtapa -gt 0 -and $liquido -ge 2 -and -not $script:Controle.Cancelar) {
        Registrar-FatorDaEtapa $Motor.EtapaIdx $liquido
    }
    $Motor.T0Etapa = $null
    $Motor.PausadoEtapa = 0.0; $Motor.PausaIni = Get-PausaIniDaEtapaNova
}

$TimerFila.add_Tick({
    if ($script:Fechando) { return }

    <#  ========================================================================
        18.20 - A PORCENTAGEM VOLTOU A SER DE TEMPO, PORQUE A MEDIDA PROVOU QUE
                O ARQUIVO NAO SERVE.

        A 18.17 trocou a conta de tempo por bytes de RPU escritos, com um
        argumento que parecia certo: o arquivo cresce com o trabalho. Os logs
        dele desmentiram, tres vezes:

          17:21:40  "o RPU parou de crescer (parado em 0,0 MB)"   <- 100s assim
          17:22:43  "voltou a crescer"
          17:23:23  "parou de crescer (parado em 86,7 MB)"

        O dovi_tool NAO escreve o RPU aos poucos: ele junta tudo e grava no
        fim. Por isso a barra dele ficava em 0% quase o censo inteiro e pulava
        para 99% no final - "a % nao conta, fica 0%, como vou saber se chegou a
        90%?" (Diego, 17/09). Ele esta certo: aquilo nao era progresso, era um
        interruptor com dois estados.

        Entao a conta volta a ser a que ele mesmo tinha proposto - o tempo
        contra o previsto, e o previsto sai da amostra daquele arquivo vezes o
        fator medido NESTA maquina, que se corrige a cada censo (4,7x no log
        dele, cinco vezes seguidas). Passando do previsto vira "(+)" e continua
        contando, que e honesto: a previsao e uma media, e disco ocupado atrasa.

        O tamanho do RPU nao foi jogado fora - ele so mudou de funcao: nao
        serve como PROGRESSO, mas e otimo como PROVA no fim (RPU muito menor do
        que este filme deveria dar = censo truncado, a trava da 18.19).

        LICAO 43: medida boa no lugar errado continua sendo medida errada.
        ======================================================================== #>
    <#  18.22: o relogio nao escreve mais o rotulo - ele so avisa o dono que
        passou mais um segundo. Uma vez por SEGUNDO, nao por batida: repintar
        um texto identico 4x por segundo foi o que gerou os defeitos da 18.06
        e da 18.11. #>
    if ($script:CensoRodando -and $script:CensoT0) {
        $segCenso = [int]((Get-Date) - $script:CensoT0).TotalSeconds
        if ($segCenso -ne $script:CensoSegMostrado) {
            $script:CensoSegMostrado = $segCenso
            try {
                $iSel = $UI.lstFila.SelectedIndex
                Update-BotaoCenso $(if ($iSel -ge 0 -and $iSel -lt $script:Videos.Count) { $script:Videos[$iSel] } else { $null })
            } catch { }
        }
    }

    <#  18.22: a cada batida, o handle preso do censo anterior e liberado se o
        trabalho dele ja acabou. Barato e local (le uma propriedade, nao
        consulta processo nenhum) - ver Liberar-CensoOrfao. #>
    try { [void](Liberar-CensoOrfao) } catch { }

    <#  18.17 - A MEDICAO VOLTA SOZINHA. A PROMESSA PASSOU A TER DONO.

        MEDIDO no log dele de 17/09 (16:45:08 -> 16:45:27, e de novo 16:49:45 ->
        16:49:59): ele desligou e religou a chave enquanto uma medicao encerrava,
        e a janela respondeu "a nova comeca assim que ela sair" - TRES vezes. Ela
        nao comecava: quem religava a medicao era a proxima troca de chave dele,
        e nao o fim da anterior. A frase era uma promessa que ninguem cumpria.

        E a licao 34 outra vez, agora na medicao: estado que espera por um evento
        trava quando o evento nao chega. A decisao "posso comecar agora?" olha o
        ESTADO, uma vez por segundo, e nao depende de mais nenhum clique. #>
    $script:TiqueConta = ($script:TiqueConta + 1) % 10
    if ($script:TiqueConta -eq 0 -and
        $script:MedirELLigado -and (-not $script:MedindoEL) -and (-not $script:MedPS) -and
        (-not $script:Lendo) -and $Estado.Atual -eq "inicial") {
        if (@(Get-PendentesDeMedida).Count -gt 0) {
            Escrever-Log "MEDICAO: a anterior saiu e a chave continua ligada - comecando a que ficou esperando" "LEITURA"
            Start-Medicao
        }
    }

    $m = $null
    while ($script:FilaMsg.TryDequeue([ref]$m)) {
        <#  18.00 - O PORTAO DO NUMERO DE SERIE, NUM LUGAR SO.

            Stop-Medicao nao espera o runspace morrer (e por isso a janela nao
            congela mais), entao uma medicao cancelada ainda pode ter mensagem
            no ar. Se a pasta for relida nesse meio tempo, a fila e OUTRA - e um
            "el" atrasado, carregando o indice da fila velha, gravaria veredicto
            certo no ARQUIVO ERRADO. Isso e pior que veredicto nenhum.

            O filtro fica aqui, antes do switch, e nao dentro de cada ramo: tres
            guardas espalhados divergem, um guarda no portao nao tem como. E
            "continue" aqui e num laco comum, sem a ambiguidade que ele tem
            dentro de um switch do PowerShell. #>
        if (@("el_ini","el","el_fim") -contains "$($m.T)") {
            if ([int]$m.Serie -ne [int]$script:MedSerie) {
                <#  18.03: o "el_fim" de uma rodada velha NAO traz veredicto
                    nenhum - traz a noticia de que aquele trabalho morreu. Ela
                    tem que ser ouvida, senao o handle do runspace nunca fecha
                    e a proxima medicao fica presa em "a anterior ainda esta
                    encerrando" para sempre (aconteceu no log dele as 23:26:38).
                    Descartar a mensagem e diferente de ignorar o fim. #>
                if ("$($m.T)" -eq "el_fim") {
                    Escrever-Log ("MEDICAO: ignorada a sobra da rodada {0} (a de agora e a {1})" -f [int]$m.Serie, [int]$script:MedSerie) "LEITURA"
                    Fechar-Runspace-Medicao
                    Fechar-MedicaoPendente
                    Update-BotaoMedirEL
                    <#  E se a chave esta ligada e ficou gente sem veredicto na
                        lista NOVA, agora da para comecar - o handle saiu. #>
                    if ($script:MedirELLigado -and -not $script:Lendo) { Start-Medicao }
                }
                continue
            }
        }
        <#  18.04: o censo tem o mesmo portao da medicao. Ele demora 105s e a
            pasta pode ter sido trocada no meio - sem isto o resultado cairia
            pelo indice na lista nova. Rodada velha nao escreve nada; so
            descarta o runspace, que e o unico recado util que ela ainda tem. #>
        <#  18.05 - O CENSO ABANDONADO NAO PERDE MAIS O RESULTADO.

            "esse censo nunca acaba, sei la?" (Diego, 17/09). No log dele:
            00:22:43 pediu o censo; depois apertou Iniciar e o censo foi
            encerrado NA TELA; as 00:23:12 o resultado chegou - 104 segundos de
            trabalho ja feito - e eu JOGAVA FORA porque a rodada tinha virado.
            Ele viu o botao voltar e nunca viu numero nenhum. Duas vezes.

            Descartar por rodada faz sentido para nao escrever na linha errada.
            Mas quem garante a linha certa agora e o CAMINHO do arquivo: o
            resultado foi medido NELE, nao na posicao dele. Se ele ainda esta na
            lista, o numero vale. Se nao esta, nao ha onde escrever. #>
        if ("$($m.T)" -eq "censo_fim") {
            $iC = Achar-LinhaPorCaminho "$($m.Caminho)" ([int]$m.Idx)
            if ($iC -lt 0) {
                Escrever-Log ("CENSO: o arquivo contado nao esta mais na lista - resultado descartado ({0})" -f "$($m.Caminho)") "LEITURA"
                $script:CensoRodando = $false; $script:CensoMudo = $false
                Fechar-Runspace-Censo
                Reset-BotaoCenso
                continue
            }
            <#  18.19 - CENSO CANCELADO NAO TEM RESULTADO. NUNCA.

                O DEFEITO MAIS GRAVE DESDE QUE O CENSO EXISTE, e ele e meu, de
                duas versoes atras. Log dele de 17/09:

                  17:39:23,6  CENSO COMPLETO pedido para o Saving Private Ryan
                  17:39:26,1  F11 - cancelado, 3 processos encerrados
                  17:39:26,4  "2953 quadro(s) no RPU, 11 cena(s), RPU 1,05 MB"
                  17:39:26,4  "1 de 11 cena(s) do FILME INTEIRO (9,09%)"

                O filme tem 243.760 quadros, 1.124 cenas e 19,22% acima do
                master. O censo cancelado dois segundos depois de comecar
                escreveu 11 cenas e 9% NA TELA, como verdade medida - por cima
                do numero certo.

                A causa: ate a 18.13 cancelar era ABANDONAR, e um resultado que
                chegasse depois era legitimo (o trabalho tinha terminado
                sozinho). Da 18.14 em diante cancelar MATA o dovi_tool no meio
                da escrita - entao o que sobra no disco e um RPU PELA METADE, e
                o motor, que so confere "o arquivo existe e nao esta vazio",
                devolve Ok=true. Eu troquei o significado do cancelamento e nao
                troquei esta regra junto.

                Duas travas, porque uma so nao basta:

                  1. se ESTE censo foi morto por nos, o resultado e descartado
                     sem discussao - nao existe censo parcial valido;
                  2. e mesmo sem ter sido morto, um RPU muito menor que o
                     previsto para a duracao do filme e um censo truncado. E a
                     mesma desconfianca que a bancada de 08/09 documentou: o
                     dovi_tool devolve "Done." em arquivo cortado, e quem
                     desconfia e o LaFirma. #>
            if ([bool]$m.Ok -and $script:CensoMorto -and
                "$($m.Caminho)" -eq "$($script:CensoCaminho)") {
                Escrever-Log ("CENSO COMPLETO: resultado DESCARTADO - este censo foi cancelado por voce e o RPU ficou pela metade ({0:N2} MB, {1} cena(s)). O veredicto anterior continua valendo." -f `
                    [double]$m.RpuMb, [int]$m.Cenas) "AVISO"
                $script:CensoRodando = $false
                Fechar-Runspace-Censo
                Reset-BotaoCenso
                continue
            }
            if ([bool]$m.Ok -and $script:CensoBytesPrev -gt 0 -and
                ([double]$m.RpuMb * 1MB) -lt ($script:CensoBytesPrev * 0.5)) {
                Escrever-Log ("CENSO COMPLETO: resultado DESCARTADO - o RPU saiu com {0:N2} MB e este filme deveria dar cerca de {1:N2} MB. Censo cortado no meio nao vira veredicto." -f `
                    [double]$m.RpuMb, ($script:CensoBytesPrev / 1MB)) "AVISO"
                $script:CensoRodando = $false
                Fechar-Runspace-Censo
                Reset-BotaoCenso
                continue
            }
            <#  18.21 - A TERCEIRA PORTA DO CENSO CANCELADO, QUE EU NAO TINHA FECHADO.

                "acho q o censo quebrou, aperte F11 duas vezes para cancelar e
                deu q ele terminou de ler ja com resultado" (Diego). A 18.19
                fechou a porta do Ok=true; o log dele de 21:55:33 mostra a que
                ficou aberta - a do Ok=FALSE:

                  21:55:33,913  cancelamento - 2 processo(s) encerrado(s)
                  21:55:33,965  cancelado de verdade
                  21:55:34,093  "encerrado a pedido - o dovi_tool foi parado"
                  21:55:34,093  "terminou depois de o botao ter sido encerrado
                                 - o RESULTADO VALE e esta na tela"

                180 milissegundos de censo, e a ultima linha diz ao usuario que
                o que esta na tela e o resultado DISSO. Isso aconteceu 14 vezes
                nesse log. O veredicto na tela ate era o antigo e certo - mas a
                frase afirma uma coisa que a janela nao conferiu, e frase que
                afirma sem conferir e mentira mesmo quando acerta (licao 2).

                A causa e a de sempre: esta linha nasceu na 18.04, quando
                cancelar era ABANDONAR e o trabalho realmente terminava sozinho
                - ali ela era verdade. Da 18.14 em diante cancelar MATA, e eu
                atualizei as regras que olhavam Ok=true e nao esta (licao 42, de
                novo, no mesmo lugar). Agora a pergunta vem antes do Serie: ESTE
                CENSO FOI MORTO POR NOS? Se foi, nao ha resultado - de nenhum
                jeito, com Ok nenhum. #>
            if ($script:CensoMorto -and "$($m.Caminho)" -eq "$($script:CensoCaminho)") {
                Escrever-Log "CENSO COMPLETO: cancelado por voce - nao ha numero novo. O veredicto que esta na tela e o anterior e continua valendo." "LEITURA"
                $script:CensoRodando = $false; $script:CensoMudo = $false
                Fechar-Runspace-Censo
                Reset-BotaoCenso
                continue
            }
            if ([int]$m.Serie -ne [int]$script:CensoSerie) {
                Escrever-Log "CENSO COMPLETO: terminou depois de o botao ter sido encerrado - o resultado vale e esta na tela (o arquivo e o mesmo)" "LEITURA"
            }
            $m.Idx = $iC
        }
        if (@("leitura_ini","leitura_pct","vazio","video","leitura_fim") -contains "$($m.T)") {
            if ([int]$m.SerieL -ne [int]$script:LeituraSerie) {
                if ("$($m.T)" -eq "leitura_fim") {
                    Escrever-Log ("LEITURA: ignorada a sobra da rodada {0} (a de agora e a {1})" -f [int]$m.SerieL, [int]$script:LeituraSerie) "LEITURA"
                }
                continue
            }
        }
        switch ($m.T) {
            "log"   {
                <#  18.14: censo encerrado a pedido nao e falha. O motor nao
                    sabe que foi de proposito - ele so ve que o RPU nao saiu -
                    e escreveria "FALHOU" em vermelho por um cancelamento que
                    foi o usuario quem pediu. Mensagem que mente e defeito
                    mesmo quando mente para o lado do alarme (licao 2). #>
                if ($script:CensoMorto -and "$($m.Texto)" -match "CENSO COMPLETO.*(FALHOU|nao produziu RPU)") {
                    Escrever-Log "CENSO COMPLETO: encerrado a pedido - o dovi_tool foi parado, nao houve falha" "LEITURA"
                } else {
                    Escrever-Log $m.Texto $m.Tipo
                }
            }
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
                $Motor.PausadoEtapa = 0.0; $Motor.PausaIni = Get-PausaIniDaEtapaNova
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
                # 16.99: aqui termina o video ANTERIOR - e este e o momento em
                # que o tempo real dele existe. Tem que vir ANTES de VideoIdx
                # mudar, senao a medida seria gravada no nome errado.
                Fechar-MedidaDoVideo -Concluido $true
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
                # 2.0.10: o % e a nota da ultima etapa do arquivo anterior nao
                # passam para o novo ("100%" ao lado da etapa 1 do seguinte).
                $Motor.PctEtapa = 0; $Motor.Nota = ""
                # 2.0.12: e o relogio e o restante do arquivo anterior tambem. No
                # log de 23/09 (11:22:45) o rodape do Ryan nasceu com "etapa 105s"
                # (a remontagem do GoT) e o restante pulou 4.943 -> 5.048s.
                $Motor.SegEtapa = 0
                $idxNovoA = [int]$m.Idx
                if ($idxNovoA -ge 0 -and $idxNovoA -lt @($script:LoteAtual).Count) { $Motor.RestVideo = [double]$script:LoteAtual[$idxNovoA].SegEstimado }
                # 16.47: arquivo novo = plano novo. O rotulo da etapa nao pode
                # herdar o "3/3" do arquivo anterior enquanto o novo diagnostica.
                $script:UltimoRotuloEtapa = ""
                # 16.38: trocou de arquivo - a marca de "convertendo" muda de
                # linha, e a anterior vira "Convertido".
                Fill-Fila $Estado.Atual
                $Motor.T0Video = Get-Date
                $Motor.PausadoVideo = 0.0
                # 17.00: a partir daqui existe um arquivo em andamento, e o
                # relogio dele vale como medida quando ele terminar.
                $Motor.MedidaAberta = $true
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
                    # 2.0.7: pausa+retoma rapido - a confirmacao da pausa chegava depois
                    # do clique de retomar e o log parecia dizer que pausou depois.
                    $atraso = if ("$($m.V)" -eq "pausado" -and $Estado.Atual -ne "pausado") { " (confirmacao do pedido anterior - ja retomado)" } else { "" }
                    Escrever-Log ("Motor confirmou '{0}' {1:0} ms depois da tecla/clique{2}" -f $m.V, $lat, $atraso) "PROVA"
                    $script:TsAcao = $null
                }
            }
            "ferr"  {
                $script:Ferramentas = @($m.Lista)
                Update-Ferramentas
                Update-FerramentasTopo
            }
            "vazio" {
                # 19.6: o motivo era escrito aqui e o Update-Disco seguinte
                # apagava com "Nenhum vídeo a converter" - e em portugues.
                $script:MotivoVazio = "$($m.Motivo)"
                $UI.txtDisco.Text = Traduzir-Frase $script:MotivoVazio
            }
            "leitura_ini" { Escrever-Log ("Lendo {0} arquivo(s)..." -f $m.Total) "LEITURA" }
            "leitura_pct" {
                $Janela.Title = "$NOME_APP  ·  " + (Traduzir-Frase ("Lendo {0}/{1} - {2}" -f ($m.Idx + 1), $m.Total, $m.Nome))
            }
            "video" {
                $d = $m.Dados
                <#  16.84: a montagem do texto do Dolby Vision saiu do runspace
                    e veio para ca, onde Format-DolbyVision existe. O runspace
                    manda os DADOS (perfil, codec, camadas, tipo de EL); quem
                    escreve e um lugar so. #>
                if ([int]$d.DVperfil -gt 0) { Update-TextosDV $d }
                $d.TamanhoTxt = Format-GB $d.Bytes
                # Nasce marcado quem tem o que converter de verdade.
                # "Ignorar" cobre so Ja-Existe-na-Saida/Erro-na-Leitura agora
                # (m3c15); "Nada a Converter" nao trava mais o video, entao
                # precisa ser checado aqui em separado pra nao nascer marcado
                # sozinho so por nao estar "Ignorado".
                $d.Marcado = (-not $d.Ignorar) -and ($d.DVprecisa -or $d.AUprecisa -or $d.LGprecisa)
                <#  18.04: se este arquivo JA foi medido nesta sessao e continua
                    igual (mesmo tamanho, mesma data), o veredicto volta com
                    ele. Medir de novo custaria 14 a 26s para chegar ao MESMO
                    numero - e era isso que se perdia a cada releitura. #>
                if ("$($d.ELtipo)" -eq "NAO_MEDIDO" -and (Restaurar-CacheEL $d)) {
                    Escrever-Log ("EL: veredicto reaproveitado da medicao desta sessao - {0} ({1})" -f $d.Nome, $d.ELtipo) "LEITURA"
                }
                [void]$script:Videos.Add($d)
                Fill-Fila "inicial"
                if ($UI.lstFila.SelectedIndex -lt 0) { $UI.lstFila.SelectedIndex = 0 }
                Update-CabecalhoFila
                Update-Disco
            }
            "el_ini" {
                <#  17.19: uma fonte so para "quem esta medindo agora" e para
                    "quantos ja foram". Os tres lugares da tela que falam disso
                    - a linha da fila, o rotulo do botao e a barrinha - passam
                    a ler estes mesmos numeros, que vem do laco que mede. #>
                $script:ELmedindoIdx = [int]$m.Idx
                $script:ELtotal      = [int]$m.Total
                $script:ELfeitos     = [int]$m.Pos - 1
                Fill-Fila "el"
                Update-BotaoMedirEL
            }
            "el" {
                <#  16.77: chega UM arquivo medido. Reescreve so o que a
                    medicao decide - rotulo, resposta, cor e coluna - e
                    redesenha. O resto da linha ja estava certo desde a fase A. #>
                $i = Achar-LinhaPorCaminho "$($m.Caminho)" ([int]$m.Idx)   # 18.05: a linha e do arquivo, nao da posicao
                if ($i -ge 0 -and $i -lt $script:Videos.Count) {
                    $v = $script:Videos[$i]
                    $v.ELtipo = "$($m.Tipo)"; $v.ELselo = "$($m.Selo)"; $v.ELmotivo = "$($m.Motivo)"
                    $v.ELmaxcll = [double]$m.MaxCLL; $v.ELmaxfall = [double]$m.MaxFALL
                    $v.ELdm = "$($m.Dm)"; $v.ELpontos = "$($m.Pontos)"
                    $v.ELexpande = $m.Expande
                    $v.ELcenas = [int]$m.Cenas; $v.ELcenasAcima = [int]$m.CenasAcima
                    $v.ELpicoCena = [double]$m.PicoCena
                    $v.L5bordas = "$($m.L5)"; $v.L5formato = "$($m.L5Formato)"
                    $v.ELregua = "$($m.Regua)"
                    $v.ELctnMaxCLL = [int]$m.CtnMaxCLL
                    $v.ELctnMaxFALL = [int]$m.CtnMaxFALL
                    $v.ELreguaSuspeita = [bool]$m.ReguaSuspeita
                    $v.ELreguaSuspeitaMotivo = "$($m.ReguaSuspeitaMotivo)"
                    $v.ELpctAcima = [double]$m.PctAcima
                    $v.ELmastermax = [double]$m.MasterMax
                    $v.ELsegundos = [double]$m.Seg
                    $v.L5area = "$($m.L5Area)"
                    # 16.84: rotulo, coluna e nome de faixa saem todos daqui.
                    Update-TextosDV $v
                    $alvoDV = Format-DolbyVision -Perfil 8 -Level "$($v.DVlevel)" -Alvo
                    <#  16.79 - A LINHA DO DV VIROU DADO, NAO PARAGRAFO.

                        A 16.78 despejava tres oracoes de explicacao na linha
                        do diagnostico ("a EL carrega imagem e o L1 descreve
                        BL+EL... o DoVi_Scripts trata esse caso"). Aula no
                        lugar errado: a linha do diagnostico e onde o usuario
                        olha para DECIDIR, e nome de ferramenta de terceiro e
                        licao de tone mapping nao ajudam a decidir nada ali.
                        As duas coisas continuam existindo - no manual, que e
                        onde se aprende, e no log, que e onde se audita.

                        O que fica na tela e o que MUDA A DECISAO, no mesmo
                        formato do resto do programa (sigla + numero medido):

                          MEL  ->  EL sem imagem · descarte sem perda
                          FEL  ->  EL com imagem · L1 153 / master 1000 nits

                        No FEL o par L1/master e a informacao inteira: L1 bem
                        abaixo do master = a EL nao expande brilho. E o numero
                        que separa o FEL comum do FEL que incomoda, e esta ali,
                        medido, em vez de descrito. #>
                    $selo = "[SERÁ CONVERTIDO]"
                    $alvo = $alvoDV.Longo
                    $nota = ""
                    $v.DiagDVcor = "verde"
                    <#  16.81 - O NUMERO TINHA QUE DIZER O QUE ELE SIGNIFICA.

                        "L1 153 / master 1.000 nits" era dado cru: quem le nao
                        sabe se 153 contra 1.000 e bom ou ruim. E era a
                        pergunta inteira - o Diego perguntou, com razao,
                        "quando da certo descartar a EL e quando nao?".

                        A resposta esta nesses dois numeros, e agora a frase a
                        diz. O L1 e o pico de brilho que a TV vai receber como
                        instrucao; o master e o pico que o filme foi feito para
                        ter. L1 abaixo do master = a EL nao esta levantando
                        brilho nenhum, entao descarta-la nao pede a TV nada que
                        o arquivo nao entregue. L1 no ou acima do master = ela
                        esta, e ai a TV vai tone mapear para um brilho que
                        deixou de existir. Esse e o caso que doi.

                        Continua RESSALVA nos dois casos, porque o residual de
                        imagem da EL se perde de qualquer jeito - mas a frase
                        agora separa "ressalva de rotina" de "olhe este". #>
                    if ($m.Tipo -eq "MEL") {
                        # 16.84: a sigla na RESPOSTA, nao so no rotulo. Na foto
                        # do Diego a linha do Troy dizia "EL vazia - descarte
                        # sem perda" e nao trazia "MEL" em lugar nenhum.
                        $nota = " — MEL: EL vazia, descarte sem perda"
                    } elseif ($m.Selo -eq "RESSALVA" -or $m.Selo -eq "EXPANDE") {
                        <#  16.88 - EU QUEBREI ISTO NA 16.87 (achado do Diego,
                            no print do Saving Private Ryan).

                            Na 14.43 criei no motor um selo NOVO, "EXPANDE",
                            para o Complex FEL - e aqui continuei testando so
                            "RESSALVA". O Ryan passou a cair no ramo final,
                            que nao mexe em nada: linha VERDE, "[SERÁ
                            CONVERTIDO]" e nenhuma palavra sobre a EL. O pior
                            resultado possivel - o unico arquivo perigoso dos
                            tres saiu pintado como o mais seguro.

                            A sigla [EL: FEL] no rotulo ficou vermelha porque
                            ela le $v.ELtipo, que chegou certo. Duas partes da
                            mesma linha discordando: o sintoma exato de dado
                            que chega e ramo que nao trata.

                            Licao para a bateria: eu testei o TEXTO das duas
                            frases e nao testei o CAMINHO ate elas. Teste de
                            texto nao pega ramo nao percorrido. #>
                        <#  16.86 - TRES NIVEIS, TRES CORES (pedido do Diego).

                            Ate a 16.85 todo FEL saia da mesma cor. Mas FEL
                            nao e um estado so, e o proprio Diego apontou:
                            "o GOT e FEL tanto quanto o Ryan, mas o do Ryan e
                            mais forte". Esta certo, e o numero prova - GOT
                            pede 153 de 1.000 nits; Ryan pede 1.608 de 1.000.
                            Pintar os dois igual e apagar a unica diferenca
                            que importa.

                            A escala agora acompanha a decisao:

                              verde    MEL              pode converter
                              laranja  FEL sem expansao pode, perde residual
                              vermelho FEL com expansao pense antes

                            Vermelho aqui NAO quer dizer "bloqueado" - o
                            arquivo converte se o usuario mandar. Quer dizer
                            "este e o caso que estraga a imagem", que e o
                            unico lugar do programa onde essa cor cabe fora
                            de erro. O ambar fica para o que nao foi medido:
                            duvida nao e o mesmo que ressalva conhecida. #>
                        $selo = "[SERÁ CONVERTIDO COM RESSALVA]"
                        $v.DiagDVcor = "laranja"
                        $nota = " — FEL: EL com imagem, descartada"
                        if ($m.Tipo -eq "MISTO") { $nota = " — MEL e FEL na mesma amostra" }
                        <#  16.87 - QUEM DECIDE E O MOTOR, NAO A TELA.

                            Ate a 16.86 a janela refazia a conta aqui com o
                            master que ELA tinha lido, enquanto o motor fazia
                            a mesma conta com o dele. Duas contas para um
                            fato so - e o console e a janela ja tinham saido
                            com frases diferentes sobre o mesmo Ryan.
                            Agora o motor manda Expande junto com a medida e
                            a tela so escolhe cor e palavra. #>
                        $l1 = [double]$m.MaxCLL; $mst = [double]$v.DVmaster
                        if ($null -ne $m.Expande -and $l1 -gt 0 -and $mst -gt 0) {
                            if ($m.Expande -eq $true) {
                                $selo = "[CONVERSÃO NÃO RECOMENDADA]"
                                $v.DiagDVcor = "vermelho"
                                $nota = " — FEL: a camada extra levanta o brilho"
                                $nota += (" · o arquivo pede {0:N0} nits e o master é {1:N0}" -f $l1, $mst)
                            } else {
                                $nota = " — FEL: a camada extra tem imagem, descartada"
                                $nota += (" · o arquivo pede {0:N0} nits, dentro dos {1:N0} do master" -f $l1, $mst)
                            }
                            <#  16.85 - QUANTAS VEZES, NAO SO SE.

                                A frase acima diz SE o pico passa do master. O
                                censo do L1 (dovi_tool export --levels, 2.3.3)
                                diz QUANTAS das cenas lidas passam - e isso
                                muda a decisao: um pico isolado numa cena e
                                outra coisa de metade do filme acima da regua.
                                So entra na tela quando ha o que contar; caso
                                contrario nao ha o que dizer e a linha nao
                                cresce a toa. #>
                            <#  16.87 - "em 1/3 cenas" SAIU DA TELA.

                                O Diego leu e perguntou se o filme tinha tres
                                cenas. Nao tem: eram tres cenas da AMOSTRA, de
                                tres trechos de dois segundos. Numero que
                                precisa de um paragrafo para nao enganar nao
                                cabe na linha da decisao - e, pior, eu ja sei
                                que essa amostra e pequena demais para virar
                                estatistica (3 a 4 cenas por filme).
                                Ele continua no log, escrito por extenso, ate
                                a amostra ser grande o bastante para a conta
                                significar alguma coisa. #>
                        } elseif ($l1 -gt 0) {
                            <#  16.96 - SEM REGUA, A LINHA DIZ O QUE SOBRA.

                                Ate aqui a frase parava em "pico do master não
                                declarado" e o usuario ficava com um numero
                                solto e nenhuma referencia. Os numeros do
                                CONTAINER estavam lidos, no mesmo ffprobe, e
                                nao apareciam em lugar nenhum.

                                Eles entram - e entram DITOS COMO SAO. O
                                MaxCLL do container e medido por histograma e
                                o L1 e MaxRGB: sao grandezas diferentes, e
                                compara-las e o erro que a licao 15 proibiu
                                aqui. Por isso a frase nao os coloca lado a
                                lado como se fossem a mesma coisa - ela diz
                                "outra régua", e o FAQ explica por que.

                                O que eles dao: uma nocao de quao claro o
                                filme e, que serve para comparar este arquivo
                                com outro e decidir na mao. Nao respondem se a
                                EL levantava brilho, e a linha nao finge que
                                respondem. #>
                            $nota += (" · L1 pede {0:N0} nits — o master não é declarado, então não há régua" -f $l1)
                            if ([int]$v.ELctnMaxCLL -gt 0) {
                                $nota += (" · o container declara MaxCLL {0:N0} por outra régua (histograma)" -f [double]$v.ELctnMaxCLL)
                            }
                        }
                    } elseif ($m.Tipo -eq "NAO_MEDIDO") {
                        $v.DiagDVcor = "ambar"
                        $nota = " — EL não medida"
                    }
                    <#  16.85 - L5: SO FALA QUANDO HA PROBLEMA.

                        O L5 diz quanto do quadro e borda. Quando ele bate com
                        a imagem nao ha nada a decidir, e a informacao vive no
                        log. Quando NAO bate - proporcao que nao existe em
                        cinema nenhum - o RPU tem crop errado, que e o defeito
                        que o DDVT chama de "bad cropped RPU". Ai vale a tela,
                        porque muda o que o usuario faz.

                        O LaFirma NAO cria esse defeito: "convert --discard"
                        nao toca nos blocos L5. Quando ele aparece, ja veio
                        assim no arquivo de origem - e o aviso diz isso. #>
                    if ("$($v.L5formato)" -match "fora dos formatos comuns") {
                        $nota += (" · borda do RPU (L5) dá {0}, que não é formato de cinema - já vem assim da origem" -f "$($v.L5area)")
                        if ($v.DiagDVcor -eq "verde") { $v.DiagDVcor = "ambar" }
                    }
                    $v.DiagDVres = "→ $selo $alvo$nota"
                    <#  17.20: chegou o veredicto DESTE arquivo - entao ele nao
                        esta mais sendo medido. Quem acende o proximo e o
                        "el_ini" seguinte. Sem isto a linha ficava em ciano ate
                        alguem redesenhar a lista por outro motivo, e no ultimo
                        arquivo nao redesenhava nunca mais: o Diego viu
                        "Medindo Camada - 3 de 3" parado com os tres ja
                        medidos, e leu aquilo como o programa travado. #>
                    if ([int]$m.Idx -eq [int]$script:ELmedindoIdx) { $script:ELmedindoIdx = -1 }
                    <#  18.04: veredicto recem-chegado vai para o cache da sessao. Relendo a
                        pasta, ele volta sem custar outros 14 a 26s. #>
                    Guardar-CacheEL $v
                    Fill-Fila "el"
                    if ($UI.lstFila.SelectedIndex -eq $i) { Update-Diagnostico }
                }
                # 17.14: um a menos na conta da espera (o aviso so se reescreve
                # se ele estiver na tela - Update-AvisoEspera decide isso).
                $script:ELfeitos++
                Update-AvisoEspera
                Update-BotaoMedirEL   # 17.16: o contador do botao anda junto
                <#  17.15 - A ESPERA ACABA QUANDO OS MARCADOS ACABAM.

                    Nao no "el_fim". Se o que sobrou medindo e arquivo
                    desmarcado, ele nao entra nesta conversao e nao ha nada
                    a esperar dele. A medicao restante e interrompida pelo
                    mesmo caminho da chave desligada (os presos viram 'EL nao
                    medida', nunca 'limpa') e a conversao comeca. #>
                if ($script:IniciarAposMedir -and @(Get-MarcadosMedindo).Count -eq 0) {
                    $sobra = @($script:Videos | Where-Object { "$($_.ELtipo)" -eq "MEDINDO" }).Count
                    $script:IniciarAposMedir = $false
                    Update-AvisoEspera
                    $UI.btnIniciar.IsEnabled = $true
                    Escrever-Log ("INICIAR: todos os arquivos DA FILA ja foram medidos - comecando agora ({0} arquivo(s) fora da fila ficaram sem medir)" -f $sobra) "ACAO"
                    Stop-Motor
                    Invoke-IniciarAutomatico
                }
            }
            "censo_fim" {
                <#  17.08 - O CENSO COMPLETO VOLTOU (item A).

                    Ele nao reclassifica MEL/FEL nem repinta por conta
                    propria - a classificacao quem faz e o dovi_tool, pelo
                    el_type do RPU, e o censo nao toca nisso.

                    17.24 - MAS O RESULTADO PRECISAVA CHEGAR NA TELA.

                    "esse censo nao serve pra nada eu acho. nem sei onde ele
                    vai" (Diego, 16/09). Ele estava certo do lugar dele: o
                    numero ia SO para o log, o campo CensoResumo era escrito e
                    nunca lido por ninguem, e na tela o unico sinal era o botao
                    apagando. Ele esperou 105 segundos e nao viu nada mudar.

                    E o numero importava. No teste dele, no Saving Private
                    Ryan, a AMOSTRA dizia 1 de 11 cenas e pico de 1.608 nits;
                    o censo do FILME INTEIRO deu 216 de 1.124 cenas (19,22%) e
                    pico de 3.468 nits. A amostra subestimou o pico em mais de
                    duas vezes.

                    Isto NAO quebra a regra da 16.87, que tirou a contagem da
                    amostra da tela. Ela foi tirada por ser pequena demais para
                    virar estatistica ("3 a 4 cenas por filme"), e o comentario
                    dela mesma diz: volta "ate a amostra ser grande o bastante
                    para a conta significar alguma coisa". O censo E essa
                    condicao cumprida - ele le o filme inteiro. #>
                $i = [int]$m.Idx
                if ($i -ge 0 -and $i -lt $script:Videos.Count -and [bool]$m.Ok) {
                    $v = $script:Videos[$i]
                    $v.CensoFeito = $true
                    $v.CensoCenas = [int]$m.Cenas
                    $v.CensoAcima = [int]$m.CenasAcima
                    $v.CensoPico  = [double]$m.PicoCena
                    $v.ELreguaSuspeita = [bool]$m.ReguaSuspeita
                    $v.ELreguaSuspeitaMotivo = "$($m.ReguaSuspeitaMotivo)"
                    $v.ELpctAcima = [double]$m.Pct
                    $v.CensoResumo = ("{0} de {1} cena(s) do filme inteiro acima do master ({2}%) - {3:N1}s" -f `
                        [int]$m.CenasAcima, [int]$m.Cenas, [double]$m.Pct, [double]$m.Seg)

                    <#  A frase do censo SUBSTITUI a anterior, nunca se soma a
                        ela: rodar o censo duas vezes nao pode empilhar duas
                        contagens na mesma linha. O marcador ' · censo:' e o
                        ponto de corte. #>
                    $resBase = "$($v.DiagDVres)"
                    $corte = $resBase.IndexOf(" · censo:")
                    if ($corte -gt 0) { $resBase = $resBase.Substring(0, $corte) }
                    $frase = (" · censo: {0:N0} de {1:N0} cenas do filme ({2:N0}%) passam do master" -f `
                        [int]$m.CenasAcima, [int]$m.Cenas, [double]$m.Pct)
                    if ([double]$m.PicoCena -gt 0) {
                        $frase += (", pico {0:N0} nits" -f [double]$m.PicoCena)
                    }
                    # 2.0.9: o rotulo "[PERDA EM ...]" da 2.0.7 foi desfeito a pedido do
                    # Diego. O cabecalho de sempre fica; o censo so ACRESCENTA o numero.
                    $resBase = [regex]::Replace($resBase, '\[PERDA EM [^\]]*\]', '[CONVERSÃO NÃO RECOMENDADA]')
                    $v.DiagDVres = $resBase + (Traduzir-Frase $frase)

                    <#  E se o censo CONTRADIZ a amostra, a cor segue o censo -
                        ele e a prova mais forte das duas. O caminho contrario
                        (censo achou menos) NAO reabilita o verde: quem ja foi
                        marcado como expansao de brilho pelo dovi_tool continua
                        marcado; o censo conta cenas, nao reclassifica camada. #>
                    if ([int]$m.CenasAcima -gt 0 -and "$($v.DiagDVcor)" -eq "verde") {
                        $v.DiagDVcor = "ambar"
                        Escrever-Log ("CENSO: a cor subiu para ambar - a amostra nao tinha visto cena acima do master, o filme inteiro tem {0}" -f [int]$m.CenasAcima) "LEITURA"
                    }

                    <#  2.0.1 - E AGORA O CENSO TAMBEM PODE DESCER A GRAVIDADE.
                        ===================================================

                        O paragrafo acima dizia que o caminho contrario "NAO
                        reabilita o verde", e isso continua valendo ao pe da
                        letra: nada aqui vira verde, e a camada NAO e
                        reclassificada - FEL continua FEL.

                        O que passa a existir e o meio do caminho. O veredicto
                        "expande" nasce de UMA comparacao - o pico da cena mais
                        alta contra o pico do master - e uma cena bastava para
                        o arquivo inteiro ficar vermelho. A 16.85 ja tinha
                        escrito o que faltava ("um pico isolado numa cena e
                        outra coisa de metade do filme acima da regua") e a
                        16.87 explicou por que nao dava para usar a amostra:
                        3 a 4 cenas nao viram estatistica. O censo le o filme
                        INTEIRO - e essa condicao cumprida.

                        AS DUAS TRAVAS, E POR QUE SAO DUAS:

                        1. FREQUENCIA - menos de 1% das cenas. Sozinha nao
                           basta: meia dezena de cenas pedindo 4.000 nits num
                           master de 1.000 e rara E grave.
                        2. TAMANHO DO ESTOURO - o pico nao passa do DOBRO do
                           master. E o que separa "o colorista encostou no
                           teto" de "a camada extra levantava o brilho".

                        OS NUMEROS SAO CONVENCAO ANCORADA EM DOIS CASOS
                        MEDIDOS, e esta escrito aqui de proposito para poder
                        ser discutido em vez de virar folclore:
                            Ryan          19,22% e 3,47x -> continua VERMELHO
                            Transformers   0,67% e 1,56x -> pico isolado
                        Dois pontos nao sao uma curva. Se um terceiro caso cair
                        no meio, o lugar de rever e aqui.

                        E o piso de 20 cenas e o mesmo que a regua suspeita ja
                        usa no motor: porcentagem de 5 cenas nao e porcentagem.
                        ==================================================== #>
                    <#  2.0.5 - A COR SEGUE A CLASSIFICACAO, E SO ELA.
                        A 2.0.2 fazia o censo descer um Complex FEL "isolado" de
                        vermelho para laranja. Laranja e a cor do Simple FEL - o
                        Diego leu, com toda razao, que o programa tinha
                        reclassificado o filme ("na primeira analise acha que e
                        FEL completo e depois analisa como FEL medio?"). E o
                        cartao final continuava dizendo "Complex FEL - CONVERSAO
                        NAO RECOMENDADA". Tres partes da tela, tres respostas.
                        Uma cor, um significado: verde MEL, laranja Simple FEL,
                        vermelho Complex FEL. O censo acrescenta NUMEROS a linha
                        (quantas cenas, quanto %), nunca troca a cor. Volta a
                        valer a regra que ja estava escrita acima: "o censo conta
                        cenas, nao reclassifica camada". #>
                }
                if ($i -ge 0 -and $i -lt $script:Videos.Count -and [bool]$m.Ok) {
                    Guardar-CacheEL $script:Videos[$i]   # 18.04: o censo tambem e caro (106s)
                    <#  18.09 - O FATOR DA PREVISAO SE CORRIGE COM A MAQUINA DELE.

                        O 4,7x inicial saiu de tres medicoes no log do Diego, no
                        mesmo arquivo. Isso e amostra pequena e de UM filme -
                        exatamente o tipo de numero que a licao 1 manda nao
                        tratar como verdade eterna. Entao cada censo que termina
                        grava a relacao real medida ali, e a proxima previsao ja
                        sai dessa maquina.

                        Limite de sanidade: so aceita fator entre 2x e 12x. Fora
                        disso o que houve foi outra coisa (cache de disco, censo
                        cancelado no meio), e um numero solto nao pode envenenar
                        a previsao de todos os proximos. #>
                    <#  18.17: e a medida que a PORCENTAGEM usa - bytes de RPU
                        por segundo de filme - se corrige pelo mesmo principio.
                        Limite de sanidade de 2 a 40 KB/s: fora disso o censo
                        foi cortado no meio e o numero nao vale. #>
                    $durFilme = [double]$script:Videos[$i].DurSeg
                    if ($durFilme -gt 0 -and [double]$m.RpuMb -gt 0) {
                        $bytesSeg = ([double]$m.RpuMb * 1MB) / $durFilme
                        if ($bytesSeg -ge 2000 -and $bytesSeg -le 40000) {
                            $script:CensoBytesSeg = $bytesSeg
                            Escrever-Log ("CENSO: o RPU real deu {0:N2} KB por segundo de filme - a porcentagem do proximo ja usa este numero" -f ($bytesSeg / 1KB)) "PROVA"
                        } else {
                            Escrever-Log ("CENSO: {0:N2} KB/s de RPU esta fora dos limites (2 a 40) - a medida NAO foi ajustada" -f ($bytesSeg / 1KB)) "AVISO"
                        }
                    }
                    <#  2.0: AQUI FICAVA UMA SEGUNDA APRENDIZAGEM DO s/s, E ELA
                        ENVENENAVA A PRIMEIRA.
                        A 18.21 aprendia "segundos por segundo de filme" de
                        QUALQUER censo, inclusive de um censo que passou 10
                        minutos preso no disco. Era assim que o Transformers
                        (HD mecanico) ensinava 0,0711 s/s ao proximo filme, que
                        podia estar num SSD. A aprendizagem certa - a que so
                        aprende quando quem mandou no relogio foi a CPU - esta
                        logo abaixo, junto do fator. Duas donas do mesmo numero
                        discordando e a licao 41 de novo: um numero, um dono. #>
                    <#  ====================================================
                        2.0 - "VC BATE NA TECLA QUE EH 1:46 E SEMPRE E UNS 2:20
                        OU MAIS" (Diego, 18/09). Ele esta certo, e a causa sao
                        DOIS RELOGIOS DIFERENTES contando a mesma coisa.

                        MEDIDO no log dele de 17/09 (22:21), o unico censo que
                        chegou ao fim:

                          22:22:53,295  CENSO COMPLETO: lendo o RPU
                          22:25:32,049  243760 quadros | RPU 103,8s + censo
                                        1,1s = 104,9s

                          parede (o que ele ve)  : 158,8s = 2m38s
                          motor (o que reportou) : 104,9s = 1m44s
                          diferenca              :  53,9s

                        A previsao usava o numero do MOTOR (104,9s / 22,5s de
                        amostra = 4,7x) e o cronometro da tela conta do CLIQUE.
                        Os 53,9s que faltam sao o que o motor nao cronometra:
                        abrir cmd, ffmpeg e dovi_tool, e a disputa de disco com
                        a medicao, que naquele log estava rodando junto.

                        Licao 15, que este projeto ja aprendeu com o MaxCLL:
                        COMPARAR SEMPRE REGUA COM A MESMA REGUA. A previsao tem
                        que ser feita no relogio em que ela vai ser conferida -
                        o da tela. Pelo relogio de parede o fator daquele
                        arquivo e 7,06x, e a previsao teria dado 2m38s, que e
                        exatamente o que ele viu.

                        O teto subiu de 12x para 20x pelo mesmo motivo: o fator
                        de parede e naturalmente maior que o de motor, e o
                        limite antigo recusaria medidas boas.
                        ==================================================== #>
                    $amostraSeg = [double]$script:Videos[$i].ELsegundos
                    $segParede = 0.0
                    if ($script:CensoT0) { $segParede = ((Get-Date) - $script:CensoT0).TotalSeconds }
                    <#  2.0b - E ELE SO APRENDE O QUE ELE PODE TER APRENDIDO.

                        O s/s descreve a CPU mastigando o RPU. Quando quem
                        mandou no relogio foi o DISCO, o tempo real nao diz
                        NADA sobre a CPU - gravar esse numero como se fosse
                        s/s de CPU envenenaria a previsao de todo arquivo que
                        vier depois num disco rapido.

                        E a mesma armadilha da licao 15 (regua com regua) e da
                        49 (numero que descreve outra coisa). Entao: so
                        aprende quando a CPU foi o gargalo de verdade. #>
                    if ([double]$v.DurSeg -gt 0 -and $segParede -gt 0) {
                        $gbAp = 0.0
                        if ([double]$v.Bytes -gt 0) { $gbAp = [double]$v.Bytes / 1GB }
                        $discoAp = 0.0
                        if ($gbAp -gt 0 -and [double]$script:CensoDiscoMbs -gt 0) {
                            $discoAp = ($gbAp * 1024.0) / [double]$script:CensoDiscoMbs
                        }
                        $cpuAp = [double]$v.DurSeg * $script:CensoSegPorSegFilme
                        if ($discoAp -gt 0 -and $discoAp -gt ($cpuAp * 1.2)) {
                            Escrever-Log ("CENSO: quem mandou no relogio foi o DISCO ({0} contra {1} de CPU) - o s/s NAO foi ajustado, porque este tempo nao mede a CPU" -f `
                                (Format-MinSeg ([int]$discoAp)), (Format-MinSeg ([int]$cpuAp))) "PROVA"
                        } else {
                            $novoSS = $segParede / [double]$v.DurSeg
                            if ($novoSS -ge 0.003 -and $novoSS -le 0.20) {
                                $script:CensoSegPorSegFilme = $novoSS
                                Escrever-Log ("CENSO: a CPU levou {0:N4}s por segundo de filme - a previsao do proximo ja usa este numero" -f $novoSS) "PROVA"
                            } else {
                                Escrever-Log ("CENSO: {0:N4} s/s fora dos limites (0,003 a 0,20) - o s/s NAO foi ajustado" -f $novoSS) "AVISO"
                            }
                        }
                    }
                    if ($amostraSeg -gt 0 -and $segParede -gt 0) {
                        $fatorReal = $segParede / $amostraSeg
                        if ($fatorReal -ge 2.0 -and $fatorReal -le 200.0) {
                            $script:CensoFator = $fatorReal
                            Escrever-Log ("CENSO: do clique ao resultado foram {0:N1}s ({1:N1}x a amostra); o motor contou {2:N1}s de trabalho. A previsao do proximo usa o relogio da TELA, que e o que voce ve." -f `
                                          $segParede, $fatorReal, [double]$m.Seg) "PROVA"
                        } else {
                            Escrever-Log ("CENSO: relacao de {0:N1}x fora dos limites (2x a 200x) - previsao NAO ajustada" -f $fatorReal) "AVISO"
                        }
                    }
                }
                $script:CensoRodando = $false; $script:CensoMudo = $false
                Fechar-Runspace-Censo
                Reset-BotaoCenso
                Update-Diagnostico
                <#  2.0.4 - O DIAGNOSTICO ERA REDESENHADO E A FILA NAO.
                    =========================================================
                    DEFEITO MEDIDO (Diego, 22/09, fotos das 17h55 e 17h56).
                    No Transformers, depois do censo:
                        a LINHA de baixo virou laranja ("cenas isoladas")
                        a COLUNA de cima continuou VERMELHA
                    A mesma tela dizendo duas coisas sobre o mesmo arquivo -
                    e no log, entre o fim do censo (17:56:43) e a proxima
                    acao dele (17:57:57), NAO existe uma linha "FILA:". A
                    fila nunca foi repintada.

                    A 2.0.2 pos coluna e diagnostico para perguntarem a cor a
                    MESMA funcao (Get-NomeCorEL), e eu tratei isso como
                    resolvido. Nao era: as duas perguntam igual, mas so uma
                    era perguntada DE NOVO. Um dono da regra nao adianta se
                    metade da tela nao volta a consultar.

                    E a licao ja estava escrita neste arquivo, no ramo logo
                    abaixo (17.20): "Estado novo sem redesenho e tela
                    mentindo." O ramo do censo nao a obedecia.
                    ========================================================= #>
                Fill-Fila "el"
            }
            "el_fim" {
                $script:MedindoEL = $false
                # 18.00: o runspace da medicao ja terminou - fechar aqui nao espera nada.
                Fechar-Runspace-Medicao
                $script:ELmedindoIdx = -1   # 17.19: ninguem mais esta na vez
                Update-BotaoMedirEL   # 17.16: apaga a barrinha e devolve o rotulo
                <#  17.20: e a FILA tambem. Apagar a variavel sem redesenhar
                    deixa a linha pintada do jeito que estava - foi assim que
                    "Medindo Camada - 3 de 3" ficou na tela depois de a medicao
                    acabar. Estado novo sem redesenho e tela mentindo. #>
                Fill-Fila "el"
                <#  18.00: quem sobrou em MEDINDO aqui e arquivo que a medicao
                    nao alcancou - porque foi cancelada no meio, ou porque o
                    trabalho falhou. Fechar-MedicaoPendente vira todos em "EL
                    nao medida", que e o terceiro estado honesto de sempre:
                    nao medir NUNCA vira "limpa". #>
                Fechar-MedicaoPendente
                <#  17.10 - A LINHA QUE PERMITE O A/B.

                    Ela sai com os mesmos campos sempre, para poder ser
                    comparada lado a lado no log: quantos arquivos, quantos GB,
                    quantos segundos, e quantos segundos por GB. Sem o "por GB"
                    duas pastas de tamanhos diferentes nao se comparam. #>
                if ([bool]$m.Falhou) {
                    Escrever-Log "MEDICAO MEL x FEL: o trabalho nao conseguiu preparar o ambiente - ninguem foi medido" "ERRO"
                } elseif ([int]$m.Total -gt 0) {
                    $sgb = if ([double]$m.Gb -gt 0) { [double]$m.Seg / [double]$m.Gb } else { 0 }
                    Escrever-Log ("Camada de melhoria medida em {0} de {1} arquivo(s) - {2:N2}s no total" -f $m.Medidos, $m.Total, $m.Seg) "LEITURA"
                    Escrever-Log ("MEDICAO MEL x FEL: LIGADA | {0} arquivo(s) | {1:N2} GB | {2:N2}s | {3:N2} s/GB" -f `
                        [int]$m.Total, [double]$m.Gb, [double]$m.Seg, $sgb) "PROVA"
                }
                <#  18.00: o Iniciar represado sai AQUI. Nao ha mais Stop-Motor
                    antes dele: o runspace da medicao e OUTRO, ja foi fechado
                    acima, e o da leitura nem esta de pe. Isto era a ordem que
                    a 17.11 teve que inventar quando os dois dividiam o mesmo
                    runspace - deixou de ser necessaria. #>
                if ($script:IniciarAposMedir) {
                    $script:IniciarAposMedir = $false
                    Update-AvisoEspera
                    $UI.btnIniciar.IsEnabled = $true
                    Escrever-Log "INICIAR: medicao terminou - comecando a conversao que estava esperando" "ACAO"
                    Invoke-IniciarAutomatico
                }
                if ($script:ReleituraPendente) {
                    $script:ReleituraPendente = $false
                    Start-Leitura
                }
            }
            "leitura_fim" {
                $script:Lendo = $false
                $UI.btnReler.IsEnabled = $true
                Update-BotaoReler
                $ativos = @(Get-Marcados).Count
                Escrever-Log ("Leitura concluida: {0} lido(s), {1} erro(s), {2:N2}s" -f $m.Ok, $m.Erros, $m.Seg) "LEITURA"
                Escrever-Log ("SELECAO: {0} de {1} marcado(s) automaticamente (tem trabalho)" -f $ativos, $script:Videos.Count) "ACAO"
                <#  16.83 - EU QUEBREI O "JA EXISTE NA SAIDA" NA 16.82.

                    Ate a 16.79 quem marcava era a LEITURA, dentro do runspace.
                    Na 16.82 tirei de la (a funcao nao existe naquele mundo) e
                    escrevi, no comentario, que "quem decide e Update-JaExiste,
                    que ja roda depois de toda leitura via Update-Selecao".
                    NAO RODAVA: Update-JaExiste so era chamado quando o usuario
                    TROCAVA a pasta de saida. Depois de uma leitura, ninguem
                    chamava.

                    Efeito, no teste do Diego (05/09 01:30): o GOT ja estava
                    convertido em 01_Arquivos_Finalizados e a janela deixou
                    clicar Iniciar; quem barrou foi o motor, la na frente
                    ("[AVISO] Ja Existe na Pasta de Saida. Pulando."). A tela
                    prometeu um trabalho que nao ia acontecer.

                    Licao para mim: escrever no comentario que algo "ja roda"
                    nao faz rodar. A bateria agora exige esta chamada. #>
                Update-JaExiste
                Fill-Fila "inicial"
                if ($script:Videos.Count -gt 0 -and $UI.lstFila.SelectedIndex -lt 0) { $UI.lstFila.SelectedIndex = 0 }
                Update-Diagnostico
                # m3c23: Update-Selecao ja faz Update-CabecalhoFila e
                # Update-Disco - chamar os dois aqui antes era trabalho dobrado
                # a cada arquivo lido (e Update-Disco estima o tamanho de todos
                # os videos marcados, nao e barato).
                Update-Selecao
                if (Test-PastasIguais) { $Janela.Title = "$NOME_APP  ·  " + (Traduzir "Origem e Saída São a Mesma Pasta") }
                <#  18.00 - A LEITURA ACABA AQUI, SEMPRE. Ate a 17.24 ela
                    continuava viva quando havia camada a medir, porque a
                    medicao rodava dentro dela. Agora sao trabalhos separados:
                    a leitura fecha o runspace dela, e a medicao nasce no seu
                    proprio, logo abaixo. #>
                Stop-Motor
                <#  18.00: a prova do A/B (quanto custou a leitura COM e SEM a
                    medicao) saiu de dentro do runspace e veio para ca, que e
                    onde se sabe se a medicao vai acontecer. Os campos sao os
                    mesmos de sempre, para as duas linhas poderem ser comparadas
                    lado a lado no log - sem o "por GB" duas pastas de tamanhos
                    diferentes nao se comparam. #>
                $semVeredicto = @(Get-PendentesDeMedida)
                if (-not $script:MedirELLigado -and $semVeredicto.Count -gt 0) {
                    $gbSem = 0.0
                    foreach ($v in $semVeredicto) { $gbSem += ([double]$v.Bytes / 1GB) }
                    Escrever-Log ("MEDICAO MEL x FEL DESLIGADA: {0} arquivo(s) ({1:N2} GB) ficaram sem veredicto de camada - aparecem como 'EL nao medida'. A leitura da pasta custou {2:N2}s." -f `
                        $semVeredicto.Count, $gbSem, [double]$m.Seg) "LEITURA"
                    Escrever-Log ("MEDICAO MEL x FEL: DESLIGADA | {0} arquivo(s) | {1:N2} GB | 0,00s | 0,00 s/GB" -f `
                        $semVeredicto.Count, $gbSem) "PROVA"
                }
                if ($script:ReleituraPendente) {
                    $script:ReleituraPendente = $false
                    Start-Leitura
                }
                elseif ($script:MedirELLigado) {
                    <#  A chave decide AQUI, com a fila ja na tela e com a
                        informacao completa - e nao la dentro do runspace, por
                        um parametro congelado no instante da partida. Se nao
                        ha ninguem sem veredicto, Start-Medicao volta na hora
                        sem fazer nada. #>
                    Start-Medicao
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
                # 16.99: e o ULTIMO arquivo da fila tambem so termina aqui.
                # Fila interrompida nao vira calibragem: tempo de conversao
                # cortada no meio nao mede coisa nenhuma.
                Fechar-MedidaDoVideo -Concluido ($m.Como -ne "interrompida")
                $TimerFilaRelogio.Stop()
                $script:Resultados = @($m.Resultados)
                Show-Resumo $m.Como
            }
        }
    }

    <#  18.08 - A ESPERA DO INICIAR DEIXOU DE DEPENDER DE UMA MENSAGEM.

        Log dele: 01:24:08 clicou Iniciar e escolheu ESPERAR a medicao; 01:24:10
        desligou a chave, e a medicao foi cancelada. O aviso "Esperando a
        medicao terminar para comecar..." ficou na tela ate 01:27:04 - quase
        TRES MINUTOS - e o botao Iniciar apagado junto. Ele so se livrou dele
        deixando tudo medir de novo: "eu tive q deixar ver todo FEL pra sumir a
        msg de esperando pra iniciar, estranho, e isso mesmo?". Nao e.

        A espera era desarmada dentro do tratador do "el_fim". Quando essa
        mensagem nao chega - rodada cancelada com serie ja virada, fila
        esvaziada, trabalho abandonado - a espera fica pendurada para sempre.
        Amarrar estado a um EVENTO que pode nao vir e a mesma familia do
        defeito anterior.

        Agora quem decide olha o ESTADO, uma vez por batida do relogio: se ha
        espera armada e nao ha mais medicao rodando, a espera acabou - por bem
        ou por mal - e a conversao comeca. Evento que chegar antes so adianta o
        mesmo desfecho. #>
    if ($script:IniciarAposMedir -and (-not $script:MedindoEL) -and $Estado.Atual -eq "inicial") {
        $script:IniciarAposMedir = $false
        Update-AvisoEspera
        # 19.6: o ramo do el_fim reacendia o botao e este nao - se o Iniciar
        # automatico desistisse (nada marcado), o botao ficava apagado.
        Set-BotaoIniciar (@(Get-Marcados).Count -gt 0)
        Escrever-Log "INICIAR: a medicao terminou (ou foi cancelada) - comecando a conversao que estava esperando" "ACAO"
        Invoke-IniciarAutomatico
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
        # 19.6: o Profile 5 sai em .mp4 e nao passa por audio/OCR (motor 14.9
        # manda StatusAudio/StatusLegenda = "P5", que nenhum switch abaixo pega).
        "P5_MP4"         { $selos += ,@("Dolby Vision Profile 5 → MP4 - REMUXADO", "ok") }
    }
    <#  17.09 - O CARTAO FINAL REPETE A RESSALVA DA CAMADA.

        Pergunta do Diego em 10/09, olhando o cartao do Ryan: "um Ryan sair
        todo verde assim seria o justo?". Nao seria. O programa tinha dito,
        no diagnostico e no log, [CONVERSAO NAO RECOMENDADA] - FEL com
        expansao de brilho, 1.608 nits pedidos contra 1.000 do master - e o
        cartao final fechou com quatro selos verdes e mais nada.

        As duas afirmacoes eram verdadeiras: a conversao fez tudo o que
        prometeu, E o arquivo era um caso de ressalva. Mostrar so a primeira
        e mentir por omissao, e o cartao final e a ULTIMA coisa que o usuario
        le - se a ressalva nao estiver ali, ela nao existiu.

        O selo NAO diz que a conversao falhou: ela nao falhou. Ele diz o que
        o arquivo era. Por isso o verde do Profile 8.1 continua ao lado dele. #>
    switch ("$($R.SeloEL)") {
        "EXPANDE"  {
            # 2.0.9: o selo de sempre (o "PERDA EM" da 2.0.7 foi desfeito).
            $selos += ,@("Complex FEL - CONVERSÃO NÃO RECOMENDADA", "err")
        }
        "RESSALVA" { $selos += ,@("Simple FEL - CONVERSÃO COM RESSALVA", "warn") }
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
    <#  16.87 - DESCARTAR E UMA ACAO, NAO UMA AUSENCIA (pedido do Diego).

        Estes quatro selos saiam em CINZA, ao lado de tres selos verdes. No
        Troy o cinza dizia "Áudios e Legendas Extras - DESCARTADOS" logo
        depois de o programa ter, de fato, escolhido entre 33 faixas e
        descartado as que nao serviam - trabalho feito, e feito certo.

        Cinza neste programa quer dizer "nada aconteceu aqui". Aconteceu:
        o descarte e metade do motivo de o arquivo final ser menor e tocar
        em TV. Agora os quatro sao verdes, como os outros tres. #>
    if ($R.DescarteAudio -and $R.DescarteLegenda) {
        $selos += ,@("Áudios e Legendas Extras - DESCARTADOS", "ok")
    } elseif ($R.DescarteAudio) {
        $selos += ,@("Áudios Extras - DESCARTADOS  ·  Legendas - TODAS MANTIDAS", "ok")
    } elseif ($R.DescarteLegenda) {
        $selos += ,@("Legendas Extras - DESCARTADAS  ·  Áudios - TODOS MANTIDOS", "ok")
    } else {
        $selos += ,@("Áudios e Legendas - TODOS MANTIDOS (Modo Seguro)", "ok")
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
        <#  18.07 - A MESMA CONDICAO NAO PODE TER DUAS CORES.

            "essa ultima imagem e igual sempre quando ta cheio o disco?
             amarelo? to vendo inconsistencia" (Diego, 17/09). Ele esta certo:
            o painel de ESPACO EM DISCO pinta "Espaco Insuficiente" de VERMELHO,
            e o cartao do resumo pintava o MESMO fato de ambar, porque olhava so
            o status "PULADO" - que cobre dois casos muito diferentes:

              ja existia na saida   -> informacao, nada a fazer   (ambar)
              nao coube no disco    -> IMPEDIMENTO, o arquivo nao saiu (vermelho)

            Cor e vocabulario neste programa: ambar avisa, vermelho impede. #>
        "PULADO"     {
            if (Test-PuladoPorEspaco $R) {
                $fundo = "#110809"; $borda = $Cores.errBorda; $ico = $Sim.Err; $corNome = $Cores.txt
            } else {
                $fundo = "#100E08"; $borda = $Cores.pausaBorda; $ico = $Sim.Skip; $corNome = $Cores.txt
            }
        }
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
            # 17.12: o selo tambem e texto de tela, montado por codigo.
            $st.Text = Traduzir-Frase ([string]$par[0]); $st.FontSize = 12.5; $st.Foreground = $bc.ConvertFromString($ft)
            $selo.Child = $st; $selos.Children.Add($selo) | Out-Null
        }
        $pilha.Children.Add($selos) | Out-Null

        $fpsTxt = Format-Fps "$($R.Fps)"
        # A leitura do arquivo final custa uma chamada de mkvmerge por video,
        # em um momento em que a conversao ja acabou - e o unico jeito de o
        # cartao falar do arquivo que existe, e nao do que se pretendia fazer.
        <#  2.0: o arquivo final agora sai com o selo [BL+RPU] no nome. O
            cartao tem que ler o arquivo QUE EXISTE - com o nome do
            episodio ele leria um caminho que nao existe mais e o cartao
            voltaria a falar do que se pretendia, nao do que saiu. O motor
            manda o nome real em NomeSaida; sem ele (Profile 5, resultado
            antigo) vale o Episodio, como antes. #>
        $nomeFinalCartao = "$($R.Episodio)"
        if ("$($R.NomeSaida)" -ne "") { $nomeFinalCartao = "$($R.NomeSaida)" }
        $descFinal = Get-DescricaoDoFinal (Join-Path $Cfg.Saida ("{0}.mkv" -f $nomeFinalCartao))
        $txtAudio = "-"
        if ($descFinal.Audio) { $txtAudio = $descFinal.Audio }
        elseif ($R.FaixasAudioMantidas) { $txtAudio = "$($R.FaixasAudioMantidas)" }
        elseif ("$($R.StatusDV)" -eq "P5_MP4" -and $R.MotivoAudio) { $txtAudio = "$($R.MotivoAudio)" }
        $txtLegenda = "-"
        if ($descFinal.Legenda) { $txtLegenda = $descFinal.Legenda }
        elseif ($R.FaixasLegendaMantidas) { $txtLegenda = "$($R.FaixasLegendaMantidas)" }
        elseif ("$($R.StatusDV)" -eq "P5_MP4" -and $R.MotivoLegenda) { $txtLegenda = "$($R.MotivoLegenda)" }
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
                <#  ============================================================
                    2.0b - "ESSA FRASE TA CERTA? OU IMPRIMI ISSO EM TUDO?"
                    (Diego, 21/09, sobre o Transformers.)

                    A conta estava certa e a FRASE estava grande demais.

                    MEDIDO na legenda que ele mandou: 1.832 blocos, e a tela
                    disse "1 falha em 1832". O denominador confere - o .srt tem
                    1.832 blocos mesmo. Mas varrendo o arquivo achei treze
                    coisas que qualquer pessoa chamaria de erro e que o contador
                    NAO conta, entre elas:

                      "Ali Spark"  (5x)   deveria ser AllSpark
                      "cal no mundo cruel"  -> "cai"
                      "waiffle" -> "waffle"   "A.OA,," -> "A.O.A."
                      "firmeca", "Blim-blom", "Sob o meu comando" (maiuscula)

                    Nao e defeito do contador: ele mede o que o Reocr SABE
                    detectar - a familia de defeito residual de OCR (a barra
                    vertical, bloco cortado, linha vazia). Nome proprio trocado
                    e letra trocada que forma outra palavra valida passam, e
                    sempre passaram.

                    O defeito e a frase. "Nenhuma falha encontrada" afirma o
                    ABSOLUTO; o que o programa pode afirmar e o que ele CONFERIU.
                    Licao 2, e licao 11 (nao afirmar em publico capacidade que
                    o codigo nao tem) - desta vez a afirmacao era para o dono. #>
                <#  2.0.2: a frase da 14.55 dizia a coisa certa e dizia mal - tres oracoes,
                    primeira pessoa e um "vale passar o olho" que soava a desculpa.
                    O conteudo continua identico: o que foi conferido, e o que o
                    contador nao alcanca. Em duas oracoes e sem falar de si. #>
                "EXCELENTE" { $acao = "Pode assistir por esta legenda." }   # 2.0.7: "nenhum defeito" ao lado de "(1 falha em 1832)" - Diego ja tinha reclamado da frase
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
            <#  17.16: a linha da qualidade e colagem - veredicto em caixa
                alta + frase + numeros entre parenteses. Traduzir a linha
                inteira nunca casaria: cada pedaco vai por si, e os numeros
                ficam onde estao. Foi ela que saiu em portugues no cartao em
                ingles do Diego ("RUIM - Prefira a legenda PGS original"). #>
            $linhaQualidade = @("Qualidade da Legenda",
                ((Traduzir $vq) + "  -  " + (Traduzir $acao) + (Traduzir-Frase $det)), $corQ)
        }
        $grade = @(
            @("Container Final", ((&{ if ("$($R.StatusDV)" -eq "P5_MP4") { "MPEG-4 (.mp4)  |  {0}" } else { "Matroska (.mkv)  |  {0}" } }) -f $R.Tamanho)),
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
            # 17.12: o rotulo da grade tambem e texto de tela. Ele era montado
            # por codigo e por isso nunca passou pela varredura de traducao -
            # em ingles a tabela inteira ficava em portugues.
            $r1.Text = Traduzir-Frase ([string]$linha[0]); $r1.FontSize = 13.5
            $r1.TextWrapping = "Wrap"
            $r1.Foreground = $bc.ConvertFromString($Cores.dim)
            $celRot.Child = $r1

            $celVal = New-Object System.Windows.Controls.Border
            $celVal.BorderBrush = $fio
            $celVal.BorderThickness = "0,0,0,$baixo"
            $celVal.Padding = "10,4,0,4"
            $r2 = New-Object System.Windows.Controls.TextBlock
            $r2.Text = Traduzir-Frase ([string]$linha[1]); $r2.FontSize = 13.5
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
        <#  17.11 - "IGNORADO - JA EXISTIA" ERA CHUTE, NAO LEITURA.

            O print do Diego, 10/09 23h56, com as duas frases na MESMA caixa:

              Situacao  Ignorado - Ja Existia na Pasta de Saida
              Motivo    espaco insuficiente - faltam ~47,68 GB

            O motor tem TRES caminhos de PULADO - ja existia na saida (dois
            deles) e espaco insuficiente - e todos carregam o motivo escrito
            no proprio resultado. A tela ignorava esse campo e chumbava o
            primeiro caso. Uma frase que contradiz a linha de baixo e pior do
            que nao ter frase nenhuma.

            Agora o rotulo sai do MOTIVO. Mesma regra que a 15.1d ja tinha
            aprendido com as cores: ler o dado gravado, nunca deduzir. #>
        $frase = switch ($status) {
            "PULADO"    { Get-FrasePulado $R }
            "CANCELADO" { "Cancelado pelo Usuário" }
            default     { "Não Finalizado - Erro" }
        }
        $corFrase = if ($status -eq "PULADO" -and -not (Test-PuladoPorEspaco $R)) { $Cores.warn } else { $Cores.err }   # 18.07
        Add-LinhaTxt $pilha ("{0}   {1}" -f (Traduzir "Situação"), (Traduzir-Frase $frase)) $corFrase 13.5 $true 2
        $motivoTela = Get-MotivoPulado $R
        if ($motivoTela -ne "") { Add-LinhaTxt $pilha ("{0}     {1}" -f (Traduzir "Motivo"), $motivoTela) $corFrase 13.5 }
        if ("$($R.Tempo)")  { Add-LinhaTxt $pilha ("{0}      {1}" -f (Traduzir "Tempo"), $R.Tempo) $Cores.dim 13.5 }
    }
    return $b
}

<#  17.11 - QUAL PULADO E ESTE.

    Tres caminhos no motor, tres frases. A do espaco tambem diz que o arquivo
    NEM COMECOU - e a diferenca entre "nao fiz" e "comecei e parei", que o
    Diego ja tinha cobrado na 14.44 do lado do motor. #>
function Test-PuladoPorEspaco($R) {
    return ([bool]("$($R.Motivo)" -match "(?i)espaco insuficiente|espaço insuficiente"))
}

<#  17.12 - O MOTIVO IA PARA A TELA COMO O MOTOR ESCREVEU.

    "espaco insuficiente - faltam ~46,80 GB": minusculo no comeco e sem
    cedilha. O motor e ASCII puro por contrato (a bateria reprova acento
    nele), entao o texto dele NUNCA vai servir de frase de tela - ele e o
    DADO, e quem escreve a frase e a janela. Mesma divisao do resto: o motor
    decide, a tela redige. #>
function Get-MotivoPulado($R) {
    $m = "$($R.Motivo)"
    if ($m -eq "") { return "" }
    if (Test-PuladoPorEspaco $R) {
        <#  2.0.10: o motor agora diz QUAL disco faltou ("espaco insuficiente
            em C: - faltam ~X"): o da origem (temporarios) ou o da saida (o
            arquivo final). A frase nomeia o disco em vez de chutar "saida". #>
        $discoM = ""
        if ($m -match '(?i)insuficiente em ([A-Z]:)') { $discoM = $Matches[1].ToUpper() }
        if ($m -match '~\s*([\d.,]+\s*[KMGT]B)') {
            $qto = $Matches[1]
            if ($discoM) { return (Traduzir-Frase ("Faltam ~{0} livres no disco {1}" -f $qto, $discoM)) }
            return (Traduzir-Frase ("Faltam ~{0} livres no disco de saída" -f $qto))
        }
        return (Traduzir "Não há espaço livre suficiente no disco de saída")
    }
    if ($m -match "(?i)ja existia|já existia") {
        return (Traduzir "O arquivo convertido já estava na pasta de saída")
    }
    # Motivo que a tela ainda nao conhece: sai como veio, mas com a primeira
    # letra em maiuscula - nunca de cara minuscula no meio do cartao.
    if ($m.Length -ge 1) { return ($m.Substring(0,1).ToUpper() + $m.Substring(1)) }
    return $m
}

function Get-FrasePulado($R) {
    if (Test-PuladoPorEspaco $R) { return "Não Iniciado - Espaço Insuficiente em Disco" }
    if ("$($R.Motivo)" -match "(?i)ja existia|já existia") { return "Ignorado - Já Existia na Pasta de Saída" }
    if ("$($R.Motivo)" -ne "") { return "Ignorado" }
    return "Ignorado - Já Existia na Pasta de Saída"
}

<#  17.15 - O CARTAO FINAL FICAVA CONGELADO NA LINGUA EM QUE NASCEU.

    "diagnostico final quando cancelado ainda fica em pt mesmo mudando pra
    ingles no final... fechei e depois uma parte ficou em ingles e outra
    parte nao."

    Ele estava certo nas duas metades. Set-Idioma ja redesenhava a fila, o
    diagnostico, o disco e as faixas - tudo que e montado por codigo. O
    cartao final era o unico painel montado por codigo que ficou de fora,
    porque so existe depois que a conversao acaba. Trocar de lingua ali nao
    mexia nele, e a tela ficava meio a meio.

    A funcao ja e idempotente (limpa a pilha e remonta do $script:Resultados),
    entao o redesenho e ela mesma, com uma trava: no redesenho ela NAO
    reescreve o log, NAO copia o log para a pasta de saida e NAO mexe no
    estado - trocar de idioma nao e uma conversao nova. E a hora e o tempo
    ficam guardados, senao o cartao passaria a mentir a cada troca de lingua,
    dizendo que a conversao terminou agora.

    Licao velha do projeto (16.93 / 17.02 / 17.05): o que a varredura de
    traducao nao alcanca e o que o CODIGO escreve, e cada um desses precisa
    ser redesenhado por nome. Esta e a lista completa. #>
$script:LoteSegEstimado = 0.0
$script:ResumoComo  = ""
$script:ResumoHora  = ""
$script:ResumoSeg   = -1.0

function Redesenhar-Resumo {
    if ("$($script:ResumoComo)" -eq "") { return }
    # 2.0.10: so existe resumo para redesenhar na tela do fim. Depois de "Nova
    # Conversao" o ResumoComo continuava cheio - trocar o idioma na tela
    # inicial punha no titulo o resultado da fila anterior.
    if ($Estado.Atual -ne "fim") { return }
    try { Show-Resumo $script:ResumoComo -Redesenho } catch { }
}

function Show-Resumo([string]$Como, [switch]$Redesenho) {
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
    if ($Redesenho) {
        # 17.15: hora e tempo sao do FIM da conversao, nao do momento em que
        # a lingua foi trocada.
        $totalSeg = [double]$script:ResumoSeg
        $agora    = "$($script:ResumoHora)"
    } else {
        $totalSeg = [math]::Max(0, $Motor.SegFila)
        if ($Motor.T0Fila) {
            $paredeFila = ((Get-Date) - $Motor.T0Fila).TotalSeconds
            if ($paredeFila -gt $totalSeg) { $totalSeg = $paredeFila }
        }
        $agora = (Get-Date).ToString("HH'h'mm")
        $script:ResumoComo = $Como
        $script:ResumoHora = $agora
        $script:ResumoSeg  = $totalSeg
    }
    $tempoTxt  = Format-MinSeg $totalSeg

    if ($Como -eq "concluida") {
        $UI.icoResumo.Text = $Sim.Ok
        $UI.icoResumo.Foreground = $bc.ConvertFromString($Cores.ok)
        # 17.15: os dois tambem sao texto de tela escrito por codigo.
        $UI.lblResumoTitulo.Text = Traduzir "Conversão Concluída"
        $Janela.Title = "$NOME_APP  ·  " + (Traduzir-Frase ("Conversão Concluída às {0}" -f $agora))
        $UI.lblResumoTempos.Text = Traduzir-Frase ("Começou às {0} - Terminou às {1} - Tempo Total {2}" -f `
            "$($Motor.HoraFila)", $agora, $tempoTxt)
    } else {
        $UI.icoResumo.Text = $Sim.Err
        $UI.icoResumo.Foreground = $bc.ConvertFromString($Cores.err)
        $UI.lblResumoTitulo.Text = Traduzir "Conversão Interrompida"
        $Janela.Title = "$NOME_APP  ·  " + (Traduzir-Frase ("Conversão Interrompida às {0}" -f $agora))
        $UI.lblResumoTempos.Text = Traduzir-Frase ("Começou às {0} - Interrompida às {1} - Tempo Total {2}" -f `
            "$($Motor.HoraFila)", $agora, $tempoTxt)
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
    <#  17.11: o contador tambem chumbava "(Já Existiam)". Somar num rotulo
        so dois motivos diferentes esconde justamente o que o usuario precisa
        saber - se falta disco, ele pode liberar e rodar de novo. #>
    $semEspaco = @($pulado | Where-Object { Test-PuladoPorEspaco $_ })
    $jaExistia = @($pulado | Where-Object { -not (Test-PuladoPorEspaco $_) })
    if ($jaExistia.Count -gt 0) { $linhas += "Ignorados (Já Existiam)       : {0}" -f $jaExistia.Count }
    if ($semEspaco.Count -gt 0) { $linhas += "Não Iniciados (Sem Espaço)    : {0}" -f $semEspaco.Count }
    if ($falhou.Count    -gt 0) { $linhas += "Não Finalizados (Erro)        : {0}" -f $falhou.Count }
    if ($cancelado.Count -gt 0) { $linhas += "Cancelados pelo Usuário       : {0}" -f $cancelado.Count }
    $linhas += "Tempo Total                   : {0}" -f $tempoTxt
    <#  17.12 - AS DUAS COLUNAS DO RESUMO TAMBEM SAO TELA.

        O titulo ("RESUMO DA CONVERSAO:") esta no XAML e sempre traduziu; as
        LINHAS sao montadas aqui, por codigo, e nunca passaram pela traducao.
        Em ingles o cartao saia com cabecalho em ingles e conteudo em
        portugues - meio a meio, que e pior do que tudo em portugues.

        Traduzir-Frase e nao Traduzir: cada linha e "rotulo : numero", entao
        o que casa com a tabela e o pedaco, nao a linha inteira. #>
    $UI.txtContadores.Text = ((@($linhas) | ForEach-Object { Traduzir-LinhaContador $_ }) -join "`n")

    if ($res.Count -eq 0) {
        $UI.txtContadores.Text = (Traduzir "O motor não devolveu nenhum resultado.") + "`n" +
                                 (Traduzir-LinhaContador ("Tempo Total                   : {0}" -f $tempoTxt))
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
    $UI.txtDetalhamento.Text = ((@($det) | ForEach-Object { Traduzir-LinhaContador $_ }) -join "`n")

    <#  17.09 - A COPIA DO LOG AO LADO DO ARQUIVO, FEITA POR QUEM RODA.

        A 14.50 pos esse bloco no finally do motor. Ele nunca rodou: a janela
        carrega as funcoes do motor pela AST e executa SO o laco dos arquivos
        - tudo que fica fora dele nao acontece na interface, e o Diego so usa
        a interface. Conferido na pasta de saida do Ryan em 10/09: o .mkv e o
        .srt estavam la, o .LaFirma.log.txt nao.

        Agora quem copia e a janela, no fim da fila, do log DELA - que e o
        log que o Diego abre no botao Log e o unico que descreve a sessao
        inteira. O modo console continua com o bloco de la, que naquele modo
        funciona.

        Falhar aqui nao custa nada: a fila terminou, o log da sessao esta
        gravado em _logs, e o pior caso e o arquivo ficar sem a copia. #>
    # 19.14: a copia <nome>.LaFirma.log.txt na pasta de saida SAIU (pedido
    # do Diego 23/09: "LOG e LOG, tem que sair em pasta de LOG"). A pasta
    # final recebe so .mkv + .srt; o log da sessao ja esta em _logs.

    <#  17.16 - OS DOIS BOTOES DO FIM NASCEM DEPOIS DA TROCA DE IDIOMA.

        Eles estao no XAML e deveriam ter sido pegos pela varredura - mas a
        varredura roda no clique do idioma, e nesse instante o painel do fim
        ainda nao existe montado. Quem troca para ingles no comeco da fila
        chega ao cartao final com "Nova Conversão" e "Encerrar Programa" em
        portugues, no meio de uma tela inteira em ingles (foto do Diego,
        13/09 10h40).

        Mesma regra de sempre, e agora sem depender de quando o painel
        nasceu: quem escreve, traduz na hora. #>
    try {
        $UI.lblNovaConversao.Text = "&#8635; " -replace "&#8635; ", ([char]0x21BB + " ")
        $UI.lblNovaConversao.Text = ([char]0x21BB) + " " + (Traduzir "Nova Conversão")
        $UI.lblEncerrar.Text      = ([char]0x23FB) + " " + (Traduzir "Encerrar Programa")
    } catch { }
    $UI.txtRodapeResumo.Text = (Traduzir "Pasta de Saída:") + " $($Cfg.Saida)`n" +
                               (Traduzir "Log completo desta sessão:") + " $($script:LogArquivo)"

    # 16.9: o resumo tambem vai pro LOG. Ate a 16.8 a sessao terminava com
    # "ESTADO: rodando -> fim" e mais nada - quem abrisse o log depois nao
    # sabia quantos converteram, quais falharam nem em quanto tempo, que e
    # justamente o que fecha a conta. Log autossuficiente e regra do projeto,
    # e o fim do log era o unico lugar onde ela nao valia.
    if ($Redesenho) { return }
    <#  17.16: a conta da FILA inteira, fechada. Por arquivo ja sai em
        PREVISAO; esta e a que responde a pergunta que o usuario faz de
        verdade - "disse 1h25, foi isso mesmo?". #>
    <#  17.20 - FILA CANCELADA NAO TEM "REAL" PARA COMPARAR.

        Log do Diego, 19:43:13, depois de ele cancelar no segundo arquivo:

          PREVISAO DA FILA: previsto 6.209s (1h43m) | real 21s | erro -99,7%

        O -99,7% nao mede nada: a fila nao errou a previsao, ela nao aconteceu.
        E numero desses polui exatamente o lugar onde a gente vai olhar depois
        para saber se a estimativa esta boa - e a linha existe para responder
        "disse 1h25, foi isso mesmo?", pergunta que nao cabe num cancelamento.

        A calibragem nunca foi afetada (ela grava por arquivo concluido), mas o
        log era lido por mim e por ele. #>
    if (($ok.Count + $parcial.Count) -eq 0 -and $cancelado.Count -eq 0) {
        # 2.0.12: fila sem nenhum arquivo convertido (todos ja existiam) - "erro -99,9%" nao e erro de previsao.
        Escrever-Log "PREVISAO DA FILA: nao comparada - nenhum arquivo foi convertido nesta fila" "PROVA"
    }
    elseif ($cancelado.Count -gt 0) {
        Escrever-Log ("PREVISAO DA FILA: nao comparada - a fila foi cancelada (previsto {0:N0}s para {1} arquivo(s))" -f `
            $script:LoteSegEstimado, $Motor.VideoTotal) "PROVA"
    }
    elseif ($script:LoteSegEstimado -gt 0) {
        <#  2.0.10: a previsao e de TRABALHO; o relogio do resumo inclui as
            pausas. Uma fila de 1h com 30 min pausada dava "erro +50%" com a
            previsao certa. A comparacao desconta a pausa (PausadoFila, que ja
            existia e ninguem lia); o Tempo Total da tela continua de parede. #>
        $pausaFila = [double]$Motor.PausadoFila
        $trabFila = [math]::Max(1.0, [double]$totalSeg - $pausaFila)
        $erroFila = 100.0 * ($trabFila - $script:LoteSegEstimado) / $script:LoteSegEstimado
        $sinalF = if ($erroFila -ge 0) { "+" } else { "" }
        $txtPausaF = if ($pausaFila -ge 1) { " (fora {0} de pausa)" -f (Format-MinSeg $pausaFila) } else { "" }
        Escrever-Log ("PREVISAO DA FILA: previsto {0:N0}s ({1}) | real {2:N0}s ({3}){6} | erro {4}{5:N1}%" -f `
                      $script:LoteSegEstimado, (Format-MinSeg $script:LoteSegEstimado),
                      $trabFila, (Format-MinSeg $trabFila), $sinalF, $erroFila, $txtPausaF) "PROVA"
    }
    Escrever-Log "===== RESUMO DA CONVERSAO =====" "PROVA"
    foreach ($l in $linhas) { Escrever-Log $l "PROVA" }
    foreach ($l in $det)    { Escrever-Log $l "PROVA" }
    foreach ($r in $res) {
        Escrever-Log ("{0} | {1} | {2}" -f "$($r.Episodio)", "$($r.Status)", "$($r.Tempo)") "PROVA"
    }
    Set-Estado "fim"
}

# ---- Janelas auxiliares (Log / Ferramentas) --------------------------------
function Show-JanelaTexto([string]$Titulo, [string]$Conteudo, [bool]$DoTopo = $false) {
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

    <#  17.03 - OS ENDERECOS DO "ENTENDA" ERAM TEXTO MORTO (achado do Diego).

        A seção 14 do FAQ existe para a pessoa CONFERIR o que o programa
        afirma - manuais da Dolby, o repositorio do dovi_tool, as planilhas
        da comunidade. Num TextBox comum o endereco e texto cru: nao tem cor,
        nao tem sublinhado, e clicar nele nao faz nada. Quem quisesse abrir
        tinha que selecionar com o mouse e copiar na mao.

        Para o texto de LEITURA (o Entenda, $DoTopo) a janela passa a montar
        um FlowDocument, onde cada endereco vira um Hyperlink de verdade:
        azul, sublinhado, e abre no navegador. O LOG continua no TextBox -
        la o que se quer e selecionar e copiar blocos inteiros, e um
        FlowDocument atrapalharia isso.

        Se qualquer coisa falhar na montagem, fica o TextBox de antes: um
        texto sem link e pior que um texto com link, mas e infinitamente
        melhor que uma janela vazia. #>
    if ($DoTopo) {
        try {
            $doc = New-Object System.Windows.Documents.FlowDocument
            $doc.FontFamily  = New-Object System.Windows.Media.FontFamily("Consolas")
            $doc.FontSize    = 14
            $doc.PagePadding = New-Object System.Windows.Thickness(14)
            $doc.Foreground  = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Cores.txt)
            $doc.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Cores.fundo)
            $azul = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4DA3FF")
            $reLink = [regex]'(https?://[^\s<>"\)\]]+)'
            foreach ($linha in ($Conteudo -split "`r?`n")) {
                $par = New-Object System.Windows.Documents.Paragraph
                $par.Margin = New-Object System.Windows.Thickness(0)
                $pos = 0
                foreach ($m in $reLink.Matches($linha)) {
                    if ($m.Index -gt $pos) {
                        $par.Inlines.Add((New-Object System.Windows.Documents.Run $linha.Substring($pos, $m.Index - $pos)))
                    }
                    $url = $m.Value
                    $lnk = New-Object System.Windows.Documents.Hyperlink((New-Object System.Windows.Documents.Run $url))
                    $lnk.Foreground = $azul
                    $lnk.TextDecorations = [System.Windows.TextDecorations]::Underline
                    $lnk.ToolTip = $url
                    $lnk.Tag = $url
                    $lnk.add_Click({
                        param($s, $e)
                        try { Start-Process "$($s.Tag)" } catch {
                            Escrever-Log ("LINK: nao consegui abrir {0} - {1}" -f $s.Tag, $_.Exception.Message) "AVISO"
                        }
                    })
                    $par.Inlines.Add($lnk)
                    $pos = $m.Index + $m.Length
                }
                if ($pos -lt $linha.Length) {
                    $par.Inlines.Add((New-Object System.Windows.Documents.Run $linha.Substring($pos)))
                }
                $doc.Blocks.Add($par)
            }
            $visor = New-Object System.Windows.Controls.FlowDocumentScrollViewer
            $visor.Document = $doc
            $visor.VerticalScrollBarVisibility = "Auto"
            $visor.Background = $doc.Background
            $visor.BorderThickness = 0
            $visor.IsSelectionEnabled = $true
            $w.Content = $visor
        } catch {
            # fica o TextBox
            Escrever-Log ("TEXTO: FlowDocument falhou, usando o texto simples - {0}" -f $_.Exception.Message) "AVISO"
        }
    }
    <#  16.88: o log abre no FIM (a linha mais nova e a que interessa); um
        texto para LER abre no comeco. Antes havia so um comportamento, e o
        FAQ abriria pelos creditos. #>
    # 17.03: o FlowDocument ja nasce no topo; o ScrollToHome era do TextBox.
    if (-not $DoTopo) { $w.add_ContentRendered({ $tb.ScrollToEnd() }) }
    elseif ($w.Content -is [System.Windows.Controls.TextBox]) { $w.add_ContentRendered({ $tb.ScrollToHome() }) }
    if ($DoTopo) { $w.Width = 900; $w.Height = 620 }
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
$UI.lblDiagTitulo.Text = Traduzir "DIAGNÓSTICO:"
foreach ($campo in @("diagDV","diagAu","diagLg","diagDVr","diagAur","diagLgr")) { $UI.$campo.Text = "" }

<#  16.93: abre no idioma que o usuario escolheu da ultima vez. Roda depois
    da janela montada, senao a varredura nao acha os rotulos. Qualquer falha
    aqui deixa o programa em portugues - que e o certo por omissao. #>
try {
    $arqPref = Get-CaminhoIdioma
    if (Test-Path -LiteralPath $arqPref) {
        $pref = ([System.IO.File]::ReadAllText($arqPref)).Trim().ToUpperInvariant()
        # 17.04: aqui so APLICA. A pergunta de reinicio e do clique no
        # botao - no arranque nao ha nada a completar, a janela nasce
        # ja no idioma certo.
        if ($pref -eq "EN") { Set-Idioma "EN" }
    }
} catch { }
$UI.txtDisco.Text = Traduzir "Lendo a pasta..."

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
        # 16.81: true quando o usuario tirou do OCR uma PGS que o automatico
        # converteria - e a unica forma de dizer NAO ao motor (ver abaixo).
        $pgsRecusada = $false
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
                <#  16.81 - A TELA DIZIA "CONVERSAO DESLIGADA" E O MOTOR
                    CONVERTIA (Troy, 05/09).

                    Marcar MANTER numa PGS so acrescentava o id em $leg. A
                    chave LegendaPgs nao era enviada - e chave AUSENTE, para
                    o motor, quer dizer "voce decide", nao "nao converta".
                    Ele decidia, achava a PGS pt-BR sozinho e fazia o OCR,
                    enquanto a tela garantia ao usuario que nao faria.

                    Exatamente a licao da 16.31 (a ausencia de uma chave nunca
                    e uma ordem) repetida no ramo vizinho. Agora MANTER numa
                    PGS que o automatico converteria manda LegendaPgs = -1,
                    que o motor 14.40 le como "nao converta nenhuma". #>
                if ($vb -eq "MANTER" -and "$($f.VerboAuto)" -eq "CONVERTER") {
                    $pgsRecusada = $true
                }
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
        # A ordem so vale se ninguem escolheu OUTRA PGS para o OCR: escolher
        # uma e recusar outra e trocar de faixa, nao desligar a conversao.
        if ($pgsRecusada -and -not $e.ContainsKey("LegendaPgs")) { $e["LegendaPgs"] = -1 }
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

$script:DiscoFalta = 0.0
$script:DiscoPreciso = 0.0
$script:DiscoLivre = 0.0
$script:DiscoCabem = 0
$script:DiscoNaoCabem = 0
$script:DiscoPrimeiroFora = ""
$script:DiscoFaltaNoPrimeiroFora = 0.0

function Test-PodeIniciar {
    <#  16.91 - COMECAR SABENDO QUE NAO CABE (achado do Diego, 08/09).

        A tela dizia "Espaço Insuficiente" em vermelho e o Iniciar comecava
        assim mesmo. O motor entao recusava arquivo por arquivo, 23 segundos
        depois, com a MESMA conta que ja estava na tela. Trabalho nenhum era
        perdido - mas a pergunta ja tinha resposta antes de comecar, e o
        programa fingiu que nao tinha.

        Agora ele pergunta. NAO bloqueia: a estimativa e estimativa (3,15x o
        tamanho do arquivo, o pior caso), o disco pode encher ou esvaziar no
        meio, e ha quem queira comecar assim mesmo para converter o que
        couber. Quem decide e o usuario - mas informado, e com o NAO
        pre-selecionado, que e a regra desta janela para pergunta perigosa
        (a mesma do Cancelar, desde a 16.12).

        HISTORIA DESTA FUNCAO: ate a 16.11 ela barrava o inicio quando havia
        escolha manual, porque as escolhas por faixa nao chegavam ao motor -
        a tela aceitava uma escolha que seria ignorada e voce so descobria 20
        minutos depois, olhando o arquivo pronto. Isso foi resolvido na porta
        do motor 13.3 e o bloqueio saiu; a funcao ficou como ponto de
        checagem, vazia, esperando o proximo motivo. Este e o motivo. #>
    <#  17.16: a pergunta passou a ter DOIS motivos, porque ha dois jeitos de
        nao caber: a fila nao cabe nem agora (conta agregada, $DiscoFalta), ou
        cabe agora e deixa de caber no meio do caminho, quando os primeiros
        arquivos ja escreveram a saida no disco (simulacao sequencial,
        $DiscoNaoCabem). O segundo era mudo ate aqui. #>
    if ($script:DiscoFalta -gt 0 -or $script:DiscoNaoCabem -gt 0) {
        <#  16.93: a pergunta passou a dizer o que vai acontecer com ESTA
            fila, arquivo por arquivo - nao mais a regra geral. "Vai converter
            o que couber" e verdade e nao ajuda ninguem a decidir; "1 de 2
            cabem, o Troy fica de fora por 65 GB" ajuda. #>
        <#  17.19 - ESTA CAIXA ESTAVA MEIO TRADUZIDA, QUE E PIOR QUE NAO ESTAR.

            Ela chamava Traduzir em UM pedaco ("nada agora - a conta aperta no
            meio da fila") e deixava o resto - a abertura, os tres rotulos, a
            explicacao do 3,15x e a pergunta - em portugues fixo. Com a tela em
            ingles saia uma caixa em portugues com uma expressao em ingles no
            meio.

            Meio traduzido engana mais que nada traduzido: quem ve uma palavra
            na sua lingua assume que o resto tambem esta - e esta caixa termina
            numa pergunta de Sim/Nao que pode custar uma fila inteira. #>
        $en = ($script:Lang -eq "EN")
        $linhaFila = ""
        if ($script:DiscoNaoCabem -gt 0) {
            $linhaFila = if ($en) {
                ("In queue order, {0} of {1} file(s) fit.`n" -f `
                 $script:DiscoCabem, ($script:DiscoCabem + $script:DiscoNaoCabem))
            } else {
                ("Na ordem da fila, {0} de {1} arquivo(s) cabem.`n" -f `
                 $script:DiscoCabem, ($script:DiscoCabem + $script:DiscoNaoCabem))
            }
            if ($script:DiscoPrimeiroFora -ne "") {
                $nomeCurto = "$($script:DiscoPrimeiroFora)"
                if ($nomeCurto.Length -gt 60) { $nomeCurto = $nomeCurto.Substring(0, 57) + "..." }
                $linhaFila += if ($en) {
                    ("The first one left out is:`n  {0}`n  ({1} would be missing by its turn)`n" -f `
                     $nomeCurto, (Format-GB $script:DiscoFaltaNoPrimeiroFora))
                } else {
                    ("O primeiro que fica de fora é:`n  {0}`n  (faltariam {1} na vez dele)`n" -f `
                     $nomeCurto, (Format-GB $script:DiscoFaltaNoPrimeiroFora))
                }
            }
            $linhaFila += "`n"
        }
        $cabeAgora = ($script:DiscoFalta -le 0)
        $abertura = if ($en) {
            if ($cabeAgora) {
                "The queue fits now, but not to the end.`n`n" +
                "Every converted file leaves its result taking up disk space. By the time the last ones come up, the free space will have shrunk - and they will not start.`n`n"
            } else {
                "The selected queue does not fit on the disk.`n`n"
            }
        } else {
            if ($cabeAgora) {
                "A fila cabe agora, mas não até o fim.`n`n" +
                "Cada arquivo convertido deixa o resultado ocupando o disco. Quando chegar a vez dos últimos, o espaço já terá diminuído - e eles não vão começar.`n`n"
            } else {
                "A fila selecionada não cabe no disco.`n`n"
            }
        }
        $faltaTxt = if ($cabeAgora) {
            if ($en) { "nothing right now - the squeeze happens mid-queue" }
            else     { "nada agora - a conta aperta no meio da fila" }
        } else { Format-GB $script:DiscoFalta }
        $corpoTxt = if ($en) {
            "Estimated needed : ~{0}`n" +
            "Free right now   : {1}`n" +
            "Must free up     : {2}`n`n" +
            "{3}" +
            "The estimate is the worst case: each file needs 3.15x its own size while converting (video extracted, converted and remuxed at the same time).`n`n" +
            "Nothing comes out half done: the engine refuses the whole file when it does not fit, and moves on to the next.`n`n" +
            "Start anyway?"
        } else {
            "Necessário estimado : ~{0}`n" +
            "Livre agora         : {1}`n" +
            "Falta liberar       : {2}`n`n" +
            "{3}" +
            "A conta é a do pior caso: cada arquivo precisa de 3,15x o próprio tamanho enquanto converte (vídeo extraído, convertido e remontado ao mesmo tempo).`n`n" +
            "Nada sai pela metade: o motor recusa o arquivo inteiro quando não cabe, e passa para o próximo.`n`n" +
            "Começar mesmo assim?"
        }
        $txt = ($abertura + $corpoTxt) -f `
                (Format-GB $script:DiscoPreciso), (Format-GB $script:DiscoLivre),
                $faltaTxt, $linhaFila
        $tituloDisco = if ($en) { "LaFirma - not enough disk space" } else { "LaFirma - falta espaço em disco" }
        $r = [System.Windows.MessageBox]::Show($txt, $tituloDisco,
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning,
                [System.Windows.MessageBoxResult]::No)
        if ($r -ne [System.Windows.MessageBoxResult]::Yes) {
            Escrever-Log ("INICIO cancelado pelo usuario: faltam {0} em disco | {1} de {2} arquivo(s) da fila cabem" -f `
                (Format-GB $script:DiscoFalta), $script:DiscoCabem, ($script:DiscoCabem + $script:DiscoNaoCabem)) "ACAO"
            return $false
        }
        Escrever-Log ("INICIO mesmo faltando {0} em disco - confirmado pelo usuario" -f (Format-GB $script:DiscoFalta)) "AVISO"
    }
    return $true
}

<#  17.11 - O INICIAR NAO ESPERAVA A MEDICAO, E ISSO CUSTAVA DUAS VEZES.

    Medido no log do Diego, 10/09 23h55:

      23:55:22.405  Medindo a camada de melhoria de 1 arquivo(s)...
      23:55:23.689  CLIQUE: Iniciar
      23:55:25.370  Medicao interrompida - marcados como EL nao medida

    Um segundo depois de a medicao comecar, o F1 a matou. A linha ficou
    ambar, sem veredicto - e trinta segundos depois o MOTOR mediu o MESMO
    arquivo de novo, sozinho, porque ele sempre mede antes de converter. O
    trabalho foi feito duas vezes e a tela nao ficou com nada.

    Pior: a chave estava LIGADA. Ligar a medicao e dizer "eu quero o
    veredicto antes de decidir" - e a tela comecava a conversao justamente
    antes de ter o veredicto para mostrar.

    Agora o Iniciar pergunta. ESPERAR e a opcao segura e vem pre-selecionada
    - e a unica das duas que nao joga trabalho fora. Quem responde "comecar
    agora" continua podendo: a conversao nao depende disso, o motor mede por
    conta propria. O que muda e que a escolha passou a ser do Diego, e nao um
    efeito colateral do clique.

    Com a chave DESLIGADA isto nao aparece: nao ha medicao para esperar. #>
$script:IniciarAposMedir = $false
$script:DicaAntesDaEspera = ""
<#  17.14 - O AVISO DE ESPERA NAO DIZIA SE ALGUMA COISA ANDAVA.

    Log de 11/09: as 00:49:59 a janela comecou a esperar, as 00:50:41 a
    medicao terminou. A foto do Diego caiu no meio desses 42 segundos, com o
    Ryan ja medido e o Troy ainda em "P7 medindo". O aviso estava CERTO - e
    mesmo assim ele leu como travado ("a medicao terminou mas ainda ficou
    falando q tava medindo e eu nao conseguia apertar f1").

    Aviso parado por 40 segundos e indistinguivel de aviso morto. O texto
    passa a carregar o progresso, que a janela ja sabe: o "leitura_fim" diz
    quantos arquivos vao ser medidos e cada "el" e um a menos. #>
$script:ELtotal = 0
$script:ELfeitos = 0
<#  17.19: o indice (em $script:Videos) do arquivo que o runspace esta medindo
    AGORA, dito por ele no "el_ini". -1 = ninguem. Indice e nao nome: dois
    arquivos podem ter o mesmo nome, indice nao se repete. #>
$script:ELmedindoIdx = -1

function Get-TextoEspera {
    <#  17.15: a conta e dos arquivos QUE VAO CONVERTER, nao de todos os que
        a leitura resolveu medir. Contar os outros faz o aviso prometer uma
        espera que nao existe.

        17.19 - E POR ISSO ELE NAO PODE DIZER "X DE Y".

        O botao ja diz "Medindo MEL x FEL: 2 de 3", com a conta do runspace -
        os arquivos que estao sendo medidos. Este aviso responde outra
        pergunta: quantos arquivos DA SUA FILA ainda estao sem veredicto. Sao
        numeros legitimamente diferentes (um arquivo desmarcado entra num e
        nao no outro), e escritos no mesmo formato pareciam o mesmo contador
        se contradizendo.
        Agora cada um tem a forma da sua pergunta: o botao conta progresso
        ("2 de 3"), o aviso conta o que falta para VOCE ("faltam 2"). #>
    $t = Traduzir "Esperando a medição terminar para começar..."
    $faltam = @(Get-MarcadosMedindo).Count
    if ($faltam -eq 1) {
        $t = "{0} {1}" -f $t, (Traduzir "(falta 1 arquivo da sua fila)")
    } elseif ($faltam -gt 1) {
        $t = "{0} {1}" -f $t, ((Traduzir "(faltam {0} arquivos da sua fila)") -f $faltam)
    }
    return $t
}

<#  17.13 - UM LUGAR SO ESCREVE A DICA DA ABA.

    Na 17.12 eu escondi o nome do arquivo UMA VEZ, na hora de comecar a
    esperar. Nao adiantou: a dica e reescrita por QUATRO pontos diferentes
    (selecao vazia, video ilegivel, nome do video, e o vazio de Fill-Faixas),
    e trocar o Modo chama Fill-Faixas - entao o nome voltava e nunca mais
    saia. Foi o que o Diego viu nas fotos 3 e 4: mesma tela, Modo trocado,
    nome de volta espremendo o aviso.

    Esconder num lugar e deixar quatro escrevendo nao e esconder: e correr
    atras. A resposta e a mesma de sempre neste projeto - UMA regra, UM
    lugar. Todo mundo passa por aqui, e aqui a espera tem prioridade.

    O texto pedido continua guardado, entao quando a espera acaba a dica
    volta sem ninguem precisar recalcular nada. #>
<#  18.13 - O CABECALHO DA ABA E DA ABA, E DE MAIS NINGUEM.

    Print dele de 17/09: aba FILA aberta, video selecionado E marcado, e o
    cabecalho dizendo "Selecione um vídeo na aba Fila." - depois sumindo
    sozinho. "video selecionado e pedindo pra selecionar video, ai de repente
    some" (Diego).

    A 18.10 consertou METADE disto: eu impedi que o NOME do arquivo fosse
    escrito ali com a FILA na frente, mas deixei os outros dois ramos do
    Fill-Faixas escrevendo sem olhar aba nenhuma. E Fill-Faixas roda por muito
    mais coisa que trocar de aba (MODO, clique em faixa, repintura). Pior: no
    meio de um repinte da fila o SelectedIndex fica -1 por um instante, o que
    cai justamente no ramo "Selecione um vídeo" - e era dai que vinha o texto
    absurdo. Ele sumia depois porque a proxima escrita vinha certa.

    Agora quem escreve no cabecalho passa por AQUI, e aqui a regra e uma so:
    texto de arquivo so aparece com a aba das FAIXAS na frente. Na FILA, o
    cabecalho fala da fila. #>
function Set-DicaFaixas([string]$Texto) {
    if ($script:AbaAtual -ne "faixas") { return }
    Set-AbaDica $Texto
}

function Set-AbaDica([string]$Texto) {
    $script:DicaAntesDaEspera = $Texto
    if ($script:IniciarAposMedir) { return }
    try { $UI.lblAbaDica.Text = $Texto } catch { }
}

<#  17.13: quem liga e desliga o aviso e esta funcao, e nao tres linhas
    espalhadas - o aviso e a dica sao a MESMA linha da tela e tem que mudar
    juntos, senao um deles sempre fica para tras. #>
<#  17.21 - O INICIAR VOLTAVA A ACENDER NO MEIO DA ESPERA.

    BUG MEDIDO no log do Diego (15/09 20:32:29 -> 20:32:46): ele armou a
    espera, marcou e desmarcou arquivos, e o Iniciar acendeu de novo - porque
    Update-Selecao decide o botao por "tem marcado + estado inicial" e nao
    sabia da espera. Ele clicou, e a MESMA pergunta apareceu pela segunda vez
    sobre a MESMA medicao. Tres lugares escreviam no botao com regras
    diferentes (Update-Selecao, Test-PastasIguais, Set-Estado) - e o quarto,
    o F1, so lia o botao.

    Uma regra, um lugar, igual ao Set-AbaDica logo acima: todo mundo passa
    por aqui, e aqui a espera tem prioridade sobre qualquer outro criterio.
    Enquanto ha um Iniciar represado nao existe um segundo Iniciar. #>
function Set-BotaoIniciar([bool]$Pode) {
    try {
        if ($script:IniciarAposMedir) { $UI.btnIniciar.IsEnabled = $false; return }
        $UI.btnIniciar.IsEnabled = $Pode
    } catch { }
}

function Update-AvisoEspera {
    try {
        if ($script:IniciarAposMedir) {
            $UI.avisoEspera.Visibility = "Visible"
            $UI.lblEsperandoMedida.Text = Get-TextoEspera
            $UI.lblAbaDica.Text = ""
        } else {
            $UI.avisoEspera.Visibility = "Collapsed"
            Restaurar-AbaDica
        }
    } catch { }
}

function Restaurar-AbaDica {
    try { $UI.lblAbaDica.Text = "$($script:DicaAntesDaEspera)" } catch { }
}

<#  17.15 - ESPERAR POR UM ARQUIVO QUE NAO VAI CONVERTER E ESPERAR A TOA.

    "Se eu deixei selecionado so o Ryan e dei comecar, e sim ele ta esperando
    1/2 blz, mas quando vai pro 2/2 pra analisar, o 2/2 nao tava selecionado
    pra converter, entao nao me importa ele terminar de ler, nao e?"

    Nao e mesmo. A medicao roda em TODO Profile 7 com EL da pasta - e certo,
    porque a fila mostra o veredicto de todos e ele pode marcar outro depois.
    Mas a ESPERA existe para uma coisa so: nao comecar a converter antes de
    saber o que vai ser convertido. Arquivo desmarcado nao entra na conversao,
    logo nao tem veredicto nenhum a atrasar.

    Quem responde "ainda falta medir?" passa a ser esta funcao, e ela pergunta
    pela FILA REAL - marcados que ainda estao em MEDINDO. Uma regra, um lugar:
    Get-Marcados ja e quem define quem entra. #>
function Get-MarcadosMedindo {
    return @(Get-Marcados | Where-Object { "$($_.ELtipo)" -eq "MEDINDO" })
}

<#  17.18/17.19 - QUAL DELES ESTA SENDO MEDIDO AGORA.

    O botao dizia "Medindo MEL x FEL: 2 de 3" e a fila nao dizia QUEM era o 2.
    Tres linhas escritas "Na Fila", e o unico jeito de descobrir qual estava
    na vez era olhar a coluna Dolby Vision procurando quem ainda tinha
    "P7 medindo" - adivinhacao, do mesmo tipo que a 16.38 ja tinha tirado da
    conversao.

    NA 17.18 EU CONSERTEI ISSO COM UMA DEDUCAO, E A DEDUCAO ESTAVA ERRADA.

    A regra era "o arquivo na vez e o primeiro MARCADO que ainda esta em
    MEDINDO", e a conta saia de $ELtotalFila, tirado dos marcados. Dois furos:

      1. o runspace mede TODOS os pendentes, marcados ou nao - entao com um
         arquivo desmarcado sendo medido, a deducao apontava para a linha
         errada;
      2. $ELtotalFila era fotografado uma vez; marcar ou desmarcar no meio da
         medicao mudava o total DEBAIXO da formula, e o numero pulava.

    Foi o que o Diego viu em 15/09: a coluna dizendo um numero enquanto o
    botao dizia outro, e a posicao andando para tras.

    E o pior: a 17.18 criou a TERCEIRA contagem da mesma coisa na tela. O
    botao contava pelo runspace (certo), o aviso de espera contava pelos
    marcados, e eu somei uma deducao. A licao do projeto e velha - regra
    escrita em dois lugares, e um dos dois desatualizado - e eu a repeti
    exatamente na semana em que a bateria passou a reprovar funcao duplicada.

    AGORA NAO SE DEDUZ NADA. O laco que mede manda um "el_ini" com o indice,
    a posicao e o total antes de cada arquivo. A linha da fila, o rotulo do
    botao e a barrinha leem os MESMOS numeros, vindos de quem esta fazendo o
    trabalho. #>
function Get-MedicaoEmCurso {
    if (-not $script:MedindoEL)     { return $null }
    if (-not $script:MedirELLigado) { return $null }
    $i = [int]$script:ELmedindoIdx
    if ($i -lt 0 -or $i -ge $script:Videos.Count) { return $null }
    $total = [int]$script:ELtotal
    if ($total -le 0) { return $null }
    $pos = [int]$script:ELfeitos + 1
    if ($pos -lt 1)      { $pos = 1 }
    if ($pos -gt $total) { $pos = $total }
    return [PSCustomObject]@{ Idx = $i; Posicao = $pos; Total = $total }
}

function Test-EsperarMedicao {
    if (-not $script:MedindoEL) { return $false }
    if (-not $script:MedirELLigado) { return $false }
    if (@(Get-MarcadosMedindo).Count -eq 0) {
        Escrever-Log "INICIAR: a medicao que sobrou e de arquivo(s) que nao estao na fila desta conversao - comecando agora" "ACAO"
        return $false
    }
    $msg = ("A medição de camada (MEL × FEL) ainda está rodando." + "`n`n" +
            "Começar agora interrompe a medição: os arquivos que faltam ficam sem veredicto na tela (aparecem como 'EL não medida')." + "`n`n" +
            "A conversão acontece de qualquer jeito - o motor mede por conta própria antes de converter cada arquivo. O que se perde é o veredicto AQUI, antes de você decidir." + "`n`n" +
            "Esperar a medição terminar e começar logo em seguida?")
    if ($script:Lang -eq "EN") {
        $msg = ("Layer measurement (MEL x FEL) is still running." + "`n`n" +
                "Starting now interrupts it: the remaining files stay without a verdict on screen ('EL not measured')." + "`n`n" +
                "The conversion happens either way - the engine measures each file on its own before converting. What is lost is the verdict HERE, before you decide." + "`n`n" +
                "Wait for the measurement to finish and start right after?")
    }
    $titulo = if ($script:Lang -eq "EN") { "LaFirma - measurement still running" } else { "LaFirma - medição ainda rodando" }
    # Sim pre-selecionado: das duas, esperar e a que nao descarta trabalho.
    $r = [System.Windows.MessageBox]::Show($msg, $titulo, "YesNo", "Question", "Yes")
    <#  17.12 - A CAIXA E MODAL, E O MUNDO NAO PARA ATRAS DELA.

        MessageBox do WPF roda um laco de mensagens PROPRIO enquanto esta
        aberta: o DispatcherTimer continua batendo e a fila de mensagens
        continua sendo lida. Ou seja, a medicao podia TERMINAR com a caixa na
        tela - e o "el_fim" passava antes de eu marcar IniciarAposMedir.

        Efeito, relatado pelo Diego em 11/09: "cliquei sim e ja tinha lido e
        apareceu que tava esperando". A janela ficava esperando para sempre um
        aviso que ja tinha acontecido, com o Iniciar apagado. Dai ele clicava
        em tudo - e "tudo" e o que a tela deixa clicar quando nao esta
        rodando, porque a conversao nunca comecou.

        A regra que eu quebrei: entre PERGUNTAR e AGIR o estado pode ter
        mudado. Quem pergunta tem que reconferir a resposta ao voltar. E a
        mesma armadilha da 16.23, no Invoke-Cancelar: a conversao podia
        terminar enquanto a pergunta estava aberta. #>
    if ($r -eq "Yes" -and -not $script:MedindoEL) {
        Escrever-Log "INICIAR: a medicao terminou enquanto a pergunta estava aberta - comecando agora, sem esperar" "ACAO"
        return $false
    }
    if ($r -eq "Yes") {
        $script:IniciarAposMedir = $true
        # 17.15: o denominador e congelado aqui - quantos da FILA faltavam
        # medir quando a espera comecou.
        $UI.btnIniciar.IsEnabled = $false
        <#  17.12: a dica com o NOME DO ARQUIVO some enquanto a espera dura.
            Ela e a vizinha do aviso na mesma linha, e nome de release tem 70
            caracteres - o aviso ficava espremido no canto, competindo com um
            texto que naquele momento nao informa nada. Quem esta esperando
            precisa saber POR QUE esta esperando, nao qual linha esta
            selecionada. Ela volta assim que a conversao comeca. #>
        Update-AvisoEspera
        Escrever-Log "INICIAR: esperando a medicao de camada terminar (escolha do usuario)" "ACAO"
        return $true
    }
    Escrever-Log "INICIAR: usuario preferiu comecar agora - a medicao em curso sera interrompida" "ACAO"
    return $false
}

<#  17.21 - A PARTIDA AUTOMATICA NAO E UM CLIQUE.

    BUG MEDIDO no log do Diego (15/09 20:32:59 e 20:36:35). A medicao
    terminou e a espera disparou sozinha. No log saiu isto, em sequencia:

      INICIAR: todos os arquivos DA FILA ja foram medidos - comecando agora
      CLIQUE: Iniciar
      INICIAR: a medicao que sobrou e de arquivo(s) que nao estao na fila

    Duas das tres linhas sao mentira. Nao houve clique - fui EU que chamei
    Invoke-Iniciar. E nao sobrou medicao nenhuma: a segunda mensagem e o
    Test-EsperarMedicao rodando PELA SEGUNDA VEZ sobre uma medicao que
    acabou, caindo no ramo "nao ha marcados medindo". O Diego leu o log e
    disse, com razao: "falando nao esperar e esperando tbm, comportamento
    muito estranho".

    A regra: quem ja decidiu esperar ja respondeu a pergunta da espera.
    Reperguntar e reabrir uma decisao tomada. A partida automatica entra
    DEPOIS da pergunta - so confere o disco, que e a unica coisa que pode ter
    mudado enquanto a medicao rodava. #>
function Invoke-IniciarAutomatico {
    if (-not (Test-PodeIniciar)) { return }
    Invoke-IniciarProtegido
}

function Invoke-Iniciar {
    Escrever-Log "CLIQUE: Iniciar" "ACAO"
    if (Test-EsperarMedicao) { return }
    if (-not (Test-PodeIniciar)) { return }
    Invoke-IniciarProtegido
}

function Invoke-IniciarProtegido {
    # Um defeito no caminho da partida fechou o programa na sua cara na 16.4.
    # Erro aqui agora vira mensagem e log - a janela continua de pe.
    try { Invoke-IniciarInterno }
    catch {
        Escrever-Log ("FALHA ao iniciar: {0}" -f $_.Exception.Message) "ERRO"
        Escrever-Log ("   em: {0}" -f $_.InvocationInfo.PositionMessage) "ERRO"
        try { Stop-Motor } catch { }
        try { $TimerFilaRelogio.Stop() } catch { }
        Set-Estado "inicial"
        # 17.19: a caixa de erro tambem fala a lingua da tela.
        $msgFalha = if ($script:Lang -eq "EN") {
            ("Could not start the conversion:`n`n{0}`n`nNothing was converted and no file was touched. This session's log has the detail." -f $_.Exception.Message)
        } else {
            ("Não consegui iniciar a conversão:`n`n{0}`n`nNada foi convertido e nenhum arquivo foi tocado. O log desta sessão tem o detalhe." -f $_.Exception.Message)
        }
        $titFalha = if ($script:Lang -eq "EN") { "LaFirma - could not start" } else { "LaFirma - falha ao iniciar" }
        [System.Windows.MessageBox]::Show($msgFalha, $titFalha, "OK", "Error") | Out-Null
    }
}

function Invoke-IniciarInterno {
    <#  17.21: o censo que estava rodando morre aqui. Ele le o filme inteiro
        e a conversao vai disputar o mesmo disco com ele - e o mesmo motivo
        que fechou o botao. Deixar rodando seria fechar a porta e esquecer
        quem ja estava dentro. #>
    if ($script:CensoRodando) {
        Escrever-Log "CENSO COMPLETO: encerrado - a conversao comecou e os dois leriam o mesmo disco" "ACAO"
        Stop-Censo
    }
    <#  18.00: e a medicao tambem. Pelo mesmo motivo do censo - ela le o RPU de
        arquivos grandes e disputaria o disco com a conversao. Quem nao tiver
        sido medido fica em "EL nao medida", que e honesto. #>
    if ($script:MedindoEL) {
        Escrever-Log "MEDICAO: encerrada - a conversao comecou e as duas leriam o mesmo disco" "ACAO"
        Stop-Medicao
    }
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
    # 17.16: o previsto da FILA fica guardado para o resumo poder fechar a
    # conta com o real (ver a linha PREVISAO DA FILA em Show-Resumo).
    $script:LoteSegEstimado = [double]$somaEst
    $agoraDt = Get-Date
    $Motor.T0Fila = $agoraDt; $Motor.T0Video = $agoraDt
    # 17.00: o Iniciar liga o relogio, mas nao ha arquivo em andamento ainda
    # - quem abre a medida e o anuncio "ARQUIVO n/N" do motor.
    $Motor.MedidaAberta = $false
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
    <#  17.19 - ESTA CAIXA SAIA EM PORTUGUES NA TELA EM INGLES.

        Achado na varredura de 15/09. As quatro caixas de dialogo montadas no
        codigo (cancelar, fechar durante a conversao, e os dois erros) nunca
        passaram pela traducao - a varredura da 17.15 alcancou o texto da
        JANELA, e estas nascem fora dela, no MessageBox.

        E sao as piores para deixar em portugues: sao as unicas da tela em que
        responder errado custa uma conversao inteira. Quem nao le portugues
        estava sendo perguntado, em portugues, se queria jogar fora meia hora
        de trabalho. #>
    $en = ($script:Lang -eq "EN")
    $oQuePerde = if ($en) { "the video being assembled right now" }
                 else     { "o vídeo que está sendo montado agora" }
    if ($Motor.VideoTotal -gt 1) {
        # 16.44: VideoIdx e 0-based. Todo o resto da tela mostra +1; so esta
        # caixa dizia "o vídeo 0 de 3" enquanto o rodapé atrás dela dizia 1/3.
        $oQuePerde = if ($en) {
            ("video {0} of {1} (the one being assembled right now)" -f ([int]$Motor.VideoIdx + 1), $Motor.VideoTotal)
        } else {
            ("o vídeo {0} de {1} (o que está sendo montado agora)" -f ([int]$Motor.VideoIdx + 1), $Motor.VideoTotal)
        }
    }
    $texto = if ($en) {
        ("Cancel the conversion?`n`nYou lose {0}, and the time already spent on it - {1} so far. The partial file is deleted.`n`nVideos that already finished stay in the output folder." -f `
            $oQuePerde, (Format-MinSeg $Motor.SegVideo))
    } else {
        ("Cancelar a conversão?`n`nVocê perde {0}, e o tempo já gasto nele - são {1} até aqui. O arquivo parcial é apagado.`n`nOs vídeos que já terminaram continuam na pasta de saída." -f `
            $oQuePerde, (Format-MinSeg $Motor.SegVideo))
    }
    $tituloCanc = if ($en) { "LaFirma - cancel the conversion?" } else { "LaFirma - cancelar a conversão?" }
    if (-not (Confirm-Parar $tituloCanc $texto)) {
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
    # 17.13: quem escreve "Cancelando..." no rodape e o PULSO (Update-Progresso),
    # nao esta linha - o rodape e reescrito a cada tique e apagaria o texto.
    # Aqui so o pedido; a tela le a flag.
    $script:TsCancel = Get-Date
    $script:Controle.Cancelar = $true
    $script:Controle.Pausar = $false
    <#  2.0.10: CANCELAR COM A CONVERSAO PAUSADA. O motor retoma para poder
        encerrar (Request-Cancelamento), mas a tela continuava no estado
        "pausado": o relogio da pausa reescrevia o titulo e o rodape a cada
        segundo com "PAUSADO - Sem Consumir CPU/Disco" enquanto o motor limpava,
        e o "Cancelando..." nunca aparecia. A tela sai da pausa junto. #>
    if ($Estado.Atual -eq "pausado") { Set-Estado "rodando" }
    $UI.btnPausar.IsEnabled = $false
    $UI.btnCancelar.IsEnabled = $false
    $Janela.Title = "$NOME_APP  ·  " + (Traduzir "Cancelando - Aguardando o Motor Encerrar...")
}
$UI.btnPausar.add_Click({ Invoke-TogglePausa })
$UI.btnCancelar.add_Click({
    Escrever-Log "CLIQUE: Cancelar" "ACAO"
    if ($Estado.Atual -in @("rodando","pausado")) { Invoke-Cancelar }
})
$UI.btnNovaConversao.add_Click({
    Escrever-Log "CLIQUE: Nova Conversao (relendo a pasta)" "ACAO"   # 2.0.7: a frase afirmava saida mesmo depois de cancelar
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
    [void](Test-PastasIguais)   # 2.0.10: o booleano vazava no retorno
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
<#  18.24: a hora da ultima abertura de CADA pasta (o freio e por pasta, nao
    global - abrir a origem nao pode travar a saida). #>
$script:AberturaPasta = @{}
<#  18.24: trazer para a frente uma janela que ja existe. Se o tipo nao puder
    ser criado, Trazer-JanelaParaFrente devolve $false e a funcao de cima abre
    uma janela nova, como sempre fez - cosmetico nunca impede a acao. #>
function Trazer-JanelaParaFrente([IntPtr]$Hwnd) {
    if ($Hwnd -eq [IntPtr]::Zero) { return $false }
    try {
        if (-not ('LaFirma.Foco' -as [type])) {
            Add-Type -Namespace LaFirma -Name Foco -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern bool SetForegroundWindow(System.IntPtr hWnd);
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern bool ShowWindowAsync(System.IntPtr hWnd, int nCmdShow);
'@ -ErrorAction Stop
        }
        # 9 = SW_RESTORE: se a janela estiver minimizada, ela volta.
        [void][LaFirma.Foco]::ShowWindowAsync($Hwnd, 9)
        return [LaFirma.Foco]::SetForegroundWindow($Hwnd)
    } catch { return $false }
}

<#  18.24: a busca da janela ja aberta mora numa funcao so dela. Assim a
    bancada consegue testar a DECISAO de Abrir-PastaNoExplorer (abrir ou
    reaproveitar) sem precisar de um Explorer de verdade do outro lado - que
    era o que impedia este caminho de ser testado rodando (licao 45). #>
function Focar-PastaJaAberta([string]$Caminho) {
    try {
        $alvo = (Get-Item -LiteralPath $Caminho -ErrorAction Stop).FullName.TrimEnd("\")
        $shell = New-Object -ComObject Shell.Application -ErrorAction Stop
        foreach ($jan in @($shell.Windows())) {
            try {
                if (-not $jan.Document) { continue }
                $dessa = "$($jan.Document.Folder.Self.Path)".TrimEnd("\")
                if ($dessa -and ($dessa -eq $alvo)) {
                    if (Trazer-JanelaParaFrente ([IntPtr]$jan.HWND)) { return $true }
                }
            } catch { }
        }
    } catch { return $false }
    return $false
}

function Abrir-PastaNoExplorer([string]$Caminho, [string]$Rotulo) {
    <#  O LOG continua em portugues - ele e um so, e e nosso. A CAIXA fala a
        lingua da tela (17.19). O rotulo chega em portugues porque e o que o
        log quer; a traducao dele mora aqui, que e onde ele vira texto de
        tela. #>
    Escrever-Log ("CLIQUE: Abrir {0}" -f $Rotulo) "ACAO"
    if ("$Caminho" -and (Test-Path -LiteralPath $Caminho)) {
        <#  18.24 - SESSENTA E CINCO JANELAS DO EXPLORER.

            "quebrou foi tudo, esses F3 e F4, ficou muito sensivel, parecia que
            nao tava abrindo nada e eu apertando e clicando" (Diego, 18/09).

            A foto dele explica melhor que qualquer log: uma coluna com vinte
            "00_Arquivos_Base - Explorador de Arquivos" e doze
            "01_Arquivos_Finalizados", uma em cima da outra. E o log conta
            certinho - 65 aberturas em 20 segundos:

              00:14:32,2  CLIQUE: Abrir Origem
              00:14:32,4  CLIQUE: Abrir Origem
              00:14:32,6  CLIQUE: Abrir Origem   <- 200ms entre elas

            E "parecia que nao estava abrindo nada" porque estava abrindo
            DEMAIS: cada janela nova nasce exatamente sobre a anterior, no
            mesmo lugar e com o mesmo conteudo. Sessenta e cinco janelas
            identicas empilhadas sao visualmente indistinguiveis de nenhuma.

            O defeito e meu e ele e de desenho, nao de sensibilidade: eu dei
            tecla a uma acao que nao tinha freio nenhum. Todo o resto desta
            barra tem regra para o toque repetido - o censo ganhou freio de 2s
            na 18.21, a medicao tem a trava do runspace, o F1 e o F2 dependem
            do estado. Estes dois eram os unicos sem nada, e sem tecla isso
            nunca aparecia porque ninguem clica sessenta vezes no mesmo botao.
            Dar a tecla foi o que revelou o buraco que ja existia.

            Duas correcoes, e a primeira e a que resolve de verdade:

              1. REAPROVEITAR A JANELA. Se o Explorer ja esta com esta pasta
                 aberta, ele vem para a frente em vez de nascer outro. E o que
                 a pessoa quer dizer com "abrir a pasta" - ver a pasta, nao
                 colecionar janelas dela. Assim, apertar quarenta vezes traz a
                 MESMA janela quarenta vezes, que e inofensivo;
              2. FREIO de 1,2s por pasta, para a rajada que chega antes de a
                 primeira janela existir (a checagem acima ainda nao teria o
                 que achar). Igual ao do censo, e igual a ele: a recusa FALA. #>
        $agora = Get-Date
        if ($script:AberturaPasta.ContainsKey("$Caminho")) {
            $desde = ($agora - $script:AberturaPasta["$Caminho"]).TotalSeconds
            if ($desde -lt 1.2) {
                Escrever-Log ("ABRIR {0}: pedido ignorado - a pasta foi aberta ha {1:N1}s (evita empilhar janelas iguais do Explorer)" -f $Rotulo, $desde) "ACAO"
                return
            }
        }
        $script:AberturaPasta["$Caminho"] = $agora
        <#  A janela ja aberta e procurada pelo caminho que ela mostra. Se o
            Shell nao responder (COM indisponivel, Explorer reiniciando), cai
            no comportamento antigo - abrir. Falhar aqui nunca pode impedir a
            pasta de abrir. #>
        if (Focar-PastaJaAberta $Caminho) {
            Escrever-Log ("ABRIR {0}: a janela do Explorer que ja estava com esta pasta veio para a frente (nenhuma janela nova)" -f $Rotulo) "ACAO"
        } else {
            Start-Process explorer.exe -ArgumentList "`"$Caminho`""
        }
    } else {
        $rotTela = if ($script:Lang -eq "EN") {
            switch ("$Rotulo") { "Saída" { "output" } "Origem" { "source" } default { "$Rotulo" } }
        } else { "$Rotulo" }
        $msgPasta = if ($script:Lang -eq "EN") {
            ("The {0} folder does not exist on this machine:{1}{1}{2}" -f $rotTela, [Environment]::NewLine, $Caminho)
        } else {
            ("A pasta de {0} não existe nesta máquina:{1}{1}{2}" -f $rotTela, [Environment]::NewLine, $Caminho)
        }
        [System.Windows.MessageBox]::Show($msgPasta, $NOME_APP) | Out-Null
    }
}
<#  18.23: a regra da casa, aplicada aqui desde o primeiro dia destes dois
    botoes: o corpo do clique e uma FUNCAO, e a tecla chama a funcao - nunca
    uma copia da regra. Foi assim que o F5, o F11 e o F12 entraram, e e o que
    impede a tecla e o mouse de divergirem depois (licao 41). #>
function Invoke-AbrirSaida  { Abrir-PastaNoExplorer $UI.txtSaida.Text  "Saída"  }
function Invoke-AbrirOrigem { Abrir-PastaNoExplorer $UI.txtOrigem.Text "Origem" }
$UI.btnAbrirSaida.add_Click({ Invoke-AbrirSaida })
<#  18.16 - O MESMO BOTAO COMECA E PARA.

    "nunca vi um botao que comeca e nao pode parar sem ser fechando o sistema,
    ou dando F1 para comecar, ou trocando de pasta" (Diego, 17/09). Ele esta
    certo, e a falta ficou obvia depois de dita: desde a 18.14 o cancelamento do
    censo funciona de verdade - so nao existia jeito de PEDIR o cancelamento sem
    fazer outra coisa junto. Agora existe, e no lugar natural: o proprio botao
    que comecou. #>
<#  18.21 - O FREIO DO BOTAO, MEDIDO NO LOG DELE DE 17/09 (21:55:33 a 21:56:30).

    "quando o censo se tiver rodando vc tem q travar teclas q podem travar ele
    nao e mais facil" (Diego, 17/09). Ele esta certo, e o log mostra o tamanho
    do buraco: em 57 segundos o censo foi COMECADO E CANCELADO 20 VEZES, varias
    delas com 130ms entre uma e outra:

      21:56:29,172  CENSO COMPLETO pedido
      21:56:29,330  cancelamento - 2 processo(s) encerrado(s)
      21:56:29,484  o anterior ainda esta encerrando
      21:56:29,698  CENSO COMPLETO pedido        <- 366ms depois de matar

    Cada um desses "pedido" abre ffmpeg + cmd + dovi_tool lendo um arquivo de
    82 GB. Vinte pares num minuto e disco sendo aberto e morto sem nunca ler
    nada - e a tela, atras, tentando desenhar vinte estados diferentes.

    A janela nao pode confiar que ninguem vai bater no botao. O freio e simples
    e nao engessa: depois de um cancelamento, o censo nao recomeca por 2
    segundos. Quem apertar nesse intervalo e RESPONDIDO (licao 2) - o silencio
    e que faz o usuario apertar de novo. #>
$script:CensoParadoEm = $null
function Invoke-BotaoCenso {
    <#  18.18: quem clica (ou aperta F11) sempre recebe uma resposta - Start-Censo
        explica cada recusa, e o cancelamento explica a dele. #>
    if ($script:CensoRodando) {
        Escrever-Log "CLIQUE: Censo Completo (pedido de cancelamento - o censo estava rodando)" "ACAO"
        $script:CensoParadoEm = Get-Date
        Stop-Censo
        return
    }
    Escrever-Log "CLIQUE: Censo Completo" "ACAO"
    if ($script:CensoParadoEm) {
        $desde = ((Get-Date) - $script:CensoParadoEm).TotalSeconds
        if ($desde -lt 2.0) {
            Escrever-Log ("CENSO COMPLETO recusado: o censo foi cancelado ha {0:N1}s - espere 2s antes de pedir de novo, senao sao dois lendo o mesmo disco" -f $desde) "ACAO"
            return
        }
    }
    Start-Censo
}
$UI.btnCenso.add_Click({ Invoke-BotaoCenso })
$UI.btnAbrirOrigem.add_Click({ Invoke-AbrirOrigem })
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
<#  18.17 - O ATUALIZAR GANHOU F5, pedido dele. Mesmo desenho do censo e da
    medicao: o corpo do clique vira funcao, e a tecla chama a FUNCAO - nunca
    uma copia da regra. #>
<#  18.18 - O ATUALIZAR TINHA TRES DONOS, E UM DELES NAO SABIA DO F5.

    "o botao F5 la em cima so aparece quando voce da F5; antes nao" (Diego,
    17/09). Achado na hora: TRES lugares escreviam o mesmo rotulo, com regras
    diferentes - Start-Leitura escrevia "Parar F5", o leitura_fim escrevia
    "Atualizar" (sem o F5, porque eu esqueci este) e a arvore do XAML escrevia
    o terceiro. Como a pasta e lida ao abrir o programa, o leitura_fim apagava
    o F5 em segundos - e so voltava quando outra coisa reescrevia.

    E o defeito que este projeto persegue desde a 16.79, e ele volta sempre que
    eu escrevo num rotulo direto em vez de deixar UMA funcao desenhar o botao.
    Agora o Atualizar tem o mesmo dono unico que o Censo (Update-BotaoCenso) e a
    medicao (Update-BotaoMedirEL) ja tinham:

      lendo    -> "[F5] Parar" em AMBAR (a cor de aviso da casa: da para parar)
      parado   -> "[F5] Atualizar" na cor normal

    Pedido dele na mesma mensagem: a tecla vem ANTES do rotulo, entre colchetes,
    igual em toda a barra. #>
function Update-BotaoReler {
    try {
        if ($script:Lendo) {
            $UI.lblReler.Text       = "[F5] " + (Traduzir "Parar")
            $UI.lblReler.Foreground = Pincel $Cores.warn
            $UI.icoReler.Foreground = Pincel $Cores.warn
        } else {
            $UI.lblReler.Text       = "[F5] " + (Traduzir "Atualizar")
            $UI.lblReler.Foreground = Pincel $Cores.txt
            $UI.icoReler.Foreground = Pincel $Cores.txt
        }
    } catch { }
}

function Invoke-Reler {
    # 19.6: reler durante a conversao chamava Stop-Motor e matava o lote.
    # O botao ja fica apagado; o F5 nao olhava o botao. Guarda aqui tambem.
    if ($Estado.Atual -eq "rodando" -or $Estado.Atual -eq "pausado") {
        Escrever-Log "ATUALIZAR bloqueado (conversao em curso)" "ACAO"
        return
    }
    <#  18.21: reler a pasta durante o censo troca a lista embaixo dele e joga
        dois minutos de leitura fora - ver o bloco do Invoke-TrocarMedirEL. #>
    if ($script:CensoRodando) {
        Escrever-Log "ATUALIZAR bloqueado (censo completo em curso - reler a pasta trocaria a lista e o resultado do censo seria descartado). Cancele o censo (F11) se quiser reler agora." "ACAO"
        return
    }
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
}
$UI.btnReler.add_Click({ Invoke-Reler })
$UI.lstFila.add_SelectionChanged({
    Update-Diagnostico
    Update-CabecalhoFila
    # m3c23: o botao Modo mostra o Modo e o Marcado DO VIDEO SELECIONADO, entao
    # trocar de video tem que atualiza-lo - inclusive na aba Fila, onde ele
    # tambem aparece. Sem isso, sair de um video desmarcado pra um marcado
    # deixava o botao travado (mais um caminho do mesmo bug).
    Update-BotaoModo
    <#  18.11 - A TABELA DE FAIXAS ERA REFEITA DUAS VEZES POR CLIQUE.

        Medido no log dele (17/09, 11:53:48,842 -> ,850 -> ,865): um clique em
        MODO com a aba FAIXAS aparecendo gerou DOIS "FAIXAS: 5 faixa(s)". O
        primeiro e o do proprio clique; o segundo nasce do Fill-Fila que vem
        logo depois - repintar a lista dispara SelectionChanged, e o
        SelectionChanged refazia a tabela inteira.

        E a mesma familia do defeito da 18.06 (o programa desmarcando arquivo
        sozinho): evento disparado pela REPINTURA, nao pelo usuario. Enquanto
        a fila esta sendo pintada, ninguem trocou de video - e a tabela ja foi
        refeita por quem mandou pintar. #>
    if ($script:AbaAtual -eq "faixas" -and (-not $script:PintandoFila)) { Fill-Faixas }
})
$UI.abaFila.add_MouseLeftButtonUp({ Escrever-Log "ABA: Fila" "ACAO"; Set-Aba "fila" })
$UI.btnMarcarTodos.add_MouseLeftButtonUp({ Set-TodosMarcados $true })
$UI.btnDesmarcarTodos.add_MouseLeftButtonUp({ Set-TodosMarcados $false })

# A marcacao e gravada pelo EVENTO, nao por binding de duas maos: assim
# nao dependemos de o WPF escrever de volta num PSCustomObject.
$script:TrocaMarca = [System.Windows.RoutedEventHandler]{
    param($remetente, $evento)
    <#  18.06 - O PROGRAMA DESMARCAVA ARQUIVO SOZINHO. ESTA NO LOG DELE:

          00:56:25,482  EL: veredicto reaproveitado - Game.of.Thrones (FEL)
          00:56:26,436  SELECAO: Game.of.Thrones -> desmarcado
          00:56:29,573  EL: veredicto reaproveitado - Saving.Private.Ryan
          00:56:30,250  SELECAO: Saving.Private.Ryan -> desmarcado

        Ninguem clicou. Um segundo depois de cada linha ser desenhada, o
        proprio programa desmarcava o arquivo. Dai os prints impossiveis: o
        Ryan com a caixinha MARCADA dizendo "Fora da Fila", e o Troy DESMARCADO
        dizendo "Proximo a Converter" - a caixinha mostrando uma coisa e o
        estado sendo outro.

        A CAUSA, e o comentario que estava aqui era a minha suposicao errada:
        eu escrevi que o disparo sintetico do WPF "SEMPRE bate com o modelo".
        Nao bate. A lista reciclava os containers das linhas, e o WPF aplica o
        Tag (que era o INDICE) e o IsChecked em momentos diferentes: chegava
        evento com o indice de UMA linha e o estado de OUTRA. Como os dois
        diferiam, isto aqui achava que era clique de gente e GRAVAVA.

        Licao 30 de novo, agora no clique: indice e endereco temporario. A
        caixinha passou a se identificar pelo CAMINHO DO ARQUIVO, que nao muda
        de dono, e a lista parou de reciclar linha (sao dezenas, nao milhares).
        E enquanto a fila esta sendo repintada, evento de caixinha nao e
        clique: e eco do desenho. #>
    if ($script:PintandoFila) { return }
    $cx = $evento.OriginalSource
    if (-not ($cx -is [System.Windows.Controls.CheckBox])) { return }
    $i = Achar-LinhaPorCaminho "$($cx.Tag)" -1
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

<#  17.10 - O CLIQUE NA CHAVE DA MEDICAO.

    Trocar a chave REFAZ a leitura: e a leitura que mede, e uma fila lida
    com a chave anterior estaria mostrando veredicto de um estado e rodape
    de outro. Releitura e barata (a fase A e instantanea) - o que custa e
    justamente a medicao, que e o que se esta ligando ou desligando. #>
<#  17.15: dois botoes, UMA acao. Duplicar o corpo do clique seria criar
    duas versoes da mesma regra para elas divergirem depois - e o defeito que
    este projeto persegue desde a 16.79. #>
<#  17.21 - A CHAVE DISPARAVA UMA LEITURA POR CLIQUE.

    MEDIDO no log do Diego (15/09 20:31:26 -> 20:31:35): oito trocas em nove
    segundos, e OITO releituras da pasta. Cada uma cancela a anterior no meio,
    e entre uma e outra a fila fica vazia - por isso o log alterna
    "SELECAO: 1 de 1" e "SELECAO: 0 de 0" e a tela pisca. Ele: "as cores e os
    botoes demoram para voltar ao normal".

    A chave em si e instantanea: o que custa e a leitura. Entao a chave
    responde na hora (rotulo, cor, preferencia guardada) e a leitura espera
    400ms de silencio - quem clicou seis vezes le a pasta UMA. Mesmo freio do
    TimerRedim, pelo mesmo motivo. #>
<#  17.23 - "PQ TEM Q RELER A PASTA QUANDO DESLIGA?" (Diego, 16/09)

    Ele estava certo, e o log dele prova com numero. Na sessao de 15/09 a
    CHAVE sozinha disparou 28 RELEITURAS, num total de 254,5s de leitura -
    mais de quatro minutos esperando. E o comentario que eu mesmo escrevi na
    17.10 dizia "releitura e barata (a fase A e instantanea)". Nunca foi
    medido: a fase A custa ~4s POR ARQUIVO (12,93s para tres, no log de
    hoje). Afirmacao minha sem medida, exatamente o que este projeto persegue.

    E o pior: RELER COM A CHAVE DESLIGADA NAO PRODUZ NADA. A fase A marca
    todo P7+EL como MEDINDO de qualquer jeito; quem decide e a linha 2658,
    que com a chave desligada pula a fase B e manda "el_fim Desligada". Dai
    Fechar-MedicaoPendente vira todos em "EL nao medida" - que e exatamente o
    estado em que eles JA estariam se ninguem tivesse lido nada. Quatro
    minutos para chegar na mesma tela.

    Pior ainda: a releitura JOGA FORA veredicto ja pago. Start-Leitura faz
    $script:Videos.Clear(), entao o FEL do GOT, que custou 14,8s para medir,
    morria porque ele desligou a chave. Ligar de novo cobrava os 14,8s outra
    vez.

    A REGRA NOVA, em uma frase: a chave decide se MEDE DAQUI PRA FRENTE, nao
    manda esquecer o que ja foi medido.

      DESLIGAR -> nao le nada. Encerra a medicao em curso (quem estava no
        meio vira "EL nao medida", como sempre) e mantem na tela o veredicto
        de quem JA foi medido - medida e fato, nao preferencia.
      LIGAR    -> se todo mundo da fila ja tem veredicto, nao ha o que medir
        e nao se le nada. So le quando existe arquivo sem veredicto - porque
        hoje a fase B mora dentro da leitura (linha 2658) e nao sabe nascer
        sozinha. Essa parte fica para quando valer a pena separar. #>
function Get-PendentesDeMedida {
    # P7 com camada EL e sem veredicto - os unicos que a fase B tocaria.
    if (-not $script:Videos) { return @() }
    return @($script:Videos | Where-Object {
        [int]$_.DVperfil -eq 7 -and "$($_.DVcamadas)" -match "EL" -and
        ("$($_.ELtipo)" -eq "NAO_MEDIDO" -or "$($_.ELtipo)" -eq "MEDINDO")
    })
}

<#  ============================================================================
    18.00 - A CHAVE VOLTOU A SER UMA CHAVE

    Ate a 17.24 este botao tinha SEIS saidas diferentes, cada uma um "if" que eu
    somei quando um caso quebrou:

        ligada - N sem veredicto, relendo a pasta para medir
        ligada - a leitura em curso ja vai medir
        ligada - todos ja tem veredicto, nada a medir
        desligada - a medicao em curso foi encerrada
        desligada durante a leitura - a leitura TERMINA, so a medicao foi cancelada
        desligada - o veredicto ja medido continua valendo

    Seis mensagens para um clique nao e modelo, e casuistica. Do lado de fora
    vira comportamento imprevisivel, e foi exatamente o que o Diego relatou.

    Com os tres trabalhos separados sobram DUAS regras, e elas cabem numa frase:

        LIGADA   -> se ha arquivo sem veredicto na fila, mede. Senao, nada.
        DESLIGADA-> para a medicao, se houver uma rodando. O que ja foi medido
                    continua valendo: medida e fato, nao preferencia.

    A leitura da pasta NAO aparece em lugar nenhum desta regra - e essa e a
    diferenca. Ligar ou desligar a chave nunca mais le pasta, nunca mais mata
    censo, e nunca mais congela a janela.

    O freio de 400ms continua, pelo motivo de sempre: o rotulo responde no
    clique, a acao espera o usuario parar de clicar. Oito cliques seguidos
    fazem UMA coisa so, no fim. #>
$TimerChaveEL = New-Object System.Windows.Threading.DispatcherTimer
$TimerChaveEL.Interval = [TimeSpan]::FromMilliseconds(400)
$TimerChaveEL.add_Tick({
    if ($script:Fechando) { return }
    $TimerChaveEL.Stop()
    if ($Estado.Atual -ne "inicial") { return }

    if (-not $script:MedirELLigado) {
        if ($script:MedindoEL) {
            Stop-Medicao
            Escrever-Log "MEDIR EL: desligada - a medicao em curso esta sendo encerrada" "ACAO"
        } else {
            Escrever-Log "MEDIR EL: desligada - nada estava sendo medido; o veredicto ja obtido continua valendo" "ACAO"
        }
        return
    }

    <#  Ligada: se a leitura ainda esta rodando, nao ha o que medir AGORA - a
        fila nem existe inteira. Quem dispara a medicao nesse caso e o
        "leitura_fim", que confere a chave no momento certo. #>
    if ($script:Lendo) {
        Escrever-Log "MEDIR EL: ligada - a medicao comeca assim que a leitura terminar" "ACAO"
        return
    }
    $faltam = @(Get-PendentesDeMedida).Count
    if ($faltam -eq 0) {
        Escrever-Log "MEDIR EL: ligada - todos os arquivos da fila ja tem veredicto" "ACAO"
        return
    }
    Start-Medicao
})

<#  18.21 - O QUE PODE QUEBRAR O CENSO AGORA FICA TRAVADO ENQUANTO ELE RODA.

    "tipo ligar e desligar fel nao eh uma logica melhor? sem engessar o
    programa vc pode seguir essa logistica" (Diego, 17/09). E a logistica certa,
    e o log dele de 21:56:32 mostra por que - com o censo rodando ele alternou
    F12 seis vezes em dois segundos:

      21:56:32,390  MEDIR EL: DESLIGADO
      21:56:32,438  CENSO COMPLETO: lendo o RPU do filme inteiro
      21:56:32,551  MEDIR EL: LIGADO        <- a medicao quer abrir dovi_tool
                                               no mesmo disco que o censo esta
                                               lendo de ponta a ponta

    Sao DUAS acoes, e as duas mexem no chao onde o censo pisa:

      F12  liga a medicao, que dispara dovi_tool por arquivo pendente - disco
           disputado com o censo, que e justamente o que a 17.21 proibiu para
           a conversao e esqueceu de proibir aqui;
      F5   rele a pasta e REFAZ a lista - o arquivo que esta sendo contado pode
           sair dela, e o resultado do censo cai no "nao esta mais na lista,
           resultado descartado". Dois minutos de leitura no lixo.

    Travar nao e engessar: o censo dura cerca de dois minutos, ele mesmo pode
    ser cancelado a qualquer momento pelo proprio botao, e a recusa DIZ como
    sair ("cancele o censo primeiro"). #>
function Invoke-TrocarMedirEL {
    if ($Estado.Atual -in @("rodando","pausado")) {
        Escrever-Log "MEDIR EL bloqueado (conversao em curso)" "ACAO"
        return
    }
    if ($script:CensoRodando) {
        Escrever-Log "MEDIR EL bloqueado (censo completo em curso - ele le o filme inteiro e a medicao disputaria o mesmo disco). Cancele o censo (F11) se quiser trocar agora." "ACAO"
        return
    }
    $script:MedirELLigado = -not $script:MedirELLigado
    Salvar-MedirEL
    Update-BotaoMedirEL
    Escrever-Log ("MEDIR EL: {0}" -f $(if ($script:MedirELLigado) { "LIGADO" } else { "DESLIGADO" })) "ACAO"
    $TimerChaveEL.Stop()
    $TimerChaveEL.Start()
}

$UI.btnMedirEL.add_MouseLeftButtonUp({ Invoke-TrocarMedirEL })
$UI.btnMedirELTopo.add_Click({ Invoke-TrocarMedirEL })

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
    # 17.03: o dropdown pode estar em ingles; tudo daqui para baixo decide
    # com o valor canonico, em portugues.
    $novo = Get-VerboCanonico "$($evento.AddedItems[0])"
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
    <#  17.16: segunda tranca. O dropdown de uma legenda que nao e a pt-BR
        nem oferece CONVERTER (Get-OpcoesVerbo), mas quem escreve o valor
        tambem confere - a lista de opcoes e desenho, e desenho nao e regra. #>
    if ($novo -eq "CONVERTER" -and $f.Tipo -eq "subtitles" -and -not (Test-EhLegendaPtBr $f)) {
        Escrever-Log ("FAIXA recusada: id {0} nao e a legenda pt-BR - o OCR deste programa e pt-BR e so" -f $f.Id) "AVISO"
        Fill-Faixas
        return
    }
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
<#  16.88 - O BOTAO "ENTENDA".

    O programa mede MEL x FEL, separa Simple de Complex, decide audio,
    escolhe legenda e recusa Perfil 5 - e cada uma dessas decisoes aparecia
    como uma linha curta na tela. Linha curta e o formato certo para DECIDIR
    e o formato errado para APRENDER: quem quer entender por que o Saving
    Private Ryan saiu vermelho nao cabe numa oracao.

    O texto vive em FAQ_PT.txt, ao lado do programa, e NAO dentro do .ps1.
    Assim da para corrigir uma frase sem tocar em codigo, o mesmo arquivo
    serve de base para o README e para o post da comunidade, e a versao EN
    entra depois como FAQ_EN.txt sem mexer em nada aqui.

    Se o arquivo faltar, a janela diz onde ele deveria estar - nao finge que
    o botao nao existe nem some com ele. #>
$UI.btnIdioma.add_Click({
    Escrever-Log "CLIQUE: Idioma" "ACAO"
    $alvo = if ($script:Lang -eq "PT") { "EN" } else { "PT" }
    Set-Idioma $alvo
    # 17.04: quem pergunta se quer reiniciar e o CLIQUE, nao o Set-Idioma -
    # senao o arranque pergunta sozinho e estoura ao fechar uma janela que
    # ainda nao foi exibida.
    if ($script:Lang -eq $alvo) { Offer-ReinicioIdioma $alvo }
})
$UI.btnEntenda.add_Click({
    Escrever-Log "CLIQUE: Entenda" "ACAO"
    <#  16.94 - O TEXTO SEGUE A LINGUA (achado do Diego, 09/09):
        "se muda pra ingles no meio, o learn q muda mas o texto q abre nao".
        Estava certo - o rotulo do botao passava pela traducao e o conteudo
        nao, entao "Learn" abria um texto inteiro em portugues. Agora o
        arquivo e escolhido na hora do clique, pela lingua ATUAL, e nao no
        carregamento: trocar a bandeira no meio da sessao ja vale no proximo
        clique, sem reiniciar. Se o FAQ_EN.txt faltar, abre o PT dizendo em
        ingles que so a versao portuguesa esta instalada - nunca uma janela
        vazia. #>
    $ehEN   = ($script:Lang -eq "EN")
    $titulo = if ($ehEN) { "LaFirma - Understand the Conversion" } else { "LaFirma - Entenda a Conversão" }
    $arq    = Join-Path $script:PastaScript $(if ($ehEN) { "FAQ_EN.txt" } else { "FAQ_PT.txt" })
    $arqPT  = Join-Path $script:PastaScript "FAQ_PT.txt"
    if (Test-Path -LiteralPath $arq) {
        $txt = [System.IO.File]::ReadAllText($arq, [System.Text.Encoding]::UTF8)
        Show-JanelaTexto $titulo $txt $true
    } elseif ($ehEN -and (Test-Path -LiteralPath $arqPT)) {
        $txt = [System.IO.File]::ReadAllText($arqPT, [System.Text.Encoding]::UTF8)
        Escrever-Log "Entenda: FAQ_EN.txt ausente - abrindo a versao PT" "AVISO"
        Show-JanelaTexto $titulo `
            ("[ The English version (FAQ_EN.txt) was not found in this folder." + "`n" +
             "  Showing the Portuguese text below. ]" + "`n`n" + $txt) $true
    } else {
        $falta = if ($ehEN) { "FAQ_EN.txt" } else { "FAQ_PT.txt" }
        $msg = if ($ehEN) {
            "The explanatory text was not found.`n`nIt should be at:`n$arq`n`n" +
            "If you assembled the folder by hand, copy $falta along with the .ps1 files."
        } else {
            "O texto explicativo não foi encontrado.`n`nEle deveria estar em:`n$arq`n`n" +
            "Se você montou a pasta na mão, copie o $falta junto com os .ps1."
        }
        Show-JanelaTexto $titulo $msg $true
    }
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

<#  17.20 - O ESC NAO DESISTIA DA ESPERA PELA MEDICAO.

    Visto no log do Diego, 19:42:32: ele clicou Iniciar com a medicao rodando,
    escolheu ESPERAR, mudou de ideia e apertou ESC - e o log respondeu
    "ignorada - nao se aplica ao estado 'inicial'". Ele so conseguiu sair
    desligando a chave de medicao, que e um caminho que ninguem adivinha.

    O estado E "inicial", entao o botao Cancelar esta apagado com razao: nao
    ha conversao para cancelar. Mas existe UMA COISA PENDENTE - o Iniciar
    represado - e ESC e a tecla de "desisto". Quando a unica coisa em curso e
    a espera, ESC desiste dela.

    Nao mexe na medicao: ela continua rodando em segundo plano e os arquivos
    seguem ganhando veredicto. O que se cancela e a PROMESSA de comecar
    sozinho quando ela acabar. #>
function Invoke-DesistirDaEspera {
    if (-not $script:IniciarAposMedir) { return $false }
    $script:IniciarAposMedir = $false
    Set-BotaoIniciar (($Estado.Atual -eq "inicial") -and (@(Get-Marcados).Count -gt 0))
    Update-AvisoEspera
    Escrever-Log "INICIAR: a espera pela medicao foi cancelada pelo usuario (ESC) - a medicao continua" "ACAO"
    return $true
}
# Teclado global: F1 inicia; F2 alterna Pausar/Retomar; ESC cancela.
$Janela.add_PreviewKeyDown({
    param($s,$e)
    <#  18.17 - A TECLA PAROU DE DIZER "IGNORADA" E AGIR ASSIM MESMO.

        MEDIDO no log dele de 17/09, 16:47:11,7 (e mais 40 vezes seguidas):

          TECLA: F11 (ignorada - nao se aplica ao estado 'rodando')
          CENSO COMPLETO: o anterior ainda esta encerrando - o novo comeca...

        Ou seja: a janela escrevia que tinha ignorado a tecla e chamava a acao
        logo em seguida - duas linhas contraditorias por tecla, e uma delas
        mentira (licao 2). A causa e simples: esse "vale" servia para F1/F2/ESC,
        onde quem manda e o IsEnabled do botao, e eu o estendi para F11/F12, onde
        quem manda e a REGRA DENTRO da funcao.

        Agora cada tecla registra so o que e verdade: as que dependem do botao
        continuam conferindo o botao; as que tem regra propria apenas dizem que
        foram apertadas e deixam a funcao explicar o que fez - que e o que ela
        ja fazia bem ("MEDIR EL bloqueado (conversao em curso)"). #>
    <#  18.18: tecla SEGURADA repete sozinha (auto-repeat do Windows). No log
        dele isso virou 20 "MEDIR EL: LIGADO/DESLIGADO" em dois segundos, que e
        ruido e nao intencao. A primeira batida vale; as repeticoes, nao. #>
    if ($e.IsRepeat) { $e.Handled = $true; return }
    <#  18.21: o F11 entrou para o grupo que confere o BOTAO. Ele ficou de fora
        na 18.17 com um motivo que era verdade na epoca ("quem manda e a regra
        dentro da funcao") e deixou de ser na 18.16, quando o botao virou
        liga/desliga: a partir dali o IsEnabled do censo passou a valer para as
        duas portas, e so a do mouse obedecia. Conferir o mesmo botao e a
        unica forma de mouse e teclado NAO poderem discordar - ler a mesma
        propriedade e mais forte que repetir a mesma regra em dois lugares. #>
    <#  18.23: F3 e F4 abrem as pastas. Sao os unicos botoes da barra que nunca
        ficam apagados (abrir uma pasta nao depende de estado nenhum), entao
        nao ha recusa a explicar - mas eles conferem o botao do mesmo jeito que
        os outros, porque a regra tem que ser a mesma para todos e nao a que
        cada caso permitiria. #>
    if ($e.Key -in @("F1","F2","F3","F4","F11","Escape")) {
        $vale = switch ($e.Key) {
            "F1"     { $UI.btnIniciar.IsEnabled }
            "F2"     { $UI.btnPausar.IsEnabled }
            "F3"     { $UI.btnAbrirOrigem.IsEnabled }
            "F4"     { $UI.btnAbrirSaida.IsEnabled }
            "F11"    { $UI.btnCenso.IsEnabled }
            "Escape" { $UI.btnCancelar.IsEnabled -or $script:IniciarAposMedir }
        }
        if ($vale) { Escrever-Log ("TECLA: {0}" -f $e.Key) "ACAO" }
        elseif ($e.Key -eq "F11") {
            <#  18.22 - A SEGUNDA PARTE: A RECUSA TEM QUE DIZER A VERDADE.

                "(ignorada - nao se aplica ao estado 'inicial')" trinta vezes
                no log dele. O estado ERA inicial, e era a coisa certa - a
                frase apontava para onde o problema nao estava, e por isso ele
                ficou batendo na tecla. O motivo real ("o censo anterior ainda
                esta encerrando") ja existia, escrito, na dica do botao; era so
                usar a mesma frase, de um lugar so, como o resto do programa
                ja faz desde a 18.18. #>
            $iSel = $UI.lstFila.SelectedIndex
            $vSel = $(if ($iSel -ge 0 -and $iSel -lt $script:Videos.Count) { $script:Videos[$iSel] } else { $null })
            Escrever-Log ("TECLA: F11 recusada - {0}" -f (Get-MotivoCenso $vSel)) "ACAO"
        }
        elseif ($e.Key -eq "Escape") {
            <#  2.0.2 - O MESMO DEFEITO DO F11, PELA OUTRA TECLA (licao 46).

                Log do Diego, 22/09: ele apertou [ESC], o motor ficou minutos
                em "cancelando", ele apertou [ESC] de novo e o log respondeu
                "(ignorada - nao se aplica ao estado 'rodando')". O estado ERA
                rodando, e era a verdade - e era inutil. A frase apontava para
                onde o problema nao estava, exatamente como a do F11 fazia
                antes da 18.22, e ele fez a unica coisa que sobrava: fechou a
                janela na mao.

                O motivo real existe e e outro em cada caso: ou o cancelamento
                JA foi pedido e esta em curso, ou nao ha o que cancelar. #>
            if ($script:TsCancel) {
                $hCancel = [int]((Get-Date) - $script:TsCancel).TotalSeconds
                Escrever-Log ("TECLA: Escape recusada - o cancelamento ja foi pedido ha {0}s e esta em curso; estou esperando a etapa atual soltar os programas dela. Apertar de novo nao acelera." -f $hCancel) "ACAO"
            } else {
                Escrever-Log "TECLA: Escape recusada - nao ha conversao em curso para cancelar." "ACAO"
            }
        }
        else { Escrever-Log ("TECLA: {0} (ignorada - nao se aplica ao estado '{1}')" -f $e.Key, $Estado.Atual) "ACAO" }
    }
    elseif ($e.Key -in @("F5","F12")) {
        Escrever-Log ("TECLA: {0}" -f $e.Key) "ACAO"
    }
    switch ($e.Key) {
        "F1"     { if ($UI.btnIniciar.IsEnabled) { Invoke-Iniciar }; $e.Handled = $true }
        "F2"     { if ($UI.btnPausar.IsEnabled)  { Invoke-TogglePausa }; $e.Handled = $true }
        "F3"     { if ($UI.btnAbrirOrigem.IsEnabled) { Invoke-AbrirOrigem }; $e.Handled = $true }
        "F4"     { if ($UI.btnAbrirSaida.IsEnabled)  { Invoke-AbrirSaida  }; $e.Handled = $true }
        "F5"     { Invoke-Reler; $e.Handled = $true }   # 19.6: a guarda de estado mora DENTRO de Invoke-Reler (um dono)
        "F11"    { if ($UI.btnCenso.IsEnabled) { Invoke-BotaoCenso }; $e.Handled = $true }
        "F12"    { Invoke-TrocarMedirEL; $e.Handled = $true }
        "Escape" {
            <#  17.20: a espera vem PRIMEIRO. Com ela pendente o estado e
                "inicial" e o Cancelar esta apagado, entao os dois nunca
                disputam - mas a ordem deixa a regra escrita. #>
            if (Invoke-DesistirDaEspera) { $e.Handled = $true }
            elseif ($UI.btnCancelar.IsEnabled) { Invoke-Cancelar; $e.Handled = $true }
        }
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
    if ($script:Fechando) { return }
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
    <#  17.10: a chave e lida ANTES da primeira leitura - senao a sessao
        inteira roda no padrao e a preferencia do Diego so valeria na
        segunda pasta. Mesma armadilha que o idioma teve na 17.02. #>
    Carregar-MedirEL
    Update-BotaoMedirEL
    Escrever-Log ("MEDIR EL: {0} (preferencia guardada)" -f `
        $(if ($script:MedirELLigado) { "LIGADO" } else { "DESLIGADO" })) "PROVA"
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
    <#  16.99: a calibragem e lida DEPOIS que o log existe, para que a linha
        que diz qual valor esta valendo apareca na sessao. Antes disso ela
        seria escrita no vazio, e o numero que manda na estimativa inteira
        ficaria sem rastro. #>
    Carregar-Calibragem
    Carregar-CalibragemEtapas
    Escrever-Log ("Interface renderizada. Iniciar chama o motor{0} DE VERDADE - a conversao escreve na pasta de saida." -f $verMotor)
})
# 16.12: fechar a janela no meio de uma conversao e cancelar por outro nome -
# o runspace morre junto e o episodio em andamento se perde. Mesma pergunta.
$Janela.add_Closing({
    param($remetente, $ev)
    if ($Estado.Atual -notin @("rodando","pausado")) { return }
    # 17.19: tambem saia so em portugues - ver o bloco do Invoke-Cancelar.
    $texto = if ($script:Lang -eq "EN") {
        ("Close the program now?`n`nA conversion is running. Closing cancels the video being assembled - the partial file is deleted and the time spent on it is lost.`n`nVideos that already finished stay in the output folder.")
    } else {
        ("Fechar o programa agora?`n`nA conversão está em andamento. Fechar cancela o vídeo que está sendo montado - o arquivo parcial é apagado e o tempo gasto nele se perde.`n`nOs vídeos que já terminaram continuam na pasta de saída.")
    }
    $tituloFechar = if ($script:Lang -eq "EN") { "LaFirma - close with a conversion running?" }
                    else { "LaFirma - fechar com conversão em andamento?" }
    if (-not (Confirm-Parar $tituloFechar $texto)) {
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
    <#  18.12 - FECHAR TEM QUE PARAR TODOS OS RELOGIOS, NAO UM SO.

        Log dele de 10/09, 01:26:31,8 - trocar o idioma e mandar reiniciar:

          01:26:31,7  IDIOMA: reinicio pedido pelo usuario
          01:26:31,8  ERRO: Nao sera possivel definir Visibility nem chamar
                      Show, ShowDialog ou WindowInteropHelper.EnsureHandle
                      depois que uma Janela for fechada.

        A janela fechava e so o TimerFila era parado. Os outros quatro
        DispatcherTimer continuavam batendo no dispatcher que ainda estava
        vivo, e o primeiro que encostou na janela morta estourou. Nao e
        cosmetico: um erro desses no fechamento pode deixar o processo velho
        pendurado enquanto o novo ja esta subindo.

        A flag existe para o que NAO e relogio: BeginInvoke ja agendado,
        mensagem em voo, callback que chega depois. Quem mexe na tela pergunta
        antes se a janela ainda existe. #>
    $script:Fechando = $true
    Escrever-Log "Janela fechada pelo usuario"
    foreach ($t in @($TimerFila, $TimerPausa, $TimerFilaRelogio, $TimerChaveEL, $TimerRedim)) {
        try { if ($t) { $t.Stop() } } catch { }
    }
    <#  2.0.10: o censo e a medicao tambem. Stop-Motor so cuida da leitura e do
        motor - fechar a janela com o [F11] rodando deixava o dovi_tool lendo o
        filme inteiro sem janela nenhuma (e, no "reiniciar para trocar o
        idioma", disputando o disco com a instancia nova). Mesma guarda do
        Iniciar (Invoke-IniciarInterno). #>
    try { if ($script:CensoRodando) { Escrever-Log "CENSO COMPLETO: encerrado - a janela foi fechada" "ACAO"; Stop-Censo } } catch { }
    try { if ($script:MedindoEL) { Escrever-Log "MEDICAO: encerrada - a janela foi fechada" "ACAO"; Stop-Medicao } } catch { }
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
