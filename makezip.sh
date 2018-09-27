#!/bin/bash

# find the version
VERSION=`cat scripting/rtd.sp | grep PLUGIN_VERSION | head -n 1 | cut -d \" -f2`
FILENAME=rtd-$VERSION.zip

if [ -f $FILENAME ]; then
	echo "File $FILENAME exists!"
	exit
fi

# prepare compilation output directory
mkdir plugins

# compile current plugin
cd scripting
./spcomp rtd.sp -o ../plugins/rtd.smx
cd ..

# package it
zip -r $FILENAME plugins configs translations scripting/rtd.sp scripting/include/rtd2.inc scripting/rtd/*

# clean up
rm -r plugins
