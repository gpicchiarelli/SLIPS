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
- ✅ **FASE 1**: RETE Esplicita (85%) - Nodi alpha/beta/join, NetworkBuilder, Propagation
- ✅ **FASE 2**: Pattern Avanzati (100%) - Multifield $?x, OR/AND CE completi
- ✅ **FASE 3**: Moduli & Focus (95%) - Defmodule, import/export, focus stack, comandi
- ✅ Exists unario: parsing/IR completo, computeLevels + delta assert
- ✅ NOT delta ottimizzato: propagazione incrementale senza full recompute
- ✅ Join incrementale: Beta engine con confronto tra backtracking e propagazione
- ✅ Attivazioni via RETE: abilitate di default su regole stabili
- 🚧 DriveEngine helpers: 2 test pending per regole 3+ pattern
- ⏳ **FASE 4**: Console & Polish (0%) - UDF estese, docs, release 1.0

**Metriche**: 8.046 LOC, 91 test (97.8% pass), 70% CLIPS coverage

## Funzionalità Completate ✅

- ✅ **RETE Algorithm**: Alpha/Beta network, join nodes, incremental propagation
- ✅ **Pattern Matching**: Single field, multifield ($?x), sequences
- ✅ **Conditional Elements**: NOT, EXISTS, OR, AND (implicit)
- ✅ **Deftemplate**: Con constraints, defaults, multifield slots
- ✅ **Defrule**: Pattern matching, salience, test CE
- ✅ **Deffacts**: Definizione e reset
- ✅ **Defmodule**: Import/export, focus stack, module commands
- ✅ **Agenda**: 4 strategie (depth, breadth, simplicity, complexity)
- ✅ **Built-in Functions**: 87+ funzioni (math, logic, facts, rules, etc.)
- ✅ **Watch System**: facts, rules, activations, rete
- ✅ **Router I/O**: Sistema I/O customizzabile

## Gap Rimanenti verso CLIPS 6.4.2 (30%)

- ⏳ **DriveEngine helpers**: 2 helper incomplete (regole 3+ pattern)
- ❌ **Sistema Oggetti**: defclass/definstances, message passing (~20% CLIPS)
- ⏳ **UDF Estese**: String/Math/IO functions (60/150 funzioni)
- ❌ **Binary Load/Save**: (bload)/(bsave)
- ⏳ **Pretty Printing**: ppdefmodule, ppdeffacts
- ⏳ **Console Completa**: Tutti i comandi interattivi

## Dove mettere le mani subito (priorità)
1) RETE esplicita e memorie persistenti
   - Introdurre nodi espliciti allineati a CLIPS: `pattern/alpha node`, `join node` (con hashed alpha + beta), `beta memory`, `end/activations`.
   - Persistenza per livello: `env.rete.betaLevels[rule][level]` già scaffolata → consolidare uso in assert/retract con propagazione completa e stabile.
   - Propagazione delta assert/retract completa: calcolo bucket hash per fatti e token, add/remove deduplicato via chiavi stabili.
   - Definizione chiavi join 1:1: variabili bound, costanti, wildcard, con short‑circuit su costanti come in CLIPS.
   - Allineare i nomi alle funzioni C per tracciabilità: es. `PPatternNode`, `AlphaMemory`, `JoinNode`, `BetaMemory`, `DriveJoin`, `NetworkAssert`.

2) Pattern matching avanzato
   - Multifield: supporto `$?x` e `$?rest` nei template e nel matcher; binding coerenti e propagazione nei test `(test ...)`.
   - Vincoli su slot: `type`, `range`, `allowed-symbols/values`, `default/default-dynamic` applicati in fase alpha ove possibile.
   - CE composti: `(and ...)` e `(or ...)` su LHS con espansione in rete equivalente (branching esplicito come in CLIPS).

3) Oggetti e moduli
   - `defclass`, `defmessage-handler`, `definstances`: IR minimale e mapping a rete oggetti (pattern oggetto vs template/slot).
   - Message passing (`send`) e risoluzione metodo; supporto `focus`/`module` con visibilità e agenda per modulo.

4) Console e loader
   - Parser `.clp` per costrutti mancanti; comandi console: `facts`, `rules`, `agenda`, `ppdefrule`, `ppdeftemplate`, `clear`, `reset`, `focus`, `watch/unwatch`.
   - API pubblica invariata (vedi AGENTS.md); estendere solo implementazione.

