;;; ...  -*- lexical-binding: t -*-

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

(use-package custom
  :custom (custom-safe-themes
           '("76ddb2e196c6ba8f380c23d169cf2c8f561fd2013ad54b987c516d3cabc00216"
             "b11edd2e0f97a0a7d5e66a9b82091b44431401ac394478beb44389cf54e6db28"
             "6bdc4e5f585bb4a500ea38f563ecf126570b9ab3be0598bdf607034bb07a8875"
             "04aa1c3ccaee1cc2b93b246c6fbcd597f7e6832a97aaeac7e5891e6863236f9f"
             "6fc9e40b4375d9d8d0d9521505849ab4d04220ed470db0b78b700230da0a86c1"
             default)))

(use-package color-theme-sanityinc-tomorrow
  :hook (after-init . color-theme-sanityinc-tomorrow-eighties)
  :config
  (advice-add #'color-theme-sanityinc-tomorrow :after
              (lambda (mode)
                (color-theme-sanityinc-tomorrow--with-colors mode
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

(use-package tab-bar
  :bind (:map tab-bar-mode-map
         ("C-<tab>" . nil)))

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
  :config
  (advice-add #'tab-bar-new-tab :after
              (lambda (&rest r)
                (let ((buf (current-buffer))
                      (tabspaces-remove-to-default nil))
                  (tabspaces-remove-buffer buf))))
  )

(provide 'init-ui)
