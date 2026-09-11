FROM quay.io/fedora/fedora-bootc:latest

# ==============================================================================
# STEP 1: Desktop Foundations
#
# Weak dependencies allowed so Fedora provides a complete desktop.
# ==============================================================================

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf5 install -y \
        sddm \
        xfce4-panel \
        network-manager-applet \
        xorg-x11-server-Xorg \
        pipewire \
        wireplumber \
        glibc-langpack-da \
        langpacks-da \
    && dnf5 clean all


# ==============================================================================
# STEP 2: Additional Utilities
#
# Weak dependencies disabled to avoid unnecessary extras.
# ==============================================================================

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf5 install -y \
        --setopt=install_weak_deps=False \
        xautolock \
        zenity \
    && dnf5 clean all


# ==============================================================================
# STEP 3: User Applications & Fonts
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
# STEP 4: Copy Feature Files
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
# STEP 5: Run Feature Installation Scripts
# ==============================================================================

RUN --mount=type=bind,source=features,target=/features \
    for script in /features/*/scripts/*.sh; do \
        [ -f "$script" ] || continue; \
        echo "Running feature script: $script"; \
        bash "$script"; \
    done


# ==============================================================================
# STEP 6: Enable Services & Set Permissions
# ==============================================================================

RUN chmod 755 /usr/local/bin/library-power-check.sh \
    && chmod 644 /etc/library-schedule.conf \
    && chmod 644 /etc/systemd/system/library-power.service \
    && systemctl enable library-power.service \
    && systemctl enable sddm.service