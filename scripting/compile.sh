#!/bin/bash -e
cd "$(dirname "$0")"

[[ $# -eq 0 ]] && exit 0

test -e compiled || mkdir compiled

smxfile="`echo "$1" | sed -e 's/\.sp$/\.smx/'`";
./spcomp $1 -ocompiled/$smxfile
