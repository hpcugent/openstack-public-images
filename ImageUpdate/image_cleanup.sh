#!/bin/bash
source ./common.sh
set -euf -o pipefail
# shellcheck source=./common.sh
YES=false
function send_help(){
    cat <<"EOF"
Usage: ./update_cleanup <flags>
Flags:
-s              Show image list and exit
-y              Don't ask for confirmation at all.
-h              For when you're confused.
Function:
The script will get all deactivated images and allow you to clean them up.
EOF
exit 0
}
OPTSTRING=":ythf:"
while getopts ${OPTSTRING} opt; do
  case ${opt} in
    y)
      YES=true
      ;;
    h)
      send_help
      ;;
    *)
      warn "Unknown flag"
      send_help
      ;;
  esac
done
sourcerc

function deleteImages(){
    COUNT=0
    for id in $(openstack image list --public -f json | jq -r '.[] | select(.Status=="deactivated") | .ID');do
        openstack image delete "$id"
        COUNT=$((COUNT+1))
    done
    success "$COUNT images cleaned up."
}


IMAGES="$(openstack image list --public --status deactivated)"
if [ -z "$IMAGES" ];then
  warn "0 deactivated public images found"
  exit 0
fi
echo "$IMAGES"
if [ $YES == false ];then
    getConfirmation "Delete all deactivated images?" "Deleting all deactivated images!"
else
    REPLY="y"
fi
if [[ $REPLY =~ ^[Yy]$ ]]; then
    deleteImages
fi
