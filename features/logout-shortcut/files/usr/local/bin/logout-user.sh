#!/bin/bash

if zenity --question \
    --title="Log ud" \
    --text="Vil du logge ud?" \
    --ok-label="Log ud" \
    --cancel-label="Annuller"
then
    loginctl terminate-user "$USER"
fi