# LaFirma Remux Forge (Black Edition)

> **Automated MKV Remuxing & Transcoding Engine**  
> *Convert Dolby Vision Profile 7 (MEL/FEL) to 8.1 without video re-encoding, transcode audio to E-AC-3 with Atmos, and process PT-BR PGS OCR subtitles with a smooth PowerShell GUI.*

[![Language: PT-BR](https://img.shields.io/badge/Language-Portuguese-green.svg)](#-português)
[![Language: EN](https://img.shields.io/badge/Language-English-blue.svg)](#-english)

---

## 📥 Downloads & Official Links / Links Oficiais

> ### ⚠️ Onde está o mais atual / Where the newest version lives
> **Este repositório é a fonte mais completa e mais atual do projeto.** Os espelhos abaixo (Proton Drive, MEGA, GoFile) continuam no ar e funcionam, mas **estão desatualizados** — eles trazem uma versão anterior do programa. Para o código, os manuais e o registro de mudanças mais recentes, use o que está aqui no GitHub.
>
> **This repository is the most complete and most up-to-date source for the project.** The mirrors below (Proton Drive, MEGA, GoFile) are still online and working, but **they are out of date** — they carry an earlier version of the program. For the latest code, manuals and changelog, use what is here on GitHub.

### 📦 Standalone Installer / Programa Pronto para Usar
> Download the compiled setup to install and use immediately / Baixe a versão compilada para instalar e usar imediatamente:
* **PROTON DRIVE:** [Download / Baixar LaFirma Remux Forge](https://drive.proton.me/urls/ZATVE13HWM#em0BACyqRM5J)
* **MEGA:** [Download / Baixar LaFirma Remux Forge](https://mega.nz/file/abxFWYpR#3DjvTORJqK-XMqp7uvR8l30qJT67wAS6OVpxLnlTI-I)
* **GOFILE:** [Download / Baixar LaFirma Remux Forge](https://gofile.io/d/YE2isutz)

---

### 💻 Full Source Code & Dev Guides / Código-Fonte & Guias
> Access the complete project directory or installer compilation guides / Para desenvolvedores e compilação do .iss:
* **AQUI NESTE REPOSITÓRIO / RIGHT HERE IN THIS REPO** — código-fonte completo, sempre o mais novo / complete source code, always the newest
* **PROTON DRIVE (Full Folder / Pasta Completa):** [Access / Acessar](https://drive.proton.me/urls/FQWT6PB5W4#VgsXd07uV4OK) *(desatualizado / outdated)*
* **MEGA (Full Folder / Pasta Completa):** [Access / Acessar](https://mega.nz/folder/aSpxxJII#v5CzveN0-Um9LryBnjfMMQ) *(desatualizado / outdated)*
* **Installer Compilation Guide (PT-BR):** [Consulte LEIA-ME_INSTALADOR[PT-BR].txt](./LEIA-ME_INSTALADOR[PT-BR].txt)
* **Installer Compilation Guide (EN):** [Check README_INSTALLER[ENGLISH].txt](./README_INSTALLER[ENGLISH].txt)

> **Por que os binários não estão no repositório / Why the binaries are not in the repo:** a pasta `tools\` tem centenas de MB de programas de **outras pessoas**, cada um com a sua licença. Não republicamos o trabalho dos outros como se fosse nosso — o repositório diz de onde cada um vem, e o pacote pronto existe para quem só quer usar. / The `tools\` folder holds hundreds of MB of **other people's** programs, each under its own licence. We do not republish other people's work as our own — the repo says where each one comes from, and the ready-made package exists for those who just want to use it.

---

## 🇵🇹 Português

O **LaFirma Remux Forge** foi criado para resolver de forma definitiva os problemas de incompatibilidade de mídia em Smart TVs (LG, Samsung), players (Shield, Apple TV, Zidoo) e servidores de mídia (**Plex**, **Jellyfin**, **Emby**).

Desenvolvido para automatizar o processamento de encodes de Blu-ray e arquivos remux, o software atua como uma ponte de orquestração: desenvolvemos toda a interface gráfica (GUI) fluida, as regras de decisão automatizadas e o motor em PowerShell que integra e automatiza ferramentas consagradas da comunidade (`ffmpeg`, `mkvmerge`, `dovi_tool`, `DDVT`, `PgsToSrt`, `Tesseract`, `DeeZy`, `seconv`). É a solução ideal tanto para arquivos individuais quanto para o processamento em lote de temporadas completas de séries.

### 💡 Dolby Vision: o programa MEDE antes de converter

Esta é a diferença que define o projeto. Converter um Perfil 7 **não é sempre a mesma coisa**, e o programa deixou de tratar como se fosse.

Antes de tocar no arquivo, ele lê o campo `el_type` dentro do RPU (com o `dovi_tool`) e separa **três** casos:

| | Cor na tela | O que significa |
|---|---|---|
| **MEL** — Minimal Enhancement Layer | 🟢 verde | A camada extra **não carrega imagem**. Descartar não muda um pixel. |
| **Simple FEL** | 🟠 laranja | A camada carrega imagem, mas é **refino** — residual, grão, degradê. Perde-se detalhe fino, visível só em quadro parado. |
| **Complex FEL** | 🔴 vermelho | A camada **levanta o brilho**. Sem ela, o RPU pede à TV um pico que o vídeo não entrega mais. É o único caso que incomoda. |

**O que separa Simple de Complex é um número:** o L1 do RPU (o pico que o arquivo pede) contra o pico do mastering display (o monitor em que o filme foi colorizado, declarado dentro do próprio arquivo). Se o arquivo não declara esse pico, **o programa diz que não sabe** em vez de escolher um lado.

Medido em máquina, sem consultar lista nenhuma:

```
Troy (2004) Director's Cut  ->  MEL            303 nits de 1.000
Game of Thrones S08E01      ->  SIMPLE FEL     153 nits de 1.000
Saving Private Ryan (1998)  ->  COMPLEX FEL  1.608 nits de 1.000
```

> ⚠️ **Vermelho não quer dizer que a conversão estraga.** Shield, Apple TV, Zidoo, Dune e as TVs **já descartam** a camada extra hoje — nesses aparelhos o Perfil 7 já toca do jeito que o convertido vai tocar. Quem perde alguma coisa é quem tem player com decodificador duplo (OPPO UDP-203/205, Panasonic UB820/UB9000, Sony X700/X800M2). O botão **Entenda**, dentro do programa, explica isso por extenso — em português e em inglês.

**Os limites, ditos sem rodeio:**
* A leitura é por **amostragem de trechos**, não pelo filme inteiro. Se é MEL ou FEL, a amostra basta (o campo não muda ao longo do filme). Os números de brilho são da amostra.
* O programa **não mede o brilho real da camada base**. A separação Simple/Complex é uma comparação com o pico do master: um bom indício, não uma prova.
* O `dovi_tool` no modo 2 (que é o que usamos) **remove do RPU o mapeamento de luma/croma do Perfil 7 FEL** — o que sai é um Perfil 8.1 legítimo, não um Perfil 7 remendado. O que **nenhum modo** do `dovi_tool` faz é **recalcular o L1**, e é daí que vem toda a ressalva.

### 💡 Perfil 5 → MP4

O Perfil 5 (nativo de Web-DL / streaming) usa o espaço de cores **IPTPQc2** e não possui camada de fallback HDR10. Remuxar para P8 gera cores roxas/esverdeadas, e fazer direito exigiria **recodificar o vídeo inteiro** — o que este programa se recusa a fazer.

Mas o P5 não fica parado. O que ele precisa não é de conversão de perfil: é de um **container** que os aparelhos leiam. O programa remuxa para **MP4 com a marca `dvh1`**, com o vídeo **copiado** quadro por quadro — é assim que um P5 toca no Apple TV, no Infuse e nos players que ignoram o `.mkv`.

Nesse caminho: o áudio é copiado quando cabe no MP4 (E-AC-3, AC-3, AAC) e vira E-AC-3 640k quando não cabe (TrueHD, DTS); a legenda de texto vira `mov_text`; a legenda PGS é **descartada com aviso**, porque legenda de imagem não existe em MP4 — e não há OCR nesse caminho.

### 💡 Outros Problemas que o programa resolve
* **Incompatibilidade de Áudio:** TrueHD (com ou sem Atmos) → **E-AC-3 Atmos** 1152 kbps via DeeZy, com os objetos de áudio preservados. DTS, DTS-HD MA e DTS:X → **E-AC-3 comum** 640 kbps via ffmpeg — **sem Atmos na saída**, porque DTS e Atmos são de empresas diferentes e os objetos do DTS:X não viram objetos Dolby.
* **Legendas PGS em PT-BR (TVs não leem):** OCR automático convertendo faixas PGS para `.SRT` em Português (PT-BR) com correção por dicionário, e uma **nota de qualidade conferida no arquivo gerado** — EXCELENTE, BOA, RAZOÁVEL ou RUIM. A faixa PGS original continua no arquivo final: o `.SRT` é uma faixa a mais, não uma troca.
* **Processamento em Lote e Espaço em Disco:** adicione uma temporada inteira e deixe o programa trabalhar. Antes de começar ele **simula a fila inteira na ordem** e diz quantos arquivos cabem, qual é o primeiro que fica de fora e quanto faltaria na vez dele. Quem não cabe **nem chega a começar**.
* **Modo Automático ou Manual:** ajuste faixa por faixa ou deixe o motor de decisão cuidar de tudo.
* **Interface em Português e Inglês**, com bandeira, sem reiniciar o programa.

### 🛠️ Instalação e Requisitos
* **Instalador:** instala o programa no sistema como qualquer aplicativo nativo e cria atalhos no Menu Iniciar e na Área de Trabalho.
* **Pré-requisito (opcional):** o programa traz suas próprias ferramentas portáteis. O **.NET Desktop Runtime 8.0** é utilizado apenas pelo motor de OCR reserva (`PgsToSrt`) e, se faltar, pode ser baixado automaticamente durante a instalação.
* **`dovi_tool` 2.3.3 ou mais novo.** Versões anteriores não têm o `export --levels`, e sem ele o programa não consegue medir MEL × FEL.
* **Observação sobre Legendas:** a precisão do OCR varia conforme a fonte usada no release, e o software emite um diagnóstico de qualidade ao final. Os processos de vídeo são **sem re-encode**, sempre.

---

## 🌐 English

**LaFirma Remux Forge** was designed to eliminate media playback incompatibility issues on Smart TVs (LG, Samsung), players (Shield, Apple TV, Zidoo) and media servers (**Plex**, **Jellyfin**, **Emby**).

Created to streamline the workflow for Blu-ray encodes and remuxes, the software serves as an orchestration bridge: we designed the smooth graphical user interface (GUI), decision logic, and PowerShell-driven engine that connects and automates established community utilities (`ffmpeg`, `mkvmerge`, `dovi_tool`, `DDVT`, `PgsToSrt`, `Tesseract`, `DeeZy`, `seconv`). Perfect for single files or batch processing entire TV show seasons.

### 💡 Dolby Vision: the program MEASURES before converting

This is the difference that defines the project. Converting a Profile 7 is **not always the same thing**, and the program stopped pretending otherwise.

Before touching the file, it reads the `el_type` field inside the RPU (with `dovi_tool`) and separates **three** cases:

| | Colour on screen | What it means |
|---|---|---|
| **MEL** — Minimal Enhancement Layer | 🟢 green | The extra layer **carries no picture**. Discarding it changes no pixel. |
| **Simple FEL** | 🟠 orange | The layer carries picture, but it is **refinement** — residual, grain, gradients. You lose fine detail, visible only on a paused frame. |
| **Complex FEL** | 🔴 red | The layer **raises brightness**. Without it the RPU asks the TV for a peak the video no longer delivers. This is the only case that matters. |

**What separates Simple from Complex is one number:** the RPU's L1 (the peak the file asks for) against the mastering display peak (the monitor the film was graded on, declared inside the file itself). If the file does not declare that peak, **the program says it does not know** rather than picking a side.

Measured on a real machine, with no list consulted:

```
Troy (2004) Director's Cut  ->  MEL              303 nits of 1,000
Game of Thrones S08E01      ->  SIMPLE FEL       153 nits of 1,000
Saving Private Ryan (1998)  ->  COMPLEX FEL    1,608 nits of 1,000
```

> ⚠️ **Red does not mean the conversion ruins the file.** Shield, Apple TV, Zidoo, Dune and TVs **already discard** the extra layer today — on those devices Profile 7 already plays the way the converted file will. Who actually loses something is whoever owns a dual-layer decoder (OPPO UDP-203/205, Panasonic UB820/UB9000, Sony X700/X800M2). The **Learn** button inside the program explains this at length, in English and Portuguese.

**The limits, said plainly:**
* The reading is **sampled from short pieces**, not the whole film. Whether it is MEL or FEL, the sample settles it (the field does not change through the film). The brightness numbers are the sample's.
* The program **does not measure the base layer's real brightness**. The Simple/Complex split is a comparison against the declared master peak: a good indication, not a proof.
* `dovi_tool` in mode 2 (what we use) **removes the Profile 7 FEL luma/chroma mapping from the RPU** — what comes out is a legitimate Profile 8.1, not a patched Profile 7. What **no dovi_tool mode** does is **recompute L1**, and that is where the whole caveat comes from.

### 💡 Profile 5 → MP4

Profile 5 (native to Web-DL / streaming) uses the **IPTPQc2** colour space without a standard HDR10 fallback layer. Forcing a remux-only conversion to P8 causes severe colour distortion (purple/green tint) or requires **full video re-encoding** — which this program refuses to do.

But P5 does not just sit there. What it needs is not a profile conversion: it is a **container** devices will read. The program remuxes it to **MP4 with the `dvh1` tag**, with the video **copied** frame by frame — that is how a P5 plays on Apple TV, on Infuse and on the players that ignore `.mkv`.

On that path: audio is copied when it fits in MP4 (E-AC-3, AC-3, AAC) and converted to E-AC-3 640k when it does not (TrueHD, DTS); text subtitles become `mov_text`; PGS subtitles are **discarded with a warning**, because image subtitles have no representation in MP4 — and there is no OCR on this path.

### 💡 Other Problems Solved
* **Audio Codec Issues:** TrueHD (with or without Atmos) → **E-AC-3 Atmos** 1152 kbps via DeeZy, audio objects preserved. DTS, DTS-HD MA and DTS:X → **plain E-AC-3** 640 kbps via ffmpeg — **no Atmos in the output**, because DTS and Atmos come from different companies and DTS:X objects do not become Dolby objects.
* **PGS Subtitles to SRT (PT-BR Focused):** automated OCR conversion of image-based PGS subtitles to clean `.SRT` with dictionary spellchecking, plus a **quality grade checked on the generated file** — EXCELLENT, GOOD, FAIR or POOR. The original PGS track stays in the final file: the `.SRT` is one extra track, not a replacement.
* **Batch Processing & Disk Management:** queue multiple files or full seasons. Before starting, the app **simulates the whole queue in order** and says how many files fit, which is the first one left out, and how much would be missing on its turn. A file that does not fit **never even starts**.
* **Auto or Manual Control:** smart auto-detection rules, or manually select/exclude specific audio tracks and subtitle streams.
* **Portuguese and English interface**, with a flag toggle, no restart needed.

### 🛠️ Installation & Requirements
* **Installer:** installs natively with standard Windows integration and Start Menu / Desktop shortcuts.
* **Dependencies (optional):** self-contained toolset. **.NET Desktop Runtime 8.0** is only required for the secondary fallback OCR engine (`PgsToSrt`) and can be downloaded automatically during installation if missing.
* **`dovi_tool` 2.3.3 or newer.** Earlier versions lack `export --levels`, and without it the program cannot measure MEL vs FEL.
* **Subtitle OCR Note:** accuracy depends on font styling and source release quality; an automated evaluation report is displayed upon completion. Video processing avoids re-encoding entirely, always.

---

## 🖼️ Interface & Demonstração / Screenshots

### 1. Análise Inicial / Initial Analysis
Análise da fila, cálculo automático de espaço em disco e diagnóstico automático do arquivo.

[![Análise Inicial](https://i.ibb.co/NdBdGZ42/image.png)](https://ibb.co/NdBdGZ42)

---

### 2. Confirmação do Processo Automático / Auto Mode
Visualização detalhada do mapeamento de faixas no Modo Automático.

[![Confirmação do Processo Automático](https://i.ibb.co/h1V3dKRK/image.png)](https://ibb.co/h1V3dKRK)

---

### 3. Confirmação do Processo Manual / Manual Mode
Modo Manual: controle total para manter, converter ou excluir cada áudio e legenda.

[![Confirmação do Processo Manual](https://i.ibb.co/G3r5TRrc/image.png)](https://ibb.co/G3r5TRrc)

---

### 4. Processo sendo Realizado / Conversion Progress
Acompanhamento em tempo real da conversão por etapas com métricas de desempenho.

[![Processo sendo Realizado](https://i.ibb.co/G4crhCS1/image.png)](https://ibb.co/G4crhCS1)

---

### 5. Finalização e Log Final / Summary & Quality Evaluation
Relatório final detalhado com verificação de integridade e qualidade da legenda.

[![Finalização e Log Final](https://i.ibb.co/LhHmtqWZ/image.png)](https://ibb.co/LhHmtqWZ)

---

## 🙏 Agradecimentos & Créditos / Credits & Acknowledgments

### 🇵🇹 Português
Este programa é uma casca em volta do trabalho de outras pessoas. Cada uma delas resolveu um problema difícil e deixou o resultado disponível para quem quisesse usar. Sem isso, nada aqui existiria.

* **FFmpeg / ffprobe**: processamento, extração e análise de mídia. É ele que corta os trechos da amostra sem recodificar, lê a duração e o FPS, e converte o áudio da família DTS.
* **MKVToolNix (`mkvmerge`)**: o padrão para arquivos Matroska. Monta o arquivo final faixa por faixa, preservando capítulos, marcas e nomes.
* **dovi_tool (por `quietvoid`)**: leitura e conversão dos metadados Dolby Vision. É ele que identifica o perfil, diz se a camada é MEL ou FEL, exporta o L1 e o L5, e faz a conversão de Perfil 7 para 8.1. **Nada disso é reimplementado aqui** — o LaFirma organiza o trabalho em volta e mostra o resultado de um jeito que dê para decidir.
* **DDVT (por `DonaldFaQ`)**: trabalho com RPU e correção de corte. **Foi a ferramenta que ensinou este projeto a existir:** antes do LaFirma, era com ela que se convertia, e foi usando ela que se entendeu o que é RPU, o que é camada de melhoria, o que muda entre um perfil e outro e por que Perfil 7 dá trabalho. A ideia de automatizar essa conversão nasceu dali.
* **DeeZy**: codificação para E-AC-3 com o Dolby Atmos preservado. É o que permite sair de um TrueHD Atmos e continuar com Atmos do outro lado.
* **PgsToSrt, Tesseract OCR & seconv**: o ecossistema técnico responsável pela extração, renderização e conversão OCR de legendas PGS em texto `.SRT`.

E dois agradecimentos que não são de código:

* **`cryptochrome`, autor do `dovi_convert`** — pela pergunta pública sobre como tratávamos a camada de melhoria: se apenas descartávamos, ou se checávamos antes se havia expansão de brilho acima da camada base. A pergunta estava certa e a resposta, na época, era desconfortável — o programa descartava sem checar. **Foi essa cobrança que fez o LaFirma passar a medir antes de converter**, e é dela que vem o vocabulário MEL / Simple FEL / Complex FEL que usamos.
* **`Reset9999` e a comunidade** — pela planilha de MEL × FEL por título. Trabalho manual e paciente, que serve de segunda opinião para todo mundo.

---

### 🌐 English
This program is a shell around other people's work. Each of them solved a hard problem and left the result available to anyone who wanted it. Without that, nothing here would exist.

* **FFmpeg / ffprobe**: media processing, extraction and analysis. It is what cuts the sample pieces without re-encoding, reads duration and FPS, and converts DTS-family audio.
* **MKVToolNix (`mkvmerge`)**: the industry standard for Matroska files. It assembles the final file track by track, preserving chapters, flags and names.
* **dovi_tool (by `quietvoid`)**: reading and converting Dolby Vision metadata. It identifies the profile, says whether the layer is MEL or FEL, exports L1 and L5, and performs the Profile 7-to-8.1 conversion. **None of it is reimplemented here** — LaFirma organises the work around it and shows the result in a way you can decide from.
* **DDVT (by `DonaldFaQ`)**: RPU work and crop correction. **It is the tool that taught this project how to exist:** before LaFirma, it was what we converted with, and it was by using it that we came to understand what an RPU is, what an enhancement layer is, what changes between profiles, and why Profile 7 is troublesome. The idea of automating this conversion was born there.
* **DeeZy**: Dolby Digital Plus encoding with native spatial Dolby Atmos metadata preservation. It is what lets a TrueHD Atmos track come out the other side still carrying Atmos.
* **PgsToSrt, Tesseract OCR & seconv**: the dedicated OCR ecosystem enabling image rendering, character recognition, and PGS-to-SRT text subtitle conversion.

And two acknowledgements that are not code:

* **`cryptochrome`, author of `dovi_convert`** — for the public question about how we handled the enhancement layer: whether we simply stripped it, or checked first whether it carried brightness expansion beyond the base layer. The question was right and the answer, at the time, was uncomfortable — the program stripped it without checking. **That challenge is why LaFirma measures before converting**, and where the MEL / Simple FEL / Complex FEL vocabulary comes from.
* **`Reset9999` and the community** — for the MEL × FEL spreadsheet by title. Manual, patient work that serves as a second opinion for everybody.
