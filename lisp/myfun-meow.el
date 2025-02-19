;;; ...  -*- lexical-binding: t -*-

(require 'meow)

(defvar my-escape-key-sequence (kbd "jj"))
(defvar my-escape-delay 0.2)
;;;###autoload
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
                           (error nil)))
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

;;;###autoload
(defun my-show-file-name ()
  (interactive)
  (let ((name (buffer-file-name)))
    (message name)
    (kill-new name)))

;;;###autoload
(defun my-copy-to-register (begin end)
  (interactive "r")
  (copy-to-register ?r begin end))

;;;###autoload
(defun my-insert-register ()
  (interactive)
  (if (get-register ?r)
      (insert-register ?r)))

;;;###autoload
(defun my-insert-after ()
  (interactive)
  (call-interactively #'meow-line)
  (call-interactively #'meow-append))

;;;###autoload
(defun my-insert-ahead ()
  (interactive)
  (call-interactively #'meow-join)
  (call-interactively #'meow-append))

;;;###autoload
(defun my-rename-file (newname)
  (interactive (list (completing-read "new file name: " 'read-file-name-internal
                                      nil nil (buffer-file-name))))
  (let ((oname (buffer-file-name)))
    (if (not (equal oname newname))
        (progn
          (set-visited-file-name newname t t)
          (rename-file oname newname)))))
