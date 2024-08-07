# .bashrc

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alh'
alias la='ls -A'
alias l='ls -CF'

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

. /usr/share/git-core/contrib/completion/git-prompt.sh
#export PS1='[\u@\h \W$(declare -F __git_ps1 &>/dev/null && __git_ps1 " (%s)")]\$ '

function nonzero_return() {
    local RETVAL=$?
    if [[ $RETVAL -ne 0 ]]
    then
        echo "❌($RETVAL)"
    else
        echo "✅"
    fi
}

frg () {
    rm -f /tmp/rg-fzf-{r,f}
    RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
    INITIAL_QUERY="${*:-}"
    fzf --ansi --disabled --query "$INITIAL_QUERY" \
        --bind "start:reload:$RG_PREFIX {q}" \
        --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
        --bind 'ctrl-t:transform:[[ ! $FZF_PROMPT =~ ripgrep ]] &&
          echo "rebind(change)+change-prompt(1. ripgrep> )+disable-search+transform-query:echo \{q} > /tmp/rg-fzf-f; cat /tmp/rg-fzf-r" ||
          echo "unbind(change)+change-prompt(2. fzf> )+enable-search+transform-query:echo \{q} > /tmp/rg-fzf-r; cat /tmp/rg-fzf-f"' \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --prompt '1. ripgrep> ' \
        --delimiter : \
        --header 'CTRL-T: Switch between ripgrep/fzf' \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --bind 'enter:become(nvim {1} +{2})'
}
fgc () {
    git checkout \
        $(
            (
                git branch -a -vv --color=always;
                pgl;
            ) |
            fzf --ansi --reverse --cycle --preview="git show --color=always \$(echo {} | awk '{print \$1}')" |
            awk '{print $1}' |
            sed 's/\*//'
        )
}
fgbc () {
    git checkout \
        $(
            git branch -a -vv --color=always |
            fzf --ansi --reverse --cycle --preview="git show --color=always \$(echo {} | awk '{print \$1}')" |
            awk '{print $1}' |
            sed 's/\*//'
        )
}
fgcc () {
    git checkout \
        $(
            pggl |
            fzf --ansi --reverse --cycle --preview="git show --color=always \$(echo {} | sed -E 's/[^a-f0-9]*([a-f0-9]+).*/\1/')" |
            sed -E 's/[^a-f0-9]*([a-f0-9]+).*/\1/'
        )
}

fs () { interactively 'sed -e {} '$1''; }
fg () { interactively 'grep --color=always {} '$1''; }

PS1='\[\e]0;Fedora\007\]\n\[\e[31m\]`nonzero_return`\[\e[32m\] \u@\h \[\e[35m\]\w\[\e[36m\]`__git_ps1`\e[0m\n$'
export PATH=$PATH:/usr/local/go/bin:~/go/bin:/usr/local/Postman\ Agent/:~/.local/lua-language-server-3.7.4-linux-x64/:~/android-studio/bin
export EDITOR=nvim
export VISUAL=nvim
export SUDO_EDITOR=nvim
export BAT_THEME="OneHalfDark"
export PATH="/usr/share/flutter/bin:$PATH"
export PATH="~/Downloads/Installers/interactively/bin/:$PATH"

export FZF_DEFAULT_OPTS="
    --walker-skip .git,node_modules,target,.local,.cache,.steam,.gradle,venv,.cache,sys,proc,.file,.npm,.dartserver
    --walker-root=/
    --cycle
    --border
"
export FZF_ALT_C_OPTS="
    $FZF_DEFAULT_OPTS
    --preview 'tree -C {}'
"


if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  tm
fi

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
