# Sample .bashrc for SUSE Linux
# Copyright (c) SUSE Software Solutions Germany GmbH

# There are 3 different types of shells in bash: the login shell, normal shell
# and interactive shell. Login shells read ~/.profile and interactive shells
# read ~/.bashrc; in our setup, /etc/profile sources ~/.bashrc - thus all
# settings made here will also take effect in a login shell.
#
# NOTE: It is recommended to make language settings in ~/.profile rather than
# here, since multilingual X sessions would not work properly if LANG is over-
# ridden in every subshell.

test -s $HOME/.alias && . $HOME/.alias || true


# Set up fzf key bindings and fuzzy completion
eval "$(fzf --bash)"

# fnm
FNM_PATH="/home/baky/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi

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
if [ -d $HOME/.bashrc.d ]; then
	for rc in $HOME/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r $HOME/.dircolors && eval "$(dircolors -b $HOME/.dircolors)" || eval "$(dircolors -b)"
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

if [ -f $HOME/.bash_aliases ]; then
    . $HOME/.bash_aliases
fi

. /etc/bash_completion.d/git-prompt
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

screenshot () {
    local filename="$HOME/Pictures/Screenshots/Screenshot_$(date +%Y-%m-%d-%H-%M-%S).png"
    grimshot savecopy anything "$filename"
    notify-send "Screenshot saved to clipboard and $filename"
}

swap_sway_wksp () {
    local wksp=$(swaymsg -rt get_workspaces | jq -r '.[] | select(.focused == true).num')
    local query="string join '' '.. | select(.type?) | select(.num == ' $1 ') | .output'"
    local output=$(swaymsg -rt get_outputs | jq -r $query)

    swaymsg [workspace = $1] move workspace to output current
    swaymsg [workspace = $wksp] move workspace to output $output
    swaymsg workspace number $1
}

get_file () {
    if [[ ! -d "$HOME/remote_device_files" ]]; then
        mkdir -p $HOME/remote_device_files
    fi
        scp bgorgani@"$1":"$2" $HOME/remote_device_files/
}

