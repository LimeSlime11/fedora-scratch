FROM quay.io/fedora/fedora-bootc:latest

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf5 install -y \
        plasma-desktop \
        sddm \
        konsole \
        dolphin \
        flatpak \
    && dnf5 clean all

# Add Flathub
RUN flatpak remote-add --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

# Install Flatpaks
RUN flatpak install -y flathub \
    org.kde.kate \
    org.mozilla.firefox

RUN systemctl enable sddm.service