(use-package yasnippet
  :config
  (yas-global-mode 1))

(use-package lsp-bridge
  :config
  (global-lsp-bridge-mode)
  (setq lsp-bridge-c-lsp-server "ccls"))

(provide 'init-lsp)
