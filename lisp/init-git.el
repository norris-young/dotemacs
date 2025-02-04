;;; ...  -*- lexical-binding: t -*-

(use-package transient :load-path "packages/transient/lisp")
(use-package magit
  :bind (:map
         my-git-map
         ("s" . magit-status)
         ("b" . magit-blame-addition)
         ("q" . magit-blame-quit))
  :custom (magit-diff-refine-hunk 'all)
  :hook (magit-blame-read-only-mode-hook . magit-motion)
  :config
  (transient-replace-suffix 'magit-log 'magit-log:--since
    '(magit-log:--since :init-value (lambda (obj) (oset obj value "1.year"))))

  (advice-add 'git-commit-turn-on-auto-fill :before
              (lambda ()
                (setq fill-column 72)))
  )

(provide 'init-git)
