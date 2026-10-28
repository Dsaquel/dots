[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

export PATH="$HOME/.local/bin:$PATH"

[ -f "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
