FROM quay.io/fedora/fedora-bootc:latest

RUN dnf5 install -y \
        @kde-desktop-environment \
    && dnf5 clean all