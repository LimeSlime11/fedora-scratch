# ephemeral mount
this feature protects the users data, by mounting the session in an overlay partition
this means, the changes made while you're logged in, are real, and saved on disk, so the device wont run into issues if theres limited RAM, however, the changes are not saved the way that it looks to the user. 

if you save a text document on the desktop, the user sees it as being in /home/guest/Desktop/, but its actually saved in the mounted overlay as a difference.

this overlay is essentially recreated on every login, so every time anyone logs in on guest, the old overlay is destroyed, and a new overlay is created.

Code explanation:

preliminarily, we set variables and ensure that guest, is the user, that is logging in, otherwise, the script just ends early, so as not to meddle with admin accounts

first, we unmount the overlay from the user's environment, and then destroy it (if there is no existing environment, it just fails silently, and continues, i think. eitherway, it doesnt break)

second, we create two directories, one for the immutable part, and "upper" for the mutable part

third, we use a very specific command that pleases SELinux, who allows us to mount these as an overlay (i honestly dont understand it much, it mounts these, and makes specific statements that must not be touched) 

fourth, we set the permissions and ownership stuff, cause if guest cant get to edit its own overlay, what would be the point?