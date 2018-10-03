#!/bin/bash

if [ $1 == "rtdtest.sp" ]; then
	sfile="rtdtest.sp";
else
	sfile="rtd.sp";
fi

./compile.sh "$sfile"

cd "$(dirname "$0")"

smxfile="`echo "$sfile" | sed -e 's/\.sp$/\.smx/'`";

if [ ! -f "./compiled/$smxfile" ]; then
	echo "Plugin \"$smxfile\" not compiled.";
	exit 1;
fi

echo "Moving \"$smxfile\" to the testing server...";

destroot=`cat ./compiled/destination`;
sshpass -f "./compiled/passfile" scp -r "../configs/rtd2_perks.default.cfg" "$destroot:/home/steam/test/tf/addons/sourcemod/configs/"
sshpass -f "./compiled/passfile" scp -r "../translations/rtd2_perks.phrases.txt" "$destroot:/home/steam/test/tf/addons/sourcemod/translations/"
sshpass -f "./compiled/passfile" scp -r "./compiled/$smxfile" "$destroot:/home/steam/test/tf/addons/sourcemod/plugins/"

echo "Removing local \"$smxfile\"...";
rm "./compiled/$smxfile";
