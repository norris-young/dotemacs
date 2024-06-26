(use-package transient :load-path "packages/transient/lisp")
(use-package magit
  :bind (:map
         my-git-map
         ("s" . magit-status)
         ("b" . magit-blame-addition)
         ("q" . magit-blame-quit))
  :custom (magit-diff-refine-hunk 'all)
  :config
  (eval-when-compile (require 'magit))
  (transient-replace-suffix 'magit-log 'magit-log:--since
    '(magit-log:--since :init-value (lambda (obj) (oset obj value "1.year"))))

  ;; Change to motion mode for magit-blame
  (with-eval-after-load 'meow
    (defun magit-motion ()
      (if magit-blame-read-only-mode
          (progn
            (meow-mode -1)
            (meow-motion-mode 1))
        (meow-mode 1)))
    (add-hook 'magit-blame-read-only-mode-hook #'magit-motion))

  (advice-add  'git-commit-turn-on-auto-fill
               :before
               (lambda ()
                 (setq fill-column 72)))
  )

(provide 'init-git)
