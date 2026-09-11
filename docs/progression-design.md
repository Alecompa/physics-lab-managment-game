# Fieldwork: progressione e piano di playtest

Stato all'11 settembre 2026: blocchi 1–3 implementati. I blocchi 2 e 3 sono stati autorizzati insieme dall'utente e richiedono ora playtest umano. I blocchi 4–6 restano in attesa. I parametri attuali hanno verifiche automatiche; il bilanciamento richiede ulteriore playtesting umano.

Sintesi per i giocatori: [roadmap](roadmap.md). Modifiche della versione attuale: [note della versione 8](releases/iteration-8.md).

La versione 5 è disponibile anche come build browser per itch.io; lo sviluppatore ne ha confermato la pubblicazione. Preset, procedura di export e controlli su salvataggi, fullscreen e UI web sono nella [guida di pubblicazione](publishing-itch.md). La distribuzione web non cambia i criteri di playtest per procedere con i blocchi successivi.

## Obiettivo

I paper producono solo impact. I fondi provengono dai grant assegnati e dal contributo universitario. Il tempo dei ricercatori deve essere conteso fra scrittura, studio e proposal. Un laboratorio prudente deve superare i primi 75 giorni, equivalenti a un'ora a 1× senza pause. L'autonomia tende a 60 giorni, oscillando con premi e investimenti.

Autonomia = fondi disponibili / `max(0, costi giornalieri - contributo universitario)`. Quando le entrate universitarie coprono i costi, non esiste una scadenza finanziaria alle condizioni correnti. Grant in review e futuri acquisti non entrano nell'autonomia corrente.

## Blocco 1: economia, grant e avvio

### Regole

- I tier dei paper conservano evidence, lavoro, probabilità, review e impact. Eliminare ogni premio monetario e ogni etichetta Funding/Paper income.
- Grant iniziale già assegnato: $30.000, laboratorio arredato. Non assegnare altri fondi alla scelta del programma.
- Stipendi giornalieri: PhD $100, ricercatore $200, tecnico $140. Upkeep base: ottica $60, materiali $100, nucleare $150, quantum $220. Restano i moltiplicatori degli upgrade.
- Contributo universitario: `120 + min(120, 4 * lifetime_impact) * recent_activity`. Attività recente 1 fino a 30 giorni dall'ultima pubblicazione, poi riduzione lineare fino a 0,25 al giorno 60. Spendere impact non diminuisce questo contributo. Entrate e costi maturano ogni ora di gioco.
- Solo i ricercatori possono usare Activity per scrivere proposal. Serve una scrivania raggiungibile. Una proposal in scrittura alla volta; review di size diverse possono sovrapporsi alla scrittura e ai paper.
- Nessun accredito automatico quando la cassa finisce. Insolvenza arresta la simulazione; il giocatore può esaminare il bilancio, caricare una partita o ricominciare.
- Smantellare strumenti, moduli e arredi non genera fondi. Evita una terza fonte monetaria e la liquidazione della dotazione iniziale.

| Grant | Premio | Ore minime | Review | Requisito | Periodo bandi |
| --- | ---: | ---: | ---: | --- | ---: |
| Introduttivo | $12.000 | 48 | 1 giorno | Primo paper sottomesso | Una sola volta |
| Small | $14.000 | 64 | 5 giorni | Introduttivo completato | 20 giorni |
| Standard | $32.000 | 192 | 8 giorni | Milestone 1 | 30 giorni |
| Large | $72.000 | 384 | 12 giorni | Milestone 2 | 45 giorni |

Il grant introduttivo è garantito con requisiti visibili, anche se il paper viene rifiutato. Vale anche senza guida visibile; nascondere il tutorial non cambia la difficoltà. Ha un iter separato e non consuma bandi small. Prima di averlo ottenuto non si presentano small ordinari. Le ore sono ore effettive di Activity, dopo spostamenti e modificatori di performance; non punti di scrittura dei paper.

Probabilità ordinaria: base 55/45/35%, più fino a 15 punti dall'impact totale, 0,5 punti per impact; più 5 punti per milestone fino a 15; più fino a 15 punti per preparazione aggiuntiva. La preparazione costa fino al 50% di ore in più, con rendimento decrescente. Tetto finale 85%. Congelare la probabilità e il sorteggio all'invio; salvare il sorteggio per evitare nuovi esiti ricaricando.

