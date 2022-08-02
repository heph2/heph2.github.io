#!/bin/sh
SERVER=kelpie
DIR=/var/www/pinkystudios.com/

hugo && rsync -avz --delete public/ ${SERVER}:${DIR}

exit 0
