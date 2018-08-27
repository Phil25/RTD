#!/bin/bash

./compile.sh "$1"

cd "$(dirname "$0")"

smxfile="`echo "$1" | sed -e 's/\.sp$/\.smx/'`";

if [ ! -f "./compiled/$smxfile" ]; then
	echo "Plugin \"$smxfile\" not compiled.";
	exit 1;
fi

echo "Moving \"$smxfile\" to the testing server...";
sshpass -f "./compiled/passfile" scp -r "./compiled/$smxfile" "`cat ./compiled/destination`:/home/steam/test/tf/addons/sourcemod/plugins/"

echo "Removing local \"$smxfile\"...";
rm "./compiled/$smxfile";
