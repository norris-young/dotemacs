;;; ...  -*- lexical-binding: t -*-

(require 'lsp-bridge)
(require 'citre)
(require 'better-jumper)

;; Set jumper in 2 cases:
;; 1. jump more than 50 lines or advise some jump functions

;; (defconst better-jumper-line-threshold 50)
;; (defun my-post-command-set-jumper ()
;;   (if (and (not (eq this-command #'better-jumper-jump-forward))
;;            (not (eq this-command #'better-jumper-jump-backward)))
;;       (let* ((oldp (window-old-point))
;;              (newp (window-point))
;;              (oldl (line-number-at-pos oldp))
;;              (newl (line-number-at-pos newp)))
;;         (if (> (abs (- oldl newl))
;;                better-jumper-line-threshold)

;;;###autoload
(defun my-set-jump (&rest _)
  (better-jumper-set-jump))

;;;###autoload
(defun my-find-def ()
  (interactive)
  (better-jumper-set-jump)
  (if (or (eq major-mode 'emacs-lisp-mode)
          (eq major-mode 'lisp-interaction-mode))
      (let ((symb (symbol-at-point)))
        (if (and symb (not (fboundp symb)))
            (find-variable symb)
          (find-function symb)))
    (if lsp-bridge-mode
        (lsp-bridge-find-def)
      (if citre-mode
          (citre-jump)))))

;;;###autoload
(defun my-find-ref ()
  (interactive)
  (better-jumper-set-jump)
  (if (or (eq major-mode 'emacs-lisp-mode)
          (eq major-mode 'lisp-interaction-mode))
      (let ((identifier (xref-backend-identifier-at-point 'elisp)))
        (xref--find-xrefs identifier 'references identifier nil))
    (if lsp-bridge-mode
        (lsp-bridge-find-references)
      (if citre-mode
          (call-interactively #'citre-jump-to-reference)))))

;;;###autoload
(defun my-after-lsp-find-def-failure (position)
  (deactivate-mark t)
  (if citre-mode
      (let ((line (nth 1 position))
            (col (nth 3 position)))
        (message "lsp-bridge find no reference try citre line: %d col: %d" (1+ line) col)
        (goto-char 1)
        (forward-line line)
        (goto-char (+ (line-beginning-position) col))
        (call-interactively 'citre-jump))))

;;;###autoload
(defun my-after-lsp-find-ref-failure (position)
  (deactivate-mark t)
  (if citre-mode
      (let ((line (nth 1 position))
            (col (nth 3 position)))
        (message "lsp-bridge find no reference try citre line: %d col: %d" (1+ line) col)
        (goto-char 1)
        (forward-line line)
        (goto-char (+ (line-beginning-position) col))
        (call-interactively 'citre-jump-to-reference))))

;;;###autoload
(defun is-lsp-bridge-process-buffer (buffer)
  (let* ((epc-con (cl-struct-slot-value 'lsp-bridge-epc-manager 'connection lsp-bridge-epc-process))
         (epc-process (if epc-con (cl-struct-slot-value 'lsp-bridge-epc-connection 'process epc-con))))
    (or (eq buffer (process-buffer lsp-bridge-internal-process))
        (eq buffer (process-buffer epc-process)))))


;;;###autoload
(defun lsp-dir (&rest _)
  (when-let* ((project (project-current))
              (project-root (nth 2 project)))
    (when (file-exists-p (expand-file-name ".project.lsp.config" project-root))
      (setq-local lsp-bridge-user-langserver-dir (file-local-name project-root))
      (setq-local lsp-bridge-user-multiserver-dir (file-local-name project-root)))))
