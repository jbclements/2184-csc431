;; this file contains a test plan, consisting of a list of test-categories.
;#lang racket

;; each category is a list of the form (cons category-name (cons points test-list))
;; where category-name is a symbol, points is a natural number, and
;; test-list is a list of tests.

;; a test is one of:
;; - (list source-file input behavior-spec), indicating that running the
;; named source-file with input taken from the named input file should
;; match the given behavior-spec, or
;; - (list source-file behavior-spec), indicating that running the named
;; source-file with empty input should match the given behavior-spec

;; a behavior-spec is one of:
;; - a string, representing text to appear on stdout when running the
;;   compiled (after trimming leading and trailing whitespace),
;; - (list 'file filename), indicating that the named file contains text
;;   that should match that produced by running the compiled program, or
;; - 'compiler-error, indicating that the compiler should signal an error
;;   for the given input file.

;(provide test-plan)

;(define test-plan
  ;'
((simplest-program
     8
     ("straight-line-a.co" "882"))
    (straight-line
     4    
     ("straight-line-b.co" "56")
     ("straight-line-c.co" "11")
     ("straight-line-1.co" "10117")
     ("num-ops.co" "1759390405"))
    (branching-with-if
     1
     ("if-branching.co" "15"))
    (top-level-first-order-funs
     4
     ("simplest-fun-call.co" "14")
     ("simple-fun-calls.co" "165")
     ("fun-calls.co" "24")
     ("first-order-murec.co" "321")
     )
    (higher-order-top-level-funs
     1
     ("ho-funs.co" "-784"))
    (inner-functions
     1
     ("lifting.co" "-190826"))
    (while
     1
     ("simple-while.co" "10")
     ("while.co" "1"))
    
    (structs
     3
     ("structs-example.co" "19")
     ("ll-ops.co" "144")
     ("bintreesort.co" "0 0 0 0 0 0 0 0 0 1 1 1 1\
 1 1 2 2 2 2 2 2 2 2 2 2 2 3 3 3 3 3 3 3 4 4 4\
 4 4 4 4 4 4 5 5 5 5 5 5 5 5 5 5 5 5 6 6 7 7 7\
 7 7 8 8 8 8 8 8 8 8 9 9 9 9 9 9 0"))
    (io
     2
     ("simple-read.co" "simple-read.in1" "230")
     ("simple-print.co" "42 221 2
0")
     ("io.co" "io.in1" "10
0")
     ("io.co" "io.in2" "20
0"))
    (closures
     2
     ("closure-1.co" "1234") 
     ("curry3-closures.co" (file "curry3-closures.out")))
    (everything-tests
     2
     ("interp.co" "interp.in1" (file "interp.out1"))
     ("interp.co" "interp.in2" (file "interp.out2"))
     ("interp.co" "interp.in3" (file "interp.out3"))
     ("interp.co" "interp.in20" (file "interp.out20")))
    (type-checking
     3
     ("tc-good.co" "-190826")
     ("tc-bad-1.co" compiler-error)
     ("tc-bad-2.co" compiler-error)
     ("tc-bad-3.co" compiler-error)
     ("tc-bad-4.co" compiler-error)
     ("tc-bad-5.co" compiler-error)
     ("tc-bad-7.co" compiler-error)
     ("tc-bad-8.co" compiler-error)
     ("tc-bad-9.co" compiler-error)
     ("tc-bad-10.co" compiler-error)
     ("tc-bad-11.co" compiler-error)
     ("tc-bad-12.co" compiler-error)
     ("tc-good-2.co" "27")
     ("tc-bad-20.co" compiler-error)
     ("tc-bad-21.co" compiler-error)
     ("tc-bad-22.co" compiler-error)
     ("tc-bad-24.co" compiler-error)
     )
    
    
    
    )
;)
