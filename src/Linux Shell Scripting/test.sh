#!/bin/bash

if [ "$(cut -d ':' -f 1 /etc/group | grep "$1")" = "" ]; then

	echo "el grupo $1 no existe"
fi
