(use-package which-key
  :custom
  (which-key-show-early-on-C-h t)
  (which-key-idle-delay 0.5)
  (which-key-idle-secondary-delay 0.05)
  :hook (after-init . which-key-mode))

(use-package acm
  :autoload acm-hide acm-doc-hide)

(use-package meow
  :init
  (defvar my-org-map (make-sparse-keymap))
  (defvar my-git-map (make-sparse-keymap))
  (defvar my-file-map (make-sparse-keymap))
  (defvar my-visit-map (make-sparse-keymap))
  (defvar my-window-map (make-sparse-keymap))
  (defvar my-buffer-map (make-sparse-keymap))
  (defvar my-search-map (make-sparse-keymap))
  (defvar my-project-map (make-sparse-keymap))
  (defvar my-function-map (make-sparse-keymap))
  (defvar my-codefold-map (make-sparse-keymap))
  (defvar meow-window-resize-map (make-sparse-keymap))
  :bind (("C-x C-S-r" . restart-emacs)
         :map
         my-file-map
         ("s" . save-buffer)
         :map
         my-visit-map
         ("m" . meow-visit)
         :map
         my-project-map
         ("k" . project-kill-buffers)
         ("p" . project-switch-project)
         ("f" . project-find-file)
         ("b" . project-switch-to-buffer)
         ("d" . project-dired))
  :hook (after-init . (lambda () (require 'meow)))
  :custom
  (meow-use-clipboard t)
  (meow-keypad-self-insert-undefined nil)
  (meow-keypad-literal-prefix ?,)
  (meow-keypad-ctrl-meta-prefix  ?.)
  (meow-keypad-start-keys '((?c . ?c) (?x. ?x)))
  (meow-selection-command-fallback
   '((meow-replace          . meow-yank)
     (meow-change           . meow-change-char)
     (meow-cancel-selection . keyboard-quit)
     (meow-pop-selection    . meow-pop-grab)
     (meow-beacon-change    . meow-beacon-change-char)))
  (meow-char-thing-table '((?r . round)
                           (?s . square)
                           (?c . curly)
                           (?' . string)
                           (?e . symbol)
                           (?w . window)
                           (?b . buffer)
                           (?p . paragraph)
                           (?l . line)
                           (?d . defun)
                           (?. . sentence)))
  :custom-face
  (meow-cheatsheet-command ((t (:inherit fixed-pitch :height 130))))
  :config
  (eval-when-compile
    (require 'meow)
    (require 'smartparens))
  ;; Add a state for resizing current window
  (meow-define-state window-resize
    "meow state for resizing current window"
    :lighter " [WR]"
    :keymap meow-window-resize-map)
  (setq meow-cursor-type-window-resize 'hollow)
  ;; Set state for some special modes
  (setf (alist-get 'help-mode meow-mode-state-list) 'motion)
  (add-to-list 'meow-mode-state-list '(lsp-bridge-ref-mode . motion))

  (defvar my-escape-key-sequence (kbd "jj"))
  (defvar my-escape-delay 0.2)
  (defun my-escape-pre-command-hook ()
    "my escape pre-command hook for quickly escape insert state."
    (if meow-insert-mode
        ;; (with-demoted-errors "my escape: Error %S"
        (when (and (equal (string-to-char (let ((key (this-command-keys)))
                                            (if (stringp key) key "n")))
                          ;; check first key
                          (elt my-escape-key-sequence 0)))
          (let* ((modified (buffer-modified-p))
                 (inserted (condition-case nil
                               (progn (self-insert-command 1) t)
                             ('error nil)))
                 (skey (elt my-escape-key-sequence 1))
                 (evt (read-event nil nil my-escape-delay)))
            (when inserted (delete-char -1))
            (set-buffer-modified-p modified)
            (cond
             ;; check second key
             ((and (characterp evt)
                   (char-equal evt skey))
              (setq this-command #'meow-insert-exit)
              (setq this-original-command #'meow-insert-exit))
             ((null evt))
             (t (setq unread-command-events
                      (cons evt unread-command-events))))))
      ;; )
      ))

  (add-hook 'pre-command-hook #'my-escape-pre-command-hook)

  (advice-add #'meow-insert-exit :after #'acm-hide)
  (advice-add #'meow-insert-exit :after #'acm-doc-hide)

  (defun my-show-file-name ()
    (interactive)
    (let ((name (buffer-file-name)))
      (message name)
      (kill-new name)))
  (define-key my-file-map (kbd "n") #'my-show-file-name)

  (defun my-copy-to-register (begin end)
    (interactive "r")
    (copy-to-register ?r begin end))

  (defun my-insert-register ()
    (interactive)
    (if (get-register ?r)
        (insert-register ?r)))

  (defun my-insert-after ()
    (interactive)
    (call-interactively #'meow-line)
    (call-interactively #'meow-append))

  (defun my-insert-ahead ()
    (interactive)
    (call-interactively #'meow-join)
    (call-interactively #'meow-append))

  (meow-motion-overwrite-define-key
   '("j" . meow-next)
   '("k" . meow-prev)
   '("h" . meow-left)
   '("l" . meow-right)
   '("J" . meow-next-expand)
   '("K" . meow-prev-expand)
   '("H" . meow-left-expand)
   '("L" . meow-right-expand)
   '("<escape>" . ignore))

  (meow-leader-define-key
   ;; SPC SPC for M-x quickly
   '("SPC" . counsel-M-x)
   ;; SPC j/k/h/l will run the original command in MOTION state.
   '("j" . "H-j")
   '("k" . "H-k")
   '("h" . "H-h")
   '("l" . "H-l")
   '("J" . "H-J")
   '("K" . "H-K")
   '("H" . "H-H")
   '("L" . "H-L")
   ;; Use SPC (0-9) for digit arguments.
   '("1" . winum-select-window-1)
   '("2" . winum-select-window-2)
   '("3" . winum-select-window-3)
   '("4" . winum-select-window-4)
   '("5" . winum-select-window-5)
   '("6" . winum-select-window-6)
   '("7" . winum-select-window-7)
   '("8" . winum-select-window-8)
   '("9" . winum-select-window-9)
   '("0" . meow-digit-argument)
   '("/" . meow-keypad-describe-key)
   `("f" . ,my-file-map)
   `("g" . ,my-git-map)
   `("o" . ,my-org-map)
   `("w" . ,my-window-map)
   `("s" . ,my-search-map)
   `("b" . ,my-buffer-map)
   `("p" . ,my-project-map)
   '("?" . meow-cheatsheet))

  (with-eval-after-load 'smartparens
    (meow-normal-define-key
     '("%" . evilmi-jump-items-native)
     '("DEL" . ignore)
     '("0" . meow-expand-0)
     '("9" . meow-expand-9)
     '("8" . meow-expand-8)
     '("7" . meow-expand-7)
     '("6" . meow-expand-6)
     '("5" . meow-expand-5)
     '("4" . meow-expand-4)
     '("3" . meow-expand-3)
     '("2" . meow-expand-2)
     '("1" . meow-expand-1)
     '("-" . negative-argument)
     '(":" . meow-goto-line)
     '(";" . meow-reverse)
     '("," . meow-inner-of-thing)
     '("." . meow-bounds-of-thing)
     '("[" . meow-beginning-of-thing)
     '("]" . meow-end-of-thing)
     '("a" . meow-append)
     '("A" . my-insert-after)
     '("b" . meow-back-word)
     '("B" . meow-back-symbol)
     '("c" . meow-change)
     '("d" . meow-kill)
     '("D" . meow-C-k)
     '("e" . meow-next-word)
     '("E" . meow-next-symbol)
     `("f" . ,my-function-map)
     '("F" . meow-find)
     '("g" . meow-pop-selection)
     '("G" . meow-grab)
     '("h" . meow-left)
     '("H" . meow-left-expand)
     '("i" . meow-insert)
     '("I" . my-insert-ahead)
     '("j" . meow-next)
     '("J" . meow-next-expand)
     '("k" . meow-prev)
     '("K" . meow-prev-expand)
     '("l" . meow-right)
     '("L" . meow-right-expand)
     '("m" . meow-join)
     '("n" . meow-search)
     '("N" . meow-to-block)
     '("o" . meow-open-below)
     '("O" . meow-open-above)
     '("p" . meow-replace)
     '("P" . meow-yank-pop)
     '("q" . meow-cancel-selection)
     '("Q" . meow-quit)
     '("r" . my-insert-register)
     '("R" . my-copy-to-register)
     '("s" . meow-line)
     '("S" . my-wrap-with-pair)
     '("t" . meow-block)
     '("T" . meow-till)
     '("u" . meow-undo)
     '("U" . undo-redo)
     `("v" . ,my-visit-map)
     '("V" . rectangle-mark-mode)
     '("w" . meow-mark-word)
     '("W" . meow-mark-symbol)
     '("x" . meow-delete)
     '("X" . meow-swap-grab)
     '("y" . meow-save)
     '("Y" . meow-sync-grab)
     `("z" . ,my-codefold-map)
     '("'" . repeat)
     '("<escape>" . ignore))

    (meow-global-mode 1))
  )

(provide 'init-meow)
