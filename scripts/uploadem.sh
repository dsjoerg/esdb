#!/bin/bash

# Usage: scripts/uploadem.sh <directory where tga files are located> <server>
#
# This script will upload all the tga files in a given directory to
# the given server.
#

find "$1" -name '*.tga' | while read name ; do
  echo "Seeing $name, uploading to $2"
  curl -F "image=@$name" "http://$2/api/v1/maps/image"
done
