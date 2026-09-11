TODO:

    add a feature for the xfce panel layout config



Known Bugs:

    When guest logs in, they might see a black screen with an "evm" warning for 1-3  seconds. it does no harm, but might cause confusion


Containerfile notes:
    step 1 installs a few packages, but with all of their critical and optional packages.
    this is because xfce is very modular. so if you only install the session manager and panel,
    youll be missing things like the network manager, volume control, bluetooth, printing, etc.
    in final production, itd make sense to go over XFCE4's dependencies and make a list of what we want.
    but for this prototype, just installing the DE with everything recommended will make everything a lot simpler,
    and way more readable.


Miscellaneous:

    if you wanna add flatpaks, put this in containerfile:

    # Add Flathub
    RUN flatpak remote-add --system --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo

    RUN flatpak install --system --noninteractive flathub \
        org.kde.kate \
        org.mozilla.firefox

    I initially used flatpaks, thinking the containerized app model will be more secure, however, customizing them (eg. applying policies to firefox) becomes a lot more tricky, plus, flatpaks inflate the image size a lot more than RPMs. for now, RPMs are a lot more practical.