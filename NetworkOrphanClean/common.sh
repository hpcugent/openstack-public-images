#!/bin/bash
set -euf -o pipefail
# Sets the cache expiry
_CACHETIME=${CACHETIME:=50}
# Add 30 second buffer to precent unnecessary cache refreshes during a run.
((_CACHETIME +=10))
PROJECT=${_PROJECT:-$(openstack project list --my-projects -f json | jq -r '.[].ID')}

if [[ -z ${_PROJECT:-} ]] || [[ $_PROJECT == "all" ]];then
  PROJECT=()
else
  PROJECT=(--project "$PROJECT")
fi
export PROJECT
# Set to true if cache is used
export IS_CACHED=false

function _getPorts(){
    IDs="$(openstack port list -f json "${PROJECT[@]}"| jq -r ".[] | .ID")"
    export IDs
}

function _writePortJson(){
    echo "$(openstack port show "$1" -f json)" > "ports/${1}.json"
}
#shellcheck disable=2120
function getPorts(){
  _getPorts
  if [[ -d ports/ ]];then
    lastModificationSeconds=$(date -r ports/ +%s)
    currentSeconds=$(date +%s)

    ((elapsedSeconds = currentSeconds - lastModificationSeconds))

    if [[ $elapsedSeconds -lt $_CACHETIME ]]; then
      IS_CACHED=true
      return
    else
      rm -rf ports/
    fi
  fi
  mkdir ports/
  export -f _writePortJson
  parallel --jobs 8 _writePortJson ::: "${IDs[@]}"
}
function getProperty(){
    arg_id=$1
    arg_prop=$2
    if [[ ! $IS_CACHED ]];then
      getPorts
    fi
    jq -r ".${arg_prop}" "ports/${arg_id}.json"
}
