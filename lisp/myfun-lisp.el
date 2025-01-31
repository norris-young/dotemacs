;;; ...  -*- lexical-binding: t -*-

(require 'edebug)
;; Simple watch window from emacswiki @https://www.emacswiki.org/emacs/SourceLevelDebugger
;;;###autoload
(defun my-elisp-add-to-watch (&optional region-start region-end)
  "Add the current variable to the *EDebug* window"
  (interactive "r")
  (let ((statement
         (if (and region-start region-end (use-region-p))
             (buffer-substring region-start region-end)
           (symbol-name (elisp--current-symbol)))))
    ;; open eval buffer
    (edebug-visit-eval-list)
    ;; jump to the end of it and add a newline
    (goto-char (point-max))
    (newline)
    ;; insert the variable
    (insert statement)
    ;; update the list
    (edebug-update-eval-list)
    ;; jump back to where we were
    (edebug-where)))
