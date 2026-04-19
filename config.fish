if status is-interactive
    # Commands to run in interactive sessions can go here
    alias enter='source ~/venv/bin/activate.fish'
    alias py='python3'
    alias python='python3'
    alias x='clear'
    alias code='code'
    alias gti='git'
    alias racket='/usr/racket/bin/racket'
    alias drracket='/usr/racket/bin/drracket'
    alias ls='eza'
    alias la='eza -a'
    alias ll='eza -al'
    alias bat='batcat'
    alias ssh='kitten ssh'
    set -U fish_user_paths ~/bin $fish_user_paths ~/ghc-9.10.3-x86_64-unknown-linux/bin ~/Desktop/cs681 ~/.local/kitty.app/bin ~/bin/blender-5.1.0-linux-x64
    set -Ux TERMINAL kitty
    function run_vegeta -a num
        echo "GET http://192.168.1.106:8080/" | vegeta attack -rate={$num} -duration=1m > results_{$num}.bin; vegeta report results_{$num}.bin > report_{$num}.txt
    end
    function ipl
	cd ~/cs316; COFFRE_HOST=cs316 sudo -E ./qemu-coffre-linux-x86_64 balaji-amd64.qcow2 4 4G < creds; cd -
    end
    function coool
	cd ~/cs6004; COFFRE_HOST=cs6004 sudo -E ./qemu-coffre-linux-x86_64 CS6004-balaji-amd64.qcow2 4 8G < creds; cd -
    end
end

alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias ..... "cd ../../../.."

alias l eza
alias ls "eza --icons=always --hyperlink"
alias ll "eza --group --header --group-directories-first --long --hyperlink"
alias lg "eza --group --header --group-directories-first --long --git --git-ignore --hyperlink"
alias le "eza --group --header --group-directories-first --long --extended --hyperlink"
alias lt "eza --group --header --group-directories-first --tree --level 3 --hyperlink"
alias l.="eza -a | grep -e '^\.'"                                     # show only dotfiles


source "$HOME/.cargo/env.fish"
zoxide init fish --cmd='cd' | source
