FROM quay.io/fedora/fedora-bootc:latest

# --setopt=install_weak_deps=False is used to avoid installing unnecessary packages that are not required for the desktop environment, which helps to keep the image size smaller.
# (things such as included games, fonts, and other packages that are not essential for the desktop environment)

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf5 install -y \
        --setopt=install_weak_deps=False \
        plasma-desktop \
        sddm \
        sddm-breeze \
        glibc-langpack-da \
        langpacks-da \
        konsole \
        dolphin \
        firefox \
        kate \
        gwenview \
        okular \
        vlc \
        7zip \
        libreoffice \
        libreoffice-langpack-da \
        libreoffice-help-da \
        hunspell-da \
        kcalc \
        google-noto-fonts \
    && dnf5 clean all


# Copy system files from features to the root filesystem
COPY features/*/files/ /

# make system file scripts executable (different from the feature scripts, which are run in the next step)
RUN find / -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null || true

# Run scripts from features
RUN --mount=type=bind,source=features,target=/features \
    for script in /features/*/scripts/*.sh; do \
        [ -f "$script" ] || continue; \
        bash "$script"; \
    done