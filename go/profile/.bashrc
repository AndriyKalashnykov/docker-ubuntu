# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# set -x

export GPG_TTY=$(tty)

source /etc/os-release

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

export TERM=xterm-256color
# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
# if [ -x /usr/bin/dircolors ]; then
#     test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
#     alias ls='ls --color=auto'
#     #alias dir='dir --color=auto'
#     #alias vdir='vdir --color=auto'

#     alias grep='grep --color=auto'
#     alias fgrep='fgrep --color=auto'
#     alias egrep='egrep --color=auto'
# fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'


# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

####################################################

## remove ssh-agent
SSHAGENT=`which ssh-agent`
SSHAGENTARGS="-s"
if [ -z "$SSH_AUTH_SOCK" -a -x "$SSHAGENT" ]; then
    eval `$SSHAGENT $SSHAGENTARGS`
    # trap "kill $SSH_AGENT_PID" 0
fi
## in .logout
if [ "${SSH_AGENT_PID+1}" == 1 ]; then
    ssh-add -D
    ssh-agent -k > /dev/null 2>&1
    unset SSH_AGENT_PID
    unset SSH_AUTH_SOCK
fi

# add passwordless ~/.ssh/id_rsa 
if [ -z "$SSH_AUTH_SOCK" ] ; then
  eval `ssh-agent -s`
  ssh-add ~/.ssh/id_rsa
fi

# https://github.com/ahmetb/kubectl-aliases
[ -f ~/.kubectl-aliases/.kubectl_aliases ] && source ~/.kubectl-aliases/.kubectl_aliases

# kubectl autocomplete
source <(kubectl completion bash)
complete -F __start_kubectl k

export GID=$(id -g)

# export KUBECONFIG=~/.kube/config:$HOME/projects/k8s-mac/kubeconfig-akalashnykov-cluster.yml

export CLICOLOR=1
#export LSCOLORS="EHfxcxdxBxegecabagacad"
# export LSCOLORS=gxfxbEaEBxxEhEhBaDaCaD
# LS_COLORS=$LS_COLORS:'ow=6;96:tw=2;35:di=2;35' ; export LS_COLORS

c_cyan=$(tput setaf 6)
c_sgr0=$(tput sgr0)
GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWCOLORHINTS=true
#GIT_PROMPT_THEME=Single_line_Dark
GIT_PROMPT_THEME=Single_line_username_repo

source /etc/profile.d/bash_completion.sh

if [ -f "$HOME/.bash-git-prompt/gitprompt.sh" ]; then
    GIT_PROMPT_ONLY_IN_REPO=1
    source $HOME/.bash-git-prompt/gitprompt.sh
fi
# export PS1='[\033[32m\]\u@\h\[\033[00m]:[${c_sgr0}\w]${c_cyan}\033[00m\]$ '
####################################################

# eval `dircolors $HOME/.dir_colors`
# test -r $HOME/.dir_colors && eval "$(dircolors -b $HOME/.dir_colors)" || eval "$(dircolors -b)"

export LS_COLORS="$(vivid generate snazzy)"

########################################################## Docker ########################################################## 

# eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
# unalias kp

# GPG 
# gpg --list-secret-keys --keyid-format=long
# git config --global user.signingkey D1FAA03AF6F5F048
# git config --global commit.gpgsign true

# debug GPG
# gpg --version
# echo "test" | gpg --clearsign
# gpg --status-fd=2 -bsau D1FAA03AF6F5F048

# echo $GITHUB_PAT | docker login ghcr.io -u andriykalashnykov --password-stdin
# export DOCKER_LOGIN= # DOCKERHUB_USERNAME
# export DOCKER_PWD_ACCT=
# export DOCKER_PWD= #DOCKERHUB_TOKEN
# export DOCKER_REGISTRY=registry-1.docker.io

# ignore vendor
export GOFLAGS=-mod=mod
