#!r6rs ;; Copyright notices may be found in "%3a41/streams.sls"
;; This file was written by Akku.scm
(library (srfi srfi-41)
  (export stream-null stream-cons stream? stream-null?
   stream-pair? stream-car stream-cdr stream-lambda
   define-stream list->stream port->stream stream stream->list
   stream-append stream-concat stream-constant stream-drop
   stream-drop-while stream-filter stream-fold stream-for-each
   stream-from stream-iterate stream-length stream-let
   stream-map stream-match stream-of stream-range stream-ref
   stream-reverse stream-scan stream-take stream-take-while
   stream-unfold stream-unfolds stream-zip)
  (import
    (srfi :41 streams primitive)
    (srfi :41 streams derived)))
