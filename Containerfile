FROM quay.io/fedora/fedora-bootc:latest

# ==============================================================================
# STAGE 1: Core OS, Desktop Shell & Display Manager
#
# Weak dependencies are disabled to avoid pulling in unnecessary software.
# Essential runtime components are explicitly installed.
#
# XFCE is a modular desktop environment, so its individual components need to
# be installed explicitly.
# ==============================================================================

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf5 install -y \
        --setopt=install_weak_deps=False \

        # --- Display & Desktop Shell ---
        sddm \
        xfce4-session \
        xfce4-panel \
        xfce4-settings \
        xfdesktop \
        xfwm4 \

        # --- Panel & Desktop Integration ---
        xfce4-statusnotifier-plugin \
        xfce4-notifyd \
        libappindicator \
        dbus-x11 \

        # --- Networking ---
        network-manager-applet \
        avahi \

        # --- Audio ---
        pipewire \
        wireplumber \
        xfce4-pulseaudio-plugin \
        pavucontrol \

        # --- Printing ---
        cups \
        cups-client \
        system-config-printer \

        # --- Display & Desktop Integration ---
        xorg-x11-server-Xorg \
        xdg-desktop-portal \

        # --- Language & Input ---
        glibc-langpack-da \
        langpacks-da \
        pam \

        # --- User Session Utilities ---
        xautolock \
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

        # --- Web & Internet ---
        firefox \

        # --- Office & Documents ---
        libreoffice \
        libreoffice-langpack-da \
        libreoffice-help-da \
        hunspell-da \
        evince \

        # --- Media ---
        vlc \

        # --- File Management ---
        thunar \
        7zip \

        # --- Basic Utilities ---
        mousepad \
        galculator \

        # --- Image Viewing ---
        ristretto \

        # --- Terminal ---
        xfce4-terminal \

        # --- Fonts ---
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