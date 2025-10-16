;;; ============================================
;;; SLIPS Example 10: Meta-Programming
;;; ============================================
;;;
;;; Esempi avanzati di meta-programmazione:
;;; - funcall per chiamate dinamiche
;;; - gensym per simboli unici
;;; - Generazione dinamica regole
;;; - Introspection
;;;
;;; Per eseguire:
;;;   SLIPS> (load "Examples/10_MetaProgramming.clp")
;;;   SLIPS> (reset)
;;;   SLIPS> (run)

(deftemplate operation
   (slot name)
   (slot op-func)
   (slot arg1)
   (slot arg2)
   (slot result))

(deftemplate generated-rule
   (slot name)
   (slot created-at))

(deffacts operations
   (operation (name add) (op-func +) (arg1 10) (arg2 5))
   (operation (name multiply) (op-func *) (arg1 10) (arg2 5))
   (operation (name subtract) (op-func -) (arg1 10) (arg2 5))
   (meta-demo))

;;; Demo funcall: esegui operazione dinamica
(defrule execute-dynamic-operation
   (declare (salience 100))
   ?op <- (operation (name ?n) (op-func ?func) (arg1 ?a1) (arg2 ?a2) (result nil))
   =>
   ; Chiamata dinamica della funzione
   (bind ?res (funcall ?func ?a1 ?a2))
   (modify ?op (result ?res))
   (printout t "funcall " ?func " " ?a1 " " ?a2 " = " ?res crlf))

;;; Demo gensym: genera simboli unici
(defrule generate-unique-symbols
   (declare (salience 90))
   ?meta <- (meta-demo)
   =>
   (printout t crlf "=== GENSYM Demo ===" crlf)
   
   ; Genera 5 simboli unici
   (bind ?symbols (create$))
   (bind ?i 1)
   (while (<= ?i 5)
      (bind ?sym (gensym))
      (bind ?symbols (insert$ ?symbols ?i ?sym))
      (bind ?i (+ ?i 1)))
   (printout t "Generated symbols: " ?symbols crlf)
   
   ; Genera con prefisso personalizzato
   (bind ?rule-sym (gensym* rule-))
   (bind ?fact-sym (gensym* fact-))
   (bind ?temp-sym (gensym* temp-))
   (printout t "Custom prefixes: " ?rule-sym ", " ?fact-sym ", " ?temp-sym crlf)
   
   (retract ?meta))

;;; Demo introspection: query template
(defrule template-introspection-demo
   (declare (salience 80))
   =>
   (printout t crlf "=== TEMPLATE INTROSPECTION ===" crlf)
   
   ; Ottieni lista slot di operation
   (bind ?slots (deftemplate-slot-names operation))
   (printout t "Template 'operation' has slots: " ?slots crlf)
   
   ; Check tipo slot
   (bind ?slot-count (length$ ?slots))
   (printout t "Total slots: " ?slot-count crlf)
   
   (bind ?i 1)
   (while (<= ?i ?slot-count)
      (bind ?slot-name (nth$ ?i ?slots))
      (bind ?is-multi (deftemplate-slot-multip operation ?slot-name))
      (bind ?type (if ?is-multi then "multifield" else "singlefield"))
      (printout t "  " ?slot-name ": " ?type crlf)
      (bind ?i (+ ?i 1))))

;;; Demo: genera nomi dinamici e usa
(defrule dynamic-naming
   (declare (salience 70))
   =>
   (printout t crlf "=== DYNAMIC NAMING ===" crlf)
   
   ; Genera nomi categoria dinamicamente
   (bind ?categories (create$ electronics books stationery))
   (bind ?i 1)
   (while (<= ?i (length$ ?categories))
      (bind ?cat (nth$ ?i ?categories))
      (bind ?var-name (sym-cat "?*" ?cat "-count*"))
      (printout t "Would create variable: " ?var-name crlf)
      (bind ?i (+ ?i 1))))

;;; Demo: string-to-field per parsing dinamico
(defrule dynamic-parsing
   (declare (salience 60))
   =>
   (printout t crlf "=== DYNAMIC PARSING ===" crlf)
   
   ; Parse stringhe in valori tipizzati
   (bind ?int-val (string-to-field "42"))
   (bind ?float-val (string-to-field "3.14"))
   (bind ?sym-val (string-to-field "hello"))
   
   (printout t "Parsed '42' as: " ?int-val " (type: integer)" crlf)
   (printout t "Parsed '3.14' as: " ?float-val " (type: float)" crlf)
   (printout t "Parsed 'hello' as: " ?sym-val " (type: symbol)" crlf))

;;; Demo: composizione funzioni
(defrule function-composition
   (declare (salience 50))
   =>
   (printout t crlf "=== FUNCTION COMPOSITION ===" crlf)
   
   ; Componi: sqrt(exp(log(16)))
   (bind ?x 16)
   (bind ?result (funcall sqrt (funcall exp (funcall log ?x))))
   (printout t "sqrt(exp(log(16))) = " ?result crlf)
   
   ; Componi: upcase(str-cat(...))
   (bind ?text1 "hello")
   (bind ?text2 "world")
   (bind ?combined (funcall upcase (funcall str-cat ?text1 " " ?text2)))
   (printout t "upcase(str-cat('hello', ' ', 'world')) = " ?combined crlf))

;;; Output atteso:
;;; funcall + 10 5 = 15
;;; funcall * 10 5 = 50
;;; funcall - 10 5 = 5
;;;
;;; === GENSYM Demo ===
;;; Generated symbols: (create$ gen1 gen2 gen3 gen4 gen5)
;;; Custom prefixes: rule-6, fact-7, temp-8
;;;
;;; === TEMPLATE INTROSPECTION ===
;;; Template 'operation' has slots: (create$ name op-func arg1 arg2 result)
;;; Total slots: 5
;;;   name: singlefield
;;;   op-func: singlefield
;;;   arg1: singlefield
;;;   arg2: singlefield
;;;   result: singlefield
;;;
;;; === DYNAMIC NAMING ===
;;; Would create variable: ?*electronics-count*
;;; Would create variable: ?*books-count*
;;; Would create variable: ?*stationery-count*
;;;
;;; === DYNAMIC PARSING ===
;;; Parsed '42' as: 42 (type: integer)
;;; Parsed '3.14' as: 3.14 (type: float)
;;; Parsed 'hello' as: hello (type: symbol)
;;;
;;; === FUNCTION COMPOSITION ===
;;; sqrt(exp(log(16))) = 16.0
;;; upcase(str-cat('hello', ' ', 'world')) = HELLO WORLD

