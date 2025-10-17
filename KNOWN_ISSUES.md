# 🐛 SLIPS - Problemi Noti e Limitazioni

**Versione**: 0.80.0-dev  
**Ultimo aggiornamento**: 16 Ottobre 2025

Questo documento elenca **onestamente** tutti i problemi identificati, le limitazioni e i workaround disponibili.

---

## ✅ Problemi Risolti

### ~~1. Regole di Moduli Non-MAIN Non Si Attivano~~ ✅ RISOLTO

**Status**: ✅ **RISOLTO** (16 Ottobre 2025)  
**Fix**: Assert come special form + moduleName assignment

**Problema**:
Le regole definite in moduli diversi da MAIN non venivano attivate.

**Soluzione**:
1. Trasformato `assert` in special form (evaluator.swift, linee 316-362)
2. Aggiunto assignment di `moduleName` alle attivazioni in tutti i punti critici:
   - `CLIPS.swift` linea 259
   - `ruleengine.swift` linea 94
   - `Nodes.swift` linee 654-656

**Risultato**:
- ✅ 7/7 test ModuleAwareAgendaTests passano
- ✅ Sistema multi-modulo completamente funzionale
- ✅ Attivazioni ereditano correttamente il modulo

---

### ~~2. Focus Stack Non Ordina Agenda~~ ✅ RISOLTO

**Status**: ✅ **RISOLTO** (16 Ottobre 2025)  
**Fix**: Integrazione focus stack in RuleEngine.run()

**Problema**:
Il comando `(focus MODULE)` non aveva effetto sull'ordine di esecuzione.

**Soluzione**:
1. Aggiunto metodo `applyFocusStackSorting()` in Agenda.swift (linee 116-121)
2. Integrato in `RuleEngine.run()` (linee 252-258)
3. L'agenda viene riordinata secondo focus stack prima di ogni ciclo run

**Risultato**:
- ✅ Focus stack ora controlla ordine esecuzione regole
- ✅ Moduli in focus hanno priorità assoluta su salience
- ✅ Test integration completi passano

---

## 🚨 Problemi Critici (Blockers)

*Nessuno! Il sistema moduli è ora completamente funzionale.* ✅

---

## ⚠️ Problemi Importanti (Non-Blockers)

### 1. Cross-Module Template Visibility (DEPRECATO)
Usare solo salience per controllo ordine:
```clp
(defrule high-priority (declare (salience 10)) => ...)
(defrule low-priority  (declare (salience 0))  => ...)
```

**ETA Fix**: Sprint 1 (2 giorni)

---

### 3. Template Globali (By Design per ora)

**Severity**: 🟡 BASSA  
**Impatto**: Namespace globale, ma funzionale  
**Status**: ✅ **Comportamento Accettabile**

**Descrizione**:
I template sono globali a tutti i moduli, simile a CLIPS default.

**Comportamento Attuale**:
```clp
(defmodule A)
(deftemplate person (slot name))  ; Definito in A

(defmodule B)
; ✅ 'person' visibile anche qui (come in CLIPS default)
(defrule use-person
  (person (name ?n))
  =>
  (printout t ?n crlf))
```

**Nota**:
Questo è il comportamento di CLIPS 6.4 quando non si usa strict import/export enforcement. È funzionale e non blocca la release 1.0.

**Workaround** (se serve isolamento):
Prefissare nomi template con modulo:
```clp
(deftemplate A-person (slot name))
(deftemplate B-customer (slot id))
```

**ETA Fix**: Post 1.0 (opzionale)

---

## ⚠️ Problemi Importanti (Non-Blockers)

### 4. Performance Assert Sotto Target

**Severity**: 🟠 IMPORTANTE  
**Impatto**: Lento per KB grandi (>10k facts)  
**Status**: Optimization needed

**Descrizione**:
Assert di 1000 fatti richiede ~240ms invece di <100ms target.

**Benchmark**:
```swift
// Test eseguito su MacBook Pro M1
Assert 1k facts: 240ms  (target: <100ms) ❌
Assert 10k facts: 2.8s  (target: <1s) ❌
Join 3-pattern: 5ms     (target: <10ms) ✅
```

**Causa Root**:
- Agenda resort a ogni insert (O(n log n))
- Alpha index senza bloom filter
- Beta memory senza strutture condivise

