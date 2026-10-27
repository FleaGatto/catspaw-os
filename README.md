# Catspaw OS

A Hyprland-first [Bazzite](https://bazzite.gg) image for the Steam Deck, built
from `bazzite-deck-gnome`. The GNOME session stays installed as a fallback;
Hyprland is the session this image exists for.

## What's in it

**The session** — hyprland, hyprlock, hypridle, hyprpaper, hyprpolkitagent,
hyprshot, xdg-desktop-portal-hyprland, waybar, wofi, SwayNotificationCenter,
kitty, grim/slurp, cliphist, brightnessctl, playerctl, pavucontrol, blueman,
nm-applet.

**The rice** — the Forest Dusk configs ship in `/etc/skel`, so a new account
comes up already riced: hypr, waybar, wofi, swaync, kitty, ghostty, wezterm,
yazi, btop, starship, fastfetch, swappy, Kvantum, qt5ct/qt6ct, nwg-dock,
quickshell, ags, MangoHud, vkBasalt, plus the `powermenu` / `wallpaper` /
`osd` / `window-switcher` / `settings` helper scripts in `~/.local/bin`.

**Extras** — see `files/usr/share/catspaw/packages-extra.list`. These install
with `--skip-unavailable`, because a few come from COPRs that can lag a Fedora
release. `catspaw-verify` reports anything that didn't make it in, and CI runs
it on every build.

**Catspaw tooling**

| Command | What it does |
|---|---|
| `catspaw-roblox <look>` | Roblox under gamescope with a Catspaw ReShade effect |
| `catspaw-shade` | vkBasalt looks for native Vulkan games |
| `sober-strap` | SoberStrap: FastFlag profiles, launch modes, shader picker |

The shaders live in `/usr/share/gamescope/reshade/Shaders`, where gamescope
looks by default. `catspaw-roblox` uses gamescope rather than vkBasalt on
purpose: vkBasalt's instance hook and Sober's Android-surface translation can't
coexist, and Sober exits at renderer init when both are loaded.

**Pro Mic** — a PipeWire filter chain (RNNoise → gate → EQ → compressor) that
publishes a processed "Pro Mic" source. Harmless if the mic isn't attached.

**Apps** — 27 flatpaks install on first boot via `catspaw-flatpaks.service`,
listed in `files/usr/share/catspaw/flatpaks.list`. No browser is included: on
first login `catspaw-browser-picker` asks which one you want.

## Rebasing to it

```sh
sudo bootc switch ghcr.io/fleagatto/catspaw-os:latest
systemctl reboot
```

From an older rpm-ostree setup:

```sh
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/fleagatto/catspaw-os:latest
```

The image is unsigned for now, hence `unverified`. Rolling back is
`sudo bootc rollback`, or pick the previous deployment in the boot menu.

## Building locally

```sh
podman build -t catspaw-os .
podman run --rm catspaw-os /usr/libexec/catspaw-verify
```

## Not included

- **Fleasion** — deliberately left out.
- **cloudflare-warp** — needs Cloudflare's own repo; add it to `build.sh` if
  you want it back.
- A **live ISO** — planned via Titanoboa so the USB boots into Hyprland rather
  than a plain installer. Not wired up yet.
