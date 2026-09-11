TODO:

    remake idle-logout for xfce
    remake numlock-enable for xfce
    add a feature for the xfce panel layout config



Known Bugs:

    When guest logs in, they might see a black screen with an "evm" warning for 1-3  seconds. it does no harm, but might cause confusion





Miscellaneous:

    if you wanna add flatpaks, put this in containerfile:

    # Add Flathub
    RUN flatpak remote-add --system --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo

    RUN flatpak install --system --noninteractive flathub \
        org.kde.kate \
        org.mozilla.firefox

    I initially used flatpaks, thinking the containerized app model will be more secure, however, customizing them (eg. applying policies to firefox) becomes a lot more tricky, plus, flatpaks inflate the image size a lot more than RPMs. for now, RPMs are a lot more practical.