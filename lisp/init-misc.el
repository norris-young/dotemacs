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


