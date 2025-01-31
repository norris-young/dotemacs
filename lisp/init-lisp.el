;;; ...  -*- lexical-binding: t -*-

(setq-default initial-scratch-message
              (concat ";; Hello, " user-login-name " - Emacs ♥ you!\n\n"))

(use-package help-fns+ :defer 1)

(use-package edebug
  :bind (:map
         edebug-mode-map
         ("A" . #'my-elisp-add-to-watch)))

(use-package edebug-x
  :hook (edebug-mode . edebug-x-mode))

(provide 'init-lisp)
