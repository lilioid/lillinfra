; load plugins
(require 'neotree)

; configure emacs options
(custom-set-variables
    '(xterm-mouse-mode :t)
    '(inhibit-startup-screen :t)
    '(indent-tabs-mode nil))
(global-set-key [f8] 'neotree-toggle)

; configure plugins: neotree
(custom-set-variables
    '(neo-theme 'nerd-icons)
    '(inhibit-startup-screen :true))

; configure plugins: tabbar

; init commands
(neotree-show)
