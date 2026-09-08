# Fieldwork: progressione e piano di playtest

Stato: blocco 1 implementato e ribilanciato dopo il primo feedback umano. I blocchi successivi attendono il playtest e una nuova richiesta di implementazione. I parametri attuali hanno verifiche automatiche; il bilanciamento richiede ulteriore playtesting umano.

Sintesi per i giocatori: [roadmap](roadmap.md). Modifiche della versione attuale: [note della versione 5](releases/iteration-5.md).

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

Supervisione assegnabile: due PhD per ricercatore, due ore Activity al giorno per studente come primo valore. PhD non supervisionati al 60% della produttività. Usura aggiuntiva per ora realmente operativa: 0,04 punti per ricercatore, 0,10 per PhD. Mostrare attese, saturazione e capacità di manutenzione. Ritarare tecnici e riparazioni dopo i test.

Controllare squadre ricche di PhD, miste e ricche di ricercatori a budget comparabile. Misurare evidence, paper, candidature, ore di manutenzione e autonomia. I PhD devono restare convenienti nella raccolta senza diventare la risposta ottimale a ogni problema.

## Blocco 3: area iniziale ed espansione

Dotazione iniziale coerente con il programma; strumenti introduttivi equivalenti per rendimento e upkeep. Rimuovere l'obbligo universale del paper di ottica nella prima milestone. Conservare gli strumenti avanzati nell'albero. Ampliamento sbloccato dalla progressione e acquistato con fondi, con spazi realmente disponibili per strumenti, letti e scrivanie. Estendere la guida.

Controllare tutti e tre gli avvii: prima pubblicazione, milestone 1, primo standard grant. Nessuna branca deve subire una penalità economica involontaria. L'ampliamento deve offrire nuove possibilità senza essere obbligatorio subito.

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

Nessun blocco successivo autorizzato.


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

Per usare le correzioni, riavviare la copia del gioco in esecuzione. Il salvataggio v5 del playtest può essere ricaricato con la sua cassa originale e la prima proposal small subito inviabile. Per provare il grant iniziale da $30.000 occorre una nuova partita. I blocchi 2–6 restano in attesa.
