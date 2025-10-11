<div align="center">

# ⚡ SLIPS

### Swift Language Implementation of Production Systems

[![CI](https://img.shields.io/github/actions/workflow/status/gpicchiarelli/SLIPS/ci.yml?branch=main&label=CI&logo=github&logoColor=white)](https://github.com/gpicchiarelli/SLIPS/actions/workflows/ci.yml)
[![Deploy Pages](https://img.shields.io/github/actions/workflow/status/gpicchiarelli/SLIPS/pages.yml?branch=main&label=docs&logo=github&logoColor=white)](https://github.com/gpicchiarelli/SLIPS/actions/workflows/pages.yml)
[![License](https://img.shields.io/github/license/gpicchiarelli/SLIPS?logo=opensourceinitiative&logoColor=white)](LICENSE)

[![Swift](https://img.shields.io/badge/Swift-6.2-FA7343?logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey?logo=apple&logoColor=white)](https://github.com/gpicchiarelli/SLIPS)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen?logo=swift&logoColor=white)](https://swift.org/package-manager/)

[![Documentation](https://img.shields.io/badge/docs-online-blue?logo=readthedocs&logoColor=white)](https://gpicchiarelli.github.io/SLIPS/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?logo=github&logoColor=white)](https://github.com/gpicchiarelli/SLIPS/pulls)
[![GitHub Stars](https://img.shields.io/github/stars/gpicchiarelli/SLIPS?style=social)](https://github.com/gpicchiarelli/SLIPS/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/gpicchiarelli/SLIPS?logo=github&logoColor=white)](https://github.com/gpicchiarelli/SLIPS/issues)
[![GitHub Contributors](https://img.shields.io/github/contributors/gpicchiarelli/SLIPS?logo=github&logoColor=white)](https://github.com/gpicchiarelli/SLIPS/graphs/contributors)

[📚 Documentazione](https://gpicchiarelli.github.io/SLIPS/) • [💡 Esempi](https://gpicchiarelli.github.io/SLIPS/it/examples.html) • [🔧 API](https://gpicchiarelli.github.io/SLIPS/it/api.html) • [🗺️ Roadmap](docs/ROADMAP.md) • [🤝 AGENTS.md](AGENTS.md)

---

</div>

## 🎯 Benvenuta/o in SLIPS

Una traduzione fedele e moderna in Swift 6 del motore CLIPS (v6.4.2).

### Obiettivo del progetto

- Tradurre integralmente il codice sorgente C di CLIPS in Swift 6.2
- Mantenere equivalenza funzionale e semantica (RETE, agenda, attivazioni, salience, test pattern, ecc.)
- Esporre una facciata pubblica compatibile con CLIPS

### Stato attuale

- ✅ Struttura SwiftPM pronta
- ✅ Facciata iniziale delle API disponibile (stub in evoluzione)
- ✅ Strumenti e linee guida per la traduzione

### Aggiornamenti recenti

- ✅ Pulizia warning in build/test (preferiti `let` dove appropriato)
- ✅ **Exists unario:** parsing/IR e valutazione LHS senza introdurre binding; aggiunto nodo `ExistsNode` nello scaffold RETE
- ✅ **Not delta ottimizzato:** propagazione incrementale per CE negati senza full recompute, con prefiltraggio costanti e bucket hash sulle chiavi di join

## 🚀 Come iniziare

```bash
# Compilare libreria + CLI
swift build

# Eseguire test
swift test

# Avviare REPL minimale
swift run slips-cli

# Aprire con Xcode (opzionale)
xed .
```

## 📁 Struttura del repository

```
SLIPS/
├── clips_core_source_642/   # Sorgenti C di riferimento (CLIPS 6.4.2)
├── clips_feature_tests_642/  # Insiemi di test .clp di riferimento
├── Sources/SLIPS/            # Codice Swift del motore in traduzione
│   ├── Core/                 # Parser, evaluator, environment
│   ├── Rete/                 # Alpha/Beta network, pattern matching
│   └── Agenda/               # Conflict resolution, strategie
└── Tests/SLIPSTests/         # Test di equivalenza e unit test
```

## 📖 Linee guida di traduzione (sintesi)

- **Traduzione semantica fedele**, non riscrittura creativa
- Ogni file `.c/.h` corrisponde a un modulo `.swift` omonimo
- **Strutture C** → `struct` Swift; **union/type-tag** → `enum` con associated values
- **Macro** → `static let` o computed property; **condizionali** → `#if os(...)`
- **Puntatori/allocazione** → tipi sicuri Swift; usare `Unsafe*` solo quando necessario
- **Evitare force unwrap**; preferire `guard let`/`if case`

## 🔧 API pubblica (facciata)

```swift
// Environment management
CLIPS.createEnvironment()
CLIPS.load("file.clp")
CLIPS.reset()

// Execution
CLIPS.run(limit: Int?)

// Facts management
CLIPS.assert(fact: String)
CLIPS.retract(id: Int)

// Evaluation
CLIPS.eval(expr: String) -> Value

// Interactive REPL
CLIPS.commandLoop()
```

### CLI eseguibile

Disponibile anche come eseguibile `slips-cli` con REPL minimale:

```bash
$ swift run slips-cli
SLIPS> (facts)
SLIPS> (run)
```

## 🧪 Nota sui test

I test puntano a convalidare l'equivalenza rispetto ai file `.clp` di riferimento. In questa fase iniziale alcuni test possono essere marcati come `XCTSkip` in attesa della completa traduzione dei moduli RETE/Agenda.

## 🤝 Contributi

- Consulta **[AGENTS.md](AGENTS.md)** per le convenzioni di traduzione e la mappatura file-per-file
- Apri una **issue** per dubbi su semantica o naming; puntiamo a **massima fedeltà a CLIPS**

## 📚 Documentazione

- 📖 **[Documentazione completa](https://gpicchiarelli.github.io/SLIPS/)** — Guida in italiano e inglese
- 💡 **[Esempi pratici](https://gpicchiarelli.github.io/SLIPS/it/examples.html)** — Tutorial e casi d'uso
- 🔧 **[API Reference](https://gpicchiarelli.github.io/SLIPS/it/api.html)** — Documentazione API completa
- 🗺️ **[Roadmap](docs/ROADMAP.md)** — Piano di sviluppo e traduzione

## 📊 Statistiche

<div align="center">

![Code Size](https://img.shields.io/github/languages/code-size/gpicchiarelli/SLIPS?logo=github&logoColor=white)
![Repo Size](https://img.shields.io/github/repo-size/gpicchiarelli/SLIPS?logo=github&logoColor=white)
![Commit Activity](https://img.shields.io/github/commit-activity/m/gpicchiarelli/SLIPS?logo=github&logoColor=white)
![Last Commit](https://img.shields.io/github/last-commit/gpicchiarelli/SLIPS?logo=github&logoColor=white)

</div>

## 📄 Licenza

SLIPS è rilasciato sotto licenza **MIT**. Vedi il file [LICENSE](LICENSE) per i dettagli.

```
Copyright (c) 2025 SLIPS Contributors
```

## 👥 Autori

Vedi [AUTHORS](AUTHORS) per la lista completa dei contributori.

---

<div align="center">

**[⭐ Metti una stella](https://github.com/gpicchiarelli/SLIPS/stargazers)** • **[🐛 Segnala un bug](https://github.com/gpicchiarelli/SLIPS/issues/new?template=bug_report.md)** • **[💡 Proponi una feature](https://github.com/gpicchiarelli/SLIPS/issues/new?template=feature_request.md)**

</div>
