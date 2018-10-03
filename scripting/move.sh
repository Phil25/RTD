#!/bin/bash

cd "$(dirname "$0")"

if [ $1 = "rtdtest.sp" ]; then
	sfile="rtdtest.sp"
else
	sfile="rtd.sp"
fi

smxfile="`echo "$sfile" | sed -e 's/\.sp$/\.smx/'`";

if [ ! -f "./compiled/$smxfile" ]; then
	echo "Plugin \"$smxfile\" not compiled.";
	exit 1;
fi

read -p "Server name(s): " servers;

if [[ $servers = "a" ]]; then
	servers="10x snow";
fi

shithappened=0;
destination=`cat ./compiled/destination`;
for server in $servers; do
	echo "Moving \"$smxfile\" to $server...";

	sshpass -f "./compiled/passfile" scp -r "../configs/rtd2_perks.default.cfg" "$destination:/home/steam/$server/tf/addons/sourcemod/configs/";
	sshpass -f "./compiled/passfile" scp -r "../translations/rtd2_perks.phrases.txt" "$destination:/home/steam/$server/tf/addons/sourcemod/translations/";
	sshpass -f "./compiled/passfile" scp -r "./compiled/$smxfile" "$destination:/home/steam/$server/tf/addons/sourcemod/plugins/";

	if [ $? -eq 0 ]; then
		shithappened=1;
	fi
done

if [ $shithappened -eq 0 ]; then
	echo "Invalid server name(s): \"$servers\".";
	exit 1;
fi

rm "./compiled/$smxfile";
