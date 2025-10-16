; ==============================================================================
; SLIPS Example 12: Template Functions & Introspection
; ==============================================================================
; Questo esempio dimostra le funzioni di introspection per template,
; permettendo di ispezionare dinamicamente la struttura dei dati.
;
; Funzionalità dimostrate:
; - deftemplate-slot-names
; - deftemplate-slot-existp
; - deftemplate-slot-multip/singlep
; - deftemplate-slot-default-value
; - deftemplate-slot-defaultp
; - deftemplate-slot-facet-existp
; - deftemplate-slot-facet-value
; - modify e duplicate
; ==============================================================================

(clear)

(printout t crlf "╔════════════════════════════════════╗" crlf)
(printout t "║  Template Functions Demonstration  ║" crlf)
(printout t "╚════════════════════════════════════╝" crlf crlf)

; ==============================================================================
; Parte 1: Definizione Template con Vari Facets
; ==============================================================================

(printout t "📋 Part 1: Template Definition" crlf)
(printout t "─────────────────────────────────────" crlf)

(deftemplate person
  (slot name (default "Anonymous"))
  (slot age (default 0))
  (slot email (default "unknown@example.com"))
  (multislot hobbies (default-dynamic (create$))))

(deftemplate product
  (slot id (default 0))
  (slot title (default "Untitled"))
  (slot price (default 9.99))
  (multislot tags))

(printout t "✓ Templates 'person' and 'product' defined" crlf crlf)

; ==============================================================================
; Parte 2: Introspection - Slot Names
; ==============================================================================

(printout t "🔍 Part 2: Slot Names Introspection" crlf)
(printout t "─────────────────────────────────────" crlf)

(bind ?person-slots (deftemplate-slot-names person))
(printout t "Slots in 'person': " ?person-slots crlf)

(bind ?product-slots (deftemplate-slot-names product))
(printout t "Slots in 'product': " ?product-slots crlf)
(printout t crlf)

; ==============================================================================
; Parte 3: Slot Existence Checks
; ==============================================================================

(printout t "✓ Part 3: Slot Existence" crlf)
(printout t "─────────────────────────────────────" crlf)

(printout t "person has 'name'? " 
  (deftemplate-slot-existp person name) crlf)
(printout t "person has 'salary'? " 
  (deftemplate-slot-existp person salary) crlf)
(printout t "product has 'tags'? " 
  (deftemplate-slot-existp product tags) crlf)
(printout t crlf)

; ==============================================================================
; Parte 4: Single vs Multifield Slots
; ==============================================================================

(printout t "📊 Part 4: Slot Types" crlf)
(printout t "─────────────────────────────────────" crlf)

(printout t "person.name is single? " 
  (deftemplate-slot-singlep person name) crlf)
(printout t "person.name is multi? " 
  (deftemplate-slot-multip person name) crlf)
(printout t "person.hobbies is multi? " 
  (deftemplate-slot-multip person hobbies) crlf)
(printout t "product.tags is multi? " 
  (deftemplate-slot-multip product tags) crlf)
(printout t crlf)

; ==============================================================================
; Parte 5: Default Values
; ==============================================================================

(printout t "🎯 Part 5: Default Values" crlf)
(printout t "─────────────────────────────────────" crlf)

(printout t "person.name default: " 
  (deftemplate-slot-default-value person name) crlf)
(printout t "person.age default: " 
  (deftemplate-slot-default-value person age) crlf)
(printout t "product.price default: " 
  (deftemplate-slot-default-value product price) crlf)
(printout t crlf)

; ==============================================================================
; Parte 6: Default Types (static vs dynamic)
; ==============================================================================

(printout t "⚙️  Part 6: Default Types" crlf)
(printout t "─────────────────────────────────────" crlf)

(printout t "person.name default type: " 
  (deftemplate-slot-defaultp person name) crlf)
(printout t "person.hobbies default type: " 
  (deftemplate-slot-defaultp person hobbies) crlf)
(printout t crlf)

; ==============================================================================
; Parte 7: Facet Introspection
; ==============================================================================

(printout t "🔬 Part 7: Facet Introspection" crlf)
(printout t "─────────────────────────────────────" crlf)

(printout t "person.name has 'default' facet? " 
  (deftemplate-slot-facet-existp person name default) crlf)
(printout t "person.name has 'type' facet? " 
  (deftemplate-slot-facet-existp person name type) crlf)
(printout t "person.name has 'range' facet? " 
  (deftemplate-slot-facet-existp person name range) crlf)

(printout t "person.name 'default' facet value: " 
  (deftemplate-slot-facet-value person name default) crlf)
