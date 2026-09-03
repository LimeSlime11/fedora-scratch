TODO:

    Scheduled sleep works, but if a guest was logged in when it kicks in, they remain logged in on wakeup. need to make the script force quit existing sessions if there are any, for safety.

Known Bugs:

    On first login, guest gets logged out on inactivity without the intended warning. subsequent logins get the warning as intended.

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