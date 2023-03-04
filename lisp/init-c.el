(use-package cc-mode
  :bind ("M-;" . my-comment-dwim)
  :hook ((gdb-many-windows-hook . tool-bar-mode)
         (c-mode . my-choose-c-style))
  :config
  (setq-default tab-width 4)
  (setq gdb-many-windows t)

  (c-add-style "linux-user" '("linux"
                              (c-basic-offset . 4)
                              (tab-width . 4)
                              (indent-tabs-mode . nil)))
  (c-add-style "linux-kernel" '("linux"
                                (c-basic-offset . 8)
                                (tab-width . 8)
                                (indent-tabs-mode . t)))
  (defun my-choose-c-style ()
    (if (string-match "linux" (buffer-file-name))
        (c-set-style "linux-kernel")
      (c-set-style "linux-user")))

  (defun my-comment-dwim ()
    (interactive)
    (let ((lines (if (use-region-p)
                     (count-lines (region-beginning) (region-end))
                   1)))
      (if (eq lines 1)
          (setq comment-style 'indent)
        (setq comment-style 'extra-line))
      (if (and (use-region-p)
               (eq lines 1))
          (progn
            (comment-or-uncomment-region (region-beginning) (region-end)))
        (comment-line nil))))
  )

(use-package citre
  :bind (:map my-function-map
         ("p" . citre-peek)
         ("R" . citre-peek-reference)
         ("u" . citre-global-update-database)
         ("C" . citre-global-create-database))
  :hook (prog-mode . citre-auto-enable-citre-mode)
  :custom
  (citre-enable-imenu-integration nil)
  ;; (citre-tags-in-buffer-backends '(global))
  ;; (citre-tags-imenu-create-tags-file-threshold nil)
  (citre-auto-enable-citre-mode-modes '(prog-mode))
  (citre-use-project-root-when-creating-tags t)
  (citre-gtags-args '("--compact"))
  :config
  (with-eval-after-load 'cc-mode (require 'citre-lang-c))
  (with-eval-after-load 'dired (require 'citre-lang-fileref))
  (with-eval-after-load 'verilog-mode (require 'citre-lang-verilog)))

(provide 'init-c)
