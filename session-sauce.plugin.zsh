#!/bin/bash

fzf_opts=(-1 -i)

# Dependencies: fzf & tmux

if ! command -V "fzf" 2>&1 >/dev/null ; then
    echo "sesh requires fzf, but couldn't find it on your path" >&2
    echo "Find installation instructions here: https://github.com/junegunn/fzf" >&2
    echo "Or 'brew install fzf' on a Mac" >&2
    return 1
fi

if ! command -V "tmux" 2>&1 >/dev/null ; then
    echo "sesh requires tmux, but couldn't find it on your path" >&2
    echo "Find installation instructions here: https://github.com/tmux/tmux" >&2
    echo "Or 'brew install tmux' on a Mac"
    return 1
fi

sess() {
if [[ -z "$TMUX" ]]; then
    attach_cmd=attach-session
else
    attach_cmd=switch-client
fi

_sess_ensure_session() {
    local session="$1"
    # Create new session
    # Fail silently if it already exists
    tmux new-session -d -s "$session" -c "cd $SESS_PROJECT_DIR/$session" >/dev/null 2>&1
}

_sess_switch_session() {
    # Attach to or switch to session
    tmux "$attach_cmd" -t "$1"
}

_sess_list_sessions() {
    tmux list-sessions -F "#{session_name}"
}


_sess_pick_and_switch() {
        # read list of sessions from stdin
        local session=$(sort | uniq | fzf "${fzf_opts[@]}")
        if [[ -z "$session" ]]; then
            # no session found
            return 0
        fi
        _sess_ensure_session "$session"
        _sess_switch_session "$session"
}

case "$1" in
    # Help
    -h*|help|--h*)
        echo Usage: >&2
        ;;
    # new
    n*)
        # Create if missing, otherwise join existing
        local session="$(basename "$(pwd)")"
        _sess_ensure_session "$session"
        _sess_switch_session "$session"
        ;;

    # list
    l*)
        _sess_list_sessions
        ;;

    # change/choose
    c*)
        _sess_list_sessions | _sess_pick_and_switch
        ;;

    # switch
    s*)
        if [[ -z "$SESS_PROJECT_DIR" ]]; then
            echo "Set your SESS_PROJECT_DIR environment variable" >&2
            echo "to allow searching for possible sessions" >&2
            return 1
        fi

        (ls "$SESS_PROJECT_DIR"; _sess_list_sessions) | _sess_pick_and_switch
        ;;
esac


# If we're in zsh we can unbind these functions so we don't pollute the global
# namespace
if command -V unfunction; then
    unfunction _sess_pick_and_switch
    unfunction _sess_list_sessions
    unfunction _sess_switch_session
    unfunction _sess_ensure_session
fi
}
