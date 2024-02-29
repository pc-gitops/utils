#!/bin/bash

# Utility to dump k8s objects to files
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@weave.works)

set -e


NAMESPACES=$(kubectl get -o json namespaces|jq '.items[].metadata.name'|sed "s/\"//g")
RESOURCES="configmap secret serviceaccounts clusterroles roles clusterrolebindings rolebindings pods deployment service hpa"

for ns in ${NAMESPACES};do
  for resource in ${RESOURCES};do
    rsrcs=$(kubectl -n ${ns} get -o json ${resource}|jq '.items[].metadata.name'|sed "s/\"//g")
    for r in ${rsrcs};do
      dir="${ns}/${resource}"
      mkdir -p "${dir}"
      kubectl -n ${ns} get -o yaml ${resource} ${r} > "${dir}/${r}.yaml"
    done
  done
done