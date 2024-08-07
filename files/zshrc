autoload -U colors && colors

alias ls="ls --color"
alias la="ls -a --color"
alias l="ls -la --color"
alias arc="vim ~/Desktop/archive/main.*"
alias :q="exit"
alias files="vim ~/files/index.md"
alias kjv="less ~/KJV/kjv"

PS1="%{$fg[green]%}%~%{$reset_color%} > "

# colored man pages
export LESS_TERMCAP_mb=$'\e[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\e[1;33m'     # begin blink
export LESS_TERMCAP_so=$'\e[01;44;37m' # begin reverse video
export LESS_TERMCAP_us=$'\e[01;37m'    # begin underline
export LESS_TERMCAP_me=$'\e[0m'        # reset bold/blink
export LESS_TERMCAP_se=$'\e[0m'        # reset reverse video
export LESS_TERMCAP_ue=$'\e[0m'        # reset underline
export GROFF_NO_SGR=1                  # for konsole and gnome-terminal

source ~/.profile

export GPG_TTY=$(tty) # fix bug with gpg signature for commits
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
