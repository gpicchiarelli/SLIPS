;;; ============================================
;;; SLIPS Example 8b: Data Validation
;;; ============================================
;;;
;;; Sistema di validazione dati complesso.
;;; Dimostra:
;;; - Validazione multi-campo
;;; - String validation con pattern
;;; - Range validation
;;; - Business rules
;;;
;;; Per eseguire:
;;;   SLIPS> (load "Examples/08b_DataValidation.clp")
;;;   SLIPS> (reset)
;;;   SLIPS> (run)

(deftemplate user-data
   (slot id)
   (slot username)
   (slot email)
   (slot age)
   (slot status (default pending)))

(deftemplate validation-error
   (slot record-id)
   (slot field)
   (slot message))

(deffacts test-records
   (user-data (id 1) (username "john_doe") (email "john@example.com") (age 25))
   (user-data (id 2) (username "ab") (email "invalid-email") (age 15))
   (user-data (id 3) (username "jane_smith") (email "jane@test.com") (age 150))
   (user-data (id 4) (username "valid_user") (email "user@domain.org") (age 30))
   (start-validation))

(defrule start-validation-rule
   (declare (salience 1000))
   ?start <- (start-validation)
   =>
   (printout t "=== DATA VALIDATION SYSTEM ===" crlf)
   (printout t "Validating user records..." crlf crlf)
   (retract ?start))

;;; Valida lunghezza username (min 3 caratteri)
(defrule validate-username-length
   (declare (salience 100))
   ?user <- (user-data (id ?id) (username ?uname) (status pending))
   (test (< (str-length ?uname) 3))
   =>
   (assert (validation-error 
      (record-id ?id)
      (field username)
      (message "Username must be at least 3 characters")))
   (printout t "ERROR [Record " ?id "]: Username too short" crlf))

;;; Valida formato email (contiene @)
(defrule validate-email-format
   (declare (salience 100))
   ?user <- (user-data (id ?id) (email ?email) (status pending))
   (test (eq (str-index "@" ?email) FALSE))
   =>
   (assert (validation-error
      (record-id ?id)
      (field email)
      (message "Email must contain @")))
   (printout t "ERROR [Record " ?id "]: Invalid email format" crlf))

;;; Valida età (range 18-120)
(defrule validate-age-range
   (declare (salience 100))
   ?user <- (user-data (id ?id) (age ?age) (status pending))
   (test (or (< ?age 18) (> ?age 120)))
   =>
   (assert (validation-error
      (record-id ?id)
      (field age)
      (message "Age must be between 18 and 120")))
   (printout t "ERROR [Record " ?id "]: Age out of range (" ?age ")" crlf))

;;; Marca come validato se nessun errore
(defrule mark-as-valid
   (declare (salience 50))
   ?user <- (user-data (id ?id) (status pending))
   (not (validation-error (record-id ?id)))
   =>
   (modify ?user (status valid))
   (printout t "SUCCESS [Record " ?id "]: All validations passed" crlf))

;;; Marca come invalido se ci sono errori
(defrule mark-as-invalid
   (declare (salience 50))
   ?user <- (user-data (id ?id) (status pending))
   (validation-error (record-id ?id))
   =>
   (modify ?user (status invalid))
   (printout t "FAILED [Record " ?id "]: Validation errors found" crlf))

;;; Riepilogo finale
(defrule validation-summary
   (declare (salience -100))
   =>
   (printout t crlf "=== VALIDATION SUMMARY ===" crlf)
   
   ; Conta record validi/invalidi
   ; (versione semplificata - in reale useremmo find-all-facts)
   (printout t "Validation process completed" crlf))

;;; Output atteso:
;;; === DATA VALIDATION SYSTEM ===
;;; Validating user records...
;;;
;;; ERROR [Record 2]: Username too short
;;; ERROR [Record 2]: Invalid email format
;;; ERROR [Record 2]: Age out of range (15)
;;; FAILED [Record 2]: Validation errors found
;;; ERROR [Record 3]: Age out of range (150)
;;; FAILED [Record 3]: Validation errors found
;;; SUCCESS [Record 1]: All validations passed
;;; SUCCESS [Record 4]: All validations passed
;;;
;;; === VALIDATION SUMMARY ===
;;; Validation process completed

