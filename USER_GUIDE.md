# 📖 SLIPS User Guide

**Versione**: 0.96  
**Data**: 16 Ottobre 2025  
**Lingua**: Italiano

---

## 📋 Indice

1. [Introduzione a SLIPS](#1-introduzione-a-slips)
2. [Facts e Templates](#2-facts-e-templates)
3. [Rules e Pattern Matching](#3-rules-e-pattern-matching)
4. [Agenda e Strategie](#4-agenda-e-strategie)
5. [Moduli e Focus](#5-moduli-e-focus)
6. [Funzioni Builtin](#6-funzioni-builtin)
7. [Best Practices](#7-best-practices)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Introduzione a SLIPS

### 1.1 Cos'è SLIPS?

**SLIPS** (Swift Language Implementation of Production Systems) è un motore di produzione basato su regole, port fedele di CLIPS 6.4.2 in Swift 6.

**Caratteristiche principali**:
- ✅ **96% compatibile** con CLIPS 6.4.2
- ✅ **165 funzioni builtin**
- ✅ **Type-safe** e **Memory-safe**
- ✅ **Zero dipendenze** (solo Foundation)
- ✅ **Production-ready**

### 1.2 Installazione

#### Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/gpicchiarelli/SLIPS.git", from: "0.96.0")
]
```

#### Da Sorgenti

```bash
git clone https://github.com/gpicchiarelli/SLIPS.git
cd SLIPS
swift build
swift test  # Verifica installazione
```

### 1.3 Primo Programma

```swift
import SLIPS

// Crea environment
CLIPS.createEnvironment()

// Definisci regola
CLIPS.eval(expr: """
(defrule hello
   (initial-fact)
   =>
   (printout t "Hello, SLIPS!" crlf))
""")

// Run
CLIPS.reset()
CLIPS.run(limit: nil)
// Output: Hello, SLIPS!
```

### 1.4 REPL Interattiva

```bash
$ swift run slips-cli

SLIPS> (+ 2 3)
5
SLIPS> (str-cat "Hello" " " "World")
"Hello World"
SLIPS> (sqrt 16)
4.0
SLIPS> (exit)
```

---

## 2. Facts e Templates

### 2.1 Deftemplate

I **template** definiscono la struttura dei fatti:

```clp
; Template semplice
(deftemplate person
   (slot name)
   (slot age))

; Template con default
(deftemplate task
   (slot title (default "untitled"))
   (slot priority (default low))
   (slot status (default pending)))

; Template con multifield
(deftemplate project
   (slot name)
   (multislot team-members)
   (multislot tags))
```

### 2.2 Assert Facts

```clp
; Assert fatto semplice
(assert (person (name "Alice") (age 30)))
; ==> f-1

; Assert con default
(assert (task (title "Review code")))
; ==> f-2 (priority low, status pending da default)

; Assert con multifield
(assert (project 
   (name "SLIPS")
   (team-members John Jane Bob)
   (tags expert-system swift production-rules)))
; ==> f-3
```

### 2.3 Retract Facts

```clp
; Retract per fact-id
(retract 1)

; Retract in regola
(defrule cleanup
   ?f <- (temp-data)
   =>
   (retract ?f))
```

### 2.4 Modify e Duplicate

**modify** - Modifica fatto esistente:

```clp
(assert (person (name "John") (age 30)))  ; f-1
(modify 1 (age 31))                        ; Aggiorna età
```

**duplicate** - Duplica con modifiche:

```clp
(duplicate 1 (name "Jane"))  ; f-2: Jane, 31 anni
(duplicate 1 (name "Bob") (age 25))  ; f-3: Bob, 25 anni
```

### 2.5 Template Introspection

```clp
; Lista slot
(deftemplate-slot-names person)
; → (create$ name age)

; Check tipo
(deftemplate-slot-multip project team-members)
; → TRUE

(deftemplate-slot-singlep person name)
; → TRUE

; Check esistenza
(deftemplate-slot-existp person salary)
; → FALSE
```

### 2.6 Query Facts

```clp
; Lista fatti
(facts)

; Check esistenza
(fact-existp 1)  ; → TRUE se f-1 esiste

; Find all facts (base)
(find-all-facts ((?p person)) TRUE)
; → lista tutti i person facts
```

---

## 3. Rules e Pattern Matching

### 3.1 Defrule Base

```clp
(defrule simple-rule
   (trigger)
   =>
   (printout t "Rule fired!" crlf))
```

### 3.2 Pattern con Variabili

```clp
; Single-field variable
(defrule greet-person
   (person (name ?n) (age ?a))
   =>
   (printout t "Hello " ?n ", age " ?a crlf))

; Multifield variable
(defrule show-tags
   (project (name ?n) (tags $?t))
   =>
   (printout t "Project " ?n " tags: " $?t crlf))
```

### 3.3 Test Constraints

```clp
; Test semplice
(defrule adults-only
   (person (name ?n) (age ?a))
   (test (>= ?a 18))
   =>
   (printout t ?n " is an adult" crlf))

; Test multipli
(defrule validate-range
   (value ?v)
   (test (> ?v 0))
   (test (< ?v 100))
   =>
   (printout t ?v " is in valid range" crlf))
```

### 3.4 NOT Conditional Element

```clp
; NOT: assenza di pattern
(defrule no-errors-found
   (scan-complete)
   (not (error))
   =>
   (printout t "All OK!" crlf))

; NOT con variabili
(defrule unique-username
   (user (username ?u))
   (not (duplicate-user (username ?u)))
   =>
   (printout t "Username " ?u " is unique" crlf))
```

### 3.5 EXISTS Conditional Element

```clp
; EXISTS: almeno uno
(defrule has-high-priority
   (exists (task (priority high)))
   =>
   (printout t "At least one high priority task" crlf))
```

### 3.6 OR Patterns

```clp
; OR tra pattern
(defrule urgent-or-critical
   (or (task (priority urgent))
       (task (priority critical)))
   =>
   (printout t "Urgent task found!" crlf))
```

### 3.7 Salience

```clp
; Priorità con salience
(defrule high-priority
   (declare (salience 100))
   (critical-alert)
   =>
   (printout t "CRITICAL!" crlf))

(defrule low-priority
   (declare (salience -10))
   (info-message)
   =>
   (printout t "Info..." crlf))
```

---

## 4. Agenda e Strategie

### 4.1 Conflict Resolution Strategies

SLIPS supporta 4 strategie di risoluzione conflitti:

```clp
; DEPTH (default) - LIFO
(set-strategy depth)

; BREADTH - FIFO
(set-strategy breadth)

; LEX - Lexicographic sort
(set-strategy lex)

; Check strategia corrente
(get-strategy)  ; → depth
```

### 4.2 Agenda Management

```clp
; Mostra agenda
(agenda)

; Esegui regole
(run)              ; Esegui tutte
(run 10)           ; Esegui max 10
```

### 4.3 Watch System

```clp
; Abilita watch
(watch facts)      ; Mostra assert/retract
(watch rules)      ; Mostra rule firing
(watch rete)       ; Mostra RETE operations

; Disabilita
(unwatch facts)
(unwatch all)
```

---

## 5. Moduli e Focus

### 5.1 Defmodule

```clp
; Modulo con export
(defmodule UTILITIES
   (export deftemplate data-record)
   (export defrule process-data))

; Modulo con import
(defmodule DATA-PROCESSING
   (import UTILITIES deftemplate data-record)
   (export ?ALL))
```

### 5.2 Focus Stack

```clp
; Imposta focus
(focus UTILITIES)

; Focus multiplo (LIFO)
(focus MODULE-A MODULE-B MODULE-C)
; Stack: MODULE-C (top), MODULE-B, MODULE-A

; Ottieni modulo corrente
(get-current-module)  ; → MODULE-C

; Cambia modulo
(set-current-module MAIN)
```

### 5.3 Comandi Moduli

```clp
; Lista moduli
(list-defmodules)

; Ottieni come multifield
(get-defmodule-list)
; → (create$ MAIN UTILITIES DATA-PROCESSING)

; Pretty print
(ppdefmodule UTILITIES)
```

---

## 6. Funzioni Builtin

SLIPS ha **165 funzioni builtin**. Ecco le categorie principali:

### 6.1 String Functions (11)

```clp
; Concatenazione
(str-cat "Hello" " " "World")  → "Hello World"
(sym-cat rule- 42)              → rule-42

; Manipolazione
(upcase "hello")                → "HELLO"
(lowcase "WORLD")               → "world"
(sub-string 1 5 "Hello World") → "Hello"
(str-replace "abc" "a" "X")    → "Xbc"

; Ricerca
(str-index "World" "Hello World")  → 7
(str-compare "abc" "def")          → -1

; Lunghezza
(str-length "café")            → 4  (caratteri UTF-8)
(str-byte-length "café")       → 5  (byte UTF-8)

; Conversione
(string-to-field "42")         → 42
(string-to-field "3.14")       → 3.14
```

### 6.2 Math Functions (36) - 100% CLIPS!

```clp
; Trigonometriche
cos, sin, tan, sec, csc, cot
acos, asin, atan, atan2, asec, acsc, acot

; Iperboliche
cosh, sinh, tanh, sech, csch, coth
acosh, asinh, atanh, asech, acsch, acoth

; Esponenziali
exp, log, log10, sqrt, **

; Utilità
abs, mod, round, pi, deg-rad, rad-deg

; Esempio
(sqrt (+ (** 3 2) (** 4 2)))  → 5.0  (Pitagora)
(round 3.5)                    → 4    (away from zero)
```

### 6.3 Multifield Functions (10) - 100% CLIPS!

```clp
(nth$ 2 (create$ a b c))       → b
(length$ (create$ 1 2 3))      → 3
(first$ (create$ a b c))       → (create$ a)
(rest$ (create$ a b c))        → (create$ b c)
(subseq$ (create$ 1 2 3 4) 2 3) → (create$ 2 3)
(member$ b (create$ a b c))    → 2
(insert$ (create$ a c) 2 b)    → (create$ a b c)
(delete$ (create$ a b c) 2 2)  → (create$ a c)
(explode$ "a b c")             → (create$ a b c)
(implode$ (create$ a b c))     → "a b c"
```

### 6.4 Template Functions (10)

```clp
; Manipulation
modify, duplicate

; Introspection
deftemplate-slot-names
deftemplate-slot-default-value
deftemplate-slot-cardinality
deftemplate-slot-types
deftemplate-slot-range
deftemplate-slot-multip
deftemplate-slot-singlep
deftemplate-slot-existp
```

### 6.5 I/O Functions (13)

```clp
; Input
read, readline, read-number, get-char

; Output
printout, print, println, put-char, flush

; File operations
open, close, remove, rename, format
```

### 6.6 Globals Functions (8)

```clp
; Definizione
(defglobal ?*debug* = TRUE)
(defglobal ?*counter* = 0)

; Gestione
show-defglobals
list-defglobals
undefglobal
get-defglobal-list
ppdefglobal
get/set-defglobal-watch
```

### 6.7 Utility Functions (6)

```clp
(gensym)           ; gen1
(gensym* rule-)    ; rule-2
(random 1 100)     ; Casuale
(seed 42)          ; Set seed
(time)             ; Timestamp
(funcall + 2 3)    ; Dynamic call → 5
```

### 6.8 Fact Query Functions (7)

```clp
find-fact
find-all-facts
do-for-fact
do-for-all-facts
any-factp
fact-existp
fact-index
```

### 6.9 Pretty Print Functions (4)

```clp
(ppdefmodule MAIN)
(ppdeffacts startup)
(ppdefrule my-rule)
(ppdeftemplate person)
```

### 6.10 Lista Completa

Vedi [FUNZIONI_REFERENCE.md](FUNZIONI_REFERENCE.md) per la lista completa di tutte le 165 funzioni.

---

## 7. Best Practices

### 7.1 Naming Conventions

```clp
; Template names: lowercase con trattini
(deftemplate user-account ...)
(deftemplate order-item ...)

; Slot names: lowercase
(slot first-name)
(slot total-amount)

; Rule names: descrittive
(defrule validate-email-format ...)
(defrule calculate-discount ...)

; Globals: ?*nome*
(defglobal ?*debug-mode* = FALSE)
(defglobal ?*max-retries* = 3)
```

### 7.2 Organizzazione Codice

```clp
;;; ===========================
;;; MODULE: VALIDATION
;;; ===========================

(defmodule VALIDATION
   (export ?ALL))

;;; --- Templates ---

(deftemplate validation-result
   (slot field)
   (slot valid)
   (slot message))

;;; --- Rules ---

(defrule validate-email
   ...
   )
```

### 7.3 Performance

**Usa salience con parsimonia**:
```clp
; GOOD: salience solo quando necessario
(defrule critical-alert
   (declare (salience 100))
   (emergency)
   =>
   ...)

; BAD: salience ovunque
(defrule normal-task
   (declare (salience 50))  ; Non necessario!
   ...)
```

**Ottimizza pattern order**:
```clp
; GOOD: pattern più selettivo prima
(defrule efficient
   (rare-condition ?x)        ; Pochi match
   (common-condition ?y)      ; Molti match
   =>
   ...)

; BAD: pattern generico prima
(defrule inefficient
   (common-condition ?y)      ; Molti match
   (rare-condition ?x)        ; Pochi match
   =>
   ...)
```

### 7.4 Debugging

```clp
; Abilita watch
(watch facts)
(watch rules)

; Inserisci debug print
(defrule my-rule
   ?f <- (data ?x)
   =>
   (printout t "DEBUG: Processing " ?x crlf)
   ...)

; Usa ppdefrule per vedere regola
(ppdefrule my-rule)
```

### 7.5 Testing

```swift
// Test in Swift
func testMyRule() throws {
    CLIPS.reset()
    CLIPS.createEnvironment()
    
    CLIPS.eval(expr: "(deftemplate ...)")
    CLIPS.eval(expr: "(defrule ...)")
    CLIPS.assert(fact: "(trigger)")
    
    CLIPS.reset()
    let fired = CLIPS.run(limit: nil)
    
    XCTAssertEqual(fired, 1)
}
```

---

## 8. Troubleshooting

### 8.1 Problemi Comuni

**Problema**: Regola non si attiva

```clp
; Verifica fatti
(facts)

; Verifica agenda
(agenda)

; Verifica pattern
(ppdefrule my-rule)

; Watch per debug
(watch facts)
(watch rules)
(reset)
(run)
```

**Problema**: Pattern non matcha

```clp
; Verifica template
(ppdeftemplate my-template)

; Verifica valori slot
(assert (debug-fact (slot value)))
(facts)  ; Controlla valori effettivi
```

**Problema**: Ordine firing errato

```clp
; Check strategia
(get-strategy)

; Usa salience
(defrule high-priority
   (declare (salience 100))
   ...)
```

### 8.2 Error Messages

**"Template does not exist"**:
```clp
; ERRORE
(assert (person (name "John")))

; SOLUZIONE: definisci template prima
(deftemplate person (slot name))
(assert (person (name "John")))
```

**"Slot does not exist"**:
```clp
; ERRORE
(assert (person (salary 1000)))  ; slot 'salary' non definito

; SOLUZIONE
(deftemplate person (slot name) (slot salary))
(assert (person (salary 1000)))
```

**"Wrong argument count"**:
```clp
; ERRORE
(str-cat)  ; str-cat richiede argomenti

; SOLUZIONE
(str-cat "a" "b")  ; → "ab"
```

### 8.3 Performance Issues

**Problema**: Run lento

1. **Riduci pattern generici**:
   ```clp
   ; LENTO
   (defrule check-all
      (data ?x)  ; Matcha TUTTI i data facts
      ...)
   
   ; VELOCE
   (defrule check-specific
      (data ?x&:(> ?x 100))  ; Filtra subito
      ...)
   ```

2. **Usa NOT con cautela**:
   ```clp
   ; Costoso con molti fatti
   (not (processed ?x))
   ```

3. **Watch rete-profile**:
   ```clp
   (watch rete-profile)
   (reset)
   (run)
   ; Mostra tempi per livello RETE
   ```

### 8.4 Memory Issues

SLIPS gestisce memoria automaticamente (Swift ARC), ma:

```swift
// Chiudi file aperti
CLIPS.eval(expr: "(close)")

// Reset environment se necessario
CLIPS.reset()  // Rimuove fatti, mantiene regole

// Clear completo
CLIPS.eval(expr: "(clear)")  // Rimuove tutto
```

### 8.5 Getting Help

- 📖 [Documentazione Online](https://gpicchiarelli.github.io/SLIPS/)
- 💡 [Esempi Pratici](Examples/)
- 🐛 [GitHub Issues](https://github.com/gpicchiarelli/SLIPS/issues)
- 📚 [FUNZIONI_REFERENCE.md](FUNZIONI_REFERENCE.md)
- 🎓 [Contributing Guidelines](CONTRIBUTING.md) per contributori

---

## 📝 Appendice: Differenze con CLIPS C

### Differenze Sintattiche

| Feature | CLIPS C | SLIPS |
|---------|---------|-------|
| Comments | `;` | `;` (uguale) |
| Multifield | `$?var` | `$?var` (uguale) |
| Globals | `?*var*` | `?*var*` (uguale) |
| Strings | `"text"` | `"text"` (uguale) |

### Funzioni Non Implementate (25)

**I/O Advanced** (7): rewind, seek, tell, unget-char, set-locale, chdir, with-open-file

**Template Advanced** (3): slot-facet-existp, slot-facet-value, slot-defaultp

**Utility** (2): release-mem, operating-system

**Altri** (13): Vari edge case

**Impatto**: < 1% use cases

### Funzioni Extra SLIPS

SLIPS include **21 funzioni experimental** per RETE tuning:
- `set-join-check`, `get-join-check`
- `set-join-activate`, etc.

---

## 🎊 Conclusione

**SLIPS è production-ready!**

- ✅ 96% compatibile CLIPS
- ✅ 165 funzioni builtin
- ✅ Type-safe e Memory-safe
- ✅ Documentazione completa
- ✅ 10 esempi pratici
- ✅ 250+ test

**Inizia ora**:
1. Prova [Examples/01_HelloWorld.clp](Examples/01_HelloWorld.clp)
2. Leggi gli altri [esempi](Examples/)
3. Consulta l'[API Reference](FUNZIONI_REFERENCE.md)
4. [Contribuisci](CONTRIBUTING.md) al progetto!

---

**Ultimo aggiornamento**: 16 Ottobre 2025  
**Versione**: 0.96  
**Status**: Production-Ready ✨

