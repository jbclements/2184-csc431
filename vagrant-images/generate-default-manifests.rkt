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
  (define full-clauses
    (append clauses common-package-decls))
  (call-with-output-file (build-path here
                                     subdir
                                     "manifests/default.pp") 
    #:exists 'truncate
    (λ (port)
      (for ([c (in-list full-clauses)])
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
  (string-append "  " (symbol->string lhs) " => " rhs ","))

;; given a name and lines, return a package require decl
(define (package-require name [lines '()])
  (decl 'package name (cons '(ensure "'installed'") lines)))

;; the decl for the java runtime
(define java-runtime-decl
  (decl 'class 'java '((distribution "'jre'"))))

;; the decl for the whole java jdk
(define java-jdk-decl
  (include 'java))

;; the packages required on all vms
(define common-packages '(clang nasm gcc-multilib make))

;; the decls required on all vms
(define common-package-decls
  (for/list ([p (in-list common-packages)])
    (package-require p)))

(define vms
  `(("racket-image"
     (,(include 'apt)
      ,(decl 'apt::ppa "ppa:plt/racket" '())
      ,(package-require 'racket
                       '((require "Apt::Ppa['ppa:plt/racket']")))
      ,java-runtime-decl))
    ("c-c++-image" (,java-runtime-decl))
    ("java-scala-clojure-image"
     ,(list java-jdk-decl
            (package-require 'ant)
            (package-require 'scala)))
    ("js-image"     (,java-runtime-decl ,(package-require 'nodejs)))
    ("python-image" ,(list java-jdk-decl
                           (package-require 'python3.6)))
    ("sml-image"    (,java-runtime-decl ,(package-require 'smlnj)))
    ("ghc-image"    (,java-runtime-decl ,(package-require 'haskell-platform)))))

;; given a subdirectory name, copy the Vagrantfile into it
(define (copy-vagrantfile subdir)
  (copy-file (build-path here "Vagrantfile")
             (build-path here subdir "Vagrantfile")
             #t))

(for ([pr (in-list vms)])
  (match-define (list name clauses) pr)
  (copy-vagrantfile (first pr))
  (write-manifest (first pr) (second pr)))



