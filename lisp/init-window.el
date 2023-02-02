(use-package winum
  :config
  (set-face-attribute 'winum-face nil :foreground "DeepPink" :underline "DeepPink" :weight 'bold)
  (winum-mode 1))

;; window management
(defadvice split-window-below (after move-after-split-below activate compile)
  (windmove-down))
(defadvice split-window-right (after move-after-split-right activate compile)
  (windmove-right))
;; rebind kill-region to C-S-k, meanwhile meow--kbd-kill-region needs to be changed.
(global-set-key (kbd "C-S-k") #'kill-region)
(global-set-key (kbd "C-w") (make-sparse-keymap))
(global-set-key (kbd "C-w m") #'delete-other-windows)
(global-set-key (kbd "C-w C-d") #'delete-window)
(global-set-key (kbd "C-w C--") #'split-window-below)
(global-set-key (kbd "C-w C-/") #'split-window-right)

(use-package shackle
  :custom
  (shackle-select-reused-windows nil)
  (shackle-inhibit-window-quit-on-same-windows t)
  (shackle-default-alignment 'below)
  (shackle-default-size 0.3)
  (shackle-rules '(("*Help*" :select t :align t)))
  (shackle-default-rule '(:select t))
  :hook ((after-init . shackle-mode)))

(provide 'init-window)