jump_ssh () {
    local connectName
    if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
        echo "Usage: olympus_con <olympus OR pulsar> <Router FQDN or IP OR Nickname if available> <New Nickname (optional)>"
        return 1
    fi
    local jumpServer="$1"
    if [[
            "$jumpServer" != "olympus.srv.prnynj.alticeusa.net" &&
            "$jumpServer" != "pulsar2.suddenlink.net"
    ]]; then
        echo "Invalid jump server. Must be either 'olympus.srv.prnynj.alticeusa.net' or 'pulsar2.suddenlink.net'"
        return 1
    fi
    if [[ "$jumpServer" == "olympus" ]]; then
        if [[ ! -f "$HOME/.connections/.olympuspasswd.gpg" ]]; then
            echo "Password files for olympus not found"
            return 1
        fi
    else
        if [[ ! -f "$HOME/.connections/.pulsarpasswd.gpg" ]]; then
            echo "Password file for pulsar not found"
            return 1
        fi
    fi
    if [[ ! -f "$HOME/.connections/.tacacspasswd.gpg" ]]; then
        echo "Password file for tacacs not found"
        return 1
    fi
    echo "Jumpserver set to $jumpServer"
    local ipOrDns="$2"
    if [[ -z "$3" ]]; then
        local name="$ipOrDns"
    else
        local name="$3"
    fi
    if [[ ! -f "$HOME/.connections/$jumpServer" ]]; then
        mkdir -p $HOME/.connections
        touch $HOME/.connections/$jumpServer
    fi
    if grep -q "^$name\\s$ipOrDns$" "$HOME/.connections/$jumpServer"; then
        echo "Connection entry exists!"
        connectName=$ipOrDns
    elif grep -q "$name\\s" "$HOME/.connections/$jumpServer"; then
        echo "Connection entry exists!"
        local entryArray=($(grep -e "^$name\\s" -e "\\s$name$" "$HOME/.connections/$jumpServer"))
        local nameInFile=${entryArray[0]}
        local ipInFile=${entryArray[1]}
        if [[ "$nameInFile" == "$ipInFile" ]]; then
            connectName=$nameInFile
        else
            connectName=$ipInFile
        fi
    else
        local ipRegex="^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$"
        if [[ $ipOrDns =~ $ipRegex ]]; then
            if grep -q "\\s$ipOrDns$" "$HOME/.connections/$jumpServer"; then
                echo "Connection entry exists!"
                local nameInFile=$(grep -oP "^.*(?= $ipOrDns$)" "$HOME/.connections/$jumpServer")
                echo "$ipOrDns is already associated with the name '$nameInFile'. Do you want to overwrite it with '$name'?"
                select ync in "Yes" "No" "Cancel"; do
                    case $ync in
                        Yes ) sed -i "s/$nameInFile $ipOrDns/$name $ipOrDns/" "$HOME/.connections/$jumpServer"; echo "Connection entry name changed"; break;;
                        No ) echo "Connection entry left alone"; break;;
                        Cancel ) return 1;;
                        * ) echo "Please answer 1 for Yes, 2 for No, or 3 for Cancel";;
                    esac
                done
            else
                echo "Connection entry does not exist."
                if [[ "$name" == "$ipOrDns" ]]; then
                    echo "Adding $name to connection list"
                else
                    echo "Adding $name($ipOrDns) to connection list"
                fi
                echo "$name $ipOrDns" >> "$HOME/.connections/$jumpServer"
            fi
            connectName=$ipOrDns
        else
            local cvSuffix=".cv.net"
            local stripCvSuffix=${name%"$cvSuffix"}
            local cvName="$stripCvSuffix$cvSuffix"
            local alticeSuffix=".alticeusa.net"
            local stripAlticeSuffix=${name%"$alticeSuffix"}
            local alticeName="$stripAlticeSuffix$alticeSuffix"
            if grep -q "$cvName\\s" "$HOME/.connections/$jumpServer"; then
                echo "Connection entry exists!"
                connectName=$cvName
            elif grep -q "$alticeName\\s" "$HOME/.connections/$jumpServer"; then
                echo "Connection entry exists!"
                connectName=$alticeName
            else
                echo "Connection entry does not exist."
                local cvIp=$(nslookup "$cvName" | grep -oP "(?<=Address: ).*")
                local alticeIp=$(nslookup "$alticeName" | grep -oP "(?<=Address: ).*")
                if nslookup "$cvName" > /dev/null; then
                    echo "DNS entry found for $cvName"
                    echo "Adding $cvName to connection list"
                    echo "$cvName $cvName" >> "$HOME/.connections/$jumpServer"
                    connectName=$cvName
                elif nslookup "$alticeName" > /dev/null; then
                    echo "DNS entry found for $alticeName"
                    echo "Adding $alticeName to connection list"
                    echo "$alticeName $alticeName" >> "$HOME/.connections/$jumpServer"
                    connectName=$alticeName
                else
                    echo "Neither $cvName or $alticeName are valid DNS names"
                    return 1
                fi
            fi
        fi
    fi

    local entryArray=($(grep "$connectName" "$HOME/.connections/$jumpServer"))
    local connectName=${entryArray[0]}
    local connectIp=${entryArray[1]}
    local windowName=$connectName
    local cvSuffix=".cv.net"
    local stripCvSuffix=${connectName%"$cvSuffix"}
    local alticeSuffix=".alticeusa.net"
    local connectName=${stripCvSuffix%"$alticeSuffix"}
    if [[ "$connectName" == "$connectIp" ]]; then
        echo "Connecting to $connectName through $jumpServer"
    else
        echo "Connecting to $connectName($connectIp) through $jumpServer"
        connectName=$connectIp
    fi
    if [[ "$jumpServer" =~ "olympus" ]]; then
        local olympusPass=$(gpg -d -q "$HOME/.connections/.olympuspasswd.gpg")
        local tacacsPass=$(gpg -d -q "$HOME/.connections/.tacacspasswd.gpg")
        if [[ ! -z "$TMUX" ]]; then
            tmux new-window -n "$windowName" "sshpass -p $olympusPass ssh -t bgorgani@$jumpServer \"sshpass -p $tacacsPass ssh bgorgani@$connectName\";bash -i"
            if [[ "$?" -ne 0 ]]; then
                tmux new-window -n "$windowName" "sshpass -p $olympusPass ssh -t bgorgani@$jumpServer \"ssh bgorgani@$connectName\";bash -i"
            fi
        else
            sshpass -p "$olympusPass" ssh -t bgorgani@"$jumpServer" "sshpass -p \"$tacacsPass\" ssh bgorgani@$connectName"
            if [[ "$?" -ne 0 ]]; then
                sshpass -p "$olympusPass" ssh -t bgorgani@$jumpServer "ssh bgorgani@$connectName"
            fi
        fi
    else
        local pulsarPass=$(gpg -d -q "$HOME/.connections/.pulsarpasswd.gpg")
        if [[ ! -z "$TMUX" ]]; then
            tmux new-window -n "$windowName" "sshpass -p $pulsarPass ssh -oKexAlgorithms=+diffie-hellman-group-exchange-sha1 \
                -oHostKeyAlgorithms=+ssh-dss -t bgorgani@$jumpServer \"ssh bgorgani@$connectName\";bash -i"
        else
            sshpass -p "$pulsarPass" ssh -oKexAlgorithms=+diffie-hellman-group-exchange-sha1 \
                -oHostKeyAlgorithms=+ssh-dss -t bgorgani@$jumpServer "ssh bgorgani@$connectName"
        fi
    fi
    echo "Connection to $connectName through $jumpServer closed"
}

