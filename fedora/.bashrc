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

PS1='\[\e]0;Fedora\007\]\n\[\e[31m\]`nonzero_return`\[\e[32m\] \u@\h \[\e[35m\]\w\[\e[36m\]`__git_ps1`\e[0m\n$'
export PATH=$PATH:/usr/local/go/bin:~/go/bin:/usr/local/Postman\ Agent/:/usr/local/lua-language-server-3.7.4-linux-x64/
export EDITOR=nvim
export VISUAL=nvim
export SUDO_EDITOR=nvim
