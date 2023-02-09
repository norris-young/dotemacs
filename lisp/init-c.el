(use-package cc-mode
  :config
  (c-add-style "linux-user" '("linux"
                              (c-basic-offset . 4)
                              (tab-width . 4)
                              (indent-tabs-mode . nil)))
  (c-add-style "linux-kernel" '("linux"
                                (c-basic-offset . 8)
                                (tab-width . 8)
                                (indent-tabs-mode . t)))
  (setq-default fill-column 80
                tab-width 4)
  (add-hook 'c-mode-hook
            (lambda ()
              (if (string-match "linux" (buffer-file-name))
                  (c-set-style "linux-kernel")
                (c-set-style "linux-user")))))
(use-package citre
  :commands (citre-update-tags-file citre-update-this-tags-file citre-edit-tags-file-recipe citre-create-tags-file citre-global-create-database citre-global-update-database)
  :hook (prog-mode . citre-auto-enable-citre-mode)
  :custom
  (citre-auto-enable-citre-mode-modes '(prog-mode))
  (citre-use-project-root-when-creating-tags t)
  (citre-gtags-args '("--compact"))
  :config
  (with-eval-after-load 'cc-mode (require 'citre-lang-c))
  (with-eval-after-load 'dired (require 'citre-lang-fileref))
  (with-eval-after-load 'verilog-mode (require 'citre-lang-verilog)))

(provide 'init-c)
