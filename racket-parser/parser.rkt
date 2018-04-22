#lang racket

;; this is the consieuten parser for Milestone 2

(require parser-tools/lex
         (prefix-in : parser-tools/lex-sre)
         parser-tools/yacc)


;; PROVIDE
(define s-expression/c
  (flat-rec-contract s-expression/c
                     (or/c symbol? string? null? number? boolean?
                           (cons/c s-expression/c s-expression/c))))

(provide/contract [string->tree (string? . -> . s-expression/c)])

;; given a string, parse it into an s-expression representing the AST
(define (string->tree str)
  (let* ([input-port (open-input-string str)]
         [lexer (lambda () (consieuten-lexer input-port))])
    (consieuten-parser lexer)))

;; LEXER (breaks string up into tokens)

;; token definitions:

(define-empty-tokens delimiters
  (EOF LBRACK RBRACK LPAREN RPAREN COMMA SEMICOLON))
(define-empty-tokens special-operators
  (PLUS MINUS TIMES DIVIDE GETS ARROW
        EQUALS NOT-EQUALS GT GEQ LT LEQ NOT AND OR))
(define-empty-tokens keywords
  (FUN RETURN INT BOOL IF WHILE ELSE NEW))
(define-tokens regular (INTLIT  BOOL-LIT ID))

;; here's the lexer:
(define consieuten-lexer
  (lexer-src-pos
   [(:+ whitespace) (return-without-pos (consieuten-lexer input-port))]
   [(:or
     (:: (char-range "1" "9") (:* (char-range "0" "9")))
     "0")
    (token-INTLIT (string->number lexeme))]
   [(:: (:or (char-range "a" "z")
             (char-range "A" "Z"))
        (:* (:or (char-range "a" "z")
                 (char-range "A" "Z")
                 (char-range "0" "9"))))
    (id-or-keyword lexeme)]

   ["->" (token-ARROW)]
   ["+" (token-PLUS)]
   ["-" (token-MINUS)]
   ["*" (token-TIMES)]
   ["/" (token-DIVIDE)]

   ["{" (token-LBRACK)]
   ["}" (token-RBRACK)]
   ["(" (token-LPAREN)]
   [")" (token-RPAREN)]
   ["," (token-COMMA)]
   [";" (token-SEMICOLON)]

   ["!=" (token-NOT-EQUALS)]
   ["==" (token-EQUALS)]
   ["&&" (token-AND)]
   ["||" (token-OR)]
   
   [">=" (token-GEQ)] 
   [">" (token-GT)]
   ["<=" (token-LEQ)]
   ["<" (token-LT)]
   ["!" (token-NOT)]
   
   ["=" (token-GETS)]
   
   [(eof) (token-EOF)]

   [any-char (error 'consieuten-lexer
                    "no match found for ~a at location ~a"
                    lexeme
                    start-pos)]))

