;;;; Common Lisp port of PrimeC/solution_2/sieve_5760of30030_only_write_read_bits.c by Daniel Spangberg
;;;
;;; approx. 2.7x speedup over PrimeSieve.lisp, approx. 335x speedup over solution_1
;;;
;;; run as:
;;;     sbcl --script PrimeSieveWheel.lisp
;;;
;;;
;;; I have no idea how this works I just stole the algorithm.
;;;
;;; For Common Lisp bit ops see https://lispcookbook.github.io/cl-cookbook/numbers.html#bit-wise-operation
;;;
;;; (compile-file "PrimeSieveWheel.lisp") will show info during the compilation
;;; regarding any inefficient code that can't be optimized.
;;; I added type declarations until there were no more messages concerning run-sieve.


(declaim
  (optimize (speed 3) (safety 0) (debug 0)))

(defconstant +bits-per-word+ 64)
(defconstant +MASK+ #x3F)
(defconstant +SHIFT+ -6)

(defconstant +steps+ #(
 8 1 2 3 1 3 2 1 2 3 3 1 3 2 1 3 2 3 4 2 1 2 1 2 7 
 2 3 1 5 1 3 3 2 3 3 1 5 1 2 1 6 6 2 1 2 3 1 5 3 3 
 3 1 3 2 1 3 2 7 2 1 2 3 4 3 5 1 2 3 1 3 3 3 2 3 1 
 3 2 4 5 1 5 1 2 1 2 3 4 2 1 2 6 4 2 1 3 2 3 6 1 2 
 1 6 3 2 3 3 3 1 3 5 1 2 3 1 3 3 2 1 5 1 5 1 2 3 3 
 1 3 3 2 3 4 3 2 1 3 2 3 4 2 1 3 2 4 3 2 4 2 3 4 5 
 1 5 1 3 2 1 2 1 5 1 5 1 2 1 2 7 2 1 2 3 3 1 3 2 4 
 5 4 2 1 2 3 4 3 2 3 3 3 1 3 3 2 1 2 3 1 5 1 2 1 5 
 1 5 1 3 2 4 3 2 1 2 3 3 4 2 1 3 5 4 2 1 3 2 4 5 3 
 1 2 4 3 3 2 1 2 3 1 3 2 3 1 5 6 1 2 1 2 3 1 3 2 1 
 2 6 1 3 3 5 3 4 2 1 2 1 2 4 3 6 2 3 1 6 2 1 2 3 4 
 2 1 2 1 6 5 1 2 1 2 3 1 5 1 2 3 4 3 2 1 3 2 3 4 2 
 3 1 2 4 3 2 3 1 2 3 1 3 3 2 3 3 4 3 2 1 5 1 5 1 2 
 1 5 1 3 2 1 5 3 1 3 2 1 3 2 3 4 3 2 1 6 5 3 1 2 3 
 1 6 2 1 2 4 3 2 1 2 1 5 1 5 3 1 2 3 1 3 2 1 5 3 1 
 3 2 6 3 4 3 2 1 2 4 3 2 3 1 2 3 4 3 3 2 3 1 3 2 1 
 2 1 5 6 1 2 6 1 3 2 1 2 3 3 1 6 3 2 9 1 2 1 2 4 3 
 2 3 1 2 4 3 3 2 1 2 3 1 3 2 1 2 6 1 6 3 2 3 1 3 2 
 3 3 3 1 3 2 1 3 2 3 4 2 1 2 1 2 7 2 3 1 5 1 3 3 2 
 1 5 1 5 1 2 7 5 1 2 1 2 3 1 3 5 3 3 1 5 1 3 2 3 4 
 2 1 2 3 4 3 5 1 2 3 1 3 3 2 1 2 3 1 3 2 1 3 5 1 5 
 3 1 2 3 4 2 1 2 6 1 3 2 1 3 2 3 6 1 2 1 2 4 3 2 3 
 1 5 1 3 5 3 3 1 3 2 1 2 1 5 1 6 2 3 3 1 6 2 3 3 1 
 3 2 1 3 2 7 2 1 3 2 4 3 2 3 1 2 3 4 3 3 5 1 3 2 3 
 1 5 1 5 1 2 1 2 4 3 2 1 2 3 3 4 2 4 2 3 4 2 1 2 1 
 6 3 2 3 3 3 1 3 3 2 1 2 3 1 3 3 2 1 5 1 5 1 3 2 3 
 1 3 2 1 2 3 7 2 1 3 5 4 2 1 2 1 2 4 5 4 2 4 3 5 1 
 2 3 1 3 2 3 1 5 1 5 1 2 1 2 3 4 2 1 2 3 3 1 3 3 3 
 5 4 2 1 2 3 4 3 2 4 2 3 1 3 3 2 1 2 3 6 1 2 1 5 1 
 5 1 2 1 2 4 5 1 2 3 4 3 2 1 3 2 3 4 2 4 2 4 3 2 3 
 1 2 3 1 3 3 2 3 3 1 3 3 2 1 5 6 1 2 1 2 3 1 3 2 1 
 8 1 3 2 1 5 3 4 2 1 2 1 6 3 5 1 2 3 1 6 2 1 2 4 3 
 2 1 2 1 6 5 3 1 2 3 1 3 2 1 2 3 3 1 3 2 1 5 3 4 5 
 1 2 4 3 2 3 1 2 3 1 3 3 3 2 3 4 2 1 2 1 5 6 1 2 1 
 5 1 3 2 1 2 3 3 1 5 1 3 2 7 3 2 1 2 4 5 3 1 2 3 1 
 3 3 2 1 2 4 3 2 1 2 6 1 6 2 1 2 3 1 3 2 1 5 3 1 3 
 2 4 2 3 4 2 1 2 1 2 7 2 3 1 5 4 3 2 1 2 3 1 5 1 2 
 1 6 5 1 2 3 3 1 3 2 3 3 3 1 3 3 3 2 3 6 1 2 3 4 3 
 5 1 2 4 3 3 2 1 2 3 1 3 2 1 3 5 1 5 1 3 2 3 4 2 3 
 6 1 3 2 1 3 2 3 6 1 2 1 2 7 2 3 1 2 3 1 3 5 1 5 1 
 3 2 1 2 6 1 5 1 2 3 3 1 3 3 2 3 3 1 5 1 3 2 3 4 2 
 1 3 2 4 3 2 3 1 2 3 4 3 2 1 5 1 3 2 1 3 5 1 5 3 1 
 2 4 3 2 1 2 3 3 1 3 2 4 2 3 4 2 1 2 1 2 4 3 2 3 6 
 1 3 3 2 3 3 1 3 2 1 2 1 5 1 6 3 2 3 1 5 1 2 3 3 4 
 2 1 3 9 2 1 2 1 2 4 5 3 1 2 4 3 3 3 2 3 1 3 2 3 1 
 5 1 5 1 2 1 2 3 1 3 2 1 2 3 3 4 3 3 2 3 4 2 1 2 1 
 6 3 2 6 3 1 3 3 2 1 2 3 4 3 2 1 5 1 5 1 2 1 2 3 1 
 5 1 2 3 4 3 2 1 3 2 3 4 2 3 1 2 4 3 2 4 2 3 1 3 5 
 3 3 1 3 3 2 1 5 1 5 1 2 1 2 3 4 2 1 5 3 1 3 2 1 3 
 5 4 2 1 2 7 3 2 3 1 2 3 1 6 2 1 2 4 5 1 2 1 5 1 5 
 3 1 2 4 3 2 1 2 3 3 1 3 2 1 5 3 4 3 3 2 4 3 2 3 1 
 2 3 1 3 3 3 2 3 1 3 2 1 2 1 5 6 1 2 1 5 1 3 2 1 2 
 6 1 5 1 5 7 2 1 2 1 2 4 3 5 1 2 3 1 6 2 1 2 3 1 3 
 2 1 2 7 6 2 1 2 3 1 3 2 1 2 3 3 1 3 2 1 3 2 3 4 2 
 3 1 2 7 2 3 1 5 1 3 3 2 1 2 3 6 1 2 1 6 5 1 2 1 5 
 1 3 2 3 3 3 1 3 2 1 3 2 3 4 3 2 3 4 8 1 2 3 1 3 3 
 2 1 2 4 3 2 1 3 5 1 5 1 2 1 2 3 4 2 1 8 1 3 2 4 2 
 3 6 1 2 1 2 4 3 2 3 1 2 3 4 5 1 2 3 1 3 2 1 2 1 5 
 1 5 1 2 3 3 1 3 3 2 3 3 1 3 3 3 2 3 6 1 3 2 4 3 2 
 3 1 2 7 3 2 1 5 1 3 2 1 2 1 5 1 5 1 3 2 4 3 2 3 3 
 3 1 3 2 4 2 3 4 2 1 2 1 2 7 2 3 3 3 1 3 3 2 1 5 1 
 3 2 1 2 6 1 5 1 3 2 3 1 3 3 2 3 3 6 1 3 5 4 2 1 2 
 1 2 4 5 3 1 2 4 3 3 2 1 2 3 1 3 2 4 5 1 5 3 1 2 3 
 1 3 2 1 2 3 3 1 3 3 3 2 3 4 2 1 2 1 2 4 3 2 4 5 1 
 3 3 2 3 3 4 2 1 2 1 5 1 6 2 1 2 3 1 5 1 2 3 4 3 2 
 1 3 2 7 2 3 1 2 4 3 2 3 1 2 3 1 3 3 5 3 1 3 5 1 5 
 1 5 1 2 1 2 3 1 3 2 1 5 3 4 2 1 3 2 3 4 2 1 2 1 6 
 3 2 3 3 3 1 6 2 1 2 4 3 3 2 1 5 1 5 3 1 2 3 1 3 2 
 1 2 3 4 3 2 1 5 3 4 3 2 1 2 4 3 2 4 2 3 1 3 6 2 3 
 1 3 2 1 2 1 5 6 1 2 1 5 4 2 1 2 3 3 1 5 1 3 9 2 1 
 2 3 4 3 2 3 1 2 3 1 3 3 2 1 2 3 1 5 1 2 6 1 6 2 1 
 2 4 3 2 1 2 3 3 1 3 2 1 3 2 3 4 2 1 3 2 7 2 3 1 5 
 1 3 3 2 1 2 3 1 5 1 2 1 11 1 2 1 2 3 1 3 2 3 6 1 3 
 2 1 5 3 4 2 1 2 3 4 3 5 1 2 3 1 6 2 1 2 3 1 3 2 1 
 3 6 5 1 2 1 2 3 4 2 1 2 6 1 3 2 1 3 2 3 6 3 1 2 4 
 3 2 3 1 2 3 1 3 5 1 2 3 4 2 1 2 1 5 1 5 1 2 6 1 3 
 3 2 3 3 1 3 2 1 3 2 3 4 3 3 2 4 5 3 1 2 3 4 3 2 1 
 6 3 2 1 2 1 5 1 5 1 2 1 2 4 3 2 1 5 3 1 3 2 4 2 3 
 4 2 1 2 1 2 4 3 2 3 3 3 4 3 2 1 2 3 1 3 2 1 2 1 5 
 1 5 1 5 3 1 3 2 1 2 3 3 4 3 3 5 6 1 2 1 2 4 5 3 1 
 2 4 3 3 2 1 2 3 1 3 2 3 1 5 1 5 1 3 2 3 1 3 2 3 3 
 3 1 3 3 3 2 3 4 2 1 2 1 2 7 2 4 2 3 1 3 3 2 1 5 4 
 2 1 2 6 1 5 1 2 1 2 3 1 6 2 3 4 5 1 3 2 3 4 2 3 1 
 2 4 3 2 3 1 2 3 1 3 3 2 3 3 1 3 3 3 5 1 5 3 1 2 3 
 1 3 2 1 5 3 1 3 2 1 3 2 3 4 2 1 2 1 6 3 2 3 1 5 1 
 6 2 3 4 3 2 1 2 1 5 1 8 1 2 3 1 5 1 2 3 3 1 3 2 1 
 5 7 3 2 1 2 4 3 2 3 1 2 3 1 3 3 3 2 3 1 3 2 3 1 5 
 6 1 2 1 5 1 3 2 1 2 3 3 6 1 3 2 7 2 1 2 1 6 3 2 3 
 3 3 1 3 3 2 1 2 3 1 3 3 2 6 1 6 2 1 2 3 1 3 2 1 2 
 3 4 3 2 1 3 2 3 4 2 1 2 1 2 7 2 4 5 1 3 5 1 2 3 1 
 5 1 2 1 6 5 1 2 1 2 3 4 2 3 3 3 1 3 2 1 3 5 4 2 1 
 2 3 4 3 5 1 2 3 1 3 3 2 1 2 3 1 5 1 3 5 1 5 1 2 1 
 2 7 2 1 2 6 1 3 2 1 3 2 3 6 1 3 2 4 3 2 3 1 2 3 1 
 3 5 1 2 3 1 3 2 1 2 1 5 6 1 2 3 3 1 3 3 2 6 1 3 2 
 1 5 3 4 2 1 3 2 4 3 5 1 2 3 7 2 1 5 1 3 2 1 2 1 6 
 5 1 2 1 2 4 3 2 1 2 3 3 1 3 2 4 2 3 4 2 3 1 2 4 3 
 2 3 3 3 1 3 3 2 1 2 3 4 2 1 2 1 5 1 5 1 3 5 1 3 2 
 1 2 3 3 4 2 1 3 5 4 3 2 1 2 4 5 3 1 2 4 3 3 2 1 2 
 4 3 2 3 1 5 1 5 1 2 1 2 3 1 3 2 1 5 3 1 3 6 2 3 4 
 2 1 2 1 2 4 3 2 4 2 3 4 3 2 1 2 3 4 2 1 2 1 5 1 5 
 1 2 3 3 1 5 1 2 3 4 3 3 3 2 3 6 3 1 2 4 3 2 3 1 2 
 4 3 3 2 3 3 1 3 3 2 1 5 1 5 1 3 2 3 1 3 2 6 3 1 3 
 2 1 3 2 3 4 2 1 2 1 9 2 3 1 2 3 1 6 2 1 6 3 2 1 2 
 6 1 5 3 1 2 3 1 3 3 2 3 3 1 5 1 5 3 4 3 2 1 2 4 3 
 2 3 1 2 3 1 3 3 3 2 3 1 3 2 1 3 5 6 3 1 5 1 3 2 1 
 2 3 3 1 5 1 3 2 7 2 1 2 1 2 4 3 2 3 1 5 1 3 3 2 3 
 3 1 3 2 1 2 6 1 6 2 1 2 3 1 5 1 2 3 3 1 3 2 1 3 2 
 7 2 1 2 1 2 7 2 3 1 5 1 3 3 3 2 3 1 5 3 1 6 5 1 2 
 1 2 3 1 3 2 3 3 3 4 2 1 3 2 3 4 2 1 2 7 3 5 3 3 1 
 3 3 2 1 2 3 1 3 3 3 5 1 5 1 2 1 2 3 4 2 1 2 7 3 2 
 1 3 2 3 6 1 2 1 2 4 3 2 4 2 3 1 3 5 1 2 3 1 3 2 1 
 2 1 5 1 5 1 2 3 3 4 3 2 3 3 1 3 2 1 3 5 4 2 1 5 4 
 3 2 3 1 2 3 4 3 2 1 5 1 5 1 2 1 5 1 5 1 2 1 2 4 3 
 2 1 2 3 3 1 3 2 4 2 3 4 2 1 3 2 4 3 2 3 3 3 1 3 3 
 2 1 2 3 1 3 2 1 2 1 5 6 1 3 2 3 1 3 2 1 2 6 4 2 1 
 8 4 2 1 2 1 2 4 8 1 2 4 6 2 1 2 3 1 3 2 3 1 6 5 1 
 2 1 2 3 1 3 2 1 2 3 3 1 3 3 3 2 3 4 2 3 1 2 4 3 2 
 4 2 3 1 3 3 2 1 2 3 4 2 1 2 1 5 1 5 1 2 1 5 1 5 1 
 2 3 4 3 2 1 3 2 3 4 5 1 2 4 5 3 1 2 3 1 3 3 2 3 4 
 3 3 2 1 5 1 5 1 2 1 2 3 1 3 2 1 5 3 1 3 2 4 2 3 4 
 2 1 2 1 6 3 2 3 1 2 3 7 2 1 2 4 3 2 1 2 1 5 1 5 3 
 3 3 1 3 2 1 2 3 3 1 3 3 5 3 7 2 1 2 4 3 2 3 1 2 4 
 3 3 3 2 3 1 3 2 1 2 1 5 6 1 3 5 1 3 2 3 3 3 1 5 1 
 3 2 7 2 1 2 1 2 7 2 3 1 2 3 1 3 3 2 1 5 1 3 2 1 2 
 6 1 6 2 1 2 3 1 3 3 2 3 3 1 5 1 3 2 3 4 2 1 2 1 2 
 7 2 3 1 5 1 3 3 2 1 2 3 1 5 1 3 6 5 3 1 2 3 1 3 2 
 3 3 3 1 3 2 1 3 2 3 4 2 1 2 3 4 3 5 1 5 1 3 3 2 3 
 3 1 3 2 1 3 5 1 6 2 1 2 3 6 1 2 6 1 3 2 1 3 2 9 1 
 2 1 2 4 3 2 3 1 2 3 1 3 6 2 3 1 3 2 3 1 5 1 5 1 2 
 3 3 1 3 3 2 3 3 4 2 1 3 2 3 4 2 1 3 6 3 2 3 3 3 4 
 3 2 1 5 1 3 3 2 1 5 1 5 1 2 1 2 4 3 2 1 2 3 4 3 2 
 4 2 3 4 2 1 2 1 2 4 3 2 6 3 1 3 5 1 2 3 1 3 2 1 2 
 1 5 1 5 1 3 2 3 4 2 1 2 3 3 4 2 1 3 5 4 2 1 2 3 4 
 5 3 1 2 4 3 3 2 1 2 3 1 5 3 1 5 1 5 1 2 1 2 4 3 2 
 1 2 3 3 1 3 3 3 2 3 4 2 1 3 2 4 3 2 4 2 3 1 3 3 2 
 1 2 3 4 2 1 2 1 5 6 1 2 1 2 3 1 5 1 2 7 3 2 1 5 3 
 4 2 3 1 2 4 3 5 1 2 3 1 6 2 3 3 1 3 3 2 1 6 5 1 2 
 1 2 3 1 3 2 1 5 3 1 3 2 1 3 2 3 4 2 3 1 6 3 2 3 1 
 2 3 1 6 2 1 2 7 2 1 2 1 5 1 5 3 1 5 1 3 2 1 2 3 3 
 1 3 2 1 5 3 4 3 2 1 2 4 5 3 1 2 3 1 3 3 3 2 4 3 2 
 1 2 1 5 6 1 2 1 5 1 3 2 1 5 3 1 5 4 2 7 2 1 2 1 2 
 4 3 2 3 1 2 3 4 3 2 1 2 3 1 3 2 1 2 6 1 6 2 3 3 1 
 3 2 1 2 3 3 1 3 3 3 2 3 6 1 2 1 2 7 2 3 1 6 3 3 2 
 1 2 3 1 5 1 2 1 6 5 1 3 2 3 1 3 2 3 3 3 1 3 2 1 3 
 2 3 4 2 1 2 3 7 5 1 2 3 1 3 3 2 1 5 1 3 2 1 8 1 5 
 1 2 1 2 3 4 3 2 6 1 5 1 3 2 3 6 1 2 1 2 4 3 2 3 1 
 2 3 1 3 5 1 2 3 1 3 2 1 3 5 1 5 3 3 3 1 3 3 2 3 3 
 1 3 2 1 3 2 3 4 2 1 3 2 4 3 2 3 1 5 4 3 2 6 1 3 2 
 1 2 1 5 1 6 2 1 2 4 5 1 2 3 3 1 3 2 4 2 7 2 1 2 1 
 2 4 3 2 3 3 3 1 3 3 3 2 3 1 3 2 3 1 5 1 5 1 3 2 3 
 1 3 2 1 2 3 3 4 2 1 3 5 4 2 1 2 1 6 5 3 3 4 3 3 2 
 1 2 3 1 3 5 1 5 1 5 1 2 1 2 3 1 3 2 1 2 3 4 3 3 3 
 2 3 4 2 1 2 1 2 4 3 2 4 2 3 1 3 5 1 2 3 4 2 1 2 1 
 5 1 5 1 2 1 2 3 6 1 2 3 4 3 2 1 3 5 4 2 3 3 4 3 2 
 3 1 2 3 1 3 3 2 3 3 1 6 2 1 5 1 5 1 2 1 2 4 3 2 1 
 5 3 1 3 2 1 3 2 3 4 2 1 3 6 3 2 3 1 2 3 1 6 2 1 2 
 4 3 2 1 2 1 5 6 3 1 2 3 1 3 2 1 2 6 1 3 2 1 5 3 4 
 3 2 1 2 4 3 5 1 2 3 1 6 3 2 3 1 3 2 1 2 1 11 1 2 1 
 5 1 3 2 1 2 3 3 1 5 1 3 2 7 2 3 1 2 4 3 2 3 1 2 3 
 1 3 3 2 1 2 3 4 2 1 2 6 1 6 2 1 5 1 3 2 1 2 3 3 1 
 3 2 1 3 2 3 4 3 2 1 2 9 3 1 5 1 3 3 2 1 2 4 5 1 2 
 1 6 5 1 2 1 2 3 1 3 2 6 3 1 3 2 4 2 3 4 2 1 2 3 4 
 3 5 1 2 3 4 3 2 1 2 3 1 3 2 1 3 5 1 5 1 2 3 3 4 2 
 1 2 6 1 3 3 3 2 3 6 1 2 1 2 4 3 2 3 1 2 4 3 5 1 2 
 3 1 3 2 1 2 1 5 1 5 1 5 3 1 3 5 3 3 1 3 2 1 3 2 3 
 4 2 1 3 2 7 2 3 1 2 3 4 3 2 1 5 1 3 2 1 2 6 1 5 1 
 2 1 2 4 3 3 2 3 3 1 5 4 2 3 4 2 1 2 1 2 4 3 2 3 3 
 3 1 3 3 2 1 2 3 1 3 2 1 3 5 1 5 4 2 3 1 3 2 1 2 3 
 3 4 2 1 3 5 4 2 1 2 1 2 4 5 3 1 6 3 3 2 3 3 1 3 2 
 3 1 5 1 6 2 1 2 3 1 5 1 2 3 3 1 3 3 3 2 7 2 1 2 1 
 2 4 3 2 4 2 3 1 3 3 3 2 3 4 2 3 1 5 1 5 1 2 1 2 3 
 1 5 1 2 3 7 2 1 3 2 3 4 2 3 1 6 3 2 3 3 3 1 3 3 2 
 3 3 1 3 3 2 1 5 1 5 1 2 1 2 3 1 3 2 1 5 4 3 2 1 3 
 2 3 4 2 1 2 1 6 3 2 4 2 3 1 8 1 2 4 3 2 1 2 1 5 1 
 5 3 1 2 3 4 2 1 2 3 3 1 3 2 1 8 4 3 2 3 4 3 2 3 1 
 2 3 1 3 3 3 2 3 1 5 1 2 1 5 6 1 2 1 6 3 2 1 2 3 3 
 1 5 1 3 2 7 2 1 3 2 4 3 2 3 1 2 3 1 3 3 2 1 2 3 1 
 3 2 1 2 6 7 2 1 2 3 1 3 2 1 2 6 1 3 2 1 5 3 4 2 1 
 2 1 2 7 5 1 5 1 6 2 1 2 3 1 5 1 2 1 6 5 1 2 1 2 3 
 1 3 2 3 3 3 1 3 2 1 3 2 3 4 2 3 3 4 3 5 1 2 3 1 3 
 3 2 1 2 3 4 2 1 3 5 1 5 1 2 1 5 4 2 1 2 6 1 3 2 1 
 3 2 3 7 2 1 2 4 5 3 1 2 3 1 3 5 1 2 4 3 2 1 2 1 5 
 1 5 1 2 3 3 1 3 3 5 3 1 3 2 4 2 3 4 2 1 3 2 4 3 2 
 3 1 2 3 4 3 2 1 5 1 3 2 1 2 1 5 1 5 1 2 3 4 3 2 1 
 2 3 3 1 3 6 2 3 6 1 2 1 2 4 3 2 3 3 4 3 3 2 1 2 3 
 1 3 2 1 2 1 5 1 5 1 3 2 3 1 3 2 3 3 3 4 2 1 3 5 4 
 2 1 2 1 2 9 3 1 2 4 3 3 2 1 5 1 3 2 3 6 1 5 1 2 1 
 2 3 1 3 3 2 3 3 1 6 3 2 3 4 2 1 2 1 2 4 3 2 4 2 3 
 1 3 3 2 1 2 3 4 2 1 3 5 1 5 3 1 2 3 1 5 1 2 3 4 3 
 2 1 3 2 3 4 2 3 1 2 4 3 2 3 1 5 1 3 3 2 3 3 1 3 3 
 2 1 5 1 6 2 1 2 3 1 5 1 5 3 1 3 2 1 3 2 7 2 1 2 1 
 6 3 2 3 1 2 3 1 6 3 2 4 3 2 3 1 5 1 5 3 1 2 3 1 3 
 2 1 2 3 3 4 2 1 5 3 4 3 2 1 6 3 2 3 3 3 1 3 3 3 2 
 3 1 3 3 2 1 5 6 1 2 1 5 1 3 2 1 2 3 4 5 1 3 2 7 2 
 1 2 1 2 4 3 2 4 2 3 1 3 5 1 2 3 1 3 2 1 2 6 1 6 2 
 1 2 3 4 2 1 2 3 3 1 3 2 1 3 5 4 2 1 2 3 7 2 3 1 5 
 1 3 3 2 1 2 3 1 5 1 2 1 6 5 1 2 1 2 4 3 2 3 3 3 1 
 3 2 1 3 2 3 4 2 1 5 4 3 5 1 2 3 1 3 3 2 1 2 3 1 3 
 2 1 3 5 6 1 2 1 2 3 4 2 1 2 6 1 3 2 1 5 3 6 1 2 1 
 2 4 3 5 1 2 3 1 8 1 2 3 1 3 2 1 2 1 6 5 1 2 3 3 1 
 3 3 2 3 3 1 3 2 1 3 2 3 4 2 4 2 4 3 2 3 1 2 3 4 3 
 2 1 5 4 2 1 2 1 5 1 5 1 2 1 6 3 2 1 2 3 3 1 3 2 4 
 2 3 4 3 2 1 2 4 5 3 3 3 1 3 3 2 1 2 4 3 2 1 2 1 5 
 1 5 1 3 2 3 1 3 2 1 5 3 4 2 4 5 4 2 1 2 1 2 4 5 3 
 1 2 7 3 2 1 2 3 1 3 2 3 1 5 1 5 1 2 3 3 1 3 2 1 2 
 3 3 1 3 3 3 2 3 6 1 2 1 2 4 3 2 4 2 4 3 3 2 1 2 3 
 4 2 1 2 1 5 1 5 1 3 2 3 1 5 3 3 4 3 2 1 3 2 3 4 2 
 3 1 2 7 2 3 1 2 3 1 3 3 2 6 1 3 3 2 6 1 5 1 2 1 2 
 3 1 3 3 5 3 1 5 1 3 2 3 4 2 1 2 1 6 3 2 3 1 2 3 1 
 6 2 1 2 4 3 2 1 3 5 1 5 3 1 2 3 1 3 2 1 2 3 3 1 3 
 2 1 5 3 4 3 2 1 2 4 3 2 3 1 5 1 3 3 5 3 1 3 2 1 2 
 1 5 7 2 1 5 1 5 1 2 3 3 1 5 1 3 2 7 2 1 2 1 2 4 3 
 2 3 1 2 3 1 3 3 3 2 3 1 3 2 3 6 1 6 2 1 2 3 1 3 2 
 1 2 3 3 4 2 1 3 2 3 4 2 1 2 1 9 2 3 6 1 3 3 2 1 2 
 3 1 6 2 1 6 5 1 2 1 2 3 1 3 2 3 3 4 3 2 1 3 2 3 4 
 2 1 2 3 4 3 6 2 3 1 3 5 1 2 3 1 3 2 1 3 5 1 5 1 2 
 1 2 3 4 2 1 2 6 1 3 2 1 3 5 6 1 2 3 4 3 2 3 1 2 3 
 1 3 5 1 2 3 1 5 1 2 1 5 1 5 1 2 3 4 3 3 2 3 3 1 3 
 2 1 3 2 3 4 2 1 3 2 4 3 2 3 1 2 3 4 3 2 1 5 1 3 2 
 1 2 1 5 6 1 2 1 2 4 3 2 1 2 6 1 3 2 6 3 4 2 1 2 1 
 2 4 3 5 3 3 1 6 2 1 2 3 1 3 2 1 2 1 6 5 1 3 2 3 1 
 3 2 1 2 3 3 4 2 1 3 5 4 2 3 1 2 4 5 3 1 2 4 3 3 2 
 1 2 3 4 2 3 1 5 1 5 1 2 1 5 1 3 2 1 2 3 3 1 3 3 3 
 2 3 4 3 2 1 2 4 5 4 2 3 1 3 3 2 1 2 7 2 1 2 1 5 1 
 5 1 2 1 2 3 1 5 1 5 4 3 2 4 2 3 4 2 3 1 2 4 3 2 3 
 1 2 3 4 3 2 3 3 1 3 3 2 1 5 1 5 1 2 3 3 1 3 2 1 5 
 3 1 3 3 3 2 3 6 1 2 1 6 3 2 3 1 2 4 6 2 1 2 4 3 2 
 1 2 1 5 1 5 4 2 3 1 3 2 3 3 3 1 3 2 1 5 3 4 3 2 1 
 2 7 2 3 1 2 3 1 3 3 3 5 1 3 2 1 2 6 6 1 2 1 5 1 3 
 3 2 3 3 1 5 1 3 2 7 2 1 2 1 2 4 3 2 3 1 2 3 1 3 3 
 2 1 2 3 1 3 2 1 8 1
))


