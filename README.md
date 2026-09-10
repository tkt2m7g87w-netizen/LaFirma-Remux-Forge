# LaFirma Remux Forge (Black Edition)

<p align="center">
  <b>&#127482;&#127480; English</b> &nbsp;&nbsp;|&nbsp;&nbsp; <a href="./README.pt-BR.md">&#127463;&#127479; Português</a>
</p>

> **Automated MKV Remuxing & Transcoding Engine**
> *Convert Dolby Vision Profile 7 (MEL/FEL) to 8.1 without video re-encoding, transcode audio to E-AC-3 with Atmos, and process PT-BR PGS OCR subtitles with a smooth PowerShell GUI.*

---

## Downloads

> **GitHub is the most up-to-date source.** The mirrors below still work, but they carry an earlier version of the program.

| | Where | Status |
|---|---|---|
| **Source code, guides, changelog** | Right here in this repo | always newest |
| **Ready-made installer** | [Releases](../../releases) | current |
| Installer — mirror | [Proton Drive](https://drive.proton.me/urls/ZATVE13HWM#em0BACyqRM5J) · [MEGA](https://mega.nz/file/abxFWYpR#3DjvTORJqK-XMqp7uvR8l30qJT67wAS6OVpxLnlTI-I) · [GoFile](https://gofile.io/d/YE2isutz) | **outdated** |
| Full folder — mirror | [Proton Drive](https://drive.proton.me/urls/FQWT6PB5W4#VgsXd07uV4OK) · [MEGA](https://mega.nz/folder/aSpxxJII#v5CzveN0-Um9LryBnjfMMQ) | **outdated** |

**Installer compilation guide:** [README_INSTALLER[ENGLISH].txt](./README_INSTALLER%5BENGLISH%5D.txt)

<details>
<summary><b>Why the binaries are not in this repo</b></summary>

The `tools\` folder holds hundreds of MB of **other people's** programs, each under its own licence. We do not republish other people's work as our own — this repo says where each one comes from, and the ready-made package exists for those who just want to use it.

</details>

---

## What it is

**LaFirma Remux Forge** was designed to eliminate media playback incompatibility on Smart TVs (LG, Samsung), players (Shield, Apple TV, Zidoo) and media servers (**Plex**, **Jellyfin**, **Emby**).

It is an orchestration bridge: we built the GUI, the decision logic and the PowerShell engine that connect and automate established community utilities (`ffmpeg`, `mkvmerge`, `dovi_tool`, `DDVT`, `PgsToSrt`, `Tesseract`, `DeeZy`, `seconv`). Works on single files or whole TV seasons.

---

## Dolby Vision: the program MEASURES before converting

This is the difference that defines the project. Converting a Profile 7 is **not always the same thing**, and the program stopped pretending otherwise.

Before touching the file, it reads the `el_type` field inside the RPU (with `dovi_tool`) and separates **three** cases:

| On screen | What it means |
|---|---|
| $\textcolor{green}{\textsf{MEL}}$ — Minimal Enhancement Layer | The extra layer **carries no picture**. Discarding it changes no pixel. |
| $\textcolor{orange}{\textsf{Simple FEL}}$ | The layer carries picture, but it is **refinement** — residual, grain, gradients. You lose fine detail, visible only on a paused frame. |
| $\textcolor{red}{\textsf{Complex FEL}}$ | The layer **raises brightness**. Without it the RPU asks the TV for a peak the video no longer delivers. This is the only case that matters. |

### What separates $\textcolor{orange}{\textsf{Simple}}$ from $\textcolor{red}{\textsf{Complex}}$

**One number.** The RPU's **L1** — the peak the file *asks for* — against the **mastering display peak** — the monitor the film was graded on, declared inside the file itself.

> **L1 below the master** → $\textcolor{orange}{\textsf{Simple FEL}}$. The base layer already delivers what the RPU asks for.
>
> **L1 at or above the master** → $\textcolor{red}{\textsf{Complex FEL}}$. The RPU asks for brightness the base layer alone does not have.
>
> **No master peak declared** → the program says **it does not know**, instead of picking a side.

Measured on a real machine, with no list consulted:

```
Troy (2004) Director's Cut  ->  MEL              303 nits of 1,000
Game of Thrones S08E01      ->  SIMPLE FEL       153 nits of 1,000
Saving Private Ryan (1998)  ->  COMPLEX FEL    1,608 nits of 1,000
```

> **Red does not mean the conversion ruins the file.** Shield, Apple TV, Zidoo, Dune and TVs **already discard** the extra layer today — on those devices Profile 7 already plays the way the converted file will. Who actually loses something is whoever owns a dual-layer decoder (OPPO UDP-203/205, Panasonic UB820/UB9000, Sony X700/X800M2).

**The limits, said plainly:**

* The reading is **sampled from short pieces**, not the whole film. Whether it is MEL or FEL, the sample settles it (the field does not change through the film). The brightness numbers are the sample's.
* The program **does not measure the base layer's real brightness**. The Simple/Complex split is a comparison against the declared master peak: a good indication, not a proof.
* `dovi_tool` in mode 2 (what we use) **removes the Profile 7 FEL luma/chroma mapping from the RPU** — what comes out is a legitimate Profile 8.1, not a patched Profile 7. What **no dovi_tool mode** does is **recompute L1**, and that is where the whole caveat comes from.

---

## Profile 5 → MP4

Profile 5 (native to Web-DL / streaming) uses the **IPTPQc2** colour space without a standard HDR10 fallback layer. Forcing a remux-only conversion to P8 causes severe colour distortion (purple/green tint), and doing it properly would require **full video re-encoding** — which this program refuses to do.

But P5 does not just sit there. What it needs is not a profile conversion: it is a **container** devices will read. The program remuxes it to **MP4 with the `dvh1` tag**, video **copied** frame by frame — that is how a P5 plays on Apple TV, on Infuse and on players that ignore `.mkv`.

On that path: audio is copied when it fits in MP4 (E-AC-3, AC-3, AAC) and converted to E-AC-3 640k when it does not (TrueHD, DTS); text subtitles become `mov_text`; PGS subtitles are **discarded with a warning**, because image subtitles have no representation in MP4 — and there is no OCR on this path.

---

## Other problems solved

### Audio

Smart TVs and soundbars refuse the lossless codecs a Blu-ray carries. The program converts only what needs converting:

* **TrueHD** and **TrueHD Atmos** → **E-AC-3 Atmos**, 1152 kbps, via DeeZy.
  The audio objects survive: Atmos goes in, Atmos comes out.
* **DTS**, **DTS-HD MA** and **DTS:X** → **plain E-AC-3**, 640 kbps, via ffmpeg.
  **No Atmos in the output.** DTS and Atmos come from different companies, and DTS:X objects do not become Dolby objects. Nothing on earth converts one into the other.
* **E-AC-3**, **AC-3** and **AAC** are already compatible and are left untouched.

### PGS subtitles → SRT

**Brazilian Portuguese only.** This is not a general-purpose OCR: the dictionary, the correction rules and the quality grading were all built around PT-BR.

Image-based PGS becomes clean `.SRT` text, spellchecked against a 1.3 million word dictionary, and the program **grades the file it generated** — EXCELLENT, GOOD, FAIR or POOR — instead of assuming it worked.

The original PGS track **stays in the final file**. The `.SRT` is one extra track, not a replacement.

### Batch and disk space

Queue a single file or a whole season. Before starting, the program **simulates the entire queue in the order the engine will process it** and tells you three things: how many files fit, which is the first one that does not, and how much would be missing by its turn.

A file that does not fit **never even starts** — no temporary folder, no 20 minutes of work thrown away.

### Auto or manual

Let the decision engine handle everything, or open the track list and choose, one by one, what to **keep**, **convert** or **drop**.

### Two languages

Portuguese and English, switched by a flag next to the Learn button. The choice is remembered between sessions.

---

## Understand the conversion

The program has a **Learn** button with 14 sections explaining what the conversion does — and what it does **not** do. The text lives in [`fonte/FAQ_EN.txt`](./fonte/FAQ_EN.txt) and can be read here without installing anything.

| # | Section |
|---|---|
| 1 | What BL, EL and RPU are |
| 2 | Profile 7, 8.1 and 5 — what changes |
| 3 | MEL, Simple FEL and Complex FEL |
| 4 | **Who actually loses when the EL is dropped** |
| 5 | Why the caveat exists (L1 is not recomputed) |
| 6 | Red does not mean it ruins anything |
| 7 | The sample is not the whole film |
| 8 | Profile 5 → MP4 |
| 9 | Audio: TrueHD, DTS and what keeps Atmos |
| 10 | PGS → SRT subtitles, PT-BR only |
| 11 | Disk space and the queue |
| 12 | Active area (L5) |
| 13 | Tool credits |
| 14 | **Where to check and learn more** — the sources |

---

## Installation & requirements

* **Installer:** installs natively with standard Windows integration and Start Menu / Desktop shortcuts.
* **Dependencies (optional):** self-contained toolset. **.NET Desktop Runtime 8.0** is only required for the fallback OCR engine (`PgsToSrt`) and can be downloaded automatically during installation if missing.
* **`dovi_tool` 2.3.3 or newer.** Earlier versions lack `export --levels`, and without it the program cannot measure MEL vs FEL.
* **Subtitle OCR note:** accuracy depends on font styling and source release quality; an automated evaluation report is shown at the end. Video processing avoids re-encoding entirely, always.

---

## Screenshots

**1. Initial analysis** — queue reading, disk-space calculation and per-file diagnosis.

[![Initial analysis](https://i.ibb.co/NdBdGZ42/image.png)](https://ibb.co/NdBdGZ42)

**2. Auto mode** — detailed track mapping decided by the program.

[![Auto mode](https://i.ibb.co/h1V3dKRK/image.png)](https://ibb.co/h1V3dKRK)

**3. Manual mode** — full control to keep, convert or drop each audio and subtitle.

[![Manual mode](https://i.ibb.co/G3r5TRrc/image.png)](https://ibb.co/G3r5TRrc)

**4. Conversion progress** — real-time per-step tracking with performance metrics.

[![Conversion progress](https://i.ibb.co/G4crhCS1/image.png)](https://ibb.co/G4crhCS1)

**5. Summary & quality evaluation** — final report with integrity check and subtitle grade.

[![Summary](https://i.ibb.co/LhHmtqWZ/image.png)](https://ibb.co/LhHmtqWZ)

---

## Credits & acknowledgments

This program is a shell around other people's work. Each of them solved a hard problem and left the result available to anyone who wanted it. Without that, nothing here would exist.

* **FFmpeg / ffprobe** — media processing, extraction and analysis. It cuts the sample pieces without re-encoding, reads duration and FPS, and converts DTS-family audio.
* **MKVToolNix (`mkvmerge`)** — the industry standard for Matroska files. It assembles the final file track by track, preserving chapters, flags and names.
* **dovi_tool (by `quietvoid`)** — reading and converting Dolby Vision metadata. It identifies the profile, says whether the layer is MEL or FEL, exports L1 and L5, and performs the Profile 7-to-8.1 conversion. **None of it is reimplemented here** — LaFirma organises the work around it and shows the result in a way you can decide from.
* **DDVT (by `DonaldFaQ`)** — RPU work and crop correction. **It is the tool that taught this project how to exist:** before LaFirma, it was what we converted with, and it was by using it that we came to understand what an RPU is, what an enhancement layer is, what changes between profiles, and why Profile 7 is troublesome. The idea of automating this conversion was born there.
* **DeeZy** — Dolby Digital Plus encoding with spatial Dolby Atmos metadata preserved. It is what lets a TrueHD Atmos track come out the other side still carrying Atmos.
* **PgsToSrt, Tesseract OCR & seconv** — the OCR ecosystem behind extracting, rendering and converting PGS subtitles into `.SRT` text.

And two acknowledgments that are not about code:

* **`cryptochrome`, author of `dovi_convert`** — for the public question about how we handled the enhancement layer: whether we simply stripped it, or checked first whether it carried brightness expansion beyond the base layer. The question was right and the answer, at the time, was uncomfortable — the program stripped it without checking. **That challenge is why LaFirma measures before converting**, and where the MEL / Simple FEL / Complex FEL vocabulary comes from.
* **`Reset9999` and the community** — for the MEL × FEL spreadsheet by title. Manual, patient work that serves as a second opinion for everybody.