;; some IDs should be 
(define (id-or-keyword str)
  (case (string->symbol str)
    [(fun) (token-FUN)]
    [(return) (token-RETURN)]
    [(int) (token-INT)]
    [(bool) (token-BOOL)]
    [(if) (token-IF)]
    [(while) (token-WHILE)]
    [(else) (token-ELSE)]
    [(true) (token-BOOL-LIT #t)]
    [(false) (token-BOOL-LIT #f)]
    [(new) (token-NEW)]
    [else (token-ID str)]))

;; strip the opening and closing parens, eliminate backslashes
;; before double-quotes.
(define (string-lit-cleanup str)
  (regexp-replace*
   "\\\\n"
   (regexp-replace* "\\\\\""
                    (substring str 1 (- (string-length str) 1))
                    "\"")
   "\n"))

;; PARSER (turns a stream of tokens into a tree)

;; the parser for the consieuten language
(define consieuten-parser
  (parser
   (precs
    (left OR)
    (left AND)
    (left EQUALS NOT-EQUALS)
    (left GT GEQ LT LEQ)
    (left PLUS MINUS)
    (left TIMES DIVIDE))

   (grammar
    [prog
     [(functions) $1]
     ]
    [functions
     [() '()]
     [(function functions) (cons $1 $2)]]
    [function
     [(FUN ID LPAREN fun-args RPAREN type LBRACK vardecls
           functions stmts RBRACK)
      (list 'function (string->symbol $2)
            $4 $6 $8 $9 $10)]]
    [fun-args
     [() '()]
     [(ty-id fun-args-kont) (cons $1 $2)]]
    [fun-args-kont
     [() '()]
     [(COMMA ty-id fun-args-kont) (cons $2 $3)]]
    [ty-id
     [(type ID) (list (string->symbol $2) $1)]]

    [type
     [(INT) 'int]
     [(BOOL) 'bool]
     [(LPAREN types ARROW type RPAREN) (list '-> $2 $4)]]
    [types
     [() '()]
     [(type types) (cons $1 $2)]]
    
    [vardecls
     [() '()]
     [(vardecl vardecls) (cons $1 $2)]]
    [vardecl
     [(type ID comma-ids SEMICOLON) (list 'vardecl $1
                                          (cons (string->symbol $2)
                                                $3))]]
    [comma-ids
     [() '()]
     [(COMMA ID comma-ids) (cons (string->symbol $2) $3)]]

    [stmts
     [() '()]
     [(stmt stmts) (cons $1 $2)]]

    [stmt
     [(lvalue GETS expr SEMICOLON) (list 'gets $1 $3)]
     [(ID LPAREN call-args RPAREN SEMICOLON)
      (list 'call (list 'var (string->symbol $1)) $3)]
     [(IF LPAREN expr RPAREN block)
      (list 'if $3 $5)]
     [(IF LPAREN expr RPAREN block ELSE block)
      (list 'if-else $3 $5 $7)]
     [(block) (list 'block $1)]
     [(RETURN expr SEMICOLON) (list 'return-expr $2)]
     [(RETURN SEMICOLON) (list 'return-void)]]

    [block
     [(LBRACK stmts RBRACK) $2]]

    [lvalue
     [(ID) (list 'lvvar (string->symbol $1))]]
    [expr
     [(ID) (list 'var (string->symbol $1))]
     [(ID LPAREN call-args RPAREN)
      (list 'call
            (list 'var (string->symbol $1))
            $3)]
     [(INTLIT) $1]
     [(expr PLUS expr)   (list 'op '+ $1 $3)]
     [(expr TIMES expr)  (list 'op '* $1 $3)]
     [(expr MINUS expr)  (list 'op '- $1 $3)]
     [(expr DIVIDE expr) (list 'op '/ $1 $3)]

     [(expr LEQ expr) (list 'op '<= $1 $3)]
     [(expr LT expr)  (list 'op '< $1 $3)]
     [(expr GEQ expr) (list 'op '>= $1 $3)]
     [(expr GT expr)  (list 'op '> $1 $3)]

     [(expr EQUALS expr)     (list 'op 'eq $1 $3)]
     [(expr NOT-EQUALS expr) (list 'op 'neq $1 $3)]

     [(MINUS expr) (list 'unop '- $2)]

     [(expr AND expr) (list 'op 'and $1 $3)]
     [(expr OR expr)  (list 'op 'or $1 $3)]

     
     
     [(LPAREN expr RPAREN) $2]]

    [call-args
     [() '()]
     [(expr call-args-kont) (cons $1 $2)]]
    [call-args-kont
     [() '()]
     [(COMMA expr call-args-kont) (cons $2 $3)]]
    
    )
   (tokens delimiters special-operators keywords regular)
   (start prog)
   (end EOF)
   (src-pos)
   (error (lambda (tok-ok? tok-name tok-value start-pos end-pos)
            (error 'parser "problem parsing at token ~a, starting at position ~a"
                   (list tok-name tok-value)
                   (position-offset start-pos))
            #;(error 'parser "problem parsing with args: ~a" 
                   (list tok-ok? tok-name tok-value 
                         (position-offset start-pos)
                         (position-line start-pos)
                         (position-col start-pos)
                         (position-line end-pos)
                         (position-col end-pos)))))
   #;(debug "/tmp/lalr-table.txt")))


;; TESTS

;; for testing purposes, turn a string into a list of tokens
;; (not used by the actual parser)
(define (string->tokens string)
  (let ([input-port (open-input-string string)])
    (let loop ()
      (let ([next-token (position-token-token
                         (consieuten-lexer input-port))])
        (if (equal? next-token (token-EOF))
            null
            (cons next-token (loop)))))))

(module+ test
  (require rackunit
           rackunit/text-ui
           racket/runtime-path)

  (define-runtime-path here ".")

  (define test-file-string
    "fun abc (int x, (int -> int) y,
         (-> (-> int)) oeu) (bool -> bool) {
  main();
}

fun main () int {
  int a,b  , c, d;
  int g, h;
  fun i1() bool {
    if (x < 14 && z > (-y) + 444) {
      {c = 12;
       a(4);}
      d = c+1;
    } else {
      if (y + 9 > 2) {
        return 9;
      }
      d = d*423;
    }
    return c+d;
  }
  fun b() (int -> int) {
    return b(4);
  }
  return i1(b);
}
")

  (define-test-suite the-test-suite
  
  ;; scanner tests
  (and
   (check-equal? (string-lit-cleanup "\"ab\n\\\\\"\"") 
                 #<<|
ab
\"
|
                 )
   
   (check-equal?
    (position-token-token (consieuten-lexer (open-input-string "")))
    (token-EOF))
   

   (check-equal? (string->tokens " 2322 ")
                 (list (token-INTLIT 2322)))
   (check-equal? (string->tokens " 2 ")
                 (list (token-INTLIT 2)))
   (check-equal? (string->tokens "0")
                 (list (token-INTLIT 0)))
   ;; this is weird...
   (check-equal? (string->tokens "00abc")
                 (list (token-INTLIT 0)
                       (token-INTLIT 0)
                       (token-ID "abc")))

   (check-equal? (string->tokens "fun main() int {
  int x, z, oth1;
  y=34;
  return y+(k*4);
}")
                 (list (token-FUN) (token-ID "main") (token-LPAREN)
                       (token-RPAREN) (token-INT) (token-LBRACK)
                       (token-INT) (token-ID "x") (token-COMMA)
                       (token-ID "z") (token-COMMA) (token-ID "oth1")
                       (token-SEMICOLON) (token-ID "y") (token-GETS)
                       (token-INTLIT 34) (token-SEMICOLON) (token-RETURN)
                       (token-ID "y") (token-PLUS) (token-LPAREN)
                       (token-ID "k") (token-TIMES) (token-INTLIT 4)
                       (token-RPAREN) (token-SEMICOLON) (token-RBRACK)))

   
   ;; REGRESSION TEST ONLY:
   (check-equal?
    (string->tokens test-file-string)
    (list  'FUN  (token-ID "abc")  'LPAREN  'INT  (token-ID "x")
           'COMMA  'LPAREN  'INT  'ARROW  'INT  'RPAREN
           (token-ID "y")  'COMMA  'LPAREN  'ARROW  'LPAREN  'ARROW
           'INT  'RPAREN  'RPAREN  (token-ID "oeu")  'RPAREN
           'LPAREN  'BOOL  'ARROW  'BOOL  'RPAREN  'LBRACK
           (token-ID "main")  'LPAREN  'RPAREN  'SEMICOLON  'RBRACK
           'FUN  (token-ID "main")  'LPAREN  'RPAREN  'INT  'LBRACK
           'INT  (token-ID "a")  'COMMA  (token-ID "b")  'COMMA
           (token-ID "c")  'COMMA  (token-ID "d")  'SEMICOLON  'INT
           (token-ID "g")  'COMMA  (token-ID "h")  'SEMICOLON  'FUN
           (token-ID "i1")  'LPAREN  'RPAREN  'BOOL  'LBRACK  'IF
           'LPAREN  (token-ID "x")  'LT  (token-INTLIT 14)  'AND
           (token-ID "z")  'GT  'LPAREN  'MINUS  (token-ID "y")
           'RPAREN  'PLUS  (token-INTLIT 444)  'RPAREN  'LBRACK
           'LBRACK  (token-ID "c")  'GETS  (token-INTLIT 12)
           'SEMICOLON  (token-ID "a")  'LPAREN  (token-INTLIT 4)
           'RPAREN  'SEMICOLON  'RBRACK  (token-ID "d")  'GETS
           (token-ID "c")  'PLUS  (token-INTLIT 1)  'SEMICOLON
           'RBRACK  'ELSE  'LBRACK  'IF  'LPAREN  (token-ID "y")
           'PLUS  (token-INTLIT 9)  'GT  (token-INTLIT 2)  'RPAREN
           'LBRACK  'RETURN  (token-INTLIT 9)  'SEMICOLON  'RBRACK
           (token-ID "d")  'GETS  (token-ID "d")  'TIMES
           (token-INTLIT 423)  'SEMICOLON  'RBRACK  'RETURN
           (token-ID "c")  'PLUS  (token-ID "d")  'SEMICOLON
           'RBRACK  'FUN  (token-ID "b")  'LPAREN  'RPAREN  'LPAREN
           'INT  'ARROW  'INT  'RPAREN  'LBRACK  'RETURN  (token-ID "b")
           'LPAREN  (token-INTLIT 4)  'RPAREN  'SEMICOLON  'RBRACK
           'RETURN  (token-ID "i1")  'LPAREN  (token-ID "b")
           'RPAREN  'SEMICOLON  'RBRACK)))
  
  (check-equal?
   (string->tree "fun main() int {
  int x, z, oth1;
  y=34;
  return y+(k*4);
}")
   '((function main () int
               ((vardecl int (x z oth1)))
               ()
               ((gets (lvvar y) 34)
                (return-expr (op + (var y) (op * (var k) 4)))))))

    (check-equal?
     (string->tree "fun main() int {
  return 3 / 4;
}")
     '((function main () int () ()
                 ((return-expr (op / 3 4))))))

    (check-equal?
     (string->tree test-file-string)
     '((function abc ((x int) (y (-> (int) int))
                              (oeu (-> () (-> () int))))
                 (-> (bool) bool)
                 () ()
                 ((call (var main) ())))
       (function main () int
                 ((vardecl int (a b c d))
                  (vardecl int (g h)))
                 ((function i1 () bool () ()
                            ((if-else
                              (op and (op < (var x) 14)
                                  (op > (var z)
                                      (op + (unop - (var y))
                                          444)))
                              ((block ((gets (lvvar c) 12)
                                       (call (var a) (4))))
                               (gets (lvvar d) (op + (var c) 1)))
                              ((if (op > (op + (var y) 9)
                                       2)
                                   ((return-expr 9)))
                               (gets (lvvar d) (op * (var d) 423))))
                             (return-expr (op + (var c) (var d)))))
                  (function b () (-> (int) int) () ()
                            ((return-expr (call (var b) (4))))))
                 ((return-expr (call (var i1) ((var b)))))))))

  (run-tests the-test-suite))


