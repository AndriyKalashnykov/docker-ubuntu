alias ll='ls -alGFHh --color'
alias ls='ls -GFHh --color'
alias la='ls -Ah -color'
alias l='ls -CFh -color'
# sort by size recursively
alias lssr='du -ah . | grep -v "/$" | sort -rh'

#pbcopy & pbpaste aliases
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias pbcopypub='pbcopy < ~/.ssh/id_rsa.pub'

alias k=kubectl

