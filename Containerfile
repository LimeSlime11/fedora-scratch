FROM quay.io/fedora/fedora-bootc:latest

# ==============================================================================
# STAGE 1: Core OS, Desktop Shell & Display Manager
#
# Weak dependencies are disabled to avoid pulling in unnecessary software.
# Essential runtime components are explicitly installed.
# for xfce, this means i have to be more explicit, because xfce is a modular desktop environment.
# ==============================================================================

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf5 install -y \
        --setopt=install_weak_deps=False \
        sddm \
        xfce4-session \
        xfce4-panel \
        xfce4-settings \
        xfdesktop \
        xfwm4 \
        xfce4-statusnotifier-plugin \
        network-manager-applet 
        xorg-x11-server-Xorg \
        xdg-desktop-portal \
        libappindicator \
        dbus-x11 \
        xfce4-notifyd \
        pipewire \
        wireplumber \
        glibc-langpack-da \
        langpacks-da \
        xautolock \
        pam \
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
        evince \
        mousepad \
        thunar \
        xfce4-terminal \
        galculator \
        ristretto \
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

RUN chmod 755 /usr/local/bin/library-power-check.sh \
    && chmod 644 /etc/library-schedule.conf \
    && chmod 644 /etc/systemd/system/library-power.service \
    && systemctl enable library-power.service \
    && systemctl enable sddm.service