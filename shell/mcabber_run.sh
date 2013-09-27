#!/bin/sh

SCREEN_CMD=/usr/bin/screen

${SCREEN_CMD} -S me@elemc.name -d -m mcabber
${SCREEN_CMD} -S elemc@jabber.ru -d -m mcabber -f ~/.mcabber/mcabberrc_j.r
