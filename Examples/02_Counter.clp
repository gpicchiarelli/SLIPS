;;; ============================================
;;; SLIPS Example 2: Counter
;;; ============================================
;;;
;;; Esempio che mostra:
;;; - Uso di variabili globali (defglobal)
;;; - Modifica di fatti (modify)
;;; - Controllo flusso con test
;;; - Aritmetica
;;;
;;; Per eseguire:
;;;   SLIPS> (load "Examples/02_Counter.clp")
;;;   SLIPS> (reset)
;;;   SLIPS> (run)

;;; Variabile globale per limite massimo
(defglobal ?*max-count* = 10)

;;; Template per contatore
(deftemplate counter
   (slot value (default 0))
   (slot step (default 1)))

;;; Fatto iniziale
(deffacts init
   (counter (value 0) (step 1)))

;;; Incrementa contatore se sotto limite
(defrule increment-counter
   (declare (salience 10))
   ?c <- (counter (value ?v) (step ?s))
   (test (< ?v ?*max-count*))
   =>
   (bind ?new-value (+ ?v ?s))
   (modify ?c (value ?new-value))
   (printout t "Count: " ?new-value crlf))

;;; Ferma quando raggiunto limite
(defrule stop-counting
   ?c <- (counter (value ?v))
   (test (>= ?v ?*max-count*))
   =>
   (printout t "Reached max count: " ?v crlf)
   (retract ?c))

;;; Output atteso:
;;; Count: 1
;;; Count: 2
;;; ...
;;; Count: 10
;;; Reached max count: 10

