set fish_greeting ""

alias ls "eza"
alias la "eza -A"
alias ll "eza -l"
alias lla "eza -lA"
alias sg "ast-grep"
alias g git
alias c clear
alias vim nvim
alias rg "rg --hyperlink-format=kitty"
alias lg lazygit

set -gx EDITOR nvim

fish_add_path -g -p ~/.local/bin
set -l _seen
set -l _clean
for _p in $PATH
    if not contains -- $_p $_seen
        set -a _seen $_p
        set -a _clean $_p
    end
end
set -gx PATH $_clean
contains node_modules/.bin $PATH; or set -gx PATH $PATH node_modules/.bin

if status is-login
    if test (tty) = "/dev/tty1"
        exec start-hyprland
    end
end
