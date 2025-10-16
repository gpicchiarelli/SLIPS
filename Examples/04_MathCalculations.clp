;;; ============================================
;;; SLIPS Example 4: Math Calculations
;;; ============================================
;;;
;;; Esempio che dimostra le math functions:
;;; - Trigonometriche
;;; - Esponenziali e logaritmi
;;; - Utilità
;;; - Conversioni angoli
;;;
;;; Per eseguire:
;;;   SLIPS> (load "Examples/04_MathCalculations.clp")
;;;   SLIPS> (reset)
;;;   SLIPS> (run)

(deftemplate calculation
   (slot name)
   (slot formula)
   (slot result))

;;; Calcoli trigonometrici
(defrule trig-calculations
   (declare (salience 50))
   =>
   (bind ?angle (/ (pi) 4))  ; 45 gradi in radianti
   (bind ?cos-val (cos ?angle))
   (bind ?sin-val (sin ?angle))
   
   (printout t "Trigonometry Demo:" crlf)
   (printout t "  cos(π/4) = " ?cos-val crlf)
   (printout t "  sin(π/4) = " ?sin-val crlf)
   (printout t "  sin²+cos² = " (+ (** ?sin-val 2) (** ?cos-val 2)) crlf))

;;; Teorema di Pitagora
(defrule pythagorean-theorem
   (declare (salience 40))
   =>
   (bind ?a 3)
   (bind ?b 4)
   (bind ?c (sqrt (+ (** ?a 2) (** ?b 2))))
   (printout t crlf "Pythagorean Theorem:" crlf)
   (printout t "  a = " ?a ", b = " ?b crlf)
   (printout t "  c = sqrt(a² + b²) = " ?c crlf))

;;; Logaritmi ed esponenziali
(defrule log-exp-demo
   (declare (salience 30))
   =>
   (bind ?e (exp 1))
   (bind ?log-e (log ?e))
   
   (printout t crlf "Exponentials & Logarithms:" crlf)
   (printout t "  e = " ?e crlf)
   (printout t "  log(e) = " ?log-e crlf)
   (printout t "  log₁₀(100) = " (log10 100) crlf))

;;; Conversione angoli
(defrule angle-conversion
   (declare (salience 20))
   =>
   (bind ?degrees 180)
   (bind ?radians (deg-rad ?degrees))
   (bind ?back (rad-deg ?radians))
   
   (printout t crlf "Angle Conversion:" crlf)
   (printout t "  " ?degrees "° = " ?radians " rad" crlf)
   (printout t "  Back to degrees: " ?back "°" crlf))

;;; Calcoli scientifici
(defrule scientific-calculation
   (declare (salience 10))
   =>
   ; Area di un cerchio: A = πr²
   (bind ?radius 5)
   (bind ?area (* (pi) (** ?radius 2)))
   
   (printout t crlf "Circle Calculations:" crlf)
   (printout t "  Radius: " ?radius crlf)
   (printout t "  Area: " ?area crlf)
   (printout t "  Circumference: " (* 2 (pi) ?radius) crlf))

;;; Statistiche base
(defrule statistics-demo
   (declare (salience 5))
   =>
   (bind ?values (create$ 10 20 30 40 50))
   (bind ?sum 0)
   (bind ?count (length$ ?values))
   
   ; Calcola somma
   (bind ?i 1)
   (while (<= ?i ?count)
      (bind ?sum (+ ?sum (nth$ ?i ?values)))
      (bind ?i (+ ?i 1)))
   
   (bind ?mean (/ ?sum ?count))
   
   (printout t crlf "Statistics:" crlf)
   (printout t "  Values: " ?values crlf)
   (printout t "  Count: " ?count crlf)
   (printout t "  Sum: " ?sum crlf)
   (printout t "  Mean: " ?mean crlf))

;;; Output atteso:
;;; Trigonometry Demo:
;;;   cos(π/4) = 0.707...
;;;   sin(π/4) = 0.707...
;;;   sin²+cos² = 1.0
;;;
;;; Pythagorean Theorem:
;;;   a = 3, b = 4
;;;   c = sqrt(a² + b²) = 5.0
;;;
;;; Exponentials & Logarithms:
;;;   e = 2.718...
;;;   log(e) = 1.0
;;;   log₁₀(100) = 2.0
;;;
;;; Angle Conversion:
;;;   180° = 3.14159... rad
;;;   Back to degrees: 180.0°
;;;
;;; Circle Calculations:
;;;   Radius: 5
;;;   Area: 78.539...
;;;   Circumference: 31.415...
;;;
;;; Statistics:
;;;   Values: (create$ 10 20 30 40 50)
;;;   Count: 5
;;;   Sum: 150
;;;   Mean: 30.0

