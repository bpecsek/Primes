;;;; Common Lisp port of PrimeC/solution_2/sieve_5760of30030_only_write_read_bits.c by Daniel Spangberg
;;;
;;; approx. 2.7x speedup over PrimeSieve.lisp, approx. 335x speedup over solution_1
;;;
;;; run as:
;;;     sbcl --script PrimeSieveWheel.lisp
;;;
;;; Algorithm is _wheel_, see PrimeC/solution_2/README.md for a better explanation than I would be able to give.
;;; I have no idea how the wheel algorithm works, I just stole the algorithm.
;;;
;;; For Common Lisp bit ops see https://lispcookbook.github.io/cl-cookbook/numbers.html#bit-wise-operation,
;;; although most of the shifts were replaced by "normel" Lisp functions,
;;; e.g. x>>n -> (floor x m), a&b -> (mod a b), 1<<x -> (expt 2 x)
;;; because sbcl optimizes these rather efficiently.
;;; Only logior and logand remain.
;;;
;;; (compile-file "PrimeSieveWheel.lisp") will show info during the compilation
;;; regarding any inefficient code that can't be optimized.
;;; I added type declarations until there were no more messages concerning run-sieve.


(declaim
  (optimize (speed 3) (safety 0) (debug 0)))


(defconstant +bits-per-word+ 64)

(deftype sieve-bitpos-type ()
  `(integer 0 63))

(deftype sieve-element-type ()
  `(unsigned-byte 64))

(deftype sieve-array-type ()
  `(simple-array sieve-element-type 1))


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
         (1+ (floor (floor maxints +bits-per-word+) 2))
         :element-type 'sieve-element-type
         :initial-element 0)))


(declaim (inline nth-bit-set-p)
         (inline set-nth-bit))

(defun nth-bit-set-p (a n)
  (declare (type sieve-array-type a)
           (fixnum n))
  (multiple-value-bind (q r) (floor n +bits-per-word+)
    (declare (fixnum q r))
    (/= 0 (logand (aref a q) (expt 2 r)))))

(defun set-nth-bit (a n)
  (declare (type sieve-array-type a)
           (fixnum n))
  (multiple-value-bind (q r) (floor n +bits-per-word+)
    (declare (fixnum q r))
    (setf #1=(aref a q)
         (logior #1# (expt 2 r)))))


(defun run-sieve (sieve-state steps)
  (declare (sieve-state sieve-state) (type (simple-vector) steps))

  (do* ((maxints (sieve-state-maxints sieve-state))
        (maxintsh (floor maxints 2))
        (a (sieve-state-a sieve-state))
        (q (1+ (isqrt maxints)))
        (step 1  (if (= step 5759) 0 (1+ step)))
        (inc (aref steps step) (aref steps step))
        (factorh (floor 17 2))
        (qh (floor q 2)))
       ((> factorh qh) sieve-state)
    (declare (fixnum maxints maxintsh q step inc factorh qh)
             (type sieve-array-type a))
    (unless (nth-bit-set-p a factorh)
      (do* ((istep step (if (= istep 5759) 0 (1+ istep)))
            (ninc (aref steps istep) (aref steps istep))
            (factor (1+ (* factorh 2)))
            (i (floor (the fixnum (* factor factor)) 2)))
           ((> i maxintsh))
        (declare (fixnum istep ninc factor i))
        (set-nth-bit a i)
        (incf i (the fixnum (* factor ninc)))))

    (incf factorh inc)))


(defun count-primes (sieve-state)
  (declare (sieve-state sieve-state))
  (do* ((maxints (sieve-state-maxints sieve-state))
        (a (sieve-state-a sieve-state))
        (ncount 6)
        (factor 17)
        (step 1  (if (= step 5759) 0 (1+ step)))
        (inc (* (aref +steps+ step) 2) (* (the fixnum (aref +steps+ step)) 2)))
       ((> factor maxints) ncount)
     (declare (fixnum maxints ncount factor inc)
              (type sieve-array-type a))
     (unless (nth-bit-set-p a (floor factor 2))
       (incf ncount))
     (incf factor inc)))


;(disassemble 'nth-bit-set-p)
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
    (format *error-output* "Passes: ~d, Time: ~f, Avg: ~f ms, Count: ~d~%" passes duration (* 1000 avg)  (count-primes result))

    (format t "mayerrobert-cl-wheel;~d;~f;1;algorithm=wheel,faithful=no,bits=1~%" passes duration)))
