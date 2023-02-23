(use-package org-superstar
  :hook (org-mode . org-superstar-mode))

(use-package org
  :bind (:map my-org-map
        ("f" . org-cycle-agenda-files)
        ("c" . org-capture)
        ("a" . org-agenda))
  :custom
  ;; Enable indentation
  (org-startup-indented t)

  ;; Org clock config
  (org-clock-in-switch-to-state "STARTED")
  (org-clock-out-remove-zero-time-clocks t)
  (org-clock-idle-time 15)

  ;; TODO keywords
  (org-todo-keywords '((sequence "TODO(t)" "STARTED(s)" "|" "DONE(d)")
                       (sequence "REPORT(r)" "BUG(b)" "KNOWNCAUSE(k)" "|" "FIXED(f)")
                       (sequence "|" "CANCELED(c)")))
  (org-log-into-drawer t)

  (org-global-properties '(("Effort_ALL" . "0 0:10 0:30 1:00 2:00 3:00 4:00 5:00 6:00 7:00")))
  (org-columns-default-format "%25ITEM(Task) %TODO %PRIORITY %TAGS %Effort(Estimated Effort){:} %CLOCKSUM")

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
     ("p" "Following Day(s) Plan"
      ((agenda "" ((org-agenda-span 'day)
                   (org-agenda-start-day "+1d")))
       (todo "" ((org-agenda-skip-function
                  '(org-agenda-skip-entry-if 'scheduled))))))))

  ;; Org list bullet
  (org-list-allow-alphabetical t)
  (org-list-demote-modify-bullet '(("1." . "1)") ("1)" . "a.") ("a." . "a)")
                                   ("a)" . "-") ("-" . ".") ("." . "+")))

  ;; Show no blank lines at the end of tree
  (org-cycle-separator-lines 0)

  ;; Set default bookmark file
  (bookmark-default-file (expand-file-name "bookmarks" org-files-dir))
  :init
  ;; Org files
  (setq org-files-dir "~/org")
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
  ;; Capture templates
  (setq org-capture-templates
        '(("b" "Buy" entry (file+headline org-file-shopping "Shopping")
           "* TODO %?\n%U"
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
  )

(provide 'init-org)
