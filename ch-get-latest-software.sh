#! /bin/bash
#debug mode
#set -x

warn () {
    /bin/echo "$0:" "$@" >&2
}
die () {
    rc=$1
    shift
    warn "$@"
    exit $rc
}

CH_ROOT="/ch"

release_ver=`/usr/bin/wget -O- http://circuithappy.com/updates/missing-link/current.txt`
/bin/echo "release version:" $release_ver

if [ -d $CH_ROOT/${release_ver} ];
then
   die 1 "This system is at the latest version."
fi

/usr/bin/wget -O /tmp/missing-link-update-$release_ver.zip http://circuithappy.com/updates/missing-link/missing-link-update-$release_ver.zip
if [ $? != 0 ]; 
then
   die 2 "wget returned a non 0 exit code trying to download missing-link-update-$release_ver.zip, bailing."
fi

/usr/bin/wget -O /tmp/missing-link-update-$release_ver.zip.md5 http://circuithappy.com/updates/missing-link/missing-link-update-$release_ver.zip.md5
if [ $? != 0 ]; 
then
   die 2 "wget returned a non 0 exit code trying to download missing-link-update-$release_ver.zip.md5, bailing."
fi

expected_md5sum=`/bin/cat /tmp/missing-link-update-$release_ver.zip.md5 | /usr/bin/awk '{print $1}'`

if [ "x${expected_md5sum}" = "x" ];
then
    die 3 "the md5sum from the server was missing or corrupt, bailing."
fi

actual_md5sum=`/usr/bin/md5sum /tmp/missing-link-update-$release_ver.zip | /usr/bin/awk '{print $1}'`

if [ ${expected_md5sum} != ${actual_md5sum} ];
then
   die 3 "the md5sum on the zip didn't match expected, bailing."
fi

/usr/bin/unzip /tmp/missing-link-update-$release_ver.zip -d $CH_ROOT/ > /tmp/unzip.out 2>&1
if [ $? != 0 ]; 
then
   die 4 "unzip returned a non 0 exit code trying to extract the update (check /tmp/unzip.out), bailing."
fi

/bin/rm $CH_ROOT/current 
if [ $? != 0 ] && [ -L $CH_ROOT/current ];
then
    warn "this is bad, we couldn't remove the old current symlink "
fi


/bin/ln -s $CH_ROOT/$release_ver $CH_ROOT/current
if [ $? != 0 ] && [ ! -L $CH_ROOT/current ];
then
    die 5 "unable to relink things, your system may be unusable after a reboot."
fi

/bin/echo $release_ver > $CH_ROOT/version.txt
if [ $? != 0 ]; 
then
   die 6 "Could not update version number file."
fi

if [ -f $CH_ROOT/${release_ver}/post.sh ];
then
   /bin/echo "I found post.sh."
   #$CH_ROOT/${release_ver}/post.sh
fi
