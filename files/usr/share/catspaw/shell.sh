#!/usr/bin/env bash
# Catspaw OS shell layer: prompt + aliases. Sourced from .bashrc, interactive
# only. Disable the prompt with CATSPAW_PROMPT=0.

[[ $- == *i* ]] || return 0

# --- aliases --------------------------------------------------------------
alias ff='fastfetch -c "${CATSPAW_DIR:-/usr/share/catspaw}/fastfetch.jsonc"'
alias paw='cat "${CATSPAW_DIR:-/usr/share/catspaw}/logo-color.txt"'
alias catspaw='catspaw_banner --force'

# --- prompt ---------------------------------------------------------------
# Two lines: a status bar, then a bare input line, so a long path never eats
# the space you type into.
[[ ${CATSPAW_PROMPT:-1} == 0 ]] && return 0

_cs_git_branch() {
    # Walk up looking for .git in-process. Only shell out to git when there is
    # actually a repo here -- a git call on every prompt in $HOME is a fork for
    # nothing, and this box is a Steam Deck.
    local d=$PWD
    while [[ -n $d && $d != / ]]; do
        if [[ -e $d/.git ]]; then
            local b
            b=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return 0
            [[ -n $b ]] && printf ' \033[38;5;240m[\033[38;5;108m%s\033[38;5;240m]\033[0m' "$b"
            return 0
        fi
        d=${d%/*}
    done
}

_cs_set_prompt() {
    # $? here is useless: Bazzite's window-title printf already ran earlier in
    # PROMPT_COMMAND and left its own (always 0) status behind. The real exit
    # code is captured by the _CS_RC= stanza prepended below.
    local rc=${_CS_RC:-0}
    local Y='\[\033[38;5;214m\]' B='\[\033[1;38;5;220m\]' D='\[\033[38;5;240m\]'
    local W='\[\033[38;5;253m\]' R='\[\033[38;5;203m\]' X='\[\033[0m\]'
    local status=''
    (( rc != 0 )) && status="${D} ${R}✖ ${rc}${X}"
    # \[ \] must wrap every non-printing run or bash miscounts the line width
    # and long commands start overwriting the prompt.
    PS1="${Y}▌${X}${W}\u${D}@${W}\h${X} ${D}${X}${Y}\w${X}\$(_cs_git_branch)${status}\n${B} ▸ ${X}"
    PS2="${Y} … ${X}"
}

# Append rather than clobber: Bazzite already puts things in PROMPT_COMMAND
# (the container prefix among them) and replacing it breaks those.
# _CS_RC must come FIRST so it sees the command's real exit status, before any
# other PROMPT_COMMAND entry overwrites it.
case ";${PROMPT_COMMAND};" in
    *";_cs_set_prompt;"*) ;;
    *) PROMPT_COMMAND="_CS_RC=\$?${PROMPT_COMMAND:+;$PROMPT_COMMAND};_cs_set_prompt" ;;
esac
