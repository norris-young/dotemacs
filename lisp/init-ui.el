;; Inhibit resizing frame
(setq frame-inhibit-implied-resize t
      frame-resize-pixelwise t)

(set-frame-font
 (font-spec :name "Sarasa Mono SC"
	    :size 14.0
	    :width 'normal
	    :weight 'normal))

(use-package color-theme-sanityinc-tomorrow
  :config
  (color-theme-sanityinc-tomorrow-eighties))
