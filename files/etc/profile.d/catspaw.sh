# Catspaw OS shell layer. profile.d is sourced by plain sh as well as bash and
# everything below is bash-only, so bail out rather than spew into a dash login.
[ -n "${BASH_VERSION:-}" ] || return 0
case $- in *i*) ;; *) return 0 ;; esac

CATSPAW_DIR="${CATSPAW_DIR:-/usr/share/catspaw}"
export CATSPAW_DIR

# A user's own copy always wins over the image's.
if [ -r "$HOME/.config/catspaw/shell.sh" ]; then
    . "$HOME/.config/catspaw/shell.sh"
elif [ -r "$CATSPAW_DIR/shell.sh" ]; then
    . "$CATSPAW_DIR/shell.sh"
fi
if [ -r "$HOME/.config/catspaw/banner.sh" ]; then
    . "$HOME/.config/catspaw/banner.sh"
elif [ -r "$CATSPAW_DIR/banner.sh" ]; then
    . "$CATSPAW_DIR/banner.sh"
fi
command -v catspaw_banner >/dev/null 2>&1 && catspaw_banner
