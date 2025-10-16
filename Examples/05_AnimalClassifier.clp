;;; ============================================
;;; SLIPS Example 5: Animal Classifier
;;; ============================================
;;;
;;; Sistema esperto classico per classificazione animali.
;;; Dimostra:
;;; - Pattern matching con variabili
;;; - Regole con multiple condizioni
;;; - Forward chaining
;;; - Salience per priorità
;;;
;;; Per eseguire:
;;;   SLIPS> (load "Examples/05_AnimalClassifier.clp")
;;;   SLIPS> (reset)
;;;   SLIPS> (run)

;;; Template per caratteristiche animali
(deftemplate animal
   (slot name)
   (slot has-fur (default no))
   (slot has-feathers (default no))
   (slot can-fly (default no))
   (slot can-swim (default no))
   (slot num-legs (default 0)))

;;; Template per classificazione
(deftemplate classification
   (slot animal)
   (slot category))

;;; Fatti iniziali: animali da classificare
(deffacts animals-to-classify
   (animal (name dog) (has-fur yes) (num-legs 4))
   (animal (name eagle) (has-feathers yes) (can-fly yes) (num-legs 2))
   (animal (name penguin) (has-feathers yes) (can-swim yes) (num-legs 2))
   (animal (name fish) (can-swim yes) (num-legs 0))
   (animal (name snake) (num-legs 0)))

;;; Regola: classifica mammiferi
(defrule classify-mammal
   (declare (salience 50))
   (animal (name ?n) (has-fur yes))
   (not (classification (animal ?n)))
   =>
   (assert (classification (animal ?n) (category mammal)))
   (printout t ?n " is a MAMMAL" crlf))

;;; Regola: classifica uccelli che volano
(defrule classify-flying-bird
   (declare (salience 40))
   (animal (name ?n) (has-feathers yes) (can-fly yes))
   (not (classification (animal ?n)))
   =>
   (assert (classification (animal ?n) (category flying-bird)))
   (printout t ?n " is a FLYING BIRD" crlf))

;;; Regola: classifica uccelli che nuotano
(defrule classify-swimming-bird
   (declare (salience 40))
   (animal (name ?n) (has-feathers yes) (can-swim yes))
   (not (classification (animal ?n)))
   =>
   (assert (classification (animal ?n) (category swimming-bird)))
   (printout t ?n " is a SWIMMING BIRD" crlf))

;;; Regola: classifica pesci
(defrule classify-fish
   (declare (salience 30))
   (animal (name ?n) (can-swim yes) (num-legs 0) (has-fur no) (has-feathers no))
   (not (classification (animal ?n)))
   =>
   (assert (classification (animal ?n) (category fish)))
   (printout t ?n " is a FISH" crlf))

;;; Regola: classifica rettili
(defrule classify-reptile
   (declare (salience 20))
   (animal (name ?n) (num-legs 0) (has-fur no) (has-feathers no))
   (not (classification (animal ?n)))
   =>
   (assert (classification (animal ?n) (category reptile)))
   (printout t ?n " is a REPTILE" crlf))

;;; Regola: riassunto finale
(defrule summary
   (declare (salience -10))
   =>
   (printout t crlf "=== Classification Summary ===" crlf)
   (bind ?mammals 0)
   (bind ?birds 0)
   (bind ?fish 0)
   (bind ?reptiles 0)
   
   ; Conta per categoria (versione semplificata)
   (printout t "All animals classified!" crlf))

;;; Output atteso:
;;; dog is a MAMMAL
;;; eagle is a FLYING BIRD
;;; penguin is a SWIMMING BIRD
;;; fish is a FISH
;;; snake is a REPTILE
;;;
;;; === Classification Summary ===
;;; All animals classified!

