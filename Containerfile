FROM quay.io/fedora/fedora-bootc:latest

# ==============================================================================
# STAGE 1: Core OS, Desktop Shell & Display Manager
#
# Weak dependencies are disabled to avoid pulling in unnecessary software.
# Essential runtime components are explicitly installed.
# ==============================================================================

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf5 install -y \
        --setopt=install_weak_deps=False \
        sddm \
        sddm-breeze \
        plasma-desktop \
        plasma-workspace-wayland \
        kwin-wayland \
        kde-settings-plasma \
        xorg-x11-server-Xwayland \
        xdg-desktop-portal-kde \
        pipewire \
        wireplumber \
        glibc-langpack-da \
        langpacks-da \
        pam \
        swayidle \
        zenity \
    && dnf5 clean all


# ==============================================================================
# STAGE 2: User Applications & Fonts
#
# Weak dependencies remain disabled to keep the image minimal.
# ==============================================================================

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf5 install -y \
        --setopt=install_weak_deps=False \
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
        google-noto-sans-fonts \
        google-noto-serif-fonts \
        google-noto-color-emoji-fonts \
    && dnf5 clean all


# ==============================================================================
# STAGE 3: Copy Feature Files
#
# The feature directory structure mirrors the root filesystem:
#
# features/power-schedule/files/etc/...       -> /etc/...
# features/power-schedule/files/usr/...       -> /usr/...
#
# This also copies files from any other features in the repository.
# ==============================================================================

COPY --chown=root:root --chmod=755 features/*/files/ /


# ==============================================================================
# STAGE 4: Run Feature Installation Scripts
# ==============================================================================

RUN --mount=type=bind,source=features,target=/features \
    for script in /features/*/scripts/*.sh; do \
        [ -f "$script" ] || continue; \
        echo "Running feature script: $script"; \
        bash "$script"; \
    done


# ==============================================================================
# STAGE 5: Enable Services & Set Permissions
# ==============================================================================

RUN chmod 755 /usr/local/bin/apply-power-schedule.sh \
    && chmod 644 /etc/library-schedule.conf \
    && chmod 644 /etc/systemd/system/library-power.service \
    && systemctl enable library-power.service \
    && systemctl enable sddm.service