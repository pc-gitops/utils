#!/usr/bin/env bash

# Utility for updating aws-auth

set -euo pipefail

function usage()
{
    echo "usage ${0} [--dry-run] [--debug]>" >&2
}

function args() {
  dry_run=""
  debug=""

  arg_list=( "$@" )
  arg_count=${#arg_list[@]}
  arg_index=0
  while (( arg_index < arg_count )); do
    case "${arg_list[${arg_index}]}" in
          "--debug") debug="--debug";set -x;;
          "--dry-run") dry_run="--dry-run=client";;
               "-h") usage; exit;;
           "--help") usage; exit;;
               "-?") usage; exit;;
        *) if [ "${arg_list[${arg_index}]:0:2}" == "--" ];then
               echo "invalid argument: ${arg_list[${arg_index}]}" >&2
               usage; exit
           fi;
           break;;
    esac
    (( arg_index+=1 ))
  done
}

args "$@"

for c in $(ls -C1 clusters | grep -v management)
do
  source eks-cluster.sh $c
  if [[ $(kubectl get cm -n kube-system aws-auth -o=jsonpath='{@.data.mapRoles}' | grep management-github-infra-runner | wc -l) -gt 0 ]]; then
    echo "$c already updated"
    continue
  fi
  echo "============= $c ======================"
  echo -e "data:\n  mapRoles: |" > ~/work/patch.yaml
  kubectl get cm -n kube-system aws-auth -o json |jq -r '.data.mapRoles' | sed s/^/\ \ \ \ / | sed '/^[[:space:]]*$/d' >> ~/work/patch.yaml
  cat ~/work/new.yaml >> ~/work/patch.yaml
  if [ -n "$debug" ]; then
    cat ~/work/patch.yaml
    kubectl get cm -n kube-system aws-auth -o yaml
  fi
  kubectl patch cm -n kube-system aws-auth --type merge $dry_run --patch-file ~/work/patch.yaml -o yaml
done
