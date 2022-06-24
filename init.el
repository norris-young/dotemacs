;; (setq garbage-collection-messages t) ; for debug
(defun post-init-gc ()
  "Do the gc we deferred in early-init.el"
  (setq gc-cons-threshold (* 16 1024 1024)) ; 16M
  (setq gc-cons-percentage 0.1) ; original value
  (garbage-collect))

(run-with-idle-timer 4 nil #'post-init-gc)
