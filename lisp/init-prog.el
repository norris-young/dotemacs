(use-package imenu-list
  :bind (:map my-buffer-map
         ("i" . imenu-list-smart-toggle)
         :map imenu-list-major-mode-map
         ("d" . imenu-list-display-dwim)))

(provide 'init-prog)
