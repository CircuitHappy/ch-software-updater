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

# check for /ch/system/current/new_system
if [ -d $CH_ROOT/current/new_system ]
then
  new_system_name=`ls | sort -n | head -1`
  if [ ! -d $CH_ROOT/current/new_system/$new_system_name ]
  then
      die 1 "new_system doesn't contain a new system folder. bailing."
  fi

  if [ -d $CH_ROOT/current/new_system/$new_system_name ]
  then
    die 2 "$new_system_name already exists. bailing."
  fi

  /bin/mv -r $CH_ROOT/current/new_system/$new_system_name $CH_ROOT/system/
  if [ -d $CH_ROOT/system/$new_system_name = false ]
  then
      die 2 "unable to move new_system in to $CH_ROOT/system/"
  fi

  /bin/rm $CH_ROOT/system/current
  if [ $? != 0 ] && [ -L $CH_ROOT/system/current ];
  then
      warn "this is bad, we couldn't remove the old system/current symlink "
  fi

  /bin/ln -s $CH_ROOT/system/$new_system_name $CH_ROOT/system/current
  if [ $? != 0 ] && [ ! -L $CH_ROOT/system/current ];
  then
      die 3 "unable to relink things, your system may be unusable after a reboot."
  fi
else
  warn "No new_system files to install."
fi
