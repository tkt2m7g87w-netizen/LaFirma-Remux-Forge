; ============================================================================
;  LaFirma Remux Forge - Black Edition
;  Script de instalacao (Inno Setup 6)
;
;  COMO COMPILAR: leia o LEIA-ME_INSTALADOR.txt. Resumo:
;    1. copie TODO o conteudo da pasta do programa para dentro de  fonte\
;    2. (OPCIONAL) copie o windowsdesktop-runtime-8.0.30-win-x64.exe para
;       redist\ . Se a pasta estiver vazia o instalador COMPILA IGUAL - so
;       fica 58 MB menor, e numa maquina sem .NET 8 ele oferece baixar da
;       Microsoft na hora de instalar. Ver redist\LEIA-ME.txt.
;    3. rode o Compilar.bat  (ou abra este arquivo no Inno e aperte F9)
;  O instalador pronto sai em  Saida\LaFirma_Setup_{#Versao}.exe
;
;  ---- 1.4: o que e obrigatorio dentro de fonte\ --------------------------
;  O motor NAO e mais um arquivo so. Desde a 14.1 ele CHAMA o
;  Corretor_Legenda.ps1 sozinho, e desde a 14.11 chama tambem o
;  Reocr_Legenda.ps1 - os dois dentro da etapa [4/5] (que era [5/7] ate a
;  14.13). Faltando qualquer um deles o instalador gera um LaFirma que
;  converte legenda pior, sem avisar ninguem.
;  Os DICIONARIOS sao dois, com papeis diferentes:
;    Auditor_OCR.dic.gz .......  50 mil palavras - usado pelo Auditor_OCR e
;                                pela correcao de acento do BinaryOCR
;    LaFirma_PTBR_1.3M.dic.gz .  1.296.517 palavras - usado pelo Corretor
;                                (2.9+) e pelo Reocr (1.2+)
;  Nenhum substitui o outro. Por isso os quatro viraram trava de compilacao
;  abaixo, no mesmo espirito das travas que ja existiam.
;
;  ---- TESSERACT: VAI NO INSTALADOR (desde a 14.23) ----------------------
;  1.7.1: este comentario dizia o CONTRARIO - "nao vai no instalador, e de
;  proposito" - e mandava rodar "winget install -e --id UB-Mannheim.
;  TesseractOCR". Era o mesmo texto velho que estava nos dois manuais e no
;  chip da janela, e ficou aqui depois de eu corrigir os outros tres.
;
;  Desde a 14.23 o tesseract.exe vai EMPACOTADO em fonte\tools\Tesseract\, com
;  por.traineddata e osd.traineddata - e ha um #error mais abaixo, neste
;  mesmo arquivo, que ABORTA a compilacao se a pasta faltar. Motor e Reocr
;  resolvem tools\Tesseract\ primeiro e so caem para o Tesseract do sistema
;  (PATH ou Program Files) se a pasta nao estiver la. O re-OCR de falas
;  curtas - o que troca "INF TOL" por "Nao!" - portanto funciona numa maquina
;  recem-formatada, sem instalar nada.
;
;  O seconv.exe (motor de OCR preferencial) e opcional na compilacao, mas se
;  ele estiver la o Latin.db TEM que estar junto - o motor exige os dois
;  ("$temSeconv = (Test-Path $seconv) -and (Test-Path $seconvDb)"). seconv
;  sozinho e 79 MB de peso morto que nunca roda.
; ============================================================================

#define Nome        "LaFirma Remux Forge"
#define NomeCompleto "LaFirma Remux Forge - Black Edition"
; ============================================================================
; VERSAO DO PRODUTO - A FONTE UNICA DA VERDADE.
;
; O programa tem UMA versao: a que aparece no titulo da janela, em
; Adicionar/Remover Programas, no nome do .exe e no topo de todo log.
; Motor, Janela, Corretor e Reocr continuam com numero proprio, mas isso e
; versao TECNICA de peca - existe para rastrear defeito, nao para o usuario
; responder "que versao do LaFirma eu tenho?".
;
; COMO NUMERAR (MAJOR.MINOR.PATCH):
;   MAJOR  1 -> 2         quebra compatibilidade, reescrita grande, mudanca
;                         de estrutura de pastas ou de formato de arquivo.
;   MINOR  1.4 -> 1.5     entrou RECURSO NOVO ou mudou algo que o usuario ve.
;   PATCH  1.5.0 -> 1.5.1 SO correcao de defeito, nada novo.
;
; 1.5.0 (26/08/2026): Tesseract empacotado (o programa virou portatil de
; verdade), PGS original mantida ao lado da .SRT, nota de qualidade da
; legenda no resumo, desinstalador que limpa a pasta inteira.
;
; Ao subir aqui, NAO e preciso mexer em .ps1 nenhum: o instalador escreve
; VERSAO.txt na pasta do programa e a Janela le esse arquivo.
;
; ATENCAO: comentario em .iss e ";" no comeco da linha. NAO usar <# #>, que e
; sintaxe de PowerShell - o Inno le como texto solto e aborta com
; "Text is not inside a section" (aconteceu em 26/08, linha 42).
; ============================================================================
#define Versao      "1.7.3"
#define VersaoGui   "16.75"
#define VersaoMotor "14.36"
#define VersaoCorretor "2.27"
#define VersaoReocr "1.29"
#define Publicador  "Diego"
#define Janela      "LaFirma_JANELA.ps1"
#define Lancador    "Abrir_LaFirma_JANELA.vbs"
#define Motor       "Converter_AUTO_DIRETO.ps1"
#define Corretor    "Corretor_Legenda.ps1"
#define Reocr       "Reocr_Legenda.ps1"
#define Dicionario  "Auditor_OCR.dic.gz"
; 1.4 (19/08): o dicionario GRANDE. O Corretor 2.9 em diante e o Reocr 1.2 em
; diante usam este, de 1.296.517 palavras (3,07 MB compactado) - o
; Auditor_OCR.dic.gz, de 50 mil, continua sendo o do Auditor. Sao dois
; arquivos diferentes com papeis diferentes; nenhum substitui o outro.
#define DicionarioGrande "LaFirma_PTBR_1.3M.dic.gz"
#define Runtime     "windowsdesktop-runtime-8.0.30-win-x64.exe"
#define LinkRuntime "https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/8.0.30/windowsdesktop-runtime-8.0.30-win-x64.exe"

; ---- Travas de compilacao: falham ALTO se a pasta fonte\ estiver incompleta.
;      Mesmo principio dos patches Python do projeto: melhor quebrar aqui do
;      que gerar um instalador que so falha na maquina do usuario.
#if !FileExists(AddBackslash(SourcePath) + "fonte\" + Janela)
  #error FALTA fonte\LaFirma_JANELA.ps1 - copie TODO o conteudo da pasta do programa para dentro de fonte\ antes de compilar.
#endif
#if !FileExists(AddBackslash(SourcePath) + "fonte\" + Motor)
  #error FALTA fonte\Converter_AUTO_DIRETO.ps1 - a janela NAO funciona sem o motor. Copie a pasta inteira do programa para fonte\.
#endif
#if !DirExists(AddBackslash(SourcePath) + "fonte\tools")
  #error FALTA fonte\tools\ - a pasta de ferramentas tem que vir junto.
#endif

; ---- 1.4: travas novas -----------------------------------------------------
#if !FileExists(AddBackslash(SourcePath) + "fonte\" + Corretor)
  #error FALTA fonte\Corretor_Legenda.ps1 - o motor chama ele sozinho na etapa [4/5] desde a v14.1. Sem ele a instalacao sai sem rede de seguranca de legenda.
#endif
#if !FileExists(AddBackslash(SourcePath) + "fonte\" + Reocr)
  #error FALTA fonte\Reocr_Legenda.ps1 - desde o motor 14.11 ele NAO e mais ferramenta avulsa: o motor chama ele dentro da etapa [4/5] e o resultado entra no .mkv final. E o que troca "INF TOL" por "Nao!". Sem ele a legenda sai sem a ultima correcao.
#endif
#if !FileExists(AddBackslash(SourcePath) + "fonte\" + Dicionario)
  #error FALTA fonte\Auditor_OCR.dic.gz - dicionario PT-BR de 50k. Usado pelo Auditor_OCR e pela correcao de acento do BinaryOCR. Sem ele os dois ficam mudos.
#endif
#if !FileExists(AddBackslash(SourcePath) + "fonte\" + DicionarioGrande)
  #error FALTA fonte\LaFirma_PTBR_1.3M.dic.gz - dicionario de 1.296.517 palavras (3,07 MB). E o que o Corretor 2.9+ e o Reocr 1.2+ usam. Com o de 50k no lugar dele volta a familia de falso positivo que a 2.9 fechou ("blipou", "pulso EM"). NAO substitua um pelo outro: sao dois arquivos, dois papeis.
#endif

; ---- seconv/BinaryOCR: opcional, mas nunca pela metade --------------------
#define SeconvExe "fonte\tools\SubtitleEdit\seconv.exe"
#define SeconvDb  "fonte\tools\SubtitleEdit\Latin.db"
#if FileExists(AddBackslash(SourcePath) + SeconvExe)
  #if !FileExists(AddBackslash(SourcePath) + SeconvDb)
    #error fonte\tools\SubtitleEdit\ tem o seconv.exe mas NAO tem o Latin.db. O motor exige os dois juntos - com so um deles o seconv nunca roda e vira 79 MB de peso morto no instalador. Copie o Latin.db de %AppData%\Subtitle Edit\Ocr\ para o lado do seconv.exe.
  #else
    #define TemSeconvLocal
  #endif
#else
  #pragma message "AVISO: fonte\tools\SubtitleEdit\seconv.exe nao encontrado. O instalador vai sair sem o motor de OCR preferencial - toda instalacao vai cair no PgsToSrt/Tesseract. Funciona, mas e o caminho que produz os blocos-lixo tipo OITECT."
#endif

; ---- libSkiaSharp.dll: NAO E RESTOLHO, E DEPENDENCIA REAL DO SECONV ------
; A auditoria de 13/08 concluiu que esta DLL era "restolho do pacote da GUI"
; porque o seconv.exe e single-file self-contained, e ela foi apagada de
; fonte\tools\SubtitleEdit\. A conclusao estava ERRADA, e o defeito ficou
; escondido por 12 dias porque a maquina de teste tinha o SubtitleEdit
; instalado e a DLL era encontrada por la.
; Na primeira instalacao limpa de verdade (25/08 19h43, sem SubtitleEdit no
; sistema) o seconv morreu na largada:
;     PGS OCR failed: The type initializer for 'SkiaSharp.SKImageInfo'
;     threw an exception.  -> Converted 0 file(s)
; O motor de OCR PREFERENCIAL estava fora do ar em qualquer maquina limpa.
; Por isso ela vira trava de compilacao junto com o Latin.db: as tres pecas
; do seconv sao inseparaveis.
#define SkiaDll "fonte\tools\SubtitleEdit\libSkiaSharp.dll"
#if !FileExists(AddBackslash(SourcePath) + SkiaDll)
  #error FALTA fonte\tools\SubtitleEdit\libSkiaSharp.dll - o seconv.exe DEPENDE dela, apesar de ser single-file. Sem ela o OCR preferencial falha com "The type initializer for SkiaSharp.SKImageInfo threw an exception" em qualquer maquina que nao tenha o SubtitleEdit instalado por fora. Recupere o arquivo do SeConv-Windows-x64.zip ou da pasta do SubtitleEdit e ponha em fonte\tools\SubtitleEdit\.
#endif

; ---- Tesseract standalone: EMPACOTADO desde a 14.23 ----------------------
; Ate a 1.4 o tesseract.exe era a UNICA peca do programa que nao vinha no
; pacote - dependia de o usuario ter instalado o UB-Mannheim por fora. Numa
; maquina recem-formatada o re-OCR de fala curta (o que troca "INF TOL" por
; "Nao!") simplesmente nao rodava, e nada quebrava de forma visivel: o
; instalador entregava um programa com um pedaco a menos, em silencio.
; Agora ele e trava de compilacao igual ao Latin.db - o setup RECUSA sair
; incompleto.
#define TessExe   "fonte\tools\Tesseract\tesseract.exe"
#define TessData  "fonte\tools\Tesseract\tessdata\por.traineddata"
#define TessDataPgs "fonte\tools\PgsToSrt\tessdata\por.traineddata"
#if !FileExists(AddBackslash(SourcePath) + TessExe)
  #error FALTA fonte\tools\Tesseract\tesseract.exe - copie a pasta inteira do Tesseract-OCR instalado (normalmente C:\Program Files\Tesseract-OCR) para fonte\tools\Tesseract\. Sem ela o programa instala e roda, mas a correcao de fala curta ("INF TOL" -> "Nao!") nao acontece numa maquina que nao tenha o Tesseract instalado por fora - que e exatamente o caso de uma maquina recem-formatada.
#else
  #if !FileExists(AddBackslash(SourcePath) + TessData) && !FileExists(AddBackslash(SourcePath) + TessDataPgs)
    #error fonte\tools\Tesseract\ tem o tesseract.exe mas NAO tem o por.traineddata (nem no tessdata\ dele nem no do PgsToSrt). Sem o dado de idioma o tesseract.exe falha em TODAS as leituras com "Error opening data file" - e o relatorio diria so "nenhuma leitura passou na trava", escondendo a causa real.
  #else
    #define TemTesseractLocal
  #endif
#endif

; O runtime e opcional na compilacao: se nao estiver em redist\, o instalador
; ainda e gerado, e na hora da instalacao ele oferece baixar da Microsoft.
;
; 1.7.1 - A ARMADILHA DO NOME EXATO. Diego: "eu acho q nem eh esse o runtime q
; funciona se bota fe, da onde vc tirou essa versao?". A versao 8.0.29 saiu do
; arquivo que estava na pasta dele. Mas ele apontou o risco certo: este teste
; procura o NOME EXATO do #define Runtime. Quem baixar a 8.0.31 (ou qualquer
; outra) tem um arquivo com outro nome, o FileExists da falso, e o instalador
; COMPILA EM SILENCIO sem o runtime - sem erro, sem aviso, e so se descobre
; numa maquina limpa sem .NET.
;
; Por isso o #pragma message abaixo: quando a pasta nao tem o nome esperado, a
; compilacao AVISA na tela do Inno, dizendo o que procurou. Continua compilando
; (o runtime e mesmo opcional), mas nao passa mais despercebido.
;
; Qualquer 8.0.x serve para o PgsToSrt; o que NAO serve e outra familia. O
; runtimeconfig dele pede "version": "8.0.0" sem rollForward, e o .NET so faz
; roll-forward DENTRO da mesma versao maior - net8.0 recusa 6.0, 9.0 e 10.0,
; inclusive as mais novas. Foi isso que fez o Diego passar uma noite instalando
; versao atras de versao ate uma funcionar.
;
; PARA DESCOBRIR QUAL ESTA NA MAQUINA, SEM COMPILAR NADA:
;     dir "C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App"
; cada versao instalada e uma pasta com o numero no nome. A 8.0.* que estiver
; la e a que funciona. Se voce baixar outra 8.0.x, mude o #define Runtime la
; em cima para o nome do arquivo baixado.
#if FileExists(AddBackslash(SourcePath) + "redist\" + Runtime)
  #define TemRuntimeLocal
