(use-package magit
  :bind (:map my-git-map
        ("s" . magit-status)
        ("b" . magit-blame-addition)
        ("q" . magit-blame-quit))
  :config
  (transient-replace-suffix 'magit-log 'magit-log:--since
    '(magit-log:--since :init-value (lambda (obj) (oset obj value "1.year"))))
  )

(provide 'init-git)
