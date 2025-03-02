;;; ...  -*- lexical-binding: t -*-

(require 'consult)

;;;###autoload
(defun consult-jump-in-buffer ()
  "Jump in buffer with `consult-imenu' or `counsult-org-heading' if in org-mode"
  (interactive)
  (call-interactively
   (cond
    ((eq major-mode 'org-mode) 'consult-org-heading)
    (t 'consult-imenu))))

;;; copy from ivy-thing-at-point
;;;###autoload
(defun my-thing-at-point ()
  "Return a string that corresponds to the current thing at point."
  (substring-no-properties
   (cond
     ((use-region-p)
      (let* ((beg (region-beginning))
             (end (region-end))
             (eol (save-excursion (goto-char beg) (line-end-position))))
        (buffer-substring-no-properties beg (min end eol))))
     ((let ((url (thing-at-point 'url)))
        ;; Work around `https://bugs.gnu.org/58091'.
        (and (stringp url) url)))
     ((let ((s (thing-at-point 'symbol)))
        (and (stringp s)
             (if (string-match "\\`[`']?\\(.*?\\)'?\\'" s)
                 (match-string 1 s)
               s))))
     ((looking-at "(+\\(\\(?:\\sw\\|\\s_\\)+\\)\\_>")
      (match-string-no-properties 1))
     (t
      ""))))

;;;###autoload
(defun consult-ripgrep-thing-at-point ()
  (interactive)
  (let ((thing (my-thing-at-point)))
    (when (use-region-p)
      (deactivate-mark))
    (consult-ripgrep nil (regexp-quote thing))))

;;;###autoload
(defun consult-ripgrep-thing-in-directory (path)
  (interactive "DDirectory for ripgrep:")
  (consult-ripgrep  path))

;;;###autoload
(defun consult-ripgrep-thing-at-point-in-directory (path)
  (interactive "DDirectory for ripgrep:")
  (let ((thing (my-thing-at-point)))
    (when (use-region-p)
      (deactivate-mark))
    (consult-ripgrep path (regexp-quote thing))))