**Workaround**:
Batch assert e singola run:
```clp
; ✅ Meglio
(batch-assert
  (person (name "Alice"))
  (person (name "Bob"))
  ; ... 1000 facts
)
(run)

; ❌ Lento
(assert (person (name "Alice")))
(run)
(assert (person (name "Bob")))
(run)
; ... repeat 1000 times
```

**ETA Fix**: Sprint 3 (1 settimana)

---

### 5. RETE Esplicito Disattivato

**Severity**: 🟠 IMPORTANTE  
**Impatto**: Ottimizzazioni avanzate non disponibili  
**Status**: Work-in-progress abbandonato

**Descrizione**:
Esiste un'implementazione RETE class-based (~900 righe) ma è disattivata perché incompleta.

**Codice**:
```swift
// ruleengine.swift:44-46
if env.useExplicitReteNodes {  // ❌ FALSE di default
    _ = NetworkBuilder.buildNetwork(for: rule, env: &env)
}
```

**File Coinvolti**:
- `Nodes.swift` (575 righe) - ~40% testato
- `NetworkBuilder.swift` (320 righe) - ~60% testato
- `Propagation.swift` (320 righe) - ~50% testato
- `DriveEngine.swift` - ❌ Stub incompleto

**Impatto Pratico**: MINIMO
- Il sistema usa ReteCompiler legacy che funziona bene
- Performance accettabili per KB <10k facts

**Workaround**: Nessuno necessario (legacy è sufficiente)

**ETA Fix**: 2.0 o mai (bassa priorità)

---

### 6. FORALL Non Implementato

**Severity**: 🟠 IMPORTANTE  
**Impatto**: Pattern matching limitato  
**Status**: Da implementare

**Descrizione**:
Conditional element FORALL non supportato.

**Esempio Non Supportato**:
```clp
; ❌ Non funziona
(defrule all-adults
  (forall (person (name ?n) (age ?a))
          (test (>= ?a 18)))
  =>
  (printout t "Everyone is adult" crlf))
```

**Workaround**:
Usare approccio negativo:
```clp
; ✅ Funziona
(defrule check-no-minors
  (not (person (age ?a&:(< ?a 18))))
  =>
  (printout t "Everyone is adult" crlf))
```

**ETA Fix**: 2.0

---

## 🟡 Limitazioni Minori

### 7. Alcuni Test RETE Esplicito Falliscono

**Severity**: 🟡 MINORE  
**Impatto**: Feature disattivata comunque  
**Status**: Known, won't fix per 1.0

**Test Falliti**:
```
❌ ReteExplicitNodesTests::testComplexNetworkWith5Levels
❌ ReteExplicitNodesTests::testJoinNodeWithMultiplePatterns
```

**Causa**: DriveEngine incompleto

**Impatto Reale**: Nessuno (RETE esplicito non usato)

---

### 8. Alcuni I/O Functions Fallback a Stdout

**Severity**: 🟡 MINORE  
**Impatto**: I/O avanzato limitato  
**Status**: Acceptable per 1.0

**Descrizione**:
Alcune funzioni I/O usano stdout/stdin di default invece di router configurabili.

**Funzioni Coinvolte**:
- `print` - sempre stdout
- `read-number` - sempre stdin
- `get-char` - sempre stdin

**Workaround**: Usare `printout` con router esplicito

**ETA Fix**: 1.5 (low priority)

---

### 9. Binary Load/Save Non Implementato

**Severity**: 🟡 MINORE  
**Impatto**: Startup lento per KB grandi  
**Status**: Feature 2.0

**Funzioni Mancanti**:
```clp
(bload "kb.bin")   ; ❌ Non supportato
(bsave "kb.bin")   ; ❌ Non supportato
```

**Workaround**: Usare `.clp` text files (load/save funzionano)

**ETA**: 2.0

---

### 10. Concurrent Execution Non Supportato

**Severity**: 🟡 MINORE  
**Impatto**: Single-threaded only  
**Status**: Architectural limitation

**Descrizione**:
L'engine è single-threaded, non può sfruttare multi-core.

**Limitazione**:
```swift
@MainActor  // ❌ Tutto su main thread
public enum CLIPS { ... }
```

**Performance Impact**:
- 1 core utilizzato
- No parallel rule firing
- No concurrent agenda processing

**Workaround**: Usare multiple Environment in thread separati (richiede coordinazione manuale)

