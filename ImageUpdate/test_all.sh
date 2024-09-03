#!/bin/bash
set -euf -o pipefail
# shellcheck source=./common.sh
source ./common.sh
TMP_DIR=${TMP_DIR:=$(pwd)}
function send_help(){
    cat <<"EOF"
Usage: ./update_images <flags>
Flags:
-h              For when you're confused.
Function:
The script will read a json file and pass the values to update_generic.sh to download, modify and then upload OS images to openstack.
EOF
exit 0
}
OPTSTRING=":hf:"
while getopts "${OPTSTRING}" opt; do
  case ${opt} in
    h)
      send_help
      ;;
    *)
      warn "Unknown flag"
      send_help
      ;;
  esac
done

function test_image(){
  ./test_image.sh "$1"
}
export -f test_image
images=$(openstack image list --status active --public -c Name -f value)
parallel --jobs 4 --keep-order test_image ::: "${images[@]}"
