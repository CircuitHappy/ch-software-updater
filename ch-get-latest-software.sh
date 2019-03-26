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
script_root=$(dirname $(readlink -f $0))
/bin/echo "Script directory:" $script_root
beta_code=""

release_server_root="http://circuithappy.com/updates/missing-link"

software_update_status=0
system_update_status=0

if [ -f "$CH_ROOT/staging" ]
then
  release_server_root="$release_server_root-staging"
  /bin/echo "release_server_root is in staging:" $release_server_root
fi

# if we are passing in a beta download code, then we need to add that code to the server path
if [ ! -z "$1" ]
then
  beta_code="$1"
  release_server_root="$release_server_root/$1"
  /bin/echo "release_server_root is now:" $release_server_root
fi

/bin/sh $script_root/ch-update-missing-link.sh $release_server_root
software_update_status=$?

if [ $software_update_status -gt 1 ]
then
  die $software_update_status
fi

/bin/sh $script_root/ch-update-system.sh $release_server_root
system_update_status=$?

if [ $system_update_status -gt 1 ]
then
  die $system_update_status
fi

#if both exit with a code of 1 that means there's no updates and no need to reboot
if [ $system_update_status -eq 1 ] && [ $software_update_status -eq 1 ]
then
  die 1
fi

#update the beta_code to the beta_code.txt, it will contain the beta_code or be blank, if it's a mainline build
/bin/echo "$beta_code" > $CH_ROOT/beta_code.txt
if [ $? != 0 ];
then
   die 6 "Could not write $CH_ROOT/beta_code.txt"
fi
