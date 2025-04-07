; load plugins
(require 'neotree)
(require 'tree-sitter)
(require 'tree-sitter-langs)

; configure emacs options
(custom-set-variables
    '(xterm-mouse-mode :t)
    '(inhibit-startup-screen :t)
    '(indent-tabs-mode nil))
(global-set-key [f8] 'neotree-toggle)

; configure lsp options
(custom-set-variables
    '(eglot-autoshutdown :t))

; configure plugins: tree-sitter
(global-tree-sitter-mode)
(add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode)

; configure plugins: neotree
(custom-set-variables
    '(neo-theme 'nerd-icons)
    '(neo-autorefresh :t)
    '(neo-vc-integration '(face)))

; configure custom nix mode that uses an lsp
(define-derived-mode nix-mode fundamental-mode "Nix" "A mode for the nix language")
(add-hook 'nix-mode-hook 'eglot-ensure)

; init commands
(neotree-show)