Il calendario ha periodi fissi a partire dal giorno 1. Una domanda inviata consuma il periodo per quella size. Una bozza non consuma il periodo. Le milestone non cambiano il periodo degli small e non rinviano date già accessibili. Il rifiuto conserva il 50% delle ore dell'ultima domanda nella stessa proposal, senza accumulo oltre quel limite. Una revisione al prossimo bando compatibile ottiene +5 punti, una sola volta; non si può trasferire il credito a un'altra size. Il cambio di size e i feedback narrativi articolati restano fuori dal primo blocco.

### Interfaccia e salvataggi

- [x] Quarto tab Grants e accesso vicino a Program/Development.
- [x] Importi, requisiti, prossimi bandi, ore, probabilità con componenti, invio, review, feedback e storico.
- [x] Bilancio e autonomia visibili; preview degli acquisti comprensiva del nuovo costo giornaliero.
- [x] Impact disponibile e totale distinti.
- [x] Fullscreen, scaling e impostazioni persistenti; contenuti raggiungibili alle scale offerte.
- [x] Tutorial esplicito su tempo, raccolta, analisi, scrittura, grant e budget; progresso salvato.
- [x] Salvataggi v5 separati dai v4, che non vengono cancellati o sovrascritti.
- [x] Verifiche automatiche per transizioni, doppio pagamento, rifiuto, calendario, ruoli, probabilità, salvataggi e insolvenza.

### Playtest di passaggio

1. Partita prudente: squadra iniziale e al massimo $3.000 di acquisti iniziali. Primo grant guidato attorno al giorno 15–20; nessuna insolvenza entro il giorno 75.
2. Espansione aggressiva: assumere e acquistare presto. La riduzione di autonomia deve essere prevedibile e può portare all'insolvenza.
3. Due rifiuti consecutivi di grant ordinari: misurare autonomia minima e possibilità di ripresentare una domanda senza interrompere tutta la scienza.
4. Scrittura competitiva: confrontare priorità paper e priorità grant; nessuna strategia deve produrre fondi illimitati senza continuare a pubblicare.
5. UI: leggere e usare tutte le schermate a 1280×800, 1440×960 e 1920×1080, in finestra e fullscreen, alle scale disponibili.

Incassi medi teorici dopo il primo ribilanciamento, prima di investimenti: $490/giorno da small al 70% ogni 20 giorni; $1.183 sommando standard al 65% ogni 30; $2.143 aggiungendo large al 60% ogni 45. Se si presenta uno small ogni due bandi, questi ultimi due valori scendono a circa $938 e $1.898. Sono opzioni di allocazione del lavoro, non quote imposte dal gioco. Questi valori assumono capacità di scrittura sufficiente e non promettono entrate regolari. Obiettivo indicativo: 35–45 giorni di autonomia prima di un esito importante, 75–100 dopo una vittoria. Nessuna correzione nascosta dei premi in funzione della cassa.

## Blocco 2: personale e manutenzione

Implementato nella versione 6. Ogni ricercatore supervisiona fino a due PhD. Le prime ore Activity disponibili vengono riservate alla supervisione: due ore reali alla scrivania per studente al giorno. Fatica, spostamenti e indisponibilità della scrivania riducono le ore erogate. Il lavoro restante torna all'Activity scelta. La supervisione non usa ore di raccolta, analisi o riposo.

La produttività scientifica di un PhD è `0,60 + 0,40 × copertura`, con copertura fra zero e uno calcolata sulle ore di supervisione ricevute il giorno precedente. I fondatori partono coperti. Una nuova assegnazione azzera il credito e il licenziamento del supervisore toglie subito il bonus. L'UI mostra ore richieste ed erogate, produttività e ore cumulate di lavoro, viaggio e attesa.

L'usura è legata alla raccolta produttiva, comprese le frazioni di ora: 0,10 punti condition per PhD e 0,04 per gli altri ruoli. Nessuna usura per attese a un banco saturo o strumenti inattivi. Rimossa la perdita fissa di 0,45 al giorno. Tecnici: riparazione base 1,2 punti/ora; altri ruoli: 0,45. Service manuale: massimo fra $60 e 12 dollari per punto condition mancante, arrotondato per eccesso.

Playtest: confrontare squadre a stipendi uguali, controllare quanto spesso il ricercatore resta senza ore per grant/paper, copertura dei turni notturni, costo di riparazione e leggibilità delle attese. La squadra ricca di PhD può produrre più dati, ma deve rinunciare a capacità scientifica e finanziaria o spendere di più in manutenzione.

