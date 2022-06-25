;; Inhibit resizing frame
(setq frame-inhibit-implied-resize t
      frame-resize-pixelwise t)

(unless (eq (frame-parameter nil 'fullscreen) 'maximized)
  (set-frame-parameter nil 'fullscreen 'maximized)
  (set-frame-parameter nil 'left 0)
  (set-frame-parameter nil 'top 0))

(set-frame-font
 (font-spec :name "Sarasa Mono SC"
	    :size 14.0
	    :width 'normal
	    :weight 'normal))

(use-package color-theme-sanityinc-tomorrow
  :ensure t
  :config
  (color-theme-sanityinc-tomorrow-eighties))
