;;; ...  -*- lexical-binding: t -*-

;;;###autoload
(defun my-choose-c-style ()
  (if (string-match "linux" (buffer-file-name))
      (c-set-style "linux-kernel")
    (c-set-style "linux-user")))

;;;###autoload
(defun my-comment-dwim ()
  (interactive)
  (let ((lines (if (use-region-p)
                   (count-lines (region-beginning) (region-end))
                 1)))
    (if (eq lines 1)
        (setq comment-style 'indent)
      (setq comment-style 'extra-line))
    (if (and (use-region-p)
             (eq lines 1))
        (progn
          (comment-or-uncomment-region (region-beginning) (region-end)))
      (comment-line nil))))

;;;###autoload
(defun my-choose-c-ts-style ()
  (if (string-match "linux" (buffer-file-name))
      (setq-local c-ts-mode-indent-offset 8
                  tab-width 8
                  indent-tabs-mode t)
    (setq-local c-ts-mode-indent-offset 4
                tab-width 4
                indent-tabs-mode nil)))

;; (defun tweak-linux-style (style)
;;   (let ((name (car style))
;;         (rules (cdr style)))
;;     (if (eq name 'linux)
;;         (setcdr style `(;; Opening bracket.
;;                         ((node-is "compound_statement") standalone-parent 0)
;;                         ((node-is "}") standalone-parent 0)
