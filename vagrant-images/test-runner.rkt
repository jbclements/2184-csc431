#lang racket

(require racket/runtime-path)

(define-runtime-path here ".")

(define project-path (build-path here "project"))
(define testing-path (build-path here "testing"))

;; a test-plan is a list of test-items
;; a test-item is a list containing a filename and an expected-result
;; an expected-result is 'compiletime-error for a file that's expected
;; to fail at compile-time, 'runtime-error for a file that's expected
;; to fail at runtime, and a string with expected output for a file
;; that's expected to succeed
(define test-plan (file->value (build-path testing-path "test-plan.rktd")))


(define stdout-log (open-output-file
                    #:exists 'truncate
                    (build-path testing-path
                                "./testing-stdout.txt")))
(define stderr-log (open-output-file
                    #:exists 'truncate
                    (build-path testing-path
                                "./testing-stderr.txt")))

;; check that the predicate is satisfied by the value
(define (check-pred pred v)
  (cond [(pred v) #t]
        [else (fprintf stderr-log
                       "check failed: pred ~e not satisfied by value ~e\n"
                       pred v)
              #f]))

;; check that the two values are equal?
(define (check-equal? a b)
  (cond [(equal? a b) #t]
        [else (fprintf stderr-log
                       "check failed: values ~e and ~e are not equal?.\n"
                       a b)
              #f]))

(define nonzero? (λ (n) (not (= n 0))))
(define zero? (λ (n) (= n 0)))

;; compile the given file, logging stdout and stderr. return
;; the error code
(define (run-compiler file)
  (define complete-path (let ([ans (path->complete-path file)])
                          (printf "complete-path: ~s\n" ans)
                          ans))
  (parameterize ([current-directory (build-path here "project")])
    (run-with-logging
     (λ () (system*/exit-code
            (build-path here "project"
                           "consieuten")
            (let ([ans complete-path])
              (printf "complete-path: ~s\n" ans)
              ans))))))

;; run the thunk with stdout and stderr redirected
(define (run-with-logging thunk)
  (parameterize ([current-output-port stdout-log]
                 [current-error-port stderr-log])
    (thunk)))

;; run the thunk, return both result of thunk and stdout produced
(define (run-for-stdout thunk)
  (define out-str (open-output-string))
  (list (parameterize ([current-output-port out-str]
                       [current-error-port stderr-log])
          (thunk))
        (get-output-string out-str)))

;; test each item
(define test-results
  (for/list ([test-item (in-list test-plan)])
    (match-define (list filename expected) test-item)
    (define test-input-path (build-path "testing" filename))
    (fprintf stdout-log "# file: ~v\n" filename)
    (flush-output stdout-log)
    (fprintf stderr-log "# file: ~v\n" filename)
    (flush-output stderr-log)
  
    (match expected
      ['compiletime-error
       (check-pred nonzero?
                   (run-compiler test-input-path))]
      [(? string? s)
       (and
        (check-pred zero? (run-compiler test-input-path))
        (let ()
          (match-define (list exit-code out-str)
            (run-for-stdout (λ () (system*/exit-code
                                   (build-path here "project"
                                               "a.out")))))
          (and
           (check-pred zero? exit-code)
           (check-equal? (string-trim out-str)
                         (string-trim s)))))])))

(fprintf stdout-log
         "# final result: \n~a\n" test-results)