fjs () {
    local jumpServer=$(
        printf "olympus.srv.prnynj.alticeusa.net\npulsar2.suddenlink.net" |
        fzf --prompt="Choose a jump server: " --preview="cat $HOME/.connections/{}"
    )
    if [[ -z "$jumpServer" ]]; then
        echo "No jump server selected"
        return 1
    fi
    local selection=$(printf "Connect\nChange entry\nDelete entry" | fzf --prompt="Choose an action: " --preview="cat $HOME/.connections/$jumpServer")
    case $selection in
        "Connect" )
            local selectionArray=(
                $(
                    awk '{ if ($1 != $2) print $1, $2; else print $1 }' "$HOME/.connections/$jumpServer" |
                    fzf --ansi --print-query --prompt="Connect to: " \
                    --preview="echo {} | awk '{print \$1}' | xargs dig " \
                    --header="To create a new entry, type the FQDN or IP address and press enter
Alternatively, you can enter a Nickname followed by an IP address"
                )
            )
            if [[ -z "${selectionArray[@]}" ]]; then
                echo "No entry selected"
                return 1
            fi
            if [[ "${#selectionArray[@]}" -eq 1 ]]; then
                local ip=${selectionArray[0]}
                local name=$ip
            elif [[ "${#selectionArray[@]}" -eq 2 ]]; then
                if [[ "${selectionArray[1]}" =~ "${selectionArray[0]}" ]]; then
                    local ip=${selectionArray[1]}
                    local name=${selectionArray[1]}
                else
                    local ip=${selectionArray[1]}
                    local name=${selectionArray[0]}
                fi
            elif [[ "${#selectionArray[@]}" -eq 3 ]]; then
                local ip=${selectionArray[2]}
                local name=${selectionArray[1]}
            else
                echo "Too many arguments given. The jump_ssh function only accepts 1 or 2 arguments"
                return 1
            fi
            jump_ssh "$jumpServer" "$ip" "$name"
            ;;
        "Change entry" )
            local entryArray=(
                $(
                    cat -p "$HOME/.connections/$jumpServer" |
                    fzf --ansi --prompt="Change entry: "
                )
            )
            if [[ -z "${entryArray[@]}" ]]; then
                echo "No entry selected"
                return 1
            fi
            local name=${entryArray[0]}
            local ip=${entryArray[1]}
            echo "Current entry: $name($ip)"
            echo "Enter new name (press enter to leave unchanged):"
            read newName
            if [[ -z "$newName" ]]; then
                newName=$name
            fi
            echo "Enter new IP (press enter to leave unchanged):"
            read newIp
            if [[ -z "$newIp" ]]; then
                newIp=$ip
            fi
            if [[ "$newName" == "$name" && "$newIp" == "$ip" ]]; then
                echo "No changes made"
            else
                sed -i "s/$name $ip/$newName $newIp/" "$HOME/.connections/$jumpServer"
                echo "Entry changed to $newName($newIp)"
            fi
            ;;
        "Delete entry" )
            local entryArray=(
                $(
                    cat -p "$HOME/.connections/$jumpServer" |
                    fzf --ansi --prompt="Delete entry: "
                )
            )
            if [[ -z "${entryArray[@]}" ]]; then
                echo "No entry selected"
                return 1
            fi
            local name=${entryArray[0]}
            local ip=${entryArray[1]}
            echo "Current entry: $name($ip)"
            echo "Are you sure you want to delete this entry?"
            select ync in "Yes" "No"; do
                case $ync in
                    Yes ) sed -i "/$name $ip/d" "$HOME/.connections/$jumpServer"; echo "Entry deleted"; break;;
                    No ) echo "Entry left alone"; break;;
                    * ) echo "Please answer 1 for Yes or 2 for No";;
                esac
            done
            ;;
    esac
}

PS1='\n\[\e[31m\]`nonzero_return`\[\e[32m\] \u@\h \[\e[35m\]\w\[\e[36m\]`__git_ps1`\e[0m\n$'
export EDITOR=nvim
export VISUAL=nvim
export SUDO_EDITOR=nvim
export BAT_THEME="OneHalfDark"
export XCURSOR_THEME="material_cursors"
export XCURSOR_SIZE="32"
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:/home/baky/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"
export PATH=$HOME/Downloads/Installers/interactively/bin/:$PATH:/usr/local/go/bin:$HOME/go/bin:/usr/local/Postman\ Agent/:$HOME/.local/lua-language-server/bin:~/android-studio/bin

# Flutter executables
export PATH="$HOME/development/flutter/bin:$PATH"

export FZF_DEFAULT_OPTS="
    --tmux 97%
    --walker-skip .git,node_modules,target,.local,.cache,.steam,.gradle,venv,.cache,sys,proc,.file,.npm,.dartserver,.mypy_cache
    --cycle
    --border
"
export FZF_ALT_C_OPTS="
    $FZF_DEFAULT_OPTS
    --preview 'tree -C {}'
"

# History across TMUX
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"


#if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
#  tm
#fi

[ -f $HOME/.fzf.bash ] && source $HOME/.fzf.bash

. "$HOME/.cargo/env"

eval "$(gh copilot alias -- bash)"
#
# Fix for tmux on openSuse with WSL2
export TMUX_TMPDIR='/tmp'
