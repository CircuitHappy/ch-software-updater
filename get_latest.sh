#! /bin/bash

release_ver=`wget -O- http://circuithappy.com/updates/missing-link/current.txt`
wget -O /tmp/missing-link-update.zip http://circuithappy.com/updates/missing-link/missing-link-update-$release_ver.zip
unzip /tmp/missing-link-update.zip
