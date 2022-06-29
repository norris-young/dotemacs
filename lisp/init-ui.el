;; Inhibit resizing frame
(setq frame-inhibit-implied-resize t
      frame-resize-pixelwise t)

(set-frame-font
 (font-spec :name "Sarasa Mono SC"
            :size 14.0
            :width 'normal
            :weight 'normal))

(use-package color-theme-sanityinc-tomorrow
  :hook (after-init . color-theme-sanityinc-tomorrow-eighties))

(with-eval-after-load 'whitespace
  (setq whitespace-style '(face trailing tabs tab-mark)))
(add-hook 'prog-mode-hook #'whitespace-mode)
(add-hook 'prog-mode-hook #'display-fill-column-indicator-mode)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

(use-package hl-line
  :hook ((after-init . global-hl-line-mode)))
