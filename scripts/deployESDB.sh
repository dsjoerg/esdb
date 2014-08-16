#!/bin/bash

pushd /Users/david/Dropbox/Programming/ggtracker
ey web disable -e production_ggtracker
cd /Users/david/Dropbox/Programming/esdb/esdb
ey deploy -e production_esdb
cd /Users/david/Dropbox/Programming/ggtracker
ey web enable -e production_ggtracker
popd
