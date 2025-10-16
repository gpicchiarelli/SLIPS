;;; ============================================
;;; SLIPS Example 7b: Diagnostic System
;;; ============================================
;;;
;;; Sistema diagnostico semplificato.
;;; Dimostra:
;;; - Inference engine
;;; - Multiple conclusioni
;;; - NOT per assenza sintomi
;;; - Salience per priorità
;;;
;;; Per eseguire:
;;;   SLIPS> (load "Examples/07b_DiagnosticSystem.clp")
;;;   SLIPS> (reset)
;;;   SLIPS> (run)

(deftemplate symptom
   (slot patient)
   (slot name))

(deftemplate diagnosis
   (slot patient)
   (slot condition)
   (slot confidence))

;;; Paziente con sintomi
(deffacts patient-data
   (patient-id p001)
   (symptom (patient p001) (name fever))
   (symptom (patient p001) (name cough))
   (symptom (patient p001) (name fatigue))
   (start-diagnosis))

;;; Inizia diagnosi
(defrule start-diagnosis-rule
   (declare (salience 1000))
   ?start <- (start-diagnosis)
   (patient-id ?pid)
   =>
   (printout t "=== DIAGNOSTIC SYSTEM ===" crlf)
   (printout t "Analyzing patient: " ?pid crlf)
   (printout t "Symptoms detected..." crlf crlf)
   (retract ?start))

;;; Diagnosi: influenza (fever + cough + fatigue)
(defrule diagnose-flu
   (declare (salience 100))
   (patient-id ?pid)
   (symptom (patient ?pid) (name fever))
   (symptom (patient ?pid) (name cough))
   (symptom (patient ?pid) (name fatigue))
   (not (diagnosis (patient ?pid) (condition flu)))
   =>
   (assert (diagnosis (patient ?pid) (condition flu) (confidence 0.85)))
   (printout t "DIAGNOSIS: Flu (confidence: 85%)" crlf))

;;; Diagnosi: common cold (cough + NO fever alto)
(defrule diagnose-cold
   (declare (salience 90))
   (patient-id ?pid)
   (symptom (patient ?pid) (name cough))
   (not (symptom (patient ?pid) (name high-fever)))
   (not (diagnosis (patient ?pid) (condition cold)))
   =>
   (assert (diagnosis (patient ?pid) (condition cold) (confidence 0.60)))
   (printout t "DIAGNOSIS: Common Cold (confidence: 60%)" crlf))

;;; Raccomandazioni basate su diagnosi
(defrule recommend-rest
   (declare (salience 50))
   (diagnosis (patient ?pid) (condition ?cond) (confidence ?conf))
   (test (> ?conf 0.5))
   =>
   (printout t "RECOMMENDATION for " ?cond ": Rest and hydration" crlf))

;;; Riepilogo finale
(defrule final-summary
   (declare (salience -100))
   (patient-id ?pid)
   =>
   (printout t crlf "=== SUMMARY ===" crlf)
   (printout t "Patient " ?pid " has been evaluated" crlf)
   (printout t "All diagnoses completed" crlf))

;;; Output atteso:
;;; === DIAGNOSTIC SYSTEM ===
;;; Analyzing patient: p001
;;; Symptoms detected...
;;;
;;; DIAGNOSIS: Flu (confidence: 85%)
;;; DIAGNOSIS: Common Cold (confidence: 60%)
;;; RECOMMENDATION for flu: Rest and hydration
;;; RECOMMENDATION for cold: Rest and hydration
;;;
;;; === SUMMARY ===
;;; Patient p001 has been evaluated
;;; All diagnoses completed

