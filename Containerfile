FROM quay.io/fedora/fedora-bootc:latest

# --setopt=install_weak_deps=False is used to avoid installing unnecessary packages that are not required for the desktop environment, which helps to keep the image size smaller.
# (things such as included games, fonts, and other packages that are not essential for the desktop environment)

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf5 install -y \
        plasma-desktop \
        sddm \
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

# login screen
RUN systemctl enable sddm.service

# Locale and keyboard
RUN ln -sf /usr/share/zoneinfo/Europe/Copenhagen /etc/localtime \
    && printf '%s\n' 'KEYMAP=dk' > /etc/vconsole.conf

# default user
RUN if ! id admin >/dev/null 2>&1; then \
        useradd --create-home --groups wheel --shell /bin/bash admin; \
    fi \
    && echo 'admin:admin' | chpasswd