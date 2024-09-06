#!/bin/bash
set -euf -o pipefail
function send_help(){
    cat <<"EOF"
Usage: ./getvmofport.sh <flags> <id>
Flags:
-s              Show group details
-h              For when you're confused.
-t              Cache time
-p              The project to inspect
EOF
exit 0
}
OPTSTRING=":sht:p:"
SHOW=false
while getopts "${OPTSTRING}" opt; do
  case ${opt} in
    s)
      SHOW=true
      ;;
    h)
      send_help
      ;;
    t)
      export CACHETIME=${OPTARG}
      ;;
    p)
      export _PROJECT=${OPTARG}
      ;;
    *)
      echo "Unknown flag"
      send_help
      ;;
  esac
done
source common.sh
secgroups="$(openstack security group list -c ID -f json "${PROJECT[@]}" | jq -r '.[].ID')"
getPorts
set +e
deadgroups=()
for group in $secgroups;do
grep -q -r "$group" ports/
    if [ $? == 1 ];then
        deadgroups+=("$group")
    fi
done
set -e

for group in "${deadgroups[@]}";do
  if [[ $SHOW == true ]];then
    openstack security group show -c id -c name -c description -c tags -c created_at "$group"
  else
    echo "$group"
  fi
done
