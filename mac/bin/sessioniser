#!/usr/bin/env zsh
# heavily inspired by https://github.com/ThePrimeagen/dev-prod-2/blob/main/tmux-sessionizer 

selected=$(find ~/dev/* -mindepth 1 -maxdepth 1 -type d | fzf)
selected_name=$selected:t

if [[ -z $selected ]]; then
    exit 0
fi


switch_to() {
    if [[ -z "$TMUX" ]]; then
        tmux attach-session -t=$1
    else
        tmux switch-client -t=$1
    fi
}

hydrate() {
    if [ -z $1/.tmux-ready ]; then
        return
    fi

    tmux send-keys -t $selected_name "./.tmux-ready" c-M
}

# no tmux currently running, or tmux running, just not in this terminal
if [[ -z "$TMUX" ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s $selected_name -c $selected_name
    exit 0
fi

if ! tmux has-session -t=$selected_name 2> /dev/null; then
    tmux new-session -ds $selected_name -c $selected_name
fi

switch_to $selected_name
hydrate $selected
