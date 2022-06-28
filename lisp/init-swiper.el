;; flx package is used for ivy fuzzy match engine
(use-package flx)
(use-package ivy
  :bind (("C-x C-b" . ivy-switch-buffer)
	 ("C-x b" . list-buffers)
	 ("C-c v" . ivy-push-view)
	 ("C-c V" . ivy-pop-view)
	 ("C-c C-r" . ivy-resume)
	 :map ivy-switch-buffer-map
	 ("C-j" . ivy-next-line)
	 ("C-k" . ivy-previous-line)
	 :map ivy-reverse-i-search-map
	 ("C-j" . ivy-next-line)
	 ("C-k" . ivy-previous-line)
	 :map ivy-minibuffer-map
	 ("C-<return>" . ivy-immediate-done)
	 ("C-j" . ivy-next-line)
	 ("C-k" . ivy-previous-line)
	 ("M-RET" . ivy-alt-done))
  :config
  (defun ivy-yank-action (x)
    (kill-new x))

  (defun ivy-copy-to-buffer-action (x)
    (with-ivy-window
      (insert x)))

  (ivy-set-actions
   t
   '(("i" ivy-copy-to-buffer-action "insert")
     ("y" ivy-yank-action "yank")))
  
  (setq ivy-use-virtual-buffers t
	ivy-count-format "(%d/%d) ")
  (ivy-mode 1))
(use-package swiper :bind (("C-s" . swiper-isearch)))
(use-package counsel
  :bind (("M-x" . counsel-M-x)
	 ("C-x C-f" . counsel-find-file)
	 ("M-y" . counsel-yank-pop)
	 ("<f1> f" . counsel-describe-function)
	 ("<f1> v" . counsel-describe-variable)
	 ("<f1> l" . counsel-find-library)
	 ("<f2> i" . counsel-info-lookup-symbol)
	 ("<f2> u" . counsel-unicode-char)
	 ("<f2> j" . counsel-set-variable)))
