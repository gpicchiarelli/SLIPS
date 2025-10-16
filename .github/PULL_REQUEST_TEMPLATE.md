## 📝 Descrizione

<!-- Descrivi brevemente le modifiche introdotte da questa PR -->

## 🎯 Tipo di Modifica

<!-- Metti una X nelle caselle appropriate -->

- [ ] 🐛 Bug fix (correzione di un problema)
- [ ] ✨ Nuova feature (aggiunta di funzionalità)
- [ ] 📚 Documentazione (solo modifiche alla documentazione)
- [ ] 🔧 Refactoring (ristrutturazione del codice senza cambiare comportamento)
- [ ] ⚡ Performance (miglioramenti delle prestazioni)
- [ ] 🧪 Test (aggiunta o correzione di test)
- [ ] 🏗️ Build/CI (modifiche al sistema di build o CI)

## 📋 Mapping CLIPS → Swift

<!-- Se hai tradotto codice C, indica il file sorgente -->

- File C di riferimento: `clips_core_source_642/core/NOMEFILE.c`
- File Swift creato/modificato: `Sources/SLIPS/NOMEFILE.swift`
- Funzioni tradotte:
  - [ ] `funzione1()` → `funzione1()`
  - [ ] `funzione2()` → `funzione2()`

## ✅ Checklist

<!-- Verifica che tutti i punti siano completati -->

- [ ] Il codice compila senza errori: `swift build`
- [ ] Tutti i test passano: `swift test`
- [ ] Nessun warning introdotto
- [ ] Documentazione aggiornata (se necessario)
- [ ] Test aggiunti/aggiornati (se necessario)
- [ ] Seguita la traduzione semantica fedele (no semplificazioni)
- [ ] Evitati force unwrap (`!`)
- [ ] Usati `guard let` / pattern matching dove appropriato
- [ ] Commenti in italiano con riferimenti a funzioni C originali

## 🧪 Test

<!-- Descrivi come hai testato le modifiche -->

```bash
swift test --filter NomeTest
```

### Risultati Test
<!-- Incolla l'output dei test o descrivi i risultati -->

```
Test Suite 'All tests' passed at ...
Executed X tests, with 0 failures (0 unexpected)
```

## 📸 Screenshot / Output

<!-- Se applicabile, aggiungi screenshot o output rilevante -->

## 🔗 Issue Correlate

<!-- Chiude/Risolve issues esistenti -->

Closes #XXX
Resolves #YYY

## 📌 Note Aggiuntive

<!-- Eventuali informazioni aggiuntive per i reviewer -->

---

### Reviewer Guide

**Per i reviewer:**
- [ ] Verifica fedeltà alla semantica CLIPS
- [ ] Controlla mapping file C → Swift
- [ ] Verifica presenza test appropriati
- [ ] Controlla che la documentazione sia chiara
- [ ] Valida pattern Swift idiomatici

