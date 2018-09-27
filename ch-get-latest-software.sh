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

release_server_root="http://circuithappy.com/updates/missing-link"

software_update_status=0
system_update_status=0

# if we are passing in a beta download code, then we need to add that code to the server path
if [ ! -z "$1" ]
then
  release_server_root="$release_server_root/$1"
  /bin/echo "release_server_root is now:" $release_server_root
fi

/bin/sh $CH_ROOT/system/current/scripts/ch-update-missing-link.sh $release_server_root
software_update_status=$?

if $software_update_status -gt 1
then
  die $software_update_status
fi

/bin/sh $CH_ROOT/system/current/scripts/ch-update-system.sh $release_server_root
system_update_status=$?

if $system_update_status -gt 1
then
  die $system_update_status
fi

#if both exit with a code of 1 that means there's no updates and no need to reboot
if [[ $system_update_status -eq 1 && $software_update_status -eq 1 ]]
then
  die 1
fi
