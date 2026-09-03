# LaFirma Remux Forge (Black Edition)

O **LaFirma Remux Forge** foi desenvolvido para resolver de forma definitiva os problemas de incompatibilidade de mídia em Smart TVs (como LG e Samsung) e servidores de mídia (**Plex**, **Jellyfin**, **Emby**). 

Ele une ferramentas consagradas da comunidade (`ffmpeg`, `mkvmerge`, `dovi_tool`, `DDVT`, `PgsToSrt`, `Tesseract`, `DeeZy`, `seconv`) em uma interface moderna, intuitiva e automatizada, ideal tanto para arquivos individuais quanto para processamento em lote (séries completas).

---

## 📸 Screenshots / Galeria

<p align="center">
  <img src="SELECIONANDO%20O%20ARQUIVO.png" alt="Fila de Processamento e Seleção" width="800"/><br/>
  <i>Análise da fila, cálculo automático de espaço em disco e diagnóstico automático do arquivo.</i>
</p>

<p align="center">
  <img src="PROCESSO%20SENDO%20REALIZADO.png" alt="Processo em Andamento" width="800"/><br/>
  <i>Acompanhamento em tempo real da conversão por etapas com métricas de desempenho.</i>
</p>

<p align="center">
  <img src="CONVERSAO%20CONCLUIDA.png" alt="Resumo da Conversão" width="800"/><br/>
  <i>Relatório final detalhado com verificação de integridade e qualidade da legenda.</i>
</p>

<p align="center">
  <img src="SELECAO%20AUTOMATICO.png" alt="Modo Automático de Faixas" width="800"/><br/>
  <i>Visualização detalhada do mapeamento de faixas no Modo Automático.</i>
</p>

<p align="center">
  <img src="SELECAO%20MANUAL.png" alt="Modo Manual de Faixas" width="800"/><br/>
  <i>Modo Manual: controle total para manter, converter ou excluir cada áudio e legenda.</i>
</p>

---

## 🇵🇹 Português

### 💡 Problemas que o programa resolve
* **Dolby Vision Incompatível:** Converte automaticamente perfis incompatíveis (Perfil 5 / 7) para **Perfil 8.1**, garantindo reprodução sem tela preta ou cores alteradas, mantendo a qualidade de imagem 100% intacta.
* **Incompatibilidade de Áudio:** Transcodifica faixas pesadas ou incompatíveis (TrueHD, DTS, DTS-HD, DTS:X) para **E-AC-3 (Dolby Digital Plus)** preservando os canais Atmos via DeeZy, mantendo a compatibilidade sem perda perceptível.
* **Legendas PGS (TVs não leem):** Realiza OCR automático convertendo faixas PGS para `.SRT` em PT-BR (com verificação de qualidade final), além de manter a faixa de áudio e legenda principal em inglês.
* **Processamento em Lote e Espaço em Disco:** Adicione uma temporada inteira e deixe o programa trabalhar. Ele calcula o espaço necessário antes de iniciar para evitar falhas por falta de armazenamento.
* **Modo Automático ou Manual:** Permite ajustar faixa por faixa ou deixar o motor de decisão inteligente cuidar de tudo.

### 🛠️ Instalação e Requisitos
* **Instalador (`LaFirma_Setup`):** Instala o programa no sistema como qualquer aplicativo nativo e cria atalhos no Menu Iniciar e Área de Trabalho.
* **Pré-requisito único:** O programa gerencia suas dependências, exigindo apenas o **.NET Runtime 8.0** para o módulo de OCR de legendas (caso o sistema não possua, o instalador fará o download/instalação automaticamente).
* **Observação sobre Legendas:** O motor de OCR (PGS para SRT) utiliza uma cadeia de ferramentas automatizadas. A precisão pode variar dependendo do release do Blu-ray, e o software emite um diagnóstico de qualidade ao final do processo. Os processos de vídeo e áudio são 100% precisos e sem perda de qualidade.

---

## 🇬🇧 English

### 💡 Problems Solved
* **Incompatible Dolby Vision:** Automatically converts Dolby Vision profiles (Profile 5 / 7) to **Profile 8.1**, ensuring flawless playback on Smart TVs and media servers (Plex/Jellyfin) with zero image or color degradation.
* **Audio Codec Issues:** Transcodes unsupported high-bitrate audio formats (TrueHD, DTS, DTS-HD, DTS:X) into **E-AC-3 (Dolby Digital Plus)** with spatial Atmos support via DeeZy, preserving high compatibility across all player devices.
* **PGS Subtitles to SRT:** Performs automated OCR conversion of image-based PGS subtitles to clean `.SRT` format (optimized for PT-BR subtitles while retaining primary English tracks).
* **Batch Processing & Disk Management:** Queues multiple files or full series seasons. The app calculates required temp/output disk space prior to processing to prevent storage overhead failures.
* **Auto or Manual Control:** Use smart auto-detection rules or manually select/exclude specific audio tracks and subtitle streams.

### 🛠️ Installation & Requirements
* **Installer (`LaFirma_Setup`):** Installs natively with standard Windows integration and Start Menu / Desktop shortcuts.
* **Dependencies:** Self-contained toolset requiring only the **.NET Runtime 8.0** (used for OCR subtitle operations).
* **Subtitle OCR Note:** PGS-to-SRT conversion relies on automated OCR engines (`seconv`/`PgsToSrt`/`Tesseract`). Accuracy depends on font styling and source release quality; an automated evaluation report is displayed upon completion. Video and audio processing pipelines remain 100% lossy-free and intact.
