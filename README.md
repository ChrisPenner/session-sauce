# Session Sauce

Session Sauce exposes the `sess` command for quick and easy tmux session management.

[![asciicast](https://asciinema.org/a/tVPETaazkExhMjFH6RWdCmUSm.svg)](https://asciinema.org/a/tVPETaazkExhMjFH6RWdCmUSm)

It allows you as the user to stop caring about which sessions currently exist
by being declarative about which project you want to switch to. If a session
exists you'll be switched there. If it doesn't, it will be created, then you'll
be switched there, detaching any current session (if one exists).

`sess` also handles your `TMUX` context for you, opening a tmux client if you're
outside of one, and switching sessions of the current client if you're already
inside tmux. No more `sessions should be nested with care, unset $TMUX to force`
messages!

Note: All subcommand names can optionally be shortened to their first letter.
E.g. `sess s` is equivalent to `sess switch`

## Compatibility

session-sauce should work on most linux and mac machines, and works with most bash-compatible shells.

Installation options:

* copy-paste `session-sauce.plugin.zsh` onto your machine and source it from your shell's `rc` file. (E.g. `~/.bashrc` or `~/.zshrc`)
* Add to your zsh plugin manager as `ChrisPenner/session-sauce`

## Compatibility

Although the script has a `zsh` suffix it should be fully compatible with all shells that can interpret `bash`.

## Dependencies:

**fzf**:

Find installation instructions here: https://github.com/junegunn/fzf
Or `brew install fzf` on a Mac

**tmux**:

Find installation instructions here: https://github.com/tmux/tmux
Or `brew install tmux` on a Mac

## Configuration

- `SESS_PROJECT_ROOT`
    export this variable from your zshrc or bashrc file.
    This should contain a list of `:` separated absolute paths to directories
    where you keep your projects.
    Projects in this directory will be used as options
    for the `sess switch` command.

## Usage

### Smart session switch

```sh
$ sess switch [query]
```

Interactively select a session from a list of your project directories
(configured by `SESS_PROJECT_ROOT`) as well as all existing sessions.

This is the most versatile and useful command.
Running simply `sess` will be expanded to `sess switch`

An optional query can be provided to pre-fill the fzf window.
If there is only one match for the query the result
will be selected automatically.

### Explicitly create a new session

```sh
$ sess new [session-name]
```

Normally you'll just use `sess switch` to create sessions,
but `sess new` can be used to explicitly create new session
in the current directory.

This can be useful for creating sessions for projects
outside of `SESS_PROJECT_ROOT`.

If no session name is provided the directory name will be used

### List all active sessions

```sh
$ sess list
```

List all the active sessions.


### Choose an active session

```sh
$ sess choose [query]
```

Interactively select a session from a list of all active sessions.
Unlike 'sess switch' this does NOT include projects from `SESS_PROJECT_ROOT`.

An optional query can be provided to pre-fill the fzf window.
If there is only one match for the query the result
will be selected automatically.


### Kill an active session

```sh
$ sess kill [query]
```

Interactively select a session from a list of all active sessions to kill.

An optional query can be provided to pre-fill the fzf window.

### Version

```sh
$ sess version
```

Display the currently installed version of sess.

### Help
```sh
$ sess help
```

Displays this usage info.
