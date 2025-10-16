;;; ============================================
;;; SLIPS Example 7: Modules System
;;; ============================================
;;;
;;; Dimostra il sistema moduli SLIPS:
;;; - defmodule con import/export
;;; - Focus stack
;;; - Organizzazione codice
;;;
;;; Per eseguire:
;;;   SLIPS> (load "Examples/07_ModulesDemo.clp")
;;;   SLIPS> (reset)
;;;   SLIPS> (run)

;;; Modulo principale
(defmodule MAIN
   (export ?ALL))

;;; Modulo per validazione dati
(defmodule VALIDATION
   (import MAIN ?ALL)
   (export deftemplate data-valid))

;;; Modulo per elaborazione
(defmodule PROCESSING
   (import MAIN ?ALL)
   (import VALIDATION deftemplate data-valid)
   (export ?ALL))

;;; Modulo per output
(defmodule OUTPUT
   (import MAIN ?ALL)
   (import PROCESSING ?ALL))

;;; === Template nel modulo MAIN ===
(deftemplate data
   (slot value)
   (slot status (default pending)))

;;; === Template nel modulo VALIDATION ===
(defmodule VALIDATION)

(deftemplate data-valid
   (slot value)
   (slot validated (default no)))

;;; === Regole VALIDATION ===
(defrule VALIDATION::validate-positive
   (declare (salience 100))
   ?d <- (data (value ?v) (status pending))
   (test (> ?v 0))
   =>
   (modify ?d (status validated))
   (assert (data-valid (value ?v) (validated yes)))
   (printout t "[VALIDATION] Value " ?v " is valid" crlf))

(defrule VALIDATION::reject-negative
   (declare (salience 100))
   ?d <- (data (value ?v) (status pending))
   (test (<= ?v 0))
   =>
   (modify ?d (status rejected))
   (printout t "[VALIDATION] Value " ?v " rejected (not positive)" crlf))

;;; === Regole PROCESSING ===
(defmodule PROCESSING)

(defrule PROCESSING::process-data
   (declare (salience 50))
   ?dv <- (data-valid (value ?v) (validated yes))
   =>
   (bind ?squared (** ?v 2))
   (bind ?sqrt (sqrt ?v))
   (printout t "[PROCESSING] Value: " ?v crlf)
   (printout t "  Squared: " ?squared crlf)
   (printout t "  Sqrt: " ?sqrt crlf)
   (retract ?dv))

;;; === Regole OUTPUT ===
(defmodule OUTPUT)

(defrule OUTPUT::show-summary
   (declare (salience -100))
   =>
   (printout t crlf "[OUTPUT] Processing complete!" crlf)
   (printout t "Current module: " (get-current-module) crlf))

;;; === Deffacts MAIN ===
(defmodule MAIN)

(deffacts test-data
   (data (value 5))
   (data (value -3))
   (data (value 16))
   (data (value 0))
   (setup-focus))

;;; Setup focus stack
(defrule MAIN::setup-focus-stack
   ?sf <- (setup-focus)
   =>
   (printout t "=== MODULES DEMO ===" crlf)
   (printout t "Setting up focus stack..." crlf)
   (focus VALIDATION PROCESSING OUTPUT)
   (printout t "Focus stack: VALIDATION → PROCESSING → OUTPUT" crlf crlf)
   (retract ?sf))

;;; Output atteso:
;;; === MODULES DEMO ===
;;; Setting up focus stack...
;;; Focus stack: VALIDATION → PROCESSING → OUTPUT
;;;
;;; [VALIDATION] Value 5 is valid
;;; [VALIDATION] Value -3 rejected (not positive)
;;; [VALIDATION] Value 16 is valid
;;; [VALIDATION] Value 0 rejected (not positive)
;;; [PROCESSING] Value: 5
;;;   Squared: 25.0
;;;   Sqrt: 2.236...
;;; [PROCESSING] Value: 16
;;;   Squared: 256.0
;;;   Sqrt: 4.0
;;; [OUTPUT] Processing complete!
;;; Current module: OUTPUT

