# LaFirma Remux Forge

Automatize o remux de vídeos MKV com o LaFirma. Converte perfis Dolby Vision (7/5 para 8.1), realiza transcodificação inteligente de áudio para E-AC-3/Atmos e processa legendas PGS com OCR automático e correção de erros. Interface gráfica fluida e motor em PowerShell, sem necessidade de instalar dependências externas para o processamento.

---

## 🇵🇹 Português

### Como Abrir
Se você instalou pelo instalador (`LaFirma_Setup`): clique no atalho **LaFirma Remux Forge** na Área de Trabalho ou no Menu Iniciar.
Se está usando a versão portátil: dê dois cliques em `Abrir_LaFirma_JANELA.vbs`.

Planos B (caso o atalho não abra):
* `Abrir_LaFirma_JANELA.bat` - Abre a mesma janela com o console visível para identificar erros.
* `Converter_AUTO_DIRETO.bat` - Pula a interface gráfica e roda o motor diretamente pelo console.

### O que o programa faz
Para cada arquivo `.mkv` na pasta `00_Arquivos_Base`, o programa realiza o diagnóstico e segue 5 etapas:
1. **Extração:** Extrai o vídeo puro sem recodificar (zero perda de qualidade).
2. **Dolby Vision:** Converte para Profile 8.1 (vídeos que já estão em Profile 8.x são pulados automaticamente).
3. **Áudio:** Converte a faixa principal para E-AC-3 (TrueHD/Atmos via DeeZy, DTS/DTS-HD via ffmpeg). Faixas compatíveis são mantidas.
4. **Legenda PT-BR:** Processa legendas com OCR automático (seconv/BinaryOCR como preferencial; PgsToSrt/Tesseract como contingência).
5. **Remux Final:** Remonta o arquivo MKV preservando apenas as faixas essenciais.

---

## 🇬🇧 English

### How to Open
If installed via the installer (`LaFirma_Setup`): click the **LaFirma Remux Forge** shortcut on the Desktop or Start Menu.
If using the portable version: double-click `Abrir_LaFirma_JANELA.vbs`.

Fallback options:
* `Abrir_LaFirma_JANELA.bat` - Opens the same window with a visible console to display errors.
* `Converter_AUTO_DIRETO.bat` - Bypasses the GUI and runs the engine directly in the console.

### What it does
For every `.mkv` file in the `00_Arquivos_Base` folder, the tool diagnoses the media and processes 5 steps:
1. **Extraction:** Extracts raw video without re-encoding (zero quality loss).
2. **Dolby Vision:** Converts to Profile 8.1 (Profile 8.x files are skipped automatically).
3. **Audio:** Converts the main audio track to E-AC-3 (TrueHD/Atmos via DeeZy, DTS/DTS-HD via ffmpeg). Compatible tracks are preserved.
4. **PT-BR Subtitles:** Processes subtitles via automatic OCR (seconv/BinaryOCR primary; PgsToSrt/Tesseract fallback).
5. **Final Remux:** Rebuilds the MKV file keeping only essential tracks.
