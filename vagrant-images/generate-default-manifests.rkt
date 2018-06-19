#lang racket

(require racket/runtime-path)

;; this file generates the default.pp manifest for each configuration,
;; and copies the Vagrantfile into each one

(define-runtime-path here ".")

;; a declaration has a kind[symbol], a name [string], and a list of
;; interior lines [(Listof (List Symbol String))]
(struct decl (kind name lines))

;; map a decl to a string
(define (decl->string the-decl)
  (match-define (decl kind name lines) the-decl)
  (apply
   string-append
   (add-between
    (append
     (list (~a kind " { \"" name "\":"))
     (map interior-line-string lines)
     (list "}"))
    "\n")))

;; given a subdirectory name and a list of decls and strings,
;; write the manifest
(define (write-manifest subdir clauses)
  (call-with-output-file (build-path here
                                     subdir
                                     "manifests/default.pp") 
    #:exists 'truncate
    (λ (port)
      (for ([c (in-list clauses)])
        (displayln
         (cond [(decl? c)   (decl->string c)]
               [(string? c) c]
               [else
                (error 'write-manifest
                       "expected decl or string, got: ~e"
                       c)])
         port)
        (newline port)))))

;; an include string
(define (include name)
  (~a "include "name))

;; given lhs and rhs strings, return a declaration interior line
(define (interior-line-string pr)
  (match-define (list lhs rhs) pr)
  (define rhs-str
    (match rhs
      [(list 'str (? string? s)) (~a "'" s "'")]
      [(? string? s) s]))
  (string-append "  " (symbol->string lhs) " => " rhs-str ","))


;; given a name and lines, return a package require decl
(define (package-require name [lines '()])
  (decl 'package name (cons '(ensure (str "installed")) lines)))

;; the decl for the java runtime
(define java-runtime-decl
  (decl 'class 'java '((distribution (str "jre")))))

;; the decls for the python 3.6 +
;; total fail, package has all kinds of strange conflicts.
#;(define python-decls
  (list (decl 'class "python"
              '())
        (decl 'python::pip "antlr"
              '((pkgname "antlr4-python3-runtime")))))

;; the decl for the whole java jdk
(define java-jdk-decl
  (include 'java))

;; the packages required on all vms
(define common-packages '(clang nasm gcc-multilib make))

;; the decls required for the racket ppa
(define racket-decls
  (list (include 'apt)
        (decl 'apt::ppa "ppa:plt/racket" '())
        (package-require 'racket '((require "Apt::Ppa['ppa:plt/racket']")))))

(define scala-decls
  (list (include 'apt)
        (decl 'apt::source
              "sbt_source"
              '((location (str "https://dl.bintray.com/sbt/debian"))
                (release (str ""))
                (repos (str "/"))
                (key "{ 'id' => '2EE0EA64E40A89B84B2DF73499E82A75642AC823',
   'server' => 'keyserver.ubuntu.com' }")))
        (package-require 'sbt
                         '((require "Apt::Source['sbt_source']")))
        (package-require 'scala)))

;; the decls required on all vms
(define common-package-decls
  (append
   racket-decls
   (for/list ([p (in-list common-packages)])
     (package-require p))))


(define vms
  `(("racket-image"
     ,(cons java-runtime-decl
            common-package-decls))
    ("c-c++-image"
     ,(list* java-runtime-decl
             (package-require 'bison)
             common-package-decls))
    ("java-scala-clojure-image"
     ,(append (list java-jdk-decl)
              scala-decls
              (list (package-require 'ant)
                    (package-require 'leiningen))
              common-package-decls))
    ("js-image"
     ,(list* java-jdk-decl
             (package-require 'npm)
             common-package-decls))
    ("python-image"
     ,(list* java-jdk-decl
             (package-require 'python3.6)
             (package-require 'python3-pip)
             (append
              ;python-decls
              common-package-decls)))
    ("sml-image"
     ,(list* java-jdk-decl
             (package-require 'smlnj)
             (package-require 'mlton)
             common-package-decls))
    ("ghc-image"
     ,(list* java-jdk-decl
             (package-require 'haskell-platform)
             common-package-decls))))



;; given a subdirectory name, copy the Vagrantfile into it
(define (copy-vagrantfile subdir)
  (copy-file (build-path here "Vagrantfile")
             (build-path here subdir "Vagrantfile")
             #t))

;; given a subdirectory name, copy the test-runner and the
;; m4 test files into it
(define (copy-test-files subdir test-set)
  (define tgt (build-path here subdir))
  (define (squish srcname tgtname)
    (delete-directory/files (build-path tgt tgtname)
                            #:must-exist? #f)
    (copy-directory/files (build-path here srcname)
                          (build-path tgt tgtname)))
  (squish "test-runner.rkt" "test-runner.rkt")
  (squish "m4-tests" "testing"))

(for ([pr (in-list vms)])
  (match-define (list name clauses) pr)
  (copy-vagrantfile name)
  (write-manifest name clauses)
  (copy-test-files name "m4-tests"))