## Blocco 3: area iniziale ed espansione

Implementato nella versione 6. La dotazione dipende dal programma: detector nucleare introduttivo per dark matter, quantum rig introduttivo per logical qubit, camera materiali introduttiva per superconductivity. Tutti hanno capacità base 18/giorno e upkeep $60/giorno, con $30.000 iniziali. Specializzazione dello staff, tre idee common e una rare corrispondono al campo principale; una common apre il campo secondario. La prima milestone richiede un paper del campo principale, oltre ai due paper totali. Le altre milestone cumulative rimangono invariate.

Lo strumento introduttivo non sblocca la costruzione dei corrispondenti strumenti avanzati. Gli upgrade richiedono la tecnologia e convertono lo strumento alle caratteristiche e all'upkeep ordinari. Descrizioni, introduzione e testi delle milestone distinguono controlli dei fondi nei detector, correzione d'errore nei qubit e riproducibilità della fase superconduttiva.

Griglia iniziale 28×20. Dalla versione 7 ha tre stanze collegate da corridoi; le vecchie partite conservano la pianta aperta. Si può costruire in qualunque stanza rispettando muri, arredi fissi e accessi. Oggetti spostabili gratuitamente mantenendo ID, assegnazioni, condition, livello e moduli; destinazioni invalide non modificano lo stato. Entrata, sedute comuni, sedie, piedi dei letti e accessi agli strumenti restano protetti. Zoom con rotella/pinch e pulsanti, pan con tasto centrale/trackpad/frecce, Fit per ripristinare la vista. Velocità da 4 a 24 caselle/ora; il tempo rimanente all'arrivo è produttivo.

Espansioni da endgame: dopo milestone 3 e Advanced instrumentation, Campus planning costa 18 impact. La prima ala costa $45.000 e porta a 34×24. Dopo la major discovery si può acquistare una seconda ala a $75.000, fino a 40×24. Non aumentano automaticamente il personale né sono necessarie per le milestone scientifiche.

Salvataggi: schema 6 con lettura dei v5; nomi dei file conservati per ritrovare le partite web esistenti. Nessun accredito o sostituzione dello strumento in una partita caricata. Prima di sovrascrivere un file v5 si conserva una copia `.v5-backup`. I PhD privi dei nuovi campi ricevono un supervisore se esiste un ricercatore con capacità e Activity sufficienti. Milestone già raggiunte restano valide.

Playtest: su tutti i programmi misurare prima pubblicazione, milestone 1, primo standard, correzioni alla disposizione e tempo perso camminando. Verificare espansioni, spostamenti e UI su sessioni lunghe e browser. Confermare che le ali siano una scelta di crescita, senza obbligare a una spesa prima del completamento scientifico.

## Blocco 4: formazione e ospiti

Summer school e conferenze con costo, durata, premio dichiarato e stipendio durante l'assenza. Premi possibili: study point, idea garantita del campo, minore usura individuale. Ospiti con bonus temporanei; alcuni opportunisti possono appropriarsi di idee non pubblicate. Comunicare il rischio e permettere di limitare l'accesso.

Controllare convenienza e costo dell'assenza, perdita temporanea di supervisione e produzione, utilità della formazione nel tempo. Furti recuperabili, senza blocchi permanenti del programma.

## Blocco 5: eventi a scelta

Eventi contestuali su conferenze, università, collaborazioni e gestione. Effetti e durata leggibili. Modificatori temporanei al contributo e ai grant, con limiti all'accumulo. Reputazione istituzionale distinta dall'impact spendibile dei paper.

Controllare opzioni con compromessi reali, frequenza delle interruzioni e sequenze negative. L'economia gestita bene deve tollerare gli eventi avversi.

## Blocco 6: concorrenza

Gruppi rivali con campi e progresso riconoscibili, rischio di pubblicazione anticipata visibile. Scelte per accelerare, differenziare o cambiare obiettivo. Penalità graduate a tier o impact, conservazione del lavoro già investito dove possibile. Protezione del tutorial e della raggiungibilità della major discovery.

Confrontare partite con e senza concorrenti. Devono restare praticabili strategie lente e paper ambiziosi. Testare sovrapposizione di concorrenza, rifiuti ed eventi prima del rilascio.

