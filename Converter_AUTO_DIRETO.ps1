# ============================================================================
#  [DDVT] Conversor de PERFIL Dolby Vision [8.1] + Conversor LEGENDA PGS [srt]
#         + Conversor de AUDIO [Dolby TrueHD / DTS:HD / DTS:X -> E-AC-3]
#  ffmpeg + dovi_tool + mkvmerge (+ OCR de legenda PT-BR opcional via PgsToSrt)
# ============================================================================
#
#  VERSAO: 14.36 (o valor efetivo esta em $SCRIPT_VERSION, mais abaixo)
#  ----------------------------------------------------------------------
#  REGRA DE VERSIONAMENTO (definida com o usuario):
#    - Atualizacao GRANDE (muda comportamento/logica): sobe o numero maior
#      (ex: 7.x -> 8.0).
#    - Atualizacao PEQUENA (ajuste/correcao pontual): sobe o numero menor
#      (ex: 8.0 -> 8.1 -> 8.2).
#  A cada novo .ps1, atualizar $SCRIPT_VERSION abaixo e este historico.
#
#  Historico (v1.0 -> v2.0 reconstruido a partir das evidencias documentadas
#  nos proprios comentarios do script; v3.0 em diante e registrado na hora).
#
#   v14.33 (um 'else' vazio que engolia tres ramos - 01/09/2026)
#     Havia um "} else { }" vazio antes do elseif do tratamento de erro do
#     OCR. Ele FECHAVA o if, e o elseif seguinte virava nome de comando.
#     O PowerShell aceita no parse (o arquivo abre limpo, a bateria passava)
#     e so estoura quando a linha roda. Resultado: qualquer falha de OCR que
#     nao fosse "falta o .NET Runtime" derrubava o EPISODIO INTEIRO com
#     "The term 'elseif' is not recognized", em vez de seguir sem legenda.
#     Os ramos "PgsToSrt indisponivel" e "codigo N" nunca rodaram.
#     Achado em auditoria; reproduzido em pwsh isolado antes de consertar.
#     A bateria agora reprova comando cujo nome e palavra-chave do
#     PowerShell - a classe do defeito, em todos os seis arquivos.
#
#   v14.32 (duas travas que nao travavam - 27/08/2026)
#     1. TEST-PATH SEM -LiteralPath na trava 'ja existe na pasta de saida'.
#        Era o unico do programa inteiro. Com colchete no nome do arquivo
#        ('Show.S01E01.[1080p].mkv') o Test-Path le o colchete como classe
#        de caractere, responde 'nao existe' com o arquivo la, e o motor
#        reconverte o episodio do zero para sobrescrever a saida boa no
#        fim. Achado em auditoria, nao em conversao - por isso a nota:
#        so aparece em release com colchete no nome.
#     2. CATCH VAZIO apagava a conferencia de espaco em disco. Get-PSDrive
#        nao resolve raiz de rede (\\servidor\share); falhando, a variavel
#        ficava nula, o if inteiro era pulado e a conversao seguia SEM
#        nenhuma conferencia - calada. Agora avisa que nao pode medir.
#
#   v14.31 (a melhor nota da legenda saia com a frase da pior - 27/08/2026)
#     TRES defeitos de MENSAGEM, todos achados no log do Diego de 27/08:
#     1. EXCELENTE CAIA NO ELSE. Os dois ifs que escolhem a frase do veredicto
#        (o da sub-etapa do Reocr e o do resumo do arquivo) tratavam BOA e
#        RAZOAVEL por nome e jogavam TODO o resto no else - o else e o texto de
#        RUIM. Como o Reocr devolve EXCELENTE quando nao sobrou defeito nenhum,
#        o Se7en de 00h32 saiu assim:
#           [AVISO] Qualidade da Legenda: EXCELENTE (0 bloco(s), 0,00%)
#                   - recomendo assistir pela faixa PGS original
#        Nota maxima, em amarelo, com [AVISO], mandando o usuario NAO usar a
#        legenda que acabou de sair perfeita. EXCELENTE tem ramo proprio agora.
#     2. O MOTIVO DO ERRO NAO IA PARA O LOG. A linha era "Falha ao Processar
#        Este Episodio. Detalhes Completos no Resumo Final Desta Execucao" - e
#        o resumo final que vai para o LOG nao tem os detalhes: o Motivo so
#        existe no objeto de resultado, que a JANELA usa no cartao. No Troy de
#        01h04 o log registrou o FALHOU sem uma palavra sobre a causa; o
#        "Espaco Insuficiente ... Faltam ~4,33 GB" so apareceu na tela. Agora
#        o motivo e impresso na hora, e por isso entra no log.
#     3. A BARRA "TRAVADA EM 87%". Ela nao travava. Eram 19 blocos suspeitos
#        numa faixa de 42 pontos de tela: cada bloco vale 2,2 pontos, e o bloco
#        13 era um dos RECUSADOS, que roda as 60 leituras inteiras antes de
#        desistir. Tres minutos de trabalho real que movem a barra 2%.
#        Numero de barra nenhum resolve isso - o que faltava era DIZER em que
#        bloco esta. A linha da etapa agora mostra "bloco 13 de 19", e o Reocr
#        1.24 passou a avisar a cada LEITURA (60 por bloco) em vez de a cada
#        altura (12 por bloco), entao a barra tambem anda cinco vezes mais.
#
#   v14.30 (o seconv rodava DUAS VEZES no mesmo arquivo - 27/08/2026)
#     MEDIDO no log do Spider-Man de 26/08: as 21:42 o motor chamou o seconv,
#     ele voltou com 31,1% dos caracteres como '*', o motor RECUSOU e caiu pro
#     PgsToSrt - 1m13s. As 21:44 o Corretor_Legenda chamou O MESMO seconv, no
#     MESMO .mkv, com o MESMO Latin.db, como "2a opiniao": mesmos 31,1% de
#     '*', ZERO correcoes, mais 1m12s jogados fora.
#     Nao e caso isolado deste arquivo: quando o Latin.db nao casa com a fonte
#     do release, as duas chamadas SEMPRE dao o mesmo resultado - e o mesmo
#     programa lendo a mesma imagem com o mesmo banco.
#     O motor agora marca $script:SeconvRecusadoNesteArquivo (zerada POR
#     ARQUIVO, junto com as notas de legenda) e passa -PularSegundaOpiniao ao
#     Corretor 2.23. So marca quando o seconv RODOU e foi recusado por
#     QUALIDADE ou por IDIOMA - nao quando ele nem gerou legenda, porque ali a
#     causa pode ser outra e a 2a opiniao ainda tem valor.
#     Quando o seconv sai bom, nada muda. Os blocos suspeitos seguem para o
#     Reocr de qualquer jeito, que usa Tesseract PSM 6 e nao depende do banco.
#     Ganho medido: ~1 min por filme, risco zero.
#
#   NOTA DE HISTORICO (27/08/2026): as versoes v14.17 a v14.29 foram
#     implementadas e documentadas nos comentarios <# v14.xx: ... #> ao lado
#     do proprio codigo, mas NAO foram lancadas nesta lista - ela ficou parada
#     na v14.16. Quem lesse so daqui concluiria que o motor nao mudou desde
#     entao, o que e falso. Nao vou inventar as entradas que faltam a partir
#     de memoria: quem quiser o detalhe delas procure os blocos v14.17+ no
#     corpo do arquivo. Da v14.30 em diante, entrada nova aqui e obrigatoria
#     na mesma edicao que muda o $SCRIPT_VERSION.
#
#   v14.16 (VIDEO QUEBRADO NA METADE DO FILME - Se7en, achado real)
#     O Se7en saiu com imagem congelada a partir de 00:47:44; o audio e a
#     legenda seguiam normais ate o fim. O video dele JA ERA Profile 8 sem
#     Enhancement Layer, ou seja: o dovi_tool nao tinha nada a fazer. Mesmo
#     assim o motor extraia os 62 GB de HEVC para um arquivo solto (.hevc,
#     Annex-B, SEM timestamps) na [1/5] e mandava esse arquivo solto para o
#     mkvmerge na [5/5]. Nesse caminho o mkvmerge tem que reconstruir sozinho
#     o cabecalho do codec (hvcC) a partir dos parametros que ele encontra no
#     fluxo, e monta a linha de tempo inteira por conta propria a partir do
#     --default-duration. Num remux HYBRID (dois encodes emendados, e o Se7en
#     e um "HYBRID" pelo proprio nome do arquivo) existe mais de um conjunto
#     de parametros dentro do fluxo - o que sobrevive no hvcC e o primeiro, e
#     da emenda em diante o decodificador passa a decodificar com o cabecalho
#     errado: imagem congela, audio continua.
#     A CORRECAO NAO E UM REMENDO NO Se7en. Quando nao ha conversao de Dolby
#     Vision a fazer, o video AGORA NAO SAI DO CONTAINER: o mkvmerge le a
#     faixa de video direto do MKV de origem, com o hvcC e os timestamps
#     originais, byte a byte. Sem arquivo solto, sem reconstrucao, sem risco -
#     para todo arquivo que ja chega em Profile 8.x, nao so para este.
#     De quebra: a [1/5] deixa de existir nesses arquivos (2m00s no Se7en) e a
#     exigencia de espaco em disco cai de 3,15x para 1,6x o tamanho da origem.
#   v14.16 (o programa entregava arquivo quebrado dizendo que estava tudo OK)
#     O motor conferia se o mkvmerge terminou sem erro e se o arquivo final
#     existia com tamanho maior que zero - e so. Um arquivo que nao decodifica
#     da metade em diante passa nos dois testes. Agora existe uma etapa
#     [VERIFICACAO] depois da remontagem: ela decodifica de verdade 10 trechos
#     curtos espalhados do inicio ao fim do arquivo final. Se algum nao
#     decodificar, o motor refaz o mesmo teste nos MESMOS pontos do arquivo de
#     ORIGEM e diz qual dos dois esta com problema, em vez de deixar isso para
#     o usuario descobrir assistindo.
#   v14.15 (a barra do dovi_tool encostava em 99% e ficava minutos parada)
#         * A estimativa dele era 15 SEGUNDOS, fixa, num trabalho que leva
#           3-4 MINUTOS em remux 4K. A curva encostava em 99% no primeiro
#           minuto e ficava la o resto da etapa - o "[3/7] em 99% durante 64%
#           da etapa" ja registrado no STATUS.
#         * Medido em tres arquivos: 2,4 a 3,3 segundos por GB. A estimativa
#           passa a acompanhar o tamanho (1,2 s/GB, mesma regra do seconv e do
#           Corretor: EST = tipico / 2,3), com piso de 8s.
#
#   v14.14 (a barra do AUDIO parava de andar depois dos 80% - era o peso)
#         * O usuario descreveu: "ate os 80 tava indo de boa, ai depois de um
#           tempo comeca a ficar lento de uma % para a outra; de 92% para 94%
#           levou muito tempo". Nao e a maquina.
#         * O DeeZy roda 3 fases (truehdd -> DEE measure -> DEE encode) e a
#           barra dava 80% pra PRIMEIRA e 10% pra cada uma das outras duas. O
#           motivo estava escrito no proprio comentario: "as fases do DEE
#           costumam ser rapidas (segundos, nao minutos)" - suposicao, nunca
#           medida. As fases 2 e 3 tinham 20% da barra pra uma fatia grande do
#           trabalho, e por isso arrastavam.
#         * Terceira vez que a MESMA causa aparece neste projeto: peso fixo por
#           suposicao. Antes foi a etapa de audio com 1/7 da regua carregando
#           80% do trabalho (janela 16.34), depois o Reocr com 5% da barra pra
#           43% do trabalho (motor 14.12).
#         * Agora cada fase vale 1/N da barra e o pedaco da fase corrente e
#           preenchido pelo percentual que o PROPRIO DeeZy informa - a barra
#           anda com o que a ferramenta diz, nao com o que o motor supoe.
#           Mais teto duro em 99% e trava de retrocesso.
#
#   v14.13 (7 etapas viraram 5 - as duas que nao eram trabalho sairam da regua)
#         * [1/7] era DIAGNOSTICO (decide o que fazer, media 1s) e [7/7] era
#           LIMPEZA (fecha em 00m00s em TODOS os logs medidos). Duas caixas de
#           sete - 29% da regua - reservadas pra 1 segundo. Era dai que vinha
#           o pedaco vazio no fim da barra do video durante a remontagem.
#         * Agora as duas tem marcador proprio ([DIAGNOSTICO] e [LIMPEZA]) e
#           as cinco de trabalho sao [1/5] a [5/5]:
#               [1/5] video  [2/5] Dolby Vision  [3/5] audio
#               [4/5] legenda  [5/5] remontagem
#           As duas continuam na tela e no log, com relogio proprio - so
#           sairam da regua e da divisao do tempo restante.
#
#   v14.12 (a barra da [5/7] para de mentir no OUTRO extremo)
#         * MEDIDO no teste do Troia de 18/08 (log 14:53:53): a 14.11 mostrou
#           100% na [5/7] as 15h16:21 e a etapa so fechou as 15h19:54.
#           TRES MINUTOS E MEIO de barra cheia com o tesseract ainda
#           trabalhando. Duas causas, as duas corrigidas:
#           (a) Show-BarraFaixa podia encostar no fim da faixa enquanto o
#               processo rodava. Agora existe TETO DURO: a barra para em
#               (fim da faixa - 1) e so Show-BarraFaixaFim escreve o numero
#               final, depois que o processo saiu de verdade.
#           (b) a estimativa do Reocr era 40s e o trabalho real foi 5m43s.
#               Agora o Reocr tem PROGRESSO REAL: ele ja anuncia
#               "candidatos a re-OCR: N" e "[i/N]" por bloco, e sao esses
#               numeros que movem a barra - igual ao PgsToSrt.
#         * Outras duas estimativas trocadas por MEDIDA, mesmo log:
#               seconv    45s -> 115s  (real: 4m22s no Troia, 3h16 de filme)
#               Corretor  25s ->  60s  (real: 2m16s - ele roda o seconv da
#                                       2a opiniao por dentro)
#           A conta do numero: a curva chega a ~90% da faixa em 2,3*EST,
#           entao EST = tempo_tipico / 2,3. Botar EST igual ao tempo tipico
#           deixaria a barra em 62% com o trabalho ja terminado.
#           Era a estimativa de 25s que fazia a barra colar em 94% e ficar la.
#
#   v14.11 (a etapa [5/7] passa a ser HONESTA, e o re-OCR entra no arquivo)
#         * BUG REAL: a barra da [5/7] saltava de 5% para 90% depois de uma
#           pausa. Causa: as rampas do seconv e do Corretor eram
#           (decorrido / 60) * 90 medidas no RELOGIO DE PAREDE, sem descontar
#           o tempo pausado. Pausar 3m38s no meio do OCR fazia o relogio
#           passar dos 60s sozinho - a primeira volta do laco depois de
#           retomar ja calculava 90%, sem um segundo de trabalho no meio.
#           Medido no log de 13/08 21:28:28 (pausa de 03m38s dentro da 5/7).
#           Agora as duas usam Get-PctSuave, que desconta
#           $script:SegundosPausadosEtapa e usa a MESMA curva assintotica que
#           a Invoke-ProcessoComBarraEstimada ja usava desde a 13.x - o
#           defeito era o OCR e o Corretor nao usarem.
#         * BUG REAL: a barra do seconv nunca apareceu no console. O laco
#           desenhava a barra e, na linha seguinte, escrevia "preparando
#           OCR..." POR CIMA dela, a cada 200ms. Mesmo defeito no Corretor.
#           Agora o nome da sub-etapa e dito UMA vez, acima da barra.
#         * A [5/7] deixou de ser uma caixa-preta: ela roda de um a quatro
#           programas em sequencia e cada um enchia a barra de 0 a 100 por
#           conta propria - a barra da mesma etapa enchia, zerava e enchia de
#           novo ("subiu pra 90, depois 100, e comecou outra parte"). Agora
#           cada sub-etapa tem NOME e um PEDACO da barra (FAIXA), calculado
#           antes de comecar; o total fecha em 100 uma vez so, e nunca anda
#           pra tras ($script:FaixaUltimo).
#         * O Reocr_Legenda ENTRA NO MOTOR, como ultima sub-etapa da [5/7].
#           Ele ja resolvia o "INF TOL" no lugar do "Nao!" (8 de 8 casos,
#           duas rodadas byte a byte identicas), mas so existia como
#           ferramenta solta: escrevia _reocr\<nome>_REOCR.srt e parava ali,
#           enquanto o .mkv ja tinha sido remontado na [6/7] com o .srt
#           anterior - e nenhuma etapa remontava de novo. A correcao existia
#           e nunca chegava dentro do arquivo (visto no player, Troia 57:06).
#           Agora o .srt que sai da [5/7] e o que vai pro mkvmerge.
#           Roda nos DOIS caminhos (seconv e PgsToSrt): o alvo dele nao e o
#           motor de OCR, e o TAMANHO da fala.
#           Sem tesseract.exe standalone ele simplesmente nao entra - avisado
#           uma vez na lista de ferramentas, nunca no meio da conversao.
#
#   v14.5 (BUG REAL: o --track-number do seconv estava recebendo o numero
#          errado - por isso o seconv "falhava por algum motivo")
#         * O seconv casa o --track-number contra o TrackNumber do MATROSKA
#           (1-based, gravado no cabecalho do .mkv). O motor passava o "id"
#           do mkvmerge (0-based, posicional). Confirmado no fonte do seconv
#           (ContainerSubtitleLoader.LoadMatroska: "options.TrackNumbers
#           .Contains(track.TrackNumber)") e no fonte do PgsToSrt, que faz
#           "track++" no Runner com o comentario "Matroska parser used here
#           start to count tracks at 1 instead of 0 in other tools (mkvmerge,
#           ffmpeg)". E por isso que o caminho do PgsToSrt sempre funcionou
#           com $track.id e o do seconv nao: o PgsToSrt corrige por dentro, o
#           seconv nao corrige.
#         * Dois estragos possiveis, os dois ja vistos na pratica: se o numero
#           nao casa com faixa nenhuma, o seconv nao gera nada e o motor cai
#           calado pro PgsToSrt (o "falhando por algum motivo" do handoff); se
#           casa com OUTRA faixa, sai legenda de outro idioma passando por
#           PT-BR (mesmo estrago do "Al*ost." no lugar de "Quase.").
#         * Corrigido usando $track.properties.number do proprio mkvmerge -J
#           (valor exato). Somar 1 no id so acertaria com faixas contiguas
#           comecando em 1 - fica so como ultimo recurso.
#         * Rede de seguranca nova: o seconv nomeia a saida de container como
#           "<arquivo>.<idioma>.srt". O motor agora confere esse sufixo contra
#           o idioma da faixa pedida e RECUSA o resultado se nao casar - em
#           vez de aceitar legenda em ingles como se fosse a PT-BR. Recusar e
#           barato: cai pro PgsToSrt logo abaixo, que e a rede de sempre.
#         * Mesmo bug existia no Corretor_Legenda 2.2 (a correcao de faixa da
#           2.2 achava a faixa certa e passava o numero errado mesmo assim) -
#           corrigido la na 2.3, que vai junto nesta entrega.
#   v14.4 (o motivo real de o seconv falhar agora aparece no console)
#         * Antes, quando o seconv nao gerava legenda, o motor so dizia "Nao
#           Gerou Legenda" e caia pro PgsToSrt sem explicar nada - foi o que
#           escondeu o bug do --track-number acima por varias rodadas. Agora
#           imprime as ultimas 6 linhas da saida real do seconv.
#         * Latin.db tambem procurado em %AppData%\Subtitle Edit\Ocr\ quando
#           nao esta em tools\SubtitleEdit\, pra parar de depender so de copia
#           manual. (Mesmo fallback foi pro Corretor_Legenda 2.1.)
#   v14.3 (acabamento do [5/7] achado no primeiro teste real)
#         * Barra de progresso do [5/7] "pulava" entre as 3 sub-fases (seconv,
#           PgsToSrt, Corretor) sem alimentar % real - agora tem rampa suave
#           por tempo decorrido, capada em 90% ate terminar de verdade.
#         * Copia solta do .srt final agora fica em 01_Arquivos_Finalizados do
#           lado do .mkv (antes so existia dentro do mkv).
#   v14.2 (seconv/BinaryOCR de volta como PREFERENCIAL)
#         * O seconv.exe real foi achado: ele NAO vem em download nenhum do
#           Subtitle Edit pro Windows (nem Setup.exe nem .zip portatil). Vem
#           do workflow "Build and release SeConv" (build-seconv.yml) do
#           repositorio oficial, disparado a mao pelo dono - artefato
#           SeConv-Windows-x64.zip. Isso continua valendo (reconferido).
#         * PgsToSrt + Corretor_Legenda ficam como rede de seguranca, e o
#           motor cai pra eles sozinho se o seconv faltar ou falhar.
#         * Repara-AcentoBinaryOcr: o BinaryOCR troca a-til/o-til/e-circunflexo por a-agudo/o-agudo/e-agudo de forma
#           sistematica - so troca de volta se a forma com til existe no
#           dicionario PT-BR e a errada nao existe. Nunca troca as cegas.
#   v14.1 (revertido o caminho seconv da v14.0 - substituido por
#          Corretor_Legenda automatico dentro do motor)
#         * MOTIVO DA REVERSAO: testado em 12/08 com o SubtitleEdit.exe real
#           (v5.1.0 e v5.2.0-beta11) - NENHUM download oficial pro Windows
#           (Setup.exe nem .zip portatil) traz o seconv.exe separado, so o
#           programa com janela. Testado chamar SubtitleEdit.exe direto com
#           os flags do seconv (sintaxe nova E a legada /convert) - as duas
#           SEMPRE abrem a janela completa, nunca rodam headless. Sem CLI
#           real, nao da pra automatizar dentro do motor sem depender de
#           clique manual toda conversao - inviavel pro objetivo do projeto.
#         * NOVA SOLUCAO: PgsToSrt/Tesseract continua sendo quem faz o OCR
#           (como sempre foi), e logo em seguida, ainda dentro do [5/7], o
#           motor chama o Corretor_Legenda.ps1 (ferramenta ja existente e ja
#           validada - 6/7 blocos-lixo reais detectados e corrigidos, 0 falso
#           positivo em 15 falas boas) automaticamente, sem pausa nem clique.
#           Se ele gerar um _CORRIGIDO.srt, o motor usa esse como final; se
#           nao gerar nada (Corretor_Legenda.ps1 ausente, ou nada pra
#           corrigir), segue com o srt original do PgsToSrt sem quebrar nada.
#         * Precisa de Corretor_Legenda.ps1 na mesma pasta do motor (raiz do
#           LaFirma) - ja estava la desde a entrega de ferramentas de 12/08.
#           Se faltar, o motor detecta e so avisa, sem travar.
#         * A etapa v14.0 anterior (seconv/BinaryOCR como preferencial) NAO
#           chegou a ser testada em producao - trocada antes de sair da fase
#           de teste. Pendente ainda (fora do escopo desta versao):
#           Find-PtBrPgsTrack tem falso-negativo conhecido (Troy 2004, Tomb
#           Raider 2001 - a faixa PGS pt-BR existe mas a deteccao automatica
#           nao acha, so selecao manual acha). Se um dia aparecer um
#           seconv.exe de verdade pro Windows, revisitar o caminho do 14.0.
#
#   v13.8 (status da legenda agora reflete o resultado FINAL, nao so o
#          diagnostico do [5/7])
#         * BUG CORRIGIDO: $statusLegenda = "JA_TEXTO" e decidido no [5/7],
#           antes de qualquer escolha manual ser resolvida no [6/7]. Se a
#           legenda PT-BR ja em texto fosse descartada por escolha manual
#           depois disso, o status NUNCA mudava - o card final e o selo da
#           janela continuavam dizendo "REAPROVEITADA", contradizendo a
#           propria tabela de faixas da mesma tela, que corretamente dizia
#           "Nenhuma (Todas Descartadas a Pedido)".
#         * Status novo: DESCARTADA_MANUAL. So entra em uso quando
#           JA_TEXTO tinha sido decidido E a faixa some da lista final de
#           legenda resolvida no [6/7]. Na-tilo muda nada pra quem nunca usa
#           Modo Manual - o automatico nunca gera esse status.
#   v13.7 (LegendaManter vazio agora e respeitado - excluir tudo na mao
#          funciona de verdade)
#         * BUG CORRIGIDO em Resolve-FaixasDoRemux: a escolha manual
#           LegendaManter = @() (excluir TODAS as legendas originais) era
#           tratada como se a chave nao tivesse vindo, porque o teste era
#           "$ids.Count -gt 0". Essa regra faz sentido pra AudioManter (nao
#           existe "arquivo sem som" valido), mas foi copiada pra legenda
#           sem ajuste - e "arquivo sem legenda" E um estado valido. O
#           motor voltava a reaproveitar a PT-BR que ja tinha decidido
#           sozinho, ignorando a escolha do usuario. Contrato agora e por
#           CHAVE PRESENTE de verdade (igual o resto da porta manual, ver
#           v13.3 abaixo): ContainsKey('LegendaManter') decide, nao o
#           tamanho da lista. O '--no-subtitles' pra esse caso ja existia,
#           so nunca era alcancado.
#         * Caso real que achou o bug: TLOU com id 30 (PT-BR) e id 3 (ENG)
#           marcadas EXCLUIR - a escolha chegava certa na janela e no log
#           ('legenda manter []'), mas o diagnostico do motor continuava
#           dizendo que ia reaproveitar a faixa 30 como padrao.
#         * De brinde: o texto do cartao-resumo final tambem mentia nesse
#           caso - "Todas as Legendas Originais Mantidas" mesmo quando o
#           pedido era descartar todas. O teste "-not $texto..." nao
#           distinguia $null (modo seguro, nunca rodou) de "" (rodou e deu
#           vazio de proposito). Agora sao dois casos, com frase propria
#           pra cada um.
#   v13.6 (cancelar na etapa 4/7 nao vira mais "falha de audio": aborta o
#          episodio de verdade, com resumo final e limpeza da saida parcial)
#         * Se a lista escolhida a mao NAO contiver mais a faixa que o motor
#           tinha elegido como padrao - o usuario excluiu justamente ela - a
#           padrao passa a ser a primeira da lista escolhida. Deixar o
#           --default-track apontando para uma faixa que nao existe mais no
#           arquivo final daria um arquivo sem faixa padrao nenhuma.
#         * Caso real que chega la: TLOU, onde o motor elege a E-AC-3 JOC
#           como padrao. Se voce marcar EXCLUIR nela, sem esta salvaguarda o
#           arquivo sairia apontando para uma faixa fantasma.
#         * $null em AudioDefault continua significando 'a faixa NOVA e a
#           padrao' e NAO e tocado por esta regra.
#   v13.5 (log de conversao movido para _logs\ - nenhuma mudanca de logica)
#   v13.4 (uma salvaguarda a mais na porta manual)
#   v13.3 (porta das ESCOLHAS MANUAIS - nada muda no console sozinho)
#         * Ate aqui o motor decidia TUDO sozinho e nao havia por onde
#           informar uma escolha do usuario. A janela (LaFirma_JANELA.ps1) tem
#           um modo Manual com tres verbos por faixa, mas as escolhas nao
#           tinham como chegar aqui - a janela bloqueava o Iniciar por isso.
#         * Agora existe UMA variavel de entrada: $script:EscolhasManuais.
#           Enquanto ela for $null - que e como o console roda - NADA neste
#           script muda: todas as funcoes novas devolvem exatamente o que o
#           motor ja decidia. Nao ha caminho novo no modo automatico.
#         * O contrato e por CHAVE PRESENTE, nao por valor: so e sobreposto
#           o que a escolha mencionar. Chave ausente = decisao do motor.
#           Isso vale ate para AudioDefault, onde $null tem significado
#           proprio ("a faixa NOVA e a padrao") - por isso ContainsKey.
#         * Formato (uma entrada por arquivo, chaveada pelo NOME do arquivo
#           ou pelo caminho completo):
#             $script:EscolhasManuais = @{
#               'Filme.mkv' = @{
#                  AudioPrincipal     = 1        # id da faixa principal
#                  ConverterPrincipal = $true    # $true forca converter,
#                                                # $false desliga a conversao
#                  AudioManter        = @(1,3)   # ids que vao pro remux
#                  AudioDefault       = 1        # id padrao ($null = a nova)
#                  LegendaManter      = @(28,4)  # ids que vao pro remux
#                  LegendaPgs         = 28       # id da PGS que vai pro OCR
#               } }
#         * O que isto DESTRAVA e o que o motor sozinho nao sabia fazer:
#           manter uma segunda faixa de audio que nao seja a reaproveitada
#           (guardar a dublagem junto, por exemplo), manter mais de uma
#           legenda, e converter a principal mesmo existindo faixa pronta.
#   v13.2 (correcao de regra de audio - arquivos DUAL AUDIO)
#         * BUG CORRIGIDO: a checagem "o arquivo ja tem uma faixa compativel,
#           entao nao precisa converter" NAO olhava o IDIOMA da faixa. Num
#           remux Dual Audio (caso real: Troy 2004 Directors Cut DUAL-LACTATO
#           - DTS-HD MA em ingles + AC-3 448k DUBLADO em pt-BR) a DUBLAGEM
#           passava nessa checagem: o DTS ingles NAO era convertido e a
#           dublagem ainda virava a faixa PADRAO do arquivo final. Como o
#           usuario assiste em ingles com legenda, o resultado era o oposto
#           do objetivo do script - e o log dizia "[NAO NECESSARIO]" como se
#           estivesse tudo certo, entao o defeito passava despercebido.
#           Vinha da v4.0, quando a regra do DTS foi escrita.
#         * A regra de idioma JA EXISTIA no projeto desde a v8.6, mas so
#           dentro de Get-FaixaAudioPrincipal ("em Dual Audio a faixa marcada
#           como default costuma ser a dublagem"). Agora ela vale tambem para
#           as DUAS funcoes que procuram faixa pronta:
#           Get-FaixaAtmosJocExistente e Get-FaixaCompativelC2Externa.
#         * CRITERIO (Test-IdiomaConflitante): uma faixa so deixa de valer
#           como candidata quando o idioma dela e CONHECIDO e DIFERENTE do
#           idioma da faixa principal. Faixa SEM idioma marcado ("und" ou
#           vazio) continua valendo - isso e proposital: em muitos remuxes a
#           faixa E-AC-3 Atmos vem sem idioma nenhum (ver o exemplo do
#           MediaInfo em Get-SinaisAtmosMediaInfo), e trata-la como conflito
#           quebraria o reaproveitamento legitimo que funciona hoje.
#         * Efeito pratico no Dual Audio: o DTS/TrueHD original passa a ser
#           convertido normalmente, a faixa NOVA vira a padrao, e a dublagem
#           e descartada no remux pela regra da v5.0 - que ja existia e nao
#           foi tocada.
#   v10.1 "LaFirma" (patch de acabamento sobre a v10.0, mesmo codinome -
#         ajustes de interface confirmados/corrigidos com testes reais)
#         * FIX: o titulo da janela (adicionado na v10.0 para os controles
#           ficarem sempre visiveis) colocava o nome/versao do produto ANTES
#           de "[F1] Pausar...". Em Windows Terminal a ABA so mostra uns
#           28-30 caracteres antes de cortar - o nome/versao sozinho ja
#           preenchia todo o espaco visivel, e o F1/F2/ESC nunca aparecia na
#           pratica (confirmado por screenshot real). Corrigido: o titulo
#           agora contem SO os controles, formato compacto ("F1=Pausar
#           F2=Retomar ESC=Cancelar", 33 caracteres) - nome/versao ja
#           aparecem no cabecalho impresso, nao precisam se repetir aqui.
#         * O bloco de PAUSADO/RETOMADO ficou ainda mais compacto (2 linhas
#           por ciclo) apos confirmar com testes reais (varias pausas
#           seguidas) que a informacao essencial cabe sem a caixa grande.
#         * Cor do cancelamento (resumo, cartao e cabecalho do cartao) mudou
#           de amarelo para VERMELHO, a pedido explicito do usuario.
#         * FIX: a mensagem de "Motivo" do cancelamento tinha um "): -"
#           estranho, porque o nome da etapa (reaproveitado de SayStep) ja
#           vem com ":" no final. Corrigido removendo esse ":" antes de
#           compor a frase. A mensagem tambem passou a informar EM QUAL
#           ETAPA o cancelamento aconteceu, em vez de repetir "cancelado
#           pelo usuario" duas vezes (uma no Status, outra identica no
#           Motivo).
#         * Confirmado por log real (varias pausas seguidas): o tempo
#           pausado continua sem afetar a contagem de progresso (sem salto,
#           sem retrocesso).
#   v10.0 "LaFirma" (VERSAO FINAL ESTAVEL)
#         Fecha o ciclo do projeto: o pipeline chegou onde precisava chegar -
#         remux autentico de Blu-ray entra, sai um arquivo com Dolby Vision
#         Profile 8.1, o melhor audio disponivel e legenda PT-BR pronta, com
#         qualidade de video intacta (validado por contagem de frames e por
#         comparacao byte-a-byte do HDR10+ contra o processo manual).
#         * CORRIGIDO DE VERDADE (audio - Atmos/JOC existente): a tentativa da
#           v9.0 via ffprobe nao funcionava (o ffprobe so preenche "profile"
#           para DTS; TrueHD e E-AC-3 vem sem esse campo, entao a faixa JOC
#           continuava invisivel). Agora a deteccao usa o MediaInfo, que
#           reporta "Dolby Digital Plus with Dolby Atmos" e "JOC" mesmo em
#           faixa SEM NOME - ver Get-SinaisAtmosMediaInfo. Confirmado em teste
#           real com o arquivo Avatar Fire and Ash 2025: o script passou a
#           reconhecer a faixa E-AC-3 JOC ja existente e a NAO reconverter o
#           TrueHD, economizando os ~55 minutos de DeeZy por episodio.
#         * NOVO: controles de teclado durante o processamento -
#           [F1] pausa (suspende de verdade o processo filho via
#           NtSuspendProcess, sem consumir CPU/disco e sem perder progresso),
#           [F2] retoma exatamente de onde parou, e [ESC] cancela a operacao
#           (encerra o processo atual, apaga a saida parcial e os temporarios
#           e interrompe o lote - mesmo efeito de fechar a janela, porem
#           organizado). O tempo pausado nao "infla" a barra de progresso.
#         * NOVO: banner centralizado, acompanhando a largura da janela - fica
#           bem apresentado com o console maximizado. Os controles de teclado
#           aparecem logo abaixo, discretos, em cinza escuro.
#         * O resumo final passou a distinguir "Cancelados pelo Usuario" de
#           falhas de verdade (amarelo, nao vermelho) e informa quantos
#           arquivos do lote nem chegaram a ser processados.
#   v9.1  (ajustes - melhoria de audio para codec nao tratado + diagnostico
#         de espaco em disco + revisao geral)
#         * AUDIO (codec nao tratado - PCM/LPCM/FLAC como faixa principal):
#           antes caia direto em MODO SEGURO (mantinha tudo, sem eleger uma
#           faixa padrao). Agora, se o arquivo ja tiver uma faixa
#           E-AC-3/AC-3/AAC compativel com a TV em outra posicao, ela e
#           promovida como padrao e a faixa principal lossless e mantida
#           junto (nao descarta nada) - espelha o comportamento do caminho
#           DTS. So cai em modo seguro puro se NAO houver faixa compativel.
#           Motivo: LPCM costuma dar problema de reproducao em varios
#           setups Plex/TV; ter uma E-AC-3 como padrao evita isso. Os
#           caminhos TrueHD e DTS ficaram INTACTOS (byte-a-byte).
#         * DIAGNOSTICO: nova linha "Espaco Livre Apos a Conversao
#           (estimado)" na checagem inicial de espaco em disco (os arquivos
#           de origem nao sao apagados, entao mostra quanto sobra no disco
#           com origem + convertidos coexistindo).
#         * Format-Tamanho agora trata valores negativos corretamente
#           (escolhe GB/MB/KB pelo valor absoluto, preserva o sinal).
#   v9.0  (mudanca grande - varios bugs reais confirmados em testes + adocao
#         de deteccao por conteudo/bitstream no lugar de nome de faixa)
#         * DIRETRIZ: onde for tecnicamente possivel, a deteccao agora olha
#           o CONTEUDO REAL do arquivo (bitstream/metadado via ffprobe/
#           mkvmerge) em vez do nome da faixa. Nome so e usado como fallback
#           ou onde nao existe sinal de conteudo equivalente (comentario,
#           SDH, variante regional de idioma).
#         * TENTATIVA (audio - Atmos/JOC existente): uma faixa E-AC-3 JOC /
#           TrueHD Atmos SEM NOME nao era reconhecida como "ja tem Atmos", e
#           o TrueHD era reconvertido a toa (confirmado no arquivo Avatar
#           Fire and Ash 2025: 55m38s desperdicados). A v9.0 tentou resolver
#           lendo o campo "profile" do ffprobe - mas ISSO NAO FUNCIONOU: o
#           ffprobe so preenche "profile" para DTS, e deixa TrueHD e E-AC-3
#           sem esse campo, entao a faixa JOC continuava invisivel. Resolvido
#           de fato na v10.0, via MediaInfo (ver adiante).
#         * CORRIGIDO BUG REAL (video - arquivo nao-HEVC): antes falhava com
#           erro generico "Codigo 1" na extracao (o bsf hevc_mp4toannexb e
#           especifico de HEVC). Agora o [1/7] checa o codec_name e pula o
#           episodio com mensagem clara (confirmado no Vampira 1974/AVC).
#         * CORRIGIDO BUG REAL (video - arquivo sem Dolby Vision): antes o
#           dovi_tool rodava sem erro em arquivo sem RPU e o script reportava
#           "[OK] RPU Convertido" - SUCESSO FALSO, gastando tempo com audio/
#           legenda a toa (confirmado no Avatar SDR: 1h02m perdida). Agora o
#           [1/7] faz deteccao PROPRIA e confiavel de DV (Get-InfoDolbyVision,
#           nao o diagnostico previo que e informativo e pode falhar em
#           silencio) e pula cedo com mensagem clara quando nao ha DV.
#         * CORRIGIDO BUG REAL (legenda - variante pt-PT sem nome): uma
#           legenda de texto SEM NOME com language_ietf "pt-PT" (Portugal)
#           era escolhida como se fosse a brasileira e a PGS Brazilian real
#           era descartada - o arquivo final saia com a legenda ERRADA
#           (confirmado no The People vs Larry Flynt 1996). Find-PtBrPgsTrack
#           e Get-FaixaLegendaPtBrTexto agora excluem tambem por language_ietf
#           "pt-PT" (metadado real), nao so pelo nome da faixa.
#         * CORRIGIDO (legenda - SDH): entre faixas PT-BR explicitas, a que
#           NAO for SDH agora tem prioridade (via Test-EhLegendaSDH, que usa
#           o metadado flag_hearing_impaired alem do nome) - antes dependia
#           da ordem no arquivo, mesma classe do bug de comentario da v8.6.
#         * DESEMPENHO: Get-InfoDolbyVision agora tem cache por arquivo
#           (mesmo padrao de Get-MkvJson), eliminando leituras ffprobe
#           duplicadas por episodio.
#         * ACABAMENTO: diagnostico previo padronizado (tag
#           [CONVERSAO NAO NECESSARIA] sempre no inicio e em amarelo);
#           removida frase redundante na legenda ja em texto; corrigidos
#           acentos residuais em comentarios; cabecalho de versao alinhado.
#   v8.6  (mudanca grande - dois bugs reais: filtro de legenda + prioridade
#         de audio)
#         * CORRIGIDO BUG REAL (legenda): validado com arquivo real (Tomb
#           Raider 2001), que tem 3 variantes de PGS em portugues -
#           "Brazilian", "Iberian" e "Brazilian (Commentary)". O script
#           escolheu a faixa certa, mas por SORTE de ordem no arquivo -
#           nenhuma das funcoes de deteccao de legenda (Find-PtBrPgsTrack,
#           Get-FaixaLegendaPtBrTexto) excluia faixas de comentario (so o
#           audio fazia isso). Se a faixa de comentario aparecesse ANTES da
#           principal, o script pegaria a errada para OCR/reaproveitamento.
#           Os TRES seletores de legenda (Find-PtBrPgsTrack,
#           Get-FaixaLegendaPtBrTexto e Get-FaixaLegendaIngles) agora
#           reaproveitam Test-EhFaixaComentario (generica, olha so o nome da
#           faixa) para excluir comentario logo na origem - o mesmo filtro
#           que o audio ja usava. Cobre casos como "English (Commentary)"
#           alem de "Brazilian (Commentary)".
#         * CORRIGIDO BUG REAL (audio): em Get-FaixaAudioPrincipal, a flag
#           "default" do remux vinha ANTES da faixa em ingles - em remuxes
#           Dual Audio SEM TrueHD (ex: dual DTS ou dual AC-3/AAC puro), a
#           flag "default" costuma marcar a dublagem escolhida pelo grupo
#           de release, nao o audio original em ingles. O fix da v6.0 so
#           cobria esse problema quando havia TrueHD no arquivo (o item 1
#           "salvava" a escolha antes de chegar no default). Nova ordem:
#           TrueHD (qualquer idioma) -> Ingles -> Default -> primeira faixa
#           nao-comentario. Correcao preventiva - mesma classe de bug ja
#           confirmada (Schindler's List) e mesmo raciocinio de codigo.
#   v8.5  (mudanca grande - bug real na selecao de legenda PT-BR)
#         * CORRIGIDO BUG REAL: Get-FaixaLegendaPtBrTexto e Find-PtBrPgsTrack
#           tinham um fallback generico ingenuo - "se so existe UMA legenda
#           em portugues generico (texto ou PGS), assume que e a
#           brasileira". Isso e ERRADO quando essa unica faixa e uma
#           variante explicitamente NAO-brasileira (ex: "Portuguese
#           (Iberian)" = Portugal). Confirmado com um arquivo real onde a
#           unica legenda em texto era Iberian e a verdadeira PT-BR estava
#           em PGS - o codigo pegava a Iberian por engano, ignorando a PGS
#           brasileira correta. Agora ambas as funcoes excluem
#           explicitamente faixas com "iberian", "portugal" ou "pt-pt" no
#           nome do fallback generico - nesses casos a funcao retorna nulo
#           e o processamento cai corretamente para a proxima opcao
#           (texto -> PGS -> nada), em vez de aceitar a faixa errada.
#   v8.4  (mudanca grande - bug real no diagnostico de legenda + acabamento)
#         * BANNER: reformulado para "Conversor de PERFIL Dolby Vision
#           [5 ou 7] -> [8.1] + Conversor LEGENDA PGS -> SRT" e "Conversor
#           de AUDIO [Dolby TrueHD/DTS:HD/DTS:X -> E-AC-3 Atmos/JOC]".
#         * DIAGNOSTICO PREVIO: as duas mensagens "[CONVERSAO NAO
#           NECESSARIA]" (audio ja tem Atmos/JOC; nenhuma legenda PT-BR em
#           PGS) mudaram de cinza para amarelo, com o colchete movido para
#           o INICIO da mensagem (igual ao padrao ja usado nas etapas
#           ao vivo [4/7]/[5/7]).
#         * CORRIGIDO BUG REAL: o diagnostico previo de legenda so
#           verificava PGS (Find-PtBrPgsTrack) - nunca checava se a PT-BR
#           ja existia pronta em TEXTO (Get-FaixaLegendaPtBrTexto, criada
#           na v7.0). Resultado: para arquivos com PT-BR ja em .srt (sem
#           PGS), a previa dizia erroneamente "nenhuma legenda
#           identificada", quando na verdade o [5/7] real ia reaproveitar
#           a .srt normalmente. Agora a previa segue a MESMA ordem de
#           prioridade real (texto primeiro, depois PGS, depois nada).
#         * Cartao final: coluna de rotulo aumentada de 34 para 40
#           caracteres - os rotulos que foram crescendo ao longo das
#           ultimas versoes (ex: "Descarte de Audios e Legendas [EXTRAS]",
#           38 chars) ja ultrapassavam os 34 originais, desalinhando a
#           coluna de valor. Corrigido na fonte (largura fixa da funcao
#           Write-CampoResumo), nao mais remendado rotulo por rotulo.
#   v8.2  (ajuste - texto de mensagens e rotulos do cartao)
#         * [5/7]: mensagem de PT-BR ja em texto reformulada para
#           "[NAO NECESSARIO] Legenda 'PT-BR .SRT' na Faixa X 'Nome'".
#         * Cartao final: rotulo de audio JA_OTIMO reformulado para
#           "Audio (E-AC-3 Atmos/JOC - PRESENTE)" / "Audio (E-AC-3/AC-3 -
#           PRESENTE)". Rotulo de legenda reaproveitada ganhou a tag
#           "[.SRT]": "Legenda PT-BR [.SRT] (Reaproveitada)".
#         * Cartao final: linha de descarte consolidada de volta em uma
#           unica linha - "Descarte de Audios e Legendas [EXTRAS]"
#           "[REMOVIDO]" - removendo a linha extra "(Audio e Legendas)".
#   v8.1  (ajuste - reorganizacao do cartao final / mini-mediainfo)
#         * A informacao de quais faixas de audio/legenda sobreviveram
#           saiu de baixo da linha "Descarte" e virou parte do bloco de
#           metricas tecnicas do arquivo final (Container/Duracao/Tempo) -
#           agora funciona como um mini-mediainfo, sempre visivel (mesmo
#           quando nao houve descarte, mostrando "Todas as Faixas/Legendas
#           Originais Mantidas (Sem Descarte)").
#         * Valores do cartao (Dolby Vision/Audio/Legenda) simplificados
#           para tags curtas e consistentes: "[CONVERTIDO]" quando algo foi
#           de fato convertido, "[NAO NECESSARIO]" quando ja estava bom ou
#           nao havia o que fazer - o motivo especifico continua no
#           ROTULO (ex: "Audio (Atmos/JOC Ja Presente)"), so a frase longa
#           repetitiva foi trocada pela tag. Falhas continuam detalhadas.
#         * Linha de "Descarte de Faixas Extras" quebrada em duas: rotulo
#           curto na linha principal, escopo "(Audio e Legendas)" numa
#           linha propria abaixo.
#   v8.0  (mudanca grande - status de audio + reformulacao do cartao final)
#         * Nova sinalizacao "PROCESSO INICIALIZADO" entre o diagnostico
#           previo e o inicio real das etapas [1/7]-[7/7].
#         * [4/7]: mensagem de "Ja Possui Faixa E-AC-3 Atmos/JOC" agora
#           mostra o CODEC REAL da faixa existente (ex: "E-AC-3 JOC").
#         * [5/7]: cor da mensagem de PT-BR ja em texto corrigida de cinza
#           para amarelo (igual ao [4/7]), e texto reformatado para
#           "[NAO NECESSARIO] ..." sem sufixo redundante.
#         * Removida redundancia de "[NAO NECESSARIO] ... Nenhuma Conversao
#           Necessaria." (dizia a mesma coisa duas vezes) em 3 mensagens de
#           audio - agora so o prefixo "[NAO NECESSARIO]" ja basta.
#         * NOVO STATUS DE AUDIO "JA_OTIMO": separa "ja esta numa
#           configuracao boa, nada a fazer" (Atmos/JOC ja existia, E-AC-3/
#           AC-3 ja existia, ou a propria principal ja e compativel) do
#           "NAO_NECESSARIO" genuino (DeeZy indisponivel, codec nao
#           tratado, faixa principal nao identificada) - o primeiro caso
#           agora usa icone [OK] verde no cartao, o segundo continua [--]
#           cinza. Mesma logica ja usada para "Dolby Vision Nao Necessario"
#           (que continua cinza, pois ali "nao precisou" e o proprio estado
#           bom, sem uma segunda categoria a distinguir).
#         * Cartao final: rotulo do audio agora e dinamico e reflete o
#           motivo real (ex: "Audio (Atmos/JOC Ja Presente)"), em vez de
#           sempre dizer "Audio -> E-AC-3" mesmo quando nada foi convertido.
#         * Cartao final: rotulo do descarte perdeu o "PGS" (agora so
#           "Legendas"), ja que o descarte de legenda tambem se aplica a
#           faixas que nunca foram PGS (ex: PT-BR ja em texto).
#         * Cartao final: quando ha descarte de faixas extras, mostra
#           agora quais faixas de audio/legenda sobreviveram (mesma
#           informacao que ja aparecia ao vivo no [6/7]), alinhada
#           corretamente sob a coluna de valor mesmo com rotulos longos.
#   v7.2  (ajuste pontual - rotulos da mensagem de legenda no [6/7])
#         * Mensagem do [6/7] agora diferencia os dois caminhos possiveis:
#           "Legenda Reaproveitada: ..." quando a PT-BR ja existia pronta em
#           texto (tag "[SRT]"), e "Legenda PGS Convertida: ..." quando foi
#           gerada via OCR a partir de uma faixa PGS (tag "[OCR/SRT]").
#         * A faixa PT-BR na mensagem agora usa o NOME REAL da faixa de
#           origem (ex: "Portuguese (Brazilian)"), em vez de um texto fixo
#           "Portugues (Brasil)". A faixa PT-BR sempre aparece primeiro na
#           mensagem, antes do ingles, nos dois caminhos.
#   v7.1  (ajuste pontual - consistencia estrutural audio/legenda)
#         * Refatorada a logica de decisao da legenda para seguir EXATAMENTE
#           o mesmo padrao do audio: uma fase de DECISAO (so descobre/gera o
#           que for possivel) separada de uma fase de RESOLUCAO unica no
#           final ($resultadoLegendaBoa, espelhando $resultadoAudioBom) que
#           decide o descarte. Antes, a legenda decidia isso dentro de cada
#           ramo separadamente - o resultado final era o mesmo, mas a
#           estrutura nao era simetrica. Nenhuma mudanca de comportamento
#           visivel - so organizacao interna, testada contra os 3 casos
#           reais ja validados (Bloodsport, The Last of Us, modo seguro).
#   v7.0  (mudanca grande - bug real na deteccao de legenda PT-BR)
#         * CORRIGIDO BUG REAL: a deteccao de legenda PT-BR so procurava em
#           faixas PGS (imagem) - se o arquivo ja tivesse uma legenda PT-BR
#           pronta em formato de TEXTO (SRT/ASS), ela era completamente
#           ignorada, e nenhum descarte de legenda acontecia (mantinha
#           TODAS as legendas originais, mesmo ja tendo uma PT-BR usavel).
#           Nova funcao Get-FaixaLegendaPtBrTexto detecta esse caso e passa
#           a ter PRIORIDADE sobre o caminho de OCR: se ja existe PT-BR em
#           texto, usa ela direto (mais confiavel que OCR, sem risco de
#           erro de reconhecimento) e aplica a mesma regra de descarte -
#           mantem so ela + a legenda inglesa completa.
#         * [6/7] agora mostra mensagens detalhadas (nao mais um "[OK]"
#           generico): "Audio Mantido: <faixas reais> - Demais Faixas de
#           Audio Descartadas [OK]" e o mesmo para legenda, usando o nome
#           real de cada faixa mantida. As linhas so aparecem quando o
#           descarte de fato aconteceu (modo seguro fica em silencio).
#         * Novo status de legenda "JA_TEXTO" (PT-BR reaproveitada sem
#           OCR), com rotulos simplificados no resumo: "Legenda PT-BR
#           (OCR)" quando veio de conversao, "Legenda PT-BR
#           (Reaproveitada)" quando ja existia pronta em texto.
#   v6.0  (mudanca grande - prioridade de faixa principal + acabamento)
#         * CORRIGIDO BUG REAL: em remuxes "Dual Audio" (ex: faixa em
#           portugues marcada como "default" pelo grupo de release), a
#           escolha da faixa principal priorizava a flag "default" do
#           arquivo ANTES de procurar TrueHD - isso podia fazer o script
#           escolher uma faixa DTS/AC-3 em outro idioma como principal e
#           NUNCA considerar o TrueHD/Atmos, descartando-o sem necessidade.
#           Agora Get-FaixaAudioPrincipal procura TrueHD/MLP em QUALQUER
#           idioma PRIMEIRO (ignorando a flag default) - so cai para
#           default/ingles/primeira faixa quando nao ha TrueHD no arquivo.
#         * Corrigido log duplicado no [7/7]: "Show-Barra 100" seguido de
#           "Show-BarraCompleta" imprimia a barra de 100% duas vezes no
#           arquivo de log (o Start-Transcript nao processa "\r" como um
#           terminal real, entao grava as duas chamadas como linhas
#           separadas). Agora so uma chamada, igual as outras 5 barras.
#         * [6/7] agora mostra linhas separadas e claras: "Descartando
#           Faixas de AUDIO Extras Desnecessarias... [OK]" e "Descartando
#           Faixas de LEGENDA Extras Desnecessarias... [OK]" (cada uma so
#           quando aplicavel), seguidas de "Montando o Arquivo MKV Final
#           (mkvmerge)..." antes da barra de progresso real do mkvmerge.
#         * Banner inicial reorganizado em 3 linhas equilibradas (nenhuma
#           ultrapassa mais a borda "====") - a largura da borda agora e
#           calculada dinamicamente a partir do texto, entao versoes
#           futuras maiores (v10.0, v100.0...) nunca mais estouram.
#   v5.0  (mudanca grande - descarte de faixas desnecessarias no remux)
#         * AUDIO: o arquivo final agora mantem SO a faixa principal (+ a
#           faixa extra reaproveitada quando aplicavel, ex: Atmos/JOC ou
#           E-AC-3/AC-3 ja existente). Comentario de diretor, dublagens e
#           quaisquer outras faixas de audio extras sao DESCARTADAS. A
#           faixa que melhor atende (E-AC-3 nova, ou a extra reaproveitada,
#           ou a principal ja compativel) vira a PADRAO do player.
#           MODO SEGURO: se o resultado nao for bom (TrueHD sem DeeZy, DTS
#           cuja conversao falhou, codec nao tratado como PCM/FLAC, ou
#           faixa principal nao identificada), NENHUM audio e descartado -
#           mantem todas as faixas originais.
#         * LEGENDA: quando o SRT pt-BR novo e gerado com sucesso (a partir
#           da faixa PGS pt-BR PRINCIPAL, nao-forcada), o arquivo final
#           mantem so esse SRT (como PADRAO) + a legenda INGLESA COMPLETA
#           (nao-forcada, nao-SDH). Descarta: a PGS pt-BR original (virou
#           SRT, redundante), forcadas, SDH, outros idiomas e legendas sem
#           idioma definido (und). Se o OCR falhar ou nao houver PGS pt-BR,
#           NENHUMA legenda e descartada (modo seguro).
#         * Find-PtBrPgsTrack agora EXCLUI faixas forcadas (uma legenda
#           forcada nunca vira a "principal" usada para o SRT padrao).
#         * Resumo e console mostram uma linha de "Descarte de Faixas
#           Extras" apenas quando algum descarte de fato aconteceu.
#   v4.0  (mudanca grande de comportamento - regra de audio refeita)
#         * FAIXA PRINCIPAL: agora escolhida de forma inteligente -
#           prioriza a faixa marcada como "default" pelo remux; se nenhuma,
#           a primeira faixa em ingles; se nenhuma, a primeira faixa de
#           audio que NAO seja comentario (de diretor/elenco/produtores,
#           detectado pelo nome da faixa). So depois disso cai para "a
#           primeira faixa de audio do arquivo" como ultimo recurso.
#         * TRUEHD: agora SEMPRE converte para E-AC-3 Atmos (JOC), mesmo
#           que ja exista uma faixa E-AC-3/AC-3 comum no arquivo - o
#           objetivo e preservar o MELHOR audio disponivel (Atmos), nao so
#           "ter algum audio que funcione". Unica excecao: se o arquivo JA
#           tiver uma faixa E-AC-3 Atmos/JOC separada, a conversao e
#           pulada (redundante).
#         * DTS/DTS-HD/DTS:X: so converte se NAO existir, em outra faixa
#           nao-comentario do arquivo, uma faixa E-AC-3/AC-3/AAC ja pronta
#           e compativel com TVs modernas (ex: LG C2). Antes disso, o
#           script comparava so pela faixa principal isolada; agora
#           verifica o arquivo inteiro (exceto faixas de comentario).
#         * Corrigido possivel uso de indice de faixa errado no DeeZy/
#           ffmpeg: como a faixa principal pode nao ser mais a "faixa 0",
#           os comandos agora usam o indice real da faixa escolhida
#           (Get-IndiceAudioNaFaixa), nao mais um indice fixo em "0".
#   v3.1  (ajuste pontual - desempenho/travamento da maquina)
#         * Corrigido: a etapa [3/7] fazia uma segunda leitura redundante do
#           arquivo de origem so para checar se podia pular o dovi_tool -
#           agora reaproveita o diagnostico ja feito no inicio do episodio.
#         * PRIORIDADE DE I/O EM DISCO: ate a v3.0, so a prioridade de CPU
#           dos processos filhos (ffmpeg/dovi_tool/mkvmerge/deezy) era
#           reduzida ('BelowNormal'). Isso NAO reduz a prioridade das
#           operacoes de disco - um processo com I/O pesado e continuo
#           (ex: dovi_tool processando um raw de ~50GB) podia disputar a
#           fila do disco em pe de igualdade com o resto do sistema e
#           travar o mouse/outros programas, mesmo com CPU liberada. Agora
#           a prioridade de I/O tambem e reduzida (NtSetInformationProcess /
#           ProcessIoPriority = Low), a mesma tecnica usada por utilitarios
#           como Process Hacker - isso deve manter o PC responsivo mesmo
#           durante a conversao de arquivos muito grandes.
#   v3.0  (ATUAL - mudanca grande de comportamento)
#         * AUDIO: a decisao de converter agora olha o CODEC DA FAIXA
#           PRINCIPAL (faixa 01), e nao mais "existe qualquer E-AC-3 no
#           arquivo". Assim, uma faixa AC-3 de comentarios do diretor nao
#           interfere mais na decisao sobre o audio do filme. Regra:
#             - TrueHD -> converte para E-AC-3 Atmos (DeeZy)
#             - DTS/DTS-HD/DTS:X -> converte para E-AC-3 comum (ffmpeg)
#             - E-AC-3 / AC-3 / AAC (ja roda em TVs como a LG C2) ->
#               [CONVERSAO NAO NECESSARIA]
#             - outros codecs -> mantidos como estao
#         * VIDEO: se o Dolby Vision de origem JA for Profile 8.x sem
#           Enhancement Layer, o dovi_tool e PULADO ([NAO NECESSARIO]) e o
#           video extraido e reaproveitado direto - sem reprocessar a toa.
#           Profiles 5 e 7 (ou 8 com EL) continuam sendo convertidos normal.
#         * Resumo e diagnostico previo atualizados para refletir os novos
#           estados "Nao Necessario" de video e audio.
#   v2.0  Resumo final em "cartoes" por episodio com detalhamento por
#         processo (Dolby Vision / audio / legenda), filtragem de
#         mensagens de erro (remove linhas de progresso, encurta caminhos)
#         e correcao do bug de achatamento de array que cortava valores
#         curtos do resumo para 1 caractere so.
#         (Este era o estado que ja rodava "praticamente tudo".)
#   v1.9  Quoting de argumentos corrigido conforme as regras reais do
#         Windows (CommandLineToArgvW) - corrige caminhos terminados em
#         "\" e argumentos com aspas internas.
#   v1.8  Verificacao de espaco em disco antes de converter (lote inteiro
#         e por episodio individual, ~3.15x o tamanho de origem).
#   v1.7  OCR de legenda PGS pt-BR -> SRT (PgsToSrt + tessdata), com
#         checagem do .NET Desktop Runtime 8.0 e aviso com link de download.
#   v1.6  Pasta de trabalho exclusiva e curta para o DeeZy/DEE, corrigindo
#         falha "Cannot open file ...atmos.json" por estouro do MAX_PATH.
#   v1.5  Suporte a familia DTS (DTS/DTS-HD/DTS:X) -> E-AC-3 comum
#         (640 kbps) via ffmpeg, para arquivos sem faixa TrueHD/Atmos.
#   v1.4  Audio TrueHD/MLP -> E-AC-3 Atmos via DeeZy (1152 kbps, minimo
#         real aceito pelo DEE) + correcao do bug de ExitCode -1 falso no
#         teste de disponibilidade do deezy.exe.
#   v1.3  Barras de progresso reais: barra estimada (ffprobe/dovi_tool),
#         barra real via -progress do ffmpeg, barra por fases do DeeZy.
#   v1.2  Pasta temporaria de cada episodio sempre criada no MESMO disco do
#         arquivo de origem (evita copia entre discos, mantem velocidade).
#   v1.1  Job Object (kernel32) garantindo que ffmpeg/dovi_tool/mkvmerge
#         morrem junto com o script, mesmo se a janela for fechada na marra.
#   v1.0  Nucleo funcional: deteccao de .mkv em 00_Arquivos_Base, extracao
#         de video via ffmpeg, conversao Dolby Vision para Profile 8.1 via
#         dovi_tool, remux final via mkvmerge, log via Start-Transcript.
# ============================================================================
$SCRIPT_VERSION  = "14.36"
$SCRIPT_CODINOME = "LaFirma"
#
#  PASTA TEMPORARIA: SEMPRE NO MESMO DISCO DO ARQUIVO DE ORIGEM
#  ----------------------------------------------------------------------
#  Durante a conversao, o programa precisa gravar uma copia temporaria do
#  video. Para manter a mesma velocidade que voce tem fazendo o processo
#  manualmente (aproveitando SSDs rapidos, por exemplo), essa pasta
#  temporaria e criada automaticamente NO MESMO DISCO onde esta o arquivo
#  .mkv de origem - nunca em outro disco. Isso evita copiar dados entre
#  discos diferentes (o que seria mais lento se um deles for um HD) e
#  mantem o processo local ao disco mais rapido disponivel para aquele
#  arquivo especifico, exatamente como o processo manual do DDVT faz.
#  Nao ha nada para configurar aqui - e automatico por episodio.
# ============================================================================
#
#  BITRATE DA FAIXA E-AC-3 ATMOS (audio)
#  ----------------------------------------------------------------------
#  Bitrate usado ao converter a faixa TrueHD/MLP Atmos original para E-AC-3
#  Atmos (via DeeZy + DEE). 1152 kbps e o valor MINIMO valido que o DEE aceita
#  para o modo "--atmos-mode bluray" com esta configuracao de canais - usar
#  768 (outro valor comum na comunidade) faz o DEE rejeitar e reajustar
#  sozinho para 1152 de qualquer forma, entao ja comecamos com o valor certo
#  para o resumo final bater com o que realmente foi codificado. Pode ajustar
#  aqui se preferir um valor mais alto (ex: 1536, 1664).
$ATMOS_BITRATE = 1152

#  BITRATE DA FAIXA E-AC-3 COMUM (audio de origem DTS)
#  ----------------------------------------------------------------------
#  Bitrate usado ao converter faixas da familia DTS (DTS, DTS-HD Master
#  Audio, DTS:X) para E-AC-3 comum, via ffmpeg. A familia DTS nao carrega
#  metadado de audio Dolby Atmos, entao a faixa gerada e um E-AC-3 5.1
#  padrao - 640 kbps e o teto de qualidade classico para E-AC-3 5.1 sem
#  Atmos (mesmo padrao dos discos e streaming de alta qualidade).
$DTS_EAC3_BITRATE = 640
# ============================================================================

$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.Encoding]::UTF8

# ---- Job Object: garante que ffmpeg/dovi_tool/mkvmerge/etc morrem junto -----
# com este script, mesmo se a janela for fechada na marra, sem depender de
# nenhum "finally" do PowerShell rodar (o Windows mata os filhos sozinho).
Add-Type -Language CSharp -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class DdvtJob {
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr CreateJobObject(IntPtr a, string lpName);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetInformationJobObject(IntPtr hJob, int JobObjectInfoClass, IntPtr lpJobObjectInfo, uint cbJobObjectInfoLength);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool AssignProcessToJobObject(IntPtr hJob, IntPtr hProcess);

    [StructLayout(LayoutKind.Sequential)]
    public struct JOBOBJECT_BASIC_LIMIT_INFORMATION {
        public Int64 PerProcessUserTimeLimit;
        public Int64 PerJobUserTimeLimit;
        public UInt32 LimitFlags;
        public UIntPtr MinimumWorkingSetSize;
        public UIntPtr MaximumWorkingSetSize;
        public UInt32 ActiveProcessLimit;
        public UIntPtr Affinity;
        public UInt32 PriorityClass;
        public UInt32 SchedulingClass;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct IO_COUNTERS {
        public UInt64 ReadOperationCount, WriteOperationCount, OtherOperationCount;
        public UInt64 ReadTransferCount, WriteTransferCount, OtherTransferCount;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION {
        public JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
        public IO_COUNTERS IoInfo;
        public UIntPtr ProcessMemoryLimit;
        public UIntPtr JobMemoryLimit;
        public UIntPtr PeakProcessMemoryUsed;
        public UIntPtr PeakJobMemoryUsed;
    }

    const int JobObjectExtendedLimitInformation = 9;
    const UInt32 JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x2000;

    public static IntPtr Handle;

    public static void Iniciar() {
        Handle = CreateJobObject(IntPtr.Zero, null);
        var info = new JOBOBJECT_EXTENDED_LIMIT_INFORMATION();
        info.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
        int length = Marshal.SizeOf(typeof(JOBOBJECT_EXTENDED_LIMIT_INFORMATION));
        IntPtr ptr = Marshal.AllocHGlobal(length);
        Marshal.StructureToPtr(info, ptr, false);
        SetInformationJobObject(Handle, JobObjectExtendedLimitInformation, ptr, (uint)length);
        Marshal.FreeHGlobal(ptr);
    }

    public static void Adotar(IntPtr hProcess) {
        if (Handle != IntPtr.Zero) { AssignProcessToJobObject(Handle, hProcess); }
    }

    // ---- Prioridade de I/O em disco (alem da prioridade de CPU) -----------
    // $proc.PriorityClass = 'BelowNormal' (definido em PowerShell) so reduz a
    // prioridade de CPU do processo - NAO reduz a prioridade das operacoes de
    // disco. Um processo fazendo I/O pesado e continuo (ex: dovi_tool lendo/
    // escrevendo dezenas de GB) pode disputar a fila do disco em pe de
    // igualdade com o resto do sistema mesmo com CPU "BelowNormal", travando
    // o mouse e outros programas. NtSetInformationProcess com a classe
    // ProcessIoPriority (33) resolve isso, baixando tambem a prioridade de
    // I/O do processo filho - a mesma tecnica usada por utilitarios como
    // Process Hacker / Process Lasso para "IO Priority: Low". E uma API nao
    // documentada oficialmente pela Microsoft, mas estavel desde o Windows
    // Vista e amplamente usada por ferramentas de sistema conhecidas.
    [DllImport("ntdll.dll")]
    private static extern int NtSetInformationProcess(IntPtr hProcess, int processInformationClass, ref int processInformation, int processInformationLength);

    private const int ProcessIoPriority = 33;
    private const int IO_PRIORITY_LOW = 1; // 0=VeryLow 1=Low 2=Normal 3=High 4=Critical

    public static void PriorizarIoBaixo(IntPtr hProcess) {
        int prioridade = IO_PRIORITY_LOW;
        NtSetInformationProcess(hProcess, ProcessIoPriority, ref prioridade, 4);
    }

    // ---- Pausar / retomar o processo filho ([F1] / [F2]) ------------------
    // NtSuspendProcess congela TODAS as threads do processo - e exatamente o
    // que o "Suspend" do Process Explorer / Process Hacker faz. Enquanto
    // suspenso o processo nao consome CPU nem disco, e o Resume o devolve
    // exatamente de onde parou, sem perder progresso: as threads congelam
    // entre instrucoes e os handles de arquivo continuam abertos e validos,
    // entao nenhuma escrita fica pela metade. E preferivel a matar/reiniciar
    // (perderia horas de trabalho) e a so parar o loop do PowerShell (que nao
    // pausaria nada - o ffmpeg/dovi_tool continuaria rodando por baixo).
    // Tambem e API nao documentada, porem estavel desde o Windows XP.
    [DllImport("ntdll.dll")]
    private static extern int NtSuspendProcess(IntPtr hProcess);

    [DllImport("ntdll.dll")]
    private static extern int NtResumeProcess(IntPtr hProcess);

    public static void Pausar(IntPtr hProcess)  { NtSuspendProcess(hProcess); }
    public static void Retomar(IntPtr hProcess) { NtResumeProcess(hProcess); }
}
"@
[DdvtJob]::Iniciar()
function Adotar-Processo($Proc) {
    try { [DdvtJob]::Adotar($Proc.Handle) } catch { }
}

function Reduzir-PrioridadeProcesso($Proc) {
    # Reduz TANTO a prioridade de CPU quanto a de I/O em disco do processo
    # filho (ffmpeg/dovi_tool/mkvmerge/deezy), para que arquivos grandes nao
    # deixem o resto do PC lento/travado enquanto convertem em segundo plano.
    # Cada chamada e protegida por try/catch: se falhar em algum ambiente
    # Windows especifico, o processo continua rodando normalmente (a
    # prioridade e so uma otimizacao, nunca bloqueia o processamento).
    try { $Proc.PriorityClass = 'BelowNormal' } catch { }
    try { [DdvtJob]::PriorizarIoBaixo($Proc.Handle) } catch { }
}

# ---- Motor de aparencia: cores ANSI de 24 bits, simbolos e molduras --------
# POR QUE ANSI EM VEZ DE -ForegroundColor:
#   1) -ForegroundColor so alcanca as 16 cores fixas do console. Para pintar
#      cores DIFERENTES NA MESMA LINHA era preciso encadear varios
#      "Write-Host -NoNewline" - e o Start-Transcript grava CADA chamada como
#      uma linha propria, entao uma linha bonita na tela virava 4 ou 5 linhas
#      picadas dentro do log .txt. Era essa a limitacao antiga.
#   2) Com ANSI a linha inteira, com todas as cores, vai numa UNICA string e
#      num UNICO Write-Host: a tela ganha cor real de 24 bits e o log volta a
#      ter 1 linha para cada 1 linha impressa.
#   3) Os codigos ANSI ficam gravados crus no .txt. Por isso, logo depois do
#      Stop-Transcript, o script le o log e apaga todos eles (ver o bloco
#      "limpeza do log" no final). O log final sai mais limpo do que era antes.
# COMPATIBILIDADE: se o console nao suportar VT (conhost antigo, saida
# redirecionada para arquivo, tarefa agendada sem console), $script:AnsiOn
# fica $false e TODA a impressao cai de volta no visual antigo, com as 16
# cores do -ForegroundColor. Nada quebra, nenhuma etapa muda.

# Interruptor manual: definir a variavel de ambiente DDVT_SEM_CORES (com
# qualquer valor) forca o modo antigo, util para depurar ou para consoles
# exoticos.
$script:AnsiOn = $false
try {
    if ($Host.UI.SupportsVirtualTerminal -and -not $env:DDVT_SEM_CORES) { $script:AnsiOn = $true }
} catch { $script:AnsiOn = $false }
# Rede de seguranca: em algumas combinacoes de host/versao a propriedade acima
# volta vazia mesmo num terminal que suporta cor. O Windows Terminal sempre
# publica a variavel WT_SESSION, e o PowerShell 7+ tem VT ligado por padrao -
# qualquer um dos dois ja e prova suficiente de suporte.
if (-not $script:AnsiOn -and -not $env:DDVT_SEM_CORES) {
    try {
        if ($env:WT_SESSION -or $PSVersionTable.PSVersion.Major -ge 7) { $script:AnsiOn = $true }
    } catch { }
}

# UTF-8 na saida: o .bat ja faz "chcp 65001", isto aqui e o cinto de seguranca
# para quando o .ps1 e chamado direto, sem passar pelo .bat.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$script:ESC       = [string][char]27
$script:AnsiReset = "$($script:ESC)[0m"

function New-Cor([int]$R, [int]$G, [int]$B) { return "$($script:ESC)[38;2;$R;$G;${B}m" }

# PALETA SEMANTICA - a regra e: cor significa ESTADO, nunca e enfeite.
#   txt   texto normal do corpo         foco  o que esta acontecendo AGORA
#   ok    concluido com sucesso         okdim variacao suave do sucesso
#   src   dado do arquivo de ORIGEM     dst   dado do arquivo FINAL
#   warn  atencao, mas nao e erro       err   erro ou cancelamento
#   dim   texto secundario              dim2  molduras, tempos, inertes
#   vazio trilho nao preenchido da barra de progresso
$script:Paleta = @{
    "txt"   = (New-Cor 201 199 191)
    "foco"  = (New-Cor 241 239 232)
    # VERDE FORTE, o mesmo tom do "-ForegroundColor Green" das versoes ate a
    # v10 (o verde brilhante do console, 22/198/12). O verde-menta 93/202/165
    # usado nas v11.x era mais suave e o usuario achou fraco demais para
    # confirmacao. Este e o "verdao" - vale para visto, barra e tudo que
    # significa sucesso.
    "ok"    = (New-Cor  22 198  12)
    "okdim" = (New-Cor 110 220  90)
    "src"   = (New-Cor 133 183 235)
    "dst"   = (New-Cor 159 225 203)
    "warn"  = (New-Cor 250 199 117)
    "err"   = (New-Cor 226  75  74)
    "dim"   = (New-Cor 136 135 128)
    "dim2"  = (New-Cor  95  94  90)
    "vazio" = (New-Cor  58  58  55)
    # Cor da MARCA (LaFirma). Fica de fora da semantica de status de proposito:
    # violeta nao significa sucesso, atencao nem erro em lugar nenhum do
    # programa, entao pode identificar o produto sem roubar significado das
    # outras cores. E a mesma familia usada nas molduras de secao.
    "marca"    = (New-Cor 214 150 255)
    "marcadim" = (New-Cor 168 140 200)
}

# Ponte com o codigo antigo: dezenas de chamadas ja existentes passam nomes de
# ConsoleColor ("DarkGray", "Green", ...). Em vez de reescrever cada uma delas
# - e arriscar mexer em texto que ja esta validado - o nome antigo e traduzido
# aqui para a chave nova da paleta. Assim toda chamada antiga continua valendo
# e ja sai com a cor nova.
$script:MapaCorLegada = @{
    "Gray" = "txt"; "White" = "foco"; "DarkGray" = "dim2"
    "Cyan" = "foco"; "DarkCyan" = "dim2"
    "Green" = "ok"; "DarkGreen" = "okdim"
    "Yellow" = "warn"; "DarkYellow" = "warn"
    "Red" = "err"; "DarkRed" = "err"
    "Magenta" = "marca"; "DarkMagenta" = "marcadim"
    "Blue" = "src"; "DarkBlue" = "src"
}

function Cor([string]$Chave) {
    if ($script:AnsiOn -and $script:Paleta.ContainsKey($Chave)) { return $script:Paleta[$Chave] }
    return ""
}
function CorDe([string]$NomeLegado) {
    if (-not $script:AnsiOn) { return "" }
    $n = [string]$NomeLegado
    if ($script:MapaCorLegada.ContainsKey($n)) { return $script:Paleta[$script:MapaCorLegada[$n]] }
    return $script:Paleta["txt"]
}
function Rst() { if ($script:AnsiOn) { return $script:AnsiReset } return "" }

# SIMBOLOS E MOLDURAS
# Montados por CODIGO de caracter ([char]0x...) de proposito: assim o .ps1
# continua sendo um arquivo ASCII PURO. Se os simbolos fossem escritos
# literalmente, o arquivo deixaria de ser ASCII e passaria a depender de BOM /
# de o PowerShell adivinhar a codificacao certa para desenhar sem virar lixo.
# Definir DDVT_SEM_SIMBOLOS volta para os marcadores antigos [OK]/[AVISO]/[ERRO]
# mantendo as cores novas.
$script:UsarSimbolos = ($script:AnsiOn -and -not $env:DDVT_SEM_SIMBOLOS)
if ($script:AnsiOn) {
    $script:BoxTL     = [string][char]0x256D   # canto arredondado superior esq
    $script:BoxTR     = [string][char]0x256E
    $script:BoxBL     = [string][char]0x2570
    $script:BoxBR     = [string][char]0x256F
    $script:BoxH      = [string][char]0x2500   # traco horizontal
    $script:BoxV      = [string][char]0x2502   # traco vertical
    $script:LinhaFina = [string][char]0x2504   # traco tracejado
    $script:Bloco     = [string][char]0x2588   # bloco cheio (barra)
    $script:Ponto     = [string][char]0x00B7   # separador discreto
} else {
    $script:BoxTL = "+"; $script:BoxTR = "+"; $script:BoxBL = "+"; $script:BoxBR = "+"
    $script:BoxH  = "="; $script:BoxV  = "|"; $script:LinhaFina = "-"
    $script:Bloco = "#"; $script:Ponto = "-"
}
if ($script:UsarSimbolos) {
    # POR QUE O VISTO SAIA ROXO NA v11.0:
    # o caractere U+2714 esta na lista de EMOJI do Unicode. Quando a fonte do
    # terminal nao tem o desenho dele, o Windows cai na Segoe UI Emoji - uma
    # fonte COLORIDA, que traz a cor embutida no proprio glifo e simplesmente
    # ignora a cor ANSI que mandamos. Por isso o visto aparecia roxo mesmo com
    # o texto ao lado saindo verde. Duas correcoes juntas resolvem:
    #   1) trocar U+2714 por U+2713, que NAO e emoji em nenhuma versao do
    #      Unicode, entao nunca cai numa fonte colorida;
    #   2) acrescentar U+FE0E (VARIATION SELECTOR-15) em todos os simbolos.
    #      Esse caractere e invisivel e significa "desenhe como TEXTO, nao como
    #      emoji" - com ele, mesmo os simbolos que tem versao emoji (o
    #      triangulo U+25B6, por exemplo) sao obrigados a respeitar a cor ANSI.
    # REGRA DA FAMILIA (v11.4): os simbolos nao podem parecer recortados de
    # lugares diferentes. Sao todos de PESO CHEIO e saem de apenas dois blocos
    # do Unicode, cada um internamente identico:
    #
    #   Formas Geometricas (U+25xx) - os estados do FLUXO, todos solidos,
    #   mesma espessura, mesma altura optica:
    #       U+25BA ponteiro solido      ->  etapa em execucao
    #       U+25CF circulo cheio        ->  nao necessario
    #       U+25B2 triangulo para cima  ->  aviso
    #       U+25A0 quadrado cheio       ->  cancelado
    #
    #   Dingbats pesados (U+27xx) - os dois VEREDITOS. O visto e o xis grosso
    #   sao um PAR desenhado junto no Unicode, com a mesma espessura de traco:
    #       U+2714 visto grosso         ->  feito
    #       U+2718 xis grosso           ->  falhou
    #
    # O que saiu na v11.3: o U+2296 (circulo com menos) vinha do bloco de
    # Operadores Matematicos - traco FINO e vazado, do lado de um visto grosso.
    # Era ele o estranho no meio. Trocado pelo U+25CF, que e da mesma familia
    # do triangulo, do quadrado e do triangulo de aviso.
    #
    # SOBRE O DESENHO MONOCROMATICO - LICAO APRENDIDA NA MARRA (v11.5):
    # o problema da fonte colorida so existe em ponto de codigo que TEM versao
    # emoji. Na v11.3 a lista tinha DOIS assim: o triangulo U+25B6 e o visto
    # U+2714, e os dois levavam o seletor U+FE0E. Em teste real numa maquina
    # Windows 11 + Windows Terminal o resultado foi MISTO: o visto saiu verde
    # (o seletor funcionou) e o triangulo saiu roxo (o seletor NAO impediu a
    # fonte colorida). Ou seja: o U+FE0E AJUDA, mas NAO GARANTE - depende de
    # existir um desenho monocromatico do caractere na cadeia de fontes do
    # terminal, e isso varia caractere a caractere.
    # CONCLUSAO QUE VIROU REGRA: nao confiar no seletor. Preferir sempre ponto
    # de codigo que NAO TENHA versao emoji nenhuma - ai nao ha o que dar
    # errado. Por isso o triangulo virou U+25BA (mesmo desenho solido apontando
    # para a direita, mesmo bloco, mas sem versao emoji). O unico que segue
    # sendo emoji e o visto U+2714, mantido porque foi CONFIRMADO saindo verde
    # nessa maquina e porque e o desenho que o usuario prefere - e para ele
    # existe a valvula DDVT_VISTO_FINO logo abaixo.
    #
    # O visto voltou a ser o U+2714 (o desenho "cheio", que era o da v11.0 e
    # que o usuario preferiu) - mas agora ACOMPANHADO do U+FE0E, e essa e toda
    # a diferenca: sem o seletor ele caia na fonte colorida de emoji e saia
    # roxo; com ele, o Windows e obrigado a procurar um desenho MONOCROMATICO
    # (Segoe UI Symbol), que respeita a cor ANSI. Mesmo desenho de antes, na
    # cor certa.
    # Os outros dois foram escolhidos de proposito em pontos de codigo que NAO
    # tem versao emoji nenhuma - assim nao dependem so do seletor para se
    # comportar:
    #   U+2296 circulo com menos  ->  "nao havia o que fazer aqui"
    #   U+2718 xis grosso         ->  falhou
    #   U+25A0 quadrado cheio     ->  parado/cancelado (o simbolo universal
    #                                 de STOP, diferente do xis de FALHA
    #                                 porque cancelar nao e a mesma coisa
    #                                 que quebrar)
    $vs = [string][char]0xFE0E
    # Valvula de escape: DDVT_VISTO_FINO troca o visto grosso (U+2714, unico
    # simbolo da lista que ainda nao foi visto rodando com o seletor) pelo
    # U+2713, que nao tem versao emoji e portanto nunca pode sair colorido.
    # Serve para resolver na hora, sem esperar nova versao do script, caso o
    # visto grosso volte a aparecer roxo em algum PC.
    # -------------------------------------------------------------------
    # TRES CONJUNTOS COMPLETOS, escolhidos pela variavel DDVT_ESTILO.
    # A ideia e nao ter mais simbolo solto de bloco diferente: cada conjunto
    # e fechado, todos os seis papeis saem da MESMA familia de desenho.
    #
    #   DDVT_ESTILO=solido  (padrao) - dingbats e formas cheias, TRACO GROSSO
    #       visto grosso, xis grosso, circulo cheio, triangulo cheio, quadrado
    #       Desenho monocromatico: a cor vem do ANSI, entao cada simbolo sai
    #       na cor do seu estado (verde, ambar, vermelho).
    #
    #   DDVT_ESTILO=formas - SO formas geometricas do bloco U+25xx
    #       Nao existe "visto" nesse bloco, entao sucesso vira circulo cheio.
    #       E o conjunto mais uniforme de todos (um bloco so) e o mais seguro
    #       em qualquer fonte. Tambem monocromatico.
    #
    #   DDVT_ESTILO=emoji - emojis coloridos
    #       ATENCAO, e uma troca de verdade: emoji tem a cor DENTRO do desenho
    #       e ignora o ANSI. Nao da para pintar um emoji. Funciona aqui porque
    #       as cores nativas ja batem com os estados (visto verde, xis
    #       vermelho, triangulo ambar), mas a partir dai a cor do simbolo deixa
    #       de ser controlada pelo programa. Alem disso emoji ocupa DUAS
    #       colunas na tela, por isso o recuo e ajustado abaixo.
    # -------------------------------------------------------------------
    # PADRAO = emoji (escolha do usuario apos comparar os quatro conjuntos na
    # tela). Nao precisa mais definir variavel nenhuma para o visual normal;
    # DDVT_ESTILO so serve para VOLTAR aos conjuntos monocromaticos.
    $script:EstiloSimbolos = ([string]$env:DDVT_ESTILO).ToLower()
    if ([string]::IsNullOrWhiteSpace($script:EstiloSimbolos)) { $script:EstiloSimbolos = "emoji" }
    if ($env:DDVT_VISTO_FINO) { $script:EstiloSimbolos = "fino" }
    switch ($script:EstiloSimbolos) {
        "emoji" {
            $vs16 = [string][char]0xFE0F   # pede a versao COLORIDA
            $script:SimOk    = [string][char]0x2705             # visto em caixa verde
            # FALHA = BOLINHA VERMELHA (U+1F534), ideia do usuario e que
            # fecha bem: junto com a bolinha amarela do "nao necessario" forma
            # uma leitura de semaforo - amarelo e atencao, vermelho e problema.
            # As duas bolinhas tem exatamente o mesmo desenho, mudando so a
            # cor, entao a diferenca entre os dois estados fica obvia.
            $script:SimErr   = [string][char]0xD83D + [string][char]0xDD34
            $script:SimSkip  = [string][char]0xD83D + [string][char]0xDFE1  # circulo amarelo
            $script:SimWarn  = [string][char]0x26A0 + $vs16     # triangulo de perigo
            # PLACA DE PARE (U+1F6D1), e nao o quadrado U+23F9: o quadrado
            # saiu AZUL na tela, o que brigava com a regra de cancelado =
            # vermelho. A placa octogonal ja e vermelha por natureza e e o
            # sinal universal de "parou aqui".
            $script:SimStop  = [string][char]0xD83D + [string][char]0xDED1
            $script:SimAtual = [string][char]0x25B6 + $vs16     # triangulo de play
            $script:LarguraSimbolo = 2
            # O triangulo de execucao sai com UMA coluna nesta fonte, enquanto
            # os demais emojis saem com DUAS. Sem este espaco a mais, o titulo
            # da etapa ficava desalinhado em relacao as linhas de resultado
            # logo abaixo dele (conferido em screenshot real).
            $script:AjusteSimboloAtual = " "
            $script:IconePasta = [string][char]0xD83D + [string][char]0xDCC1  # pasta
            $script:IconeDisco = [string][char]0xD83D + [string][char]0xDCBE  # disco
            break
        }
        "formas" {
            $script:SimOk    = [string][char]0x25CF + $vs   # circulo cheio
            $script:SimErr   = [string][char]0x25C6 + $vs   # losango cheio
            $script:SimSkip  = [string][char]0x25CB + $vs   # circulo vazio
            $script:SimWarn  = [string][char]0x25B2 + $vs   # triangulo para cima
            $script:SimStop  = [string][char]0x25A0 + $vs   # quadrado cheio
            $script:SimAtual = [string][char]0x25B6 + $vs   # triangulo apontando
            $script:LarguraSimbolo = 1
            break
        }
        "fino" {
            $script:SimOk    = [string][char]0x2713 + $vs
            $script:SimErr   = [string][char]0x2717 + $vs
            $script:SimSkip  = [string][char]0x25CB + $vs
            $script:SimWarn  = [string][char]0x25B2 + $vs
            $script:SimStop  = [string][char]0x25A1 + $vs
            $script:SimAtual = [string][char]0x203A + $vs
            $script:LarguraSimbolo = 1
            break
        }
        default {
            $script:SimOk    = [string][char]0x2714 + $vs   # visto grosso
            $script:SimErr   = [string][char]0x2718 + $vs   # xis grosso
            $script:SimSkip  = [string][char]0x25CF + $vs   # circulo cheio
            $script:SimWarn  = [string][char]0x25B2 + $vs   # triangulo para cima
            $script:SimStop  = [string][char]0x25A0 + $vs   # quadrado cheio
            $script:SimAtual = [string][char]0x25B6 + $vs   # triangulo apontando
            $script:LarguraSimbolo = 1
        }
    }
} else {
    $script:SimOk = "[OK]"; $script:SimAtual = ">"; $script:SimWarn = "[AVISO]"
    $script:SimErr = "[ERRO]"; $script:SimSkip = "[--]"; $script:SimStop = "[STOP]"
    $script:LarguraSimbolo = 1
}
# Recuo depois do simbolo: emoji ocupa DUAS colunas, os demais uma. Manter o
# total constante e o que garante que uma tela com [OK], aviso e erro fique
# com todos os textos comecando na mesma coluna.
$script:PosSimbolo = " " * [Math]::Max(1, 3 - $script:LarguraSimbolo)
if (-not $script:AjusteSimboloAtual) { $script:AjusteSimboloAtual = "" }
# Icone de pasta e de disco: so os estilos com emoji tem desenho proprio. Nos
# demais o espaco e reservado em branco, para as linhas continuarem alinhadas
# na mesma coluna em qualquer estilo.
if (-not $script:IconePasta) { $script:IconePasta = " " }
if (-not $script:IconeDisco) { $script:IconeDisco = " " }

# Marcacao de texto para linhas MULTICOLORIDAS, no formato "{ok}texto{/}".
# Usada apenas em textos FIXOS escritos aqui dentro - nunca em nome de arquivo
# ou mensagem de erro vinda de fora, que poderiam conter chaves por acidente e
# baguncar a marcacao. Para conteudo dinamico usa-se (Cor "x") + valor + (Rst).
$script:PadraoTag  = '\{(/|[a-z0-9]+)\}'
$script:PadraoAnsi = "$([char]27)\[[0-9;]*m"

function Fmt([string]$Texto) {
    if ([string]::IsNullOrEmpty($Texto)) { return "" }
    if (-not $script:AnsiOn) { return [regex]::Replace($Texto, $script:PadraoTag, "") }
    $avaliador = {
        param($m)
        $chave = $m.Groups[1].Value
        if ($chave -eq "/") { return $script:AnsiReset }
        if ($script:Paleta.ContainsKey($chave)) { return $script:Paleta[$chave] }
        return ""
    }
    return ([regex]::Replace($Texto, $script:PadraoTag, $avaliador) + $script:AnsiReset)
}

function Fmt-Largura([string]$Texto) {
    # Largura VISIVEL do texto: desconta as marcas e os codigos ANSI, que
    # ocupam bytes na string mas nenhuma coluna na tela. Sem isso qualquer
    # centralizacao ou alinhamento sai torto quando a linha tem cor.
    if ([string]::IsNullOrEmpty($Texto)) { return 0 }
    $semTag  = [regex]::Replace($Texto, $script:PadraoTag, "")
    $semAnsi = [regex]::Replace($semTag, $script:PadraoAnsi, "")
    return $semAnsi.Length
}

function Say-Fmt([string]$Texto) { Write-Host (Fmt $Texto) }

# Linha de DETECCAO do diagnostico (o que o arquivo TEM). E a linha-mae de
# cada par pergunta/resposta, entao recebe a enfase: NEGRITO (ESC[1m - o
# console nao muda tamanho de letra, negrito e o maximo de peso disponivel)
# por cima do azul de "dado da origem". A resposta logo abaixo faz o caminho
# inverso e fica mais apagada - juntos, os dois criam a hierarquia que o
# usuario pediu: primeiro o que foi analisado, depois, menor, o veredito.
function Say-Deteccao($Texto) {
    if ($script:AnsiOn) { Write-Host ($script:ESC + "[1m" + (Cor "src") + $Texto + $script:AnsiReset) }
    else                { Write-Host $Texto -ForegroundColor Blue }
}

# TRES ESTADOS, TRES SIMBOLOS, TRES CORES - e sempre os mesmos, em qualquer
# parte da tela. E o vocabulario visual do programa inteiro:
#   ok    visto      verde     foi feito
#   skip  circulo    ambar     nao precisava ser feito (nao e erro)
#   err   xis        vermelho  falhou
# Quando a frase comeca com uma tag entre colchetes (ex: "[CONVERSAO NAO
# NECESSARIA] ..."), SO a tag recebe a cor do estado e o resto da frase fica em
# texto normal. A resposta salta aos olhos sem que a linha inteira grite.
function SayResposta($Estado, $Texto) {
    $t = [string]$Texto
    if (-not $script:AnsiOn) {
        $corLegada = switch ($Estado) { "ok" { "Green" } "err" { "Red" } default { "Yellow" } }
        Write-Host ("        " + $t) -ForegroundColor $corLegada
        return
    }
    $sim = switch ($Estado) { "ok" { $script:SimOk } "err" { $script:SimErr } default { $script:SimSkip } }
    $cor = switch ($Estado) { "ok" { "ok" }         "err" { "err" }         default { "warn" } }
    $m = [regex]::Match($t, '^(\[[^\]]+\])\s*(.*)$')
    if ($m.Success) {
        # O texto depois da tag sai em "dim": a resposta e o degrau de baixo
        # da hierarquia (deteccao em negrito > tag colorida > complemento).
        Write-Host ("     " + (Cor $cor) + $sim + $script:PosSimbolo + $m.Groups[1].Value + " " + (Cor "dim") + $m.Groups[2].Value + $script:AnsiReset)
    } else {
        Write-Host ("     " + (Cor $cor) + $sim + $script:PosSimbolo + $t + $script:AnsiReset)
    }
}

# Titulo de secao: sempre na cor da marca, para o olho achar rapido onde cada
# bloco comeca quando o log esta longo.
function SayTitulo($Texto) {
    if ($script:AnsiOn) { Write-Host ((Cor "marca") + $Texto + $script:AnsiReset) }
    else                { Write-Host $Texto -ForegroundColor Magenta }
}

# Contador do resumo: um "0" nunca recebe cor de status. Antes o
# "Nao Finalizados (Erro) : 0" saia em vermelho mesmo sem nenhum erro, o que
# fazia a linha parecer um problema quando na verdade era a melhor noticia.
function Say-Contador($Rotulo, $Valor, $CorQuandoMaiorQueZero) {
    $cor = if ([int]$Valor -gt 0) { $CorQuandoMaiorQueZero } else { "DarkGray" }
    Say ("  {0}: {1}" -f ([string]$Rotulo).PadRight(31), $Valor) $cor
}

# ---- saida auxiliar ---------------------------------------------------------
# Todos os textos impressos continuam IDENTICOS aos da v10.1. O que muda e so
# a camada de cor e o marcador a esquerda: em console com VT o [OK]/[AVISO]/
# [ERRO] vira simbolo, no modo compativel os colchetes voltam exatamente como
# eram. Cada funcao mantem o mesmo nome e a mesma assinatura de antes, entao
# nenhuma das ~200 chamadas espalhadas pelo script precisou ser tocada.
function Say($Text, $Color = "Gray") {
    if ($script:AnsiOn) { Write-Host ((CorDe $Color) + $Text + $script:AnsiReset) }
    else                { Write-Host $Text -ForegroundColor $Color }
}
function SayStep($Text) {
    $script:EtapaAtualNome = $Text
    Write-Host ""
    if ($script:AnsiOn) { Write-Host ("  " + (Cor "ok")   + $script:SimAtual + $script:PosSimbolo + $script:AjusteSimboloAtual + (Cor "foco") + $Text + $script:AnsiReset) }
    else                { Write-Host "  > $Text" -ForegroundColor Cyan }
}
function SayOk($Text) {
    # Simbolo E texto no MESMO verde. Antes o visto saia verde e a frase em
    # cinza claro, o que dava a impressao de dois estados na mesma linha.
    # Confirmacao e uma coisa so: verde inteiro.
    if ($script:AnsiOn) { Write-Host ("  " + (Cor "ok")   + $script:SimOk   + $script:PosSimbolo + $Text + $script:AnsiReset) }
    else                { Write-Host "  [OK] $Text" -ForegroundColor Green }
}
function SayWarn($Text) {
    if ($script:AnsiOn) { Write-Host ("  " + (Cor "warn") + $script:SimWarn + $script:PosSimbolo + (Cor "warn") + $Text + $script:AnsiReset) }
    else                { Write-Host "  [AVISO] $Text" -ForegroundColor Yellow }
}
# Cancelamento nao e falha: tem cor vermelha (pedido do usuario) mas simbolo
# proprio, o quadrado de "parado". Assim da para distinguir num relance um lote
# interrompido de proposito de um episodio que quebrou.
function SayStop($Text) {
    if ($script:AnsiOn) { Write-Host ("  " + (Cor "err") + $script:SimStop + $script:PosSimbolo + (Cor "err") + $Text + $script:AnsiReset) }
    else                { Write-Host "  [CANCELADO] $Text" -ForegroundColor Red }
}
function SayErr($Text) {
    if ($script:AnsiOn) { Write-Host ("  " + (Cor "err")  + $script:SimErr  + $script:PosSimbolo + (Cor "err")  + $Text + $script:AnsiReset) }
    else                { Write-Host "  [ERRO] $Text" -ForegroundColor Red }
}
function Line($Char = "=", $Color = "DarkCyan", $Width = 78) {
    if ($script:AnsiOn) {
        # O separador fino ("-") vira tracejado e o forte ("=") vira traco
        # continuo: a hierarquia visual passa a ser dada pelo PESO do traco,
        # nao por dois caracteres ASCII diferentes.
        $c = if ($Char -eq "-") { $script:LinhaFina } else { $script:BoxH }
        Write-Host ((Cor "dim2") + ($c * $Width) + $script:AnsiReset)
    } else {
        Write-Host ($Char.ToString() * $Width) -ForegroundColor $Color
    }
}
function Say-Centralizado($Texto, $Color = "Gray", $Largura = 0) {
    if ($Largura -le 0) { $Largura = if ($script:BannerLargura) { $script:BannerLargura } else { 78 } }
    $t = ([string]$Texto).Trim()
    $recuo = [Math]::Max(0, [int](($Largura - (Fmt-Largura $t)) / 2))
    if ($script:AnsiOn) { Write-Host ((" " * $recuo) + (CorDe $Color) + $t + $script:AnsiReset) }
    else                { Write-Host ((" " * $recuo) + $t) -ForegroundColor $Color }
}

$BARLEN = 40
function New-BarraTexto($Pct) {
    $p = [math]::Max(0, [math]::Min(100, $Pct))
    $filled = [math]::Floor($BARLEN * $p / 100)
    return ("#" * $filled).PadRight($BARLEN, '-')
}
function Show-Barra($Pct) {
    # Floor e nao [int]: [int] arredonda, entao 99,6% virava 100% na tela com
    # o processo ainda rodando. Mesma armadilha do Format-Duracao.
    $p = [int][math]::Floor([math]::Max(0, [math]::Min(100, $Pct)))
    if ($script:AnsiOn) {
        # DE PROPOSITO usa [Console]::Write e nao Write-Host: o Start-Transcript
        # NAO captura escrita feita direto no console. Como esta funcao e
        # chamada a cada ~200ms, era ela a responsavel pelas centenas de linhas
        # "0%", "1%", "1%"... que sujavam o log. Agora o progresso vai so para
        # a tela e o log recebe apenas a linha final de 100% de cada etapa.
        $cheio = [math]::Floor($BARLEN * $p / 100)
        $s = "`r        " + (Cor "ok") + ($script:Bloco * $cheio) +
             (Cor "vazio") + ($script:Bloco * ($BARLEN - $cheio)) +
             (Cor "foco") + ("{0,4}%" -f $p) + $script:AnsiReset
        [Console]::Write($s)
    } else {
        Write-Host -NoNewline ("`r        [{0}] {1,3}%" -f (New-BarraTexto $p), $p) -ForegroundColor Cyan
    }
}
function Show-BarraCompleta() {
    # Quando o usuario cancelou, a etapa NAO chegou ao fim - desenhar uma barra
    # verde de 100% ali seria mentira, e era o que acontecia: no screenshot de
    # um cancelamento aos 71%, logo abaixo do aviso vermelho aparecia uma barra
    # cheia como se tivesse terminado. Nesse caso a barra parcial e so apagada
    # da tela e nada e escrito no lugar.
    if ($script:CancelamentoSolicitado) {
        if ($script:AnsiOn) { [Console]::Write("`r" + (" " * ($BARLEN + 20)) + "`r") }
        return
    }
    if ($script:AnsiOn) {
        # Limpa o rastro da barra parcial na tela e so entao imprime a linha
        # definitiva - esta sim via Write-Host, para ficar registrada no log.
        [Console]::Write("`r" + (" " * ($BARLEN + 20)) + "`r")
        Write-Host ("        " + (Cor "ok") + ($script:Bloco * $BARLEN) + (Cor "foco") + " 100%" + $script:AnsiReset)
    } else {
        Write-Host ("`r        [{0}] 100%{1}" -f ("#" * $BARLEN), (" " * 15)) -ForegroundColor Cyan
    }
}

<#  v14.11: FAIXA DA BARRA (sub-etapas dentro de uma etapa [n/7])
    -------------------------------------------------------------------------
    POR QUE ISTO EXISTE. A etapa [5/7] nao e uma coisa so: ela pode rodar ate
    QUATRO programas em sequencia (seconv -> PgsToSrt -> Corretor_Legenda ->
    Reocr_Legenda). Ate a 14.10 cada um deles desenhava a barra de 0 a 100 por
    conta propria, entao a barra da MESMA etapa enchia, zerava e enchia de
    novo - foi isso que o usuario viu como "subiu pra 90, depois 100, e
    comecou outra parte do processo".
    A FAIXA resolve: cada sub-etapa recebe um PEDACO da barra (ex.: o seconv
    fica entre 0% e 50%) e o progresso interno dela e mapeado pra dentro desse
    pedaco. A barra da etapa passa a andar sempre pra frente, de 0 a 100, uma
    vez so.
    $script:FaixaUltimo trava o retrocesso: se por qualquer motivo um calculo
    devolver numero menor que o ja mostrado, a barra fica onde estava. Barra
    que anda pra tras e pior que barra parada.
#>
$script:FaixaIni    = 0.0
$script:FaixaFim    = 100.0
$script:FaixaUltimo = -1.0

function Set-FaixaBarra($Ini, $Fim) {
    $script:FaixaIni    = [double]$Ini
    $script:FaixaFim    = [double]$Fim
    $script:FaixaUltimo = -1.0
}
function Reset-FaixaBarra() { Set-FaixaBarra 0 100 }

function Show-BarraFaixa($Pct) {
    $p = [math]::Max(0.0, [math]::Min(100.0, [double]$Pct))
    $real = $script:FaixaIni + ($script:FaixaFim - $script:FaixaIni) * ($p / 100.0)
    # v14.12: TETO DURO. Enquanto a sub-etapa esta rodando, a barra NUNCA
    # encosta no fim da faixa. Na 14.11 o Reocr do Troia mostrou 100% as
    # 15h16 e so terminou as 15h19 - quase 4 minutos de "100%" com o
    # tesseract ainda trabalhando. Barra cheia com processo vivo e a mesma
    # mentira que a rampa velha contava, so que no outro extremo.
    # Quem escreve o numero final e Show-BarraFaixaFim, e so quando acabou.
    $teto = $script:FaixaFim - 1.0
    if ($teto -lt $script:FaixaIni) { $teto = $script:FaixaIni }
    if ($real -gt $teto) { $real = $teto }
    if ($real -lt $script:FaixaUltimo) { $real = $script:FaixaUltimo }
    $script:FaixaUltimo = $real
    Show-Barra $real
}
function Show-BarraFaixaFim() {
    # So desenha a linha definitiva de 100% quando a faixa REALMENTE fecha a
    # etapa. Se ainda vem sub-etapa depois, a barra apenas para no fim da
    # faixa - escrever 100% ali seria a mentira que a 14.10 contava.
    if ($script:FaixaFim -ge 100) { Show-BarraCompleta; return }
    if ($script:CancelamentoSolicitado) { return }
    $script:FaixaUltimo = $script:FaixaFim
    Show-Barra $script:FaixaFim
}

<#  v14.11: SaySub - anuncia a sub-etapa pelo NOME.
    Duas escritas, de proposito:
      1. uma linha normal (Write-Host), que fica na tela ACIMA da barra e
         entra no log - assim o log sozinho conta quem rodou e quando;
      2. uma repintura (Write-Host -NoNewline), que e o unico formato que a
         JANELA transforma em NOTA na linha da etapa (ver "16.10" no fonte
         dela). Sem esta segunda escrita a janela mostraria a barra andando
         sem dizer o que esta rodando.
#>
function SaySub($Texto, $Ini, $Fim) {
    Set-FaixaBarra $Ini $Fim
    if ($script:AnsiOn) { Write-Host ("      " + (Cor "dim2") + $script:LinhaFina + " " + (Cor "dim") + $Texto + $script:AnsiReset) }
    else                { Write-Host ("      - " + $Texto) -ForegroundColor DarkGray }
    Write-Host -NoNewline ("`r        " + $Texto)
}

<#  v14.11: Get-PctSuave - a curva unica de todo progresso ESTIMADO do motor.
    Recebe o instante inicial, quanto ja estava pausado quando a sub-etapa
    comecou, e quanto tempo ela costuma levar. Devolve uma porcentagem que:
      * DESCONTA o tempo pausado ($script:SegundosPausadosEtapa). Era esta a
        causa do salto denunciado pelo usuario: a rampa antiga era
        (decorrido / 60) * 90 medida no RELOGIO DE PAREDE. Pausar 3m38s no
        meio do OCR fazia o relogio passar dos 60s sozinho, entao a primeira
        volta do laco DEPOIS de retomar ja calculava 90%. A barra saltava de
        5% pra 90% sem UM SEGUNDO de trabalho no meio.
      * e assintotica: sobe rapido no comeco e vai chegando perto de 99 sem
        nunca bater um teto e travar (a rampa antiga capava em 90 e ficava
        parada la, dando impressao de processo morto).
    E a mesma curva que a Invoke-ProcessoComBarraEstimada ja usava desde a
    13.x - o defeito era o OCR e o Corretor NAO usarem.
#>
function Get-PctSuave($Inicio, $PausadoNoComeco, $EstimativaSegundos) {
    $est = [double]$EstimativaSegundos
    if ($est -le 0) { $est = 30 }
    $pausado = [double]$script:SegundosPausadosEtapa - [double]$PausadoNoComeco
    if ($pausado -lt 0) { $pausado = 0 }
    $trabalho = ((Get-Date) - $Inicio).TotalSeconds - $pausado
    if ($trabalho -lt 0) { $trabalho = 0 }
    return (99 * (1 - [math]::Exp(-$trabalho / $est)))
}

# ---- Controles de teclado: [F1] pausar / [F2] retomar / [ESC] cancelar ------
# Sao checados dentro dos loops que ja acompanham o progresso dos processos
# pesados (ffmpeg, dovi_tool, DeeZy, mkvmerge, OCR), entao respondem em ate
# ~0,2s sem custo nenhum: [Console]::KeyAvailable so olha o buffer do teclado,
# nao bloqueia nem espera.
$script:CancelamentoSolicitado = $false
$script:SegundosPausadosEtapa  = 0.0

# KeyAvailable lanca excecao quando a entrada do console esta redirecionada
# (ex: script chamado dentro de um pipe, ou por uma tarefa agendada sem
# console interativo). Nesses casos os controles ficam simplesmente inativos e
# a conversao roda normal, sem quebrar nada.
$script:ConsoleInterativo = $false
try { $null = [Console]::KeyAvailable; $script:ConsoleInterativo = $true } catch { $script:ConsoleInterativo = $false }

function Suspender-Processo($Proc) {
    if ($Proc -and -not $Proc.HasExited) { try { [DdvtJob]::Pausar($Proc.Handle) } catch { } }
}
function Retomar-Processo($Proc) {
    if ($Proc -and -not $Proc.HasExited) { try { [DdvtJob]::Retomar($Proc.Handle) } catch { } }
}

function Request-Cancelamento($Proc) {
    # Cancelamento pelo ESC: mesma consequencia pratica de fechar a janela no
    # meio (o episodio nao e finalizado e os temporarios sao apagados), so que
    # de forma organizada - quem faz a limpeza e o mesmo catch/finally por
    # episodio que ja trata qualquer outra falha. Aqui so encerramos o
    # processo atual e marcamos a flag; o loop principal ve a flag e para.
    $script:CancelamentoSolicitado = $true
    Write-Host ""
    SayStop "[CANCELANDO] Encerrando o Processo Atual e Limpando os Temporarios..."
    if ($Proc -and -not $Proc.HasExited) {
        # Retomar antes de matar: um processo suspenso pode nao processar o
        # pedido de encerramento enquanto estiver congelado.
        try { [DdvtJob]::Retomar($Proc.Handle) } catch { }
        try { $Proc.Kill() } catch { }
        try { $null = $Proc.WaitForExit(5000) } catch { }
    }
}

function Enter-Pausa($Proc) {
    # Congela o processo filho e fica esperando [F2] (retomar) ou [ESC].
    # O tempo parado e acumulado em $script:SegundosPausadosEtapa para que a
    # barra de progresso estimada nao "salte" ao retomar.
    Suspender-Processo $Proc
    $larg = if ($script:BannerLargura) { $script:BannerLargura } else { 78 }
    Write-Host ""
    # Aviso de pausa COMPACTO (1 linha, com borda em cima/embaixo): destacado o
    # suficiente para nao passar despercebido no meio da barra de progresso,
    # sem virar um bloco gigante repetido a cada pausa. Uma versao maior (com
    # varias linhas de texto explicativo) foi tentada primeiro, mas cada pausa/
    # retomada duplicava aquilo tudo no log - ficava ilegivel num arquivo com
    # varias pausas seguidas. O Start-Transcript grava tudo que passa na tela
    # (nao existe como "apagar" um bloco ja impresso do arquivo de log depois
    # que o usuario retoma), entao o jeito de manter o log limpo e nunca
    # imprimir mais do que o essencial em primeiro lugar.
    Line "=" "Yellow" $larg
    Say-Centralizado ">>> PAUSADO (sem consumir CPU/disco) - [F2] Retomar   [ESC] Cancelar <<<" "Yellow" $larg
    Line "=" "Yellow" $larg

    $iniPausa = Get-Date
    while ($true) {
        Start-Sleep -Milliseconds 120
        if (-not $script:ConsoleInterativo) { break }
        try {
            while ([Console]::KeyAvailable) {
                $k = [Console]::ReadKey($true)
                if ($k.Key -eq "F2") {
                    Retomar-Processo $Proc
                    $seg = ((Get-Date) - $iniPausa).TotalSeconds
                    $script:SegundosPausadosEtapa += $seg
                    Say-Centralizado (">>> RETOMADO - Tempo Pausado: {0} <<<" -f (Format-Duracao $seg)) "Green" $larg
                    Write-Host ""
                    # LIMPEZA DA TELA SEM MEXER NO LOG
                    # ---------------------------------
                    # O bloco de pausa ocupa SEIS linhas na tela (a linha em
                    # branco de cima, as duas bordas, o aviso, a linha de
                    # retomada e a linha em branco de baixo). Numa etapa com
                    # varias pausas seguidas isso vai empilhando e enterra a
                    # barra de progresso.
                    # A saida: as seis linhas ja foram impressas com Write-Host,
                    # entao o Start-Transcript JA GRAVOU todas elas - o log fica
                    # exatamente como era. Aqui embaixo mandamos apenas os
                    # codigos de controle do cursor por [Console]::Write, que o
                    # transcript NAO captura (mesmo mecanismo que ja usamos para
                    # a barra nao encher o log de porcentagens).
                    #   ESC[6A  sobe seis linhas, voltando o cursor para a
                    #           propria linha da barra de progresso
                    #   ESC[0J  apaga dali para baixo
                    # Na volta seguinte do loop a barra se redesenha no lugar de
                    # sempre, como se a pausa nunca tivesse aparecido. Se pausar
                    # de novo, o aviso e impresso de novo - so nao se acumula.
                    if ($script:AnsiOn -and $script:ConsoleInterativo) {
                        try { [Console]::Write($script:ESC + "[6A" + $script:ESC + "[0J") } catch { }
                    }
                    return
                }
                if ($k.Key -eq "Escape") {
                    $script:SegundosPausadosEtapa += ((Get-Date) - $iniPausa).TotalSeconds
                    Request-Cancelamento $Proc
                    return
                }
            }
        } catch { break }
    }
}

function Invoke-ControlesTeclado($Proc) {
    # Chamada a cada volta dos loops de progresso. Consome TODAS as teclas
    # pendentes do buffer (evita que teclas digitadas por engano fiquem
    # "presas" e sejam interpretadas depois, no meio de outra etapa).
    if (-not $script:ConsoleInterativo) { return }
    if ($script:CancelamentoSolicitado) { return }
    try {
        while ([Console]::KeyAvailable) {
            $k = [Console]::ReadKey($true)
            switch ($k.Key) {
                "F1"     { Enter-Pausa $Proc; break }
                "Escape" { Request-Cancelamento $Proc; break }
            }
            if ($script:CancelamentoSolicitado) { return }
        }
    } catch { }
}

$ScriptDir0 = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceDir0 = Join-Path $ScriptDir0 "00_Arquivos_Base"
$OutputDir0 = Join-Path $ScriptDir0 "01_Arquivos_Finalizados"
[System.IO.Directory]::CreateDirectory($OutputDir0) | Out-Null
# v13.5: o log de conversao passou a morar em _logs\, para nao se misturar
# com os .mkv prontos dentro de 01_Arquivos_Finalizados. Se a pasta nao puder
# ser criada (disco protegido, permissao negada), volta para o comportamento
# antigo - gravar no lugar velho e melhor do que nao gravar log nenhum.
$LogsDir0   = Join-Path $ScriptDir0 "_logs"
try { [System.IO.Directory]::CreateDirectory($LogsDir0) | Out-Null } catch { }
if (-not (Test-Path -LiteralPath $LogsDir0)) { $LogsDir0 = $OutputDir0 }
$LogFile    = Join-Path $LogsDir0 ("log_conversao_" + (Get-Date -Format "yyyy-MM-dd_HHmmss") + ".txt")
# [Management.Automation.WildcardPattern]::Escape evita erro do Start-Transcript
# quando a pasta tem colchetes [ ] ou outros caracteres curinga no nome.
Start-Transcript -Path ([Management.Automation.WildcardPattern]::Escape($LogFile)) -Force | Out-Null

$resultados = @()
$inicioGeral = Get-Date

try {

Write-Host ""
# O nome do produto vem PRIMEIRO e sozinho, na cor da marca. As linhas de
# descricao vem logo abaixo, TODAS na mesma cor: antes o "Conversor de AUDIO"
# ficava verde sozinho, o que dava a entender que aquela linha tinha um status
# diferente das outras - e nao tem, e so a continuacao da mesma frase.
$bannerLinhas = @(
    ("{0}  -  VERSAO {1}" -f $SCRIPT_CODINOME, $SCRIPT_VERSION),
    "",
    "[DDVT] Conversor de Dolby VISION [Perfil 5/7/8] -> [Perfil 8.1]",
    "+ Conversor de LEGENDA [PGS -> SRT]",
    "+ Conversor de AUDIO [Dolby TrueHD/DTS:HD/DTS:X -> E-AC-3 Atmos/JOC]"
)
# O banner e o unico bloco que acompanha a LARGURA DA JANELA: com o console
# maximizado, uma borda de 78 colunas encolhida num canto fica pobre, entao
# aqui ela ocupa a tela toda e o texto vai centralizado (o resto do script
# continua alinhado a esquerda em 78 colunas, que e o que faz sentido para
# leitura de log). Usa a largura da JANELA visivel, nao a do buffer - o buffer
# costuma ser bem mais largo e jogaria o "centro" para fora do campo de visao.
$bannerLargura = 78
try {
    $larguraJanela = $Host.UI.RawUI.WindowSize.Width
    # -1 para nunca encostar na ultima coluna (encostar faz o console quebrar
    # a linha sozinho e sujar o desenho da borda).
    if ($larguraJanela -gt 20) { $bannerLargura = [int]$larguraJanela - 1 }
} catch { }
# +6 e nao +2: com a moldura desenhada, +2 fazia o texto mais longo encostar
# nas bordas laterais quando a janela estava estreita. A folga garante que a
# caixa sempre respire, independente do tamanho do console.
$bannerLargura = [Math]::Max($bannerLargura, (($bannerLinhas | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum + 6))
# Guardada em escopo de script porque o bloco de PAUSA ([F1]) tambem se
# centraliza por ela, para ficar alinhado com o cabecalho.
$script:BannerLargura = $bannerLargura

# Cabecalho em moldura de cantos arredondados. A borda usa a cor de sucesso
# (a mesma da barra de progresso e dos [OK]) para amarrar o visual inteiro numa
# familia de cor so. Dentro dela, a PRIMEIRA linha e a de maior destaque e as
# demais descem em intensidade - hierarquia por brilho, nao por cor diferente.
if ($script:AnsiOn) {
    $bannerInterno = $bannerLargura - 2
    Write-Host ((Cor "marcadim") + $script:BoxTL + ($script:BoxH * $bannerInterno) + $script:BoxTR + $script:AnsiReset)
    for ($iB = 0; $iB -lt $bannerLinhas.Count; $iB++) {
        $linhaBanner = [string]$bannerLinhas[$iB]
        $corLinha = if ($iB -eq 0) { Cor "marca" } else { Cor "marcadim" }
        $recuoB = [Math]::Max(0, [int](($bannerInterno - $linhaBanner.Length) / 2))
        $sobraB = [Math]::Max(0, $bannerInterno - $recuoB - $linhaBanner.Length)
        Write-Host ((Cor "marcadim") + $script:BoxV + $script:AnsiReset + (" " * $recuoB) + $corLinha + $linhaBanner + (" " * $sobraB) + (Cor "marcadim") + $script:BoxV + $script:AnsiReset)
    }
    Write-Host ((Cor "marcadim") + $script:BoxBL + ($script:BoxH * $bannerInterno) + $script:BoxBR + $script:AnsiReset)
} else {
    Line "=" "DarkCyan" $bannerLargura
    foreach ($linhaBanner in $bannerLinhas) { Say-Centralizado $linhaBanner "Magenta" $bannerLargura }
    Line "=" "DarkCyan" $bannerLargura
}
# Controles do teclado: centralizados logo abaixo do banner e em cinza escuro,
# para ficarem visiveis ao lado do cabecalho. MAS o cabecalho impresso rola
# para cima e desaparece conforme o log cresce (e um console comum, nao da
# para "fixar" uma regiao do texto no meio da tela). A SOLUCAO real para os
# controles ficarem SEMPRE visiveis, do inicio ao fim, independente de quanto
# o log rolar, e o TITULO DA JANELA - ele nunca rola, fica fixo na barra de
# titulo/aba o tempo todo. Por isso os controles sao escritos nos dois lugares:
# aqui (para quem esta vendo o comeco do log) e no titulo (para sempre).
if ($script:ConsoleInterativo) {
    if ($script:AnsiOn) {
        # As TECLAS ficam em ambar (mesma cor de "atencao/acao do usuario") e o
        # que elas fazem fica em cinza. E exatamente o tipo de linha que antes
        # era impossivel: duas cores na mesma linha sem picotar o log.
        $ctrl = "{warn}[F1]{/}{dim} Pausar     {warn}[F2]{/}{dim} Retomar     {warn}[ESC]{/}{dim} Cancelar{/}"
        $recuoCtrl = [Math]::Max(0, [int](($bannerLargura - (Fmt-Largura $ctrl)) / 2))
        Write-Host ((" " * $recuoCtrl) + (Fmt $ctrl))
    } else {
        Say-Centralizado "[F1] Pausar     [F2] Retomar     [ESC] Cancelar" "DarkGray" $bannerLargura
    }
    try {
        # FIX: a 1a versao colocava "[DDVT] Conversor DV 8.1 - v10.0 LaFirma"
        # ANTES dos controles - em Windows Terminal a ABA so mostra uns 28-30
        # caracteres antes de cortar, entao o nome/versao sozinho ja preenchia
        # todo o espaco visivel e o F1/F2/ESC nunca aparecia (confirmado em
        # screenshot real do usuario). O titulo agora contem SO os controles,
        # sem repetir nome/versao (que ja aparecem no cabecalho impresso logo
        # abaixo), no formato mais compacto possivel ("F1=Pausar" em vez de
        # "[F1] Pausar") para maximizar a chance de caber inteiro na aba.
        $Host.UI.RawUI.WindowTitle = "F1=Pausar F2=Retomar ESC=Cancelar"
    } catch { }
}
Write-Host ""

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ToolsDir   = Join-Path $ScriptDir "tools"
$SourceDir  = Join-Path $ScriptDir "00_Arquivos_Base"
$OutputDir  = Join-Path $ScriptDir "01_Arquivos_Finalizados"
$WorkDirRaiz = Join-Path $ScriptDir "_temp_conversao"   # usado so como fallback improvavel

$ffmpeg     = Join-Path $ToolsDir "ffmpeg.exe"
$ffprobe    = Join-Path $ToolsDir "ffprobe.exe"
$doviTool   = Join-Path $ToolsDir "dovi_tool.exe"
$mkvmerge   = Join-Path $ToolsDir "mkvmerge.exe"
# MediaInfo: usado APENAS para identificar Atmos/JOC no audio (ver
# Get-SinaisAtmosMediaInfo). E a unica ferramenta do tools\ que reporta isso de
# forma confiavel - o ffprobe nao expoe "profile" para TrueHD nem para E-AC-3
# (so para DTS), entao nao serve para essa deteccao. Se o MediaInfo.exe nao
# existir, a deteccao cai no metodo antigo (nome da faixa) sem quebrar nada.
$mediainfo  = Join-Path $ToolsDir "MediaInfo.exe"
$pgsToSrt   = Join-Path $ToolsDir "PgsToSrt\PgsToSrt.exe"
$tessData   = Join-Path $ToolsDir "PgsToSrt\tessdata"
# v14.0 (revisado): Corretor_Legenda.ps1 - roda automaticamente logo apos o
# PgsToSrt/Tesseract, na mesma etapa [5/7], sem passo manual nenhum. Detecta
# e corrige os blocos "alienigenas" que o Tesseract produz em fala curta
# (ex: "Quase." -> "OITECT") usando dicionario PT-BR + regras de
# plausibilidade - mesma ferramenta ja validada em 6/7 casos reais, 0 falso
# positivo em 15 falas boas. Substitui a tentativa de integrar o seconv/
# BinaryOCR direto (v14.0 original): confirmado em teste real que nenhum
# download oficial do Subtitle Edit pro Windows (nem o Setup.exe, nem o
# .zip portatil) traz o seconv.exe separado - so o programa com janela, que
# nao roda headless (testado com a sintaxe nova E com a sintaxe legada
# /convert, as duas abrem a janela). Fica pendente revisitar se um dia
# aparecer um seconv.exe de verdade.
$corretorLegenda = Join-Path $ScriptDir "Corretor_Legenda.ps1"
# v14.2: seconv/BinaryOCR de volta como PREFERENCIAL (mesma ideia da v14.0,
# mantida ate o fim como pedido). Se o binario nao estiver em
# tools\SubtitleEdit\, ou falhar na hora, o motor cai automaticamente pro
# PgsToSrt/Tesseract + Corretor_Legenda (fluxo da v14.1) - nunca fica sem
# solucao nenhuma.
$seconv     = Join-Path $ToolsDir "SubtitleEdit\seconv.exe"
$seconvDb   = Join-Path $ToolsDir "SubtitleEdit\Latin.db"
# v14.4: se nao achar em tools\SubtitleEdit\, tenta o local padrao do proprio
# Subtitle Edit em %AppData% antes de desistir - mesmo fallback que botei
# agora no Corretor_Legenda, pra parar de depender so de copia manual.
if (-not (Test-Path -LiteralPath $seconvDb)) {
    $seconvDbAppData = Join-Path $env:APPDATA "Subtitle Edit\Ocr\Latin.db"
    if (Test-Path -LiteralPath $seconvDbAppData) { $seconvDb = $seconvDbAppData }
}
# v14.5: BUG REAL - o dicionario estava sendo procurado SO em
# tools\SubtitleEdit\Auditor_OCR.dic.gz, e ele nunca esteve la: mora na RAIZ
# do LaFirma (e e por isso que o Limpar_Testes protege "Auditor_OCR.dic.gz"
# pelo nome na raiz, e que o Corretor_Legenda procura em $Raiz). Resultado:
# Get-DicionarioAcentuado voltava vazio, Repara-AcentoBinaryOcr desistia na
# primeira linha ("if ($dic.Count -eq 0) { return 0 }") e a correcao de
# acento do BinaryOCR NUNCA rodou - calada, porque 0 troca nao imprime nada
# diferente. Agora procura nos tres lugares plausiveis, na ordem certa.
$seconvDic = ""
foreach ($cand in @(
    (Join-Path $ScriptDir "Auditor_OCR.dic.gz"),
    (Join-Path $ToolsDir  "SubtitleEdit\Auditor_OCR.dic.gz"),
    "C:\LaFirma\Auditor_OCR.dic.gz"
)) {
    if (Test-Path -LiteralPath $cand) { $seconvDic = $cand; break }
}
$deezy      = Join-Path $ToolsDir "DeeZy\deezy.exe"
# Ferramentas internas que o DeeZy usa (dentro de tools\DeeZy\apps\). O DeeZy
# consegue achar sozinho por essa estrutura de pastas, mas passar os caminhos
# explicitos deixa a conversao de audio mais robusta (funciona mesmo se o
# auto-discovery do DeeZy mudar entre versoes).
#
# 14.35: o --ffmpeg passou a apontar para tools\ffmpeg.exe. Antes apontava
# para tools\DeeZy\apps\ffmpeg\ffmpeg.exe - que e BYTE A BYTE o mesmo
# arquivo (MD5 70195e0342959d38e4ddb410456c9de2 nos dois, 40.808.448 bytes).
# Eram 40 MB do mesmo binario carregados duas vezes dentro do instalador.
# O processo que o DeeZy executa e identico; so o caminho no disco mudou.
# Com isso a pasta tools\DeeZy\apps\ffmpeg\ inteira saiu do instalador.
$deezyFfmpeg  = Join-Path $ToolsDir "ffmpeg.exe"
$deezyDee     = Join-Path $ToolsDir "DeeZy\apps\dee\dee.exe"
$deezyTruehdd = Join-Path $ToolsDir "DeeZy\apps\truehdd\truehdd.exe"

SayTitulo "  PASTAS:"
Say ("  {0}  Pasta de Origem : {1}" -f $script:IconePasta, $SourceDir) "DarkGray"
Say ("  {0}  Pasta de Saida  : {1}" -f $script:IconePasta, $OutputDir) "DarkGray"
Write-Host ""

$pastaBaseFoiCriadaAgora = $false
if (-not (Test-Path -LiteralPath $SourceDir)) {
    [System.IO.Directory]::CreateDirectory($SourceDir) | Out-Null
    $pastaBaseFoiCriadaAgora = $true
}

foreach ($t in @($ffmpeg, $ffprobe, $doviTool, $mkvmerge)) {
    if (-not (Test-Path -LiteralPath $t)) { throw "Ferramenta Obrigatoria Nao Encontrada: $t" }
}

$LinkDotNetRuntime = "https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/8.0.30/windowsdesktop-runtime-8.0.30-win-x64.exe"
$temOcr = Test-Path -LiteralPath $pgsToSrt
if ($temOcr) {
    # Teste rapido: so confere se o Windows CONSEGUE abrir o PgsToSrt.exe.
    # Isso nao muda nada do processamento normal - so melhora a mensagem
    # de erro caso falte o .NET Desktop Runtime 8.0 no PC.
    $tmpErrTeste = [System.IO.Path]::GetTempFileName()
    $tmpOutTeste = [System.IO.Path]::GetTempFileName()
    try {
        $procTeste = Start-Process -FilePath $pgsToSrt -NoNewWindow -PassThru -Wait -RedirectStandardError $tmpErrTeste -RedirectStandardOutput $tmpOutTeste
        $saidaTeste = Get-Content -LiteralPath $tmpErrTeste -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
        if ($saidaTeste -match "\.NET" -and $saidaTeste -match "(?i)install|update") {
            $temOcr = $false
            SayWarn "PgsToSrt Encontrado, Mas Falta o .NET Desktop Runtime 8.0 no Windows. OCR de Legenda Sera Desativado Nesta Execucao."
            Say ("        Baixe e Instale em: {0}" -f $LinkDotNetRuntime) "Yellow"
        }
    } catch { } finally {
        Remove-Item -LiteralPath $tmpErrTeste -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tmpOutTeste -Force -ErrorAction SilentlyContinue
    }
}
$temCorretor = Test-Path -LiteralPath $corretorLegenda
$temSeconv = (Test-Path -LiteralPath $seconv) -and (Test-Path -LiteralPath $seconvDb)

<#  v14.11: Reocr_Legenda entra no MOTOR.
    -------------------------------------------------------------------------
    O DEFEITO QUE ISTO FECHA. O Reocr_Legenda ja resolvia o "INF TOL" no lugar
    do "Nao!" (8 de 8 casos, duas rodadas com resultado identico byte a byte),
    MAS ele so existia como ferramenta solta: escrevia _reocr\<nome>_REOCR.srt
    e parava ali. O .mkv final ja tinha sido remontado na [6/7] com o .srt
    ANTERIOR, e nenhuma etapa remontava de novo. Ou seja: a correcao existia e
    nunca chegava dentro do arquivo. Foi exatamente isso que o usuario viu no
    player, aos 57:06 do Troia.
    Agora ele roda como ULTIMA sub-etapa da [5/7], antes da remontagem - o
    .srt que vai pro mkvmerge ja e o corrigido.

    PRE-REQUISITO: tesseract.exe STANDALONE (o tessdata\ do PgsToSrt e so a
    biblioteca, nao o programa). Se nao estiver instalado, o motor NAO quebra
    e NAO reclama no meio da conversao: avisa uma vez aqui, na lista de
    ferramentas, e a sub-etapa simplesmente nao entra na conta da barra.
#>
<#  v14.23: TESSERACT EMPACOTADO - a ultima peca que nao era portatil.
    O programa inteiro roda de tools\: ffmpeg, ffprobe, dovi_tool, mkvmerge,
    DeeZy, seconv. O tesseract.exe standalone era a UNICA que dependia de
    instalacao por fora (UB-Mannheim). Numa maquina recem-formatada isso
    fazia a sub-etapa de re-OCR simplesmente nao existir - o setup instalava
    um programa com um pedaco a menos, sem que nada quebrasse de forma
    visivel. Agora a copia empacotada vem PRIMEIRO na busca; o Tesseract do
    sistema fica so como ultimo recurso, pra quem ja tinha um instalado.  #>
$reocrLegenda = Join-Path $ScriptDir "Reocr_Legenda.ps1"
$tesseractExe = ""
$tesseractEmpacotado = $false
foreach ($cand in @((Join-Path $ToolsDir "Tesseract\tesseract.exe"),
                    (Join-Path $ToolsDir "Tesseract-OCR\tesseract.exe"))) {
    if (Test-Path -LiteralPath $cand) { $tesseractExe = $cand; $tesseractEmpacotado = $true; break }
}
if ($tesseractExe -eq "") {
    try {
        $cmdTess = Get-Command "tesseract.exe" -ErrorAction SilentlyContinue
        if ($cmdTess) { $tesseractExe = $cmdTess.Source }
    } catch { }
}
if ($tesseractExe -eq "") {
    foreach ($cand in @("C:\Program Files\Tesseract-OCR\tesseract.exe",
                        "C:\Program Files (x86)\Tesseract-OCR\tesseract.exe")) {
        if (Test-Path -LiteralPath $cand) { $tesseractExe = $cand; break }
    }
}
$temReocr = (Test-Path -LiteralPath $reocrLegenda) -and ($tesseractExe -ne "")
SayTitulo "  FERRAMENTAS DISPONIVEIS:"
if ($temSeconv) { SayOk "OCR de Legenda PT-BR Disponivel (seconv / BinaryOCR - preferencial)" }
elseif ((Test-Path -LiteralPath $seconv) -and -not (Test-Path -LiteralPath $seconvDb)) {
    SayWarn "seconv.exe Encontrado, Mas Falta o Banco 'Latin.db' em tools\SubtitleEdit\. Caindo Para PgsToSrt + Corretor_Legenda."
}
if ($temOcr -and $temCorretor) { SayOk "Rede de Seguranca Disponivel (PgsToSrt + Corretor_Legenda automatico)" }
elseif ($temOcr -and -not $temCorretor) { SayOk "Rede de Seguranca Disponivel (PgsToSrt - sem Corretor_Legenda.ps1, correcao de blocos-lixo desativada)" }
elseif (-not $temOcr -and -not $temSeconv) { SayWarn "Nem seconv Nem PgsToSrt Encontrados. A Conversao Vai Seguir Sem Legenda OCR." }
if ($temReocr -and $tesseractEmpacotado) { SayOk "Re-OCR de Falas Curtas Disponivel (Reocr_Legenda + Tesseract PSM 6 empacotado - roda dentro da [4/5])" }
elseif ($temReocr) { SayOk "Re-OCR de Falas Curtas Disponivel (Reocr_Legenda + Tesseract PSM 6 do sistema - roda dentro da [4/5])" }
elseif (Test-Path -LiteralPath $reocrLegenda) {
    SayWarn "Reocr_Legenda.ps1 Existe, Mas Falta o tesseract.exe em tools\Tesseract\. Falas Curtas Tipo 'Nao!' Nao Serao Refeitas."
    Say "        A pasta vem no instalador - se sumiu, reinstale o LaFirma." "DarkGray"
}

$temDeezy = Test-Path -LiteralPath $deezy
if ($temDeezy) {
    # Teste rapido: so confere se o Windows CONSEGUE abrir o deezy.exe (ou
    # seja, se o executavel e a estrutura de pastas apps\ estao corretas).
    # Nao valida a licenca do DEE em si - isso so e confirmado de verdade
    # na hora de converter o audio de cada episodio.
    #
    # IMPORTANTE: usamos System.Diagnostics.Process (e nao Start-Process -Wait)
    # e "prendemos" o .Handle logo apos iniciar. Sem isso, o .NET pode
    # devolver ExitCode = -1 mesmo quando o deezy.exe roda e sai com 0 - era
    # exatamente o que fazia o teste falhar com "(codigo -1)" e desativar o
    # DeeZy sem necessidade. Tambem lemos a saida real do --version para
    # confirmar de verdade que o binario respondeu.
    try {
        $psiDeezy = New-Object System.Diagnostics.ProcessStartInfo
        $psiDeezy.FileName = $deezy
        $psiDeezy.Arguments = "--version"
        $psiDeezy.RedirectStandardOutput = $true
        $psiDeezy.RedirectStandardError  = $true
        $psiDeezy.UseShellExecute = $false
        $psiDeezy.CreateNoWindow  = $true
        $procDeezyTeste = New-Object System.Diagnostics.Process
        $procDeezyTeste.StartInfo = $psiDeezy
        $procDeezyTeste.Start() | Out-Null
        $null = $procDeezyTeste.Handle          # <- prende o handle (evita ExitCode -1 falso)
        Adotar-Processo $procDeezyTeste
        $saidaDeezyOut = $procDeezyTeste.StandardOutput.ReadToEnd()
        $saidaDeezyErr = $procDeezyTeste.StandardError.ReadToEnd()
        $procDeezyTeste.WaitForExit()
        $codigoDeezy = $procDeezyTeste.ExitCode
        $saidaDeezy  = ($saidaDeezyOut + " " + $saidaDeezyErr).Trim()

        # deezy --version imprime algo como "deezy 1.3.14" e sai com codigo 0.
        # IMPORTANTE: a regex de versao deve ser estrita (palavra-limite no inicio)
        # para nao capturar numeros que aparecam dentro de caminhos de pasta no
        # stderr de erro (ex: "Dolby Vision 8.1\tools\" -> confunde "8.1" com versao).
        # Procuramos especificamente o padrao "deezy X.Y" ou "version X.Y" ou uma
        # linha que comece com digitos de versao no inicio da saida.
        $pareceVersao = $false
        $versaoEncontrada = ""
        if ($saidaDeezy -match '(?i)(?:deezy|version)[^\d]*(\d+\.\d+[\d\.]*)') {
            $pareceVersao = $true
            $versaoEncontrada = $Matches[1]
        } elseif ($codigoDeezy -eq 0) {
            # saiu com 0 mesmo sem identificar a string de versao: consideramos OK
            $pareceVersao = $true
        }

        if (-not $pareceVersao) {
            $temDeezy = $false
            # Extrai so a primeira linha do erro para nao logar paths gigantes
            $primeiraLinhaErro = ($saidaDeezy -split "`n")[0].Trim()
            $detalheDeezy = if ($primeiraLinhaErro) { $primeiraLinhaErro } else { "codigo $codigoDeezy" }
            SayWarn "DeeZy Encontrado, Mas Nao Consegui Executa-lo: $detalheDeezy"
            SayWarn "A Conversao de Audio para E-AC-3 Atmos Sera Desativada Nesta Execucao."
        } else {
            # A versao e guardada aqui e so IMPRESSA depois da linha de [OK]
            # do DeeZy. Antes ela saia ANTES, o que deixava uma linha cinza
            # solta entre dois vistos verdes, como se fosse detalhe do OCR -
            # quando na verdade e detalhe do DeeZy.
            if ($versaoEncontrada) { $script:VersaoDeezy = $versaoEncontrada }
        }
    } catch {
        $temDeezy = $false
        SayWarn "DeeZy Encontrado, Mas Nao Consegui Executa-lo ($($_.Exception.Message)). A Conversao de Audio para E-AC-3 Atmos Sera Desativada Nesta Execucao."
    }
}
if ($temDeezy) {
    SayOk "Conversao de Audio TrueHD -> E-AC-3 Atmos Disponivel (DeeZy)"
    if ($script:VersaoDeezy) { Say ("        Versao do DeeZy Detectada: {0}" -f $script:VersaoDeezy) "DarkGray" }
}
elseif (-not (Test-Path -LiteralPath $deezy)) { SayWarn "deezy.exe Nao Encontrado em tools\DeeZy\. A Conversao de Audio Sera Desativada Nesta Execucao." }
Write-Host ""

[System.IO.Directory]::CreateDirectory($OutputDir) | Out-Null


function Get-MkvJson {
    # Le e cacheia o resultado do "mkvmerge -J" por arquivo. Antes, cada
    # funcao de deteccao (faixa de audio, checagem de E-AC-3, busca de
    # legenda) chamava o mkvmerge separadamente - 3 a 4 execucoes identicas
    # por episodio (diagnostico + etapas). Com o cache, roda UMA vez por
    # arquivo e todas as funcoes reutilizam o mesmo resultado.
    param([string]$MkvPath)
    if ($script:CacheMkvJsonPath -eq $MkvPath -and $script:CacheMkvJson) { return $script:CacheMkvJson }
    $jsonRaw = & $mkvmerge -J "$MkvPath" 2>$null
    if (-not $jsonRaw) { return $null }
    $script:CacheMkvJson = $jsonRaw | ConvertFrom-Json
    $script:CacheMkvJsonPath = $MkvPath
    return $script:CacheMkvJson
}

function Test-VideoDecodavel {
    <#  v14.16: CONFERENCIA DE VERDADE DO ARQUIVO FINAL.
        Ate a 14.15 o motor dava o arquivo por bom se o mkvmerge saisse com
        codigo 0 e o arquivo existisse com tamanho > 0. O Se7en passou nos
        dois e estava com a imagem congelada a partir dos 47 minutos.
        Aqui o ffmpeg DECODIFICA mesmo (nao e "-c copy", nao e ffprobe) alguns
        quadros em N pontos espalhados pelo arquivo. Sao ~12 quadros por ponto:
        rapido, e o suficiente para pegar cabecalho de codec errado, corte no
        meio e fluxo truncado.
        Nao decide nada: so mede e devolve. Quem decide e a etapa.

        v14.20: O QUE CONTA COMO FALHA MUDOU - E ESTE ERA UM DEFEITO GRAVE.
        Ate a 14.19 a regra era "se o ffmpeg escreveu QUALQUER COISA no stderr,
        o trecho falhou". Isso confunde duas coisas muito diferentes:
            reclamacao do decodificador   (ele resmunga e entrega os quadros)
            falha de decodificacao        (nao sai quadro nenhum)
        No Spider-Man (log 19/08 11h47) o resultado foi
            "O ARQUIVO FINAL NAO DECODIFICOU EM 7 DE 10 TRECHOS"
        com a mensagem  "First slice in a frame missing."  - que quer dizer
        exatamente "a busca me largou no meio de um quadro". O ffmpeg descarta
        aquele quadro incompleto, resincroniza no proximo e decodifica os 12
        normalmente. Nada quebrado. A prova esta no proprio log: o teste foi
        repetido no arquivo de ORIGEM e ele "falhou" nos MESMOS 7 pontos - e o
        arquivo de origem toca inteiro, do inicio ao fim.
        Ou seja: a rede de seguranca que existe para dizer "seu arquivo
        quebrou" gritou num arquivo perfeito. Alarme falso e a mesma familia
        de defeito que este projeto ja mordeu quinze vezes: MENSAGEM QUE MENTE.
        E o pior tipo dela - a que faz duvidar de um arquivo bom.
        A regra nova nao lista mensagens conhecidas (remendo que envelhece
        mal, uma linha nova do ffmpeg e a lista fura). Ela pergunta o que
        importa: SAIU QUADRO? O ffmpeg e obrigado a informar quantos quadros
        entregou ("-stats" imprime "frame= N" na ultima linha).
            saiu a quantidade pedida  -> o trecho decodifica. Ponto.
            saiu menos da metade      -> falha de verdade, com o texto junto.
        A reclamacao continua sendo registrada - agora como RUIDO, num campo
        proprio, para o log poder dizer a verdade inteira: "decodificou, e o
        ffmpeg reclamou". Informacao, nao alarme. #>
    param(
        [string]$Caminho,
        [double]$DuracaoSeg,
        [int]$Pontos = 10,
        [int]$Quadros = 12,
        [switch]$ComBarra
    )
    # ATENCAO (nao remover): o script inteiro roda com $ErrorActionPreference
    # = "Stop". No Windows PowerShell 5.1, "& programa 2>&1" com Stop transforma
    # QUALQUER linha que o programa escreva no stderr em erro terminante - e a
    # funcao inteira morreria justamente quando encontrasse o que veio procurar.
    # A atribuicao abaixo cria uma copia LOCAL da preferencia (escopo de
    # funcao); ao sair, o valor "Stop" do script volta sozinho.
    $ErrorActionPreference = "Continue"
    $res = @{ Ok = $true; Testados = 0; Falhas = @(); Ruidos = @() }
    if ([string]::IsNullOrWhiteSpace($Caminho) -or -not (Test-Path -LiteralPath $Caminho)) {
        $res.Ok = $false
        return $res
    }
    # Arquivo curto demais para espalhar pontos: nao ha o que amostrar.
    if ($DuracaoSeg -le 10) { return $res }
    if ($Pontos -lt 2) { $Pontos = 2 }
    $inicio = $DuracaoSeg * 0.01
    $fim    = $DuracaoSeg * 0.98
    $passo  = ($fim - $inicio) / ($Pontos - 1)
    $inv    = [System.Globalization.CultureInfo]::InvariantCulture
    $falhas = New-Object System.Collections.ArrayList
    $ruidos = New-Object System.Collections.ArrayList
    # Quantos quadros bastam para dizer "este trecho decodifica". Metade do
    # pedido: uma busca que cai no meio de um quadro custa no maximo o primeiro
    # (o decodificador resincroniza no proximo), entao exigir a metade da folga
    # de sobra sem deixar passar um trecho que so entrega dois ou tres.
    $minQuadros = [math]::Max(1, [int][math]::Floor($Quadros / 2.0))
    for ($i = 0; $i -lt $Pontos; $i++) {
        if ($script:CancelamentoSolicitado) { break }
        $t = $inicio + ($passo * $i)
        $res.Testados = $res.Testados + 1
        # Duas tentativas no MESMO ponto. Um erro que aparece uma vez e some na
        # repeticao nao e defeito do arquivo - e ruido (disco ocupado, leitura
        # concorrente). So conta como falha o que falha nas duas.
        $texto = ""
        $codigo = 0
        $quadrosLidos = 0
        $decodificou = $false
        for ($tent = 1; $tent -le 2; $tent++) {
            # O "-ss" ANTES do "-i" e a busca rapida: o ffmpeg posiciona no
            # keyframe igual ou anterior ao instante pedido e decodifica dali.
            # Mesmo assim ele pode ser largado no meio de um quadro (fluxo HEVC
            # com quadro repartido em varias fatias) - por isso quem decide e a
            # contagem de quadros, nao o silencio do stderr.
            # "-stats" e o que faz a ultima linha trazer "frame= N".
            $argsFf = @("-hide_banner","-nostdin","-v","error","-stats",
                        "-ss",([double]$t).ToString("0.000", $inv),
                        "-i","$Caminho","-map","0:v:0","-frames:v","$Quadros",
                        "-an","-sn","-f","null","-")
            $saida = @(& $ffmpeg @argsFf 2>&1)
            $codigo = $LASTEXITCODE
            $bruto = (($saida | ForEach-Object { "$_" }) -join " ").Trim()
            # A ultima ocorrencia de "frame=" e a linha final de estatistica.
            $quadrosLidos = 0
            $achados = [regex]::Matches($bruto, 'frame=\s*(\d+)')
            if ($achados.Count -gt 0) {
                $quadrosLidos = [int]$achados[$achados.Count - 1].Groups[1].Value
            }
            # O texto guardado e so o que NAO e a linha de estatistica - ela
            # aparece sempre e nao e reclamacao de ninguem.
            $texto = ([regex]::Replace($bruto, 'frame=\s*\d+[^\r\n]*', '')).Trim()
            $decodificou = ($codigo -eq 0 -and $quadrosLidos -ge $minQuadros)
            if ($decodificou -and $texto -eq "") { break }
        }
        if ($texto.Length -gt 160) { $texto = $texto.Substring(0, 160) + "..." }
        if ($decodificou) {
            # Entregou os quadros. Se resmungou no caminho, isso e RUIDO: vai
            # para o log como informacao e nao derruba a conferencia.
            if ($texto -ne "") {
                [void]$ruidos.Add(@{ Segundo = [double]$t; Detalhe = $texto })
            }
        } else {
            [void]$falhas.Add(@{ Segundo = [double]$t; Detalhe = $texto
                                 Quadros = $quadrosLidos; Codigo = $codigo })
            $res.Ok = $false
        }
        if ($ComBarra) { Show-Barra (100.0 * ($i + 1) / $Pontos) }
    }
    $res.Falhas = @($falhas)
    $res.Ruidos = @($ruidos)
    return $res
}

function Get-DuracaoDoArquivo {
    <#  v14.20: um ffprobe so, para o [VERIFICACAO] poder comparar a duracao do
        arquivo final com a da origem. Devolve 0 quando nao da para saber - e
        quem chama trata 0 como "nao sei", nunca como "zero segundos". #>
    param([string]$Caminho)
    $ErrorActionPreference = "Continue"
    if ([string]::IsNullOrWhiteSpace($Caminho) -or -not (Test-Path -LiteralPath $Caminho)) { return 0.0 }
    $d = 0.0
    try {
        $bruto = & $ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$Caminho" 2>$null
        $txt = ("$bruto").Trim()
        [double]::TryParse($txt, [System.Globalization.NumberStyles]::Float,
                           [System.Globalization.CultureInfo]::InvariantCulture, [ref]$d) | Out-Null
    } catch { $d = 0.0 }
    if ($d -lt 0) { $d = 0.0 }
    return $d
}

function Get-IndiceAudioNaFaixa {
    # Retorna a posicao 0-based de $Faixa dentro da lista de faixas de AUDIO
    # do arquivo (na ordem em que aparecem no container) - e o indice que o
    # DeeZy ("--track-index") e o ffmpeg ("-map 0:a:N") esperam. Como agora
    # a faixa PRINCIPAL escolhida por Get-FaixaAudioPrincipal pode nao ser
    # mais sempre a primeira faixa de audio do arquivo (ex: quando a faixa 01
    # e um comentario, ou quando a faixa em ingles/default esta em outra
    # posicao), os comandos de extracao de audio precisam apontar para o
    # indice CERTO - nao mais fixo em "0".
    param([string]$MkvPath, $Faixa)
    if (-not $Faixa) { return 0 }
    $json = Get-MkvJson -MkvPath $MkvPath
    if (-not $json) { return 0 }
    $audios = @($json.tracks | Where-Object { $_.type -eq "audio" })
    for ($i = 0; $i -lt $audios.Count; $i++) {
        if ($audios[$i].id -eq $Faixa.id) { return $i }
    }
    return 0
}

# ============================================================================
#  v13.3 - PORTA DAS ESCOLHAS MANUAIS
# ============================================================================
# Fora da janela esta variavel nunca e preenchida, e entao Get-EscolhaManual
# devolve $null em todas as chamadas e o motor se comporta exatamente como na
# 13.2. Nao existe caminho novo no modo automatico - so um $null a mais.
$script:EscolhasManuais = $null

function Get-EscolhaManual {
    # Devolve a hashtable de escolhas deste arquivo, ou $null. Aceita a chave
    # pelo NOME do arquivo ou pelo caminho completo: a janela conhece o
    # caminho, mas o nome sozinho e mais facil de escrever a mao numa sonda.
    param([string]$Arquivo)
    if (-not $script:EscolhasManuais) { return $null }
    if ([string]::IsNullOrWhiteSpace($Arquivo)) { return $null }
    if ($script:EscolhasManuais.ContainsKey($Arquivo)) { return $script:EscolhasManuais[$Arquivo] }
    $nome = [System.IO.Path]::GetFileName($Arquivo)
    if ($nome -and $script:EscolhasManuais.ContainsKey($nome)) { return $script:EscolhasManuais[$nome] }
    return $null
}

function Test-EscolheuConverter {
    # $true / $false quando a escolha manual mandou explicitamente converter
    # (ou nao) a faixa principal; $null quando ela nao falou nada a respeito -
    # e ai quem decide continua sendo o motor.
    param([string]$Arquivo)
    $e = Get-EscolhaManual $Arquivo
    if (-not $e) { return $null }
    if (-not $e.ContainsKey('ConverterPrincipal')) { return $null }
    return [bool]$e['ConverterPrincipal']
}

function Resolve-FaixasDoRemux {
    # O UNICO ponto em que a escolha manual troca a lista de faixas que vai
    # para o mkvmerge. Recebe o que o motor decidiu e devolve o que sai - sem
    # escolha manual, devolve identico ao que entrou (a sonda testa esse caso
    # primeiro, porque e ele que garante que o console nao mudou).
    param(
        [string]$Arquivo,
        $IdsAudio, $IdAudioDefault, $IdsLegenda,
        [bool]$AudioSemRestricao, [bool]$LegendaSemRestricao
    )
    $saida = @{
        Audio               = @($IdsAudio)
        AudioDefault        = $IdAudioDefault
        Legenda             = @($IdsLegenda)
        AudioSemRestricao   = $AudioSemRestricao
        LegendaSemRestricao = $LegendaSemRestricao
        Manual              = $false
    }
    $e = Get-EscolhaManual $Arquivo
    if (-not $e) { return $saida }

    if ($e.ContainsKey('AudioManter')) {
        $ids = @($e['AudioManter'] | Where-Object { $null -ne $_ })
        # Lista vazia NAO vira 'descarta todo o audio': isso produziria um
        # arquivo sem som. Escolha vazia = o motor decide, como antes.
        if ($ids.Count -gt 0) {
            $saida.Audio = $ids
            $saida.AudioSemRestricao = $false   # sem isso o --audio-tracks nem sai
            $saida.Manual = $true
        }
    }
    if ($e.ContainsKey('AudioDefault')) { $saida.AudioDefault = $e['AudioDefault']; $saida.Manual = $true }
    # v13.4: a padrao tem que existir na lista que vai sair. $null aqui e
    # legitimo (quer dizer 'a faixa NOVA sera a padrao'), por isso o teste
    # exige -ne $null antes de olhar a lista.
    if ($saida.Manual -and $null -ne $saida.AudioDefault -and (@($saida.Audio) -notcontains $saida.AudioDefault)) {
        $saida.AudioDefault = @($saida.Audio)[0]
    }
    if ($e.ContainsKey('LegendaManter')) {
        $ids = @($e['LegendaManter'] | Where-Object { $null -ne $_ })
        # v13.7: DIFERENTE do audio (bloco logo acima). Legenda vazia E um
        # estado valido - nao existe "arquivo sem legenda quebrado" como
        # existe "arquivo sem audio quebrado". Antes desta versao, a
        # condicao 'Count -gt 0' tratava LegendaManter=@() como se a chave
        # nao tivesse vindo, e a escolha manual de excluir tudo era
        # silenciosamente ignorada - o motor voltava a reaproveitar a
        # PT-BR que ja tinha decidido sozinho. Contrato do projeto e por
        # CHAVE PRESENTE, nao por valor (ver cabecalho do arquivo) - a mera
        # presenca da chave, mesmo com lista vazia, ja E a escolha manual e
        # tem que valer. O '--no-subtitles' pra esse caso ja existia mais
        # abaixo (bloco 'else' de idsLegendaManter.Count -eq 0), so nunca
        # era alcancado porque a lista nunca chegava vazia ate aqui.
        $saida.Legenda = $ids
        $saida.LegendaSemRestricao = $false
        $saida.Manual = $true
    }
    return $saida
}

function Get-FaixaAudioPrincipal {
    # Escolhe a faixa de audio PRINCIPAL do filme/episodio - a que representa
    # o audio original, nao um extra como comentario de diretor/elenco.
    # Ordem de prioridade dentro das faixas que NAO sao comentario:
    #   1) TrueHD/MLP, em QUALQUER idioma - ignora a flag "default" do
    #      remux. Motivo: em remuxes "Dual Audio", a faixa marcada como
    #      default costuma ser a dublagem (ex: DTS em portugues) escolhida
    #      pelo grupo de release para aquele publico especifico - nao a
    #      melhor faixa tecnicamente. Como o objetivo do script e sempre
    #      preservar o TrueHD/Atmos quando ele existir (regra definida com
    #      o usuario), a busca por TrueHD vem antes de qualquer flag do
    #      arquivo, para nunca perder o Atmos por causa disso.
    #   2) Se nao houver TrueHD, a primeira faixa em ingles (idioma mais
    #      comum como audio original de Blu-ray) - vem ANTES da flag
    #      "default", pelo MESMO motivo do item 1: em remuxes Dual Audio
    #      SEM TrueHD (ex: dual DTS ou dual AC-3/AAC puro), a flag
    #      "default" do arquivo tambem costuma marcar a dublagem, nao o
    #      audio original em ingles.
    #      BUG CORRIGIDO NA v8.6: ate a v8.5, a flag "default" vinha ANTES
    #      do ingles - entao esse mesmo problema (perder o audio original
    #      para uma dublagem marcada como default pelo grupo de release)
    #      podia acontecer em qualquer arquivo Dual Audio SEM TrueHD. So
    #      nao tinha sido percebido antes porque toda a evidencia real do
    #      bug (ex: Schindler's List) envolvia arquivos COM TrueHD, onde o
    #      item 1 ja "salvava" a escolha automaticamente antes de chegar
    #      nesse ponto - um dual-audio puro em DTS/AC-3 (sem TrueHD) sofria
    #      do mesmo problema sem nada para salvar a escolha.
    #   3) Se nao houver ingles, a faixa marcada como "default" pelo
    #      proprio remux (flag padrao do mkvmerge/mkv).
    #   4) Se nada disso bater, a primeira faixa de audio nao-comentario na
    #      ordem em que aparece no arquivo (comportamento antigo).
    #   5) Caso TODAS as faixas estejam marcadas como comentario (raro), usa
    #      a primeira faixa de audio do arquivo mesmo assim.
    param([string]$MkvPath)
    $json = Get-MkvJson -MkvPath $MkvPath
    if (-not $json) { return $null }
    $todas = @($json.tracks | Where-Object { $_.type -eq "audio" })
    # v13.3: escolha manual da principal. Entra ANTES de qualquer regra
    # (comentario, idioma, flag default) porque o usuario olhou a tabela de
    # faixas e apontou uma - nao ha o que deduzir depois disso. Se o id nao
    # existir no arquivo, cai na regra normal em vez de devolver nada.
    $escManual = Get-EscolhaManual $MkvPath
    if ($escManual -and $escManual.ContainsKey('AudioPrincipal') -and $null -ne $escManual['AudioPrincipal']) {
        $escolhida = @($todas | Where-Object { $_.id -eq $escManual['AudioPrincipal'] })
        if ($escolhida.Count -gt 0) { return $escolhida[0] }
    }
    if ($todas.Count -eq 0) { return $null }

    $naoComentario = @($todas | Where-Object { -not (Test-EhFaixaComentario $_) })
    if ($naoComentario.Count -eq 0) { return $todas[0] }

    $trueHd = @($naoComentario | Where-Object { Test-EhTrueHD $_ })
    if ($trueHd.Count -gt 0) { return $trueHd[0] }

    $ingles = @($naoComentario | Where-Object {
        $_.properties.language -match "^(eng|en)$" -or $_.properties.language_ietf -match "(?i)^en"
    })
    if ($ingles.Count -gt 0) { return $ingles[0] }

    $default = @($naoComentario | Where-Object { $_.properties.default_track -eq $true })
    if ($default.Count -gt 0) { return $default[0] }

    return $naoComentario[0]
}

function Test-EhFaixaComentario {
    # Detecta faixas de "comentario" (diretor, elenco, produtores etc.) pelo
    # nome da faixa - essas faixas nunca devem ser tratadas como o audio
    # principal do filme, nem contam como "ja tem E-AC-3 compativel".
    param($Track)
    if (-not $Track) { return $false }
    return ($Track.properties.track_name -match "(?i)commentary|coment.rio")
}

function Test-EhTrueHD {
    param($Track)
    if (-not $Track) { return $false }
    return ($Track.codec -match "(?i)TrueHD|MLP")
}

function Test-EhDts {
    # Detecta qualquer variante da familia DTS: DTS, DTS-ES, DTS-HD High
    # Resolution, DTS-HD Master Audio e DTS:X (o mkvmerge reporta DTS:X
    # dentro de "DTS-HD Master Audio"). Todas essas variantes sao tratadas
    # igual: decodificadas pelo ffmpeg e recodificadas para E-AC-3 comum
    # (sem Atmos - a familia DTS nao carrega metadado de audio Dolby).
    param($Track)
    if (-not $Track) { return $false }
    return ($Track.codec -match "(?i)DTS")
}

function Test-EhCompativelC2 {
    # Retorna $true se a faixa estiver num codec que a maioria das TVs/
    # soundbars modernas (ex: LG C2) reproduz de forma nativa sem precisar
    # de conversao: E-AC-3 (Dolby Digital Plus), AC-3 (Dolby Digital) ou AAC.
    #
    # Usada em dois contextos:
    #   1) Na faixa PRINCIPAL: se ela ja estiver aqui, nao ha o que fazer
    #      (a menos que seja TrueHD - ver regra especial mais abaixo).
    #   2) Em OUTRAS faixas do arquivo (Get-FaixaCompativelC2Externa):
    #      para decidir se vale a pena converter um DTS quando ja existe uma
    #      faixa E-AC-3/AC-3 pronta e utilizavel em outro lugar do arquivo.
    param($Track)
    if (-not $Track) { return $false }
    return ($Track.codec -match "(?i)E-AC-3|EAC3|EAC-3|(^|\s)AC-?3($|\s)|Dolby Digital|AAC")
}

function Get-SinaisAtmosMediaInfo {
    # Le, via MediaInfo CLI, os campos que identificam Dolby Atmos / JOC em
    # cada faixa de audio - UMA passada por arquivo, com cache.
    #
    # POR QUE MEDIAINFO E NAO FFPROBE: o ffprobe NAO expoe o campo "profile"
    # para TrueHD nem para E-AC-3 - so para DTS. Verificado na pratica com
    # ffprobe -show_entries stream=index,codec_type,codec_name,profile no
    # arquivo Avatar Fire and Ash 2025:
    #     index 1 -> codec_name "truehd"  (sem profile)
    #     index 2 -> codec_name "dts"     profile "DTS-HD MA"
    #     index 3 -> codec_name "eac3"    (sem profile)  <- a faixa JOC!
    #     index 4 -> codec_name "eac3"    (sem profile)
    # Ou seja, pelo ffprobe e impossivel distinguir um E-AC-3 comum de um
    # E-AC-3 JOC (Atmos). O MediaInfo distingue com clareza - mesma saida,
    # mesmo arquivo, template abaixo:
    #     2|MLP FBA|Dolby TrueHD with Dolby Atmos|16-ch|Engelsk TrueHD 7.1...
    #     3|DTS|DTS-HD Master Audio|XLL|Engelsk DTS-HD MA 7.1
    #     4|E-AC-3|Dolby Digital Plus with Dolby Atmos|JOC|      <- SEM titulo
    #     5|E-AC-3|Dolby Digital Plus|Dep|Brazilian              <- sem Atmos
    # Repare que a faixa 4 (JOC de verdade) e identificada mesmo sem nome, e
    # fica bem separada da faixa 5 (dublagem E-AC-3 comum). Sao esses dois
    # campos que interessam: Format_Commercial_IfAny (traz "Dolby Atmos") e
    # Format_AdditionalFeatures (traz "JOC").
    #
    # Retorna um ARRAY com um texto de sinal por faixa de AUDIO, na ORDEM em
    # que as faixas aparecem no arquivo. O casamento com as faixas do
    # mkvmerge e feito por ORDEM (a i-esima faixa de audio de um e a i-esima
    # do outro) - as duas ferramentas listam na mesma ordem fisica, e isso e
    # mais confiavel do que tentar casar numeros de ID (o MediaInfo comeca a
    # numerar em 1 e conta o video; o mkvmerge comeca em 0).
    # Se o MediaInfo.exe nao existir ou falhar, retorna array vazio e quem
    # chama cai no metodo antigo (nome da faixa), sem quebrar nada.
    param([string]$MkvPath)
    if ($script:CacheSinaisAtmosPath -eq $MkvPath -and $null -ne $script:CacheSinaisAtmos) { return $script:CacheSinaisAtmos }
    $resultado = @()
    try {
        if (Test-Path -LiteralPath $mediainfo) {
            $saida = & $mediainfo "--Output=Audio;%Format_Commercial_IfAny%|%Format_AdditionalFeatures%\r\n" "$MkvPath" 2>$null
            foreach ($linha in @($saida)) {
                # Toda linha valida tem o separador "|" (mesmo quando os dois
                # campos vem vazios, a linha e "|"). Filtrar por isso descarta
                # linhas em branco soltas SEM desalinhar a ordem das faixas.
                if ($linha -notmatch '\|') { continue }
                $resultado += ([string]$linha).Trim()
            }
        }
    } catch { }
    $script:CacheSinaisAtmos = $resultado
    $script:CacheSinaisAtmosPath = $MkvPath
    return $resultado
}

function Test-EhAtmosOuJoc {
    # Detecta se uma faixa carrega metadado Dolby Atmos/JOC (Joint Object
    # Coding). Duas fontes de sinal, checadas em ordem:
    #   1) Os campos do MediaInfo (via Get-SinaisAtmosMediaInfo) - leitura
    #      real do bitstream, funciona MESMO SEM nome de faixa. Recebe aqui o
    #      texto ja resolvido para ESTA faixa (o chamador casa por ordem).
    #      Resolve o caso real do arquivo Avatar Fire and Ash 2025, em que uma
    #      faixa E-AC-3 JOC sem nome nao era reconhecida como "ja tem Atmos" e
    #      o script reconvertia o TrueHD a toa (55+ min desperdicados).
    #   2) Fallback: codec + nome da faixa (metodo antigo) - cobre o caso do
    #      MediaInfo.exe ausente, e casos em que o proprio remux/scene group
    #      ja nomeia a faixa (ex: "EAC3 Atmos").
    param($Track, $SinalMediaInfo)
    if (-not $Track) { return $false }
    if ($SinalMediaInfo -and ($SinalMediaInfo -match "(?i)Atmos|\bJOC\b")) { return $true }
    $sinal = "$($Track.codec) $($Track.properties.track_name)"
    return ($sinal -match "(?i)Atmos|\bJOC\b")
}

function Get-IdiomaFaixa {
    # Devolve o idioma da faixa NORMALIZADO para comparacao (minusculo, codigo
    # de 3 letras quando conhecido). Prefere o language_ietf do mkvmerge, que e
    # o mais preciso ("pt-BR"), e usa so a subtag principal ("pt"); se nao
    # houver, cai no campo language ("por").
    # Codigos que significam "nao informado" (und/mis/mul/zxx/qaa) e a ausencia
    # do campo viram string VAZIA - e string vazia nunca conflita com nada
    # (ver Test-IdiomaConflitante).
    param($Track)
    if (-not $Track) { return "" }
    $v = "$($Track.properties.language_ietf)".Trim()
    if ($v) { $v = ($v -split "-")[0] } else { $v = "$($Track.properties.language)".Trim() }
    $v = $v.ToLower()
    if ($v -eq "" -or $v -eq "und" -or $v -eq "mis" -or $v -eq "mul" -or $v -eq "zxx" -or $v -eq "qaa") { return "" }
    # Equivalencias ISO 639-1 <-> 639-2 dos idiomas que aparecem nestes remuxes.
    # Sem isso, "en" (vindo do IETF) e "eng" (vindo do language) seriam lidos
    # como idiomas DIFERENTES e a funcao inverteria o proprio sentido.
    $mapa = @{ "en" = "eng"; "pt" = "por"; "es" = "spa"; "fr" = "fre"; "fra" = "fre";
               "de" = "ger"; "deu" = "ger"; "it" = "ita"; "ja" = "jpn"; "jpn" = "jpn";
               "ko" = "kor"; "zh" = "chi"; "zho" = "chi"; "ru" = "rus" }
    if ($mapa.ContainsKey($v)) { return $mapa[$v] }
    return $v
}

function Test-IdiomaConflitante {
    # $true SO quando as duas faixas tem idioma CONHECIDO e DIFERENTE.
    # Se qualquer um dos dois for desconhecido, devolve $false ("nao conflita").
    #
    # POR QUE ISSO EXISTE (v13.2): as funcoes que procuram uma faixa "ja pronta"
    # no arquivo olhavam so o CODEC. Num remux Dual Audio a dublagem pt-BR e um
    # AC-3/E-AC-3 perfeitamente valido pelo codec - e era ela que cancelava a
    # conversao do audio original em ingles, virando ainda por cima a faixa
    # padrao. Uma dublagem NAO substitui o audio original: ela e outro idioma.
    param($A, $B)
    $ia = Get-IdiomaFaixa $A
    $ib = Get-IdiomaFaixa $B
    if (-not $ia -or -not $ib) { return $false }
    return ($ia -ne $ib)
}

function Get-FaixaAtmosJocExistente {
    # Retorna a PRIMEIRA faixa (ou $null) que o arquivo JA tiver, em QUALQUER
    # posicao que nao seja a $FaixaExcluir (normalmente a propria faixa
    # TrueHD sendo avaliada), com metadado Atmos/JOC - por exemplo, uma
    # faixa E-AC-3 Atmos que ja veio no proprio release. Nesse caso, converter
    # o TrueHD de novo seria redundante (o objetivo - manter o melhor audio
    # disponivel com Atmos - ja esta atendido). O retorno (objeto ou $null)
    # funciona tanto para checagem booleana (if (...)) quanto para pegar o Id
    # da faixa a manter no remux.
    # O sinal de Atmos vem do MediaInfo e e casado por ORDEM: a i-esima faixa
    # de audio da lista do mkvmerge corresponde ao i-esimo sinal retornado.
    param([string]$MkvPath, $FaixaExcluir)
    # v13.3: quando a escolha manual mandou CONVERTER a principal, nenhuma
    # faixa pronta pode cancelar a conversao - e exatamente o caso Lara
    # Croft, onde o motor reaproveitava uma E-AC-3 de conversao anterior.
    if ((Test-EscolheuConverter $MkvPath) -eq $true) { return $null }
    $json = Get-MkvJson -MkvPath $MkvPath
    if (-not $json) { return $null }
    $sinais = Get-SinaisAtmosMediaInfo -MkvPath $MkvPath
    $audios = @($json.tracks | Where-Object { $_.type -eq "audio" })
    for ($i = 0; $i -lt $audios.Count; $i++) {
        $faixa = $audios[$i]
        if ($FaixaExcluir -and $faixa.id -eq $FaixaExcluir.id) { continue }
        # v13.2: dublagem nao vale como "ja tem Atmos" - ver Test-IdiomaConflitante.
        if (Test-IdiomaConflitante $faixa $FaixaExcluir) { continue }
        $sinalFaixa = if ($i -lt $sinais.Count) { $sinais[$i] } else { $null }
        if (Test-EhAtmosOuJoc $faixa $sinalFaixa) { return $faixa }
    }
    return $null
}

function Get-FaixaCompativelC2Externa {
    # Retorna a PRIMEIRA faixa (ou $null) que o arquivo JA tiver, em QUALQUER
    # posicao que nao seja a $FaixaExcluir (normalmente a propria faixa DTS
    # sendo avaliada) e que NAO seja uma faixa de comentario, com um audio
    # compativel com TVs/soundbars modernas (E-AC-3/AC-3/AAC). Usada para
    # decidir se vale a pena converter um DTS: se ja existe uma faixa assim
    # pronta no arquivo, nao faz sentido gastar tempo convertendo o DTS - o
    # player ja tem uma faixa funcional para usar. O retorno (objeto ou
    # $null) funciona tanto para checagem booleana quanto para pegar o Id.
    param([string]$MkvPath, $FaixaExcluir)
    # v13.3: mesma regra do Get-FaixaAtmosJocExistente - ver la.
    if ((Test-EscolheuConverter $MkvPath) -eq $true) { return $null }
    $json = Get-MkvJson -MkvPath $MkvPath
    if (-not $json) { return $null }
    $audios = @($json.tracks | Where-Object { $_.type -eq "audio" })
    $candidatas = @($audios | Where-Object {
        (-not $FaixaExcluir -or $_.id -ne $FaixaExcluir.id) -and
        (-not (Test-EhFaixaComentario $_)) -and
        (-not (Test-IdiomaConflitante $_ $FaixaExcluir)) -and
        (Test-EhCompativelC2 $_)
    })
    if ($candidatas.Count -gt 0) { return $candidatas[0] }
    return $null
}

function Find-PtBrPgsTrack {
    # Acha a legenda PT-BR "principal" (completa) em PGS - EXCLUINDO
    # explicitamente qualquer faixa marcada como "forcada" (forced_track) e
    # qualquer faixa de COMENTARIO (ex: "Brazilian (Commentary)").
    # Faixas forcadas normalmente so legendam trechos pontuais (ex: dialogos
    # em outro idioma dentro de um filme em ingles) e NAO servem como a
    # legenda completa para assistir o filme/serie - por isso nunca podem
    # virar a faixa "principal" usada para gerar o SRT padrao.
    # BUG CORRIGIDO NA v8.6: um arquivo real (Tomb Raider 2001) tem 3
    # variantes de PGS em portugues - "Brazilian", "Iberian" e "Brazilian
    # (Commentary)". O script escolheu a faixa certa (Brazilian normal),
    # mas por SORTE de ordem no arquivo - nenhuma das funcoes de deteccao de
    # legenda excluia faixas de comentario (so o audio fazia isso, via
    # Test-EhFaixaComentario). Se um dia a faixa de comentario aparecer
    # ANTES da principal no arquivo, o script pegaria a errada para o OCR.
    # Agora reaproveita Test-EhFaixaComentario (funcao generica, olha so o
    # nome da faixa - funciona igual para audio ou legenda) para excluir
    # essas faixas logo na origem, antes de qualquer outra checagem.
    param([string]$MkvPath)
    # v13.3: escolha manual de QUAL faixa PGS vai para o OCR. Mesmo criterio
    # da faixa de audio principal: id que nao existe no arquivo cai na regra
    # normal em vez de devolver nada.
    $escManual = Get-EscolhaManual $MkvPath
    if ($escManual -and $escManual.ContainsKey('LegendaPgs') -and $null -ne $escManual['LegendaPgs']) {
        $jm = Get-MkvJson -MkvPath $MkvPath
        if ($jm) {
            $pgsEscolhida = @($jm.tracks | Where-Object { $_.type -eq "subtitles" -and $_.id -eq $escManual['LegendaPgs'] })
            if ($pgsEscolhida.Count -gt 0) { return $pgsEscolhida[0] }
        }
    }
    $json = Get-MkvJson -MkvPath $MkvPath
    if (-not $json) { return $null }
    $subs = @($json.tracks | Where-Object {
        $_.type -eq "subtitles" -and $_.codec -match "PGS" -and $_.properties.forced_track -ne $true -and
        (-not (Test-EhFaixaComentario $_))
    })
    if ($subs.Count -eq 0) { return $null }
    $explicit = @($subs | Where-Object {
        ($_.properties.language_ietf -match "(?i)^pt-BR") -or
        ($_.properties.track_name -match "(?i)\b(bras|brazil|pt-?br)")
    })
    if ($explicit.Count -gt 0) { return $explicit[0] }
    # Fallback generico: exclui faixas com sinal explicito de serem uma
    # variante NAO-brasileira do portugues (ex: "Portuguese (Iberian)" =
    # Portugal) - senao, se essa fosse a UNICA faixa PGS em portugues
    # generico do arquivo, seria erroneamente tratada como a brasileira.
    # FIX: antes so excluia pelo NOME da faixa ("iberian|portugal|pt-pt").
    # Um arquivo real (The People vs Larry Flynt 1996) tem uma legenda em
    # texto SEM NOME mas com language_ietf explicito "pt-PT" - a exclusao
    # por nome nao pegava esse caso (nome vazio nao bate com nada), entao
    # essa faixa europeia era escolhida como se fosse a brasileira. Agora
    # tambem exclui pelo language_ietf diretamente (metadado real do
    # arquivo, nao depende de nome nenhum).
    $generic = @($subs | Where-Object {
        ($_.properties.language -match "^(por|pt)$" -or $_.properties.language_ietf -match "(?i)^pt") -and
        ($_.properties.track_name -notmatch "(?i)iberian|portugal|\bpt-?pt\b") -and
        ($_.properties.language_ietf -notmatch "(?i)^pt-PT\b")
    })
    if ($generic.Count -eq 1) { return $generic[0] }
    return $null
}

function Test-EhLegendaSDH {
    # Detecta legenda SDH / "hearing impaired" (para surdos - inclui
    # descricoes de som como "[musica tensa]", "[porta batendo]"). O
    # mkvmerge TEM a propriedade oficial flag_hearing_impaired, mas ela
    # frequentemente NAO vem preenchida em remuxes de scene groups - por
    # isso a checagem olha tambem o NOME da faixa (ex: "English SDH",
    # "English (SDH)", "Hearing Impaired"), que e como a maioria dos
    # remuxes de fato sinaliza SDH.
    param($Track)
    if (-not $Track) { return $false }
    if ($Track.properties.flag_hearing_impaired -eq $true) { return $true }
    return ($Track.properties.track_name -match "(?i)\bSDH\b|hearing.?impaired|deaf")
}

function Get-RotuloFaixa {
    # Retorna um rotulo curto e legivel de uma faixa (audio ou legenda) a
    # partir do seu Id - usado para montar mensagens de console que mostram
    # EXATAMENTE quais faixas sobreviveram ao descarte, sem precisar repetir
    # a logica de deteccao. Prioriza o "track_name" (nome dado pelo proprio
    # remux, normalmente o mais descritivo); se a faixa nao tiver nome,
    # cai para o codec.
    param([string]$MkvPath, $Id)
    if ($null -eq $Id) { return $null }
    $json = Get-MkvJson -MkvPath $MkvPath
    if (-not $json) { return $null }
    $t = $json.tracks | Where-Object { $_.id -eq $Id } | Select-Object -First 1
    if (-not $t) { return $null }
    if (-not [string]::IsNullOrWhiteSpace($t.properties.track_name)) { return $t.properties.track_name }
    return $t.codec
}

function Get-FaixaLegendaPtBrTexto {
    # Acha uma legenda PT-BR que JA esteja em formato de TEXTO (SRT, ASS/SSA,
    # etc - qualquer coisa que NAO seja imagem/PGS/VobSub). Nesses casos NAO
    # e preciso rodar OCR nenhum - a faixa ja esta pronta para uso direto, e
    # usar ela e ate MELHOR do que gerar uma nova via OCR (OCR pode errar
    # caracteres; uma legenda de texto nativa e sempre exata). Mesma logica
    # de prioridade da Find-PtBrPgsTrack: nome/idioma explicito pt-BR
    # primeiro, senao idioma generico portugues (so se houver exatamente uma
    # faixa E ela nao tiver nenhum sinal de ser uma variante NAO-brasileira
    # do portugues). Exclui faixas forcadas (nunca vira a "principal").
    # BUG CORRIGIDO NA v8.6: mesma correcao aplicada a Find-PtBrPgsTrack -
    # agora tambem exclui faixas de COMENTARIO (ex: "Brazilian (Commentary)")
    # do candidato a legenda PT-BR em texto, reaproveitando
    # Test-EhFaixaComentario (generica, olha so o nome da faixa).
    param([string]$MkvPath)
    $json = Get-MkvJson -MkvPath $MkvPath
    if (-not $json) { return $null }
    $subs = @($json.tracks | Where-Object {
        $_.type -eq "subtitles" -and
        ($_.codec -notmatch "(?i)PGS|VobSub") -and
        ($_.properties.forced_track -ne $true) -and
        (-not (Test-EhFaixaComentario $_))
    })
    if ($subs.Count -eq 0) { return $null }
    $explicit = @($subs | Where-Object {
        ($_.properties.language_ietf -match "(?i)^pt-BR") -or
        ($_.properties.track_name -match "(?i)\b(bras|brazil|pt-?br)")
    })
    if ($explicit.Count -gt 0) {
        # FIX: entre as explicitas, prioriza a que NAO for SDH - um arquivo
        # com duas variantes PT-BR explicitas (normal + "(SDH)") so escolhia
        # a primeira na ordem do arquivo (sorte de ordem), mesma classe do
        # bug de comentario ja corrigido na v8.6. Test-EhLegendaSDH usa o
        # metadado real flag_hearing_impaired quando disponivel, alem do
        # nome, entao isso tambem segue a diretriz de preferir conteudo real.
        $explicitNaoSdh = @($explicit | Where-Object { -not (Test-EhLegendaSDH $_) })
        if ($explicitNaoSdh.Count -gt 0) { return $explicitNaoSdh[0] }
        return $explicit[0]
    }
    # Fallback generico: BUG CORRIGIDO - antes, se so houvesse UMA faixa de
    # texto em portugues generico ("por"/"pt"), o codigo assumia (sem
    # verificar mais nada) que era a brasileira. Isso e ERRADO quando essa
    # unica faixa e explicitamente de outra variante (ex: "Portuguese
    # (Iberian)" = Portugal, nao Brasil). Agora essas faixas sao excluidas
    # do fallback - nesses casos a funcao retorna $null e o processamento
    # cai para a checagem de PGS (que costuma identificar a faixa
    # brasileira corretamente pelo nome/idioma explicito).
    # FIX: um arquivo real (The People vs Larry Flynt 1996) tem uma legenda
    # de texto SEM NOME mas com language_ietf explicito "pt-PT" - a exclusao
    # antiga so olhava o nome (vazio, nao pegava nada), entao essa faixa
    # europeia foi escolhida por engano como se fosse a brasileira (bug
    # confirmado em log real). Agora tambem exclui pelo language_ietf.
    $generic = @($subs | Where-Object {
        ($_.properties.language -match "^(por|pt)$" -or $_.properties.language_ietf -match "(?i)^pt") -and
        ($_.properties.track_name -notmatch "(?i)iberian|portugal|\bpt-?pt\b") -and
        ($_.properties.language_ietf -notmatch "(?i)^pt-PT\b")
    })
    if ($generic.Count -eq 1) { return $generic[0] }
    return $null
}

function Get-MotivoSemLegendaPtBr {
    <#  v14.21: POR QUE NAO ACHOU A LEGENDA PT-BR.
        Ate a 14.20 o motor dizia "Nenhuma Legenda PT-BR (PGS ou Texto) foi
        Identificada" e parava por ai. No Fallout S02E04 (log 19/08 15h05) o
        arquivo TEM uma faixa marcada "Portugues" na lista - entao a frase le
        como se o motor tivesse ficado cego. Ele nao ficou: recusou por um
        motivo, e o motivo estava so na cabeca do codigo.
        Esta funcao refaz as mesmas perguntas dos seletores e devolve o que
        encontrou e por que cada candidata caiu fora. Nao decide nada - so
        explica a decisao que ja foi tomada.
        Regra do projeto: quem afirma tem que mostrar em que se baseou. #>
    param([string]$MkvPath)
    $json = Get-MkvJson -MkvPath $MkvPath
    if (-not $json) { return "nao foi possivel reler as faixas do arquivo para explicar" }
    $emPortugues = @($json.tracks | Where-Object {
        $_.type -eq "subtitles" -and (
            ("$($_.properties.language)" -match "^(por|pt)$") -or
            ("$($_.properties.language_ietf)" -match "(?i)^pt") -or
            ("$($_.properties.track_name)" -match "(?i)portug|brasil|brazil")
        )
    })
    if ($emPortugues.Count -eq 0) {
        return "este arquivo nao tem NENHUMA faixa de legenda em portugues"
    }
    $motivos = New-Object System.Collections.ArrayList
    $candidatas = 0
    foreach ($t in $emPortugues) {
        $nome = "$($t.properties.track_name)"
        $ietf = "$($t.properties.language_ietf)"
        $como = if ($nome) { $nome } elseif ($ietf) { $ietf } else { "$($t.properties.language)" }
        $rot = "faixa $($t.id) '$como'"
        if ($t.properties.forced_track -eq $true) {
            [void]$motivos.Add("$rot e FORCADA (so traduz trechos em outra lingua, nao serve de principal)")
        } elseif (Test-EhFaixaComentario $t) {
            [void]$motivos.Add("$rot e faixa de COMENTARIO")
        } elseif ($ietf -match "(?i)^pt-PT\b" -or $nome -match "(?i)iberian|portugal|\bpt-?pt\b") {
            [void]$motivos.Add("$rot e portugues de PORTUGAL, nao do Brasil")
        } else {
            $candidatas++
            [void]$motivos.Add("$rot esta em portugues GENERICO ('por'), sem dizer se e do Brasil")
        }
    }
    $texto = ($motivos -join " | ")
    if ($candidatas -gt 1) {
        # Este e o caso em que o motor PODERIA ter escolhido e nao escolheu de
        # proposito: com duas ou mais genericas, pegar uma seria chute.
        $texto += " -> sao $candidatas faixas genericas e nenhuma se identifica como brasileira; escolher uma seria chute, entao nenhuma foi usada"
    }
    return $texto
}

function Get-FaixaLegendaIngles {
    # Acha a legenda em ingles COMPLETA do arquivo (a que serve para
    # assistir), em QUALQUER formato (PGS ou texto/SRT/ASS) - usada para
    # decidir qual legenda inglesa e mantida no remux final (sem conversao,
    # so copiada como esta). Prioridade:
    #   1) Ingles nao-forcada e nao-SDH (a legenda completa "normal").
    #   2) Se nao houver, ingles nao-forcada mesmo que SDH (melhor SDH do
    #      que nenhuma legenda inglesa).
    #   3) Se nao houver, a primeira ingles qualquer (ate forcada) - ultimo
    #      recurso, so para nao descartar 100% do ingles quando so existe
    #      uma faixa forcada.
    param([string]$MkvPath)
    # Exclui faixas de COMENTARIO (ex: "English (Commentary)") logo na origem -
    # mesma protecao aplicada aos seletores de PT-BR e de audio (v8.6). Sem
    # isso, se uma legenda inglesa de comentario aparecesse antes da normal no
    # arquivo, ela poderia ser escolhida por engano como "a legenda inglesa a
    # manter" no remux final.
    $json = Get-MkvJson -MkvPath $MkvPath
    if (-not $json) { return $null }
    $ingles = @($json.tracks | Where-Object {
        $_.type -eq "subtitles" -and
        ($_.properties.language -match "^(eng|en)$" -or $_.properties.language_ietf -match "(?i)^en") -and
        (-not (Test-EhFaixaComentario $_))
    })
    if ($ingles.Count -eq 0) { return $null }

    $completa = @($ingles | Where-Object {
        ($_.properties.forced_track -ne $true) -and (-not (Test-EhLegendaSDH $_))
    })
    if ($completa.Count -gt 0) { return $completa[0] }

    $naoForcada = @($ingles | Where-Object { $_.properties.forced_track -ne $true })
    if ($naoForcada.Count -gt 0) { return $naoForcada[0] }

    return $ingles[0]
}

function Get-InfoDolbyVision {
    # Le os metadados completos do Dolby Vision (perfil, level, camadas
    # presentes e compatibilidade) do side-data do stream de video, via
    # ffprobe, e monta os nomes tecnicos padronizados:
    #   - Codec:   "dvhe.07.06" (dvhe.0<perfil>.0<level>)
    #   - Camadas: "BL+EL+RPU" (conforme flags bl/el/rpu do arquivo)
    #   - Nome:    "Profile 7.6" (perfil.level) ou "Profile 8.1" (perfil 8
    #              usa o bl_signal_compatibility_id, convencao da comunidade)
    # Usado apenas no diagnostico informativo - a conversao (dovi_tool)
    # lida com qualquer perfil de origem automaticamente.
    param([string]$MkvPath)
    # Cache por arquivo: esta funcao e chamada 2x por episodio (uma no
    # diagnostico previo informativo, outra na etapa [1/7] que decide se o
    # arquivo e um DV valido e alimenta a [3/7]). Como o resultado e o mesmo,
    # a segunda chamada reaproveita o cache em vez de reabrir o .mkv - mesmo
    # padrao de Get-MkvJson. O cache guarda tambem os "misses" (resultado
    # $null) para nao re-tentar um arquivo sem DV.
    if ($script:CacheInfoDVPath -eq $MkvPath) { return $script:CacheInfoDV }
    $script:CacheInfoDVPath = $MkvPath
    try {
        $jsonRaw = & $ffprobe -v quiet -print_format json -show_streams -select_streams v:0 "$MkvPath" 2>$null
        if (-not $jsonRaw) { $script:CacheInfoDV = $null; return $null }
        $json = $jsonRaw | ConvertFrom-Json
        $sideData = @($json.streams[0].side_data_list | Where-Object { $_.side_data_type -match "(?i)dovi|dolby vision" })
        if ($sideData.Count -eq 0) { $script:CacheInfoDV = $null; return $null }
        $dv = $sideData[0]

        $perfil = [int]$dv.dv_profile
        $level  = [int]$dv.dv_level
        $compat = [int]$dv.dv_bl_signal_compatibility_id

        $camadasLista = @()
        if ([int]$dv.bl_present_flag -eq 1)  { $camadasLista += "BL" }
        if ([int]$dv.el_present_flag -eq 1)  { $camadasLista += "EL" }
        if ([int]$dv.rpu_present_flag -eq 1) { $camadasLista += "RPU" }
        $camadas = $camadasLista -join "+"

        $codec = "dvhe.{0:D2}.{1:D2}" -f $perfil, $level

        # Perfil 8 usa a convencao "8.<compat_id>" (ex: 8.1); os demais usam
        # "<perfil>.<level>" (ex: 7.6, 5.6).
        $nome = if ($perfil -eq 8) { "Profile 8.$compat" } else { "Profile $perfil.$level" }

        $script:CacheInfoDV = [PSCustomObject]@{
            Perfil  = $perfil
            Level   = $level
            Compat  = $compat
            Codec   = $codec
            Camadas = $camadas
            Nome    = $nome
        }
        return $script:CacheInfoDV
    } catch { $script:CacheInfoDV = $null; return $null }
}

function Format-Tamanho($Bytes) {
    # FIX (v9.0): usa o valor ABSOLUTO para escolher a unidade (GB/MB/KB),
    # preservando o sinal no resultado - sem isso, um valor negativo (ex: o
    # "Espaco Livre Apos a Conversao" pode dar negativo quando nao ha espaco
    # suficiente) caia sempre no ramo de KB e mostrava um numero gigante e
    # confuso em vez de, por exemplo, "-4,88 GB".
    $abs = [math]::Abs($Bytes)
    if ($abs -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($abs -ge 1MB) { return "{0:N0} MB" -f ($Bytes / 1MB) }
    return "{0:N0} KB" -f ($Bytes / 1KB)
}

function Format-Duracao($Segundos) {
    $t = [TimeSpan]::FromSeconds($Segundos)
    # Acima de 1 hora, mostra "1h 24m 10s"; abaixo, mantem "24m 10s".
    if ($t.TotalHours -ge 1) {
        return "{0}h {1:D2}m {2:D2}s" -f [int][math]::Floor($t.TotalHours), $t.Minutes, $t.Seconds
    }
    # BUG CORRIGIDO NA v11.2 (achado conferindo um log real): aqui estava
    # [int]$t.TotalMinutes. No PowerShell o cast [int] ARREDONDA, nao trunca -
    # entao 53 segundos (0,88 minuto) virava [int]0,88 = 1 e a linha saia como
    # "01m 53s", inflando o valor em um minuto inteiro sempre que a parte de
    # segundos passava de 30. Era por isso que a soma das etapas nao batia com
    # o tempo total do episodio: "01m 59s" eram 59s e "01m 53s" eram 53s.
    # [math]::Floor trunca de verdade e resolve para todos os casos.
    return "{0:D2}m {1:D2}s" -f [int][math]::Floor($t.TotalMinutes), $t.Seconds
}

function Get-ResumoErro {
    # Filtra o texto de saida de uma ferramenta (ex: DeeZy) para uso em
    # mensagens de erro/resumo. Remove linhas de progresso repetitivas
    # (ex: "truehdd (1 of 3)  45.3%", "DEE encode (3 of 3) 100.0%") que
    # nao agregam nada ao diagnostico e so poluem o log/resumo final -
    # mantem apenas as linhas com informacao real (avisos, erros).
    param([string[]]$Linhas, [string]$TextoErro = "", [int]$MaxChars = 500)
    $relevantes = @()
    if ($Linhas) {
        $relevantes = @($Linhas | Where-Object {
            $_ -and ($_.Trim()) -and
            ($_ -notmatch '^\s*\S+\s*\(\d+\s+of\s+\d+\)\s+[\d.]+%\s*$') -and  # progresso do DeeZy: "truehdd (1 of 3) 45.3%"
            ($_ -notmatch '^\s*[a-z_]+=\S*\s*$')                               # progresso do ffmpeg (-progress): "out_time_ms=...", "frame=..."
        })
    }
    $texto = (($relevantes -join " | ") + " " + $TextoErro).Trim(" |")
    $texto = $texto.Trim()
    if ([string]::IsNullOrWhiteSpace($texto)) { return "" }
    # Encurta caminhos completos do Windows (ex: "C:\Users\...\arquivo.ec3")
    # para so o nome do arquivo/pasta final (ex: "...\arquivo.ec3"). Caminhos
    # longos sao a maior fonte de poluicao visual nas mensagens de erro do
    # DEE/DeeZy - o nome do arquivo sozinho ja identifica o problema.
    $texto = $texto -replace '[A-Za-z]:\\(?:[^\\/:*?"<>|\r\n]+\\)*([^\\/:*?"<>|\r\n]+)', '...\$1'
    if ($texto.Length -gt $MaxChars) {
        # mantem o FINAL do texto (onde geralmente esta o erro fatal real),
        # nao o inicio (que costuma ser so avisos preliminares)
        $texto = "(...) " + $texto.Substring($texto.Length - $MaxChars)
    }
    return $texto
}

function Say-TempoEtapa($Inicio) {
    $decorrido = (Get-Date) - $Inicio
    Say ("        Tempo da etapa: {0}" -f (Format-Duracao $decorrido.TotalSeconds)) "DarkGray"
}

function ConvertTo-ArgString($ArgsArray) {
    # Monta a linha de comando seguindo as regras REAIS de quoting do Windows
    # (CommandLineToArgvW). O jeito antigo (so trocar " por \") quebrava em
    # dois casos comuns:
    #   1. Caminhos que terminam em "\" (ex: "C:\pasta\") - o \ final escapava
    #      a aspa de fechamento e embaralhava todos os argumentos seguintes.
    #   2. Barras invertidas antes de aspas em geral.
    # Aqui cada argumento e sempre envolvido em aspas, as barras invertidas que
    # antecedem uma aspa (ou o fim do argumento) sao duplicadas, e as aspas
    # internas viram \". Isso e o comportamento correto e a prova de caminhos
    # com espacos, &, %, etc.
    $partes = foreach ($a in $ArgsArray) {
        $s = [string]$a
        $sb = New-Object System.Text.StringBuilder
        [void]$sb.Append('"')
        $barras = 0
        foreach ($ch in $s.ToCharArray()) {
            if ($ch -eq '\') {
                $barras++
            } elseif ($ch -eq '"') {
                [void]$sb.Append('\' * ($barras * 2 + 1))
                [void]$sb.Append('"')
                $barras = 0
            } else {
                if ($barras -gt 0) { [void]$sb.Append('\' * $barras); $barras = 0 }
                [void]$sb.Append($ch)
            }
        }
        # barras invertidas no fim do argumento: dobra para nao escapar a aspa final
        if ($barras -gt 0) { [void]$sb.Append('\' * ($barras * 2)) }
        [void]$sb.Append('"')
        $sb.ToString()
    }
    return ($partes -join ' ')
}

# ---- processo com barra baseada em tempo estimado (sem sinal real de % ) ---
# usado para ffprobe/dovi_tool, que nao expoe progresso - a barra sobe de
# forma suave (curva assintotica ate ~99%) conforme o tempo estimado passa,
# e so fecha em 100% quando o processo realmente termina.
function Invoke-ProcessoComBarraEstimada {
    param([string]$Exe, [string[]]$ArgList, [double]$EstimativaSegundos = 4)
    $tmpOut = [System.IO.Path]::GetTempFileName()
    $tmpErr = [System.IO.Path]::GetTempFileName()
    try {
        $proc = Start-Process -FilePath $Exe -ArgumentList (ConvertTo-ArgString $ArgList) `
            -NoNewWindow -PassThru -RedirectStandardOutput $tmpOut -RedirectStandardError $tmpErr
        # Acessar .Handle logo apos iniciar "prende" o handle do processo com as
        # permissoes certas - sem isso, .ExitCode pode voltar vazio/incorreto
        # em alguns ambientes Windows (bug conhecido do Process do .NET).
        $null = $proc.Handle
        Adotar-Processo $proc
        Reduzir-PrioridadeProcesso $proc

        $tIni = Get-Date
        $script:SegundosPausadosEtapa = 0.0
        while (-not $proc.HasExited) {
            Invoke-ControlesTeclado $proc
            if ($script:CancelamentoSolicitado) { break }
            # Desconta o tempo em que o processo ficou pausado ([F1]), senao a
            # barra "saltaria" ao retomar - o progresso estimado deve refletir
            # so o tempo em que o processo realmente esteve trabalhando.
            $decorrido = ((Get-Date) - $tIni).TotalSeconds - $script:SegundosPausadosEtapa
            if ($decorrido -lt 0) { $decorrido = 0 }
            # Curva assintotica: sobe rapido no comeco e vai se aproximando de
            # 99% aos poucos, MAS NUNCA TRAVA - continua subindo (95, 96, 97...)
            # por mais tempo que o processo real demore, em vez de bater um
            # teto fixo e ficar parada esperando terminar.
            $pct = 99 * (1 - [math]::Exp(-$decorrido / $EstimativaSegundos))
            Show-Barra $pct
            Start-Sleep -Milliseconds 150
        }
        $proc.WaitForExit()
        # v14.18: a barra cheia so e desenhada se o processo terminou BEM.
        # Antes ela era desenhada sempre, entao uma falha do dovi_tool ou do
        # ffmpeg aparecia como barra verde em 100% com a mensagem de erro
        # vermelha logo abaixo - a tela dizia "terminou" e "falhou" ao mesmo
        # tempo.
        $exitCode = -1
        try { $exitCode = $proc.ExitCode } catch { $exitCode = -1 }
        if ($exitCode -eq 0) { Show-BarraCompleta }

        $saida = @()
        if (Test-Path -LiteralPath $tmpOut) { $saida = @(Get-Content -LiteralPath $tmpOut -Encoding UTF8) }
        $erro = ""
        if (Test-Path -LiteralPath $tmpErr) { $erro = (Get-Content -LiteralPath $tmpErr -Encoding UTF8 -Raw) }
        return @{ ExitCode = $exitCode; Output = $saida; ErrorText = $erro }
    } finally {
        Remove-Item -LiteralPath $tmpOut -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tmpErr -Force -ErrorAction SilentlyContinue
    }
}

# ---- ffmpeg com barra real baseada em -progress -----------------------------
function Invoke-FfmpegComBarra {
    param([string[]]$ArgList, [double]$DuracaoTotalSeg)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ffmpeg
    $psi.Arguments = ConvertTo-ArgString $ArgList
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow  = $true
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    $sync = [hashtable]::Synchronized(@{ OutSeg = 0.0; Linhas = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList)) })
    $onData = {
        if ($EventArgs.Data) {
            $linha = $EventArgs.Data
            $Event.MessageData.Linhas.Add($linha)
            if ($linha -match 'out_time_ms=(\d+)') {
                $Event.MessageData.OutSeg = [double]$Matches[1] / 1000000.0
            }
        }
    }
    $subOut = Register-ObjectEvent -InputObject $proc -EventName OutputDataReceived -Action $onData -MessageData $sync
    $subErr = Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived  -Action $onData -MessageData $sync

    $proc.Start() | Out-Null
    # Acessar .Handle logo apos iniciar "prende" o handle do processo com as
    # permissoes certas - sem isso, .ExitCode pode voltar vazio/incorreto em
    # alguns ambientes Windows (mesma protecao usada nas demais Invoke-*).
    $null = $proc.Handle
    Adotar-Processo $proc
    Reduzir-PrioridadeProcesso $proc
    $proc.BeginOutputReadLine()
    $proc.BeginErrorReadLine()

    while (-not $proc.HasExited) {
        Invoke-ControlesTeclado $proc
        if ($script:CancelamentoSolicitado) { break }
        $pct = 0
        if ($DuracaoTotalSeg -gt 0) { $pct = 100 * $sync.OutSeg / $DuracaoTotalSeg }
        Show-Barra $pct
        Start-Sleep -Milliseconds 200
    }
    $proc.WaitForExit()
    Unregister-Event -SourceIdentifier $subOut.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $subErr.Name -ErrorAction SilentlyContinue
    Remove-Job -Name $subOut.Name -ErrorAction SilentlyContinue
    Remove-Job -Name $subErr.Name -ErrorAction SilentlyContinue
    Show-BarraCompleta
    # ErrorText incluido (vazio) so para uniformizar o retorno com as outras
    # Invoke-* - o stderr do ffmpeg ja vem capturado dentro de Output (o mesmo
    # handler de evento coleta stdout e stderr na mesma lista de linhas).
    return @{ ExitCode = $proc.ExitCode; Output = $sync.Linhas; ErrorText = "" }
}

<#  DeeZy com barra REAL baseada nas fases que a propria ferramenta reporta.
    O DeeZy roda em fases sequenciais: "truehdd (1 of 3) XX.X%",
    "DEE measure (2 of 3) XX.X%", "DEE encode (3 of 3) XX.X%".

    v14.14 - O PESO 80/10/10 ESTAVA ERRADO, E FOI CHUTE DESDE O COMECO.
    A versao anterior dava 80% da barra pra PRIMEIRA fase e dividia os 20%
    restantes entre as outras, com a justificativa (escrita aqui mesmo) de que
    "as fases de medicao e codificacao do DEE costumam ser rapidas em
    comparacao (segundos, nao minutos)". Isso nunca foi medido - e o usuario
    mediu, olhando a tela: a barra ia ate 80% num ritmo, e dos 80% em diante
    arrastava; de 92% para 94% levava minutos.
    Nao e a maquina e nao e o disco. O TEMPO TOTAL e o mesmo: e a barra que
    reservava 10% pra uma fase que consome uma fatia grande do trabalho.
    E o MESMO defeito que ja apareceu duas vezes neste projeto - peso fixo
    baseado em suposicao, em vez de medida: primeiro nas 7 etapas (a etapa de
    audio com 1/7 da regua carregando 80% do trabalho), depois nas
    sub-etapas da legenda (o Reocr com 5% da barra pra 43% do trabalho).
    Terceira vez, mesma causa.

    A CORRECAO NAO E OUTRO CHUTE. Em vez de um peso fixo qualquer, cada fase
    passa a valer o mesmo pedaco da barra (1/N), e o pedaco da fase que esta
    rodando e preenchido pelo percentual que o proprio DeeZy informa. Ou seja:
    a barra passa a andar com o que a ferramenta DIZ, e nao com o que o motor
    ACHA que ela vai demorar.
    Isso nao promete que cada fase leve o mesmo tempo - promete que a barra
    nao vai mais concentrar 80% de si mesma numa fase e espremer o resto. Se
    uma fase for mais lenta, ela anda mais devagar DENTRO do pedaco dela, o
    que e visivel e honesto; antes ela andava devagar num pedaco de 10%, o
    que parecia travamento.
    O teto duro tambem entra aqui: enquanto o processo estiver vivo a barra
    para em 99%. Quem escreve 100% e o fim da funcao.
#>
function Invoke-DeezyComBarra {
    param([string[]]$ArgList)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $deezy
    $psi.Arguments = ConvertTo-ArgString $ArgList
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow  = $true
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    $sync = [hashtable]::Synchronized(@{
        FaseAtual = 0; FaseTotal = 0; FasePct = 0.0
        Linhas = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
    })
    $onData = {
        if ($EventArgs.Data) {
            $linha = $EventArgs.Data
            $Event.MessageData.Linhas.Add($linha)
            if ($linha -match '\((\d+)\s+of\s+(\d+)\)\s+([\d.]+)%') {
                $Event.MessageData.FaseAtual = [int]$Matches[1]
                $Event.MessageData.FaseTotal = [int]$Matches[2]
                $Event.MessageData.FasePct   = [double]$Matches[3]
            }
        }
    }
    $subOut = Register-ObjectEvent -InputObject $proc -EventName OutputDataReceived -Action $onData -MessageData $sync
    $subErr = Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived  -Action $onData -MessageData $sync

    $proc.Start() | Out-Null
    $null = $proc.Handle
    Adotar-Processo $proc
    Reduzir-PrioridadeProcesso $proc
    $proc.BeginOutputReadLine()
    $proc.BeginErrorReadLine()

    $tIni = Get-Date
    $script:UltimoPctDeezy = 0.0
    while (-not $proc.HasExited) {
        Invoke-ControlesTeclado $proc
        if ($script:CancelamentoSolicitado) { break }
        $pct = 0.0
        if ($sync.FaseTotal -gt 0) {
            # fase N de M, com o pedaco da fase atual preenchido pelo % que o
            # proprio DeeZy informa. Cada fase vale 1/M da barra.
            $iFase = [math]::Max(1, [int]$sync.FaseAtual)
            $nFases = [math]::Max(1, [int]$sync.FaseTotal)
            if ($iFase -gt $nFases) { $iFase = $nFases }
            $dentro = [math]::Max(0.0, [math]::Min(100.0, [double]$sync.FasePct)) / 100.0
            $pct = 100.0 * (($iFase - 1) + $dentro) / $nFases
        } else {
            # Ainda sem nenhuma leitura de fase (DeeZy ainda inicializando/
            # extraindo) - sobe bem devagar so para indicar atividade real.
            $decorrido = ((Get-Date) - $tIni).TotalSeconds
            $pct = [math]::Min(5, $decorrido / 2)
        }
        # teto duro: 100% so quando o processo sair de verdade
        if ($pct -gt 99.0) { $pct = 99.0 }
        # e nunca pra tras - o DeeZy repete a linha da fase anterior as vezes
        if ($pct -lt $script:UltimoPctDeezy) { $pct = $script:UltimoPctDeezy }
        $script:UltimoPctDeezy = $pct
        Show-Barra $pct
        Start-Sleep -Milliseconds 200
    }
    $proc.WaitForExit()
    Unregister-Event -SourceIdentifier $subOut.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $subErr.Name -ErrorAction SilentlyContinue
    Remove-Job -Name $subOut.Name -ErrorAction SilentlyContinue
    Remove-Job -Name $subErr.Name -ErrorAction SilentlyContinue
    Show-BarraCompleta
    return @{ ExitCode = $proc.ExitCode; Output = $sync.Linhas; ErrorText = "" }
}

function Invoke-MkvMergeComProgresso {
    param([string[]]$ArgList)
    $fullArgs = @("--gui-mode") + $ArgList
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $mkvmerge
    $psi.Arguments = ConvertTo-ArgString $fullArgs
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow  = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    # "Prende" o handle logo apos iniciar (evita .ExitCode vazio/incorreto em
    # alguns ambientes Windows) - mesma protecao usada nas demais Invoke-*.
    $null = $proc.Handle
    Adotar-Processo $proc
    Reduzir-PrioridadeProcesso $proc

    <#  v14.26: DEADLOCK DE PIPE NO STDERR - O MESMO DEFEITO DE 6 HORAS, VIVO.
        Esta funcao redireciona stdout E stderr, le o stdout num laco
        bloqueante e so chamava ReadToEnd() no stderr DEPOIS do laco.
        O pipe do Windows tem ~4 KB: se o mkvmerge escrever mais que isso no
        stderr durante o remux, ele BLOQUEIA escrevendo no stderr, para de
        emitir "#GUI#progress" no stdout, e o laco abaixo espera para sempre.
        Programa congelado no meio da [5/5], a 0% de CPU - exatamente o
        sintoma que a regra do projeto descreve e que ja custou 6 horas
        paradas no Homem-Aranha. A regra existia; esta funcao escapou dela.

        REPRODUZIDO EM BANCADA antes de corrigir: processo que escreve 60 mil
        linhas no stderr e progresso no stdout.
            lendo so o stdout (como estava) : TRAVOU apos 3 linhas
            drenando o stderr junto         : terminou, 121 linhas

        Correcao: o stderr passa a ser drenado de forma assincrona, por
        evento, desde antes do laco. Nao da para usar BeginErrorReadLine aqui
        porque o stdout e lido de forma SINCRONA (ReadLine, que este laco
        precisa para responder as teclas) e o .NET nao deixa misturar os dois
        modos no mesmo processo. Por isso o dreno vai num Runspace proprio:
        ele so consome o pipe e guarda as linhas, sem tocar no stdout. #>
    $errBuffer = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
    $psDreno = [PowerShell]::Create()
    $null = $psDreno.AddScript({
        param($fluxo, $destino)
        try {
            while ($null -ne ($l = $fluxo.ReadLine())) { [void]$destino.Add($l) }
        } catch { }
    }).AddArgument($proc.StandardError).AddArgument($errBuffer)
    $drenoHandle = $psDreno.BeginInvoke()

    $outrasLinhas = New-Object System.Collections.Generic.List[string]
    while (-not $proc.StandardOutput.EndOfStream) {
        $line = $proc.StandardOutput.ReadLine()
        if ($line -match '#GUI#progress\s+(\d+)%') {
            Show-Barra ([int]$Matches[1])
        } elseif ($line.Trim()) {
            $outrasLinhas.Add($line)
        }
        # Aqui a checagem de teclas fica APOS a leitura da linha (e nao no topo
        # do loop como nas outras etapas) porque ReadLine() e bloqueante: o
        # controle so pode ser processado quando o mkvmerge devolve alguma
        # linha. Como ele emite "#GUI#progress" a todo instante durante o
        # remux, na pratica a resposta continua imediata.
        Invoke-ControlesTeclado $proc
        if ($script:CancelamentoSolicitado) { break }
    }
    <#  O stderr ja foi todo consumido pelo dreno; aqui so se espera ele
        fechar e se junta o que foi guardado. WaitForExit vem antes do
        EndInvoke para o processo poder fechar o pipe e o dreno sair do
        ReadLine sozinho. #>
    $proc.WaitForExit()
    try { $null = $psDreno.EndInvoke($drenoHandle) } catch { }
    try { $psDreno.Dispose() } catch { }
    $stderrTxt = (@($errBuffer) -join "`r`n")
    Show-BarraCompleta

    if ($proc.ExitCode -ge 2) {
        SayErr "O mkvmerge Reportou Erro (Codigo $($proc.ExitCode)):"
        foreach ($l in $outrasLinhas) { Say "        $l" "Red" }
        if ($stderrTxt.Trim()) { Say "        $stderrTxt" "Red" }
    } elseif ($proc.ExitCode -eq 1 -and $outrasLinhas.Count -gt 0) {
        SayWarn "O mkvmerge Terminou com Avisos:"
        foreach ($l in $outrasLinhas) { Say "        $l" "Yellow" }
    }
    return $proc.ExitCode
}

function Invoke-PgsToSrtComProgresso {
    param([string[]]$ArgList)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $pgsToSrt
    $psi.Arguments = ConvertTo-ArgString $ArgList
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow  = $true
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    $sync = [hashtable]::Synchronized(@{ Total = 0; Feitos = 0; Linhas = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList)) })
    $onData = {
        if ($EventArgs.Data) {
            $linha = $EventArgs.Data
            $Event.MessageData.Linhas.Add($linha)
            if ($linha -match 'for (\d+) items') {
                $Event.MessageData.Total = [int]$Matches[1]
            } elseif ($Event.MessageData.Total -gt 0 -and
                      $Event.MessageData.Feitos -lt $Event.MessageData.Total) {
                # v14.18: contava QUALQUER linha, e o mesmo tratador esta
                # registrado no stdout E no stderr - aviso do Tesseract virava
                # "item concluido". Feitos passava de Total e a barra encostava
                # no teto da faixa antes de o OCR terminar. O teto abaixo nao
                # conserta a contagem, mas impede que ela minta para cima.
                $Event.MessageData.Feitos++
            }
        }
    }
    $subOut = Register-ObjectEvent -InputObject $proc -EventName OutputDataReceived -Action $onData -MessageData $sync
    $subErr = Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived  -Action $onData -MessageData $sync

    $proc.Start() | Out-Null
    # "Prende" o handle logo apos iniciar (evita .ExitCode vazio/incorreto em
    # alguns ambientes Windows) - mesma protecao usada nas demais Invoke-*.
    $null = $proc.Handle
    Adotar-Processo $proc
    Reduzir-PrioridadeProcesso $proc
    $proc.BeginOutputReadLine()
    $proc.BeginErrorReadLine()

    $inicioPgs = Get-Date
    $pausaBasePgs = [double]$script:SegundosPausadosEtapa
    while (-not $proc.HasExited) {
        Invoke-ControlesTeclado $proc
        if ($script:CancelamentoSolicitado) { break }
        # v14.11: este e o UNICO progresso 100% REAL desta etapa - o PgsToSrt
        # anuncia "for N items" e depois uma linha por bloco. Enquanto ele
        # ainda nao anunciou o total, a barra usa a curva suave em vez de
        # ficar zerada (antes ficava em 0% e so aparecia "preparando OCR...").
        if ($sync.Total -gt 0) {
            Show-BarraFaixa (100 * $sync.Feitos / $sync.Total)
        } else {
            Show-BarraFaixa (Get-PctSuave $inicioPgs $pausaBasePgs 20)
        }
        Start-Sleep -Milliseconds 200
    }
    $proc.WaitForExit()
    Unregister-Event -SourceIdentifier $subOut.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $subErr.Name -ErrorAction SilentlyContinue
    Remove-Job -Name $subOut.Name -ErrorAction SilentlyContinue
    Remove-Job -Name $subErr.Name -ErrorAction SilentlyContinue
    Show-BarraFaixaFim
    return @{ ExitCode = $proc.ExitCode; Output = $sync.Linhas }
}

<#  v14.2: Invoke-SeconvOcrComProgresso
    Roda o OCR via seconv/BinaryOCR direto no .mkv. Diferente do PgsToSrt, o
    seconv nao aceita "--output <arquivo exato>" - ele escreve o .srt numa
    pasta (--output-folder) usando o proprio nome do .mkv como base. Por isso
    a funcao roda num subpasta TEMPORARIA isolada (evita pegar .srt de sobra
    de uma rodada anterior por engano) e move/renomeia o resultado pro
    $DestinoSrt esperado. Nao inventa suposicao sobre o nome exato do arquivo
    de saida - so confia no que aparecer sozinho dentro dessa pasta isolada.
#>
function Invoke-SeconvOcrComProgresso {
    # v14.5: ATENCAO - $TrackId aqui e o TrackNumber do MATROSKA (1-based,
    # gravado no cabecalho do .mkv), NAO o "id" do mkvmerge (0-based,
    # posicional). Quem chama e responsavel por converter. Ver o comentario
    # grande no [5/7], onde a conversao acontece.
    param([string]$MkvPath, [int]$TrackId, [string]$DestinoSrt, [string]$IdiomaEsperado = "")

    $tmpDir = Join-Path $WorkDir ("_seconv_tmp_" + [guid]::NewGuid().ToString("N").Substring(0,8))
    [System.IO.Directory]::CreateDirectory($tmpDir) | Out-Null

    $argList = @(
        "$MkvPath", "subrip",
        "--track-number:$TrackId",
        "--ocr-engine:binaryocr",
        "--ocr-db:$seconvDb",
        "--output-folder:$tmpDir",
        "--overwrite"
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $seconv
    $psi.Arguments = ConvertTo-ArgString $argList
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow  = $true
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    $linhas = New-Object System.Collections.ArrayList
    $onData = {
        if ($EventArgs.Data) { [void]$Event.MessageData.Add($EventArgs.Data) }
    }
    $subOut = Register-ObjectEvent -InputObject $proc -EventName OutputDataReceived -Action $onData -MessageData $linhas
    $subErr = Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived  -Action $onData -MessageData $linhas

    $proc.Start() | Out-Null
    $null = $proc.Handle
    Adotar-Processo $proc
    Reduzir-PrioridadeProcesso $proc
    $proc.BeginOutputReadLine()
    $proc.BeginErrorReadLine()

    # v14.11: a barra desta sub-etapa deixou de brigar com o texto. Ate a
    # 14.10 o laco desenhava a barra e, na linha seguinte, escrevia
    # "preparando OCR (seconv/BinaryOCR)..." POR CIMA dela - ou seja, a barra
    # do seconv NUNCA apareceu no console, so o texto piscando. Agora o nome
    # da sub-etapa e dito UMA vez (por quem chama, via SaySub) e o laco cuida
    # so da barra.
    $inicioSeconv = Get-Date
    $pausaBaseSeconv = [double]$script:SegundosPausadosEtapa
    while (-not $proc.HasExited) {
        Invoke-ControlesTeclado $proc
        if ($script:CancelamentoSolicitado) { break }
        # v14.12: 45s era chute. Medido no Troia (log 18/08 15h06-15h11):
        # 4m22s (263s) num filme de 3h16.
        # A curva e 99*(1-e^(-t/EST)), entao ela chega a ~90% da faixa em
        # 2,3*EST. Pra 90% no tempo tipico, EST = tipico/2,3 = 115s. Botar
        # EST = 263 deixaria a barra em 62% quando o trabalho ja acabou.
        Show-BarraFaixa (Get-PctSuave $inicioSeconv $pausaBaseSeconv 115)
        Start-Sleep -Milliseconds 200
    }
    $proc.WaitForExit()
    Unregister-Event -SourceIdentifier $subOut.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $subErr.Name -ErrorAction SilentlyContinue
    Remove-Job -Name $subOut.Name -ErrorAction SilentlyContinue
    Remove-Job -Name $subErr.Name -ErrorAction SilentlyContinue
    Show-BarraFaixaFim

    # v14.5: rede de seguranca de IDIOMA. O seconv nomeia a saida de faixa de
    # container como "<arquivo>.<idioma>.srt" (ResolveOutputFileName no fonte
    # dele), com o idioma vindo do proprio Matroska. Se o idioma esperado veio
    # junto, so aceitamos o .srt que casa com ele. Assim, se o --track-number
    # apontar pra faixa errada por qualquer motivo, o motor RECUSA em vez de
    # entregar legenda em INGLES achando que e a PT-BR - foi exatamente esse o
    # estrago visto no Corretor 2.1 ("Al*ost." no lugar de "Quase."). Recusar
    # aqui e barato: o motor cai sozinho pro PgsToSrt logo abaixo.
    $todosSrt = @(Get-ChildItem -LiteralPath $tmpDir -Filter *.srt -ErrorAction SilentlyContinue)
    $srtGerado = $null
    # v14.10: guardo POR QUE o seconv nao serviu, pra manchete nao mentir.
    # Ver o bloco de comentario perto de "MotivoRecusa" no fim desta funcao.
    $motivoRecusa = ""
    if ($todosSrt.Count -eq 0) { $motivoRecusa = "vazio" }
    if ($todosSrt.Count -gt 0) {
        if ($IdiomaEsperado -ne "") {
            $casam = @($todosSrt | Where-Object { $_.BaseName -match ("(?i)\." + [regex]::Escape($IdiomaEsperado) + "$") })
            if ($casam.Count -gt 0) {
                $srtGerado = $casam[0]
            } elseif ($todosSrt.Count -eq 1 -and $todosSrt[0].BaseName -notmatch "\.[A-Za-z]{2,3}$") {
                # Faixa sem idioma declarado no .mkv: o seconv nao poe sufixo
                # nenhum. Como veio um arquivo so, e o da faixa que pedimos.
                $srtGerado = $todosSrt[0]
            } else {
                [void]$linhas.Add(("recusado pelo motor: esperava idioma '" + $IdiomaEsperado + "', o seconv gerou " + (($todosSrt | ForEach-Object { $_.Name }) -join ", ") + " - faixa errada, nao vou misturar idioma."))
                $motivoRecusa = "idioma"
            }
        } else {
            $srtGerado = $todosSrt[0]
        }
    }

    # v14.6: rede de seguranca de QUALIDADE. A de idioma nao basta.
    # CASO REAL (teste de 12/08 23:07, GoT S08E01): o seconv rodou na faixa
    # CERTA e gerou portugues de verdade - e mesmo assim o resultado era
    # inutilizavel. 951 de 13.322 caracteres (7,1%) sairam como "*", e 378
    # dos 446 blocos (84,8%) tinham pelo menos um.
    # POR QUE: o BinaryOCR e comparacao de BITMAP, nao OCR de verdade. Ele
    # casa o desenho de cada letra contra o banco (Latin.db). Glifo que nao
    # casa vira literalmente "*" - isso esta escrito no fonte do seconv:
    #     if (match == null) { matches.Add(new CompareMatch("*", ...)) }
    # (BinaryOcrOcrEngine.Recognize). E a tolerancia, MaxErrorPercent = 0.5,
    # e um "private const" - nao da pra afrouxar por linha de comando.
    # Neste release o banco nao conhecia o desenho de: m (439x), a-til (124),
    # e-agudo (65), e-circunflexo (51), a-agudo (47), V (35), i-agudo,
    # o-agudo, o-til, a-crase. So o "m" ja destroi a legenda inteira.
    # Ou seja: a qualidade do BinaryOCR depende do banco casar com a FONTE
    # daquele release. Quando casa, e o melhor resultado que existe. Quando
    # nao casa, sai lixo com cara de legenda - e o motor engolia calado.
    # Agora nao mais: se a densidade de "*" passar do limite, RECUSA e cai
    # pro PgsToSrt/Tesseract, que e OCR de verdade e generaliza entre fontes.
    # LIMITE: "*" e raro em legenda legitima (censura tipo "f***"). Exijo os
    # dois ao mesmo tempo pra nao recusar por causa de uma censura pontual:
    # pelo menos 10 asteriscos E mais de 0,5% dos caracteres.
    if ($null -ne $srtGerado) {
        try {
            $conteudoSrt = Get-Content -LiteralPath $srtGerado.FullName -Raw -Encoding UTF8
            $soFalas = @($conteudoSrt -split "`n" | Where-Object {
                $_ -notmatch '-->' -and $_.Trim() -notmatch '^\d+$'
            }) -join ''
            $totalChars = ($soFalas -replace '\s', '').Length
            $asteriscos = ([regex]::Matches($soFalas, '\*')).Count
            if ($totalChars -gt 0) {
                $pctLixo = $asteriscos / $totalChars
                if ($asteriscos -ge 10 -and $pctLixo -gt 0.005) {
                    [void]$linhas.Add(("recusado pelo motor: " + $asteriscos + " de " + $totalChars + " caracteres (" + ([Math]::Round($pctLixo * 100, 1)) + "%) sairam como '*'."))
                    [void]$linhas.Add("o BinaryOCR marca com '*' todo glifo que nao acha no Latin.db - o banco nao casa com a fonte deste release.")
                    [void]$linhas.Add("caindo pro PgsToSrt/Tesseract, que e OCR de verdade e nao depende de banco por fonte.")
                    $srtGerado = $null
                    $motivoRecusa = ("qualidade:" + ([Math]::Round($pctLixo * 100, 1)))
                }
            }
        } catch {
            # nao conseguiu ler pra conferir: nao e motivo pra recusar, o
            # arquivo existe e tem tamanho. Segue com ele.
        }
    }
    $sucesso = $false
    $trocasAcento = 0
    if ($srtGerado -and $srtGerado.Length -gt 0) {
        $trocasAcento = Repara-AcentoBinaryOcr -SrtPath $srtGerado.FullName
        Move-Item -LiteralPath $srtGerado.FullName -Destination $DestinoSrt -Force
        $sucesso = $true
    }
    Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    # v14.10 - MotivoRecusa: a MANCHETE MENTIA.
    # Nos logs de 13/08 (Troia 12:43 e GoT 13:54) o motor imprimia
    #     "[AVISO] seconv Nao Gerou Legenda. Tentando PgsToSrt..."
    # e logo abaixo, em cinza, a verdade:
    #     "seconv: V Conversion completed successfully!"
    #     "seconv: recusado pelo motor: 17715 de 37579 caracteres (47.1%)..."
    # Ou seja: o seconv GEROU a legenda; quem recusou fomos nos, pela taxa de
    # asterisco. Quem le so a linha de destaque entende o oposto do que
    # aconteceu, e vai procurar defeito no seconv que nao existe. Mesma familia
    # dos outros tres casos de "mensagem que mente" que ja fechamos.
    # Agora o motivo sobe junto e a manchete diz qual dos tres foi.
    if (-not $sucesso -and $motivoRecusa -eq "") { $motivoRecusa = "vazio" }
    return @{ ExitCode = $proc.ExitCode; Output = $linhas; Sucesso = $sucesso; TrocasAcento = $trocasAcento; MotivoRecusa = $motivoRecusa }
}

<#  v14.2: Repara-AcentoBinaryOcr
    O motor BinaryOCR do seconv troca sistematicamente a-til/o-til/e-circunflexo por a-agudo/o-agudo/e-agudo
    (confirmado 100% consistente em 82/82 ocorrencias de "na-tilo" no teste real
    de 12/08 - GoT S08E01). Corrige com a MESMA logica segura ja usada no
    Corretor_Legenda para o classico "I lido como l": so troca a palavra pela
    variante com til/circunflexo se essa variante existe no dicionario PT-BR
    E a forma com acento agudo/sem til NAO existe. Nunca troca as cegas.
#>
$script:DicAcentoCache = $null
function Get-DicionarioAcentuado {
    if ($null -ne $script:DicAcentoCache) { return $script:DicAcentoCache }
    $script:DicAcentoCache = New-Object 'System.Collections.Generic.HashSet[string]'
    if ($seconvDic -ne "" -and (Test-Path -LiteralPath $seconvDic)) {
        try {
            $fs = [System.IO.File]::OpenRead($seconvDic)
            $gz = New-Object System.IO.Compression.GZipStream($fs, [System.IO.Compression.CompressionMode]::Decompress)
            $sr = New-Object System.IO.StreamReader($gz, [System.Text.Encoding]::UTF8)
            $conteudo = $sr.ReadToEnd()
            $sr.Close(); $gz.Close(); $fs.Close()
            foreach ($w in ($conteudo -split '\s+')) {
                if ($w) { [void]$script:DicAcentoCache.Add($w) }
            }
        } catch { }
    }
    return $script:DicAcentoCache
}
function Repara-AcentoBinaryOcr {
    param([string]$SrtPath)
    $dic = Get-DicionarioAcentuado
    if ($dic.Count -eq 0) { return 0 }  # dicionario nao disponivel - nao mexe em nada

    # v14.5: BUG REAL, DOIS DE UMA VEZ, NESTA UNICA LINHA. Antes ela era:
    #     $mapa = @{ 'a-agudo'='a-til'; 'A-agudo'='A-til'; ... }  (com as
    #     letras acentuadas escritas literalmente no codigo)
    # (1) ESTE ARQUIVO E SEM BOM (regra do projeto). O Windows PowerShell 5.1
    #     - que e quem roda o motor, via "powershell" no .bat - le arquivo sem
    #     BOM como ANSI/Windows-1252, NAO como UTF-8. Entao cada letra
    #     acentuada escrita literalmente aqui virava DOIS caracteres tortos.
    #     O .srt, ao contrario, e lido com "-Encoding UTF8" explicito, ou
    #     seja: com os acentos CERTOS. As chaves do mapa nunca batiam com
    #     nada. Zero trocas, sempre, sem erro nenhum na tela.
    # (2) @{} no PowerShell cria hashtable CASE-INSENSITIVE. Mesmo com o
    #     encoding certo, 'A-agudo' e 'a-agudo' sao a MESMA chave - e o
    #     proprio parser recusa o literal ("Duplicate keys are not allowed in
    #     hash literals"). No pwsh 7 isso e erro fatal: o motor inteiro nao
    #     carrega. So nao explodiu na sua maquina porque o 5.1 leu tudo como
    #     ANSI e os pares tortos, por acaso, nao colidiram.
    # CORRECAO: Dictionary[string,string] (case-SENSITIVE, ao contrario de
    # @{}) montado por codigo de caractere. Assim este arquivo continua 100%
    # ASCII puro - que e exatamente o que faz a regra "motor sem BOM" ser
    # segura - e o mapa passa a bater com o texto real do .srt.
    # REGRA PRA SEMPRE: nunca escreva letra acentuada literal neste arquivo,
    # nem em codigo nem em comentario. Use [char]0x00XX.
    $mapa = New-Object 'System.Collections.Generic.Dictionary[string,string]'
    $mapa[[string][char]0x00E1] = [string][char]0x00E3   # a-agudo -> a-til
    $mapa[[string][char]0x00C1] = [string][char]0x00C3   # A-agudo -> A-til
    $mapa[[string][char]0x00E9] = [string][char]0x00EA   # e-agudo -> e-circunflexo
    $mapa[[string][char]0x00C9] = [string][char]0x00CA   # E-agudo -> E-circunflexo
    $mapa[[string][char]0x00F3] = [string][char]0x00F5   # o-agudo -> o-til
    $mapa[[string][char]0x00D3] = [string][char]0x00D5   # O-agudo -> O-til
    $conteudo = Get-Content -LiteralPath $SrtPath -Raw -Encoding UTF8
    $script:trocasFeitas = 0
    $novoConteudo = [regex]::Replace($conteudo, '\p{L}+', {
        param($m)
        $palavra = $m.Value
        if ($dic.Contains($palavra)) { return $palavra }  # ja esta certa, nao mexe
        $candidata = ($palavra.ToCharArray() | ForEach-Object {
            if ($mapa.ContainsKey([string]$_)) { $mapa[[string]$_] } else { $_ }
        }) -join ''
        if ($candidata -ne $palavra -and $dic.Contains($candidata)) {
            $script:trocasFeitas++
            return $candidata
        }
        return $palavra
    })
    Set-Content -LiteralPath $SrtPath -Value $novoConteudo -Encoding UTF8 -NoNewline
    return $script:trocasFeitas
}

<#  v14.0 (revisado): Invoke-CorretorLegenda
    Roda o Corretor_Legenda.ps1 (ferramenta ja validada, 6/7 casos reais
    pegos, 0 falso positivo) como subprocesso, logo apos o PgsToSrt/
    Tesseract ter gerado o .srt. Ele NUNCA sobrescreve - sempre escreve
    <nome>_CORRIGIDO.srt do lado. Se esse arquivo aparecer, o motor troca o
    srt final por ele; se nao aparecer (Corretor_Legenda.ps1 ausente, ou
    nao achou nada pra corrigir), segue com o srt original do PgsToSrt sem
    quebrar nada.
#>
function Invoke-CorretorLegenda {
    param([string]$MkvPath, [string]$SrtPath)
    if (-not $temCorretor) { return $null }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    <#  v14.30: NAO MANDAR O CORRETOR REFAZER O QUE JA FALHOU AQUI.
        Se o seconv rodou nesta rodada, neste mesmo .mkv, e o motor recusou a
        leitura dele, a "2a opiniao" do Corretor chamaria o MESMO seconv, com o
        MESMO Latin.db, na MESMA imagem - e voltaria com a mesma recusa.
        Medido no Spider-Man de 26/08: 1m13s no motor + 1m12s no Corretor, e a
        2a opiniao fechou com 0 correcoes.
        Quando o seconv sai BOM, nada muda: a marca nao e ligada e a 2a opiniao
        roda como sempre. Os blocos suspeitos seguem para o Reocr de qualquer
        jeito, que usa outro caminho (Tesseract PSM 6) e nao depende do banco. #>
    $argsCorretor = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "$corretorLegenda", "-Mkv", "$MkvPath", "-Srt", "$SrtPath", "-SemPausa")
    if ($script:SeconvRecusadoNesteArquivo) { $argsCorretor += "-PularSegundaOpiniao" }
    $psi.Arguments = ConvertTo-ArgString $argsCorretor
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow  = $true
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    # v14.8 - TRAVAMENTO DE 6 HORAS NO HOMEM-ARANHA. Esta funcao redirecionava
    # a saida do Corretor e NUNCA LIA o que vinha. O buffer do cano do Windows
    # tem uns 4 KB: enquanto o Corretor escreve menos que isso, cabe no buffer
    # e ninguem percebe. Quando ele escreve MAIS, a chamada de escrita dele
    # trava esperando alguem esvaziar o cano - e o motor, do outro lado, so
    # fica olhando "ja terminou?" num laco que nunca vai ser verdade. Os dois
    # esperam um pelo outro pra sempre, com 0% de CPU. Nao trava, nao da erro,
    # nao consome nada: fica parado ate alguem matar na mao.
    #
    # Por que so apareceu agora: e proporcional ao TAMANHO DO RELATORIO. GoT
    # (446 blocos, poucas correcoes) cabia no buffer. O Corretor 2.7 passou a
    # imprimir mais - a linha dos nomes proprios protegidos e o ANTES/DEPOIS
    # de cada bloco corrigido - e num filme longo isso estourou os 4 KB.
    # Ou seja: o defeito e ANTIGO e estava aqui esperando; a 2.7 so puxou o
    # gatilho. A culpa e desta funcao, nao do Corretor.
    #
    # Prova no log de 13/08: OCR terminou 02:30:27, o Corretor comecou no mesmo
    # segundo, e as 08:31 - SEIS HORAS depois - ainda estava na etapa 5/7 com
    # "nenhum processo do motor ativo" e 0% de CPU. So andou quando o usuario
    # mandou cancelar.
    #
    # A correcao e a mesma que as outras 5 chamadas de processo deste motor ja
    # faziam: ler o cano de forma assincrona enquanto o processo roda. Esta era
    # a UNICA das 6 que redirecionava sem drenar.
    $linhasCorretor = New-Object System.Collections.ArrayList
    $onDataCorretor = {
        if ($EventArgs.Data) { [void]$Event.MessageData.Add($EventArgs.Data) }
    }
    $subOutCorretor = Register-ObjectEvent -InputObject $proc -EventName OutputDataReceived -Action $onDataCorretor -MessageData $linhasCorretor
    $subErrCorretor = Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived  -Action $onDataCorretor -MessageData $linhasCorretor

    $proc.Start() | Out-Null
    $null = $proc.Handle
    Adotar-Processo $proc
    Reduzir-PrioridadeProcesso $proc
    $proc.BeginOutputReadLine()
    $proc.BeginErrorReadLine()
    $inicioCorretor = Get-Date
    $pausaBaseCorretor = [double]$script:SegundosPausadosEtapa
    while (-not $proc.HasExited) {
        Invoke-ControlesTeclado $proc
        if ($script:CancelamentoSolicitado) { break }
        # v14.11: mesma correcao aplicada no seconv - curva suave que DESCONTA
        # pausa, dentro da faixa reservada pra esta sub-etapa. E o texto saiu
        # do laco: quem anuncia o nome e o SaySub, uma vez so.
        # v14.12: 25s era chute, e por isso a barra colava em 94% e ficava
        # la. O Corretor roda o seconv da 2a opiniao POR DENTRO - no Troia
        # foram 2m16s (136s). Mesma regra do seconv: EST = 136/2,3 = 60s.
        Show-BarraFaixa (Get-PctSuave $inicioCorretor $pausaBaseCorretor 60)
        Start-Sleep -Milliseconds 200
    }
    $proc.WaitForExit()
    # v14.8: solta os assinantes de evento, senao eles vazam a cada arquivo da
    # fila (as outras 5 chamadas ja faziam isso).
    if ($subOutCorretor) { Unregister-Event -SourceIdentifier $subOutCorretor.Name -ErrorAction SilentlyContinue }
    if ($subErrCorretor) { Unregister-Event -SourceIdentifier $subErrCorretor.Name -ErrorAction SilentlyContinue }
    Show-BarraFaixaFim

    # v14.7: BUG REAL, e dos grandes - o motor procurava o arquivo corrigido na
    # PASTA ERRADA desde a v14.1, ou seja, o Corretor_Legenda NUNCA foi usado
    # de verdade. Ele rodava, achava os blocos-lixo, corrigia, gravava - e o
    # motor olhava noutro lugar, nao achava nada, e seguia com o .srt cru do
    # PgsToSrt. Silencioso: nenhum erro, nenhum aviso.
    # O motor procurava em Split-Path do $SrtPath, que e a pasta de trabalho
    # (_ddvt_temp_<nome>\, do lado do video). O Corretor grava na PASTA DELE:
    #     $raiz = pasta do Corretor_Legenda.ps1   (C:\LaFirma)
    #     $pastaSaida = $raiz\_corretor
    #     $srtSaida = $pastaSaida\<nome>_CORRIGIDO.srt
    # Prova do teste de 13/08 00:28: o relatorio dele dizia
    # "SRT CORRIGIDO: C:\LaFirma\_corretor\..._ptbr_CORRIGIDO.srt", com
    # "OITECT" -> "Quase." e "as llhas" -> "as Ilhas" ja resolvidos, e mesmo
    # assim o .mkv final saiu com "OITECT" e "as llhas".
    # Agora procura nos dois lugares, na ordem certa.
    # A checagem de DATA e obrigatoria: o nome do arquivo e sempre o mesmo,
    # entao sem ela um _CORRIGIDO de uma rodada ANTERIOR seria usado como se
    # fosse desta - o que seria pior que nao usar nada.
    $nomeBase = [System.IO.Path]::GetFileNameWithoutExtension($SrtPath)
    $candidatos = @(
        (Join-Path (Join-Path $ScriptDir "_corretor") ($nomeBase + "_CORRIGIDO.srt")),
        (Join-Path (Split-Path -Parent $SrtPath) ($nomeBase + "_CORRIGIDO.srt"))
    )
    foreach ($cand in $candidatos) {
        if (-not (Test-Path -LiteralPath $cand)) { continue }
        $arq = Get-Item -LiteralPath $cand
        if ($arq.Length -le 0) { continue }
        if ($arq.LastWriteTime -lt $inicioCorretor) { continue }   # sobra de outra rodada
        return $cand
    }
    return $null
}

<#  v14.11: Invoke-ReocrLegenda
    -------------------------------------------------------------------------
    Roda o Reocr_Legenda.ps1 como subprocesso, como ULTIMA sub-etapa da [5/7]
    - depois do Corretor, antes do mkvmerge da [6/7].

    O QUE ELE FAZ (resumo; o detalhe esta no cabecalho do proprio script): o
    PgsToSrt nao deixa escolher o PSM do Tesseract e usa o padrao (PSM 3,
    "pagina inteira automatica"), que e o pior modo possivel pra imagem de
    legenda de 1-2 palavras. E dai que sai "INF TOL" no lugar de "Nao!". O
    Reocr pega SO os blocos suspeitos do .srt ja gerado, recorta a imagem
    daquele bloco especifico com ffmpeg e refaz no tesseract.exe com --psm 6
    (bloco unico de texto).

    TRES CUIDADOS, todos iguais aos que a Invoke-CorretorLegenda ja tomava:
      1. DRENAR O CANO. Registrar OutputDataReceived e nunca ler foi o que
         travou o Homem-Aranha por 6 horas na v14.8. O relatorio do Reocr e
         grande (ANTES/DEPOIS de cada bloco tocado), entao aqui e certeza de
         estourar os ~4 KB do buffer se ninguem esvaziar.
      2. CHECAR A DATA do arquivo de saida. O nome e sempre o mesmo
         (<base>_REOCR.srt), entao sem essa checagem uma sobra de rodada
         anterior entraria no lugar da desta - pior que nao corrigir nada.
      3. NUNCA SOBRESCREVER. Ele grava um arquivo NOVO; o motor so troca o
         ponteiro se o arquivo novo existir, nao estiver vazio e for desta
         rodada. Se qualquer coisa falhar, segue com o .srt que ja tinha.
#>
function Invoke-ReocrLegenda {
    param([string]$MkvPath, [string]$SrtPath)
    if (-not $temReocr) { return $null }
    if (-not (Test-Path -LiteralPath $SrtPath)) { return $null }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $argsReocr = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "$reocrLegenda",
                   "$MkvPath", "$SrtPath", "-SemPausa")
    if ($tesseractExe -ne "") { $argsReocr += @("-TesseractExe", "$tesseractExe") }
    $psi.Arguments = ConvertTo-ArgString $argsReocr
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow  = $true
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    <#  v14.12: PROGRESSO REAL, nao mais estimativa por relogio.
        O Reocr conta em voz alta o que esta fazendo: primeiro
        "Blocos suspeitos (candidatos a re-OCR): N" e depois uma linha
        "[i/N] hh:mm:ss,mmm :: '...'" por bloco. Sao esses dois numeros que
        alimentam a barra agora - o mesmo que o PgsToSrt ja fazia com o
        "for N items". Antes era curva de 40s num trabalho que levou 5m43s
        no Troia: a barra colava no fim e ficava minutos parada.
        A leitura acontece no MESMO evento que ja drenava o cano (obrigatorio
        - ver o comentario do travamento de 6 horas na Invoke-CorretorLegenda).
    #>
    $sincReocr = [hashtable]::Synchronized(@{
        Total = 0; Feitos = 0
        # v14.17: progresso DENTRO do bloco, vindo do proprio Reocr 1.10
        # (linhas "#PROG# bloco passo total"). Zero = Reocr antigo, sem
        # progresso fino; ai vale a curva assintotica mais abaixo.
        Passo = 0; PassoTotal = 0
        Linhas = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
        # v14.27: veredicto da legenda, lido da saida do Reocr 1.18 para ser
        # repetido na tela final da conversao.
        Veredicto = ""; NotaDefeitos = -1; NotaPct = ""; NotaBlocos = 0
    })
    $onDataReocr = {
        if ($EventArgs.Data) {
            $ln = $EventArgs.Data
            [void]$Event.MessageData.Linhas.Add($ln)
            if ($ln -match "(?i)candidatos a re-OCR\s*:\s*(\d+)") {
                $Event.MessageData.Total = [int]$Matches[1]
            } elseif ($ln -match "^#PROG#\s+(\d+)\s+(\d+)\s+(\d+)") {
                $Event.MessageData.Feitos     = [int]$Matches[1]
                $Event.MessageData.Passo      = [int]$Matches[2]
                $Event.MessageData.PassoTotal = [int]$Matches[3]
            } elseif ($ln -match "^\s*\[(\d+)/(\d+)\]") {
                if ([int]$Matches[1] -ne [int]$Event.MessageData.Feitos) { $Event.MessageData.Passo = 0 }
                $Event.MessageData.Feitos = [int]$Matches[1]
                if ($Event.MessageData.Total -le 0) { $Event.MessageData.Total = [int]$Matches[2] }
            } elseif ($ln -match "QUALIDADE DA LEGENDA\s*:\s*(\S+)") {
                # v14.27: o Reocr 1.18 fecha o relatorio com o veredicto da
                # legenda. O motor le a linha aqui para repetir na tela final,
                # junto do resto do resumo - senao a nota fica so no relatorio
                # e o usuario descobre a qualidade assistindo ao filme.
                $Event.MessageData.Veredicto = $Matches[1]
            } elseif ($ln -match "(\d+) blocos no arquivo\s*-\s*(\d+) com defeito conhecido \(([\d,\.]+)%\)") {
                $Event.MessageData.NotaBlocos   = [int]$Matches[1]
                $Event.MessageData.NotaDefeitos = [int]$Matches[2]
                $Event.MessageData.NotaPct      = $Matches[3]
            }
        }
    }
    $subOutReocr = Register-ObjectEvent -InputObject $proc -EventName OutputDataReceived -Action $onDataReocr -MessageData $sincReocr
    $subErrReocr = Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived  -Action $onDataReocr -MessageData $sincReocr

    $proc.Start() | Out-Null
    $null = $proc.Handle
    Adotar-Processo $proc
    Reduzir-PrioridadeProcesso $proc
    $proc.BeginOutputReadLine()
    $proc.BeginErrorReadLine()

    <#  v14.11: TETO DE TEMPO. O Reocr gasta ate 3 chamadas de ffmpeg por
        bloco suspeito, e o numero de suspeitos depende do arquivo: no Troia
        foram 8; num .srt que saiu do seconv com 70% de caractere ilegivel
        pode ser MUITO mais. Como esta sub-etapa agora esta DENTRO da
        conversao, ela nao pode ter direito a tempo infinito - uma melhoria
        cosmetica de legenda nao vale segurar um lote inteiro.
        Passou do teto: o processo e morto, o .srt anterior (que ja esta bom)
        e mantido, e o motor avisa. Nada quebra, nada e perdido.
        O tempo PAUSADO nao conta pro teto - senao pausar pro almoco mataria
        uma etapa que estava indo bem.
    #>
    $tetoReocrSeg = 900.0    # 15 minutos de trabalho REAL
    $estourouTeto = $false
    $inicioReocr = Get-Date
    $pausaBaseReocr = [double]$script:SegundosPausadosEtapa
    # v14.17: marcadores da troca de bloco (ver o bloco de comentario abaixo)
    $ultimoFeitosR = 0
    $trabNaTrocaR  = 0.0
    while (-not $proc.HasExited) {
        Invoke-ControlesTeclado $proc
        if ($script:CancelamentoSolicitado) { break }
        $pausadoReocr = [double]$script:SegundosPausadosEtapa - $pausaBaseReocr
        if ($pausadoReocr -lt 0) { $pausadoReocr = 0 }
        $trabalhoReocr = ((Get-Date) - $inicioReocr).TotalSeconds - $pausadoReocr
        if ($trabalhoReocr -gt $tetoReocrSeg) {
            $estourouTeto = $true
            try { $proc.Kill() } catch { }
            break
        }
        if ($sincReocr.Total -gt 0) {
            <#  v14.17: A BARRA FICAVA PARADA - E A CONTA ERA ZERO POR ALGEBRA.
                O Reocr so anuncia "[i/N]" quando COMECA um bloco. Entre um
                anuncio e o proximo a barra nao tinha o que ler, e a 14.12
                tinha posto aqui um preenchimento pela media. So que a conta
                era:
                    media   = trabalho / feitos
                    noBloco = trabalho - (media * feitos)
                e (trabalho/feitos)*feitos E o proprio trabalho. Ou seja
                noBloco dava SEMPRE ZERO, e a fracao SEMPRE ZERO: o
                preenchimento nunca existiu de verdade.
                No Se7en de 19/08 isso apareceu como a barra travada em 83%
                por QUATRO MINUTOS (01:37:15 a 01:41:15 no log) - um bloco
                que demorou muito mais que os outros.
                Agora o tempo de cada bloco e MARCADO na hora em que o numero
                muda ($trabNaTrocaR). A media vem so dos blocos JA FECHADOS, e
                o tempo dentro do bloco atual e a diferenca de verdade.
                E a fracao usa a mesma curva assintotica do resto do programa
                em vez de um teto duro: bloco que demora o dobro da media vai
                a 86% do seu pedaco, o triplo vai a 95% - continua andando,
                nunca chega no proximo bloco antes dele. #>
            $feitosBrutosR = [int]$sincReocr.Feitos
            if ($feitosBrutosR -ne $ultimoFeitosR) {
                $ultimoFeitosR = $feitosBrutosR
                $trabNaTrocaR  = $trabalhoReocr
            }
            # O -1 e de proposito - o bloco anunciado ainda esta SENDO feito.
            $feitosR = [math]::Max(0, $ultimoFeitosR - 1)
            $fracao = 0.0
            if ([int]$sincReocr.PassoTotal -gt 0) {
                # Progresso DE VERDADE dentro do bloco: o Reocr 1.10 avisa a
                # cada altura testada (12 passos por bloco). Nao ha nada a
                # estimar - e so ler.
                $fracao = [double]$sincReocr.Passo / [double]$sincReocr.PassoTotal
                if ($fracao -gt 0.97) { $fracao = 0.97 }
                if ($fracao -lt 0.0)  { $fracao = 0.0 }
            } elseif ($feitosR -gt 0) {
                # Reocr antigo (sem "#PROG#"): sobra a curva assintotica em
                # cima da media dos blocos ja fechados.
                $mediaR = $trabNaTrocaR / $feitosR
                if ($mediaR -gt 0) {
                    $noBloco = $trabalhoReocr - $trabNaTrocaR
                    if ($noBloco -lt 0) { $noBloco = 0 }
                    $fracao = 1.0 - [math]::Exp(-$noBloco / $mediaR)
                    if ($fracao -gt 0.97) { $fracao = 0.97 }
                }
            }
            <#  v14.31: "A BARRA TRAVA EM 87%" - ELA NAO TRAVA, ELA E FINA
                DEMAIS PARA O QUE ESTA ACONTECENDO.
                Medido no log do Diego (Spider-Man 27/08 00h11-00h14): a etapa
                ficou 3 MINUTOS marcando 87%. A barra estava CERTA: eram 19
                blocos suspeitos numa faixa de 42 pontos de tela, ou seja cada
                bloco vale 2,2 pontos - e o bloco 13 era um dos RECUSADOS, que
                roda as 60 leituras inteiras (3 instantes x 4 alturas x 5
                modos) antes de desistir. Tres minutos de trabalho real que
                movem a barra 2%: para quem olha, esta parado.
                Numero nenhum de barra resolve isso. O que faltava era DIZER em
                que bloco ele esta. Com "bloco 13 de 19" na linha da etapa, os
                mesmos 3 minutos param de parecer travamento e viram o que sao:
                um bloco dificil. A janela ja transforma esta repintura em NOTA
                (ver "16.10" no fonte dela) e ignora repeticao identica, entao
                isto so escreve quando o numero muda de verdade. #>
            $blocoAgora = [int]$sincReocr.Feitos
            if ($blocoAgora -gt 0 -and $blocoAgora -ne $script:UltimoBlocoReocr) {
                $script:UltimoBlocoReocr = $blocoAgora
                Write-Host -NoNewline ("`r        Re-OCR de falas curtas (Reocr_Legenda / Tesseract PSM 6) - bloco {0} de {1}" -f $blocoAgora, [int]$sincReocr.Total)
            }
            Show-BarraFaixa (100.0 * ($feitosR + $fracao) / [double]$sincReocr.Total)
        } else {
            # ainda lendo o .srt e escolhendo os suspeitos - curva suave
            Show-BarraFaixa (Get-PctSuave $inicioReocr $pausaBaseReocr 25)
        }
        Start-Sleep -Milliseconds 200
    }
    $proc.WaitForExit()
    if ($subOutReocr) { Unregister-Event -SourceIdentifier $subOutReocr.Name -ErrorAction SilentlyContinue }
    if ($subErrReocr) { Unregister-Event -SourceIdentifier $subErrReocr.Name -ErrorAction SilentlyContinue }
    Remove-Job -Name $subOutReocr.Name -ErrorAction SilentlyContinue
    Remove-Job -Name $subErrReocr.Name -ErrorAction SilentlyContinue
    Show-BarraFaixaFim
    if ($estourouTeto) {
        SayWarn "Re-OCR de Falas Curtas Passou de 15 Minutos e Foi Interrompido. A Legenda Anterior Foi Mantida (Ela Ja Estava Boa)."
        return $null
    }
    if ($script:CancelamentoSolicitado) { return $null }

    # O Reocr grava na PASTA DELE (<raiz>\_reocr\), igual ao Corretor. A
    # segunda opcao cobre o caso de ele um dia gravar do lado do .srt.
    $nomeBaseR = [System.IO.Path]::GetFileNameWithoutExtension($SrtPath)
    $candidatosR = @(
        (Join-Path (Join-Path $ScriptDir "_reocr") ($nomeBaseR + "_REOCR.srt")),
        (Join-Path (Split-Path -Parent $SrtPath) ($nomeBaseR + "_REOCR.srt"))
    )
    foreach ($candR in $candidatosR) {
        if (-not (Test-Path -LiteralPath $candR)) { continue }
        $arqR = Get-Item -LiteralPath $candR
        if ($arqR.Length -le 0) { continue }
        if ($arqR.LastWriteTime -lt $inicioReocr) { continue }   # sobra de outra rodada
        # v14.11: quantos blocos ele de fato trocou - sai do proprio relatorio
        # dele, pra manchete nao ter que adivinhar.
        $trocados = 0
        foreach ($ln in $sincReocr.Linhas) {
            # Linha do RESUMO dele: "Aceitos (passaram na trava)  : 8"
            if ("$ln" -match "(?i)^\s*Aceitos\s*\(passaram na trava\)\s*:\s*(\d+)") { $trocados = [int]$Matches[1] }
        }
        return @{ Caminho = $candR; Trocados = $trocados; Veredicto = $sincReocr.Veredicto; NotaDefeitos = $sincReocr.NotaDefeitos; NotaPct = $sincReocr.NotaPct; NotaBlocos = $sincReocr.NotaBlocos }
    }
    return $null
}


$files = @(Get-ChildItem -LiteralPath $SourceDir -Filter *.mkv)

Line
SayTitulo ("  {0:D2} ARQUIVO(s) ENCONTRADO(s) NESTA PASTA:" -f $files.Count)
Line
Write-Host ""

if ($pastaBaseFoiCriadaAgora) {
    SayWarn "A Pasta '00_Arquivos_Base' Nao Existia. Acabei de Cria-la."
}
if ($files.Count -eq 0) {
    SayWarn "Nenhum Arquivo .mkv Encontrado em $SourceDir. Coloque os Arquivos la Dentro e Rode de Novo."
}

# ---- verificacao geral de espaco em disco para o lote inteiro --------------
# Formula baseada na experiencia real: cada episodio, durante o proprio
# processamento, precisa de ate ~3x o seu proprio tamanho (video extraido +
# RPU convertido + arquivo final sendo montado, temporariamente juntos). Os
# arquivos finais de episodios ja concluidos ficam ocupando espaco de forma
# permanente. Entao a pior hora (fim do lote) precisa de:
#     espaco de TODOS os arquivos finais (~soma de todos os tamanhos)
#   + a "folga" extra (~2x) do MAIOR arquivo, que e quem exige mais durante
#     o proprio processamento dele.
if ($files.Count -gt 0) {
    $somaTotal   = ($files | Measure-Object -Property Length -Sum).Sum
    $maiorArq    = ($files | Measure-Object -Property Length -Maximum).Maximum
    # +15% de folga no maior arquivo para os temporarios que o DeeZy cria ao
    # converter a faixa TrueHD/MLP para E-AC-3 Atmos (mesma folga usada no
    # calculo por episodio, mais abaixo).
    $espacoNecessarioLote = $somaTotal + (2.15 * $maiorArq)

    $driveOrigem = [System.IO.Path]::GetPathRoot($SourceDir)
    try {
        $espacoLivreLote = (Get-PSDrive -Name ($driveOrigem.TrimEnd('\','/').TrimEnd(':')) -ErrorAction Stop).Free
        # Rotulos com largura FIXA de 40 colunas: antes cada uma das tres
        # linhas tinha um recuo diferente e os dois-pontos nao se alinhavam.
        # 40 e o tamanho do rotulo mais longo dos tres, entao todos cabem sem
        # cortar e a coluna dos valores fica reta.
        SayTitulo "  ESPACO EM DISCO:"
        Say ("  {0}  {1}: ~{2}" -f $script:IconeDisco, "Espaco Necessario Estimado".PadRight(40), (Format-Tamanho $espacoNecessarioLote)) "White"
        Say ("  {0}  {1}: {2}"  -f $script:IconeDisco, ("Espaco Livre em " + $driveOrigem).PadRight(40), (Format-Tamanho $espacoLivreLote)) "White"
        # Espaco livre estimado DEPOIS que todo o lote terminar. O DDVT nao
        # apaga os arquivos de origem (ficam em 00_Arquivos_Base) - o arquivo
        # final vai para 01_Arquivos_Finalizados, ficando os dois no disco ao
        # mesmo tempo. Como o video e so copiado (sem recodificar), o tamanho
        # final costuma ficar bem proximo da soma dos originais - por isso
        # $somaTotal e usado como estimativa (pode variar um pouco pra menos,
        # dependendo de quantas faixas de audio/legenda extras forem
        # descartadas no processo).
        $espacoAposConversao = $espacoLivreLote - $somaTotal
        Say ("  {0}  {1}: ~{2}" -f $script:IconeDisco, "Espaco Livre Apos a Conversao (estimado)".PadRight(40), (Format-Tamanho $espacoAposConversao)) "White"
        if ($espacoLivreLote -lt $espacoNecessarioLote) {
            $faltam = $espacoNecessarioLote - $espacoLivreLote
            SayWarn ("O Espaco Pode Nao Ser Suficiente para Converter Todos os Arquivos em Sequencia. Faltam Aproximadamente {0}. O Programa Vai Converter o Que Couber e Avisar Caso Algum Episodio Precise Ser Pulado por Falta de Espaco." -f (Format-Tamanho $faltam))
        } else {
            SayOk "Espaco em Disco Suficiente para Converter Todos os Arquivos Encontrados."
        }
        Write-Host ""
    } catch { }
}

# ============================================================================
# v14.9 - FAXINEIRO DE ENTRADA. Le antes de comecar qualquer conversao.
#
# O PROBLEMA REAL (13/08, Homem-Aranha): sobraram 50,89 GB de video cru na
# pasta _ddvt_temp_<nome>\ depois que a conversao travou e o usuario teve que
# matar o programa na mao.
#
# Por que a limpeza existente nao pegou: ela mora num "finally", que so roda
# quando o script CHEGA ao fim do bloco - nem que seja com erro. Se o processo
# e MORTO (fechar a janela, Gerenciador de Tarefas, travamento), o finally
# nunca executa e a pasta fica la ocupando o disco pra sempre.
#
# Nao da pra garantir limpeza no momento da morte - por definicao. O que da
# pra garantir e limpar na PROXIMA vez que abrir. E isso que esta funcao faz,
# e por isso ela cobre qualquer forma de morte: travamento, queda de energia,
# fim do processo na marra.
#
# Seguranca: NAO apaga pasta que outro LaFirma esteja usando agora. Testa isso
# tentando renomear a pasta pra ela mesma - se estiver em uso, o Windows
# recusa, e a gente pula sem falar nada.
# ============================================================================
function Remove-SobrasDeTemporarios {
    <#  v14.19: A RAIZ DO DISCO NAO PODE SER VARRIDA COM -Recurse.
        A 14.18 mandou varrer tambem a raiz de cada disco, para achar as
        pastas de audio "_ddvt_au_NNN" que nascem la. So que a varredura era
        -Recurse - e -Recurse na raiz do C: significa percorrer o disco
        INTEIRO, pasta por pasta, antes de o primeiro video comecar.
        Medido no log de 19/08: 34 segundos parados entre "laco do motor
        localizado" (+2,3s) e o primeiro arquivo (+36,3s), sem nenhuma linha
        no meio. Foi exatamente isso.
        As pastas de audio ficam SEMPRE no primeiro nivel da raiz - o motor
        as cria com Join-Path <raiz> "_ddvt_au_NNN". Entao a raiz e varrida
        sem -Recurse, e so as pastas dos arquivos continuam recursivas. #>
    param([string[]]$Pastas, [string[]]$Raizes)
    $achadas = New-Object System.Collections.ArrayList
    foreach ($pasta in ($Pastas | Select-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($pasta)) { continue }
        if (-not (Test-Path -LiteralPath $pasta)) { continue }
        try {
            $subs = @(Get-ChildItem -LiteralPath $pasta -Directory -Filter "_ddvt_temp_*" -Recurse -ErrorAction SilentlyContinue)
        } catch { $subs = @() }
        foreach ($s in $subs) { [void]$achadas.Add($s) }
    }
    foreach ($raiz in ($Raizes | Select-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($raiz)) { continue }
        if (-not (Test-Path -LiteralPath $raiz)) { continue }
        try {
            # SEM -Recurse: um nivel so. E instantaneo.
            $subs = @(Get-ChildItem -LiteralPath $raiz -Directory -Filter "_ddvt_*" -ErrorAction SilentlyContinue)
        } catch { $subs = @() }
        foreach ($s in $subs) { [void]$achadas.Add($s) }
    }
    if ($achadas.Count -eq 0) { return }

    $totalBytes = 0
    $apagadas   = 0
    $caminhosApagados = @()
    $emUso      = 0
    $naoDeu = 0
    $motivoNaoDeu = ""
    foreach ($dir in $achadas) {
        $tam = 0
        try {
            $tam = (Get-ChildItem -LiteralPath $dir.FullName -Recurse -File -ErrorAction SilentlyContinue |
                    Measure-Object -Property Length -Sum).Sum
            if (-not $tam) { $tam = 0 }
        } catch { $tam = 0 }
        # Esta em uso por OUTRA conversao rodando agora? Testa de verdade:
        # tenta abrir cada arquivo em modo exclusivo. Se algum estiver travado
        # (o ffmpeg escrevendo o .hevc, por exemplo), o Windows recusa e a
        # gente deixa a pasta quieta - apagar ali quebraria a outra conversao.
        $emUsoAgora = $false
        try {
            foreach ($arq in @(Get-ChildItem -LiteralPath $dir.FullName -Recurse -File -ErrorAction SilentlyContinue)) {
                try {
                    $fs = [System.IO.File]::Open($arq.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
                    $fs.Close(); $fs.Dispose()
                } catch { $emUsoAgora = $true; break }
            }
        } catch { }
        if ($emUsoAgora) { $emUso++; continue }
        try {
            Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction Stop
            $apagadas++
            $totalBytes += $tam
            $caminhosApagados += ("{0}  ({1})" -f $dir.FullName, (Format-Tamanho $tam))
        } catch {
            # v14.18: antes isto somava no MESMO contador do teste de arquivo
            # travado, e a mensagem la embaixo afirmava categoricamente que
            # havia "outra conversao rodando agora". Permissao negada, caminho
            # acima de 260 caracteres (que acontece com nome de episodio
            # longo) ou atributo somente-leitura viravam a mesma frase, e o
            # usuario ia procurar um segundo LaFirma aberto que nao existe.
            $naoDeu++
            $motivoNaoDeu = $_.Exception.Message
        }
    }

    if ($naoDeu -gt 0) {
        SayWarn ("{0} pasta(s) temporaria(s) nao puderam ser removidas. Motivo da ultima: {1}" -f $naoDeu, $motivoNaoDeu)
    }
    if ($apagadas -gt 0) {
        SayWarn ("Encontrei {0} pasta(s) temporaria(s) de uma conversao anterior que nao terminou - provavelmente o programa foi fechado ou travou no meio." -f $apagadas)
        <#  v14.34: o log de 01/09 23h38 dizia "Limpei Agora e Liberei 0 KB"
            depois de achar uma pasta orfa - e o Diego tinha 102 GB parados no
            disco. "0 KB" ali nao e informacao, e um numero que nao ajuda
            ninguem: ou a pasta estava vazia mesmo, ou a medicao falhou. As
            duas coisas agora aparecem com o CAMINHO, que e o que permite ir
            olhar. #>
        foreach ($cam in $caminhosApagados) { Say ("   apagada: " + $cam) }
        if ($totalBytes -gt 0) {
            SayOk ("Limpei Agora e Liberei {0} de Disco." -f (Format-Tamanho $totalBytes))
        } else {
            SayOk "Limpei Agora. As pastas estavam vazias (ou nao consegui medir o tamanho antes de apagar)."
        }
    }
    if ($emUso -gt 0) {
        SayWarn ("{0} pasta(s) temporaria(s) estao em uso por outra conversao rodando agora - deixei quietas." -f $emUso)
    }
}

$numero = 0
$script:FaxinaJaFeita = $false
foreach ($f in $files) {

    # v14.9: a faxina roda DENTRO do laco, no primeiro arquivo, de proposito.
    # A JANELA executa SO o "foreach ($f in $files)" do motor - tudo que fica
    # fora dele nunca roda na interface. Como o Diego roda sempre pela janela,
    # a limpeza tinha que estar aqui pra valer. Alem disso, so aqui a gente
    # sabe a pasta real dos arquivos ($f.DirectoryName), que e onde a pasta
    # _ddvt_temp_ nasce - e ela pode estar em qualquer lugar, nao so em
    # 00_Arquivos_Base (no Homem-Aranha estava em 00_Arquivos_Base\ORIGINAL\).
    if (-not $script:FaxinaJaFeita) {
        $script:FaxinaJaFeita = $true
        $pastasParaVarrer = New-Object System.Collections.ArrayList
        foreach ($fArq in $files) { [void]$pastasParaVarrer.Add($fArq.DirectoryName) }
        if ($SourceDir) { [void]$pastasParaVarrer.Add($SourceDir) }
        if ($OutputDir) { [void]$pastasParaVarrer.Add($OutputDir) }
        # v14.18: as pastas de AUDIO ("_ddvt_au_NNN") nascem na RAIZ do disco,
        # nao do lado do arquivo. v14.19: elas vao numa lista SEPARADA, porque
        # a raiz do disco nao pode ser varrida com -Recurse (ver a funcao).
        $raizesParaVarrer = New-Object System.Collections.ArrayList
        foreach ($fArq in $files) {
            try { [void]$raizesParaVarrer.Add([System.IO.Path]::GetPathRoot($fArq.FullName)) } catch { }
        }
        try { Remove-SobrasDeTemporarios -Pastas @($pastasParaVarrer) -Raizes @($raizesParaVarrer) } catch { }
    }


    $numero++
    $name    = $f.BaseName
    $outFile = Join-Path $OutputDir ($name + ".mkv")
    $tIni    = Get-Date

    Write-Host ""
    Line "#" "DarkMagenta"
    SayTitulo ("  ARQUIVO {0}/{1}: {2}" -f $numero, $files.Count, $name)
    Line "#" "DarkMagenta"

    <#  14.32: -LiteralPath NAO E DETALHE AQUI.
        $outFile vem do nome do arquivo, e nome de release tem colchete:
        "Show.S01E01.[1080p].[DV].mkv". Sem -LiteralPath o Test-Path le
        "[1080p]" como CLASSE DE CARACTERE e devolve $false com o arquivo
        existindo do lado. A trava "ja existe, pulando" nao disparava: o
        motor reconvertia o episodio inteiro do zero e no fim sobrescrevia
        a saida boa. Era o unico Test-Path do programa sem -LiteralPath. #>
    if (Test-Path -LiteralPath $outFile) {
        SayWarn "Ja Existe na Pasta de Saida. Pulando."
        $resultados += [PSCustomObject]@{ Episodio = $name; Status = "PULADO"; StatusDV = ""; StatusAudio = ""; MotivoAudio = ""; CodecAudio = "-"; TipoConvAudio = ""; StatusLegenda = ""; MotivoLegenda = ""; DescarteAudio = $false; DescarteLegenda = $false; FaixasAudioMantidas = $null; FaixasLegendaMantidas = $null; NotaLegendaVeredicto = ""; NotaLegendaDefeitos = -1; NotaLegendaPct = ""; NotaLegendaBlocos = 0; Fps = ""; Tamanho = ""; DuracaoVideo = ""; Tempo = ""; Motivo = "ja existia na pasta de saida" }
        continue
    }

    # Pasta temporaria deste episodio: sempre criada na MESMA pasta/disco
    # onde o arquivo de origem esta (evita copiar dados entre discos e
    # mantem a velocidade do disco onde o arquivo ja esta gravado).
    $WorkDir = Join-Path $f.DirectoryName ("_ddvt_temp_" + $name)
    [System.IO.Directory]::CreateDirectory($WorkDir) | Out-Null

    # Pasta temporaria EXCLUSIVA do DeeZy/DEE, curta e na RAIZ do mesmo disco
    # do arquivo de origem (mantem o principio de "mesmo disco", mas evita o
    # limite classico do Windows de 260 caracteres por caminho - MAX_PATH).
    # O DEE (dee.exe) e um executavel legado que nao suporta caminhos longos:
    # ele cria sua PROPRIA subpasta (nome com hash, ~37 caracteres) e gera
    # nomes de arquivo internos que REPETEM o nome inteiro do episodio
    # (ex: "...atmos.json", ~100 caracteres). Somado a nossa propria estrutura
    # de pastas (que ja pode ter 100+ caracteres so no nome do episodio),
    # o caminho final facilmente passa de 260 caracteres e o DEE falha com
    # "Cannot open file ...atmos.json" - mesmo depois de processar 100% do
    # audio, porque so tenta ABRIR o arquivo de config no final. Por isso
    # aqui usamos uma pasta bem curta ("_ddvt_au_" + numero do episodio) em
    # vez do WorkDir (que ja carrega o nome completo do episodio).
    $driveRaiz = [System.IO.Path]::GetPathRoot($f.FullName)
    $AudioWorkDir = Join-Path $driveRaiz ("_ddvt_au_" + $numero.ToString("D3"))
    if (Test-Path -LiteralPath $AudioWorkDir) { Remove-Item -LiteralPath $AudioWorkDir -Recurse -Force -ErrorAction SilentlyContinue }
    [System.IO.Directory]::CreateDirectory($AudioWorkDir) | Out-Null

    $rawHevc = Join-Path $WorkDir ($name + "_raw.hevc")
    $p81Hevc = Join-Path $WorkDir ($name + "_P81.hevc")
    $srtPtBr = $null
    # Status da etapa de Dolby Vision: "OK" = convertido pelo dovi_tool;
    # "NAO_NECESSARIO" = ja era Profile 8.x sem EL e foi so reaproveitado.
    $statusDV = "OK"

    # ---- Diagnostico previo: analisa o arquivo ANTES de comecar a converter
    # e mostra exatamente o que vai ser feito em cada frente (Dolby Vision,
    # audio, legenda) - assim da pra conferir de cara se o script identificou
    # tudo certo, sem precisar esperar a etapa correspondente rodar so pra
    # descobrir. Puramente informativo - nao interrompe o fluxo se algo aqui
    # falhar (o diagnostico real de cada etapa acontece de novo, na hora).
    try {
        SayTitulo "  O QUE FOI ENCONTRADO NESTE ARQUIVO:"
        Write-Host ""

        # --- Dolby Vision ---
        $diagDV = Get-InfoDolbyVision -MkvPath $f.FullName
        if ($diagDV) {
            Say-Deteccao ("        Dolby VISION: {0} [{1}] [{2}] [DETECTADO]" -f $diagDV.Nome, $diagDV.Codec, $diagDV.Camadas)
            $temEL = ($diagDV.Camadas -match "EL")
            if ($diagDV.Perfil -eq 8 -and -not $temEL) {
                # Ja e Profile 8.x e nao tem Enhancement Layer: converter de
                # novo com o dovi_tool nao muda nada de util. Pulamos a etapa.
                # FIX: padronizado com o resto do diagnostico - tag
                # [CONVERSAO NAO NECESSARIA] sempre no INICIO da linha, cor
                # amarela sempre (antes essa linha especifica usava cinza e
                # tag no final, inconsistente com as demais).
                SayResposta "skip" ("[CONVERSAO NAO NECESSARIA] Ja Esta em {0} (BL+RPU, Sem Enhancement Layer)" -f $diagDV.Nome)
            } else {
                # Perfil 5 ou 7 (ou 8 ainda com EL): o level e mantido, o perfil
                # vira 8 (compat 1) e o Enhancement Layer e descartado (BL+RPU).
                $codecAlvo = "dvhe.08.{0:D2}" -f $diagDV.Level
                SayResposta "ok" ("Sera Convertido para Profile 8.1 [{0}] [BL+RPU] [OK]" -f $codecAlvo)
            }
        } else {
            # FIX: antes essa mensagem dizia "Sera Convertido" mesmo sem
            # nenhum Dolby Vision identificado - o episodio agora e PULADO
            # cedo no processamento real (ver [1/7]), entao o diagnostico
            # precisa refletir isso em vez de prometer uma conversao que
            # nao vai acontecer.
            Say "        Dolby Vision: Nenhum Perfil Identificado pelo ffprobe [AVISO]" "DarkYellow"
            Say "        Este Arquivo Nao Parece Ter Dolby Vision - Este Episodio Sera Pulado" "Red"
        }
        Write-Host ""
        # --- Audio ---
        # A decisao olha a faixa de audio PRINCIPAL (nao necessariamente a
        # faixa 01 - ver Get-FaixaAudioPrincipal: default/ingles/nao-comentario
        # tem prioridade). Mesma ordem de verificacao da etapa real [4/7]:
        #   TrueHD -> SEMPRE converte para Atmos/JOC, EXCETO se ja existir uma
        #             faixa E-AC-3 Atmos/JOC em outro lugar do arquivo.
        #   DTS    -> converte para E-AC-3 comum, EXCETO se ja existir uma
        #             faixa E-AC-3/AC-3 (nao-comentario) pronta no arquivo
        #             E NO MESMO IDIOMA (v13.2 - dublagem nao conta).
        #   E-AC-3/AC-3/AAC -> nao necessario | outro codec -> mantido.
        $diagFaixaAudio = Get-FaixaAudioPrincipal -MkvPath $f.FullName
        # v14.8: o DIAGNOSTICO nao consultava a escolha manual. Resultado: com
        # "manter audio" marcado na janela, ele anunciava "SERA CONVERTIDO
        # E-AC-3" e la na [4/7] fazia o certo ("Conversao Desligada na Escolha
        # Manual"). O motor sempre respeitou a escolha; quem mentia era o
        # aviso. Mesma familia dos outros: anunciar uma coisa e fazer outra.
        $diagEscolheuConverter = Test-EscolheuConverter $f.FullName
        if ($null -ne $diagEscolheuConverter -and -not $diagEscolheuConverter) {
            $nomeDiagManual = if ($diagFaixaAudio) { $diagFaixaAudio.codec } else { "Faixa Principal" }
            Say-Deteccao ("        AUDIO PRINCIPAL: {0} [DETECTADO]" -f $nomeDiagManual)
            SayResposta "skip" "[ESCOLHA MANUAL] Conversao Desligada por Voce - a Faixa Sera Mantida Como Esta"
        } elseif (Test-EhTrueHD $diagFaixaAudio) {
            # mkvmerge reporta "TrueHD Atmos" ou "TrueHD"; prefixamos "Dolby"
            $nomeAudioDiag = if ($diagFaixaAudio.codec -match "(?i)^Dolby") { $diagFaixaAudio.codec } else { "Dolby $($diagFaixaAudio.codec)" }
            Say-Deteccao ("        AUDIO PRINCIPAL: {0} [DETECTADO]" -f $nomeAudioDiag)
            if (Get-FaixaAtmosJocExistente -MkvPath $f.FullName -FaixaExcluir $diagFaixaAudio) {
                SayResposta "skip" "[CONVERSAO NAO NECESSARIA] Arquivo Ja Possui Faixa E-AC-3 Atmos/JOC"
            } elseif ($temDeezy) {
                SayResposta "ok" ("Sera Convertido para E-AC-3 Atmos (DeeZy, {0} kbps) [OK]" -f $ATMOS_BITRATE)
            } else {
                SayResposta "skip" "[FERRAMENTA INDISPONIVEL] DeeZy Nao Encontrado - Faixa Sera Mantida Como Esta"
            }
        } elseif (Test-EhDts $diagFaixaAudio) {
            Say-Deteccao ("        AUDIO PRINCIPAL: {0} [DETECTADO]" -f $diagFaixaAudio.codec)
            if (Get-FaixaCompativelC2Externa -MkvPath $f.FullName -FaixaExcluir $diagFaixaAudio) {
                # FIX: padronizado - tag no INICIO, amarelo (antes: cinza,
                # tag no final, inconsistente com as demais linhas do bloco).
                SayResposta "skip" "[CONVERSAO NAO NECESSARIA] Ja Existe Faixa E-AC-3/AC-3 Compativel no Arquivo"
            } else {
                SayResposta "ok" ("Sera Convertido para E-AC-3 (ffmpeg, {0} kbps) [OK]" -f $DTS_EAC3_BITRATE)
            }
        } elseif (Test-EhCompativelC2 $diagFaixaAudio) {
            Say-Deteccao ("        AUDIO PRINCIPAL: {0} [DETECTADO]" -f $diagFaixaAudio.codec)
            SayResposta "skip" "[CONVERSAO NAO NECESSARIA] Faixa Ja Compativel com a TV (E-AC-3/AC-3/AAC)"
        } elseif ($diagFaixaAudio) {
            Say-Deteccao ("        AUDIO PRINCIPAL: {0} [DETECTADO]" -f $diagFaixaAudio.codec)
            SayResposta "skip" "[CONVERSAO NAO NECESSARIA] Faixa Mantida Como Esta"
        } else {
            Say "        Audio Principal: Faixa Principal" "DarkYellow"
            SayResposta "skip" "[AVISO] Nao Foi Possivel Identificar a Faixa - Modo Seguro (Nada Sera Descartado)"
        }
        Write-Host ""
        # --- Legenda ---
        # Mesma ordem de prioridade real usada no [5/7]: primeiro verifica se
        # ja existe PT-BR em TEXTO (nao precisa de OCR, e o melhor caso) -
        # so se nao houver isso e que verifica PGS (precisa de OCR). Antes
        # esse diagnostico so checava PGS, entao para arquivos com PT-BR ja
        # em texto (sem PGS) ele dizia erroneamente "nenhuma legenda
        # identificada", quando na verdade o [5/7] ia reaproveitar a .srt.
        $diagLegendaTexto = Get-FaixaLegendaPtBrTexto -MkvPath $f.FullName
        if ($diagLegendaTexto) {
            $nomeLegTexto = $diagLegendaTexto.properties.track_name
            if ([string]::IsNullOrWhiteSpace($nomeLegTexto)) {
                Say-Deteccao ("        LEGENDA PT-BR [.SRT]: Faixa {0} Encontrada [DETECTADO]" -f $diagLegendaTexto.id)
            } else {
                Say-Deteccao ("        LEGENDA PT-BR [.SRT]: '{0}' Encontrada na Faixa {1} [DETECTADO]" -f $nomeLegTexto, $diagLegendaTexto.id)
            }
            # FIX: a linha anterior ja diz "[.SRT]" (ou seja, ja esta em
            # texto) - repetir "Ja Esta em Texto" aqui era redundante. Agora
            # a linha so acrescenta a informacao NOVA (o que vai acontecer).
            SayResposta "skip" "[CONVERSAO NAO NECESSARIA] Sera Reaproveitada Diretamente Como Legenda Padrao"
        } else {
            $diagPgs = Find-PtBrPgsTrack -MkvPath $f.FullName
            if ($diagPgs) {
                $nomeFaixaPgs = $diagPgs.properties.track_name
                if ([string]::IsNullOrWhiteSpace($nomeFaixaPgs)) {
                    Say-Deteccao ("        LEGENDA PGS: Faixa {0} Encontrada [DETECTADO]" -f $diagPgs.id)
                } else {
                    Say-Deteccao ("        LEGENDA PGS: '{0}' Encontrada na Faixa {1} [DETECTADO]" -f $nomeFaixaPgs, $diagPgs.id)
                }
                SayResposta "ok" "Sera Convertida via OCR para .SRT [OK]"
            } else {
                Say "        Legenda PGS" "DarkYellow"
                SayResposta "skip" "[CONVERSAO NAO NECESSARIA] Nenhuma Legenda PT-BR (PGS ou Texto) foi Identificada"
            }
        }
        Write-Host ""
    } catch {
        Say "        (Nao Foi Possivel Gerar o Diagnostico Previo. Seguindo com o Processamento Normal.)" "DarkGray"
    }

    SayTitulo "  PROCESSO INICIALIZADO:"

    try {
        <#  v14.13: AS ETAPAS PASSARAM DE 7 PARA 5.
            O usuario reclamou, com razao: "essas etapas de 1 a 7 ja deveriam
            ter virado outras etapas faz tempo". Duas das sete nunca foram
            trabalho:
              [1/7] era o DIAGNOSTICO (ffprobe/mkvmerge -J) - ele decide o que
                    vai ser feito, nao faz nada com o arquivo. Media 1s.
              [7/7] era a LIMPEZA dos temporarios. Fecha em 00m00s em TODOS os
                    logs medidos, sem excecao.
            Duas caixas de sete (29% da regua) reservadas pra 1 segundo de
            trabalho - e era dai que vinha o pedaco vazio no fim da barra do
            video durante a remontagem: a barra guardava lugar pra uma etapa
            que nao gasta tempo.
            Agora as duas tem MARCADOR PROPRIO ([DIAGNOSTICO] e [LIMPEZA]) em
            vez de numero. Elas continuam aparecendo e continuam com relogio
            proprio no log - so sairam da regua e da divisao do tempo.
        #>
        SayStep "[DIAGNOSTICO] Detectando Informacoes do Video (ffprobe):"
        $etapaIni = Get-Date
        $infoResult = Invoke-ProcessoComBarraEstimada -Exe $ffprobe -ArgList @("-v","error","-select_streams","v:0","-show_entries","stream=r_frame_rate,codec_name:format=duration","-of","json","$($f.FullName)") -EstimativaSegundos 3
        $infoJson = ($infoResult.Output -join "") | ConvertFrom-Json
        $fpsRaw = $infoJson.streams[0].r_frame_rate
        if ([string]::IsNullOrWhiteSpace($fpsRaw)) { throw "O ffprobe Nao Retornou FPS. O Arquivo Pode Estar Corrompido ou em Uso." }

        # FIX: antes, um arquivo que nao fosse HEVC (ex: AVC/H.264) ou que
        # simplesmente nao tivesse Dolby Vision seguia para as proximas
        # etapas mesmo assim - o filtro bsf hevc_mp4toannexb do [2/7] e
        # especifico de HEVC e falhava com um erro generico e confuso
        # ("Codigo 1") em arquivos AVC (confirmado com arquivo real,
        # Vampira 1974). Pior: em arquivos HEVC SEM Dolby Vision (confirmado
        # com arquivo real, Avatar Fire and Ash 2025 WEB-DL SDR), o dovi_tool
        # rodava sem erro (nao ha RPU para falhar) e o script reportava
        # "[OK] RPU Convertido para Profile 8.1" mesmo sem converter nada de
        # util - sucesso falso que so era descoberto depois de gastar tempo
        # com audio/legenda a toa (nesse caso real, 55+ minutos). Agora as
        # duas checagens acontecem cedo, aqui no [1/7], pulando o episodio
        # com mensagem clara em vez de seguir em frente.
        $codecVideoOrigem = $infoJson.streams[0].codec_name
        if ($codecVideoOrigem -notmatch "(?i)^hevc$") {
            throw ("Este Arquivo Nao E HEVC (Codec Detectado: {0}). O DDVT So Converte Dolby Vision em Video HEVC. Pulando Este Episodio." -f $codecVideoOrigem)
        }
        # Deteccao propria de Dolby Vision aqui (NAO reaproveita o $diagDV do
        # diagnostico previo de proposito): aquele bloco e "puramente
        # informativo" e engolido por um catch - se ele tivesse falhado por
        # um motivo transitorio, $diagDV ficaria nulo e um arquivo DV VALIDO
        # seria pulado por engano (falso negativo). Aqui a leitura e refeita
        # de forma confiavel, e o episodio so e pulado quando a deteccao
        # FUNCIONA e confirma que realmente nao ha Dolby Vision.
        $infoDV = Get-InfoDolbyVision -MkvPath $f.FullName
        if (-not $infoDV) {
            throw "Nenhum Dolby Vision Foi Identificado Neste Arquivo (o ffprobe Nao Encontrou RPU de Dolby Vision no Video). O DDVT E Especifico para Conversao de Perfil Dolby Vision - Este Arquivo Nao E um Candidato Valido para a Ferramenta. Pulando Este Episodio."
        }

        <#  v14.16: A DECISAO SOBRE O VIDEO PASSOU A SER TOMADA AQUI.
            Ate a 14.15 ela era tomada la dentro da [2/5], DEPOIS de ja ter
            extraido o video inteiro para um arquivo solto na [1/5]. Ou seja:
            o motor gastava 62 GB de disco e minutos de leitura para so entao
            descobrir que nao havia nada a fazer com aquele video.
            Sabendo agora - antes de tocar no arquivo - da para pular a [1/5]
            inteira e, principalmente, deixar o video DENTRO do container do
            comeco ao fim. Ver o cabecalho desta versao: e essa saida e volta
            pelo arquivo solto que quebrou o Se7en. #>
        $jaEhP8SemEL = ($infoDV -and $infoDV.Perfil -eq 8 -and ($infoDV.Camadas -notmatch "EL"))
        $videoDireto = $jaEhP8SemEL
        # Id da faixa de video no mkvmerge (nao no ffprobe): e o que vai no
        # --video-tracks quando o video for copiado direto da origem.
        $idVideoOrigem = -1
        try {
            $jsonOrigem = Get-MkvJson -MkvPath $f.FullName
            if ($jsonOrigem) {
                $faixasVideo = @($jsonOrigem.tracks | Where-Object { $_.type -eq "video" })
                if ($faixasVideo.Count -gt 0) { $idVideoOrigem = [int]$faixasVideo[0].id }
            }
        } catch { }
        if ($videoDireto -and $idVideoOrigem -lt 0) {
            # Sem o id nao da para pedir a faixa certa ao mkvmerge. Em vez de
            # arriscar um arquivo errado, volta para o caminho antigo.
            $videoDireto = $false
        }

        $duracaoTotal = 0.0
        [double]::TryParse($infoJson.format.duration, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$duracaoTotal) | Out-Null

        SayOk "FPS: $fpsRaw | Duracao: $(Format-Duracao $duracaoTotal)"

        $tamanhoOrigemBytes = $f.Length
        $driveWork = [System.IO.Path]::GetPathRoot($WorkDir)
        $espacoLivre = $null
        <#  14.32: catch VAZIO aqui apagava a trava inteira em silencio.
            Get-PSDrive resolve "C:\" mas nao resolve raiz de rede
            ("\\servidor\share"). Falhando, $espacoLivre ficava $null, o
            if abaixo era pulado e o episodio convertia SEM nenhuma
            conferencia de espaco - exatamente o que o throw mais adiante
            existe para evitar. Continua sem travar (nao da para travar em
            cima de uma conta que nao foi feita), mas agora AVISA. #>
        try {
            $espacoLivre = (Get-PSDrive -Name ($driveWork.TrimEnd('\','/').TrimEnd(':')) -ErrorAction Stop).Free
        } catch {
            SayWarn ("Nao Foi Possivel Medir o Espaco Livre em '{0}' - a Conferencia de Espaco Nao Vai Acontecer Neste Arquivo." -f $driveWork)
        }
        if ($null -ne $espacoLivre) {
            # 3,15x o tamanho da origem: video extraido + RPU convertido +
            # arquivo final sendo montado, temporariamente coexistindo no disco
            # (numero validado pelo usuario no processo manual do DDVT), mais uma
            # folga de 15% para os temporarios que o DeeZy cria ao converter a
            # faixa TrueHD/MLP para E-AC-3 Atmos.
            # v14.16: quando o video nao sai do container (ja e Profile 8.x),
            # os dois arquivos soltos de video simplesmente nao existem - so o
            # arquivo final e os temporarios de audio. A exigencia cai para
            # 1,6x, e arquivo grande deixa de ser recusado por espaco que o
            # motor nem ia usar.
            $fatorEspaco = if ($videoDireto) { 1.6 } else { 3.15 }
            $espacoNecessario = $tamanhoOrigemBytes * $fatorEspaco
            if ($espacoLivre -lt $espacoNecessario) {
                $faltamEpisodio = $espacoNecessario - $espacoLivre
                throw ("Espaco Insuficiente em {0} para Converter Este Arquivo com Seguranca. Necessario ~{1} (~{2}x o Tamanho do Arquivo), Disponivel {3}. Faltam ~{4}. Pulando Este Episodio para Nao Gerar um Arquivo Final Incompleto/Corrompido." -f $driveWork, (Format-Tamanho $espacoNecessario), ($fatorEspaco.ToString("0.##", [System.Globalization.CultureInfo]::InvariantCulture)), (Format-Tamanho $espacoLivre), (Format-Tamanho $faltamEpisodio))
            }
        }

        Say-TempoEtapa $etapaIni

        SayStep "[1/5] Extraindo Video Puro do MKV (ffmpeg, Sem Recodificar):"
        $etapaIni = Get-Date
        if ($videoDireto) {
            # v14.16: NAO EXTRAI. Ver o cabecalho desta versao.
            # Extrair so faz sentido quando alguem vai MEXER no fluxo de video
            # (o dovi_tool). Se ninguem vai mexer, tirar o video do container
            # e devolver depois nao melhora nada e pode quebrar: o arquivo
            # solto perde os timestamps e o cabecalho de codec do container, e
            # os dois tem que ser reconstruidos na remontagem.
            $p81Hevc = $null
            SayResposta "skip" ("[NAO NECESSARIO] O Video Ja Esta em {0} (BL+RPU, Sem Enhancement Layer) e Nao Sera Alterado. Ele Vai do MKV de Origem Direto para o MKV Final, Sem Sair do Container - Sem Perder Timestamps nem Cabecalho de Codec." -f $infoDV.Nome)
        } else {
            $ffArgs = @("-y","-v","error","-progress","pipe:1","-i","$($f.FullName)","-map","0:v:0","-c","copy","-bsf:v","hevc_mp4toannexb","-f","hevc","$rawHevc")
            $ffResult = Invoke-FfmpegComBarra -ArgList $ffArgs -DuracaoTotalSeg $duracaoTotal
            if ($ffResult.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $rawHevc) -or (Get-Item -LiteralPath $rawHevc).Length -eq 0) {
                throw "O ffmpeg Falhou ao Extrair o Video (Codigo $($ffResult.ExitCode))."
            }
            SayOk "Video Extraido: $(Format-Tamanho (Get-Item -LiteralPath $rawHevc).Length)"
        }
        Say-TempoEtapa $etapaIni

        SayStep "[2/5] Convertendo Dolby Vision para Profile 8.1 (dovi_tool):"
        $etapaIni = Get-Date
        # Verifica o perfil de origem: se ja for Profile 8.x SEM Enhancement
        # Layer, converter de novo nao muda nada de util - o video ja esta no
        # formato-alvo (BL+RPU). Nesse caso pulamos o dovi_tool e apenas
        # reaproveitamos o video extraido como se fosse o "_P81".
        # Reaproveita o $infoDV ja lido de forma confiavel na etapa [1/7]
        # (aquela leitura pula o episodio se nao houver DV, entao aqui
        # $infoDV nunca e nulo) - evita um segundo ffprobe no arquivo de
        # origem (que pode ser grande) bem no meio do processamento, sem
        # ganho nenhum.
        # v14.16: $jaEhP8SemEL agora e decidido la no [DIAGNOSTICO], antes de
        # qualquer coisa ser feita com o arquivo - e a [1/5] ja nao extraiu
        # nada. Aqui so resta registrar o status, nao ha arquivo solto para
        # renomear (era o Move-Item de $rawHevc para $p81Hevc, que sumiu junto
        # com a extracao desnecessaria).
        if ($jaEhP8SemEL) {
            $statusDV = "NAO_NECESSARIO"
            SayResposta "skip" ("[NAO NECESSARIO] Video Ja Esta em {0} (BL+RPU, Sem Enhancement Layer). Nenhuma Conversao de RPU a Fazer." -f $infoDV.Nome)
            <#  v14.18: O CAMINHO DE RECUO DA 14.16 ESTAVA QUEBRADO.
                Quando o video ja e Profile 8.x mas o mkvmerge -J nao devolve
                o id da faixa de video, a 14.16 desliga o $videoDireto e volta
                para o caminho antigo - a [1/5] extrai o video de novo. So que
                o Move-Item de $rawHevc para $p81Hevc tinha sido removido junto
                com a extracao, entao a [5/5] mandava o mkvmerge ler um arquivo
                que nunca foi criado. O recuo escolhia um caminho quebrado: o
                episodio ia ate o fim e morria com "mkvmerge Terminou com Erro"
                depois de ja ter gastado o disco e o tempo da extracao. #>
            if (-not $videoDireto) {
                Move-Item -LiteralPath $rawHevc -Destination $p81Hevc -Force
                if (-not (Test-Path -LiteralPath $p81Hevc) -or (Get-Item -LiteralPath $p81Hevc).Length -eq 0) {
                    throw "Falha ao Reaproveitar o Video Ja em Profile 8.x (Arquivo Vazio ou Inexistente)."
                }
            }
        } else {
            $statusDV = "OK"
            <#  v14.15: A ESTIMATIVA DO dovi_tool ERA 15 SEGUNDOS - FIXA.
                A curva chega a 99% em cerca de 4,6 x a estimativa, ou seja
                ~70s. Mas o dovi_tool leva MINUTOS num remux 4K:
                    Troia       87,00 GB -> 3m51s (231s)
                    Spider-Man  61,50 GB -> 3m23s (203s)
                    GoT S08E01  20,60 GB ->   49s
                Com 15s a barra encostava em 99% no primeiro minuto e ficava
                la pelos dois minutos seguintes - foi o "[3/7] fica em 99%
                durante 64% da etapa" que voce apontou.
                Os tres casos dao 2,4 a 3,3 segundos por GB. A estimativa agora
                acompanha o TAMANHO do arquivo: usando a mesma regra ja aplicada
                no seconv e no Corretor (a curva chega a ~90% em 2,3 x a
                estimativa), fica 2,8 / 2,3 = 1,2 segundo por GB.
                Piso de 8s para arquivo pequeno nao passar direto pelo 0%.
            #>
            $gbEntrada = 0.0
            try { $gbEntrada = [double]((Get-Item -LiteralPath $rawHevc).Length) / 1GB } catch { }
            $estDovi = [math]::Max(8.0, $gbEntrada * 1.2)
            $dvResult = Invoke-ProcessoComBarraEstimada -Exe $doviTool -ArgList @("-m","2","convert","--discard","-i","$rawHevc","-o","$p81Hevc") -EstimativaSegundos $estDovi
            if ($dvResult.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $p81Hevc) -or (Get-Item -LiteralPath $p81Hevc).Length -eq 0) {
                $detalhe = $dvResult.ErrorText.Trim()
                if ([string]::IsNullOrWhiteSpace($detalhe)) { $detalhe = "Sem Detalhes Retornados pelo dovi_tool (Codigo $($dvResult.ExitCode))" }
                throw "O dovi_tool Falhou na Conversao: $detalhe"
            }
            SayOk "RPU Convertido para Profile 8.1"
            Remove-Item -LiteralPath $rawHevc -Force -ErrorAction SilentlyContinue
        }
        Say-TempoEtapa $etapaIni

        SayStep "[3/5] Conversao de Audio para E-AC-3:"
        $etapaIni = Get-Date
        $eac3File = $null
        $eac3TrackName = "E-AC-3"
        $statusAudio = "NAO_NECESSARIO"
        $motivoAudio = ""
        $tipoConversaoAudio = ""
        $faixaPrincipal = Get-FaixaAudioPrincipal -MkvPath $f.FullName
        $codecAudioOrigem = if ($faixaPrincipal -and $faixaPrincipal.codec) { $faixaPrincipal.codec } else { "-" }
        # Indice real da faixa principal entre as faixas de audio (pode nao
        # ser mais "0" - ver Get-FaixaAudioPrincipal/Get-IndiceAudioNaFaixa).
        $indiceAudioPrincipal = Get-IndiceAudioNaFaixa -MkvPath $f.FullName -Faixa $faixaPrincipal
        # Controla quais faixas de audio ORIGINAIS entram no remux final -
        # tudo que nao for a faixa principal (e, quando aplicavel, a faixa
        # extra ja existente reaproveitada) e descartado (comentario,
        # dublagem, faixas extras). Preenchido conforme o resultado da
        # decisao abaixo; usado la no [6/7].
        $audioSemRestricao = $false   # $true = nao mexe em nada (faixa principal nao identificada - modo seguro)
        $idAudioExtra = $null         # Id de uma faixa ja existente reaproveitada (Atmos/JOC ou compativel)
        $audioPrincipalEhCompativel = $false  # $true = a propria faixa principal ja e E-AC-3/AC-3/AAC

        # Caminho curto para o arquivo de saida (o dee.exe e ferramentas legadas
        # nao suportam caminhos acima de 260 caracteres - MAX_PATH do Windows).
        $eac3Candidate = Join-Path $AudioWorkDir "atmos.ec3"
        if (Test-Path -LiteralPath $eac3Candidate) { Remove-Item -LiteralPath $eac3Candidate -Force -ErrorAction SilentlyContinue }

        if (-not $faixaPrincipal) {
            $motivoAudio = "Faixa de Audio Principal Nao Identificada"
            $audioSemRestricao = $true
            SayResposta "skip" "[NAO NECESSARIO] Nao Foi Possivel Identificar a Faixa de Audio Principal. Mantendo Todas as Faixas (Modo Seguro)."
        } elseif ((Test-EscolheuConverter $f.FullName) -eq $false) {
            # ---- v13.3: conversao DESLIGADA na escolha manual --------------
            # O usuario marcou MANTER na faixa principal. Entra antes de todos
            # os caminhos de conversao: nao ha o que decidir depois de uma
            # escolha explicita. A faixa fica como esta, e quais faixas vao
            # para o remux quem diz e o Resolve-FaixasDoRemux la no [6/7].
            $motivoAudio = "Conversao de Audio Desligada na Escolha Manual"
            $statusAudio = "JA_OTIMO"
            $audioPrincipalEhCompativel = $true   # o resultado e 'bom' por decisao do usuario
            SayResposta "skip" ("[NAO NECESSARIO] Conversao Desligada na Escolha Manual - a Faixa Principal ({0}) Sera Mantida Como Esta." -f $codecAudioOrigem)
        } elseif (Test-EhTrueHD $faixaPrincipal) {
            # ---- Caminho 1: Dolby TrueHD/MLP -> E-AC-3 Atmos (DeeZy + DEE) ----
            # REGRA: se a faixa principal e TrueHD, SEMPRE converter para
            # E-AC-3 Atmos (JOC) - independente de existir qualquer outra
            # faixa E-AC-3/AC-3 comum no arquivo. O objetivo e manter o
            # MELHOR audio disponivel (Atmos), nao so "um audio que funcione".
            # Unica excecao: se o arquivo JA tiver uma faixa E-AC-3 Atmos/JOC
            # separada (ex: alguem ja fez essa conversao antes) - nesse caso
            # nao ha o que fazer de novo.
            $faixaAtmosExistente = Get-FaixaAtmosJocExistente -MkvPath $f.FullName -FaixaExcluir $faixaPrincipal
            if ($faixaAtmosExistente) {
                $idAudioExtra = $faixaAtmosExistente.id
                $motivoAudio = "Arquivo Ja Possui Faixa E-AC-3 Atmos/JOC"
                $statusAudio = "JA_OTIMO"
                SayResposta "skip" ("[NAO NECESSARIO] O Arquivo Ja Possui uma Faixa E-AC-3 Atmos/JOC ({0})." -f $faixaAtmosExistente.codec)
            } elseif (-not $temDeezy) {
                $motivoAudio = "DeeZy Indisponivel"
                SayResposta "skip" "[NAO NECESSARIO] Faixa TrueHD Presente, Mas o DeeZy Nao Esta Disponivel. Seguindo Sem a Faixa E-AC-3."
            } else {
                $tipoConversaoAudio = "TRUEHD"
                $eac3TrackName = "E-AC-3 Atmos"
                Say ("        Faixa Dolby TrueHD/MLP Detectada ({0}). Convertendo para E-AC-3 Atmos via DeeZy..." -f $codecAudioOrigem) "DarkGray"
                $deezyArgs = @(
                    "encode", "atmos",
                    "--atmos-mode", "bluray",
                    "--bitrate", "$ATMOS_BITRATE",
                    "--track-index", "$indiceAudioPrincipal",
                    "--temp-dir", "$AudioWorkDir",
                    "--output", "$eac3Candidate",
                    "--overwrite"
                )
                # Passa os caminhos internos explicitamente quando existirem (mais
                # robusto que confiar so no auto-discovery da pasta apps\).
                if (Test-Path -LiteralPath $deezyFfmpeg)  { $deezyArgs += @("--ffmpeg",  "$deezyFfmpeg") }
                if (Test-Path -LiteralPath $deezyDee)     { $deezyArgs += @("--dee",     "$deezyDee") }
                if (Test-Path -LiteralPath $deezyTruehdd) { $deezyArgs += @("--truehdd", "$deezyTruehdd") }
                $deezyArgs += "$($f.FullName)"
                $deezyResult = Invoke-DeezyComBarra -ArgList $deezyArgs
                if ($deezyResult.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $eac3Candidate) -or (Get-Item -LiteralPath $eac3Candidate).Length -eq 0) {
                    $textoErroAudio = Get-ResumoErro -Linhas $deezyResult.Output -TextoErro $deezyResult.ErrorText -MaxChars 320
                    if ([string]::IsNullOrWhiteSpace($textoErroAudio)) { $textoErroAudio = "Codigo $($deezyResult.ExitCode)" }
                    # Dica automatica: "Cannot open/write file" no DEE quase sempre e
                    # limite de caminho (MAX_PATH, 260 caracteres) - problema legado
                    # do Windows, tanto para arquivos de entrada quanto de saida.
                    if ($textoErroAudio -match "(?i)cannot (open|write) file") {
                        $textoErroAudio += " [Provavel Causa: Caminho de Arquivo Excedeu 260 Caracteres (Limite Classico do Windows)]"
                    }
                    # v13.6: cancelar MATA o processo de audio, e sem esta guarda
                    # o motor lia a morte do processo como "falha de audio" - o
                    # MODO SEGURO entrava e seguia para as etapas 5/6/7 como se
                    # nada tivesse acontecido. Resultado: nenhum resumo final, saida
                    # parcial de 0 KB largada e o processo preso segurando o log.
                    # Mesma guarda que ja existe no fim do episodio: joga no catch
                    # que apaga a saida parcial e registra CANCELADO corretamente.
                    if ($script:CancelamentoSolicitado) {
                        throw "Operacao Cancelada pelo Usuario ([ESC])."
                    }
                    $statusAudio = "ERRO"
                    $motivoAudio = $textoErroAudio
                    SayWarn "A Conversao de Audio Falhou. Seguindo Sem a Faixa E-AC-3. Detalhes Completos no Resumo Final Desta Execucao."
                } else {
                    $eac3File = $eac3Candidate
                    $statusAudio = "OK"
                    SayOk ("Audio Convertido para E-AC-3 Atmos ({0})" -f (Format-Tamanho (Get-Item -LiteralPath $eac3Candidate).Length))
                }
            }
        } elseif (Test-EhDts $faixaPrincipal) {
            # ---- Caminho 2: Familia DTS -> E-AC-3 comum (ffmpeg) --------------
            # Cobre DTS, DTS-ES, DTS-HD High Resolution, DTS-HD Master Audio e
            # DTS:X. A familia DTS nao carrega metadado Dolby Atmos, entao a
            # faixa gerada e um E-AC-3 padrao (sem Atmos), decodificada e
            # recodificada pelo proprio ffmpeg - nao passa pelo DeeZy/DEE.
            # REGRA: so converte se NAO existir, em outra faixa nao-comentario
            # do arquivo, um audio ja compativel com a TV (E-AC-3/AC-3/AAC)
            # E NO MESMO IDIOMA da principal (v13.2: uma dublagem pt-BR nao
            # substitui o audio original em ingles - ver Test-IdiomaConflitante).
            # Se ja existir, nao faz sentido gastar tempo convertendo o DTS -
            # o player ja tem uma faixa funcional para usar (diferente do
            # TrueHD, aqui nao ha "qualidade Atmos" a preservar).
            $faixaCompativelExistente = Get-FaixaCompativelC2Externa -MkvPath $f.FullName -FaixaExcluir $faixaPrincipal
            if ($faixaCompativelExistente) {
                $idAudioExtra = $faixaCompativelExistente.id
                $motivoAudio = "Ja Existe Faixa E-AC-3/AC-3 Compativel no Arquivo"
                $statusAudio = "JA_OTIMO"
                SayResposta "skip" "[NAO NECESSARIO] Ja Existe uma Faixa E-AC-3/AC-3 Compativel no Arquivo."
            } else {
                $tipoConversaoAudio = "DTS"
                $eac3TrackName = "E-AC-3"
                Say ("        Faixa da Familia DTS Detectada ({0}). Convertendo para E-AC-3 via ffmpeg..." -f $codecAudioOrigem) "DarkGray"
                $ffAudioArgs = @(
                    "-y","-v","error","-progress","pipe:1",
                    "-i","$($f.FullName)",
                    "-map","0:a:$indiceAudioPrincipal",
                    "-c:a","eac3",
                    "-b:a","${DTS_EAC3_BITRATE}k"
                )
                # O encoder E-AC-3 do ffmpeg suporta ate 5.1: se a origem tiver mais
                # canais (ex: DTS-HD MA 7.1), faz downmix automatico para 6 canais.
                $canaisOrigem = 0
                if ($faixaPrincipal.properties -and $faixaPrincipal.properties.audio_channels) {
                    $canaisOrigem = [int]$faixaPrincipal.properties.audio_channels
                }
                if ($canaisOrigem -gt 6) { $ffAudioArgs += @("-ac","6") }
                $ffAudioArgs += "$eac3Candidate"
                $ffAudioResult = Invoke-FfmpegComBarra -ArgList $ffAudioArgs -DuracaoTotalSeg $duracaoTotal
                if ($ffAudioResult.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $eac3Candidate) -or (Get-Item -LiteralPath $eac3Candidate).Length -eq 0) {
                    $textoErroAudio = Get-ResumoErro -Linhas $ffAudioResult.Output -TextoErro $ffAudioResult.ErrorText -MaxChars 320
                    if ([string]::IsNullOrWhiteSpace($textoErroAudio)) { $textoErroAudio = "Codigo $($ffAudioResult.ExitCode)" }
                    # v13.6: cancelar MATA o processo de audio, e sem esta guarda
                    # o motor lia a morte do processo como "falha de audio" - o
                    # MODO SEGURO entrava e seguia para as etapas 5/6/7 como se
                    # nada tivesse acontecido. Resultado: nenhum resumo final, saida
                    # parcial de 0 KB largada e o processo preso segurando o log.
                    # Mesma guarda que ja existe no fim do episodio: joga no catch
                    # que apaga a saida parcial e registra CANCELADO corretamente.
                    if ($script:CancelamentoSolicitado) {
                        throw "Operacao Cancelada pelo Usuario ([ESC])."
                    }
                    $statusAudio = "ERRO"
                    $motivoAudio = $textoErroAudio
                    SayWarn "A Conversao de Audio Falhou. Seguindo Sem a Faixa E-AC-3. Detalhes Completos no Resumo Final Desta Execucao."
                } else {
                    $eac3File = $eac3Candidate
                    $statusAudio = "OK"
                    SayOk ("Audio Convertido para E-AC-3 ({0})" -f (Format-Tamanho (Get-Item -LiteralPath $eac3Candidate).Length))
                }
            }
        } elseif (Test-EhCompativelC2 $faixaPrincipal) {
            # Faixa principal ja e E-AC-3/AC-3/AAC: ja roda nativamente na TV
            # (ex: LG C2). Nao ha TrueHD para preservar em Atmos nem DTS para
            # substituir - nenhuma conversao e necessaria. Como a propria
            # faixa principal ja e uma boa faixa compativel, o descarte das
            # demais faixas extras PODE acontecer (a experiencia final e boa).
            $audioPrincipalEhCompativel = $true
            $motivoAudio = "Faixa Principal Ja Esta em $codecAudioOrigem (Compativel)"
            $statusAudio = "JA_OTIMO"
            SayResposta "skip" ("[NAO NECESSARIO] Faixa de Audio Principal Ja Esta em {0} (Compativel)." -f $codecAudioOrigem)
        } else {
            # Codec fora dos casos tratados (ex: PCM/LPCM, FLAC). Nao e TrueHD
            # nem DTS, e nao esta na lista de "compativel com a TV". Nao ha
            # como/porque converter a faixa principal em si (e lossless e nao
            # ha metadado Atmos a preservar - decodificar pra E-AC-3 so
            # perderia qualidade sem ganho). MAS: se o arquivo JA tiver, em
            # outra faixa nao-comentario, um audio compativel com a TV
            # (E-AC-3/AC-3/AAC), vale a pena promover essa faixa como padrao -
            # assim o player pega direto uma faixa que roda nativamente, sem
            # depender do LPCM/FLAC (que da problema em varios setups Plex/TV).
            # O principal lossless NAO e descartado: ele e mantido junto (vira
            # nao-padrao). Isso espelha o comportamento do caminho DTS.
            # Se NAO houver nenhuma faixa compativel existente, cai no MODO
            # SEGURO puro (mantem tudo, sem eleger padrao) - ver bloco abaixo.
            $faixaCompativelExistente = Get-FaixaCompativelC2Externa -MkvPath $f.FullName -FaixaExcluir $faixaPrincipal
            if ($faixaCompativelExistente) {
                $idAudioExtra = $faixaCompativelExistente.id
                $motivoAudio = "Faixa Principal em $codecAudioOrigem, Mas Ja Existe Faixa E-AC-3/AC-3 Compativel no Arquivo"
                $statusAudio = "JA_OTIMO"
                SayResposta "skip" ("[NAO NECESSARIO] Faixa Principal em {0} (Nao Tratado), Mas o Arquivo Ja Possui uma Faixa E-AC-3/AC-3 Compativel ({1}) - Ela Sera a Padrao." -f $codecAudioOrigem, $faixaCompativelExistente.codec)
            } else {
                $motivoAudio = "Faixa Principal em $codecAudioOrigem (Mantida)"
                SayResposta "skip" ("[NAO NECESSARIO] Faixa de Audio Principal em {0}. Mantida Como Esta." -f $codecAudioOrigem)
            }
        }

        # ---- Resolve quais faixas de audio ORIGINAIS vao para o remux -----
        # REGRA DE SEGURANCA: so descarta faixas de audio quando o resultado
        # final e comprovadamente BOM - ou seja, quando existe pelo menos uma
        # faixa que atende ao objetivo:
        #   (a) uma faixa E-AC-3 NOVA foi gerada com sucesso ($eac3File), OU
        #   (b) uma faixa extra ja existente foi reaproveitada ($idAudioExtra
        #       - Atmos/JOC no caso TrueHD, ou E-AC-3/AC-3 no caso DTS), OU
        #   (c) a propria faixa principal ja e compativel com a TV
        #       ($audioPrincipalEhCompativel - E-AC-3/AC-3/AAC).
        # Se NADA disso valer (ex: TrueHD sem DeeZy, DTS cuja conversao
        # falhou, ou codec nao tratado como PCM/FLAC), entra em MODO SEGURO:
        # nenhuma faixa de audio e descartada - o arquivo mantem todas as
        # faixas originais como estao. Assim nunca ficamos presos a uma unica
        # faixa que pode nao ser ideal para reproduzir.
        #
        # O Id que fica marcado como faixa padrao (--default-track):
        #   - Se uma faixa NOVA foi gerada -> ela sera a padrao (marcada la
        #     embaixo, ao adiciona-la); as originais mantidas ficam nao-padrao.
        #   - Senao, se uma faixa extra existente foi reaproveitada -> ela.
        #   - Senao (principal ja compativel) -> a propria faixa principal.
        $idsAudioManter = @()
        $idAudioDefault = $null
        $resultadoAudioBom = ($null -ne $eac3File) -or ($null -ne $idAudioExtra) -or $audioPrincipalEhCompativel
        if (-not $audioSemRestricao -and $faixaPrincipal -and $resultadoAudioBom) {
            $idsAudioManter = @($faixaPrincipal.id)
            # v14.18: $idAudioExtra pode valer 0 (a faixa de audio vem antes
            # do video na lista do mkvmerge). Zero e FALSO em PowerShell, entao
            # o teste de verdade simples descartava justamente a faixa que a
            # mensagem tinha acabado de dizer que ia manter. O proprio codigo ja
            # sabia disso duas linhas acima ($resultadoAudioBom usa -ne $null).
            if ($null -ne $idAudioExtra) { $idsAudioManter += $idAudioExtra }
            if ($eac3File) {
                $idAudioDefault = $null   # a faixa NOVA (adicionada depois) sera a padrao
            } elseif ($null -ne $idAudioExtra) {
                $idAudioDefault = $idAudioExtra
            } else {
                $idAudioDefault = $faixaPrincipal.id
            }
        } else {
            # Modo seguro: garante que nenhum descarte de audio acontece.
            $audioSemRestricao = $true
        }
        Say-TempoEtapa $etapaIni

        SayStep "[4/5] Conversao de Legenda PGS para .SRT:"
        $etapaIni = Get-Date
        <#  v14.34: MARCA A HORA EM QUE A LEGENDA COMECOU.
            Serve para a faxina do fim: tudo que aparecer em _corretor\ e
            _reocr\ depois deste instante foi ESTE arquivo que gerou, e so
            isso pode ser apagado quando a legenda sair limpa. Sem a marca a
            faxina teria que adivinhar por nome, e o relatorio (que se chama
            relatorio_corretor_<data>.txt) nao carrega o nome do filme. #>
        $script:T0Legenda = Get-Date
        $statusLegenda = "NAO_NECESSARIO"
        $motivoLegenda = ""
        $idLegendaPtBrOriginal = $null   # Id da faixa pt-BR ja existente (texto), se reaproveitada
        $idLegendaPtBrOriginalPgs = $null  # v14.23: Id da faixa PGS pt-BR que virou SRT - agora MANTIDA no final
        # v14.28: nota da legenda deste arquivo. Zerada aqui: sao POR ARQUIVO,
        # senao o segundo episodio da fila herdaria a nota do primeiro.
        $script:NotaLegendaVeredicto = ""
        $script:NotaLegendaDefeitos  = -1
        $script:NotaLegendaPct       = ""
        $script:NotaLegendaBlocos    = 0
        # v14.30: o seconv foi tentado e recusado NESTE arquivo? Zerada aqui
        # pelo mesmo motivo das notas acima - e por arquivo, nao por fila.
        # Quem le isto e a Invoke-CorretorLegenda, pra nao mandar o Corretor
        # rodar o mesmo seconv de novo. Ver o comentario la.
        $script:SeconvRecusadoNesteArquivo = $false
        # v14.31: contador de bloco do Reocr - por arquivo, como todo o resto.
        $script:UltimoBlocoReocr = 0
        $nomeLegendaPgsOrigem = $null    # Nome da faixa PGS pt-BR de origem, se convertida via OCR

        $trackTexto = Get-FaixaLegendaPtBrTexto -MkvPath $f.FullName
        if ($trackTexto) {
            # ---- Caminho 1: PT-BR ja pronta em texto (SRT/ASS) -----------
            # v14.10: faixa sem nome saia com aspas vazias no log
            # ("na Faixa 4 ''" - GoT S08E01, log de 13/08 13:54). Aspas
            # vazias parecem defeito de codigo; agora ou vem o nome ou nao
            # vem nada.
            $nomeFaixaTexto = ""
            if ($trackTexto.properties.track_name) { $nomeFaixaTexto = " '" + $trackTexto.properties.track_name + "'" }
            SayResposta "skip" ("[NAO NECESSARIO] Legenda 'PT-BR .SRT' na Faixa " + $trackTexto.id + $nomeFaixaTexto)
            $statusLegenda = "JA_TEXTO"
            $idLegendaPtBrOriginal = $trackTexto.id
        } elseif (-not $temSeconv -and -not $temOcr) {
            SayResposta "skip" "[NAO NECESSARIO] Nem seconv Nem PgsToSrt Instalados. Sem OCR."
        } else {
            # ---- Caminho 2: PT-BR so existe em PGS - precisa de OCR ------
            $track = Find-PtBrPgsTrack -MkvPath $f.FullName
            if (-not $track) {
                SayResposta "skip" "[NAO NECESSARIO] Nenhuma Legenda PT-BR (PGS ou Texto) Identificada Neste Episodio."
            } else {
                $nomeFaixaPgs = ""
                if ($track.properties.track_name) { $nomeFaixaPgs = " '" + $track.properties.track_name + "'" }
                Say ("        Legenda PT-BR Encontrada na Faixa " + $track.id + $nomeFaixaPgs) "DarkGray"
                # v14.23: guardado para o [5/5] poder MANTER a PGS original no
                # arquivo final ao lado do SRT gerado (decisao de 22/08).
                $idLegendaPtBrOriginalPgs = $track.id
                $srtCandidate = Join-Path $WorkDir ($name + "_ptbr.srt")
                if (Test-Path -LiteralPath $srtCandidate) { Remove-Item -LiteralPath $srtCandidate -Force }

                <#  v14.11: REPARTICAO DA BARRA DA [5/7].
                    Esta etapa roda de UM a QUATRO programas em sequencia, e
                    ate a 14.10 cada um desenhava a barra de 0 a 100 por conta
                    propria - a barra da mesma etapa enchia, zerava e enchia
                    de novo. Aqui cada sub-etapa que VAI rodar recebe um
                    pedaco da barra, calculado ANTES de comecar, e o total
                    fecha em 100 uma vez so. Se o Reocr nao estiver
                    disponivel, o pedaco dele vai pra quem roda por ultimo -
                    a barra nunca "sobra" faltando um naco no fim.
                #>
                <#  v14.12: os tamanhos das faixas agora vem de TEMPO MEDIDO,
                    nao de chute. Troia (3h16), log de 18/08:
                        seconv .....  4m23s   (263s,  33%)
                        PgsToSrt ...    47s   ( 47s,   6%)
                        Corretor ...  2m16s   (136s,  17%)
                        Reocr ......  5m43s   (343s,  43%)
                    Na 14.11 o Reocr tinha 5% da barra pra 43% do trabalho -
                    o mesmo erro de peso que a JANELA ja tinha corrigido nas
                    etapas grandes, repetido aqui dentro em miniatura.
                #>
                $fimSeconv = 35
                $iniPgs = 35; $fimPgs = 42
                $iniCorretor = 42; $fimCorretor = 58
                if (-not $temSeconv) {
                    # sem seconv, o PgsToSrt e o Corretor herdam a faixa dele
                    $iniPgs = 0; $fimPgs = 12; $iniCorretor = 12; $fimCorretor = 45
                }
                $iniReocr = $fimCorretor
                if (-not $temReocr) {
                    # sem Reocr, quem roda por ultimo fecha em 100
                    $fimCorretor = 100
                    <#  v14.18: AQUI TAMBEM SE DAVA $fimSeconv = 100, E ISSO
                        FAZIA A BARRA VOLTAR. "100" significa "o seconv e o
                        ultimo, pode fechar a barra" - mas era decidido ANTES
                        de saber se o seconv ia ser aceito. Numa maquina com
                        seconv e sem Tesseract standalone (configuracao comum,
                        o proprio programa diz que o Tesseract e opcional), a
                        barra da [4/5] subia ate 99%, o motor imprimia "seconv
                        Gerou a Legenda, mas o Motor Recusou" e a barra CAIA
                        para 35%, porque o PgsToSrt entra na faixa 35..42 e a
                        troca de faixa zera a trava de nao-retroceder.
                        O seconv nunca fecha a barra: se ele for aceito, quem
                        fecha e o Corretor, que roda depois dele de qualquer
                        jeito. #>
                }

                $viaSeconv = $false
                if ($temSeconv) {
                    # v14.2: seconv/BinaryOCR - PREFERENCIAL. Ja resolveu o
                    # problema real (blocos-lixo tipo "OITECT") no teste de
                    # 12/08, sem os erros pontuais que o Tesseract deixava.
                    # v14.5: BUG REAL CORRIGIDO - o seconv casa o
                    # --track-number contra o TrackNumber do MATROSKA (1-based,
                    # do cabecalho do arquivo), e nao contra o "id" do mkvmerge
                    # (0-based, posicional). Confirmado no fonte do seconv
                    # (ContainerSubtitleLoader.LoadMatroska faz
                    # "options.TrackNumbers.Contains(track.TrackNumber)", onde
                    # TrackNumber vem do elemento Matroska TrackNumber) e no
                    # PgsToSrt, que faz "track++" no Runner justamente pra
                    # converter o id do mkvmerge nesse numero - por isso o
                    # caminho do PgsToSrt sempre funcionou com $track.id e o do
                    # seconv "falhava por algum motivo". Os dois numeros vem de
                    # graca no mkvmerge -J: .id e .properties.number. Usar o
                    # number, que e o valor exato - somar 1 no id so acerta
                    # quando as faixas sao contiguas comecando em 1.
                    $numeroSeconv = if ($null -ne $track.properties.number) { [int]$track.properties.number } else { [int]$track.id + 1 }
                    $idiomaSeconv = if ($track.properties.language) { [string]$track.properties.language } else { "" }
                    SaySub "OCR rapido (seconv / BinaryOCR)" 0 $fimSeconv
                    $ocrResult = Invoke-SeconvOcrComProgresso -MkvPath $f.FullName -TrackId $numeroSeconv -DestinoSrt $srtCandidate -IdiomaEsperado $idiomaSeconv
                    if ($ocrResult.Sucesso) { $viaSeconv = $true }
                }
                if (-not $viaSeconv) {
                    # Rede de seguranca: seconv ausente OU falhou nesta rodada.
                    # PgsToSrt/Tesseract de sempre, seguido do Corretor_Legenda
                    # automatico (mesma logica da v14.1) - nunca fica sem nada.
                    if ($temSeconv) {
                        # v14.10: a manchete agora conta o que de fato aconteceu.
                        # Ver o comentario "MotivoRecusa" em Invoke-SeconvOcrComProgresso.
                        $motivoSeconv = ""
                        if ($ocrResult -and $ocrResult.ContainsKey("MotivoRecusa")) { $motivoSeconv = [string]$ocrResult.MotivoRecusa }
                        <#  v14.30: MARCA A RECUSA PARA O CORRETOR NAO REPETIR.
                            So marca quando o seconv RODOU e a leitura foi
                            recusada por qualidade ('*' demais) ou por idioma -
                            nesses dois casos repetir da o mesmo resultado,
                            porque e o mesmo programa lendo a mesma imagem com
                            o mesmo Latin.db.
                            NAO marca quando o seconv nem gerou legenda: ali a
                            causa pode ser outra (faixa errada, arquivo em uso)
                            e a 2a opiniao ainda pode ter valor. #>
                        if ($motivoSeconv -like "qualidade:*" -or $motivoSeconv -eq "idioma") {
                            $script:SeconvRecusadoNesteArquivo = $true
                        }
                        if ($motivoSeconv -like "qualidade:*") {
                            $pctRuim = $motivoSeconv.Split(":")[1]
                            SayWarn ("seconv Gerou a Legenda, mas o Motor Recusou: " + $pctRuim + "% dos Caracteres Sairam como '*'. Refazendo com PgsToSrt (Tesseract).")
                        } elseif ($motivoSeconv -eq "idioma") {
                            SayWarn "seconv Gerou Legenda de OUTRO Idioma - Recusada pelo Motor. Refazendo com PgsToSrt (Tesseract)."
                        } else {
                            SayWarn "seconv Nao Gerou Legenda. Tentando PgsToSrt (Tesseract) Como Alternativa."
                        }
                        # v14.4: antes o motivo real do seconv falhar ficava
                        # escondido (so "Nao Gerou Legenda", sem dizer por que)
                        # - agora mostra as ultimas linhas da saida dele, pra
                        # nao precisar adivinhar de novo na proxima falha.
                        $linhasSeconv = @($ocrResult.Output | Where-Object { $_ -and $_.Trim() -ne "" } | Select-Object -Last 6)
                        foreach ($ln in $linhasSeconv) { Say ("        seconv: " + $ln) "DarkGray" }
                    }
                    $ocrArgs = @("--input", "$($f.FullName)", "--track", "$($track.id)", "--output", "$srtCandidate", "--tesseractlanguage", "por", "--tesseractdata", "$tessData")
                    # v14.11: o seconv saiu de cena; quem sobrou passa a poder
                    # fechar a barra. Sem isto, num caso "seconv falhou e nao
                    # tem Reocr" a etapa terminaria com a barra em 70%.
                    if (-not $temReocr) { $fimCorretor = 100 }
                    <#  v14.18: FALTAVA A GUARDA DO $temOcr AQUI.
                        A entrada deste bloco aceita "seconv OU PgsToSrt". O
                        caminho do seconv e guardado; este NAO era. Numa
                        maquina com seconv e sem PgsToSrt (ou sem o .NET 8,
                        que ja desliga $temOcr la em cima com a mensagem "OCR
                        de Legenda Sera Desativado Nesta Execucao"), o seconv
                        rodava, era recusado pela trava de qualidade, e o
                        motor tentava iniciar um .exe inexistente. Isso e erro
                        terminante: o episodio INTEIRO caia no catch e o
                        arquivo final era apagado - horas de extracao, dovi
                        e DeeZy jogadas fora por causa de uma sub-etapa de
                        legenda, que e opcional.
                        Legenda que nao da para fazer nao derruba episodio. #>
                    if (-not $temOcr) {
                        SayWarn "PgsToSrt Nao Esta Disponivel Nesta Maquina - Sem Segunda Tentativa de OCR. O Episodio Continua Sem a Legenda Nova."
                        # Objeto de mentira nao: um resultado de verdade,
                        # dizendo o que houve, para o bloco de erro logo
                        # abaixo montar a mensagem certa em vez de "Codigo ".
                        $ocrResult = @{ ExitCode = -1; TrocasAcento = 0
                                        Output = @("PgsToSrt nao instalado ou .NET Desktop Runtime 8.0 ausente") }
                    } else {
                        SaySub "OCR completo (PgsToSrt / Tesseract)" $iniPgs $fimPgs
                        $ocrResult = Invoke-PgsToSrtComProgresso -ArgList $ocrArgs
                    }
                }

                if ((Test-Path -LiteralPath $srtCandidate) -and (Get-Item -LiteralPath $srtCandidate).Length -gt 0) {
                    $srtPtBr = $srtCandidate
                    $statusLegenda = "OK"
                    if ($viaSeconv -and $ocrResult.TrocasAcento -gt 0) {
                        SayOk "Legenda Convertida com Sucesso (seconv/BinaryOCR, $($ocrResult.TrocasAcento) Acento(s) Corrigido(s))"
                    } elseif ($viaSeconv) {
                        SayOk "Legenda Convertida com Sucesso (seconv/BinaryOCR)"
                    } else {
                        SayOk "Legenda Convertida com Sucesso (PgsToSrt)"
                        # so roda o Corretor_Legenda quando o caminho foi o
                        # PgsToSrt/Tesseract - o seconv ja nao produz o tipo
                        # de lixo que o Corretor foi feito pra pegar
                        if ($temCorretor) {
                            SaySub "Revisao de blocos-lixo (Corretor_Legenda)" $iniCorretor $fimCorretor
                            $srtCorrigido = Invoke-CorretorLegenda -MkvPath $f.FullName -SrtPath $srtCandidate
                            if ($srtCorrigido) {
                                $srtPtBr = $srtCorrigido
                                SayOk "Corretor_Legenda Revisou e Corrigiu Blocos-Lixo do OCR"
                            }
                        }
                    }

                    <#  v14.11: RE-OCR DAS FALAS CURTAS - a ultima sub-etapa.
                        Roda nos DOIS caminhos (seconv e PgsToSrt) de proposito:
                        o alvo dele nao e o motor de OCR, e o TAMANHO da fala.
                        Bloco de uma ou duas palavras e o pior caso dos dois
                        (no PgsToSrt vira "INF TOL"; no seconv vira "*"), e a
                        regra de suspeita dele - letra sozinha, ou palavra toda
                        maiuscula fora do dicionario - pega os dois formatos.
                        Ele so TROCA um bloco quando o resultado novo passa na
                        trava dele; nos testes de 13/08 foram 8 de 8 blocos,
                        duas rodadas seguidas com saida identica byte a byte, e
                        zero bloco bom estragado.
                        E aqui, dentro da [5/7], que ele precisava estar: o
                        .srt que sai desta linha e o mesmo que a [6/7] entrega
                        pro mkvmerge. Como ferramenta solta ele corrigia um
                        arquivo que ninguem mais lia.
                    #>
                    if ($temReocr) {
                        # v14.12: se o seconv foi aceito, PgsToSrt e Corretor
                        # nao rodaram - a faixa deles vai toda pro Reocr, em
                        # vez de a barra dar um pulo de 35 pra 58 do nada.
                        $iniReocrReal = $iniReocr
                        if ($viaSeconv) { $iniReocrReal = $fimSeconv }
                        SaySub "Re-OCR de falas curtas (Reocr_Legenda / Tesseract PSM 6)" $iniReocrReal 100
                        $reocrRes = Invoke-ReocrLegenda -MkvPath $f.FullName -SrtPath $srtPtBr
                        if ($reocrRes -and $reocrRes.Caminho) {
                            $srtPtBr = $reocrRes.Caminho
                            if ($reocrRes.Trocados -gt 0) {
                                SayOk ("Reocr_Legenda Refez " + $reocrRes.Trocados + " Fala(s) Curta(s) em PSM 6 (ex: 'INF TOL' -> 'Nao!')")
                            } else {
                                SayOk "Reocr_Legenda Revisou as Falas Curtas Suspeitas (PSM 6)"
                            }

                            <#  v14.27: A NOTA DA LEGENDA NA TELA DA CONVERSAO.
                                O Reocr 1.18 fecha o relatorio dele com um
                                veredicto (BOA / RAZOAVEL / RUIM) calculado em
                                cima do que sobrou de defeito conhecido. Esse
                                numero so servia para quem abrisse o relatorio.
                                Repetido aqui, ele responde na hora a pergunta
                                que o usuario sempre teve: "posso confiar nesta
                                legenda ou uso a PGS original?" - e a PGS
                                original esta no arquivo justamente para isso.
                                Uma linha so, com a cor do veredicto.  #>
                            if ($reocrRes.Veredicto -ne "") {
                                # v14.28: guardado para o resumo do arquivo, la embaixo.
                                $script:NotaLegendaVeredicto = $reocrRes.Veredicto
                                $script:NotaLegendaDefeitos  = $reocrRes.NotaDefeitos
                                $script:NotaLegendaPct       = $reocrRes.NotaPct
                                $script:NotaLegendaBlocos    = $reocrRes.NotaBlocos
                                $txtNota = "Qualidade da Legenda: " + $reocrRes.Veredicto
                                if ($reocrRes.NotaDefeitos -ge 0) {
                                    $txtNota = $txtNota + " (" + $reocrRes.NotaDefeitos + " bloco(s) com defeito, " + $reocrRes.NotaPct + "%)"
                                }
                                <#  v14.31: EXCELENTE CAIA NO ELSE E LEVAVA A FRASE DE RUIM.
                                    Este if tratava BOA e RAZOAVEL por nome e jogava TODO
                                    o resto no else - inclusive EXCELENTE, que o Reocr
                                    devolve quando NAO sobrou defeito nenhum.
                                    Registrado no log do Se7en de 27/08 00h32:
                                      [AVISO] Qualidade da Legenda: EXCELENTE
                                              (0 bloco(s) com defeito, 0,00%)
                                              - recomendo assistir pela faixa PGS original
                                    A melhor nota possivel saindo em AMARELO, com [AVISO],
                                    mandando o usuario NAO usar a legenda que acabou de
                                    sair perfeita. Agora EXCELENTE tem ramo proprio. #>
                                if ($reocrRes.Veredicto -ceq "EXCELENTE") {
                                    SayOk ($txtNota + " - nenhuma falha encontrada, pode assistir por ela")
                                } elseif ($reocrRes.Veredicto -ceq "BOA") {
                                    SayOk $txtNota
                                } elseif ($reocrRes.Veredicto -ceq "RAZOAVEL") {
                                    SayWarn ($txtNota + " - se tropecar numa fala, troque para a faixa PGS original no player")
                                } else {
                                    SayWarn ($txtNota + " - recomendo assistir pela faixa PGS original, que esta no arquivo")
                                }
                            }
                        }
                    }

                    # Fecha a barra da etapa UMA vez, aqui, depois que a ultima
                    # sub-etapa terminou de verdade.
                    Reset-FaixaBarra
                    Show-BarraCompleta
                    $nomeLegendaPgsOrigem = if ([string]::IsNullOrWhiteSpace($track.properties.track_name)) { "Portugues (Brasil)" } else { $track.properties.track_name }
                } else {
                    # v14.11: deu errado - a faixa volta ao padrao pra nao
                    # contaminar a proxima etapa que use a barra.
                    Reset-FaixaBarra
                    $textoOcr = ($ocrResult.Output -join " ")
                    $statusLegenda = "ERRO"
                    if ($textoOcr -match "\.NET" -and $textoOcr -match "(?i)install|update") {
                        $motivoLegenda = "Falta o .NET Desktop Runtime 8.0 no Windows"
                        SayWarn "O OCR Falhou: Falta o .NET Desktop Runtime 8.0 no Windows. Seguindo Sem Legenda."
                        Say ("        Baixe e Instale em: {0}" -f $LinkDotNetRuntime) "Yellow"
                    <#  14.33: HAVIA UM "} else { }" VAZIO AQUI, E ELE FECHAVA O IF.
                        Com o if fechado, o "elseif" da linha de baixo deixava de ser
                        palavra-chave e virava NOME DE COMANDO. O PowerShell aceita
                        isso no parse - o arquivo abre limpo, a bateria passa - e so
                        estoura quando a linha roda:
                            The term 'elseif' is not recognized as a name of a cmdlet
                        Efeito: QUALQUER falha de OCR que nao fosse "falta o .NET"
                        derrubava o episodio inteiro com essa mensagem, em vez de
                        seguir sem legenda nova. E os dois ramos abaixo - "PgsToSrt
                        indisponivel" e "codigo N" - nunca rodaram na vida.
                        Reproduzido em pwsh isolado antes e depois do conserto. #>
                    } elseif ([int]$ocrResult.ExitCode -eq -1 -and $textoOcr -match "(?i)PgsToSrt nao instalado") {
                        $motivoLegenda = "PgsToSrt Indisponivel Nesta Maquina"
                        SayWarn "Sem OCR Disponivel para Esta Faixa. Seguindo Sem Legenda Nova."
                    } else {
                        $motivoLegenda = "Codigo $($ocrResult.ExitCode)"
                        SayWarn "O OCR Nao Gerou Legenda (Codigo $($ocrResult.ExitCode)). Seguindo Sem Ela."
                    }
                }
            }
        }

        # ---- Resolve quais legendas ORIGINAIS vao para o remux ------------
        # MESMO PADRAO usado para o audio (ver bloco $resultadoAudioBom logo
        # acima, no [4/7]): a fase de DECISAO (bloco if/elseif acima) so
        # descobre/gera o que for possivel; esta fase de RESOLUCAO, sempre
        # ao final, e quem decide - com base no "o resultado foi bom?" - se
        # o descarte de fato acontece. So filtra (descarta pt-BR redundante/
        # forcada/outros idiomas, mantendo so a legenda em ingles) quando ha
        # uma legenda pt-BR PRINCIPAL disponivel para ser a padrao - seja
        # porque ja existia pronta em texto ($idLegendaPtBrOriginal) ou foi
        # gerada agora via OCR ($srtPtBr). Em qualquer outro caso (nada
        # disso encontrado, ou o OCR falhou), MODO SEGURO: nada e filtrado -
        # mantem todas as legendas originais como estao.
        $idsLegendaManter = @()
        $resultadoLegendaBoa = ($null -ne $srtPtBr) -or ($null -ne $idLegendaPtBrOriginal)
        if ($resultadoLegendaBoa) {
            $legendaSemRestricao = $false
            $faixaIngles = Get-FaixaLegendaIngles -MkvPath $f.FullName
            # v14.18: mesmo caso do audio - id 0 e falso em PowerShell.
            if ($null -ne $idLegendaPtBrOriginal) {
                $idsLegendaManter = @($idLegendaPtBrOriginal)
                if ($faixaIngles -and $faixaIngles.id -ne $idLegendaPtBrOriginal) { $idsLegendaManter += $faixaIngles.id }
            } else {
                <#  v14.23: A PGS pt-BR ORIGINAL PASSA A SER MANTIDA.
                    Ate a 14.22 a PGS que virou SRT era descartada por ser
                    "redundante". Decisao do usuario, 22/08: o OCR nunca vai
                    ser 100% - a PGS original e a unica copia fiel do que esta
                    gravado no disco, e ela ja fica no arquivo do mesmo jeito
                    que a legenda inglesa fica. Custa alguns MB e resolve todo
                    caso em que o SRT convertido errar uma fala.
                    O SRT novo continua sendo a legenda PADRAO - so deixou de
                    ser a unica. Quem quiser a original troca no player.  #>
                if ($null -ne $idLegendaPtBrOriginalPgs) { $idsLegendaManter = @($idLegendaPtBrOriginalPgs) }
                if ($faixaIngles -and (@($idsLegendaManter) -notcontains $faixaIngles.id)) { $idsLegendaManter += $faixaIngles.id }
            }
        } else {
            # Modo seguro: garante que nenhum descarte de legenda acontece.
            $legendaSemRestricao = $true
        }
        Say-TempoEtapa $etapaIni

        SayStep "[5/5] Remontando MKV Final (mkvmerge):"
        $etapaIni = Get-Date

        # ---- v13.3: ultima palavra das escolhas manuais -------------------
        # Aqui, e SO aqui, a lista que vai pro mkvmerge pode ser trocada. Fica
        # depois do audio ([4/7]) e da legenda ([5/7]) porque precisa das duas
        # listas prontas, e antes de qualquer flag ser montada. Sem escolha
        # manual, Resolve-FaixasDoRemux devolve identico ao que recebeu.
        $remux = Resolve-FaixasDoRemux -Arquivo $f.FullName -IdsAudio $idsAudioManter -IdAudioDefault $idAudioDefault -IdsLegenda $idsLegendaManter -AudioSemRestricao $audioSemRestricao -LegendaSemRestricao $legendaSemRestricao
        $idsAudioManter      = @($remux.Audio)
        $idAudioDefault      = $remux.AudioDefault
        $idsLegendaManter    = @($remux.Legenda)
        $audioSemRestricao   = $remux.AudioSemRestricao
        $legendaSemRestricao = $remux.LegendaSemRestricao
        <#  v14.24: A PGS ORIGINAL SOBREVIVE A ESCOLHA MANUAL.
            Defeito medido no Spider-Man de 25/08 15h13. O motor 14.23 passou
            a manter a PGS pt-BR original ao lado do .SRT gerado - mas so no
            caminho AUTOMATICO. Com escolha manual na janela o log saiu:
                [ESCOLHA MANUAL] Audio: 1 | Legenda: 3
                Legenda PGS Convertida: ... - Demais Legendas Descartadas
            e a PGS foi embora do mesmo jeito.

            A causa nao e o Resolve-FaixasDoRemux estar errado - ele faz o que
            deve, que e a escolha do usuario ter a ultima palavra. O problema e
            que a PGS pt-BR NUNCA APARECE na lista de faixas que a janela
            oferece: do ponto de vista da tela ela "virou" o .SRT e sumiu.
            Logo o usuario nao a excluiu - ele nunca teve a chance de
            inclui-la. Tratar a ausencia dela como decisao dele seria inventar
            uma escolha que nao houve.

            Por isso ela e re-adicionada aqui, DEPOIS da resolucao manual: a
            PGS original e o par da .SRT que esta sendo gerada, nao uma faixa
            concorrente. As faixas que o usuario de fato viu e decidiu
            (audio, ingles, forcada, comentario) continuam intocadas.

            Excecao: se ele desligou a conversao de legenda, nao ha .SRT novo
            e nada disso se aplica - a lista dele vale inteira.  #>
        if ($remux.Manual -and $null -ne $idLegendaPtBrOriginalPgs -and $null -ne $srtPtBr) {
            if (@($idsLegendaManter) -notcontains $idLegendaPtBrOriginalPgs) {
                $idsLegendaManter = @($idsLegendaManter) + $idLegendaPtBrOriginalPgs
                $legendaSemRestricao = $false
                Say ("        PGS pt-BR original (faixa " + $idLegendaPtBrOriginalPgs + ") mantida junto com o .SRT - ela nao e oferecida na tela de escolha.") "DarkGray"
            }
        }
        if ($remux.Manual) {
            SayResposta "skip" ("[ESCOLHA MANUAL] Audio: {0} | Legenda: {1}" -f ((@($idsAudioManter) -join ", ")), ((@($idsLegendaManter) -join ", ")))
        }

        # v13.8: BUG CORRIGIDO - $statusLegenda foi decidido la no [5/7], ANTES
        # desta resolucao manual existir. Se ele ficou "JA_TEXTO" (a PT-BR ja
        # em texto seria reaproveitada) mas a escolha manual excluiu essa
        # faixa aqui no [6/7], o status tinha que mudar - sem isso, o card
        # final e o selo da janela continuavam dizendo "REAPROVEITADA" mesmo
        # com a faixa fora do arquivo. Achado real: badge "Legenda PT-BR
        # [.SRT] - REAPROVEITADA" ao lado da tabela dizendo corretamente
        # "Nenhuma (Todas Descartadas a Pedido)" - as duas descrevendo o
        # MESMO resultado de jeitos contraditorios.
        if ($statusLegenda -eq "JA_TEXTO" -and $idLegendaPtBrOriginal -and (@($idsLegendaManter) -notcontains $idLegendaPtBrOriginal)) {
            $statusLegenda = "DESCARTADA_MANUAL"
        }

        # ---- Monta os flags de selecao/padrao para o arquivo ORIGINAL -----
        # (--no-video $f.FullName). Isso e o que efetivamente descarta as
        # faixas de audio/legenda desnecessarias (comentario, dublagem,
        # PGS pt-BR redundante, forcada, outros idiomas) - o mkvmerge so
        # copia o que for explicitamente selecionado abaixo. Quando o modo
        # "sem restricao" esta ativo (faixa principal/legenda pt-BR nao
        # identificada com seguranca, ou OCR falhou), nenhum flag de
        # selecao e adicionado - o arquivo original entra 100% intacto,
        # exatamente como sempre funcionou.
        $flagsOriginal = @()

        if (-not $audioSemRestricao -and $idsAudioManter.Count -gt 0) {
            $flagsOriginal += @("--audio-tracks", ($idsAudioManter -join ","))
            foreach ($idAud in $idsAudioManter) {
                $padrao = if ($idAud -eq $idAudioDefault) { "yes" } else { "no" }
                $flagsOriginal += @("--default-track", "${idAud}:${padrao}")
            }
        }

        if (-not $legendaSemRestricao) {
            # Quando o filtro esta ativo, SO a legenda inglesa completa
            # sobrevive (em $idsLegendaManter) - alem do SRT pt-BR novo,
            # adicionado mais abaixo. Todo o resto e descartado: a PGS pt-BR
            # original (virou SRT, redundante), legendas forcadas, SDH,
            # outros idiomas E legendas sem idioma definido (und/undefined) -
            # nenhuma delas entra em $idsLegendaManter, entao o mkvmerge nao
            # as copia.
            if ($idsLegendaManter.Count -gt 0) {
                $flagsOriginal += @("--subtitle-tracks", ($idsLegendaManter -join ","))
                foreach ($idLeg in $idsLegendaManter) {
                    # Se a faixa PT-BR ja existia em texto e foi reaproveitada
                    # (sem OCR), ELA e a padrao. Caso contrario (SRT novo via
                    # OCR sera adicionado mais abaixo, ou so sobrou o ingles),
                    # a legenda original mantida nunca e a padrao.
                    $padraoLeg = if ($idLegendaPtBrOriginal -and $idLeg -eq $idLegendaPtBrOriginal) { "yes" } else { "no" }
                    $flagsOriginal += @("--default-track", "${idLeg}:${padraoLeg}")
                }
            } else {
                # Filtro ativo mas nao sobrou nenhuma legenda original para
                # manter (ex: nao ha faixa em ingles) - descarta todas as
                # legendas originais, so o SRT pt-BR novo permanece.
                $flagsOriginal += @("--no-subtitles")
            }
        }

        # Mensagens do [6/7]: so aparecem quando o descarte de fato foi
        # aplicado naquela frente (audio/legenda) - em modo seguro (nada
        # descartado), a linha correspondente e omitida por completo, para
        # nao poluir com informacao que nao reflete nenhuma acao real.
        # $textoFaixasAudioMantidas/$textoFaixasLegendaMantidas guardam a
        # mesma informacao para reaproveitar no cartao-resumo final do
        # episodio (senao ela some da tela em lotes grandes).
        $textoFaixasAudioMantidas = $null
        $textoFaixasLegendaMantidas = $null
        if (-not $audioSemRestricao) {
            $rotulosAudio = @($idsAudioManter | ForEach-Object { Get-RotuloFaixa -MkvPath $f.FullName -Id $_ } | Where-Object { $_ })
            if ($eac3File) { $rotulosAudio += "$eac3TrackName (Novo)" }
            $textoFaixasAudioMantidas = $rotulosAudio -join " + "
            SayResposta "ok" ("Audio Mantido: {0} - Demais Faixas de Audio Descartadas [OK]" -f $textoFaixasAudioMantidas)
        }
        if (-not $legendaSemRestricao) {
        <#  v14.24: sem este rotulo a linha mentiria por ambiguidade.
            Agora que a PGS pt-BR original fica no arquivo ao lado da .SRT
            gerada dela, as duas tem o MESMO nome de faixa e a mensagem sairia
            "Portuguese (Brazilian) [OCR/SRT] + English + Portuguese
            (Brazilian)" - o usuario leria como faixa duplicada ou erro. O
            sufixo diz qual e qual.  #>
            $rotulosLegenda = @($idsLegendaManter | ForEach-Object {
                $rot = Get-RotuloFaixa -MkvPath $f.FullName -Id $_
                if ($rot -and $idLegendaPtBrOriginal -and $_ -eq $idLegendaPtBrOriginal) { $rot = "$rot [SRT]" }
                elseif ($rot -and $null -ne $idLegendaPtBrOriginalPgs -and $_ -eq $idLegendaPtBrOriginalPgs -and $srtPtBr) { $rot = "$rot [PGS original]" }
                $rot
            } | Where-Object { $_ })
            if ($srtPtBr) {
                $rotuloEtapaLegenda = "Legenda PGS Convertida"
                # A faixa pt-BR nova (OCR) sempre aparece primeiro na mensagem,
                # igual ao caso "reaproveitada" (onde ela ja vem primeiro em
                # $idsLegendaManter) - por isso e inserida no inicio, nao no fim.
                $rotulosLegenda = @("$nomeLegendaPgsOrigem [OCR/SRT]") + $rotulosLegenda
            } else {
                $rotuloEtapaLegenda = "Legenda Reaproveitada"
            }
            $textoFaixasLegendaMantidas = $rotulosLegenda -join " + "
            SayResposta "ok" ("{0}: {1} - Demais Legendas Descartadas [OK]" -f $rotuloEtapaLegenda, $textoFaixasLegendaMantidas)

            <#  v14.28: A NOTA DA LEGENDA NO RESUMO DO ARQUIVO.
                O veredicto ja era lido da saida do Reocr e impresso no meio da
                [4/5] - onde ele rola para cima e some antes de a conversao
                acabar. Fora dali, so existia dentro de
                _reocr\relatorio_reocr_*.txt: para saber se podia confiar na
                legenda o usuario tinha que abrir um .txt numa subpasta.

                Agora ele fecha o bloco de legenda do resumo do arquivo, ao
                lado das faixas que ficaram - que e onde a pergunta nasce
                ("mantive as duas; qual eu uso?") e onde ela tem que ser
                respondida. #>
            if ($null -ne $script:NotaLegendaVeredicto -and $script:NotaLegendaVeredicto -ne "") {
                $linhaNota = "        Qualidade da Legenda Convertida: " + $script:NotaLegendaVeredicto
                if ($script:NotaLegendaDefeitos -ge 0) {
                    $linhaNota += (" - {0} de {1} bloco(s) com defeito ({2}%)" -f $script:NotaLegendaDefeitos, $script:NotaLegendaBlocos, $script:NotaLegendaPct)
                }
                if ($script:NotaLegendaVeredicto -ceq "EXCELENTE") {
                    # v14.31: mesmo defeito do ramo da sub-etapa - ver o
                    # comentario grande la em cima. EXCELENTE caia no else e o
                    # resumo do arquivo mandava usar a PGS original.
                    Say $linhaNota "Green"
                    Say "        Nenhuma falha encontrada. Pode assistir por ela." "DarkGray"
                } elseif ($script:NotaLegendaVeredicto -ceq "BOA") {
                    Say $linhaNota "Green"
                    Say "        Pode assistir por ela." "DarkGray"
                } elseif ($script:NotaLegendaVeredicto -ceq "RAZOAVEL") {
                    Say $linhaNota "Yellow"
                    Say "        Se tropecar numa fala, troque no player para a faixa PGS original." "DarkGray"
                } else {
                    Say $linhaNota "Red"
                    Say "        Recomendo assistir pela faixa PGS original - ela esta neste mesmo arquivo." "DarkGray"
                }
            }
        } else {
            <#  v14.21: O MODO SEGURO ERA MUDO - E ISSO VIROU UMA SURPRESA.
                Sem legenda pt-BR, o motor nao descarta legenda nenhuma (de
                proposito: nao joga fora o que nao sabe avaliar). So que ele
                fazia isso em SILENCIO - o bloco acima nao roda e a [5/5] nao
                escrevia uma linha sequer sobre legenda.
                Resultado real (Fallout S02E04, 19/08): dois episodios da mesma
                serie sairam com 2 legendas e o terceiro com 33, e o unico
                jeito de descobrir era abrindo o arquivo. O Diego abriu:
                "o fallout 04 ficou horrivel as legendas... manteve todas
                e isso mesmo?".
                E isso mesmo, e agora o motor fala. Decisao mantida (o modo
                seguro nao perde nada); o que muda e que ele passa a ser
                ANUNCIADO, com a contagem e com o motivo de nao ter achado a
                pt-BR - a pergunta seguinte inevitavel. #>
            $nLegOriginais = 0
            try {
                $jsonLeg = Get-MkvJson -MkvPath $f.FullName
                if ($jsonLeg) { $nLegOriginais = @($jsonLeg.tracks | Where-Object { $_.type -eq "subtitles" }).Count }
            } catch { }
            $textoFaixasLegendaMantidas = if ($nLegOriginais -gt 0) {
                "Todas as $nLegOriginais Legendas Originais Mantidas (Modo Seguro)"
            } else { "Todas as Legendas Originais Mantidas (Modo Seguro)" }
            SayResposta "skip" ("[MODO SEGURO] Legenda: Nenhuma Faixa Descartada - as {0} Legendas do Original Foram Mantidas Como Estavam." -f $nLegOriginais)
            Say ("        Sem uma legenda PT-BR para ser a principal, o motor nao escolhe o que jogar fora.") "DarkGray"
            Say ("        Por que nao achou PT-BR: " + (Get-MotivoSemLegendaPtBr -MkvPath $f.FullName)) "DarkGray"
        }

        # Fallback para o mini-mediainfo do cartao final: mesmo sem descarte
        # (modo seguro), o campo nunca fica vazio - sempre ha algo a mostrar
        # sobre a composicao final de audio/legenda do arquivo.
        # v13.7: o teste era '-not $texto...', que e verdadeiro tanto para
        # $null (bloco nunca rodou, modo seguro) quanto para "" (bloco
        # rodou e o resultado foi lista vazia de proposito - exclusao
        # manual de tudo). Os dois casos viravam a MESMA frase enganosa
        # "Todas Mantidas", inclusive quando nada foi mantido. Agora so cai
        # no fallback quando o bloco de fato nunca rodou ($null).
        if ($null -eq $textoFaixasAudioMantidas)   { $textoFaixasAudioMantidas   = "Todas as Faixas Originais Mantidas (Sem Descarte)" }
        if ($null -eq $textoFaixasLegendaMantidas) { $textoFaixasLegendaMantidas = "Todas as Legendas Originais Mantidas (Sem Descarte)" }
        if ($textoFaixasLegendaMantidas -eq "")    { $textoFaixasLegendaMantidas = "Nenhuma (Todas Descartadas a Pedido)" }

        Say "        Montando o Arquivo MKV Final (mkvmerge)..." "DarkGray"
        <#  v14.16: DOIS CAMINHOS, E O NOVO E O SEGURO.
            CAMINHO DIRETO ($videoDireto): o video nunca saiu do container.
            O MKV de origem entra como PRIMEIRO arquivo e traz a faixa de
            video junto - com o hvcC e os timestamps ORIGINAIS, copiados byte
            a byte pelo mkvmerge. Nao existe --default-duration nem
            --fix-bitstream-timing-information aqui de proposito: os dois so
            fazem sentido quando a entrada e um fluxo solto SEM linha de tempo
            propria, e e justamente a linha de tempo reconstruida (mais o
            cabecalho de codec reconstruido) que quebrou o Se7en.
            CAMINHO ANTIGO: o video foi extraido porque o dovi_tool precisou
            mexer nele. Nesse caso nao ha alternativa - o fluxo solto entra
            como primeiro arquivo e a origem entra com --no-video. #>
        if ($videoDireto) {
            $mkvArgs = @("-o", "$outFile")
            # O --default-track no video e explicito de proposito: no caminho
            # antigo o video vinha de um fluxo solto, que nao carrega flag
            # nenhuma, e o mkvmerge o marcava como padrao. Copiando do
            # container, a flag do ORIGINAL e que seria preservada - e ha
            # remux por ai com o video marcado como nao-padrao. Forcando aqui,
            # o arquivo final sai igual ao que ja saia antes.
            $mkvArgs += @("--video-tracks", "$idVideoOrigem", "--default-track", "${idVideoOrigem}:yes")
            $mkvArgs += $flagsOriginal
            $mkvArgs += @("$($f.FullName)")
        } else {
            $mkvArgs = @(
                "-o", "$outFile",
                "--default-duration", "0:${fpsRaw}p",
                "--fix-bitstream-timing-information", "0:1",
                "$p81Hevc"
            )
            $mkvArgs += $flagsOriginal
            $mkvArgs += @("--no-video", "$($f.FullName)")
        }
        if ($eac3File) {
            $idiomaOriginal = if ($faixaPrincipal.properties.language) { $faixaPrincipal.properties.language } else { "eng" }
            $mkvArgs += @("--language", "0:$idiomaOriginal", "--track-name", "0:$eac3TrackName", "--default-track", "0:yes", "$eac3File")
        }
        if ($srtPtBr) { $mkvArgs += @("--language", "0:por", "--track-name", "0:Portugues (Brasil) [OCR]", "--default-track", "0:yes", "$srtPtBr") }
        $exitCode = Invoke-MkvMergeComProgresso -ArgList $mkvArgs
        if ($exitCode -ne 0 -and $exitCode -ne 1) {
            # mkvmerge retorna 1 para "avisos" (nao fatal); qualquer coisa >=2 e erro real
            throw "O mkvmerge Terminou com Erro (Codigo $exitCode)."
        }
        if (-not (Test-Path -LiteralPath $outFile) -or (Get-Item -LiteralPath $outFile).Length -eq 0) {
            throw "O mkvmerge Nao Gerou o Arquivo Final."
        }

        $tamanhoFinal = (Get-Item -LiteralPath $outFile).Length
        $tempoGasto   = (Get-Date) - $tIni
        # Antes esta linha dizia "Arquivo Finalizado - 24,98 GB em 04m 04s" e
        # logo abaixo aparecia "Tempo da etapa: 02m 06s" - dois numeros de
        # tempo colados, sem dizer que mediam coisas diferentes. O "em" era o
        # tempo do EPISODIO INTEIRO (desde a etapa 1) e o outro era so a etapa
        # de remontagem. Agora cada numero diz o que e.
        SayOk ("Arquivo Finalizado - {0}" -f (Format-Tamanho $tamanhoFinal))
        Say-TempoEtapa $etapaIni
        Say ("        Tempo deste episodio ate aqui: {0}" -f (Format-Duracao $tempoGasto.TotalSeconds)) "DarkGray"

        # v14.3: copia solta do .srt final na pasta de saida, do lado do mkv.
        # Antes a legenda OCR so existia MUXADA dentro do mkv - o WorkDir com
        # o .srt era apagado no [7/7] e nao sobrava nada solto pra conferir
        # rapido sem abrir o mkv inteiro. So copia se realmente gerou uma
        # legenda nova via OCR ($srtPtBr setado) - nao copia nada quando a
        # PT-BR ja veio pronta em texto (nao ha OCR pra "salvar copia de").
        if ($srtPtBr -and (Test-Path -LiteralPath $srtPtBr)) {
            $srtCopiaFinal = Join-Path $OutputDir ($name + ".srt")
            try {
                Copy-Item -LiteralPath $srtPtBr -Destination $srtCopiaFinal -Force
            } catch { }
        }

        <#  v14.16: [VERIFICACAO] - O MOTOR CONFERE O QUE ELE MESMO ENTREGOU.
            Antes desta versao, o criterio de "deu certo" era: mkvmerge saiu
            com codigo 0 e o arquivo final existe com tamanho > 0. So isso.
            O Se7en passou nos dois criterios com a imagem congelada a partir
            dos 47 minutos - o usuario so descobriu assistindo.
            Aqui o ffmpeg DECODIFICA de verdade 10 trechos curtos espalhados
            do inicio ao fim do arquivo final. Se algum trecho nao decodificar,
            o mesmo teste roda nos MESMOS pontos do arquivo de ORIGEM - e ai da
            para dizer qual dos dois esta com problema, em vez de deixar a
            duvida no colo do usuario.
            Nao apaga nem rejeita o arquivo: quem decide o que fazer com ele e
            o usuario. O motor so para de mentir que esta tudo certo. #>
        SayStep "[VERIFICACAO] Conferindo se o Arquivo Final Decodifica do Inicio ao Fim:"
        $etapaIni = Get-Date
        $statusVerif = "OK"
        $textoVerif = ""
        try {
            <#  v14.20: PRIMEIRO A DURACAO, DEPOIS OS TRECHOS.
                A amostragem responde "o fluxo decodifica NESTES 10 pontos".
                Ela nao responde "o arquivo inteiro esta aqui" - se a
                remontagem cortar o final, os 10 pontos caem todos dentro do
                que sobrou e passam. Um ffprobe compara a duracao do final com
                a da origem e fecha esse buraco por um custo perto de zero.
                Tolerancia: 1 segundo ou 0,5% do filme, o que for maior. Nao e
                zero de proposito - remux legitimo pode variar alguns quadros
                no ultimo cluster, e reclamar disso seria criar um alarme falso
                novo no lugar do que a 14.20 acabou de tirar. #>
            $duracaoFinal = Get-DuracaoDoArquivo -Caminho $outFile
            if ($duracaoTotal -gt 0 -and $duracaoFinal -gt 0) {
                $folga = [math]::Max(1.0, $duracaoTotal * 0.005)
                $difDur = [math]::Abs($duracaoFinal - $duracaoTotal)
                if ($difDur -gt $folga) {
                    $statusVerif = "FALHA"
                    # A origem tem a duracao certa por definicao - se o final
                    # difere, isso nasceu AQUI. A frase carrega o "Apareceu na
                    # Remontagem" porque e ela que faz o resumo final marcar o
                    # episodio como OK_PARCIAL em vez de OK.
                    $textoVerif = ("A Duracao do Arquivo Final Difere da Origem em {0} - o Problema Apareceu na Remontagem" -f (Format-Duracao $difDur))
                    SayWarn ("A DURACAO NAO CONFERE: origem {0}, arquivo final {1} - diferenca de {2}." -f `
                        (Format-Duracao $duracaoTotal), (Format-Duracao $duracaoFinal), (Format-Duracao $difDur))
                    Say "        Isso significa que o arquivo final perdeu (ou ganhou) tempo na remontagem." "DarkGray"
                } else {
                    SayOk ("Duracao Confere com a Origem: {0}" -f (Format-Duracao $duracaoFinal))
                }
            } elseif ($duracaoTotal -gt 0) {
                SayWarn "NAO FOI POSSIVEL LER A DURACAO DO ARQUIVO FINAL PARA COMPARAR COM A ORIGEM."
            }
            $verif = Test-VideoDecodavel -Caminho $outFile -DuracaoSeg $duracaoTotal -Pontos 10 -ComBarra
            # v14.20: "PULADA" nunca pode apagar uma FALHA ja encontrada. Se a
            # duracao nao conferiu, o episodio esta com defeito mesmo que a
            # amostragem por trechos nao tenha rodado.
            if ($script:CancelamentoSolicitado) {
                if ($statusVerif -ne "FALHA") { $statusVerif = "PULADA" }
            } elseif ($verif.Testados -le 0) {
                if ($statusVerif -ne "FALHA") { $statusVerif = "PULADA" }
                # v14.18: a frase antiga era "Arquivo Curto Demais para
                # Amostrar". Ela AFIRMAVA um fato sobre o arquivo. Mas o
                # caminho que chega aqui tambem inclui o caso em que o
                # ffprobe nao devolveu duracao ($duracaoTotal = 0) - e ai o
                # programa nao mediu nada, so nao sabe. Um filme de 3 horas
                # sairia com "curto demais" e a rede de seguranca do video
                # desligada em silencio. Agora a mensagem diz qual dos dois e.
                if ($duracaoTotal -le 10) {
                    SayResposta "skip" ("[NAO NECESSARIO] Arquivo de {0} - Curto Demais para Amostrar. Verificacao Dispensada." -f (Format-Duracao $duracaoTotal))
                } else {
                    SayWarn "NAO FOI POSSIVEL VERIFICAR: o ffprobe Nao Devolveu a Duracao Deste Arquivo, Entao Nao Ha Como Espalhar os Pontos de Teste. O Arquivo Final NAO Foi Conferido."
                }
            } elseif ($verif.Ok) {
                Show-BarraCompleta
                SayOk ("Video Integro - {0} Trechos Decodificados do Inicio ao Fim, Nenhum Erro" -f $verif.Testados)
                # v14.20: "reclamou mas entregou" nao pode sair como silencio
                # nem como alarme. Sai como o que e: uma nota de rodape.
                $nRuido = @($verif.Ruidos).Count
                if ($nRuido -gt 0) {
                    $ptsR = @(@($verif.Ruidos) | ForEach-Object { Format-Duracao ([double]$_.Segundo) })
                    Say ("        Nota: em {0} dos {1} pontos o ffmpeg reclamou da BUSCA e mesmo assim entregou os quadros pedidos - a busca caiu no meio de um quadro e ele resincronizou. Nao e defeito do arquivo." -f $nRuido, $verif.Testados) "DarkGray"
                    Say ("        Pontos com Ruido: " + ($ptsR -join ", ")) "DarkGray"
                    Say ("        ffmpeg: " + "$(@($verif.Ruidos)[0].Detalhe)") "DarkGray"
                }
            } else {
                $statusVerif = "FALHA"
                $pontos = @(@($verif.Falhas) | ForEach-Object { Format-Duracao ([double]$_.Segundo) })
                $primeiro = [double](@($verif.Falhas)[0].Segundo)
                SayWarn ("O ARQUIVO FINAL NAO ENTREGOU QUADROS EM {0} DE {1} TRECHOS. Primeiro Ponto com Falha: {2}." -f @($verif.Falhas).Count, $verif.Testados, (Format-Duracao $primeiro))
                Say ("        (o teste pede 12 quadros por ponto e aceita a partir de 6; nestes pontos veio menos que isso)") "DarkGray"
                Say ("        Pontos com Falha: " + ($pontos -join ", ")) "DarkGray"
                $det = "$(@($verif.Falhas)[0].Detalhe)"
                if ($det -ne "") { Say ("        ffmpeg: " + $det) "DarkGray" }
                # Agora a pergunta que importa: o problema nasceu aqui ou ja
                # vinha do arquivo de origem? Mesmo teste, mesmos pontos.
                Say "        Repetindo o Mesmo Teste nos Mesmos Pontos do Arquivo de ORIGEM..." "DarkGray"
                $verifOrig = Test-VideoDecodavel -Caminho $f.FullName -DuracaoSeg $duracaoTotal -Pontos 10
                if ($verifOrig.Testados -le 0) {
                    $textoVerif = "Nao Foi Possivel Testar o Arquivo de Origem para Comparar"
                    SayWarn $textoVerif
                } elseif ($verifOrig.Ok) {
                    $textoVerif = ("O Arquivo de ORIGEM Decodifica Sem Erro nos Mesmos {0} Pontos - o Problema Apareceu na Remontagem" -f $verifOrig.Testados)
                    SayWarn $textoVerif
                } else {
                    $textoVerif = ("O Arquivo de ORIGEM Falha nos Mesmos Pontos ({0} de {1}) - o Problema JA VEM DO ARQUIVO DE ORIGEM, Nao da Conversao" -f @($verifOrig.Falhas).Count, $verifOrig.Testados)
                    SayResposta "skip" ("[ORIGEM] " + $textoVerif)
                }
            }
        } catch {
            $statusVerif = "PULADA"
            SayWarn ("Nao Foi Possivel Verificar o Arquivo Final: {0}" -f $_.Exception.Message)
        }
        Say-TempoEtapa $etapaIni

        SayStep "[LIMPEZA] Limpando Arquivos Temporarios Deste Episodio:"
        $etapaIni = Get-Date
        # v14.9: antes esta etapa so IMPRIMIA "Temporarios Removidos" - quem
        # apagava de verdade era o "finally", depois. Ou seja: anunciava a
        # limpeza sem ter limpado, e sem conferir se deu certo. Agora apaga
        # aqui, mede quanto liberou e fala o numero. O finally continua no
        # lugar como rede, pros casos de erro.
        <#  v14.18: A CONFIRMACAO SO OLHAVA METADE DA LIMPEZA.
            Sao DUAS pastas: o $WorkDir (do lado do arquivo) e o $AudioWorkDir
            (na raiz do disco, "_ddvt_au_NNN"), onde o DeeZy/truehdd deixam os
            intermediarios - que num TrueHD e o GROSSO do lixo. A conta de
            bytes so somava o $WorkDir e o teste final so olhava o $WorkDir.
            Resultado: se o dee.exe ainda segurasse um handle, o motor escrevia
            "Temporarios Removidos" com dezenas de GB intactos no disco. E o
            numero anunciado como liberado sempre foi menor que o real.
            Isto e o mesmo defeito que a v14.9 diz ter fechado, sobrevivendo na
            outra metade da funcao. #>
        $bytesLiberados = 0
        try {
            foreach ($pastaTmp in @($WorkDir, $AudioWorkDir)) {
                if (-not (Test-Path -LiteralPath $pastaTmp)) { continue }
                $somaTmp = (Get-ChildItem -LiteralPath $pastaTmp -Recurse -File -ErrorAction SilentlyContinue |
                            Measure-Object -Property Length -Sum).Sum
                if ($somaTmp) { $bytesLiberados += [double]$somaTmp }
                Remove-Item -LiteralPath $pastaTmp -Recurse -Force -ErrorAction SilentlyContinue
            }
        } catch { }
        Show-BarraCompleta
        if ((Test-Path -LiteralPath $WorkDir) -or (Test-Path -LiteralPath $AudioWorkDir)) {
            SayWarn "Nao Consegui Remover a Pasta Temporaria Agora (algum arquivo ainda em uso). Ela Sera Limpa na Proxima Vez que o Programa Abrir."
        } elseif ($bytesLiberados -gt 0) {
            SayOk ("Temporarios Removidos - {0} Liberados" -f (Format-Tamanho $bytesLiberados))
        } else {
            SayOk "Temporarios Removidos"
        }
        <#  v14.34: AS PASTAS _corretor E _reocr NAO FICAM MAIS PARA TRAS
            QUANDO A LEGENDA SAI LIMPA.
            Diego: "A PASTA CORRETOR REOCR (...) TEM Q SUMIR NO FINAL, HOJE
            ELA FICA PQ NOS PRECISAMOS DO LOG PARA ARRUMAR (...) QUANDO A
            LEGENDA FOR CRITICA, ELA SO PODE FICAR ALI CRIADA".
            E exatamente isso: o .srt corrigido, os relatorios e os PNGs das
            tiras sao material de INVESTIGACAO. Quando nao ha o que investigar
            - legenda EXCELENTE ou BOA, que e o caso normal - eles sao lixo na
            pasta do usuario, e a legenda ja esta DENTRO do mkv final.
            Quando a nota e RAZOAVEL ou RUIM, ou quando a legenda deu erro,
            fica tudo onde esta e o motor diz o caminho: ali a pasta e a unica
            forma de descobrir o que saiu torto.
            So apaga o que ESTE arquivo criou (data >= $script:T0Legenda).
            Legenda de outro filme, ou de uma rodada anterior que voce ainda
            nao olhou, nao e assunto desta conversao. #>
        if ($script:T0Legenda) {
            $notaLeg = "$($script:NotaLegendaVeredicto)"
            $legendaLimpa = ($notaLeg -ceq "EXCELENTE" -or $notaLeg -ceq "BOA")
            $pastasLeg = @((Join-Path $ScriptDir "_corretor"), (Join-Path $ScriptDir "_reocr"))
            if ($legendaLimpa) {
                $apagadosLeg = 0
                foreach ($pl in $pastasLeg) {
                    if (-not (Test-Path -LiteralPath $pl)) { continue }
                    foreach ($arqLeg in @(Get-ChildItem -LiteralPath $pl -File -ErrorAction SilentlyContinue)) {
                        if ($arqLeg.LastWriteTime -lt $script:T0Legenda) { continue }
                        try { Remove-Item -LiteralPath $arqLeg.FullName -Force -ErrorAction Stop; $apagadosLeg++ } catch { }
                    }
                }
                if ($apagadosLeg -gt 0) {
                    SayOk ("Legenda {0}: Removi os {1} Arquivo(s) de Trabalho do Corretor e do Reocr - a Legenda Boa Ja Esta Dentro do MKV Final." -f $notaLeg, $apagadosLeg)
                }
            } elseif ($notaLeg -ne "") {
                SayWarn ("Legenda {0}: MANTIVE os arquivos de trabalho em _corretor e _reocr de proposito - e por eles que se descobre o que saiu torto." -f $notaLeg)
            }
        }
        Say-TempoEtapa $etapaIni

        # Rede de seguranca do [ESC]: normalmente o cancelamento derruba o
        # processo da etapa em andamento e ela ja falha sozinha, caindo no
        # catch. Mas se o ESC for pressionado exatamente no intervalo entre
        # duas etapas, nenhuma delas falha - e sem esta guarda o episodio
        # seria registrado como concluido, mesmo com o usuario tendo mandado
        # parar (e com o arquivo possivelmente incompleto). Lancar aqui manda
        # o fluxo para o mesmo catch, que apaga a saida parcial e registra
        # corretamente como CANCELADO.
        if ($script:CancelamentoSolicitado) { throw "Operacao Cancelada pelo Usuario ([ESC])." }

        # Status geral: "OK" so se tudo que foi tentado funcionou.
        # "OK_PARCIAL" se o Dolby Vision foi convertido mas alguma etapa opcional
        # (audio ou legenda) falhou - o arquivo final existe e e utilizavel, mas
        # nao esta 100% completo conforme esperado.
        # v14.16: uma falha de decodificacao NASCIDA na remontagem nunca mais
        # sai daqui como "OK". Quando a falha ja existe no arquivo de origem, o
        # resultado da conversao continua sendo o esperado - o motor avisou, e
        # nao ha nada que ele pudesse ter feito diferente.
        $verifQuebrouAqui = ($statusVerif -eq "FALHA" -and $textoVerif -match "(?i)Apareceu na Remontagem")
        $statusGeral = if ($statusAudio -eq "ERRO" -or $statusLegenda -eq "ERRO" -or $verifQuebrouAqui) { "OK_PARCIAL" } else { "OK" }

        $resultados += [PSCustomObject]@{
            Episodio      = $name
            Status        = $statusGeral
            StatusDV      = $statusDV
            StatusAudio   = $statusAudio
            MotivoAudio   = $motivoAudio
            CodecAudio    = $codecAudioOrigem
            TipoConvAudio = $tipoConversaoAudio
            StatusLegenda = $statusLegenda
            MotivoLegenda = $motivoLegenda
            DescarteAudio    = (-not $audioSemRestricao)
            DescarteLegenda  = (-not $legendaSemRestricao)
            FaixasAudioMantidas   = $textoFaixasAudioMantidas
            FaixasLegendaMantidas = $textoFaixasLegendaMantidas
            <#  v14.29: a nota da legenda vai no OBJETO DE RESULTADO, nao so
                na tela. O motor ja imprimia a linha e a Janela nao mostrava
                nada: o cartao final e montado a partir DESTE objeto, campo a
                campo, e ignora linha solta de saida. Rodada de 26/08 11h28:
                a nota estava no log (12:30:36) e ausente na tela.  #>
            NotaLegendaVeredicto = $script:NotaLegendaVeredicto
            NotaLegendaDefeitos  = $script:NotaLegendaDefeitos
            NotaLegendaPct       = $script:NotaLegendaPct
            NotaLegendaBlocos    = $script:NotaLegendaBlocos
            Fps           = $fpsRaw
            Tamanho       = Format-Tamanho $tamanhoFinal
            DuracaoVideo  = Format-Duracao $duracaoTotal
            Tempo         = Format-Duracao $tempoGasto.TotalSeconds
            Motivo        = ""
        }

    } catch {
        # Cancelamento pelo [ESC] nao e "falha": o usuario mandou parar. O
        # tratamento aproveita este mesmo catch/finally (que ja apaga a saida
        # parcial e os temporarios), so mudando o rotulo e o motivo - o mesmo
        # efeito pratico de fechar a janela no meio, porem organizado.
        if ($script:CancelamentoSolicitado) {
            SayStop "Operacao Cancelada pelo Usuario. Removendo a Saida Parcial e os Temporarios Deste Episodio..."
            if (Test-Path -LiteralPath $outFile) { Remove-Item -LiteralPath $outFile -Force -ErrorAction SilentlyContinue }
            # O Motivo aqui NAO repete "cancelado pelo usuario" (isso ja esta
            # no Status, logo acima) - em vez disso, informa QUAL etapa estava
            # em andamento quando o [ESC] foi pressionado, que e a informacao
            # nova e util para quem esta lendo o resumo depois.
            # SayStep formata o texto da etapa com ":" no final (ex: "[2/7]
            # Extraindo Video Puro do MKV (ffmpeg, Sem Recodificar):"), porque
            # e pensado pra aparecer sozinho como cabecalho de etapa. Usado
            # aqui dentro de uma frase, esse ":" sobrando deixava a mensagem
            # com um "): -" estranho (confirmado em log real). Removido antes
            # de compor a frase.
            $etapaNoCancelamento = if ($script:EtapaAtualNome) { $script:EtapaAtualNome.TrimEnd(":") } else { "processamento" }
            $resultados += [PSCustomObject]@{
                Episodio = $name; Status = "CANCELADO"; StatusDV = ""; StatusAudio = ""; MotivoAudio = ""; CodecAudio = "-"; TipoConvAudio = ""; StatusLegenda = ""; MotivoLegenda = ""; DescarteAudio = $false; DescarteLegenda = $false; FaixasAudioMantidas = $null; FaixasLegendaMantidas = $null; NotaLegendaVeredicto = ""; NotaLegendaDefeitos = -1; NotaLegendaPct = ""; NotaLegendaBlocos = 0; Fps = ""; Tamanho = ""; DuracaoVideo = ""; Tempo = Format-Duracao ((Get-Date) - $tIni).TotalSeconds; Motivo = ("Interrompido durante a etapa {0} - Saida Parcial e Temporarios Foram Removidos." -f $etapaNoCancelamento)
            }
        } else {
            $erroFiltrado = Get-ResumoErro -Linhas @() -TextoErro $_.Exception.Message -MaxChars 320
            if ([string]::IsNullOrWhiteSpace($erroFiltrado)) { $erroFiltrado = $_.Exception.Message }
            <#  v14.31: O LOG NAO REGISTRAVA O MOTIVO DO ERRO.
                Esta linha dizia "Detalhes Completos no Resumo Final Desta
                Execucao" - e o resumo final que vai para o LOG nao tem os
                detalhes: o Motivo so existe no objeto de resultado, que a
                JANELA usa para desenhar o cartao. Quem abrisse o log depois
                (que e o que o Diego manda para ca) via um episodio FALHOU sem
                uma palavra sobre a causa.
                Prova: log de 27/08 01h04, Troy - o log tem
                "[ERRO] Falha ao Processar Este Episodio." e nada mais; o
                motivo real ("Espaco Insuficiente ... Faltam ~4,33 GB") so
                aparecia no cartao da tela.
                Agora o motivo vai para a tela E para o log, na hora. #>
            SayErr "Falha ao Processar Este Episodio:"
            foreach ($ln in @($erroFiltrado -split "(?<=\.)\s+" | Where-Object { $_ -and $_.Trim() -ne "" })) {
                Say ("        " + $ln.Trim()) "Red"
            }
            if (Test-Path -LiteralPath $outFile) { Remove-Item -LiteralPath $outFile -Force -ErrorAction SilentlyContinue }
            $resultados += [PSCustomObject]@{
                Episodio = $name; Status = "FALHOU"; StatusDV = ""; StatusAudio = ""; MotivoAudio = ""; CodecAudio = "-"; TipoConvAudio = ""; StatusLegenda = ""; MotivoLegenda = ""; DescarteAudio = $false; DescarteLegenda = $false; FaixasAudioMantidas = $null; FaixasLegendaMantidas = $null; NotaLegendaVeredicto = ""; NotaLegendaDefeitos = -1; NotaLegendaPct = ""; NotaLegendaBlocos = 0; Fps = ""; Tamanho = ""; DuracaoVideo = ""; Tempo = Format-Duracao ((Get-Date) - $tIni).TotalSeconds; Motivo = $erroFiltrado
            }
        }
    } finally {
        Remove-Item -LiteralPath $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $AudioWorkDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    # [ESC] interrompe o LOTE INTEIRO, nao so o episodio atual: se o usuario
    # mandou parar, nao faz sentido emendar no proximo arquivo. Os episodios
    # que ainda nao comecaram nem entram no resumo (nao foram tocados).
    if ($script:CancelamentoSolicitado) {
        # (sem linha em branco aqui: a mensagem de cancelamento do episodio ja
        # saiu logo acima, e o pulo duplo deixava um buraco na tela e no log)
        SayStop "Lote Interrompido pelo Usuario - Os Arquivos Restantes Nao Foram Processados."
        break
    }
}

# ---- limpeza final: remove a pasta temporaria "de fallback" caso ela tenha
# chegado a ser criada (nao deveria, ja que cada episodio limpa a sua) -------
Remove-Item -LiteralPath $WorkDirRaiz -Recurse -Force -ErrorAction SilentlyContinue

# ---- resumo final -----------------------------------------------------------
$duracaoGeral = (Get-Date) - $inicioGeral
$ok       = @($resultados | Where-Object { $_.Status -eq "OK" })
$parcial  = @($resultados | Where-Object { $_.Status -eq "OK_PARCIAL" })
$falhou   = @($resultados | Where-Object { $_.Status -eq "FALHOU" })
$pulado   = @($resultados | Where-Object { $_.Status -eq "PULADO" })
$cancelado = @($resultados | Where-Object { $_.Status -eq "CANCELADO" })
$processados = @($ok + $parcial)   # episodios onde o Dolby Vision foi convertido (sucesso total ou parcial)

Write-Host ""
Line
SayTitulo "  RESUMO DA CONVERSAO:"
Line
Write-Host ""
Say ("  Total de Arquivos Encontrados  : {0}" -f $files.Count) "White"
Say-Contador "Convertidos com Sucesso"  $ok.Count      "Green"
Say-Contador "Convertidos com Avisos"   $parcial.Count "Yellow"
Say-Contador "Nao Finalizados (Erro)"   $falhou.Count  "Red"
Say-Contador "Ignorados (Ja Existiam)"  $pulado.Count  "DarkGray"
# A linha de cancelamento so aparece quando realmente houve [ESC] - em uma
# execucao normal ela nao polui o resumo.
if ($cancelado.Count -gt 0) {
    Say ("  Cancelados pelo Usuario        : {0}" -f $cancelado.Count) "Red"
    $naoProcessados = $files.Count - $resultados.Count
    if ($naoProcessados -gt 0) {
        Say ("  Nao Processados (Lote Parado)  : {0}" -f $naoProcessados) "DarkGray"
    }
}
Say ("  Tempo Total                    : {0}" -f (Format-Duracao $duracaoGeral.TotalSeconds)) "White"

# ---- detalhamento por processo ----------------------------------------------
# Contadores separados por frente de conversao (Dolby Vision, Audio, Legenda).
# Isso existe porque "Convertidos com Sucesso" sozinho nao diz o que cada
# frente realmente FEZ. Para nao poluir, mostramos SO as linhas com contagem
# maior que zero - ou seja, so o que de fato aconteceu neste lote (uma linha
# zerada nao agrega nada e so ocupa espaco).
if ($processados.Count -gt 0) {
    $dvConvertido       = @($processados | Where-Object { $_.StatusDV -eq "OK" }).Count
    $dvNaoNecess        = @($processados | Where-Object { $_.StatusDV -eq "NAO_NECESSARIO" }).Count
    $audioTrueHdConv    = @($processados | Where-Object { $_.StatusAudio -eq "OK" -and $_.TipoConvAudio -eq "TRUEHD" }).Count
    $audioDtsConv       = @($processados | Where-Object { $_.StatusAudio -eq "OK" -and $_.TipoConvAudio -eq "DTS" }).Count
    $audioJaOtimo       = @($processados | Where-Object { $_.StatusAudio -eq "JA_OTIMO" }).Count
    $audioNaoNecess     = @($processados | Where-Object { $_.StatusAudio -eq "NAO_NECESSARIO" }).Count
    $audioComFalha      = @($processados | Where-Object { $_.StatusAudio -eq "ERRO" }).Count
    $legendaConvertida  = @($processados | Where-Object { $_.StatusLegenda -eq "OK" }).Count
    $legendaJaTexto     = @($processados | Where-Object { $_.StatusLegenda -eq "JA_TEXTO" }).Count
    $legendaNaoNecess   = @($processados | Where-Object { $_.StatusLegenda -eq "NAO_NECESSARIO" }).Count
    $legendaComFalha    = @($processados | Where-Object { $_.StatusLegenda -eq "ERRO" }).Count
    $legendaDescManual  = @($processados | Where-Object { $_.StatusLegenda -eq "DESCARTADA_MANUAL" }).Count

    Write-Host ""
    SayTitulo "  DETALHAMENTO POR PROCESSO:"
    if ($dvConvertido -gt 0) { Say ("        Dolby Vision Convertido para Profile 8.1   : {0}" -f $dvConvertido) "Green" }
    if ($dvNaoNecess  -gt 0) { Say ("        Dolby Vision Ja Era Profile 8.1 (Mantido)  : {0}" -f $dvNaoNecess) "DarkGray" }
    if ($audioTrueHdConv   -gt 0) { Say ("        Audio TrueHD Convertido para E-AC-3 Atmos  : {0}" -f $audioTrueHdConv) "Green" }
    if ($audioDtsConv      -gt 0) { Say ("        Audio DTS Convertido para E-AC-3           : {0}" -f $audioDtsConv) "Green" }
    if ($audioJaOtimo      -gt 0) { Say ("        Audio Ja Estava Otimo (Atmos/Compativel)   : {0}" -f $audioJaOtimo) "Green" }
    if ($audioNaoNecess    -gt 0) { Say ("        Audio Nao Necessario (Sem Alternativa)      : {0}" -f $audioNaoNecess) "DarkGray" }
    if ($audioComFalha     -gt 0) { Say ("        Audio com Falha na Conversao               : {0}" -f $audioComFalha) "Red" }
    if ($legendaConvertida -gt 0) { Say ("        Legenda PT-BR (OCR)                        : {0}" -f $legendaConvertida) "Green" }
    if ($legendaJaTexto    -gt 0) { Say ("        Legenda PT-BR (Reaproveitada)              : {0}" -f $legendaJaTexto) "Green" }
    if ($legendaNaoNecess  -gt 0) { Say ("        Legenda Nao Necessaria (Nao Encontrada)    : {0}" -f $legendaNaoNecess) "DarkGray" }
    if ($legendaComFalha   -gt 0) { Say ("        Legenda com Falha no OCR                   : {0}" -f $legendaComFalha) "Red" }
    if ($legendaDescManual  -gt 0) { Say ("        Legenda PT-BR Descartada a Pedido (Manual) : {0}" -f $legendaDescManual) "DarkGray" }
}
Write-Host ""

# ---- helpers visuais do resumo tecnico -------------------------------------
# Cada episodio vira um "cartao" com rotulos alinhados e um marcador de status
# colorido a esquerda. Deixa a leitura muito mais rapida do que texto corrido.

function Split-TextoEmLinhas {
    # Quebra um texto longo em varias linhas de largura maxima definida,
    # respeitando palavras inteiras (nao corta no meio de uma palavra) -
    # exceto quando a propria palavra (ex: um nome de arquivo sem espacos)
    # e maior que a largura, caso em que ela e cortada em pedacos do
    # tamanho da largura para nao estourar a linha mesmo assim.
    param([string]$Texto, [int]$Largura = 68)
    if ([string]::IsNullOrWhiteSpace($Texto)) { return @() }
    $palavras = $Texto -split '\s+' | Where-Object { $_ }
    $linhas = New-Object System.Collections.Generic.List[string]
    $atual = ""
    foreach ($p in $palavras) {
        if ($p.Length -gt $Largura) {
            if ($atual) { $linhas.Add($atual); $atual = "" }
            for ($i = 0; $i -lt $p.Length; $i += $Largura) {
                $tam = [Math]::Min($Largura, $p.Length - $i)
                $linhas.Add($p.Substring($i, $tam))
            }
            continue
        }
        $candidato = if ($atual) { "$atual $p" } else { $p }
        if ($candidato.Length -gt $Largura -and $atual) {
            $linhas.Add($atual)
            $atual = $p
        } else {
            $atual = $candidato
        }
    }
    if ($atual) { $linhas.Add($atual) }
    return $linhas
}

function Get-MarcadorVisual($Marcador, $LarguraVisivel, $Cor) {
    # O simbolo sai da COR, nao do texto do marcador. Motivo: o mesmo marcador
    # "[--]" era usado tanto para "nao necessario" (cinza) quanto para o Status
    # de um episodio CANCELADO (vermelho) - decidindo pelo texto, os dois
    # ganhavam o mesmo desenho e a linha vermelha de cancelamento aparecia com
    # simbolo de "nao precisou". Como a cor JA carrega o estado em todo o
    # programa, derivar dela garante que simbolo e cor nunca se contradigam.
    if (-not $script:AnsiOn) { return ([string]$Marcador).PadRight($LarguraVisivel) }
    $m = ([string]$Marcador).Trim()
    if ($m -eq "") { return (" " * $LarguraVisivel) }
    # O TEXTO do marcador manda, nao a cor. A v11.3 fazia pela cor e criou uma
    # incoerencia que o usuario pegou: "nao necessario" e "aviso" sao os dois
    # ambar, entao pela cor os dois viravam TRIANGULO - e no diagnostico
    # "nao necessario" e CIRCULO. Dois desenhos para a mesma coisa na mesma
    # tela. Agora o triangulo fica reservado a aviso de verdade.
    # A cor entra so como desempate do "[--]", que serve para dois papeis
    # diferentes: nao-necessario (ambar/cinza) e Status de episodio CANCELADO
    # (vermelho).
    $c = [string]$Cor
    $sim = switch ($m) {
        "[OK]"    { $script:SimOk }
        "[ OK ]"  { $script:SimOk }
        "[!!]"    { $script:SimErr }
        "[FALHA]" { $script:SimErr }
        "[STOP ]" { $script:SimStop }
        "[AVISO]" { $script:SimWarn }
        "[SKIP ]" { $script:SimSkip }
        "[--]"    { if ($c -match "Red") { $script:SimStop } else { $script:SimSkip } }
        default   { $script:SimSkip }
    }
    return ($sim + (" " * [Math]::Max(1, $LarguraVisivel - $script:LarguraSimbolo)))
}

function Write-CampoResumo {
    param(
        [string]$Marcador,      # simbolo a esquerda: [OK] [--] [!!]
        [string]$CorMarcador,
        [string]$Rotulo,        # nome tecnico do campo (largura fixa)
        [string]$Valor,
        [string]$CorValor = "Gray"
    )
    # Textos curtos (uma linha) saem exatamente como antes. Textos longos
    # (ex: mensagens de erro) sao quebrados em varias linhas curtas,
    # indentadas sob a mesma coluna onde o valor comeca - em vez de uma
    # unica linha gigante que quebra feio e sem alinhamento no console.
    # Os marcadores do cartao usam EXATAMENTE os mesmos tres simbolos do resto
    # do programa, para "visto" significar a mesma coisa aqui e la em cima.
    # A largura visivel e mantida em 4 colunas na mao: PadRight nao serve
    # porque o seletor de variacao (U+FE0E) conta como caractere na string mas
    # nao ocupa coluna nenhuma na tela, e o alinhamento sairia torto.
    $marc = Get-MarcadorVisual $Marcador 4 $CorValor
    $prefixo    = "  {0}  {1}  " -f $marc, $Rotulo.PadRight(40)
    # Largura visivel fixa: 2 + 4 (marcador) + 2 + 40 (rotulo) + 2 = 50. Nao da
    # para usar $prefixo.Length porque o seletor U+FE0E entra na contagem da
    # string sem ocupar coluna na tela.
    $indentCont = " " * 50
    $rotuloPad  = ([string]$Rotulo).PadRight(40)
    # IMPORTANTE: envolver a chamada em @(...) forca o PowerShell a sempre
    # tratar o retorno como ARRAY, mesmo com 0 ou 1 item. Sem isso, quando
    # Split-TextoEmLinhas devolve EXATAMENTE 1 linha, o PowerShell "achata"
    # o retorno para uma STRING pura (nao um array de 1 posicao) - e ai
    # $linhasValor[0] passa a pegar o primeiro CARACTERE da string, nao a
    # primeira linha ("Convertido"[0] = "C"). Foi exatamente esse bug que
    # cortou todos os valores curtos do resumo para 1 letra so.
    $linhasValor = @(Split-TextoEmLinhas -Texto $Valor -Largura 68)
    # O ROTULO agora sai sempre em cinza e so o VALOR recebe a cor de status.
    # Antes a linha inteira era pintada com a cor do valor, o que fazia um campo
    # em vermelho gritar duas vezes (nome + conteudo). Com o rotulo neutro, a
    # cor sobra so para a informacao que realmente muda de estado.
    # O MARCADOR sai na cor do estado (era o erro da v11.2: ele vinha junto do
    # rotulo, dentro do mesmo trecho cinza, entao o visto e o quadrado apareciam
    # apagados). Rotulo continua cinza e o valor volta a ser o unico texto
    # colorido da linha - agora acompanhado por um simbolo da mesma cor.
    if ($linhasValor.Count -eq 0) {
        if ($script:AnsiOn) { Write-Host ("  " + (CorDe $CorValor) + $marc + "  " + (Cor "dim2") + $rotuloPad + $script:AnsiReset) }
        else { Write-Host ($prefixo.TrimEnd()) -ForegroundColor $CorValor }
        return
    }
    if ($script:AnsiOn) {
        Write-Host ("  " + (CorDe $CorValor) + $marc + "  " + (Cor "dim2") + $rotuloPad + "  " + (CorDe $CorValor) + $linhasValor[0] + $script:AnsiReset)
    } else {
        Write-Host ($prefixo + $linhasValor[0]) -ForegroundColor $CorValor
    }
    for ($i = 1; $i -lt $linhasValor.Count; $i++) {
        if ($script:AnsiOn) { Write-Host ($indentCont + (CorDe $CorValor) + $linhasValor[$i] + $script:AnsiReset) }
        else { Write-Host ($indentCont + $linhasValor[$i]) -ForegroundColor $CorValor }
    }
}

if ($resultados.Count -gt 0) {
    foreach ($r in $resultados) {
        Write-Host ""
        Line "-" "DarkGray"
        # cabecalho do cartao: marcador geral + nome do episodio (linha unica)
        $marcadorGeral = switch ($r.Status) {
            "OK"         { "[ OK ]"; break }
            "OK_PARCIAL" { "[AVISO]"; break }
            "PULADO"     { "[SKIP ]"; break }
            "CANCELADO"  { "[STOP ]"; break }
            default      { "[FALHA]" }
        }
        $corGeral = switch ($r.Status) {
            "OK"         { "Green"; break }
            "OK_PARCIAL" { "Yellow"; break }
            "PULADO"     { "DarkGray"; break }
            "CANCELADO"  { "Red"; break }
            default      { "Red" }
        }
        if ($script:AnsiOn) {
            # marcador colorido pelo status + nome do episodio sempre em
            # destaque neutro, para o nome nunca competir com o status.
            Write-Host ("  " + (CorDe $corGeral) + (Get-MarcadorVisual $marcadorGeral 6 $corGeral) + (Cor "foco") + [string]$r.Episodio + $script:AnsiReset)
        } else {
            Write-Host ("  {0}  {1}" -f $marcadorGeral, $r.Episodio) -ForegroundColor $corGeral
        }
        Write-Host ""

        if ($r.Status -eq "OK" -or $r.Status -eq "OK_PARCIAL") {
            # --- Video / Dolby Vision ---
            if ($r.StatusDV -eq "NAO_NECESSARIO") {
                Write-CampoResumo "[--]" "Yellow" "Dolby Vision -> Profile 8.1 (RPU)" "[NAO NECESSARIO]" "Yellow"
            } else {
                Write-CampoResumo "[OK]" "Green" "Dolby Vision -> Profile 8.1 (RPU)" "[CONVERTIDO]" "Green"
            }

            # --- Audio ---
            # Rotulo e icone variam conforme o que REALMENTE aconteceu:
            #   OK        -> convertido agora (TrueHD/DTS), rotulo mostra o tipo.
            #   JA_OTIMO  -> ja estava numa configuracao boa sem precisar de
            #                trabalho (Atmos/JOC ja existia, E-AC-3/AC-3 ja
            #                existia, ou a propria principal ja e compativel)
            #                - e um resultado POSITIVO, entao [OK] verde, nao
            #                [--] cinza (que fica reservado para "nao deu pra
            #                fazer nada": DeeZy indisponivel, codec nao
            #                tratado, faixa principal nao identificada).
            switch ($r.StatusAudio) {
                "OK" {
                    $rotuloAudio = if ($r.TipoConvAudio -eq "DTS") { "Audio DTS -> E-AC-3" } else { "Audio TrueHD -> E-AC-3 Atmos" }
                    Write-CampoResumo "[OK]" "Green" $rotuloAudio "[CONVERTIDO]" "Green"
                    break
                }
                "JA_OTIMO" {
                    $rotuloAudio = if ($r.MotivoAudio -match "Atmos/JOC") {
                        "Audio (E-AC-3 Atmos/JOC - PRESENTE)"
                    } elseif ($r.MotivoAudio -match "E-AC-3/AC-3 Compativel") {
                        "Audio (E-AC-3/AC-3 - PRESENTE)"
                    } else {
                        "Audio (Ja Compativel)"
                    }
                    Write-CampoResumo "[--]" "Yellow" $rotuloAudio "[NAO NECESSARIO]" "Yellow"
                    break
                }
                "ERRO" {
                    $rotuloAudio = if ($r.TipoConvAudio -eq "DTS") { "Audio DTS -> E-AC-3" } else { "Audio TrueHD -> E-AC-3 Atmos" }
                    Write-CampoResumo "[!!]" "Red" $rotuloAudio ("Falha - {0}" -f $r.MotivoAudio) "Red"
                    break
                }
                default {
                    # Genuinamente "nao deu pra fazer nada" - DeeZy indisponivel,
                    # codec nao tratado (PCM/FLAC), ou faixa principal nao
                    # identificada. Continua com o icone [--] cinza.
                    $rotuloAudio = if ($r.MotivoAudio -match "DeeZy Indisponivel") {
                        "Audio TrueHD (DeeZy Indisponivel)"
                    } elseif ($r.MotivoAudio -match "Nao Identificada") {
                        "Audio (Faixa Nao Identificada)"
                    } else {
                        "Audio ($($r.CodecAudio))"
                    }
                    Write-CampoResumo "[--]" "Yellow" $rotuloAudio "[NAO NECESSARIO]" "Yellow"
                }
            }

            # --- Legenda ---
            switch ($r.StatusLegenda) {
                "OK" {
                    Write-CampoResumo "[OK]" "Green" "Legenda PT-BR (OCR)" "[CONVERTIDO]" "Green"
                    break
                }
                "JA_TEXTO" {
                    Write-CampoResumo "[--]" "Yellow" "Legenda PT-BR [.SRT] (Reaproveitada)" "[NAO NECESSARIO]" "Yellow"
                    break
                }
                "DESCARTADA_MANUAL" {
                    Write-CampoResumo "[--]" "Yellow" "Legenda PT-BR [.SRT]" "[DESCARTADA A PEDIDO]" "Yellow"
                    break
                }
                "ERRO" {
                    Write-CampoResumo "[!!]" "Red" "Legenda PT-BR (OCR)" ("Falha - {0}" -f $r.MotivoLegenda) "Red"
                    break
                }
                default {
                    Write-CampoResumo "[--]" "Yellow" "Legenda PT-BR" "[NAO NECESSARIO]" "Yellow"
                }
            }

            # --- Descarte de faixas extras (audio/legenda desnecessarias) --
            # So aparece quando algum descarte de fato aconteceu neste
            # episodio - nao polui o cartao nos casos em que nada foi
            # filtrado (modo seguro, sem faixa principal/pt-BR identificada).
            if ($r.DescarteAudio -or $r.DescarteLegenda) {
                Write-CampoResumo "[OK]" "Green" "Descarte de Audios e Legendas [EXTRAS]" "[REMOVIDO]" "Green"
            }

            # --- Metricas tecnicas (mini-mediainfo do arquivo final) -------
            Write-Host ""
            Write-CampoResumo " " "DarkGray" "Container Final" ("Matroska (.mkv)  |  {0}" -f $r.Tamanho) "Gray"
            Write-CampoResumo " " "DarkGray" "Audio" $r.FaixasAudioMantidas "Gray"
            Write-CampoResumo " " "DarkGray" "Legenda" $r.FaixasLegendaMantidas "Gray"
            # FPS vem como fracao do ffprobe (ex: 24000/1001). Mostramos o valor
            # decimal amigavel (ex: 23.976) alem da fracao exata.
            $fpsInfo = ""
            if ($r.Fps) {
                $fpsTexto = $r.Fps
                if ($r.Fps -match '^(\d+)\s*/\s*(\d+)$' -and [int]$Matches[2] -ne 0) {
                    $fpsDec = [math]::Round([double]$Matches[1] / [double]$Matches[2], 3)
                    $fpsTexto = "{0} fps ({1})" -f $fpsDec, $r.Fps
                } else {
                    $fpsTexto = "{0} fps" -f $r.Fps
                }
                $fpsInfo = "  |  " + $fpsTexto
            }
            Write-CampoResumo " " "DarkGray" "Duracao / Taxa de Quadros" ("{0}{1}" -f $r.DuracaoVideo, $fpsInfo) "Gray"
            Write-CampoResumo " " "DarkGray" "Tempo de Processamento" $r.Tempo "Gray"
        } elseif ($r.Status -eq "PULADO") {
            Write-CampoResumo "[--]" "Yellow" "Status" ("Pulado - {0}" -f $r.Motivo) "Yellow"
        } elseif ($r.Status -eq "CANCELADO") {
            Write-CampoResumo "[--]" "Red" "Status" "Cancelado pelo Usuario" "Red"
            Write-CampoResumo "  "   "Red" "Motivo" $r.Motivo "Red"
        } else {
            Write-CampoResumo "[!!]" "Red" "Status" "Falha na Conversao" "Red"
            Write-CampoResumo "  "   "Red" "Motivo" $r.Motivo "Red"
        }
    }
    Write-Host ""
    Line "-" "DarkGray"
}

Line
Say ("  Pasta de Saida: {0}" -f $OutputDir) "White"
Say ("  Log Completo Salvo em: {0}" -f $LogFile) "DarkGray"
Line

} catch {
    Write-Host ""
    Line "!" "Red"
    SayErr $_.Exception.Message
    Say ("  Linha: {0}" -f $_.InvocationInfo.ScriptLineNumber) "Red"
    Line "!" "Red"
} finally {
    Write-Host ""
    # ORDEM IMPORTA: o transcript e fechado e limpo ANTES do "Pressione ENTER".
    # Na v11.0/11.1 a limpeza vinha depois, entao enquanto a janela esperava a
    # tecla o arquivo de log ainda estava aberto, sem rodape e cheio dos
    # codigos de cor crus - quem abrisse ou copiasse o log nesse momento pegava
    # a versao suja. Agora, quando o ENTER aparece na tela, o log ja esta
    # pronto e legivel.
    Stop-Transcript | Out-Null
    # LIMPEZA DO LOG: o transcript grava os codigos ANSI crus (ESC[38;2;...m),
    # que na tela viram cor mas no .txt seriam lixo ilegivel. Aqui o arquivo e
    # relido e todos os codigos sao removidos, deixando um log em texto puro -
    # e sem as centenas de linhas de porcentagem, que agora nao passam mais
    # pelo transcript. Falha aqui nao afeta nada: o pior caso e um log com os
    # codigos dentro, e a conversao ja terminou de qualquer forma.
    if ($script:AnsiOn) {
        try {
            $conteudoLog = [System.IO.File]::ReadAllText($LogFile)
            $conteudoLog = [regex]::Replace($conteudoLog, $script:PadraoAnsi, "")
            [System.IO.File]::WriteAllText($LogFile, $conteudoLog, (New-Object System.Text.UTF8Encoding($false)))
        } catch { }
    }
    Read-Host "Pressione ENTER para Fechar" | Out-Null
}
