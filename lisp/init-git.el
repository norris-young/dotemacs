(use-package magit
  :bind (:map my-git-map
        ("s" . magit-status)
        ("b" . magit-blame-addition)
        ("q" . magit-blame-quit))
  :custom
  (magit-display-buffer-function 'magit-display-buffer-fullframe-status-v1))

(provide 'init-git)
