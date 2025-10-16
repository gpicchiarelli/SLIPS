;;; ============================================
;;; SLIPS Example 9: File I/O
;;; ============================================
;;;
;;; Dimostra funzioni I/O avanzate:
;;; - Scrittura su file
;;; - Lettura da file
;;; - Formattazione
;;; - File operations
;;;
;;; Per eseguire:
;;;   SLIPS> (load "Examples/09_FileIO.clp")
;;;   SLIPS> (reset)
;;;   SLIPS> (run)

(deftemplate report-item
   (slot id)
   (slot description)
   (slot value))

(deffacts report-data
   (report-item (id 1) (description "Total Sales") (value 15234.56))
   (report-item (id 2) (description "Total Costs") (value 8921.33))
   (report-item (id 3) (description "Net Profit") (value 6313.23))
   (generate-report))

;;; Genera report su file
(defrule generate-text-report
   (declare (salience 100))
   ?gen <- (generate-report)
   =>
   (printout t "=== FILE I/O DEMO ===" crlf)
   (printout t "Generating report..." crlf)
   
   ; Apri file per scrittura
   (bind ?success (open "report.txt" "w"))
   
   (if ?success then
      ; Scrivi header
      (println "SALES REPORT")
      (println "=" (str-cat "=" "=" "=" "=" "=" "=" "=" "=" "=" "="))
      (println)
      
      ; Scrivi data
      (bind ?timestamp (time))
      (println "Generated at: " ?timestamp)
      (println)
      
      ; Chiudi file
      (close)
      (printout t "Report written to report.txt" crlf)
   else
      (printout t "ERROR: Could not open file" crlf))
   
   (retract ?gen))

;;; Formattazione avanzata
(defrule format-demo
   (declare (salience 90))
   =>
   (printout t crlf "=== FORMAT Demo ===" crlf)
   
   ; Format con percentuali
   (bind ?score 85)
   (bind ?total 100)
   (bind ?percent (/ (* ?score 100.0) ?total))
   (bind ?formatted (format nil "Score: %d/%d (%.1f%%)" ?score ?total ?percent))
   (printout t ?formatted crlf)
   
   ; Format con decimali
   (bind ?pi-val (pi))
   (bind ?pi-str (format nil "π = %.5f" ?pi-val))
   (printout t ?pi-str crlf)
   
   ; Format con stringhe
   (bind ?name "Alice")
   (bind ?age 25)
   (bind ?greeting (format nil "Hello, %s! You are %d years old." ?name ?age))
   (printout t ?greeting crlf))

;;; Scrive dati formattati
(defrule write-formatted-data
   (declare (salience 80))
   (report-item (id ?id) (description ?desc) (value ?val))
   =>
   (bind ?line (format nil "%2d. %-20s $%10.2f" ?id ?desc ?val))
   (printout t ?line crlf))

;;; File manipulation demo
(defrule file-operations-demo
   (declare (salience 70))
   =>
   (printout t crlf "=== FILE OPERATIONS ===" crlf)
   
   ; Crea file temporaneo
   (bind ?opened (open "temp.txt" "w"))
   (if ?opened then
      (println "Temporary file created")
      (close)
      (printout t "Created temp.txt" crlf)
      
      ; Rinomina
      (bind ?renamed (rename "temp.txt" "temp_backup.txt"))
      (if ?renamed then
         (printout t "Renamed to temp_backup.txt" crlf)
         
         ; Rimuovi
         (bind ?removed (remove "temp_backup.txt"))
         (if ?removed then
            (printout t "Removed temp_backup.txt" crlf)))))

;;; Random number generation per report ID
(defrule random-demo
   (declare (salience 60))
   =>
   (printout t crlf "=== RANDOM Demo ===" crlf)
   (bind ?report-id (random 1000 9999))
   (printout t "Generated Report ID: " ?report-id crlf)
   
   ; Genera 5 numeri casuali
   (bind ?numbers (create$))
   (bind ?i 1)
   (while (<= ?i 5)
      (bind ?num (random 1 100))
      (bind ?numbers (insert$ ?numbers ?i ?num))
      (bind ?i (+ ?i 1)))
   (printout t "Random numbers: " ?numbers crlf))

;;; Output atteso (circa):
;;; === FILE I/O DEMO ===
;;; Generating report...
;;; Report written to report.txt
;;;
;;; === FORMAT Demo ===
;;; Score: 85/100 (85.0%)
;;; π = 3.14159
;;; Hello, Alice! You are 25 years old.
;;;
;;;  1. Total Sales          $  15234.56
;;;  2. Total Costs          $   8921.33
;;;  3. Net Profit           $   6313.23
;;;
;;; === FILE OPERATIONS ===
;;; Created temp.txt
;;; Renamed to temp_backup.txt
;;; Removed temp_backup.txt
;;;
;;; === RANDOM Demo ===
;;; Generated Report ID: 7423
;;; Random numbers: (create$ 42 17 89 3 56)

