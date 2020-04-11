#!/bin/bash

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
    local attach_cmd=attach-session
else
    local attach_cmd=switch-client
fi

_sess_ensure_session() {
    local session="$1"
    local dir="$2"
    # Create new session
    # Fail silently if it already exists
    tmux new-session -d -s "$session" -c "$dir" >/dev/null 2>&1
}

_sess_switch_session() {
    # Attach to or switch to session
    tmux "$attach_cmd" -t "$1"
}

_sess_list_sessions() {
    tmux list-sessions -F "#{session_name}"
}

_sess_split_name_from_dir() {
    xargs -I '{}' bash -c 'echo -e "{}\t$(basename {})"'
}


_sess_pick() {
    sort -k2 | uniq -i -f1 | fzf $2 --no-multi --with-nth=2 -q "$1"
}

_sess_switch() {
    # Switch to a chosen session
    local session_and_dir="$1"
    if [[ -z "$session_and_dir" ]]; then
        # no session chosen
        return 0
    fi
    local dir=$(echo "$session_and_dir" | cut -f1)
    local session=$(echo "$session_and_dir" | cut -f2)
    _sess_ensure_session "$session" "$dir"
    _sess_switch_session "$session"
}

_sess_kill() {
    # Switch to a chosen session
    local session_and_dir="$1"
    local session=$(echo "$session_and_dir" | cut -f2)
    if [[ -z "$session" ]]; then
        # no session chosen
        return 0
    fi
    tmux kill-session -t "$session"
    echo "Successfully killed '$session'"
}

_sess_usage() {
    cat >&2 <<EOF
'sess' is a layer on top of tmux and fzf which provides quick switching and
creation of tmux sessions.

It allows you as the user to not care about which sessions currently exist
by simply asserting that you wish to switch to a given project, if a session
exists you'll be switched there. If it doesn't, it will be created, then you'll
be switched there.

'sess' also handles your TMUX context for you, opening a tmux client if you're
outside of one, and switching sessions of the current client if you're already
inside tmux.

Note: All subcommand names can optionally be shortened to their first letter.
E.g. 'sess s' is equivalent to 'sess switch'

Dependencies:

- fzf
    Find installation instructions here: https://github.com/junegunn/fzf
    Or 'brew install fzf' on a Mac

- tmux
    Find installation instructions here: https://github.com/tmux/tmux
    Or 'brew install tmux' on a Mac

Configuration:

- SESS_PROJECT_ROOT
    export this variable from your zshrc or bashrc file.
    This should be an absolute path to the directory where you keep your
    projects. Projects in this directory will be used as options
    for the 'sess switch' command.

Usage:

$ sess switch [query]
Interactively select a session from a list of your project directories
(configured by SESS_PROJECT_ROOT) as well as all existing sessions.

This is the most versatile and useful command.
Running simply 'sess' will be expanded to 'sess switch'

An optional query can be provided to pre-fill the fzf window.
If there is only one match for the query the result
will be selected automatically.

$ sess new [session-name]
Normally you'll just use 'sess switch' to create sessions,
but 'sess new' can be used to explicitly create new session 
in the current directory.

This can be useful for creating sessions for projects 
outside of SESS_PROJECT_ROOT.

If no session name is provided the directory name will be used

$ sess list
List all active sessions

$ sess choose [query]
Interactively select a session from a list of all active sessions.
Unlike 'sess switch' this does NOT include projects from SESS_PROJECT_ROOT.

An optional query can be provided to pre-fill the fzf window.
If there is only one match for the query the result
will be selected automatically.

$ sess kill [query]
Interactively select a session from a list of all active sessions to kill.

An optional query can be provided to pre-fill the fzf window.

$ sess help
Displays this usage info.
EOF
}

case "$1" in
    # Help
    -h*|help|--h*)
      _sess_usage
        ;;
    # new
    n*)
        # Create if missing, otherwise join existing
        local dir="$(pwd)"
        local session="$(basename "$dir")"
        _sess_ensure_session "$session" "$dir"
        _sess_switch_session "$session"
        ;;

    # list
    l*)
        _sess_list_sessions
        ;;

    # change/choose
    c*)
        local session_and_dir=$(_sess_list_sessions | _sess_split_name_from_dir | _sess_pick "$2" -1)
        _sess_switch "$session_and_dir"
        ;;

    # kill
    k*)
        local session_and_dir=$(_sess_list_sessions | _sess_split_name_from_dir | _sess_pick "$2")
        _sess_kill "$session_and_dir"
        ;;

    # switch
    *)
        if [[ -z "$SESS_PROJECT_ROOT" ]]; then
            echo "The default 'sess' command uses the SESS_PROJECT_ROOT environment variable" >&2
            echo "to discover your projects. Set this in your shell's rc file." >&2
            echo "E.g. 'export SESS_PROJECT_ROOT=~/projects'" >&2
            echo >&2
            echo "Run 'sess help' for more information" >&2
            return 1
        fi

        local session_and_dir=$( (ls -d "$SESS_PROJECT_ROOT"/* | _sess_split_name_from_dir; _sess_list_sessions) | _sess_pick "$2" -1)
        _sess_switch "$session_and_dir"
        ;;
esac


# If we're in zsh we can unbind these functions so we don't pollute the global
# namespace
if command -V unfunction 2>&1 >/dev/null ; then
    unfunction _sess_pick
    unfunction _sess_switch
    unfunction _sess_kill
    unfunction _sess_list_sessions
    unfunction _sess_switch_session
    unfunction _sess_ensure_session
    unfunction _sess_usage
fi
}
