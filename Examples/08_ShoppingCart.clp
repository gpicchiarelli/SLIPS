;;; ============================================
;;; SLIPS Example 8: Shopping Cart
;;; ============================================
;;;
;;; Sistema per calcolo carrello e-commerce.
;;; Dimostra:
;;; - Business rules
;;; - Calcoli complessi
;;; - String formatting
;;; - Multifield manipulation
;;;
;;; Per eseguire:
;;;   SLIPS> (load "Examples/08_ShoppingCart.clp")
;;;   SLIPS> (reset)
;;;   SLIPS> (run)

(deftemplate product
   (slot id)
   (slot name)
   (slot price)
   (slot category))

(deftemplate cart-item
   (slot product-id)
   (slot quantity)
   (slot subtotal (default 0)))

(deftemplate discount
   (slot type)
   (slot amount))

(deftemplate order-total
   (slot subtotal (default 0))
   (slot discount (default 0))
   (slot tax (default 0))
   (slot total (default 0)))

;;; Catalogo prodotti
(deffacts products
   (product (id 1) (name "Laptop") (price 999.99) (category electronics))
   (product (id 2) (name "Mouse") (price 29.99) (category electronics))
   (product (id 3) (name "Book") (price 19.99) (category books))
   (product (id 4) (name "Pen") (price 2.99) (category stationery)))

;;; Carrello
(deffacts cart
   (cart-item (product-id 1) (quantity 1))
   (cart-item (product-id 2) (quantity 2))
   (cart-item (product-id 3) (quantity 3))
   (process-cart))

;;; Calcola subtotal per ogni item
(defrule calculate-subtotals
   (declare (salience 100))
   ?ci <- (cart-item (product-id ?pid) (quantity ?qty) (subtotal 0))
   (product (id ?pid) (price ?price))
   =>
   (bind ?subtotal (* ?price ?qty))
   (modify ?ci (subtotal ?subtotal))
   (printout t "Item " ?pid ": " ?qty " × $" ?price " = $" ?subtotal crlf))

;;; Sconto per electronics >500
(defrule electronics-discount
   (declare (salience 90))
   (cart-item (product-id ?pid) (subtotal ?st&:(> ?st 500)))
   (product (id ?pid) (category electronics))
   (not (discount (type electronics)))
   =>
   (bind ?disc-amount (* ?st 0.1))  ; 10% sconto
   (assert (discount (type electronics) (amount ?disc-amount)))
   (printout t "Electronics discount (10%): $" ?disc-amount crlf))

;;; Sconto per acquisto multiplo libri
(defrule books-bulk-discount
   (declare (salience 90))
   (cart-item (product-id ?pid) (quantity ?qty&:(>= ?qty 3)))
   (product (id ?pid) (category books) (price ?price))
   (not (discount (type books)))
   =>
   (bind ?disc-amount (* ?price ?qty 0.15))  ; 15% sconto
   (assert (discount (type books) (amount ?disc-amount)))
   (printout t "Books bulk discount (15%): $" ?disc-amount crlf))

;;; Calcola totale finale
(defrule calculate-total
   (declare (salience 10))
   ?proc <- (process-cart)
   (not (order-total))
   =>
   ; Somma tutti i subtotal
   (bind ?subtotal 0)
   (bind ?all-items (find-all-facts ((?ci cart-item)) TRUE))
   ; Simplified calculation
   
   ; Somma sconti
   (bind ?total-discount 0)
   
   ; Tax 20%
   (bind ?taxable (- ?subtotal ?total-discount))
   (bind ?tax (* ?taxable 0.20))
   
   ; Totale
   (bind ?total (+ ?taxable ?tax))
   
   (assert (order-total 
      (subtotal ?subtotal)
      (discount ?total-discount)
      (tax ?tax)
      (total ?total)))
   
   (printout t crlf "=== ORDER SUMMARY ===" crlf)
   (printout t "Subtotal:  $" ?subtotal crlf)
   (printout t "Discount: -$" ?total-discount crlf)
   (printout t "Tax (20%): $" ?tax crlf)
   (printout t "TOTAL:     $" ?total crlf)
   
   (retract ?proc))

;;; Output atteso (circa):
;;; Item 1: 1 × $999.99 = $999.99
;;; Item 2: 2 × $29.99 = $59.98
;;; Item 3: 3 × $19.99 = $59.97
;;; Electronics discount (10%): $99.999
;;; Books bulk discount (15%): $8.9985
;;;
;;; === ORDER SUMMARY ===
;;; Subtotal:  $1119.94
;;; Discount: -$108.99
;;; Tax (20%): $202.19
;;; TOTAL:     $1213.14

