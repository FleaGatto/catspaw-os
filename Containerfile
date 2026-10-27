# Catspaw OS — a Hyprland-first Bazzite image for the Steam Deck.
#
# Built on bazzite-deck-gnome so the GNOME session stays available as a
# fallback; Hyprland is the session this image is actually for.
FROM ghcr.io/ublue-os/bazzite-deck-gnome:stable

# Everything that ends up on the filesystem verbatim: branding, skel configs,
# the Catspaw shaders, SoberStrap, the Pro Mic chain, first-boot services.
COPY files/ /
COPY build_files/ /tmp/build_files/

RUN --mount=type=cache,dst=/var/cache/libdnf5,sharing=locked \
    /tmp/build_files/build.sh && \
    rm -rf /tmp/build_files && \
    ostree container commit
