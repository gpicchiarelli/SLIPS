# 🐛 Bug Tracking - Test Falliti

**Data**: 17 Ottobre 2025  
**RETE**: Fedele al C, attivata  
**Test totali**: 287  
**Pass**: 276 (96.2%)  
**Fail**: 11 (3.8%)

---

## ✅ Bug Risolti

### 1. **retract ritorna int invece di boolean**
**File**: `functions.swift:372`  
**Test**: `ConstructsTests::testTemplateAndFacts`  

**Problema**:
```swift
return .int(id)  // ❌ SBAGLIATO
```

**Fix**:
```swift
return .boolean(true)  // ✅ CORRETTO - come CLIPS C
```

**Status**: ✅ **RISOLTO** - Test passa

---

## 🔍 Bug Da Risolvere

### 2. **OR CE crea attivazioni duplicate**
**File**: `evaluator.swift:187-202`, `ruleengine.swift:40-63`  
**Test**: `RuleOrAndMultifieldTests::testOrCEExpandsAndFires`  

**Problema**:
- OR CE espande in multiple regole (disjuncts) come dovrebbe
- Ma ENTRAMBE le regole vengono aggiunte alla RETE
- Risultato: 2 attivazioni invece di 1

**Esempio**:
```clp
(defrule r (or (A v ?x) (B v ?x)) (C v ?x) => (printout t "O"))
```

Crea:
- `r` (con pattern A)  
- `r$or1` (con pattern B)

Entrambe si attivano quando dovrebbe attivarsene solo una.

**Root Cause** (da verificare):
```swift
// evaluator.swift:232
for (i, pats) in altSets.enumerated() {
    let rname = (i == 0) ? ruleName : (ruleName + "$or" + String(i))
    var rule = Rule(...)
    // ... 
    RuleEngine.addRule(&env, rule)  // ← Aggiunge TUTTE le regole
}
```

Entrambe le regole vengono aggiunte come regole indipendenti. In CLIPS C, i disjuncts condividono l'attivazione o uno solo dovrebbe attivarsi per evento.

**Soluzione proposta**:
- Verificare come CLIPS C gestisce i disjuncts
- Probabilmente solo il PRIMO disjunct che matcha dovrebbe attivarsi
- Oppure deduplicare per `displayName` invece di `name`

---

### 3. **NOT + test combinati non filtrano**
**File**: `evaluator.swift:203-210`, `ruleengine.swift`  
**Test**: `RuleNotTestCombinedTests::testNotWithTestFiltersAsExpected`  

**Problema**:
```clp
(defrule r 
  (A v ?x) 
  (not (B v ?x)) 
  (test (> ?x 1)) 
  => 
  (printout t "OK"))
```

Expected: 1 activation (solo per A v 2, non per A v 1)  
Got: 2 activations

**Root Cause**:
- Il test `(test (> ?x 1))` sembra non filtrare correttamente
- Oppure NOT + test combinati creano logica sbagliata
- Variabile `?x` deve essere bound da (A v ?x) e verificata nel test

**Analisi**:
```swift
// evaluator.swift:219-225
if n.type == .fcall {
    if let (p, preds) = parseSimplePattern(&env, n) {
        altSets = altSets.map { $0 + [p] }
        for pr in preds { tests.append(pr) }  // ← test aggiunti separatamente
    }
}
```

I test vengono estratti dai pattern ma forse non valutati correttamente nella RETE.

---

### 4. **Test predicati inline in slot non funzionano**
**File**: Parser, Pattern matching  
**Test**: `RuleSlotTestTests::testSlotInternalTestUsesBoundVar`  

**Problema**:
```clp
(defrule r 
  (rec a ?x b (test (> ?x 10))) 
  => 
  (printout t "OK" crlf))
```

Expected: Fire solo se ?x > 10  
Got: Fire sempre (o mai)

**Root Cause**:
Test inline in slot `b (test (> ?x 10))` non viene parsato o valutato correttamente.

**CLIPS C**:
In `pattern.c` e `factlhs.c`, i test inline sono integrati nel pattern matching.

**SLIPS**:
Il parser probabilmente ignora o non gestisce test inline negli slot.

---

### 5. **Retract incrementale non rimuove attivazioni**
**Test**: Multiple test su retract

**Problema**:
Quando un fatto viene retratto, le attivazioni che dipendono da esso dovrebbero essere rimosse.

**Files coinvolti**:
- `Propagation.swift::propagateRetract`
- `functions.swift::builtin_retract`
- `ruleengine.swift::onRetract` (se esiste)

**Status**: Da analizzare

---

### 6. **JoinWhitelistStableTests fallisce**
**Problema**: Join stability detection non funziona con RETE esplicita

**Root Cause**: Forse un flag experimental che ora è sempre true/false

**Status**: Bassa priorità

---

## 📊 Priorità

| Bug | Priorità | Complessità | Impatto |
|-----|----------|-------------|---------|
| 1. retract boolean | ✅ FATTO | Bassa | Alto |
| 2. OR duplicati | 🔴 ALTA | Media | Alto |
| 3. NOT + test | 🔴 ALTA | Alta | Alto |
| 4. Test inline slot | 🟡 MEDIA | Alta | Medio |
| 5. Retract incrementale | 🟡 MEDIA | Media | Medio |
| 6. Join whitelist | 🟢 BASSA | Bassa | Basso |

---

## 🎯 Prossimi Passi

1. ✅ Fix retract boolean - **FATTO**
2. 🔄 Analizzare OR disjuncts in CLIPS C
3. 🔄 Verificare test evaluation nella RETE
4. 🔄 Implementare test inline in slot

**Obiettivo**: 100% test pass entro fine giornata

---

**Aggiornato**: 17 Ottobre 2025 22:04

