(setq-default tab-width 4)
(use-package cc-mode
  :bind ("M-;" . my-comment-dwim)
  :hook (c-mode . my-choose-c-style)
  :config
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

(use-package c-ts-mode
  :hook (c-ts-mode . my-choose-c-ts-style)
  :config
  (eval-when-compile (require 'c-ts-mode))
  (setq-default c-ts-mode-indent-style 'linux)
  (defun my-choose-c-ts-style ()
    (if (string-match "linux" (buffer-file-name))
        (setq-local c-ts-mode-indent-offset 8
              tab-width 8
              indent-tabs-mode t)
      (setq-local c-ts-mode-indent-offset 4
            tab-width 4
            indent-tabs-mode nil)))

  (defun tweak-linux-style (style)
    (let ((name (car style))
          (rules (cdr style)))
      (if (eq name 'linux)
          (setcdr style `(;; Opening bracket.
                          ((node-is "compound_statement") standalone-parent 0)
                          ((node-is "}") standalone-parent 0)
                          ,@rules)))))

  (advice-add #'c-ts-mode--indent-styles :around
              (lambda (fn mode)
                (let ((styles (funcall fn mode)))
                  (mapc #'tweak-linux-style styles)
                  styles)))
  )

(use-package gdb-mi
  :hook (gdb-many-windows-hook . tool-bar-mode)
  :custom
  (gdb-debuginfod-enable-setting nil)
  :config
  (setq gdb-many-windows t)
  )

(use-package citre
  :autoload citre-global-dbpath
  :bind (:map
         my-function-map
         ("p" . citre-peek)
         ("P" . citre-peek-reference)
         ("D" . citre-jump)
         ("R" . citre-jump-to-reference)
         ("u" . citre-global-update-database)
         ("C" . citre-global-create-database))
  :hook
  (find-file . (lambda ()
                 (if (not (file-exists-p (buffer-file-name)))
                     (setq-local citre-new-file t)
                   (setq-local citre-new-file nil))))
  (after-save . (lambda ()
                  (when (and (eq major-mode 'c-ts-mode)
                             (not citre-new-file)
                             (citre-global-dbpath))
                    (citre-global-update-file))))
  :config
  (with-eval-after-load 'cc-mode (require 'citre-lang-c))
  (with-eval-after-load 'dired (require 'citre-lang-fileref))
  (with-eval-after-load 'verilog-mode (require 'citre-lang-verilog))
  )

(use-package cmake-ts-mode
  :custom (cmake-ts-mode-indent-offset 4))

(provide 'init-c)
