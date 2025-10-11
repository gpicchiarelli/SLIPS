<div align="center">

# ⚡ SLIPS

### Swift Language Implementation of Production Systems

**Traduzione semantica fedele di CLIPS 6.4.2 in Swift 6.2**

[![CI](https://img.shields.io/github/actions/workflow/status/gpicchiarelli/SLIPS/ci.yml?branch=main&label=CI&logo=github)](https://github.com/gpicchiarelli/SLIPS/actions/workflows/ci.yml)
[![Deploy Pages](https://img.shields.io/github/actions/workflow/status/gpicchiarelli/SLIPS/pages.yml?branch=main&label=docs&logo=github)](https://github.com/gpicchiarelli/SLIPS/actions/workflows/pages.yml)
[![codecov](https://img.shields.io/codecov/c/github/gpicchiarelli/SLIPS?logo=codecov)](https://codecov.io/gh/gpicchiarelli/SLIPS)

[![Swift](https://img.shields.io/badge/Swift-6.2-FA7343?logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey?logo=apple)](https://github.com/gpicchiarelli/SLIPS)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen?logo=swift)](https://swift.org/package-manager/)
[![License](https://img.shields.io/github/license/gpicchiarelli/SLIPS)](LICENSE)

[![Documentation](https://img.shields.io/badge/docs-online-blue?logo=readthedocs&logoColor=white)](https://gpicchiarelli.github.io/SLIPS/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)](https://github.com/gpicchiarelli/SLIPS/pulls)
[![GitHub Stars](https://img.shields.io/github/stars/gpicchiarelli/SLIPS?style=social)](https://github.com/gpicchiarelli/SLIPS/stargazers)

[📚 Documentazione](https://gpicchiarelli.github.io/SLIPS/) • [💡 Esempi](https://gpicchiarelli.github.io/SLIPS/it/examples.html) • [🔧 API Reference](https://gpicchiarelli.github.io/SLIPS/it/api.html) • [🗺️ Roadmap](docs/ROADMAP.md)

---

</div>

## 🎯 Cos'è SLIPS?

**SLIPS** è una traduzione **file-per-file** e **semanticamente fedele** del motore CLIPS (C Language Integrated Production System) versione 6.4.2 in Swift 6.2. Non è un wrapper, né un binding: è una traduzione completa che preserva algoritmi, architettura e comportamento del sistema originale, adattandoli alla sicurezza e modernità di Swift.

### Perché SLIPS?

- 🎯 **Fedeltà Assoluta** — Traduzione 1:1 che preserva RETE, salience, strategie agenda
- 🔒 **Type Safety** — Sfrutta il sistema di tipi robusto di Swift 6.2
- 💾 **Memory Safety** — Gestione automatica della memoria senza malloc/free manuali
- ⚡ **Performance** — Algoritmo RETE con pattern matching incrementale
- 📚 **Documentazione Completa** — Ogni file Swift traccia il corrispondente file C originale
- 🧪 **Test Estensivi** — Suite di test basata sui file `.clp` di riferimento CLIPS

## 🚀 Quick Start

### Installazione

#### Swift Package Manager

Aggiungi SLIPS come dipendenza nel tuo `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/gpicchiarelli/SLIPS.git", from: "0.1.0")
]
```

#### Clonazione Repository

```bash
git clone https://github.com/gpicchiarelli/SLIPS.git
cd SLIPS
swift build
swift test
```

### Primo Programma

```swift
import SLIPS

// Crea environment
let env = CLIPS.createEnvironment()

// Definisci un template
CLIPS.eval(expr: """
(deftemplate persona
    (slot nome (type STRING))
    (slot età (type INTEGER)))
""")

// Definisci una regola
CLIPS.eval(expr: """
(defrule saluta-adulto
    (persona (nome ?n) (età ?e&:(>= ?e 18)))
    =>
    (printout t "Ciao " ?n ", sei maggiorenne!" crlf))
""")

// Asserisci fatti
CLIPS.eval(expr: "(assert (persona (nome \"Mario\") (età 25)))")
CLIPS.eval(expr: "(assert (persona (nome \"Luigi\") (età 16)))")

// Esegui le regole
let fired = CLIPS.run(limit: nil)
print("Regole eseguite: \(fired)")
```

### CLI Interattiva

```bash
swift run slips-cli
```

```
SLIPS> (deftemplate automobile (slot marca) (slot modello))
SLIPS> (assert (automobile (marca "Ferrari") (modello "F40")))
<Fact-1>
SLIPS> (facts)
f-1     (automobile (marca "Ferrari") (modello "F40"))
For a total of 1 fact.
SLIPS> (exit)
```

## 📦 Stato del Progetto

### ✅ Funzionalità Implementate

- **Core Engine**
  - ✅ Environment e gestione stato
  - ✅ Parser espressioni CLIPS
  - ✅ Evaluator con funzioni built-in
  - ✅ Router I/O con callback personalizzabili
  - ✅ Sistema di binding variabili (locali e globali)

- **Costrutti**
  - ✅ `deftemplate` con slot e constraints
  - ✅ `deffacts` per fatti iniziali
  - ✅ `defrule` con pattern matching
  - ✅ `assert` / `retract` incrementale
  - ✅ Slot con default (statici e dinamici)
  - ✅ Constraints su tipi e valori

- **Pattern Matching**
  - ✅ Pattern positivi con bind variabili
  - ✅ Pattern negati (`not`) con propagazione incrementale
  - ✅ Exists unario (senza binding)
  - ✅ Test predicati in LHS
  - ✅ Variabili condivise tra pattern

- **RETE Algorithm**
  - ✅ Alpha network con indexing per template
  - ✅ Beta engine per pattern positivi
  - ✅ Propagazione incrementale su assert/retract
  - ✅ Delta NOT ottimizzato (hash buckets + prefiltraggio)
  - ✅ Join incrementale con confronto backtracking/beta
  - 🚧 Nodi RETE espliciti (alpha/beta/join nodes) — in sviluppo

- **Agenda**
  - ✅ Coda attivazioni con priorità (salience)
  - ✅ Strategie: `depth`, `breadth`, `lex`, `mea`
  - ✅ Conflict resolution
  - ✅ Timestamp e recency per LEX/MEA

- **Funzioni Built-in**
  - ✅ Aritmetiche: `+`, `-`, `*`, `/`, `div`, `mod`
  - ✅ Confronto: `=`, `<>`, `<`, `<=`, `>`, `>=`
  - ✅ Logiche: `and`, `or`, `not`, `eq`, `neq`
  - ✅ Costrutti: `bind`, `printout`, `assert`, `retract`
  - ✅ Utilità: `facts`, `rules`, `agenda`, `watch`, `run`, `reset`, `clear`
  - ✅ Liste: `create$`, `length$`, `nth$`, `member$`

- **Watch & Debug**
  - ✅ `watch facts` / `unwatch facts`
  - ✅ `watch rules` / `unwatch rules`
  - ✅ `watch activations` / `unwatch activations`
  - ✅ Flag sperimentale `join-check` per validazione beta engine

### 🚧 In Sviluppo

- 🚧 Nodi RETE espliciti per ottimizzazione avanzata
- 🚧 Pattern con vincoli complessi (NCC completo)
- 🚧 Funzioni definite dall'utente (`deffunction`)
- 🚧 COOL (CLIPS Object-Oriented Language)
- 🚧 Moduli (`defmodule`)

## 🏗️ Architettura

### Struttura del Progetto

```
SLIPS/
├── Sources/SLIPS/
│   ├── CLIPS.swift              # Facciata pubblica API
│   ├── Core/
│   │   ├── envrnmnt.swift       # Environment (environment.c)
│   │   ├── evaluator.swift      # Evaluator (evaluatn.c)
│   │   ├── expressn.swift       # Espressioni (expressn.c)
│   │   ├── scanner.swift        # Scanner/Lexer (scanner.c)
│   │   ├── router.swift         # Router I/O (router.c)
│   │   ├── functions.swift      # Funzioni built-in
│   │   └── ...
│   ├── Rete/
│   │   ├── AlphaNetwork.swift   # Alpha memory
│   │   ├── BetaEngine.swift     # Beta network (drive.c)
│   │   ├── BetaNetwork.swift    # Beta memory
│   │   └── Nodes.swift          # Nodi RETE
│   └── Agenda/
│       └── Agenda.swift         # Agenda (agenda.c)
├── Tests/SLIPSTests/
│   ├── RuleEngineTests.swift
│   ├── ReteJoinTests.swift
│   ├── AgendaStrategyTests.swift
│   └── ...
├── clips_core_source_642/       # Sorgenti C originali (riferimento)
└── clips_feature_tests_642/     # Test CLIPS (golden files)
```

### Mapping C → Swift

| C (CLIPS) | Swift (SLIPS) |
|-----------|---------------|
| `struct` | `struct` |
| `union` + type tag | `enum` con associated values |
| `#define` macro | `static let` o computed property |
| `malloc`/`free` | `Array`, `Dictionary`, ARC |
| Puntatori | Reference types, `Unsafe*` quando necessario |
| `void*` | Generics o `Any` type-safe |

## 📖 Documentazione

### 📚 Risorse Disponibili

- **[Documentazione Online](https://gpicchiarelli.github.io/SLIPS/)** — Guida completa in italiano/inglese
- **[Esempi Pratici](https://gpicchiarelli.github.io/SLIPS/it/examples.html)** — Tutorial step-by-step
- **[API Reference](https://gpicchiarelli.github.io/SLIPS/it/api.html)** — Documentazione API completa
- **[Roadmap](docs/ROADMAP.md)** — Piano di sviluppo e traduzione
- **[AGENTS.md](AGENTS.md)** — Linee guida per contributor e agenti AI

### 🔧 API Principale

```swift
// Creazione environment
let env = CLIPS.createEnvironment()

// Caricamento file
CLIPS.load("regole.clp")

// Valutazione espressioni
let result = CLIPS.eval(expr: "(+ 2 3)")  // .int(5)

// Reset e gestione
CLIPS.reset()
CLIPS.run(limit: nil)

// Assert e retract
let id = CLIPS.assert(fact: "(temperatura 25)")
CLIPS.retract(id: id)

// REPL interattivo
CLIPS.commandLoop()
```

## 🧪 Testing

### Esecuzione Test

```bash
# Tutti i test
swift test

# Test specifico
swift test --filter ReteJoinTests

# Con output verbose
swift test -v

# Con coverage
swift test --enable-code-coverage
```

### Test di Equivalenza

I test sono progettati per verificare l'equivalenza comportamentale con CLIPS 6.4.2:

- ✅ Test basati sui file `.clp` di riferimento CLIPS
- ✅ Confronto output con CLIPS originale
- ✅ Validazione RETE con flag `join-check`
- ✅ Test di regressione su assert/retract incrementale

## 🤝 Contribuire

SLIPS accoglie contributi! Consulta [AGENTS.md](AGENTS.md) per le linee guida complete.

### 🎯 Principi di Traduzione

1. **Fedeltà Semantica** — Preservare algoritmi e comportamento, non semplificare
2. **Mapping 1:1** — Ogni file `.c/.h` corrisponde a un file `.swift` omonimo
3. **Type Safety** — Evitare force unwrap, usare `guard let` e pattern matching
4. **Documentazione** — Commentare in italiano, citare funzioni C originali
5. **Test-Driven** — Aggiungere test per ogni modulo tradotto

### 🚀 Come Contribuire

1. **Fork** del repository
2. Crea un **branch** per la tua feature: `git checkout -b feature/nome-feature`
3. **Traduci** seguendo le linee guida in `AGENTS.md`
4. **Testa** il codice: `swift test`
5. **Commit** con messaggi descrittivi
6. **Push** al branch: `git push origin feature/nome-feature`
7. Apri una **Pull Request**

### 📋 Template PR e Issues

Il progetto include template dettagliati per:
- 🐛 Bug report con confronto CLIPS
- ✨ Feature request con riferimenti al codice C
- ❓ Domande e discussioni
- 📝 Pull request con checklist traduzione

## 📊 Statistiche

<div align="center">

![GitHub code size](https://img.shields.io/github/languages/code-size/gpicchiarelli/SLIPS)
![GitHub repo size](https://img.shields.io/github/repo-size/gpicchiarelli/SLIPS)
![Lines of code](https://img.shields.io/tokei/lines/github/gpicchiarelli/SLIPS)
![GitHub commit activity](https://img.shields.io/github/commit-activity/m/gpicchiarelli/SLIPS)
![GitHub last commit](https://img.shields.io/github/last-commit/gpicchiarelli/SLIPS)

</div>

## 🔗 Riferimenti

- **[CLIPS Official Site](http://clipsrules.sourceforge.net/)** — Sito ufficiale CLIPS
- **[CLIPS 6.4.2 User Guide](http://clipsrules.sourceforge.net/documentation/v642/ug.pdf)** — Manuale utente
- **[CLIPS 6.4.2 Reference Manual](http://clipsrules.sourceforge.net/documentation/v642/apg.pdf)** — Manuale di riferimento
- **[NASA CLIPS History](https://www.jsc.nasa.gov/node/15006)** — Storia di CLIPS alla NASA

## 📄 Licenza

SLIPS è rilasciato sotto licenza **MIT**. Vedi il file [LICENSE](LICENSE) per i dettagli completi.

```
Copyright (c) 2025 SLIPS Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software.
```

## 👥 Autori e Riconoscimenti

Vedi [AUTHORS](AUTHORS) per la lista completa dei contributori.

### Ringraziamenti Speciali

- **NASA** e il team originale di CLIPS per aver creato questo straordinario sistema
- La **community Swift** per gli strumenti e il supporto
- Tutti i **contributor** che hanno dedicato tempo a questo progetto

---

<div align="center">

**[⭐ Metti una stella su GitHub](https://github.com/gpicchiarelli/SLIPS/stargazers)** • **[🐛 Segnala un Bug](https://github.com/gpicchiarelli/SLIPS/issues/new?template=bug_report.md)** • **[💡 Proponi una Feature](https://github.com/gpicchiarelli/SLIPS/issues/new?template=feature_request.md)**

Fatto con ❤️ e ☕ per la community Swift

</div>