## Registro dei test

Per ogni run registrare seed, programma, strategia, giorno finale, insolvenza, autonomia minima, acquisti, staff, ore di proposal, invii/esiti per size, rifiuti consecutivi, intervalli fra pubblicazioni e giorni delle milestone. Separare risultati automatici e osservazioni umane. Dopo ogni blocco aggiornare qui parametri, risultati, problemi e decisione sul passaggio successivo.

### Blocco 1

La prima implementazione ha superato 154 verifiche finanziarie e 53 verifiche UI in headless, oltre alle regressioni di progressione e interfaccia. La verifica grafica include fullscreen e ritorno alla finestra. I risultati definitivi dopo la revisione sono riportati sotto.

Con staff controllato, prima lettera a evidence minima e $3.000 riservati ad acquisti, 24 run su 12 seed hanno superato il giorno 75. Il grant introduttivo arriva al giorno 20. Le varianti forzano fino a due rifiuti ordinari: in nove delle dodici varianti entrambi gli invii avvengono entro il giorno 75, nelle altre solo uno. Cassa finale delle run prudenti circa $7.800–$20.350; autonomia minima circa 23,5–43,7 giorni. Questo è un controllo automatico dell'avvio, non una misura della difficoltà percepita o del completamento dei tre programmi.

La review introduttiva è stata ridotta da cinque giorni a uno: con la prima lettera a 18 evidence, la review lunga portava il premio al giorno 24. Le review ordinarie restano 5/8/12 giorni.

### Feedback umano e revisione del bilanciamento

Il primo playtest dell'utente segnala insolvenza attorno al giorno 65 dopo un'espansione moderata, un esperimento e un ricercatore aggiuntivi. Una seconda proposal era pronta, ma il prossimo bando arrivava dopo l'esaurimento della cassa. Il caso è stato riprodotto e corretto nella revisione descritta sotto. Prima del blocco 2 resta da verificare sul campo che un'espansione moderata possa ricevere il successivo esito e recuperare dopo un rifiuto. Il caso con rifiuti consecutivi deve comunque conservare pressione finanziaria.

Stato storico al termine del blocco 1: nessun blocco successivo era ancora autorizzato. L'11 settembre l'utente ha autorizzato i blocchi 2 e 3.


### Ribilanciamento dopo il feedback del giorno 65

Il salvataggio segnalato mostra al giorno 59 una cassa di $3.893, costi di $760/giorno e contributo di $136. Il burn netto di $624 lascia circa 6,24 giorni. La proposal small da 96 ore è pronta. L'introduttivo aveva prenotato il calendario small fino al giorno 61; il passaggio alla prima milestone riallineava quella data al giorno 81. Era una penalità della progressione che impediva una risposta utile del giocatore.

Correzioni implementate:

- Grant iniziale da $24.000 a $30.000 per nuove partite.
- Small da $12.000 a $14.000; lavoro minimo da 96 a 64 ore. Con energia e spostamenti, le 96 ore originarie occupavano troppo tempo per sostenere il calendario proposto.
- Introduttivo separato dai bandi ordinari; gli small restano ogni 20 giorni anche dopo le milestone.
- Nessun ricalcolo retroattivo che rinvii un bando già accessibile.
- Avviso nelle proposal pronte e in review se la cassa non copre il tempo fino al primo esito possibile.
- Compatibilità con i primi salvataggi v5: contanti e premi storici restano invariati; si elimina l'attesa small derivata dal solo introduttivo. Le bozze già aperte conservano il lavoro richiesto; le nuove usano 64 ore. Le review introduttive già inviate conservano il tempo residuo. I file v4 restano separati.

Nella riproduzione dello stato segnalato la proposal può essere inviata al giorno 59. Forzando un'accettazione soltanto nel test, l'esito arriva al giorno 64 con circa $14.773 rimasti. Questo dimostra che il calendario non impedisce più di ricevere l'esito; nel gioco l'accettazione resta casuale. Il salvataggio originale è stato verificato in sola lettura, senza aggiungere fondi o sovrascriverlo.

Una matrice di 30 run aggiunge al giorno 25 un ricercatore, uno strumento, un letto e una scrivania. Ritarda volontariamente la prima proposal fino al giorno 30. Include 12 seed con ottica, 12 con materiali e 6 varianti materiali con primo rifiuto forzato. La strategia dà priorità alle revisioni dopo un rifiuto e dedica entrambi i ricercatori alle proposal quando l'autonomia scende sotto 20 giorni. Non riduce i costi dopo l'espansione.

