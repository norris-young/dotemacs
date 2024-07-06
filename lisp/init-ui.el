(use-package pixel-scroll
  :custom (pixel-scroll-precision-large-scroll-height 40.0)
  :hook (after-init . pixel-scroll-precision-mode))

;; (use-package frame
;;   :config
;;   (set-frame-font (font-spec :name "JetBrainsMono Nerd Font Mono"
;;                              :size 15.0
;;                              :width 'normal
;;                              :weight 'semi-bold))
;;   (cl-dolist (face '(variable-pitch fixed-pitch fixed-pitch-serif))
;;     (set-face-font face (font-spec :name "JetBrainsMono Nerd Font Mono"
;;                                    :size 14.0
;;                                    :width 'normal
;;                                    :weight 'semi-bold)))
;;   )

(use-package color-theme-sanityinc-tomorrow
  :hook (after-init . color-theme-sanityinc-tomorrow-eighties)
  :config
  (advice-add #'color-theme-sanityinc-tomorrow-eighties :after
              (lambda ()
                (color-theme-sanityinc-tomorrow--with-colors
                 'eighties
                 (set-face-attribute 'font-lock-bracket-face nil
                                     :foreground `,foreground)
                 (set-face-attribute 'font-lock-operator-face nil
                                     :foreground `,green)
                 (set-face-attribute 'font-lock-number-face nil
                                     :foreground `,blue)
                 (set-face-attribute 'font-lock-escape-face nil
                                     :foreground "#9370db")
                 (set-face-attribute 'font-lock-property-use-face nil
                                     :foreground "#9370db"
                                     :slant 'italic))))
  )

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

(use-package cnfonts
  :bind (("C--" . cnfonts-decrease-fontsize)
         ("C-=" . cnfonts-increase-fontsize))
  :custom
  (cnfonts-use-system-type t)
  (cnfonts-default-fontsize 15.0)
  (cnfonts-profiles '("default-fonts"))
  :hook (after-init . cnfonts-mode))

(use-package tabspaces
  :hook
  (after-init . tabspaces-mode) ;; use this only if you want the minor-mode loaded at startup.
  (tabspaces-mode . (lambda () (tab-rename "Home")))
  :commands (tabspaces-switch-or-create-workspace
             tabspaces-open-or-create-project-and-workspace)
  :custom
  (tabspaces-use-filtered-buffers-as-default t)
  (tabspaces-default-tab "Home")
  (tabspaces-remove-to-default t)
  (tabspaces-include-buffers '("*scratch*"))
  (tabspaces-initialize-project-with-todo nil)
  ;; sessions
  (tabspaces-session t)
  ;; (tabspaces-session-auto-restore t)
  )

(provide 'init-ui)
