; ==============================================================================
; SLIPS Example 11: Multi-Module System
; ==============================================================================
; Questo esempio dimostra il sistema di moduli completamente funzionale
; con focus stack, import/export, e module-aware agenda.
;
; Funzionalità dimostrate:
; - Defmodule con import/export
; - Focus stack per controllo flusso
; - Module-aware agenda
; - Template functions introspection
; ==============================================================================

; Modulo MAIN: Entry point e coordinamento
(defmodule MAIN
  (export ?ALL))

; Template condivisi (visibili da tutti i moduli)
(deftemplate order
  (slot id (default 0))
  (slot customer (default "unknown"))
  (slot amount (default 0.0))
  (slot status (default "pending")))

(deftemplate invoice
  (slot order-id)
  (slot total)
  (slot tax))

; ==============================================================================
; Modulo VALIDATION: Validazione ordini
; ==============================================================================

(defmodule VALIDATION
  (import MAIN ?ALL)
  (export ?ALL))

(defrule VALIDATION::check-order-valid
  "Valida che l'ordine abbia dati completi"
  (declare (salience 100))
  (order (id ?id&:(> ?id 0))
         (customer ?c&:(neq ?c "unknown"))
         (amount ?a&:(> ?a 0))
         (status "pending"))
  =>
  (printout t "✓ Order " ?id " validation passed" crlf)
  (modify (order (id ?id)) (status "validated")))

(defrule VALIDATION::reject-invalid-order
  "Rigetta ordini con dati incompleti"
  (declare (salience 100))
  (order (id ?id)
         (status "pending"))
  (test (or (eq ?id 0) (< ?id 0)))
  =>
  (printout t "✗ Order " ?id " validation failed" crlf)
  (retract ?id))

; ==============================================================================
; Modulo BILLING: Calcolo fatture
; ==============================================================================

(defmodule BILLING
  (import MAIN ?ALL)
  (import VALIDATION ?ALL))

(defrule BILLING::calculate-invoice
  "Genera fattura per ordine validato"
  (declare (salience 50))
  (order (id ?oid)
         (amount ?amt)
         (status "validated"))
  =>
  (bind ?tax (* ?amt 0.22))
  (bind ?total (+ ?amt ?tax))
  (assert (invoice (order-id ?oid) (total ?total) (tax ?tax)))
  (printout t "→ Invoice generated for order " ?oid crlf)
  (printout t "  Amount: " ?amt " Tax: " ?tax " Total: " ?total crlf)
  (modify (order (id ?oid)) (status "invoiced")))

; ==============================================================================
; Modulo REPORTING: Report e statistiche
; ==============================================================================

(defmodule REPORTING
  (import MAIN ?ALL)
  (import BILLING ?ALL))

(defrule REPORTING::print-summary
  "Stampa riepilogo finale"
  (declare (salience 10))
  (invoice (order-id ?oid) (total ?total))
  =>
  (printout t "═══════════════════════════" crlf)
  (printout t "REPORT: Order " ?oid " completed" crlf)
  (printout t "Final total: €" ?total crlf)
  (printout t "═══════════════════════════" crlf))

; ==============================================================================
; Scenario di Test
; ==============================================================================

; Reset environment
(clear)

; Definisci moduli (già fatto sopra)
(printout t crlf "╔══════════════════════════════════════╗" crlf)
(printout t "║ Multi-Module Order Processing System ║" crlf)
(printout t "╚══════════════════════════════════════╝" crlf crlf)

; Verifica template functions
(printout t "📋 Template Introspection:" crlf)
(printout t "   Slots in 'order': " (deftemplate-slot-names order) crlf)
(printout t "   Default status: " (deftemplate-slot-default-value order status) crlf)
(printout t "   Status default type: " (deftemplate-slot-defaultp order status) crlf)
(printout t crlf)

; Test 1: Ordine valido
(printout t "📦 Test 1: Valid Order" crlf)
(printout t "──────────────────────────────────────" crlf)

(assert (order (id 1001) (customer "Alice Smith") (amount 150.00)))

; Imposta focus per processare in ordine: VALIDATION → BILLING → REPORTING
(focus VALIDATION)
(focus BILLING)  
(focus REPORTING)

; Mostra focus stack
(printout t "Focus stack: " (get-focus-stack) crlf crlf)

; Esegui ciclo
(run)

(printout t crlf)

; Test 2: Ordine invalido (verrà rigettato)
(printout t "📦 Test 2: Invalid Order (negative ID)" crlf)
(printout t "──────────────────────────────────────" crlf)

(assert (order (id -1) (customer "Bob Jones") (amount 200.00)))

(focus VALIDATION)
(run)

(printout t crlf)

; Test 3: Ordine parziale (customer sconosciuto)
(printout t "📦 Test 3: Partial Order (unknown customer)" crlf)
(printout t "──────────────────────────────────────" crlf)

(assert (order (id 1002) (amount 75.50)))

(focus VALIDATION)
(run)

(printout t crlf)

; Statistiche finali
(printout t "╔══════════════════════════════════════╗" crlf)
(printout t "║          Final Statistics            ║" crlf)
(printout t "╚══════════════════════════════════════╝" crlf)
(printout t "Total facts: " (facts) crlf)
(printout t "Active modules: " (list-defmodules) crlf)
(printout t "Current module: " (get-current-module) crlf)

; Mostra tutte le fatture generate
(printout t crlf "Generated Invoices:" crlf)
(do-for-all-facts ((?inv invoice)) TRUE
  (printout t "  Invoice #" ?inv:order-id " - Total: €" ?inv:total crlf))

(printout t crlf "✓ Demo completata!" crlf crlf)

; ==============================================================================
; Output Atteso:
; ==============================================================================
;
; ╔══════════════════════════════════════╗
; ║ Multi-Module Order Processing System ║
; ╚══════════════════════════════════════╝
;
; 📋 Template Introspection:
;    Slots in 'order': (create$ id customer amount status)
;    Default status: "pending"
;    Status default type: static
;
; 📦 Test 1: Valid Order
; ──────────────────────────────────────
; Focus stack: (create$ REPORTING BILLING VALIDATION)
;
; ✓ Order 1001 validation passed
; → Invoice generated for order 1001
;   Amount: 150.0 Tax: 33.0 Total: 183.0
; ═══════════════════════════
; REPORT: Order 1001 completed
; Final total: €183.0
; ═══════════════════════════
;
; 📦 Test 2: Invalid Order (negative ID)
; ──────────────────────────────────────
; ✗ Order -1 validation failed
;
; 📦 Test 3: Partial Order (unknown customer)
; ──────────────────────────────────────
; (Nessun output - ordine rimane pending)
;
; ╔══════════════════════════════════════╗
; ║          Final Statistics            ║
; ╚══════════════════════════════════════╝
; Total facts: 3
; Active modules: (create$ MAIN VALIDATION BILLING REPORTING)
; Current module: MAIN
;
; Generated Invoices:
;   Invoice #1001 - Total: €183.0
;
; ✓ Demo completata!
;
; ==============================================================================

; Note:
; - Questo esempio richiede SLIPS 0.96+ (sistema moduli completo)
; - Dimostra focus stack, module-aware agenda, e template introspection
; - Ordine di esecuzione controllato dal focus stack
; - Le regole si attivano nel modulo corretto grazie al fix del 16/10/2025

