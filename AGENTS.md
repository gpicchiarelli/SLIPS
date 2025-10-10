Indicazioni per agenti e contributor

Ambito
- Questo file vale per l’intero repository.
- Le istruzioni si applicano a ogni file generato o modificato.

Stile e filosofia
- Traduzione semantica fedele del codice C di CLIPS (v6.4.2) in Swift 6.2.
- Non semplificare algoritmi (RETE, agenda, join, salience, test di pattern).
- Mantieni nomi, responsabilità e flusso logico equivalenti.

Mappatura file-per-file
- Ogni file `.c` o `.h` sotto `clips_core_source_642/` deve corrispondere a un file `.swift` omonimo sotto `Sources/SLIPS/` (o sottocartelle coerenti).
- Le macro vengono tramutate in `static let` o computed properties.
- Le `struct` C diventano `struct` Swift; le union/type-tag diventano `enum` Swift con associated values.

Sicurezza Swift
- Evitare force unwrap; preferire `guard let` e pattern matching.
- Usare `Array`, `Dictionary`, `ManagedBuffer` per sostituire allocazioni manuali quando possibile.
- Utilizzare `Unsafe*` solo dove strettamente necessario per performance o semantica.

API pubblica da rispettare
- `CLIPS.createEnvironment()`, `CLIPS.load(_:)`, `CLIPS.reset()`, `CLIPS.run(limit:)`, `CLIPS.assert(fact:)`, `CLIPS.retract(id:)`, `CLIPS.eval(expr:)`, `CLIPS.commandLoop()`
- La facciata deve rimanere stabile; l’implementazione interna può evolvere durante la traduzione.

Testing
- Ogni modulo tradotto aggiunge o estende test in `Tests/SLIPSTests/`.
- Usare i file `.clp` in `clips_feature_tests_642/` come riferimento (golden) finché non viene fornita una cartella `clips_core_tests_642/` distinta.
- È accettabile marcare alcuni test `XCTSkip` fino al completamento dei moduli RETE/Agenda.

Documentazione
- Scrivere commenti e README in italiano, citando dove utile i nomi originali delle funzioni C per facilitarne il tracciamento (`git blame`/`git log`).

