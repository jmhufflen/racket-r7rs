#lang racket/base

; This implementation of cond-expand works, but it doesn't actually support any "feature" identifiers.
; Eventually, some of them should be added.

(require (for-syntax racket/base
                     racket/function
                     syntax/parse)
         (prefix-in 6: rnrs/base-6)
         "import.rkt")

(provide cond-expand features)

(define (features)
  (6:list))

(begin-for-syntax
  (define (module-exists? path)
    (with-handlers ([exn:missing-module? (const #f)])
      (dynamic-require path #f)
      #t))

  (define-syntax-class ce-requirement
    #:literals (6:and 6:or 6:not 6:else)
    #:datum-literals (library)
    #:attributes (true?)
    (pattern (6:and req:ce-requirement ...)
             #:attr true? (andmap values (attribute req.true?)))
    (pattern (6:or req:ce-requirement ...)
             #:attr true? (ormap values (attribute req.true?)))
    (pattern (6:not req:ce-requirement)
             #:attr true? (not (attribute req.true?)))
    (pattern (library name:library-name)
             #:attr true? (module-exists? (syntax->datum #'name.module-path)))
    (pattern 6:else #:attr true? #t)
    (pattern _:id #:attr true? #f)))

(define-syntax cond-expand
  (syntax-parser
    [(_ [req:ce-requirement . body] ...+)
     (or (for/or ([true? (in-list (attribute req.true?))]
                  [body (in-list (attribute body))])
           (and true? #`(begin . #,body)))
         #'(begin))]))

(module+ test
  (require rackunit)

  (check-true
   (cond-expand [(library (racket base)) #t]
                [6:else #f]))
  (check-false
   (cond-expand [(library (some really long module that should never exist)) #t]
                [6:else #f])))