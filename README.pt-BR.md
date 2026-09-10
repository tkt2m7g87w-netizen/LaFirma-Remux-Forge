# LaFirma Remux Forge (Black Edition)

**Leia em outros idiomas:** [🌐 English](./README.md)

> **Remux e conversão automatizados de MKV**
> *Converte Dolby Vision Perfil 7 (MEL/FEL) para 8.1 sem recodificar o vídeo, transforma o áudio em E-AC-3 com Atmos e converte legendas PGS em PT-BR por OCR, com uma interface fluida em PowerShell.*

---

## 📥 Downloads

> **⚠️ O GitHub é a fonte mais atual.** Os espelhos abaixo continuam no ar e funcionam, mas trazem uma versão anterior do programa.

| | Onde | Estado |
|---|---|---|
| **Código-fonte, guias, changelog** | Aqui neste repositório | ✅ sempre o mais novo |
| **Instalador pronto** | [Releases](../../releases) | ✅ atual |
| Instalador — espelho | [Proton Drive](https://drive.proton.me/urls/ZATVE13HWM#em0BACyqRM5J) · [MEGA](https://mega.nz/file/abxFWYpR#3DjvTORJqK-XMqp7uvR8l30qJT67wAS6OVpxLnlTI-I) · [GoFile](https://gofile.io/d/YE2isutz) | ⚠️ desatualizado |
| Pasta completa — espelho | [Proton Drive](https://drive.proton.me/urls/FQWT6PB5W4#VgsXd07uV4OK) · [MEGA](https://mega.nz/folder/aSpxxJII#v5CzveN0-Um9LryBnjfMMQ) | ⚠️ desatualizado |

**Guia de compilação do instalador:** [LEIA-ME_INSTALADOR[PT-BR].txt](./LEIA-ME_INSTALADOR%5BPT-BR%5D.txt)

<details>
<summary><b>Por que os binários não estão neste repositório</b></summary>

A pasta `tools\` tem centenas de MB de programas de **outras pessoas**, cada um com a sua licença. Não republicamos o trabalho dos outros como se fosse nosso — este repositório diz de onde cada um vem, e o pacote pronto existe para quem só quer usar.

</details>

---

## O que é

O **LaFirma Remux Forge** foi criado para resolver de forma definitiva os problemas de incompatibilidade de mídia em Smart TVs (LG, Samsung), players (Shield, Apple TV, Zidoo) e servidores de mídia (**Plex**, **Jellyfin**, **Emby**).

Ele é uma ponte de automação: nós fizemos a interface, a lógica de decisão e o motor em PowerShell que conectam e orquestram ferramentas consagradas da comunidade (`ffmpeg`, `mkvmerge`, `dovi_tool`, `DDVT`, `PgsToSrt`, `Tesseract`, `DeeZy`, `seconv`). Serve para um arquivo só ou para temporadas inteiras.

---

## 💡 Dolby Vision: o programa MEDE antes de converter

É a diferença que define o projeto. Converter um Perfil 7 **não é sempre a mesma coisa**, e o programa deixou de fingir que era.

Antes de tocar no arquivo, ele lê o campo `el_type` dentro do RPU (com o `dovi_tool`) e separa **três** casos:

| | Cor na tela | O que significa |
|---|---|---|
| **MEL** — Minimal Enhancement Layer | 🟢 verde | A camada extra **não carrega imagem**. Descartar não muda um pixel. |
| **Simple FEL** | 🟠 laranja | A camada carrega imagem, mas é **refino** — residual, grão, degradê. Perde-se detalhe fino, visível só em quadro parado. |
| **Complex FEL** | 🔴 vermelho | A camada **levanta o brilho**. Sem ela, o RPU pede à TV um pico que o vídeo não entrega mais. É o único caso que incomoda. |

**O que separa Simple de Complex é um número:** o L1 do RPU (o pico que o arquivo pede) contra o pico do mastering display (o monitor em que o filme foi finalizado, declarado dentro do próprio arquivo). Se o arquivo não declara esse pico, **o programa diz que não sabe** em vez de escolher um lado.

Medido em máquina real, sem consultar lista nenhuma:

```
Troy (2004) Director's Cut  ->  MEL            303 nits de 1.000
Game of Thrones S08E01      ->  SIMPLE FEL     153 nits de 1.000
Saving Private Ryan (1998)  ->  COMPLEX FEL  1.608 nits de 1.000
```

> ⚠️ **Vermelho não quer dizer que a conversão estraga.** Shield, Apple TV, Zidoo, Dune e as TVs **já descartam** a camada extra hoje — nesses aparelhos o Perfil 7 já toca do jeito que o convertido vai tocar. Quem perde alguma coisa é quem tem player com decodificador duplo (OPPO UDP-203/205, Panasonic UB820/UB9000, Sony X700/X800M2).

**Os limites, ditos sem rodeio:**

* A leitura é por **amostragem de trechos**, não pelo filme inteiro. Se é MEL ou FEL, a amostra basta (o campo não muda ao longo do filme). Os números de brilho são da amostra.
* O programa **não mede o brilho real da camada base**. A separação Simple/Complex é uma comparação contra o pico do master declarado: uma boa indicação, não uma prova.
* O `dovi_tool` no modo 2 (que é o que usamos) **remove do RPU o mapeamento de luma/croma do Perfil 7 FEL** — o que sai é um Perfil 8.1 legítimo, não um Perfil 7 remendado. O que **nenhum modo** do `dovi_tool` faz é **recalcular o L1**, e é daí que vem toda a ressalva.

---

## 💡 Perfil 5 → MP4

O Perfil 5 (nativo de Web-DL / streaming) usa o espaço de cores **IPTPQc2** e não possui camada de fallback HDR10. Remuxar para P8 gera cores roxas/esverdeadas, e fazer direito exigiria **recodificar o vídeo inteiro** — o que este programa se recusa a fazer.

Mas o P5 não fica parado. O que ele precisa não é de conversão de perfil: é de um **container** que os aparelhos leiam. O programa remuxa para **MP4 com a marca `dvh1`**, com o vídeo **copiado** quadro por quadro — é assim que um P5 toca no Apple TV, no Infuse e nos players que ignoram o `.mkv`.

Nesse caminho: o áudio é copiado quando cabe no MP4 (E-AC-3, AC-3, AAC) e vira E-AC-3 640k quando não cabe (TrueHD, DTS); a legenda de texto vira `mov_text`; a legenda PGS é **descartada com aviso**, porque legenda de imagem não existe em MP4 — e não há OCR nesse caminho.

---

## 💡 Outros problemas que o programa resolve

| | |
|---|---|
| **Áudio incompatível** | TrueHD (com ou sem Atmos) → **E-AC-3 Atmos** 1152 kbps via DeeZy, com os objetos de áudio preservados. DTS, DTS-HD MA e DTS:X → **E-AC-3 comum** 640 kbps via ffmpeg — **sem Atmos na saída**, porque DTS e Atmos são de empresas diferentes e os objetos do DTS:X não viram objetos Dolby. |
| **Legenda PGS → SRT** | **Só em português do Brasil.** OCR automático das faixas PGS para `.SRT`, com correção por dicionário e uma **nota de qualidade conferida no arquivo gerado** — EXCELENTE, BOA, RAZOÁVEL ou RUIM. A faixa PGS original continua no arquivo final: o `.SRT` é uma faixa a mais, não uma troca. |
| **Lote e espaço em disco** | Adicione uma temporada inteira e deixe o programa trabalhar. Antes de começar ele **simula a fila inteira na ordem** e diz quantos arquivos cabem, qual é o primeiro que fica de fora e quanto faltaria na vez dele. Quem não cabe **nem chega a começar**. |
| **Automático ou manual** | Deixe o motor de decisão cuidar de tudo, ou escolha faixa por faixa o que manter, converter ou excluir. |
| **Duas línguas** | Português e inglês, com uma bandeira ao lado do botão Entenda. A escolha fica guardada entre as sessões. |

---

## 📖 Entenda a conversão

O programa traz um botão **Entenda** com 14 seções que explicam o que a conversão faz — e o que ela **não** faz. O texto vive em [`fonte/FAQ_PT.txt`](./fonte/FAQ_PT.txt) e pode ser lido aqui sem instalar nada.

| # | Seção |
|---|---|
| 1 | O que é BL, EL e RPU |
| 2 | Perfil 7, 8.1 e 5 — o que muda |
| 3 | MEL, Simple FEL e Complex FEL |
| 4 | **Quem realmente perde com o descarte da EL** |
| 5 | Por que a ressalva existe (o L1 não é recalculado) |
| 6 | Vermelho não quer dizer que estraga |
| 7 | A amostra não é o filme inteiro |
| 8 | Perfil 5 → MP4 |
| 9 | Áudio: TrueHD, DTS e o que sai com Atmos |
| 10 | Legenda PGS → SRT, só PT-BR |
| 11 | Espaço em disco e a fila |
| 12 | Área ativa (L5) |
| 13 | Créditos das ferramentas |
| 14 | **Onde conferir e aprender mais** — as fontes |

---

## 🛠️ Instalação e requisitos

* **Instalador:** instala o programa no sistema como qualquer aplicativo nativo e cria atalhos no Menu Iniciar e na Área de Trabalho.
* **Pré-requisito (opcional):** o programa traz suas próprias ferramentas portáteis. O **.NET Desktop Runtime 8.0** é usado apenas pelo motor de OCR reserva (`PgsToSrt`) e, se faltar, pode ser baixado automaticamente durante a instalação.
* **`dovi_tool` 2.3.3 ou mais novo.** Versões anteriores não têm o `export --levels`, e sem ele o programa não consegue medir MEL × FEL.
* **Sobre a legenda:** a precisão do OCR varia conforme a fonte usada no release, e o programa emite um diagnóstico de qualidade no final. Os processos de vídeo são **sem re-encode**, sempre.

---

## 🖼️ Telas do programa

**1. Análise inicial** — leitura da fila, cálculo de espaço em disco e diagnóstico de cada arquivo.

[![Análise inicial](https://i.ibb.co/NdBdGZ42/image.png)](https://ibb.co/NdBdGZ42)

**2. Modo automático** — o mapeamento de faixas que o programa decidiu.

[![Modo automático](https://i.ibb.co/h1V3dKRK/image.png)](https://ibb.co/h1V3dKRK)

**3. Modo manual** — controle total para manter, converter ou excluir cada áudio e legenda.

[![Modo manual](https://i.ibb.co/G3r5TRrc/image.png)](https://ibb.co/G3r5TRrc)

**4. Conversão em andamento** — acompanhamento por etapas, em tempo real.

[![Conversão em andamento](https://i.ibb.co/G4crhCS1/image.png)](https://ibb.co/G4crhCS1)

**5. Resumo final** — relatório com verificação de integridade e a nota da legenda.

[![Resumo final](https://i.ibb.co/LhHmtqWZ/image.png)](https://ibb.co/LhHmtqWZ)

---

## 🙏 Agradecimentos e créditos

Este programa é uma casca em volta do trabalho de outras pessoas. Cada uma delas resolveu um problema difícil e deixou o resultado disponível para quem quisesse usar. Sem isso, nada aqui existiria.

* **FFmpeg / ffprobe** — processamento, extração e análise de mídia. É ele que corta os trechos da amostra sem recodificar, lê a duração e o FPS, e converte o áudio da família DTS.
* **MKVToolNix (`mkvmerge`)** — o padrão para arquivos Matroska. Monta o arquivo final faixa por faixa, preservando capítulos, marcas e nomes.
* **dovi_tool (por `quietvoid`)** — leitura e conversão dos metadados Dolby Vision. É ele que identifica o perfil, diz se a camada é MEL ou FEL, exporta o L1 e o L5, e faz a conversão de Perfil 7 para 8.1. **Nada disso é reimplementado aqui** — o LaFirma organiza o trabalho em volta e mostra o resultado de um jeito que dê para decidir.
* **DDVT (por `DonaldFaQ`)** — trabalho com RPU e correção de corte. **Foi a ferramenta que ensinou este projeto a existir:** antes do LaFirma, era com ela que se convertia, e foi usando ela que se entendeu o que é RPU, o que é camada de melhoria, o que muda entre um perfil e outro e por que Perfil 7 dá trabalho. A ideia de automatizar essa conversão nasceu dali.
* **DeeZy** — codificação para E-AC-3 com o Dolby Atmos preservado. É o que permite sair de um TrueHD Atmos e continuar com Atmos do outro lado.
* **PgsToSrt, Tesseract OCR & seconv** — o ecossistema responsável pela extração, renderização e conversão OCR das legendas PGS em texto `.SRT`.

E dois agradecimentos que não são de código:

* **`cryptochrome`, autor do `dovi_convert`** — pela pergunta pública sobre como tratávamos a camada de melhoria: se apenas descartávamos, ou se checávamos antes se havia expansão de brilho acima da camada base. A pergunta estava certa e a resposta, na época, era desconfortável — o programa descartava sem checar. **Foi essa cobrança que fez o LaFirma passar a medir antes de converter**, e é dela que vem o vocabulário MEL / Simple FEL / Complex FEL que usamos.
* **`Reset9999` e a comunidade** — pela planilha de MEL × FEL por título. Trabalho manual e paciente, que serve de segunda opinião para todo mundo.
