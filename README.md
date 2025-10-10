# SLIPS – Swift Language Implementation of Production Systems

[![License](https://img.shields.io/github/license/gpicchiarelli/SLIPS)](https://github.com/gpicchiarelli/SLIPS/blob/main/LICENSE)
[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg)](https://github.com/gpicchiarelli/SLIPS)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Build Status](https://img.shields.io/github/actions/workflow/status/gpicchiarelli/SLIPS/ci.yml?branch=main)](https://github.com/gpicchiarelli/SLIPS/actions)

[![Documentation](https://img.shields.io/badge/docs-online-blue.svg)](https://gpicchiarelli.github.io/SLIPS/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/gpicchiarelli/SLIPS/pulls)
[![GitHub Stars](https://img.shields.io/github/stars/gpicchiarelli/SLIPS?style=social)](https://github.com/gpicchiarelli/SLIPS/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/gpicchiarelli/SLIPS?style=social)](https://github.com/gpicchiarelli/SLIPS/network/members)
[![GitHub Issues](https://img.shields.io/github/issues/gpicchiarelli/SLIPS)](https://github.com/gpicchiarelli/SLIPS/issues)
[![GitHub Contributors](https://img.shields.io/github/contributors/gpicchiarelli/SLIPS)](https://github.com/gpicchiarelli/SLIPS/graphs/contributors)
[![Code Size](https://img.shields.io/github/languages/code-size/gpicchiarelli/SLIPS)](https://github.com/gpicchiarelli/SLIPS)
[![Last Commit](https://img.shields.io/github/last-commit/gpicchiarelli/SLIPS)](https://github.com/gpicchiarelli/SLIPS/commits/main)

Benvenuta/o in SLIPS, una traduzione fedele e moderna in Swift 6 del motore CLIPS (v6.4.2). 

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
- `clips_core_source_642/`: sorgenti C di riferimento (CLIPS 6.4.2)
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

## Documentazione
- 📖 [Documentazione completa](https://gpicchiarelli.github.io/SLIPS/)
- 💡 [Esempi pratici](https://gpicchiarelli.github.io/SLIPS/it/examples.html)
- 📚 [API Reference](https://gpicchiarelli.github.io/SLIPS/it/api.html)

## Licenza

SLIPS è rilasciato sotto licenza MIT. Vedi il file [LICENSE](LICENSE) per i dettagli.

Copyright (c) 2025 SLIPS Contributors

## Autore
Vedi [AUTHORS](AUTHORS) per la lista completa dei contributori.
