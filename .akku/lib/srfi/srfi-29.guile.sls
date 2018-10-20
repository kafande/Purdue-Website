#!r6rs ;; Copyright notices may be found in "%3a29/localization.sls"
;; This file was written by Akku.scm
(library (srfi srfi-29)
  (export current-language current-country current-locale-details
    declare-bundle! store-bundle store-bundle! load-bundle!
    localized-template)
  (import (rnrs) (srfi :6))
  (define (current-locale-details . args)
    (error 'current-locale-details
      "procedure not supplied by reference implementation"))
  (define-syntax store-bundle
    (identifier-syntax store-bundle!))
  (define *localization-bundles* '())
  (define current-language
    (let ([current-language-value 'en])
      (lambda args
        (if (null? args)
            current-language-value
            (set! current-language-value (car args))))))
  (define current-country
    (let ([current-country-value 'us])
      (lambda args
        (if (null? args)
            current-country-value
            (set! current-country-value (car args))))))
  (define load-bundle! (lambda (bundle-specifier) #f))
  (define store-bundle! (lambda (bundle-specifier) #f))
  (define declare-bundle!
    (letrec ([remove-old-bundle (lambda (specifier bundle)
                                  (cond
                                    [(null? bundle) '()]
                                    [(equal? (caar bundle) specifier)
                                     (cdr bundle)]
                                    [else
                                     (cons
                                       (car bundle)
                                       (remove-old-bundle
                                         specifier
                                         (cdr bundle)))]))])
      (lambda (bundle-specifier bundle-assoc-list)
        (set! *localization-bundles*
          (cons
            (cons bundle-specifier bundle-assoc-list)
            (remove-old-bundle
              bundle-specifier
              *localization-bundles*))))))
  (define localized-template
    (letrec ([rdc (lambda (ls)
                    (if (null? (cdr ls))
                        '()
                        (cons (car ls) (rdc (cdr ls)))))]
             [find-bundle (lambda (specifier template-name)
                            (cond
                              [(assoc specifier *localization-bundles*) =>
                               (lambda (bundle) bundle)]
                              [(null? specifier) #f]
                              [else
                               (find-bundle
                                 (rdc specifier)
                                 template-name)]))])
      (lambda (package-name template-name)
        (let loop ([specifier (cons
                                package-name
                                (list
                                  (current-language)
                                  (current-country)))])
          (and (not (null? specifier))
               (let ([bundle (find-bundle specifier template-name)])
                 (and bundle
                      (cond
                        [(assq template-name bundle) => cdr]
                        [(null? (cdr specifier)) #f]
                        [else (loop (rdc specifier))]))))))))
  (define format
    (lambda (format-string . objects)
      (let ([buffer (open-output-string)])
        (let loop ([format-list (string->list format-string)]
                   [objects objects]
                   [object-override #f])
          (cond
            [(null? format-list) (get-output-string buffer)]
            [(char=? (car format-list) #\~)
             (cond
               [(null? (cdr format-list))
                (error 'format "Incomplete escape sequence")]
               [(char-numeric? (cadr format-list))
                (let posloop ([fl (cddr format-list)]
                              [pos (string->number
                                     (string (cadr format-list)))])
                  (cond
                    [(null? fl)
                     (error 'format "Incomplete escape sequence")]
                    [(and (eq? (car fl) '#\@) (null? (cdr fl)))
                     (error 'format "Incomplete escape sequence")]
                    [(and (eq? (car fl) '#\@) (eq? (cadr fl) '#\*))
                     (loop (cddr fl) objects (list-ref objects pos))]
                    [else
                     (posloop
                       (cdr fl)
                       (+ (* 10 pos)
                          (string->number (string (car fl)))))]))]
               [else
                (case (cadr format-list)
                  [(#\a)
                   (cond
                     [object-override
                      (begin
                        (display object-override buffer)
                        (loop (cddr format-list) objects #f))]
                     [(null? objects)
                      (error 'format "No value for escape sequence")]
                     [else
                      (begin
                        (display (car objects) buffer)
                        (loop (cddr format-list) (cdr objects) #f))])]
                  [(#\s)
                   (cond
                     [object-override
                      (begin
                        (display object-override buffer)
                        (loop (cddr format-list) objects #f))]
                     [(null? objects)
                      (error 'format "No value for escape sequence")]
                     [else
                      (begin
                        (write (car objects) buffer)
                        (loop (cddr format-list) (cdr objects) #f))])]
                  [(#\%)
                   (if object-override
                       (error 'format
                         "Escape sequence following positional override does not require a value"))
                   (display #\newline buffer)
                   (loop (cddr format-list) objects #f)]
                  [(#\~)
                   (if object-override
                       (error 'format
                         "Escape sequence following positional override does not require a value"))
                   (display #\~ buffer)
                   (loop (cddr format-list) objects #f)]
                  [else (error 'format "Unrecognized escape sequence")])])]
            [else
             (display (car format-list) buffer)
             (loop (cdr format-list) objects #f)]))))))
