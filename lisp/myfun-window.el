;;; ...  -*- lexical-binding: t -*-

;;;###autoload
(defun switch-to-minibuffer ()
  "Switch to minibuffer window."
  (interactive)
  (if (active-minibuffer-window)
      (select-window (active-minibuffer-window))))

;;;###autoload
(defun my-switch-to-message-buffer ()
  (interactive)
  (switch-to-buffer "*Messages*"))

;;;###autoload
(defun my-switch-to-scratch-buffer ()
  (interactive)
  (switch-to-buffer "*scratch*"))

;; Add functions for resizing window
;;;###autoload
(defun my-move-window-top-border-up ()
  (interactive)
  (if (not (= (nth 1 (window-edges)) 0))
      (let ((win (selected-window)))
        (windmove-up)
        (shrink-window 1)
        (select-window win))))

;;;###autoload
(defun my-move-window-top-border-down ()
  (interactive)
  (if (not (= (nth 1 (window-edges)) 0))
      (let ((win (selected-window)))
        (windmove-up)
        (enlarge-window 1)
        (select-window win))))

;;;###autoload
(defun my-move-window-left-border-left ()
  (interactive)
  (if (not (= (nth 0 (window-edges)) 0))
      (let ((win (selected-window)))
        (windmove-left)
        (shrink-window 1 t)
        (select-window win))))

;;;###autoload
(defun my-move-window-left-border-right ()
  (interactive)
  (if (not (= (nth 0 (window-edges)) 0))
      (let ((win (selected-window)))
        (windmove-left)
        (enlarge-window 1 t)
        (select-window win))))

;;;###autoload
(defun my-move-window-right-border-right ()
  (interactive)
  (if (not (= (nth 2 (window-edges))
              (nth 2 (window-edges (frame-root-window)))))
      (enlarge-window 1 t)))

;;;###autoload
(defun my-move-window-right-border-left ()
  (interactive)
  (if (not (= (nth 2 (window-edges))
              (nth 2 (window-edges (frame-root-window)))))
      (shrink-window 1 t)))

;;;###autoload
(defun my-move-window-bottom-border-down ()
  (interactive)
  (if (not (= (nth 3 (window-edges))
              (nth 3 (window-edges (frame-root-window)))))
      (enlarge-window 1)))

;;;###autoload
(defun my-move-window-bottom-border-up ()
  (interactive)
  (if (not (= (nth 3 (window-edges))
              (nth 3 (window-edges (frame-root-window)))))
      (shrink-window 1)))
