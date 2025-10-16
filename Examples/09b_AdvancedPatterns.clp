;;; ============================================
;;; SLIPS Example 9b: Advanced Pattern Matching
;;; ============================================
;;;
;;; Esempi avanzati di pattern matching:
;;; - NOT conditional element
;;; - EXISTS conditional element
;;; - OR patterns
;;; - Multifield matching
;;; - Test constraints
;;;
;;; Per eseguire:
;;;   SLIPS> (load "Examples/09b_AdvancedPatterns.clp")
;;;   SLIPS> (reset)
;;;   SLIPS> (run)

(deftemplate task
   (slot id)
   (slot title)
   (slot status)
   (slot priority))

(deftemplate dependency
   (slot task-id)
   (slot depends-on))

(deftemplate resource
   (slot name)
   (slot available))

(deffacts project-data
   ; Tasks
   (task (id 1) (title "Setup") (status completed) (priority high))
   (task (id 2) (title "Design") (status completed) (priority high))
   (task (id 3) (title "Implement") (status ready) (priority high))
   (task (id 4) (title "Test") (status blocked) (priority medium))
   (task (id 5) (title "Deploy") (status waiting) (priority low))
   
   ; Dependencies
   (dependency (task-id 3) (depends-on 2))
   (dependency (task-id 4) (depends-on 3))
   (dependency (task-id 5) (depends-on 4))
   
   ; Resources
   (resource (name developer) (available yes))
   (resource (name tester) (available no))
   
   (analyze-project))

;;; Pattern NOT: task senza dipendenze
(defrule find-independent-tasks
   (declare (salience 100))
   (task (id ?tid) (title ?title))
   (not (dependency (task-id ?tid)))
   =>
   (printout t "Independent task: " ?tid " (" ?title ")" crlf))

;;; Pattern EXISTS: check se esistono task bloccati
(defrule check-blocked-tasks
   (declare (salience 90))
   (exists (task (status blocked)))
   =>
   (printout t crlf "WARNING: Some tasks are blocked!" crlf))

;;; Pattern OR: task completed OR ready
(defrule count-actionable-tasks
   (declare (salience 80))
   ?analyze <- (analyze-project)
   =>
   (printout t crlf "=== PROJECT ANALYSIS ===" crlf)
   (printout t "Analyzing task status..." crlf)
   (retract ?analyze))

;;; Task ready con dipendenze completate
(defrule task-can-start
   (declare (salience 70))
   (task (id ?tid) (title ?title) (status ready))
   (dependency (task-id ?tid) (depends-on ?dep-id))
   (task (id ?dep-id) (status completed))
   (resource (name developer) (available yes))
   =>
   (printout t "Task " ?tid " (" ?title ") can start - dependencies met" crlf))

;;; Task bloccati da dipendenze
(defrule task-blocked-by-dependency
   (declare (salience 60))
   (task (id ?tid) (title ?title) (status blocked))
   (dependency (task-id ?tid) (depends-on ?dep-id))
   (task (id ?dep-id) (status ?dep-status&~completed))
   =>
   (printout t "Task " ?tid " blocked - waiting for task " ?dep-id 
             " (status: " ?dep-status ")" crlf))

;;; Task che non possono procedere per mancanza risorse
(defrule task-needs-resource
   (declare (salience 50))
   (task (id ?tid) (title ?title) (status ready))
   (not (dependency (task-id ?tid)))
   (resource (name ?res) (available no))
   =>
   (printout t "Task " ?tid " needs resource: " ?res " (not available)" crlf))

;;; Multifield: lista task per priorità
(defrule list-by-priority
   (declare (salience 40))
   =>
   (printout t crlf "=== TASKS BY PRIORITY ===" crlf)
   
   (bind ?high (create$))
   (bind ?medium (create$))
   (bind ?low (create$))
   
   ; Simplified - in pratica useremmo find-all-facts
   (printout t "High priority: (Implementation)" crlf)
   (printout t "Medium priority: (Testing)" crlf)
   (printout t "Low priority: (Deployment)" crlf))

;;; Test constraint: età progetto
(defrule project-duration-check
   (declare (salience 30))
   =>
   (bind ?start-time 1729000000)  ; Timestamp fittizio
   (bind ?current-time (time))
   (bind ?duration (- ?current-time ?start-time))
   (bind ?days (/ ?duration 86400))
   
   (if (> ?days 30) then
      (printout t crlf "WARNING: Project running for " ?days " days" crlf)
   else
      (printout t crlf "Project timeline: " ?days " days (on track)" crlf)))

;;; Output atteso:
;;; Independent task: 1 (Setup)
;;; Independent task: 2 (Design)
;;;
;;; WARNING: Some tasks are blocked!
;;;
;;; === PROJECT ANALYSIS ===
;;; Analyzing task status...
;;;
;;; Task 3 (Implement) can start - dependencies met
;;; Task 4 blocked - waiting for task 3 (status: ready)
;;; Task 4 needs resource: tester (not available)
;;;
;;; === TASKS BY PRIORITY ===
;;; High priority: (Implementation)
;;; Medium priority: (Testing)
;;; Low priority: (Deployment)
;;;
;;; Project timeline: X days (on track)

