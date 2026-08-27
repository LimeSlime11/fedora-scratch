TODO:

firefox config doesnt work at all.

if you wanna add flatpaks, put this in vontainerfile:
# Add Flathub
RUN flatpak remote-add --system --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

RUN flatpak install --system --noninteractive flathub \
    org.kde.kate \
    org.mozilla.firefox