#else
  #pragma message "AVISO: redist\{#Runtime} nao encontrado. O instalador vai sair 58 MB menor e, numa maquina sem o .NET Desktop Runtime 8.0, vai OFERECER BAIXAR da Microsoft durante a instalacao (precisa de internet naquele momento). Se voce baixou outra versao 8.0.x, o nome do arquivo e diferente: ajuste o #define Runtime no topo deste script. Ver redist\LEIA-ME.txt."
#endif

[Setup]
AppId={{7C4E9A16-3D52-4B8F-9E21-5A0C7F1B62D4}
AppName={#NomeCompleto}
AppVersion={#Versao}
AppVerName={#NomeCompleto} {#Versao}
AppPublisher={#Publicador}
VersionInfoVersion={#Versao}
VersionInfoDescription={#NomeCompleto} - conversor Dolby Vision Perfil 8.1

; C:\LaFirma - caminho CURTO e SEM ESPACO, e fora de Program Files de proposito:
; o motor grava log e temporarios ao lado do script, e dentro de Program Files o
; Windows bloqueia a escrita (ou a virtualiza e some com os logs).
DefaultDirName={sd}\LaFirma
DisableDirPage=no
DefaultGroupName={#Nome}
DisableProgramGroupPage=yes
AllowNoIcons=yes

OutputDir=Saida
OutputBaseFilename=LaFirma_Setup_{#Versao}
SetupIconFile=icone\LaFirmaRemuxForge.ico
UninstallDisplayIcon={app}\icone\LaFirmaRemuxForge.ico
; O icone tambem no canto das telas do assistente e no painel da esquerda.
; Condicional de proposito: se o .bmp nao existir, o Inno usa a arte padrao
; em vez de RECUSAR compilar - imagem bonita nao pode travar um build.
#if FileExists(AddBackslash(SourcePath) + "icone\wizard_small.bmp")
WizardSmallImageFile=icone\wizard_small.bmp
#endif
#if FileExists(AddBackslash(SourcePath) + "icone\wizard.bmp")
WizardImageFile=icone\wizard.bmp
#endif
UninstallDisplayName={#NomeCompleto}

Compression=lzma2/normal
SolidCompression=yes
WizardStyle=modern
; Precisa de admin para criar C:\ e para instalar o .NET Runtime.
PrivilegesRequired=admin

[Languages]
Name: "brazilian"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[CustomMessages]
brazilian.CriandoPastas=Criando as pastas de trabalho...
#ifdef TemSeconvLocal
brazilian.InstalandoRuntime=Instalando o .NET Desktop Runtime 8 (usado pela rede de seguranca do OCR de legenda)...
#else
brazilian.InstalandoRuntime=Instalando o .NET Desktop Runtime 8 (necessario para o OCR de legenda)...
#endif
brazilian.AtalhoConsole=Converter pelo Console (avancado)
brazilian.AtalhoBase=Pasta de Arquivos Base
brazilian.AtalhoSaida=Pasta de Arquivos Finalizados

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; ---- O programa inteiro, com tudo que estiver dentro de fonte\ -------------
; Este Source e RECURSIVO (recursesubdirs createallsubdirs): tudo que estiver
; em fonte\ entra sozinho, inclusive tools\SubtitleEdit\, Corretor_Legenda.ps1,
; Auditor_OCR.*, Reocr_Legenda.* e o Auditor_OCR.dic.gz. NAO e preciso criar
; entrada nova aqui pra arquivo novo - basta ele estar em fonte\.
;
; Excludes: o aviso da pasta, uma trava contra copiar video por engano para
; dentro de fonte\ (sem isso um .mkv esquecido viraria um instalador de 80 GB),
; e - 1.4 - as pastas/arquivos de trabalho que o proprio programa gera. Se voce
; testou dentro de fonte\ alguma vez, esse lixo iria junto pro instalador.
;
; O .vbs sai daqui de proposito: ele tem uma entrada propria logo abaixo,
; vinda de lancador\. Deixar as duas ativas fazia o mesmo arquivo ser copiado
; duas vezes, e se as copias divergissem, quem ganhava era a ultima - confusao
; garantida no dia em que o lancador mudar.
Source: "fonte\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; \
    Excludes: "COPIE_O_PROGRAMA_AQUI.txt,_testes\*,{#Lancador},README.md,LEIA_ME.txt,Limpar_Testes.ps1,Limpar_Testes.bat,Auditor_OCR.ps1,Auditor_OCR.bat,Reocr_Legenda.bat,deezy_work\*,*.mkv,*.mp4,*.m2ts,*.hevc,*.srt,*.sup,00_Arquivos_Base\*,01_Arquivos_Finalizados\*,_temp_conversao\*,_ddvt_temp_*\*,_logs\*,_corretor\*,_reocr\*,_auditoria_ocr\*,_retratos\*,LaFirma_motor_log_*.txt,log_conversao_*.txt,relatorio_*.txt,tools\DeeZy\apps\ffmpeg\*,tools\PgsToSrt\x86\*"

;
; ---- 1.7: O MANUAL TAMBEM E ENTREGA (03/09) -------------------------------
; Diego LEU o COMO_USAR e achou, num paragrafo, o que tres auditorias minhas
; nao acharam: a arvore ainda dizia "apps\ (ffmpeg, dee e truehdd internos do
; DeeZy)" um dia depois de eu tirar o ffmpeg de la. Eu tinha "atualizado" os
; manuais com um replace do numero da versao, sem reler o conteudo.
;
; Puxando esse fio, na mesma leitura:
;   - os dois manuais mandavam instalar o Tesseract por fora com winget e
;     baixar o .NET 8 na mao. Os dois vem no instalador desde a 14.23;
;   - o COMO_USAR dava so o fator 3,15x de disco. O motor usa 1,6x quando o
;     video ja e Profile 8.1 e nem sai do container (v14.16);
;   - os dois afirmavam que temporario "nunca acumula" - o Troy travado de
;     01/09 desmentiu isso na pratica;
;   - o chip da janela dizia "Tesseract standalone" (GUI 16.75 corrige);
;   - e o Converter_AUTO_DIRETO.bat dizia v14.34 com o motor em 14.35 - o
;     mesmo tipo de titulo parado que ele ja tinha achado na 1.6.7.
;
; A bateria ganhou testes para cada um desses: manual e .bat agora sao
; conferidos contra o CODIGO, nao contra a minha memoria.
;
; ---- 1.6.9: OS 40 MB QUE FALTAVAM (03/09) ---------------------------------
; Diego: "e ae o ffmpeg a +? quando se vai resolve isso [...] ou vc tem medo
; de fuder tudo?".
;
; Na 1.6.8 eu tirei as subpastas e deixei os 40 MB do ffmpeg.exe duplicado,
; alegando a minha propria regra (mudanca no motor nao vai para build sem
; conversao real). A regra continua valendo, mas ela nao se aplica aqui: o
; ffmpeg.exe de tools\DeeZy\apps\ffmpeg\ e BYTE A BYTE o mesmo
; tools\ffmpeg.exe - MD5 70195e0342959d38e4ddb410456c9de2, 40.808.448 bytes
; nos dois. Apontar o --ffmpeg para o outro caminho executa O MESMO BINARIO;
; nao existe comportamento novo que possa dar errado.
;
; MOTOR 14.35 faz isso, e o Exclude agora e a pasta inteira:
;
;     tools\DeeZy\apps\ffmpeg\*
;
; Total tirado desde a 1.6.7: 297 MB.
;
; ---- 1.6.8: 251 MB DE ffmpeg QUE NUNCA RODOU (03/09) ----------------------
; Diego, depois de tres auditorias minhas: "esse tempo todo q eu falo de lixo
; desnecessario [...] vc agora a pouco quis tirar kbytes por peso [...] e vc
; nao ve 251 megas".
;
; A pasta tools\DeeZy\apps\ffmpeg\ veio de um zip de BUILD COMPLETO do
; ffmpeg. O motor so chama UM arquivo dela - o ffmpeg.exe da raiz - na linha
; do --ffmpeg passado ao DeeZy. Tudo o mais e sobra do zip:
;
;     bin\       237,6 MB   ffmpeg/ffplay/ffprobe + DLLs shared, nunca chamados
;     doc\        11,0 MB   documentacao HTML
;     lib\         1,7 MB   .lib de quem vai COMPILAR contra o ffmpeg
;     include\     1,2 MB   headers .h, idem
;     presets\     0,0 MB
;
; E na mesma varredura, o PgsToSrt: a pasta x86\ (5,5 MB - leptonica e
; tesseract53 de 32 bits). O PgsToSrt.exe e PE32+ / machine 0x8664: x64 puro.
; O Tncl.NativeLoader dele escolhe x64\ ou x86\ pela arquitetura do PROCESSO,
; e o processo nunca vai ser 32 bits. A pasta x86\ nao tem como ser aberta.
;
; E o ffmpeg.exe que fica (40.808.448 bytes) e BYTE A BYTE o mesmo arquivo que
; tools\ffmpeg.exe - MD5 70195e0342959d38e4ddb410456c9de2 nos dois. Nao mexi
; nisso porque o motor passa os dois caminhos de proposito (o comentario da
; linha 1859 do motor explica: sobreviver a mudanca de auto-discovery do
; DeeZy). 40 MB duplicados sao aceitaveis; 251 MB de peso morto nao eram.
;
; POR QUE AQUI E NAO APAGANDO A PASTA: apagar resolve nesta maquina, nesta
; semana. O Exclude resolve para sempre - se um dia alguem re-extrair o zip do
; ffmpeg por cima, o instalador continua sem levar.
;
; ---- 1.6.4: A FAXINA DO INSTALADOR (pedido do Diego, 02/09) ----------------
; "o usuario final nao vai ficar fazendo teste, ele so vai abrir o programa e
; usar (...) temos q enxugar esse monte de .bat e .ps1 do instalador final".
; Sairam, todos conferidos um por um contra quem os chama:
;   Limpar_Testes.ps1/.bat  - ferramenta de desenvolvimento. Nada no programa
;                             chama: so o proprio Limpar_Testes se cita.
;   Auditor_OCR.ps1/.bat    - idem.
;   deezy_work\*             - pasta de trabalho que o DeeZy cria DENTRO de
;                             tools\DeeZy\ quando roda aqui na arvore de
;                             fontes (batch-results\ e logs\). Nao e do
;                             programa: e sujeira de execucao, e ia junto.
;
; ATENCAO - O Auditor_OCR.dic.gz FICA, e por pouco eu tirei junto (02/09).
; O nome engana: ele parece ser "o dicionario do Auditor" e o Auditor esta
; saindo. Mas quem le esse arquivo tambem e o MOTOR, em
; Converter_AUTO_DIRETO.ps1 (o $seconvDic que alimenta a Repara-AcentoBinaryOcr,
; a correcao de acento da legenda que sai do seconv/BinaryOCR). Sem o arquivo
; a funcao devolve vazio, a correcao desiste na primeira linha e NAO IMPRIME
; NADA - que e exatamente o defeito calado que a v14.5 fechou. O Corretor
; tambem o usa como segunda opcao, se o dicionario de 1.3M nao estiver la.
; 199 KB. Fica.
;   Reocr_Legenda.bat       - o .ps1 FICA (o motor chama em toda legenda PGS);
;                             o .bat era so pra rodar solto, na mao.
;
; 1.6.7 - O Abrir_LaFirma_JANELA.bat VOLTOU. Eu o tinha tirado por ser "um
; segundo caminho para a mesma coisa que o .vbs, so que com console piscando".
; Errado: o console piscando E o motivo de ele existir. Diego usa esse .bat
; para TESTAR - abre pela pasta e a tela preta mostra o erro que o .vbs
; esconde. Ferramenta que se usa toda semana nao sai por causa de 167 bytes.
; O .vbs continua sendo o caminho do usuario final (atalho do menu).
; FICARAM de proposito: Converter_AUTO_DIRETO.bat (o modo console e o plano B
; de quando a janela nao abre - 278 bytes que salvam o programa inteiro),
; Corretor_Legenda.ps1 e Reocr_Legenda.ps1 (o motor chama os dois), o
; LaFirma_PTBR_1.3M.dic.gz (o Corretor e o Reocr leem), COMO_USAR_PT.txt,
; HOW_TO_USE_EN.txt e o Changelog.txt.
;
; ---- A BATERIA DE TESTES NAO ENTRA (decisao de 27/08) -----------------------
; _testes\ continua nos Excludes do Source de cima, de proposito. Ela e
; ferramenta de DESENVOLVIMENTO - roda antes de compilar, na arvore de fontes.
; Instalador e do usuario final; bateria de regressao nao e assunto dele.
; Se um dia isso mudar, basta acrescentar aqui uma entrada PROPRIA (nao adianta
; so tirar do Excludes): o "*.srt" que esta nos Excludes do Source de cima
; deixaria as AMOSTRAS para tras sem ninguem perceber, e a bateria chegaria
; quebrada do outro lado.

; 1.5.5: LEIA_ME.txt entrou nos Excludes pelo mesmo motivo do README.md, e o
; caso e pior porque o arquivo era RECENTE e parecia legitimo. Ele veio junto
; de uma entrega de 27/08 (instrucoes de "extraia por cima de C:\LaFirma"),
; ficou solto em fonte\ e seria instalado na maquina do usuario final anunciando
; "Janela 16.60 | Corretor 2.23 | Reocr 1.24" - versoes que ja nao existiam - e
; falando de uma pasta _para_compilar\ que o usuario nao tem. Arquivo de recado
; entre a gente nao e documentacao de produto: os manuais do usuario sao o
; COMO_USAR_PT.txt e o HOW_TO_USE_EN.txt.
;
; 1.4: README.md entrou nos Excludes porque e um arquivo de scaffold antigo
; (datado de 29/06/2025, bem antes do projeto existir de verdade) que sobrou
; solto dentro de fonte\ - nao e lido por nenhum script nem citado em nenhum
; outro lugar do projeto. Sem o Exclude ele seria copiado pra dentro de
; {app} em toda instalacao, sem nenhuma utilidade pro usuario final.
Source: "icone\LaFirmaRemuxForge.ico"; DestDir: "{app}\icone"; Flags: ignoreversion
Source: "lancador\{#Lancador}"; DestDir: "{app}"; Flags: ignoreversion

; ---- .NET Desktop Runtime 8: so e extraido se realmente faltar na maquina --
#ifdef TemRuntimeLocal
Source: "redist\{#Runtime}"; DestDir: "{tmp}"; Flags: deleteafterinstall; Check: PrecisaDotNet
#endif

[Dirs]
; users-modify: o programa roda SEM elevacao depois de instalado, e precisa
; gravar log, temporarios e os videos convertidos aqui dentro.
Name: "{app}";                            Permissions: users-modify
Name: "{app}\00_Arquivos_Base";           Permissions: users-modify
Name: "{app}\01_Arquivos_Finalizados";    Permissions: users-modify
; _logs: os dois scripts criam sozinhos se faltar, mas ja deixar criada com
; permissao de escrita evita qualquer surpresa na primeira execucao.
Name: "{app}\_logs";                      Permissions: users-modify
; 1.6.4: _corretor e _reocr NAO nascem mais na instalacao. Elas sao pastas de
; INVESTIGACAO: o motor cria quando precisa e, desde o 14.34, apaga o conteudo
; sozinho quando a legenda sai EXCELENTE ou BOA. Cria-las vazias na instalacao
; so servia para o usuario abrir duas pastas vazias e se perguntar o que era.

[Icons]
; 16.25: o atalho chama o lancador .vbs, nao o powershell.exe direto. O .vbs
; usa WScript.Shell.Run com janela escondida no nivel do processo - isso
; evita o "flash" de console/Terminal que o -WindowStyle Hidden sozinho nao
; suprime mais em builds recentes do Windows 11 (Windows Terminal como host
; padrao). O icone do atalho continua sendo o do programa; o icone da JANELA
; em si (title bar / barra de tarefas quando aberta) vem do proprio script
; PowerShell, que agora define Window.Icon (ver LaFirma_JANELA.ps1 16.25).
; AppUserModelID: TEM que ser exatamente o mesmo texto que o LaFirma_JANELA.ps1
; declara em codigo (16.26+). E esse par atalho<->processo que faz o Windows
; resolver o botao da barra de tarefas na hora. So o codigo, sem o atalho
; declarando o mesmo ID, deixa o botao "orfao": demora ~20s pra achar o icone
; e a janela some do Alt+Tab visual quando minimizada.
Name: "{group}\{#Nome}"; \
    Filename: "{sys}\wscript.exe"; \
    Parameters: """{app}\{#Lancador}"""; \
    WorkingDir: "{app}"; IconFilename: "{app}\icone\LaFirmaRemuxForge.ico"; \
    AppUserModelID: "LaFirma.RemuxForge.BlackEdition"; \
    Comment: "{#NomeCompleto}"

Name: "{autodesktop}\{#Nome}"; \
    Filename: "{sys}\wscript.exe"; \
    Parameters: """{app}\{#Lancador}"""; \
    WorkingDir: "{app}"; IconFilename: "{app}\icone\LaFirmaRemuxForge.ico"; \
    AppUserModelID: "LaFirma.RemuxForge.BlackEdition"; \
    Comment: "{#NomeCompleto}"; Tasks: desktopicon

; Plano B: o modo console puro, que nao depende da janela.
Name: "{group}\{cm:AtalhoConsole}"; Filename: "{app}\Converter_AUTO_DIRETO.bat"; \
    WorkingDir: "{app}"; IconFilename: "{app}\icone\LaFirmaRemuxForge.ico"

Name: "{group}\{cm:AtalhoBase}";  Filename: "{app}\00_Arquivos_Base"
Name: "{group}\{cm:AtalhoSaida}"; Filename: "{app}\01_Arquivos_Finalizados"

[Run]
#ifdef TemRuntimeLocal
Filename: "{tmp}\{#Runtime}"; Parameters: "/install /passive /norestart"; \
    StatusMsg: "{cm:InstalandoRuntime}"; Check: PrecisaDotNet; \
    Flags: waituntilterminated
#endif

Filename: "{sys}\wscript.exe"; \
    Parameters: """{app}\{#Lancador}"""; \
    WorkingDir: "{app}"; Description: "Abrir o {#Nome} agora"; \
    Flags: nowait postinstall skipifsilent

[UninstallDelete]
; 1.4.1: DESINSTALAR PASSOU A SIGNIFICAR SUMIR DE VERDADE.
;
; Ate aqui esta secao removia apenas as pastas de trabalho, e o Inno remove
; sozinho apenas os arquivos que ELE escreveu. Resultado medido na maquina do
; Diego em 25/08: depois de desinstalar, C:\LaFirma continuava com 17 itens -
; scripts copiados a mao durante os testes, o Checar_Ambiente antigo e um
; Auditor_OCR.dic.gz de 3 MB (o dicionario grande com o nome errado). Nada
; disso e do usuario; e residuo. Um desinstalador que deixa residuo nao
; desinstalou.
;
; Agora vai tudo. O QUE O USUARIO CRIOU e tratado no [Code], em
; CurUninstallStepChanged, que pergunta antes - ver la embaixo.
Type: filesandordirs; Name: "{app}\_logs"
Type: filesandordirs; Name: "{app}\_corretor"
Type: filesandordirs; Name: "{app}\_reocr"
Type: filesandordirs; Name: "{app}\_auditoria_ocr"
Type: filesandordirs; Name: "{app}\_temp_conversao"
Type: filesandordirs; Name: "{app}\tools"
Type: files;          Name: "{app}\*.ps1"
Type: files;          Name: "{app}\*.bat"
Type: files;          Name: "{app}\*.vbs"
Type: files;          Name: "{app}\*.dic.gz"
Type: files;          Name: "{app}\*.txt"
Type: files;          Name: "{app}\*.md"

[Code]
var
  RuntimeFoiInstalado: Boolean;

{ ---- Deteccao do .NET Desktop Runtime 8 --------------------------------------
  Quem precisa do .NET aqui e o PgsToSrt.exe, que e um app .NET framework-
  dependent. O seconv.exe NAO precisa: ele e publicado self-contained e
  single-file (confirmado no workflow oficial build-seconv.yml do Subtitle
  Edit), entao carrega o proprio runtime dentro dos 79 MB dele.
  A checagem e por PASTA de versao instalada, que e o jeito que nao depende
  do 'dotnet' estar no PATH.                                                }
function TemWindowsDesktop8(): Boolean;
var
  Raiz, Base: String;
  Rec: TFindRec;
begin
  Result := False;

  Raiz := GetEnv('ProgramW6432');
  if Raiz = '' then
    Raiz := GetEnv('ProgramFiles');
  if Raiz = '' then
    Exit;

  Base := AddBackslash(Raiz) + 'dotnet\shared\Microsoft.WindowsDesktop.App';
  if not DirExists(Base) then
    Exit;

  if FindFirst(AddBackslash(Base) + '8.*', Rec) then
  begin
    try
      repeat
        if (Rec.Attributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
        begin
          Result := True;
          Break;
        end;
      until not FindNext(Rec);
    finally
      FindClose(Rec);
    end;
  end;
end;

function PrecisaDotNet(): Boolean;
begin
  Result := not TemWindowsDesktop8();
end;

function InitializeSetup(): Boolean;
begin
  Result := True;
  if not IsWin64 then
  begin
    MsgBox('Este programa precisa de um Windows 64 bits.' + #13#10 +
           'As ferramentas de conversao (ffmpeg, dovi_tool, mkvmerge) sao todas x64.',
           mbCriticalError, MB_OK);
    Result := False;
  end;
end;

{ Escreve o VERSAO.txt na pasta do programa logo apos copiar os arquivos.
  E o unico lugar onde a versao do produto existe em disco: a Janela le dali,
  entao subir a versao no topo deste .iss basta - nenhum .ps1 precisa mudar.
  (Sem escrever a constante de pasta com chaves aqui: em Pascal chave FECHA
   comentario - ver o aviso grande la embaixo, no bloco da desinstalacao.) }
procedure EscreverVersaoTxt();
var
  Linhas: TArrayOfString;
begin
  SetArrayLength(Linhas, 8);
  Linhas[0] := '{#NomeCompleto} v{#Versao}';
  Linhas[1] := 'Produto   : {#Versao}';
  Linhas[2] := 'Janela    : {#VersaoGui}';
  Linhas[3] := 'Motor     : {#VersaoMotor}';
  Linhas[4] := 'Corretor  : {#VersaoCorretor}';
  Linhas[5] := 'Reocr     : {#VersaoReocr}';
  Linhas[6] := 'Instalado : ' + GetDateTimeString('dd/mm/yyyy hh:nn', '/', ':');
  Linhas[7] := '';
  try
    SaveStringsToFile(ExpandConstant('{app}\VERSAO.txt'), Linhas, False);
  except
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Codigo: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    EscreverVersaoTxt();

    { Confere DEPOIS de instalar. Se ainda faltar o runtime, avisa e oferece
      abrir a pagina da Microsoft - nunca deixa o usuario descobrir sozinho
      la na etapa 5/7 que a legenda nao saiu.

      1.4: o texto agora depende de o seconv ter sido empacotado ou nao. Com
      o seconv junto, faltar o .NET NAO desliga o OCR - desliga so a rede de
      seguranca (PgsToSrt + Corretor_Legenda). Dizer "o OCR fica desligado"
      nesse caso seria mentira, e mentira que assusta o usuario a toa.     }
    if PrecisaDotNet() then
    begin
#ifdef TemSeconvLocal
      if MsgBox('O .NET Desktop Runtime 8 nao foi encontrado neste computador.' + #13#10 + #13#10 +
                'O OCR de legenda continua funcionando: o motor principal de OCR (seconv/BinaryOCR) ' +
                'vem junto com o programa e nao depende do .NET.' + #13#10 + #13#10 +
                'O que fica desligado e a REDE DE SEGURANCA (PgsToSrt + Corretor_Legenda), que so ' +
                'entra em acao quando o motor principal falha em algum arquivo.' + #13#10 + #13#10 +
                'Quer abrir a pagina de download da Microsoft agora?',
                mbConfirmation, MB_YESNO) = IDYES then
#else
      if MsgBox('O .NET Desktop Runtime 8 nao foi encontrado neste computador.' + #13#10 + #13#10 +
                'Sem ele o programa instala e converte normalmente, mas o OCR de legenda ' +
                '(PGS para SRT, etapa 5/7) fica desligado.' + #13#10 + #13#10 +
                'Quer abrir a pagina de download da Microsoft agora?',
                mbConfirmation, MB_YESNO) = IDYES then
#endif
      begin
        ShellExec('open', '{#LinkRuntime}', '', '', SW_SHOWNORMAL, ewNoWait, Codigo);
      end;
    end;
  end;
end;

{ ---- Desinstalacao: o que fazer com as pastas de video -----------------------

  ATENCAO A QUEM FOR EDITAR ESTE COMENTARIO:
  em Pascal, chaves sao delimitador de COMENTARIO. Escrever a constante da
  pasta do programa (com chaves, como se usa nas secoes [Files] e afins) aqui
  dentro FECHA o comentario naquele ponto e o resto do texto vira codigo.
  Foi exatamente o que derrubou a compilacao em 26/08:
      Error on line 434: Column 58: 'BEGIN' expected.
  A coluna 58 era o fecha-chaves do meio da palavra. Dentro de comentario,
  escreva "a pasta do programa" por extenso. No CODIGO, use
  UninstallExpandConstant, que e onde a constante deve mesmo aparecer.

  REGRA (decisao do Diego, 25/08): "apaga tudo mas avisa se tiver coisa dentro
  dessas pastas e se eu quiser manter so elas apos desinstalar, deixar".

  Ou seja: o programa some inteiro, sem residuo. As DUAS pastas de video
  (00_Arquivos_Base e 01_Arquivos_Finalizados) sao o unico lugar onde pode
  haver arquivo que o usuario colocou - e por isso sao as unicas sobre as
  quais se pergunta, e so quando ha algo dentro.

  Se estiverem vazias, nada e perguntado e a pasta do programa some
  inteira: caixa de dialogo sem decisao a tomar e so mais um clique.
------------------------------------------------------------------------------ }

function PastaTemArquivo(const Caminho: String): Boolean;
var
  Busca: TFindRec;
begin
  Result := False;
  if FindFirst(AddBackslash(Caminho) + '*', Busca) then
  begin
    try
      repeat
        if (Busca.Name <> '.') and (Busca.Name <> '..') then
        begin
          Result := True;
          Exit;
        end;
      until not FindNext(Busca);
    finally
      FindClose(Busca);
    end;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  PastaBase, PastaFinal, PastaApp, Aviso: String;
  TemBase, TemFinal: Boolean;
begin
  if CurUninstallStep <> usPostUninstall then
    Exit;

  { ExpandConstant: durante a desinstalacao o Inno resolve a constante da
    pasta do programa pelo valor gravado no registro.
    UninstallExpandConstant NAO existe no Inno Setup 6 - tentar usar da
    "Unknown identifier" e aborta a compilacao. }
  PastaBase  := ExpandConstant('{app}\00_Arquivos_Base');
  PastaFinal := ExpandConstant('{app}\01_Arquivos_Finalizados');

  TemBase  := DirExists(PastaBase)  and PastaTemArquivo(PastaBase);
  TemFinal := DirExists(PastaFinal) and PastaTemArquivo(PastaFinal);

  if TemBase or TemFinal then
  begin
    Aviso := 'Ainda ha arquivos nas suas pastas de video:' + #13#10 + #13#10;
    if TemBase then
      Aviso := Aviso + '    00_Arquivos_Base' + #13#10;
    if TemFinal then
      Aviso := Aviso + '    01_Arquivos_Finalizados' + #13#10;
    Aviso := Aviso + #13#10 +
      'SIM  = manter essas pastas e o que ha dentro delas.' + #13#10 +
      '       Todo o resto do programa ja foi removido.' + #13#10 + #13#10 +
      'NAO  = apagar tambem essas pastas, com os arquivos dentro.' + #13#10 +
      '       Esta acao nao tem volta.' + #13#10 + #13#10 +
      'Quer MANTER as pastas de video?';

    if MsgBox(Aviso, mbConfirmation, MB_YESNO) = IDNO then
    begin
      DelTree(PastaBase,  True, True, True);
      DelTree(PastaFinal, True, True, True);
    end;
  end
  else
  begin
    { Vazias: nada a preservar e nada a perguntar. }
    DelTree(PastaBase,  True, True, True);
    DelTree(PastaFinal, True, True, True);
  end;

  { Se depois de tudo a pasta do programa ficou vazia, ela tambem sai - senao
    fica uma casca vazia em C:\ que o usuario tem que apagar a mao. }
  PastaApp := ExpandConstant('{app}');
  if DirExists(PastaApp) and (not PastaTemArquivo(PastaApp)) then
    RemoveDir(PastaApp);
end;
