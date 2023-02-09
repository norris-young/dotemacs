(use-package pixel-scroll
  :custom (pixel-scroll-precision-large-scroll-height 40.0)
  :hook (after-init . pixel-scroll-precision-mode))

(use-package frame
  :config
  (set-frame-font (font-spec :name "JetBrainsMono Nerd Font"
                             :size 14.0
                             :width 'normal
                             :weight 'normal))
  (cl-dolist (face '(variable-pitch fixed-pitch fixed-pitch-serif))
    (set-face-font face (font-spec :name "JetBrainsMono Nerd Font"
                                   :size 14.0
                                   :width 'normal
                                   :weight 'normal))))

(use-package color-theme-sanityinc-tomorrow
  :hook (after-init . color-theme-sanityinc-tomorrow-eighties))

;; This minor mode cannot be the first function in hook, so move it here for fix bug
;; @see https://github.com/DarthFennec/highlight-indent-guides/issues/15#issuecomment-300233767
;; (use-package highlight-indent-guides
;;   :config
;;   (setq highlight-indent-guides-method 'column))
;; (add-hook 'prog-mode-hook #'highlight-indent-guides-mode)

(use-package whitespace
  :custom (whitespace-style '(face trailing tabs tab-mark))
  :hook ((prog-mode . whitespace-mode)
         (prog-mode . display-fill-column-indicator-mode)
         (prog-mode . display-line-numbers-mode))
  :config
  (setq-default fill-column 80))

(use-package hl-line
  :hook (after-init . global-hl-line-mode))

(provide 'init-ui)
