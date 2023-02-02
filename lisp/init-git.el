(use-package magit
  :config
  (put 'magit-log-mode 'magit-log-default-arguments
       '("--graph" "-n256" "--decorate" "--since=1.year"))
  (setq magit-display-buffer-function #'magit-display-buffer-traditional))

(provide 'init-git)
