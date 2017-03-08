;; Homework 5. Listdiffs

(define (null-ld? obj)
	(if (pair? obj)
		(if (eq? (car obj) (cdr obj)) #t #f)
		#f)
	)

(define (listdiff? obj)
;	(let (head (car obj))
;		(tail (cdr obj))
	(cond ((not (pair? obj)) #f)
		((null? (cdr obj)) #t)
		((null? (car obj)) #f)
		((null-ld? obj) #t)
		((not (pair? (car obj))) #f)
		(else (listdiff? (cons (cdr (car obj)) (cdr obj))))
		)
;		)
	)

;	From piazza:
;	You can assume that the input must be a valid form.
;	Don't need to add an additional checking routine.
(define (cons-ld obj listdiff)
	(cons (cons obj (car listdiff)) (cdr listdiff)))

(define (car-ld listdiff)
	(cond ((null-ld? listdiff) "error") ; It is an error if listdiff has no elements. 
		((listdiff? listdiff) (car (car listdiff)))
		(else "error")
		)
	)

(define (cdr-ld listdiff)
	(cond ((null-ld? listdiff) "error")
		((listdiff? listdiff) (cons (cdr (car listdiff)) (cdr listdiff)))
		(else "error")
		)
	)

(define (listdiff obj . args)
	;(let ((listobj (list obj)))
	;	(cons (append (cons obj args) listobj) listobj)
	;	)
	;	According to Piazza: "Let's choose the simplest listdiff."
	(cons (cons obj args) null))

(define (length-ld listdiff)
	(cond ((not (listdiff? listdiff)) "error")
		(else (let length-ld-helper ((listdiff listdiff) (len 0))
				(if (null-ld? listdiff)
					len
					(length-ld-helper (cons (cdr (car listdiff)) (cdr listdiff)) (+ 1 len)))
				)
			)
		)
	)

; Return a listdiff consisting of the elements of the first listdiff
; followed by the elements of the other listdiffs. 
; The resulting listdiff is always newly allocated, 
; except that it shares structure with the last argument.
(define (append-ld listdiff . others)
	(if (null? others)
		listdiff
		(let traversal-ld ((curLd (cons listdiff others)))
			(if (null? (cdr curLd))
				(car curLd)
				(let traversal-elem ((curLst (listdiff->list (car curLd))))
					(if (null? curLst)
						(traversal-ld (cdr curLd))
						(cons-ld (car curLst) (traversal-elem (cdr curLst)))
						)
					)
				)
			)
		)
	)

;(define (assq-ld obj alistdiff)
;	(let assq-ld-helper ((obj obj) (alistdiff alistdiff) (store '()))
;		(cond ((null-ld? alistdiff) (if (empty? store) #f store))
;			((not (pair? (car-ld alistdiff))) #f)
;			((and (eq? obj (car (car-ld alistdiff))) (empty store)) 
;				(assq-ld-helper obj (cdr-ld alistdiff) (car-ld alistdiff)))
;			(else (assq-ld-helper obj (cdr-ld alistdiff) store))
;			)
;		)
;	) 
(define (assq-ld obj alistdiff)
	(let assq-ld-helper ((obj obj)(alistdiff alistdiff)(store null))
		(if (null-ld? alistdiff)
			(if (empty? store) #f store)
			(if (pair? (car-ld alistdiff))
				(if (and (eq? obj (car (car-ld alistdiff))) (empty? store))
					(assq-ld-helper obj (cdr-ld alistdiff) (car-ld alistdiff))
					(assq-ld-helper obj (cdr-ld alistdiff) store))
				#f)
			)
		)
	)

(define (list->listdiff list)
	(cond ((not (list? list)) "error")
		((null? list) (cons list list))
;		(else (cons (append list (cons (car list) null)) (cons (car list) null))) 
;		^ another way... but the output is more complicated
; According to Piazza: Let's choose the simplest one.
; (list->listdiff '(1 2 3 4))
; The output could be '((1 2 3 4))
		(else (cons list null))	
		)
	)

(define (listdiff->list listdiff)
	(if (not (listdiff? listdiff)) 
		"error"
		(if (null-ld? listdiff) 
			null
			(let listdiff-list-helper ((listdiff listdiff) (myList null))
				(if (equal? (length-ld listdiff) 0)
					myList
					(listdiff-list-helper (cdr-ld listdiff) (append myList (list (car-ld listdiff))))
					)
				)
			)
		)
	)


(define (expr-returning listdiff)
	(define (expr-returning-helper myList symbol) 
		(if (empty? myList) 
			symbol 
			(expr-returning-helper (cdr myList) `(cons (quote ,(car myList)) ,symbol)))
		)
	(if (listdiff? listdiff)
		`(let ((lst (quote ,(cdr listdiff)))) (cons ,(expr-returning-helper (reverse (listdiff->list listdiff)) 'lst) lst))
		"error")
	)
