(use-package winum
  :custom-face (winum-face ((nil (:foregound "DeepPink") (:underline "DeepPink") (:weight 'bold))))
  :hook (after-init . winum-mode))

(use-package winner
  :hook (after-init . winner-mode)
  :bind (:map
         my-window-map
         ("r" . winner-undo)
         ("R" . winner-redo)))

;; window management
(use-package window
  :bind (("M-j" . scroll-up-line)
         ("M-k" . scroll-down-line)
         :map
         my-buffer-map
         ("d" . kill-current-buffer)
         ("M" . switch-to-minibuffer)
         ("n" . next-buffer)
         ("p" . previous-buffer)
         ("m" . my-switch-to-message-buffer)
         ("s" . my-switch-to-scratch-buffer)
         :map
         my-window-map
         ("h" . windmove-left)
         ("j" . windmove-down)
         ("k" . windmove-up)
         ("l" . windmove-right)
         ("w" . meow-window-resize-mode)
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

  (defun my-switch-to-message-buffer ()
    (interactive)
    (switch-to-buffer "*Messages*"))

  (defun my-switch-to-scratch-buffer ()
    (interactive)
    (switch-to-buffer "*scratch*"))

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
  ;; Add functions for resizing window
  (defun my-move-window-top-border-up ()
    (interactive)
    (if (not (= (nth 1 (window-edges)) 0))
        (let ((win (selected-window)))
          (windmove-up)
          (shrink-window 1)
          (select-window win))))
  (defun my-move-window-top-border-down ()
    (interactive)
    (if (not (= (nth 1 (window-edges)) 0))
        (let ((win (selected-window)))
          (windmove-up)
          (enlarge-window 1)
          (select-window win))))
  (defun my-move-window-left-border-left ()
    (interactive)
    (if (not (= (nth 0 (window-edges)) 0))
        (let ((win (selected-window)))
          (windmove-left)
          (shrink-window 1 t)
          (select-window win))))
  (defun my-move-window-left-border-right ()
    (interactive)
    (if (not (= (nth 0 (window-edges)) 0))
        (let ((win (selected-window)))
          (windmove-left)
          (enlarge-window 1 t)
          (select-window win))))
  (defun my-move-window-right-border-right ()
    (interactive)
    (if (not (= (nth 2 (window-edges))
                (nth 2 (window-edges (frame-root-window)))))
        (enlarge-window 1 t)))
  (defun my-move-window-right-border-left ()
    (interactive)
    (if (not (= (nth 2 (window-edges))
                (nth 2 (window-edges (frame-root-window)))))
        (shrink-window 1 t)))
  (defun my-move-window-bottom-border-down ()
    (interactive)
    (if (not (= (nth 3 (window-edges))
                (nth 3 (window-edges (frame-root-window)))))
        (enlarge-window 1)))
  (defun my-move-window-bottom-border-up ()
    (interactive)
    (if (not (= (nth 3 (window-edges))
                (nth 3 (window-edges (frame-root-window)))))
        (shrink-window 1)))

  (with-eval-after-load 'meow
    (meow-define-keys 'window-resize
      '("<escape>" . meow-normal-mode)
      '("h" . my-move-window-left-border-left)
      '("j" . my-move-window-bottom-border-down)
      '("k" . my-move-window-top-border-up)
      '("l" . my-move-window-right-border-right)
      '("H" . my-move-window-right-border-left)
      '("J" . my-move-window-top-border-down)
      '("K" . my-move-window-bottom-border-up)
      '("L" . my-move-window-left-border-right)
      '("SCP" . meow-keypad)))
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