Risultati: 28/30 run superano il giorno 75; 12/12 con ottica, 11/12 con materiali, 5/6 con primo rifiuto forzato. Tutte ricevono il primo esito ordinario entro i giorni 51–54. Le due run perse condividono il seed 6 e ricevono tre rifiuti ordinari prima dell'insolvenza al giorno 67. Non sono 30 osservazioni indipendenti della probabilità di fallimento: sono scenari di regressione con seed e comportamenti controllati. Il dettaglio riproducibile è in [playtest-block1.json](playtest-block1.json), generato da `tests/test_economy_balance.gd`.

Da verificare nella prossima sessione umana: tempo perso a cercare il bando corretto, frequenza dei cambi Activity, comprensione degli avvisi, reazione possibile a un primo rifiuto, utilità dei grant standard e leggibilità del layout compatto. Il completamento dei tre programmi con questa economia non è ancora stato validato in partite complete.


### Verifica finale del blocco 1

Godot 4.7.2, tutti i controlli passati:

| Suite | Controlli |
| --- | ---: |
| Simulazione esistente | 509 |
| Progressione esistente | 238 |
| Interfaccia esistente | 141 |
| Funding, calendario e salvataggi | 158 |
| Riproduzione del caso segnalato e scenari moderati | 191 |
| Interfaccia funding con rendering, fullscreen e preferenze | 62 |

La suite UI funding passa anche in headless, con 60 controlli; gli altri due verificano il fullscreen reale. Questi conteggi includono asserzioni durante scenari automatici, non soltanto test unitari indipendenti. `git diff --check` non segnala errori.

Le nuove run prudenti di `test_funding.gd`, con 64 ore small, superano tutte il giorno 75: cassa finale circa $13.846–$42.243 e autonomia minima circa 43,5–61,8 giorni. L'espansione estrema senza prima pubblicazione termina al giorno 27. I valori della prima implementazione sopra restano come confronto storico.

Sono state renderizzate le schermate funding e le impostazioni a 1280×800, 1440×960 e 1920×1080, alle scale 100%, 115% e 130%. A larghezza logica ridotta il layout alterna laboratorio e gestione tramite un pulsante dedicato, senza tagliare il pannello Grants. Le schermate ampie possono scorrere. Fullscreen e ritorno alla finestra funzionano; le preferenze di scala persistono. La rilettura visiva e il playtest umano delle altre schermate alle scale alte restano nella checklist della prossima sessione.

Per usare le correzioni, riavviare la copia del gioco in esecuzione. Il salvataggio v5 del playtest può essere ricaricato con la sua cassa originale e la prima proposal small subito inviabile. Per provare il grant iniziale da $30.000 occorre una nuova partita. Questo era lo stato della versione 5; i blocchi 2 e 3 sono ora implementati nella versione 6.

### Verifica dei blocchi 2 e 3

I test comprendono 67 controlli dedicati a supervisione, usura produttiva, manutenzione, spostamenti, avvii, espansioni e migrazione, 16 controlli UI con rendering e 42 controlli su avvii e confronti economici. Passano anche simulazione, progressione, UI, funding e scenari di espansione moderata. Le asserzioni ripetute sui percorsi variano di numero con i nuovi tragitti.

Nei 18 avvii controllati, sei seed per programma, le tempistiche di prima pubblicazione, milestone 1, introduttivo e prima review standard coincidono fra le tre branche a parità di seed. Il benchmark iniziale deterministico raggiunge 18 evidence al giorno 4 per tutte e tre. Questi test non misurano la durata di una partita umana completa.

A $800/giorno di stipendi, con quattro banchi e 30 giorni senza paper o grant, i confronti producono:

| Squadra | Evidence | Study point | Usura totale |
| --- | ---: | ---: | ---: |
| 6 PhD + 1 ricercatore | 490,6 | 100,3 | 96,5 |
| 4 PhD + 2 ricercatori | 450,5 | 200,5 | 61,5 |
| 4 ricercatori | 357,7 | 138,8 | 18,8 |

Le routine sono dichiarate nel report: i ricercatori raccolgono e analizzano nella squadra senza PhD. Il confronto mostra compromessi, non dimostra una strategia ottimale universale. I numeri della tabella sono storici della v6; il [report avvii e squadre](playtest-blocks23-programs.json) viene aggiornato dai test della versione corrente.