5) Test golden e benchmark
   - Estendere la suite usando `clips_feature_tests_642/` come golden: casi multifield, CE composti, join profondi, salience/strategie agenda.
   - Aggiungere benchmark e profiling su reti grandi (profili CPU/memoria; bucket hit‑rate join hash; dimensione beta per livello).
   - È accettabile marcare `XCTSkip` per aree ancora in porting (oggetti/moduli) ma tracciare DoD sotto.

## Milestones e Definition of Done
M1 — RETE esplicita e stabile
- DoD: nodi alpha/join/beta persistenti; `updateGraphOnAssertDelta` e `updateGraphOnRetractDelta` coprono tutti i casi positivi; equivalenza con backtracking su suite esistente; nessun duplicate activation; ricostruzione coerente `rebuildAgenda`.
- Test: `ReteAlphaTests`, `ReteJoin*`, delta assert/retract su 2–5 livelli; golden join smoke grandi.

M2 — Pattern multifield e CE composti
- DoD: `$?` variabili segment e multifield nei match e nei test; valutazione vincoli slot completa; supporto `(and|or)` in LHS con espansione in rete; equivalenza con golden.
- Test: nuovi `.clp` per multifield, OR/AND nidificati, combinazione con `not/exists`.

M3 — Oggetti e moduli
- DoD: `defclass/definstances/send` minimi funzionanti; `module/focus` con agenda per modulo e visibilità; stampa `facts/rules` compatibile.
- Test: classi semplici, message dispatch, focus round‑robin/priorità, visibilità tra moduli.

M4 — Console, UDF e libreria
- DoD: comandi console principali; UDF comuni (stringhe, liste, numeri) portate dai file CLIPS corrispondenti; `commandLoop` interattivo stabile.
- Test: snapshot di output per `facts`, `rules`, `agenda`, `ppdef*`; golden su script `.clp` multi‑feature.

## Porting 1:1: riferimento file C → Swift (focus minimo)
- Rete: `pattern.c`, `reteutil.c`, `drive.c`, `network.c`, `rulebld.c` → `Sources/SLIPS/Rete/*` (nodi, memorie, propagazione, compilazione regole).
- Agenda: `crstrtgy.c`, `reorder.c` → `Sources/SLIPS/Agenda/Agenda.swift` (strategie, riordino attivazioni, salience).
- Costrutti/fatti/template: `constrct*.c`, `fact*.c`, `tmplt*.c` → `Core/*` e `Facts.swift`/`Templates.swift`.
- Oggetti: `class*.c`, `ins*.c`, `objrtmch.c` → `Objects.swift` e futuro `Rete/Object*`.
- Funzioni/UDF: `prcdrfun.c`, `miscfun.c`, `strngfun.c` → `Core/functions.swift` + nuovi file.

Note operative
- Mantenere naming e responsabilità equivalenti alle funzioni C per facilitare `git blame` e tracciabilità.
- Spostare calcoli su costanti in fase alpha; preferire indici hash/bucket su slot dominanti come fa CLIPS.
- Evitare force unwrap; usare `guard let` e pattern matching per sicurezza Swift (vedi AGENTS.md).

## Piano di test e benchmark
- Per ogni milestone: aggiungere test in `Tests/SLIPSTests/` citando il `.clp` golden usato.
- Aggiungere test di equivalenza RETE vs backtracking sui match (bindings + factIDs) per garantire identità semantica.
- Benchmark: reti con 10k–100k fatti, join a 3–6 livelli, distribuzione uniforme e skew; misurare throughput assert/retract e memoria beta.

## Prossimi passi concreti
- [ ] M1: Consolidare `betaLevels` e propagazione completa in `BetaEngine.updateGraphOnAssertDelta/OnRetractDelta` (per‑livello + terminale).
- [ ] M1: Introdurre struttura nodi 1:1 con CLIPS e builder della rete (compilatore) con join key canoniche.
- [ ] M2: Aggiungere supporto multifield nel matcher e nei template; estendere parser per `$?` e default multipli.
- [ ] M2: Implementare `(and|or)` in LHS con espansione del piano e nodi.
- [ ] M3: Scaffolding `Objects.swift` e stub test `XCTSkip` per `defclass/definstances/send`.
- [ ] M4: Estendere router/console con `facts/rules/ppdef*/agenda/focus` e test snapshot.
