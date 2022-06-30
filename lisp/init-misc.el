;; Do not insert tab and save file place by default
(add-hook 'after-init-hook (lambda ()
                             (setq-default indent-tabs-mode nil)
                             (setq-default save-place-mode t)))

;;scroll configuration
(setq scroll-up-aggressively 0.1
      scroll-down-aggressively 0.1
      scroll-preserve-screen-position t
      scroll-margin 3
      scroll-step 1)

(defadvice scroll-up-command (before scroll-up-less-line activate compile)
  (if (not arg) (setq arg 15)))
(defadvice scroll-down-command (before scroll-down-less-line activate compile)
  (if (not arg) (setq arg 15)))

(global-set-key (kbd "M-k") #'scroll-down-line)
(global-set-key (kbd "M-j") #'scroll-up-line)
(global-set-key (kbd "C-M-j") #'join-line)

(add-hook 'before-save-hook #'delete-trailing-whitespace)

(use-package smartparens
  :bind (("M--" . sp-unwrap-sexp)
         ("M-[" . sp-backward-slurp-sexp)
         ("M-]" . sp-forward-slurp-sexp)
         ("M-{" . sp-backward-barf-sexp)
         ("M-}" . sp-forward-barf-sexp))
  :hook ((after-init . (lambda ()
                         (require 'smartparens-config)
                         (show-smartparens-global-mode)
                         (smartparens-global-mode))))
  :config
  (defun my-wrap-with-pair (c)
    (interactive "c")
    (let ((active-pair (char-to-string c)))
      (cl-dolist (pair sp-pair-list)
         (if (or (equal (car pair) active-pair)
                 (equal (cdr pair) active-pair))
             (progn
               (sp-wrap-with-pair (car pair))
               (cl-return))))))
  )

(use-package evil-matchit
  :config
  (global-set-key (kbd "%") 'evilmi-jump-items-native))