La matrice di espansione moderata del blocco 1, aggiornata per pubblicare nel campo iniziale effettivo, supera il giorno 75 in 29/30 run. Il [report economico](playtest-blocks23-economy.json) contiene ora la verifica della versione 7 riportata sotto. Il report originale del blocco 1 rimane come riferimento storico.

Da verificare giocando: interpretazione del bonus applicato il giorno successivo, frequenza dei cambi di supervisore, spostamenti su touchpad, costo delle due ali in endgame e compatibilità del browser su itch.io. Non sono implementati formazione, ospiti, eventi a scelta o rivali.


### Versione 7: priorità Activity, ambientazione e audio

Su richiesta del playtest, Papers first e Grants first scelgono l'ordine dei due lavori. Se il primo non è disponibile si passa al secondo, poi allo studio. Si completano prima le ore di supervisione; le frazioni d'ora residue passano al lavoro successivo. Solo i ricercatori scrivono grant. Study e Maintain rimangono scelte esplicite. Creazione e invio delle proposal restano azioni del giocatore. La priorità si modifica sia in People sia in Grants e viene salvata per persona.

Le nuove partite mantengono 28×20 celle ma partono con sala strumenti, ufficio e sala comune collegate da un corridoio. Porte ampie, piante, scaffali, lavagne e cucina danno forma agli spazi; gli arredi funzionali restano spostabili e le ali acquistabili come prima. Muri e decorazioni fisiche sono rispettati da piazzamento e pathfinding. I salvataggi v5/v6 conservano la pianta aperta per evitare che nuovi muri coprano gli oggetti. Lo schema 7 registra la pianta; la prima sovrascrittura salva una copia della vecchia versione.

Musica ambient CC0 e suoni di interazione/esito, inclusi nella build. Volumi separati in Settings, zero per silenziare, preferenze persistenti. Avvio al primo gesto dell'utente per il browser. Crediti e sorgenti in [assets/audio/CREDITS.md](../assets/audio/CREDITS.md).

UI abbreviata in People, Grants, Build, Papers, programmi, albero tecnologico e impostazioni. Costi, scadenze, condizioni di blocco e avvisi finanziari restano visibili; tratti, formule e dettagli sono nei tooltip. La guida completa rimane disponibile.

Verifiche: 55 controlli dedicati, anche con rendering, più regressioni passate. La matrice economica sopravvive fino al giorno 75 in 30/30 scenari di espansione moderata. I 18 avvii mantengono equivalenza tra programmi a parità di seed. Questi test non misurano il comfort d'ascolto né la difficoltà di una partita completa.

Nel playtest controllare:
- Se la priorità scelta è comprensibile e riduce i cambi manuali durante le review.
- Se un grant prioritario ritarda troppo i paper quando la copertura PhD assorbe Activity.
- Congestione delle porte con 8–12 persone e percorsi dopo lo spostamento dei mobili.
- Utilità dello spazio libero e dei costosi ampliamenti dopo la terza milestone.
- Volume e ripetitività della musica dopo 20 minuti, chiarezza degli effetti e persistenza del mute nel browser.
- Visibilità dei tooltip dei tratti, formule dei grant e requisiti delle tecnologie alle scale 100–130%.


### Versione 8: asset e leggibilità

Furniture Kit, UI Pack e Cursor Pack di Kenney, tutti CC0, danno al laboratorio uno stile più illustrato: arredi in PNG, pavimenti chiari, controlli in rilievo, cornici e puntatori dedicati. I dettagli dei pacchetti e le licenze sono in [crediti grafici](../assets/kenney/CREDITS.md). L'economia e la geometria di piazzamento rimangono quelle della versione 7; questo aggiornamento non introduce il blocco 4.

Controllare durante il playtest:

- Riconoscimento di scrivanie, letti, strumenti e porte a zoom Fit e durante il pan.
- Corrispondenza tra cursore, cella evidenziata e oggetto piazzato, anche con UI al 130%.
- Leggibilità dei titoli, del quaderno, delle barre di avanzamento e dei tooltip.
- Distinzione fra pulsanti attivi, selezionati, premuti e disabilitati.
- Avvio della nuova build nel browser, senza risorse mancanti, e corretta visualizzazione delle partite salvate.
