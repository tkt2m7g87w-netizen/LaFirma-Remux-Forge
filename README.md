# LaFirma Remux Forge (Black Edition)

> **Automated MKV Remuxing & Transcoding Engine**  
> *Convert Dolby Vision Profile 7 (MEL/FEL) to 8.1, transcode Atmos audio to E-AC-3, and process PT-BR PGS OCR subtitles with a smooth PowerShell GUI.*

[![Language: PT-BR](https://img.shields.io/badge/Language-Portuguese-green.svg)](#-português)
[![Language: EN](https://img.shields.io/badge/Language-English-blue.svg)](#-english)

---

## 📥 Downloads & Official Links / Links Oficiais

### 📦 Standalone Installer / Programa Pronto para Usar
> Download the compiled setup to install and use immediately / Baixe a versão compilada para instalar e usar imediatamente:
* **PROTON DRIVE:** [Download / Baixar LaFirma Remux Forge](https://drive.proton.me/urls/ZATVE13HWM#em0BACyqRM5J)
* **MEGA:** [Download / Baixar LaFirma Remux Forge](https://mega.nz/file/abxFWYpR#3DjvTORJqK-XMqp7uvR8l30qJT67wAS6OVpxLnlTI-I)
* **GOFILE:** [Download / Baixar LaFirma Remux Forge](https://gofile.io/d/YE2isutz)

---

### 💻 Full Source Code & Dev Guides / Código-Fonte & Guias
> Access the complete project directory or installer compilation guides / Para desenvolvedores e compilação do .iss:
* **PROTON DRIVE (Full Folder / Pasta Completa):** [Access / Acessar](https://drive.proton.me/urls/FQWT6PB5W4#VgsXd07uV4OK)
* **MEGA (Full Folder / Pasta Completa):** [Access / Acessar](https://mega.nz/folder/aSpxxJII#v5CzveN0-Um9LryBnjfMMQ)
* **Installer Compilation Guide (PT-BR):** [Consulte LEIA-ME_INSTALADOR[PT-BR].txt](./LEIA-ME_INSTALADOR[PT-BR].txt)
* **Installer Compilation Guide (EN):** [Check README_INSTALLER[ENGLISH].txt](./README_INSTALLER[ENGLISH].txt)

---

## 🇵🇹 Português

O **LaFirma Remux Forge** foi criado para resolver de forma definitiva os problemas de incompatibilidade de mídia em Smart TVs (LG, Samsung) e servidores de mídia (**Plex**, **Jellyfin**, **Emby**).

Desenvolvido para automatizar o processamento de encodes de Blu-ray e arquivos remux, o software atua como uma ponte de orquestração: desenvolvemos toda a interface gráfica (GUI) fluida, as regras de decisão automatizadas e o motor em PowerShell que integra e automatiza ferramentas consagradas da comunidade (`ffmpeg`, `mkvmerge`, `dovi_tool`, `DDVT`, `PgsToSrt`, `Tesseract`, `DeeZy`, `seconv`). É a solução ideal tanto para arquivos individuais quanto para o processamento em lote de temporadas completas de séries.

### 💡 Tratamento Transparente de Perfis Dolby Vision (P7 e P5)
* **Dolby Vision Perfil 7 para 8.1 (Remux Lossless):** O programa injeta e converte RPU de arquivos P7 oriundos de Blu-ray UHD para o Perfil 8.1 de forma 100% *lossless* no vídeo.
  * **Perfil 7 MEL (Minimum Enhancement Layer):** Contém apenas metadados. A conversão para P8.1 é perfeita e idêntica ao original.
  * **Perfil 7 FEL (Full Enhancement Layer):** Na vasta maioria dos casos (onde a EL não expande o brilho de forma crítica), o descarte da EL mantém a imagem intacta. O programa processa a conversão de metadados mantendo o arquivo compatível com players nativos sem recodificação.
* **Por que NÃO convertemos Perfil 5 diretamente via Remux?** O Perfil 5 (nativo do Web-DL / serviços de streaming) utiliza o espaço de cores patenteado **IPTPQc2** e não possui camada de fallback HDR10 padrão. Tentar convertê-lo via simples remux para P8 ou HDR10 gera cores roxas/esverdeadas ou exige re-encode total do vídeo. Para preservar a filosofia *lossless* e a velocidade do projeto, o programa preserva e identifica a estrutura do P5 sem mentir sobre capacidades de conversão sem re-encode.

### 💡 Outros Problemas que o programa resolve
* **Incompatibilidade de Áudio:** Transcodifica faixas pesadas (TrueHD, DTS, DTS-HD, DTS:X) para **E-AC-3 (Dolby Digital Plus)** preservando os canais Atmos via DeeZy, mantendo a compatibilidade sem perda perceptível.
* **Legendas PGS em PT-BR (TVs não leem):** Realiza OCR automático convertendo faixas PGS para `.SRT` exclusivamente em Português (PT-BR) com correção ortográfica baseada em dicionário, além de preservar a faixa de legenda original em inglês.
* **Processamento em Lote e Espaço em Disco:** Adicione uma temporada inteira e deixe o programa trabalhar. Ele calcula o espaço necessário antes de iniciar para evitar falhas por falta de armazenamento.
* **Modo Automático ou Manual:** Permite ajustar faixa por faixa ou deixar o motor de decisão inteligente cuidar de tudo.

### 🛠️ Instalação e Requisitos
* **Instalador (`LaFirma_Setup_1.0.exe`):** Instala o programa no sistema como qualquer aplicativo nativo e cria atalhos no Menu Iniciar e Área de Trabalho.
* **Pré-requisito (Opcional):** O programa traz suas próprias ferramentas portáteis. O **.NET Desktop Runtime 8.0** é utilizado apenas pelo motor de OCR reserva (`PgsToSrt`). Caso o sistema não o possua e o instalador seja gerado sem o runtime embutido, o download poderá ser feito automaticamente durante a instalação.
* **Observação sobre Legendas:** O motor de OCR (PGS para SRT) utiliza uma cadeia de ferramentas automatizadas focadas em PT-BR. A precisão pode variar dependendo do release do Blu-ray, e o software emite um diagnóstico de qualidade ao final do processo. Os processos de vídeo e áudio são 100% precisos e sem perda de qualidade.

---

## 🇬🇧 English

**LaFirma Remux Forge** was designed to eliminate media playback incompatibility issues on Smart TVs (LG, Samsung, etc.) and media servers (**Plex**, **Jellyfin**, **Emby**).

Created to streamline the workflow for Blu-ray encodes and remuxes, the software serves as an orchestration bridge: we designed the smooth graphical user interface (GUI), decision logic, and PowerShell-driven engine that connects and automates established community utilities (`ffmpeg`, `mkvmerge`, `dovi_tool`, `DDVT`, `PgsToSrt`, `Tesseract`, `DeeZy`, `seconv`). Perfect for single files or batch processing entire TV show seasons.

### 💡 Transparent Dolby Vision Profile Handling (P7 & P5)
* **Dolby Vision Profile 7 to 8.1 (Lossless Remux):** Extracts and converts RPU metadata from UHD Blu-ray P7 releases into Profile 8.1 with 100% video bit-exact preservation.
  * **Profile 7 MEL (Minimum Enhancement Layer):** Contains metadata only. Conversion to P8.1 is 100% identical and loss-free.
  * **Profile 7 FEL (Full Enhancement Layer):** In the vast majority of releases (where EL does not carry critical brightness expansion), stripping the EL leaves the underlying video stream untouched while preserving dynamic metadata for TV compatibility.
* **Why we do NOT convert Profile 5 via simple Remux:** Profile 5 (native to Web-DL / streaming) uses **IPTPQc2** color space without a standard HDR10 fallback layer. Forcing a remux-only conversion to P8 or HDR10 causes severe color distortion (purple/green tint) or requires full video re-encoding. To maintain our "zero video re-encode" speed and fidelity commitment, P5 is handled appropriately without false conversion claims.

### 💡 Other Problems Solved
* **Audio Codec Issues:** Transcodes unsupported high-bitrate audio formats (TrueHD, DTS, DTS-HD, DTS:X) into **E-AC-3 (Dolby Digital Plus)** with spatial Atmos support via DeeZy, preserving high compatibility across all player devices.
* **PGS Subtitles to SRT (PT-BR Focused):** Performs automated OCR conversion of image-based PGS subtitles to clean `.SRT` format specifically for Portuguese (PT-BR) with dictionary spellchecking, while retaining primary English subtitle tracks.
* **Batch Processing & Disk Management:** Queues multiple files or full series seasons. The app calculates required temp/output disk space prior to processing to prevent storage overhead failures.
* **Auto or Manual Control:** Use smart auto-detection rules or manually select/exclude specific audio tracks and subtitle streams.

### 🛠️ Installation & Requirements
* **Installer (`LaFirma_Setup_1.0.exe`):** Installs natively with standard Windows integration and Start Menu / Desktop shortcuts.
* **Dependencies (Optional):** Self-contained toolset. **.NET Desktop Runtime 8.0** is only required for the secondary fallback OCR engine (`PgsToSrt`). If missing and not bundled into the installer, it will offer to download it automatically.
* **Subtitle OCR Note:** PGS-to-SRT conversion relies on automated OCR engines (`seconv`/`PgsToSrt`/`Tesseract`) configured for PT-BR text processing. Accuracy depends on font styling and source release quality; an automated evaluation report is displayed upon completion. Video and audio processing pipelines remain 100% lossy-free and intact.

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

Este projeto não existiria sem o trabalho incrível dos desenvolvedores e da comunidade open-source por trás das ferramentas que integramos em nosso motor de automação:

* **FFmpeg**: O motor fundamental para processamento e manipulação de mídia.
* **MKVToolNix (`mkvmerge`)**: A referência definitiva para multiplexação de arquivos Matroska (MKV).
* **dovi_tool & DDVT**: Ferramentas essenciais criadas pela comunidade para manipulação e conversão de metadados Dolby Vision.
* **DeeZy**: Utilitário para codificação e preservação de áudio espacial Dolby Digital Plus / Atmos.
* **PgsToSrt, Tesseract & seconv**: O ecossistema responsável por extração, renderização e conversão OCR de alta precisão para legendas PGS.

*This project would not be possible without the incredible work of the open-source community and developers behind the core binaries integrated into our automation engine.*
