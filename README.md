TODO:

    lock down KDE, so people cant customize and mess it up.

    remove shutdown/reboot/sleep from login screen and kde menus


Known Bugs:

    The favorited apps list on the kde context menu is empty, even though i've defined them in KDE-layout//kicker-extra-favoritesrc





Miscellaneous:

    if you wanna add flatpaks, put this in containerfile:

    # Add Flathub
    RUN flatpak remote-add --system --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo

    RUN flatpak install --system --noninteractive flathub \
        org.kde.kate \
        org.mozilla.firefox

    I initially used flatpaks, thinking the containerized app model will be more secure, however, customizing them (eg. applying policies to firefox) becomes a lot more tricky, plus, flatpaks inflate the image size a lot more than RPMs. for now, RPMs are a lot more practical.