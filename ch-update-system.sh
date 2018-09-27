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

if [ ! -z "$1" ]
then
  release_server_root=$1
fi

current_txt_url=$release_server_root/current-system.txt

# check if current.txt exists, then wget to pick up the current release version
if `/usr/bin/wget -q $current_txt_url -O /tmp/current-system.txt`
then
  release_ver=`cat /tmp/current-system.txt`
  /bin/echo "system version:" $release_ver
else
  die 2 "Could not find a system release version file here: $current_txt_url, bailing."
fi

if [ -z $release_ver ]
then
  die 2 "failed to get valid system release version, probably could not download current-system.txt, bailing."
fi

current_ln_path=`readlink -f /ch/system/current`
/bin/echo "/ch/system/current links to:" $current_ln_path

# is the current release version already installed?
if [ -d $CH_ROOT/system/${release_ver} ]
then
  release_directory_exists=true
else
  release_directory_exists=false
fi

# if the current release is already installed and "current" is already linked to it, exit now
if [ $release_directory_exists = true ] && [ $CH_ROOT/system/${release_ver} -ef $current_ln_path ];
  then
   if [ -f $CH_ROOT/system/${release_ver}/post.sh ];
   then
     /bin/echo "post.sh script found. running it."
     /bin/sh $CH_ROOT/system/${release_ver}/post.sh
     /bin/rm $CH_ROOT/system/${release_ver}/post.sh
   fi

   die 1 "This system is at the latest version."
   #mv $CH_ROOT/${release_ver} $CH_ROOT/${release_ver}.`date +%s`
fi

# if the release directory doesn't exist, then download and install
if [ $release_directory_exists = false ]
then
  /usr/bin/wget -O /tmp/missing-link-system-$release_ver.zip $release_server_root/missing-link-system-$release_ver.zip
  if [ $? != 0 ];
  then
     die 2 "wget returned a non 0 exit code trying to download missing-link-system-$release_ver.zip, bailing."
  fi

  /usr/bin/wget -O /tmp/missing-link-system-$release_ver.zip.md5 $release_server_root/missing-link-system-$release_ver.zip.md5
  if [ $? != 0 ];
  then
     die 2 "wget returned a non 0 exit code trying to download missing-link-system-$release_ver.zip.md5, bailing."
  fi

  # make md5 file like this
  #[majer@prod ~]$ md5sum foozle.zip > foozle.zip.md5
  #[majer@prod ~]$ cat foozle.zip.md5
  #6749bb24f706bbd4141cba5ba1081e72  foozle.zip
  #

  expected_md5sum=`/bin/cat /tmp/missing-link-system-$release_ver.zip.md5 | /usr/bin/awk '{print $1}'`

  if [ "x${expected_md5sum}" = "x" ];
  then
      die 3 "the md5sum from the server was missing or corrupt, bailing."
  fi

  actual_md5sum=`/usr/bin/md5sum /tmp/missing-link-system-$release_ver.zip | /usr/bin/awk '{print $1}'`

  if [ ${expected_md5sum} != ${actual_md5sum} ];
  then
     die 3 "the md5sum on the zip didn't match expected, bailing."
  fi

  /usr/bin/unzip /tmp/missing-link-system-$release_ver.zip -d $CH_ROOT/system/ > /tmp/unzip.out 2>&1
  if [ $? != 0 ];
  then
     die 4 "unzip returned a non 0 exit code trying to extract the update (check /tmp/unzip.out), bailing."
  fi
# release directory already exists
else
  # if "current" is pointing at another directory but current release is already installed
  # then we just need to relink the symlink to the current release directory
  /bin/echo "Release directory already exists. Relinking that:" $CH_ROOT/system/${release_ver}
fi

/bin/rm $CH_ROOT/system/current
if [ $? != 0 ] && [ -L $CH_ROOT/system/current ];
then
    warn "this is bad, we couldn't remove the old current symlink "
fi


/bin/ln -s $CH_ROOT/system/$release_ver $CH_ROOT/system/current
if [ $? != 0 ] && [ ! -L $CH_ROOT/system/current ];
then
    die 5 "unable to relink things, your system may be unusable after a reboot."
fi

#/bin/echo $release_ver > $CH_ROOT/version.txt
/bin/cp /tmp/current-system.txt $CH_ROOT/system-version.txt
if [ $? != 0 ];
then
   die 6 "Could not update version number file."
fi

if [ -f $CH_ROOT/system/${release_ver}/post.sh ];
then
   /bin/echo "post.sh script found. running it."
   /bin/sh $CH_ROOT/system/${release_ver}/post.sh
fi
