(defun my-elisp-find-function-or-variable-at-point ()
  (interactive)
  (let ((symb (symbol-at-point)))
    (if (and symb
             (not (equal symb 0))
             (not (fboundp symb)))
        (find-variable-other-window symb)
      (find-function-other-window symb))))

(global-set-key (kbd "C-t") (make-sparse-keymap))
(global-set-key (kbd "C-t C-l") #'my-elisp-find-function-or-variable-at-point)
