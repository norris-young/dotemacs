;;; ...  -*- lexical-binding: t -*-

;; (setq garbage-collection-messages t) ; for debug
;;;###autoload
(defun post-init-gc ()
  "Do the gc we deferred in early-init.el"
  (setq gc-cons-threshold (* 128 1024 1024)) ; 128M
  (setq gc-cons-percentage 0.1) ; original value
  (garbage-collect))
