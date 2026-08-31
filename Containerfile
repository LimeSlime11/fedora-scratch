FROM quay.io/fedora/fedora-bootc:latest

# ==============================================================================
# STAGE 1: Core OS, Desktop Shell & Display Manager
# Weak dependencies DISABLED: prevents games, extra utilities, and bloat.
# Manually includes the 4 essential daemons (PipeWire, XWayland, Portals).
# ==============================================================================
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf5 install -y \
        --setopt=install_weak_deps=False \
        # Display Manager & Shell
        sddm \
        sddm-breeze \
        plasma-desktop \
        plasma-workspace-wayland \
        kwin-wayland \
        kde-settings-plasma \
        # MUST-HAVE Core Runtime Daemons (Manually specified since weak deps are OFF)
        xorg-x11-server-Xwayland \
        xdg-desktop-portal-kde \
        pipewire \
        wireplumber \
        # Language & Base System
        glibc-langpack-da \
        langpacks-da \
        pam \
    && dnf5 clean all

# ==============================================================================
# STAGE 2: User Applications & Fonts
# Weak dependencies DISABLED: prevents extra app extensions and unneeded extras.
# ==============================================================================
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf5 install -y \
        --setopt=install_weak_deps=False \
        # User Applications
        firefox \
        libreoffice \
        libreoffice-langpack-da \
        libreoffice-help-da \
        hunspell-da \
        vlc \
        okular \
        kate \
        dolphin \
        konsole \
        kcalc \
        gwenview \
        7zip \
        # Lightweight Fonts
        google-noto-sans-fonts \
        google-noto-serif-fonts \
        google-noto-color-emoji-fonts \
    && dnf5 clean all

# ==============================================================================
# STAGE 3: Custom Configuration & Script Injection
# ==============================================================================
COPY --chown=root:root --chmod=755 features/*/files/ /

RUN --mount=type=bind,source=features,target=/features \
    for script in /features/*/scripts/*.sh; do \
        [ -f "$script" ] || continue; \
        bash "$script"; \
    done