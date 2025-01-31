;;; ...  -*- lexical-binding: t -*-

(require 'org)

;; Auto update todo state after children's todo state changes.
;;;###autoload
(defun org-todo-if-needed (state)
  "Change header state to STATE unless the current item is in STATE already."
  (unless (string-equal (org-get-todo-state) state)
    (org-todo state)))

;;;###autoload
(defun org-summary-todo-cookie (n-done n-not-done)
  "Switch header state to DONE when all subentries are DONE, to TODO when none
are DONE, and to STARTED otherwise"
  (let (org-log-done)   ; turn off logging
    (org-todo-if-needed (cond ((= n-done 0)
                               "TODO")
                              ((= n-not-done 0)
                               "DONE")
                              (t
                               "STARTED")))))

;;;###autoload
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

;; Add function for different behaviours of attachments in different modes.
;;;###autoload
(defun my-org-attach ()
  (interactive)
  (pcase major-mode
    ('dired-mode
     (call-interactively #'org-attach-dired-to-subtree))
    ('org-mode
     (call-interactively #'org-attach))))
