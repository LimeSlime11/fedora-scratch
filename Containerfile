FROM quay.io/fedora/fedora-bootc:latest

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf5 install -y \
        plasma-desktop \
        dolphin \
        sddm \
    && dnf5 clean all

RUN systemctl enable sddm.service