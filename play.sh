#!/bin/bash

# Sylvain Ellenstein, DGSE, Ministère des Armées, Balard, Paris
# 2018-12-19
# TODO : mix two flows with -m

if [ $# -ne 1 ]
then
  echo "$0 flowfile"
	exit
fi

# Get the current size of the flowfile
# Does not work on macos : one or more spaces before the size
size=$(wc -c $1 | cut -d ' ' -f 1)

# Wait a few seconds
sleep 3

# Read the new data (appended to the file),
# starting from the calculated file size (which has grown, meanwhile).
# Pass G.711 data to sox and make it play on the default sound device
tail -c +$size -f $1 | sox --type raw --rate 8000 -e u-law - -d
