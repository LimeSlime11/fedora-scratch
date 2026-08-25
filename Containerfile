FROM quay.io/fedora/fedora-bootc:latest

# --setopt=install_weak_deps=False is used to avoid installing unnecessary packages that are not required for the desktop environment, which helps to keep the image size smaller.
# (things such as included games, fonts, and other packages that are not essential for the desktop environment)

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf5 install -y \
        --setopt=install_weak_deps=False \
        plasma-desktop \
        sddm \
        sddm-breeze \
        konsole \
        dolphin \
        flatpak \
    && dnf5 clean all

# Add Flathub
RUN flatpak remote-add --system --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

RUN flatpak install --system --noninteractive flathub \
    org.kde.kate \
    org.mozilla.firefox

# enable login manager
RUN systemctl enable sddm.service

# Copy system files from features to the root filesystem
COPY features/*/files/ /

# Run scripts from features
RUN --mount=type=bind,source=features,target=/features \
    for script in /features/*/scripts/*.sh; do \
        [ -f "$script" ] || continue; \
        bash "$script"; \
    done