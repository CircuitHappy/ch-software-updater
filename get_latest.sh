#! /bin/bash

set -x

warn () {
    echo "$0:" "$@" >&2
}
die () {
    rc=$1
    shift
    warn "$@"
    exit $rc
}

CH_ROOT="/ch"

release_ver=`wget -O- http://circuithappy.com/updates/missing-link/current.txt`
echo "release version:" $release_ver

if [ -d $CH_ROOT/${release_ver} ];
then
   die 1 "This system is at the latest version."
   #mv $CH_ROOT/${release_ver} $CH_ROOT/${release_ver}.`date +%s`
fi

wget -O /tmp/missing-link-update-$release_ver.zip http://circuithappy.com/updates/missing-link/missing-link-update-$release_ver.zip
if [ $? != 0 ]; 
then
   die 2 "wget returned a non 0 exit code trying to download missing-link-update-$release_ver.zip, bailing."
fi



#uncomment this after
wget -O /tmp/missing-link-update-$release_ver.zip.md5 http://circuithappy.com/updates/missing-link/missing-link-update-$release_ver.zip.md5
if [ $? != 0 ]; 
then
   die 2 "wget returned a non 0 exit code trying to download missing-link-update-$release_ver.zip.md5, bailing."
fi


# make md5 file like this
#[majer@prod ~]$ md5sum foozle.zip > foozle.zip.md5
#[majer@prod ~]$ cat foozle.zip.md5
#6749bb24f706bbd4141cba5ba1081e72  foozle.zip
#

expected_md5sum=`cat /tmp/missing-link-update-$release_ver.zip.md5 | awk '{print $1}'`

if [ "x${expected_md5sum}" = "x" ];
then
    die 3 "the md5sum from the server was missing or corrupt, bailing."
fi

actual_md5sum=`md5sum /tmp/missing-link-update-$release_ver.zip | awk '{print $1}'`

if [ ${expected_md5sum} != ${actual_md5sum} ];
then
   die 3 "the md5sum on the zip didn't match expected, bailing."
fi

unzip /tmp/missing-link-update-$release_ver.zip -d $CH_ROOT/ > /tmp/unzip.out 2>&1
if [ $? != 0 ]; 
then
   die 4 "unzip returned a non 0 exit code trying to extract the update (check /tmp/unzip.out), bailing."
fi

rm $CH_ROOT/current 
if [ $? != 0 ] && [ -L $CH_ROOT/current ];
then
    warn "this is bad, we couldn't remove the old current symlink "
fi


ln -s $CH_ROOT/$release_ver $CH_ROOT/current
if [ $? != 0 ] && [ ! -L $CH_ROOT/current ];
then
    die 5 "unable to relink things, your system may be unusable after a reboot."
fi