**ETA**: 3.0 (major redesign)

---

## 📊 Test Coverage Gaps

### 11. Pochi Test di Integrazione End-to-End

**Severity**: 🟡 MINORE  
**Impatto**: Possibili regressioni nascoste  
**Status**: Da migliorare

**Situazione Attuale**:
- 250+ test (96.8% pass)
- Ma: Molti test isolati per singole funzioni
- Pochi scenari completi multi-step

**Gap Identificati**:
1. No test per workflow completo (load → assert → run → query)
2. No stress test (>10k facts)
3. No test cross-module completi
4. No test performance regression

**ETA Improvement**: Post-1.0

---

## 🔧 Workaround Generali

### Pattern 1: Evitare Multi-Modulo
```clp
; ❌ Evitare per ora
(defmodule A)
(defmodule B)

; ✅ Usare solo MAIN
(defrule rule-1 ...)
(defrule rule-2 ...)
```

### Pattern 2: Usare Salience invece di Focus
```clp
; ❌ Focus non affidabile
(focus MODULE-A)

; ✅ Usare salience
(defrule high-prio (declare (salience 10)) ...)
(defrule low-prio  (declare (salience 0))  ...)
```

### Pattern 3: Prefissare Nomi per Namespace
```clp
; ✅ Simulare namespace manualmente
(deftemplate billing-order (slot id))
(deftemplate shipping-package (slot id))
```

### Pattern 4: Batch Operations
```clp
; ✅ Ridurre numero di (run)
(assert (fact1))
(assert (fact2))
; ... many asserts
(run)  ; Single run migliore

; ❌ Evitare
(assert (fact1)) (run)
(assert (fact2)) (run)
```

---

## 📋 Tabella Riepilogativa

| # | Problema | Severity | Impatto | Workaround | ETA Fix |
|---|----------|----------|---------|------------|---------|
| 1 | Regole moduli non-MAIN | 🔴 | Alto | Usa MAIN | Sprint 1 |
| 2 | Focus stack ignorato | 🔴 | Alto | Usa salience | Sprint 1 |
| 3 | Template globali | 🔴 | Medio | Prefix names | Sprint 2 |
| 4 | Performance assert | 🟠 | Medio | Batch ops | Sprint 3 |
| 5 | RETE esplicito off | 🟠 | Basso | Nessuno | 2.0 |
| 6 | FORALL mancante | 🟠 | Basso | Usa NOT | 2.0 |
| 7 | Test RETE falliti | 🟡 | Nessuno | N/A | Won't fix |
| 8 | I/O fallback stdout | 🟡 | Basso | Usa printout | 1.5 |
| 9 | No bload/bsave | 🟡 | Basso | Usa text | 2.0 |
| 10 | No concurrency | 🟡 | Medio | Multi-env | 3.0 |
| 11 | Test coverage gaps | 🟡 | Basso | N/A | Post-1.0 |

---

## 🎯 Priorità Fix per Release

### 1.0 Beta (2-3 Settimane)
**Must-Fix**:
- ✅ #1: Regole moduli non-MAIN
- ✅ #2: Focus stack
- ⚠️ #3: Template isolati (nice-to-have)

**Can-Wait**:
- ❌ #4, #5, #6: Performance e features avanzate → 1.5/2.0

### 1.0 Stable (1-2 Mesi)
**Must-Fix**:
- ✅ #3: Template isolati
- ✅ #4: Performance optimization

### 2.0 (3-6 Mesi)
**Features**:
- ✅ #5: RETE esplicito completo
- ✅ #6: FORALL
- ✅ #9: Binary load/save

---

## 📞 Reporting Issues

**Trovato un nuovo problema?**

1. Verifica non sia già listato qui
2. Crea issue su GitHub con:
   - Descrizione concisa
   - Codice riproduzione minimo
   - Comportamento atteso vs attuale
   - Versione SLIPS

**Template Issue**:
```markdown
**Problema**: [titolo breve]
**Severity**: [🔴 Critico / 🟠 Importante / 🟡 Minore]

**Riproduzione**:
```clp
; codice minimo
```

**Comportamento Attuale**: ...
**Comportamento Atteso**: ...
**Versione**: 0.80.0-dev
```

---

**Ultima revisione**: 16 Ottobre 2025  
**Prossimo update**: Dopo fix Sprint 1

