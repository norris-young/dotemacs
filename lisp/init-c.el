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

(provide 'init-c)
