# prevent myself from overwriting stuff (missing trailing slash)
alias mv="mv -i"
alias cp="cp -iv"

alias kodolocal="awslocal --region ap-southeast-2"
alias dynamo="AWS_REGION=ap-southeast-2 DYNAMO_ENDPOINT=http://localhost:4566 npx dynamodb-admin --port 8009"

# use bat by default (syntax highlighting, git integration, ...)
alias cat='bat'

# use difftastic instead of diff
alias diff='difft'

# copy over kitty terminfo files when connecting via ssh
# https://sw.kovidgoyal.net/kitty/faq/#i-get-errors-about-the-terminal-being-unknown-or-opening-the-terminal-failing-or-functional-keys-like-arrow-keys-don-t-work
alias s="kitten ssh"

# MAC adress changer (free wifi hack)
# https://github.com/stefanjudis/dotfiles/blob/primary/config/oh-my-zsh/aliases.zsh
alias freewifi="sudo ifconfig en0 ether `openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//'`"

# Re-enable long press for Umlaute
alias umlaute="defaults write -g ApplePressAndHoldEnabled -bool true"

# Worktrunk
alias wtc='wt switch --create --execute=claude'
alias wtcc='wt switch --create --execute=cursor'
alias wtco='wt switch --create --execute=codex'
alias wts='wt switch'
alias wtr='wt remove'
