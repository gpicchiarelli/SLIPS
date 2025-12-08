# Contributing to SLIPS

Grazie per voler contribuire a **SLIPS**, traduzione fedele di CLIPS in Swift 6.2.
L'obiettivo è mantenere la parità funzionale con il motore originale, adottando Swift solo dove non altera la semantica.

---

## 📋 Requisiti

- **Swift 6.2+**
- **macOS 14+** o **Linux compatibile**
- **Xcode 16.x** (opzionale, per sviluppo macOS)

## 🚀 Setup Sviluppo

```bash
# Clona il repository
git clone https://github.com/gpicchiarelli/SLIPS.git
cd SLIPS

# Build
swift build

# Test
swift test

# Watch mode (richiede fswatch)
fswatch -o Sources/ | xargs -n1 -I{} swift test
```

---

## 📝 Linee Guida

### Principi Fondamentali

1. **Traduzione Fedele**: Traduci il codice C 1:1 dove possibile
   - Mantieni la stessa struttura algoritmica
   - Rispetta nomi e responsabilità originali
   - Documenta deviazioni necessarie

2. **Swift Idiomatico**: Usa Swift idiomatico solo se:
   - È trasparente sul piano semantico
   - Non altera le performance
   - Migliora la leggibilità senza cambiare comportamento

3. **Determinismo**: Mantieni determinismo rigoroso
   - Stessi input → stessi output
   - Test devono essere riproducibili
   - Evita effetti collaterali non documentati

### Struttura Codice

Ogni modulo tradotto deve:
- Avere test dedicati in `Tests/SLIPSTests/`
- Seguire la struttura file-per-file da CLIPS C
- Includere commenti con riferimenti ai file C originali

### Testing

- **Ogni modifica richiede test**
- Test devono essere specifici e isolati
- Usare `clips_feature_tests_642/` come riferimento golden
- Marcare `XCTSkip` solo se strettamente necessario

---

## 🔀 Branch e Commit

### Branch Strategy

- **`main`**: Stabile, sempre funzionante
- **`develop`**: Sviluppo attivo
- **`feat/`**: Nuove feature
- **`fix/`**: Bugfix
- **`perf/`**: Ottimizzazioni performance
- **`docs/`**: Documentazione

### Commit Messages

Usa [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(rete): implement beta memory activation
fix(agenda): correct salience ordering
docs(readme): update installation instructions
perf(assert): optimize fact lookup
test(pattern): add multifield sequence tests
```

**Formato**:
- `type(scope): description`
- Tipo: `feat`, `fix`, `docs`, `perf`, `test`, `refactor`, `chore`
- Scope: modulo modificato (es. `rete`, `agenda`, `parser`)

---

## 🔍 Pull Request Process

### Checklist PR

- [ ] Test verdi (`swift test`)
- [ ] Codice formattato (SwiftFormat o manuale)
- [ ] Nessun warning di compilazione
- [ ] Test coverage mantenuta o migliorata
- [ ] Documentazione aggiornata (se necessario)
- [ ] CHANGELOG.md aggiornato (per modifiche user-facing)

### Review Criteria

Il codice viene valutato su:
1. **Correttezza**: Funziona come previsto?
2. **Fedeltà CLIPS**: È equivalente all'originale C?
3. **Qualità**: Swift idiomatico, leggibile, manutenibile?
4. **Test**: Copertura adeguata?

### Apertura PR

1. Fork del repository
2. Crea branch feature/fix
3. Commit con messaggi chiari
4. Push e apri PR
5. Compila template PR completamente

---

## 🐛 Reporting Bugs

Usa il template [Bug Report](.github/ISSUE_TEMPLATE/bug_report.md):

- Descrizione chiara del problema
- Steps per riprodurre
- Comportamento atteso vs attuale
- Ambiente (OS, Swift version, etc.)
- Log/Output rilevanti

---

## ✨ Richiedere Feature

Usa il template [Feature Request](.github/ISSUE_TEMPLATE/feature_request.md):

- Descrizione della feature
- Motivazione e use case
- Proposta di implementazione
- Riferimenti a CLIPS C (se presente)

---

## 📚 Documentazione

### Per Utenti

- `README.md`: Overview e quick start
- `USER_GUIDE.md`: Guida completa
- `Examples/`: Esempi pratici

### Per Sviluppatori

- `AGENTS.md`: Linee guida per agenti AI
- `docs/ROADMAP.md`: Roadmap progetto
- Commenti inline con riferimenti file C

---

## 🎯 Priorità Contributi

### High Priority

- Fix moduli (issue #1, #2, #3)
- Test integrazione end-to-end
- Performance optimization
- Bug fixes critici

### Medium Priority

- Documentazione esempi
- FORALL implementation
- Binary save/load
- Extended I/O functions

### Low Priority

- RETE esplicito completion
- Concurrency support
- Debugging tools

---

## 💡 Best Practices

### Code Style

- Swift idiomatico dove possibile
- Commenti in italiano con riferimenti C
- Naming: preferire nomi CLIPS quando chiari
- Gestione errori: `guard let` invece di force unwrap

### Performance

- Profiling prima di ottimizzare
- Benchmark per modifiche significative
- Documentare trade-off

### Testing

- Unit test per ogni funzione pubblica
- Integration test per workflow completi
- Golden tests per compatibility CLIPS

---

## 📄 Licenza

Contributi soggetti alla licenza MIT. Contribuendo, accetti che il tuo codice sarà rilasciato sotto la stessa licenza del progetto.

---

## 🤝 Codice di Condotta

Questo progetto segue il [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).
Rispetta sempre gli altri collaboratori.

---

## ❓ Domande?

- **Issues**: Per bug e feature requests
- **Discussions**: Per domande generali
- **AGENTS.md**: Per agenti AI che contribuiscono

---

**Grazie per il tuo contributo a SLIPS!** 🚀
