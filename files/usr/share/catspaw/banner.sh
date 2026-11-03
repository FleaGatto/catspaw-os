#!/usr/bin/env bash
# Catspaw OS login banner.
#
# Sourced from .bashrc, so it has to be defensive: anything printed by a
# NON-interactive shell corrupts scp/rsync/sftp and any script that sources
# this file. Every guard below exists for that reason.
#
#   CATSPAW_BANNER=0       disable entirely
#   CATSPAW_BANNER_MS=600  wall-clock budget in ms (default 450)
#   CATSPAW_BANNER_ONCE=0  animate in every shell, not just the first
#
# A login banner must never be able to hold a terminal hostage. Three things
# enforce that, and a timeout alone is not enough:
#   1. a wall-clock budget; past it the FINISHED frame is printed at once, so a
#      slow machine sees the same picture, just not drawn.
#   2. any keypress skips it instantly -- if you are typing, you want the shell,
#      not the cat.
#   3. it animates once per boot. The fifth terminal of the day gets one line.
#      Replaying an intro on every shell is the thing that made this unusable.
#
# catspaw_banner --force  replays it in full, ignoring 2 and 3.

catspaw_banner() {
    # System assets, unless this user keeps their own copy.
    local dir="${CATSPAW_DIR:-/usr/share/catspaw}"
    [[ -r $HOME/.config/catspaw/cat.txt ]] && dir="$HOME/.config/catspaw"
    local art="$dir/cat.txt"

    # --- guards -----------------------------------------------------------
    [[ $- == *i* ]]        || return 0   # interactive only
    [[ -t 1 ]]             || return 0   # stdout is a terminal
    [[ ${CATSPAW_BANNER:-1} != 0 ]] || return 0
    [[ $TERM == dumb || -z $TERM ]] && return 0
    [[ -r $art ]]          || return 0

    local cols=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}
    local force=0
    [[ $1 == --force ]] && force=1

    # Once per boot. XDG_RUNTIME_DIR is tmpfs, so the stamp clears on reboot
    # without anything having to tidy up after it.
    local stamp="${XDG_RUNTIME_DIR:-/tmp}/catspaw-banner.stamp"
    if (( ! force )) && [[ ${CATSPAW_BANNER_ONCE:-1} != 0 && -e $stamp ]]; then
        printf '\033[38;5;214m▌\033[1;38;5;220m catspaw os \033[0m\033[38;5;240m// operator ready\033[0m\n'
        return 0
    fi
    : > "$stamp" 2>/dev/null

    # --- clock ------------------------------------------------------------
    # EPOCHREALTIME parsed in-process: a fork per deadline check would cost far
    # more than the animation it is policing. The decimal separator is locale
    # dependent, hence the comma swap.
    local _CS_NOW=0 _CS_END=0 _CS_ABORT=0
    _cs_now() {
        local e=${EPOCHREALTIME/,/.} s f
        s=${e%.*}; f="${e#*.}000000"
        _CS_NOW=$(( s * 1000000 + 10#${f:0:6} ))
    }
    _cs_live() {                       # still inside budget and not cancelled?
        (( _CS_ABORT )) && return 1
        _cs_now
        (( _CS_NOW < _CS_END ))
    }
    _cs_now
    _CS_END=$(( _CS_NOW + ${CATSPAW_BANNER_MS:-450} * 1000 ))

    # The nap doubles as the skip key. Reading stdin with a timeout sleeps
    # without forking (the old trick, which used a dummy fd) AND returns early
    # the moment a key is pressed -- rc 0 means a keypress, so treat it as
    # "skip". rc 1 is EOF (non-tty stdin): no sleep, no abort, just run fast.
    _nap() {
        local _k
        IFS= read -rsn1 -t "$1" _k 2>/dev/null
        (( $? == 0 )) && _CS_ABORT=1
        return 0
    }

    _cs_done() {                       # always leave the terminal usable
        printf '\033[?25h'
        trap - INT
        unset -f _nap _cs_now _cs_live _cs_done
    }

    # Ctrl+C must actually cancel. The old handler restored the cursor and
    # removed itself but never exited, so bash resumed the loop and the banner
    # carried on regardless -- it looked like it could not be stopped.
    trap '_CS_ABORT=1' INT
    printf '\033[?25l'

    # --- cat, rainbowed with lolcat --------------------------------------
    local -a art_lines
    mapfile -t art_lines < "$art"
    local n=${#art_lines[@]} i
    if command -v lolcat >/dev/null 2>&1; then
        for ((i = 0; i < n; i++)); do
            if ! _cs_live; then        # dump whatever is left in one go
                printf '%s\n' "${art_lines[@]:i}" | lolcat -p 3 2>/dev/null \
                    || printf '%s\n' "${art_lines[@]:i}"
                break
            fi
            printf '%s\n' "${art_lines[i]}" | lolcat -p 3 2>/dev/null \
                || printf '%s\n' "${art_lines[i]}"
            _nap 0.012
        done
    else
        printf '%s\n' "${art_lines[@]}"
    fi

    # --- CATSPAW OS, revealed column by column ---------------------------
    local -a rows
    if (( cols >= 82 )); then
        rows=(
' ██████╗ █████╗ ████████╗███████╗██████╗  █████╗ ██╗    ██╗   ██████╗ ███████╗'
'██╔════╝██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██║    ██║  ██╔═══██╗██╔════╝'
'██║     ███████║   ██║   ███████╗██████╔╝███████║██║ █╗ ██║  ██║   ██║███████╗'
'██║     ██╔══██║   ██║   ╚════██║██╔═══╝ ██╔══██║██║███╗██║  ██║   ██║╚════██║'
'╚██████╗██║  ██║   ██║   ███████║██║     ██║  ██║╚███╔███╔╝  ╚██████╔╝███████║'
' ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝     ╚═╝  ╚═╝ ╚══╝╚══╝    ╚═════╝ ╚══════╝'
        )
    else
        rows=(
'╔═╗╔═╗╔╦╗╔═╗╔═╗╔═╗╦ ╦  ╔═╗╔═╗'
'║  ╠═╣ ║ ╚═╗╠═╝╠═╣║║║  ║ ║╚═╗'
'╚═╝╩ ╩ ╩ ╚═╝╩  ╩ ╩╚╩╝  ╚═╝╚═╝'
        )
    fi

    local h=${#rows[@]} maxlen=0 r
    for r in "${rows[@]}"; do (( ${#r} > maxlen )) && maxlen=${#r}; done

    printf '\n'
    for ((i = 0; i < h; i++)); do printf '\n'; done

    # _cs_paint draws the logo clipped to `c` columns; c >= maxlen is the
    # finished frame, which is what the give-up paths print.
    local c hue step=2
    _cs_paint() {
        printf '\033[%dA' "$h"
        local j
        for ((j = 0; j < h; j++)); do
            hue=$(( (j * 26 + $1 * 2) % 180 + 36 ))
            printf '\033[2K\033[38;5;%dm%s\033[0m\n' "$hue" "${rows[j]:0:$1}"
        done
    }
    for ((c = 1; c <= maxlen + step; c += step)); do
        if ! _cs_live; then
            _cs_paint "$maxlen"
            break
        fi
        _cs_paint "$c"
        _nap 0.010
    done
    unset -f _cs_paint

    # --- tagline, typed --------------------------------------------------
    local msg="  [ catspaw os // sub-system online // operator ready ]"
    printf '\n\033[38;5;213m'
    for ((i = 0; i < ${#msg}; i++)); do
        if ! _cs_live; then
            printf '%s' "${msg:i}"     # rest of the line at once
            break
        fi
        printf '%s' "${msg:i:1}"
        _nap 0.012
    done
    printf '\033[0m\n\n'

    _cs_done
}
