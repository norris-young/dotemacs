(use-package org-superstar
  :hook (org-mode . org-superstar-mode))

(use-package org
  :bind (:map my-org-map
        ("f" . org-cycle-agenda-files)
        ("c" . org-capture)
        ("r" . org-refile)
        ("s" . org-schedule)
        ("p" . org-set-property)
        ("A" . my-org-attach)
        ("a" . org-agenda))
  :custom
  ;; Enable indentation
  (org-startup-indented t)

  ;; Org clock config
  (org-clock-in-switch-to-state "STARTED")
  (org-clock-out-remove-zero-time-clocks t)
  (org-clock-idle-time 15)

  ;; TODO keywords
  (org-todo-keywords '((sequence "TODO(t)" "RUN(r!)" "|" "DONE(d!)")
                       (sequence "TOBUY(u)" "ORDERED(o@)" "|" "RECVED(!)")
                       (sequence "INTR(i!)" "SUSPEND(s!)" "BLOCK(b@/!)" "|" "CANCELED(c@/!)")))
  (org-todo-keyword-faces '(("TODO"     :foreground "orange"      :weight bold)
                            ("TOBUY"    :foreground "orange"      :weight bold)
                            ("RUN"      :foreground "yellow"      :weight bold)
                            ("ORDERED"  :foreground "yellow"      :weight bold)
                            ("DONE"     :foreground "light green" :weight bold)
                            ("RECVED"   :foreground "light green" :weight bold)
                            ("INTR"     :foreground "tomato"      :weight bold)
                            ("SUSPEND"  :foreground "dark red"    :weight bold)
                            ("BLOCK"    :foreground "red"         :weight bold)
                            ("CANCELED" :foreground "light green" :weight bold)))
  ;; Log task state changing events into LOGBOOK
  (org-log-into-drawer t)

  ;; Effort larger than 4 hours should be divided into smaller pieces
  (org-global-properties '(("Effort_ALL" . "0 0:10 0:30 1:00 2:00 3:00 4:00")))
  ;; (org-columns-default-format "%25ITEM(Task) %TODO %PRIORITY %TAGS %Effort(Estimated Effort){:} %CLOCKSUM")

  ;; Insert new notes at the beginning
  (org-reverse-note-order t)

  ;; Refile config
  (org-refile-use-outline-path 'file)
  (org-outline-path-complete-in-steps nil)
  (org-refile-allow-creating-parent-nodes 'confirm)
  (org-refile-targets '((nil :maxlevel . 10)
                        (org-agenda-files :maxlevel . 10)))

  ;; Attachments config
  (org-attach-id-dir "attaches/")
  (org-attach-store-link-p 'attached)

  ;; Indentation config
  ;; (org-hide-leading-stars t)

  ;; Agenda view
  (org-agenda-custom-commands
   '(("r" "Weekly Review"
      ((agenda "" ((org-agenda-overriding-header "Weekly Review")
                   (org-agenda-span 'week)
                   (org-agenda-show-log 'clockcheck)
                   (org-agenda-start-with-log-mode nil)
                   (org-agenda-log-mode-items '(closed clock state))
                   (org-agenda-clockreport-mode t)))))
     ("p" "Planning"
      ((agenda "" ((org-agenda-span 'day)
                   (org-agenda-start-day "+1d")))
       (tags "refile"
             ((org-agenda-overriding-header "Tasks to refile")
              (org-tags-match-list-sublevels nil)))
       (todo "" ((org-agenda-skip-function
                  '(org-agenda-skip-entry-if 'scheduled)))))
      ((org-agenda-window-setup 'only-window)
       (org-agenda-restore-windows-after-quit t))
      )))

  ;; Org list bullet
  (org-list-allow-alphabetical t)
  (org-list-demote-modify-bullet '(("1." . "1)")
                                   ("1)" . "a.")
                                   ("a." . "a)")
                                   ("a)" . "-")
                                   ("-" . ".")
                                   ("." . "+")))

  ;; Show no blank lines at the end of tree
  (org-cycle-separator-lines 0)

  ;; Set default bookmark file
  (bookmark-default-file (expand-file-name "bookmarks" org-files-dir))

  ;; Capture templates
  (org-capture-templates
   '(("b" "Buy" entry (file+headline org-file-shopping "Shopping")
      "* TOBUY %?\n%U"
      :prepend t :empty-lines-after 1)
     ("m" "Meeting" entry (file+headline org-file-note "Meetings")
      "* %?\n%U\n%i"
      :prepend t :jump-to-captured t :empty-lines-after 1)
     ("n" "Notes" entry (file+headline org-file-note "Quick notes")
      "* %?\n%U\n%i"
      :prepend t :empty-lines-after 1)
     ("t" "TODO" entry (file+headline org-file-note "Unclassified todos")
      "* TODO %?\n%U\n%i\n%^{Effort}p"
      :prepend t :empty-lines-after 1)
     ("w" "Work" entry (file+headline org-file-source "Unclassified tasks")
      "* TODO %?\n%U\n%i\n%^{Effort}p"
      :prepend t :jump-to-captured t :empty-lines-after 1)))

  ;; mobile files sync directory
  (org-mobile-directory "~/Dropbox/org")

  ;; org tags list
  (org-tags-alist '(("shopping" . ?s)))


  :init
  ;; Org files
  (defvar org-files-dir "~/org")
  (if (not (file-directory-p org-files-dir))
      (make-directory org-files-dir))
  (defvar org-agenda-files nil)
  (dolist (file '("note" "source" "improve" "interest" "meanning" "shopping"))
    (add-to-list 'org-agenda-files
                 (setf (symbol-value (intern (concat "org-file-" file)))
                       (expand-file-name (concat file ".org") org-files-dir))))
  (dolist (file org-agenda-files)
    (if (not (file-exists-p file))
        (make-empty-file file)))

  :config
  (eval-when-compile (require 'org))
  ;; Auto save org buffers after refile.
  (advice-add #'org-refile :after (lambda (&rest _) (org-save-all-org-buffers)))

  ;; Auto update todo state after children's todo state changes.
  (defun org-todo-if-needed (state)
    "Change header state to STATE unless the current item is in STATE already."
    (unless (string-equal (org-get-todo-state) state)
      (org-todo state)))

  (defun org-summary-todo-cookie (n-done n-not-done)
    "Switch header state to DONE when all subentries are DONE, to TODO when none
are DONE, and to STARTED otherwise"
    (let (org-log-done org-log-states)   ; turn off logging
      (org-todo-if-needed (cond ((= n-done 0)
                                 "TODO")
                                ((= n-not-done 0)
                                 "DONE")
                                (t
                                 "STARTED")))))
  (add-hook 'org-after-todo-statistics-hook #'org-summary-todo-cookie)

  (defun org-summary-checkbox-cookie ()
    "Switch header state to DONE when all checkboxes are ticked, to TODO when
none are ticked, and to STARTED otherwise"
    (let (beg end)
      (unless (not (org-get-todo-state))
        (save-excursion
          (org-back-to-heading t)
          (setq beg (point))
          (end-of-line)
          (setq end (point))
          (goto-char beg)
          ;; Regex group 1: %-based cookie
          ;; Regex group 2 and 3: x/y cookie
          (if (re-search-forward "\\[\\([0-9]*%\\)\\]\\|\\[\\([0-9]*\\)/\\([0-9]*\\)\\]"
                                 end t)
              (if (match-end 1)
                  ;; [xx%] cookie support
                  (cond ((equal (match-string 1) "100%")
                         (org-todo-if-needed "DONE"))
                        ((equal (match-string 1) "0%")
                         (org-todo-if-needed "TODO"))
                        (t
                         (org-todo-if-needed "STARTED")))
                ;; [x/y] cookie support
                (if (> (match-end 2) (match-beginning 2)) ; = if not empty
                    (cond ((equal (match-string 2) (match-string 3))
                           (org-todo-if-needed "DONE"))
                          ((or (equal (string-trim (match-string 2)) "")
                               (equal (match-string 2) "0"))
                           (org-todo-if-needed "TODO"))
                          (t
                           (org-todo-if-needed "STARTED")))
                  (org-todo-if-needed "STARTED"))))))))
  (add-hook 'org-checkbox-statistics-hook #'org-summary-checkbox-cookie)

  ;; Add function for different behaviours of attachments in different modes.
  (defun my-org-attach ()
    (interactive)
    (pcase major-mode
      ('dired-mode
       (call-interactively #'org-attach-dired-to-subtree))
      ('org-mode
       (call-interactively #'org-attach))))
  )

(provide 'init-org)