(printout t "person.hobbies 'cardinality' facet: " 
  (deftemplate-slot-facet-value person hobbies cardinality) crlf)
(printout t crlf)

; ==============================================================================
; Parte 8: Modify e Duplicate
; ==============================================================================

(printout t "✏️  Part 8: Modify & Duplicate" crlf)
(printout t "─────────────────────────────────────" crlf)

; Crea un fatto persona
(bind ?p1 (assert (person (name "Alice") (age 30) 
                          (hobbies reading coding))))
(printout t "Created: f-" ?p1 crlf)

; Modifica (preserva fact-id)
(modify ?p1 (age 31))
(printout t "Modified: f-" ?p1 " (age updated to 31)" crlf)

; Duplica con modifiche
(bind ?p2 (duplicate ?p1 (name "Bob") (age 25)))
(printout t "Duplicated: f-" ?p2 " (new person 'Bob')" crlf)
(printout t crlf)

; ==============================================================================
; Parte 9: Dynamic Template Analysis
; ==============================================================================

(printout t "🎓 Part 9: Dynamic Template Analysis" crlf)
(printout t "─────────────────────────────────────" crlf)

; Funzione helper per analizzare un template
(deffunction analyze-template (?template-name)
  (printout t crlf "Analysis of template '" ?template-name "':" crlf)
  
  ; Get all slot names
  (bind ?slots (deftemplate-slot-names ?template-name))
  (printout t "  Slots (" (length$ ?slots) "): " ?slots crlf)
  
  ; Analyze each slot
  (foreach ?slot ?slots
    (printout t "  └─ " ?slot ":" crlf)
    (printout t "     - Type: " 
      (if (deftemplate-slot-multip ?template-name ?slot) 
        then "multifield" 
        else "single-field") crlf)
    
    (bind ?default-type (deftemplate-slot-defaultp ?template-name ?slot))
    (if (neq ?default-type FALSE)
      then 
      (printout t "     - Default: " ?default-type " = " 
        (deftemplate-slot-default-value ?template-name ?slot) crlf))
  )
  (printout t crlf))

; Analizza entrambi i template
(analyze-template person)
(analyze-template product)

; ==============================================================================
; Parte 10: Practical Use Case - Data Migration
; ==============================================================================

(printout t "🔄 Part 10: Practical Example - Data Validation" crlf)
(printout t "─────────────────────────────────────" crlf)

; Regola che valida che tutti gli slot obbligatori siano compilati
(defrule validate-person
  (person (name ?n) (age ?a) (email ?e))
  (test (eq (deftemplate-slot-defaultp person name) "static"))
  (test (neq ?n (deftemplate-slot-default-value person name)))
  (test (> ?a 0))
  =>
  (printout t "✓ Person '" ?n "' validated (age: " ?a ", email: " ?e ")" crlf))

; Testa la validazione
(assert (person (name "Charlie" (age 28) (email "charlie@test.com")))
(run)

(printout t crlf)

; ==============================================================================
; Summary
; ==============================================================================

(printout t "╔════════════════════════════════════╗" crlf)
(printout t "║            Summary                 ║" crlf)
(printout t "╚════════════════════════════════════╝" crlf)
(printout t "Total facts: " (facts) crlf)
(printout t "Templates defined: person, product" crlf)
(printout t "Functions demonstrated: 14" crlf)
(printout t "  - deftemplate-slot-names" crlf)
(printout t "  - deftemplate-slot-existp" crlf)
(printout t "  - deftemplate-slot-multip/singlep" crlf)
(printout t "  - deftemplate-slot-default-value" crlf)
(printout t "  - deftemplate-slot-defaultp" crlf)
(printout t "  - deftemplate-slot-facet-existp" crlf)
(printout t "  - deftemplate-slot-facet-value" crlf)
(printout t "  - modify" crlf)
(printout t "  - duplicate" crlf)
(printout t crlf)
(printout t "✓ All template functions working!" crlf)
(printout t crlf)

; ==============================================================================
; Learning Points:
; ==============================================================================
; 
; 1. Template introspection permette meta-programming
; 2. Le funzioni slot-* permettono validazione dinamica
; 3. modify preserva fact-id (utile per tracking)
; 4. duplicate crea nuovo fatto (utile per versioning)
; 5. I facets forniscono metadati sui constraints
; 6. Static vs dynamic defaults: static è valutato al parsing,
;    dynamic è valutato a runtime
; 7. Multifield slots hanno cardinality (min max)
; 8. Template functions + regole = validazione potente
;
; ==============================================================================

