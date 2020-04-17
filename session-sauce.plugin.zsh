#!/bin/bash

sess() {
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
    # Before switching, stash the current session so we can switch back later.
    local current_session=$(tmux display-message -p '#S')
    if [[ -n "$current_session" ]] ; then
        # Set a global tmux env var with the current session
        tmux set-environment -g SESS_LAST_SESSION "$current_session"
    fi
    # Attach to or switch to session
    tmux "$attach_cmd" -t "$1"
}

_sess_list_sessions() {
    tmux list-sessions -F "#{session_name}" 2>&1
}

_sess_split_name_from_dir() {
    xargs -I '{}' bash -c 'echo -e "{}\t$(basename {})"'
}

_sess_pick() {
    sort -k2 | uniq -i -f1 | fzf $2 --with-nth=2 -q "$1"
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
    # Kill the chosen session
    local sessions_and_dirs="$1"
    local sessions=$(echo "$session_and_dir" | cut -f2)
    if [[ -z "$sessions" ]]; then
        # no session chosen
        return 0
    fi
    echo "$sessions" | xargs -n1  tmux kill-session -t
    echo "$sessions" | xargs -n1 echo "Successfully killed"
}

_sess_usage() {
    cat >&2 <<EOF
Consult the README for the most comprehensive info:
https://github.com/ChrisPenner/session-sauce

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
    This should contain a list of ':' separated absolute paths to directories
    where you keep your projects.
    Projects in this directory will be used as options
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

$ sess -
Switch back to your previously accessed session.
Use this when quick-switching between two projects.

This command requires a running tmux server.
I recommend adding a tmux binding for this one; consult the README to see how.

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
Use tab to select multiple sessions.

An optional query can be provided to pre-fill the fzf window.

$ sess version
Display the currently installed version of sess.

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
        local session_and_dir=$(_sess_list_sessions | _sess_split_name_from_dir | _sess_pick "$2" "--multi")
        _sess_kill "$session_and_dir"
        ;;

    # version
    v*)
        echo "1.3.0"
        ;;

    # Quick switch back to last session
    '-')
        local last_session=$(tmux show-environment -g SESS_LAST_SESSION 2> /dev/null | sed "s:^.*=::")
        if [[ -z "$last_session" ]]; then
            echo "No session stashed. Try switching sessions first."
            return 1
        fi
        _sess_switch_session "$last_session"
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

        local session_and_dir=$( \
                (for root in $(tr ":" "\n" <<< "$SESS_PROJECT_ROOT"); do
                  ls -d "$root"/*
                done | _sess_split_name_from_dir; _sess_list_sessions) |
            _sess_pick "$2" --select-1)

        _sess_switch "$session_and_dir"
        ;;
esac


# If we're in zsh we can unbind these functions so we don't pollute the global
# namespace
if command -V unfunction >/dev/null 2>&1 ; then
    unfunction _sess_pick
    unfunction _sess_switch
    unfunction _sess_kill
    unfunction _sess_list_sessions
    unfunction _sess_switch_session
    unfunction _sess_ensure_session
    unfunction _sess_usage
fi
}
