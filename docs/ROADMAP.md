# Roadmap di Traduzione SLIPS

Obiettivo: traduzione fedele del core CLIPS (v6.4.2) in Swift 6.2.

Fasi principali
- Ambiente e runtime base (envrnmnt.c) → `Environment.swift`
- Memoria/allocatori e userdata (memalloc.h, userdata.c) → `Memory.swift`, `UserData.swift`
- Router I/O e diagnostica (router.h, fileutil.c, watch.h) → `IO.swift`, `Watch.swift`
- Espressioni e funzioni (expressn.c, prcdrfun.c, miscfun.c) → `Expressions.swift`, `Procedures.swift`
- Simboli e stringhe (symblcmp.c, strngrtr.c) → `Symbols.swift`
- Costrutti (constrct.h, cstrcpsr.c, constrnt.c) → `Constructs.swift`, `Constraints.swift`
- Fatti e template (fact*.c/.h, deftemplate) → `Facts.swift`, `Templates.swift`
- Rete RETE (pattern.c, drive.c, join*, beta*, alpha*) → `Rete.swift`, `Nodes/`
- Agenda e attivazioni (crstrtgy.c, reorder.c) → `Agenda.swift`
- Oggetti (classe*.c, obj*.c, ins*.c) → `Objects.swift`

Linee guida operative
- Traduzione 1:1 per file; mantenere nomi e semantica.
- Aggiungere test XCTest per ogni modulo tradotto usando `.clp` esistenti.
- Documentare in testa a ogni file Swift la fonte originale (file C, funzioni).

Criteri di completamento
- Compilazione `swift build` su macOS 15 / Swift 6.2
- Test chiave verdi: assert/retract, deftemplate, not/exists, salience, watch
- Esecuzione `CLIPS.commandLoop()` opzionale ma consigliata a fine progetto

Stato avanzamento (aggiornato Ottobre 2025)
- ✅ Exists unario (RETE): parsing/IR completo, computeLevels + delta assert, retract parziale; attivazioni immediate per regole unarie senza vincoli
- ✅ NOT delta ottimizzato: propagazione incrementale senza full recompute (hash join + prefiltri costanti)
- ✅ Join incrementale: Beta engine con confronto tra backtracking classico e propagazione incrementale
- ✅ Attivazioni via RETE: abilitate di default su regole stabili (join-check attivo di default); fallback naïve limitato ai soli casi non coperti
- 🚧 RETE completo: nodi espliciti alpha/beta/join in fase di sviluppo
