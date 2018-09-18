#!/bin/bash

./compile.sh "$1"

cd "$(dirname "$0")"

smxfile="`echo "$1" | sed -e 's/\.sp$/\.smx/'`";

if [ ! -f "./compiled/$smxfile" ]; then
	echo "Plugin \"$smxfile\" not compiled.";
	exit 1;
fi

echo "Moving \"$smxfile\" to the testing server...";

destroot=`cat ./compiled/destination`;
sshpass -f "./compiled/passfile" scp -r "./compiled/$smxfile" "$destroot:/home/steam/test/tf/addons/sourcemod/plugins/"
sshpass -f "./compiled/passfile" scp -r "../configs/rtd2_perks.default.cfg" "$destroot:/home/steam/test/tf/addons/sourcemod/configs/"
sshpass -f "./compiled/passfile" scp -r "../translations/rtd2_perks.phrases.txt" "$destroot:/home/steam/test/tf/addons/sourcemod/translations/"

echo "Removing local \"$smxfile\"...";
rm "./compiled/$smxfile";
