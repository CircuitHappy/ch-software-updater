#! /bin/bash

release_ver=`curl http://circuithappy.com/updates/missing-link/current.txt`
echo "release version:" $release_ver
wget -O /tmp/missing-link-update.zip http://circuithappy.com/updates/missing-link/missing-link-update-$release_ver.zip
unzip /tmp/missing-link-update.zip
