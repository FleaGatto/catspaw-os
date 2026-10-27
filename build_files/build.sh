#!/usr/bin/bash
# Layer the Catspaw OS packages onto Bazzite.
set -ouex pipefail

### ------------------------------------------------------------- repos
# The Hyprland ecosystem beyond what Fedora ships, plus terminals and LACT.
# A COPR that has no Fedora 43 build must not take the whole image down.
for repo in solopasha/hyprland pgdev/ghostty wezfurlong/wezterm-nightly ilyaz/LACT; do
    dnf5 -y copr enable "$repo" || echo "WARN: copr $repo unavailable, continuing"
done

### ------------------------------------------------- the Hyprland session
# These must all install: without them there is no desktop to boot into.
dnf5 -y install \
    hyprland hyprlock hypridle hyprpaper hyprpolkitagent hyprshot \
    xdg-desktop-portal-hyprland \
    waybar wofi SwayNotificationCenter \
    kitty grim slurp cliphist \
    brightnessctl playerctl pavucontrol blueman network-manager-applet \
    java-21-openjdk-devel

### ------------------------------------------------------------ extras
# --skip-unavailable: a package missing from a COPR is reported in the build
# log and skipped, rather than failing the image. Check the log after a build.
mapfile -t extras < <(grep -vE '^[[:space:]]*(#|$)' /usr/share/catspaw/packages-extra.list)
dnf5 -y --skip-unavailable install "${extras[@]}"

# COPRs stay out of the installed system: updates come from rebuilding.
for repo in solopasha/hyprland pgdev/ghostty wezfurlong/wezterm-nightly ilyaz/LACT; do
    dnf5 -y copr disable "$repo" || true
done

### ---------------------------------------------------------- branding
sed -i \
    -e 's/^NAME=.*/NAME="Catspaw OS"/' \
    -e 's/^PRETTY_NAME=.*/PRETTY_NAME="Catspaw OS"/' \
    -e 's/^VARIANT=.*/VARIANT="Catspaw"/' \
    -e 's/^VARIANT_ID=.*/VARIANT_ID=catspaw/' \
    /usr/lib/os-release
echo 'CATSPAW_OS=1' >> /usr/lib/os-release

### ------------------------------------------------------------ services
systemctl enable catspaw-flatpaks.service

### ------------------------------------------------------------ cleanup
dnf5 clean all