(defstruct sieve-state
  (maxints -1 :type fixnum :read-only t)
  (a nil :type simple-array))


(defun create-sieve (maxints)
  (declare (fixnum maxints))
  (make-sieve-state
    :maxints maxints
    :a (make-array
         (1+ (floor maxints +bits-per-word+))
         :element-type '(unsigned-byte 64)
         :initial-element 0)))


(defun run-sieve (sieve-state steps)
  (declare (sieve-state sieve-state) (simple-vector steps))

  (let* ((maxints (sieve-state-maxints sieve-state))
         (maxintsh (ash maxints -1))
         (a (sieve-state-a sieve-state))
         (q (1+ (isqrt maxints)))
         (step 1)
         (inc (aref steps step))
         (factorh (ash 17 -1))
         (qh (ash q -1)))
    (declare (fixnum maxints maxintsh q step inc factorh qh)
             (type (array (unsigned-byte 64) 1) a))
    (do () ((> factorh qh))

      (if (not (zerop (logand (aref a (ash factorh +SHIFT+))
                              (ash 1 (logand factorh +MASK+)))))
            (progn
              (incf factorh inc)
              (when (= (incf step) 5760) (setq step 0))
              (setq inc (aref steps step)))

        (let* ((istep step)
               (ninc (aref steps istep))
               (factor (1+ (ash factorh 1))))
          (declare (fixnum istep ninc factor))

          (do ((i (ash (the fixnum (* factor factor)) -1)))
              ((> i maxintsh))
            (declare (fixnum i))
            (setf (aref a (ash i +SHIFT+))
                  (logior (aref a (ash i +SHIFT+))
                          (ash 1 (logand i +MASK+))))
            (incf i (the fixnum (* factor ninc)))
            (when (= (incf istep) 5760) (setq istep 0))
            (setq ninc (aref steps istep)))

          (incf factorh inc)
          (if (= (incf step) 5760) (setq step 0))
          (setq inc (aref steps step)))))))


