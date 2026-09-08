# Generazione dell'infografica della roadmap

Strumento: ImageGen integrato in Codex. Nessun uso della CLI/API fallback.

File finale: [fieldwork-roadmap-v5.png](fieldwork-roadmap-v5.png), PNG da 1672 × 941 pixel. Il prompt richiedeva idealmente 3840 × 2160; queste sono le dimensioni effettive restituite dallo strumento.

La roadmap visualizza la versione 5 implementata e in playtest, seguita dai cinque blocchi previsti. I numeri indicano blocchi di lavoro, non nuove versioni. Non sono promesse date di uscita. Il testo di riferimento accessibile è in [roadmap.md](roadmap.md).

## Prompt finale

```text
Use case: infographic-diagram.
Asset type: official developer roadmap poster for the indie physics laboratory management game Fieldwork, in Italian.
Create one polished, high-resolution landscape infographic, ideally 3840 x 2160. It must feel like an actual game developer's roadmap announcement, not a generic business presentation.
Brand style from the game: deep midnight navy #080f17, slate blue lab panels #111f2a, bright cyan #67e6e0, restrained amber #f2c16e for planned work, crisp warm white text. Subtle technical grid and scientific linework, premium editorial typography. Tiny detailed isometric laboratory illustrations in each card: laser optics bench and grant papers for block 1; researchers and calibration tools for 2; branching instruments and a lab floorplan extension for 3; conference badge, visitor and travel case for 4; discussion at a physics conference and choice cards for 5; two rival laboratories and competing research plots for 6. Science visuals are decorative and must not displace the copy.
Composition: spacious header with FIELDWORK and ROADMAP DI SVILUPPO, then a balanced grid of SIX numbered cards in three columns and two rows, reading 01 02 03 on the first row and 04 05 06 on the second row. All six cards are fully visible. The first card has a cyan border and a distinct IMPLEMENTATO / IN PLAYTEST badge; the second has the amber PROSSIMO BLOCCO badge; the rest have muted IN PROGRAMMA badges. The numbers are implementation blocks, NOT promised version numbers. Card illustrations stay to a corner with plenty of uninterrupted flat dark background for text. Body text must be large, sharp, left-aligned and readable. Do not place sentences over illustrations. Use subtle connectors or progress line to imply sequence, without crossing any text.
Use ONLY the following exact Italian copy. Preserve accents, numbers and dollar values. Text in square brackets below describes layout and is not to be printed.

[Header]
FIELDWORK
ROADMAP DI SVILUPPO
Versione 5 • Settembre 2026

[Card 01]
01
IMPLEMENTATO / IN PLAYTEST
Grant e nuova economia
Paper: solo impact
Grant iniziale: $30.000
Small: $14.000 • 64 ore • ogni 20 giorni
Tutorial, fullscreen e UI scalabile
Grafica del laboratorio rinnovata

[Card 02]
02
PROSSIMO BLOCCO
Personale e manutenzione
Supervisione dei PhD
Usura legata all'utilizzo
Ruoli e costi da ribilanciare

[Card 03]
03
IN PROGRAMMA
Specializzazione ed espansione
Dotazione iniziale per branca
Milestone coerenti col programma
Nuovi spazi sbloccabili

[Card 04]
04
IN PROGRAMMA
Formazione e ospiti
Summer school e conferenze
Bonus temporanei dei visitatori
Rischio di furto delle idee

[Card 05]
05
IN PROGRAMMA
Eventi a scelta
Conferenze e collaborazioni
Reputazione e sostegno universitario
Effetti temporanei sui grant

[Card 06]
06
IN PROGRAMMA
Concorrenza scientifica
Gruppi rivali e priorità di pubblicazione
Idee da differenziare
Penalità graduate a tier o impact

[Footer]
Un blocco alla volta. Playtest e ribilanciamento prima di procedere.
Ordine previsto, senza date di uscita confermate.

Constraints: no release dates for future blocks; no invented future version numbers; no additional promises; no percentages or charts implying progress completion of planned blocks; no logos of other games; no watermark; no lorem ipsum; no extra words in illustrations. Keep a generous safe margin around all edges and all text fully legible. The first card must clearly distinguish implemented content from all the planned cards.
```
