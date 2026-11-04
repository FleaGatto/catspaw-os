#!/usr/bin/bash
# Layer the Catspaw OS packages onto Bazzite.
set -ouex pipefail

### ------------------------------------------------------------- repos
# The Hyprland ecosystem beyond what Fedora ships, plus terminals and LACT.
# A COPR that has no Fedora 43 build must not take the whole image down.
# sdegler/hyprland, NOT solopasha/hyprland. solopasha has only a rawhide
# chroot, so enabling it silently did nothing and the mandatory hyprland
# install below then failed every CI run. sdegler ships fedora-43/44/45, which
# covers both the pinned base and :stable. pgdev/ghostty has no chroots at all
# and is dropped; ghostty stays in packages-extra.list, where --skip-unavailable
# reports it instead of killing the build.
for repo in sdegler/hyprland wezfurlong/wezterm-nightly ilyaz/LACT; do
    dnf5 -y copr enable "$repo" || echo "WARN: copr $repo unavailable, continuing"
done

### ------------------------------------------------- the Hyprland session
# These must all install: without them there is no desktop to boot into.
dnf5 -y install \
    hyprland hyprlock hypridle hyprpaper hyprpolkitagent hyprshot \
    xdg-desktop-portal-hyprland \
    waybar wofi SwayNotificationCenter \
    kitty grim slurp cliphist \
    brightnessctl playerctl pavucontrol blueman network-manager-applet

### ------------------------------------------------------------ extras
# --skip-unavailable: a package missing from a COPR is reported in the build
# log and skipped, rather than failing the image. Check the log after a build.
mapfile -t extras < <(grep -vE '^[[:space:]]*(#|$)' /usr/share/catspaw/packages-extra.list)
# --skip-unavailable goes AFTER the subcommand; dnf5 rejects it before. It
# covers a package that is missing, but NOT one that installs and then loses a
# file conflict -- that aborts the entire transaction and takes every other
# extra with it. Try the batch first because it is much faster, then fall back
# to one at a time so a single bad package is reported rather than fatal.
if ! dnf5 -y install --skip-unavailable "${extras[@]}"; then
    echo "WARN: batch install of extras failed; retrying individually"
    for pkg in "${extras[@]}"; do
        dnf5 -y install --skip-unavailable "$pkg" || echo "WARN: skipped $pkg"
    done
fi

### --------------------------------------------------------------- plasma
# A second, small desktop. See packages-kde.list for what is left out and why.
mapfile -t kde < <(grep -vE '^[[:space:]]*(#|$)' /usr/share/catspaw/packages-kde.list)
dnf5 -y install --skip-unavailable "${kde[@]}"

# COPRs stay out of the installed system: updates come from rebuilding.
for repo in sdegler/hyprland wezfurlong/wezterm-nightly ilyaz/LACT; do
    dnf5 -y copr disable "$repo" || true
done

### ------------------------------------------------------------- debloat
# One at a time, and never fatal: a package upstream already dropped must not
# take the build down. catspaw-verify reports what is actually gone.
mapfile -t unwanted < <(grep -vE '^[[:space:]]*(#|$)' /usr/share/catspaw/packages-remove.list)
for pkg in "${unwanted[@]}"; do
    dnf5 -y remove "$pkg" || echo "WARN: could not remove $pkg (already absent?)"
done

### ---------------------------------------------------------- branding
# ID is changed to catspaw by choice. ID_LIKE keeps bazzite and fedora so that
# anything matching on ID_LIKE -- which is most things that matter -- still
# resolves; only code hardcoding ID=bazzite can be surprised.
sed -i \
    -e 's/^NAME=.*/NAME="Catspaw OS"/' \
    -e 's/^PRETTY_NAME=.*/PRETTY_NAME="Catspaw OS"/' \
    -e 's/^VARIANT=.*/VARIANT="Catspaw"/' \
    -e 's/^VARIANT_ID=.*/VARIANT_ID=catspaw/' \
    -e 's|^ID=.*|ID=catspaw|' \
    -e 's|^LOGO=.*|LOGO=catspaw-logo|' \
    -e 's|^HOME_URL=.*|HOME_URL="https://github.com/FleaGatto/catspaw-os"|' \
    -e 's|^BUG_REPORT_URL=.*|BUG_REPORT_URL="https://github.com/FleaGatto/catspaw-os/issues"|' \
    /usr/lib/os-release
grep -q '^ID_LIKE=' /usr/lib/os-release \
    && sed -i 's|^ID_LIKE=.*|ID_LIKE="bazzite fedora"|' /usr/lib/os-release \
    || echo 'ID_LIKE="bazzite fedora"' >> /usr/lib/os-release
echo 'CATSPAW_OS=1' >> /usr/lib/os-release

cat > /etc/issue <<'ISSUE'

  Catspaw OS  \n \l

ISSUE

### ------------------------------------------------------------- plymouth
# NOTE: plymouth reads its theme from the initramfs, which on an ostree image is
# prebuilt. Setting the default here is necessary but may not be sufficient --
# if the splash still looks stock after rebasing, the initramfs needs
# regenerating on the deployed system:
#     sudo rpm-ostree initramfs --enable
plymouth-set-default-theme catspaw || echo "WARN: could not set plymouth theme"

### ------------------------------------------------------------ services
systemctl enable catspaw-flatpaks.service
# /etc/skel only applies to accounts created after it exists, and nobody
# creates an account when they rebase -- so without this the shipped Hyprland
# config never reaches an existing user. See the unit for the ordering.
systemctl enable catspaw-skel.service

### ------------------------------------------------------------ cleanup
dnf5 clean all
