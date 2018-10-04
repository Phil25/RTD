#!/bin/bash -e
cd "$(dirname "$0")"

[[ $# -eq 0 ]] && exit 0

test -e compiled || mkdir compiled

if [ $1 = "rtdtest.sp" ]; then
	sfile="rtdtest.sp"
else
	sfile="rtd.sp"
fi

smxfile="`echo "$sfile" | sed -e 's/\.sp$/\.smx/'`";
./spcomp $sfile -ocompiled/$smxfile
