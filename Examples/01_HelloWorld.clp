;;; ============================================
;;; SLIPS Example 1: Hello World
;;; ============================================
;;;
;;; Esempio base che mostra:
;;; - Definizione template
;;; - Assert di un fatto
;;; - Regola semplice
;;; - Printout
;;;
;;; Per eseguire:
;;;   SLIPS> (load "Examples/01_HelloWorld.clp")
;;;   SLIPS> (reset)
;;;   SLIPS> (run)

;;; Definisce template per messaggi
(deftemplate message
   (slot text (default ""))
   (slot priority (default 1)))

;;; Fatto iniziale
(deffacts startup
   (message (text "Hello, SLIPS!") (priority 1)))

;;; Regola che stampa messaggi
(defrule print-message
   ?msg <- (message (text ?txt) (priority ?p))
   =>
   (printout t "Message (priority " ?p "): " ?txt crlf)
   (retract ?msg))

;;; Output atteso:
;;; Message (priority 1): Hello, SLIPS!

