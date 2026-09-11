# Pubblicare Fieldwork su itch.io

Build corrente: versione 8, Godot 4.7.2. I controlli storici della prima build qui sotto si riferiscono alla versione 5. Per le nuove funzionalità e verifiche vedi le [note della versione 8](releases/iteration-8.md).

La prima pubblicazione della versione 5 su itch.io è stata completata dallo sviluppatore e confermata in chat. Le istruzioni restano come riferimento per aggiornamenti e nuove pagine. L'URL pubblico non è ancora riportato nella documentazione.

## File da caricare

Lo ZIP generato è `exports/fieldwork-v8-web-itch.zip`. Contiene `index.html` direttamente nella radice insieme al motore WebAssembly, al codice JavaScript e alle risorse del gioco. Carica lo ZIP intero, senza estrarlo o rinominare i file al suo interno.

La build usa il renderer Compatibility, un solo thread e canvas adattivo. PWA ed estensioni sono disattivate. Non richiede SharedArrayBuffer o l'opzione sperimentale di isolamento del browser su itch.io.

La versione 8 deve essere caricata come nuovo ZIP; nessun aggiornamento è stato pubblicato automaticamente.

## Verifica storica della prima build v5

- Export release completato; template ufficiali verificati contro il checksum SHA-512 della release Godot.
- ZIP integro, nove file nella radice, 10.389.490 byte compressi e 40.089.935 byte estratti. I file coincidono con la copia per l'anteprima locale.
- Avvio verificato nel browser integrato di Codex via HTTP locale, nuova partita in pausa con $30.000, simulazione e tab Grants funzionanti.
- Return to main menu, ricaricamento della pagina e Continue ripristinano il laboratorio al giorno 2, ore 11:00, con $29.617 visualizzati e 4,5 evidence ottiche. Nessun errore o avviso nella console durante questa prova.
- Regressione UI in modalità headless: 60 controlli passati, zero falliti. I controlli con rendering riportati nelle note della versione sono verifiche precedenti separate.

SHA-256 dello ZIP verificato: `ba7069632c200213d9a1f31312de6c00ce8f51bf791548e62c6aecdf705eb96e`.

La pubblicazione riuscita è confermata dallo sviluppatore. Questo controllo locale non è una verifica diretta della pagina pubblica, né una prova completa su tutti i browser. I controlli di anteprima qui sotto restano utili a ogni aggiornamento.

## Prima pubblicazione

1. Accedi a [itch.io e crea un progetto](https://itch.io/game/new).
2. Imposta il titolo, per esempio **Fieldwork**, e scegli **HTML** nel campo **Kind of project**. Indica lo stato **In development**.
3. In **Uploads**, carica `fieldwork-v8-web-itch.zip` e seleziona **This file will be played in the browser** per questo file.
4. In **Embed options**, scegli **Click to launch in fullscreen**. La UI del laboratorio sfrutta bene uno schermo grande; rotella e pinch controllano lo zoom della mappa. Se preferisci incorporarlo nella pagina, usa 1440 × 960 e attiva **Fullscreen button** e **Click to play**.
5. Non dichiarare il supporto mobile per questa build: i controlli sono pensati per mouse e tastiera. Lascia disattivato **SharedArrayBuffer support**, se disponibile.
6. Aggiungi descrizione, immagine di copertina e screenshot. La mappa corrente è in `docs/prototype-v8.png`; `docs/funding-overview.png` illustra il sistema di finanziamento. La vecchia immagine `docs/fieldwork-roadmap-v5.png` è storica: per lo stato attuale usa `docs/roadmap.md`.
7. Salva inizialmente come **Draft**, apri l'anteprima e completa i controlli sotto. Poi imposta la visibilità **Public** e salva per pubblicarlo.

I nomi delle sezioni possono variare con la lingua dell'account. La [guida ufficiale agli HTML5 di itch.io](https://itch.io/docs/creators/html5) descrive ZIP, modalità di incorporamento e limiti degli upload.

## Controlli nell'anteprima di itch.io

- Avvia una nuova partita e controlla che parta in pausa con $30.000.
- Controlla arredi, cornici e cursori; prova zoom, pan e piazzamento.
- Prova tutti i tab, le priorità Papers first/Grants first, i tooltip e lo scaling della UI.
- Dopo il primo clic controlla musica ed effetti. Prova i due volumi e il mute in Settings; devono persistere dopo il ricaricamento.
- Avvia il tempo, poi metti in pausa. Salva in uno slot, attendi qualche secondo e ricarica la pagina. Il laboratorio deve comparire in Continue e Load laboratory.
- Entra ed esci dal fullscreen, anche dopo aver ricaricato la pagina.
- Controlla almeno il browser che userai per condividere il gioco con i tester. Il test locale non verifica le impostazioni dell'iframe e dello storage di itch.io.

I salvataggi web restano nel browser e nel profilo usato. Non sincronizzano con i salvataggi della versione desktop. Navigazione privata, pulizia dei dati del sito o restrizioni allo storage possono impedirne la conservazione. Prima di chiudere la scheda usa Save oppure Return to main menu, che salva automaticamente. L'autosave avviene ogni cinque giorni di gioco.

Per il fullscreen usa il comando della pagina itch.io o Display settings nel gioco. Il browser può intercettare F11. In una scheda in background la simulazione può fermarsi: non è una modalità di avanzamento offline. Questi vincoli sono descritti nella [documentazione web di Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

## Rigenerare la build

Il preset è in `export_presets.cfg`. Lo script richiede Python 3 e Godot 4.7.2 stabile. I template web sono già presenti localmente in `exports/templates/`; questa cartella e gli ZIP generati sono esclusi da Git.

```sh
python3 tools/export_web.py
```

Su un altro computer, scarica l'archivio standard **Godot_v4.7.2-stable_export_templates.tpz** dalla [release ufficiale](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable). Poi esegui una volta:

```sh
python3 tools/export_web.py --templates /percorso/Godot_v4.7.2-stable_export_templates.tpz
```

Se Godot non è nel PATH o nella posizione standard su macOS, aggiungi `--godot /percorso/eseguibile/Godot`. Lo script importa le risorse, esporta in modalità release, controlla i file obbligatori e i limiti dimensionali, quindi crea lo ZIP con i file nella radice. Test, documentazione e template non entrano nel pacchetto.

Per provarlo localmente:

```sh
python3 -m http.server 8065 --bind 127.0.0.1 --directory exports/web
```

Apri `http://127.0.0.1:8065/` nel browser. Non aprire `index.html` con un doppio clic: l'export richiede un server HTTP. Ferma il server con Ctrl+C.

Per aggiornare il gioco su itch.io, rigenera lo ZIP, sostituisci il vecchio upload, ricontrolla che sia selezionato per l'esecuzione nel browser e ripeti il test in anteprima. Mantieni invariata la pagina del progetto per dare continuità ai tester.
