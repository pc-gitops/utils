#!/bin/bash

# Utility to stop processes
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)


set -euo pipefail

function usage()
{
    set +x
    echo "USAGE: ${0##*/} [--debug] [--all] [--dry-run] [--force] <string to match processes>"
	echo " <string to match processes> is string passed to grep to match proccesses"
	echo "use '--debug' for verbose output"
	echo "use '--dry-run' to list processes but not stop them"
	echo "use '--force' to suppress prompt to confirm termination"
    echo "use '--all' to search all process, defaults to ones running on this terminal"
    echo "If the environmental variable NOT_PROCESS_GROUP is set, processes in that group will not be included"
    echo "use this when runnign this from another script to prevent it stopping that script"
}

function args() {
  unset all
  unset dry_run
  unset force
  unset target
  unset debug

  arg_list=( "$@" )
  arg_count=${#arg_list[@]}
  arg_index=0
  while (( arg_index < arg_count )); do
    case "${arg_list[${arg_index}]}" in
          "--debug") debug=1;set -x;;
            "--all") all="ax";;
        "--dry-run") dry_run=1;;
          "--force") force=1;;
               "-h") usage; exit;;
           "--help") usage; exit;;
               "-?") usage; exit;;
        *) if [ "${arg_list[${arg_index}]:0:2}" == "--" ];then
               echo "invalid argument: ${arg_list[${arg_index}]}"
               usage; exit
           fi;
           break;;
    esac
    (( arg_index+=1 ))
  done
  target="${arg_list[*]:$arg_index:$(( arg_count - arg_index + 1))}"
  if [ -z "${target:-}" ] ; then
      usage; exit 1
  fi
}

args $@

if [ -n "${debug:-}" ];then
    echo "list all processes on users terminal..."
    ps -o pid,pgid,cmd
fi

if [ -z "${NOT_PROCESS_GROUP:-}" ];then
    NOT_PROCESS_GROUP="$$"
fi
if { pids="$(ps -o pid,pgid,cmd ${all:-} | awk -F ' ' '$2 != '"${NOT_PROCESS_GROUP}"''| grep "${target}" | awk '{print $1}')"; }; then
    echo "found processes matching '$target'"
    ps -o pid,pgid,cmd ${pids}
    if [[ -z "${dry_run:-}" && -z "${force:-}" ]];then
        read -p  "press any key to stop process, ctl C to cancel"
    fi
    if [ -z "${dry_run:-}" ]; then
        kill -9 $pids
    fi
else
    echo "no matching processes not found"
fi
