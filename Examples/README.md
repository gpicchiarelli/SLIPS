# 📚 SLIPS Examples

Questa directory contiene esempi progressivi per imparare SLIPS, dal livello base a quello avanzato.

---

## 🎓 Livello Base (01-05)

### 01_HelloWorld.clp
**Concetti**: First rule, printout, assert
```clp
(defrule hello
  =>
  (printout t "Hello, World!" crlf))
```

### 02_Counter.clp
**Concetti**: Variables, retract, bindings
- Pattern matching con variabili
- Incremento contatore con retract/assert

### 03_StringProcessing.clp
**Concetti**: String functions, str-cat, upcase, lowcase
- Manipolazione stringhe
- 11 funzioni string disponibili

### 04_MathCalculations.clp
**Concetti**: Math functions, arithmetic, trigonometry
- Operazioni matematiche
- 36 funzioni math (sin, cos, sqrt, exp, log, etc.)

### 05_AnimalClassifier.clp
**Concetti**: Pattern matching, salience, multiple patterns
- Sistema di classificazione
- Regole con priorità

---

## 🔧 Livello Intermedio (06-08)

### 06_TemplateManipulation.clp
**Concetti**: deftemplate, slots, defaults
- Definizione template strutturati
- Slot con valori di default

### 07_ModulesDemo.clp
**Concetti**: defmodule, focus, import/export
- Sistema multi-modulo base
- Focus stack

### 07b_DiagnosticSystem.clp
**Concetti**: Expert system, multi-step reasoning
- Sistema diagnostico medico
- Ragionamento multi-livello

### 08_ShoppingCart.clp
**Concetti**: Complex rules, aggregation, math
- Carrello e-commerce
- Calcolo totale con sconti

### 08b_DataValidation.clp
**Concetti**: Constraints, validation, error handling
- Validazione dati input
- Gestione errori

---

## 🚀 Livello Avanzato (09-12)

### 09_FileIO.clp
**Concetti**: I/O functions, read, printout
- Lettura/scrittura file
- Formattazione output

### 09b_AdvancedPatterns.clp
**Concetti**: Multifield, NOT, EXISTS, complex CE
- Pattern matching avanzato
- Conditional elements complessi

### 10_MetaProgramming.clp
**Concetti**: Reflection, dynamic rules, funcall
- Meta-programming
- Generazione dinamica regole

### 11_MultiModuleSystem.clp ⭐ NUOVO
**Concetti**: Multi-module architecture, focus stack, module-aware agenda
- Sistema completo multi-modulo
- Validazione → Billing → Reporting
- Focus stack per controllo flusso
- **Richiede**: SLIPS 0.96+

### 12_TemplateFunctions.clp ⭐ NUOVO
**Concetti**: Template introspection, facets, modify, duplicate
- 14 funzioni template complete
- Analisi dinamica struttura dati
- Meta-programming avanzato
- **Richiede**: SLIPS 0.96+

---

## 📊 Tabella Riepilogativa

| # | Nome | Difficoltà | Concetti Chiave | Funzioni Usate |
|---|------|------------|-----------------|----------------|
| 01 | HelloWorld | ⭐ | Base | printout, assert |
| 02 | Counter | ⭐ | Variables | bind, retract |
| 03 | StringProcessing | ⭐⭐ | Strings | str-cat, upcase, sub-string |
| 04 | MathCalculations | ⭐⭐ | Math | sqrt, sin, cos, exp |
| 05 | AnimalClassifier | ⭐⭐ | Patterns | salience, multi-pattern |
| 06 | TemplateManipulation | ⭐⭐ | Templates | deftemplate, slots |
| 07 | ModulesDemo | ⭐⭐⭐ | Modules | defmodule, focus |
| 07b | DiagnosticSystem | ⭐⭐⭐ | Expert | inference, chaining |
| 08 | ShoppingCart | ⭐⭐⭐ | Business | aggregation, math |
| 08b | DataValidation | ⭐⭐⭐ | Validation | constraints, tests |
| 09 | FileIO | ⭐⭐⭐ | I/O | read, open, close |
| 09b | AdvancedPatterns | ⭐⭐⭐⭐ | CE | NOT, EXISTS, multifield |
| 10 | MetaProgramming | ⭐⭐⭐⭐ | Meta | funcall, reflection |
| 11 | MultiModuleSystem | ⭐⭐⭐⭐ | Modules++ | focus stack, cross-module |
| 12 | TemplateFunctions | ⭐⭐⭐⭐ | Introspection | slot-names, facets, modify |

