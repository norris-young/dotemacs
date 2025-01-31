;;; ...  -*- lexical-binding: t -*-

(require 'meow)
(require 'magit)

;;;###autoload
(defun magit-motion ()
  (if magit-blame-read-only-mode
      (progn
        (meow-mode -1)
        (meow-motion-mode 1))
    (meow-mode 1)))
