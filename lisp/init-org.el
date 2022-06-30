(use-package org
  :bind (:map org-mode-map
              ("C-c C-o" . nil)
              ("C-c o" .  org-open-at-point))
  :custom
  (org-clock-in-switch-to-state "STARTED")
  (org-clock-out-remove-zero-time-clocks t)
  :config
  (setq org-catch-invisible-edits 'show)

  (setq org-todo-keywords
        '((sequence "TODO(t)" "STARTED(s)" "|" "DONE(d)")
          (sequence "REPORT(r)" "BUG(b)" "KNOWNCAUSE(k)" "|" "FIXED(f)")
          (sequence "|" "CANCELED(c)")))
  (setq org-log-into-drawer t)
  (setq org-clock-x11idle-program-name '("xprintidle"))
  (setq org-global-properties '(("Effort_ALL" . "0 0:10 0:30 1:00 2:00 3:00 4:00 5:00 6:00 7:00")))
  (setq org-columns-default-format "%25ITEM(Task) %TODO %PRIORITY %TAGS %Effort(Estimated Effort){:} %CLOCKSUM")
  (setq org-reverse-note-order t)
  (setq org-refile-use-outline-path 'file)
  (setq org-outline-path-complete-in-steps nil)
  (setq org-refile-allow-creating-parent-nodes 'confirm)
  (setq org-attach-id-dir "attaches/")
  (setq org-attach-store-link-p t)

  (setq org-files-dir "~/org")
  (setq org-file-note
        (expand-file-name "note.org" org-files-dir))
  (setq org-file-work
        (expand-file-name "work.org" org-files-dir))
  (setq org-file-study
        (expand-file-name "study.org" org-files-dir))
  (setq org-file-life
        (expand-file-name "life.org" org-files-dir))
  (setq org-file-journal
        (expand-file-name "journal.org" org-files-dir))
  (setq org-agenda-files (list org-file-note org-file-work org-file-study org-file-life org-file-journal))
  (if (not (file-directory-p org-files-dir))
      (make-directory org-files-dir))
  (dolist (org-file org-agenda-files)
    (if (not (file-exists-p org-file))
        (with-temp-buffer (write-file org-file))))
  (setq org-refile-targets
        '((nil :maxlevel . 10)
          (org-agenda-files :maxlevel . 10)))

  (setq org-capture-templates
        '(("b" "Buy" entry (file+headline org-file-life "Shopping")
           "* TODO %?\n  %U"
           :prepend t :empty-lines-after 1)
          ("j" "Journal Entry"
           entry (file+datetree org-file-journal)
           "* %?"
           :prepend t
           :time-prompt t
           :jump-to-captured t
           :empty-lines-after 1)
          ("m" "meeting" entry (file+headline org-file-note "Meeting Summary")
           "* %?\n  %U\n  %i"
           :prepend t
           :jump-to-captured t
           :empty-lines-after 1)
          ("n" "notes" entry (file+headline org-file-note "Quick notes")
           "* %?\n  %U\n  %i"
           :prepend t
           :empty-lines-after 1)
          ;; TODO: Try to use org-capture to add code snippets
          ;; ("s" "Code Snippet" entry
          ;;  (file org-agenda-file-code-snippet)
          ;;  "* %?\t%^g\n#+BEGIN_SRC %^{language}\n\n#+END_SRC")
          ("t" "Todo" entry (file+headline org-file-life "Cinches")
           "* TODO %?\n  %U\n  %i\n  %^{Effort}p"
           :prepend t
           :empty-lines-after 1)
          ("w" "work" entry (file+headline org-file-work "Undefined works")
           "* TODO %?\n  %U\n  %i\n  %^{Effort}p"
           :prepend t
           :jump-to-captured t
           :empty-lines-after 1)
          ("x" "Web Collections" entry (file+headline org-file-note "Web collections")
           "* %?\n  %U\n  %:link"
           :prepend t
           :empty-lines-after 1)))

  (setq org-agenda-custom-commands
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
  (setq org-list-allow-alphabetical t)
  (setq org-list-demote-modify-bullet
        '(("1." . "1)") ("1)" . "a.") ("a." . "a)")
          ("a)" . "-") ("-" . ".") ("." . "+")))
  (setq org-startup-with-inline-images t)
  (setq org-pretty-entities t)
  (setq org-mobile-directory "/mnt/d/Documents/NutCloud/orgmobile")
  (setq org-agenda-include-diary nil))

(global-set-key (kbd "C-c C-o") 'org-cycle-agenda-files)
