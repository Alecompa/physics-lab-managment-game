# Fieldwork, versione 5: grant, avvio guidato e grafica

Aggiornamento dell'8 settembre 2026 rispetto alla versione con programmi di ricerca, albero tecnologico e letti assegnati. Stato: implementato, in playtest.

## Economia scientifica

I paper danno solo impact. I grant e il contributo universitario finanziano personale e strumenti. Il laboratorio iniziale riceve $30.000; la prima proposal introduttiva assegna $12.000 dopo aver sottomesso un paper. Il grant introduttivo è garantito una sola volta e ha una review di un giorno.

I ricercatori scrivono proposal nelle ore di Activity, usando scrivanie raggiungibili e rinunciando in quelle ore a scrittura e studio. Gli small assegnano $14.000 per 64 ore minime, gli standard $32.000 per 192 ore e i large $72.000 per 384 ore. Le review durano 5, 8 e 12 giorni. Milestone 1 e 2 sbloccano rispettivamente standard e large.

Il successo dipende da size, impact totale, milestone, preparazione e revisioni. Un rifiuto conserva metà del lavoro per la stessa proposal; il bonus di revisione non si accumula. Bandi ogni 20, 30 e 45 giorni limitano gli invii. Le review di size diverse possono sovrapporsi.

Stipendi e upkeep sono stati ribilanciati. Entrate universitarie e spese maturano ogni ora. Il sostegno dipende dall'impact totale e perde parte del bonus dopo una pausa prolungata nelle pubblicazioni. L'impact speso in tecnologie non diminuisce il sostegno. L'insolvenza ferma il laboratorio: non esistono salvataggi monetari automatici o rimborsi dallo smantellamento.

## Correzioni dal primo playtest

Un'espansione moderata poteva esaurire i fondi prima del successivo bando, anche con una proposal pronta. Il grant introduttivo non occupa più un bando small e le milestone non rinviano il calendario. Gli small restano ogni 20 giorni. Il grant iniziale è passato da $24.000 a $30.000; gli small da $12.000 a $14.000 e da 96 a 64 ore.

Gli avvisi spiegano quando la cassa prevista non copre l'attesa di un esito. Importi, scadenze, probabilità, avanzamento, storico e autonomia sono visibili nella gestione finanziaria.

## Interfaccia e grafica

Nuovo tab Grants, avvio guidato, impact disponibile e totale distinti, preview dell'autonomia dopo gli acquisti e grafici finanziari. Le decisioni di paper e grant e le milestone si presentano in sequenza, senza sovrapporsi.

Fullscreen tramite F11, scala UI al 100%, 115% o 130%, preferenze persistenti e layout compatto per finestre strette. Il restyling comprende palette navy e cyan, pulsanti animati, notebook, ritratti, strumenti, porte, arredi e animazioni del laboratorio disegnati in Godot.

## Salvataggi

I salvataggi v5 hanno file separati dai v4. I primi salvataggi v5 conservano cassa, premi già ottenuti, bozze e review in corso. Il caricamento elimina l'attesa small dovuta al solo grant introduttivo. I $30.000 iniziali si applicano alle nuove partite; non vengono accreditati retroattivamente.

Riavviare la copia del gioco in esecuzione per usare l'aggiornamento.

## Versione browser

Export web release per itch.io con Godot 4.7.2, renderer Compatibility e un solo thread. Il canvas si adatta alla finestra; PWA ed estensioni sono disattivate. La pubblicazione su itch.io è stata confermata dallo sviluppatore.

Nel browser i pulsanti Quit e Save and quit sono nascosti. Return to main menu salva la partita; il menu ricorda che i salvataggi restano nel browser. Le preferenze di scala vengono ripristinate, mentre il fullscreen richiede un nuovo clic o tasto e non si attiva automaticamente al caricamento.

Preset e script di packaging permettono di rigenerare `exports/fieldwork-v5-web-itch.zip`, con `index.html` nella radice. L'archivio contiene nove file e pesa circa 10,4 MB. Vedi [guida all'export, pubblicazione e verifica web](../publishing-itch.md).

## Verifica e lavoro successivo

Passati 509 controlli di simulazione, 238 di progressione, 141 della UI esistente, 158 del funding, 191 del ribilanciamento e 62 della UI funding con rendering. Verificate tre risoluzioni, tre scale, fullscreen e persistenza delle preferenze.

Negli scenari controllati con espansione moderata, 28 run su 30 superano il giorno 75. La strategia reagisce al budget e dà priorità alle revisioni; il dato non rappresenta una probabilità di sopravvivenza per qualsiasi giocatore. Il completamento dei tre programmi con la nuova economia richiede ancora playtesting completo.

Il prossimo blocco riguarda personale e manutenzione. Supervisione, usura differenziata dei PhD, espansione del laboratorio, formazione, ospiti, eventi con effetti e concorrenti non sono ancora implementati. Vedi [roadmap](../roadmap.md) e [design completo](../progression-design.md).
