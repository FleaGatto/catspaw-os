# Catspaw OS — a Hyprland-first Bazzite image for the Steam Deck.
#
# Built on bazzite-deck-gnome so the GNOME session stays available as a
# fallback; Hyprland is the session this image is actually for.
# Default is the exact digest this was developed against, so a local build is
# reproducible. CI overrides it with :stable (see .github/workflows/build.yml)
# so the Sunday rebuild still tracks upstream Bazzite.
ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite-deck-gnome@sha256:20503f01477c554871c64307edfe29bb7c70468c055ad6ead239434bc5fae05a
FROM ${BASE_IMAGE}

# Everything that ends up on the filesystem verbatim: branding, skel configs,
# the Catspaw shaders, SoberStrap, the Pro Mic chain, first-boot services.
COPY files/ /
COPY build_files/ /tmp/build_files/

# The final step differs by base. `ostree container commit` is deprecated and
# fails outright on a bootc base with "Not in an ostree-based container
# environment"; `bootc container lint` is its replacement. BASE_IMAGE defaults
# to an older pinned digest for reproducible local builds while CI overrides it
# with :stable, so both have to work -- pick by what the base actually ships.
RUN --mount=type=cache,dst=/var/cache/libdnf5,sharing=locked \
    /tmp/build_files/build.sh && \
    rm -rf /tmp/build_files && \
    if command -v bootc >/dev/null 2>&1; then \
        bootc container lint; \
    else \
        ostree container commit; \
    fi
