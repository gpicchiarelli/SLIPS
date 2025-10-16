;;; ============================================
;;; SLIPS Example 6: Template Manipulation
;;; ============================================
;;;
;;; Dimostra le nuove template functions:
;;; - modify: modifica fatto esistente
;;; - duplicate: duplica con modifiche
;;; - deftemplate-slot-*: introspection
;;;
;;; Per eseguire:
;;;   SLIPS> (load "Examples/06_TemplateManipulation.clp")
;;;   SLIPS> (reset)
;;;   SLIPS> (run)

(deftemplate person
   (slot name (default "unknown"))
   (slot age (default 0))
   (slot city (default ""))
   (multislot hobbies))

(deftemplate event
   (slot description)
   (slot timestamp))

(deffacts initial-data
   (person (name "John") (age 30) (city "Rome"))
   (person (name "Jane") (age 25) (city "Milan"))
   (trigger-update)
   (trigger-duplicate)
   (trigger-introspection))

;;; Demo: modifica fatto esistente
(defrule modify-person-age
   (declare (salience 50))
   ?trigger <- (trigger-update)
   ?p <- (person (name "John") (age ?old-age))
   =>
   (printout t "=== MODIFY Demo ===" crlf)
   (printout t "Original: John, age " ?old-age crlf)
   
   (bind ?new-age (+ ?old-age 1))
   (modify ?p (age ?new-age))
   
   (printout t "Modified: John, age " ?new-age crlf)
   (retract ?trigger))

;;; Demo: duplica fatto con modifiche
(defrule duplicate-person
   (declare (salience 40))
   ?trigger <- (trigger-duplicate)
   ?p <- (person (name "Jane") (age ?age) (city ?city))
   =>
   (printout t crlf "=== DUPLICATE Demo ===" crlf)
   (printout t "Original: Jane, " ?age ", " ?city crlf)
   
   ; Duplica cambiando nome e città
   (bind ?new-id (duplicate ?p (name "Julia") (city "Florence")))
   
   (printout t "Duplicated as fact-" ?new-id ": Julia, " ?age ", Florence" crlf)
   (retract ?trigger))

;;; Demo: introspection su template
(defrule template-introspection
   (declare (salience 30))
   ?trigger <- (trigger-introspection)
   =>
   (printout t crlf "=== TEMPLATE INTROSPECTION ===" crlf)
   
   ; Lista slot
   (bind ?slots (deftemplate-slot-names person))
   (printout t "Slots in 'person': " ?slots crlf)
   
   ; Check tipo slot
   (bind ?is-multi (deftemplate-slot-multip person hobbies))
   (bind ?is-single (deftemplate-slot-singlep person name))
   (printout t "  'hobbies' is multifield: " ?is-multi crlf)
   (printout t "  'name' is singlefield: " ?is-single crlf)
   
   ; Check esistenza
   (bind ?exists (deftemplate-slot-existp person salary))
   (printout t "  'salary' exists: " ?exists crlf)
   
   (retract ?trigger))

;;; Demo: uso combinato
(defrule combined-demo
   (declare (salience 10))
   =>
   (printout t crlf "=== COMBINED Demo ===" crlf)
   
   ; Crea persona
   (bind ?p-id (assert (person (name "Marco") (age 35) (city "Venice"))))
   (printout t "Created fact-" ?p-id crlf)
   
   ; Modifica età
   (modify ?p-id (age 36))
   (printout t "Modified age to 36" crlf)
   
   ; Duplica in altra città
   (bind ?dup-id (duplicate ?p-id (name "Maria") (city "Naples")))
   (printout t "Duplicated as fact-" ?dup-id crlf))

;;; Output atteso:
;;; === MODIFY Demo ===
;;; Original: John, age 30
;;; Modified: John, age 31
;;;
;;; === DUPLICATE Demo ===
;;; Original: Jane, 25, Milan
;;; Duplicated as fact-X: Julia, 25, Florence
;;;
;;; === TEMPLATE INTROSPECTION ===
;;; Slots in 'person': (create$ name age city hobbies)
;;;   'hobbies' is multifield: TRUE
;;;   'name' is singlefield: TRUE
;;;   'salary' exists: FALSE
;;;
;;; === COMBINED Demo ===
;;; Created fact-X
;;; Modified age to 36
;;; Duplicated as fact-Y

