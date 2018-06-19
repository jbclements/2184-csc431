#lang racket

(require racket/runtime-path)

(define-runtime-path here ".")

(define project-path (build-path here "project"))
(define testing-path (build-path here "testing"))

;; number of seconds to wait before concluding that
;; a test has failed
(define MAXWAIT 30)

;; extra flags required by a nonconforming compiler:
(define extra-flags '(#;"-O0"))

;; a test-plan is a list of test-groups

;; a test group is (cons <group-name> (cons <num-points> <list-of-test-items))

;; a test-item is a list containing a filename and an expected-result

;; an expected-result is 'compiletime-error for a file that's expected
;; to fail at compile-time, 'runtime-error for a file that's expected
;; to fail at runtime, and a string with expected output for a file
;; that's expected to succeed

(define compiler-name "consieuten")

(define test-plan (file->value (build-path testing-path "test-plan.rktd")))
(define consieuten-exec-path
  (let ()
    (define expected-exec-path-file (build-path project-path "consieuten-path"))
    (define exec-dir
      (cond [(file-exists? expected-exec-path-file)
             (define path
               (build-path project-path
                           (string-trim (file->string expected-exec-path-file))))
             
             path]
            [else
             (printf "no 'consieuten-path' file found. Using project directory\n")
             project-path]))
    (define compiler-file (build-path exec-dir compiler-name))
    (unless (file-exists? compiler-file)
      (error 'consieuten-exec-path
             "given path to consieuten executable doesn't refer to existing file: ~e"
             compiler-file))
    exec-dir))

(define generated-executable-path
  (build-path consieuten-exec-path "a.out"))


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

(define subprocess-env
  (let ()
    (define new-env
      (environment-variables-copy (current-environment-variables)))
    (environment-variables-set!
     new-env
     #"CLASSPATH"
     #"/vagrant/antlr-4.7.1-complete.jar:.")
    new-env))

;; compile the given file, logging stdout and stderr. return
;; the error code
(define (run-compiler file)
  (printf "testing file: ~v\n" file)
  (define complete-path (path->complete-path file))
  (parameterize ([current-directory consieuten-exec-path]
                 [current-environment-variables subprocess-env])
    (run-with-logging
     (λ ()
       (when (file-exists? generated-executable-path)
         (delete-file generated-executable-path))
       (apply
            system*/exit-code
            (build-path consieuten-exec-path
                        compiler-name)
            (append
             extra-flags
             (list complete-path)))))))

;; run the thunk with stdout and stderr redirected
(define (run-with-logging thunk)
  (parameterize ([current-output-port stdout-log]
                 [current-error-port stderr-log])
    (thunk)))

;; run the thunk, return both result of thunk and stdout produced,
;; or #f if the process timed out.
(define (run-for-stdout thunk)
  (define ch (make-channel))
  (define executable-thread
    (thread
     (λ ()
       (define out-str (open-output-string))
       (channel-put
        ch
        (list (parameterize ([current-output-port out-str]
                             [current-error-port stderr-log])
                (thunk))
              (get-output-string out-str))))))
  (or
   (sync/timeout MAXWAIT ch)
   (begin
     (fprintf stderr-log
              "timeout... program didn't halt after ~v seconds\n"
              MAXWAIT)
     ;; this does *not* kill the subprocess...
     (kill-thread executable-thread)
     #f)))


;; run one test
(define (run-test source-file maybe-input expected-out-str)
  (define input-port
    (cond [maybe-input (open-input-file maybe-input)]
          [else (open-input-string "")]))
  (and
   (check-pred zero? (run-compiler source-file))
   (let ()
     (define run-result
       (parameterize ([current-input-port input-port]
                      [current-environment-variables subprocess-env])
         (run-for-stdout (λ () (system*/exit-code
                                generated-executable-path)))))
     (match run-result
       [#f #f]
       [(list exit-code out-str)
        (when maybe-input (close-input-port input-port))
        (and
         (check-pred zero? exit-code)
         (check-equal? (string-trim out-str)
                       (string-trim expected-out-str)))]))))

;; test each item
(define test-results
  (for/list ([test-group (in-list test-plan)])
    (append
     (take test-group 2)
     (for/list ([test-item (in-list (rest (rest test-group)))])
       (match-define (list filename maybe-infile expected)
         (match test-item
           [(list a b c) (list a b c)]
           [(list a c) (list a #f c)]))
       (define test-input-path (build-path testing-path filename))
       (fprintf stdout-log "# file: ~v\n" filename)
       (flush-output stdout-log)
       (fprintf stderr-log "# file: ~v\n" filename)
       (flush-output stderr-log)
  
       (match expected
         ['compiler-error
          (check-pred nonzero?
                      (run-compiler test-input-path))]
         [(list 'file expected-output-path)
          (run-test test-input-path
                    (and maybe-infile (build-path testing-path maybe-infile))
                    (file->string (build-path testing-path expected-output-path)))]
         [(? string? out-str)
          (run-test test-input-path
                    (and maybe-infile (build-path testing-path maybe-infile))
                    out-str)])))))

(fprintf stdout-log
         "# final result: \n~a\n" test-results)
(close-output-port stdout-log)

