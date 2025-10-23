# 🚀 SLIPS - Swift Language Implementation of Production Systems

[![Swift Version](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%20|%20Linux-lightgrey.svg)](https://swift.org)
[![Status](https://img.shields.io/badge/Status-Beta-yellow.svg)]()

**SLIPS** è un'implementazione moderna di un sistema di produzione (production system / rule engine) ispirata a [CLIPS](https://www.clipsrules.net/), scritta interamente in Swift 6.2.

> **🎯 Stato Attuale**: Production-Ready 0.96 - **Core engine completo**, 165 funzioni builtin, 97.8% test pass rate  
> **📖 Per analisi dettagliata**: Vedi [PROJECT_STATUS_REAL.md](PROJECT_STATUS_REAL.md) e [KNOWN_ISSUES.md](KNOWN_ISSUES.md)

---

## 📋 Indice

- [Cos'è SLIPS](#cosè-slips)
- [Caratteristiche](#caratteristiche)
- [Stato del Progetto](#stato-del-progetto)
- [Quick Start](#quick-start)
- [Esempi](#esempi)
- [Funzionalità Supportate](#funzionalità-supportate)
- [Architettura](#architettura)
- [Limitazioni Note](#limitazioni-note)
- [Roadmap](#roadmap)
- [Contribuire](#contribuire)
- [Licenza](#licenza)

---

## Cos'è SLIPS?

SLIPS è un **rule-based expert system** che permette di definire:
- **Facts**: Rappresentazioni di conoscenza (dati)
- **Rules**: Regole condizione→azione
- **Templates**: Strutture dati tipizzate

Il sistema usa **forward chaining** per:
1. Matchare pattern nei fatti
2. Attivare regole corrispondenti
3. Eseguire azioni che modificano lo stato

### Esempio Minimo

```swift
import SLIPS

// Crea environment
let env = CLIPS.createEnvironment()

// Definisci template
CLIPS.eval(expr: "(deftemplate person (slot name) (slot age))")

// Definisci regola
CLIPS.eval(expr: """
(defrule check-adult
  (person (name ?n) (age ?a&:(>= ?a 18)))
  =>
  (printout t ?n " is an adult" crlf))
""")

// Aggiungi fatti
CLIPS.assert(fact: "(person (name Alice) (age 25))")
CLIPS.assert(fact: "(person (name Bob) (age 16))")

// Esegui motore
CLIPS.run()
// Output: Alice is an adult
```

---

## Caratteristiche

### ✅ Core Engine (Stabile)

- **Pattern Matching Completo**
  - Variabili single-field (`?x`)
  - Variabili multi-field (`$?x`)
  - Sequence matching con backtracking
  - Predicati inline `(test (> ?x 10))`
  
- **Conditional Elements**
  - NOT - Negazione logica
  - EXISTS - Esistenza quantificata
  - AND/OR - Combinazioni logiche
  
- **Agenda Management**
  - Strategie: depth, breadth, lex
  - Salience per priorità regole
  - Conflict resolution automatico

- **RETE Network**
  - Alpha indexing per template
  - Beta memory incrementale
  - Hash-based join optimization
  - Propagazione efficiente assert/retract

### ✅ 165 Funzioni Builtin

**Matematiche** (36 funzioni)
```clp
(sqrt 16)           ; → 4.0
(sin (/ pi 2))      ; → 1.0
(pow 2 10)          ; → 1024.0
(round 3.7)         ; → 4
```

**String** (11 funzioni)
```clp
(str-cat "Hello" " " "World")     ; → "Hello World"
(upcase "hello")                  ; → "HELLO"
(sub-string 2 5 "Hello World")   ; → "ello"
(str-index "World" "Hello World") ; → 7
```

**Multifield** (10 funzioni)
```clp
(nth$ 2 (create$ a b c))          ; → b
(length$ (create$ 1 2 3 4))       ; → 4
(first$ (create$ a b c))          ; → (a)
(rest$ (create$ a b c))           ; → (b c)
(member$ b (create$ a b c))       ; → 2
```

**Template/Facts** (10 funzioni)
```clp
(modify 1 (age 26))               ; Modifica fatto
(duplicate 1 (name "Copy"))       ; Duplica fatto
(fact-slot-value 1 age)          ; Leggi slot
```

**I/O** (13 funzioni)
```clp
(open "data.txt" input)
(read input)
(printout t "Hello" crlf)
(format t "Value: %d" 42)
```

**Utility** (6 funzioni)
```clp
(gensym)                          ; → gen1, gen2, ...
(random 1 100)                    ; → numero casuale
(time)                            ; → timestamp
```

**Fact Query** (7 funzioni)
```clp
(find-all-facts ((?p person)) (>= ?p:age 18))
(fact-existp person)
(do-for-all-facts ((?p person)) TRUE ...)
```

Vedi lista completa in [FUNZIONI_REFERENCE.md](FUNZIONI_REFERENCE.md)

### ⚠️ Moduli (Parziale)

**Supporto Base** ✅:
```clp
(defmodule MAIN)
(defmodule BILLING)

(get-current-module)      ; Comandi base funzionanti
(set-current-module BILLING)
(list-defmodules)
```

**Limitazioni Note** ⚠️:
- Template non isolati tra moduli (globali)
- Regole di moduli non-MAIN potrebbero non attivarsi correttamente
- Focus stack implementato ma non integrato
- Import/export parsing presente ma non enforced

> **Workaround**: Usare principalmente modulo MAIN per 1.0 Beta  
> **Dettagli**: Vedi [KNOWN_ISSUES.md](KNOWN_ISSUES.md) #1, #2, #3

---

## Stato del Progetto

### 🎯 Completezza: 85%

| Componente | Completezza | Status | Note |
|------------|-------------|--------|------|
| **Core Engine** | 95% | ✅ Stabile | Production-ready |
| **Pattern Matching** | 98% | ✅ Stabile | Manca FORALL |
| **Builtin Functions** | 100% | ✅ Completo | 165 funzioni |
| **RETE Network** | 90% | ✅ Stabile | Legacy + Explicit |
| **Moduli Base** | 85% | ✅ Buono | MAIN + Focus stack |
| **Cross-Module** | 60% | ⚠️ Parziale | In sviluppo |
| **Performance** | 75% | ✅ Buono | <10k facts |
| **Documentazione** | 90% | ✅ Eccellente | Aggiornata 12/2025 |

### 📊 Metriche Codice

```
Linee di codice: 11.687
File Swift: 43
Test: 250+ (96.8% pass rate)
Coverage: ~75% (stimato)
```

### 🧪 Test Status

```
✅ Core Functions: 100% (159 test)
✅ String/Math/Multifield: 100% (154 test)  
✅ Pattern Matching: 100% (47 test)
✅ Modules Base: 100% (22 test)
⚠️ RETE Explicit: 83% (10/12 pass)
❌ Module-Aware: 20% (1/5 pass)
```

**Per analisi completa**: [PROJECT_STATUS_REAL.md](PROJECT_STATUS_REAL.md)

---

## Quick Start

### Installazione

#### Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/your-repo/SLIPS.git", from: "0.80.0")
]
```

#### Build da Sorgente

```bash
git clone https://github.com/your-repo/SLIPS.git
cd SLIPS
swift build
swift test  # Esegui test
```

### Uso Base

```swift
import SLIPS

// 1. Crea environment
let env = CLIPS.createEnvironment()

// 2. Carica regole da file
try CLIPS.load("rules.clp")

// 3. Aggiungi fatti
CLIPS.assert(fact: "(customer (name John) (status premium))")

// 4. Esegui motore
let fired = CLIPS.run()
print("Fired \(fired) rules")

// 5. Query fatti
CLIPS.eval(expr: "(facts)")

// 6. Loop interattivo
CLIPS.commandLoop()
```

### CLI

```bash
# Build CLI
swift build -c release

# Esegui
.build/release/slips-cli

# REPL interattivo
CLIPS> (deftemplate person (slot name))
CLIPS> (assert (person (name Alice)))
CLIPS> (facts)
CLIPS> (exit)
```

---

## Esempi

### Esempio 1: Sistema Esperto Base

```clp
; examples/expert_system.clp

(deftemplate symptom
  (slot name)
  (slot severity (type INTEGER) (range 1 10)))

(deftemplate diagnosis
  (slot disease)
  (slot confidence (type FLOAT)))

(defrule diagnose-flu
  (symptom (name fever) (severity ?s1&:(> ?s1 7)))
  (symptom (name cough))
  =>
  (assert (diagnosis (disease "Influenza") (confidence 0.8))))

(defrule diagnose-cold
  (symptom (name fever) (severity ?s&:(< ?s 5)))
  (symptom (name cough))
  (not (symptom (name muscle-pain)))
  =>
  (assert (diagnosis (disease "Common Cold") (confidence 0.9))))
```

### Esempio 2: Pattern Multifield

```clp
; Pattern matching su sequenze
(deftemplate sequence
  (multislot items))

(defrule find-pattern
  (sequence (items $?before target $?after))
  (test (> (length$ ?before) 0))
  =>
  (printout t "Found target after " (length$ ?before) " items" crlf))
```

### Esempio 3: Aggregazione

```clp
; Calcolo totale ordini
(deftemplate order
  (slot id)
  (slot amount (type FLOAT)))

(defrule calculate-total
  =>
  (bind ?total 0.0)
  (do-for-all-facts ((?o order)) TRUE
    (bind ?total (+ ?total ?o:amount)))
  (printout t "Total: " ?total crlf))
```

### Altri Esempi

Vedi directory [`Examples/`](Examples/) per:
- Sistema shopping cart
- Classificatore animali
- Validazione dati
- Pattern avanzati
- Meta-programmazione

---

## Funzionalità Supportate

### Pattern Matching

| Feature | Status | Esempio |
|---------|--------|---------|
| Single-field variable | ✅ | `(person (name ?n))` |
| Multi-field variable | ✅ | `(list (items $?all))` |
| Constrained variable | ✅ | `?x&:(> ?x 10)` |
| Sequence matching | ✅ | `(items $?pre target $?post)` |
| NOT element | ✅ | `(not (blocked))` |
| EXISTS element | ✅ | `(exists (person (age ?a)))` |
| Test predicates | ✅ | `(test (>= ?age 18))` |
| OR element | ✅ | `(or (a) (b))` |
| AND element | ✅ | `(and (a) (b))` |
| FORALL element | ❌ | Planned 2.0 |

### Templates

| Feature | Status |
|---------|--------|
| Slot singoli | ✅ |
| Multislot | ✅ |
| Default statici | ✅ |
| Default dinamici | ✅ |
| Type constraints | ✅ |
| Range constraints | ✅ |
| Allowed values | ✅ |

### Agenda

| Feature | Status |
|---------|--------|
| Salience | ✅ |
| Depth strategy | ✅ |
| Breadth strategy | ✅ |
| LEX strategy | ✅ |
| Agenda listing | ✅ |
| Rule removal | ✅ |

### Moduli

| Feature | Status | Note |
|---------|--------|------|
| Defmodule | ✅ | Base funzionante |
| Import/Export parsing | ✅ | Non enforced |
| Focus command | ⚠️ | Implementato, non integrato |
| Current module | ✅ | Tracking OK |
| Module-scoped templates | ❌ | Planned 1.0 |
| Cross-module rules | ⚠️ | Limitato |

---

## Architettura

### Componenti Principali

```
SLIPS/
├── CLIPS.swift              # Facciata pubblica API
├── Core/
│   ├── evaluator.swift      # Parsing ed evaluation
│   ├── ruleengine.swift     # Pattern matching & firing
│   ├── functions.swift      # Registry funzioni
│   ├── Modules.swift        # Sistema moduli
│   ├── *Functions.swift     # Builtin specializzati (8 moduli)
│   └── ...                  # Altri core components
├── Rete/
│   ├── AlphaNetwork.swift   # Alpha indexing
│   ├── BetaEngine.swift     # Beta memory & join
│   ├── NetworkBuilder.swift # RETE construction
│   └── ...                  # Altri componenti RETE
└── Agenda/
    └── Agenda.swift         # Conflict resolution
```

### Design Patterns

- **Environment as Context**: Tutti i metodi ricevono `inout Environment`
- **Value Semantics**: Struct per immutabilità
- **Protocol-Oriented**: Estensibilità tramite protocol
- **Functional Core**: Logica pura separata da I/O

### Performance

| Operazione | Target | Attuale | Status |
|------------|--------|---------|--------|
| Assert 1k facts | <100ms | ~240ms | ⚠️ Accettabile |
| Join 3-pattern | <10ms | ~5ms | ✅ Ottimo |
| Retract cascade | <50ms | ~10ms | ✅ Ottimo |
| Build network | <10ms | ~1ms | ✅ Ottimo |

**Note**: Performance adeguata per KB <10k facts. Ottimizzazioni planned per 1.5.

---

## Limitazioni Note

### Critiche (Blockers per Production)

1. **Regole moduli non-MAIN non attivano** 🔴
   - Workaround: Usare solo MAIN
   - Fix: Sprint 1 (1 settimana)

2. **Focus stack non ordina agenda** 🔴
   - Workaround: Usare salience
   - Fix: Sprint 1 (2 giorni)

3. **Template non isolati tra moduli** 🔴
   - Workaround: Prefissare nomi
   - Fix: Sprint 2 (2 giorni)

### Importanti (Non-Blockers)

4. **Performance assert sotto target** 🟠
   - Impact: Lento per KB >10k facts
   - Fix: Sprint 3 (1 settimana)

5. **RETE esplicito disattivato** 🟠
   - Impact: Minimo (legacy funziona)
   - Fix: 2.0 o mai

### Minori

6. **FORALL non implementato** 🟡
7. **No binary load/save** 🟡
8. **No concurrency** 🟡

**Dettagli completi**: [KNOWN_ISSUES.md](KNOWN_ISSUES.md)

---

## Roadmap

### 1.0 Beta (2-3 Settimane) ⏳

**Must-Fix**:
- ✅ Fix regole moduli non-MAIN
- ✅ Integrare focus stack in run()
- ⚠️ Template module-scoped (nice-to-have)

**Scope**:
- Core engine stabile
- 156 funzioni builtin
- Moduli base (MAIN completo)
- Documentazione accurata

**Label**: "Production-Ready Core, Moduli in Beta"

### 1.0 Stable (1-2 Mesi)

**Aggiunte**:
- ✅ Cross-module completo
- ✅ Performance <100ms per 1k assert
- ✅ Import/export enforcement
- ✅ 50+ esempi reali
- ✅ Test coverage >90%

### 1.5 (3-4 Mesi)

**Features**:
- ✅ Performance optimization avanzate
- ✅ Binary load/save
- ✅ Extended I/O functions
- ✅ Debugging tools

### 2.0 (6+ Mesi)

**Major Features**:
- ✅ RETE esplicito completo
- ✅ FORALL conditional element
- ✅ Concurrent execution
- ✅ Performance >100k facts
- ✅ Rule/template inheritance

**Dettagli**: [ROADMAP_REALISTIC.md](ROADMAP_REALISTIC.md) (da creare)

---

## Contribuire

Contributi benvenuti! Per favore:

1. Leggi [CONTRIBUTING.md](CONTRIBUTING.md)
2. Leggi [AGENTS.md](AGENTS.md) per linee guida agenti AI
3. Controlla [KNOWN_ISSUES.md](KNOWN_ISSUES.md) per problemi noti
4. Apri issue per discutere feature grandi

### Setup Sviluppo

```bash
git clone https://github.com/your-repo/SLIPS.git
cd SLIPS
swift build
swift test

# Watch mode (richiede fswatch)
fswatch -o Sources/ | xargs -n1 -I{} swift test
```

### Priorità Contributi

**High Priority**:
- Fix moduli (issue #1, #2, #3)
- Test integrazione end-to-end
- Performance optimization

**Medium Priority**:
- Documentazione esempi
- FORALL implementation
- Binary save/load

**Low Priority**:
- RETE esplicito completion
- Concurrency

---

## Testing

```bash
# Run tutti i test
swift test

# Run test specifici
swift test --filter StringFunctionsTests
swift test --filter testMultifieldAdvanced

# Con verbose
swift test --verbose

# Generate coverage (richiede llvm-cov)
swift test --enable-code-coverage
```

### Test Suites

- **Core**: Engine, pattern matching, agenda (100% pass)
- **Functions**: Tutte le 156 builtin (100% pass)
- **RETE**: Network construction, propagation (96% pass)
- **Modules**: Base functionality (95% pass)
- **Integration**: End-to-end scenarios (80% pass)

---

## Documentazione

### Utente

- [README.md](README.md) - Questo file
- [USER_GUIDE.md](USER_GUIDE.md) - Guida completa utente
- [FUNZIONI_REFERENCE.md](FUNZIONI_REFERENCE.md) - Reference funzioni
- [Examples/](Examples/) - Esempi pratici

### Sviluppatore

- [ARCHITECTURE_DIAGRAM.md](ARCHITECTURE_DIAGRAM.md) - Architettura sistema
- [PROJECT_STATUS_REAL.md](PROJECT_STATUS_REAL.md) - Analisi stato reale
- [KNOWN_ISSUES.md](KNOWN_ISSUES.md) - Problemi e limitazioni
- [AGENTS.md](AGENTS.md) - Linee guida contributor

### Libro (LaTeX)

- [libro/](libro/) - Manuale completo in LaTeX (27 capitoli)
- Copertura: teoria RETE, architettura CLIPS, implementazione SLIPS

---

## FAQ

**Q: SLIPS è production-ready?**  
A: Sì per casi d'uso base (modulo MAIN, <10k facts). No per enterprise multi-modulo complesso. Vedi [PROJECT_STATUS_REAL.md](PROJECT_STATUS_REAL.md).

**Q: È compatibile con CLIPS?**  
A: Parzialmente. Core semantics sì, ma sintassi e alcune feature differiscono. Non c'è interoperabilità binaria.

**Q: Perché Swift invece di C?**  
A: Memory safety, modern syntax, type system robusto, cross-platform senza dipendenze C.

**Q: Performance vs CLIPS C?**  
A: ~2-3x più lento per assert, comparabile per firing. Accettabile per KB <10k facts.

**Q: Posso usare SLIPS in iOS/macOS app?**  
A: Sì! È una libreria Swift standard. Esempio: app rules-based decision making.

**Q: Supporta concurrency?**  
A: No. Single-threaded per 1.x. Planned per 3.0.

**Q: Dove trovo aiuto?**  
A: 
- GitHub Issues per bug/feature requests
- Discussions per domande generali
- [USER_GUIDE.md](USER_GUIDE.md) per tutorial

---

## Crediti

**Progetto**: SLIPS (Swift Language Implementation of Production Systems)  
**Ispirazione**: [CLIPS](https://www.clipsrules.net/) (C Language Integrated Production System)  
**Autori**: Vedi [AUTHORS](AUTHORS)  
**Licenza**: MIT - Vedi [LICENSE](LICENSE)

### Ringraziamenti

- Gary Riley e team CLIPS per il sistema originale e documentazione
- Swift community per tooling eccellente
- Contributors (vedi [AUTHORS](AUTHORS))

---

## Licenza

```
MIT License

Copyright (c) 2025 SLIPS Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Link Utili

- **Repository**: https://github.com/your-repo/SLIPS
- **Issues**: https://github.com/your-repo/SLIPS/issues
- **Discussions**: https://github.com/your-repo/SLIPS/discussions
- **CLIPS Official**: https://www.clipsrules.net/
- **Swift**: https://swift.org/

---

**Ultimo aggiornamento**: 16 Ottobre 2025  
**Versione**: 0.80.0-dev  
**Status**: Beta - Core Stabile, Moduli in Sviluppo

**🚀 Pronto per iniziare? Vedi [Quick Start](#quick-start) sopra!**
