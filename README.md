# LaFirma Remux Forge (Black Edition)

---

## 📥 Downloads & Links Oficiais

### 📦 Programa Pronto para Usar (Executável / Instalador)
> Baixe a versão compilada, instale e comece a converter seus arquivos imediatamente:
* **MEGA:** [Baixar LaFirma Remux Forge](https://mega.nz/file/abxFWYpR#3DjvTORJqK-XMqp7uvR8l30qJT67wAS6OVpxLnlTI-I)
* **GOFILE:** [Baixar LaFirma Remux Forge](https://gofile.io/d/YE2isutz)

---

### 💻 Código-Fonte Completo & Pasta do Projeto (Para Compilar)
> Para desenvolvedores ou usuários que desejam acessar a estrutura inteira de arquivos:
* **MEGA (Pasta Completa):** [Acessar Pasta do Projeto](https://mega.nz/folder/XL5ExRaC#rUepdnN0domt5MUaaugQhQ)

---

## 🇵🇹 Português

O **LaFirma Remux Forge** foi criado para resolver de forma definitiva os problemas de incompatibilidade de mídia em Smart TVs (LG, Samsung) e servidores de mídia (**Plex**, **Jellyfin**, **Emby**).

Desenvolvido para automatizar o processamento de encodes de Blu-ray e arquivos remux, ele reúne e orquestra ferramentas consagradas da comunidade (`ffmpeg`, `mkvmerge`, `dovi_tool`, `DDVT`, `PgsToSrt`, `Tesseract`, `DeeZy`, `seconv`) em uma interface gráfica moderna e intuitiva. É ideal para arquivos individuais ou processamento em lote de temporadas completas de séries.

### 💡 Problemas que o programa resolve
* **Dolby Vision Incompatível:** Converte automaticamente perfis incompatíveis (Perfil 5 / 7) para **Perfil 8.1**, garantindo reprodução sem tela preta ou cores alteradas, mantendo a qualidade de imagem 100% intacta.
* **Incompatibilidade de Áudio:** Transcodifica faixas pesadas (TrueHD, DTS, DTS-HD, DTS:X) para **E-AC-3 (Dolby Digital Plus)** preservando os canais Atmos via DeeZy, mantendo a compatibilidade sem perda perceptível.
* **Legendas PGS (TVs não leem):** Realiza OCR automático convertendo faixas PGS para `.SRT` em PT-BR (com verificação de qualidade final), além de manter a faixa de áudio e legenda principal em inglês.
* **Processamento em Lote e Espaço em Disco:** Adicione uma temporada inteira e deixe o programa trabalhar. Ele calcula o espaço necessário antes de iniciar para evitar falhas por falta de armazenamento.
* **Modo Automático ou Manual:** Permite ajustar faixa por faixa ou deixar o motor de decisão inteligente cuidar de tudo.

### 🛠️ Instalação e Requisitos
* **Instalador (`LaFirma_Setup`):** Instala o programa no sistema como qualquer aplicativo nativo e cria atalhos no Menu Iniciar e Área de Trabalho.
* **Pré-requisito único:** O programa gerencia suas dependências, exigindo apenas o **.NET Runtime 8.0** para o módulo de OCR de legendas (caso o sistema não possua, o instalador fará o download/instalação automaticamente).
* **Observação sobre Legendas:** O motor de OCR (PGS para SRT) utiliza uma cadeia de ferramentas automatizadas. A precisão pode variar dependendo do release do Blu-ray, e o software emite um diagnóstico de qualidade ao final do processo. Os processos de vídeo e áudio são 100% precisos e sem perda de qualidade.

---

## 🇬🇧 English

**LaFirma Remux Forge** was designed to eliminate media playback incompatibility issues on Smart TVs (LG, Samsung, etc.) and media servers (**Plex**, **Jellyfin**, **Emby**).

Created to streamline the workflow for Blu-ray encodes and remuxes, it integrates and orchestrates established open-source utilities (`ffmpeg`, `mkvmerge`, `dovi_tool`, `DDVT`, `PgsToSrt`, `Tesseract`, `DeeZy`, `seconv`) into a modern, easy-to-use graphical interface. Perfect for single files or batch processing entire TV show seasons.

### 💡 Problems Solved
* **Incompatible Dolby Vision:** Automatically converts Dolby Vision profiles (Profile 5 / 7) to **Profile 8.1**, ensuring flawless playback on Smart TVs and media servers with zero image or color degradation.
* **Audio Codec Issues:** Transcodes unsupported high-bitrate audio formats (TrueHD, DTS, DTS-HD, DTS:X) into **E-AC-3 (Dolby Digital Plus)** with spatial Atmos support via DeeZy, preserving high compatibility across all player devices.
* **PGS Subtitles to SRT:** Performs automated OCR conversion of image-based PGS subtitles to clean `.SRT` format (optimized for PT-BR subtitles while retaining primary English tracks).
* **Batch Processing & Disk Management:** Queues multiple files or full series seasons. The app calculates required temp/output disk space prior to processing to prevent storage overhead failures.
* **Auto or Manual Control:** Use smart auto-detection rules or manually select/exclude specific audio tracks and subtitle streams.

### 🛠️ Installation & Requirements
* **Installer (`LaFirma_Setup`):** Installs natively with standard Windows integration and Start Menu / Desktop shortcuts.
* **Dependencies:** Self-contained toolset requiring only the **.NET Runtime 8.0** (used for OCR subtitle operations).
* **Subtitle OCR Note:** PGS-to-SRT conversion relies on automated OCR engines (`seconv`/`PgsToSrt`/`Tesseract`). Accuracy depends on font styling and source release quality; an automated evaluation report is displayed upon completion. Video and audio processing pipelines remain 100% lossy-free and intact.

---

## 🖼️ Interface & Demonstração (Clique nos botões abaixo para baixar)

<div align="center">

### 1. Seleção de Arquivo e Fila
Análise da fila, cálculo automático de espaço em disco e diagnóstico automático do arquivo.

[![Análise Inicial](https://i.ibb.co/NdBdGZ42/image.png)](https://ibb.co/NdBdGZ42)


---

### 2. Processo em Andamento
Acompanhamento em tempo real da conversão por etapas com métricas de desempenho.

[![Processo sendo Realizado](https://i.ibb.co/G4crhCS1/image.png)](https://ibb.co/G4crhCS1)
---

### 3. Resumo da Conversão
Relatório final detalhado com verificação de integridade e qualidade da legenda.


[![Finalização / Log Final](https://i.ibb.co/LhHmtqWZ/image.png)](https://ibb.co/LhHmtqWZ)

---

### 4. Modo Automático de Mapeamento
Visualização detalhada do mapeamento de faixas no Modo Automático.



[![Confirmação do Processo Manual](https://i.ibb.co/G3r5TRrc/image.png)](https://ibb.co/G3r5TRrc)

![Finalização / Log Final](https://i.ibb.co/LhHmtqWZ/image.png)


---

### 5. Modo Manual de Mapeamento
Modo Manual: controle total para manter, converter ou excluir cada áudio e legenda.


![Confirmação do Processo Automático](https://i.ibb.co/h1V3dKRK/image.png)

</div>