(defun count-primes (sieve-state)
  (declare (sieve-state sieve-state))
  (let* ((maxints (sieve-state-maxints sieve-state))
         (a (sieve-state-a sieve-state))
         (ncount 6)
         (factor 17)
         (step 1)
         (inc (ash (aref +steps+ step) 1)))
    (declare (fixnum maxints ncount factor inc)
             (type (array (unsigned-byte 64) 1) a))
    (do () ((> factor maxints))
      (when (zerop (logand (aref a (ash factor (+ -1 +SHIFT+)))
                           (ash 1 (logand (ash factor -1) +MASK+))))
        (incf ncount))
      (incf factor inc)
      (when (= (incf step) 5760) (setq step 0))
      (setq inc (ash (the fixnum (aref +steps+ step)) 1)))
    ncount))


;(disassemble 'run-sieve)


(let* ((passes 0)
       (start (get-internal-real-time))
       (end (+ start (* internal-time-units-per-second 5)))
       result)
  (declare (fixnum passes))

  (do () ((>= (get-internal-real-time) end))
    (setq result (create-sieve 1000000))
    (run-sieve result +steps+)
    (incf passes))

  (let* ((duration  (/ (- (get-internal-real-time) start) internal-time-units-per-second))
         (avg (/ duration passes)))
    (format *error-output* "Passes: ~d  Time: ~f Avg: ~f ms Count: ~d~%" passes duration (* 1000 avg)  (count-primes result))

    (format t "mayerrobert-cl-wheel;~d;~f;1;algorithm=wheel,faithful=no,bits=1~%" passes duration)))
