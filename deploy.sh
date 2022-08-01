#!/bin/sh
SERVER=sea
DIR=/var/www/pinkystudios.com/

hugo && rsync -avz --delete public/ ${SERVER}:${DIR}

exit 0
