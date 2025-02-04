;;; ...  -*- lexical-binding: t -*-

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
  )

(use-package c-ts-mode
  :mode ("\\.cu\\'" . c++-ts-mode)
  :hook ((c-ts-mode . my-choose-c-ts-style)
         (c-ts-mode . c-ts-mode-setup))
  :config
  (setq-default c-ts-mode-indent-style 'linux)

  ;; (advice-add #'c-ts-mode--indent-styles :around
  ;;             (lambda (fn mode)
  ;;               (let ((styles (funcall fn mode)))
  ;;                 (mapc #'tweak-linux-style styles)
  ;;                 styles)))
  )

(use-package gdb-mi
  :hook (gdb-many-windows . tool-bar-mode)
  :custom
  (gdb-debuginfod-enable-setting nil)
  :config
  (setq gdb-many-windows t)
  )

(use-package citre
  :autoload citre-global-dbpath
  ;; :init
  ;; (defvar citre-new-file nil)
  :bind (:map
         my-function-map
         ("p" . citre-peek)
         ("P" . citre-peek-reference)
         ("D" . citre-jump)
         ("R" . citre-jump-to-reference)
         ("u" . citre-global-update-database)
         ("C" . citre-global-create-database))
  ;; :hook
  ;; (find-file . (lambda ()
  ;;                (if (not (file-exists-p (buffer-file-name)))
  ;;                    (setq-local citre-new-file t))))
  ;; (after-save . (lambda ()
  ;;                 (when (and (eq major-mode 'c-ts-mode)
  ;;                            (not citre-new-file)
  ;;                            (citre-global-dbpath))
  ;;                   (citre-global-update-file))))
  :config
  (with-eval-after-load 'cc-mode (require 'citre-lang-c))
  (with-eval-after-load 'dired (require 'citre-lang-fileref))
  (with-eval-after-load 'verilog-mode (require 'citre-lang-verilog))
  )

(use-package cmake-ts-mode
  :custom (cmake-ts-mode-indent-offset 4))

(provide 'init-c)
