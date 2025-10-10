# SLIPS – Swift Logical Inference Production System

Benvenuta/o in SLIPS, una traduzione fedele e moderna in Swift 6 del motore CLIPS (v6.42). 

Obiettivo del progetto:
- Tradurre integralmente il codice sorgente C di CLIPS in Swift 6.2
- Mantenere equivalenza funzionale e semantica (RETE, agenda, attivazioni, salience, test pattern, ecc.)
- Esporre una facciata pubblica compatibile con CLIPS

Stato attuale:
- Struttura SwiftPM pronta
- Facciata iniziale delle API disponibile (stub in evoluzione)
- Strumenti e linee guida per la traduzione

Come iniziare
- Compilare libreria + CLI: `swift build`
- Eseguire test: `swift test`
- Avviare REPL minimale: `swift run slips-cli`
- Aprire con Xcode (opzionale): `xed .`

Struttura del repository
- `clips_core_source_642/`: sorgenti C di riferimento (CLIPS 6.40)
- `clips_feature_tests_642/`: insiemi di test `.clp` di riferimento
- `Sources/SLIPS/`: codice Swift del motore in traduzione
- `Tests/SLIPSTests/`: test di equivalenza e unit test

Linee guida di traduzione (sintesi)
- Traduzione semantica fedele, non riscrittura creativa
- Ogni file `.c/.h` corrisponde a un modulo `.swift` omonimo
- Strutture C → `struct` Swift; union/type-tag → `enum` con associated values
- Macro → `static let` o computed property; condizionali → `#if os(...)`
- Puntatori/allocazione → tipi sicuri Swift; usare `Unsafe*` solo quando necessario
- Evitare force unwrap; preferire `guard let`/`if case`

API pubblica (facciata)
- `CLIPS.createEnvironment()`
- `CLIPS.load("file.clp")`
- `CLIPS.reset()`
- `CLIPS.run(limit: Int?)`
- `CLIPS.assert(fact: String)`
- `CLIPS.retract(id: Int)`
- `CLIPS.eval(expr: String) -> Value`
- `CLIPS.commandLoop()`
  - Disponibile anche come eseguibile `slips-cli` con REPL minimale

Nota sui test
- I test puntano a convalidare l’equivalenza rispetto ai file `.clp` di riferimento. In questa fase iniziale alcuni test possono essere marcati come `XCTSkip` in attesa della completa traduzione dei moduli RETE/Agenda.

Contributi
- Consulta `AGENTS.md` per le convenzioni di traduzione e la mappatura file-per-file
- Apri una issue per dubbi su semantica o naming; puntiamo a massima fedeltà a CLIPS

Licenza
- In attesa di definizione; attualmente il codice è in sviluppo aperto a contributi.
