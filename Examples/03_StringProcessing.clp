;;; ============================================
;;; SLIPS Example 3: String Processing
;;; ============================================
;;;
;;; Esempio che dimostra le nuove string functions:
;;; - str-cat, sym-cat
;;; - upcase, lowcase
;;; - sub-string, str-index
;;; - str-replace
;;; - str-length
;;;
;;; Per eseguire:
;;;   SLIPS> (load "Examples/03_StringProcessing.clp")
;;;   SLIPS> (reset)
;;;   SLIPS> (run)

(deftemplate text-data
   (slot original)
   (slot processed))

(deffacts text-samples
   (process "hello world")
   (process "CLIPS in Swift")
   (process "café")
   (process "replace-this-text"))

;;; Converte in maiuscolo
(defrule uppercase-text
   (declare (salience 40))
   ?p <- (process ?txt)
   =>
   (bind ?upper (upcase ?txt))
   (assert (text-data (original ?txt) (processed ?upper)))
   (printout t "Upper: " ?upper crlf)
   (retract ?p))

;;; Concatenazione stringhe
(defrule concatenate-demo
   (declare (salience 30))
   =>
   (bind ?greeting (str-cat "Hello" " " "SLIPS"))
   (printout t "Concatenated: " ?greeting crlf)
   
   (bind ?sym (sym-cat rule- 42))
   (printout t "Symbol: " ?sym crlf))

;;; Estrazione sottostringa
(defrule substring-demo
   (declare (salience 20))
   =>
   (bind ?text "Hello World")
   (bind ?hello (sub-string 1 5 ?text))
   (bind ?world (sub-string 7 11 ?text))
   (printout t "Parts: " ?hello " + " ?world crlf))

;;; Ricerca e sostituzione
(defrule search-replace-demo
   (declare (salience 10))
   =>
   (bind ?text "The quick brown fox")
   (bind ?pos (str-index "brown" ?text))
   (printout t "Found 'brown' at position: " ?pos crlf)
   
   (bind ?replaced (str-replace ?text "brown" "red"))
   (printout t "Replaced: " ?replaced crlf))

;;; Lunghezza stringhe (UTF-8)
(defrule length-demo
   (declare (salience 5))
   =>
   (bind ?text "café")
   (bind ?chars (str-length ?text))
   (bind ?bytes (str-byte-length ?text))
   (printout t "UTF-8 Demo: '" ?text "'" crlf)
   (printout t "  Characters: " ?chars crlf)
   (printout t "  Bytes: " ?bytes crlf))

;;; Output atteso:
;;; Upper: HELLO WORLD
;;; Upper: CLIPS IN SWIFT
;;; Upper: CAFÉ
;;; Upper: REPLACE-THIS-TEXT
;;; Concatenated: Hello SLIPS
;;; Symbol: rule-42
;;; Parts: Hello + World
;;; Found 'brown' at position: 11
;;; Replaced: The quick red fox
;;; UTF-8 Demo: 'café'
;;;   Characters: 4
;;;   Bytes: 5

