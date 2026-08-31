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
        google-noto-fonts-all \
    && dnf5 clean all


# FIX 1: Make any copied files/scripts executable natively during the COPY step.
# This injects the files into the final image with correct permissions.
COPY --chmod=755 features/*/files/ /

# FIX 2: Removed the "RUN find / -type f..." command entirely.

# Run scripts from features (the bind mount stays read-only for the build process)
RUN --mount=type=bind,source=features,target=/features \
    for script in /features/*/scripts/*.sh; do \
        [ -f "$script" ] || continue; \
        bash "$script"; \
    done