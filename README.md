TODO:

adjustments to kde are in pinned-apps, gotta rename that. that file is copied from the vm with its customized configuration, because kde is confusing and this is the only working method ive found

if you wanna add flatpaks, put this in vontainerfile:
# Add Flathub
RUN flatpak remote-add --system --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

RUN flatpak install --system --noninteractive flathub \
    org.kde.kate \
    org.mozilla.firefox