(use-package winum
  :custom-face (winum-face ((nil (:foregound "DeepPink") (:underline "DeepPink") (:weight 'bold))))
  :hook (after-init . winum-mode))

;; window management
(use-package window
  :bind (("M-j" . scroll-up-line)
         ("M-k" . scroll-down-line)
         :map my-window-map
         ("-" . split-window-below)
         ("/" . split-window-right)
         ("m" . delete-other-windows)
         ("d" . delete-window))
  :config
  (defun switch-to-minibuffer ()
    "Switch to minibuffer window."
    (interactive)
    (if (active-minibuffer-window)
        (select-window (active-minibuffer-window))))

  ;;scroll configuration
  (setq-default scroll-up-aggressively 0.1
                scroll-down-aggressively 0.1)
  (setq scroll-preserve-screen-position t
        scroll-margin 3
        scroll-step 1)

  (advice-add #'split-window-below :after #'windmove-down)
  (advice-add #'split-window-right :after #'windmove-right)
  (advice-add #'scroll-up-command :around (lambda (old &optional x)
                                            (if (not x)
                                                (funcall old 20)
                                              (funcall old x))))
  (advice-add #'scroll-down-command :around (lambda (old &optional x)
                                              (if (not x)
                                                  (funcall old 20)
                                                (funcall old x))))
  )

(use-package shackle
  :custom
  (shackle-select-reused-windows nil)
  (shackle-inhibit-window-quit-on-same-windows t)
  (shackle-default-alignment 'below)
  (shackle-default-size 0.3)
  (shackle-rules '(("*Help*" :select t :align t)))
  (shackle-default-rule '(:select t))
  :hook (after-init . shackle-mode))

(provide 'init-window)
