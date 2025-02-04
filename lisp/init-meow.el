;;; ...  -*- lexical-binding: t -*-

(use-package which-key
  :custom
  (which-key-show-early-on-C-h t)
  (which-key-idle-delay 0.5)
  (which-key-idle-secondary-delay 0.05)
  :hook (after-init . which-key-mode))

(use-package meow
  :demand t
  :init
  (defvar my-org-map (make-sparse-keymap))
  (defvar my-git-map (make-sparse-keymap))
  (defvar my-file-map (make-sparse-keymap))
  (defvar my-window-map (make-sparse-keymap))
  (defvar my-buffer-map (make-sparse-keymap))
  (defvar my-search-map (make-sparse-keymap))
  (defvar my-function-map (make-sparse-keymap))
  (defvar my-codefold-map (make-sparse-keymap))
  (defvar meow-window-resize-map (make-sparse-keymap))
  :bind (("C-x C-S-r" . restart-emacs)
         :map
         project-prefix-map
         ("C-b" . project-switch-to-buffer)
         ("b" . project-list-buffers)
         :map
         my-file-map
         ("n" . my-show-file-name)
         ("s" . save-buffer))
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
  :hook
  (pre-command . my-escape-pre-command-hook)
  :config
  ;; Set state for some special modes
  (setf (alist-get 'help-mode meow-mode-state-list) 'motion)
  (add-to-list 'meow-mode-state-list '(lsp-bridge-ref-mode . motion))

  (advice-add #'meow-insert-exit :after (lambda (&rest _)
                                          (acm-hide)
                                          (acm-doc-hide)))

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
   `("p" . ,project-prefix-map)
   '("?" . meow-cheatsheet))

  (with-eval-after-load 'tabspaces
    (meow-leader-define-key
     `("t" . ,tabspaces-command-map)))

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
   '("t" . meow-block)
   '("T" . meow-till)
   '("u" . meow-undo)
   '("U" . undo-redo)
   '("v" . avy-goto-word-1)
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

  (with-eval-after-load 'smartparens
    (meow-normal-define-key
     '("S" . my-wrap-with-pair)))

  (meow-global-mode 1)
  )

;; Add a state for resizing current window
(meow-define-state window-resize
  "meow state for resizing current window"
  :lighter " [WR]"
  :keymap meow-window-resize-map)
(setq meow-cursor-type-window-resize 'hollow)

(provide 'init-meow)
