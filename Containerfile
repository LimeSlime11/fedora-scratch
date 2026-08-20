FROM quay.io/fedora/fedora-bootc:latest

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf5 install -y \
        @kde-desktop-environment \
    && dnf5 clean all