---

## 🎯 Percorso di Apprendimento Consigliato

### Giorno 1: Fondamenti
1. 01_HelloWorld.clp
2. 02_Counter.clp
3. 05_AnimalClassifier.clp

### Giorno 2: Funzioni Builtin
4. 03_StringProcessing.clp
5. 04_MathCalculations.clp
6. 06_TemplateManipulation.clp

### Giorno 3: Moduli e Strutture
7. 07_ModulesDemo.clp
8. 08_ShoppingCart.clp
9. 08b_DataValidation.clp

### Giorno 4: Avanzato
10. 09b_AdvancedPatterns.clp
11. 11_MultiModuleSystem.clp ⭐
12. 12_TemplateFunctions.clp ⭐

### Giorno 5: Progetti Reali
13. 07b_DiagnosticSystem.clp
14. 10_MetaProgramming.clp
15. Crea il tuo progetto!

---

## 🔧 Come Eseguire gli Esempi

### Opzione 1: SLIPS CLI
```bash
swift run slips-cli Examples/01_HelloWorld.clp
```

### Opzione 2: SLIPS REPL
```bash
swift run slips-cli
SLIPS> (load "Examples/01_HelloWorld.clp")
SLIPS> (reset)
SLIPS> (run)
```

### Opzione 3: Programmaticamente
```swift
import SLIPS

@MainActor
func runExample() {
    _ = CLIPS.createEnvironment()
    _ = CLIPS.load("Examples/01_HelloWorld.clp")
    _ = CLIPS.reset()
    _ = CLIPS.run()
}
```

---

## 📝 Convenzioni negli Esempi

### Commenti
- `; ===========` - Sezioni principali
- `; Parte N:` - Sottosezioni
- `; Concetti:` - Lista concetti dimostrati

### Output
- `✓` - Operazione riuscita
- `✗` - Operazione fallita
- `→` - Output o risultato
- `═══` - Separatori sezioni

### Stile Codice
- **Nomi descrittivi**: `calculate-total` invece di `calc-t`
- **Indentazione 2 spazi**: Standard CLIPS
- **Comments in italiano**: Spiegazioni chiare
- **Output formattato**: Box ASCII per leggibilità

---

## 🆕 Novità 0.96.0 (16 Ottobre 2025)

- ✅ **Example 11**: Multi-Module System completo
  - Dimostra fix moduli critici
  - Focus stack funzionante
  - Module-aware agenda

- ✅ **Example 12**: Template Functions complete
  - 14 funzioni template introspection
  - Facets, modify, duplicate
  - Meta-programming pratico

---

## 💡 Suggerimenti

### Per Principianti
- Inizia con 01-05
- Esegui ogni esempio e studia l'output
- Modifica gli esempi per sperimentare
- Usa `(facts)` e `(rules)` per esplorare lo stato

### Per Intermedi
- Studia 06-09
- Combina concetti di esempi diversi
- Crea varianti degli esempi
- Sperimenta con salience e strategie

### Per Avanzati
- Approfondisci 10-12
- Crea sistemi multi-modulo complessi
- Usa template introspection per validazione
- Ottimizza performance con focus stack

---

## 🐛 Segnalazione Problemi

Se trovi bug negli esempi o hai suggerimenti:
1. Verifica di usare SLIPS 0.96.0+
2. Controlla KNOWN_ISSUES.md
3. Apri un issue su GitHub (quando disponibile)

---

## 🤝 Contribuire

Vuoi aggiungere esempi?
1. Segui lo stile degli esempi esistenti
2. Documenta chiaramente i concetti
3. Testa che funzioni con SLIPS attuale
4. Invia una PR (quando repository pubblico)

---

**Ultimo aggiornamento**: 16 Ottobre 2025  
**Esempi totali**: 12 (+2 oggi!)  
**Copertura funzionalità**: 96%

Happy coding with SLIPS! 🚀
