this feature is responsible for what apps are pinned to the taskbar

the pinned-apps.conf file is the apps themselves, which couldve just been in the script itself, 
but instead is imported into it, for convenience of customisation. 
every separate line is one separate app, in their respective order.

the script targets a specific line in a specific file and replaces it with these apps.

the reason i do this instad of just baking in a premade file, is because
that file is a mess that is constantly changed by other scripts within kde itself.

theres no order, and certain lines wont even be in that file if certain features have been left default.

in GNOME, i couldve simply baked in a list of apps within a dedicated file for pinned apps, but KDE 
just doesnt do that. 

KDE is made for users to customize themselves, through graphical interfaces. its not very cooperative
when trying to customize an image. 

as im writing this, i actually do have that dynamic file baked in, at the KDE-layout feature, because i had
customized kde manually, then copied this file into subsequent builds. it works, but its not very maintainable.

anyway, the specifics of this feature are:

pinned-apps.conf = list of apps separated by line
append-apps.sh = reads .conf, then finds the appropriate line to copypaste these, into /etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc

the .conf uses the format required by plasma-org.kde.plasma.desktop-appletsrc,
as im writing this, the apps translate to:
system settings, preffered filemanager (dolphin), preffered browser (firefox), and a custom script shortcut for logout, i added in the logout-shortcut feature.