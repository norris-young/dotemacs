(setq indent-tabs-mode nil)
(save-place-mode 1)

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

(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(with-eval-after-load 'whitespace
  (setq whitespace-style '(face trailing tabs tab-mark)))
(add-hook 'prog-mode-hook #'display-fill-column-indicator-mode)
(add-hook 'prog-mode-hook #'whitespace-mode)

(use-package hl-line
  :hook ((after-init . global-hl-line-mode)))
